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

// TestMarktplatzAPI_DownloadRejectsOversize stellt sicher, dass ein Download-
// Request, der ein zu grosses Modell fuer den freien Speicherplatz
// deklariert, mit 400 + Klartext abgewiesen wird. Frueher waere der Job als
// "queued" angenommen worden und erst nach Schaeden einer halbherigen
// Download-Datei gescheitert.
func TestMarktplatzAPI_DownloadRejectsOversize(t *testing.T) {
	restore := cacheHardwareProfileForTest(HardwareProfile{
		DiskFreeBytes: 5 * 1024 * 1024 * 1024, // 5 GB frei
		Detected:      true,
	})
	defer restore()

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

	// 20 GB beantragt, nur 5 GB frei -> 400.
	body := `{"provider":"huggingface","model_id":"org/big","size_bytes":21474836480}`
	req := httptest.NewRequest("POST", "/api/marktplatz/download", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req, 5000)
	if err != nil {
		t.Fatalf("request: %v", err)
	}
	if resp.StatusCode != 400 {
		t.Fatalf("expected 400 oversize, got %d", resp.StatusCode)
	}
	out := decodeJSONBody(t, resp.Body)
	msg, _ := out["error"].(string)
	if !strings.Contains(strings.ToLower(msg), "speicherplatz") {
		t.Fatalf("expected 'Speicherplatz' in message, got %q", msg)
	}
	if v, _ := out["disk_free_bytes"].(float64); int64(v) != 5*1024*1024*1024 {
		t.Fatalf("disk_free_bytes mismatch: %v", out["disk_free_bytes"])
	}
	if v, _ := out["required_bytes"].(float64); int64(v) < 20*1024*1024*1024 {
		t.Fatalf("required_bytes should be >= 20GB, got %v", out["required_bytes"])
	}
}

// TestMarktplatzAPI_DownloadAcceptsUnknownSize ignoriert size_bytes == 0
// (z.B. API-Modelle ohne echte Datei), so dass Backwards-Kompatibilität
// fuer aeltere Clients gewaehrleistet bleibt.
func TestMarktplatzAPI_DownloadAcceptsUnknownSize(t *testing.T) {
	restore := cacheHardwareProfileForTest(HardwareProfile{
		DiskFreeBytes: 1024, // winzig – wuerde jeden echten Download ablehnen
		Detected:      true,
	})
	defer restore()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{
		"model_dir":"data/models",
		"openrouter_token":"mock"
	}`), 0o600); err != nil {
		t.Fatalf("write: %v", err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("init: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	// OpenRouter-API-Deskriptor – kein size_bytes -> Pre-Check skipped.
	body := `{"provider":"openrouter","model_id":"openai/gpt-4o"}`
	req := httptest.NewRequest("POST", "/api/marktplatz/download", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req, 5000)
	if err != nil {
		t.Fatalf("request: %v", err)
	}
	if resp.StatusCode != 200 {
		t.Fatalf("expected 200 for size-less download, got %d", resp.StatusCode)
	}

	// Aufräumen: wartet bis Job complete, so dass TempDir cleanup nicht
	// an einer noch laufenden Goroutine haengt.
	out := decodeJSONBody(t, resp.Body)
	jobID, _ := out["job_id"].(string)
	waitForJobCompletion(t, app, jobID, 2*time.Second)
}
