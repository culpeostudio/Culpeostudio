package engine

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/fillyengine/backend/internal/modelcatalog"
	"github.com/fillyengine/backend/internal/modelstorage"
)

const marketplaceBundleManifest = ".philoengine-complete.json"

type stagedModelPath struct {
	original string
	staged   string
}

func (m *EngineModule) deleteModel(ctx context.Context, id string) ([]modelcatalog.ModelRecord, error) {
	release, err := m.acquireLifecycle(ctx, false)
	if err != nil {
		return nil, err
	}
	defer release()

	m.mu.RLock()
	root := m.modelDir
	m.mu.RUnlock()
	releaseModelDirectory := modelstorage.Acquire(root)
	defer releaseModelDirectory()

	m.mu.RLock()
	record, exists := m.modelsByID[id]
	knownModels := append([]modelcatalog.ModelRecord(nil), m.models...)
	for _, instance := range m.instances {
		if instance.ModelID == id {
			m.mu.RUnlock()
			return nil, fmt.Errorf("Modell wird noch von der Instanz %q verwendet. Entferne zuerst die Modellinstanz", instance.ID)
		}
	}
	m.mu.RUnlock()
	if !exists {
		return nil, os.ErrNotExist
	}
	if len(record.Files) == 0 {
		if record.Format != modelcatalog.FormatSafeTensors || strings.TrimSpace(record.RelativePath) == "" {
			return nil, fmt.Errorf("Modell %q hat keine katalogisierten Dateien zum Löschen", record.Name)
		}
	}

	root, err = filepath.Abs(filepath.Clean(root))
	if err != nil {
		return nil, err
	}
	root, err = filepath.EvalSymlinks(root)
	if err != nil {
		return nil, err
	}
	if !modelcatalog.VerifyFingerprint(root, record) {
		_, _ = m.rescan(context.Background())
		return nil, fmt.Errorf("Modell %q wurde seit dem letzten Scan geändert. Die Liste wurde aktualisiert; bitte die Löschung erneut bestätigen", record.Name)
	}
	expectedRoot, err := os.Stat(root)
	if err != nil {
		return nil, err
	}
	rootFS, err := os.OpenRoot(root)
	if err != nil {
		return nil, err
	}
	defer rootFS.Close()
	openedRoot, err := rootFS.Stat(".")
	if err != nil {
		return nil, err
	}
	if !os.SameFile(expectedRoot, openedRoot) {
		return nil, fmt.Errorf("model_dir wurde während der Löschvorbereitung ausgetauscht")
	}
	if err := cleanupStagedModelDeletionsRoot(rootFS); err != nil {
		return nil, fmt.Errorf("eine frühere Modelllöschung konnte noch nicht bereinigt werden: %w", err)
	}

	targets, bundle, err := modelDeletionTargets(rootFS, record, knownModels)
	if err != nil {
		return nil, err
	}
	nonce, err := randomHex(12)
	if err != nil {
		return nil, err
	}
	stagingDir := ".philoengine-delete-" + nonce + ".tmp"
	if err := rootFS.Mkdir(stagingDir, 0o700); err != nil {
		return nil, err
	}
	staged, err := stageModelPaths(rootFS, stagingDir, targets, bundle)
	if err != nil {
		rollbackErr := rollbackStagedModelPaths(rootFS, stagingDir, staged)
		return nil, errors.Join(err, rollbackErr)
	}

	rescanContext := context.Background()
	if ctx != nil {
		rescanContext = context.WithoutCancel(ctx)
	}
	records, err := m.rescan(rescanContext)
	if err == nil && catalogContainsModel(records, id) {
		err = fmt.Errorf("Modell %q wurde nach der Löschung weiterhin im Modellordner gefunden", record.Name)
	}
	if err != nil {
		rollbackErr := rollbackStagedModelPaths(rootFS, stagingDir, staged)
		if rollbackErr == nil {
			_, _ = m.rescan(context.Background())
		}
		return nil, errors.Join(err, rollbackErr)
	}
	if err := rootFS.RemoveAll(stagingDir); err != nil {
		return nil, fmt.Errorf("Modell wurde aus dem Katalog entfernt, aber der vorgemerkte Löschordner konnte nicht vollständig bereinigt werden: %w", err)
	}
	pruneEmptyModelParents(rootFS, staged)
	m.events.publish("model_deleted", map[string]string{"id": id, "name": record.Name})
	return records, nil
}

func modelDeletionTargets(rootFS *os.Root, record modelcatalog.ModelRecord, knownModels []modelcatalog.ModelRecord) ([]string, bool, error) {
	bundleDirectory := ""
	switch record.Format {
	case modelcatalog.FormatSafeTensors:
		relativePath := strings.TrimSpace(record.RelativePath)
		if relativePath != "" && relativePath != "." {
			clean, cleanErr := cleanModelRelativePath(relativePath)
			if cleanErr != nil {
				return nil, false, cleanErr
			}
			bundleDirectory = clean
		}
	case modelcatalog.FormatGGUF:
		if len(record.Files) > 0 {
			first, cleanErr := cleanModelRelativePath(record.Files[0])
			if cleanErr != nil {
				return nil, false, cleanErr
			}
			candidate := filepath.Dir(first)
			if candidate != "." {
				manifest, statErr := rootFS.Lstat(filepath.Join(candidate, marketplaceBundleManifest))
				if statErr == nil && manifest.Mode().IsRegular() {
					bundleDirectory = candidate
				}
			}
		}
	}
	if bundleDirectory != "" && bundleDirectory != "." && modelBundleIsExclusive(bundleDirectory, record.ID, knownModels) {
		return []string{bundleDirectory}, true, nil
	}

	targets := make([]string, 0, len(record.Files))
	seen := make(map[string]struct{}, len(record.Files))
	for _, relativeFile := range record.Files {
		clean, cleanErr := cleanModelRelativePath(relativeFile)
		if cleanErr != nil {
			return nil, false, cleanErr
		}
		if _, duplicate := seen[clean]; duplicate {
			continue
		}
		seen[clean] = struct{}{}
		targets = append(targets, clean)
	}
	return targets, false, nil
}

func cleanModelRelativePath(value string) (string, error) {
	clean := filepath.Clean(filepath.FromSlash(strings.TrimSpace(value)))
	if clean == "" || clean == "." || filepath.IsAbs(clean) || clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("Modelldateipfad %q verlaesst model_dir", value)
	}
	return clean, nil
}

func modelBundleIsExclusive(directory, selectedID string, knownModels []modelcatalog.ModelRecord) bool {
	for _, other := range knownModels {
		if other.ID == selectedID {
			continue
		}
		paths := append([]string(nil), other.Files...)
		if strings.TrimSpace(other.RelativePath) != "" && other.RelativePath != "." {
			paths = append(paths, other.RelativePath)
		}
		for _, candidate := range paths {
			clean, err := cleanModelRelativePath(candidate)
			if err == nil && relativePathInside(directory, clean) {
				return false
			}
		}
	}
	return true
}

func relativePathInside(directory, candidate string) bool {
	relative, err := filepath.Rel(filepath.Clean(directory), filepath.Clean(candidate))
	return err == nil && relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator))
}

func stageModelPaths(rootFS *os.Root, stagingDir string, targets []string, bundle bool) ([]stagedModelPath, error) {
	staged := make([]stagedModelPath, 0, len(targets))
	for index, target := range targets {
		info, err := rootFS.Lstat(target)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return staged, err
		}
		if info.Mode()&os.ModeSymlink != 0 {
			return staged, fmt.Errorf("Modelldateipfad %q ist ein symbolischer Link", target)
		}
		if bundle {
			if !info.IsDir() {
				return staged, fmt.Errorf("Modellpaket %q ist kein Ordner", target)
			}
		} else if !info.Mode().IsRegular() {
			return staged, fmt.Errorf("katalogisierte Modelldatei %q ist keine regulaere Datei", target)
		}
		stagedPath := filepath.Join(stagingDir, fmt.Sprintf("%06d", index))
		if err := rootFS.Rename(target, stagedPath); err != nil {
			return staged, err
		}
		entry := stagedModelPath{original: target, staged: stagedPath}
		staged = append(staged, entry)
		stagedInfo, err := rootFS.Lstat(stagedPath)
		if err != nil {
			return staged, err
		}
		if !os.SameFile(info, stagedInfo) {
			return staged, fmt.Errorf("Modellpfad %q wurde parallel ausgetauscht; Löschung abgebrochen", target)
		}
	}
	return staged, nil
}

func rollbackStagedModelPaths(rootFS *os.Root, stagingDir string, staged []stagedModelPath) error {
	var rollbackErr error
	for index := len(staged) - 1; index >= 0; index-- {
		if err := rootFS.Rename(staged[index].staged, staged[index].original); err != nil {
			rollbackErr = errors.Join(rollbackErr, err)
		}
	}
	if err := rootFS.RemoveAll(stagingDir); err != nil {
		rollbackErr = errors.Join(rollbackErr, err)
	}
	return rollbackErr
}

func catalogContainsModel(records []modelcatalog.ModelRecord, id string) bool {
	for _, record := range records {
		if record.ID == id {
			return true
		}
	}
	return false
}

func pruneEmptyModelParents(rootFS *os.Root, staged []stagedModelPath) {
	for _, entry := range staged {
		for directory := filepath.Dir(entry.original); directory != "."; directory = filepath.Dir(directory) {
			info, err := rootFS.Lstat(directory)
			if err != nil || !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
				break
			}
			if err := rootFS.Remove(directory); err != nil {
				break
			}
		}
	}
}

func cleanupStagedModelDeletions(root string) error {
	rootFS, err := os.OpenRoot(root)
	if err != nil {
		return err
	}
	defer rootFS.Close()
	return cleanupStagedModelDeletionsRoot(rootFS)
}

func cleanupStagedModelDeletionsRoot(rootFS *os.Root) error {
	directory, err := rootFS.Open(".")
	if err != nil {
		return err
	}
	entries, readErr := directory.ReadDir(-1)
	closeErr := directory.Close()
	if readErr != nil {
		return readErr
	}
	if closeErr != nil {
		return closeErr
	}
	for _, entry := range entries {
		name := entry.Name()
		if !entry.IsDir() || !strings.HasPrefix(name, ".philoengine-delete-") || !strings.HasSuffix(name, ".tmp") {
			continue
		}
		if err := rootFS.RemoveAll(name); err != nil {
			return err
		}
	}
	return nil
}
