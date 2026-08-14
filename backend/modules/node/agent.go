package node

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
	"github.com/culpeohq/backend/internal/wireguard"
)

// initializeNodeMode gives this machine an identity, writes its side of the
// tunnel and prints the join code a Studio is paired with.
//
// It is deliberately loud. A node is a headless process on another machine,
// and the join code is the only thing its operator has to take away from the
// first start; burying it in a debug log would make the feature unusable.
func (m *Module) initializeNodeMode() error {
	if err := m.identity.load(); err != nil {
		return err
	}
	if existing, ok := m.identity.get(); ok {
		m.announceIdentity(existing, false)
		return nil
	}

	fresh := identity{
		NodeID:    newID(),
		Name:      nodeName(),
		Token:     newToken(),
		CreatedAt: time.Now().UTC(),
	}
	if strings.TrimSpace(fresh.Token) == "" {
		return fmt.Errorf("Pairing-Token konnte nicht erzeugt werden")
	}

	endpoint := strings.TrimSpace(os.Getenv("CULPEO_NODE_WG_ENDPOINT"))
	if endpoint == "" {
		// Without a public address there is nothing to write into a peer
		// block, so no tunnel is built. The node still works for an operator
		// who runs their own: the identity and the token exist, and the Studio
		// can be pointed at them by hand.
		if err := m.identity.save(fresh); err != nil {
			return err
		}
		log.Printf("[node] Node-Modus ohne WireGuard: CULPEO_NODE_WG_ENDPOINT ist nicht gesetzt.")
		log.Printf("[node] Dieser Node laesst sich nur manuell hinzufuegen. Adresse und Ports selbst eintragen, Token: %s", fresh.Token)
		return nil
	}

	pairing, err := wireguard.Pair(wireguard.PairingRequest{
		NodeID:      fresh.NodeID,
		Name:        fresh.Name,
		Token:       fresh.Token,
		GRPCPort:    envPort("GRPC_PORT", 50051),
		GatewayPort: gatewayPortFromEnv(),
		Network:     strings.TrimSpace(os.Getenv("CULPEO_NODE_WG_NETWORK")),
		Endpoint:    endpoint,
		ListenPort:  envPort("CULPEO_NODE_WG_PORT", wireguard.DefaultListenPort),
	})
	if err != nil {
		return fmt.Errorf("Node-Tunnel vorbereiten: %w", err)
	}

	configPath := filepath.Join(m.tunnelDir, pairing.InterfaceName+".conf")
	if err := writeTunnelConfig(configPath, pairing.NodeConfig); err != nil {
		return err
	}

	fresh.InterfaceName = pairing.InterfaceName
	fresh.ConfigPath = configPath
	fresh.NodeAddress = pairing.NodeAddress
	fresh.ClientAddress = pairing.ClientAddress
	fresh.Endpoint = endpoint
	fresh.JoinCode = pairing.JoinCode
	if err := m.identity.save(fresh); err != nil {
		return err
	}
	m.announceIdentity(fresh, true)
	return nil
}

// InitOnly reports whether this process was started only to set the node up.
//
// It exists because of an ordering problem with no way around it: a node binds
// its control plane to its address inside the tunnel, and that tunnel is
// described by a config the node itself writes on first start. The first run
// therefore cannot serve anything - the interface it would bind to does not
// exist yet. Init mode does the setup, prints the join code and stops, so an
// installer can bring the tunnel up before the service is ever started.
func InitOnly() bool {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("CULPEO_NODE_INIT"))) {
	case "1", "true", "yes", "on":
		return true
	default:
		return false
	}
}

// PairingSummary is what an installer needs to print and to act on after the
// setup run.
type PairingSummary struct {
	NodeID        string
	Name          string
	Token         string
	JoinCode      string
	InterfaceName string
	ConfigPath    string
	NodeAddress   string
	Endpoint      string
}

// Pairing reports how this node was set up. It is empty on a Studio, and on a
// node that has not been initialised.
func (m *Module) Pairing() (PairingSummary, bool) {
	current, ok := m.identity.get()
	if !ok {
		return PairingSummary{}, false
	}
	return PairingSummary{
		NodeID:        current.NodeID,
		Name:          current.Name,
		Token:         current.Token,
		JoinCode:      current.JoinCode,
		InterfaceName: current.InterfaceName,
		ConfigPath:    current.ConfigPath,
		NodeAddress:   current.NodeAddress,
		Endpoint:      current.Endpoint,
	}, true
}

// announceIdentity prints what the operator has to act on.
func (m *Module) announceIdentity(current identity, fresh bool) {
	if fresh {
		log.Printf("[node] Node-Modus eingerichtet als %q (%s).", current.Name, current.NodeID)
	} else {
		log.Printf("[node] Node-Modus aktiv als %q (%s).", current.Name, current.NodeID)
	}
	if current.ConfigPath != "" {
		log.Printf("[node] Tunnel-Konfiguration: %s", current.ConfigPath)
		log.Printf("[node] Tunnel starten mit: %s", wireguard.RaiseCommand(current.ConfigPath))
	}
	if current.JoinCode != "" {
		log.Printf("[node] Join-Code fuer das Studio (eine Zeile, enthaelt den privaten Schluessel des Studios):")
		log.Printf("[node] %s", current.JoinCode)
	}
	if current.NodeAddress != "" {
		log.Printf("[node] Adresse im Tunnel: %s", current.NodeAddress)
	}
}

func writeTunnelConfig(path, contents string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return fmt.Errorf("Tunnel-Konfiguration schreiben: %w", err)
	}
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		return fmt.Errorf("Tunnel-Konfiguration schreiben: %w", err)
	}
	return nil
}

func nodeName() string {
	if configured := strings.TrimSpace(os.Getenv("CULPEO_NODE_NAME")); configured != "" {
		return configured
	}
	if host, err := os.Hostname(); err == nil && strings.TrimSpace(host) != "" {
		return strings.TrimSpace(host)
	}
	return "Node"
}

func envPort(name string, fallback int) int {
	raw := strings.TrimSpace(os.Getenv(name))
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil || value <= 0 || value > 65535 {
		log.Printf("[node] %s=%q ist kein gueltiger Port, es bleibt bei %d", name, raw, fallback)
		return fallback
	}
	return value
}

// gatewayPortFromEnv reads the port out of the engine's gateway address, which
// is where the port actually lives.
func gatewayPortFromEnv() int {
	address := strings.TrimSpace(os.Getenv("ENGINE_GATEWAY_ADDR"))
	if address == "" {
		return 8091
	}
	index := strings.LastIndex(address, ":")
	if index < 0 {
		return 8091
	}
	value, err := strconv.Atoi(address[index+1:])
	if err != nil || value <= 0 || value > 65535 {
		return 8091
	}
	return value
}

// agentService answers the calls a Studio makes on a node.
type agentService struct {
	nodev1.UnimplementedNodeAgentServiceServer
	module *Module
}

func (s *agentService) GetNodeStatus(
	ctx context.Context,
	_ *nodev1.GetNodeStatusRequest,
) (*nodev1.GetNodeStatusResponse, error) {
	current, ok := s.module.identity.get()
	if !ok {
		return nil, status.Error(codes.FailedPrecondition, "dieser Rechner laeuft nicht im Node-Modus")
	}
	bridge := s.module.agent
	response := &nodev1.GetNodeStatusResponse{
		NodeId:           current.NodeID,
		Name:             current.Name,
		Version:          buildVersion(),
		GatewayKeyIssued: strings.TrimSpace(current.GatewayKeyID) != "",
	}
	if bridge.Hardware != nil {
		profile := bridge.Hardware()
		response.Hardware = profile
		if profile != nil {
			response.DiskFreeBytes = profile.GetDiskFreeBytes()
		}
	}
	if bridge.ModelDir != nil {
		response.ModelDir = bridge.ModelDir()
	}
	if bridge.ModelCount != nil {
		response.ModelCount = int32(bridge.ModelCount())
	}
	if bridge.InstanceCount != nil {
		response.InstanceCount = int32(bridge.InstanceCount())
	}
	if bridge.GatewayBaseURL != nil {
		response.GatewayBaseUrl = s.module.reachableGatewayURL(bridge.GatewayBaseURL(), current.NodeAddress)
	}
	return response, nil
}

func (s *agentService) IssueGatewayKey(
	ctx context.Context,
	req *nodev1.IssueGatewayKeyRequest,
) (*nodev1.IssueGatewayKeyResponse, error) {
	current, ok := s.module.identity.get()
	if !ok {
		return nil, status.Error(codes.FailedPrecondition, "dieser Rechner laeuft nicht im Node-Modus")
	}
	bridge := s.module.agent
	if bridge.IssueGatewayKey == nil {
		return nil, status.Error(codes.Unavailable, "die Engine dieses Nodes kann keine Gateway-Schluessel ausstellen")
	}
	label := strings.TrimSpace(req.GetLabel())
	if label == "" {
		label = "Culpeo Studio"
	}
	keyID, secret, err := bridge.IssueGatewayKey(label)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Gateway-Schluessel ausstellen: %v", err)
	}
	if _, err := s.module.identity.update(func(value *identity) { value.GatewayKeyID = keyID }); err != nil {
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	response := &nodev1.IssueGatewayKeyResponse{KeyId: keyID, Secret: secret}
	if bridge.GatewayBaseURL != nil {
		response.GatewayBaseUrl = s.module.reachableGatewayURL(bridge.GatewayBaseURL(), current.NodeAddress)
	}
	return response, nil
}

// reachableGatewayURL rewrites a loopback gateway address to the node's tunnel
// address. A node whose gateway still listens on 127.0.0.1 is usable for
// downloads but not for inference, and reporting the loopback URL would send
// the Studio to its own machine - which is worse than reporting nothing.
func (m *Module) reachableGatewayURL(baseURL, nodeAddress string) string {
	baseURL = strings.TrimSpace(baseURL)
	if baseURL == "" || strings.TrimSpace(nodeAddress) == "" {
		return ""
	}
	trimmed := strings.TrimPrefix(strings.TrimPrefix(baseURL, "http://"), "https://")
	host, port, found := strings.Cut(trimmed, ":")
	if !found {
		return ""
	}
	switch host {
	case "127.0.0.1", "localhost", "::1", "[::1]":
		return ""
	case "0.0.0.0", "::", "[::]":
		// Listening everywhere includes the tunnel, so the address the Studio
		// should use is the node's address in it.
		host = nodeAddress
	}
	return "http://" + joinHostPortString(host, port)
}

func joinHostPortString(host, port string) string {
	if strings.Contains(host, ":") && !strings.HasPrefix(host, "[") {
		host = "[" + host + "]"
	}
	return host + ":" + port
}

// buildVersion reports what this node runs, so a Studio can say when the two
// have drifted apart.
func buildVersion() string {
	if configured := strings.TrimSpace(os.Getenv("CULPEO_VERSION")); configured != "" {
		return configured
	}
	return "dev"
}
