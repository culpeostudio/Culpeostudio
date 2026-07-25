package marktplatz

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/fillyengine/backend/modules/marktplatz/openrouter"
	"github.com/gofiber/fiber/v2"
)

func TestMarktplatzAPI_SearchAndDownloadJob(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")

	if err := os.WriteFile(settingsPath, []byte(`{
  "model_dir": "data/models",
  "openrouter_token": "mock-token"
}
`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	searchReq := httptest.NewRequest("GET", "/api/marktplatz/search?provider=openrouter&q=gemini", nil)
	searchResp, err := app.Test(searchReq, 5000)
	if err != nil {
		t.Fatalf("search request failed: %v", err)
	}
	if searchResp.StatusCode != 200 {
		t.Fatalf("expected search 200, got %d", searchResp.StatusCode)
	}
	var searchBody map[string]interface{}
	if err := json.NewDecoder(searchResp.Body).Decode(&searchBody); err != nil {
		t.Fatalf("decode search response failed: %v", err)
	}
	if _, ok := searchBody["has_more"]; !ok {
		t.Fatalf("expected has_more in search response")
	}

	downloadReq := httptest.NewRequest(
		"POST",
		"/api/marktplatz/download",
		strings.NewReader(`{"provider":"openrouter","model_id":"google/gemini-2.5-pro"}`),
	)
	downloadReq.Header.Set("Content-Type", "application/json")
	downloadResp, err := app.Test(downloadReq, 5000)
	if err != nil {
		t.Fatalf("download request failed: %v", err)
	}
	if downloadResp.StatusCode != 200 {
		t.Fatalf("expected download 200, got %d", downloadResp.StatusCode)
	}

	var downloadBody map[string]interface{}
	if err := json.NewDecoder(downloadResp.Body).Decode(&downloadBody); err != nil {
		t.Fatalf("decode download response failed: %v", err)
	}
	jobID, _ := downloadBody["job_id"].(string)
	if strings.TrimSpace(jobID) == "" {
		t.Fatalf("job_id missing in download response")
	}

	jobReq := httptest.NewRequest("GET", "/api/marktplatz/job/"+jobID, nil)
	jobResp, err := app.Test(jobReq, 5000)
	if err != nil {
		t.Fatalf("job request failed: %v", err)
	}
	if jobResp.StatusCode != 200 {
		t.Fatalf("expected job 200, got %d", jobResp.StatusCode)
	}
	waitForJobCompletion(t, app, jobID, 3*time.Second)

	hwReq := httptest.NewRequest("GET", "/api/marktplatz/hardware/profile", nil)
	hwResp, err := app.Test(hwReq, 5000)
	if err != nil {
		t.Fatalf("hardware profile request failed: %v", err)
	}
	if hwResp.StatusCode != 200 {
		t.Fatalf("expected hardware profile 200, got %d", hwResp.StatusCode)
	}

	var hwBody map[string]interface{}
	if err := json.NewDecoder(hwResp.Body).Decode(&hwBody); err != nil {
		t.Fatalf("decode hardware profile failed: %v", err)
	}
	if _, ok := hwBody["ram_gb"]; !ok {
		t.Fatalf("expected ram_gb in hardware profile response")
	}

	deleteReq := httptest.NewRequest("DELETE", "/api/marktplatz/job/"+jobID, nil)
	deleteResp, err := app.Test(deleteReq, 5000)
	if err != nil {
		t.Fatalf("delete request failed: %v", err)
	}
	if deleteResp.StatusCode != 200 {
		t.Fatalf("expected delete 200, got %d", deleteResp.StatusCode)
	}
}

func TestMarktplatzAPI_AlibabaProviderRejected(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	req := httptest.NewRequest("GET", "/api/marktplatz/search?provider=alibaba_cloud", nil)
	resp, err := app.Test(req, 5000)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != 400 {
		t.Fatalf("expected alibaba_cloud to be rejected with 400, got %d", resp.StatusCode)
	}
}

func TestMarktplatzAPI_DetailAcceptsNamespacedModelIDQuery(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	provider := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/models" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"data":[{"id":"openai/gpt-5.6-luna-pro","name":"GPT","context_length":128000}]}`))
	}))
	defer provider.Close()

	openrouter.InvalidateCache()
	module := New(settingsPath)
	module.orAPIBase = provider.URL
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}
	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))

	request := httptest.NewRequest(
		"GET",
		"/api/marktplatz/model?provider=openrouter&id=openai%2Fgpt-5.6-luna-pro",
		nil,
	)
	response, err := app.Test(request, 5000)
	if err != nil {
		t.Fatalf("detail request failed: %v", err)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("expected detail response 200, got %d", response.StatusCode)
	}
	var body map[string]interface{}
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatalf("decode detail response failed: %v", err)
	}
	if body["model_id"] != "openai/gpt-5.6-luna-pro" {
		t.Fatalf("unexpected detail response: %#v", body)
	}
}

func TestMarktplatzAPI_StartActiveAPIModel(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{
  "model_dir": "data/models",
  "openrouter_token": "mock-openrouter",
  "featherless_token": "mock-featherless"
}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	startReq := httptest.NewRequest(
		"POST",
		"/api/marktplatz/api-models/start",
		strings.NewReader(`{"provider":"openrouter","model_id":"openai/gpt-4o","display_name":"GPT-4o"}`),
	)
	startReq.Header.Set("Content-Type", "application/json")
	startResp, err := app.Test(startReq, 5000)
	if err != nil {
		t.Fatalf("start api model request failed: %v", err)
	}
	if startResp.StatusCode != 200 {
		t.Fatalf("expected start 200, got %d", startResp.StatusCode)
	}

	startBody := decodeJSONBody(t, startResp.Body)
	model, ok := startBody["model"].(map[string]interface{})
	if !ok {
		t.Fatalf("expected model object, got %#v", startBody["model"])
	}
	modelRef, _ := model["model_ref"].(string)
	if strings.TrimSpace(modelRef) == "" {
		t.Fatalf("expected model_ref")
	}

	listReq := httptest.NewRequest("GET", "/api/marktplatz/api-models/active", nil)
	listResp, err := app.Test(listReq, 5000)
	if err != nil {
		t.Fatalf("list active models request failed: %v", err)
	}
	if listResp.StatusCode != 200 {
		t.Fatalf("expected list 200, got %d", listResp.StatusCode)
	}
	listBody := decodeJSONBody(t, listResp.Body)
	models := modelListFromBody(t, listBody["models"])
	if len(models) != 1 {
		t.Fatalf("expected one active model, got %d", len(models))
	}

	deleteReq := httptest.NewRequest("DELETE", "/api/marktplatz/api-models/"+modelRef, nil)
	deleteResp, err := app.Test(deleteReq, 5000)
	if err != nil {
		t.Fatalf("delete active model request failed: %v", err)
	}
	if deleteResp.StatusCode != 200 {
		t.Fatalf("expected delete 200, got %d", deleteResp.StatusCode)
	}
}

func TestMarktplatzAPI_StartAPIModelValidation(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	cases := []struct {
		name string
		body string
	}{
		{
			name: "huggingface rejected",
			body: `{"provider":"huggingface","model_id":"org/model"}`,
		},
		{
			name: "missing openrouter token",
			body: `{"provider":"openrouter","model_id":"openai/gpt-4o"}`,
		},
		{
			name: "missing model id",
			body: `{"provider":"featherless","model_id":""}`,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest("POST", "/api/marktplatz/api-models/start", strings.NewReader(tc.body))
			req.Header.Set("Content-Type", "application/json")
			resp, err := app.Test(req, 5000)
			if err != nil {
				t.Fatalf("request failed: %v", err)
			}
			if resp.StatusCode != 400 {
				t.Fatalf("expected 400, got %d", resp.StatusCode)
			}
		})
	}
}

func TestMarktplatzAPI_GPUFitSearchExpandsUntilPageCanBeFilled(t *testing.T) {
	restoreHardwareProfile := cacheHardwareProfileForTest(HardwareProfile{
		VRAMGB:   8,
		HasGPU:   true,
		GPUName:  "Test GPU",
		Detected: true,
	})
	defer restoreHardwareProfile()

	hfModels := buildHFSearchFixtures(240, func(index int) int64 {
		if index >= 210 {
			return 4 * 1024 * 1024 * 1024
		}
		return 12 * 1024 * 1024 * 1024
	})
	server, requestedLimits := newHFSearchServer(t, hfModels)
	defer server.Close()

	module, app := newTestMarketplaceApp(t, server.URL)
	_ = module

	req := httptest.NewRequest("GET", "/api/marktplatz/search?provider=all&local_only=true&gpu_fit=true&limit=24&page=1", nil)
	resp, err := app.Test(req, 5000)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != 200 {
		t.Fatalf("expected search 200, got %d", resp.StatusCode)
	}

	body := decodeJSONBody(t, resp.Body)
	models := modelListFromBody(t, body["models"])
	if len(models) != 24 {
		t.Fatalf("expected expanded search to fill first page with 24 runnable models, got %d", len(models))
	}
	if body["has_more"] != true {
		t.Fatalf("expected has_more to stay true after expanded gpu search, got %#v", body["has_more"])
	}
	if maxIntSlice(*requestedLimits) <= 192 {
		t.Fatalf("expected hugggingface search window to expand beyond 192, got %#v", *requestedLimits)
	}
}

func TestMarktplatzAPI_GPUFitSearchKeepsHasMoreWhenMoreFitsExistPastCurrentWindow(t *testing.T) {
	restoreHardwareProfile := cacheHardwareProfileForTest(HardwareProfile{
		VRAMGB:   8,
		HasGPU:   true,
		GPUName:  "Test GPU",
		Detected: true,
	})
	defer restoreHardwareProfile()

	hfModels := buildHFSearchFixtures(240, func(index int) int64 {
		switch {
		case index >= 168 && index < 208:
			return 4 * 1024 * 1024 * 1024
		default:
			return 12 * 1024 * 1024 * 1024
		}
	})
	server, _ := newHFSearchServer(t, hfModels)
	defer server.Close()

	_, app := newTestMarketplaceApp(t, server.URL)

	pageOneReq := httptest.NewRequest("GET", "/api/marktplatz/search?provider=all&local_only=true&gpu_fit=true&limit=24&page=1", nil)
	pageOneResp, err := app.Test(pageOneReq, 5000)
	if err != nil {
		t.Fatalf("page 1 request failed: %v", err)
	}
	if pageOneResp.StatusCode != 200 {
		t.Fatalf("expected page 1 search 200, got %d", pageOneResp.StatusCode)
	}

	pageOneBody := decodeJSONBody(t, pageOneResp.Body)
	pageOneModels := modelListFromBody(t, pageOneBody["models"])
	if len(pageOneModels) != 24 {
		t.Fatalf("expected first page to return 24 runnable models, got %d", len(pageOneModels))
	}
	if pageOneBody["has_more"] != true {
		t.Fatalf("expected page 1 has_more to stay true when more gpu-fit models exist later, got %#v", pageOneBody["has_more"])
	}

	pageTwoReq := httptest.NewRequest("GET", "/api/marktplatz/search?provider=all&local_only=true&gpu_fit=true&limit=24&page=2", nil)
	pageTwoResp, err := app.Test(pageTwoReq, 5000)
	if err != nil {
		t.Fatalf("page 2 request failed: %v", err)
	}
	if pageTwoResp.StatusCode != 200 {
		t.Fatalf("expected page 2 search 200, got %d", pageTwoResp.StatusCode)
	}

	pageTwoBody := decodeJSONBody(t, pageTwoResp.Body)
	pageTwoModels := modelListFromBody(t, pageTwoBody["models"])
	if len(pageTwoModels) != 16 {
		t.Fatalf("expected second page to return remaining 16 runnable models, got %d", len(pageTwoModels))
	}
	if pageTwoBody["has_more"] != false {
		t.Fatalf("expected page 2 has_more to be false after all runnable models were returned, got %#v", pageTwoBody["has_more"])
	}
}

func newTestMarketplaceApp(t *testing.T, hfAPIBase string) (*MarktplatzModule, *fiber.App) {
	t.Helper()

	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	module.hfAPIBase = hfAPIBase
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)
	return module, app
}

func newHFSearchServer(t *testing.T, models []map[string]interface{}) (*httptest.Server, *[]int) {
	t.Helper()

	requestedLimits := &[]int{}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/models" {
			http.NotFound(w, r)
			return
		}

		limit, _ := strconv.Atoi(strings.TrimSpace(r.URL.Query().Get("limit")))
		*requestedLimits = append(*requestedLimits, limit)
		if limit <= 0 || limit > len(models) {
			limit = len(models)
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(models[:limit])
	}))
	return server, requestedLimits
}

func buildHFSearchFixtures(total int, sizeForIndex func(index int) int64) []map[string]interface{} {
	models := make([]map[string]interface{}, 0, total)
	for i := 0; i < total; i++ {
		modelID := fmt.Sprintf("test/model-%03d-GGUF", i)
		optionName := fmt.Sprintf("model-%03d-Q4_K_M.gguf", i)
		models = append(models, map[string]interface{}{
			"id":           modelID,
			"author":       "test",
			"downloads":    total - i,
			"pipeline_tag": "text-generation",
			"siblings": []map[string]interface{}{
				{
					"rfilename": optionName,
					"size":      sizeForIndex(i),
				},
			},
		})
	}
	return models
}

func cacheHardwareProfileForTest(profile HardwareProfile) func() {
	hardwareProfileCache.mu.Lock()
	previousProfile := hardwareProfileCache.profile
	previousExpiresAt := hardwareProfileCache.expiresAt
	hardwareProfileCache.profile = profile
	hardwareProfileCache.expiresAt = time.Now().Add(time.Minute)
	hardwareProfileCache.mu.Unlock()

	return func() {
		hardwareProfileCache.mu.Lock()
		hardwareProfileCache.profile = previousProfile
		hardwareProfileCache.expiresAt = previousExpiresAt
		hardwareProfileCache.mu.Unlock()
	}
}

func decodeJSONBody(t *testing.T, bodyReader interface{ Read([]byte) (int, error) }) map[string]interface{} {
	t.Helper()

	var body map[string]interface{}
	if err := json.NewDecoder(bodyReader).Decode(&body); err != nil {
		t.Fatalf("decode response failed: %v", err)
	}
	return body
}

func modelListFromBody(t *testing.T, value interface{}) []interface{} {
	t.Helper()

	models, ok := value.([]interface{})
	if !ok {
		t.Fatalf("expected models array, got %#v", value)
	}
	return models
}

func maxIntSlice(values []int) int {
	best := 0
	for _, value := range values {
		if value > best {
			best = value
		}
	}
	return best
}

func waitForJobCompletion(t *testing.T, app *fiber.App, jobID string, timeout time.Duration) {
	t.Helper()

	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		req := httptest.NewRequest("GET", "/api/marktplatz/job/"+jobID, nil)
		resp, err := app.Test(req, 5000)
		if err != nil {
			t.Fatalf("job poll request failed: %v", err)
		}
		if resp.StatusCode != 200 {
			t.Fatalf("expected job poll 200, got %d", resp.StatusCode)
		}

		body := decodeJSONBody(t, resp.Body)
		status, _ := body["status"].(string)
		switch status {
		case "done", "failed":
			return
		}

		time.Sleep(50 * time.Millisecond)
	}

	t.Fatalf("job %s did not finish within %s", jobID, timeout)
}

func TestMarktplatzAPI_SearchHuggingFaceHasMoreNormal(t *testing.T) {
	restoreHardwareProfile := cacheHardwareProfileForTest(HardwareProfile{
		RAMGB:    16,
		Detected: true,
	})
	defer restoreHardwareProfile()

	// 1. Mock server returning exactly 25 models when requested (hasMore should be true)
	hfModels := buildHFSearchFixtures(25, func(index int) int64 {
		return 12 * 1024 * 1024 * 1024
	})
	server, requestedLimits := newHFSearchServer(t, hfModels)
	defer server.Close()

	_, app := newTestMarketplaceApp(t, server.URL)

	req1 := httptest.NewRequest("GET", "/api/marktplatz/search?provider=huggingface&limit=24&page=1", nil)
	resp1, err := app.Test(req1, 5000)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	body1 := decodeJSONBody(t, resp1.Body)
	models1 := modelListFromBody(t, body1["models"])
	if len(models1) != 24 {
		t.Errorf("expected 24 models, got %d", len(models1))
	}
	if body1["has_more"] != true {
		t.Errorf("expected has_more to be true when 25 models are available, got %v", body1["has_more"])
	}
	foundLimit25 := false
	for _, l := range *requestedLimits {
		if l == 25 {
			foundLimit25 = true
		}
	}
	if !foundLimit25 {
		t.Errorf("expected backend to request 25 models from HuggingFace, requested limits: %v", *requestedLimits)
	}

	// 2. Mock server returning exactly 24 models (hasMore should be false since we asked for 25 but only got 24)
	hfModels2 := buildHFSearchFixtures(24, func(index int) int64 {
		return 12 * 1024 * 1024 * 1024
	})
	server2, _ := newHFSearchServer(t, hfModels2)
	defer server2.Close()

	_, app2 := newTestMarketplaceApp(t, server2.URL)

	req2 := httptest.NewRequest("GET", "/api/marktplatz/search?provider=huggingface&limit=24&page=1", nil)
	resp2, err := app2.Test(req2, 5000)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	body2 := decodeJSONBody(t, resp2.Body)
	models2 := modelListFromBody(t, body2["models"])
	if len(models2) != 24 {
		t.Errorf("expected 24 models, got %d", len(models2))
	}
	if body2["has_more"] != false {
		t.Errorf("expected has_more to be false when only 24 models exist, got %v", body2["has_more"])
	}
}

func TestMarktplatzAPI_CategoryFilterExpandsProviderWindow(t *testing.T) {
	restoreHardwareProfile := cacheHardwareProfileForTest(HardwareProfile{RAMGB: 16, Detected: true})
	defer restoreHardwareProfile()

	hfModels := buildHFSearchFixtures(80, func(index int) int64 {
		return 4 * 1024 * 1024 * 1024
	})
	for index := range hfModels {
		if index >= 30 && index%2 == 0 {
			hfModels[index]["id"] = fmt.Sprintf("test/coder-model-%03d-GGUF", index)
		}
	}
	server, requestedLimits := newHFSearchServer(t, hfModels)
	defer server.Close()

	_, app := newTestMarketplaceApp(t, server.URL)
	req := httptest.NewRequest("GET", "/api/marktplatz/search?provider=huggingface&category=code&limit=24&page=1", nil)
	resp, err := app.Test(req, 5000)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	body := decodeJSONBody(t, resp.Body)
	models := modelListFromBody(t, body["models"])
	if len(models) != 24 {
		t.Fatalf("expected category search to collect 24 later matches, got %d", len(models))
	}
	if maxIntSlice(*requestedLimits) <= 25 {
		t.Fatalf("expected expanded provider window, requested limits: %v", *requestedLimits)
	}
}
