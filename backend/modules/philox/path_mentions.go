package philox

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var drivePathStartPattern = regexp.MustCompile(`(?i)[A-Z]:\\`)

func extractMentionedRoots(message string) []string {
	indices := drivePathStartPattern.FindAllStringIndex(message, -1)
	if len(indices) == 0 {
		return nil
	}

	roots := make([]string, 0, len(indices))
	for i, index := range indices {
		start := index[0]
		end := len(message)
		if i+1 < len(indices) {
			end = indices[i+1][0]
		}
		candidate := strings.TrimSpace(message[start:end])
		candidate = trimPathCandidate(candidate)
		if candidate == "" {
			continue
		}
		roots = append(roots, candidate)
	}
	return roots
}

func trimPathCandidate(candidate string) string {
	value := strings.TrimSpace(candidate)
	if value == "" {
		return ""
	}

	terminators := []string{"\r", "\n", ";", "|"}
	for _, token := range terminators {
		if idx := strings.Index(value, token); idx >= 0 {
			value = strings.TrimSpace(value[:idx])
		}
	}

	suffixes := []string{
		" und",
		" oder",
		", bitte",
		".",
		",",
		" )",
		")",
		" ]",
		"]",
		"`",
		"\"",
		"'",
	}
	for _, suffix := range suffixes {
		for strings.HasSuffix(strings.ToLower(value), suffix) {
			value = strings.TrimSpace(value[:len(value)-len(suffix)])
		}
	}

	value = strings.Trim(value, "\"'`")
	value = strings.TrimSpace(value)
	if value == "" {
		return ""
	}

	if trimmed := existingPathPrefix(value); trimmed != "" {
		return trimmed
	}
	return value
}

func existingPathPrefix(value string) string {
	current := strings.TrimSpace(value)
	for current != "" {
		cleaned := strings.TrimSpace(strings.TrimRight(current, ".,);]`\"'"))
		if cleaned == "" {
			return ""
		}
		if info, err := os.Stat(cleaned); err == nil {
			if info.IsDir() {
				return cleaned
			}
			return filepath.Dir(cleaned)
		}
		next := trimLastWhitespaceToken(cleaned)
		if next == cleaned {
			break
		}
		current = next
	}
	return ""
}

func trimLastWhitespaceToken(value string) string {
	lastWhitespace := -1
	for i := len(value) - 1; i >= 0; i-- {
		switch value[i] {
		case ' ', '\t':
			lastWhitespace = i
		default:
			if lastWhitespace >= 0 {
				return strings.TrimSpace(value[:lastWhitespace])
			}
		}
	}
	return value
}

func normalizeMentionedRoots(paths []string) []string {
	normalized := make([]string, 0, len(paths))
	seen := map[string]struct{}{}
	for _, candidate := range paths {
		abs, err := filepath.Abs(strings.TrimSpace(candidate))
		if err != nil {
			continue
		}
		resolved := filepath.Clean(abs)
		if info, err := os.Stat(resolved); err == nil {
			if !info.IsDir() {
				resolved = filepath.Dir(resolved)
			}
			if eval, err := filepath.EvalSymlinks(resolved); err == nil {
				resolved = filepath.Clean(eval)
			}
		} else if ext := filepath.Ext(resolved); ext != "" {
			resolved = filepath.Dir(resolved)
		}
		key := strings.ToLower(resolved)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		normalized = append(normalized, resolved)
	}
	return normalized
}

func mergeAllowedRoots(existing, mentioned []string, executor *toolExecutor) []string {
	if len(mentioned) == 0 {
		return existing
	}
	merged := append([]string{}, existing...)
	merged = append(merged, normalizeMentionedRoots(mentioned)...)
	if executor == nil {
		return merged
	}
	normalized, err := executor.NormalizeRoots(merged)
	if err != nil {
		return existing
	}
	return normalized
}
