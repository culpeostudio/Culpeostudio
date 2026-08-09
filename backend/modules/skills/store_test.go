package skills

import (
	"os"
	"path/filepath"
	"testing"
)

func TestStoreImportCopiesSkillAndBlocksDuplicate(t *testing.T) {
	tmpDir := t.TempDir()
	source := filepath.Join(tmpDir, "source")
	writeSkillFile(t, source, `---
name: data-tool
description: Works with local datasets.
license: Apache-2.0
metadata:
  author: test
allowed-tools: Read Grep
---

# Data Tool

Inspect datasets carefully.
`)
	if err := os.MkdirAll(filepath.Join(source, "scripts"), 0o755); err != nil {
		t.Fatalf("mkdir scripts: %v", err)
	}
	if err := os.WriteFile(filepath.Join(source, "scripts", "helper.py"), []byte("print('ok')\n"), 0o700); err != nil {
		t.Fatalf("write script: %v", err)
	}
	if err := os.MkdirAll(filepath.Join(source, "references"), 0o755); err != nil {
		t.Fatalf("mkdir references: %v", err)
	}
	if err := os.WriteFile(filepath.Join(source, "references", "api.md"), []byte("# API\n"), 0o600); err != nil {
		t.Fatalf("write reference: %v", err)
	}

	store := NewStore(filepath.Join(tmpDir, "skills"))
	if err := store.Load(); err != nil {
		t.Fatalf("Load failed: %v", err)
	}
	record, err := store.Import(source, true)
	if err != nil {
		t.Fatalf("Import failed: %v", err)
	}
	if record.Name != "data-tool" || !record.Enabled || !record.FileSummary.HasScripts || !record.FileSummary.HasReferences {
		t.Fatalf("unexpected record: %+v", record)
	}
	if _, err := os.Stat(filepath.Join(tmpDir, "skills", "data-tool", "scripts", "helper.py")); err != nil {
		t.Fatalf("expected script to be copied: %v", err)
	}
	if _, err := store.Import(source, true); err == nil {
		t.Fatalf("expected duplicate import to fail")
	}
}

func TestStoreSetEnabledDeleteAndRescan(t *testing.T) {
	tmpDir := t.TempDir()
	source := filepath.Join(tmpDir, "source")
	writeSkillFile(t, source, `---
name: review-helper
description: Reviews code changes.
---

# Review Helper

Focus on bugs and missing tests.
`)

	store := NewStore(filepath.Join(tmpDir, "skills"))
	if err := store.Load(); err != nil {
		t.Fatalf("Load failed: %v", err)
	}
	if _, err := store.Import(source, true); err != nil {
		t.Fatalf("Import failed: %v", err)
	}
	updated, err := store.SetEnabled("review-helper", false)
	if err != nil {
		t.Fatalf("SetEnabled failed: %v", err)
	}
	if updated.Enabled {
		t.Fatalf("expected skill to be disabled")
	}
	rescanned, err := store.Rescan()
	if err != nil {
		t.Fatalf("Rescan failed: %v", err)
	}
	if len(rescanned) != 1 || rescanned[0].Enabled {
		t.Fatalf("expected rescan to preserve disabled state, got %+v", rescanned)
	}
	if err := store.Delete("review-helper"); err != nil {
		t.Fatalf("Delete failed: %v", err)
	}
	if got := store.List(); len(got) != 0 {
		t.Fatalf("expected empty list after delete, got %+v", got)
	}
}
