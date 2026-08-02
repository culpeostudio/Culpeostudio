package marktplatz

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestValidateGGUFSplits(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		assets  []string
		wantErr bool
	}{
		{name: "single file", assets: []string{"model-q4.gguf"}},
		{name: "complete group", assets: []string{"model-00001-of-00003.gguf", "model-00002-of-00003.gguf", "model-00003-of-00003.gguf"}},
		{name: "complete group in subdirectory", assets: []string{"quant/model-00001-of-00002.gguf", "quant/model-00002-of-00002.gguf"}},
		{name: "missing middle", assets: []string{"model-00001-of-00003.gguf", "model-00003-of-00003.gguf"}, wantErr: true},
		{name: "missing first", assets: []string{"model-00002-of-00002.gguf"}, wantErr: true},
		{name: "mismatched totals", assets: []string{"model-00001-of-00002.gguf", "model-00002-of-00003.gguf"}, wantErr: true},
		{name: "mismatched totals reverse order", assets: []string{"model-00002-of-00003.gguf", "model-00001-of-00002.gguf"}, wantErr: true},
		{name: "invalid part number", assets: []string{"model-00003-of-00002.gguf"}, wantErr: true},
	}
	for _, test := range tests {
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			err := validateGGUFSplits(test.assets)
			if test.wantErr && err == nil {
				t.Fatalf("validateGGUFSplits(%#v) unexpectedly succeeded", test.assets)
			}
			if !test.wantErr && err != nil {
				t.Fatalf("validateGGUFSplits(%#v) failed: %v", test.assets, err)
			}
		})
	}
}

func TestValidateSafeTensorBundleRequiresConfigTokenizerAndIndexShards(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	mustWriteTestFile(t, root, "config.json", `{}`)
	mustWriteTestFile(t, root, "tokenizer/tokenizer.json", `{}`)
	mustWriteTestFile(t, root, "weights/model-00001-of-00002.safetensors", "one")
	mustWriteTestFile(t, root, "model.safetensors.index.json", `{
  "weight_map": {
    "a": "weights/model-00001-of-00002.safetensors",
    "b": "weights/model-00002-of-00002.safetensors"
  }
}`)

	assets := []string{
		"config.json", "tokenizer/tokenizer.json", "model.safetensors.index.json",
		"weights/model-00001-of-00002.safetensors",
	}
	err := validateBundleFiles(root, "safetensors", assets)
	if err == nil || !strings.Contains(err.Error(), "model-00002-of-00002.safetensors") {
		t.Fatalf("expected missing index shard error, got %v", err)
	}

	mustWriteTestFile(t, root, "weights/model-00002-of-00002.safetensors", "two")
	assets = append(assets, "weights/model-00002-of-00002.safetensors")
	if err := validateBundleFiles(root, "safetensors", assets); err != nil {
		t.Fatalf("complete SafeTensors bundle rejected: %v", err)
	}

	if err := os.Remove(filepath.Join(root, "config.json")); err != nil {
		t.Fatalf("remove config: %v", err)
	}
	err = validateBundleFiles(root, "safetensors", assets)
	if err == nil || !strings.Contains(err.Error(), "config.json") {
		t.Fatalf("expected missing config error, got %v", err)
	}
}

func TestValidateSafeTensorBundleRejectsEmptyIndex(t *testing.T) {
	t.Parallel()
	root := t.TempDir()
	mustWriteTestFile(t, root, "config.json", `{}`)
	mustWriteTestFile(t, root, "tokenizer.json", `{}`)
	mustWriteTestFile(t, root, "model.safetensors", "weights")
	mustWriteTestFile(t, root, "model.safetensors.index.json", `{"weight_map":{}}`)

	err := validateBundleFiles(root, "safetensors", []string{
		"config.json", "tokenizer.json", "model.safetensors", "model.safetensors.index.json",
	})
	if err == nil || !strings.Contains(err.Error(), "keine Gewichte") {
		t.Fatalf("expected empty weight_map error, got %v", err)
	}
}

func TestValidateAndPublishBundleWritesAtomicCompletionManifest(t *testing.T) {
	t.Parallel()

	base := t.TempDir()
	staging := filepath.Join(base, "bundle.staging-job")
	final := filepath.Join(base, "bundle")
	if err := os.MkdirAll(staging, 0o755); err != nil {
		t.Fatalf("mkdir staging: %v", err)
	}
	if err := os.MkdirAll(final, 0o755); err != nil {
		t.Fatalf("mkdir old final: %v", err)
	}
	mustWriteTestFile(t, final, "old.txt", "old bundle")
	mustWriteTestFile(t, staging, "quant/model.gguf", "GGUF-test-content")

	manifestPath, err := validateAndPublishBundle(staging, final, bundleManifest{
		Provider: "huggingface", Repository: "acme/tiny", Revision: "main",
		CommitSHA: "deadbeef", Format: "gguf",
	}, []string{"quant/model.gguf"})
	if err != nil {
		t.Fatalf("validateAndPublishBundle failed: %v", err)
	}
	if manifestPath != filepath.Join(final, completionManifestName) {
		t.Fatalf("manifest path = %q", manifestPath)
	}
	if _, err := os.Stat(staging); !os.IsNotExist(err) {
		t.Fatalf("staging directory still exists after publish: %v", err)
	}
	if _, err := os.Stat(final + ".previous"); !os.IsNotExist(err) {
		t.Fatalf("backup directory still exists after publish: %v", err)
	}
	if _, err := os.Stat(filepath.Join(final, "old.txt")); !os.IsNotExist(err) {
		t.Fatalf("old bundle content survived replacement: %v", err)
	}
	if _, err := os.Stat(manifestPath + ".tmp"); !os.IsNotExist(err) {
		t.Fatalf("temporary manifest survived publish: %v", err)
	}

	data, err := os.ReadFile(manifestPath)
	if err != nil {
		t.Fatalf("read manifest: %v", err)
	}
	var manifest bundleManifest
	if err := json.Unmarshal(data, &manifest); err != nil {
		t.Fatalf("decode manifest: %v", err)
	}
	if manifest.SchemaVersion != 1 || manifest.Provider != "huggingface" || manifest.Repository != "acme/tiny" || manifest.CommitSHA != "deadbeef" {
		t.Fatalf("unexpected manifest metadata: %#v", manifest)
	}
	if manifest.CreatedAt.IsZero() || manifest.CreatedAt.Location().String() != "UTC" {
		t.Fatalf("manifest created_at must be populated in UTC: %v", manifest.CreatedAt)
	}
	if len(manifest.Files) != 1 {
		t.Fatalf("manifest should hash exactly the downloaded asset, got %#v", manifest.Files)
	}
	wantHash := sha256.Sum256([]byte("GGUF-test-content"))
	want := bundleManifestFile{Path: "quant/model.gguf", Size: int64(len("GGUF-test-content")), SHA256: hex.EncodeToString(wantHash[:])}
	if manifest.Files[0] != want {
		t.Fatalf("manifest file = %#v, want %#v", manifest.Files[0], want)
	}
}

func TestValidateAndPublishBundleFailurePreservesExistingFinal(t *testing.T) {
	t.Parallel()

	base := t.TempDir()
	staging := filepath.Join(base, "bundle.staging-job")
	final := filepath.Join(base, "bundle")
	if err := os.MkdirAll(staging, 0o755); err != nil {
		t.Fatalf("mkdir staging: %v", err)
	}
	if err := os.MkdirAll(final, 0o755); err != nil {
		t.Fatalf("mkdir final: %v", err)
	}
	mustWriteTestFile(t, final, "sentinel.txt", "last known good")

	mustWriteTestFile(t, staging, "model.gguf", "complete")
	mustWriteTestFile(t, staging, "download.tmp", "partial")

	_, err := validateAndPublishBundle(staging, final, bundleManifest{Format: "gguf"}, []string{"model.gguf"})
	if err == nil || !strings.Contains(err.Error(), "unvollstaendige oder unsichere Datei") {
		t.Fatalf("expected temporary-file validation error, got %v", err)
	}
	data, readErr := os.ReadFile(filepath.Join(final, "sentinel.txt"))
	if readErr != nil || string(data) != "last known good" {
		t.Fatalf("existing final was changed after failed publish: data=%q err=%v", data, readErr)
	}
	if _, statErr := os.Stat(filepath.Join(final, completionManifestName)); !os.IsNotExist(statErr) {
		t.Fatalf("completion manifest was published for invalid bundle: %v", statErr)
	}
}

func mustWriteTestFile(t *testing.T, root, relative, contents string) {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", relative, err)
	}
	if err := os.WriteFile(path, []byte(contents), 0o644); err != nil {
		t.Fatalf("write %s: %v", relative, err)
	}
}
