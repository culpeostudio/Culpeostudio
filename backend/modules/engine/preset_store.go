// Saved engine configurations.
//
// Every instance used to be configured from nothing. The settings that make a
// model behave - context mode, KV cache policy, the MoE split, the offload
// switches - had to be rebuilt by hand for each one, and a configuration that
// worked well existed only inside whichever instance happened to carry it.
//
// A preset is that configuration under a name. It stores exactly an
// EngineConfig, so anything the engine accepts can be saved, and it exports as
// the same JSON it stores, so a working setup can be handed to somebody else
// with a different model directory.

package engine

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
	"time"
)

// EnginePreset is one saved configuration.
type EnginePreset struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	// Description is the user's own note about when to reach for this.
	Description string       `json:"description,omitempty"`
	Config      EngineConfig `json:"config"`
	// ModelID is the model this was saved from, kept only as a hint. A preset
	// stays applicable to any model: it is a set of settings, not a binding.
	ModelID   string    `json:"model_id,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	// BuiltIn marks the presets the engine ships. They can be applied and
	// copied but not edited away, so there is always something to fall back to.
	BuiltIn bool `json:"built_in,omitempty"`
}

type persistedEnginePresets struct {
	SchemaVersion int             `json:"schema_version"`
	Presets       []*EnginePreset `json:"presets"`
}

type enginePresetStore struct {
	mu      sync.RWMutex
	path    string
	presets map[string]*EnginePreset
}

const enginePresetSchemaVersion = 1

// maxEnginePresets bounds the file. The store is written whole on every change,
// so an unbounded list would eventually make saving one preset expensive.
const maxEnginePresets = 200

func newEnginePresetStore(path string) (*enginePresetStore, error) {
	store := &enginePresetStore{path: path, presets: map[string]*EnginePreset{}}
	payload, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return store, nil
	}
	if err != nil {
		return nil, err
	}
	var persisted persistedEnginePresets
	if err := json.Unmarshal(payload, &persisted); err != nil {
		return nil, fmt.Errorf("Engine-Presets ungueltig: %w", err)
	}
	for _, preset := range persisted.Presets {
		if preset == nil || strings.TrimSpace(preset.ID) == "" || preset.BuiltIn {
			continue
		}
		preset.Config = normalizeConfig(preset.Config)
		store.presets[preset.ID] = preset
	}
	if err := os.Chmod(path, 0o600); err != nil {
		return nil, err
	}
	return store, nil
}

// builtInPresets are the three starting points that cover most of what people
// reach for. They are computed rather than stored so a later change to the
// defaults reaches existing installs.
func builtInPresets() []*EnginePreset {
	balanced := defaultEngineConfig()

	quality := defaultEngineConfig()
	quality.KVCachePolicy = "native"
	quality.RuntimeOptions["kv_cache_dtype"] = "f16"

	roomy := defaultEngineConfig()
	roomy.RuntimeOptions["allow_ram_offload"] = true
	roomy.RuntimeOptions["cpu_moe"] = true

	return []*EnginePreset{
		{
			ID: "builtin_balanced", Name: "Ausgewogen", BuiltIn: true,
			Description: "Der Standard: 4-Bit-KV-Cache, Kontext automatisch, alles auf der GPU.",
			Config:      balanced,
		},
		{
			ID: "builtin_quality", Name: "Qualität zuerst", BuiltIn: true,
			Description: "Voller KV-Cache statt 4 Bit. Braucht deutlich mehr Speicher, kostet dafür keine Qualität am Kontext.",
			Config:      quality,
		},
		{
			ID: "builtin_large_model", Name: "Großes Modell auf kleiner Karte", BuiltIn: true,
			Description: "Erlaubt System-RAM und legt die Experten eines MoE-Modells dorthin. Langsamer, dafür läuft es.",
			Config:      roomy,
		},
	}
}

// list returns the built-ins followed by the user's own, each group sorted by
// name so the order does not move between calls.
func (s *enginePresetStore) list() []*EnginePreset {
	if s == nil {
		return nil
	}
	s.mu.RLock()
	own := make([]*EnginePreset, 0, len(s.presets))
	for _, preset := range s.presets {
		own = append(own, clonePreset(preset))
	}
	s.mu.RUnlock()
	sort.Slice(own, func(a, b int) bool {
		if own[a].Name != own[b].Name {
			return own[a].Name < own[b].Name
		}
		return own[a].ID < own[b].ID
	})
	return append(builtInPresets(), own...)
}

func (s *enginePresetStore) get(id string) (*EnginePreset, bool) {
	id = strings.TrimSpace(id)
	for _, preset := range builtInPresets() {
		if preset.ID == id {
			return preset, true
		}
	}
	if s == nil {
		return nil, false
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	preset := s.presets[id]
	return clonePreset(preset), preset != nil
}

// save creates or replaces a preset. An empty id creates; a built-in id is
// refused, because a built-in is the thing a broken preset is recovered from.
func (s *enginePresetStore) save(preset EnginePreset) (*EnginePreset, error) {
	if s == nil {
		return nil, fmt.Errorf("Engine-Presets sind nicht initialisiert")
	}
	name := strings.TrimSpace(preset.Name)
	if name == "" {
		return nil, fmt.Errorf("ein Preset braucht einen Namen")
	}
	if len(name) > 120 {
		return nil, fmt.Errorf("der Preset-Name ist zu lang")
	}
	id := strings.TrimSpace(preset.ID)
	for _, builtIn := range builtInPresets() {
		if builtIn.ID == id {
			return nil, fmt.Errorf("ein mitgeliefertes Preset kann nicht ueberschrieben werden; bitte unter neuem Namen speichern")
		}
	}

	now := time.Now().UTC()
	s.mu.Lock()
	defer s.mu.Unlock()
	if id == "" {
		generated, err := randomHex(8)
		if err != nil {
			return nil, err
		}
		id = "pre_" + generated
		if len(s.presets) >= maxEnginePresets {
			return nil, fmt.Errorf("es sind hoechstens %d eigene Presets moeglich", maxEnginePresets)
		}
	}
	existing := s.presets[id]
	stored := &EnginePreset{
		ID: id, Name: name, Description: strings.TrimSpace(preset.Description),
		Config: normalizeConfig(cloneEngineConfig(preset.Config)),
		// The model is a hint about where this came from, not a constraint.
		ModelID:   strings.TrimSpace(preset.ModelID),
		CreatedAt: now, UpdatedAt: now,
	}
	if existing != nil {
		stored.CreatedAt = existing.CreatedAt
	}

	next := clonePresetMap(s.presets)
	next[id] = stored
	if err := s.saveLocked(next); err != nil {
		return nil, err
	}
	s.presets = next
	return clonePreset(stored), nil
}

func (s *enginePresetStore) delete(id string) error {
	if s == nil {
		return fmt.Errorf("Engine-Presets sind nicht initialisiert")
	}
	id = strings.TrimSpace(id)
	for _, builtIn := range builtInPresets() {
		if builtIn.ID == id {
			return fmt.Errorf("ein mitgeliefertes Preset kann nicht geloescht werden")
		}
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, exists := s.presets[id]; !exists {
		return os.ErrNotExist
	}
	next := clonePresetMap(s.presets)
	delete(next, id)
	if err := s.saveLocked(next); err != nil {
		return err
	}
	s.presets = next
	return nil
}

// exportPresets renders the given presets, or all of the user's own when no ids
// are named, as the transfer format. Built-ins are skipped: the receiving
// install has its own.
func (s *enginePresetStore) exportPresets(ids []string) ([]byte, error) {
	wanted := map[string]bool{}
	for _, id := range ids {
		if trimmed := strings.TrimSpace(id); trimmed != "" {
			wanted[trimmed] = true
		}
	}
	selected := []*EnginePreset{}
	for _, preset := range s.list() {
		if preset.BuiltIn {
			continue
		}
		if len(wanted) > 0 && !wanted[preset.ID] {
			continue
		}
		selected = append(selected, preset)
	}
	if len(selected) == 0 {
		return nil, fmt.Errorf("es gibt keine eigenen Presets zum Exportieren")
	}
	payload, err := json.MarshalIndent(persistedEnginePresets{
		SchemaVersion: enginePresetSchemaVersion, Presets: selected,
	}, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(payload, '\n'), nil
}

// importPresets reads the transfer format back. Every entry is given a fresh
// id, so importing the same file twice produces copies rather than silently
// overwriting presets that happened to share an id.
func (s *enginePresetStore) importPresets(payload []byte) ([]*EnginePreset, error) {
	var incoming persistedEnginePresets
	if err := json.Unmarshal(payload, &incoming); err != nil {
		return nil, fmt.Errorf("die Preset-Datei ist kein gueltiges JSON: %w", err)
	}
	if incoming.SchemaVersion > enginePresetSchemaVersion {
		return nil, fmt.Errorf("die Preset-Datei stammt aus einer neueren Version (Schema %d)", incoming.SchemaVersion)
	}
	if len(incoming.Presets) == 0 {
		return nil, fmt.Errorf("die Preset-Datei enthaelt keine Presets")
	}
	imported := make([]*EnginePreset, 0, len(incoming.Presets))
	for _, preset := range incoming.Presets {
		if preset == nil {
			continue
		}
		saved, err := s.save(EnginePreset{
			Name: preset.Name, Description: preset.Description,
			Config: preset.Config, ModelID: preset.ModelID,
		})
		if err != nil {
			return imported, err
		}
		imported = append(imported, saved)
	}
	if len(imported) == 0 {
		return nil, fmt.Errorf("die Preset-Datei enthaelt keine verwertbaren Presets")
	}
	return imported, nil
}

func (s *enginePresetStore) saveLocked(presets map[string]*EnginePreset) error {
	ordered := make([]*EnginePreset, 0, len(presets))
	for _, preset := range presets {
		ordered = append(ordered, preset)
	}
	sort.Slice(ordered, func(a, b int) bool { return ordered[a].ID < ordered[b].ID })
	payload, err := json.MarshalIndent(persistedEnginePresets{
		SchemaVersion: enginePresetSchemaVersion, Presets: ordered,
	}, "", "  ")
	if err != nil {
		return err
	}
	return atomicPrivateWrite(s.path, append(payload, '\n'))
}

func clonePreset(preset *EnginePreset) *EnginePreset {
	if preset == nil {
		return nil
	}
	copied := *preset
	copied.Config = cloneEngineConfig(preset.Config)
	return &copied
}

func clonePresetMap(presets map[string]*EnginePreset) map[string]*EnginePreset {
	result := make(map[string]*EnginePreset, len(presets))
	for id, preset := range presets {
		result[id] = clonePreset(preset)
	}
	return result
}
