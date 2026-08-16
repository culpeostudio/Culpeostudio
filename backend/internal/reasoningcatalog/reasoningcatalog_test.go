package reasoningcatalog

import (
	"context"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"reflect"
	"testing"
)

func TestCatalog_RefreshAndLoad(t *testing.T) {
	// Sample OpenRouter API response
	fakeJSON := `{
		"data": [
			{
				"id": "model-1",
				"name": "Model 1",
				"reasoning": {
					"mandatory": true,
					"default_enabled": true,
					"supported_efforts": ["low", "high", "unknown"],
					"default_effort": "low"
				}
			},
			{
				"id": "model-2",
				"name": "Model 2"
			}
		]
	}`

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(fakeJSON))
	}))
	defer server.Close()

	tmpDir := t.TempDir()
	path := filepath.Join(tmpDir, "openrouter_reasoning.json")

	cat := New(path, server.Client())
	cat.url = server.URL // override for testing

	// 1. Refresh from fake API
	cat.Refresh(context.Background())

	profiles := cat.Profiles()
	if len(profiles) != 2 {
		t.Fatalf("expected 2 profiles, got %d", len(profiles))
	}

	p1 := profiles[0]
	if p1.ID != "model-1" || !p1.Mandatory || p1.DefaultEffort != "low" {
		t.Errorf("unexpected p1: %+v", p1)
	}
	expectedEfforts := []string{"low", "high"}
	if !reflect.DeepEqual(p1.SupportedEfforts, expectedEfforts) {
		t.Errorf("expected efforts %v, got %v", expectedEfforts, p1.SupportedEfforts)
	}

	p2 := profiles[1]
	if p2.ID != "model-2" || p2.Name != "Model 2" || len(p2.SupportedEfforts) > 0 {
		t.Errorf("unexpected p2: %+v", p2)
	}

	// 2. Load from disk into new catalog
	cat2 := New(path, nil)
	cat2.Load()

	profiles2 := cat2.Profiles()
	if !reflect.DeepEqual(profiles, profiles2) {
		t.Errorf("loaded profiles %v do not match saved profiles %v", profiles2, profiles)
	}

	// 3. Refresh offline doesn't wipe
	cat2.url = "http://localhost:0" // fail to connect
	cat2.Refresh(context.Background())

	profiles3 := cat2.Profiles()
	if !reflect.DeepEqual(profiles, profiles3) {
		t.Errorf("offline refresh wiped profiles, got %v", profiles3)
	}
}

func TestCatalog_ContextLength(t *testing.T) {
	// top_provider narrows the window for model-1; model-2 only reports the
	// model-level one; model-3 reports none at all.
	fakeJSON := `{
		"data": [
			{"id": "vendor/model-1", "context_length": 200000, "top_provider": {"context_length": 131072, "max_completion_tokens": 64000}},
			{"id": "vendor/model-1-mini", "context_length": 64000, "top_provider": {"max_completion_tokens": 8192}},
			{"id": "other/model-3"}
		]
	}`

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(fakeJSON))
	}))
	defer server.Close()

	cat := New(filepath.Join(t.TempDir(), "openrouter_reasoning.json"), server.Client())
	cat.url = server.URL
	cat.Refresh(context.Background())

	cases := map[string]int{
		"vendor/model-1":      131072,
		"VENDOR/MODEL-1":      131072,
		"model-1-mini":        64000,
		"openai/model-1-mini": 64000,
		"other/model-3":       0,
		"never-heard-of-it":   0,
		"":                    0,
	}
	for modelID, want := range cases {
		if got := cat.ContextLengthFor(modelID); got != want {
			t.Errorf("ContextLengthFor(%q) = %d, want %d", modelID, got, want)
		}
	}

	// Only the two entries that report a window are averaged.
	if got, want := cat.AverageContextLength(), (131072+64000)/2; got != want {
		t.Errorf("AverageContextLength() = %d, want %d", got, want)
	}

	if got := New("", nil).AverageContextLength(); got != 0 {
		t.Errorf("empty catalog averaged to %d, want 0", got)
	}

	// The answer ceiling rides along on the same entry, resolved the same way.
	outputCases := map[string]int{
		"vendor/model-1":    64000,
		"model-1-mini":      8192,
		"other/model-3":     0,
		"never-heard-of-it": 0,
	}
	for modelID, want := range outputCases {
		if got := cat.MaxOutputTokensFor(modelID); got != want {
			t.Errorf("MaxOutputTokensFor(%q) = %d, want %d", modelID, got, want)
		}
	}
	if got, want := cat.AverageMaxOutputTokens(), (64000+8192)/2; got != want {
		t.Errorf("AverageMaxOutputTokens() = %d, want %d", got, want)
	}
}

func TestNormalizeEfforts(t *testing.T) {
	raw := []string{" MAX ", "unknown", "minimal", "low"}
	expected := []string{"minimal", "low", "max"}
	got := normalizeEfforts(raw)
	if !reflect.DeepEqual(got, expected) {
		t.Errorf("expected %v, got %v", expected, got)
	}
}
