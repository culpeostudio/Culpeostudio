package nodeagent

import (
	"context"
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"

	hardwarev1 "github.com/culpeohq/backend/gen/go/culpeostudio/hardware/v1"
	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
)

const testToken = "pairing-token-1234567890"

func newTestService(t *testing.T, bridge AgentBridge) *Service {
	t.Helper()
	service, err := New(Config{
		IdentityPath: filepath.Join(t.TempDir(), "node-identity.json"),
		NodeID:       "node-test-01",
		Name:         "Werkstatt Node",
		Token:        testToken,
		Version:      "test-version",
	}, bridge)
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	return service
}

func TestNewPersistsStableIdentityAndName(t *testing.T) {
	path := filepath.Join(t.TempDir(), "state", "node-identity.json")
	first, err := New(Config{
		IdentityPath: path,
		NodeID:       "node-alpha-01",
		Name:         "Werkstatt",
		Token:        testToken,
		Version:      "1.2.3",
	}, AgentBridge{})
	if err != nil {
		t.Fatalf("first New: %v", err)
	}
	identity := first.Identity()
	if identity.NodeID != "node-alpha-01" || identity.Name != "Werkstatt" || identity.CreatedAt.IsZero() {
		t.Fatalf("first identity = %+v", identity)
	}
	if first.PairingToken() != testToken {
		t.Fatal("configured pairing token was not retained")
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("stat identity: %v", err)
	}
	if got, want := info.Mode().Perm(), os.FileMode(0o600); got != want {
		t.Errorf("identity permissions = %o, want %o", got, want)
	}

	second, err := New(Config{IdentityPath: path, Name: "GPU Rack"}, AgentBridge{})
	if err != nil {
		t.Fatalf("reopen identity: %v", err)
	}
	if got := second.Identity(); got.NodeID != identity.NodeID || got.Name != "GPU Rack" || !got.CreatedAt.Equal(identity.CreatedAt) {
		t.Errorf("reopened identity = %+v, want stable id/date and updated name", got)
	}
	if second.PairingToken() != testToken {
		t.Fatal("reopened identity changed the pairing token")
	}

	if _, err := New(Config{IdentityPath: path, NodeID: "other-node-01"}, AgentBridge{}); err == nil {
		t.Fatal("a different configured node id should be rejected")
	}
	if _, err := New(Config{IdentityPath: path, Token: "different-pairing-token-987654"}, AgentBridge{}); err == nil {
		t.Fatal("a different configured pairing token should be rejected")
	}
}

func TestNewGeneratesAndRetainsIdentityWhenNotConfigured(t *testing.T) {
	path := filepath.Join(t.TempDir(), "node-identity.json")
	first, err := New(Config{IdentityPath: path, Name: "Automatisch"}, AgentBridge{})
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	identity := first.Identity()
	if _, err := normalizeNodeID(identity.NodeID); err != nil {
		t.Fatalf("generated node id %q is invalid: %v", identity.NodeID, err)
	}
	if _, err := normalizeToken(first.PairingToken()); err != nil {
		t.Fatalf("generated token is invalid: %v", err)
	}

	second, err := New(Config{IdentityPath: path}, AgentBridge{})
	if err != nil {
		t.Fatalf("reopen generated identity: %v", err)
	}
	if got := second.Identity(); got != identity {
		t.Errorf("reopened identity = %+v, want %+v", got, identity)
	}
	if second.PairingToken() != first.PairingToken() {
		t.Fatal("generated pairing token changed after restart")
	}
}

func TestNewRejectsInvalidIdentityConfiguration(t *testing.T) {
	tests := []struct {
		name     string
		cfg      Config
		withPath bool
	}{
		{name: "missing path", cfg: Config{NodeID: "node-01", Name: "Node", Token: testToken}},
		{name: "node id with space", cfg: Config{NodeID: "node id", Name: "Node", Token: testToken}, withPath: true},
		{name: "short token", cfg: Config{Name: "Node", Token: "short"}, withPath: true},
		{name: "whitespace token", cfg: Config{Name: "Node", Token: " " + testToken}, withPath: true},
		{name: "control in name", cfg: Config{Name: "bad\nname", Token: testToken}, withPath: true},
		{name: "whitespace version", cfg: Config{Name: "Node", Token: testToken, Version: " 1.0"}, withPath: true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if test.withPath {
				test.cfg.IdentityPath = filepath.Join(t.TempDir(), "node-identity.json")
			}
			if _, err := New(test.cfg, AgentBridge{}); err == nil {
				t.Fatal("New accepted invalid configuration")
			}
		})
	}
}

func TestNewValidatesConfigurationBeforeWritingIdentity(t *testing.T) {
	path := filepath.Join(t.TempDir(), "node-identity.json")
	_, err := New(Config{
		IdentityPath: path,
		Name:         "Node",
		Version:      "bad\nversion",
	}, AgentBridge{})
	if err == nil {
		t.Fatal("New accepted an invalid version")
	}
	if _, statErr := os.Stat(path); !os.IsNotExist(statErr) {
		t.Fatalf("invalid configuration wrote an identity file: %v", statErr)
	}
}

func TestNewRejectsSymlinkedIdentityFile(t *testing.T) {
	directory := t.TempDir()
	target := filepath.Join(directory, "target.json")
	if err := os.WriteFile(target, []byte(`{}`), 0o600); err != nil {
		t.Fatalf("write target: %v", err)
	}
	path := filepath.Join(directory, "node-identity.json")
	if err := os.Symlink(target, path); err != nil {
		t.Fatalf("create symlink: %v", err)
	}
	if _, err := New(Config{IdentityPath: path, Name: "Node", Token: testToken}, AgentBridge{}); err == nil {
		t.Fatal("New accepted a symlinked identity file")
	}
}

func TestAlternateAuthOnlyAllowsNodeOperations(t *testing.T) {
	service := newTestService(t, AgentBridge{})
	for _, method := range []string{
		nodev1.NodeAgentService_GetNodeStatus_FullMethodName,
		"/culpeostudio.engine.v1.EngineService/ListModels",
		"/culpeostudio.engine.v1.EngineService/RevokeKey",
		"/culpeostudio.marketplace.v1.MarketplaceService/StartDownload",
	} {
		userID, ok := service.AlternateAuth(context.Background(), method, testToken)
		if !ok || userID != "node:node-test-01" {
			t.Errorf("AlternateAuth(%q) = (%q, %t), want node identity", method, userID, ok)
		}
	}
	for _, method := range []string{
		"/culpeostudio.node.v1.NodeService/ListNodes",
		"/culpeostudio.login.v1.LoginService/Login",
		"/culpeostudio.engine.v1.EngineService/ListKeys",
		"/culpeostudio.engine.v1.EngineService",
	} {
		if userID, ok := service.AlternateAuth(context.Background(), method, testToken); ok || userID != "" {
			t.Errorf("AlternateAuth unexpectedly accepted %q as %q", method, userID)
		}
	}
	if _, ok := service.AuthenticateGRPCToken(context.Background(), nodev1.NodeAgentService_GetNodeStatus_FullMethodName, "wrong-pairing-token-123"); ok {
		t.Fatal("wrong pairing token was accepted")
	}
}

func TestGetNodeStatusReportsBridgeValues(t *testing.T) {
	service := newTestService(t, AgentBridge{
		Hardware: func() *hardwarev1.HardwareProfile {
			return &hardwarev1.HardwareProfile{Os: "linux", DiskFreeBytes: 42}
		},
		ModelDir:       func() string { return " /srv/culpeo/models " },
		ModelCount:     func() int { return 4 },
		InstanceCount:  func() int { return 2 },
		GatewayBaseURL: func() string { return "http://node.internal:8091/" },
	})
	response, err := service.GetNodeStatus(context.Background(), &nodev1.GetNodeStatusRequest{})
	if err != nil {
		t.Fatalf("GetNodeStatus: %v", err)
	}
	if response.GetNodeId() != "node-test-01" || response.GetName() != "Werkstatt Node" || response.GetVersion() != "test-version" {
		t.Errorf("identity response = %+v", response)
	}
	if response.GetHardware().GetOs() != "linux" || response.GetDiskFreeBytes() != 42 {
		t.Errorf("hardware response = %+v", response.GetHardware())
	}
	if response.GetModelDir() != "/srv/culpeo/models" || response.GetModelCount() != 4 || response.GetInstanceCount() != 2 {
		t.Errorf("model status = dir %q, models %d, instances %d", response.GetModelDir(), response.GetModelCount(), response.GetInstanceCount())
	}
	if response.GetGatewayBaseUrl() != "http://node.internal:8091" {
		t.Errorf("gateway url = %q", response.GetGatewayBaseUrl())
	}
}

func TestGetNodeStatusRejectsInvalidBridgeValues(t *testing.T) {
	tests := []struct {
		name   string
		bridge AgentBridge
	}{
		{name: "negative model count", bridge: AgentBridge{ModelCount: func() int { return -1 }}},
		{name: "negative disk", bridge: AgentBridge{Hardware: func() *hardwarev1.HardwareProfile { return &hardwarev1.HardwareProfile{DiskFreeBytes: -1} }}},
		{name: "invalid gateway url", bridge: AgentBridge{GatewayBaseURL: func() string { return "file:///tmp/gateway" }}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			service := newTestService(t, test.bridge)
			_, err := service.GetNodeStatus(context.Background(), &nodev1.GetNodeStatusRequest{})
			if status.Code(err) != codes.Internal {
				t.Fatalf("GetNodeStatus error code = %s, want %s (error: %v)", status.Code(err), codes.Internal, err)
			}
		})
	}
}

func TestIssueGatewayKeyPersistsOnlyKeyID(t *testing.T) {
	path := filepath.Join(t.TempDir(), "node-identity.json")
	var receivedLabel string
	service, err := New(Config{
		IdentityPath: path,
		NodeID:       "node-key-01",
		Name:         "Key Node",
		Token:        testToken,
	}, AgentBridge{
		GatewayBaseURL: func() string { return "https://node.internal:8091/" },
		IssueGatewayKey: func(label string) (string, string, error) {
			receivedLabel = label
			return "gateway-key-01", "gateway-secret-1234567890", nil
		},
	})
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	response, err := service.IssueGatewayKey(context.Background(), &nodev1.IssueGatewayKeyRequest{})
	if err != nil {
		t.Fatalf("IssueGatewayKey: %v", err)
	}
	if receivedLabel != defaultGatewayKeyLabel {
		t.Errorf("default label = %q, want %q", receivedLabel, defaultGatewayKeyLabel)
	}
	if response.GetKeyId() != "gateway-key-01" || response.GetSecret() != "gateway-secret-1234567890" || response.GetGatewayBaseUrl() != "https://node.internal:8091" {
		t.Errorf("gateway key response = %+v", response)
	}
	statusResponse, err := service.GetNodeStatus(context.Background(), &nodev1.GetNodeStatusRequest{})
	if err != nil {
		t.Fatalf("GetNodeStatus after key: %v", err)
	}
	if !statusResponse.GetGatewayKeyIssued() {
		t.Fatal("key issuance was not reflected in node status")
	}

	reopened, err := New(Config{IdentityPath: path}, AgentBridge{})
	if err != nil {
		t.Fatalf("reopen identity: %v", err)
	}
	reopenedStatus, err := reopened.GetNodeStatus(context.Background(), &nodev1.GetNodeStatusRequest{})
	if err != nil {
		t.Fatalf("GetNodeStatus on reopened service: %v", err)
	}
	if !reopenedStatus.GetGatewayKeyIssued() {
		t.Fatal("persisted key id was not reflected in reopened status")
	}
	identityFile, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read identity: %v", err)
	}
	if string(identityFile) == "" || strings.Contains(string(identityFile), response.GetSecret()) {
		t.Fatal("identity file should not store the issued gateway secret")
	}
}

func TestIssueGatewayKeyValidationAndAvailability(t *testing.T) {
	withoutIssuer := newTestService(t, AgentBridge{})
	if _, err := withoutIssuer.IssueGatewayKey(context.Background(), &nodev1.IssueGatewayKeyRequest{}); status.Code(err) != codes.Unavailable {
		t.Fatalf("missing issuer code = %s, want %s (error: %v)", status.Code(err), codes.Unavailable, err)
	}

	service := newTestService(t, AgentBridge{
		IssueGatewayKey: func(string) (string, string, error) {
			return "key-01", testToken, nil
		},
	})
	if _, err := service.IssueGatewayKey(context.Background(), &nodev1.IssueGatewayKeyRequest{Label: "bad\nlabel"}); status.Code(err) != codes.InvalidArgument {
		t.Fatalf("invalid label code = %s, want %s (error: %v)", status.Code(err), codes.InvalidArgument, err)
	}

	issuerCalled := false
	invalidGateway := newTestService(t, AgentBridge{
		GatewayBaseURL: func() string { return "not a URL" },
		IssueGatewayKey: func(string) (string, string, error) {
			issuerCalled = true
			return "key-01", testToken, nil
		},
	})
	if _, err := invalidGateway.IssueGatewayKey(context.Background(), &nodev1.IssueGatewayKeyRequest{}); status.Code(err) != codes.Internal {
		t.Fatalf("invalid gateway code = %s, want %s (error: %v)", status.Code(err), codes.Internal, err)
	}
	if issuerCalled {
		t.Fatal("invalid gateway URL should be rejected before rotating a key")
	}
}

func TestRegisterGRPCExposesNodeAgentService(t *testing.T) {
	service := newTestService(t, AgentBridge{})
	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	service.RegisterGRPC(server)
	go func() { _ = server.Serve(listener) }()
	t.Cleanup(server.Stop)
	t.Cleanup(func() { _ = listener.Close() })

	connection, err := grpc.DialContext(
		t.Context(),
		"bufnet",
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) { return listener.Dial() }),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("dial bufconn: %v", err)
	}
	t.Cleanup(func() { _ = connection.Close() })
	response, err := nodev1.NewNodeAgentServiceClient(connection).GetNodeStatus(t.Context(), &nodev1.GetNodeStatusRequest{})
	if err != nil {
		t.Fatalf("NodeAgentService.GetNodeStatus: %v", err)
	}
	if response.GetNodeId() != "node-test-01" {
		t.Errorf("NodeAgentService returned node %q", response.GetNodeId())
	}
}
