// Package apimodels tracks which hosted provider models a user has activated.
package apimodels

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

const (
	ProviderOpenRouter  = "openrouter"
	ProviderFeatherless = "featherless"

	MaxActiveModels = 8
)

var ErrActiveModelsLimitReached = errors.New("limit fuer aktive api-modelle erreicht")

type ActiveModel struct {
	Provider    string    `json:"provider"`
	ModelID     string    `json:"model_id"`
	DisplayName string    `json:"display_name"`
	ModelRef    string    `json:"model_ref"`
	StartedAt   time.Time `json:"started_at"`
	LastUsedAt  time.Time `json:"last_used_at"`
}

type Store struct {
	path   string
	mu     sync.Mutex
	loaded bool
	models map[string]ActiveModel
}

func NewStoreForSettings(settingsFile string) *Store {
	cleanPath := strings.TrimSpace(settingsFile)
	if cleanPath == "" {
		cleanPath = filepath.Join("data", "settings.json")
	}
	return NewStore(filepath.Join(filepath.Dir(cleanPath), "active_api_models.json"))
}

func NewStore(path string) *Store {
	return &Store{
		path:   strings.TrimSpace(path),
		models: make(map[string]ActiveModel),
	}
}

func NormalizeProvider(provider string) string {
	return strings.ToLower(strings.TrimSpace(strings.ReplaceAll(provider, " ", "_")))
}

func IsSupportedProvider(provider string) bool {
	switch NormalizeProvider(provider) {
	case ProviderOpenRouter, ProviderFeatherless:
		return true
	default:
		return false
	}
}

func ModelRef(provider, modelID string) string {
	cleanProvider := NormalizeProvider(provider)
	cleanModel := strings.TrimSpace(modelID)
	if cleanProvider == "" || cleanModel == "" {
		return ""
	}
	return cleanProvider + ":" + base64.RawURLEncoding.EncodeToString([]byte(cleanModel))
}

func (s *Store) Start(provider, modelID, displayName string) (ActiveModel, error) {
	cleanProvider := NormalizeProvider(provider)
	cleanModel := strings.TrimSpace(modelID)
	if !IsSupportedProvider(cleanProvider) {
		return ActiveModel{}, fmt.Errorf("provider wird fuer API-Chat nicht unterstuetzt")
	}
	if cleanModel == "" {
		return ActiveModel{}, fmt.Errorf("model_id ist erforderlich")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.loadNoLock(); err != nil {
		return ActiveModel{}, err
	}

	now := time.Now().UTC()
	ref := ModelRef(cleanProvider, cleanModel)
	model, exists := s.models[ref]
	if !exists {

		if len(s.models) >= MaxActiveModels {
			return ActiveModel{}, ErrActiveModelsLimitReached
		}
		model = ActiveModel{
			Provider:   cleanProvider,
			ModelID:    cleanModel,
			ModelRef:   ref,
			StartedAt:  now,
			LastUsedAt: now,
		}
	}
	if strings.TrimSpace(displayName) != "" {
		model.DisplayName = strings.TrimSpace(displayName)
	}
	if strings.TrimSpace(model.DisplayName) == "" {
		model.DisplayName = cleanModel
	}
	model.LastUsedAt = now
	s.models[ref] = model
	return model, s.writeNoLock()
}

func (s *Store) List() ([]ActiveModel, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.loadNoLock(); err != nil {
		return nil, err
	}
	out := make([]ActiveModel, 0, len(s.models))
	for _, model := range s.models {
		out = append(out, model)
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].LastUsedAt.After(out[j].LastUsedAt)
	})
	return out, nil
}

func (s *Store) Get(modelRef string) (ActiveModel, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.loadNoLock(); err != nil {
		return ActiveModel{}, false, err
	}
	model, ok := s.models[strings.TrimSpace(modelRef)]
	return model, ok, nil
}

func (s *Store) Touch(modelRef string) (ActiveModel, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.loadNoLock(); err != nil {
		return ActiveModel{}, false, err
	}
	ref := strings.TrimSpace(modelRef)
	model, ok := s.models[ref]
	if !ok {
		return ActiveModel{}, false, nil
	}
	model.LastUsedAt = time.Now().UTC()
	s.models[ref] = model
	if err := s.writeNoLock(); err != nil {
		return ActiveModel{}, false, err
	}
	return model, true, nil
}

func (s *Store) Delete(modelRef string) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.loadNoLock(); err != nil {
		return false, err
	}
	ref := strings.TrimSpace(modelRef)
	if _, ok := s.models[ref]; !ok {
		return false, nil
	}
	delete(s.models, ref)
	return true, s.writeNoLock()
}

func (s *Store) loadNoLock() error {
	if s.loaded {
		return nil
	}
	s.models = make(map[string]ActiveModel)
	if s.path == "" {
		s.path = filepath.Join("data", "active_api_models.json")
	}
	data, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) {
		s.loaded = true
		return nil
	}
	if err != nil {
		return err
	}
	if strings.TrimSpace(string(data)) == "" {
		s.loaded = true
		return nil
	}

	var models []ActiveModel
	if err := json.Unmarshal(data, &models); err != nil {
		return err
	}
	for _, model := range models {
		model.Provider = NormalizeProvider(model.Provider)
		model.ModelID = strings.TrimSpace(model.ModelID)
		if model.ModelID == "" || !IsSupportedProvider(model.Provider) {
			continue
		}
		if strings.TrimSpace(model.ModelRef) == "" {
			model.ModelRef = ModelRef(model.Provider, model.ModelID)
		}
		if strings.TrimSpace(model.DisplayName) == "" {
			model.DisplayName = model.ModelID
		}
		s.models[model.ModelRef] = model
	}
	s.loaded = true
	return nil
}

func (s *Store) writeNoLock() error {
	out := make([]ActiveModel, 0, len(s.models))
	for _, model := range s.models {
		out = append(out, model)
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].LastUsedAt.After(out[j].LastUsedAt)
	})
	payload, err := json.MarshalIndent(out, "", "  ")
	if err != nil {
		return err
	}
	payload = append(payload, '\n')
	if err := os.MkdirAll(filepath.Dir(s.path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(s.path, payload, 0o600)
}
