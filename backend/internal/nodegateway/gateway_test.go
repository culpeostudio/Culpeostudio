package nodegateway

import (
	"crypto/tls"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/culpeohq/backend/internal/nodecert"
)

func TestGatewayProxiesOnlyV1OverTLS(t *testing.T) {
	var calls atomic.Int64
	var received struct {
		sync.Mutex
		path          string
		authorization string
		body          string
	}
	upstream := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		calls.Add(1)
		body, err := io.ReadAll(request.Body)
		if err != nil {
			t.Errorf("read upstream request body: %v", err)
		}
		received.Lock()
		received.path = request.URL.RequestURI()
		received.authorization = request.Header.Get("Authorization")
		received.body = string(body)
		received.Unlock()
		writer.Header().Set("X-Upstream", "seen")
		_, _ = writer.Write([]byte("proxied response"))
	}))
	defer upstream.Close()

	gateway := startGateway(t, upstream.URL)
	client := trustedTestClient()

	request, err := http.NewRequest(http.MethodPost, "https://"+gateway.Address()+"/v1/models/download?source=studio", strings.NewReader(`{"model":"small"}`))
	if err != nil {
		t.Fatalf("create TLS request: %v", err)
	}
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Authorization", "Bearer node-secret")
	response, err := client.Do(request)
	if err != nil {
		t.Fatalf("TLS request through gateway: %v", err)
	}
	responseBody, readErr := io.ReadAll(response.Body)
	_ = response.Body.Close()
	if readErr != nil {
		t.Fatalf("read proxy response: %v", readErr)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("proxy status = %d, want 200; body=%q", response.StatusCode, responseBody)
	}
	if response.Header.Get("X-Upstream") != "seen" || string(responseBody) != "proxied response" {
		t.Fatalf("upstream response was not preserved: headers=%v body=%q", response.Header, responseBody)
	}
	received.Lock()
	if received.path != "/v1/models/download?source=studio" {
		t.Errorf("upstream path = %q", received.path)
	}
	if received.authorization != "Bearer node-secret" {
		t.Errorf("Authorization = %q, want preserved bearer token", received.authorization)
	}
	if received.body != `{"model":"small"}` {
		t.Errorf("upstream body = %q", received.body)
	}
	received.Unlock()

	denied, err := client.Get("https://" + gateway.Address() + "/health")
	if err != nil {
		t.Fatalf("request to denied path: %v", err)
	}
	_ = denied.Body.Close()
	if denied.StatusCode != http.StatusNotFound {
		t.Errorf("non-/v1 status = %d, want 404", denied.StatusCode)
	}
	if calls.Load() != 1 {
		t.Errorf("upstream calls after denied path = %d, want 1", calls.Load())
	}

	traversal, err := client.Get("https://" + gateway.Address() + "/v1/../health")
	if err != nil {
		t.Fatalf("request with path traversal: %v", err)
	}
	_ = traversal.Body.Close()
	if traversal.StatusCode != http.StatusNotFound {
		t.Errorf("path traversal status = %d, want 404", traversal.StatusCode)
	}
	if calls.Load() != 1 {
		t.Errorf("upstream calls after path traversal = %d, want 1", calls.Load())
	}

	plainClient := &http.Client{Timeout: time.Second}
	plainResponse, plainErr := plainClient.Get("http://" + gateway.Address() + "/v1/models/download")
	if plainErr == nil {
		_ = plainResponse.Body.Close()
		if plainResponse.StatusCode == http.StatusOK {
			t.Error("a plaintext HTTP request reached the TLS gateway")
		}
	}
	if calls.Load() != 1 {
		t.Errorf("upstream calls after plaintext request = %d, want 1", calls.Load())
	}
}

func TestGatewayStreamsUpstreamResponses(t *testing.T) {
	firstChunkSent := make(chan struct{})
	releaseSecondChunk := make(chan struct{})
	upstream := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "text/event-stream")
		_, _ = writer.Write([]byte("data: first\n\n"))
		writer.(http.Flusher).Flush()
		close(firstChunkSent)
		<-releaseSecondChunk
		_, _ = writer.Write([]byte("data: second\n\n"))
		writer.(http.Flusher).Flush()
	}))
	defer upstream.Close()

	gateway := startGateway(t, upstream.URL)
	request, err := http.NewRequest(http.MethodGet, "https://"+gateway.Address()+"/v1/chat/completions", nil)
	if err != nil {
		t.Fatal(err)
	}
	response, err := trustedTestClient().Do(request)
	if err != nil {
		t.Fatalf("stream request: %v", err)
	}
	defer response.Body.Close()
	if response.Header.Get("Content-Type") != "text/event-stream" {
		t.Fatalf("stream content type = %q", response.Header.Get("Content-Type"))
	}

	select {
	case <-firstChunkSent:
	case <-time.After(time.Second):
		t.Fatal("upstream did not send first stream chunk")
	}
	chunk := make([]byte, len("data: first\n\n"))
	if _, err := io.ReadFull(response.Body, chunk); err != nil {
		t.Fatalf("read first streamed chunk: %v", err)
	}
	if string(chunk) != "data: first\n\n" {
		t.Fatalf("first streamed chunk = %q", chunk)
	}
	close(releaseSecondChunk)
	second, err := io.ReadAll(response.Body)
	if err != nil {
		t.Fatalf("read second streamed chunk: %v", err)
	}
	if string(second) != "data: second\n\n" {
		t.Fatalf("second streamed chunk = %q", second)
	}
}

func TestGatewayRejectsPreTLS12(t *testing.T) {
	upstream := httptest.NewServer(http.NotFoundHandler())
	defer upstream.Close()
	gateway := startGateway(t, upstream.URL)

	connection, err := tls.Dial("tcp", gateway.Address(), &tls.Config{
		InsecureSkipVerify: true, // Test only: nodecert is intentionally self-signed.
		MinVersion:         tls.VersionTLS11,
		MaxVersion:         tls.VersionTLS11,
	})
	if err == nil {
		_ = connection.Close()
		t.Fatal("TLS 1.1 was accepted although the gateway requires TLS 1.2")
	}
}

func TestStartRejectsNonLoopbackUpstream(t *testing.T) {
	_, err := Start(Config{
		ListenAddress: "127.0.0.1:0",
		UpstreamURL:   "http://example.com:8091",
		TLSCertFile:   "not-used-before-upstream-validation",
		TLSKeyFile:    "not-used-before-upstream-validation",
	})
	if err == nil || !strings.Contains(err.Error(), "Loopback") {
		t.Fatalf("Start non-loopback upstream error = %v", err)
	}
}

func startGateway(t *testing.T, upstreamURL string) *Gateway {
	t.Helper()
	certificate, err := nodecert.Ensure(t.TempDir())
	if err != nil {
		t.Fatalf("create temporary node certificate: %v", err)
	}
	gateway, err := Start(Config{
		ListenAddress: "127.0.0.1:0",
		UpstreamURL:   upstreamURL,
		TLSCertFile:   certificate.CertificatePath,
		TLSKeyFile:    certificate.PrivateKeyPath,
	})
	if err != nil {
		t.Fatalf("start gateway: %v", err)
	}
	t.Cleanup(func() {
		if err := gateway.Close(); err != nil {
			t.Errorf("close gateway: %v", err)
		}
	})
	return gateway
}

func trustedTestClient() *http.Client {
	return &http.Client{
		Timeout: 3 * time.Second,
		Transport: &http.Transport{
			// Test only: production Studio pins the node certificate fingerprint.
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true, MinVersion: tls.VersionTLS12},
		},
	}
}
