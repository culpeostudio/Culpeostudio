package apimodels

import (
	"errors"
	"fmt"
	"path/filepath"
	"testing"
)

func TestStoreRejectsActiveModelsLimit(t *testing.T) {
	store := NewStore(filepath.Join(t.TempDir(), "active_api_models.json"))

	for i := 0; i < MaxActiveModels; i++ {
		modelID := fmt.Sprintf("vendor/model-%d", i)
		if _, err := store.Start(ProviderOpenRouter, modelID, ""); err != nil {
			t.Fatalf("start %d failed unexpectedly: %v", i, err)
		}
	}

	if _, err := store.Start(ProviderOpenRouter, "vendor/overflow", ""); !errors.Is(err, ErrActiveModelsLimitReached) {
		t.Fatalf("expected ErrActiveModelsLimitReached, got %v", err)
	}

	models, err := store.List()
	if err != nil {
		t.Fatalf("list failed: %v", err)
	}
	if len(models) != MaxActiveModels {
		t.Fatalf("expected %d active, got %d", MaxActiveModels, len(models))
	}
	refToDelete := models[0].ModelRef
	if _, err := store.Delete(refToDelete); err != nil {
		t.Fatalf("delete failed: %v", err)
	}
	if _, err := store.Start(ProviderOpenRouter, "vendor/back_in", ""); err != nil {
		t.Fatalf("start after delete failed: %v", err)
	}
}

func TestStoreTouchWithinLimitDoesNotCountDouble(t *testing.T) {
	store := NewStore(filepath.Join(t.TempDir(), "active_api_models.json"))
	_, err := store.Start(ProviderFeatherless, "vendor/fixed", "Fixed")
	if err != nil {
		t.Fatalf("first start failed: %v", err)
	}
	for i := 0; i < MaxActiveModels-1; i++ {
		if _, err := store.Start(ProviderOpenRouter, fmt.Sprintf("vendor/fill-%d", i), ""); err != nil {
			t.Fatalf("filler %d failed: %v", i, err)
		}
	}

	if _, err := store.Start(ProviderFeatherless, "vendor/fixed", "Fixed Updated"); err != nil {
		t.Fatalf("touch within limit should not be blocked, got %v", err)
	}
}
