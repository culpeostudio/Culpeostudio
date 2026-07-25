package marktplatz

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/fillyengine/backend/modules/marktplatz/common"
)

const completionManifestName = ".philoengine-complete.json"

type bundleManifest struct {
	SchemaVersion int                  `json:"schema_version"`
	Provider      string               `json:"provider"`
	Repository    string               `json:"repository"`
	Revision      string               `json:"revision"`
	CommitSHA     string               `json:"commit_sha,omitempty"`
	Format        string               `json:"format"`
	CreatedAt     time.Time            `json:"created_at"`
	Files         []bundleManifestFile `json:"files"`
}

type bundleManifestFile struct {
	Path   string `json:"path"`
	Size   int64  `json:"size_bytes"`
	SHA256 string `json:"sha256"`
}

func prepareBundlePaths(baseDir, provider, repository, revision, jobID string) (staging string, final string, err error) {
	parts := []string{baseDir, safeBundleComponent(provider)}
	for _, part := range strings.Split(strings.ReplaceAll(repository, "\\", "/"), "/") {
		part = safeBundleComponent(part)
		if part == "" {
			return "", "", fmt.Errorf("ungueltige Repository-ID")
		}
		parts = append(parts, part)
	}
	parts = append(parts, safeBundleComponent(revision))
	final = filepath.Join(parts...)
	baseAbs, absErr := filepath.Abs(baseDir)
	if absErr != nil {
		return "", "", absErr
	}
	finalAbs, absErr := filepath.Abs(final)
	if absErr != nil || !isWithinDir(finalAbs, baseAbs) {
		return "", "", fmt.Errorf("Bundle-Ziel ausserhalb des Modellordners")
	}
	staging = final + ".staging-" + safeBundleComponent(jobID)
	if err := os.RemoveAll(staging); err != nil {
		return "", "", err
	}
	if err := os.MkdirAll(staging, 0o755); err != nil {
		return "", "", err
	}
	return staging, final, nil
}

func safeBundleComponent(value string) string {
	clean := common.SafeFileName(strings.TrimSpace(value))
	clean = strings.Trim(clean, ". ")
	if clean == "" || clean == "." || clean == ".." {
		return "unknown"
	}
	return clean
}

func validateAndPublishBundle(staging, final string, manifest bundleManifest, assets []string) (string, error) {
	if err := validateBundleFiles(staging, manifest.Format, assets); err != nil {
		return "", err
	}
	files, err := hashBundleFiles(staging)
	if err != nil {
		return "", err
	}
	manifest.SchemaVersion = 1
	manifest.CreatedAt = time.Now().UTC()
	manifest.Files = files
	payload, err := json.MarshalIndent(manifest, "", "  ")
	if err != nil {
		return "", err
	}
	payload = append(payload, '\n')
	tmpManifest := filepath.Join(staging, completionManifestName+".tmp")
	if err := os.WriteFile(tmpManifest, payload, 0o644); err != nil {
		return "", err
	}
	if err := os.Rename(tmpManifest, filepath.Join(staging, completionManifestName)); err != nil {
		return "", err
	}
	if err := os.MkdirAll(filepath.Dir(final), 0o755); err != nil {
		return "", err
	}
	backup := final + ".previous"
	_ = os.RemoveAll(backup)
	if _, err := os.Stat(final); err == nil {
		if err := os.Rename(final, backup); err != nil {
			return "", err
		}
	}
	if err := os.Rename(staging, final); err != nil {
		if _, backupErr := os.Stat(backup); backupErr == nil {
			_ = os.Rename(backup, final)
		}
		return "", err
	}
	_ = os.RemoveAll(backup)
	return filepath.Join(final, completionManifestName), nil
}

func validateBundleFiles(root, format string, assets []string) error {
	if len(assets) == 0 {
		return fmt.Errorf("Bundle enthaelt keine Assets")
	}
	for _, asset := range assets {
		relative, ok := common.SafeRelativePath(asset)
		if !ok {
			return fmt.Errorf("unsicherer Asset-Pfad %q", asset)
		}
		info, err := os.Lstat(filepath.Join(root, relative))
		if err != nil || !info.Mode().IsRegular() {
			return fmt.Errorf("Download unvollstaendig: %s fehlt", asset)
		}
	}
	switch strings.ToLower(strings.TrimSpace(format)) {
	case "safetensors":
		if !regularFile(filepath.Join(root, "config.json")) {
			return fmt.Errorf("SafeTensors-Bundle unvollstaendig: config.json fehlt")
		}
		if !hasTokenizerAsset(root) {
			return fmt.Errorf("SafeTensors-Bundle unvollstaendig: Tokenizer fehlt")
		}
		if err := validateSafeTensorIndex(root); err != nil {
			return err
		}
	case "gguf":
		if err := validateGGUFSplits(assets); err != nil {
			return err
		}
	default:
		return fmt.Errorf("nicht startbares Bundle-Format %q", format)
	}
	return nil
}

func regularFile(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular()
}

func hasTokenizerAsset(root string) bool {
	found := false
	_ = filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil || entry.IsDir() {
			return nil
		}
		base := strings.ToLower(entry.Name())
		if base == "tokenizer.json" || base == "tokenizer.model" || base == "sentencepiece.bpe.model" || base == "spiece.model" || base == "vocab.json" || base == "vocab.txt" {
			found = true
		}
		return nil
	})
	return found
}

func validateSafeTensorIndex(root string) error {
	indexPath := filepath.Join(root, "model.safetensors.index.json")
	data, err := os.ReadFile(indexPath)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return err
	}
	var index struct {
		WeightMap map[string]string `json:"weight_map"`
	}
	if err := json.Unmarshal(data, &index); err != nil {
		return fmt.Errorf("SafeTensors-Index ungueltig: %w", err)
	}
	if len(index.WeightMap) == 0 {
		return fmt.Errorf("SafeTensors-Index unvollstaendig: weight_map enthaelt keine Gewichte")
	}
	for _, shard := range index.WeightMap {
		relative, ok := common.SafeRelativePath(shard)
		if !ok || !regularFile(filepath.Join(root, relative)) {
			return fmt.Errorf("SafeTensors-Bundle unvollstaendig: Index-Shard %s fehlt", shard)
		}
	}
	return nil
}

var downloadedSplitPattern = regexp.MustCompile(`(?i)^(.*)-(\d+)-of-(\d+)\.gguf$`)

func validateGGUFSplits(assets []string) error {
	groups := map[string]map[int]bool{}
	totals := map[string]int{}
	for _, asset := range assets {
		match := downloadedSplitPattern.FindStringSubmatch(filepath.Base(asset))
		if len(match) != 4 {
			continue
		}
		var index, total int
		_, _ = fmt.Sscanf(match[2], "%d", &index)
		_, _ = fmt.Sscanf(match[3], "%d", &total)
		key := strings.ToLower(match[1])
		if index < 1 || total < 1 || index > total {
			return fmt.Errorf("GGUF-Split hat ungueltige Teilnummer %d von %d", index, total)
		}
		if previous, exists := totals[key]; exists && previous != total {
			return fmt.Errorf("GGUF-Split hat widerspruechliche Gesamtzahlen %d und %d", previous, total)
		}
		if groups[key] == nil {
			groups[key] = map[int]bool{}
		}
		groups[key][index] = true
		totals[key] = total
	}
	for key, present := range groups {
		for index := 1; index <= totals[key]; index++ {
			if !present[index] {
				return fmt.Errorf("GGUF-Split unvollstaendig: Teil %d von %d fehlt", index, totals[key])
			}
		}
	}
	return nil
}

func hashBundleFiles(root string) ([]bundleManifestFile, error) {
	files := []bundleManifestFile{}
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			return nil
		}
		if entry.Type()&os.ModeSymlink != 0 || strings.HasSuffix(entry.Name(), ".part") || strings.HasSuffix(entry.Name(), ".tmp") {
			return fmt.Errorf("unvollstaendige oder unsichere Datei im Bundle: %s", entry.Name())
		}
		file, err := os.Open(path)
		if err != nil {
			return err
		}
		hash := sha256.New()
		_, copyErr := io.Copy(hash, file)
		closeErr := file.Close()
		if copyErr != nil {
			return copyErr
		}
		if closeErr != nil {
			return closeErr
		}
		info, err := entry.Info()
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		files = append(files, bundleManifestFile{Path: filepath.ToSlash(relative), Size: info.Size(), SHA256: hex.EncodeToString(hash.Sum(nil))})
		return nil
	})
	sort.Slice(files, func(i, j int) bool { return files[i].Path < files[j].Path })
	return files, err
}
