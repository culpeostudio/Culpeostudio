package marketplace

import (
	"testing"

	"github.com/culpeohq/backend/modules/marketplace/types"
)

func TestDownloadJobLifecycle(t *testing.T) {
	store := NewDownloadJobStore()
	job := store.Create(types.ProviderHuggingFace, "org/model", "weights.gguf", "data/models")
	if job.Status != DownloadStatusQueued {
		t.Fatalf("expected queued, got %s", job.Status)
	}

	store.SetRunning(job.ID)
	store.SetProgress(job.ID, 42)
	store.SetDone(job.ID, "data/models/weights.gguf")

	got, ok := store.Get(job.ID)
	if !ok {
		t.Fatalf("job should exist")
	}
	if got.Status != DownloadStatusDone {
		t.Fatalf("expected done, got %s", got.Status)
	}
	if got.Progress != 100 {
		t.Fatalf("expected progress 100, got %d", got.Progress)
	}
	if got.OutputPath == "" {
		t.Fatalf("expected output path")
	}
}

func TestDownloadJobKeepsKnownCombinedSize(t *testing.T) {
	store := NewDownloadJobStore()
	job := store.CreateWithAssets(
		types.ProviderHuggingFace,
		"org/sharded-model",
		"model-00001-of-00002.safetensors",
		[]string{"model-00001-of-00002.safetensors", "model-00002-of-00002.safetensors"},
		"data/models",
	)
	store.SetExpectedBytes(job.ID, 12*1024*1024*1024)
	store.SetRunning(job.ID)
	store.SetStats(job.ID, 2*1024*1024*1024, 6*1024*1024*1024, 100)

	got, ok := store.Get(job.ID)
	if !ok {
		t.Fatal("job should exist")
	}
	if got.TotalBytes != 12*1024*1024*1024 {
		t.Fatalf("expected combined total to remain 12 GiB, got %d", got.TotalBytes)
	}
}
