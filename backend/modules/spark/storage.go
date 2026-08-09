package spark

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// projectStore keeps one JSON file per project below baseDir.
type projectStore struct {
	baseDir string
}

func newProjectStore(baseDir string) *projectStore {
	return &projectStore{baseDir: strings.TrimSpace(baseDir)}
}

func (s *projectStore) enabled() bool { return s != nil && s.baseDir != "" }

func (s *projectStore) dir() string {
	if s == nil {
		return ""
	}
	return s.baseDir
}

func (s *projectStore) Initialize() error {
	if !s.enabled() {
		return nil
	}
	return os.MkdirAll(s.baseDir, 0o755)
}

func (s *projectStore) projectPath(id string) string {
	return filepath.Join(s.baseDir, id+".json")
}

func (s *projectStore) Write(id string, payload []byte) error {
	if !s.enabled() {
		return nil
	}
	id = strings.TrimSpace(id)
	if id == "" {
		return errors.New("spark: project id required")
	}
	if err := s.Initialize(); err != nil {
		return err
	}
	tmp := s.projectPath(id) + ".tmp"
	if err := os.WriteFile(tmp, payload, 0o644); err != nil {
		return fmt.Errorf("write spark project: %w", err)
	}
	if err := os.Rename(tmp, s.projectPath(id)); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("replace spark project: %w", err)
	}
	return nil
}

func (s *projectStore) LoadAll() ([]*Project, error) {
	if !s.enabled() {
		return nil, nil
	}
	if err := s.Initialize(); err != nil {
		return nil, err
	}
	matches, err := filepath.Glob(filepath.Join(s.baseDir, "*.json"))
	if err != nil {
		return nil, fmt.Errorf("glob spark projects: %w", err)
	}
	projects := make([]*Project, 0, len(matches))
	for _, match := range matches {
		content, readErr := os.ReadFile(match)
		if readErr != nil {
			log.Printf("[spark] Projekt-Datei %s nicht lesbar: %v", match, readErr)
			continue
		}
		var project Project
		if err := json.Unmarshal(content, &project); err != nil {
			log.Printf("[spark] Projekt-Datei %s nicht dekodierbar: %v", match, err)
			continue
		}
		if strings.TrimSpace(project.ID) == "" {
			continue
		}
		projects = append(projects, &project)
	}
	return projects, nil
}

func (s *projectStore) Delete(id string) error {
	if !s.enabled() {
		return nil
	}
	if err := os.Remove(s.projectPath(strings.TrimSpace(id))); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("delete spark project: %w", err)
	}
	return nil
}
