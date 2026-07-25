package engine

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/localinference"
)

func TestGatewayRoutesScopedKeyAndForwardsSSEWithoutBuffering(t *testing.T) {
	worker := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		if request.Header.Get("Authorization") != "Bearer worker-secret" {
			http.Error(w, "missing worker auth", http.StatusUnauthorized)
			return
		}
		w.Header().Set("Content-Type", "text/event-stream")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("data: {\"text\":\"Gr"))
		if flush, ok := w.(http.Flusher); ok {
			flush.Flush()
		}
		_, _ = w.Write([]byte("üße\"}\n\ndata: [DONE]\n\n"))
	}))
	defer worker.Close()

	keys, err := newEngineKeyStore(filepath.Join(t.TempDir(), "keys.json"))
	if err != nil {
		t.Fatal(err)
	}
	_, plaintext, err := keys.create("test", []string{"alpha"})
	if err != nil {
		t.Fatal(err)
	}
	model := gatewayModel{ID: "alpha", Ready: true, BaseURL: worker.URL, WorkerSecret: "worker-secret", ContextLimit: 4096, CreatedAt: time.Now(), Runtime: "test"}
	gateway := newLocalGateway(keys, func(id string) (gatewayModel, bool) { return model, id == "alpha" }, func() []gatewayModel { return []gatewayModel{model} })
	address, err := gateway.start("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer gateway.shutdown(context.Background())

	request, _ := http.NewRequest(http.MethodPost, "http://"+address+"/v1/chat/completions", strings.NewReader(`{"model":"alpha","messages":[{"role":"user","content":"Hallo"}],"stream":true}`))
	request.Header.Set("Authorization", "Bearer "+plaintext)
	request.Header.Set("Content-Type", "application/json")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	data, _ := io.ReadAll(response.Body)
	_ = response.Body.Close()
	if response.StatusCode != http.StatusOK || !strings.Contains(string(data), "Grüße") || !strings.Contains(string(data), "[DONE]") {
		t.Fatalf("unexpected gateway response %d: %q", response.StatusCode, data)
	}

	request, _ = http.NewRequest(http.MethodPost, "http://"+address+"/v1/completions", strings.NewReader(`{"model":"beta","prompt":"x"}`))
	request.Header.Set("Authorization", "Bearer "+plaintext)
	response, err = http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusUnauthorized {
		t.Fatalf("scoped key returned %d for another instance", response.StatusCode)
	}
}

func TestGatewayAdmissionReturnsBoundedQueueStatus(t *testing.T) {
	keys, err := newEngineKeyStore(filepath.Join(t.TempDir(), "keys.json"))
	if err != nil {
		t.Fatal(err)
	}
	_, plaintext, err := keys.create("queue", nil)
	if err != nil {
		t.Fatal(err)
	}
	model := gatewayModel{ID: "alpha", Ready: true, BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret", ContextLimit: 4096}
	called := false
	gateway := newLocalGateway(
		keys,
		func(id string) (gatewayModel, bool) { return model, id == "alpha" },
		func() []gatewayModel { return []gatewayModel{model} },
		func(context.Context, string) (func(), error) {
			called = true
			return nil, &inferenceAdmissionError{code: "inference_queue_full", err: localinference.ErrInferenceBusy}
		},
	)
	address, err := gateway.start("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer gateway.shutdown(context.Background())
	request, _ := http.NewRequest(http.MethodPost, "http://"+address+"/v1/chat/completions", strings.NewReader(`{"model":"alpha","messages":[{"role":"user","content":"Hallo"}]}`))
	request.Header.Set("Authorization", "Bearer "+plaintext)
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if !called || response.StatusCode != http.StatusTooManyRequests || response.Header.Get("Retry-After") != "120" {
		t.Fatalf("admission response called=%v status=%d retry=%q", called, response.StatusCode, response.Header.Get("Retry-After"))
	}
}

func TestGatewayPropagatesClientCancellationToWorker(t *testing.T) {
	started := make(chan struct{})
	cancelled := make(chan struct{})
	worker := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		// The real workers parse the complete JSON body before inference. Reading
		// it here is also required for net/http to observe a later peer close and
		// cancel the worker request context.
		_, _ = io.Copy(io.Discard, request.Body)
		close(started)
		<-request.Context().Done()
		close(cancelled)
	}))
	defer worker.Close()
	keys, err := newEngineKeyStore(filepath.Join(t.TempDir(), "keys.json"))
	if err != nil {
		t.Fatal(err)
	}
	_, plaintext, err := keys.create("cancel", nil)
	if err != nil {
		t.Fatal(err)
	}
	model := gatewayModel{ID: "alpha", Ready: true, BaseURL: worker.URL, WorkerSecret: "worker-secret", ContextLimit: 4096}
	gateway := newLocalGateway(keys, func(id string) (gatewayModel, bool) { return model, id == "alpha" }, func() []gatewayModel { return []gatewayModel{model} })
	address, err := gateway.start("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer gateway.shutdown(context.Background())

	requestContext, cancel := context.WithCancel(context.Background())
	request, _ := http.NewRequestWithContext(requestContext, http.MethodPost, "http://"+address+"/v1/completions", strings.NewReader(`{"model":"alpha","prompt":"long request"}`))
	request.Header.Set("Authorization", "Bearer "+plaintext)
	done := make(chan struct{})
	go func() {
		response, _ := http.DefaultClient.Do(request)
		if response != nil {
			_ = response.Body.Close()
		}
		close(done)
	}()
	select {
	case <-started:
	case <-time.After(time.Second):
		t.Fatal("worker did not receive proxied request")
	}
	cancel()
	select {
	case <-cancelled:
	case <-time.After(time.Second):
		t.Fatal("upstream worker context was not cancelled")
	}
	<-done
}
