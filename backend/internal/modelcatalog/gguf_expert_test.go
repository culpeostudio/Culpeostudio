package modelcatalog

import (
	"bytes"
	"encoding/binary"
	"os"
	"path/filepath"
	"testing"
)

// moeTensor is one entry in the synthetic model below: the name decides whether
// it counts as expert weight, the size decides how much.
type moeTensor struct {
	name  string
	bytes int64
}

// writeMoEGGUF builds a GGUF whose tensor offsets are laid out back to back, so
// the size the parser derives from the gaps is exactly the size asked for here.
func writeMoEGGUF(t *testing.T, path string, tensors []moeTensor, alignment uint32) {
	t.Helper()
	type metadataEntry struct {
		key       string
		valueType uint32
		value     any
	}
	entries := []metadataEntry{
		{"general.architecture", ggufTypeString, "llama"},
		{"general.name", ggufTypeString, "moe-test"},
		{"general.file_type", ggufTypeUint32, uint32(15)},
		{"general.alignment", ggufTypeUint32, alignment},
		{"llama.block_count", ggufTypeUint32, uint32(4)},
		{"llama.attention.head_count", ggufTypeUint32, uint32(4)},
		{"llama.attention.head_count_kv", ggufTypeUint32, uint32(2)},
		{"llama.embedding_length", ggufTypeUint32, uint32(128)},
		{"llama.context_length", ggufTypeUint32, uint32(8192)},
	}

	var contents bytes.Buffer
	contents.WriteString("GGUF")
	for _, value := range []any{uint32(3), uint64(len(tensors)), uint64(len(entries))} {
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

	offset := uint64(0)
	for _, tensor := range tensors {
		writeGGUFString(t, &contents, tensor.name)
		// One dimension, one element per byte, type 0 (f32 in ggml, irrelevant
		// here because sizes come from the offsets).
		for _, value := range []any{uint32(1), uint64(tensor.bytes), uint32(0), offset} {
			if err := binary.Write(&contents, binary.LittleEndian, value); err != nil {
				t.Fatal(err)
			}
		}
		offset += uint64(tensor.bytes)
	}

	// Pad the header out to the alignment boundary, then append exactly as much
	// data as the offsets describe.
	header := contents.Len()
	padding := 0
	if remainder := header % int(alignment); remainder != 0 {
		padding = int(alignment) - remainder
	}
	contents.Write(make([]byte, padding))
	contents.Write(make([]byte, offset))

	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, contents.Bytes(), 0o600); err != nil {
		t.Fatal(err)
	}
}

func TestGGUFMeasuresExpertWeightPerLayer(t *testing.T) {
	path := filepath.Join(t.TempDir(), "moe.gguf")
	writeMoEGGUF(t, path, []moeTensor{
		{"token_embd.weight", 1000},
		{"blk.0.attn_q.weight", 100},
		{"blk.0.ffn_gate_exps.weight", 400},
		{"blk.0.ffn_up_exps.weight", 400},
		{"blk.0.ffn_down_exps.weight", 400},
		{"blk.1.attn_q.weight", 100},
		{"blk.1.ffn_gate_exps.weight", 400},
		{"blk.1.ffn_up_exps.weight", 400},
		{"blk.1.ffn_down_exps.weight", 400},
		// A shared expert stays on the accelerator with the dense path, so it
		// must not be counted as offloadable expert weight.
		{"blk.1.ffn_gate_shexp.weight", 250},
		{"output.weight", 1000},
	}, 32)

	parsed, err := parseGGUF(path)
	if err != nil {
		t.Fatal(err)
	}
	if parsed.expertLayers != 2 {
		t.Fatalf("expert layers = %d, want 2", parsed.expertLayers)
	}
	if parsed.expertBytes != 2400 {
		t.Fatalf("expert bytes = %d, want 2400 (the six _exps tensors, not the shared one)", parsed.expertBytes)
	}
}

func TestGGUFReportsNoExpertsForADenseModel(t *testing.T) {
	path := filepath.Join(t.TempDir(), "dense.gguf")
	writeMoEGGUF(t, path, []moeTensor{
		{"token_embd.weight", 1000},
		{"blk.0.attn_q.weight", 100},
		{"blk.0.ffn_gate.weight", 400},
		{"output.weight", 1000},
	}, 32)

	parsed, err := parseGGUF(path)
	if err != nil {
		t.Fatal(err)
	}
	// Zero on both is what the planner tests for, so a dense model must not
	// report a partial figure.
	if parsed.expertBytes != 0 || parsed.expertLayers != 0 {
		t.Fatalf("dense model reported %d expert bytes over %d layers", parsed.expertBytes, parsed.expertLayers)
	}
}

func TestGGUFExpertMeasurementSurvivesAnUnusualAlignment(t *testing.T) {
	// The default is 32; a file that declares something else must still be read
	// correctly, because the data section start depends on it.
	path := filepath.Join(t.TempDir(), "aligned.gguf")
	writeMoEGGUF(t, path, []moeTensor{
		{"blk.0.ffn_up_exps.weight", 512},
		{"output.weight", 128},
	}, 4096)

	parsed, err := parseGGUF(path)
	if err != nil {
		t.Fatal(err)
	}
	if parsed.expertBytes != 512 || parsed.expertLayers != 1 {
		t.Fatalf("expert bytes = %d over %d layers, want 512 over 1", parsed.expertBytes, parsed.expertLayers)
	}
}
