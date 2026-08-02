package marktplatz

import (
	"context"
	"math"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/fillyengine/backend/modules/marktplatz/huggingface"
	"github.com/fillyengine/backend/modules/marktplatz/openrouter"
	"github.com/fillyengine/backend/modules/marktplatz/types"
)

func TestHuggingFaceSearchMapping(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[
  {
    "id": "org/example-model",
    "pipeline_tag": "text-generation",
    "siblings": [{"rfilename": "model.Q4_K_M.gguf"}],
    "tags": ["gguf", "text-generation"]
  }
]`))
	}))
	defer server.Close()

	module := New("")
	module.hfAPIBase = server.URL

	models, err := huggingface.SearchHuggingFace(context.Background(), module.metadataClient, module.hfAPIBase, "example", "gguf", 5, "")
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(models) != 1 {
		t.Fatalf("expected 1 model, got %d", len(models))
	}
	if models[0].Provider != types.ProviderHuggingFace {
		t.Fatalf("expected provider %q, got %q", types.ProviderHuggingFace, models[0].Provider)
	}
	if models[0].ModelID != "org/example-model" {
		t.Fatalf("unexpected model id %q", models[0].ModelID)
	}
}

func TestOpenRouterSearchMapping(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
  "data": [
    {
      "id": "meta-llama/llama-3-8b",
      "name": "Llama 3 8B",
      "description": "test model description",
      "context_length": 131072,
      "pricing": {
        "prompt": "0.0000001",
        "completion": "0"
      }
    }
  ]
}`))
	}))
	defer server.Close()

	module := New("")
	module.orAPIBase = server.URL
	openrouter.InvalidateCache()

	models, err := openrouter.SearchOpenRouter(context.Background(), module.metadataClient, module.orAPIBase, "llama", "", 5, "")
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(models) != 1 {
		t.Fatalf("expected 1 model, got %d", len(models))
	}
	if models[0].Provider != types.ProviderOpenRouter {
		t.Fatalf("expected provider %q, got %q", types.ProviderOpenRouter, models[0].Provider)
	}
	if models[0].ModelID != "meta-llama/llama-3-8b" {
		t.Fatalf("unexpected model id %q", models[0].ModelID)
	}
	if math.Abs(models[0].PricePer1MInput-0.1) > 1e-9 || math.Abs(models[0].PricePer1MOutput-0) > 1e-9 {
		t.Fatalf("expected parsed OpenRouter prices per 1M tokens, got %#v", models[0])
	}
	if !models[0].PriceKnown {
		t.Fatalf("expected OpenRouter price to be marked as known")
	}
	if models[0].ContextLength != 131072 {
		t.Fatalf("expected context length to be mapped, got %#v", models[0].ContextLength)
	}
}
