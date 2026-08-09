package types

import "testing"

func TestNormalizeFormatAliases(t *testing.T) {
	cases := map[string]string{
		"Safetensors":  "safetensors",
		"safe-tensors": "safetensors",
		"ONNX":         "onnx",
		"MLX":          "mlx",
		"NVIDIA NeMo":  "nemo",
		"nemo":         "nemo",
		"GGUF":         "gguf",
	}

	for input, expected := range cases {
		if got := NormalizeFormat(input); got != expected {
			t.Fatalf("NormalizeFormat(%q) = %q, expected %q", input, got, expected)
		}
	}
}

func TestMatchesFormatAliases(t *testing.T) {
	if !MatchesFormat([]string{"nemo"}, "NVIDIA NeMo") {
		t.Fatalf("expected NVIDIA NeMo alias to match nemo")
	}
	if !MatchesFormat([]string{"safetensors"}, "safe-tensors") {
		t.Fatalf("expected safe-tensors alias to match safetensors")
	}
	if MatchesFormat([]string{"gguf"}, "onnx") {
		t.Fatalf("did not expect onnx filter to match gguf")
	}
}
