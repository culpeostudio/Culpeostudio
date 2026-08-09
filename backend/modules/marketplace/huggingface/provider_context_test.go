package huggingface

import "testing"

func TestExtractContextLengthPrefersHuggingFaceConfig(t *testing.T) {
	config := map[string]interface{}{
		"text_config": map[string]interface{}{
			"max_position_embeddings": float64(131072),
		},
	}
	if got := extractContextLength(config, []string{"text-generation", "context:8k"}); got != 131072 {
		t.Fatalf("expected config context 131072, got %d", got)
	}
}

func TestExtractContextLengthUsesContextTagWhenConfigIsAbsent(t *testing.T) {
	if got := extractContextLength(nil, []string{"chat", "context:128k"}); got != 128000 {
		t.Fatalf("expected tag context 128000, got %d", got)
	}
}
