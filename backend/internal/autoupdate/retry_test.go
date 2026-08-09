package autoupdate

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func countingAssetServer(t *testing.T, payload []byte, failures int32) (*httptest.Server, *atomic.Int32) {
	t.Helper()
	var requests atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		if requests.Add(1) <= failures {
			http.Error(writer, "temporarily unavailable", http.StatusServiceUnavailable)
			return
		}
		_, _ = writer.Write(payload)
	}))
	t.Cleanup(server.Close)
	return server, &requests
}

func testClient(t *testing.T, serverURL string) *Client {
	t.Helper()
	host := strings.Split(strings.TrimPrefix(serverURL, "http://"), ":")[0]
	client, err := NewClientForTesting(serverURL, NewOriginPolicy([]string{host}, true), nil)
	if err != nil {
		t.Fatal(err)
	}
	client.retryDelay = time.Millisecond
	return client
}

func TestDownloadAssetRetriesTransientFailures(t *testing.T) {
	t.Parallel()
	payload := []byte("verified update payload")
	checksum := sha256.Sum256(payload)
	server, requests := countingAssetServer(t, payload, downloadAttempts-1)
	client := testClient(t, server.URL)

	asset := Asset{
		URL:    server.URL,
		SHA256: hex.EncodeToString(checksum[:]),
		Size:   int64(len(payload)),
	}
	destination := filepath.Join(t.TempDir(), "update.tar.gz")
	if err := client.DownloadAsset(context.Background(), asset, destination); err != nil {
		t.Fatalf("DownloadAsset() error = %v", err)
	}
	if got := requests.Load(); got != downloadAttempts {
		t.Fatalf("requests = %d, want %d", got, downloadAttempts)
	}
}

func TestDownloadAssetGivesUpAfterRepeatedFailures(t *testing.T) {
	t.Parallel()
	server, requests := countingAssetServer(t, []byte("unused"), downloadAttempts+1)
	client := testClient(t, server.URL)

	asset := Asset{URL: server.URL, SHA256: strings.Repeat("a", 64), Size: 6}
	err := client.DownloadAsset(context.Background(), asset, filepath.Join(t.TempDir(), "update"))
	if err == nil {
		t.Fatal("DownloadAsset() unexpectedly succeeded")
	}
	if got := requests.Load(); got != downloadAttempts {
		t.Fatalf("requests = %d, want %d", got, downloadAttempts)
	}
}

func TestDownloadAssetDoesNotRetryContentMismatch(t *testing.T) {
	t.Parallel()

	server, requests := countingAssetServer(t, []byte("wrong payload"), 0)
	client := testClient(t, server.URL)

	asset := Asset{URL: server.URL, SHA256: strings.Repeat("a", 64), Size: 13}
	if err := client.DownloadAsset(context.Background(), asset, filepath.Join(t.TempDir(), "update")); err == nil {
		t.Fatal("DownloadAsset() unexpectedly accepted a checksum mismatch")
	}
	if got := requests.Load(); got != 1 {
		t.Fatalf("requests = %d, want 1", got)
	}
}

func TestDownloadAssetDoesNotRetryNotFound(t *testing.T) {
	t.Parallel()
	var requests atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		requests.Add(1)
		http.NotFound(writer, nil)
	}))
	t.Cleanup(server.Close)
	client := testClient(t, server.URL)

	asset := Asset{URL: server.URL, SHA256: strings.Repeat("a", 64), Size: 6}
	if err := client.DownloadAsset(context.Background(), asset, filepath.Join(t.TempDir(), "update")); err == nil {
		t.Fatal("DownloadAsset() unexpectedly succeeded")
	}
	if got := requests.Load(); got != 1 {
		t.Fatalf("requests = %d, want 1", got)
	}
}
