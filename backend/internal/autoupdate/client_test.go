package autoupdate

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestClientFetchesManifestAndVerifiedAsset(t *testing.T) {
	t.Parallel()
	assetPayload := []byte("verified update payload")
	checksum := sha256.Sum256(assetPayload)

	var server *httptest.Server
	server = httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/manifest.json":
			writer.Header().Set("Content-Type", "application/json")
			_, _ = fmt.Fprintf(writer, `{
				"schema_version": 1,
				"version": "1.1.0",
				"assets": {
					"linux-x64": {
						"url": %q,
						"sha256": %q,
						"size": %d,
						"format": "tar.gz",
						"launcher": {"path": "launcher/culpeostudio"},
						"backend": {"path": "backend/server"},
						"frontend": {"path": "frontend/app"}
					}
				}
			}`, server.URL+"/asset.tar.gz", hex.EncodeToString(checksum[:]), len(assetPayload))
		case "/asset.tar.gz":
			_, _ = writer.Write(assetPayload)
		default:
			http.NotFound(writer, request)
		}
	}))
	t.Cleanup(server.Close)

	host := strings.Split(strings.TrimPrefix(server.URL, "http://"), ":")[0]
	policy := NewOriginPolicy([]string{host}, true)
	client, err := NewClientForTesting(server.URL+"/manifest.json", policy, server.Client())
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := client.FetchManifest(context.Background())
	if err != nil {
		t.Fatalf("FetchManifest() error = %v", err)
	}
	asset := manifest.Assets["linux-x64"]
	destination := filepath.Join(t.TempDir(), "update.tar.gz")
	if err := client.DownloadAsset(context.Background(), asset, destination); err != nil {
		t.Fatalf("DownloadAsset() error = %v", err)
	}
	got, err := os.ReadFile(destination)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != string(assetPayload) {
		t.Fatalf("download = %q, want %q", got, assetPayload)
	}
}

func TestClientDeletesChecksumMismatch(t *testing.T) {
	t.Parallel()
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		_, _ = writer.Write([]byte("bad"))
	}))
	t.Cleanup(server.Close)
	host := strings.Split(strings.TrimPrefix(server.URL, "http://"), ":")[0]
	client, err := NewClientForTesting(server.URL, NewOriginPolicy([]string{host}, true), server.Client())
	if err != nil {
		t.Fatal(err)
	}
	destination := filepath.Join(t.TempDir(), "asset")
	asset := Asset{
		URL:    server.URL,
		SHA256: strings.Repeat("a", 64),
		Size:   3,
	}
	if err := client.DownloadAsset(context.Background(), asset, destination); err == nil {
		t.Fatal("DownloadAsset() unexpectedly accepted a checksum mismatch")
	}
	if _, err := os.Stat(destination); !os.IsNotExist(err) {
		t.Fatalf("partial download still exists: %v", err)
	}
}

func TestGitHubOriginPolicyAcceptsReleaseDownloads(t *testing.T) {
	t.Parallel()

	for _, rawURL := range []string{
		"https://raw.githubusercontent.com/culpeohq/CulpeoStudio/main/quikinstall/manifest.json",
		"https://github.com/culpeohq/CulpeoStudio/releases/download/v1.0.0/culpeostudio-1.0.0-linux-x64.tar.gz",
		"https://objects.githubusercontent.com/some/redirected/path",
		"https://release-assets.githubusercontent.com/some/redirected/path",
	} {
		if _, err := GitHubOriginPolicy().Validate(rawURL); err != nil {
			t.Errorf("Validate(%q) error = %v", rawURL, err)
		}
	}
}

func TestGitHubOriginPolicyRejectsUntrustedHost(t *testing.T) {
	t.Parallel()
	if _, err := GitHubOriginPolicy().Validate("https://example.com/update.zip"); err == nil {
		t.Fatal("GitHub policy unexpectedly accepted an untrusted host")
	}
	if _, err := GitHubOriginPolicy().Validate("http://github.com/update.zip"); err == nil {
		t.Fatal("GitHub policy unexpectedly accepted HTTP")
	}
}
