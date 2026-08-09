package skills

import (
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

type Store struct {
	rootDir      string
	registryPath string
	mu           sync.RWMutex
	loaded       bool
	skills       map[string]SkillRecord
}

func NewStore(rootDir string) *Store {
	cleanRoot := strings.TrimSpace(rootDir)
	if cleanRoot == "" {
		cleanRoot = defaultSkillsDir
	}
	return &Store{
		rootDir:      filepath.Clean(cleanRoot),
		registryPath: filepath.Join(filepath.Clean(cleanRoot), registryFileName),
		skills:       map[string]SkillRecord{},
	}
}

func (s *Store) Load() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := os.MkdirAll(s.rootDir, 0o755); err != nil {
		return err
	}

	data, err := os.ReadFile(s.registryPath)
	if errors.Is(err, os.ErrNotExist) {
		s.skills = map[string]SkillRecord{}
		s.loaded = true
		return nil
	}
	if err != nil {
		return err
	}
	if len(strings.TrimSpace(string(data))) == 0 {
		s.skills = map[string]SkillRecord{}
		s.loaded = true
		return nil
	}

	var registry registryFile
	if err := json.Unmarshal(data, &registry); err != nil {
		return err
	}
	next := map[string]SkillRecord{}
	for _, record := range registry.Skills {
		name := strings.TrimSpace(record.Name)
		if name == "" {
			continue
		}
		next[name] = record
	}
	s.skills = next
	s.loaded = true
	return nil
}

func (s *Store) List() []SkillRecord {
	s.mu.RLock()
	defer s.mu.RUnlock()

	records := make([]SkillRecord, 0, len(s.skills))
	for _, record := range s.skills {
		records = append(records, record)
	}
	sort.Slice(records, func(i, j int) bool {
		return records[i].Name < records[j].Name
	})
	return records
}

func (s *Store) Import(sourcePath string, enabled bool) (SkillRecord, error) {
	result, err := validateSkillDir(sourcePath)
	if err != nil {
		return SkillRecord{}, err
	}

	name := strings.TrimSpace(result.Frontmatter.Name)
	destination := filepath.Join(s.rootDir, name)
	now := time.Now().UTC()

	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.ensureLoadedLocked(); err != nil {
		return SkillRecord{}, err
	}
	if _, exists := s.skills[name]; exists {
		return SkillRecord{}, fmt.Errorf("Skill %q ist bereits eingebunden", name)
	}
	if _, err := os.Stat(destination); err == nil {
		return SkillRecord{}, fmt.Errorf("Skill-Ordner %q existiert bereits", name)
	} else if !errors.Is(err, os.ErrNotExist) {
		return SkillRecord{}, err
	}

	tmpDir := destination + ".tmp-" + fmt.Sprintf("%d", now.UnixNano())
	if err := copyDir(filepath.Clean(sourcePath), tmpDir); err != nil {
		_ = os.RemoveAll(tmpDir)
		return SkillRecord{}, err
	}
	if err := os.Rename(tmpDir, destination); err != nil {
		_ = os.RemoveAll(tmpDir)
		return SkillRecord{}, err
	}

	record := recordFromValidation(result, destination, enabled, now, now, true, nil)
	s.skills[name] = record
	if err := s.writeLocked(); err != nil {
		return SkillRecord{}, err
	}
	return record, nil
}

func (s *Store) SetEnabled(name string, enabled bool) (SkillRecord, error) {
	name = strings.TrimSpace(name)
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.ensureLoadedLocked(); err != nil {
		return SkillRecord{}, err
	}
	record, exists := s.skills[name]
	if !exists {
		return SkillRecord{}, os.ErrNotExist
	}
	record.Enabled = enabled
	record.UpdatedAt = time.Now().UTC()
	s.skills[name] = record
	if err := s.writeLocked(); err != nil {
		return SkillRecord{}, err
	}
	return record, nil
}

func (s *Store) Delete(name string) error {
	name = strings.TrimSpace(name)
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.ensureLoadedLocked(); err != nil {
		return err
	}
	record, exists := s.skills[name]
	if !exists {
		return os.ErrNotExist
	}
	if err := os.RemoveAll(record.Path); err != nil {
		return err
	}
	delete(s.skills, name)
	return s.writeLocked()
}

func (s *Store) Rescan() ([]SkillRecord, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.ensureLoadedLocked(); err != nil {
		return nil, err
	}
	if err := os.MkdirAll(s.rootDir, 0o755); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	next := map[string]SkillRecord{}
	entries, err := os.ReadDir(s.rootDir)
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		path := filepath.Join(s.rootDir, entry.Name())
		result, err := validateSkillDir(path)
		name := entry.Name()
		if err == nil {
			name = strings.TrimSpace(result.Frontmatter.Name)
		}
		previous, hadPrevious := s.skills[name]
		enabled := false
		importedAt := now
		if hadPrevious {
			enabled = previous.Enabled
			importedAt = previous.ImportedAt
		}
		if err != nil {
			record := SkillRecord{
				Name:       name,
				Enabled:    enabled,
				Path:       path,
				ImportedAt: importedAt,
				UpdatedAt:  now,
				Valid:      false,
				Errors:     []string{err.Error()},
			}
			if hadPrevious {
				record.Description = previous.Description
				record.License = previous.License
				record.Compatibility = previous.Compatibility
				record.Metadata = previous.Metadata
				record.AllowedTools = previous.AllowedTools
			}
			if summary, summaryErr := summarizeFiles(path); summaryErr == nil {
				record.FileSummary = summary
			}
			next[name] = record
			continue
		}
		next[name] = recordFromValidation(result, path, enabled, importedAt, now, true, nil)
	}
	s.skills = next
	if err := s.writeLocked(); err != nil {
		return nil, err
	}
	return s.listLocked(), nil
}

func (s *Store) ensureLoadedLocked() error {
	if s.loaded {
		return nil
	}
	if err := os.MkdirAll(s.rootDir, 0o755); err != nil {
		return err
	}
	s.skills = map[string]SkillRecord{}
	s.loaded = true
	return nil
}

func (s *Store) writeLocked() error {
	if err := os.MkdirAll(s.rootDir, 0o755); err != nil {
		return err
	}
	payload, err := json.MarshalIndent(registryFile{Skills: s.listLocked()}, "", "  ")
	if err != nil {
		return err
	}
	payload = append(payload, '\n')
	return os.WriteFile(s.registryPath, payload, 0o600)
}

func (s *Store) listLocked() []SkillRecord {
	records := make([]SkillRecord, 0, len(s.skills))
	for _, record := range s.skills {
		records = append(records, record)
	}
	sort.Slice(records, func(i, j int) bool {
		return records[i].Name < records[j].Name
	})
	return records
}

func recordFromValidation(result validationResult, path string, enabled bool, importedAt, updatedAt time.Time, valid bool, problems []string) SkillRecord {
	frontmatter := result.Frontmatter
	return SkillRecord{
		Name:          strings.TrimSpace(frontmatter.Name),
		Description:   strings.TrimSpace(frontmatter.Description),
		Enabled:       enabled,
		Path:          filepath.Clean(path),
		ImportedAt:    importedAt,
		UpdatedAt:     updatedAt,
		License:       strings.TrimSpace(frontmatter.License),
		Compatibility: strings.TrimSpace(frontmatter.Compatibility),
		Metadata:      frontmatter.Metadata,
		AllowedTools:  strings.TrimSpace(frontmatter.AllowedTools),
		Valid:         valid,
		Errors:        problems,
		FileSummary:   result.Summary,
	}
}

func copyDir(source, destination string) error {
	sourceInfo, err := os.Stat(source)
	if err != nil {
		return err
	}
	if !sourceInfo.IsDir() {
		return errors.New("Quelle muss ein Ordner sein")
	}
	if err := os.MkdirAll(destination, sourceInfo.Mode()); err != nil {
		return err
	}

	return filepath.WalkDir(source, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if path == source {
			return nil
		}
		rel, err := filepath.Rel(source, path)
		if err != nil {
			return err
		}
		target := filepath.Join(destination, rel)
		info, err := entry.Info()
		if err != nil {
			return err
		}
		if entry.IsDir() {
			return os.MkdirAll(target, info.Mode())
		}
		if entry.Type()&os.ModeSymlink != 0 {
			return errors.New("Symlinks in Skill-Ordnern werden nicht importiert")
		}
		return copyFile(path, target, info.Mode())
	})
}

func copyFile(source, destination string, mode os.FileMode) error {
	in, err := os.Open(source)
	if err != nil {
		return err
	}
	defer in.Close()
	if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
		return err
	}
	out, err := os.OpenFile(destination, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	defer out.Close()
	if _, err := io.Copy(out, in); err != nil {
		return err
	}
	return out.Close()
}
