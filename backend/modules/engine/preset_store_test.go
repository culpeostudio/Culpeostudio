package engine

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func newTestPresetStore(t *testing.T) *enginePresetStore {
	t.Helper()
	store, err := newEnginePresetStore(filepath.Join(t.TempDir(), "presets.json"))
	if err != nil {
		t.Fatal(err)
	}
	return store
}

func TestPresetStoreSavesUpdatesAndReloads(t *testing.T) {
	path := filepath.Join(t.TempDir(), "presets.json")
	store, err := newEnginePresetStore(path)
	if err != nil {
		t.Fatal(err)
	}

	config := defaultEngineConfig()
	config.RuntimeOptions["cpu_moe_layers"] = 24
	config.IdleTimeoutSeconds = intPointer(-1)

	saved, err := store.save(EnginePreset{Name: "MoE auf kleiner Karte", Config: config, ModelID: "mdl_a"})
	if err != nil {
		t.Fatal(err)
	}
	if saved.ID == "" || saved.BuiltIn {
		t.Fatalf("saved preset = %+v", saved)
	}

	// Saving under the same id replaces rather than duplicating, and the
	// creation time survives.
	updated, err := store.save(EnginePreset{ID: saved.ID, Name: "Umbenannt", Config: config})
	if err != nil {
		t.Fatal(err)
	}
	if updated.ID != saved.ID || updated.Name != "Umbenannt" {
		t.Fatalf("update produced %+v", updated)
	}
	if !updated.CreatedAt.Equal(saved.CreatedAt) {
		t.Fatal("an update must not reset the creation time")
	}

	// A second store over the same file sees the same presets, which is the
	// whole point of saving one.
	reopened, err := newEnginePresetStore(path)
	if err != nil {
		t.Fatal(err)
	}
	restored, ok := reopened.get(saved.ID)
	if !ok {
		t.Fatal("the preset did not survive a reload")
	}
	if restored.Name != "Umbenannt" {
		t.Fatalf("restored name %q", restored.Name)
	}
	if value, _ := intOption(restored.Config.RuntimeOptions, "cpu_moe_layers"); value == nil || *value != 24 {
		t.Fatalf("the runtime options did not survive: %v", restored.Config.RuntimeOptions)
	}
	if restored.Config.IdleTimeoutSeconds == nil || *restored.Config.IdleTimeoutSeconds != -1 {
		t.Fatal("the idle timeout did not survive; -1 means never unload and must not normalise away")
	}
}

func TestPresetStoreProtectsTheBuiltIns(t *testing.T) {
	store := newTestPresetStore(t)

	presets := store.list()
	if len(presets) < 3 {
		t.Fatalf("expected the shipped presets, got %d", len(presets))
	}
	builtIn := presets[0]
	if !builtIn.BuiltIn {
		t.Fatal("the built-ins must be listed first")
	}

	// A built-in is what a user falls back to after breaking their own, so it
	// can be neither replaced nor removed.
	if _, err := store.save(EnginePreset{ID: builtIn.ID, Name: "Entführt", Config: defaultEngineConfig()}); err == nil {
		t.Fatal("a built-in must not be overwritable")
	}
	if err := store.delete(builtIn.ID); err == nil {
		t.Fatal("a built-in must not be deletable")
	}
	if _, ok := store.get(builtIn.ID); !ok {
		t.Fatal("the built-in disappeared")
	}
}

func TestPresetStoreRejectsAnUnnamedPresetAndAnUnknownDelete(t *testing.T) {
	store := newTestPresetStore(t)

	if _, err := store.save(EnginePreset{Name: "   ", Config: defaultEngineConfig()}); err == nil {
		t.Fatal("a preset without a name has nothing to find it by")
	}
	if err := store.delete("pre_missing"); !os.IsNotExist(err) {
		t.Fatalf("deleting an unknown preset returned %v", err)
	}
}

func TestPresetExportSkipsBuiltInsAndImportMakesCopies(t *testing.T) {
	store := newTestPresetStore(t)
	config := defaultEngineConfig()
	config.RuntimeOptions["jinja"] = true
	original, err := store.save(EnginePreset{Name: "Werkzeugaufrufe", Config: config})
	if err != nil {
		t.Fatal(err)
	}

	document, err := store.exportPresets(nil)
	if err != nil {
		t.Fatal(err)
	}
	var exported persistedEnginePresets
	if err := json.Unmarshal(document, &exported); err != nil {
		t.Fatal(err)
	}
	// The receiving install ships its own built-ins; exporting them would only
	// create duplicates there.
	if len(exported.Presets) != 1 || exported.Presets[0].Name != "Werkzeugaufrufe" {
		t.Fatalf("export contained %d presets: %+v", len(exported.Presets), exported.Presets)
	}

	imported, err := store.importPresets(document)
	if err != nil {
		t.Fatal(err)
	}
	if len(imported) != 1 {
		t.Fatalf("imported %d presets", len(imported))
	}
	// A fresh id, so importing the same file twice does not silently replace
	// the preset it came from.
	if imported[0].ID == original.ID {
		t.Fatal("an import must not overwrite the preset it was exported from")
	}
	if value, _ := boolOption(imported[0].Config.RuntimeOptions, "jinja"); !value {
		t.Fatal("the runtime options did not survive the round trip")
	}
}

func TestPresetImportRefusesRubbish(t *testing.T) {
	store := newTestPresetStore(t)

	for name, document := range map[string]string{
		"not json":      "definitely not json",
		"empty list":    `{"schema_version":1,"presets":[]}`,
		"newer schema":  `{"schema_version":99,"presets":[{"name":"x"}]}`,
		"unnamed entry": `{"schema_version":1,"presets":[{"name":"  "}]}`,
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := store.importPresets([]byte(document)); err == nil {
				t.Fatalf("%s was accepted", name)
			}
		})
	}
}

func TestPresetExportOfNothingSaysSo(t *testing.T) {
	store := newTestPresetStore(t)
	// Only built-ins exist, and those are never exported.
	_, err := store.exportPresets(nil)
	if err == nil || !strings.Contains(err.Error(), "keine eigenen Presets") {
		t.Fatalf("export of an empty set returned %v", err)
	}
}
