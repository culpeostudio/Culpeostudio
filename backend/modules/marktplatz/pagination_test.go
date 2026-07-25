package marktplatz

import (
	"testing"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

func TestPaginateModels(t *testing.T) {
	models := make([]types.ModelSummary, 0, 45)
	for i := 0; i < 45; i++ {
		models = append(models, types.ModelSummary{ModelID: "m"})
	}

	page1, hasMore1 := paginateModels(models, 1, 20)
	if len(page1) != 20 || !hasMore1 {
		t.Fatalf("expected page1 len=20 hasMore=true, got len=%d hasMore=%v", len(page1), hasMore1)
	}

	page3, hasMore3 := paginateModels(models, 3, 20)
	if len(page3) != 5 || hasMore3 {
		t.Fatalf("expected page3 len=5 hasMore=false, got len=%d hasMore=%v", len(page3), hasMore3)
	}
}
