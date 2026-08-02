package philobot

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"
)

func newProjectTestApp(t *testing.T, withUserHeader bool) (*PhiloBotModule, *fiber.App) {
	t.Helper()
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
	if withUserHeader {
		app.Use(func(c *fiber.Ctx) error {
			if userID := c.Get("X-Test-User"); userID != "" {
				c.Locals("user_id", userID)
			}
			return c.Next()
		})
	}
	module.RegisterRoutes(app.Group("/api"))
	return module, app
}

func doJSON(t *testing.T, app *fiber.App, method, path, body string, headers map[string]string) (int, map[string]any) {
	t.Helper()
	var reader io.Reader
	if body != "" {
		reader = strings.NewReader(body)
	}
	req := httptest.NewRequest(method, path, reader)
	req.Header.Set("Content-Type", "application/json")
	for key, value := range headers {
		req.Header.Set(key, value)
	}
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("%s %s failed: %v", method, path, err)
	}
	var decoded map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode %s %s failed: %v", method, path, err)
	}
	return resp.StatusCode, decoded
}

func TestPhiloBotProjectCRUD(t *testing.T) {
	_, app := newProjectTestApp(t, false)

	status, created := doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"Arbeit","color":"#C9A24A"}`, nil)
	if status != http.StatusOK {
		t.Fatalf("create status=%d body=%v", status, created)
	}
	project := created["project"].(map[string]any)
	projectID := project["id"].(string)
	if projectID == "" || project["name"] != "Arbeit" || project["color"] != "#C9A24A" {
		t.Fatalf("unexpected project payload: %v", project)
	}

	status, list := doJSON(t, app, http.MethodGet, "/api/philobot/projects", "", nil)
	if status != http.StatusOK {
		t.Fatalf("list status=%d", status)
	}
	projects := list["projects"].([]any)
	if len(projects) != 1 || projects[0].(map[string]any)["id"] != projectID {
		t.Fatalf("expected exactly the created project, got %v", projects)
	}

	status, renamed := doJSON(t, app, http.MethodPost, "/api/philobot/project/"+projectID+"/rename", `{"name":"Buero"}`, nil)
	if status != http.StatusOK {
		t.Fatalf("rename status=%d body=%v", status, renamed)
	}
	if renamed["project"].(map[string]any)["name"] != "Buero" {
		t.Fatalf("rename not applied: %v", renamed)
	}

	status, deleted := doJSON(t, app, http.MethodDelete, "/api/philobot/project/"+projectID, "", nil)
	if status != http.StatusOK || deleted["status"] != "deleted" {
		t.Fatalf("delete status=%d body=%v", status, deleted)
	}
	_, list = doJSON(t, app, http.MethodGet, "/api/philobot/projects", "", nil)
	if len(list["projects"].([]any)) != 0 {
		t.Fatalf("project survived delete: %v", list)
	}
}

func TestPhiloBotProjectValidation(t *testing.T) {
	_, app := newProjectTestApp(t, false)

	status, body := doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"   "}`, nil)
	if status != http.StatusBadRequest {
		t.Fatalf("empty name status=%d body=%v", status, body)
	}

	status, created := doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"`+strings.Repeat("x", 200)+`"}`, nil)
	if status != http.StatusOK {
		t.Fatalf("long name status=%d body=%v", status, created)
	}
	name := created["project"].(map[string]any)["name"].(string)
	if len([]rune(name)) > 80 {
		t.Fatalf("name not truncated to 80 runes: %d", len([]rune(name)))
	}

	status, body = doJSON(t, app, http.MethodPost, "/api/philobot/project/does-not-exist/rename", `{"name":"x"}`, nil)
	if status != http.StatusNotFound {
		t.Fatalf("rename missing status=%d body=%v", status, body)
	}
	status, body = doJSON(t, app, http.MethodDelete, "/api/philobot/project/does-not-exist", "", nil)
	if status != http.StatusNotFound {
		t.Fatalf("delete missing status=%d body=%v", status, body)
	}
}

func TestPhiloBotSessionProjectAssignment(t *testing.T) {
	_, app := newProjectTestApp(t, false)

	_, created := doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"Projekt A"}`, nil)
	projectID := created["project"].(map[string]any)["id"].(string)

	status, sessionResp := doJSON(t, app, http.MethodPost, "/api/philobot/session",
		`{"model_id":"stub","project_id":"`+projectID+`"}`, nil)
	if status != http.StatusOK {
		t.Fatalf("create session status=%d body=%v", status, sessionResp)
	}
	sessionID := sessionResp["session_id"].(string)

	status, _ = doJSON(t, app, http.MethodPost, "/api/philobot/message",
		`{"session_id":"`+sessionID+`","message":"Hallo"}`, nil)
	if status != http.StatusOK {
		t.Fatalf("message status=%d", status)
	}

	_, list := doJSON(t, app, http.MethodGet, "/api/philobot/sessions", "", nil)
	sessions := list["sessions"].([]any)
	if len(sessions) != 1 {
		t.Fatalf("expected 1 session summary, got %v", sessions)
	}
	if sessions[0].(map[string]any)["project_id"] != projectID {
		t.Fatalf("summary missing project_id: %v", sessions[0])
	}

	_, second := doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"Projekt B"}`, nil)
	secondID := second["project"].(map[string]any)["id"].(string)
	status, assigned := doJSON(t, app, http.MethodPost, "/api/philobot/session/"+sessionID+"/project",
		`{"project_id":"`+secondID+`"}`, nil)
	if status != http.StatusOK {
		t.Fatalf("assign status=%d body=%v", status, assigned)
	}
	if assigned["session"].(map[string]any)["project_id"] != secondID {
		t.Fatalf("assign not reflected: %v", assigned)
	}

	status, _ = doJSON(t, app, http.MethodDelete, "/api/philobot/project/"+secondID, "", nil)
	if status != http.StatusOK {
		t.Fatalf("delete project status=%d", status)
	}
	_, list = doJSON(t, app, http.MethodGet, "/api/philobot/sessions", "", nil)
	sessions = list["sessions"].([]any)
	if len(sessions) != 1 {
		t.Fatalf("session lost after project delete: %v", sessions)
	}
	if pid, ok := sessions[0].(map[string]any)["project_id"]; ok && pid != "" {
		t.Fatalf("project_id not cleared after delete: %v", sessions[0])
	}

	_, created = doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"Tmp"}`, nil)
	tmpID := created["project"].(map[string]any)["id"].(string)
	doJSON(t, app, http.MethodPost, "/api/philobot/session/"+sessionID+"/project", `{"project_id":"`+tmpID+`"}`, nil)
	status, unassigned := doJSON(t, app, http.MethodPost, "/api/philobot/session/"+sessionID+"/project", `{"project_id":""}`, nil)
	if status != http.StatusOK {
		t.Fatalf("unassign status=%d body=%v", status, unassigned)
	}
	if pid, ok := unassigned["session"].(map[string]any)["project_id"]; ok && pid != "" {
		t.Fatalf("unassign not reflected: %v", unassigned)
	}

	status, _ = doJSON(t, app, http.MethodPost, "/api/philobot/session/"+sessionID+"/project", `{"project_id":"nope"}`, nil)
	if status != http.StatusNotFound {
		t.Fatalf("assign unknown project status=%d", status)
	}
	status, _ = doJSON(t, app, http.MethodPost, "/api/philobot/session/nope/project", `{"project_id":"`+tmpID+`"}`, nil)
	if status != http.StatusNotFound {
		t.Fatalf("assign unknown session status=%d", status)
	}

	status, _ = doJSON(t, app, http.MethodPost, "/api/philobot/session", `{"model_id":"stub","project_id":"nope"}`, nil)
	if status != http.StatusNotFound {
		t.Fatalf("create session unknown project status=%d", status)
	}
}

func TestPhiloBotProjectsIsolatedByUser(t *testing.T) {
	_, app := newProjectTestApp(t, true)
	alice := map[string]string{"X-Test-User": "alice"}
	bob := map[string]string{"X-Test-User": "bob"}

	_, created := doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"Alice Privat"}`, alice)
	projectID := created["project"].(map[string]any)["id"].(string)

	_, list := doJSON(t, app, http.MethodGet, "/api/philobot/projects", "", bob)
	if len(list["projects"].([]any)) != 0 {
		t.Fatalf("alice project leaked to bob: %v", list)
	}

	status, _ := doJSON(t, app, http.MethodPost, "/api/philobot/project/"+projectID+"/rename", `{"name":"gehackt"}`, bob)
	if status != http.StatusNotFound {
		t.Fatalf("bob rename status=%d", status)
	}
	status, _ = doJSON(t, app, http.MethodDelete, "/api/philobot/project/"+projectID, "", bob)
	if status != http.StatusNotFound {
		t.Fatalf("bob delete status=%d", status)
	}

	_, sessionResp := doJSON(t, app, http.MethodPost, "/api/philobot/session", `{"model_id":"stub"}`, bob)
	bobSession := sessionResp["session_id"].(string)
	status, _ = doJSON(t, app, http.MethodPost, "/api/philobot/session/"+bobSession+"/project",
		`{"project_id":"`+projectID+`"}`, bob)
	if status != http.StatusNotFound {
		t.Fatalf("bob assign to alice project status=%d", status)
	}

	_, aliceSessionResp := doJSON(t, app, http.MethodPost, "/api/philobot/session", `{"model_id":"stub"}`, alice)
	aliceSession := aliceSessionResp["session_id"].(string)
	status, _ = doJSON(t, app, http.MethodPost, "/api/philobot/session/"+aliceSession+"/project",
		`{"project_id":"`+projectID+`"}`, alice)
	if status != http.StatusOK {
		t.Fatalf("alice assign status=%d", status)
	}
}

func TestPhiloBotProjectsSurviveReload(t *testing.T) {
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
	module.RegisterRoutes(app.Group("/api"))

	_, created := doJSON(t, app, http.MethodPost, "/api/philobot/project", `{"name":"Persist"}`, nil)
	projectID := created["project"].(map[string]any)["id"].(string)
	_, sessionResp := doJSON(t, app, http.MethodPost, "/api/philobot/session",
		`{"model_id":"stub","project_id":"`+projectID+`"}`, nil)
	sessionID := sessionResp["session_id"].(string)
	doJSON(t, app, http.MethodPost, "/api/philobot/message",
		`{"session_id":"`+sessionID+`","message":"Hallo"}`, nil)

	reloaded := New(settingsPath)
	if err := reloaded.Initialize(); err != nil {
		t.Fatal(err)
	}
	app2 := fiber.New()
	reloaded.RegisterRoutes(app2.Group("/api"))

	_, list := doJSON(t, app2, http.MethodGet, "/api/philobot/projects", "", nil)
	projects := list["projects"].([]any)
	if len(projects) != 1 || projects[0].(map[string]any)["id"] != projectID {
		t.Fatalf("project lost on reload: %v", projects)
	}
	_, sessions := doJSON(t, app2, http.MethodGet, "/api/philobot/sessions", "", nil)
	entries := sessions["sessions"].([]any)
	if len(entries) != 1 || entries[0].(map[string]any)["project_id"] != projectID {
		t.Fatalf("session assignment lost on reload: %v", entries)
	}
}
