package marketplace

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/culpeohq/backend/modules/marketplace/types"
)

func TestDownloadJobCancelOnDelete(t *testing.T) {
	store := NewDownloadJobStore()
	job := store.Create(types.ProviderHuggingFace, "org/model", "weights.gguf", "data/models")

	cancelled := make(chan struct{})
	var once sync.Once
	store.RegisterCancel(job.ID, func() {
		once.Do(func() { close(cancelled) })
	})

	if !store.Delete(job.ID) {
		t.Fatalf("delete should report true for an existing job")
	}

	select {
	case <-cancelled:

	case <-time.After(time.Second):
		t.Fatalf("cancel func was not invoked after Delete")
	}

	if _, ok := store.Get(job.ID); ok {
		t.Fatalf("job should be removed after Delete")
	}
}

func TestDownloadJobUnregisterCancelCleanup(t *testing.T) {
	store := NewDownloadJobStore()
	job := store.Create(types.ProviderHuggingFace, "org/model", "weights.gguf", "data/models")

	store.RegisterCancel(job.ID, func() {})
	store.UnregisterCancel(job.ID)

	if !store.Delete(job.ID) {
		t.Fatalf("delete should still work after UnregisterCancel")
	}
}

func TestRegisterCancelKeepsContextAlive(t *testing.T) {
	store := NewDownloadJobStore()
	job := store.Create(types.ProviderHuggingFace, "org/model", "weights.gguf", "data/models")

	ctx, cancel := context.WithCancel(context.Background())
	store.RegisterCancel(job.ID, cancel)
	defer cancel()

	store.Delete(job.ID)

	<-ctx.Done()
	if ctx.Err() != context.Canceled {
		t.Fatalf("expected context.Canceled, got %v", ctx.Err())
	}
}
