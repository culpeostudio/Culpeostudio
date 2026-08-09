package modelcatalog

import (
	"context"
	"crypto/sha256"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

var ggufSplitPattern = regexp.MustCompile(`(?i)^(.*)-(\d+)-of-(\d+)\.gguf$`)

type discoveredFile struct {
	abs string
	rel string
}

type ggufGroup struct {
	logicalRel string
	name       string
	total      int
	width      int
	totalText  string
	dir        string
	shards     map[int]discoveredFile
	issues     []ValidationIssue
}

func (s *Scanner) Scan(ctx context.Context) ([]ModelRecord, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	root, err := canonicalRoot(s.root)
	if err != nil {
		return nil, err
	}

	var ggufFiles []discoveredFile
	err = filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if err := ctx.Err(); err != nil {
			return err
		}
		if path == root {
			return nil
		}
		if entry.IsDir() {
			name := strings.ToLower(entry.Name())
			if transientModelDirectory(name) {
				return filepath.SkipDir
			}
		}
		if entry.Type()&os.ModeSymlink != 0 {
			target, evalErr := filepath.EvalSymlinks(path)
			if evalErr != nil || !withinRoot(root, target) {
				if entry.IsDir() {
					return filepath.SkipDir
				}
				return nil
			}

			return nil
		}
		if entry.IsDir() {
			return nil
		}
		if !entry.Type().IsRegular() {
			return nil
		}
		name := strings.ToLower(entry.Name())
		if transientOrProjection(name) {
			return nil
		}
		rel, relErr := filepath.Rel(root, path)
		if relErr != nil {
			return relErr
		}
		// GGUF is the only format the llama.cpp engine can load.
		if strings.HasSuffix(name, ".gguf") {
			ggufFiles = append(ggufFiles, discoveredFile{abs: path, rel: filepath.ToSlash(rel)})
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("scan model directory: %w", err)
	}

	records := scanGGUFFiles(root, ggufFiles)
	sort.Slice(records, func(i, j int) bool { return records[i].RelativePath < records[j].RelativePath })
	return records, nil
}

func transientModelDirectory(lowerName string) bool {
	if strings.Contains(lowerName, ".staging-") || strings.HasSuffix(lowerName, ".previous") {
		return true
	}
	return strings.HasSuffix(lowerName, ".part") || strings.HasSuffix(lowerName, ".partial") || strings.HasSuffix(lowerName, ".tmp")
}

func canonicalRoot(root string) (string, error) {
	if strings.TrimSpace(root) == "" {
		return "", fmt.Errorf("model directory is empty")
	}
	abs, err := filepath.Abs(root)
	if err != nil {
		return "", fmt.Errorf("resolve model directory: %w", err)
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return "", fmt.Errorf("resolve model directory symlinks: %w", err)
	}
	info, err := os.Stat(resolved)
	if err != nil {
		return "", fmt.Errorf("stat model directory: %w", err)
	}
	if !info.IsDir() {
		return "", fmt.Errorf("model directory is not a directory: %s", root)
	}
	return filepath.Clean(resolved), nil
}

func withinRoot(root, candidate string) bool {
	rel, err := filepath.Rel(filepath.Clean(root), filepath.Clean(candidate))
	if err != nil {
		return false
	}
	return rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) && !filepath.IsAbs(rel)
}

func transientOrProjection(lowerName string) bool {
	if strings.Contains(lowerName, "mmproj") {
		return true
	}
	for _, marker := range []string{".part", ".partial", ".tmp"} {
		if strings.HasSuffix(lowerName, marker) || strings.Contains(lowerName, marker+".") {
			return true
		}
	}
	return false
}

func scanGGUFFiles(root string, files []discoveredFile) []ModelRecord {
	groups := make(map[string]*ggufGroup)
	for _, file := range files {
		base := filepath.Base(file.abs)
		matches := ggufSplitPattern.FindStringSubmatch(base)
		if len(matches) != 4 {
			key := "single:" + file.rel
			groups[key] = &ggufGroup{
				logicalRel: file.rel,
				name:       strings.TrimSuffix(base, filepath.Ext(base)),
				total:      1,
				shards:     map[int]discoveredFile{1: file},
			}
			continue
		}
		index, indexErr := strconv.Atoi(matches[2])
		total, totalErr := strconv.Atoi(matches[3])
		if indexErr != nil || totalErr != nil || index < 1 || total < 1 || index > total || total > 100000 {
			key := "single:" + file.rel
			groups[key] = &ggufGroup{
				logicalRel: file.rel,
				name:       strings.TrimSuffix(base, filepath.Ext(base)),
				total:      1,
				shards:     map[int]discoveredFile{1: file},
				issues: []ValidationIssue{{
					Code:        "invalid_gguf_split",
					Severity:    SeverityError,
					Message:     fmt.Sprintf("GGUF split name %q has an invalid shard index or total.", base),
					Remediation: "Re-download the complete split with unchanged provider filenames.",
				}},
			}
			continue
		}
		dirRel := filepath.ToSlash(filepath.Dir(file.rel))
		if dirRel == "." {
			dirRel = ""
		}
		key := strings.ToLower(dirRel + "/" + matches[1] + "|" + matches[3])
		group := groups[key]
		if group == nil {
			first := fmt.Sprintf("%s-%0*d-of-%s.gguf", matches[1], len(matches[2]), 1, matches[3])
			logicalRel := first
			if dirRel != "" {
				logicalRel = dirRel + "/" + first
			}
			group = &ggufGroup{
				logicalRel: logicalRel,
				name:       matches[1],
				total:      total,
				width:      len(matches[2]),
				totalText:  matches[3],
				dir:        dirRel,
				shards:     make(map[int]discoveredFile),
			}
			groups[key] = group
		}
		if existing, duplicate := group.shards[index]; duplicate {
			group.issues = append(group.issues, ValidationIssue{
				Code:        "duplicate_gguf_shard",
				Severity:    SeverityError,
				Message:     fmt.Sprintf("GGUF split contains duplicate shard %d: %s and %s.", index, existing.rel, file.rel),
				Remediation: "Keep exactly one provider shard for every split index.",
			})
			continue
		}
		group.shards[index] = file
	}

	keys := make([]string, 0, len(groups))
	for key := range groups {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	records := make([]ModelRecord, 0, len(keys))
	for _, key := range keys {
		group := groups[key]
		record := ModelRecord{
			ID:                stableID(FormatGGUF, group.logicalRel),
			Name:              group.name,
			RelativePath:      group.logicalRel,
			Format:            FormatGGUF,
			RuntimeCandidates: []string{"llama_cpp"},
			Issues:            append([]ValidationIssue(nil), group.issues...),
		}
		var fingerprintFiles []string
		var tensorParameters int64
		// A split model carries its experts across shards, so both figures are
		// summed rather than taken from whichever shard was read last.
		var expertBytes int64
		expertLayers := map[int]bool{}
		for shard := 1; shard <= group.total; shard++ {
			file, exists := group.shards[shard]
			if !exists {
				record.Issues = append(record.Issues, ValidationIssue{
					Code:        "missing_gguf_shard",
					Severity:    SeverityError,
					Message:     fmt.Sprintf("GGUF split is missing shard %d of %d", shard, group.total),
					Remediation: "Download the complete split group into the same directory.",
				})
				continue
			}
			record.Files = append(record.Files, file.rel)
			fingerprintFiles = append(fingerprintFiles, file.rel)
			if info, err := os.Stat(file.abs); err == nil {
				record.SizeBytes += info.Size()
			}
			parsed, err := parseGGUF(file.abs)
			if err != nil {
				record.Issues = append(record.Issues, ValidationIssue{
					Code:        "invalid_gguf",
					Severity:    SeverityError,
					Message:     fmt.Sprintf("%s is not a readable GGUF file: %v", file.rel, err),
					Remediation: "Re-download this GGUF shard.",
				})
				continue
			}
			mergeMetadata(&record.Metadata, parsed.Metadata)
			if parsed.tensorParameters > 0 {
				tensorParameters = saturatingAdd(tensorParameters, parsed.tensorParameters)
			}
			if parsed.expertBytes > 0 {
				expertBytes = saturatingAdd(expertBytes, parsed.expertBytes)
				// Shards split a model by tensor, not by layer, so the layer
				// counts cannot simply be added. The largest is the right answer
				// for the common case where one shard holds every expert block,
				// and it never overstates how many layers can be offloaded.
				for layer := 0; layer < parsed.expertLayers; layer++ {
					expertLayers[layer] = true
				}
			}
		}
		record.Metadata.ExpertWeightBytes = expertBytes
		record.Metadata.ExpertLayers = len(expertLayers)
		if tensorParameters > 0 {
			record.Metadata.ParameterCount = tensorParameters
		}
		if record.Metadata.HeadDimension == 0 && record.Metadata.EmbeddingDimension > 0 && record.Metadata.AttentionHeads > 0 {
			record.Metadata.HeadDimension = record.Metadata.EmbeddingDimension / record.Metadata.AttentionHeads
		}
		if record.Metadata.Name != "" {
			record.Name = record.Metadata.Name
		}
		if record.Metadata.Quantization == "" {
			record.Metadata.Quantization = inferQuantizationFromName(group.name)
		}
		sort.Strings(record.Files)
		record.Fingerprint = sampledFingerprint(root, fingerprintFiles)
		record.Complete = !hasBlockingIssue(record.Issues)
		record.Startable = record.Complete
		records = append(records, record)
	}
	return records
}

func stableID(format Format, logicalPath string) string {
	sum := sha256.Sum256([]byte(string(format) + "\x00" + filepath.ToSlash(filepath.Clean(logicalPath))))
	return fmt.Sprintf("mdl_%x", sum[:12])
}

func hasBlockingIssue(issues []ValidationIssue) bool {
	for _, issue := range issues {
		if issue.Severity == SeverityError {
			return true
		}
	}
	return false
}

func mergeMetadata(dst *Metadata, src Metadata) {
	if dst.Name == "" {
		dst.Name = src.Name
	}
	if dst.Architecture == "" {
		dst.Architecture = src.Architecture
	}
	if dst.Layers == 0 {
		dst.Layers = src.Layers
	}
	if dst.AttentionHeads == 0 {
		dst.AttentionHeads = src.AttentionHeads
	}
	if dst.KVHeads == 0 {
		dst.KVHeads = src.KVHeads
	}
	if dst.HeadDimension == 0 {
		dst.HeadDimension = src.HeadDimension
	}
	if dst.EmbeddingDimension == 0 {
		dst.EmbeddingDimension = src.EmbeddingDimension
	}
	if dst.ContextLength == 0 {
		dst.ContextLength = src.ContextLength
	}
	if dst.SlidingWindow == 0 {
		dst.SlidingWindow = src.SlidingWindow
	}
	if dst.ParameterCount == 0 {
		dst.ParameterCount = src.ParameterCount
	}
	if dst.Quantization == "" {
		dst.Quantization = src.Quantization
	}
	if dst.StoredTensorDataType == "" {
		dst.StoredTensorDataType = src.StoredTensorDataType
	}
}

func saturatingAdd(a, b int64) int64 {
	if b > 0 && a > int64(^uint64(0)>>1)-b {
		return int64(^uint64(0) >> 1)
	}
	return a + b
}
