package benchmark

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const snapshotSchema = 3

type snapshotFile struct {
	SchemaVersion int       `json:"schema_version"`
	Board         string    `json:"board"`
	PublishedAt   string    `json:"published_at"`
	FetchedAt     time.Time `json:"fetched_at"`
	Entries       []Entry   `json:"entries"`
}

func snapshotFilePath(dir, boardKey string) string {
	return filepath.Join(strings.TrimSpace(dir), boardKey+".json")
}

func loadSnapshot(path string) (*snapshotFile, error) {
	path = strings.TrimSpace(path)
	if path == "" {
		return nil, nil
	}

	payload, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("Benchmark-Abzug lesen: %w", err)
	}
	if len(strings.TrimSpace(string(payload))) == 0 {
		return nil, nil
	}

	var snapshot snapshotFile
	if err := json.Unmarshal(payload, &snapshot); err != nil {
		return nil, fmt.Errorf("Benchmark-Abzug enthaelt ungueltiges JSON: %w", err)
	}
	if snapshot.SchemaVersion != snapshotSchema {
		return nil, fmt.Errorf("Benchmark-Abzug hat Schema %d, erwartet %d", snapshot.SchemaVersion, snapshotSchema)
	}
	if len(snapshot.Entries) == 0 {
		return nil, nil
	}
	return &snapshot, nil
}

func saveSnapshot(path, boardKey string, entries []Entry, fetchedAt time.Time, publishedAt string) (err error) {
	path = strings.TrimSpace(path)
	if path == "" {
		return errors.New("Benchmark-Abzugspfad ist leer")
	}

	payload, err := json.Marshal(snapshotFile{
		SchemaVersion: snapshotSchema,
		Board:         boardKey,
		PublishedAt:   publishedAt,
		FetchedAt:     fetchedAt,
		Entries:       entries,
	})
	if err != nil {
		return fmt.Errorf("Benchmark-Abzug serialisieren: %w", err)
	}

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

	if err = temporary.Chmod(0o600); err != nil {
		return err
	}
	if _, err = temporary.Write(append(payload, '\n')); err != nil {
		return err
	}
	if err = temporary.Sync(); err != nil {
		return err
	}
	if err = temporary.Close(); err != nil {
		return err
	}
	return os.Rename(temporaryPath, path)
}
