package marktplatz

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

// TestDownloadJobCancelOnDelete prueft, dass Delete einer laufenden Job-ID
// die hinterlegte CancelFunc ausloest. Frueher lief die Download-Goroutine
// bei "Abbrechen" weiter – der Button war wirkungslos.
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
		// ok – cancels wurde synchron ausgeloesst
	case <-time.After(time.Second):
		t.Fatalf("cancel func was not invoked after Delete")
	}

	if _, ok := store.Get(job.ID); ok {
		t.Fatalf("job should be removed after Delete")
	}
}

// TestDownloadJobUnregisterCancelCleanup stellt sicher, dass nach
// runDownloadJob-Ende (done/failed) die hinterlegte CancelFunc entfernt wird,
// so dass kein toter Referenz-ptr im Store uebrigbleibt.
func TestDownloadJobUnregisterCancelCleanup(t *testing.T) {
	store := NewDownloadJobStore()
	job := store.Create(types.ProviderHuggingFace, "org/model", "weights.gguf", "data/models")

	store.RegisterCancel(job.ID, func() {})
	store.UnregisterCancel(job.ID)

	// Nach cleanup darf ein spaeteres Delete keine panic wegen nil map
	// ausloesen; cancel fehlt einfach, der Job wird nur geloescht.
	if !store.Delete(job.ID) {
		t.Fatalf("delete should still work after UnregisterCancel")
	}
}

// TestRegisterCancelKeepsContextAlive dokumentiert das Zusammenspiel mit
// echten context.CancelFunc – die Goroutine soll ctx.Err() beobachten.
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
