package marktplatz

import (
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
)

func TestMarktplatzAPI_DownloadDedupReturnsExistingJob(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
		t.Fatalf("write settings: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("init: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	body := `{"provider":"openrouter","model_id":"openai/gpt-4o"}`
	req1 := httptest.NewRequest("POST", "/api/marktplatz/download", strings.NewReader(body))
	req1.Header.Set("Content-Type", "application/json")
	resp1, err := app.Test(req1, 5000)
	if err != nil {
		t.Fatalf("first download: %v", err)
	}
	if resp1.StatusCode != 200 {
		t.Fatalf("expected first 200, got %d", resp1.StatusCode)
	}
	first := decodeJSONBody(t, resp1.Body)
	jobID1, _ := first["job_id"].(string)
	if strings.TrimSpace(jobID1) == "" {
		t.Fatalf("first job_id missing")
	}
	if first["existing"] == true {
		t.Fatalf("first request must not be flagged existing")
	}

	req2 := httptest.NewRequest("POST", "/api/marktplatz/download", strings.NewReader(body))
	req2.Header.Set("Content-Type", "application/json")
	resp2, err := app.Test(req2, 5000)
	if err != nil {
		t.Fatalf("second download: %v", err)
	}
	if resp2.StatusCode != 200 {
		t.Fatalf("expected second 200, got %d", resp2.StatusCode)
	}
	second := decodeJSONBody(t, resp2.Body)
	jobID2, _ := second["job_id"].(string)
	if jobID2 != jobID1 {
		t.Fatalf("expected dedup to return same job_id %q, got %q", jobID1, jobID2)
	}
	if second["existing"] != true {
		t.Fatalf("expected existing=true on dedup response, got %#v", second["existing"])
	}
	if msg, _ := second["message"].(string); strings.TrimSpace(msg) == "" {
		t.Fatalf("expected explanatory message on dedup response")
	}

	waitForJobCompletion(t, app, jobID1, 2*time.Second)
}
