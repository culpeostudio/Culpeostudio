package marktplatz

import (
	"fmt"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/apimodels"
)

// TestMarktplatzAPI_StartAPIModelLimitReached startet MaxActiveModels
// Modelle und verlangt, dass der naechste Start mit 400 + Limit-Hinweis
// beantwortet wird – nicht als 500er Internal Error.
func TestMarktplatzAPI_StartAPIModelLimitReached(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{
	"model_dir": "data/models",
	"openrouter_token": "mock-token"
}`), 0o600); err != nil {
		t.Fatalf("write settings: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("init: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	for i := 0; i < apimodels.MaxActiveModels; i++ {
		body := fmt.Sprintf(`{"provider":"openrouter","model_id":"v/m-%d"}`, i)
		req := httptest.NewRequest("POST", "/api/marktplatz/api-models/start", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		resp, err := app.Test(req, 5000)
		if err != nil {
			t.Fatalf("start %d: %v", i, err)
		}
		if resp.StatusCode != 200 {
			t.Fatalf("start %d: expected 200, got %d", i, resp.StatusCode)
		}
	}

	// (MaxActiveModels+1).start -> 400 mit Limit-Hinweis
	overflowReq := httptest.NewRequest("POST", "/api/marktplatz/api-models/start",
		strings.NewReader(`{"provider":"openrouter","model_id":"v/overflow"}`))
	overflowReq.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(overflowReq, 5000)
	if err != nil {
		t.Fatalf("overflow request: %v", err)
	}
	if resp.StatusCode != 400 {
		t.Fatalf("expected 400 at limit, got %d", resp.StatusCode)
	}
	body := decodeJSONBody(t, resp.Body)
	msg, _ := body["error"].(string)
	if !strings.Contains(strings.ToLower(msg), "limit") {
		t.Fatalf("expected 'limit' in error message, got %q", msg)
	}
	limit, _ := body["limit"].(float64)
	if int(limit) != apimodels.MaxActiveModels {
		t.Fatalf("limit field: expected %d, got %v", apimodels.MaxActiveModels, limit)
	}
}
