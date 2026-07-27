package philobot

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/localinference"
)

type fakeLocalModels struct {
	model       localinference.Model
	resolveErr  error
	streamErr   error
	requestSeen localinference.ChatRequest
}

type fakeWarmupLocalModels struct {
	mu               sync.Mutex
	model            localinference.Model
	ready            bool
	ensureCalls      int
	streamCalls      int
	seenUserMessages []string
}

type blockingLocalModels struct {
	model   localinference.Model
	started chan struct{}
	release chan struct{}
	once    sync.Once
}

func (f *blockingLocalModels) ReadyLocalModels() []localinference.Model {
	return []localinference.Model{f.model}
}

func (f *blockingLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	return f.model, nil
}

func (f *blockingLocalModels) StreamLocalChat(ctx context.Context, instanceID string, _ localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	f.once.Do(func() { close(f.started) })
	select {
	case <-ctx.Done():
		return "", ctx.Err()
	case <-f.release:
	}
	if emit != nil {
		if err := emit("serialized reply"); err != nil {
			return "", err
		}
	}
	return "serialized reply", nil
}

func (f *fakeWarmupLocalModels) ReadyLocalModels() []localinference.Model {
	f.mu.Lock()
	defer f.mu.Unlock()
	if !f.ready {
		return nil
	}
	return []localinference.Model{f.model}
}

func (f *fakeWarmupLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	if !f.ready {
		return localinference.Model{}, localinference.ErrNotReady
	}
	return f.model, nil
}

func (f *fakeWarmupLocalModels) EnsureLocalModelReady(_ context.Context, instanceID string, emit func(localinference.WarmupProgress) error) (localinference.Model, error) {
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	f.mu.Lock()
	f.ensureCalls++
	f.mu.Unlock()
	for _, progress := range []localinference.WarmupProgress{
		{OperationID: "op-1", InstanceID: instanceID, Status: "queued", Phase: "admission", Progress: 0.1, QueuePosition: 1, Placement: "gpu"},
		{OperationID: "op-1", InstanceID: instanceID, Status: "ready", Phase: "healthcheck", Progress: 1, Placement: "gpu"},
	} {
		if emit != nil {
			if err := emit(progress); err != nil {
				return localinference.Model{}, err
			}
		}
	}
	f.mu.Lock()
	f.ready = true
	f.mu.Unlock()
	return f.model, nil
}

func (f *fakeWarmupLocalModels) StreamLocalChat(_ context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	f.mu.Lock()
	f.streamCalls++
	for _, message := range request.Messages {
		if message.Role == "user" {
			f.seenUserMessages = append(f.seenUserMessages, message.Content)
		}
	}
	f.mu.Unlock()
	if emit != nil {
		if err := emit("warm reply"); err != nil {
			return "", err
		}
	}
	return "warm reply", nil
}

func (f *fakeLocalModels) ReadyLocalModels() []localinference.Model {
	if f.resolveErr != nil {
		return nil
	}
	return []localinference.Model{f.model}
}

func (f *fakeLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	if f.resolveErr != nil {
		return localinference.Model{}, f.resolveErr
	}
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	return f.model, nil
}

func (f *fakeLocalModels) StreamLocalChat(_ context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	f.requestSeen = request
	if f.streamErr != nil {
		return "", f.streamErr
	}
	if emit != nil {
		if err := emit("Antwort vom lokalen Modell"); err != nil {
			return "", err
		}
	}
	return "Antwort vom lokalen Modell", nil
}

func TestPhiloBotLocalEngineSessionAndMessage(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	local := &fakeLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", ModelID: "catalog-id", DisplayName: "Qwythos lokal", ContextLimit: 8192,
	}}
	module.SetLocalModels(local)
	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_ref":"local:inst-ready"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	if createResponse.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(createResponse.Body)
		t.Fatalf("expected local session 200, got %d: %s", createResponse.StatusCode, body)
	}
	var created map[string]interface{}
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	if created["provider"] != "local" || created["instance_id"] != "inst-ready" || created["context_limit"] != float64(8192) {
		t.Fatalf("unexpected local session %#v", created)
	}

	message := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"Hallo"}`))
	message.Header.Set("Content-Type", "application/json")
	messageResponse, err := app.Test(message)
	if err != nil {
		t.Fatal(err)
	}
	if messageResponse.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(messageResponse.Body)
		t.Fatalf("expected local message 200, got %d: %s", messageResponse.StatusCode, body)
	}
	if len(local.requestSeen.Messages) < 2 || local.requestSeen.Messages[0].Role != "system" || local.requestSeen.Messages[len(local.requestSeen.Messages)-1].Content != "Hallo" {
		t.Fatalf("local engine did not receive system prompt and user message: %#v", local.requestSeen.Messages)
	}
	history := httptest.NewRequest(http.MethodGet, "/api/philobot/history/"+created["session_id"].(string), nil)
	historyResponse, err := app.Test(history)
	if err != nil {
		t.Fatal(err)
	}
	var historyBody map[string]interface{}
	if err := json.NewDecoder(historyResponse.Body).Decode(&historyBody); err != nil {
		t.Fatal(err)
	}
	if historyBody["model_ref"] != "local:inst-ready" || historyBody["provider"] != "local" || historyBody["display_name"] != "Qwythos lokal" || historyBody["context_limit"] != float64(8192) {
		t.Fatalf("history lost local model metadata: %#v", historyBody)
	}
}

func TestPhiloBotLocalEngineSessionReportsNotFoundAndNotReady(t *testing.T) {
	for _, tc := range []struct {
		name       string
		err        error
		wantStatus int
		wantCode   string
	}{
		{name: "not found", err: localinference.ErrNotFound, wantStatus: http.StatusNotFound, wantCode: "local_model_not_found"},
		{name: "not ready", err: localinference.ErrNotReady, wantStatus: http.StatusConflict, wantCode: "local_model_not_ready"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			module := New(filepath.Join(t.TempDir(), "settings.json"))
			module.SetLocalModels(&fakeLocalModels{resolveErr: tc.err})
			app := fiber.New()
			module.RegisterRoutes(app.Group("/api"))
			request := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"provider":"local","model_id":"inst-x"}`))
			request.Header.Set("Content-Type", "application/json")
			response, err := app.Test(request)
			if err != nil {
				t.Fatal(err)
			}
			if response.StatusCode != tc.wantStatus {
				t.Fatalf("expected %d, got %d", tc.wantStatus, response.StatusCode)
			}
			body, _ := io.ReadAll(response.Body)
			if !strings.Contains(string(body), tc.wantCode) {
				t.Fatalf("expected code %q in %s", tc.wantCode, body)
			}
		})
	}
}

func TestLocalChatErrorStatusContextLimit(t *testing.T) {
	status, code := localChatErrorStatus(localinference.ErrContextLimit)
	if status != http.StatusUnprocessableEntity || code != "context_length_exceeded" {
		t.Fatalf("unexpected status/code %d %s", status, code)
	}
}

func TestLocalChatErrorStatusResourceAndQueueCodes(t *testing.T) {
	for _, test := range []struct {
		err        error
		wantStatus int
		wantCode   string
	}{
		{localinference.ErrGuardRejected, http.StatusServiceUnavailable, "resource_guard_rejected"},
		{localinference.ErrQueueTimeout, http.StatusGatewayTimeout, "model_queue_timeout"},
		{localinference.ErrWarmupCanceled, http.StatusConflict, "model_warmup_canceled"},
		{localinference.ErrInferenceBusy, http.StatusTooManyRequests, "local_inference_busy"},
		{errPhiloBotSessionBusy, http.StatusTooManyRequests, "session_busy"},
	} {
		status, code := localChatErrorStatus(test.err)
		if status != test.wantStatus || code != test.wantCode {
			t.Fatalf("%v => (%d,%s), want (%d,%s)", test.err, status, code, test.wantStatus, test.wantCode)
		}
	}
}

func TestPhiloBotRejectsConcurrentMutationOfSameSession(t *testing.T) {
	local := &blockingLocalModels{
		model:   localinference.Model{InstanceID: "serialized", DisplayName: "Serialized", ContextLimit: 2048},
		started: make(chan struct{}),
		release: make(chan struct{}),
	}
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.SetLocalModels(local)
	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_ref":"local:serialized"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	sessionID := created["session_id"].(string)

	firstDone := make(chan *http.Response, 1)
	firstErr := make(chan error, 1)
	go func() {
		request := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+sessionID+`","message":"first"}`))
		request.Header.Set("Content-Type", "application/json")
		response, requestErr := app.Test(request, 5000)
		if requestErr != nil {
			firstErr <- requestErr
			return
		}
		firstDone <- response
	}()

	select {
	case <-local.started:
	case <-time.After(2 * time.Second):
		t.Fatal("first request did not enter model generation")
	}

	concurrent := httptest.NewRequest(http.MethodPost, "/api/philobot/stream", strings.NewReader(`{"session_id":"`+sessionID+`","message":"duplicate"}`))
	concurrent.Header.Set("Content-Type", "application/json")
	concurrentResponse, err := app.Test(concurrent)
	if err != nil {
		t.Fatal(err)
	}
	if concurrentResponse.StatusCode != http.StatusTooManyRequests || concurrentResponse.Header.Get("Retry-After") != "1" {
		body, _ := io.ReadAll(concurrentResponse.Body)
		t.Fatalf("concurrent status=%d retry-after=%q body=%s", concurrentResponse.StatusCode, concurrentResponse.Header.Get("Retry-After"), body)
	}
	var busyBody map[string]any
	if err := json.NewDecoder(concurrentResponse.Body).Decode(&busyBody); err != nil {
		t.Fatal(err)
	}
	if busyBody["code"] != "session_busy" {
		t.Fatalf("concurrent error=%#v", busyBody)
	}

	close(local.release)
	select {
	case err := <-firstErr:
		t.Fatal(err)
	case response := <-firstDone:
		if response.StatusCode != http.StatusOK {
			body, _ := io.ReadAll(response.Body)
			t.Fatalf("first request status=%d: %s", response.StatusCode, body)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("first request did not finish after release")
	}

	history := httptest.NewRequest(http.MethodGet, "/api/philobot/history/"+sessionID, nil)
	historyResponse, err := app.Test(history)
	if err != nil {
		t.Fatal(err)
	}
	var historyBody map[string]any
	if err := json.NewDecoder(historyResponse.Body).Decode(&historyBody); err != nil {
		t.Fatal(err)
	}
	messages, _ := historyBody["messages"].([]any)
	if len(messages) != 2 {
		t.Fatalf("busy request mutated history: %#v", historyBody["messages"])
	}
}

func TestPhiloBotInferenceBusyReturnsRetryAfter(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.SetLocalModels(&fakeLocalModels{
		model:     localinference.Model{InstanceID: "busy", DisplayName: "Busy", ContextLimit: 2048},
		streamErr: localinference.ErrInferenceBusy,
	})
	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_ref":"local:busy"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	message := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"hello"}`))
	message.Header.Set("Content-Type", "application/json")
	response, err := app.Test(message)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusTooManyRequests || response.Header.Get("Retry-After") != "120" {
		t.Fatalf("status=%d retry-after=%q", response.StatusCode, response.Header.Get("Retry-After"))
	}
}

func TestPhiloBotAPI_CreateMessageAndHistory(t *testing.T) {
	module := New()
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest(
		"POST",
		"/api/philobot/session",
		strings.NewReader(`{"model_id":"philobot-v1"}`),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq)
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	if createResp.StatusCode != 200 {
		t.Fatalf("expected create session 200, got %d", createResp.StatusCode)
	}

	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create session failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)
	if createBody["status"] != "created" {
		t.Fatalf("expected status created, got %v", createBody["status"])
	}

	messageReq := httptest.NewRequest(
		"POST",
		"/api/philobot/message",
		strings.NewReader(`{"session_id":"`+sessionID+`","message":"Hallo"}`),
	)
	messageReq.Header.Set("Content-Type", "application/json")
	messageResp, err := app.Test(messageReq)
	if err != nil {
		t.Fatalf("message failed: %v", err)
	}
	if messageResp.StatusCode != 200 {
		t.Fatalf("expected message 200, got %d", messageResp.StatusCode)
	}

	var messageBody map[string]interface{}
	if err := json.NewDecoder(messageResp.Body).Decode(&messageBody); err != nil {
		t.Fatalf("decode message failed: %v", err)
	}
	if messageBody["reply"] == "" {
		t.Fatalf("expected non-empty reply")
	}

	historyReq := httptest.NewRequest("GET", "/api/philobot/history/"+sessionID, nil)
	historyResp, err := app.Test(historyReq)
	if err != nil {
		t.Fatalf("history failed: %v", err)
	}
	if historyResp.StatusCode != 200 {
		t.Fatalf("expected history 200, got %d", historyResp.StatusCode)
	}

	var historyBody map[string]interface{}
	if err := json.NewDecoder(historyResp.Body).Decode(&historyBody); err != nil {
		t.Fatalf("decode history failed: %v", err)
	}
	if len(historyBody["messages"].([]interface{})) != 2 {
		t.Fatalf("expected 2 history entries")
	}
}

func TestPhiloBotAPI_InvalidMessage(t *testing.T) {
	module := New()
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	req := httptest.NewRequest(
		"POST",
		"/api/philobot/message",
		strings.NewReader(`{"session_id":"","message":""}`),
	)
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("invalid message request failed: %v", err)
	}
	if resp.StatusCode != 400 {
		t.Fatalf("expected 400, got %d", resp.StatusCode)
	}
}

func TestPhiloBotAPI_EditMessageTruncatesHistoryAndRegenerates(t *testing.T) {
	module := New()
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest(
		"POST",
		"/api/philobot/session",
		strings.NewReader(`{"model_id":"philobot-v1"}`),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq)
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create session failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)

	for _, msg := range []string{"erste frage", "zweite frage"} {
		req := httptest.NewRequest(
			"POST",
			"/api/philobot/message",
			strings.NewReader(`{"session_id":"`+sessionID+`","message":"`+msg+`"}`),
		)
		req.Header.Set("Content-Type", "application/json")
		resp, err := app.Test(req)
		if err != nil {
			t.Fatalf("message failed: %v", err)
		}
		if resp.StatusCode != 200 {
			t.Fatalf("expected message 200, got %d", resp.StatusCode)
		}
	}

	editReq := httptest.NewRequest(
		"POST",
		"/api/philobot/message",
		strings.NewReader(`{"session_id":"`+sessionID+`","message":"bearbeitete frage","edit_message_index":0}`),
	)
	editReq.Header.Set("Content-Type", "application/json")
	editResp, err := app.Test(editReq)
	if err != nil {
		t.Fatalf("edit message failed: %v", err)
	}
	if editResp.StatusCode != 200 {
		t.Fatalf("expected edit 200, got %d", editResp.StatusCode)
	}

	historyReq := httptest.NewRequest("GET", "/api/philobot/history/"+sessionID, nil)
	historyResp, err := app.Test(historyReq)
	if err != nil {
		t.Fatalf("history failed: %v", err)
	}
	var historyBody map[string]interface{}
	if err := json.NewDecoder(historyResp.Body).Decode(&historyBody); err != nil {
		t.Fatalf("decode history failed: %v", err)
	}
	messages := historyBody["messages"].([]interface{})
	if len(messages) != 2 {
		t.Fatalf("expected truncated history with 2 entries, got %d", len(messages))
	}
	user := messages[0].(map[string]interface{})
	if user["content"] != "bearbeitete frage" {
		t.Fatalf("expected edited first message, got %#v", user["content"])
	}
}

func TestPhiloBotAPI_StreamActiveOpenRouterModel(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/chat/completions" {
			http.NotFound(w, r)
			return
		}
		if r.Header.Get("Authorization") != "Bearer mock-token" {
			t.Fatalf("unexpected authorization header %q", r.Header.Get("Authorization"))
		}
		body, _ := io.ReadAll(r.Body)
		if !strings.Contains(string(body), "Thinking: Dual") || !strings.Contains(string(body), "Stil: Kritisch") {
			t.Fatalf("expected thinking/style instructions in provider payload, got %s", string(body))
		}
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\"Hallo\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\" Welt\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"openrouter_token":"mock-token"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	module.orAPIBase = providerServer.URL
	if err := module.botStore.SaveBot(BotConfig{
		ID:            "critic",
		Name:          "Critic",
		SystemPrompt:  "Du bist ein kritischer Bot.",
		Keywords:      []string{"hi"},
		ResponseStyle: "critical",
	}); err != nil {
		t.Fatalf("save critical bot failed: %v", err)
	}
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("start active model failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest(
		"POST",
		"/api/philobot/session",
		strings.NewReader(`{"model_ref":"`+active.ModelRef+`"}`),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq, 5000)
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	if createResp.StatusCode != 200 {
		t.Fatalf("expected create session 200, got %d", createResp.StatusCode)
	}
	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create session failed: %v", err)
	}
	sessionID, _ := createBody["session_id"].(string)

	streamReq := httptest.NewRequest(
		"POST",
		"/api/philobot/stream",
		strings.NewReader(`{"session_id":"`+sessionID+`","message":"Hi","thinking_level":"deep","response_style":"critical"}`),
	)
	streamReq.Header.Set("Content-Type", "application/json")
	streamResp, err := app.Test(streamReq, 5000)
	if err != nil {
		t.Fatalf("stream request failed: %v", err)
	}
	if streamResp.StatusCode != 200 {
		t.Fatalf("expected stream 200, got %d", streamResp.StatusCode)
	}
	streamBody, _ := io.ReadAll(streamResp.Body)
	if !strings.Contains(string(streamBody), "text_delta") || !strings.Contains(string(streamBody), `"chunk":"H"`) {
		t.Fatalf("expected text deltas in SSE body, got %s", string(streamBody))
	}

	historyReq := httptest.NewRequest("GET", "/api/philobot/history/"+sessionID, nil)
	historyResp, err := app.Test(historyReq, 5000)
	if err != nil {
		t.Fatalf("history failed: %v", err)
	}
	var historyBody map[string]interface{}
	if err := json.NewDecoder(historyResp.Body).Decode(&historyBody); err != nil {
		t.Fatalf("decode history failed: %v", err)
	}
	messages := historyBody["messages"].([]interface{})
	if len(messages) != 2 {
		t.Fatalf("expected 2 history messages, got %d", len(messages))
	}
	assistant := messages[1].(map[string]interface{})
	if assistant["content"] != "Hallo Welt" {
		t.Fatalf("expected streamed reply in history, got %#v", assistant["content"])
	}
}

func TestPhiloBotAPI_StreamProviderErrorDoesNotSaveAssistantReply(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "model unavailable", http.StatusNotFound)
	}))
	defer providerServer.Close()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"openrouter_token":"mock-token"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	module.orAPIBase = providerServer.URL
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("start active model failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest(
		"POST",
		"/api/philobot/session",
		strings.NewReader(`{"model_ref":"`+active.ModelRef+`"}`),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq, 5000)
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)

	streamReq := httptest.NewRequest(
		"POST",
		"/api/philobot/stream",
		strings.NewReader(`{"session_id":"`+sessionID+`","message":"Hi"}`),
	)
	streamReq.Header.Set("Content-Type", "application/json")
	streamResp, err := app.Test(streamReq, 5000)
	if err != nil {
		t.Fatalf("stream request failed: %v", err)
	}
	streamBody, _ := io.ReadAll(streamResp.Body)
	if !strings.Contains(string(streamBody), "error") {
		t.Fatalf("expected SSE error, got %s", string(streamBody))
	}
	if !strings.Contains(string(streamBody), `"code":"provider_error"`) || strings.Contains(string(streamBody), "model_binding_missing") {
		t.Fatalf("unbound provider 404 must remain provider_error, got %s", string(streamBody))
	}

	historyReq := httptest.NewRequest("GET", "/api/philobot/history/"+sessionID, nil)
	historyResp, err := app.Test(historyReq, 5000)
	if err != nil {
		t.Fatalf("history failed: %v", err)
	}
	var historyBody map[string]interface{}
	if err := json.NewDecoder(historyResp.Body).Decode(&historyBody); err != nil {
		t.Fatalf("decode history failed: %v", err)
	}
	if len(historyBody["messages"].([]interface{})) != 0 {
		t.Fatalf("expected no persisted messages after provider error")
	}
}

func TestPhiloBotAPI_StreamOpenRouterUserNotFoundShowsActionableError(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = io.WriteString(w, `{"error":{"message":"User not found.","code":401}}`)
	}))
	defer providerServer.Close()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"openrouter_token":"mock-token"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	module.orAPIBase = providerServer.URL
	active, err := module.activeModels.Start("openrouter", "google/gemma-4-26b-a4b-it:free", "Gemma")
	if err != nil {
		t.Fatalf("start active model failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest(
		"POST",
		"/api/philobot/session",
		strings.NewReader(`{"model_ref":"`+active.ModelRef+`"}`),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq, 5000)
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)

	streamReq := httptest.NewRequest(
		"POST",
		"/api/philobot/stream",
		strings.NewReader(`{"session_id":"`+sessionID+`","message":"Hi"}`),
	)
	streamReq.Header.Set("Content-Type", "application/json")
	streamResp, err := app.Test(streamReq, 5000)
	if err != nil {
		t.Fatalf("stream request failed: %v", err)
	}
	streamBody, _ := io.ReadAll(streamResp.Body)
	body := string(streamBody)
	if !strings.Contains(body, "OpenRouter API-Key ist ungueltig oder gehoert zu keinem OpenRouter-Konto") {
		t.Fatalf("expected actionable OpenRouter error, got %s", body)
	}
	if strings.Contains(body, "User not found.") {
		t.Fatalf("expected raw provider JSON to be hidden, got %s", body)
	}
}

func TestPhiloBotAPI_BotBuilderAutoSavesGeneratedBotAndHidesMarker(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/chat/completions" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/event-stream")
		reply := `Erstellt. Du findest den Bot jetzt in der Verwaltung.
[SAVE_BOT: {"name":"EhrlichBot","system_prompt":"Du bist ein direkter Devil-Advocate. Zerlege schwache Argumente sachlich und gib konkrete Verbesserungen.","keywords":["ehrlich","devil advocate","kritik"],"is_default":false}]`
		_, _ = io.WriteString(w, `data: {"choices":[{"delta":{"content":`+strconv.Quote(reply)+`}}]}`+"\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"openrouter_token":"mock-token"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	module.orAPIBase = providerServer.URL
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("start active model failed: %v", err)
	}
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest(
		"POST",
		"/api/philobot/session",
		strings.NewReader(`{"model_ref":"`+active.ModelRef+`"}`),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq, 5000)
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create session failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)

	streamReq := httptest.NewRequest(
		"POST",
		"/api/philobot/stream",
		strings.NewReader(`{"session_id":"`+sessionID+`","message":"botbuilder bau mir einen ehrlichen devil advocate"}`),
	)
	streamReq.Header.Set("Content-Type", "application/json")
	streamResp, err := app.Test(streamReq, 5000)
	if err != nil {
		t.Fatalf("stream request failed: %v", err)
	}
	streamBodyBytes, _ := io.ReadAll(streamResp.Body)
	streamBody := string(streamBodyBytes)
	if strings.Contains(streamBody, "SAVE_BOT") {
		t.Fatalf("expected hidden save marker, got %s", streamBody)
	}
	if strings.Contains(streamBody, `"chunk":"Erstellt.`) {
		t.Fatalf("expected character deltas instead of one full message delta, got %s", streamBody)
	}
	firstCharacterIdx := strings.Index(streamBody, `"chunk":"E"`)
	createdIdx := strings.Index(streamBody, "bot_created")
	if firstCharacterIdx == -1 || createdIdx == -1 || firstCharacterIdx > createdIdx {
		t.Fatalf("expected bot_created event and character deltas, got %s", streamBody)
	}

	getReq := httptest.NewRequest("GET", "/api/philobot/bots", nil)
	getResp, err := app.Test(getReq)
	if err != nil {
		t.Fatalf("get bots failed: %v", err)
	}
	var getBody map[string]interface{}
	if err := json.NewDecoder(getResp.Body).Decode(&getBody); err != nil {
		t.Fatalf("decode get bots failed: %v", err)
	}
	found := false
	for _, item := range getBody["bots"].([]interface{}) {
		bot := item.(map[string]interface{})
		if bot["name"] == "EhrlichBot" {
			found = true
			break
		}
	}
	if !found {
		t.Fatalf("expected generated bot in management, got %#v", getBody["bots"])
	}
}

func TestPhiloBotAPI_BotsManagementAndKeywordRouting(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	// 1. Get bots list (should contain at least default philobot)
	getReq := httptest.NewRequest("GET", "/api/philobot/bots", nil)
	getResp, err := app.Test(getReq)
	if err != nil {
		t.Fatalf("get bots failed: %v", err)
	}
	if getResp.StatusCode != 200 {
		t.Fatalf("expected get bots 200, got %d", getResp.StatusCode)
	}
	var getBody map[string]interface{}
	if err := json.NewDecoder(getResp.Body).Decode(&getBody); err != nil {
		t.Fatalf("decode get bots failed: %v", err)
	}
	botsList, ok := getBody["bots"].([]interface{})
	if !ok || len(botsList) == 0 {
		t.Fatalf("expected bots list to be non-empty")
	}

	// 2. Create a new custom bot
	customBotJSON := `{"id":"mathbot","name":"MathBot","system_prompt":"Du bist ein Mathe-Experte.","keywords":["mathe","rechnen"]}`
	postReq := httptest.NewRequest("POST", "/api/philobot/bots", strings.NewReader(customBotJSON))
	postReq.Header.Set("Content-Type", "application/json")
	postResp, err := app.Test(postReq)
	if err != nil {
		t.Fatalf("save bot failed: %v", err)
	}
	if postResp.StatusCode != 200 {
		t.Fatalf("expected save bot 200, got %d", postResp.StatusCode)
	}

	// 3. Create session and test message keyword routing (non-streaming)
	createReq := httptest.NewRequest("POST", "/api/philobot/session", strings.NewReader(`{"model_id":"mock"}`))
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq)
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	var createBody map[string]interface{}
	_ = json.NewDecoder(createResp.Body).Decode(&createBody)
	sessionID := createBody["session_id"].(string)

	// Message with keyword "mathe" should trigger "mathbot"
	messageReq := httptest.NewRequest(
		"POST",
		"/api/philobot/message",
		strings.NewReader(`{"session_id":"`+sessionID+`","message":"Kannst du mir bei Mathe helfen?"}`),
	)
	messageReq.Header.Set("Content-Type", "application/json")
	messageResp, err := app.Test(messageReq)
	if err != nil {
		t.Fatalf("message request failed: %v", err)
	}
	var messageBody map[string]interface{}
	_ = json.NewDecoder(messageResp.Body).Decode(&messageBody)
	if messageBody["bot_id"] != "mathbot" {
		t.Errorf("expected bot_id to be 'mathbot', got %v", messageBody["bot_id"])
	}
	if messageBody["bot_name"] != "MathBot" {
		t.Errorf("expected bot_name to be 'MathBot', got %v", messageBody["bot_name"])
	}

	// 4. Delete the custom bot
	deleteReq := httptest.NewRequest("DELETE", "/api/philobot/bots/mathbot", nil)
	deleteResp, err := app.Test(deleteReq)
	if err != nil {
		t.Fatalf("delete bot failed: %v", err)
	}
	if deleteResp.StatusCode != 200 {
		t.Fatalf("expected delete bot 200, got %d", deleteResp.StatusCode)
	}
}

func TestPhiloBotAPI_BotBuilderIsLocked(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	lockedBotJSON := `{"id":"botbuilder","name":"Bot-Builder","system_prompt":"Manipulated prompt","keywords":["locked"],"response_style":"critical"}`
	postReq := httptest.NewRequest("POST", "/api/philobot/bots", strings.NewReader(lockedBotJSON))
	postReq.Header.Set("Content-Type", "application/json")
	postResp, err := app.Test(postReq)
	if err != nil {
		t.Fatalf("save locked bot failed: %v", err)
	}
	if postResp.StatusCode != 403 {
		t.Fatalf("expected save locked bot 403, got %d", postResp.StatusCode)
	}

	getReq := httptest.NewRequest("GET", "/api/philobot/bots", nil)
	getResp, err := app.Test(getReq)
	if err != nil {
		t.Fatalf("get bots failed: %v", err)
	}
	var getBody map[string]interface{}
	if err := json.NewDecoder(getResp.Body).Decode(&getBody); err != nil {
		t.Fatalf("decode get bots failed: %v", err)
	}

	found := false
	for _, item := range getBody["bots"].([]interface{}) {
		bot := item.(map[string]interface{})
		if bot["id"] == "botbuilder" {
			found = true
			prompt, _ := bot["system_prompt"].(string)
			if !strings.Contains(prompt, "gesperrt") {
				t.Fatalf("expected default locked botbuilder prompt, got %q", prompt)
			}
			break
		}
	}
	if !found {
		t.Fatalf("expected botbuilder in bots list")
	}
}

func TestPhiloBotHandlersIsolateBotsAndSessionsByJWTUser(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error {
		if userID := c.Get("X-Test-User"); userID != "" {
			c.Locals("user_id", userID)
		}
		return c.Next()
	})
	module.RegisterRoutes(app.Group("/api"))

	save := httptest.NewRequest(http.MethodPost, "/api/philobot/bots", strings.NewReader(`{"id":"alice-only","name":"Alice Only","system_prompt":"secret","keywords":["alice"]}`))
	save.Header.Set("Content-Type", "application/json")
	save.Header.Set("X-Test-User", "Alice")
	saveResponse, err := app.Test(save)
	if err != nil || saveResponse.StatusCode != http.StatusOK {
		t.Fatalf("alice save status=%v err=%v", saveResponse.StatusCode, err)
	}

	bobList := httptest.NewRequest(http.MethodGet, "/api/philobot/bots", nil)
	bobList.Header.Set("X-Test-User", "bob")
	bobResponse, err := app.Test(bobList)
	if err != nil {
		t.Fatal(err)
	}
	bobBody, _ := io.ReadAll(bobResponse.Body)
	if strings.Contains(string(bobBody), "alice-only") {
		t.Fatalf("alice bot leaked into bob namespace: %s", bobBody)
	}

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_id":"stub"}`))
	create.Header.Set("Content-Type", "application/json")
	create.Header.Set("X-Test-User", "ALICE")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	sessionID := created["session_id"].(string)

	for _, request := range []*http.Request{
		httptest.NewRequest(http.MethodGet, "/api/philobot/history/"+sessionID, nil),
		httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+sessionID+`","message":"steal"}`)),
		httptest.NewRequest(http.MethodPost, "/api/philobot/stream", strings.NewReader(`{"session_id":"`+sessionID+`","message":"steal"}`)),
	} {
		request.Header.Set("Content-Type", "application/json")
		request.Header.Set("X-Test-User", "bob")
		response, err := app.Test(request)
		if err != nil {
			t.Fatal(err)
		}
		if response.StatusCode != http.StatusNotFound {
			t.Fatalf("cross-user %s status=%d, want 404", request.URL.Path, response.StatusCode)
		}
	}

	aliceMessage := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+sessionID+`","message":"same account despite case"}`))
	aliceMessage.Header.Set("Content-Type", "application/json")
	aliceMessage.Header.Set("X-Test-User", "alice")
	aliceResponse, err := app.Test(aliceMessage)
	if err != nil {
		t.Fatal(err)
	}
	if aliceResponse.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(aliceResponse.Body)
		t.Fatalf("lowercase owner status=%d: %s", aliceResponse.StatusCode, body)
	}
}

func TestLockedBotLocalBindingWarmsAndForwardsOriginalMessageOnce(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	local := &fakeWarmupLocalModels{model: localinference.Model{
		InstanceID: "inst-warm", ModelID: "catalog", DisplayName: "Warm Local", ContextLimit: 4096,
	}}
	module := New(settingsPath)
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	if err := module.botStore.SaveBotForUser("alice", BotConfig{
		ID: "bound", Name: "Bound", SystemPrompt: "bound prompt",
		ModelBinding: &ModelBinding{Kind: "local", InstanceID: "inst-warm", DisplayName: "Warm Local"},
	}); err != nil {
		t.Fatal(err)
	}
	if err := module.botStore.SaveBotForUser("alice", BotConfig{
		ID: "rival", Name: "Rival", SystemPrompt: "rival prompt", Keywords: []string{"switch-now"},
	}); err != nil {
		t.Fatal(err)
	}

	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "Alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))
	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"bot_id":"bound","model_id":"ignored"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	if createResponse.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(createResponse.Body)
		t.Fatalf("create status=%d: %s", createResponse.StatusCode, body)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	if created["locked_bot_id"] != "bound" || created["provider"] != "local" {
		t.Fatalf("locked binding missing from session: %#v", created)
	}

	original := "switch-now but stay locked"
	stream := httptest.NewRequest(http.MethodPost, "/api/philobot/stream", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"`+original+`"}`))
	stream.Header.Set("Content-Type", "application/json")
	streamResponse, err := app.Test(stream, 5000)
	if err != nil {
		t.Fatal(err)
	}
	streamBody, _ := io.ReadAll(streamResponse.Body)
	if !strings.Contains(string(streamBody), "event: model_warmup") || !strings.Contains(string(streamBody), `"placement":"gpu"`) {
		t.Fatalf("warmup progress missing from SSE: %s", streamBody)
	}
	if !strings.Contains(string(streamBody), `"id":"bound"`) || strings.Contains(string(streamBody), `"id":"rival"`) {
		t.Fatalf("locked bot was overridden by keyword: %s", streamBody)
	}
	local.mu.Lock()
	ensureCalls := local.ensureCalls
	streamCalls := local.streamCalls
	seen := append([]string(nil), local.seenUserMessages...)
	local.mu.Unlock()
	if ensureCalls != 1 || streamCalls != 1 {
		t.Fatalf("ensure=%d stream=%d, want exactly one each", ensureCalls, streamCalls)
	}
	if len(seen) != 1 || seen[0] != original {
		t.Fatalf("original message was not forwarded exactly once: %#v", seen)
	}

	history := httptest.NewRequest(http.MethodGet, "/api/philobot/history/"+created["session_id"].(string), nil)
	historyResponse, err := app.Test(history)
	if err != nil {
		t.Fatal(err)
	}
	var historyBody map[string]any
	if err := json.NewDecoder(historyResponse.Body).Decode(&historyBody); err != nil {
		t.Fatal(err)
	}
	if historyBody["model_ref"] != "local:inst-warm" || historyBody["display_name"] != "Warm Local" || historyBody["context_limit"] != float64(4096) {
		t.Fatalf("effective bound model metadata not persisted in session: %#v", historyBody)
	}
}

func TestAgenticLockedLocalBindingUsesWarmupPipeline(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	local := &fakeWarmupLocalModels{model: localinference.Model{
		InstanceID: "agentic-local", DisplayName: "Agentic Local", ContextLimit: 4096,
	}}
	module := New(settingsPath)
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	if err := module.botStore.SaveBotForUser("alice", BotConfig{
		ID: "agentic-bound", Name: "Agentic Bound", SystemPrompt: "bound",
		ModelBinding: &ModelBinding{Kind: "local", InstanceID: "agentic-local"},
	}); err != nil {
		t.Fatal(err)
	}

	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))
	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"bot_id":"agentic-bound"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	if createResponse.StatusCode != http.StatusOK {
		t.Fatalf("create status=%d: %#v", createResponse.StatusCode, created)
	}

	original := "agentic must honor binding"
	stream := httptest.NewRequest(http.MethodPost, "/api/philobot/stream", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"`+original+`","thinking_level":"agentic"}`))
	stream.Header.Set("Content-Type", "application/json")
	streamResponse, err := app.Test(stream, 5000)
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(streamResponse.Body)
	streamText := string(body)
	if !strings.Contains(streamText, "event: model_warmup") || !strings.Contains(streamText, "event: text_delta") || !strings.Contains(streamText, "event: done") {
		t.Fatalf("bound agentic SSE contract incomplete: %s", streamText)
	}
	local.mu.Lock()
	ensureCalls := local.ensureCalls
	streamCalls := local.streamCalls
	seen := append([]string(nil), local.seenUserMessages...)
	local.mu.Unlock()
	if ensureCalls != 1 || streamCalls != 1 || len(seen) != 1 || seen[0] != original {
		t.Fatalf("bound agentic forwarding ensure=%d stream=%d seen=%#v", ensureCalls, streamCalls, seen)
	}
}

func TestAgenticMissingLockedBindingReturnsStructuredError(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	local := &fakeWarmupLocalModels{ready: true, model: localinference.Model{
		InstanceID: "bound-then-removed", DisplayName: "Removed", ContextLimit: 4096,
	}}
	module := New(settingsPath)
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	if err := module.botStore.SaveBotForUser("alice", BotConfig{
		ID: "removed-bound", Name: "Removed Bound", SystemPrompt: "bound",
		ModelBinding: &ModelBinding{Kind: "local", InstanceID: "bound-then-removed"},
	}); err != nil {
		t.Fatal(err)
	}

	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))
	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"bot_id":"removed-bound"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	local.mu.Lock()
	local.model.InstanceID = "different-instance"
	local.mu.Unlock()

	stream := httptest.NewRequest(http.MethodPost, "/api/philobot/stream", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"hello","thinking_level":"agentic"}`))
	stream.Header.Set("Content-Type", "application/json")
	streamResponse, err := app.Test(stream, 5000)
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(streamResponse.Body)
	streamText := string(body)
	if !strings.Contains(streamText, `"code":"model_binding_missing"`) || !strings.Contains(streamText, `"status":404`) {
		t.Fatalf("missing bound model did not produce structured agentic error: %s", streamText)
	}
	if strings.Contains(streamText, "warm reply") {
		t.Fatalf("missing binding silently fell through: %s", streamText)
	}
}

func TestPersistedInvalidBindingReturnsStructuredSessionError(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	stored := botStoreFile{
		Version: botStoreSchemaVersion,
		Users: map[string]botStoreUser{
			"alice": {Bots: []BotConfig{{
				ID: "invalid-bound", Name: "Invalid Bound", SystemPrompt: "bound", ResponseStyle: "balanced",
				ModelBinding: &ModelBinding{Kind: "api", Provider: "removed-provider", ModelID: "vendor/model"},
			}}},
		},
	}
	payload, err := json.Marshal(stored)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(tmpDir, "bots.json"), payload, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}

	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))
	request := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"bot_id":"invalid-bound"}`))
	request.Header.Set("Content-Type", "application/json")
	response, err := app.Test(request)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusUnprocessableEntity {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("invalid persisted binding status=%d: %s", response.StatusCode, body)
	}
	var body map[string]any
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	if body["code"] != "model_binding_invalid" {
		t.Fatalf("invalid persisted binding code=%v", body["code"])
	}
	bot, _ := module.botStore.GetBotForUser("alice", "invalid-bound")
	if bot.ModelBinding == nil || bot.ModelBinding.Provider != "removed-provider" {
		t.Fatalf("request-time validation erased persisted binding: %#v", bot.ModelBinding)
	}
}

func TestAutomaticKeywordInvalidBindingAnnouncesBotBeforeError(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	stored := botStoreFile{
		Version: botStoreSchemaVersion,
		Users: map[string]botStoreUser{
			"alice": {Bots: []BotConfig{{
				ID: "invalid-keyword", Name: "Invalid Keyword", SystemPrompt: "bound", Keywords: []string{"route-invalid"}, ResponseStyle: "balanced",
				ModelBinding: &ModelBinding{Kind: "api", Provider: "removed-provider", ModelID: "vendor/model"},
			}}},
		},
	}
	payload, err := json.Marshal(stored)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(tmpDir, "bots.json"), payload, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_id":"stub"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}

	stream := httptest.NewRequest(http.MethodPost, "/api/philobot/stream", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"route-invalid now"}`))
	stream.Header.Set("Content-Type", "application/json")
	streamResponse, err := app.Test(stream, 5000)
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(streamResponse.Body)
	text := string(body)
	selectedIndex := strings.Index(text, `"type":"bot_selected"`)
	errorIndex := strings.Index(text, `"code":"model_binding_invalid"`)
	if selectedIndex < 0 || !strings.Contains(text, `"id":"invalid-keyword"`) || errorIndex <= selectedIndex {
		t.Fatalf("bot identity must precede binding error: %s", text)
	}
}

func TestAutomaticKeywordBotSwitchesEffectiveSessionModel(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	local := &fakeWarmupLocalModels{model: localinference.Model{
		InstanceID: "keyword-local", DisplayName: "Keyword Local", ContextLimit: 3072,
	}}
	module := New(settingsPath)
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	if err := module.botStore.SaveBotForUser("alice", BotConfig{
		ID: "keyword-bound", Name: "Keyword Bound", SystemPrompt: "bound",
		Keywords:     []string{"use-keyword-model"},
		ModelBinding: &ModelBinding{Kind: "local", InstanceID: "keyword-local"},
	}); err != nil {
		t.Fatal(err)
	}
	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))
	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_id":"normal-selection"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	if _, locked := created["locked_bot_id"]; locked {
		t.Fatalf("automatic session was unexpectedly locked: %#v", created)
	}
	message := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"please use-keyword-model"}`))
	message.Header.Set("Content-Type", "application/json")
	messageResponse, err := app.Test(message)
	if err != nil {
		t.Fatal(err)
	}
	if messageResponse.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(messageResponse.Body)
		t.Fatalf("message status=%d: %s", messageResponse.StatusCode, body)
	}
	history := httptest.NewRequest(http.MethodGet, "/api/philobot/history/"+created["session_id"].(string), nil)
	historyResponse, err := app.Test(history)
	if err != nil {
		t.Fatal(err)
	}
	var historyBody map[string]any
	if err := json.NewDecoder(historyResponse.Body).Decode(&historyBody); err != nil {
		t.Fatal(err)
	}
	if historyBody["active_bot_id"] != "keyword-bound" || historyBody["model_ref"] != "local:keyword-local" || historyBody["context_limit"] != float64(3072) {
		t.Fatalf("keyword binding did not switch effective session model: %#v", historyBody)
	}
}

func TestAPIBoundBotRoutesDirectlyToBoundModel(t *testing.T) {
	var requestBody string
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		requestBody = string(body)
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\"bound api reply\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"openrouter_token":"token"}`), 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	module.orAPIBase = providerServer.URL
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	if err := module.botStore.SaveBotForUser("alice", BotConfig{
		ID: "api-bound", Name: "API Bound", SystemPrompt: "api bound",
		ModelBinding: &ModelBinding{Kind: "api", Provider: "openrouter", ModelID: "vendor/bound-model", DisplayName: "Bound Model"},
	}); err != nil {
		t.Fatal(err)
	}
	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"bot_id":"api-bound","provider":"featherless","model_id":"ignored/model"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	if created["provider"] != "openrouter" || created["model_id"] != "vendor/bound-model" {
		t.Fatalf("API binding did not override request model: %#v", created)
	}

	message := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"hello"}`))
	message.Header.Set("Content-Type", "application/json")
	messageResponse, err := app.Test(message, 5000)
	if err != nil {
		t.Fatal(err)
	}
	if messageResponse.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(messageResponse.Body)
		t.Fatalf("message status=%d: %s", messageResponse.StatusCode, body)
	}
	if !strings.Contains(requestBody, `"model":"vendor/bound-model"`) || strings.Contains(requestBody, "ignored/model") {
		t.Fatalf("provider received wrong model: %s", requestBody)
	}
}

func TestAPIBoundBotProviderNotFoundReturnsStructuredMissingBinding(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		_, _ = io.WriteString(w, `{"error":{"message":"model not found"}}`)
	}))
	defer providerServer.Close()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"openrouter_token":"token"}`), 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	module.orAPIBase = providerServer.URL
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	if err := module.botStore.SaveBotForUser("alice", BotConfig{
		ID: "missing-api", Name: "Missing API", SystemPrompt: "bound",
		ModelBinding: &ModelBinding{Kind: "api", Provider: "openrouter", ModelID: "vendor/missing"},
	}); err != nil {
		t.Fatal(err)
	}
	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error { c.Locals("user_id", "alice"); return c.Next() })
	module.RegisterRoutes(app.Group("/api"))

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"bot_id":"missing-api"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]any
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	message := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"hello"}`))
	message.Header.Set("Content-Type", "application/json")
	response, err := app.Test(message, 5000)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("message status=%d, want 404: %s", response.StatusCode, body)
	}
	var body map[string]any
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	if body["code"] != "model_binding_missing" {
		t.Fatalf("error code=%v, want model_binding_missing", body["code"])
	}
}

func TestReadOpenAIStreamBuffersSplitUTF8Chunks(t *testing.T) {
	stream := []byte("data: {\"choices\":[{\"delta\":{\"content\":\"Hallo 🚀 Welt\"}}]}\n\ndata: [DONE]\n\n")
	splitIndex := bytes.Index(stream, []byte("🚀"))
	if splitIndex < 0 {
		t.Fatalf("expected rocket emoji in test stream")
	}
	reader := io.MultiReader(
		bytes.NewReader(stream[:splitIndex+1]),
		bytes.NewReader(stream[splitIndex+1:]),
	)

	reply, err := readOpenAIStream(reader, nil, nil)
	if err != nil {
		t.Fatalf("readOpenAIStream failed: %v", err)
	}
	if reply != "Hallo 🚀 Welt" {
		t.Fatalf("expected utf-8 safe reply, got %q", reply)
	}
}

func TestReadOpenAIStreamParsesMultilineSSEDataBlocks(t *testing.T) {
	stream := strings.NewReader(
		"event: message\n" +
			"data: {\"choices\":[\n" +
			"data: {\"delta\":{\"content\":\"Hallo\"}},\n" +
			"data: {\"delta\":{\"content\":\" Welt\"}}]}\n\n" +
			"data: [DONE]\n\n",
	)

	reply, err := readOpenAIStream(stream, nil, nil)
	if err != nil {
		t.Fatalf("readOpenAIStream failed: %v", err)
	}
	if reply != "Hallo Welt" {
		t.Fatalf("expected multiline SSE payload to decode, got %q", reply)
	}
}

// TestReadOpenAIStreamRoutesNativeReasoningSeparately stellt sicher, dass
// OpenRouters natives "reasoning" Delta-Feld ueber emitReasoning geht und NICHT
// im zurueckgegebenen (sichtbaren/persistierten) Antworttext landet.
func TestReadOpenAIStreamRoutesNativeReasoningSeparately(t *testing.T) {
	stream := strings.NewReader(
		"data: {\"choices\":[{\"delta\":{\"reasoning\":\"Ich ueberlege...\"}}]}\n\n" +
			"data: {\"choices\":[{\"delta\":{\"content\":\"Antwort\"}}]}\n\n" +
			"data: [DONE]\n\n",
	)
	var reasoning strings.Builder
	reply, err := readOpenAIStream(stream, nil, func(chunk string) error {
		reasoning.WriteString(chunk)
		return nil
	})
	if err != nil {
		t.Fatalf("readOpenAIStream failed: %v", err)
	}
	if reply != "Antwort" {
		t.Fatalf("reasoning darf nicht im sichtbaren Reply landen, bekam: %q", reply)
	}
	if reasoning.String() != "Ich ueberlege..." {
		t.Fatalf("unerwarteter Reasoning-Text: %q", reasoning.String())
	}
}

func TestStreamingTextEmitterBuffersIncompleteGraphemeAcrossChunks(t *testing.T) {
	var got []string
	emitter := newStreamingTextEmitter(func(chunk string) error {
		got = append(got, chunk)
		return nil
	})

	if err := emitter.Emit("A👩‍"); err != nil {
		t.Fatalf("Emit first chunk failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "A" {
		t.Fatalf("expected only complete graphemes after first chunk, got %q", joined)
	}

	if err := emitter.Emit("💻B"); err != nil {
		t.Fatalf("Emit second chunk failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "A👩‍💻" {
		t.Fatalf("expected combined grapheme after second chunk, got %q", joined)
	}

	if err := emitter.Flush(); err != nil {
		t.Fatalf("Flush failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "A👩‍💻B" {
		t.Fatalf("expected flushed text, got %q", joined)
	}
}

func TestStreamingTextEmitterBuffersIncompleteUTF8BytesAcrossChunks(t *testing.T) {
	var got []string
	emitter := newStreamingTextEmitter(func(chunk string) error {
		got = append(got, chunk)
		return nil
	})

	if err := emitter.Emit(string([]byte{0xe2, 0x82})); err != nil {
		t.Fatalf("Emit first chunk failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "" {
		t.Fatalf("expected incomplete utf-8 bytes to be buffered, got %q", joined)
	}

	if err := emitter.Emit(string([]byte{0xac, ' ', 'o', 'k'})); err != nil {
		t.Fatalf("Emit second chunk failed: %v", err)
	}
	if err := emitter.Flush(); err != nil {
		t.Fatalf("Flush failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "€ ok" {
		t.Fatalf("expected reconstructed utf-8 sequence, got %q", joined)
	}
}

func TestStreamingTextEmitterDropsInvalidUTF8Bytes(t *testing.T) {
	var got []string
	emitter := newStreamingTextEmitter(func(chunk string) error {
		got = append(got, chunk)
		return nil
	})

	if err := emitter.Emit(string([]byte{'A', 0xff, 'B'})); err != nil {
		t.Fatalf("Emit failed: %v", err)
	}
	if err := emitter.Flush(); err != nil {
		t.Fatalf("Flush failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "AB" {
		t.Fatalf("expected invalid utf-8 byte to be dropped, got %q", joined)
	}
}

func TestBuildRuntimeSystemPromptAvoidsMarkdownCodeFences(t *testing.T) {
	prompt := buildRuntimeSystemPrompt("Du bist PhiloBot.", "medium", "balanced")

	if !strings.Contains(prompt, "Verpacke niemals reines Markdown in einen ```markdown Block") {
		t.Fatalf("expected markdown code-fence instruction in prompt, got %q", prompt)
	}
	if !strings.Contains(prompt, "Listen, Tabellen, Checkboxen") {
		t.Fatalf("expected direct markdown structure instruction in prompt, got %q", prompt)
	}
	if !strings.Contains(prompt, "Verwende niemals Inline-HTML-Tags wie <kbd>, <br>") {
		t.Fatalf("expected inline-html ban in prompt, got %q", prompt)
	}
}

func TestBuildBotRuntimeSystemPromptMakesSelectedBotIdentityAuthoritative(t *testing.T) {
	prompt := buildBotRuntimeSystemPrompt(BotConfig{
		ID:           "mathbot",
		Name:         "MathBot",
		SystemPrompt: "Du hilfst bei Mathematik.",
	}, "medium", "balanced")

	for _, expected := range []string{"Aktiver Bot: MathBot (ID: mathbot)", "ausschliesslich als dieser Bot", "Bezeichne dich nicht als ein allgemeines Basismodell, ChatGPT", "Du hilfst bei Mathematik."} {
		if !strings.Contains(prompt, expected) {
			t.Fatalf("expected bot identity instruction %q in prompt, got %q", expected, prompt)
		}
	}
}

type fakeMemoryProvider struct {
	lastUser    string
	lastProject string
	lastQuery   string
	recall      string
}

func (f *fakeMemoryProvider) PhiloBotMemoryContext(userID, project, query string) string {
	f.lastUser = userID
	f.lastProject = project
	f.lastQuery = query
	return f.recall
}

func TestAppendMemoryRecall(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	base := "SYSTEM-PROMPT"

	// Ohne angebundenes Gedaechtnis bleibt der Prompt unveraendert.
	if got := module.appendMemoryRecall("local", "", "wie heisse ich", base); got != base {
		t.Fatalf("ohne Memory sollte der Prompt unveraendert bleiben, bekam %q", got)
	}

	// Mit Treffer wird der Recall angehaengt und User/Projekt/Query durchgereicht.
	fake := &fakeMemoryProvider{recall: "- Der Nutzer heisst David."}
	module.SetMemory(fake)
	got := module.appendMemoryRecall("david", "proj-42", "wie heisse ich", base)
	if !strings.HasPrefix(got, base) {
		t.Fatalf("Basis-Prompt muss erhalten bleiben: %q", got)
	}
	if !strings.Contains(got, philoBotMemoryPreamble) || !strings.Contains(got, "David") {
		t.Fatalf("Recall wurde nicht angehaengt: %q", got)
	}
	if fake.lastUser != "david" || fake.lastProject != "proj-42" || fake.lastQuery != "wie heisse ich" {
		t.Fatalf("User/Projekt/Query nicht durchgereicht: user=%q project=%q query=%q", fake.lastUser, fake.lastProject, fake.lastQuery)
	}

	// Leerer Recall haengt nichts an.
	fake.recall = "   "
	if got := module.appendMemoryRecall("david", "", "hi", base); got != base {
		t.Fatalf("leerer Recall sollte nichts anhaengen, bekam %q", got)
	}
}

// TestPhiloBotInjectsMemoryRecallIntoLocalModel beweist, dass ein LOKALER Bot
// den nutzerweiten Recall im System-Prompt erhaelt (End-to-End ueber HTTP).
func TestPhiloBotInjectsMemoryRecallIntoLocalModel(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	local := &fakeLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", ModelID: "catalog-id", DisplayName: "Lokal", ContextLimit: 8192,
	}}
	module.SetLocalModels(local)
	module.SetMemory(&fakeMemoryProvider{recall: "- Der Nutzer heißt David."})

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_ref":"local:inst-ready"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]interface{}
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}

	message := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"wie heiße ich"}`))
	message.Header.Set("Content-Type", "application/json")
	if _, err := app.Test(message); err != nil {
		t.Fatal(err)
	}

	if len(local.requestSeen.Messages) == 0 || local.requestSeen.Messages[0].Role != "system" {
		t.Fatalf("kein System-Prompt beim lokalen Modell: %#v", local.requestSeen.Messages)
	}
	system := local.requestSeen.Messages[0].Content
	if !strings.Contains(system, "David") || !strings.Contains(system, philoBotMemoryPreamble) {
		t.Fatalf("Recall nicht im System-Prompt des lokalen Modells: %q", system)
	}
}

// TestPhiloBotInjectsMemoryRecallIntoAPIModel beweist dasselbe fuer einen
// API-Bot (OpenRouter): der Recall landet in der System-Message der Anfrage.
func TestPhiloBotInjectsMemoryRecallIntoAPIModel(t *testing.T) {
	var capturedBody string
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/chat/completions" {
			http.NotFound(w, r)
			return
		}
		body, _ := io.ReadAll(r.Body)
		capturedBody = string(body)
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\"Hallo David\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"openrouter_token":"mock-token"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}
	module := New(settingsPath)
	module.orAPIBase = providerServer.URL
	module.SetMemory(&fakeMemoryProvider{recall: "- Der Nutzer heißt David."})
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("start active model failed: %v", err)
	}

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))

	create := httptest.NewRequest(http.MethodPost, "/api/philobot/session", strings.NewReader(`{"model_ref":"`+active.ModelRef+`"}`))
	create.Header.Set("Content-Type", "application/json")
	createResponse, err := app.Test(create, 5000)
	if err != nil {
		t.Fatal(err)
	}
	var created map[string]interface{}
	if err := json.NewDecoder(createResponse.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}

	message := httptest.NewRequest(http.MethodPost, "/api/philobot/message", strings.NewReader(`{"session_id":"`+created["session_id"].(string)+`","message":"wie heiße ich"}`))
	message.Header.Set("Content-Type", "application/json")
	if _, err := app.Test(message, 5000); err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(capturedBody, "David") || !strings.Contains(capturedBody, philoBotMemoryPreamble) {
		t.Fatalf("Recall nicht in der API-Anfrage: %s", capturedBody)
	}
}

func TestWindowMessagesKeepsMostRecent(t *testing.T) {
	msgs := make([]chatMessage, 0, 30)
	for i := 0; i < 30; i++ {
		msgs = append(msgs, chatMessage{Role: "user", Content: fmt.Sprintf("m%d", i)})
	}
	// Unterhalb des Fensters: alles bleibt.
	if got := windowMessages(msgs[:10], maxModelHistoryMessages); len(got) != 10 {
		t.Fatalf("erwartete 10 Nachrichten, bekam %d", len(got))
	}
	// Oberhalb des Fensters: nur die letzten N, in Reihenfolge.
	got := windowMessages(msgs, maxModelHistoryMessages)
	if len(got) != maxModelHistoryMessages {
		t.Fatalf("erwartete %d Nachrichten, bekam %d", maxModelHistoryMessages, len(got))
	}
	if got[0].Content != fmt.Sprintf("m%d", 30-maxModelHistoryMessages) {
		t.Fatalf("Fenster begann falsch: %q", got[0].Content)
	}
	if got[len(got)-1].Content != "m29" {
		t.Fatalf("Fenster endete falsch: %q", got[len(got)-1].Content)
	}
}

func TestPhiloBotSessionCustomTitlePersists(t *testing.T) {
	settings := filepath.Join(t.TempDir(), "settings.json")
	module := New(settings)
	session := &philoBotSession{
		ID:       "chat-rename-1",
		UserID:   "local",
		Messages: []chatMessage{{Role: "user", Content: "Hallo Welt"}},
	}
	module.mu.Lock()
	module.sessions[session.ID] = session
	module.mu.Unlock()

	// Ohne Custom-Titel wird er aus der ersten Nachricht abgeleitet.
	if got := summarizeSession(session).Title; got != "Hallo Welt" {
		t.Fatalf("abgeleiteter Titel falsch: %q", got)
	}

	// Custom-Titel gewinnt und ueberlebt einen Neustart.
	session.Title = "Mein Projekt"
	module.persistSession(session.ID)
	if got := summarizeSession(session).Title; got != "Mein Projekt" {
		t.Fatalf("Custom-Titel wurde nicht genutzt: %q", got)
	}

	restarted := New(settings)
	restarted.loadPersistedSessions()
	restarted.mu.Lock()
	loaded := restarted.sessions[session.ID]
	restarted.mu.Unlock()
	if loaded == nil || loaded.Title != "Mein Projekt" {
		t.Fatalf("Custom-Titel nicht persistiert: %#v", loaded)
	}
}

func TestPhiloBotSessionPersistenceRoundTrip(t *testing.T) {
	settings := filepath.Join(t.TempDir(), "settings.json")

	first := New(settings)
	session := &philoBotSession{
		ID:          "chat-persist-1",
		UserID:      "local",
		Provider:    "openrouter",
		ModelID:     "model-x",
		DisplayName: "Model X",
		Messages: []chatMessage{
			{Role: "user", Content: "Mein Name ist David"},
			{Role: "assistant", Content: "Hallo David"},
		},
		MutationInFlight: true, // transient – darf nicht persistiert werden
	}
	first.mu.Lock()
	first.sessions[session.ID] = session
	first.mu.Unlock()
	first.persistSession(session.ID)

	// Neustart simulieren: neues Modul, gleicher Ordner.
	second := New(settings)
	second.loadPersistedSessions()
	second.mu.Lock()
	loaded := second.sessions[session.ID]
	second.mu.Unlock()

	if loaded == nil {
		t.Fatalf("Session wurde nach Neustart nicht geladen")
	}
	if len(loaded.Messages) != 2 || loaded.Messages[0].Content != "Mein Name ist David" {
		t.Fatalf("Nachrichten nicht korrekt persistiert: %#v", loaded.Messages)
	}
	if loaded.MutationInFlight {
		t.Fatalf("MutationInFlight darf nicht persistiert werden")
	}
	if loaded.UpdatedAt.IsZero() {
		t.Fatalf("UpdatedAt sollte beim Speichern gesetzt werden")
	}

	summary := summarizeSession(loaded)
	if summary.Title != "Mein Name ist David" {
		t.Fatalf("Titel sollte aus erster Nutzernachricht stammen, war %q", summary.Title)
	}
	if summary.MessageCount != 2 {
		t.Fatalf("MessageCount falsch: %d", summary.MessageCount)
	}

	// Loeschen entfernt die Datei; ein weiterer Neustart findet nichts mehr.
	if err := second.storage.Delete(session.ID); err != nil {
		t.Fatalf("delete fehlgeschlagen: %v", err)
	}
	third := New(settings)
	third.loadPersistedSessions()
	third.mu.Lock()
	_, stillThere := third.sessions[session.ID]
	third.mu.Unlock()
	if stillThere {
		t.Fatalf("geloeschte Session sollte nach Neustart weg sein")
	}
}
