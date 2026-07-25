package marktplatz

import (
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"
)

// TestMarktplatzAPI_SearchRejectsLocalFiltersForCloudProviders stellt
// sicher, dass local_only/gpu_fit/quantization, die HF-spezifisch sind
// (lokale gguf-Downloads, VRAM-Check), beim Cloud-Provider nicht zu einer
// stillen leeren Ergebnisliste fuehren. Frueher kam einfach [] models
// zurueck – jetzt 400 mit Klartext.
func TestMarktplatzAPI_SearchRejectsLocalFiltersForCloudProviders(t *testing.T) {
	cases := []struct {
		name   string
		query  string
		expect int
	}{
		{"localOnly on OpenRouter", "provider=openrouter&local_only=true", 400},
		{"gpuFit on OpenRouter", "provider=openrouter&gpu_fit=true", 400},
		{"quantization on Featherless", "provider=featherless&quantization=Q4_K_M", 400},
		{"localOnly on HuggingFace allowed", "provider=huggingface&local_only=true", 200},
		{"providerAll with localOnly allowed", "provider=all&local_only=true", 200},
		{"plain huggingface search allowed", "provider=huggingface", 200},
	}

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
		t.Fatalf("write settings: %v", err)
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			module := New(settingsPath)
			if err := module.Initialize(); err != nil {
				t.Fatalf("init: %v", err)
			}
			app := fiber.New()
			api := app.Group("/api")
			module.RegisterRoutes(api)

			req := httptest.NewRequest("GET", "/api/marktplatz/search?"+tc.query, nil)
			resp, err := app.Test(req, 5000)
			if err != nil {
				t.Fatalf("request: %v", err)
			}
			if resp.StatusCode != tc.expect {
				t.Fatalf("expected %d for %q, got %d", tc.expect, tc.query, resp.StatusCode)
			}
			if tc.expect == 400 {
				body := decodeJSONBody(t, resp.Body)
				msg, _ := body["error"].(string)
				if !strings.Contains(strings.ToLower(msg), "lokal") && !strings.Contains(strings.ToLower(msg), "local") {
					t.Fatalf("expected actionable error message about local filters, got %q", msg)
				}
			}
		})
	}
}
