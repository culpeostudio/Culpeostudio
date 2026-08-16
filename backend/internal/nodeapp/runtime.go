package nodeapp

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/grpcserver"
	"github.com/culpeohq/backend/internal/nodecert"
	"github.com/culpeohq/backend/internal/nodeconnection"
	"github.com/culpeohq/backend/internal/nodegateway"
	"github.com/culpeohq/backend/modules/engine"
	"github.com/culpeohq/backend/modules/marketplace"
	"github.com/culpeohq/backend/modules/nodeagent"
)

// Runtime is one standalone Node process.  It contains only the services a
// remote Studio needs to place models on this machine and operate them:
// NodeAgentService, MarketplaceService, and EngineService.
type Runtime struct {
	config Config

	engine      *engine.EngineModule
	marketplace *marketplace.MarketplaceModule
	agent       *nodeagent.Service
	grpc        *grpcserver.Server
	gateway     *nodegateway.Gateway

	link string

	closeOnce sync.Once
	closeErr  error
}

const gracefulGRPCStopTimeout = 10 * time.Second

// New assembles and initializes a standalone Node.  It never loads Studio
// configuration or registers a Studio module, and it does not create a
// network listener until Run is called.
func New(config Config) (*Runtime, error) {
	config, err := normalizeConfig(config)
	if err != nil {
		return nil, err
	}
	if err := prepareDataDir(config.DataDir); err != nil {
		return nil, err
	}
	if err := prepareSettings(config); err != nil {
		return nil, err
	}

	certificate, err := nodecert.Ensure(config.DataDir)
	if err != nil {
		return nil, err
	}

	engineModule := engine.New(config.SettingsFile())
	// The external Node gateway is a separate TLS proxy. The Engine stays on
	// an ephemeral loopback port, so it can never accidentally become public
	// and several Node tests/processes do not fight over a fixed local port.
	engineModule.SetGatewayBind("127.0.0.1:0")
	marketplaceModule := marketplace.New(config.SettingsFile())
	gatewayURL := ""
	agent, err := nodeagent.New(nodeagent.Config{
		IdentityPath: config.IdentityFile(),
		Name:         config.Name,
		Version:      config.Version,
	}, nodeagent.AgentBridge{
		Hardware:        marketplaceModule.HardwareProfileProto,
		ModelDir:        engineModule.ModelDir,
		ModelCount:      engineModule.CatalogSize,
		InstanceCount:   engineModule.InstanceCount,
		GatewayBaseURL:  func() string { return gatewayURL },
		IssueGatewayKey: engineModule.IssueGatewayKey,
	})
	if err != nil {
		return nil, fmt.Errorf("Node-Identitaet einrichten: %w", err)
	}

	link, err := connectionLink(config, certificate, agent)
	if err != nil {
		return nil, err
	}

	if err := engineModule.Initialize(); err != nil {
		return nil, fmt.Errorf("Engine initialisieren: %w", err)
	}
	if err := marketplaceModule.Initialize(); err != nil {
		_ = engineModule.Shutdown()
		return nil, fmt.Errorf("Marketplace initialisieren: %w", err)
	}
	gateway, err := nodegateway.Start(nodegateway.Config{
		ListenAddress: config.GatewayListen,
		UpstreamURL:   engineModule.GatewayBaseURL(),
		TLSCertFile:   certificate.CertificatePath,
		TLSKeyFile:    certificate.PrivateKeyPath,
	})
	if err != nil {
		_ = engineModule.Shutdown()
		return nil, fmt.Errorf("TLS-Inferenzgateway starten: %w", err)
	}
	gatewayURL, err = publicGatewayURL(config, gateway.Address())
	if err != nil {
		_ = gateway.Close()
		_ = engineModule.Shutdown()
		return nil, err
	}

	host, port, _ := net.SplitHostPort(config.Listen)
	grpcServer, err := grpcserver.New(grpcserver.Config{
		Host: host,
		Port: port,
		Auth: grpcmw.AuthConfig{
			OnlyAlternateAuth: true,
			AlternateAuth:     agent.AlternateAuth,
		},
		TLSCert: certificate.CertificatePath,
		TLSKey:  certificate.PrivateKeyPath,
	})
	if err != nil {
		_ = gateway.Close()
		_ = engineModule.Shutdown()
		return nil, fmt.Errorf("TLS-Steuerungsebene einrichten: %w", err)
	}
	engineModule.RegisterGRPC(grpcServer.GetGRPC())
	marketplaceModule.RegisterGRPC(grpcServer.GetGRPC())
	agent.RegisterGRPC(grpcServer.GetGRPC())

	return &Runtime{
		config:      config,
		engine:      engineModule,
		marketplace: marketplaceModule,
		agent:       agent,
		grpc:        grpcServer,
		gateway:     gateway,
		link:        link,
	}, nil
}

// PairingLink creates or reads only the long-lived local pairing material and
// returns the single link that is pasted into Studio.  It does not initialize
// an Engine, download anything, or start a listener, so it is safe as an
// explicit `culpeo-node pairing-link` command.
func PairingLink(config Config) (string, error) {
	config, err := normalizeConfig(config)
	if err != nil {
		return "", err
	}
	if err := prepareDataDir(config.DataDir); err != nil {
		return "", err
	}
	certificate, err := nodecert.Ensure(config.DataDir)
	if err != nil {
		return "", err
	}
	agent, err := nodeagent.New(nodeagent.Config{
		IdentityPath: config.IdentityFile(),
		Name:         config.Name,
		Version:      config.Version,
	}, nodeagent.AgentBridge{})
	if err != nil {
		return "", fmt.Errorf("Node-Identitaet einrichten: %w", err)
	}
	return connectionLink(config, certificate, agent)
}

func connectionLink(config Config, certificate nodecert.Certificate, agent *nodeagent.Service) (string, error) {
	link, err := nodeconnection.Encode(nodeconnection.Connection{
		NodeID:      agent.Identity().NodeID,
		Endpoint:    config.Advertise,
		Fingerprint: certificate.Fingerprint,
		Token:       agent.PairingToken(),
		Name:        agent.Identity().Name,
	})
	if err != nil {
		return "", fmt.Errorf("Node-Verbindungslink erzeugen: %w", err)
	}
	return link, nil
}

// ConnectionLink is sensitive credential material.  It is intentionally
// returned only to callers that explicitly ask for it; Run never logs it.
func (r *Runtime) ConnectionLink() string { return r.link }

// Run starts the TLS-only gRPC control plane and blocks until ctx is cancelled
// or the listener exits with an error.  Its shutdown path stops the Engine so
// child model processes are not orphaned.
func (r *Runtime) Run(ctx context.Context) error {
	if r == nil || r.grpc == nil {
		return fmt.Errorf("Node-Laufzeit ist nicht eingerichtet")
	}
	done := make(chan error, 1)
	go func() { done <- r.grpc.Start() }()

	select {
	case err := <-done:
		_ = r.Close()
		if err == nil {
			return fmt.Errorf("Node-Steuerungsebene wurde unerwartet beendet")
		}
		return err
	case <-ctx.Done():
		r.stopGRPC()
		err := <-done
		closeErr := r.Close()
		if err != nil && !errors.Is(err, net.ErrClosed) {
			return err
		}
		return closeErr
	}
}

// stopGRPC gives finite unary calls a chance to finish, but does not let an
// open event stream prevent systemd or SIGTERM from stopping the Node forever.
func (r *Runtime) stopGRPC() {
	stopped := make(chan struct{})
	go func() {
		r.grpc.Stop()
		close(stopped)
	}()
	select {
	case <-stopped:
	case <-time.After(gracefulGRPCStopTimeout):
		r.grpc.ForceStop()
		<-stopped
	}
}

// Close stops local modules.  It is safe to call more than once.
func (r *Runtime) Close() error {
	if r == nil {
		return nil
	}
	r.closeOnce.Do(func() {
		var failures []string
		if r.gateway != nil {
			if err := r.gateway.Close(); err != nil {
				failures = append(failures, err.Error())
			}
		}
		if r.engine != nil {
			if err := r.engine.Shutdown(); err != nil {
				failures = append(failures, err.Error())
			}
		}
		if r.marketplace != nil {
			if err := r.marketplace.Shutdown(); err != nil {
				failures = append(failures, err.Error())
			}
		}
		if len(failures) > 0 {
			r.closeErr = fmt.Errorf("Node stoppen: %s", strings.Join(failures, "; "))
		}
	})
	return r.closeErr
}

func normalizeConfig(config Config) (Config, error) {
	dataDir, err := cleanDirectory(config.DataDir, defaultDataDir, "Node-Datenordner")
	if err != nil {
		return Config{}, err
	}
	modelDir, err := resolveModelDirectory(dataDir, config.ModelDir)
	if err != nil {
		return Config{}, err
	}
	listen := strings.TrimSpace(config.Listen)
	if listen == "" {
		listen = defaultListen
	}
	if err := validateBindAddress(listen); err != nil {
		return Config{}, fmt.Errorf("Node-Listen-Adresse: %w", err)
	}
	advertise := strings.TrimSpace(config.Advertise)
	if advertise == "" {
		if host, _, splitErr := net.SplitHostPort(listen); splitErr == nil && !isWildcardHost(host) {
			advertise = listen
		}
	}
	if err := validateAdvertiseAddress(advertise); err != nil {
		return Config{}, fmt.Errorf("Node-Erreichbarkeit: %w", err)
	}
	gatewayListen := strings.TrimSpace(config.GatewayListen)
	if gatewayListen == "" {
		gatewayListen = defaultGatewayListen
	}
	if err := validateBindAddress(gatewayListen); err != nil {
		return Config{}, fmt.Errorf("Node-Gateway-Listen-Adresse: %w", err)
	}
	gatewayAdvertise := strings.TrimSpace(config.GatewayAdvertise)
	if gatewayAdvertise == "" {
		gatewayAdvertise, err = advertiseWithListenerPort(advertise, gatewayListen)
		if err != nil {
			return Config{}, fmt.Errorf("Node-Gateway-Erreichbarkeit: %w", err)
		}
	}
	if err := validateGatewayAdvertise(gatewayAdvertise, !config.GatewayAdvertiseSet); err != nil {
		return Config{}, fmt.Errorf("Node-Gateway-Erreichbarkeit: %w", err)
	}
	config.DataDir = dataDir
	config.ModelDir = modelDir
	config.Listen = listen
	config.Advertise = advertise
	config.GatewayListen = gatewayListen
	config.GatewayAdvertise = gatewayAdvertise
	config.Name = strings.TrimSpace(config.Name)
	config.Version = strings.TrimSpace(config.Version)
	return config, nil
}

func publicGatewayURL(config Config, actualListenAddress string) (string, error) {
	advertise := config.GatewayAdvertise
	_, configuredPort, configErr := net.SplitHostPort(config.GatewayListen)
	if configErr != nil {
		return "", fmt.Errorf("Node-Gateway-Listen-Adresse: %w", configErr)
	}
	if configuredPort == "0" && !config.GatewayAdvertiseSet {
		host, _, advertiseErr := net.SplitHostPort(advertise)
		if advertiseErr != nil {
			return "", fmt.Errorf("Node-Gateway-Erreichbarkeit: %w", advertiseErr)
		}
		_, actualPort, actualErr := net.SplitHostPort(actualListenAddress)
		if actualErr != nil {
			return "", fmt.Errorf("Node-Gateway-Adresse: %w", actualErr)
		}
		advertise = net.JoinHostPort(host, actualPort)
	}
	if err := validateAdvertiseAddress(advertise); err != nil {
		return "", fmt.Errorf("Node-Gateway-Erreichbarkeit: %w", err)
	}
	return "https://" + advertise, nil
}

func prepareDataDir(dataDir string) error {
	if err := os.MkdirAll(dataDir, 0o700); err != nil {
		return fmt.Errorf("Node-Datenordner anlegen: %w", err)
	}
	if err := os.Chmod(dataDir, 0o700); err != nil {
		return fmt.Errorf("Zugriffsrechte des Node-Datenordners absichern: %w", err)
	}
	return nil
}

func prepareSettings(config Config) error {
	store := appsettings.NewStore(config.SettingsFile())
	if err := store.Load(); err != nil {
		return fmt.Errorf("Node-Settings laden: %w", err)
	}
	modelDir := config.ModelDir
	if !config.ModelDirSet {
		// Preserve a deliberately configured directory from a previous service
		// run.  The generic appsettings default is only a placeholder and is
		// replaced by the Node's own data/models directory.
		if current := strings.TrimSpace(store.Get().ModelDir); current != "" && current != appsettings.DefaultModelDir {
			var err error
			modelDir, err = resolveModelDirectory(config.DataDir, current)
			if err != nil {
				return fmt.Errorf("gespeicherter Node-Modellordner: %w", err)
			}
		}
	}
	if _, err := store.Update(appsettings.Update{ModelDir: &modelDir}); err != nil {
		return fmt.Errorf("Node-Modellordner vorbereiten: %w", err)
	}
	return nil
}
