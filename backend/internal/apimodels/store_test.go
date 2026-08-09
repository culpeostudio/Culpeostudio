package apimodels

import (
	"path/filepath"
	"testing"
	"time"
)

func TestStoreStartListDeleteAndTouch(t *testing.T) {
	store := NewStore(filepath.Join(t.TempDir(), "active_api_models.json"))

	first, err := store.Start(ProviderOpenRouter, "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("start first model failed: %v", err)
	}
	if first.ModelRef == "" {
		t.Fatalf("expected model_ref")
	}

	time.Sleep(time.Millisecond)
	second, err := store.Start(ProviderOpenRouter, "openai/gpt-4o", "GPT-4o Updated")
	if err != nil {
		t.Fatalf("start duplicate model failed: %v", err)
	}
	if second.ModelRef != first.ModelRef {
		t.Fatalf("expected duplicate start to keep model_ref")
	}
	if second.DisplayName != "GPT-4o Updated" {
		t.Fatalf("expected display name update, got %q", second.DisplayName)
	}

	list, err := store.List()
	if err != nil {
		t.Fatalf("list failed: %v", err)
	}
	if len(list) != 1 {
		t.Fatalf("expected one deduped model, got %d", len(list))
	}

	touched, ok, err := store.Touch(first.ModelRef)
	if err != nil {
		t.Fatalf("touch failed: %v", err)
	}
	if !ok || !touched.LastUsedAt.After(first.LastUsedAt) {
		t.Fatalf("expected model to be touched")
	}

	deleted, err := store.Delete(first.ModelRef)
	if err != nil {
		t.Fatalf("delete failed: %v", err)
	}
	if !deleted {
		t.Fatalf("expected delete to report true")
	}

	list, err = store.List()
	if err != nil {
		t.Fatalf("list after delete failed: %v", err)
	}
	if len(list) != 0 {
		t.Fatalf("expected empty list after delete, got %d", len(list))
	}
}

func TestStoreRejectsUnsupportedProvider(t *testing.T) {
	store := NewStore(filepath.Join(t.TempDir(), "active_api_models.json"))
	if _, err := store.Start("huggingface", "org/model", ""); err == nil {
		t.Fatalf("expected huggingface to be rejected for API chat")
	}
}
