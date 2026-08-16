// Package node connects one Studio to the other machines it is allowed to run
// models on.
//
// A node is not a different kind of program: it is this same backend, started
// in node mode on another machine and reached over a WireGuard tunnel. That is
// what makes the feature small enough to be trustworthy. The Studio does not
// invent a second protocol for downloading or starting models - it calls the
// node's own EngineService and MarketplaceService, authenticated with the
// node's pairing token, and the node does the work with the code it already
// runs for itself.
//
// Two things follow from that, and both are the point:
//
//   - A download aimed at a node is fetched by the node, straight from the
//     model host. A file of tens of gigabytes never crosses the tunnel.
//   - A model started on a node appears beside the local ones in the engine.
//     Only its process is elsewhere; its output is streamed back through the
//     node's OpenAI gateway.
package node

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	hardwarev1 "github.com/culpeohq/backend/gen/go/culpeostudio/hardware/v1"
	"github.com/culpeohq/backend/internal/noderouting"
)

var (
	// errNodeUnknown is returned for an id no longer in the registry. It is a
	// sentinel because the gRPC layer turns it into NotFound and the engine
	// turns it into "this instance is gone".
	errNodeUnknown = errors.New("Node ist nicht hinterlegt")
	// errNodeDisabled separates "switched off here" from "not reachable",
	// because the remedy is different.
	errNodeDisabled = errors.New("Node ist deaktiviert")
)

// AgentBridge is what a node reports about the machine it runs on. Every entry
// comes from a module this one must not import - the engine owns the gateway
// and the instances, the marketplace owns hardware detection - so they arrive
// as functions wired in cmd/server rather than as package dependencies.
type AgentBridge struct {
	Hardware        func() *hardwarev1.HardwareProfile
	ModelDir        func() string
	ModelCount      func() int
	InstanceCount   func() int
	GatewayBaseURL  func() string
	IssueGatewayKey func(label string) (keyID string, secret string, err error)
}

// Module is the node module. On a Studio it holds the registry of nodes; in
// node mode it holds this machine's own identity and answers the agent calls.
type Module struct {
	dataDir   string
	tunnelDir string

	registry *registry

	connectionsMu sync.Mutex
	connections   map[string]*pooledConnection

	// nodeMode makes this backend a node: it generates an identity, prints a
	// join code and accepts a Studio's pairing token. A Studio and a node are
	// the same binary, and only this flag separates them.
	nodeMode    bool
	identity    *identityStore
	agent       AgentBridge
	initialized bool
}

var _ Directory = (*Module)(nil)

// New builds the module. settingsFile names the settings file the rest of the
// backend uses; only its directory matters here, because that is where the
// registry and the tunnel configs belong.
func New(settingsFile string) *Module {
	dataDir := filepath.Dir(strings.TrimSpace(settingsFile))
	if dataDir == "" || dataDir == "." {
		dataDir = "data"
	}
	return &Module{
		dataDir:     dataDir,
		tunnelDir:   filepath.Join(dataDir, "wireguard"),
		registry:    newRegistry(filepath.Join(dataDir, "nodes.json")),
		connections: map[string]*pooledConnection{},
		nodeMode:    nodeModeEnabled(),
		identity:    newIdentityStore(filepath.Join(dataDir, "node_identity.json")),
	}
}

// nodeModeEnabled reads the one switch that turns this backend into a node.
func nodeModeEnabled() bool {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("CULPEO_NODE_MODE"))) {
	case "1", "true", "yes", "on":
		return true
	default:
		return false
	}
}

func (m *Module) Name() string { return "node" }

// InNodeMode reports whether this backend is a node rather than a Studio.
func (m *Module) InNodeMode() bool { return m.nodeMode }

// SetAgentBridge wires what the agent reports. It is called before Initialize.
func (m *Module) SetAgentBridge(bridge AgentBridge) { m.agent = bridge }

// Initialize is idempotent. cmd/server has to run it before the engine module
// is built - node mode decides where the engine's gateway binds - and then
// again as part of the ordinary module loop.
func (m *Module) Initialize() error {
	if m.initialized {
		return nil
	}
	if err := os.MkdirAll(m.dataDir, 0o700); err != nil {
		return fmt.Errorf("Node-Datenordner anlegen: %w", err)
	}
	if err := m.registry.load(); err != nil {
		return err
	}
	if m.nodeMode {
		if err := m.initializeNodeMode(); err != nil {
			return err
		}
	}
	m.initialized = true
	return nil
}

// GatewayBind is where a node's OpenAI gateway should listen: its own address
// inside the tunnel. A manually managed tunnel supplies that address explicitly
// through CULPEO_NODE_TUNNEL_ADDRESS during Initialize; guessing one would
// otherwise open the gateway wider than intended.
func (m *Module) GatewayBind() string {
	if !m.nodeMode {
		return ""
	}
	current, ok := m.identity.get()
	if !ok || strings.TrimSpace(current.NodeAddress) == "" {
		return ""
	}
	return noderouting.JoinHostPort(current.NodeAddress, gatewayPortFromEnv())
}

// ControlPlaneHost is the address a node's gRPC server has to listen on.
//
// A node is only ever reached through the tunnel, so it listens there and
// nowhere else. Loopback would make it unreachable and every interface would
// expose the control plane to whatever network the machine is on.
func (m *Module) ControlPlaneHost() string {
	if !m.nodeMode {
		return ""
	}
	current, ok := m.identity.get()
	if !ok {
		return ""
	}
	return strings.TrimSpace(current.NodeAddress)
}

func (m *Module) Shutdown() error {
	m.connectionsMu.Lock()
	defer m.connectionsMu.Unlock()
	var failures []string
	for id, pooled := range m.connections {
		if err := pooled.connection.Close(); err != nil {
			failures = append(failures, fmt.Sprintf("%s: %v", id, err))
		}
	}
	m.connections = map[string]*pooledConnection{}
	if len(failures) > 0 {
		return fmt.Errorf("Node-Verbindungen schliessen: %s", strings.Join(failures, "; "))
	}
	return nil
}

// EnabledTargets lists the nodes a merged view should include.
func (m *Module) EnabledTargets() []Target {
	if m.nodeMode {
		// A node does not fan out to further nodes. Allowing it would make the
		// topology a graph, and every list a question about cycles.
		return nil
	}
	stored := m.registry.list()
	targets := make([]Target, 0, len(stored))
	for _, entry := range sortedByName(stored) {
		if !entry.Enabled {
			continue
		}
		targets = append(targets, targetFrom(entry))
	}
	return targets
}

// LookupTarget resolves one node whether or not it is enabled.
func (m *Module) LookupTarget(nodeID string) (Target, bool) {
	entry, ok := m.registry.get(nodeID)
	if !ok {
		return Target{}, false
	}
	return targetFrom(entry), true
}

func targetFrom(entry storedNode) Target {
	return Target{
		ID:             entry.ID,
		Name:           entry.Name,
		Address:        entry.Address,
		GRPCPort:       entry.GRPCPort,
		GatewayPort:    entry.GatewayPort,
		Token:          entry.Token,
		TLSFingerprint: entry.TLSFingerprint,
		GatewayKey:     entry.GatewayKey,
		GatewayBaseURL: entry.GatewayBaseURL,
	}
}

// touch records that a node answered, without disturbing the cached profile.
func (m *Module) touch(nodeID string) {
	_, _ = m.registry.update(nodeID, func(entry *storedNode) {
		entry.LastSeenAt = time.Now().UTC()
		entry.State = stateOnline
		entry.StatusMessage = ""
	})
}

// markUnreachable records why a node did not answer, so a list can say so
// without probing again.
func (m *Module) markUnreachable(nodeID, state, message string) {
	_, _ = m.registry.update(nodeID, func(entry *storedNode) {
		entry.State = state
		entry.StatusMessage = message
	})
}

const (
	stateOnline       = "online"
	stateOffline      = "offline"
	stateUnauthorized = "unauthorized"
)
