package appsettings

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
)

const (
	DefaultSettingsFile = "data/settings.json"
	DefaultModelDir     = "data/models"
)

type Settings struct {
	ModelDir              string            `json:"model_dir"`
	HuggingFaceToken      string            `json:"huggingface_token,omitempty"`
	OpenRouterToken       string            `json:"openrouter_token,omitempty"`
	FeatherlessToken      string            `json:"featherless_token,omitempty"`
	Shortcuts             map[string]string `json:"shortcuts,omitempty"`
	EngineRAMReserveBytes *int64            `json:"engine_ram_reserve_bytes,omitempty"`
	EngineGPUReserveBytes *int64            `json:"engine_gpu_reserve_bytes,omitempty"`
}

type Update struct {
	ModelDir              *string
	HuggingFaceToken      *string
	OpenRouterToken       *string
	FeatherlessToken      *string
	Shortcuts             map[string]string
	EngineRAMReserveBytes *int64
	EngineGPUReserveBytes *int64
	ResetEngineReserves   bool
}

type Store struct {
	path     string
	mu       sync.RWMutex
	loaded   bool
	settings Settings
}

func NewStore(path string) *Store {
	cleanPath := strings.TrimSpace(path)
	if cleanPath == "" {
		cleanPath = DefaultSettingsFile
	}
	return &Store{
		path:     cleanPath,
		settings: defaultSettings(),
	}
}

func defaultShortcuts() map[string]string {
	return map[string]string{
		"switch_to_chat":         "ctrl+alt+c",
		"switch_to_philox":       "ctrl+alt+p",
		"switch_to_engine":       "ctrl+alt+e",
		"switch_to_marketplace":  "ctrl+alt+m",
		"switch_to_training":     "ctrl+alt+t",
		"switch_to_quantization": "ctrl+alt+q",
		"switch_to_generative":   "ctrl+alt+g",
		"switch_to_news":         "ctrl+alt+n",
		"switch_to_settings":     "ctrl+alt+s",
		"toggle_sidebar":         "ctrl+shift+f",
		"focus_chat_input":       "ctrl+i",
		"new_chat_session":       "ctrl+k",
		"toggle_chat_tab":        "ctrl+tab",
		"toggle_engine":          "ctrl+alt+enter",
		"load_model":             "ctrl+alt+l",
		"focus_search":           "ctrl+f",
		"show_help":              "f1",
		"toggle_theme":           "ctrl+shift+t",
	}
}

func defaultSettings() Settings {
	return Settings{
		ModelDir:  DefaultModelDir,
		Shortcuts: defaultShortcuts(),
	}
}

func (s *Store) Path() string {
	return s.path
}

func (s *Store) Load() error {
	data, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) {
		s.mu.Lock()
		s.loaded = true
		s.settings = defaultSettings()
		s.mu.Unlock()
		return nil
	}
	if err != nil {
		return err
	}

	if len(strings.TrimSpace(string(data))) == 0 {
		s.mu.Lock()
		s.loaded = true
		s.settings = defaultSettings()
		s.mu.Unlock()
		return nil
	}

	loaded := defaultSettings()
	if err := json.Unmarshal(data, &loaded); err != nil {
		return err
	}

	loaded.ModelDir = strings.TrimSpace(loaded.ModelDir)
	if loaded.ModelDir == "" {
		loaded.ModelDir = DefaultModelDir
	}
	loaded.HuggingFaceToken = strings.TrimSpace(loaded.HuggingFaceToken)
	loaded.OpenRouterToken = strings.TrimSpace(loaded.OpenRouterToken)
	loaded.FeatherlessToken = strings.TrimSpace(loaded.FeatherlessToken)
	if loaded.Shortcuts == nil {
		loaded.Shortcuts = defaultShortcuts()
	}

	s.mu.Lock()
	s.loaded = true
	s.settings = loaded
	s.mu.Unlock()
	return nil
}

func (s *Store) Get() Settings {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.settings
}

func (s *Store) Update(update Update) (Settings, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if !s.loaded {
		s.settings = defaultSettings()
		s.loaded = true
	}

	if update.ModelDir != nil {
		v := strings.TrimSpace(*update.ModelDir)
		if v == "" {
			v = DefaultModelDir
		}
		resolved, err := prepareModelDir(v)
		if err != nil {
			return Settings{}, err
		}
		s.settings.ModelDir = resolved
	}
	if update.HuggingFaceToken != nil {
		s.settings.HuggingFaceToken = strings.TrimSpace(*update.HuggingFaceToken)
	}
	if update.OpenRouterToken != nil {
		s.settings.OpenRouterToken = strings.TrimSpace(*update.OpenRouterToken)
	}
	if update.FeatherlessToken != nil {
		s.settings.FeatherlessToken = strings.TrimSpace(*update.FeatherlessToken)
	}
	if update.Shortcuts != nil {
		s.settings.Shortcuts = update.Shortcuts
	}
	if update.ResetEngineReserves {
		s.settings.EngineRAMReserveBytes = nil
		s.settings.EngineGPUReserveBytes = nil
	}
	if update.EngineRAMReserveBytes != nil {
		if *update.EngineRAMReserveBytes < 0 {
			return Settings{}, errors.New("die Engine-RAM-Reserve darf nicht negativ sein")
		}
		value := *update.EngineRAMReserveBytes
		s.settings.EngineRAMReserveBytes = &value
	}
	if update.EngineGPUReserveBytes != nil {
		if *update.EngineGPUReserveBytes < 0 {
			return Settings{}, errors.New("die Engine-GPU-Reserve darf nicht negativ sein")
		}
		value := *update.EngineGPUReserveBytes
		s.settings.EngineGPUReserveBytes = &value
	}

	if err := s.writeLocked(); err != nil {
		return Settings{}, err
	}
	return s.settings, nil
}

func prepareModelDir(raw string) (string, error) {
	value := strings.TrimSpace(raw)
	if runtime.GOOS != "windows" && LooksLikeWindowsPath(value) {
		return "", errors.New("der Modellordner ist ein Windows-Pfad; bitte auf diesem System einen Linux-Ordner auswählen")
	}
	abs, err := filepath.Abs(filepath.Clean(value))
	if err != nil {
		return "", errors.New("der Modellordner ist ungültig")
	}
	if err := os.MkdirAll(abs, 0o755); err != nil {
		return "", errors.New("der Modellordner konnte nicht angelegt werden")
	}
	info, err := os.Stat(abs)
	if err != nil || !info.IsDir() {
		return "", errors.New("der gewählte Modellpfad ist kein Ordner")
	}
	return abs, nil
}

// LooksLikeWindowsPath erkennt Laufwerkspfade wie D:\\Modelle. Andere
// Module nutzen dies, um auf Linux kein Verzeichnis mit literalem Namen
// "D:\\..." innerhalb des Backend-Arbeitsordners anzulegen.
func LooksLikeWindowsPath(value string) bool {
	return len(value) >= 3 &&
		((value[0] >= 'A' && value[0] <= 'Z') || (value[0] >= 'a' && value[0] <= 'z')) &&
		value[1] == ':' && (value[2] == '\\' || value[2] == '/')
}

func (s *Store) writeLocked() error {
	payload, err := json.MarshalIndent(s.settings, "", "  ")
	if err != nil {
		return err
	}
	payload = append(payload, '\n')

	dir := filepath.Dir(s.path)
	if dir != "." {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return err
		}
	}

	return os.WriteFile(s.path, payload, 0o600)
}
