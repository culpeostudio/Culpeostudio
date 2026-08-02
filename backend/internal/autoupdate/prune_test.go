package autoupdate

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func makeBundleDir(t *testing.T, root, name string) string {
	t.Helper()
	path := filepath.Join(root, "versions", name)
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

func makeAgedDir(t *testing.T, parent, name string, age time.Duration) string {
	t.Helper()
	path := filepath.Join(parent, name)
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatal(err)
	}
	stamp := time.Now().Add(-age)
	if err := os.Chtimes(path, stamp, stamp); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestPruneVersionsKeepsActiveAndRollback(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	active := quarantineState("1.2.3", strings.Repeat("a", 64))
	rollback := quarantineState("1.2.2", strings.Repeat("b", 64))
	activeDir := makeBundleDir(t, root, filepath.Base(active.Bundle))
	rollbackDir := makeBundleDir(t, root, filepath.Base(rollback.Bundle))
	obsoleteDir := makeBundleDir(t, root, "1.0.0-cccccccccccc")

	if err := PruneVersions(root, active, rollback); err != nil {
		t.Fatalf("PruneVersions() error = %v", err)
	}
	for _, kept := range []string{activeDir, rollbackDir} {
		if _, err := os.Stat(kept); err != nil {
			t.Fatalf("PruneVersions() removed %s: %v", kept, err)
		}
	}
	if _, err := os.Stat(obsoleteDir); !os.IsNotExist(err) {
		t.Fatalf("PruneVersions() kept the obsolete bundle: %v", err)
	}
}

func TestPruneVersionsRemovesOnlyStaleTemporaries(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	active := quarantineState("1.2.3", strings.Repeat("a", 64))
	makeBundleDir(t, root, filepath.Base(active.Bundle))
	versionsRoot := filepath.Join(root, "versions")

	staleStaging := makeAgedDir(t, versionsRoot, stagingPrefix+"old", 48*time.Hour)
	freshStaging := makeAgedDir(t, versionsRoot, stagingPrefix+"new", time.Minute)
	staleWork := makeAgedDir(t, root, updateWorkPrefix+"old", 48*time.Hour)
	freshWork := makeAgedDir(t, root, updateWorkPrefix+"new", time.Minute)

	if err := PruneVersions(root, active); err != nil {
		t.Fatalf("PruneVersions() error = %v", err)
	}
	for _, removed := range []string{staleStaging, staleWork} {
		if _, err := os.Stat(removed); !os.IsNotExist(err) {
			t.Fatalf("PruneVersions() kept abandoned %s: %v", removed, err)
		}
	}

	for _, kept := range []string{freshStaging, freshWork} {
		if _, err := os.Stat(kept); err != nil {
			t.Fatalf("PruneVersions() removed in-flight %s: %v", kept, err)
		}
	}
}

func TestPruneVersionsRefusesWithoutAKnownBundle(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	existing := makeBundleDir(t, root, "1.2.3-aaaaaaaaaaaa")
	if err := PruneVersions(root); err != nil {
		t.Fatalf("PruneVersions() error = %v", err)
	}
	if _, err := os.Stat(existing); err != nil {
		t.Fatalf("PruneVersions() wiped the installation without a keep set: %v", err)
	}
	if err := PruneVersions(root, CurrentState{Version: "not-semver"}); err != nil {
		t.Fatalf("PruneVersions() error = %v", err)
	}
	if _, err := os.Stat(existing); err != nil {
		t.Fatalf("PruneVersions() wiped the installation for an invalid keep state: %v", err)
	}
}
