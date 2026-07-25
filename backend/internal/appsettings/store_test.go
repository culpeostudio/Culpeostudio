package appsettings

import (
	"os"
	"path/filepath"
	"testing"
)

func TestStoreLoadDefaultsWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	store := NewStore(filepath.Join(tmpDir, "settings.json"))

	if err := store.Load(); err != nil {
		t.Fatalf("Load failed: %v", err)
	}

	got := store.Get()
	if got.ModelDir != DefaultModelDir {
		t.Fatalf("expected default model dir %q, got %q", DefaultModelDir, got.ModelDir)
	}
}

func TestStoreUpdatePersistsAndTokenFlags(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	store := NewStore(settingsPath)
	if err := store.Load(); err != nil {
		t.Fatalf("Load failed: %v", err)
	}

	modelDir := filepath.Join(tmpDir, "models")
	hfToken := "hf_test_123"
	orToken := "or_test_456"
	flToken := "fl_test_abc"

	if _, err := store.Update(Update{
		ModelDir:         &modelDir,
		HuggingFaceToken: &hfToken,
		OpenRouterToken:  &orToken,
		FeatherlessToken: &flToken,
	}); err != nil {
		t.Fatalf("Update failed: %v", err)
	}

	// Load fresh store from disk to verify persistence.
	fresh := NewStore(settingsPath)
	if err := fresh.Load(); err != nil {
		t.Fatalf("fresh Load failed: %v", err)
	}

	got := fresh.Get()
	if got.ModelDir != modelDir {
		t.Fatalf("expected model dir %q, got %q", modelDir, got.ModelDir)
	}
	if got.HuggingFaceToken != hfToken {
		t.Fatalf("expected hf token %q, got %q", hfToken, got.HuggingFaceToken)
	}
	if got.OpenRouterToken != orToken {
		t.Fatalf("expected openrouter token %q, got %q", orToken, got.OpenRouterToken)
	}
	if got.FeatherlessToken != flToken {
		t.Fatalf("expected featherless token %q, got %q", flToken, got.FeatherlessToken)
	}

	data, err := os.ReadFile(settingsPath)
	if err != nil {
		t.Fatalf("read settings file failed: %v", err)
	}
	if len(data) == 0 {
		t.Fatalf("settings file should not be empty")
	}
}

func TestSeparateStoresSeeUpdatedModelDirectoryImmediately(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	writer := NewStore(settingsPath)
	reader := NewStore(settingsPath)
	if err := writer.Load(); err != nil {
		t.Fatalf("writer load: %v", err)
	}
	if err := reader.Load(); err != nil {
		t.Fatalf("reader load: %v", err)
	}

	modelDir := filepath.Join(tmpDir, "chosen-models")
	if _, err := writer.Update(Update{ModelDir: &modelDir}); err != nil {
		t.Fatalf("writer update: %v", err)
	}
	if err := reader.Load(); err != nil {
		t.Fatalf("reader reload: %v", err)
	}
	if got := reader.Get().ModelDir; got != modelDir {
		t.Fatalf("expected second store to see %q, got %q", modelDir, got)
	}
	if info, err := os.Stat(modelDir); err != nil || !info.IsDir() {
		t.Fatalf("expected selected model directory to exist, stat=%v info=%v", err, info)
	}
}

func TestEngineReserveExpertValuesPreserveZeroAndCanResetToAuto(t *testing.T) {
	store := NewStore(filepath.Join(t.TempDir(), "settings.json"))
	if err := store.Load(); err != nil {
		t.Fatal(err)
	}
	zero := int64(0)
	if _, err := store.Update(Update{EngineRAMReserveBytes: &zero, EngineGPUReserveBytes: &zero}); err != nil {
		t.Fatal(err)
	}
	got := store.Get()
	if got.EngineRAMReserveBytes == nil || *got.EngineRAMReserveBytes != 0 || got.EngineGPUReserveBytes == nil || *got.EngineGPUReserveBytes != 0 {
		t.Fatalf("explicit zero reserves were not retained: %#v", got)
	}
	if _, err := store.Update(Update{ResetEngineReserves: true}); err != nil {
		t.Fatal(err)
	}
	got = store.Get()
	if got.EngineRAMReserveBytes != nil || got.EngineGPUReserveBytes != nil {
		t.Fatalf("reset did not restore automatic reserves: %#v", got)
	}
}
