package autoupdate

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func quarantineState(version, checksum string) CurrentState {
	return CurrentState{
		SchemaVersion: ManifestSchemaVersion,
		Version:       version,
		Bundle:        "versions/" + version + "-" + checksum[:12],
		AssetSHA256:   checksum,
		UpdatedAt:     "2026-07-26T12:00:00Z",
	}
}

func TestQuarantineBlocksOnlyTheFailedBuild(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	broken := strings.Repeat("a", 64)
	if err := QuarantineBundle(root, quarantineState("1.2.3", broken), "frontend exited during startup"); err != nil {
		t.Fatalf("QuarantineBundle() error = %v", err)
	}
	quarantine, err := LoadQuarantine(root)
	if err != nil {
		t.Fatalf("LoadQuarantine() error = %v", err)
	}
	if !quarantine.Contains("1.2.3", strings.ToUpper(broken)) {
		t.Fatal("Contains() did not match the quarantined build")
	}
	if quarantine.Contains("1.2.4", broken) {
		t.Fatal("Contains() blocked a different version")
	}
	// A republished build of the same version has a new checksum and must stay
	// installable, otherwise a bad release could never be fixed in place.
	if quarantine.Contains("1.2.3", strings.Repeat("b", 64)) {
		t.Fatal("Contains() blocked a rebuilt asset of the same version")
	}
}

func TestQuarantineIsIdempotentAndBounded(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	state := quarantineState("1.2.3", strings.Repeat("a", 64))
	for range 3 {
		if err := QuarantineBundle(root, state, "boom"); err != nil {
			t.Fatalf("QuarantineBundle() error = %v", err)
		}
	}
	quarantine, err := LoadQuarantine(root)
	if err != nil {
		t.Fatalf("LoadQuarantine() error = %v", err)
	}
	if len(quarantine.Entries) != 1 {
		t.Fatalf("entries = %d, want 1", len(quarantine.Entries))
	}

	for index := range maxQuarantineEntries + 5 {
		checksum := strings.Repeat("0", 60) + string("0123456789abcdef"[index%16]) + "abc"
		if err := QuarantineBundle(root, quarantineState("2.0.0", checksum), "boom"); err != nil {
			t.Fatalf("QuarantineBundle() error = %v", err)
		}
	}
	quarantine, err = LoadQuarantine(root)
	if err != nil {
		t.Fatalf("LoadQuarantine() error = %v", err)
	}
	if len(quarantine.Entries) > maxQuarantineEntries {
		t.Fatalf("entries = %d, want at most %d", len(quarantine.Entries), maxQuarantineEntries)
	}
}

func TestLoadQuarantineTreatsMissingListAsEmpty(t *testing.T) {
	t.Parallel()
	quarantine, err := LoadQuarantine(t.TempDir())
	if err != nil {
		t.Fatalf("LoadQuarantine() error = %v", err)
	}
	if len(quarantine.Entries) != 0 {
		t.Fatalf("entries = %d, want 0", len(quarantine.Entries))
	}
}

func TestLoadQuarantineReportsCorruptListAsEmpty(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, quarantineFilename), []byte("{oops"), 0o600); err != nil {
		t.Fatal(err)
	}
	quarantine, err := LoadQuarantine(root)
	if err == nil {
		t.Fatal("LoadQuarantine() unexpectedly accepted a corrupt list")
	}
	// The caller keeps updating on a corrupt list, so it must be empty and not
	// silently block every version.
	if quarantine.Contains("1.2.3", strings.Repeat("a", 64)) {
		t.Fatal("corrupt list blocked a version")
	}
}
