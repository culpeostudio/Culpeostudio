package modelcatalog

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
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

func TestScanCompleteSafeTensorsBundle(t *testing.T) {
	root := t.TempDir()
	dir := filepath.Join(root, "provider", "repo", "revision")
	writeJSONFile(t, filepath.Join(dir, "config.json"), map[string]any{
		"model_type": "llama", "architectures": []string{"LlamaForCausalLM"},
		"num_hidden_layers": 4, "num_attention_heads": 8, "num_key_value_heads": 2,
		"hidden_size": 256, "max_position_embeddings": 16384, "sliding_window": 4096,
		"torch_dtype": "bfloat16",
	})
	writeJSONFile(t, filepath.Join(dir, "tokenizer.json"), map[string]any{"version": "1.0"})
	writeJSONFile(t, filepath.Join(dir, "tokenizer_config.json"), map[string]any{"chat_template": "{{ messages }}"})
	writeSafeTensors(t, filepath.Join(dir, "model.safetensors"), "BF16", []int64{2, 3})

	records, err := Scan(context.Background(), root)
	if err != nil {
		t.Fatal(err)
	}
	if len(records) != 1 {
		t.Fatalf("records = %#v", records)
	}
	record := records[0]
	if !record.Complete || record.Format != FormatSafeTensors || record.RelativePath != "provider/repo/revision" {
		t.Fatalf("record = %#v", record)
	}
	if record.Metadata.Layers != 4 || record.Metadata.KVHeads != 2 || record.Metadata.HeadDimension != 32 || record.Metadata.ParameterCount != 6 {
		t.Fatalf("metadata = %#v", record.Metadata)
	}
	if record.Metadata.StoredTensorDataType != "BF16" || record.Metadata.ContextLength != 16384 {
		t.Fatalf("dtype/context metadata = %#v", record.Metadata)
	}
	if got := strings.Join(record.RuntimeCandidates, ","); got != "vllm,transformers" {
		t.Fatalf("runtime candidates = %q", got)
	}
}

func TestScanSafeTensorsValidatesIndexAndShards(t *testing.T) {
	t.Run("multiple shards need index", func(t *testing.T) {
		root := t.TempDir()
		writeSafeBundleSidecars(t, root)
		writeSafeTensors(t, filepath.Join(root, "model-00001-of-00002.safetensors"), "F16", []int64{2})
		writeSafeTensors(t, filepath.Join(root, "model-00002-of-00002.safetensors"), "F16", []int64{2})
		records, err := Scan(context.Background(), root)
		if err != nil {
			t.Fatal(err)
		}
		if len(records) != 1 || records[0].Complete || !hasIssue(records[0], "safetensors_index_missing") {
			t.Fatalf("record = %#v", records)
		}
	})

	t.Run("index references every shard", func(t *testing.T) {
		root := t.TempDir()
		writeSafeBundleSidecars(t, root)
		writeSafeTensors(t, filepath.Join(root, "model-00001-of-00002.safetensors"), "F16", []int64{2})
		writeJSONFile(t, filepath.Join(root, "model.safetensors.index.json"), map[string]any{
			"metadata": map[string]any{"total_size": 8},
			"weight_map": map[string]string{
				"a": "model-00001-of-00002.safetensors",
				"b": "model-00002-of-00002.safetensors",
			},
		})
		records, err := Scan(context.Background(), root)
		if err != nil {
			t.Fatal(err)
		}
		if len(records) != 1 || records[0].Complete || !hasIssue(records[0], "missing_safetensors_shard") {
			t.Fatalf("record = %#v", records)
		}

		writeSafeTensors(t, filepath.Join(root, "model-00002-of-00002.safetensors"), "F16", []int64{2})
		records, err = Scan(context.Background(), root)
		if err != nil {
			t.Fatal(err)
		}
		if len(records) != 1 || !records[0].Complete || records[0].Metadata.ParameterCount != 4 {
			t.Fatalf("completed record = %#v", records)
		}
	})
}

func TestScanSafeTensorsMissingTokenizerRemainsVisibleButNotStartable(t *testing.T) {
	root := t.TempDir()
	writeJSONFile(t, filepath.Join(root, "config.json"), map[string]any{
		"model_type": "llama", "num_hidden_layers": 1, "num_attention_heads": 1,
		"hidden_size": 8, "max_position_embeddings": 1024,
	})
	writeSafeTensors(t, filepath.Join(root, "model.safetensors"), "F16", []int64{1})
	records, err := Scan(context.Background(), root)
	if err != nil {
		t.Fatal(err)
	}
	if len(records) != 1 || records[0].Complete || !hasIssue(records[0], "tokenizer_missing") {
		t.Fatalf("record = %#v", records)
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

func writeSafeBundleSidecars(t *testing.T, dir string) {
	t.Helper()
	writeJSONFile(t, filepath.Join(dir, "config.json"), map[string]any{
		"model_type": "llama", "num_hidden_layers": 1, "num_attention_heads": 1,
		"hidden_size": 8, "max_position_embeddings": 1024,
	})
	writeJSONFile(t, filepath.Join(dir, "tokenizer.json"), map[string]any{"version": "1.0"})
	writeJSONFile(t, filepath.Join(dir, "tokenizer_config.json"), map[string]any{"chat_template": "{{ messages }}"})
}

func writeJSONFile(t *testing.T, path string, value any) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	data, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
}

func writeSafeTensors(t *testing.T, path, dtype string, shape []int64) {
	t.Helper()
	bits := map[string]int64{"F16": 16, "BF16": 16, "F32": 32, "I8": 8, "U8": 8}[dtype]
	if bits == 0 {
		t.Fatalf("unsupported test dtype %q", dtype)
	}
	parameters := int64(1)
	for _, dimension := range shape {
		parameters *= dimension
	}
	dataBytes := parameters * bits / 8
	header, err := json.Marshal(map[string]any{
		"weight": map[string]any{"dtype": dtype, "shape": shape, "data_offsets": []int64{0, dataBytes}},
	})
	if err != nil {
		t.Fatal(err)
	}
	if padding := (8 - len(header)%8) % 8; padding > 0 {
		header = append(header, bytes.Repeat([]byte(" "), padding)...)
	}
	var contents bytes.Buffer
	if err := binary.Write(&contents, binary.LittleEndian, uint64(len(header))); err != nil {
		t.Fatal(err)
	}
	contents.Write(header)
	contents.Write(make([]byte, dataBytes))
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, contents.Bytes(), 0o600); err != nil {
		t.Fatal(err)
	}
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
