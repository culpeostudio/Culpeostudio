package autoupdate

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
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

func TestInstallActivatesVerifiedBundle(t *testing.T) {
	t.Parallel()
	archive := testBundleArchive(t)
	checksum := sha256.Sum256(archive)
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		_, _ = writer.Write(archive)
	}))
	t.Cleanup(server.Close)
	host := strings.Split(strings.TrimPrefix(server.URL, "http://"), ":")[0]
	client, err := NewClientForTesting(server.URL, NewOriginPolicy([]string{host}, true), server.Client())
	if err != nil {
		t.Fatal(err)
	}
	asset := Asset{
		URL:       server.URL,
		SHA256:    hex.EncodeToString(checksum[:]),
		Size:      int64(len(archive)),
		Format:    "tar.gz",
		Launcher:  Entrypoint{Path: "launcher/myphiloengine"},
		Backend:   Entrypoint{Path: "backend/server"},
		Frontend:  Entrypoint{Path: "frontend/app"},
		HealthURL: "http://127.0.0.1:8080/health",
	}
	manifest := Manifest{
		SchemaVersion: ManifestSchemaVersion,
		Version:       "1.2.3",
		Assets:        map[string]Asset{"linux-x64": asset},
	}
	root := t.TempDir()
	state, err := client.Install(context.Background(), root, manifest, asset)
	if err != nil {
		t.Fatalf("Install() error = %v", err)
	}
	loaded, err := LoadCurrent(root)
	if err != nil {
		t.Fatalf("LoadCurrent() error = %v", err)
	}
	if loaded != state {
		t.Fatalf("LoadCurrent() = %#v, want %#v", loaded, state)
	}
	bundle, err := ResolveInstalledBundle(root, loaded)
	if err != nil {
		t.Fatalf("ResolveInstalledBundle() error = %v", err)
	}
	if _, err := os.Stat(bundle.Backend); err != nil {
		t.Fatal(err)
	}
}

func TestInstallReusesAnAlreadyInstalledBundle(t *testing.T) {
	t.Parallel()
	archive := testBundleArchive(t)
	checksum := sha256.Sum256(archive)
	server, requests := countingAssetServer(t, archive, 0)
	client := testClient(t, server.URL)
	asset := Asset{
		URL:      server.URL,
		SHA256:   hex.EncodeToString(checksum[:]),
		Size:     int64(len(archive)),
		Format:   "tar.gz",
		Launcher: Entrypoint{Path: "launcher/myphiloengine"},
		Backend:  Entrypoint{Path: "backend/server"},
		Frontend: Entrypoint{Path: "frontend/app"},
	}
	manifest := Manifest{
		SchemaVersion: ManifestSchemaVersion,
		Version:       "1.2.3",
		Assets:        map[string]Asset{"linux-x64": asset},
	}
	root := t.TempDir()
	if _, err := client.Install(context.Background(), root, manifest, asset); err != nil {
		t.Fatalf("Install() error = %v", err)
	}

	state, err := client.Install(context.Background(), root, manifest, asset)
	if err != nil {
		t.Fatalf("second Install() error = %v", err)
	}
	if got := requests.Load(); got != 1 {
		t.Fatalf("asset requests = %d, want 1", got)
	}
	if _, err := ResolveInstalledBundle(root, state); err != nil {
		t.Fatalf("ResolveInstalledBundle() error = %v", err)
	}
}

func TestInstallRejectsAForeignBundleDirectory(t *testing.T) {
	t.Parallel()
	archive := testBundleArchive(t)
	checksum := sha256.Sum256(archive)
	server, requests := countingAssetServer(t, archive, 0)
	client := testClient(t, server.URL)
	asset := Asset{
		URL:      server.URL,
		SHA256:   hex.EncodeToString(checksum[:]),
		Size:     int64(len(archive)),
		Format:   "tar.gz",
		Launcher: Entrypoint{Path: "launcher/myphiloengine"},
		Backend:  Entrypoint{Path: "backend/server"},
		Frontend: Entrypoint{Path: "frontend/app"},
	}
	manifest := Manifest{
		SchemaVersion: ManifestSchemaVersion,
		Version:       "1.2.3",
		Assets:        map[string]Asset{"linux-x64": asset},
	}
	root := t.TempDir()
	target := filepath.Join(root, "versions", "1.2.3-"+asset.SHA256[:12])
	if err := os.MkdirAll(target, 0o755); err != nil {
		t.Fatal(err)
	}
	if _, err := client.Install(context.Background(), root, manifest, asset); err == nil {
		t.Fatal("Install() unexpectedly overwrote an unrecognised bundle directory")
	}
	if got := requests.Load(); got != 0 {
		t.Fatalf("asset requests = %d, want 0", got)
	}
}

func TestLoadCurrentRejectsEscapingBundle(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	payload := `{
		"schema_version": 1,
		"version": "1.0.0",
		"bundle": "../outside",
		"asset_sha256": "` + strings.Repeat("a", 64) + `",
		"updated_at": "2026-07-26T12:00:00Z"
	}`
	if err := os.WriteFile(filepath.Join(root, currentStateFilename), []byte(payload), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := LoadCurrent(root); err == nil {
		t.Fatal("LoadCurrent() unexpectedly accepted an escaping bundle")
	}
}

func testBundleArchive(t *testing.T) []byte {
	t.Helper()
	var output bytes.Buffer
	gzipWriter := gzip.NewWriter(&output)
	tarWriter := tar.NewWriter(gzipWriter)
	for name, content := range map[string]string{
		"launcher/myphiloengine": "#!/bin/sh\nexit 0\n",
		"backend/server":         "#!/bin/sh\nexit 0\n",
		"frontend/app":           "#!/bin/sh\nexit 0\n",
	} {
		payload := []byte(content)
		if err := tarWriter.WriteHeader(&tar.Header{
			Name: name,
			Mode: 0o755,
			Size: int64(len(payload)),
		}); err != nil {
			t.Fatalf("WriteHeader(%s): %v", name, err)
		}
		if _, err := tarWriter.Write(payload); err != nil {
			t.Fatalf("Write(%s): %v", name, err)
		}
	}
	if err := tarWriter.Close(); err != nil {
		t.Fatal(err)
	}
	if err := gzipWriter.Close(); err != nil {
		t.Fatal(err)
	}
	return output.Bytes()
}

func ExampleCurrentState() {
	state := CurrentState{Version: "1.2.3", Bundle: "versions/1.2.3-abcd"}
	fmt.Println(state.Version, state.Bundle)
	// Output: 1.2.3 versions/1.2.3-abcd
}
