package marketplace

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/modules/marketplace/openrouter"
)

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

func newTestOpenRouterService(t *testing.T, apiBase string) *grpcService {
	t.Helper()

	openrouter.InvalidateCache()
	service := newTestService(t, `{"model_dir":"data/models"}`)
	service.module.orAPIBase = apiBase
	return service
}

func TestMarketplaceService_OpenRouterPaginatesBeyondFirstPage(t *testing.T) {
	restoreHardwareProfile := cacheHardwareProfileForTest(HardwareProfile{
		RAMGB:    16,
		Detected: true,
	})
	defer restoreHardwareProfile()

	server := newOpenRouterSearchServer(t, 60)
	defer server.Close()

	service := newTestOpenRouterService(t, server.URL)

	searchPage := func(page int32) *marketplacev1.SearchModelsResponse {
		t.Helper()
		response, err := service.SearchModels(context.Background(), &marketplacev1.SearchModelsRequest{
			Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
			PageSize: 24,
			Page:     page,
		})
		if err != nil {
			t.Fatalf("page %d request failed: %v", page, err)
		}
		return response
	}

	first := searchPage(1)
	if len(first.GetModels()) != 24 {
		t.Fatalf("expected 24 models on page 1, got %d", len(first.GetModels()))
	}
	if !first.GetHasMore() {
		t.Fatalf("expected has_more true while 60 models exist")
	}

	last := searchPage(3)
	if len(last.GetModels()) != 12 {
		t.Fatalf("expected 12 models on page 3, got %d", len(last.GetModels()))
	}
	if last.GetHasMore() {
		t.Fatalf("expected has_more false on the last page")
	}
}
