package marketplace

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/culpeohq/backend/modules/marketplace/types"
)

func TestRunDownloadJobDescriptorFileName(t *testing.T) {
	cases := []struct {
		name    string
		modelID string
		want    string
	}{
		{"nested org model", "openrouter/openai/gpt-4o", "gpt-4o.json"},
		{"slash-free model id", "gpt-4o", "gpt-4o.json"},
		{"featherless with org", "featherless/openai/gpt-4o", "gpt-4o.json"},
		{"two segments", "Anthropic/Claude-3", "Claude-3.json"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			tmpDir := t.TempDir()
			settingsPath := filepath.Join(tmpDir, "settings.json")
			if err := os.WriteFile(settingsPath, []byte(`{"model_dir":"data/models"}`), 0o600); err != nil {
				t.Fatalf("write settings: %v", err)
			}
			module := New(settingsPath)
			if err := module.Initialize(); err != nil {
				t.Fatalf("init: %v", err)
			}

			job := module.jobs.Create(types.ProviderOpenRouter, tc.modelID, "", filepath.Join(tmpDir, "downloads"))
			go module.runDownloadJob(job.ID)

			deadline := time.Now().Add(3 * time.Second)
			var judged []string
			for time.Now().Before(deadline) {
				entries, err := os.ReadDir(filepath.Join(tmpDir, "downloads"))
				if err == nil {
					for _, e := range entries {
						if !e.IsDir() && strings.HasSuffix(e.Name(), ".json") {
							judged = append(judged, e.Name())
						}
					}
					if len(judged) > 0 {
						break
					}
				}
				time.Sleep(30 * time.Millisecond)
			}
			if len(judged) == 0 {
				t.Fatalf("no descriptor file written")
			}
			if judged[0] != tc.want {
				t.Fatalf("descriptor filename: expected %q, got %q", tc.want, judged[0])
			}
		})
	}
}
