package marketplace

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/internal/apimodels"
)

func TestMarketplaceService_StartAPIModelLimitReached(t *testing.T) {
	service := newTestService(t, `{
	"model_dir": "data/models",
	"openrouter_token": "mock-token"
}`)

	for i := 0; i < apimodels.MaxActiveModels; i++ {
		_, err := service.StartApiModel(context.Background(), &marketplacev1.StartApiModelRequest{
			Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
			ModelId:  fmt.Sprintf("v/m-%d", i),
		})
		if err != nil {
			t.Fatalf("start %d failed: %v", i, err)
		}
	}

	// A full slot list is a quota problem, not a malformed request, so it is
	// reported as RESOURCE_EXHAUSTED where the HTTP API only had 400.
	_, err := service.StartApiModel(context.Background(), &marketplacev1.StartApiModelRequest{
		Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
		ModelId:  "v/overflow",
	})
	requireCode(t, err, codes.ResourceExhausted)

	// The message has to name the limit: it is what the user needs in order to
	// know how many models to remove.
	if !strings.Contains(err.Error(), fmt.Sprintf("%d", apimodels.MaxActiveModels)) {
		t.Fatalf("expected the limit in the error message, got %q", err.Error())
	}
}
