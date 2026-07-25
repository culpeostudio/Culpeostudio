package settings

import (
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"
)

func TestSettingsAPI_GetAndUpdate(t *testing.T) {
	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	getReq := httptest.NewRequest("GET", "/api/settings", nil)
	getResp, err := app.Test(getReq)
	if err != nil {
		t.Fatalf("GET settings failed: %v", err)
	}
	if getResp.StatusCode != 200 {
		t.Fatalf("expected GET 200, got %d", getResp.StatusCode)
	}

	var before map[string]interface{}
	if err := json.NewDecoder(getResp.Body).Decode(&before); err != nil {
		t.Fatalf("decode GET settings failed: %v", err)
	}
	if before["huggingface_token_set"] == true {
		t.Fatalf("expected hf token flag false by default")
	}

	putReq := httptest.NewRequest(
		"PUT",
		"/api/settings",
		strings.NewReader(fmt.Sprintf(`{
  "model_dir":%q,
  "huggingface_token":"hf_secret",
  "openrouter_token":"or_secret",
  "featherless_token":"fl_secret"
}`, filepath.Join(filepath.Dir(settingsPath), "models"))),
	)
	putReq.Header.Set("Content-Type", "application/json")
	putResp, err := app.Test(putReq)
	if err != nil {
		t.Fatalf("PUT settings failed: %v", err)
	}
	if putResp.StatusCode != 200 {
		t.Fatalf("expected PUT 200, got %d", putResp.StatusCode)
	}

	var after map[string]interface{}
	if err := json.NewDecoder(putResp.Body).Decode(&after); err != nil {
		t.Fatalf("decode PUT settings failed: %v", err)
	}
	if after["huggingface_token_set"] != true || after["openrouter_token_set"] != true || after["featherless_token_set"] != true {
		t.Fatalf("expected token flags true after update")
	}
	if _, exists := after["huggingface_token"]; exists {
		t.Fatalf("response must not include huggingface token value")
	}
	if _, exists := after["openrouter_token"]; exists {
		t.Fatalf("response must not include openrouter token value")
	}
}

func TestSettingsAPI_TestProvider(t *testing.T) {
	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	// Since we mock or don't actually test the real live outgoing request,
	// checking the endpoint for invalid input and invalid provider first is good.
	invalidReq := httptest.NewRequest("GET", "/api/settings/test-provider/invalid", nil)
	invalidResp, err := app.Test(invalidReq)
	if err != nil {
		t.Fatalf("GET test provider failed: %v", err)
	}
	if invalidResp.StatusCode != 400 {
		t.Fatalf("expected 400 for invalid provider, got %d", invalidResp.StatusCode)
	}

	// We can check with empty/no token, which makes it perform public checks
	// (Note: internet is required for public check, but let's see if it handles it or we can just test the route dispatching)
	testReq := httptest.NewRequest("GET", "/api/settings/test-provider/huggingface", nil)
	testResp, err := app.Test(testReq)
	if err != nil {
		t.Fatalf("GET test provider huggingface failed: %v", err)
	}
	// Let's check status code. Since it attempts an HTTP request, if there's no internet in build container it might return false but status code should be 200 JSON
	if testResp.StatusCode != 200 {
		t.Fatalf("expected 200, got %d", testResp.StatusCode)
	}
	var res map[string]interface{}
	if err := json.NewDecoder(testResp.Body).Decode(&res); err != nil {
		t.Fatalf("decode test provider response failed: %v", err)
	}
	if res["provider"] != "huggingface" {
		t.Fatalf("expected provider huggingface, got %v", res["provider"])
	}
}
