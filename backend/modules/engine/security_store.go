package engine

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

type engineKeyRecord struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	Hash        string     `json:"hash,omitempty"`
	InstanceIDs []string   `json:"instance_ids,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	LastUsedAt  *time.Time `json:"last_used_at,omitempty"`
	RevokedAt   *time.Time `json:"revoked_at,omitempty"`
}

type engineKeyPublic struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	InstanceIDs []string   `json:"instance_ids,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	LastUsedAt  *time.Time `json:"last_used_at,omitempty"`
	RevokedAt   *time.Time `json:"revoked_at,omitempty"`
}

type engineKeyStore struct {
	mu   sync.RWMutex
	path string
	keys map[string]*engineKeyRecord
}

func newEngineKeyStore(path string) (*engineKeyStore, error) {
	store := &engineKeyStore{path: path, keys: map[string]*engineKeyRecord{}}
	if err := store.load(); err != nil {
		return nil, err
	}
	return store, nil
}

func (s *engineKeyStore) create(name string, instanceIDs []string) (engineKeyPublic, string, error) {
	id, err := randomHex(8)
	if err != nil {
		return engineKeyPublic{}, "", err
	}
	secret, err := randomHex(24)
	if err != nil {
		return engineKeyPublic{}, "", err
	}
	plaintext := "phe_" + id + "_" + secret
	sum := sha256.Sum256([]byte(plaintext))
	record := &engineKeyRecord{
		ID: id, Name: strings.TrimSpace(name), Hash: hex.EncodeToString(sum[:]),
		InstanceIDs: uniqueStrings(instanceIDs), CreatedAt: time.Now().UTC(),
	}
	if record.Name == "" {
		record.Name = "Lokaler Engine-Schluessel"
	}
	s.mu.Lock()
	s.keys[id] = record
	err = s.saveLocked()
	s.mu.Unlock()
	if err != nil {
		return engineKeyPublic{}, "", err
	}
	return publicEngineKey(record), plaintext, nil
}

func (s *engineKeyStore) list() []engineKeyPublic {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]engineKeyPublic, 0, len(s.keys))
	for _, record := range s.keys {
		result = append(result, publicEngineKey(record))
	}
	sort.Slice(result, func(i, j int) bool { return result[i].CreatedAt.Before(result[j].CreatedAt) })
	return result
}

func (s *engineKeyStore) revoke(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	record := s.keys[id]
	if record == nil || record.RevokedAt != nil {
		return false
	}
	now := time.Now().UTC()
	record.RevokedAt = &now
	return s.saveLocked() == nil
}

func (s *engineKeyStore) rotate(id string) (engineKeyPublic, string, error) {
	s.mu.RLock()
	record := s.keys[id]
	if record == nil {
		s.mu.RUnlock()
		return engineKeyPublic{}, "", os.ErrNotExist
	}
	name := record.Name
	scope := append([]string(nil), record.InstanceIDs...)
	s.mu.RUnlock()
	if !s.revoke(id) {
		return engineKeyPublic{}, "", errors.New("Schluessel ist bereits widerrufen")
	}
	return s.create(name, scope)
}

func (s *engineKeyStore) authorize(plaintext, instanceID string) bool {
	scope, ok := s.authorizedScope(plaintext)
	return ok && (len(scope) == 0 || containsString(scope, instanceID))
}

func (s *engineKeyStore) authorizedScope(plaintext string) ([]string, bool) {
	sum := sha256.Sum256([]byte(strings.TrimSpace(plaintext)))
	wanted := []byte(hex.EncodeToString(sum[:]))
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, record := range s.keys {
		if record.RevokedAt != nil || subtle.ConstantTimeCompare([]byte(record.Hash), wanted) != 1 {
			continue
		}
		now := time.Now().UTC()
		record.LastUsedAt = &now

		_ = s.saveLocked()
		return append([]string(nil), record.InstanceIDs...), true
	}
	return nil, false
}

func (s *engineKeyStore) load() error {
	data, err := os.ReadFile(s.path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return err
	}
	var records []*engineKeyRecord
	if err := json.Unmarshal(data, &records); err != nil {
		return fmt.Errorf("Engine-Schluesseldatei ungueltig: %w", err)
	}
	for _, record := range records {
		if record != nil && record.ID != "" && record.Hash != "" {
			s.keys[record.ID] = record
		}
	}
	return nil
}

func (s *engineKeyStore) saveLocked() error {
	records := make([]*engineKeyRecord, 0, len(s.keys))
	for _, record := range s.keys {
		copy := *record
		copy.InstanceIDs = append([]string(nil), record.InstanceIDs...)
		records = append(records, &copy)
	}
	sort.Slice(records, func(i, j int) bool { return records[i].CreatedAt.Before(records[j].CreatedAt) })
	payload, err := json.MarshalIndent(records, "", "  ")
	if err != nil {
		return err
	}
	payload = append(payload, '\n')
	return atomicPrivateWrite(s.path, payload)
}

func publicEngineKey(record *engineKeyRecord) engineKeyPublic {
	return engineKeyPublic{ID: record.ID, Name: record.Name, InstanceIDs: append([]string(nil), record.InstanceIDs...), CreatedAt: record.CreatedAt, LastUsedAt: record.LastUsedAt, RevokedAt: record.RevokedAt}
}

type remoteCodeApproval struct {
	ModelFingerprint string    `json:"model_fingerprint"`
	PythonFilesHash  string    `json:"python_files_hash"`
	ApprovedAt       time.Time `json:"approved_at"`
}

type remoteCodeStore struct {
	mu        sync.RWMutex
	path      string
	approvals map[string]remoteCodeApproval
}

func newRemoteCodeStore(path string) (*remoteCodeStore, error) {
	s := &remoteCodeStore{path: path, approvals: map[string]remoteCodeApproval{}}
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return s, nil
	}
	if err != nil {
		return nil, err
	}
	var approvals []remoteCodeApproval
	if err := json.Unmarshal(data, &approvals); err != nil {
		return nil, err
	}
	for _, approval := range approvals {
		s.approvals[approval.ModelFingerprint] = approval
	}
	return s, nil
}

func (s *remoteCodeStore) approve(fingerprint, pythonHash string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.approvals[fingerprint] = remoteCodeApproval{ModelFingerprint: fingerprint, PythonFilesHash: pythonHash, ApprovedAt: time.Now().UTC()}
	return s.saveLocked()
}

func (s *remoteCodeStore) approved(fingerprint, pythonHash string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	approval, ok := s.approvals[fingerprint]
	return ok && approval.PythonFilesHash == pythonHash
}

func (s *remoteCodeStore) saveLocked() error {
	items := make([]remoteCodeApproval, 0, len(s.approvals))
	for _, item := range s.approvals {
		items = append(items, item)
	}
	sort.Slice(items, func(i, j int) bool { return items[i].ModelFingerprint < items[j].ModelFingerprint })
	payload, err := json.MarshalIndent(items, "", "  ")
	if err != nil {
		return err
	}
	return atomicPrivateWrite(s.path, append(payload, '\n'))
}

func hashPythonFiles(root string) (string, int, error) {
	type fileHash struct{ path, hash string }
	files := []fileHash{}
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() || !strings.EqualFold(filepath.Ext(entry.Name()), ".py") {
			return nil
		}
		if entry.Type()&os.ModeSymlink != 0 {
			resolved, err := filepath.EvalSymlinks(path)
			if err != nil {
				return err
			}
			relative, err := filepath.Rel(root, resolved)
			if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) || filepath.IsAbs(relative) {
				return fmt.Errorf("Python-Symlink %s verlaesst den Modellordner", entry.Name())
			}
		}
		info, err := entry.Info()
		if err != nil {
			return err
		}
		if info.Size() > 8<<20 {
			return fmt.Errorf("Python-Datei %s ist fuer Remote-Code-Zustimmung zu gross", entry.Name())
		}
		file, err := os.Open(path)
		if err != nil {
			return err
		}
		h := sha256.New()
		_, copyErr := io.Copy(h, file)
		closeErr := file.Close()
		if copyErr != nil {
			return copyErr
		}
		if closeErr != nil {
			return closeErr
		}
		relative, _ := filepath.Rel(root, path)
		files = append(files, fileHash{filepath.ToSlash(relative), hex.EncodeToString(h.Sum(nil))})
		return nil
	})
	if err != nil {
		return "", 0, err
	}
	sort.Slice(files, func(i, j int) bool { return files[i].path < files[j].path })
	h := sha256.New()
	for _, file := range files {
		_, _ = io.WriteString(h, file.path+"\x00"+file.hash+"\n")
	}
	return hex.EncodeToString(h.Sum(nil)), len(files), nil
}

func atomicPrivateWrite(path string, payload []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, payload, 0o600); err != nil {
		return err
	}
	if err := os.Chmod(tmp, 0o600); err != nil {
		_ = os.Remove(tmp)
		return err
	}
	if err := os.Rename(tmp, path); err != nil {
		_ = os.Remove(tmp)
		return err
	}
	return os.Chmod(path, 0o600)
}

func randomHex(bytes int) (string, error) {
	buffer := make([]byte, bytes)
	if _, err := rand.Read(buffer); err != nil {
		return "", err
	}
	return hex.EncodeToString(buffer), nil
}

func uniqueStrings(values []string) []string {
	seen := map[string]bool{}
	result := []string{}
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value != "" && !seen[value] {
			seen[value] = true
			result = append(result, value)
		}
	}
	sort.Strings(result)
	return result
}

func containsString(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}
