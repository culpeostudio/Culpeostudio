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
	defaultUserLanguage   = "de"
	userPreferencesSchema = 1
)

var errInvalidUserLanguage = errors.New("language muss 'de' oder 'en' sein")

type UserPreferences struct {
	Language string `json:"language"`
}

type persistedUserPreferences struct {
	SchemaVersion int                        `json:"schema_version"`
	Users         map[string]UserPreferences `json:"users"`
}

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
		preferences, err = normalizedUserPreferences(preferences.Language)
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

func (s *UserPreferencesStore) Set(username, language string) (UserPreferences, error) {
	if s == nil {
		return UserPreferences{}, errors.New("Benutzerpraeferenzen sind nicht initialisiert")
	}
	userID := normalizeUsername(username)
	if userID == "" {
		return UserPreferences{}, errors.New("Benutzerkennung ist erforderlich")
	}
	preferences, err := normalizedUserPreferences(language)
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
		Language: defaultUserLanguage,
	}
}

func normalizedUserPreferences(language string) (UserPreferences, error) {
	language = strings.ToLower(strings.TrimSpace(language))
	if language != "de" && language != "en" {
		return UserPreferences{}, errInvalidUserLanguage
	}
	return UserPreferences{Language: language}, nil
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
