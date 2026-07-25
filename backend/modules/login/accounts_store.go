package login

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"

	"golang.org/x/crypto/bcrypt"
)

var (
	ErrUserExists   = errors.New("user already exists")
	ErrUserNotFound = errors.New("user not found")
)

type accountRecord struct {
	Username     string `json:"username"`
	PasswordHash string `json:"password_hash"`
}

type accountFile struct {
	Users []accountRecord `json:"users"`
}

type AccountStore struct {
	path  string
	mu    sync.RWMutex
	users map[string]accountRecord
}

func NewAccountStore(path string) *AccountStore {
	return &AccountStore{
		path:  strings.TrimSpace(path),
		users: make(map[string]accountRecord),
	}
}

func (s *AccountStore) Path() string {
	return s.path
}

func normalizeUsername(username string) string {
	return strings.ToLower(strings.TrimSpace(username))
}

func (s *AccountStore) Load() error {
	if s.path == "" {
		return errors.New("accounts file path is empty")
	}

	data, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) {
		s.mu.Lock()
		s.users = make(map[string]accountRecord)
		s.mu.Unlock()
		return nil
	}
	if err != nil {
		return err
	}

	if len(strings.TrimSpace(string(data))) == 0 {
		s.mu.Lock()
		s.users = make(map[string]accountRecord)
		s.mu.Unlock()
		return nil
	}

	var payload accountFile
	if err := json.Unmarshal(data, &payload); err != nil {
		return err
	}

	loaded := make(map[string]accountRecord)
	for _, u := range payload.Users {
		key := normalizeUsername(u.Username)
		if key == "" || strings.TrimSpace(u.PasswordHash) == "" {
			continue
		}
		u.Username = strings.TrimSpace(u.Username)
		loaded[key] = u
	}

	s.mu.Lock()
	s.users = loaded
	s.mu.Unlock()
	return nil
}

func (s *AccountStore) ValidateCredentials(username, password string) bool {
	key := normalizeUsername(username)
	if key == "" || strings.TrimSpace(password) == "" {
		return false
	}

	s.mu.RLock()
	user, ok := s.users[key]
	s.mu.RUnlock()
	if !ok {
		return false
	}

	return bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)) == nil
}

// CanonicalUsername resolves a case-insensitive login name to the spelling
// stored for the account. JWT subjects and per-user stores must not depend on
// how the user happened to capitalize the login form.
func (s *AccountStore) CanonicalUsername(username string) (string, bool) {
	key := normalizeUsername(username)
	if key == "" {
		return "", false
	}
	s.mu.RLock()
	user, ok := s.users[key]
	s.mu.RUnlock()
	if !ok {
		return "", false
	}
	return user.Username, true
}

func (s *AccountStore) ListUsers() []string {
	s.mu.RLock()
	usernames := make([]string, 0, len(s.users))
	for _, user := range s.users {
		usernames = append(usernames, user.Username)
	}
	s.mu.RUnlock()

	sort.Slice(usernames, func(i, j int) bool {
		return strings.ToLower(usernames[i]) < strings.ToLower(usernames[j])
	})

	return usernames
}

func (s *AccountStore) UserExists(username string) bool {
	key := normalizeUsername(username)
	if key == "" {
		return false
	}

	s.mu.RLock()
	_, ok := s.users[key]
	s.mu.RUnlock()
	return ok
}

func (s *AccountStore) CreateUser(username, password string) error {
	if s.path == "" {
		return errors.New("accounts file path is empty")
	}

	cleanUsername := strings.TrimSpace(username)
	cleanPassword := strings.TrimSpace(password)
	key := normalizeUsername(cleanUsername)
	if key == "" || cleanPassword == "" {
		return errors.New("username and password are required")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(cleanPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	s.mu.Lock()
	if _, exists := s.users[key]; exists {
		s.mu.Unlock()
		return ErrUserExists
	}
	s.users[key] = accountRecord{
		Username:     cleanUsername,
		PasswordHash: string(hash),
	}
	usersCopy := snapshotRecords(s.users)
	s.mu.Unlock()

	return s.writeRecords(usersCopy)
}

func (s *AccountStore) ResetPassword(username, password string) error {
	if s.path == "" {
		return errors.New("accounts file path is empty")
	}

	cleanUsername := strings.TrimSpace(username)
	cleanPassword := strings.TrimSpace(password)
	key := normalizeUsername(cleanUsername)
	if key == "" || cleanPassword == "" {
		return errors.New("username and password are required")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(cleanPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	s.mu.Lock()
	user, ok := s.users[key]
	if !ok {
		s.mu.Unlock()
		return ErrUserNotFound
	}
	user.PasswordHash = string(hash)
	s.users[key] = user
	usersCopy := snapshotRecords(s.users)
	s.mu.Unlock()

	return s.writeRecords(usersCopy)
}

func (s *AccountStore) DeleteUser(username string) (bool, error) {
	key := normalizeUsername(username)
	if key == "" {
		return false, errors.New("username is required")
	}

	s.mu.Lock()
	if _, ok := s.users[key]; !ok {
		s.mu.Unlock()
		return false, nil
	}
	delete(s.users, key)
	usersCopy := snapshotRecords(s.users)
	s.mu.Unlock()

	if err := s.writeRecords(usersCopy); err != nil {
		return false, err
	}
	return true, nil
}

func snapshotRecords(users map[string]accountRecord) []accountRecord {
	records := make([]accountRecord, 0, len(users))
	for _, user := range users {
		records = append(records, user)
	}

	sort.Slice(records, func(i, j int) bool {
		return strings.ToLower(records[i].Username) < strings.ToLower(records[j].Username)
	})

	return records
}

func (s *AccountStore) writeRecords(records []accountRecord) error {
	payload := accountFile{Users: records}
	serialized, err := json.MarshalIndent(payload, "", "  ")
	if err != nil {
		return err
	}
	serialized = append(serialized, '\n')

	dir := filepath.Dir(s.path)
	if dir != "." {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return err
		}
	}

	return os.WriteFile(s.path, serialized, 0o600)
}
