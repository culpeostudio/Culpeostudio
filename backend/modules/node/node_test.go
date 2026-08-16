package node

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
	"github.com/culpeohq/backend/internal/wireguard"
)

func TestQualifyAndSplitRoundTrip(t *testing.T) {
	qualified := Qualify("abc123", "inst-42")
	if qualified == "inst-42" {
		t.Fatal("a node id should have changed the identifier")
	}
	nodeID, localID, ok := Split(qualified)
	if !ok {
		t.Fatalf("Split(%q) reported a local id", qualified)
	}
	if nodeID != "abc123" || localID != "inst-42" {
		t.Errorf("Split = (%q, %q), want (abc123, inst-42)", nodeID, localID)
	}
}

func TestQualifyLeavesLocalIdentifiersAlone(t *testing.T) {
	if got := Qualify("", "inst-42"); got != "inst-42" {
		t.Errorf("Qualify with no node = %q, want inst-42", got)
	}
	if got := Qualify("abc", ""); got != "" {
		t.Errorf("Qualify of an empty id = %q, want empty", got)
	}
	nodeID, localID, ok := Split("inst-42")
	if ok {
		t.Error("a plain identifier should not be read as a node's")
	}
	if nodeID != "" || localID != "inst-42" {
		t.Errorf("Split of a local id = (%q, %q), want (\"\", inst-42)", nodeID, localID)
	}
}

// A malformed qualified id must not fall back to being treated as local:
// that would send a call meant for a node to this machine's own store, where
// it might match something.
func TestSplitRejectsMalformedQualifiedIdentifiers(t *testing.T) {
	for _, id := range []string{"n:", "n:abc", "n::inst", "n:abc:"} {
		nodeID, localID, ok := Split(id)
		if ok {
			t.Errorf("Split(%q) = (%q, %q, true), want a refusal", id, nodeID, localID)
		}
		if localID != id {
			t.Errorf("Split(%q) rewrote the id to %q; it should be left alone", id, localID)
		}
	}
}

func TestTargetEndpointAndGatewayURL(t *testing.T) {
	target := Target{Address: "10.77.0.1", GRPCPort: 50051, GatewayPort: 8091}
	if got := target.Endpoint(); got != "10.77.0.1:50051" {
		t.Errorf("Endpoint = %q", got)
	}
	if got := target.GatewayURL(); got != "http://10.77.0.1:8091" {
		t.Errorf("GatewayURL = %q", got)
	}

	// What the node reported wins: it may serve its gateway somewhere other
	// than the port the join code guessed.
	reported := Target{Address: "10.77.0.1", GatewayPort: 8091, GatewayBaseURL: "http://10.77.0.1:9000/"}
	if got := reported.GatewayURL(); got != "http://10.77.0.1:9000" {
		t.Errorf("GatewayURL with a reported base = %q", got)
	}

	bare := Target{Address: "fd00::1"}
	if got := bare.Endpoint(); got != "[fd00::1]:50051" {
		t.Errorf("an IPv6 address needs brackets before a port, got %q", got)
	}
}

func TestCheckTunnelAddressRefusesPublicAddresses(t *testing.T) {
	for _, address := range []string{"10.77.0.1", "192.168.1.5", "127.0.0.1", "node.internal"} {
		if err := checkTunnelAddress(address); err != nil {
			t.Errorf("checkTunnelAddress(%q) = %v, want accepted", address, err)
		}
	}
	for _, address := range []string{"8.8.8.8", "203.0.113.7", ""} {
		if err := checkTunnelAddress(address); err == nil {
			t.Errorf("checkTunnelAddress(%q) accepted an address the token must not go to", address)
		}
	}
}

func TestRegistryPersistsAndReloads(t *testing.T) {
	path := filepath.Join(t.TempDir(), "nodes.json")
	first := newRegistry(path)
	if err := first.load(); err != nil {
		t.Fatalf("load on a missing file should be fine: %v", err)
	}
	added, err := first.add(storedNode{
		ID: "abc123", Name: "Werkstatt", Address: "10.77.0.1",
		GRPCPort: 50051, GatewayPort: 8091, Enabled: true,
		Token: "secret-token", AddedAt: time.Now().UTC(),
	})
	if err != nil {
		t.Fatalf("add: %v", err)
	}
	if added.Name != "Werkstatt" {
		t.Errorf("name = %q", added.Name)
	}

	second := newRegistry(path)
	if err := second.load(); err != nil {
		t.Fatalf("load: %v", err)
	}
	reloaded, ok := second.get("abc123")
	if !ok {
		t.Fatal("the node did not survive a reload")
	}
	if reloaded.Token != "secret-token" || reloaded.Address != "10.77.0.1" {
		t.Errorf("reloaded entry lost data: %+v", reloaded)
	}
	if info, err := os.Stat(path); err != nil || info.Mode().Perm() != 0o600 {
		t.Fatalf("registry permissions = info=%v err=%v, want 0600", info, err)
	}
}

func TestRegistryLoadTightensPermissionsAndRejectsSymlinks(t *testing.T) {
	directory := t.TempDir()
	path := filepath.Join(directory, "nodes.json")
	if err := os.WriteFile(path, []byte(`{"nodes":[]}`), 0o644); err != nil {
		t.Fatalf("write registry: %v", err)
	}
	if err := newRegistry(path).load(); err != nil {
		t.Fatalf("load permissive registry: %v", err)
	}
	if info, err := os.Stat(path); err != nil || info.Mode().Perm() != 0o600 {
		t.Fatalf("load did not tighten registry permissions: info=%v err=%v", info, err)
	}

	target := filepath.Join(directory, "target.json")
	if err := os.WriteFile(target, []byte(`{"nodes":[]}`), 0o600); err != nil {
		t.Fatalf("write target: %v", err)
	}
	symlink := filepath.Join(directory, "symlink.json")
	if err := os.Symlink(target, symlink); err != nil {
		t.Fatalf("create symlink: %v", err)
	}
	if err := newRegistry(symlink).load(); err == nil {
		t.Fatal("registry loader accepted a symlink")
	}
}

func TestRegistryRejectsDuplicatesAndKeepsNamesApart(t *testing.T) {
	registry := newRegistry(filepath.Join(t.TempDir(), "nodes.json"))
	if _, err := registry.add(storedNode{ID: "one", Name: "Werkstatt", Enabled: true}); err != nil {
		t.Fatalf("add: %v", err)
	}
	if _, err := registry.add(storedNode{ID: "one", Name: "Anders"}); err == nil {
		t.Error("adding the same node twice should be refused")
	}
	// The name is what a user picks a download target by, so two nodes must
	// not share one.
	second, err := registry.add(storedNode{ID: "two", Name: "Werkstatt", Enabled: true})
	if err != nil {
		t.Fatalf("add: %v", err)
	}
	if second.Name == "Werkstatt" {
		t.Error("the second node kept a name that was already taken")
	}
	if !strings.HasPrefix(second.Name, "Werkstatt") {
		t.Errorf("the suffixed name should still be recognisable, got %q", second.Name)
	}
}

func TestRegistryRejectsOverlappingManagedTunnelNetworks(t *testing.T) {
	registry := newRegistry(filepath.Join(t.TempDir(), "nodes.json"))
	if _, err := registry.add(storedNode{
		ID: "first", Name: "Erster Node", Enabled: true,
		Tunnel: storedTunnel{Managed: true, Network: "10.44.0.0/24"},
	}); err != nil {
		t.Fatalf("add first node: %v", err)
	}

	if _, err := registry.add(storedNode{
		ID: "overlap", Name: "Kollidierender Node", Enabled: true,
		Tunnel: storedTunnel{Managed: true, Network: "10.44.0.128/25"},
	}); !errors.Is(err, errTunnelNetworkConflict) {
		t.Fatalf("overlapping network error = %v, want errTunnelNetworkConflict", err)
	}

	if _, err := registry.add(storedNode{
		ID: "second", Name: "Zweiter Node", Enabled: true,
		Tunnel: storedTunnel{Managed: true, Network: "10.45.0.0/24"},
	}); err != nil {
		t.Fatalf("add non-overlapping node: %v", err)
	}
}

func TestRegistryChecksLegacyTunnelConfigForNetworkConflicts(t *testing.T) {
	directory := t.TempDir()
	configPath := filepath.Join(directory, "culpeo-legacy.conf")
	config := `[Interface]
Address = 10.52.0.2/32

[Peer]
AllowedIPs = 10.52.0.0/24
`
	if err := os.WriteFile(configPath, []byte(config), 0o600); err != nil {
		t.Fatalf("write legacy config: %v", err)
	}

	registry := newRegistry(filepath.Join(directory, "nodes.json"))
	if _, err := registry.add(storedNode{
		ID: "legacy", Name: "Alter Node", Address: "10.52.0.1", Enabled: true,
		Tunnel: storedTunnel{Managed: true, ConfigPath: configPath},
	}); err != nil {
		t.Fatalf("add legacy node: %v", err)
	}
	if _, err := registry.add(storedNode{
		ID: "new", Name: "Neuer Node", Address: "10.52.0.129", Enabled: true,
		Tunnel: storedTunnel{Managed: true, Network: "10.52.0.128/25"},
	}); !errors.Is(err, errTunnelNetworkConflict) {
		t.Fatalf("legacy overlap error = %v, want errTunnelNetworkConflict", err)
	}
}

func TestAddFromJoinCodeStopsTunnelNetworkConflicts(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}

	first, err := wireguard.Pair(wireguard.PairingRequest{
		NodeID: "first-node", Token: "first-token", Network: "10.61.0.0/24", Endpoint: "first.example.org",
	})
	if err != nil {
		t.Fatalf("pair first node: %v", err)
	}
	firstCode, err := wireguard.DecodeJoinCode(first.JoinCode)
	if err != nil {
		t.Fatalf("decode first node code: %v", err)
	}
	if _, err := module.registry.add(storedNode{
		ID: firstCode.NodeID, Name: "Erster Node", Address: firstCode.NodeAddress, Enabled: true,
		Tunnel: storedTunnel{Managed: true, Network: firstCode.Network},
	}); err != nil {
		t.Fatalf("add first node: %v", err)
	}

	second, err := wireguard.Pair(wireguard.PairingRequest{
		NodeID: "second-node", Token: "second-token", Network: "10.61.0.128/25", Endpoint: "second.example.org",
	})
	if err != nil {
		t.Fatalf("pair second node: %v", err)
	}
	_, err = (&grpcService{module: module}).addFromJoinCode(context.Background(), second.JoinCode, "")
	if status.Code(err) != codes.FailedPrecondition {
		t.Fatalf("add conflicting join code status = %s, want %s (error: %v)", status.Code(err), codes.FailedPrecondition, err)
	}
	if _, exists := module.registry.get("second-node"); exists {
		t.Error("conflicting node was added to the registry")
	}
}

func TestRegistryUpdateAndRemove(t *testing.T) {
	registry := newRegistry(filepath.Join(t.TempDir(), "nodes.json"))
	if _, err := registry.add(storedNode{ID: "one", Name: "Werkstatt", Enabled: true}); err != nil {
		t.Fatalf("add: %v", err)
	}
	updated, err := registry.update("one", func(entry *storedNode) { entry.Enabled = false })
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	if updated.Enabled {
		t.Error("the node was not switched off")
	}
	if _, err := registry.update("missing", func(*storedNode) {}); err == nil {
		t.Error("updating an unknown node should fail")
	}
	if _, err := registry.remove("one"); err != nil {
		t.Fatalf("remove: %v", err)
	}
	if _, ok := registry.get("one"); ok {
		t.Error("the node survived its removal")
	}
}

func TestEnabledTargetsSkipsDisabledNodes(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if _, err := module.registry.add(storedNode{ID: "one", Name: "An", Address: "10.77.0.1", Enabled: true}); err != nil {
		t.Fatalf("add: %v", err)
	}
	if _, err := module.registry.add(storedNode{ID: "two", Name: "Aus", Address: "10.77.0.3", Enabled: false}); err != nil {
		t.Fatalf("add: %v", err)
	}
	targets := module.EnabledTargets()
	if len(targets) != 1 || targets[0].ID != "one" {
		t.Errorf("EnabledTargets = %+v, want only the enabled node", targets)
	}
	if _, ok := module.LookupTarget("two"); !ok {
		t.Error("a disabled node should still be resolvable by id")
	}
	if _, err := module.Dial("two"); err == nil {
		t.Error("dialling a disabled node should fail rather than connect")
	}
}

// A Studio has no pairing token of its own, so it must not start honouring
// one: the token is a node's credential, and only a node knows what it means.
func TestAuthenticateGRPCTokenIsInertOnAStudio(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if _, ok := module.AuthenticateGRPCToken(t.Context(), nodeAgentPrefix+"GetNodeStatus", "whatever"); ok {
		t.Error("a Studio accepted a pairing token")
	}
}

func TestPairedMethodsAreLimitedToRunningModels(t *testing.T) {
	allowed := []string{
		nodeAgentPrefix + "GetNodeStatus",
		"/culpeostudio.engine.v1.EngineService/ListInstances",
		"/culpeostudio.engine.v1.EngineService/CreateInstance",
		"/culpeostudio.marketplace.v1.MarketplaceService/StartDownload",
	}
	for _, method := range allowed {
		if !pairedMethodAllowed(method) {
			t.Errorf("%s should be reachable with a pairing token", method)
		}
	}
	// A pairing token is not a login. Nothing about the machine's own data,
	// and none of its keys, may be reached with it.
	refused := []string{
		"/culpeostudio.memory.v1.MemoryService/Search",
		"/culpeostudio.scout.v1.ScoutService/ListSessions",
		"/culpeostudio.login.v1.LoginService/Login",
		"/culpeostudio.node.v1.NodeService/ListNodes",
		"/culpeostudio.engine.v1.EngineService/CreateKey",
		"/culpeostudio.engine.v1.EngineService/ListKeys",
	}
	for _, method := range refused {
		if pairedMethodAllowed(method) {
			t.Errorf("%s must not be reachable with a pairing token", method)
		}
	}
}

func TestIdentityStoreRoundTrip(t *testing.T) {
	path := filepath.Join(t.TempDir(), "node_identity.json")
	store := newIdentityStore(path)
	if err := store.load(); err != nil {
		t.Fatalf("load on a missing file should be fine: %v", err)
	}
	if _, ok := store.get(); ok {
		t.Fatal("an unwritten identity should not report as loaded")
	}
	if err := store.save(identity{NodeID: "abc", Name: "Node", Token: "token", CreatedAt: time.Now().UTC()}); err != nil {
		t.Fatalf("save: %v", err)
	}
	if !store.matches("token") {
		t.Error("the stored token was not recognised")
	}
	if store.matches("other") || store.matches("") {
		t.Error("a wrong token was accepted")
	}

	reloaded := newIdentityStore(path)
	if err := reloaded.load(); err != nil {
		t.Fatalf("load: %v", err)
	}
	current, ok := reloaded.get()
	if !ok || current.NodeID != "abc" {
		t.Errorf("identity did not survive a reload: %+v", current)
	}
}

func TestReachableGatewayURLRewritesUnusableHosts(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	// A gateway still on loopback cannot be reached from the Studio, and
	// reporting it would send the Studio to its own machine.
	if got := module.reachableGatewayURL("http://127.0.0.1:8091", "10.77.0.1"); got != "" {
		t.Errorf("a loopback gateway = %q, want empty", got)
	}
	if got := module.reachableGatewayURL("http://0.0.0.0:8091", "10.77.0.1"); got != "http://10.77.0.1:8091" {
		t.Errorf("a wildcard gateway = %q, want the tunnel address", got)
	}
	if got := module.reachableGatewayURL("http://10.77.0.1:8091", "10.77.0.1"); got != "http://10.77.0.1:8091" {
		t.Errorf("a tunnel gateway = %q, want it unchanged", got)
	}
	if got := module.reachableGatewayURL("http://[fd12:3456::8]:8091", "fd12:3456::8"); got != "http://[fd12:3456::8]:8091" {
		t.Errorf("an IPv6 tunnel gateway = %q, want a valid bracketed URL", got)
	}
	if got := module.reachableGatewayURL("http://[::]:8091", "fd12:3456::8"); got != "http://[fd12:3456::8]:8091" {
		t.Errorf("an IPv6 wildcard gateway = %q, want the IPv6 tunnel address", got)
	}
	if got := module.reachableGatewayURL("", "10.77.0.1"); got != "" {
		t.Errorf("no gateway = %q, want empty", got)
	}
}

func TestManualTunnelAddressOnlyAcceptsPrivateIPAddresses(t *testing.T) {
	for name, test := range map[string]struct {
		raw     string
		want    string
		wantErr bool
	}{
		"RFC1918 IPv4": {raw: "10.77.0.1", want: "10.77.0.1"},
		"IPv6 ULA":     {raw: "fd12:3456::8", want: "fd12:3456::8"},
		"missing":      {wantErr: true},
		"hostname":     {raw: "node.internal", wantErr: true},
		"with port":    {raw: "10.77.0.1:50051", wantErr: true},
		"CIDR":         {raw: "10.77.0.1/24", wantErr: true},
		"loopback":     {raw: "127.0.0.1", wantErr: true},
		"wildcard":     {raw: "0.0.0.0", wantErr: true},
		"link local":   {raw: "169.254.10.3", wantErr: true},
		"public":       {raw: "203.0.113.8", wantErr: true},
	} {
		t.Run(name, func(t *testing.T) {
			t.Setenv(manualTunnelAddressEnv, test.raw)
			got, err := manualTunnelAddress()
			if test.wantErr {
				if err == nil {
					t.Fatalf("manualTunnelAddress(%q) = %q, nil error", test.raw, got)
				}
				return
			}
			if err != nil {
				t.Fatalf("manualTunnelAddress(%q): %v", test.raw, err)
			}
			if got != test.want {
				t.Errorf("manualTunnelAddress(%q) = %q, want %q", test.raw, got, test.want)
			}
		})
	}
}

func TestManualNodeBindsOnlyToConfiguredTunnelAddress(t *testing.T) {
	module := newManualNodeModule(t, "10.88.0.9")
	if got := module.ControlPlaneHost(); got != "10.88.0.9" {
		t.Errorf("ControlPlaneHost = %q, want configured tunnel address", got)
	}
	if got := module.GatewayBind(); got != "10.88.0.9:9123" {
		t.Errorf("GatewayBind = %q, want configured tunnel address and gateway port", got)
	}

	current, ok := module.identity.get()
	if !ok {
		t.Fatal("manual node did not persist an identity")
	}
	if current.NodeAddress != "10.88.0.9" || current.Endpoint != "" || current.JoinCode != "" {
		t.Errorf("manual identity = %+v, want an endpointless identity with the private address", current)
	}
}

func TestManualNodeBindsIPv6ULATunnelAddress(t *testing.T) {
	module := newManualNodeModule(t, "fd12:3456::8")
	if got := module.ControlPlaneHost(); got != "fd12:3456::8" {
		t.Errorf("ControlPlaneHost = %q, want configured IPv6 tunnel address", got)
	}
	if got := module.GatewayBind(); got != "[fd12:3456::8]:9123" {
		t.Errorf("GatewayBind = %q, want bracketed IPv6 tunnel address and gateway port", got)
	}
}

func TestManualNodeRequiresTunnelAddressBeforeCreatingIdentity(t *testing.T) {
	t.Setenv("CULPEO_NODE_MODE", "1")
	t.Setenv("CULPEO_NODE_WG_ENDPOINT", "")
	t.Setenv(manualTunnelAddressEnv, "")

	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	module := New(settingsPath)
	err := module.Initialize()
	if err == nil {
		t.Fatal("manual node initialized without a private tunnel address")
	}
	if !strings.Contains(err.Error(), manualTunnelAddressEnv) {
		t.Errorf("Initialize error = %q, want the required setting", err)
	}
	if _, ok := module.identity.get(); ok {
		t.Error("manual node persisted an identity despite an unsafe configuration")
	}
	if _, statErr := os.Stat(filepath.Join(filepath.Dir(settingsPath), "node_identity.json")); !os.IsNotExist(statErr) {
		t.Errorf("identity file exists after rejected setup: %v", statErr)
	}
}

func TestManualNodeMigratesEndpointlessIdentityAndKeepsPairingAuthAndGatewayKey(t *testing.T) {
	t.Setenv("CULPEO_NODE_MODE", "1")
	t.Setenv("CULPEO_NODE_WG_ENDPOINT", "")
	t.Setenv(manualTunnelAddressEnv, "10.89.0.7")
	t.Setenv("ENGINE_GATEWAY_ADDR", ":9123")

	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	store := newIdentityStore(filepath.Join(filepath.Dir(settingsPath), "node_identity.json"))
	if err := store.save(identity{
		NodeID: "old-manual-node", Name: "Alt", Token: "pairing-token", CreatedAt: time.Now().UTC(),
	}); err != nil {
		t.Fatalf("save legacy identity: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize migrates a legacy manual node: %v", err)
	}
	if got := module.ControlPlaneHost(); got != "10.89.0.7" {
		t.Errorf("ControlPlaneHost = %q, want migrated address", got)
	}
	if got := module.GatewayBind(); got != "10.89.0.7:9123" {
		t.Errorf("GatewayBind = %q, want migrated address", got)
	}

	reloaded := newIdentityStore(filepath.Join(filepath.Dir(settingsPath), "node_identity.json"))
	if err := reloaded.load(); err != nil {
		t.Fatalf("reload migrated identity: %v", err)
	}
	current, ok := reloaded.get()
	if !ok || current.NodeAddress != "10.89.0.7" {
		t.Errorf("migrated identity = %+v, want private tunnel address", current)
	}

	userID, authenticated := module.AuthenticateGRPCToken(context.Background(), nodeAgentPrefix+"GetNodeStatus", "pairing-token")
	if !authenticated || userID != "node:old-manual-node" {
		t.Errorf("manual node pairing auth = (%q, %t), want its node identity", userID, authenticated)
	}
	if _, authenticated := module.AuthenticateGRPCToken(context.Background(), "/culpeostudio.node.v1.NodeService/ListNodes", "pairing-token"); authenticated {
		t.Error("manual node pairing token gained access outside the node allowlist")
	}

	module.SetAgentBridge(AgentBridge{
		GatewayBaseURL: func() string { return "http://10.89.0.7:9123" },
		IssueGatewayKey: func(label string) (string, string, error) {
			if label != "Culpeo Studio" {
				t.Errorf("gateway key label = %q", label)
			}
			return "gateway-key-id", "gateway-secret", nil
		},
	})
	response, err := (&agentService{module: module}).IssueGatewayKey(context.Background(), &nodev1.IssueGatewayKeyRequest{})
	if err != nil {
		t.Fatalf("IssueGatewayKey: %v", err)
	}
	if response.GetGatewayBaseUrl() != "http://10.89.0.7:9123" || response.GetSecret() != "gateway-secret" {
		t.Errorf("gateway response = %+v, want private URL and issued secret", response)
	}
}

func newManualNodeModule(t *testing.T, address string) *Module {
	t.Helper()
	t.Setenv("CULPEO_NODE_MODE", "1")
	t.Setenv("CULPEO_NODE_WG_ENDPOINT", "")
	t.Setenv(manualTunnelAddressEnv, address)
	t.Setenv("ENGINE_GATEWAY_ADDR", ":9123")

	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize manual node: %v", err)
	}
	return module
}
