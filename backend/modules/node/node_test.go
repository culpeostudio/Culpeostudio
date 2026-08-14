package node

import (
	"path/filepath"
	"strings"
	"testing"
	"time"
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
	if got := module.reachableGatewayURL("", "10.77.0.1"); got != "" {
		t.Errorf("no gateway = %q, want empty", got)
	}
}
