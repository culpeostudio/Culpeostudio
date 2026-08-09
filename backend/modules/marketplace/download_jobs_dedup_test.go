package marketplace

import (
	"testing"

	"github.com/culpeohq/backend/modules/marketplace/types"
)

func TestDownloadJobStoreDedupActiveJob(t *testing.T) {
	store := NewDownloadJobStore()

	first := store.Create(types.ProviderHuggingFace, "org/model", "weights.gguf", "data/models")
	store.SetRunning(first.ID)

	if got, ok := store.ActiveJobForModel(types.ProviderHuggingFace, "org/model"); !ok {
		t.Fatalf("expected to find active job for org/model")
	} else if got.ID != first.ID {
		t.Fatalf("expected active job %s, got %s", first.ID, got.ID)
	}

	if _, ok := store.ActiveJobForModel(types.ProviderOpenRouter, "org/model"); ok {
		t.Fatalf("dedup should only match same provider")
	}

	store.SetDone(first.ID, "data/models/weights.gguf")
	if _, ok := store.ActiveJobForModel(types.ProviderHuggingFace, "org/model"); ok {
		t.Fatalf("dedup should not match a finished job")
	}

	fail := store.Create(types.ProviderHuggingFace, "org/model", "weights.gguf", "data/models")
	store.SetFailed(fail.ID, dummyErr("netz"))
	if _, ok := store.ActiveJobForModel(types.ProviderHuggingFace, "org/model"); ok {
		t.Fatalf("dedup should not match a failed job")
	}
}

type dummyErr string

func (e dummyErr) Error() string { return string(e) }
