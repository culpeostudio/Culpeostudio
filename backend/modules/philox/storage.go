package philox

import (
	"compress/gzip"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"sync"
)

type sessionStorage struct {
	baseDir string
}

func newSessionStorage(baseDir string) *sessionStorage {
	return &sessionStorage{baseDir: baseDir}
}

func (s *sessionStorage) Initialize() error {
	return os.MkdirAll(s.baseDir, 0o755)
}

func (s *sessionStorage) sessionPath(id string) string {
	return filepath.Join(s.baseDir, id+".json.gz")
}

func (s *sessionStorage) metaPath(id string) string {
	return filepath.Join(s.baseDir, id+".meta.json")
}

func (s *sessionStorage) SaveSession(session *PersistedSession) error {
	if err := s.Initialize(); err != nil {
		return err
	}
	tempPath := s.sessionPath(session.ID) + ".tmp"
	file, err := os.Create(tempPath)
	if err != nil {
		return fmt.Errorf("create session temp file: %w", err)
	}

	gzipWriter := gzip.NewWriter(file)
	encoder := json.NewEncoder(gzipWriter)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(session); err != nil {
		_ = gzipWriter.Close()
		_ = file.Close()
		_ = os.Remove(tempPath)
		return fmt.Errorf("encode session: %w", err)
	}
	if err := gzipWriter.Close(); err != nil {
		_ = file.Close()
		_ = os.Remove(tempPath)
		return fmt.Errorf("close gzip writer: %w", err)
	}
	if err := file.Close(); err != nil {
		_ = os.Remove(tempPath)
		return fmt.Errorf("close temp file: %w", err)
	}
	if err := os.Rename(tempPath, s.sessionPath(session.ID)); err != nil {
		_ = os.Remove(tempPath)
		return fmt.Errorf("replace session file: %w", err)
	}
	return s.SaveMeta(session.Summary())
}

func (s *sessionStorage) LoadSession(id string) (*PersistedSession, error) {
	file, err := os.Open(s.sessionPath(id))
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, err
		}
		return nil, fmt.Errorf("open session: %w", err)
	}
	defer file.Close()

	gzipReader, err := gzip.NewReader(file)
	if err != nil {
		return nil, fmt.Errorf("open gzip reader: %w", err)
	}
	defer gzipReader.Close()

	var session PersistedSession
	if err := json.NewDecoder(gzipReader).Decode(&session); err != nil {
		return nil, fmt.Errorf("decode session: %w", err)
	}
	if session.Messages == nil {
		session.Messages = []ConversationMessage{}
	}
	if session.ArchivedMessages == nil {
		session.ArchivedMessages = []ConversationMessage{}
	}
	if session.CompressedMemories == nil {
		session.CompressedMemories = []CompressedMemory{}
	}
	if session.ToolAudit == nil {
		session.ToolAudit = []ToolAuditEntry{}
	}
	return &session, nil
}

func (s *sessionStorage) SaveMeta(summary SessionSummary) error {
	if err := s.Initialize(); err != nil {
		return err
	}
	tempPath := s.metaPath(summary.ID) + ".tmp"
	payload, err := json.MarshalIndent(summary, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal session metadata: %w", err)
	}
	if err := os.WriteFile(tempPath, payload, 0o644); err != nil {
		return fmt.Errorf("write metadata temp file: %w", err)
	}
	if err := os.Rename(tempPath, s.metaPath(summary.ID)); err != nil {
		_ = os.Remove(tempPath)
		return fmt.Errorf("replace metadata file: %w", err)
	}
	return nil
}

func (s *sessionStorage) ListSummaries() ([]SessionSummary, error) {
	if err := s.Initialize(); err != nil {
		return nil, err
	}
	matches, err := filepath.Glob(filepath.Join(s.baseDir, "*.meta.json"))
	if err != nil {
		return nil, fmt.Errorf("glob metadata files: %w", err)
	}
	results := make([]SessionSummary, 0, len(matches))
	for _, match := range matches {
		content, err := os.ReadFile(match)
		if err != nil {
			continue
		}
		var summary SessionSummary
		if err := json.Unmarshal(content, &summary); err != nil {
			continue
		}
		results = append(results, summary)
	}
	sort.Slice(results, func(i, j int) bool {
		return results[i].UpdatedAt.After(results[j].UpdatedAt)
	})
	return results, nil
}

func (s *sessionStorage) DeleteSession(id string) error {
	paths := []string{s.sessionPath(id), s.metaPath(id)}
	for _, target := range paths {
		if err := os.Remove(target); err != nil && !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("delete session file %s: %w", target, err)
		}
	}
	return nil
}

type sessionStore struct {
	mu       sync.RWMutex
	sessions map[string]*PersistedSession
	storage  *sessionStorage
}

func newSessionStore(storage *sessionStorage) *sessionStore {
	return &sessionStore{
		sessions: make(map[string]*PersistedSession),
		storage:  storage,
	}
}

func (s *sessionStore) Initialize() error {
	return s.storage.Initialize()
}

func (s *sessionStore) Save(session *PersistedSession) error {
	session.UpdatedAt = nowUTC()
	s.mu.Lock()
	s.sessions[session.ID] = session
	s.mu.Unlock()
	return s.storage.SaveSession(session)
}

func (s *sessionStore) Create(session *PersistedSession) error {
	return s.Save(session)
}

func (s *sessionStore) Get(id string) (*PersistedSession, error) {
	s.mu.RLock()
	if session, ok := s.sessions[id]; ok {
		s.mu.RUnlock()
		return session, nil
	}
	s.mu.RUnlock()

	session, err := s.storage.LoadSession(id)
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	s.sessions[id] = session
	s.mu.Unlock()
	return session, nil
}

func (s *sessionStore) List() ([]SessionSummary, error) {
	summaries, err := s.storage.ListSummaries()
	if err != nil {
		return nil, err
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	for i := range summaries {
		if cached, ok := s.sessions[summaries[i].ID]; ok && cached.UpdatedAt.After(summaries[i].UpdatedAt) {
			summaries[i] = cached.Summary()
		}
	}
	sort.Slice(summaries, func(i, j int) bool {
		return summaries[i].UpdatedAt.After(summaries[j].UpdatedAt)
	})
	return summaries, nil
}

func (s *sessionStore) Delete(id string) error {
	s.mu.Lock()
	delete(s.sessions, id)
	s.mu.Unlock()
	return s.storage.DeleteSession(id)
}
