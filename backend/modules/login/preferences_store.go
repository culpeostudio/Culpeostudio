package login

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

const (
	defaultUserLanguage        = "de"
	defaultUserFrontendVersion = "classic"
	userPreferencesSchema      = 1
)

var (
	errInvalidUserLanguage        = errors.New("language muss 'de' oder 'en' sein")
	errInvalidUserFrontendVersion = errors.New("frontend_version muss 'lite' oder 'classic' sein")
)

// UserPreferences contains the UI choices that belong to one authenticated
// login. An entry is written only after the user confirms both choices, so a
// missing entry remains the durable signal for the first-login flow.
type UserPreferences struct {
	Language        string `json:"language"`
	FrontendVersion string `json:"frontend_version"`
}

type persistedUserPreferences struct {
	SchemaVersion int                        `json:"schema_version"`
	Users         map[string]UserPreferences `json:"users"`
}

// UserPreferencesStore persists the per-login UI profile separately from
// login_accounts.json. Keeping it separate avoids rewriting password hashes
// whenever a user changes a visual preference.
type UserPreferencesStore struct {
	path  string
	mu    sync.RWMutex
	users map[string]UserPreferences
}

func NewUserPreferencesStore(path string) *UserPreferencesStore {
	return &UserPreferencesStore{
		path:  strings.TrimSpace(path),
		users: make(map[string]UserPreferences),
	}
}

func (s *UserPreferencesStore) Load() error {
	if s == nil {
		return errors.New("Benutzerpraeferenzen sind nicht initialisiert")
	}
	if s.path == "" {
		return errors.New("Benutzerpraeferenzen-Dateipfad ist leer")
	}
	s.mu.Lock()
	defer s.mu.Unlock()

	payload, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) {
		s.users = make(map[string]UserPreferences)
		return nil
	}
	if err != nil {
		return fmt.Errorf("Benutzerpraeferenzen lesen: %w", err)
	}
	if len(strings.TrimSpace(string(payload))) == 0 {
		s.users = make(map[string]UserPreferences)
		return nil
	}

	var persisted persistedUserPreferences
	if err := json.Unmarshal(payload, &persisted); err != nil {
		return fmt.Errorf("Benutzerpraeferenzen enthalten ungueltiges JSON: %w", err)
	}
	if persisted.SchemaVersion != userPreferencesSchema {
		return fmt.Errorf("Benutzerpraeferenzen-Schema %d wird nicht unterstuetzt", persisted.SchemaVersion)
	}

	loaded := make(map[string]UserPreferences, len(persisted.Users))
	for userID, preferences := range persisted.Users {
		userID = normalizeUsername(userID)
		if userID == "" {
			continue
		}
		preferences, err = normalizedUserPreferences(preferences.Language, preferences.FrontendVersion)
		if err != nil {
			return fmt.Errorf("Benutzerpraeferenzen fuer %q sind ungueltig: %w", userID, err)
		}
		loaded[userID] = preferences
	}

	s.users = loaded
	if err := os.Chmod(s.path, 0o600); err != nil {
		return fmt.Errorf("Benutzerpraeferenzen-Berechtigungen setzen: %w", err)
	}
	return nil
}

// Get returns stable defaults together with configured=false when the login
// has not completed onboarding yet.
func (s *UserPreferencesStore) Get(username string) (UserPreferences, bool) {
	if s == nil {
		return defaultUserPreferences(), false
	}
	userID := normalizeUsername(username)
	if userID == "" {
		return defaultUserPreferences(), false
	}

	s.mu.RLock()
	preferences, configured := s.users[userID]
	s.mu.RUnlock()
	if !configured {
		return defaultUserPreferences(), false
	}
	return preferences, true
}

// Set validates and atomically persists the complete profile. A full profile
// is required so an interrupted onboarding flow never becomes configured with
// only one of its two choices.
func (s *UserPreferencesStore) Set(username, language, frontendVersion string) (UserPreferences, error) {
	if s == nil {
		return UserPreferences{}, errors.New("Benutzerpraeferenzen sind nicht initialisiert")
	}
	userID := normalizeUsername(username)
	if userID == "" {
		return UserPreferences{}, errors.New("Benutzerkennung ist erforderlich")
	}
	preferences, err := normalizedUserPreferences(language, frontendVersion)
	if err != nil {
		return UserPreferences{}, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	nextUsers := cloneUserPreferences(s.users)
	nextUsers[userID] = preferences
	if err := s.writeLocked(nextUsers); err != nil {
		return UserPreferences{}, err
	}
	s.users = nextUsers
	return preferences, nil
}

func defaultUserPreferences() UserPreferences {
	return UserPreferences{
		Language:        defaultUserLanguage,
		FrontendVersion: defaultUserFrontendVersion,
	}
}

func normalizedUserPreferences(language, frontendVersion string) (UserPreferences, error) {
	language = strings.ToLower(strings.TrimSpace(language))
	frontendVersion = strings.ToLower(strings.TrimSpace(frontendVersion))
	if language != "de" && language != "en" {
		return UserPreferences{}, errInvalidUserLanguage
	}
	if frontendVersion != "lite" && frontendVersion != "classic" {
		return UserPreferences{}, errInvalidUserFrontendVersion
	}
	return UserPreferences{Language: language, FrontendVersion: frontendVersion}, nil
}

func cloneUserPreferences(users map[string]UserPreferences) map[string]UserPreferences {
	cloned := make(map[string]UserPreferences, len(users)+1)
	for userID, preferences := range users {
		cloned[userID] = preferences
	}
	return cloned
}

func (s *UserPreferencesStore) writeLocked(users map[string]UserPreferences) error {
	if s.path == "" {
		return errors.New("Benutzerpraeferenzen-Dateipfad ist leer")
	}
	persisted := persistedUserPreferences{
		SchemaVersion: userPreferencesSchema,
		Users:         cloneUserPreferences(users),
	}
	payload, err := json.MarshalIndent(persisted, "", "  ")
	if err != nil {
		return fmt.Errorf("Benutzerpraeferenzen serialisieren: %w", err)
	}
	return atomicPrivateWriteUserPreferences(s.path, append(payload, '\n'))
}

// atomicPrivateWriteUserPreferences makes a complete profile replacement
// visible in one rename and keeps user data private on disk. The temporary
// file is created beside the target so os.Rename stays atomic on one volume.
func atomicPrivateWriteUserPreferences(path string, payload []byte) (err error) {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}

	temporary, err := os.CreateTemp(dir, filepath.Base(path)+".tmp-*")
	if err != nil {
		return err
	}
	temporaryPath := temporary.Name()
	defer func() {
		if err != nil {
			_ = temporary.Close()
			_ = os.Remove(temporaryPath)
		}
	}()

	if err := temporary.Chmod(0o600); err != nil {
		return err
	}
	if _, err := temporary.Write(payload); err != nil {
		return err
	}
	if err := temporary.Sync(); err != nil {
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	if err := os.Rename(temporaryPath, path); err != nil {
		return err
	}
	return nil
}
