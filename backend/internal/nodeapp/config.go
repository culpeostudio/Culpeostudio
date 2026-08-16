// Package nodeapp assembles the deliberately small standalone Culpeo Node
// backend.  It keeps process configuration separate from the Engine and
// Marketplace packages, so those packages remain usable by Studio too.
package nodeapp

import (
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/culpeohq/backend/internal/appsettings"
)

const (
	defaultDataDir       = "data/culpeo-node"
	defaultListen        = "0.0.0.0:50051"
	defaultGatewayListen = "0.0.0.0:50052"
)

// Config contains the few operating values a standalone Node needs.  The
// pairing token and stable node id deliberately do not appear here: they are
// generated once and persisted by nodeagent.
type Config struct {
	DataDir   string
	ModelDir  string
	Listen    string
	Advertise string
	// GatewayListen is the separate HTTPS listener used solely for OpenAI
	// compatible inference. The regular Node control plane remains gRPC.
	GatewayListen       string
	GatewayAdvertise    string
	GatewayAdvertiseSet bool
	Name                string
	Version             string
	ModelDirSet         bool
}

// SettingsFile is the Engine and Marketplace settings document belonging to
// this Node.  It never overlaps Studio's default data/settings.json unless an
// operator deliberately points DataDir there.
func (c Config) SettingsFile() string { return filepath.Join(c.DataDir, "settings.json") }

// IdentityFile is private nodeagent state, separate from model and engine
// state so it remains stable across routine cleanup of those caches.
func (c Config) IdentityFile() string { return filepath.Join(c.DataDir, "node_identity.json") }

// FromEnv reads the small Node-specific environment contract.  It accepts a
// lookup function to keep configuration tests independent of process global
// state.
func FromEnv(lookup func(string) string) (Config, error) {
	if lookup == nil {
		lookup = os.Getenv
	}
	dataDir, err := cleanDirectory(lookup("CULPEO_NODE_DATA_DIR"), defaultDataDir, "Node-Datenordner")
	if err != nil {
		return Config{}, err
	}
	modelRaw := strings.TrimSpace(lookup("CULPEO_NODE_MODEL_DIR"))
	modelDir, err := resolveModelDirectory(dataDir, modelRaw)
	if err != nil {
		return Config{}, err
	}

	listen := strings.TrimSpace(lookup("CULPEO_NODE_LISTEN"))
	if listen == "" {
		listen = defaultListen
	}
	if err := validateBindAddress(listen); err != nil {
		return Config{}, fmt.Errorf("CULPEO_NODE_LISTEN: %w", err)
	}

	advertise := strings.TrimSpace(lookup("CULPEO_NODE_ADVERTISE"))
	if advertise == "" {
		// A concrete listen address is a good zero-configuration development
		// default.  Wildcards cannot be pasted into Studio, so production
		// services must state their reachable endpoint explicitly.
		if host, _, splitErr := net.SplitHostPort(listen); splitErr == nil && !isWildcardHost(host) {
			advertise = listen
		}
	}
	if err := validateAdvertiseAddress(advertise); err != nil {
		return Config{}, fmt.Errorf("CULPEO_NODE_ADVERTISE: %w", err)
	}
	gatewayListen := strings.TrimSpace(lookup("CULPEO_NODE_GATEWAY_LISTEN"))
	if gatewayListen == "" {
		gatewayListen = defaultGatewayListen
	}
	if err := validateBindAddress(gatewayListen); err != nil {
		return Config{}, fmt.Errorf("CULPEO_NODE_GATEWAY_LISTEN: %w", err)
	}
	gatewayAdvertiseRaw := strings.TrimSpace(lookup("CULPEO_NODE_GATEWAY_ADVERTISE"))
	gatewayAdvertise := gatewayAdvertiseRaw
	if gatewayAdvertise == "" {
		gatewayAdvertise, err = advertiseWithListenerPort(advertise, gatewayListen)
		if err != nil {
			return Config{}, fmt.Errorf("CULPEO_NODE_GATEWAY_ADVERTISE: %w", err)
		}
	}
	if err := validateGatewayAdvertise(gatewayAdvertise, gatewayAdvertiseRaw == ""); err != nil {
		return Config{}, fmt.Errorf("CULPEO_NODE_GATEWAY_ADVERTISE: %w", err)
	}

	return Config{
		DataDir:             dataDir,
		ModelDir:            modelDir,
		ModelDirSet:         modelRaw != "",
		Listen:              listen,
		Advertise:           advertise,
		GatewayListen:       gatewayListen,
		GatewayAdvertise:    gatewayAdvertise,
		GatewayAdvertiseSet: gatewayAdvertiseRaw != "",
		Name:                strings.TrimSpace(lookup("CULPEO_NODE_NAME")),
		Version:             strings.TrimSpace(lookup("CULPEO_NODE_VERSION")),
	}, nil
}

// GatewayURL is the public, TLS-only endpoint the Studio uses for streamed
// inference after it has authenticated over the pinned gRPC control plane.
func (c Config) GatewayURL() string {
	return "https://" + strings.TrimSpace(c.GatewayAdvertise)
}

func cleanDirectory(raw, fallback, description string) (string, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		value = fallback
	}
	if value == "" {
		return "", fmt.Errorf("%s fehlt", description)
	}
	if appsettings.LooksLikeWindowsPath(value) {
		return "", fmt.Errorf("%s ist ein Windows-Pfad", description)
	}
	abs, err := filepath.Abs(filepath.Clean(value))
	if err != nil {
		return "", fmt.Errorf("%s ist ungueltig", description)
	}
	resolved, err := resolveExistingPath(abs)
	if err != nil {
		return "", fmt.Errorf("%s ist ungueltig: %w", description, err)
	}
	if protectedSystemDirectory(resolved) {
		return "", fmt.Errorf("%s darf kein geschuetzter Systempfad sein", description)
	}
	return resolved, nil
}

// resolveExistingPath resolves every existing path component before a Node
// creates or chmods a directory. Without this, a harmless-looking path such
// as /srv/node-data could be a symlink to /etc and make the service change a
// system directory's permissions. A non-existing tail stays beneath the
// resolved parent; it is safe for MkdirAll to create on first start.
func resolveExistingPath(value string) (string, error) {
	value = filepath.Clean(value)
	if resolved, err := filepath.EvalSymlinks(value); err == nil {
		return filepath.Abs(resolved)
	} else if !errors.Is(err, os.ErrNotExist) {
		return "", err
	}

	parent := value
	var missing []string
	for {
		if _, err := os.Lstat(parent); err == nil {
			break
		} else if !errors.Is(err, os.ErrNotExist) {
			return "", err
		}
		base := filepath.Base(parent)
		next := filepath.Dir(parent)
		if next == parent {
			return "", fmt.Errorf("kein existierender Elternordner")
		}
		missing = append(missing, base)
		parent = next
	}
	resolvedParent, err := filepath.EvalSymlinks(parent)
	if err != nil {
		return "", err
	}
	for index := len(missing) - 1; index >= 0; index-- {
		resolvedParent = filepath.Join(resolvedParent, missing[index])
	}
	return filepath.Abs(resolvedParent)
}

// resolveModelDirectory makes a relative model directory deliberately belong
// to the Node data directory. It is also used for a persisted settings value,
// which must not bypass Node path validation just because it was written by a
// previous version of the generic settings store.
func resolveModelDirectory(dataDir, raw string) (string, error) {
	modelDir := strings.TrimSpace(raw)
	if modelDir == "" {
		modelDir = filepath.Join(dataDir, "models")
	} else if !filepath.IsAbs(modelDir) {
		modelDir = filepath.Join(dataDir, modelDir)
	}
	return cleanDirectory(modelDir, "", "Node-Modellordner")
}

// protectedSystemDirectory rejects both the roots and sensitive subtrees
// whose contents a Node must never own. prepareDataDir tightens permissions on
// its input, so accepting /etc/ssh or /usr/local here would let a mistaken
// service environment damage the host before the Node starts listening.
//
// /var/lib/<node>, /opt/<node>, /srv/<node>, temporary test directories, and
// a developer's working tree remain valid. Their broad parent directories are
// rejected only when selected directly.
func protectedSystemDirectory(value string) bool {
	value = filepath.Clean(value)
	for _, root := range []string{
		"/bin", "/boot", "/dev", "/etc", "/lib", "/lib32", "/lib64",
		"/proc", "/root", "/run", "/sbin", "/sys", "/usr",
		"/var/cache", "/var/log", "/var/run", "/var/spool",
	} {
		if pathAtOrBelow(value, root) {
			return true
		}
	}
	switch value {
	case "/", "/home", "/opt", "/srv", "/tmp", "/var", "/var/lib":
		return true
	}
	return false
}

func pathAtOrBelow(value, root string) bool {
	return value == root || strings.HasPrefix(value, root+string(filepath.Separator))
}

func validateBindAddress(value string) error {
	host, port, err := net.SplitHostPort(strings.TrimSpace(value))
	if err != nil || strings.TrimSpace(host) == "" {
		return fmt.Errorf("muss Host:Port sein")
	}
	if _, err := validListenPort(port); err != nil {
		return err
	}
	return nil
}

func validateGatewayAdvertise(value string, allowDynamicPort bool) error {
	host, port, err := net.SplitHostPort(strings.TrimSpace(value))
	if err != nil || strings.TrimSpace(host) == "" {
		return fmt.Errorf("muss die von Studio erreichbare Host:Port-Adresse sein")
	}
	if isWildcardHost(host) {
		return fmt.Errorf("darf keine Wildcard-Adresse sein")
	}
	if port == "0" && allowDynamicPort {
		return nil
	}
	if _, err := validPort(port); err != nil {
		return err
	}
	return nil
}

func validateAdvertiseAddress(value string) error {
	host, port, err := net.SplitHostPort(strings.TrimSpace(value))
	if err != nil || strings.TrimSpace(host) == "" {
		return fmt.Errorf("muss die von Studio erreichbare Host:Port-Adresse sein")
	}
	if isWildcardHost(host) {
		return fmt.Errorf("darf keine Wildcard-Adresse sein")
	}
	if _, err := validPort(port); err != nil {
		return err
	}
	return nil
}

func validPort(raw string) (int, error) {
	port, err := strconv.Atoi(raw)
	if err != nil || port < 1 || port > 65535 {
		return 0, fmt.Errorf("enthaelt keinen gueltigen Port")
	}
	return port, nil
}

func validListenPort(raw string) (int, error) {
	port, err := strconv.Atoi(raw)
	if err != nil || port < 0 || port > 65535 {
		return 0, fmt.Errorf("enthaelt keinen gueltigen Port")
	}
	return port, nil
}

func isWildcardHost(host string) bool {
	host = strings.Trim(strings.TrimSpace(host), "[]")
	if host == "" || host == "0.0.0.0" || host == "::" {
		return true
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsUnspecified()
}

func advertiseWithListenerPort(advertise, listener string) (string, error) {
	host, _, err := net.SplitHostPort(strings.TrimSpace(advertise))
	if err != nil {
		return "", fmt.Errorf("Node-Endpunkt muss Host:Port sein")
	}
	_, port, err := net.SplitHostPort(strings.TrimSpace(listener))
	if err != nil {
		return "", fmt.Errorf("Gateway-Listener muss Host:Port sein")
	}
	return net.JoinHostPort(host, port), nil
}
