package nodeapp

import (
	"context"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	"github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
	"github.com/culpeohq/backend/internal/nodeconnection"
	studionode "github.com/culpeohq/backend/modules/node"
)

// This crosses the real boundary a user relies on: an independently started
// Node prints a link, Studio adds that link through its ordinary NodeService,
// and all later Engine/Marketplace calls use the pinned TLS connection the
// Studio registry created. The OpenRouter descriptor download is deliberately
// network-free, while still proving the job and its output run on the Node's
// own model directory rather than in Studio.
func TestStandaloneNodePairsWithStudioAndServesLocalEngineAndMarketplace(t *testing.T) {
	t.Setenv("ENGINE_GATEWAY_ADDR", "127.0.0.1:0")
	nodePort := reserveTestPort(t)
	nodeData := t.TempDir()
	runtime, err := New(Config{
		DataDir:       nodeData,
		Listen:        net.JoinHostPort("127.0.0.1", nodePort),
		Advertise:     net.JoinHostPort("127.0.0.1", nodePort),
		GatewayListen: "127.0.0.1:0",
		Name:          "Integration Node",
	})
	if err != nil {
		t.Fatalf("Node vorbereiten: %v", err)
	}
	nodeContext, cancelNode := context.WithCancel(context.Background())
	nodeDone := make(chan error, 1)
	go func() { nodeDone <- runtime.Run(nodeContext) }()
	t.Cleanup(func() {
		cancelNode()
		select {
		case runErr := <-nodeDone:
			if runErr != nil {
				t.Errorf("Node beenden: %v", runErr)
			}
		case <-time.After(10 * time.Second):
			t.Error("Node beendete sich nicht")
		}
	})

	studioModule := studionode.New(filepath.Join(t.TempDir(), "studio-settings.json"))
	if err := studioModule.Initialize(); err != nil {
		t.Fatalf("Studio-Node-Registry initialisieren: %v", err)
	}
	t.Cleanup(func() { _ = studioModule.Shutdown() })
	studioServer := grpc.NewServer()
	studioModule.RegisterGRPC(studioServer)
	studioListener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Studio-Testlistener: %v", err)
	}
	go func() { _ = studioServer.Serve(studioListener) }()
	t.Cleanup(func() {
		studioServer.Stop()
		_ = studioListener.Close()
	})

	studioConnection, err := grpc.NewClient(
		studioListener.Addr().String(),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("Studio-Verbindung: %v", err)
	}
	t.Cleanup(func() { _ = studioConnection.Close() })
	studioClient := nodev1.NewNodeServiceClient(studioConnection)

	var added *nodev1.AddNodeResponse
	deadline := time.Now().Add(10 * time.Second)
	for time.Now().Before(deadline) {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		added, err = studioClient.AddNode(ctx, &nodev1.AddNodeRequest{
			Source: &nodev1.AddNodeRequest_JoinCode{JoinCode: runtime.ConnectionLink()},
		})
		cancel()
		if err == nil {
			break
		}
		if status.Code(err) != codes.Unavailable {
			t.Fatalf("Node hinzufuegen: %v", err)
		}
		time.Sleep(50 * time.Millisecond)
	}
	if err != nil {
		t.Fatalf("Node wurde nicht erreichbar: %v", err)
	}
	if added.GetNode().GetState() != nodev1.NodeState_NODE_STATE_ONLINE {
		t.Fatalf("Node-Status = %s, message=%q", added.GetNode().GetState(), added.GetNode().GetStatusMessage())
	}

	connection, err := studioModule.Dial(added.GetNode().GetId())
	if err != nil {
		t.Fatalf("gepaarte TLS-Verbindung: %v", err)
	}
	capabilities, err := enginev1.NewEngineServiceClient(connection).GetCapabilities(
		context.Background(), &enginev1.GetCapabilitiesRequest{},
	)
	if err != nil {
		t.Fatalf("Engine auf Node: %v", err)
	}
	if capabilities.GetHardware() == nil {
		t.Fatal("Node-Engine lieferte keine lokale Hardware")
	}
	hardware, err := marketplacev1.NewMarketplaceServiceClient(connection).GetHardwareProfile(
		context.Background(), &marketplacev1.GetHardwareProfileRequest{},
	)
	if err != nil {
		t.Fatalf("Marketplace auf Node: %v", err)
	}
	if hardware.GetProfile() == nil {
		t.Fatal("Node-Marketplace lieferte kein lokales Hardware-Profil")
	}
	download, err := marketplacev1.NewMarketplaceServiceClient(connection).StartDownload(
		context.Background(),
		&marketplacev1.StartDownloadRequest{
			Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
			ModelId:  "openai/node-only-test",
		},
	)
	if err != nil {
		t.Fatalf("Download auf Node einplanen: %v", err)
	}
	if download.GetJobId() == "" {
		t.Fatal("Node-Download lieferte keine Job-ID")
	}
	deadline = time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		jobs, listErr := marketplacev1.NewMarketplaceServiceClient(connection).ListDownloadJobs(
			context.Background(), &marketplacev1.ListDownloadJobsRequest{},
		)
		if listErr != nil {
			t.Fatalf("Node-Download abfragen: %v", listErr)
		}
		for _, job := range jobs.GetJobs() {
			if job.GetId() != download.GetJobId() {
				continue
			}
			if job.GetStatus() == marketplacev1.DownloadStatus_DOWNLOAD_STATUS_DONE {
				deadline = time.Time{}
				break
			}
			if job.GetStatus() == marketplacev1.DownloadStatus_DOWNLOAD_STATUS_FAILED {
				t.Fatalf("Node-Download schlug fehl: %s", job.GetError())
			}
		}
		if deadline.IsZero() {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	if !deadline.IsZero() {
		t.Fatal("Node-Download wurde nicht fertig")
	}
	if _, err := os.Stat(filepath.Join(nodeData, "models", "node-only-test.json")); err != nil {
		t.Fatalf("Download liegt nicht im Node-Modellordner: %v", err)
	}

	target, ok := studioModule.LookupTarget(added.GetNode().GetId())
	if !ok || target.GatewayKey == "" || target.GatewayBaseURL == "" {
		t.Fatalf("Studio speicherte keinen direkten Gateway-Zugang: %+v", target)
	}
	tlsConfig, err := nodeconnection.PinnedTLSConfig(target.TLSFingerprint)
	if err != nil {
		t.Fatalf("Gateway-TLS-Pin: %v", err)
	}
	request, err := http.NewRequest(http.MethodGet, target.GatewayURL()+"/v1/models", nil)
	if err != nil {
		t.Fatalf("Gateway-Anfrage: %v", err)
	}
	request.Header.Set("Authorization", "Bearer "+target.GatewayKey)
	response, err := (&http.Client{Transport: &http.Transport{TLSClientConfig: tlsConfig}}).Do(request)
	if err != nil {
		t.Fatalf("gepinnter HTTPS-Gateway-Aufruf: %v", err)
	}
	_ = response.Body.Close()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("gepinnter Gateway-Status = %d, want 200", response.StatusCode)
	}

	oldGatewayKey := target.GatewayKey
	disable := false
	disabled, err := studioClient.UpdateNode(context.Background(), &nodev1.UpdateNodeRequest{
		NodeId:  added.GetNode().GetId(),
		Enabled: &disable,
	})
	if err != nil {
		t.Fatalf("direkten Node deaktivieren: %v", err)
	}
	if disabled.GetNode().GetState() != nodev1.NodeState_NODE_STATE_DISABLED {
		t.Fatalf("deaktivierter Node-Status = %s", disabled.GetNode().GetState())
	}
	oldKeyRequest, err := http.NewRequest(http.MethodGet, target.GatewayURL()+"/v1/models", nil)
	if err != nil {
		t.Fatalf("alte Gateway-Anfrage: %v", err)
	}
	oldKeyRequest.Header.Set("Authorization", "Bearer "+oldGatewayKey)
	oldKeyResponse, err := (&http.Client{Transport: &http.Transport{TLSClientConfig: tlsConfig}}).Do(oldKeyRequest)
	if err != nil {
		t.Fatalf("widerrufenen Gateway-Schluessel pruefen: %v", err)
	}
	_ = oldKeyResponse.Body.Close()
	if oldKeyResponse.StatusCode == http.StatusOK {
		t.Fatal("deaktivierter Node akzeptierte den widerrufenen Gateway-Schluessel noch")
	}

	enable := true
	enabled, err := studioClient.UpdateNode(context.Background(), &nodev1.UpdateNodeRequest{
		NodeId:  added.GetNode().GetId(),
		Enabled: &enable,
	})
	if err != nil {
		t.Fatalf("direkten Node reaktivieren: %v", err)
	}
	if enabled.GetNode().GetState() != nodev1.NodeState_NODE_STATE_ONLINE {
		t.Fatalf("reaktivierter Node-Status = %s, message=%q", enabled.GetNode().GetState(), enabled.GetNode().GetStatusMessage())
	}
	renewed, ok := studioModule.LookupTarget(added.GetNode().GetId())
	if !ok || renewed.GatewayKey == "" || renewed.GatewayKey == oldGatewayKey {
		t.Fatalf("Reaktivierung stellte keinen frischen Gateway-Schluessel aus: %+v", renewed)
	}
}

func reserveTestPort(t *testing.T) string {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("freien Port bestimmen: %v", err)
	}
	defer listener.Close()
	_, port, err := net.SplitHostPort(listener.Addr().String())
	if err != nil {
		t.Fatalf("freien Port zerlegen: %v", err)
	}
	return port
}
