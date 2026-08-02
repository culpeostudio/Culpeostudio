// Package pathmention finds file and directory paths named in a message, so an
// assistant can be granted access to exactly those.
package pathmention

import (
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"
)

var windowsPath = regexp.MustCompile(`(?i)\b[a-z]:[\\/][^\s"'<>|*?]*`)

var unixPath = regexp.MustCompile(`(?:^|[\s"'(<])(~?/[^\s"'<>|*?:]+)`)

var systemPrefixes = []string{
	"/etc", "/usr", "/bin", "/sbin", "/lib", "/lib64", "/boot", "/dev",
	"/proc", "/sys", "/run", "/var/log", "/var/lib", "/snap",
	`c:\windows`, `c:\program files`, `c:\program files (x86)`,
	`c:\programdata`,
}

func Extract(message string) []string {
	if strings.TrimSpace(message) == "" {
		return nil
	}

	seen := map[string]struct{}{}
	var out []string
	for _, candidate := range candidates(message) {
		dir, ok := resolveDir(candidate)
		if !ok {
			continue
		}
		key := strings.ToLower(dir)
		if _, dup := seen[key]; dup {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, dir)
	}
	sort.Strings(out)
	return out
}

func candidates(message string) []string {
	var found []string
	found = append(found, windowsPath.FindAllString(message, -1)...)
	for _, match := range unixPath.FindAllStringSubmatch(message, -1) {
		if len(match) > 1 {
			found = append(found, match[1])
		}
	}

	out := make([]string, 0, len(found))
	for _, raw := range found {

		trimmed := strings.TrimRight(strings.TrimSpace(raw), `.,;:!?)"'`)
		if trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}

func resolveDir(candidate string) (string, bool) {
	expanded, ok := expandHome(candidate)
	if !ok {
		return "", false
	}
	if isSystemPath(expanded) {
		return "", false
	}

	info, err := os.Stat(expanded)
	if err != nil {

		return "", false
	}

	dir := expanded
	if !info.IsDir() {
		dir = filepath.Dir(expanded)
	}
	resolved, err := filepath.Abs(dir)
	if err != nil {
		return "", false
	}

	if eval, err := filepath.EvalSymlinks(resolved); err == nil {
		resolved = eval
	}
	resolved = filepath.Clean(resolved)

	if resolved == string(filepath.Separator) || isDriveRoot(resolved) {
		return "", false
	}
	if isSystemPath(resolved) {
		return "", false
	}

	if home, err := os.UserHomeDir(); err == nil && home != "" {
		if strings.EqualFold(filepath.Clean(home), resolved) {
			return "", false
		}
	}
	return resolved, true
}

func expandHome(path string) (string, bool) {
	if !strings.HasPrefix(path, "~") {
		return path, true
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", false
	}
	if path == "~" {
		return home, true
	}
	if strings.HasPrefix(path, "~/") {
		return filepath.Join(home, path[2:]), true
	}

	return "", false
}

func isSystemPath(path string) bool {
	lower := strings.ToLower(filepath.Clean(path))
	if runtime.GOOS == "windows" {
		lower = strings.ReplaceAll(lower, "/", `\`)
	}
	for _, prefix := range systemPrefixes {
		if lower == prefix || strings.HasPrefix(lower, prefix+string(filepath.Separator)) {
			return true
		}

		if strings.HasPrefix(lower, prefix+"/") || strings.HasPrefix(lower, prefix+`\`) {
			return true
		}
	}
	return false
}

func isDriveRoot(path string) bool {
	cleaned := strings.TrimSuffix(strings.TrimSuffix(path, `\`), "/")
	return len(cleaned) == 2 && cleaned[1] == ':'
}
