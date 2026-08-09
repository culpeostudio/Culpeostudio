package modelcatalog

import (
	"bytes"
	"context"
	"encoding/binary"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"testing"
)

func TestScanGGUFMetadataIgnoresTransientProjectionAndEscapingSymlink(t *testing.T) {
	root := t.TempDir()
	modelPath := filepath.Join(root, "nested", "llama-Q4_K_M.gguf")
	writeTestGGUF(t, modelPath, "Catalog Llama")
	writeTestGGUF(t, filepath.Join(root, "nested", "vision-mmproj.gguf"), "projection")
	writeTestGGUF(t, filepath.Join(root, "nested", "unfinished.part.gguf"), "partial")
	if err := os.WriteFile(filepath.Join(root, "download.tmp"), []byte("temporary"), 0o600); err != nil {
		t.Fatal(err)
	}

	external := filepath.Join(t.TempDir(), "outside.gguf")
	writeTestGGUF(t, external, "outside")
	if err := os.Symlink(external, filepath.Join(root, "escape.gguf")); err != nil && runtime.GOOS != "windows" {
		t.Fatal(err)
	}

	records, err := Scan(context.Background(), root)
	if err != nil {
		t.Fatalf("Scan() error = %v", err)
	}
	if len(records) != 1 {
		t.Fatalf("Scan() returned %d records, want 1: %#v", len(records), records)
	}
	record := records[0]
	if !record.Complete || !record.Startable || record.Format != FormatGGUF {
		t.Fatalf("unexpected GGUF status: %#v", record)
	}
	if record.Metadata.Architecture != "llama" || record.Metadata.Layers != 2 || record.Metadata.KVHeads != 2 {
		t.Fatalf("metadata = %#v", record.Metadata)
	}
	if record.Metadata.ContextLength != 8192 || record.Metadata.HeadDimension != 32 {
		t.Fatalf("context/head metadata = %#v", record.Metadata)
	}
	if record.Metadata.ParameterCount != 6 || record.Metadata.Quantization != "Q4_K_M" {
		t.Fatalf("parameter/quantization metadata = %#v", record.Metadata)
	}
	if !strings.HasPrefix(record.ID, "mdl_") || !strings.HasPrefix(record.Fingerprint, "sha256:") {
		t.Fatalf("ID/fingerprint = %q / %q", record.ID, record.Fingerprint)
	}
	second, err := Scan(context.Background(), root)
	if err != nil || second[0].ID != record.ID || second[0].Fingerprint != record.Fingerprint {
		t.Fatalf("scan is not stable: %#v, %v", second, err)
	}
}

func TestScanDoesNotPublishMarketplaceStagingOrPreviousDirectories(t *testing.T) {
	root := t.TempDir()
	writeTestGGUF(t, filepath.Join(root, "repo.staging-download", "model.gguf"), "staging")
	writeTestGGUF(t, filepath.Join(root, "repo.previous", "model.gguf"), "previous")
	records, err := Scan(context.Background(), root)
	if err != nil {
		t.Fatal(err)
	}
	if len(records) != 0 {
		t.Fatalf("transient bundle directories leaked into catalog: %#v", records)
	}
}

func TestScanGGUFSplitGroupIsStableAcrossCompletion(t *testing.T) {
	root := t.TempDir()
	secondShard := filepath.Join(root, "model-00002-of-00002.gguf")
	writeTestGGUF(t, secondShard, "Split Model")

	before, err := Scan(context.Background(), root)
	if err != nil {
		t.Fatal(err)
	}
	if len(before) != 1 || before[0].Complete || !hasIssue(before[0], "missing_gguf_shard") {
		t.Fatalf("incomplete split = %#v", before)
	}
	id, fingerprint := before[0].ID, before[0].Fingerprint
	if before[0].RelativePath != "model-00001-of-00002.gguf" {
		t.Fatalf("logical split path = %q", before[0].RelativePath)
	}

	writeTestGGUF(t, filepath.Join(root, "model-00001-of-00002.gguf"), "Split Model")
	after, err := Scan(context.Background(), root)
	if err != nil {
		t.Fatal(err)
	}
	if len(after) != 1 || !after[0].Complete || len(after[0].Files) != 2 {
		t.Fatalf("completed split = %#v", after)
	}
	if after[0].ID != id {
		t.Fatalf("ID changed from %q to %q", id, after[0].ID)
	}
	if after[0].Fingerprint == fingerprint {
		t.Fatal("fingerprint did not change when a shard was added")
	}
	if after[0].Metadata.ParameterCount != 12 {
		t.Fatalf("split parameter count = %d, want 12", after[0].Metadata.ParameterCount)
	}
}

func hasIssue(record ModelRecord, code string) bool {
	for _, issue := range record.Issues {
		if issue.Code == code {
			return true
		}
	}
	return false
}

func writeTestGGUF(t *testing.T, path, name string) {
	t.Helper()
	type metadataEntry struct {
		key       string
		valueType uint32
		value     any
	}
	entries := []metadataEntry{
		{"general.architecture", ggufTypeString, "llama"},
		{"general.name", ggufTypeString, name},
		{"general.file_type", ggufTypeUint32, uint32(15)},
		{"llama.block_count", ggufTypeUint32, uint32(2)},
		{"llama.attention.head_count", ggufTypeUint32, uint32(4)},
		{"llama.attention.head_count_kv", ggufTypeUint32, uint32(2)},
		{"llama.embedding_length", ggufTypeUint32, uint32(128)},
		{"llama.context_length", ggufTypeUint32, uint32(8192)},
	}
	var contents bytes.Buffer
	contents.WriteString("GGUF")
	for _, value := range []any{uint32(3), uint64(1), uint64(len(entries))} {
		if err := binary.Write(&contents, binary.LittleEndian, value); err != nil {
			t.Fatal(err)
		}
	}
	for _, entry := range entries {
		writeGGUFString(t, &contents, entry.key)
		if err := binary.Write(&contents, binary.LittleEndian, entry.valueType); err != nil {
			t.Fatal(err)
		}
		if entry.valueType == ggufTypeString {
			writeGGUFString(t, &contents, entry.value.(string))
		} else if err := binary.Write(&contents, binary.LittleEndian, entry.value); err != nil {
			t.Fatal(err)
		}
	}
	writeGGUFString(t, &contents, "weight")
	for _, value := range []any{uint32(2), uint64(2), uint64(3), uint32(0), uint64(0)} {
		if err := binary.Write(&contents, binary.LittleEndian, value); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, contents.Bytes(), 0o600); err != nil {
		t.Fatal(err)
	}
}

func writeGGUFString(t *testing.T, buffer *bytes.Buffer, value string) {
	t.Helper()
	if err := binary.Write(buffer, binary.LittleEndian, uint64(len(value))); err != nil {
		t.Fatal(err)
	}
	buffer.WriteString(value)
}

func TestCatalogOrderIsDeterministic(t *testing.T) {
	root := t.TempDir()
	writeTestGGUF(t, filepath.Join(root, "z.gguf"), "z")
	writeTestGGUF(t, filepath.Join(root, "a.gguf"), "a")
	records, err := Scan(context.Background(), root)
	if err != nil {
		t.Fatal(err)
	}
	paths := []string{records[0].RelativePath, records[1].RelativePath}
	if !sort.StringsAreSorted(paths) {
		t.Fatalf("paths are not sorted: %v", paths)
	}
}
