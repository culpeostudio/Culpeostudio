package engine

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
)

type engineUserPreferences struct {
	VisibleInstanceIDs []string `json:"visible_instance_ids,omitempty"`
}

type persistedEngineUserPreferences struct {
	SchemaVersion int                              `json:"schema_version"`
	Users         map[string]engineUserPreferences `json:"users"`
}

// enginePreferenceStore deliberately lives outside engine_instances.json:
// instances and hardware are machine-wide, while picker visibility belongs to
// the authenticated login. Every mutation is an atomic 0600 replacement.
type enginePreferenceStore struct {
	mu    sync.RWMutex
	path  string
	users map[string]engineUserPreferences
}

func newEnginePreferenceStore(path string) (*enginePreferenceStore, error) {
	store := &enginePreferenceStore{path: path, users: map[string]engineUserPreferences{}}
	payload, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return store, nil
	}
	if err != nil {
		return nil, err
	}
	var persisted persistedEngineUserPreferences
	if err := json.Unmarshal(payload, &persisted); err != nil {
		return nil, fmt.Errorf("Engine-Benutzereinstellungen ungueltig: %w", err)
	}
	for userID, preferences := range persisted.Users {
		userID = normalizedEngineUserID(userID)
		if userID == "" {
			continue
		}
		preferences.VisibleInstanceIDs = uniqueStrings(preferences.VisibleInstanceIDs)
		store.users[userID] = preferences
	}
	if err := os.Chmod(path, 0o600); err != nil {
		return nil, err
	}
	return store, nil
}

func normalizedEngineUserID(value string) string {
	// Login account keys are case-insensitive but otherwise preserve the full
	// trimmed username. Using the stricter memory/file-name sanitizer here would
	// merge distinct valid accounts such as "alice" and "alice!", and would map
	// Unicode-only names to the shared fallback namespace.
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return "local"
	}
	return value
}

func (s *enginePreferenceStore) visible(userID, instanceID string) bool {
	if s == nil {
		return false
	}
	userID = normalizedEngineUserID(userID)
	instanceID = strings.TrimSpace(instanceID)
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, id := range s.users[userID].VisibleInstanceIDs {
		if id == instanceID {
			return true
		}
	}
	return false
}

func (s *enginePreferenceStore) setVisible(userID, instanceID string, visible bool) error {
	if s == nil {
		return fmt.Errorf("Engine-Benutzereinstellungen sind nicht initialisiert")
	}
	userID = normalizedEngineUserID(userID)
	instanceID = strings.TrimSpace(instanceID)
	if instanceID == "" {
		return fmt.Errorf("Instanz-ID ist erforderlich")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	nextUsers := cloneEnginePreferenceUsers(s.users)
	preferences := nextUsers[userID]
	ids := make([]string, 0, len(preferences.VisibleInstanceIDs)+1)
	for _, id := range preferences.VisibleInstanceIDs {
		if id != instanceID {
			ids = append(ids, id)
		}
	}
	if visible {
		ids = append(ids, instanceID)
	}
	sort.Strings(ids)
	preferences.VisibleInstanceIDs = ids
	if len(ids) == 0 {
		delete(nextUsers, userID)
	} else {
		nextUsers[userID] = preferences
	}
	if err := s.saveUsersLocked(nextUsers); err != nil {
		return err
	}
	s.users = nextUsers
	return nil
}

func cloneEnginePreferenceUsers(input map[string]engineUserPreferences) map[string]engineUserPreferences {
	result := make(map[string]engineUserPreferences, len(input))
	for userID, preferences := range input {
		preferences.VisibleInstanceIDs = append([]string(nil), preferences.VisibleInstanceIDs...)
		result[userID] = preferences
	}
	return result
}

func (s *enginePreferenceStore) saveUsersLocked(users map[string]engineUserPreferences) error {
	persisted := persistedEngineUserPreferences{SchemaVersion: 1, Users: map[string]engineUserPreferences{}}
	for userID, preferences := range users {
		preferences.VisibleInstanceIDs = append([]string(nil), preferences.VisibleInstanceIDs...)
		persisted.Users[userID] = preferences
	}
	payload, err := json.MarshalIndent(persisted, "", "  ")
	if err != nil {
		return err
	}
	return atomicPrivateWrite(s.path, append(payload, '\n'))
}
