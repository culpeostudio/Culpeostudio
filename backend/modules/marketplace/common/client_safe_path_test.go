package common

import (
	"path/filepath"
	"testing"
)

func TestSafeRelativePathRejectsTraversalAndAbsolutePaths(t *testing.T) {
	t.Parallel()

	unsafe := []string{
		"",
		"   ",
		"/etc/passwd",
		"../secret",
		"weights/../../secret",
		`..\secret`,
		`C:\Windows\system32`,
		`\\server\share\model.gguf`,
	}
	for _, input := range unsafe {
		input := input
		t.Run(input, func(t *testing.T) {
			t.Parallel()
			if got, ok := SafeRelativePath(input); ok {
				t.Fatalf("SafeRelativePath(%q) unexpectedly accepted %q", input, got)
			}
		})
	}
}

func TestSafeRelativePathPreservesSafeSnapshotSubdirectories(t *testing.T) {
	t.Parallel()

	cases := map[string]string{
		"config.json":                   "config.json",
		"tokenizer/vocab.json":          filepath.Join("tokenizer", "vocab.json"),
		`tokenizer\special_tokens.json`: filepath.Join("tokenizer", "special_tokens.json"),
		"./weights/model.safetensors":   filepath.Join("weights", "model.safetensors"),
	}
	for input, expected := range cases {
		got, ok := SafeRelativePath(input)
		if !ok {
			t.Fatalf("SafeRelativePath(%q) unexpectedly rejected", input)
		}
		if got != expected {
			t.Fatalf("SafeRelativePath(%q) = %q, want %q", input, got, expected)
		}
	}
}
