package marktplatz

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/modules/marktplatz/openrouter"
)

// newOpenRouterSearchServer stellt den Katalog-Endpunkt von OpenRouter mit
// total Modellen nach. OpenRouter kennt keinen limit-Parameter – die Antwort
// enthaelt immer den kompletten Katalog.
func newOpenRouterSearchServer(t *testing.T, total int) *httptest.Server {
	t.Helper()

	models := make([]map[string]interface{}, 0, total)
	for i := 0; i < total; i++ {
		models = append(models, map[string]interface{}{
			"id":             fmt.Sprintf("vendor/model-%03d", i),
			"name":           fmt.Sprintf("Model %03d", i),
			"description":    "cloud model",
			"context_length": 128000,
			"pricing": map[string]string{
				"prompt":     "0.000005",
				"completion": "0.000015",
			},
		})
	}

	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/models" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"data": models})
	}))
}

func newTestOpenRouterApp(t *testing.T, apiBase string) *fiber.App {
	t.Helper()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	openrouter.InvalidateCache()
	module := New(settingsPath)
	module.orAPIBase = apiBase
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	return app
}

// TestMarktplatzAPI_OpenRouterPaginatesBeyondFirstPage haelt fest, dass eine
// Cloud-Suche ohne Filter weiterblaettern kann. Frueher wurde das Suchfenster
// nur fuer HuggingFace um ein Modell erhoeht; OpenRouter lieferte deshalb
// exakt eine volle Seite, has_more war false und der Katalog endete nach den
// ersten 24 Modellen.
func TestMarktplatzAPI_OpenRouterPaginatesBeyondFirstPage(t *testing.T) {
	restoreHardwareProfile := cacheHardwareProfileForTest(HardwareProfile{
		RAMGB:    16,
		Detected: true,
	})
	defer restoreHardwareProfile()

	server := newOpenRouterSearchServer(t, 60)
	defer server.Close()

	app := newTestOpenRouterApp(t, server.URL)

	req := httptest.NewRequest("GET", "/api/marktplatz/search?provider=openrouter&limit=24&page=1", nil)
	resp, err := app.Test(req, 5000)
	if err != nil {
		t.Fatalf("page 1 request failed: %v", err)
	}
	body := decodeJSONBody(t, resp.Body)
	models := modelListFromBody(t, body["models"])
	if len(models) != 24 {
		t.Fatalf("expected 24 models on page 1, got %d", len(models))
	}
	if body["has_more"] != true {
		t.Fatalf("expected has_more true while 60 models exist, got %#v", body["has_more"])
	}

	// Letzte Seite: 60 Modelle, 24 pro Seite -> Seite 3 traegt den Rest und
	// meldet has_more=false.
	lastReq := httptest.NewRequest("GET", "/api/marktplatz/search?provider=openrouter&limit=24&page=3", nil)
	lastResp, err := app.Test(lastReq, 5000)
	if err != nil {
		t.Fatalf("page 3 request failed: %v", err)
	}
	lastBody := decodeJSONBody(t, lastResp.Body)
	lastModels := modelListFromBody(t, lastBody["models"])
	if len(lastModels) != 12 {
		t.Fatalf("expected 12 models on page 3, got %d", len(lastModels))
	}
	if lastBody["has_more"] != false {
		t.Fatalf("expected has_more false on the last page, got %#v", lastBody["has_more"])
	}
}
