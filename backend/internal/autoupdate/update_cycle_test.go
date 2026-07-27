package autoupdate

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

// TestFailedUpdateIsQuarantinedAndReclaimed walks the cycle that used to repeat
// on every start: a release installs, fails to start, gets rolled back, and is
// then downloaded again. The quarantine list must stop the retry and the prune
// pass must give the disk space back.
func TestFailedUpdateIsQuarantinedAndReclaimed(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("the test bundle uses shell entrypoints")
	}
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
	// Stand in for the version that was running before the update.
	previous := quarantineState("1.2.2", "bb"+hex.EncodeToString(checksum[:])[2:])
	previousDir := makeBundleDir(t, root, filepath.Base(previous.Bundle))

	state, err := client.Install(context.Background(), root, manifest, asset)
	if err != nil {
		t.Fatalf("Install() error = %v", err)
	}
	bundle, err := ResolveInstalledBundle(root, state)
	if err != nil {
		t.Fatalf("ResolveInstalledBundle() error = %v", err)
	}

	// The bundled entrypoints exit immediately, which is exactly the startup
	// failure that triggers a rollback.
	runErr := RunBundle(context.Background(), root, bundle, io.Discard, io.Discard)
	if !IsStartupError(runErr) {
		t.Fatalf("RunBundle() error = %v, want a startup error", runErr)
	}
	if err := QuarantineBundle(root, state, runErr.Error()); err != nil {
		t.Fatalf("QuarantineBundle() error = %v", err)
	}
	if err := ActivateState(root, previous); err == nil {
		// The stand-in has no metadata, so activation is expected to refuse it.
		t.Fatal("ActivateState() accepted a bundle without metadata")
	}

	quarantine, err := LoadQuarantine(root)
	if err != nil {
		t.Fatalf("LoadQuarantine() error = %v", err)
	}
	if !quarantine.Contains(manifest.Version, asset.SHA256) {
		t.Fatal("the failed release was not quarantined")
	}

	// Next start: the release is skipped, so nothing is downloaded again and the
	// broken bundle is removed.
	if err := PruneVersions(root, previous); err != nil {
		t.Fatalf("PruneVersions() error = %v", err)
	}
	if _, err := os.Stat(bundle.Root); !os.IsNotExist(err) {
		t.Fatalf("the quarantined bundle still occupies disk: %v", err)
	}
	if _, err := os.Stat(previousDir); err != nil {
		t.Fatalf("PruneVersions() removed the rollback target: %v", err)
	}
	if got := requests.Load(); got != 1 {
		t.Fatalf("asset requests = %d, want 1", got)
	}
}
