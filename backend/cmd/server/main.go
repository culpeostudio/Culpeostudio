// Command server runs the Culpeo Studio backend: the gRPC control plane, the
// module registry, and the small HTTP server the memory viewer still needs.
package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"

	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/config"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/grpcserver"
	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memoryembed"
	"github.com/culpeohq/backend/internal/middleware"

	modModule "github.com/culpeohq/backend/modules"
	modBenchmark "github.com/culpeohq/backend/modules/benchmark"
	modCulpeosearch "github.com/culpeohq/backend/modules/culpeosearch"
	modEngine "github.com/culpeohq/backend/modules/engine"
	modLogin "github.com/culpeohq/backend/modules/login"
	modMarketplace "github.com/culpeohq/backend/modules/marketplace"
	modMemory "github.com/culpeohq/backend/modules/memory"
	modNews "github.com/culpeohq/backend/modules/news"
	modNode "github.com/culpeohq/backend/modules/node"
	modProviders "github.com/culpeohq/backend/modules/providers"
	modScout "github.com/culpeohq/backend/modules/scout"
	modSettings "github.com/culpeohq/backend/modules/settings"
	modSkills "github.com/culpeohq/backend/modules/skills"
	modSpark "github.com/culpeohq/backend/modules/spark"
)

func main() {
	cfg := config.Load()
	loginModule := modLogin.New(
		cfg.JWTSecret,
		cfg.LoginAccountsFile,
		cfg.AuthConfigFile,
		cfg.UserPreferencesFile,
	)

	// What is left of the HTTP server: the memory viewer, an HTML page a
	// browser renders, plus the endpoints that page fetches and the health
	// probe. Everything the app talks to is gRPC.
	app := fiber.New(fiber.Config{
		AppName:      "Culpeo Studio Backend",
		ServerHeader: "Culpeo Studio",

		Immutable: true,
	})

	app.Use(logger.New())
	app.Use(recover.New())
	app.Use(middleware.AuthMiddleware(cfg.JWTSecret, loginModule.UserExists))

	api := app.Group("/api")

	memoryModule := modMemory.New(
		cfg.MemorySQLitePath,
		cfg.MemoryVectorPath,
		memoryembed.Config{
			Backend:        cfg.EmbeddingBackend,
			HashDims:       cfg.EmbeddingHashDims,
			SidecarURL:     cfg.EmbeddingSidecarURL,
			SidecarModel:   cfg.EmbeddingSidecarModel,
			OllamaURL:      cfg.EmbeddingOllamaURL,
			OllamaModel:    cfg.EmbeddingOllamaModel,
			APIURL:         cfg.EmbeddingAPIURL,
			APIKey:         cfg.EmbeddingAPIKey,
			APIModel:       cfg.EmbeddingAPIModel,
			MinFreeMemMB:   cfg.EmbeddingMinFreeMemMB,
			MinCores:       cfg.EmbeddingMinCores,
			TimeoutSeconds: cfg.EmbeddingTimeoutSec,
		},
		cfg.MemoryProjectTag,
		cfg.MemoryAPIToken,
		cfg.MemoryDefaultUserID,
		cfg.MemoryContextBudget,
		memory.CompressionPolicy{
			UserDataThreshold:          cfg.UserThreshold,
			ProjectStatusThreshold:     cfg.StatusThreshold,
			ProjectBrainstormThreshold: cfg.BrainstormThreshold,
			ChangeRequestThreshold:     cfg.ChangeRequestThreshold,
		},
		cfg.CaptureRateLimit,
		cfg.ChatWindowSize,
		cfg.ChatOverlapSize,
		cfg.MemoryViewerTitle,
		modMemory.MaintenanceConfig{
			ReindexInterval:     time.Duration(cfg.MemoryReindexIntervalSeconds) * time.Second,
			ReindexBatchSize:    cfg.MemoryReindexBatchSize,
			ReindexConcurrency:  cfg.MemoryReindexConcurrency,
			SoftDeleteRetention: time.Duration(cfg.MemorySoftDeleteRetentionDays) * 24 * time.Hour,
		},
		cfg.MemoryTokenizerFamily,
		cfg.MemoryTokenizerModelPath,
	)

	scoutModule := modScout.New(cfg.SettingsFile)
	providerModule := modProviders.New(cfg.SettingsFile, cfg.ProviderEncryptionSecret)
	sparkModule := modSpark.New(cfg.SettingsFile)

	scoutModule.SetProviderConnections(providerModule.Manager())
	scoutModule.SetAgent(sparkModule)
	sparkModule.SetMemory(memoryModule)
	sparkModule.SetPlanStore(scoutModule)
	sparkModule.SetProjectDetachedHook(scoutModule.DetachProject)
	scoutModule.SetExistingUsers(loginModule.ListUserIDs)
	loginModule.SetUserCreatedHook(scoutModule.EnsureUser)

	// The node module comes first and is initialised out of turn, because node
	// mode decides where the engine's gateway binds: a node serves its models
	// on its address inside the tunnel, and the engine reads that when it is
	// built rather than later.
	nodeModule := modNode.New(cfg.SettingsFile)
	if err := nodeModule.Initialize(); err != nil {
		log.Fatalf("[node] Initialisierung fehlgeschlagen: %v", err)
	}
	// The setup run of a node stops here. It has written the identity and the
	// tunnel config and printed the join code; it cannot serve, because the
	// interface it would bind to is the one that config describes and nobody
	// has brought it up yet. The installer does that, then starts the service.
	if nodeModule.InNodeMode() && modNode.InitOnly() {
		if pairing, ok := nodeModule.Pairing(); ok && pairing.JoinCode == "" {
			log.Printf("[node] Kein Join-Code: ohne CULPEO_NODE_WG_ENDPOINT wird kein Tunnel gebaut.")
		}
		return
	}

	engineModule := modEngine.New(cfg.SettingsFile)
	if bind := nodeModule.GatewayBind(); bind != "" {
		engineModule.EnableNodeGateway(bind)
	}
	marketplaceModule := modMarketplace.New(cfg.SettingsFile)

	scoutModule.SetLocalModels(engineModule)
	skillsModule := modSkills.New("data/skills")

	searchModule := modCulpeosearch.New()

	// What a node reports about itself. The engine owns the models and the
	// gateway, the marketplace owns hardware detection; the node module is
	// handed both as functions so it depends on neither.
	nodeModule.SetAgentBridge(modNode.AgentBridge{
		Hardware:        marketplaceModule.HardwareProfileProto,
		ModelDir:        engineModule.ModelDir,
		ModelCount:      engineModule.CatalogSize,
		InstanceCount:   engineModule.InstanceCount,
		GatewayBaseURL:  engineModule.GatewayBaseURL,
		IssueGatewayKey: engineModule.IssueGatewayKey,
	})
	// And what a Studio does with its nodes: run downloads and models on them.
	engineModule.SetNodes(nodeModule)
	marketplaceModule.SetNodes(nodeModule)

	modules := []modModule.Module{
		memoryModule,
		loginModule,
		// Als Variable, weil der Node-Teil sie noch verdrahtet.
		marketplaceModule,
		providerModule,
		scoutModule,
		sparkModule,
		modSettings.New(cfg.SettingsFile),
		skillsModule,
		engineModule,
		nodeModule,
		modNews.New(cfg.NewsSavedFile),
		modBenchmark.New(cfg.BenchmarkCacheDir, cfg.SettingsFile),
		searchModule,
	}

	// Registered separately from the loop below, because the gRPC server is
	// only built further down once the modules exist.
	var grpcModules []modModule.GRPCRegistrar

	for _, m := range modules {
		if err := m.Initialize(); err != nil {
			log.Fatalf("[%s] Initialisierung fehlgeschlagen: %v", m.Name(), err)
		}
		if grpcModule, ok := m.(modModule.GRPCRegistrar); ok {
			grpcModules = append(grpcModules, grpcModule)
		}
	}

	// Memory is the only module left with HTTP routes, so it is wired by name
	// rather than through an interface nothing else implements.
	memoryModule.RegisterRoutes(api)
	memoryModule.RegisterAppRoutes(app)

	eventBus := bus.Get()

	memoryModule.AttachBus(eventBus)

	eventBus.On(bus.EventModelDownloaded, func(e bus.Event) {
		log.Printf("[Bus] Modell heruntergeladen: %v – Engine kann Modell-Liste aktualisieren", e.Data)
	})

	eventBus.OnAll(func(e bus.Event) {
		log.Printf("[Bus] %s -> %s: %v", e.Source, e.Type, e.Data)
	})

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"modules": len(modules),
		})
	})

	api.Post("/shutdown", func(c *fiber.Ctx) error {
		log.Println("[API] Shutdown requested via HTTP")
		go func() {
			time.Sleep(200 * time.Millisecond)
			if p, err := os.FindProcess(os.Getpid()); err == nil {
				_ = p.Signal(syscall.SIGINT)
			}
		}()
		return c.JSON(fiber.Map{"status": "shutting down"})
	})

	// A node's control plane belongs on the tunnel: loopback would put it out
	// of the Studio's reach, and every interface would offer it to whatever
	// network the machine happens to sit on.
	grpcHost := cfg.HTTPHost
	if nodeHost := nodeModule.ControlPlaneHost(); nodeHost != "" {
		grpcHost = nodeHost
		log.Printf("[node] gRPC hoert auf %s:%s, erreichbar nur ueber den Tunnel", grpcHost, cfg.GRPCPort)
	}

	grpcSrv, err := grpcserver.New(grpcserver.Config{
		Host: grpcHost,
		Port: cfg.GRPCPort,
		Auth: grpcmw.AuthConfig{
			Secret:        cfg.JWTSecret,
			IsActiveUser:  loginModule.UserExists,
			PublicMethods: publicGRPCMethods(),
			// Two credentials that are not this app's login reach the modules
			// that issued them, and nothing else. Memory hands its API token to
			// tools outside the app, which have no account to log in with; a
			// node hands its pairing token to the one Studio it is paired with.
			AlternateAuth: func(ctx context.Context, fullMethod, token string) (string, bool) {
				if userID, ok := memoryModule.AuthenticateGRPCToken(ctx, fullMethod, token); ok {
					return userID, true
				}
				return nodeModule.AuthenticateGRPCToken(ctx, fullMethod, token)
			},
		},
		TLSCert: cfg.TLSCert,
		TLSKey:  cfg.TLSKey,
		RateLimits: []grpcmw.RateLimit{
			{
				// Provider discovery can fan out to third-party catalogues. Keep
				// it bounded per authenticated caller without slowing local chat.
				Limiter: providerModule.Limiter(),
				Applies: func(fullMethod string) bool {
					return strings.HasPrefix(fullMethod, "/culpeostudio.providers.v1.ProviderService/")
				},
			},
			{
				// CulpeoSearch fans every call out to public engines, so an
				// unbounded caller would hammer them on our behalf.
				Limiter: searchModule.Limiter(),
				Applies: func(fullMethod string) bool {
					return strings.HasPrefix(fullMethod, "/culpeostudio.search.v1.SearchService/")
				},
			},
			{
				// Memory capture is called on every chat turn and writes to the
				// store each time.
				Limiter: memoryModule.CaptureLimiter(),
				Applies: modMemory.RateLimitedGRPCMethod,
			},
		},
	})
	if err != nil {
		log.Fatalf("[gRPC] Start fehlgeschlagen: %v", err)
	}

	for _, m := range grpcModules {
		m.RegisterGRPC(grpcSrv.GetGRPC())
	}
	log.Printf("[gRPC] %d Module registriert", len(grpcModules))

	go func() {
		err := grpcSrv.Start()
		if err == nil {
			return
		}
		// Every client talks to this process exclusively over gRPC, so a
		// listener that never came up (e.g. the port is already held by
		// another process, such as a node running locally) leaves a backend
		// that looks alive on /health but answers nothing. Logging and
		// carrying on used to hide that: the frontend would dial the port,
		// reach whatever else is squatting on it, and hang until its own
		// per-call deadline before surfacing a timeout with no clue why.
		// Failing loudly here turns that into an immediate, diagnosable
		// crash instead.
		log.Fatalf("[gRPC] Start fehlgeschlagen: %v", err)
	}()

	go func() {

		addr := cfg.HTTPHost + ":" + cfg.HTTPPort
		if cfg.UseHTTPS && cfg.TLSCert != "" && cfg.TLSKey != "" {
			log.Printf("[HTTPS] Server läuft auf %s", addr)
			if err := app.ListenTLS(addr, cfg.TLSCert, cfg.TLSKey); err != nil {
				log.Fatalf("[HTTPS] Fehler: %v", err)
			}
		} else {
			log.Printf("[HTTP] Server läuft auf %s", addr)
			if err := app.Listen(addr); err != nil {
				log.Fatalf("[HTTP] Fehler: %v", err)
			}
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Server wird heruntergefahren...")

	for _, m := range modules {
		if err := m.Shutdown(); err != nil {
			log.Printf("[%s] Shutdown-Fehler: %v", m.Name(), err)
		}
	}

	grpcSrv.Stop()

	if err := app.Shutdown(); err != nil {
		log.Fatalf("Fiber Shutdown-Fehler: %v", err)
	}

	log.Println("Server gestoppt.")
}
