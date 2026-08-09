package marketplace

import (
	"context"
	"strings"
	"testing"
	"time"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
)

func TestMarketplaceService_DownloadDedupReturnsExistingJob(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)

	request := &marketplacev1.StartDownloadRequest{
		Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
		ModelId:  "openai/gpt-4o",
	}

	first, err := service.StartDownload(context.Background(), request)
	if err != nil {
		t.Fatalf("first download failed: %v", err)
	}
	if strings.TrimSpace(first.GetJobId()) == "" {
		t.Fatalf("first job_id missing")
	}
	if first.GetExisting() {
		t.Fatalf("first request must not be flagged existing")
	}

	second, err := service.StartDownload(context.Background(), request)
	if err != nil {
		t.Fatalf("second download failed: %v", err)
	}
	if second.GetJobId() != first.GetJobId() {
		t.Fatalf("expected dedup to return same job_id %q, got %q", first.GetJobId(), second.GetJobId())
	}
	if !second.GetExisting() {
		t.Fatalf("expected existing=true on dedup response")
	}
	// The German sentence the JSON body carried is gone: the flag says what
	// happened and the client phrases it in the user's own language.
	if second.GetTargetDir() == "" {
		t.Fatalf("expected the dedup response to name the target directory")
	}

	waitForJobCompletion(t, service, first.GetJobId(), 2*time.Second)
}
