package node

import (
	"context"
	"crypto/tls"
	"net"
	"net/http"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
	"github.com/culpeohq/backend/internal/nodecert"
	"github.com/culpeohq/backend/internal/nodeconnection"
)

const (
	directPairingTestToken      = "direct-pairing-token-1234567890"
	directPairingTestGatewayKey = "direct-gateway-key-1234567890"
)

type directPairingTestAgent struct {
	nodev1.UnimplementedNodeAgentServiceServer
	gatewayURL string
}

func (agent directPairingTestAgent) GetNodeStatus(
	context.Context,
	*nodev1.GetNodeStatusRequest,
) (*nodev1.GetNodeStatusResponse, error) {
	return &nodev1.GetNodeStatusResponse{
		NodeId:         "direct-node-test",
		Name:           "Werkstatt-Node",
		Version:        "test-version",
		ModelDir:       "/srv/culpeo/models",
		ModelCount:     3,
		InstanceCount:  1,
		DiskFreeBytes:  42,
		GatewayBaseUrl: agent.gatewayURL,
	}, nil
}

func (agent directPairingTestAgent) IssueGatewayKey(
	context.Context,
	*nodev1.IssueGatewayKeyRequest,
) (*nodev1.IssueGatewayKeyResponse, error) {
	return &nodev1.IssueGatewayKeyResponse{
		KeyId:          "direct-gateway-key-id",
		Secret:         directPairingTestGatewayKey,
		GatewayBaseUrl: agent.gatewayURL,
	}, nil
}

// startDirectPairingTestNode exposes the same essential first-contact shape
// as the standalone Node: TLS with a self-signed certificate plus a pairing
// token accepted only by the NodeAgent status call.
func startDirectPairingTestNode(t *testing.T, expectedToken, reportedGatewayURL string) (endpoint, fingerprint string) {
	t.Helper()
	certificate, err := nodecert.Ensure(t.TempDir())
	if err != nil {
		t.Fatalf("Node-Zertifikat: %v", err)
	}
	return startDirectPairingTestNodeWithCertificate(t, expectedToken, reportedGatewayURL, certificate)
}

func startDirectPairingTestNodeWithCertificate(t *testing.T, expectedToken, reportedGatewayURL string, certificate nodecert.Certificate) (endpoint, fingerprint string) {
	t.Helper()
	keyPair, err := tls.LoadX509KeyPair(certificate.CertificatePath, certificate.PrivateKeyPath)
	if err != nil {
		t.Fatalf("TLS-Keypair: %v", err)
	}
	gatewayListener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Gateway listen: %v", err)
	}
	gatewayURL := "https://" + gatewayListener.Addr().String()
	if reportedGatewayURL != "" {
		gatewayURL = reportedGatewayURL
	}
	gatewayServer := &http.Server{Handler: http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/v1/models" {
			http.NotFound(writer, request)
			return
		}
		if request.Header.Get("Authorization") != "Bearer "+directPairingTestGatewayKey {
			http.Error(writer, "gateway key rejected", http.StatusUnauthorized)
			return
		}
		writer.WriteHeader(http.StatusOK)
	})}
	go func() {
		_ = gatewayServer.Serve(tls.NewListener(gatewayListener, &tls.Config{
			Certificates: []tls.Certificate{keyPair},
			MinVersion:   tls.VersionTLS12,
		}))
	}()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	server := grpc.NewServer(
		grpc.Creds(credentials.NewTLS(&tls.Config{
			Certificates: []tls.Certificate{keyPair},
			MinVersion:   tls.VersionTLS12,
		})),
		grpc.UnaryInterceptor(func(
			ctx context.Context,
			req any,
			info *grpc.UnaryServerInfo,
			handler grpc.UnaryHandler,
		) (any, error) {
			values := metadata.ValueFromIncomingContext(ctx, "authorization")
			if len(values) != 1 || values[0] != "Bearer "+expectedToken {
				return nil, status.Error(codes.Unauthenticated, "Pairing-Token abgelehnt")
			}
			return handler(ctx, req)
		}),
	)
	nodev1.RegisterNodeAgentServiceServer(server, directPairingTestAgent{gatewayURL: gatewayURL})
	go func() {
		_ = server.Serve(listener)
	}()
	t.Cleanup(func() {
		server.Stop()
		_ = listener.Close()
		_ = gatewayServer.Close()
		_ = gatewayListener.Close()
	})
	return listener.Addr().String(), certificate.Fingerprint
}

func directPairingLink(t *testing.T, endpoint, fingerprint, token string) string {
	t.Helper()
	link, err := nodeconnection.Encode(nodeconnection.Connection{
		NodeID:      "direct-node-test",
		Endpoint:    endpoint,
		Fingerprint: fingerprint,
		Token:       token,
		Name:        "Direkter Test-Node",
	})
	if err != nil {
		t.Fatalf("Verbindungslink: %v", err)
	}
	return link
}

func newDirectPairingStudio(t *testing.T) *Module {
	t.Helper()
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Studio-Node-Modul initialisieren: %v", err)
	}
	t.Cleanup(func() { _ = module.Shutdown() })
	return module
}

func TestAddNodeAcceptsDirectTLSConnectionAndCachesStatus(t *testing.T) {
	endpoint, fingerprint := startDirectPairingTestNode(t, directPairingTestToken, "")
	module := newDirectPairingStudio(t)

	response, err := (&grpcService{module: module}).AddNode(context.Background(), &nodev1.AddNodeRequest{
		Source: &nodev1.AddNodeRequest_JoinCode{
			JoinCode: directPairingLink(t, endpoint, fingerprint, directPairingTestToken),
		},
	})
	if err != nil {
		t.Fatalf("AddNode mit direktem Link: %v", err)
	}
	if response.GetNode().GetState() != nodev1.NodeState_NODE_STATE_ONLINE {
		t.Fatalf("Node-Zustand = %s, want online", response.GetNode().GetState())
	}
	if len(response.GetNextSteps()) != 0 {
		t.Errorf("direkter Node hat unerwartete Restschritte: %v", response.GetNextSteps())
	}
	if response.GetNode().GetModelDir() != "/srv/culpeo/models" || response.GetNode().GetModelCount() != 3 || response.GetNode().GetInstanceCount() != 1 {
		t.Errorf("gecachter Status = %+v", response.GetNode())
	}
	if response.GetNode().GetGatewayPort() <= 0 {
		t.Errorf("Gateway-Port = %d, want reachable HTTPS port", response.GetNode().GetGatewayPort())
	}
	if got := response.GetNode().GetTunnel().GetStatusMessage(); got != "Direkte TLS-Verbindung; kein Tunnel erforderlich." {
		t.Errorf("Tunnel-Hinweis = %q", got)
	}

	stored, ok := module.registry.get(response.GetNode().GetId())
	if !ok {
		t.Fatal("erfolgreich gepaarter Node fehlt aus der Registry")
	}
	if stored.TLSFingerprint != fingerprint {
		t.Errorf("gespeicherter TLS-Fingerprint = %q", stored.TLSFingerprint)
	}
	if stored.GatewayKeyLabel == "" {
		t.Error("direkter Node hat keine Studio-spezifische Gateway-Schluesselbezeichnung")
	}
	if stored.Tunnel.Managed {
		t.Error("direkter Node wurde faelschlich als WireGuard-Tunnel gespeichert")
	}
	if stored.State != stateOnline || stored.Version != "test-version" || stored.ModelCount != 3 {
		t.Errorf("gecachter Registry-Status = %+v", stored)
	}
	reloaded := newRegistry(module.registry.path)
	if err := reloaded.load(); err != nil {
		t.Fatalf("direkte Registry erneut laden: %v", err)
	}
	persisted, ok := reloaded.get(response.GetNode().GetId())
	if !ok || persisted.TLSFingerprint != fingerprint || persisted.Token != directPairingTestToken {
		t.Errorf("direkter Node wurde nicht vollstaendig persistiert: %+v", persisted)
	}
}

func TestAddNodeUpdatesStableDirectNodeAfterEndpointChange(t *testing.T) {
	certificate, err := nodecert.Ensure(t.TempDir())
	if err != nil {
		t.Fatalf("Node-Zertifikat: %v", err)
	}
	firstEndpoint, fingerprint := startDirectPairingTestNodeWithCertificate(t, directPairingTestToken, "", certificate)
	module := newDirectPairingStudio(t)
	first, err := (&grpcService{module: module}).addFromJoinCode(
		context.Background(), directPairingLink(t, firstEndpoint, fingerprint, directPairingTestToken), "",
	)
	if err != nil {
		t.Fatalf("erster Node-Link: %v", err)
	}
	before, ok := module.registry.get(first.GetNode().GetId())
	if !ok {
		t.Fatal("erster Node fehlt in Registry")
	}

	secondEndpoint, _ := startDirectPairingTestNodeWithCertificate(t, directPairingTestToken, "", certificate)
	updated, err := (&grpcService{module: module}).addFromJoinCode(
		context.Background(), directPairingLink(t, secondEndpoint, fingerprint, directPairingTestToken), "",
	)
	if err != nil {
		t.Fatalf("aktualisierter Node-Link: %v", err)
	}
	if updated.GetNode().GetId() != first.GetNode().GetId() {
		t.Fatalf("Endpointwechsel erzeugte einen neuen Node: %q statt %q", updated.GetNode().GetId(), first.GetNode().GetId())
	}
	if nodes := module.registry.list(); len(nodes) != 1 {
		t.Fatalf("Endpointwechsel hinterlegte %d Nodes statt einem: %+v", len(nodes), nodes)
	}
	after, ok := module.registry.get(first.GetNode().GetId())
	if !ok || (after.Address == before.Address && after.GRPCPort == before.GRPCPort) || after.GatewayKeyLabel != before.GatewayKeyLabel {
		t.Fatalf("Endpointwechsel aktualisierte Registry nicht stabil: vorher=%+v nachher=%+v", before, after)
	}
}

func TestAddNodeRollsBackDirectConnectionWithWrongCertificatePin(t *testing.T) {
	endpoint, fingerprint := startDirectPairingTestNode(t, directPairingTestToken, "")
	wrongFingerprint := "0" + fingerprint[1:]
	if wrongFingerprint == fingerprint {
		wrongFingerprint = "1" + fingerprint[1:]
	}
	module := newDirectPairingStudio(t)

	_, err := (&grpcService{module: module}).addFromJoinCode(
		context.Background(),
		directPairingLink(t, endpoint, wrongFingerprint, directPairingTestToken),
		"",
	)
	if status.Code(err) != codes.Unavailable {
		t.Fatalf("falscher TLS-Pin = %s, want %s (error: %v)", status.Code(err), codes.Unavailable, err)
	}
	if nodes := module.registry.list(); len(nodes) != 0 {
		t.Errorf("falscher TLS-Pin blieb in der Registry: %+v", nodes)
	}
}

func TestAddNodeRollsBackDirectConnectionWithWrongToken(t *testing.T) {
	endpoint, fingerprint := startDirectPairingTestNode(t, directPairingTestToken, "")
	module := newDirectPairingStudio(t)

	_, err := (&grpcService{module: module}).addFromJoinCode(
		context.Background(),
		directPairingLink(t, endpoint, fingerprint, "wrong-pairing-token-1234567890"),
		"",
	)
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("falscher Pairing-Token = %s, want %s (error: %v)", status.Code(err), codes.Unauthenticated, err)
	}
	if nodes := module.registry.list(); len(nodes) != 0 {
		t.Errorf("falscher Pairing-Token blieb in der Registry: %+v", nodes)
	}
}

func TestAddNodeRollsBackDirectConnectionWithUnreachableGateway(t *testing.T) {
	endpoint, fingerprint := startDirectPairingTestNode(t, directPairingTestToken, "https://127.0.0.1:1")
	module := newDirectPairingStudio(t)

	_, err := (&grpcService{module: module}).addFromJoinCode(
		context.Background(),
		directPairingLink(t, endpoint, fingerprint, directPairingTestToken),
		"",
	)
	if status.Code(err) != codes.Unavailable {
		t.Fatalf("unerreichbares Gateway = %s, want %s (error: %v)", status.Code(err), codes.Unavailable, err)
	}
	if nodes := module.registry.list(); len(nodes) != 0 {
		t.Errorf("Node mit unerreichbarem Gateway blieb in der Registry: %+v", nodes)
	}
}

func TestDialDirectTLSAllowsPublicEndpoint(t *testing.T) {
	module := newDirectPairingStudio(t)
	const fingerprint = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	if _, err := module.registry.add(storedNode{
		ID:             "public-direct",
		Name:           "Oeffentlicher Node",
		Address:        "203.0.113.7",
		GRPCPort:       50051,
		Enabled:        true,
		Token:          directPairingTestToken,
		TLSFingerprint: fingerprint,
		Tunnel:         storedTunnel{Managed: false},
		AddedAt:        time.Now().UTC(),
	}); err != nil {
		t.Fatalf("direkten oeffentlichen Node eintragen: %v", err)
	}
	connection, err := module.Dial("public-direct")
	if err != nil {
		t.Fatalf("Dial lehnte einen TLS-gepinnten oeffentlichen Endpunkt ab: %v", err)
	}
	if err := connection.Close(); err != nil {
		t.Errorf("Test-Verbindung schliessen: %v", err)
	}
}

func TestRegistryDirectTLSEntryDoesNotClaimWireGuardRoute(t *testing.T) {
	registry := newRegistry(filepath.Join(t.TempDir(), "nodes.json"))
	if _, err := registry.add(storedNode{
		ID:      "legacy-tunnel",
		Name:    "Alter Tunnel",
		Enabled: true,
		Tunnel: storedTunnel{
			Managed: true,
			Network: "10.77.0.0/24",
		},
	}); err != nil {
		t.Fatalf("Legacy-Tunnel eintragen: %v", err)
	}
	if _, err := registry.add(storedNode{
		ID:             "direct-overlap",
		Name:           "Direkte TLS-Verbindung",
		Address:        "10.77.0.1",
		GRPCPort:       50051,
		Enabled:        true,
		Token:          directPairingTestToken,
		TLSFingerprint: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		Tunnel:         storedTunnel{Managed: false},
	}); err != nil {
		t.Fatalf("direkter TLS-Node wurde als WireGuard-Route behandelt: %v", err)
	}
}
