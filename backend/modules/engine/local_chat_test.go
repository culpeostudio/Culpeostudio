package engine

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/localinference"
)

func TestStreamLocalChatUsesWorkerSecretAndStreams(t *testing.T) {
	worker := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/v1/chat/completions" {
			t.Fatalf("unexpected worker path %q", request.URL.Path)
		}
		if got := request.Header.Get("Authorization"); got != "Bearer internal-worker-secret" {
			t.Fatalf("unexpected worker authorization %q", got)
		}
		if request.Header.Get("X-OpenRouter-Api-Key") != "" {
			t.Fatal("provider credential was forwarded to local worker")
		}
		body, _ := io.ReadAll(request.Body)
		if !strings.Contains(string(body), `"model":"local-ready"`) || !strings.Contains(string(body), `"temperature":0.2`) {
			t.Fatalf("unexpected worker payload %s", body)
		}
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\"Hallo\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\" lokal\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer worker.Close()

	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["local-ready"] = &EngineInstance{
		ID: "local-ready", ModelID: "catalog-model", ServedModelName: "Lokales Modell",
		State: engineruntime.StateReady, BaseURL: worker.URL, WorkerSecret: "internal-worker-secret",
		EffectiveConfig: EngineConfig{GenerationDefaults: map[string]interface{}{"temperature": 0.2}},
		Plan:            &ContextPlanView{EffectiveContextTokens: 4096}, CreatedAt: time.Now(),
	}

	var chunks []string
	reply, err := module.StreamLocalChat(context.Background(), "local-ready", localinference.ChatRequest{
		Messages: []localinference.Message{{Role: "user", Content: "Hallo"}},
	}, func(chunk string) error {
		chunks = append(chunks, chunk)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if reply != "Hallo lokal" || strings.Join(chunks, "") != reply {
		t.Fatalf("unexpected streamed reply %q chunks %#v", reply, chunks)
	}
	models := module.ReadyLocalModels()
	if len(models) != 1 || models[0].InstanceID != "local-ready" || models[0].ContextLimit != 4096 {
		t.Fatalf("unexpected ready model list %#v", models)
	}
}

func TestLocalChatRejectsMissingStoppedRemoteAndOversizedTargets(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["stopped"] = &EngineInstance{ID: "stopped", State: engineruntime.StateStopped}
	if _, err := module.ResolveLocalModel("missing"); !errors.Is(err, localinference.ErrNotFound) {
		t.Fatalf("expected not found, got %v", err)
	}
	if _, err := module.ResolveLocalModel("stopped"); !errors.Is(err, localinference.ErrNotReady) {
		t.Fatalf("expected not ready, got %v", err)
	}
	module.instances["remote"] = &EngineInstance{ID: "remote", State: engineruntime.StateReady, BaseURL: "http://example.com:8080", WorkerSecret: "secret"}
	if _, err := module.StreamLocalChat(context.Background(), "remote", localinference.ChatRequest{Messages: []localinference.Message{{Role: "user", Content: "x"}}}, nil); err == nil || !strings.Contains(err.Error(), "Loopback") {
		t.Fatalf("expected remote worker rejection, got %v", err)
	}
	module.instances["small"] = &EngineInstance{ID: "small", State: engineruntime.StateReady, BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret", Plan: &ContextPlanView{EffectiveContextTokens: 4}}
	maxTokens := 5
	_, err := module.StreamLocalChat(context.Background(), "small", localinference.ChatRequest{Messages: []localinference.Message{{Role: "user", Content: "x"}}, MaxTokens: &maxTokens}, nil)
	if !errors.Is(err, localinference.ErrContextLimit) {
		t.Fatalf("expected context limit, got %v", err)
	}
}

func TestQueuedInferenceRechecksEmergencyGuardAfterAdmission(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.inferenceQueueTimeout = 2 * time.Second
	module.instances["ready"] = &EngineInstance{
		ID: "ready", State: engineruntime.StateReady,
		BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret",
		EffectiveConfig: EngineConfig{MaxSequences: 1},
		CreatedAt:       time.Now(), UpdatedAt: time.Now(),
	}

	firstRelease, err := module.acquireInference(context.Background(), "ready")
	if err != nil {
		t.Fatal(err)
	}
	result := make(chan error, 1)
	go func() {
		release, acquireErr := module.acquireInference(context.Background(), "ready")
		if release != nil {
			release()
		}
		result <- acquireErr
	}()

	deadline := time.Now().Add(time.Second)
	for {
		module.inferenceMu.Lock()
		gate := module.inferenceGates["ready"]
		module.inferenceMu.Unlock()
		waiting := 0
		if gate != nil {
			gate.mu.Lock()
			waiting = len(gate.waiting)
			gate.mu.Unlock()
		}
		if waiting == 1 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("second inference did not enter the queue")
		}
		time.Sleep(time.Millisecond)
	}

	module.mu.Lock()
	module.guardState = GuardEmergency
	module.mu.Unlock()
	firstRelease()
	select {
	case err := <-result:
		if !errors.Is(err, localinference.ErrGuardRejected) {
			t.Fatalf("queued inference error = %v, want guard rejection", err)
		}
	case <-time.After(time.Second):
		t.Fatal("queued inference did not leave after emergency transition")
	}
	module.mu.RLock()
	active := module.instances["ready"].ActiveRequests
	module.mu.RUnlock()
	if active != 0 {
		t.Fatalf("active requests = %d after rejected queued inference", active)
	}

	module.mu.Lock()
	module.guardState = GuardNormal
	module.mu.Unlock()
	release, err := module.acquireInference(context.Background(), "ready")
	if err != nil {
		t.Fatalf("inference gate remained stranded: %v", err)
	}
	release()
}

func TestQueuedInferenceCannotCrossWorkerGeneration(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.inferenceQueueTimeout = 2 * time.Second
	module.instances["ready"] = &EngineInstance{
		ID: "ready", State: engineruntime.StateReady,
		BaseURL: "http://127.0.0.1:1", WorkerSecret: "old-secret", workerGeneration: 7,
		EffectiveConfig: EngineConfig{MaxSequences: 1}, CreatedAt: time.Now(), UpdatedAt: time.Now(),
	}
	firstRelease, err := module.acquireInference(context.Background(), "ready")
	if err != nil {
		t.Fatal(err)
	}
	queued := make(chan error, 1)
	go func() {
		release, acquireErr := module.acquireInference(context.Background(), "ready")
		if release != nil {
			release()
		}
		queued <- acquireErr
	}()
	deadline := time.Now().Add(time.Second)
	for {
		module.inferenceMu.Lock()
		oldGate := module.inferenceGates["ready"]
		module.inferenceMu.Unlock()
		oldGate.mu.Lock()
		waiting := len(oldGate.waiting)
		oldGate.mu.Unlock()
		if waiting == 1 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("second inference did not wait on old generation")
		}
		time.Sleep(time.Millisecond)
	}

	module.mu.Lock()
	instance := module.instances["ready"]
	instance.workerGeneration = 8
	instance.WorkerSecret = "new-secret"
	instance.ActiveRequests = 0
	module.inferenceMu.Lock()
	module.inferenceGates["ready"] = &inferenceGate{}
	module.inferenceMu.Unlock()
	module.mu.Unlock()
	firstRelease()
	select {
	case err := <-queued:
		if !errors.Is(err, localinference.ErrNotReady) {
			t.Fatalf("old-generation waiter error = %v, want not ready", err)
		}
	case <-time.After(time.Second):
		t.Fatal("old-generation waiter remained stranded")
	}
	module.mu.RLock()
	active := module.instances["ready"].ActiveRequests
	module.mu.RUnlock()
	if active != 0 {
		t.Fatalf("old release changed new generation count to %d", active)
	}

	newRelease, err := module.acquireInference(context.Background(), "ready")
	if err != nil {
		t.Fatalf("new generation gate unusable: %v", err)
	}
	newRelease()
}

func TestOldInferenceReleaseCannotDecrementNewGeneration(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["ready"] = &EngineInstance{
		ID: "ready", State: engineruntime.StateReady,
		BaseURL: "http://127.0.0.1:1", WorkerSecret: "old-secret", workerGeneration: 1,
		EffectiveConfig: EngineConfig{MaxSequences: 2}, CreatedAt: time.Now(), UpdatedAt: time.Now(),
	}
	oldRelease, err := module.acquireInference(context.Background(), "ready")
	if err != nil {
		t.Fatal(err)
	}
	module.mu.Lock()
	instance := module.instances["ready"]
	instance.WorkerSecret = "new-secret"
	instance.workerGeneration = 2
	instance.ActiveRequests = 0
	module.inferenceMu.Lock()
	module.inferenceGates["ready"] = &inferenceGate{}
	module.inferenceMu.Unlock()
	module.mu.Unlock()
	newRelease, err := module.acquireInference(context.Background(), "ready")
	if err != nil {
		t.Fatal(err)
	}
	oldRelease()
	module.mu.RLock()
	active := module.instances["ready"].ActiveRequests
	module.mu.RUnlock()
	if active != 1 {
		t.Fatalf("old release decremented new generation to %d", active)
	}
	newRelease()
}

func TestRestartDrainWaitsForActiveInferenceLease(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["ready"] = &EngineInstance{
		ID: "ready", State: engineruntime.StateReady,
		BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret", workerGeneration: 1,
		EffectiveConfig: EngineConfig{MaxSequences: 1}, CreatedAt: time.Now(), UpdatedAt: time.Now(),
	}
	release, err := module.acquireInference(context.Background(), "ready")
	if err != nil {
		t.Fatal(err)
	}
	module.mu.Lock()
	module.instances["ready"].State = engineruntime.StateDraining
	module.mu.Unlock()

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	drained := make(chan error, 1)
	go func() {
		drained <- module.waitForInstanceDrain(ctx, "ready")
	}()
	select {
	case err := <-drained:
		t.Fatalf("drain completed while inference was active: %v", err)
	case <-time.After(30 * time.Millisecond):
	}

	release()
	select {
	case err := <-drained:
		if err != nil {
			t.Fatalf("drain failed after inference release: %v", err)
		}
	case <-time.After(500 * time.Millisecond):
		t.Fatal("drain did not complete after inference release")
	}
}

func TestLocalWorkerErrorPreservesActionableStatus(t *testing.T) {
	for _, tc := range []struct {
		status int
		want   error
	}{
		{http.StatusNotFound, localinference.ErrNotFound},
		{http.StatusConflict, localinference.ErrNotReady},
		{http.StatusUnprocessableEntity, localinference.ErrContextLimit},
		{http.StatusServiceUnavailable, localinference.ErrWorkerUnavailable},
	} {
		response := &http.Response{
			StatusCode: tc.status,
			Body:       io.NopCloser(strings.NewReader(`{"error":{"message":"worker detail"}}`)),
		}
		err := localWorkerError(response)
		if !errors.Is(err, tc.want) || !strings.Contains(err.Error(), "worker detail") {
			t.Fatalf("status %d returned %v", tc.status, err)
		}
	}
}
