package apimodels

import (
	"errors"
	"fmt"
	"path/filepath"
	"testing"
)

// TestStoreRejectsActiveModelsLimit dreht MaxActiveModels+1 Starts und
// verlangt, dass der letzte Registrate mit ErrActiveModelsLimitReached
// fehlschlaegt, waehrend die ersten MaxActiveModels erfolgreich registriert
// werden. So kann ein Client nicht beliebig viele Cloud-Modelle
// gleichzeitig buchen.
func TestStoreRejectsActiveModelsLimit(t *testing.T) {
	store := NewStore(filepath.Join(t.TempDir(), "active_api_models.json"))

	for i := 0; i < MaxActiveModels; i++ {
		modelID := fmt.Sprintf("vendor/model-%d", i)
		if _, err := store.Start(ProviderOpenRouter, modelID, ""); err != nil {
			t.Fatalf("start %d failed unexpectedly: %v", i, err)
		}
	}

	// Der (MaxActiveModels+1).start muss fehlschlagen.
	if _, err := store.Start(ProviderOpenRouter, "vendor/overflow", ""); !errors.Is(err, ErrActiveModelsLimitReached) {
		t.Fatalf("expected ErrActiveModelsLimitReached, got %v", err)
	}

	// Nach Delete einem Slot werden neue Starts wieder akzeptiert.
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

// TestStoreTouchWithinLimitDoesNotCountDouble stellt sicher, dass ein
// erneutes Starten desselben Modells (Touch-Pfad) nicht erneut gegen das
// Limit zaehlt. Sonst koennte ein User ein geliebtes Modell nicht mehr
// aktualisieren, sobald die Liste voll ist.
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
	// Liste jetzt voll; erneutes Starten desselben Modells klappt.
	if _, err := store.Start(ProviderFeatherless, "vendor/fixed", "Fixed Updated"); err != nil {
		t.Fatalf("touch within limit should not be blocked, got %v", err)
	}
}
