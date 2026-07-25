package philox

import (
	"encoding/json"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"
)

// newTestModule builds a Philox module backed by a temp session store. The agent
// backend was removed, so there is no model client to mock anymore.
func newTestModule(t *testing.T) *PhiloxModule {
	t.Helper()
	storage := newSessionStorage(t.TempDir())
	module := &PhiloxModule{
		store:    newSessionStore(storage),
		executor: newToolExecutor(),
		requests: newSessionRequestRegistry(),
	}
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	return module
}

func TestPhiloxAPI_MessageReportsAgentDisabled(t *testing.T) {
	module := newTestModule(t)

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest("POST", "/api/philox/session", strings.NewReader(`{"mode":"execute"}`))
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq)
	if err != nil {
		t.Fatalf("create failed: %v", err)
	}
	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)

	msgReq := httptest.NewRequest("POST", "/api/philox/message", strings.NewReader(`{"session_id":"`+sessionID+`","message":"Hallo"}`))
	msgReq.Header.Set("Content-Type", "application/json")
	msgResp, err := app.Test(msgReq)
	if err != nil {
		t.Fatalf("message failed: %v", err)
	}
	if msgResp.StatusCode != 500 {
		t.Fatalf("expected 500 for disabled agent, got %d", msgResp.StatusCode)
	}
	var msgBody map[string]interface{}
	if err := json.NewDecoder(msgResp.Body).Decode(&msgBody); err != nil {
		t.Fatalf("decode message failed: %v", err)
	}
	if reason, _ := msgBody["error"].(string); !strings.Contains(reason, "deaktiviert") {
		t.Fatalf("expected disabled error, got %v", msgBody["error"])
	}
}

func TestPhiloxAPI_ListSessionsAndSessionMetadata(t *testing.T) {
	module := newTestModule(t)

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest("POST", "/api/philox/session", strings.NewReader(`{"mode":"plan"}`))
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq)
	if err != nil {
		t.Fatalf("create failed: %v", err)
	}
	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)

	sessionReq := httptest.NewRequest("GET", "/api/philox/session/"+sessionID, nil)
	sessionResp, err := app.Test(sessionReq)
	if err != nil {
		t.Fatalf("session metadata failed: %v", err)
	}
	var sessionBody map[string]interface{}
	if err := json.NewDecoder(sessionResp.Body).Decode(&sessionBody); err != nil {
		t.Fatalf("decode session failed: %v", err)
	}
	if sessionBody["mode"] != "plan" {
		t.Fatalf("expected plan mode, got %v", sessionBody["mode"])
	}

	listReq := httptest.NewRequest("GET", "/api/philox/sessions", nil)
	listResp, err := app.Test(listReq)
	if err != nil {
		t.Fatalf("list sessions failed: %v", err)
	}
	var listBody map[string]interface{}
	if err := json.NewDecoder(listResp.Body).Decode(&listBody); err != nil {
		t.Fatalf("decode list failed: %v", err)
	}
	if len(listBody["sessions"].([]interface{})) != 1 {
		t.Fatalf("expected one session")
	}
}

func TestPhiloxAPI_DeleteSession(t *testing.T) {
	module := newTestModule(t)

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	createReq := httptest.NewRequest("POST", "/api/philox/session", strings.NewReader(`{"mode":"execute"}`))
	createReq.Header.Set("Content-Type", "application/json")
	createResp, err := app.Test(createReq)
	if err != nil {
		t.Fatalf("create failed: %v", err)
	}

	var createBody map[string]interface{}
	if err := json.NewDecoder(createResp.Body).Decode(&createBody); err != nil {
		t.Fatalf("decode create failed: %v", err)
	}
	sessionID := createBody["session_id"].(string)

	deleteReq := httptest.NewRequest("DELETE", "/api/philox/session/"+sessionID, nil)
	deleteResp, err := app.Test(deleteReq)
	if err != nil {
		t.Fatalf("delete failed: %v", err)
	}
	if deleteResp.StatusCode != 200 {
		t.Fatalf("expected delete 200, got %d", deleteResp.StatusCode)
	}

	getReq := httptest.NewRequest("GET", "/api/philox/session/"+sessionID, nil)
	getResp, err := app.Test(getReq)
	if err != nil {
		t.Fatalf("get after delete failed: %v", err)
	}
	if getResp.StatusCode != 404 {
		t.Fatalf("expected 404 after delete, got %d", getResp.StatusCode)
	}

	listReq := httptest.NewRequest("GET", "/api/philox/sessions", nil)
	listResp, err := app.Test(listReq)
	if err != nil {
		t.Fatalf("list after delete failed: %v", err)
	}
	var listBody map[string]interface{}
	if err := json.NewDecoder(listResp.Body).Decode(&listBody); err != nil {
		t.Fatalf("decode list failed: %v", err)
	}
	if len(listBody["sessions"].([]interface{})) != 0 {
		t.Fatalf("expected no sessions after delete")
	}
}

func TestPhiloxAPI_InvalidMessage(t *testing.T) {
	module := newTestModule(t)

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	req := httptest.NewRequest(
		"POST",
		"/api/philox/message",
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

func TestPathSandboxBlocksTraversal(t *testing.T) {
	executor := newToolExecutor()
	root := t.TempDir()
	session := &PersistedSession{AllowedRoots: []string{root}}

	if _, err := executor.resolvePath(session, filepath.Join(root, "inside.txt"), true); err != nil {
		t.Fatalf("expected inside path to resolve: %v", err)
	}
	if _, err := executor.resolvePath(session, filepath.Join(root, "..", "outside.txt"), true); err == nil {
		t.Fatalf("expected traversal to be blocked")
	}
}

func TestStorageRoundTrip(t *testing.T) {
	storage := newSessionStorage(t.TempDir())
	session := &PersistedSession{
		ID:                 "session-1",
		EffectiveModel:     "test-model",
		ThinkingLevel:      ThinkingBalanced,
		Mode:               ModeExecute,
		AllowedRoots:       []string{`C:\tmp`},
		Messages:           []ConversationMessage{{Role: "user", Content: "Hallo", CreatedAt: nowUTC()}},
		CompressedMemories: []CompressedMemory{{ID: "memory-1", Summary: "Kurz", CreatedAt: nowUTC()}},
		CreatedAt:          nowUTC(),
		UpdatedAt:          nowUTC(),
	}
	if err := storage.SaveSession(session); err != nil {
		t.Fatalf("save failed: %v", err)
	}
	loaded, err := storage.LoadSession(session.ID)
	if err != nil {
		t.Fatalf("load failed: %v", err)
	}
	if loaded.ID != session.ID || len(loaded.Messages) != 1 || len(loaded.CompressedMemories) != 1 {
		t.Fatalf("unexpected loaded session: %+v", loaded)
	}
}

func TestCompressionTriggersAtThreshold(t *testing.T) {
	session := &PersistedSession{
		ID:             "compress-me",
		EffectiveModel: "test-model",
		ThinkingLevel:  ThinkingBalanced,
		Mode:           ModeExecute,
		AllowedRoots:   []string{`C:\allowed`},
		Messages:       []ConversationMessage{},
	}
	for i := 0; i < 20; i++ {
		session.Messages = append(session.Messages, ConversationMessage{
			Role:      "user",
			Content:   strings.Repeat("kontext ", 3000),
			CreatedAt: nowUTC(),
		})
	}
	event := maybeCompressSession(session)
	if event == nil || !event.Triggered {
		t.Fatalf("expected compression to trigger")
	}
	if len(session.CompressedMemories) == 0 {
		t.Fatalf("expected compressed memories")
	}
	if len(session.Messages) != activeMessageWindow {
		t.Fatalf("expected active messages trimmed to %d, got %d", activeMessageWindow, len(session.Messages))
	}
}

func TestExtractMentionedRootsSupportsMultiplePaths(t *testing.T) {
	paths := extractMentionedRoots(
		`Nutze bitte C:\Users\david\Music\myphiloengine\modules\philox und C:\Users\david\StudioProjects\myphilo\lib\modules\philox`,
	)
	if len(paths) != 2 {
		t.Fatalf("expected 2 paths, got %d: %#v", len(paths), paths)
	}
}

func TestTrimPathCandidateRemovesTrailingSentenceText(t *testing.T) {
	root := t.TempDir()
	child := filepath.Join(root, "modules", "philox")
	if err := os.MkdirAll(child, 0o755); err != nil {
		t.Fatalf("mkdir failed: %v", err)
	}

	candidate := child + " baue unter page bitte den planungsmodus um"
	trimmed := trimPathCandidate(candidate)
	if trimmed != child {
		t.Fatalf("expected %q, got %q", child, trimmed)
	}
}
