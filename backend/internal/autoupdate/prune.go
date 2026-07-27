package autoupdate

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	updateWorkPrefix = ".update-work-"
	stagingPrefix    = ".staging-"
	// Leftovers are only removed once they are clearly not in use. An update
	// holds the install lock for its whole run, so anything older than this was
	// abandoned by a crashed or killed process.
	staleTemporaryAge = 24 * time.Hour
)

// PruneVersions removes installed bundles that are neither active nor kept for
// rollback, plus staging and work directories abandoned by interrupted updates.
// Without it every update leaves a full backend and frontend build behind
// forever.
func PruneVersions(installRoot string, keep ...CurrentState) error {
	absoluteRoot, err := filepath.Abs(installRoot)
	if err != nil {
		return fmt.Errorf("resolve install root: %w", err)
	}
	retained := make(map[string]struct{}, len(keep))
	for _, state := range keep {
		if validateCurrentState(state) != nil {
			continue
		}
		retained[filepath.Base(filepath.FromSlash(state.Bundle))] = struct{}{}
	}
	// Refusing to prune without a known-good bundle avoids wiping the only
	// installation when the caller could not read current.json.
	if len(retained) == 0 {
		return nil
	}

	var failures []string
	versionsRoot := filepath.Join(absoluteRoot, "versions")
	entries, err := os.ReadDir(versionsRoot)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("read versions directory: %w", err)
	}
	for _, entry := range entries {
		name := entry.Name()
		if _, hold := retained[name]; hold {
			continue
		}
		if strings.HasPrefix(name, stagingPrefix) && !isStale(entry) {
			continue
		}
		if err := os.RemoveAll(filepath.Join(versionsRoot, name)); err != nil {
			failures = append(failures, fmt.Sprintf("versions/%s: %v", name, err))
		}
	}

	rootEntries, err := os.ReadDir(absoluteRoot)
	if err != nil {
		return fmt.Errorf("read install root: %w", err)
	}
	for _, entry := range rootEntries {
		name := entry.Name()
		if !strings.HasPrefix(name, updateWorkPrefix) || !isStale(entry) {
			continue
		}
		if err := os.RemoveAll(filepath.Join(absoluteRoot, name)); err != nil {
			failures = append(failures, fmt.Sprintf("%s: %v", name, err))
		}
	}

	if len(failures) > 0 {
		return fmt.Errorf("remove obsolete update data: %s", strings.Join(failures, "; "))
	}
	return nil
}

func isStale(entry os.DirEntry) bool {
	info, err := entry.Info()
	if err != nil {
		return false
	}
	return time.Since(info.ModTime()) > staleTemporaryAge
}
