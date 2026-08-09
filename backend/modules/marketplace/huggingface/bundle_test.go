package huggingface

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sort"
	"strings"
	"testing"
)

func TestResolveBundleAssetsCompletesSafeTensorsSnapshot(t *testing.T) {
	t.Parallel()

	siblings := []string{
		"weights/model-00001-of-00002.safetensors",
		"weights/model-00002-of-00002.safetensors",
		"model.safetensors.index.json",
		"config.json",
		"generation_config.json",
		"tokenizer/tokenizer.json",
		"tokenizer_config.json",
		"chat_template.jinja",
		"modeling_custom.py",
		"README.md",
		"other-quant/model.safetensors",
	}
	server := newHFBundleMetadataServer(t, "acme/tiny", "deadbeef", siblings)
	defer server.Close()

	descriptor, err := ResolveBundleAssets(
		context.Background(), server.Client(), server.URL, "acme/tiny", "feature/rev", "",
		[]string{
			"weights/model-00001-of-00002.safetensors",
			"weights/model-00002-of-00002.safetensors",
		},
	)
	if err != nil {
		t.Fatalf("ResolveBundleAssets failed: %v", err)
	}
	if descriptor.Format != "safetensors" {
		t.Fatalf("format = %q, want safetensors", descriptor.Format)
	}
	if descriptor.Revision != "feature/rev" || descriptor.CommitSHA != "deadbeef" {
		t.Fatalf("unexpected revision pin: %#v", descriptor)
	}

	want := []string{
		"weights/model-00001-of-00002.safetensors",
		"weights/model-00002-of-00002.safetensors",
		"model.safetensors.index.json",
		"config.json",
		"generation_config.json",
		"tokenizer/tokenizer.json",
		"tokenizer_config.json",
		"chat_template.jinja",
		"modeling_custom.py",
	}
	assertSameStrings(t, descriptor.Assets, want)
	for _, excluded := range []string{"README.md", "other-quant/model.safetensors"} {
		if containsString(descriptor.Assets, excluded) {
			t.Fatalf("unrelated repository asset %q was included: %#v", excluded, descriptor.Assets)
		}
	}
}

func TestResolveBundleAssetsKeepsGGUFSelectionNarrow(t *testing.T) {
	t.Parallel()

	siblings := []string{
		"gguf/model-Q4_K_M-00001-of-00002.gguf",
		"gguf/model-Q4_K_M-00002-of-00002.gguf",
		"config.json",
		"tokenizer.json",
	}
	server := newHFBundleMetadataServer(t, "acme/gguf", "cafebabe", siblings)
	defer server.Close()

	selected := []string{
		"gguf/model-Q4_K_M-00001-of-00002.gguf",
		"gguf/model-Q4_K_M-00002-of-00002.gguf",
	}
	descriptor, err := ResolveBundleAssets(context.Background(), server.Client(), server.URL, "acme/gguf", "", "", selected)
	if err != nil {
		t.Fatalf("ResolveBundleAssets failed: %v", err)
	}
	if descriptor.Format != "gguf" || descriptor.Revision != "main" {
		t.Fatalf("unexpected descriptor: %#v", descriptor)
	}
	assertSameStrings(t, descriptor.Assets, selected)
}

func TestResolveBundleAssetsRejectsUnknownAndUnsafeAssets(t *testing.T) {
	t.Parallel()

	t.Run("unknown requested asset", func(t *testing.T) {
		server := newHFBundleMetadataServer(t, "acme/tiny", "deadbeef", []string{"model.safetensors", "config.json", "tokenizer.json"})
		defer server.Close()

		_, err := ResolveBundleAssets(context.Background(), server.Client(), server.URL, "acme/tiny", "main", "", []string{"missing.safetensors"})
		if err == nil || !strings.Contains(err.Error(), "not part of repository") {
			t.Fatalf("expected unknown asset error, got %v", err)
		}
	})

	t.Run("unsafe support asset", func(t *testing.T) {
		server := newHFBundleMetadataServer(t, "acme/tiny", "deadbeef", []string{
			"model.safetensors", "config.json", "tokenizer.json", "../modeling_evil.py",
		})
		defer server.Close()

		_, err := ResolveBundleAssets(context.Background(), server.Client(), server.URL, "acme/tiny", "main", "", []string{"model.safetensors"})
		if err == nil || !strings.Contains(err.Error(), "unsafe repository asset path") {
			t.Fatalf("expected unsafe asset error, got %v", err)
		}
	})
}

func newHFBundleMetadataServer(t *testing.T, modelID, sha string, siblings []string) *httptest.Server {
	t.Helper()
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		basePath := "/api/models/" + modelID
		if r.URL.Path != basePath && !strings.HasPrefix(r.URL.Path, basePath+"/revision/") {
			http.NotFound(w, r)
			return
		}
		if r.URL.Query().Get("blobs") != "true" {
			t.Errorf("metadata request did not ask for blobs: %s", r.URL.String())
		}
		out := HuggingFaceModel{ID: modelID, SHA: sha}
		for _, name := range siblings {
			out.Siblings = append(out.Siblings, HuggingFaceSibling{RFilename: name, Size: 10})
		}
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(out); err != nil {
			t.Errorf("encode metadata: %v", err)
		}
	}))
}

func assertSameStrings(t *testing.T, got, want []string) {
	t.Helper()
	gotCopy := append([]string(nil), got...)
	wantCopy := append([]string(nil), want...)
	sort.Strings(gotCopy)
	sort.Strings(wantCopy)
	if strings.Join(gotCopy, "\n") != strings.Join(wantCopy, "\n") {
		t.Fatalf("assets mismatch\n got: %#v\nwant: %#v", gotCopy, wantCopy)
	}
}

func containsString(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}
