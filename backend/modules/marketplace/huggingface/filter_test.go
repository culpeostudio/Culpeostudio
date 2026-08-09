package huggingface

import "testing"

func TestInferHFOptionFormat(t *testing.T) {
	cases := []struct {
		name     string
		fileName string
		ext      string
		expected string
	}{
		{
			name:     "nemo extension",
			fileName: "model.nemo",
			ext:      "nemo",
			expected: "nemo",
		},
		{
			name:     "mlx safetensors path",
			fileName: "mlx/model.safetensors",
			ext:      "safetensors",
			expected: "mlx",
		},
		{
			name:     "onnx token in filename",
			fileName: "encoder_onnx_data.bin",
			ext:      "bin",
			expected: "onnx",
		},
		{
			name:     "plain safetensors",
			fileName: "model.safetensors",
			ext:      "safetensors",
			expected: "safetensors",
		},
	}

	for _, tc := range cases {
		if got := inferHFOptionFormat(tc.fileName, tc.ext); got != tc.expected {
			t.Fatalf("%s: expected %q, got %q", tc.name, tc.expected, got)
		}
	}
}

func TestBuildHuggingFaceOptionsGroupsSafetensorsShards(t *testing.T) {
	options := BuildHuggfaceFilteredOptions([]HuggingFaceSibling{
		{RFilename: "model-00001-of-00002.safetensors", Size: 3 * 1024 * 1024 * 1024},
		{RFilename: "model-00002-of-00002.safetensors", Size: 2 * 1024 * 1024 * 1024},
		{RFilename: "config.json", Size: 1024},
	})
	if len(options) != 1 {
		t.Fatalf("expected a single logical checkpoint option, got %#v", options)
	}
	option := options[0]
	if option.Format != "safetensors" || len(option.AssetIDs) != 2 {
		t.Fatalf("expected both shards in one option, got %#v", option)
	}
	if option.SizeBytes != 5*1024*1024*1024 {
		t.Fatalf("expected combined shard size, got %d", option.SizeBytes)
	}
	if option.AssetID == "" {
		t.Fatal("logical option must retain a primary asset id")
	}
}

func TestBuildHuggingFaceOptionsGroupsGGUFShards(t *testing.T) {

	options := BuildHuggfaceFilteredOptions([]HuggingFaceSibling{
		{RFilename: "Llama-3.3-70B-Instruct-Q5_K_M-00001-of-00002.gguf", Size: 10 * 1024 * 1024 * 1024},
		{RFilename: "Llama-3.3-70B-Instruct-Q5_K_M-00002-of-00002.gguf", Size: 9 * 1024 * 1024 * 1024},
		{RFilename: "config.json", Size: 1024},
	})
	if len(options) != 1 {
		t.Fatalf("expected a single logical checkpoint option, got %#v", options)
	}
	option := options[0]
	if option.Format != "gguf" || len(option.AssetIDs) != 2 {
		t.Fatalf("expected both gguf shards in one option, got %#v", option)
	}
	if option.SizeBytes != 19*1024*1024*1024 {
		t.Fatalf("expected combined shard size, got %d", option.SizeBytes)
	}
}

func TestBuildHuggingFaceOptionsGroupsShardsWithMismatchedDigitWidth(t *testing.T) {

	options := BuildHuggfaceFilteredOptions([]HuggingFaceSibling{
		{RFilename: "model-00001-of-000163.safetensors", Size: 4 * 1024 * 1024 * 1024},
		{RFilename: "model-00002-of-000163.safetensors", Size: 4 * 1024 * 1024 * 1024},
		{RFilename: "config.json", Size: 1024},
	})
	if len(options) != 1 {
		t.Fatalf("expected a single logical checkpoint option, got %#v", options)
	}
	if options[0].SizeBytes != 8*1024*1024*1024 {
		t.Fatalf("expected combined shard size, got %d", options[0].SizeBytes)
	}
}
