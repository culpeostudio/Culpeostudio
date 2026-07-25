package marktplatz

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/modules/marktplatz/types"
)

func TestHuggingFaceBundlePublishesManifestBeforeModelDownloadedEvent(t *testing.T) {
	// The event bus is process-global. Do not run this test in parallel with
	// other tests that may also assert model download events.
	const (
		modelID  = "bundle-event-test/tiny"
		commit   = "deadbeef-event-test"
		asset    = "weights/model.gguf"
		contents = "GGUF event fixture"
	)

	provider := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/api/models/" + modelID:
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"id":       modelID,
				"sha":      commit,
				"siblings": []map[string]interface{}{{"rfilename": asset, "size": len(contents)}},
			})
		case "/" + modelID + "/resolve/" + commit + "/" + asset:
			w.Header().Set("Content-Length", "18")
			_, _ = w.Write([]byte(contents))
		default:
			http.NotFound(w, r)
		}
	}))
	defer provider.Close()

	tmpDir := t.TempDir()
	modelDir := filepath.Join(tmpDir, "models")
	settingsPath := filepath.Join(tmpDir, "settings.json")
	settings, err := json.Marshal(map[string]string{"model_dir": modelDir})
	if err != nil {
		t.Fatalf("marshal settings: %v", err)
	}
	if err := os.WriteFile(settingsPath, settings, 0o600); err != nil {
		t.Fatalf("write settings: %v", err)
	}

	module := New(settingsPath)
	module.hfAPIBase = provider.URL
	module.metadataClient = provider.Client()
	module.downloadClient = provider.Client()
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize module: %v", err)
	}

	events := make(chan bus.Event, 1)
	bus.Get().On(bus.EventModelDownloaded, func(event bus.Event) {
		if event.Data["model_id"] != modelID {
			return
		}
		select {
		case events <- event:
		default:
		}
	})

	job := module.jobs.CreateWithAssetsAndRevision(types.ProviderHuggingFace, modelID, asset, []string{asset}, modelDir, "main")
	module.runDownloadJob(job.ID)

	completed, ok := module.jobs.Get(job.ID)
	if !ok {
		t.Fatal("completed job disappeared")
	}
	if completed.Status != DownloadStatusDone || completed.CommitSHA != commit {
		t.Fatalf("unexpected completed job: %#v", completed)
	}
	manifestPath := filepath.Join(completed.OutputPath, completionManifestName)
	if _, err := os.Stat(manifestPath); err != nil {
		t.Fatalf("completion manifest missing when job became done: %v", err)
	}
	if got, err := os.ReadFile(filepath.Join(completed.OutputPath, filepath.FromSlash(asset))); err != nil || string(got) != contents {
		t.Fatalf("relative asset path was not preserved: data=%q err=%v", got, err)
	}

	select {
	case event := <-events:
		if event.Source != "marktplatz" {
			t.Fatalf("event source = %q", event.Source)
		}
		if event.Data["job_id"] != job.ID || event.Data["commit_sha"] != commit || event.Data["path"] != completed.OutputPath {
			t.Fatalf("event did not describe published bundle: %#v", event.Data)
		}
		if _, err := os.Stat(filepath.Join(event.Data["path"].(string), completionManifestName)); err != nil {
			t.Fatalf("event fired before completion manifest became visible: %v", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for EventModelDownloaded")
	}
}
