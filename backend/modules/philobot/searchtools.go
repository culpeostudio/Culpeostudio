package philobot

import (
	"bufio"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"
)

// skippedDirNames werden bei allen Verzeichnis-Durchlaeufen (grep_search,
// find_files, Dateibaum) ignoriert: VCS-Metadaten, Abhaengigkeiten und
// Build-Outputs, die das Ergebnis nur aufblaehen.
var skippedDirNames = map[string]struct{}{
	".git":         {},
	"node_modules": {},
	"build":        {},
	".dart_tool":   {},
	".idea":        {},
	"__pycache__":  {},
	".venv":        {},
}

func shouldSkipDir(name string) bool {
	_, ok := skippedDirNames[name]
	return ok
}

const (
	// maxSearchFileSize ueberspringt grosse Dateien bei der Volltextsuche.
	maxSearchFileSize = 1 << 20 // 1 MB
	// maxSearchResults deckelt die Trefferanzahl, damit der Tool-Loop und
	// das Modell nicht in Ergebnissen ertrinken.
	maxSearchResults     = 200
	maxSearchResultsHard = 1000
	// maxMatchLineRunes kuerzt einzelne Trefferzeilen.
	maxMatchLineRunes = 200
)

// isBinaryFile heuristisch: ein NUL-Byte in den ersten 8 KB gilt als binaer.
func isBinaryFile(path string) bool {
	f, err := os.Open(path)
	if err != nil {
		return true // nicht lesbar -> lieber ueberspringen
	}
	defer f.Close()
	buf := make([]byte, 8192)
	n, _ := f.Read(buf)
	return strings.ContainsRune(string(buf[:n]), '\x00')
}

// searchRoot loest das optionale path-Argument der Such-Tools auf; ohne Angabe
// wird der erste freigegebene Root durchsucht.
func (e *fileToolExecutor) searchRoot(args map[string]interface{}) (string, error) {
	rawPath, _ := args["path"].(string)
	if strings.TrimSpace(rawPath) == "" {
		if len(e.roots) == 0 {
			return "", fmt.Errorf("kein freigegebener Root vorhanden")
		}
		return e.roots[0], nil
	}
	return e.resolvePath(rawPath, false)
}

// clampMaxResults liest das optionale max_results-Argument.
func clampMaxResults(args map[string]interface{}) int {
	maxResults := maxSearchResults
	if raw, ok := args["max_results"].(float64); ok && int(raw) > 0 {
		maxResults = int(raw)
		if maxResults > maxSearchResultsHard {
			maxResults = maxSearchResultsHard
		}
	}
	return maxResults
}

// matchGlobPattern matcht ein Glob-Pattern mit **-Unterstuetzung: * und ?
// wirken pro Pfad-Segment, ** steht fuer beliebig viele Segmente.
func matchGlobPattern(pattern, name string) bool {
	pSeg := strings.Split(filepath.ToSlash(pattern), "/")
	nSeg := strings.Split(filepath.ToSlash(name), "/")
	return matchGlobSegments(pSeg, nSeg)
}

func matchGlobSegments(p, n []string) bool {
	for len(p) > 0 {
		if p[0] == "**" {
			for i := 0; i <= len(n); i++ {
				if matchGlobSegments(p[1:], n[i:]) {
					return true
				}
			}
			return false
		}
		if len(n) == 0 {
			return false
		}
		ok, err := path.Match(p[0], n[0])
		if err != nil || !ok {
			return false
		}
		p = p[1:]
		n = n[1:]
	}
	return len(n) == 0
}

// grepSearch durchsucht Dateien im Sandbox-Bereich nach einem Literal oder
// Regex und liefert Treffer als {path, line, text} zurueck.
func (e *fileToolExecutor) grepSearch(args map[string]interface{}) (map[string]interface{}, error) {
	pattern, _ := args["pattern"].(string)
	isRegex, _ := args["is_regex"].(bool)
	globFilter, _ := args["glob"].(string)
	maxResults := clampMaxResults(args)

	var matches func(line string) bool
	if isRegex {
		re, err := regexp.Compile(pattern)
		if err != nil {
			return nil, fmt.Errorf("ungueltiges Regex-Muster: %v", err)
		}
		matches = re.MatchString
	} else {
		matches = func(line string) bool { return strings.Contains(line, pattern) }
	}

	root, err := e.searchRoot(args)
	if err != nil {
		return nil, err
	}
	results := make([]map[string]interface{}, 0, 32)
	truncated := false

	scanFile := func(filePath string) bool {
		// true = Ergebnis-Cap erreicht, Walk abbrechen.
		f, err := os.Open(filePath)
		if err != nil {
			return false
		}
		defer f.Close()
		scanner := bufio.NewScanner(f)
		scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
		lineNo := 0
		for scanner.Scan() {
			lineNo++
			line := scanner.Text()
			if !matches(line) {
				continue
			}
			text := strings.TrimSpace(line)
			if runes := []rune(text); len(runes) > maxMatchLineRunes {
				text = string(runes[:maxMatchLineRunes]) + "…"
			}
			results = append(results, map[string]interface{}{
				"path": filePath,
				"line": lineNo,
				"text": text,
			})
			if len(results) >= maxResults {
				return true
			}
		}
		return false
	}

	info, statErr := os.Stat(root)
	switch {
	case statErr != nil:
		return nil, statErr
	case !info.IsDir():
		if scanFile(root) {
			truncated = true
		}
	default:
		_ = filepath.WalkDir(root, func(p string, d os.DirEntry, walkErr error) error {
			if walkErr != nil {
				return nil
			}
			if d.IsDir() {
				if p != root && shouldSkipDir(d.Name()) {
					return filepath.SkipDir
				}
				return nil
			}
			if globFilter != "" && !matchGlobPattern(globFilter, d.Name()) {
				return nil
			}
			if fi, fiErr := d.Info(); fiErr != nil || fi.Size() > maxSearchFileSize {
				return nil
			}
			if isBinaryFile(p) {
				return nil
			}
			if scanFile(p) {
				truncated = true
				return filepath.SkipAll
			}
			return nil
		})
	}

	return map[string]interface{}{
		"ok":        true,
		"pattern":   pattern,
		"path":      root,
		"matches":   results,
		"count":     len(results),
		"truncated": truncated,
	}, nil
}

// findFiles sucht Dateien anhand eines Glob-Musters (z. B. "*.dart" oder
// "**/test_*.go") und liefert relative Pfade zurueck.
func (e *fileToolExecutor) findFiles(args map[string]interface{}) (map[string]interface{}, error) {
	pattern, _ := args["pattern"].(string)
	maxResults := clampMaxResults(args)

	root, err := e.searchRoot(args)
	if err != nil {
		return nil, err
	}
	info, err := os.Stat(root)
	if err != nil {
		return nil, err
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("kein Verzeichnis: %s", root)
	}
	matchOnPath := strings.Contains(pattern, "/")

	found := make([]string, 0, 32)
	truncated := false
	_ = filepath.WalkDir(root, func(p string, d os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return nil
		}
		if d.IsDir() {
			if p != root && shouldSkipDir(d.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		rel, relErr := filepath.Rel(root, p)
		if relErr != nil {
			return nil
		}
		candidate := d.Name()
		if matchOnPath {
			candidate = rel
		}
		if !matchGlobPattern(pattern, candidate) {
			return nil
		}
		found = append(found, rel)
		if len(found) >= maxResults {
			truncated = true
			return filepath.SkipAll
		}
		return nil
	})

	return map[string]interface{}{
		"ok":        true,
		"pattern":   pattern,
		"path":      root,
		"files":     found,
		"count":     len(found),
		"truncated": truncated,
	}, nil
}

// dirTreeEntry ist ein Knoten des Dateibaums fuer den Frontend-Endpunkt.
type dirTreeEntry struct {
	Name     string          `json:"name"`
	Path     string          `json:"path"` // relativ zum Projekt-Root
	IsDir    bool            `json:"is_dir"`
	Children []*dirTreeEntry `json:"children,omitempty"`
}

const (
	maxTreeDepth   = 4
	maxTreeEntries = 500
)

// buildDirTree erzeugt einen tiefen- und eintragsbegrenzten Verzeichnisbaum.
func buildDirTree(root string) (*dirTreeEntry, bool) {
	remaining := maxTreeEntries
	truncated := false
	var walk func(dir string, depth int) []*dirTreeEntry
	walk = func(dir string, depth int) []*dirTreeEntry {
		if depth > maxTreeDepth || remaining <= 0 {
			truncated = truncated || depth <= maxTreeDepth
			return nil
		}
		entries, err := os.ReadDir(dir)
		if err != nil {
			return nil
		}
		children := make([]*dirTreeEntry, 0, len(entries))
		for _, entry := range entries {
			if remaining <= 0 {
				truncated = true
				break
			}
			if entry.IsDir() && shouldSkipDir(entry.Name()) {
				continue
			}
			remaining--
			rel, relErr := filepath.Rel(root, filepath.Join(dir, entry.Name()))
			if relErr != nil {
				continue
			}
			node := &dirTreeEntry{
				Name:  entry.Name(),
				Path:  rel,
				IsDir: entry.IsDir(),
			}
			if entry.IsDir() {
				node.Children = walk(filepath.Join(dir, entry.Name()), depth+1)
			}
			children = append(children, node)
		}
		return children
	}
	tree := &dirTreeEntry{Name: filepath.Base(root), Path: ".", IsDir: true}
	tree.Children = walk(root, 1)
	return tree, truncated
}
