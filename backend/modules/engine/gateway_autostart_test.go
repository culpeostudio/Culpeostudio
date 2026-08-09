package engine

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func newTestKeys(t *testing.T, scope []string) (*engineKeyStore, string) {
	t.Helper()
	keys, err := newEngineKeyStore(filepath.Join(t.TempDir(), "keys.json"))
	if err != nil {
		t.Fatal(err)
	}
	_, plaintext, err := keys.create("test", scope)
	if err != nil {
		t.Fatal(err)
	}
	return keys, plaintext
}

func TestGatewayResolvesTheServedModelNameAsAnAlias(t *testing.T) {
	worker := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		body, _ := io.ReadAll(request.Body)
		// Whatever name the client used, the worker only answers to the
		// instance id, so the proxied body must carry that.
		if !strings.Contains(string(body), `"model":"inst_alpha"`) {
			http.Error(w, "model was not rewritten: "+string(body), http.StatusBadRequest)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"choices":[{"text":"ok"}],"usage":{"completion_tokens":7}}`))
	}))
	defer worker.Close()

	keys, plaintext := newTestKeys(t, []string{"inst_alpha"})
	model := gatewayModel{
		ID: "inst_alpha", Alias: "qwen3-coder", Ready: true,
		BaseURL: worker.URL, WorkerSecret: "secret", ContextLimit: 4096,
	}
	var measured atomic.Int64
	gateway := newLocalGateway(keys, gatewayDependencies{
		lookup: func(name string) (gatewayModel, bool) {
			return model, name == "inst_alpha" || name == "qwen3-coder"
		},
		list: func() []gatewayModel { return []gatewayModel{model} },
		recordUsage: func(_ string, sample gatewayUsageSample) {
			measured.Store(int64(sample.OutputTokens))
		},
	})
	address, err := gateway.start("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer gateway.shutdown(context.Background())

	request, _ := http.NewRequest(http.MethodPost, "http://"+address+"/v1/chat/completions",
		strings.NewReader(`{"model":"qwen3-coder","messages":[{"role":"user","content":"hi"}]}`))
	request.Header.Set("Authorization", "Bearer "+plaintext)
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(response.Body)
	_ = response.Body.Close()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("alias request returned %d: %s", response.StatusCode, body)
	}
	// The gateway used to be a pure byte proxy, so a request driven from an
	// external SDK contributed nothing to the instance's throughput figures.
	if measured.Load() != 7 {
		t.Fatalf("gateway usage was not measured: %d", measured.Load())
	}
}

func TestGatewayKeepsExistenceHiddenFromAnUnauthorizedKey(t *testing.T) {
	keys, plaintext := newTestKeys(t, []string{"inst_alpha"})
	model := gatewayModel{ID: "inst_beta", Ready: true, BaseURL: "http://127.0.0.1:1", WorkerSecret: "s"}
	gateway := newLocalGateway(keys, gatewayDependencies{
		lookup: func(name string) (gatewayModel, bool) { return model, name == "inst_beta" },
		list:   func() []gatewayModel { return []gatewayModel{model} },
	})
	address, err := gateway.start("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer gateway.shutdown(context.Background())

	// The instance exists but is outside this key's scope. Answering 404 here
	// would tell the caller it exists, which a key that cannot reach it should
	// not learn.
	request, _ := http.NewRequest(http.MethodPost, "http://"+address+"/v1/chat/completions",
		strings.NewReader(`{"model":"inst_beta","messages":[]}`))
	request.Header.Set("Authorization", "Bearer "+plaintext)
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusUnauthorized {
		t.Fatalf("out-of-scope instance returned %d, want 401", response.StatusCode)
	}
}

func TestGatewayOnlyAutostartsWhenTheInstanceOptedIn(t *testing.T) {
	keys, plaintext := newTestKeys(t, nil)
	cold := gatewayModel{ID: "inst_alpha", Ready: false}
	warmed := atomic.Bool{}

	gateway := newLocalGateway(keys, gatewayDependencies{
		lookup: func(string) (gatewayModel, bool) { return cold, true },
		list:   func() []gatewayModel { return []gatewayModel{cold} },
		ensureReady: func(context.Context, string) error {
			warmed.Store(true)
			return nil
		},
	})
	address, err := gateway.start("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer gateway.shutdown(context.Background())

	post := func() *http.Response {
		request, _ := http.NewRequest(http.MethodPost, "http://"+address+"/v1/chat/completions",
			strings.NewReader(`{"model":"inst_alpha","messages":[]}`))
		request.Header.Set("Authorization", "Bearer "+plaintext)
		response, err := http.DefaultClient.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		return response
	}

	response := post()
	body, _ := io.ReadAll(response.Body)
	_ = response.Body.Close()
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("a cold instance without the opt-in returned %d", response.StatusCode)
	}
	if warmed.Load() {
		t.Fatal("loading a model because a request named it must take the owner's opt-in")
	}
	if !strings.Contains(string(body), "automatische") {
		t.Fatalf("the answer should say what to switch on, got %s", body)
	}

	// With the box ticked the same request warms the instance instead.
	cold.Autostart = true
	response = post()
	_ = response.Body.Close()
	if !warmed.Load() {
		t.Fatal("an opted-in instance must be warmed up on demand")
	}
}

func TestGatewayHealthNeedsNoKey(t *testing.T) {
	keys, _ := newTestKeys(t, nil)
	gateway := newLocalGateway(keys, gatewayDependencies{
		list: func() []gatewayModel { return []gatewayModel{{ID: "a", Ready: true}, {ID: "b"}} },
	})
	address, err := gateway.start("127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer gateway.shutdown(context.Background())

	response, err := http.Get("http://" + address + "/health")
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(response.Body)
	_ = response.Body.Close()
	if response.StatusCode != http.StatusOK || !strings.Contains(string(body), `"ready_models":1`) {
		t.Fatalf("health returned %d: %s", response.StatusCode, body)
	}
}

func TestInstanceIdleTimeoutFollowsTheInstanceConfig(t *testing.T) {
	module := &EngineModule{idleTimeout: 15 * time.Minute}

	if got := module.instanceIdleTimeout(&EngineInstance{}); got != 15*time.Minute {
		t.Fatalf("an unset timeout follows the engine default, got %v", got)
	}
	fiveMinutes := 300
	instance := &EngineInstance{RequestedConfig: EngineConfig{IdleTimeoutSeconds: &fiveMinutes}}
	if got := module.instanceIdleTimeout(instance); got != 5*time.Minute {
		t.Fatalf("configured timeout ignored, got %v", got)
	}
	// A negative value is how "keep it loaded until I stop it" is expressed,
	// and it has to come back as zero so the caller clears the deadline.
	never := -1
	instance = &EngineInstance{RequestedConfig: EngineConfig{IdleTimeoutSeconds: &never}}
	if got := module.instanceIdleTimeout(instance); got != 0 {
		t.Fatalf("never-unload must report no deadline, got %v", got)
	}
}

func TestGatewayModelCarriesTheAutostartOptIn(t *testing.T) {
	instance := &EngineInstance{
		ID: "inst_a", ServedModelName: "friendly", State: engineruntime.StateReady,
		GatewayAutostart: true,
	}
	model := gatewayModelFor(instance)
	if model.Alias != "friendly" || !model.Autostart || !model.Ready {
		t.Fatalf("gatewayModelFor = %+v", model)
	}
}
