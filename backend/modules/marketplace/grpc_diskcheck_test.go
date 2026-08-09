package marketplace

import (
	"context"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc/codes"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
)

func TestMarketplaceService_DownloadRejectsOversize(t *testing.T) {
	restore := cacheHardwareProfileForTest(HardwareProfile{
		DiskFreeBytes: 5 * 1024 * 1024 * 1024,
		Detected:      true,
	})
	defer restore()

	service := newTestService(t, `{"model_dir":"data/models"}`)

	_, err := service.StartDownload(context.Background(), &marketplacev1.StartDownloadRequest{
		Provider:  marketplacev1.Provider_PROVIDER_HUGGINGFACE,
		ModelId:   "org/big",
		SizeBytes: 21474836480,
	})
	// The request is well formed; the machine simply cannot hold the model,
	// which is a precondition rather than a bad argument.
	requireCode(t, err, codes.FailedPrecondition)

	// The numbers the HTTP body carried in separate fields now have to be in
	// the message, because that is all the client shows.
	message := strings.ToLower(err.Error())
	if !strings.Contains(message, "speicherplatz") {
		t.Fatalf("expected 'Speicherplatz' in message, got %q", err.Error())
	}
	if !strings.Contains(message, "5.0 gb") {
		t.Fatalf("expected the free space in the message, got %q", err.Error())
	}
	if !strings.Contains(message, "22.0 gb") {
		t.Fatalf("expected the required space including the margin, got %q", err.Error())
	}
}

func TestMarketplaceService_DownloadAcceptsUnknownSize(t *testing.T) {
	restore := cacheHardwareProfileForTest(HardwareProfile{
		DiskFreeBytes: 1024,
		Detected:      true,
	})
	defer restore()

	service := newTestService(t, `{
		"model_dir":"data/models",
		"openrouter_token":"mock"
	}`)

	// Without a size there is nothing to compare against, so the tiny amount of
	// free space must not block the job.
	response, err := service.StartDownload(context.Background(), &marketplacev1.StartDownloadRequest{
		Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
		ModelId:  "openai/gpt-4o",
	})
	if err != nil {
		t.Fatalf("size-less download failed: %v", err)
	}

	waitForJobCompletion(t, service, response.GetJobId(), 2*time.Second)
}
