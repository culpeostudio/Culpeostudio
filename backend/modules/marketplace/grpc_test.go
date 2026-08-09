package marketplace

import (
	"context"
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

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/modules/marketplace/openrouter"
)

func TestMarketplaceService_SearchAndDownloadJob(t *testing.T) {
	service := newTestService(t, `{
  "model_dir": "data/models",
  "openrouter_token": "mock-token"
}
`)

	searchResponse, err := service.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
		Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
		Query:    "gemini",
	})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if searchResponse.GetPageSize() != defaultPageSize {
		t.Fatalf("expected the default page size to be reported, got %d", searchResponse.GetPageSize())
	}

	downloadResponse, err := service.StartDownload(context.Background(), &marketplacev1.StartDownloadRequest{
		Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
		ModelId:  "google/gemini-2.5-pro",
	})
	if err != nil {
		t.Fatalf("download failed: %v", err)
	}
	jobID := downloadResponse.GetJobId()
	if strings.TrimSpace(jobID) == "" {
		t.Fatalf("job_id missing in download response")
	}

	if _, err := service.GetDownloadJob(context.Background(), &marketplacev1.GetDownloadJobRequest{Id: jobID}); err != nil {
		t.Fatalf("job lookup failed: %v", err)
	}
	waitForJobCompletion(t, service, jobID, 3*time.Second)

	hardwareResponse, err := service.GetHardwareProfile(context.Background(), &marketplacev1.GetHardwareProfileRequest{})
	if err != nil {
		t.Fatalf("hardware profile failed: %v", err)
	}
	if hardwareResponse.GetProfile() == nil {
		t.Fatalf("expected a hardware profile in the response")
	}

	if _, err := service.DeleteDownloadJob(context.Background(), &marketplacev1.DeleteDownloadJobRequest{Id: jobID}); err != nil {
		t.Fatalf("delete failed: %v", err)
	}
}

// A provider outside the enum can only reach the backend from a client built
// against a newer schema. The free-form provider string the HTTP API took made
// this the common case; here it is the exception, and it is still refused.
func TestMarketplaceService_UnknownProviderRejected(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)

	_, err := service.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
		Provider: marketplacev1.Provider(99),
	})
	requireCode(t, err, codes.InvalidArgument)
}

func TestMarketplaceService_DetailAcceptsNamespacedModelID(t *testing.T) {
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
	service := newTestService(t, `{"model_dir":"data/models"}`)
	service.module.orAPIBase = provider.URL

	// The id travels as a proto field, so the slash needs no escaping - the
	// query parameter it replaced had to be percent-encoded and decoded again.
	response, err := service.GetModelDetail(context.Background(), &marketplacev1.GetModelDetailRequest{
		Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
		Id:       "openai/gpt-5.6-luna-pro",
	})
	if err != nil {
		t.Fatalf("detail request failed: %v", err)
	}
	if got := response.GetDetail().GetSummary().GetModelId(); got != "openai/gpt-5.6-luna-pro" {
		t.Fatalf("model_id = %q, want %q", got, "openai/gpt-5.6-luna-pro")
	}
}

func TestMarketplaceService_DetailRequiresConcreteProvider(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)

	for _, provider := range []marketplacev1.Provider{
		marketplacev1.Provider_PROVIDER_UNSPECIFIED,
		marketplacev1.Provider_PROVIDER_ALL,
	} {
		_, err := service.GetModelDetail(context.Background(), &marketplacev1.GetModelDetailRequest{
			Provider: provider,
			Id:       "org/model",
		})
		requireCode(t, err, codes.InvalidArgument)
	}
}

func TestMarketplaceService_StartActiveAPIModel(t *testing.T) {
	service := newTestService(t, `{
  "model_dir": "data/models",
  "openrouter_token": "mock-openrouter",
  "featherless_token": "mock-featherless"
}`)

	startResponse, err := service.StartApiModel(context.Background(), &marketplacev1.StartApiModelRequest{
		Provider:    marketplacev1.Provider_PROVIDER_OPENROUTER,
		ModelId:     "openai/gpt-4o",
		DisplayName: "GPT-4o",
	})
	if err != nil {
		t.Fatalf("start api model failed: %v", err)
	}
	modelRef := startResponse.GetModel().GetModelRef()
	if strings.TrimSpace(modelRef) == "" {
		t.Fatalf("expected model_ref")
	}

	listResponse, err := service.ListActiveApiModels(context.Background(), &marketplacev1.ListActiveApiModelsRequest{})
	if err != nil {
		t.Fatalf("list active models failed: %v", err)
	}
	if len(listResponse.GetModels()) != 1 {
		t.Fatalf("expected one active model, got %d", len(listResponse.GetModels()))
	}

	if _, err := service.DeleteActiveApiModel(context.Background(), &marketplacev1.DeleteActiveApiModelRequest{
		ModelRef: modelRef,
	}); err != nil {
		t.Fatalf("delete active model failed: %v", err)
	}
}

func TestMarketplaceService_StartAPIModelValidation(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)

	cases := []struct {
		name    string
		request *marketplacev1.StartApiModelRequest
		want    codes.Code
	}{
		{
			// A HuggingFace repository is downloaded and run locally, so there
			// is no hosted API to start it against.
			name: "huggingface rejected",
			request: &marketplacev1.StartApiModelRequest{
				Provider: marketplacev1.Provider_PROVIDER_HUGGINGFACE,
				ModelId:  "org/model",
			},
			want: codes.InvalidArgument,
		},
		{
			// The provider and model are fine; what is missing is the token in
			// the settings, which the user has to add first.
			name: "missing openrouter token",
			request: &marketplacev1.StartApiModelRequest{
				Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
				ModelId:  "openai/gpt-4o",
			},
			want: codes.FailedPrecondition,
		},
		{
			name: "missing model id",
			request: &marketplacev1.StartApiModelRequest{
				Provider: marketplacev1.Provider_PROVIDER_FEATHERLESS,
			},
			want: codes.InvalidArgument,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := service.StartApiModel(context.Background(), tc.request)
			requireCode(t, err, tc.want)
		})
	}
}

func TestMarketplaceService_GPUFitSearchExpandsUntilPageCanBeFilled(t *testing.T) {
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

	service := newTestHuggingFaceService(t, server.URL)

	response, err := service.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
		Provider:  marketplacev1.Provider_PROVIDER_ALL,
		LocalOnly: true,
		GpuFit:    true,
		PageSize:  24,
		Page:      1,
	})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(response.GetModels()) != 24 {
		t.Fatalf("expected expanded search to fill first page with 24 runnable models, got %d", len(response.GetModels()))
	}
	if !response.GetHasMore() {
		t.Fatalf("expected has_more to stay true after expanded gpu search")
	}
	if maxIntSlice(*requestedLimits) <= 192 {
		t.Fatalf("expected huggingface search window to expand beyond 192, got %#v", *requestedLimits)
	}
}

func TestMarketplaceService_GPUFitSearchKeepsHasMoreWhenMoreFitsExistPastCurrentWindow(t *testing.T) {
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

	service := newTestHuggingFaceService(t, server.URL)

	searchPage := func(page int32) *marketplacev1.SearchModelsResponse {
		t.Helper()
		response, err := service.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
			Provider:  marketplacev1.Provider_PROVIDER_ALL,
			LocalOnly: true,
			GpuFit:    true,
			PageSize:  24,
			Page:      page,
		})
		if err != nil {
			t.Fatalf("page %d search failed: %v", page, err)
		}
		return response
	}

	pageOne := searchPage(1)
	if len(pageOne.GetModels()) != 24 {
		t.Fatalf("expected first page to return 24 runnable models, got %d", len(pageOne.GetModels()))
	}
	if !pageOne.GetHasMore() {
		t.Fatalf("expected page 1 has_more to stay true when more gpu-fit models exist later")
	}

	pageTwo := searchPage(2)
	if len(pageTwo.GetModels()) != 16 {
		t.Fatalf("expected second page to return remaining 16 runnable models, got %d", len(pageTwo.GetModels()))
	}
	if pageTwo.GetHasMore() {
		t.Fatalf("expected page 2 has_more to be false after all runnable models were returned")
	}
}

func TestMarketplaceService_SearchHuggingFaceHasMoreNormal(t *testing.T) {
	restoreHardwareProfile := cacheHardwareProfileForTest(HardwareProfile{
		RAMGB:    16,
		Detected: true,
	})
	defer restoreHardwareProfile()

	hfModels := buildHFSearchFixtures(25, func(index int) int64 {
		return 12 * 1024 * 1024 * 1024
	})
	server, requestedLimits := newHFSearchServer(t, hfModels)
	defer server.Close()

	service := newTestHuggingFaceService(t, server.URL)

	response, err := service.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
		Provider: marketplacev1.Provider_PROVIDER_HUGGINGFACE,
		PageSize: 24,
		Page:     1,
	})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(response.GetModels()) != 24 {
		t.Errorf("expected 24 models, got %d", len(response.GetModels()))
	}
	if !response.GetHasMore() {
		t.Errorf("expected has_more to be true when 25 models are available")
	}
	foundLimit25 := false
	for _, limit := range *requestedLimits {
		if limit == 25 {
			foundLimit25 = true
		}
	}
	if !foundLimit25 {
		t.Errorf("expected backend to request 25 models from HuggingFace, requested limits: %v", *requestedLimits)
	}

	exactModels := buildHFSearchFixtures(24, func(index int) int64 {
		return 12 * 1024 * 1024 * 1024
	})
	exactServer, _ := newHFSearchServer(t, exactModels)
	defer exactServer.Close()

	exactService := newTestHuggingFaceService(t, exactServer.URL)
	exactResponse, err := exactService.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
		Provider: marketplacev1.Provider_PROVIDER_HUGGINGFACE,
		PageSize: 24,
		Page:     1,
	})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(exactResponse.GetModels()) != 24 {
		t.Errorf("expected 24 models, got %d", len(exactResponse.GetModels()))
	}
	if exactResponse.GetHasMore() {
		t.Errorf("expected has_more to be false when only 24 models exist")
	}
}

func TestMarketplaceService_CategoryFilterExpandsProviderWindow(t *testing.T) {
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

	service := newTestHuggingFaceService(t, server.URL)
	response, err := service.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
		Provider: marketplacev1.Provider_PROVIDER_HUGGINGFACE,
		Category: marketplacev1.Category_CATEGORY_CODE,
		PageSize: 24,
		Page:     1,
	})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(response.GetModels()) != 24 {
		t.Fatalf("expected category search to collect 24 later matches, got %d", len(response.GetModels()))
	}
	if maxIntSlice(*requestedLimits) <= 25 {
		t.Fatalf("expected expanded provider window, requested limits: %v", *requestedLimits)
	}
}

// newTestService builds the service on a module backed by a throwaway settings
// file. The service is called directly, the way the settings module's tests do:
// the interceptors it would sit behind on a real listener are covered in
// internal/grpcmw.
func newTestService(t *testing.T, settingsJSON string) *grpcService {
	t.Helper()

	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	if err := os.WriteFile(settingsPath, []byte(settingsJSON), 0o600); err != nil {
		t.Fatalf("write settings failed: %v", err)
	}

	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module failed: %v", err)
	}
	return &grpcService{module: module}
}

func newTestHuggingFaceService(t *testing.T, hfAPIBase string) *grpcService {
	t.Helper()

	service := newTestService(t, `{"model_dir":"data/models"}`)
	service.module.hfAPIBase = hfAPIBase
	return service
}

func requireCode(t *testing.T, err error, want codes.Code) {
	t.Helper()

	if err == nil {
		t.Fatalf("expected %s, got no error", want)
	}
	if got := status.Code(err); got != want {
		t.Fatalf("status code = %s, want %s (%v)", got, want, err)
	}
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

func maxIntSlice(values []int) int {
	best := 0
	for _, value := range values {
		if value > best {
			best = value
		}
	}
	return best
}

func waitForJobCompletion(t *testing.T, service *grpcService, jobID string, timeout time.Duration) {
	t.Helper()

	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		response, err := service.GetDownloadJob(context.Background(), &marketplacev1.GetDownloadJobRequest{Id: jobID})
		if err != nil {
			t.Fatalf("job poll failed: %v", err)
		}
		switch response.GetJob().GetStatus() {
		case marketplacev1.DownloadStatus_DOWNLOAD_STATUS_DONE,
			marketplacev1.DownloadStatus_DOWNLOAD_STATUS_FAILED:
			return
		}

		time.Sleep(50 * time.Millisecond)
	}

	t.Fatalf("job %s did not finish within %s", jobID, timeout)
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
