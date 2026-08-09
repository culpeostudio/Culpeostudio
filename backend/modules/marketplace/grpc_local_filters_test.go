package marketplace

import (
	"context"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
)

// local_only, gpu_fit and quantization all describe running a model on this
// machine, which the hosted providers never do. The schema cannot express that
// dependency between fields, so the service still has to.
func TestMarketplaceService_SearchRejectsLocalFiltersForCloudProviders(t *testing.T) {
	cases := []struct {
		name    string
		request *marketplacev1.SearchModelsRequest
		wantErr bool
	}{
		{
			name: "localOnly on OpenRouter",
			request: &marketplacev1.SearchModelsRequest{
				Provider:  marketplacev1.Provider_PROVIDER_OPENROUTER,
				LocalOnly: true,
			},
			wantErr: true,
		},
		{
			name: "gpuFit on OpenRouter",
			request: &marketplacev1.SearchModelsRequest{
				Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
				GpuFit:   true,
			},
			wantErr: true,
		},
		{
			name: "quantization on Featherless",
			request: &marketplacev1.SearchModelsRequest{
				Provider:     marketplacev1.Provider_PROVIDER_FEATHERLESS,
				Quantization: "Q4_K_M",
			},
			wantErr: true,
		},
		{
			name: "localOnly on HuggingFace allowed",
			request: &marketplacev1.SearchModelsRequest{
				Provider:  marketplacev1.Provider_PROVIDER_HUGGINGFACE,
				LocalOnly: true,
			},
		},
		{
			name: "providerAll with localOnly allowed",
			request: &marketplacev1.SearchModelsRequest{
				Provider:  marketplacev1.Provider_PROVIDER_ALL,
				LocalOnly: true,
			},
		},
		{
			name: "plain huggingface search allowed",
			request: &marketplacev1.SearchModelsRequest{
				Provider: marketplacev1.Provider_PROVIDER_HUGGINGFACE,
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			service := newTestService(t, `{"model_dir":"data/models"}`)

			_, err := service.SearchModels(context.Background(), tc.request)
			if !tc.wantErr {
				if err != nil {
					t.Fatalf("expected the search to be accepted, got %v", err)
				}
				return
			}

			requireCode(t, err, codes.InvalidArgument)
			message := strings.ToLower(err.Error())
			if !strings.Contains(message, "lokal") && !strings.Contains(message, "local") {
				t.Fatalf("expected actionable error message about local filters, got %q", err.Error())
			}
		})
	}
}
