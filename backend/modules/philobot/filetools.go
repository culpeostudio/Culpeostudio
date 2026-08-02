package philobot

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
)

type outsideRootsError struct {
	resolved string
}

func (e *outsideRootsError) Error() string {
	return fmt.Sprintf("Pfad ausserhalb erlaubter Roots: %s", e.resolved)
}

type fileToolExecutor struct {
	roots        []string
	readPaths    map[string]struct{}
	ctx          context.Context
	asker        permissionAsker
	emitEvent    func(eventType string, data interface{}) error
	sessionID    string
	approvedOnce map[string]struct{}

	approvedPrograms map[string]struct{}
}

func newFileToolExecutor(roots []string) (*fileToolExecutor, error) {
	return newFileToolExecutorWithPermissions(context.Background(), roots, nil, nil, "")
}

func newFileToolExecutorWithPermissions(
	ctx context.Context,
	roots []string,
	asker permissionAsker,
	emitEvent func(eventType string, data interface{}) error,
	sessionID string,
) (*fileToolExecutor, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	e := &fileToolExecutor{
		readPaths:        map[string]struct{}{},
		ctx:              ctx,
		asker:            asker,
		emitEvent:        emitEvent,
		sessionID:        sessionID,
		approvedOnce:     map[string]struct{}{},
		approvedPrograms: map[string]struct{}{},
	}
	normalized, err := e.normalizeRoots(roots)
	if err != nil {
		return nil, err
	}
	if len(normalized) == 0 {
		return nil, errors.New("kein gueltiger Projekt-Root fuer Dateizugriff")
	}
	e.roots = normalized
	return e, nil
}

func (e *fileToolExecutor) normalizeRoots(roots []string) ([]string, error) {
	seen := map[string]struct{}{}
	normalized := make([]string, 0, len(roots))
	for _, root := range roots {
		trimmed := strings.TrimSpace(root)
		if trimmed == "" {
			continue
		}
		abs, err := filepath.Abs(trimmed)
		if err != nil {
			return nil, fmt.Errorf("root path aufloesen: %w", err)
		}
		resolved := filepath.Clean(abs)
		if info, err := os.Stat(resolved); err == nil && info.IsDir() {
			if eval, err := filepath.EvalSymlinks(resolved); err == nil {
				resolved = filepath.Clean(eval)
			}
		}
		key := strings.ToLower(resolved)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		normalized = append(normalized, resolved)
	}
	sort.Strings(normalized)
	return normalized, nil
}

func (e *fileToolExecutor) resolvePath(rawPath string, allowMissing bool) (string, error) {
	trimmed := strings.TrimSpace(rawPath)
	if trimmed == "" {
		return "", errors.New("Pfad fehlt")
	}

	candidate := trimmed
	if !filepath.IsAbs(candidate) {
		if len(e.roots) == 0 {
			return "", errors.New("relativer Pfad ohne freigegebenen Root nicht erlaubt")
		}
		candidate = filepath.Join(e.roots[0], candidate)
	}

	abs, err := filepath.Abs(candidate)
	if err != nil {
		return "", fmt.Errorf("Pfad aufloesen: %w", err)
	}
	resolved := filepath.Clean(abs)
	if allowMissing {
		parent := filepath.Dir(resolved)
		if info, err := os.Stat(parent); err == nil && info.IsDir() {
			if eval, err := filepath.EvalSymlinks(parent); err == nil {
				resolved = filepath.Join(filepath.Clean(eval), filepath.Base(resolved))
			}
		}
	} else if eval, err := filepath.EvalSymlinks(resolved); err == nil {
		resolved = filepath.Clean(eval)
	}

	for _, root := range e.roots {
		rootAbs := filepath.Clean(root)
		rel, err := filepath.Rel(rootAbs, resolved)
		if err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
			return resolved, nil
		}
	}

	if _, ok := e.approvedOnce[strings.ToLower(resolved)]; ok {
		return resolved, nil
	}
	return "", &outsideRootsError{resolved: resolved}
}

func (e *fileToolExecutor) Execute(name string, args map[string]interface{}) map[string]interface{} {
	if args == nil {
		args = map[string]interface{}{}
	}

	args = normalizeToolArguments(name, args)
	if err := validateFileToolArguments(name, args); err != nil {
		return map[string]interface{}{
			"ok":         false,
			"error":      "ungueltige Tool-Argumente: " + err.Error(),
			"error_code": "invalid_tool_arguments",
			"hint":       truncationAwareHint(name, args),
		}
	}

	result, err := e.dispatch(name, args)
	for err != nil {
		var outside *outsideRootsError
		if !errors.As(err, &outside) || e.asker == nil {
			break
		}
		decision := e.requestPermission(name, outside.resolved)
		onceKey := ""
		switch decision {
		case permissionOnce:
			onceKey = strings.ToLower(outside.resolved)
			e.approvedOnce[onceKey] = struct{}{}
		case permissionSession:
			e.grantSessionRoot(outside.resolved)
		default:

			return map[string]interface{}{
				"ok":         false,
				"error":      err.Error(),
				"error_code": "permission_denied",
			}
		}
		result, err = e.dispatch(name, args)
		if onceKey != "" {

			delete(e.approvedOnce, onceKey)
		}
	}
	if err != nil {
		return map[string]interface{}{"ok": false, "error": err.Error()}
	}
	return result
}

func (e *fileToolExecutor) requestPermission(tool, resolved string) string {
	requestID := "perm-" + uuid.New().String()
	if e.emitEvent != nil {
		_ = e.emitEvent("permission_request", map[string]interface{}{
			"request_id": requestID,
			"tool":       tool,
			"path":       resolved,
			"session_id": e.sessionID,
		})
	}
	decision := e.asker.Ask(e.ctx, permissionRequest{ID: requestID, Tool: tool, Path: resolved})
	log.Printf("[philobot] Permission-Entscheidung (tool=%s, path=%s, decision=%s)", tool, resolved, decision)
	if e.emitEvent != nil {
		_ = e.emitEvent("permission_result", map[string]interface{}{
			"request_id": requestID,
			"decision":   decision,
		})
	}
	return decision
}

func (e *fileToolExecutor) grantSessionRoot(resolved string) {
	root := resolved
	if info, err := os.Stat(resolved); err != nil || !info.IsDir() {
		root = filepath.Dir(resolved)
	}
	normalized, err := e.normalizeRoots(append(append([]string{}, e.roots...), root))
	if err != nil || len(normalized) == 0 {
		return
	}
	e.roots = normalized
}

func (e *fileToolExecutor) dispatch(name string, args map[string]interface{}) (map[string]interface{}, error) {
	switch name {
	case "list_dir":
		return e.listDir(args)
	case "read_file":
		return e.readFile(args)
	case "write_file":
		return e.writeFile(args)
	case "patch_file":
		return e.patchFile(args)
	case "delete_path":
		return e.deletePath(args)
	case "move_path":
		return e.movePath(args)
	case "make_dir":
		return e.makeDir(args)
	case "stat_path":
		return e.statPath(args)
	case "grep_search":
		return e.grepSearch(args)
	case "find_files":
		return e.findFiles(args)
	case "run_command":
		return e.runCommand(args)
	default:
		return nil, fmt.Errorf("unbekanntes Tool: %s", name)
	}
}

func (e *fileToolExecutor) emitFileChanged(resolvedPath, action string, oldText, newText string) {
	if e.emitEvent == nil {
		return
	}
	data := map[string]interface{}{
		"path":   resolvedPath,
		"action": action,
	}
	if canDiffText(oldText, newText) {
		data["diff"] = unifiedDiff(oldText, newText, filepath.Base(resolvedPath))
	} else {
		data["diff_skipped"] = true
	}
	_ = e.emitEvent("file_changed", data)
}

func validateFileToolArguments(toolName string, args map[string]interface{}) error {
	requiredString := func(field string, allowEmpty bool) error {
		value, exists := args[field]
		if !exists {
			return fmt.Errorf("%s fehlt", field)
		}
		text, ok := value.(string)
		if !ok {
			return fmt.Errorf("%s muss ein String sein", field)
		}
		if !allowEmpty && strings.TrimSpace(text) == "" {
			return fmt.Errorf("%s darf nicht leer sein", field)
		}
		return nil
	}

	switch toolName {
	case "list_dir", "read_file", "delete_path", "make_dir", "stat_path":
		return requiredString("path", false)
	case "grep_search", "find_files":
		return requiredString("pattern", false)
	case "run_command":
		return requiredString("command", false)
	case "write_file":
		if err := requiredString("path", false); err != nil {
			return err
		}
		return requiredString("content", true)
	case "patch_file":
		if err := requiredString("path", false); err != nil {
			return err
		}
		if err := requiredString("old_text", true); err != nil {
			return err
		}
		return requiredString("new_text", true)
	case "move_path":
		if err := requiredString("source_path", false); err != nil {
			return err
		}
		return requiredString("destination_path", false)
	default:
		return nil
	}
}

func fileToolArgumentHint(toolName string) string {
	switch toolName {
	case "write_file":
		return `Erwarte {"path":"<datei>","content":"<vollstaendiger inhalt>"}. Wenn der Inhalt zu lang ist, verwende stattdessen patch_file mit mehreren Aufrufen.`
	case "patch_file":
		return `Erwarte {"path":"<datei>","old_text":"<alt>","new_text":"<neu>"}. Backslashes in Pfaden muessen escaped sein.`
	case "move_path":
		return `Erwarte {"source_path":"<quelle>","destination_path":"<ziel>"}.`
	case "grep_search":
		return `Erwarte {"pattern":"<suchbegriff>"} mit optional "glob":"*.dart", "is_regex":true, "path":"<ordner>".`
	case "find_files":
		return `Erwarte {"pattern":"*.dart"} oder {"pattern":"**/test/*.go"} fuer Pfad-Muster.`
	case "run_command":
		return `Erwarte {"command":"<programm>","args":["<arg1>","<arg2>"]}. Kein Shell — keine Pipes oder Umleitungen.`
	default:
		return `Tool-Argumente muessen genau ein gueltiges JSON-Objekt sein, ohne Markdown-Codeblock oder Prefix.`
	}
}

func (e *fileToolExecutor) markRead(resolved string) {
	e.readPaths[strings.ToLower(filepath.Clean(resolved))] = struct{}{}
}

func (e *fileToolExecutor) wasRead(resolved string) bool {
	_, ok := e.readPaths[strings.ToLower(filepath.Clean(resolved))]
	return ok
}

func (e *fileToolExecutor) listDir(args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(path, false)
	if err != nil {
		return nil, err
	}
	entries, err := os.ReadDir(resolved)
	if err != nil {
		return nil, err
	}
	items := make([]map[string]interface{}, 0, len(entries))
	for _, entry := range entries {
		info, _ := entry.Info()
		size := int64(0)
		modTime := ""
		if info != nil {
			size = info.Size()
			modTime = info.ModTime().UTC().Format(time.RFC3339)
		}
		items = append(items, map[string]interface{}{
			"name":     entry.Name(),
			"is_dir":   entry.IsDir(),
			"size":     size,
			"mod_time": modTime,
		})
	}
	return map[string]interface{}{"ok": true, "path": resolved, "entries": items}, nil
}

func (e *fileToolExecutor) readFile(args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(path, false)
	if err != nil {
		return nil, err
	}
	content, err := os.ReadFile(resolved)
	if err != nil {
		return nil, err
	}

	maxChars := 32000
	if raw, ok := args["max_chars"].(float64); ok && int(raw) > 0 {
		maxChars = int(raw)
	}
	text := string(content)
	lineCount := strings.Count(text, "\n") + 1
	truncated := false
	if len(text) > maxChars {
		text = text[:maxChars]
		truncated = true
	}
	e.markRead(resolved)
	result := map[string]interface{}{
		"ok":         true,
		"path":       resolved,
		"content":    text,
		"truncated":  truncated,
		"lines":      lineCount,
		"size_bytes": len(content),
	}
	if truncated {
		result["hint"] = fmt.Sprintf("Datei hat %d Zeilen, nur die ersten %d Zeichen werden angezeigt. Nutze max_chars fuer mehr.", lineCount, maxChars)
	}
	return result, nil
}

func (e *fileToolExecutor) writeFile(args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	content, _ := args["content"].(string)
	resolved, err := e.resolvePath(path, true)
	if err != nil {
		return nil, err
	}

	fileExisted := false
	oldText := ""
	if info, statErr := os.Stat(resolved); statErr == nil {
		fileExisted = true
		if info.Size() <= 256*1024 {
			if raw, readErr := os.ReadFile(resolved); readErr == nil {
				oldText = string(raw)
			}
		}
	}

	if err := os.MkdirAll(filepath.Dir(resolved), 0o755); err != nil {
		return nil, err
	}
	if err := os.WriteFile(resolved, []byte(content), 0o644); err != nil {
		return nil, err
	}
	result := map[string]interface{}{"ok": true, "path": resolved, "bytes_written": len(content)}

	if fileExisted && !e.wasRead(resolved) {
		result["warning"] = "Du hast diese bestehende Datei ueberschrieben ohne sie vorher mit read_file zu lesen. Das kann zu Datenverlust fuehren. Lies Dateien immer zuerst bevor du sie aenderst."
	}

	action := "created"
	if fileExisted {
		action = "modified"
	}
	e.emitFileChanged(resolved, action, oldText, content)

	return result, nil
}

func (e *fileToolExecutor) patchFile(args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	search, _ := args["old_text"].(string)
	replace, _ := args["new_text"].(string)
	resolved, err := e.resolvePath(path, false)
	if err != nil {
		return nil, err
	}
	content, err := os.ReadFile(resolved)
	if err != nil {
		return nil, err
	}
	current := string(content)
	if search == "" {
		return nil, errors.New("old_text darf nicht leer sein")
	}
	if !strings.Contains(current, search) {
		return nil, errors.New("old_text wurde in der Datei nicht gefunden")
	}
	updated := strings.ReplaceAll(current, search, replace)
	if err := os.WriteFile(resolved, []byte(updated), 0o644); err != nil {
		return nil, err
	}
	result := map[string]interface{}{"ok": true, "path": resolved, "replacements": strings.Count(current, search)}

	if !e.wasRead(resolved) {
		result["warning"] = "Du hast diese Datei mit patch_file geaendert ohne sie vorher mit read_file zu lesen. Lies Dateien immer zuerst um sicherzustellen dass dein old_text korrekt und aktuell ist."
	}

	e.emitFileChanged(resolved, "modified", current, updated)

	return result, nil
}

func (e *fileToolExecutor) deletePath(args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(path, false)
	if err != nil {
		return nil, err
	}

	oldText := ""
	if info, statErr := os.Stat(resolved); statErr == nil && !info.IsDir() && info.Size() <= 256*1024 {
		if raw, readErr := os.ReadFile(resolved); readErr == nil {
			oldText = string(raw)
		}
	}
	if err := os.RemoveAll(resolved); err != nil {
		return nil, err
	}
	e.emitFileChanged(resolved, "deleted", oldText, "")
	return map[string]interface{}{"ok": true, "path": resolved, "deleted": true}, nil
}

func (e *fileToolExecutor) movePath(args map[string]interface{}) (map[string]interface{}, error) {
	source, _ := args["source_path"].(string)
	destination, _ := args["destination_path"].(string)
	resolvedSource, err := e.resolvePath(source, false)
	if err != nil {
		return nil, err
	}
	resolvedDestination, err := e.resolvePath(destination, true)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(filepath.Dir(resolvedDestination), 0o755); err != nil {
		return nil, err
	}
	if err := os.Rename(resolvedSource, resolvedDestination); err != nil {
		return nil, err
	}
	if e.emitEvent != nil {
		_ = e.emitEvent("file_changed", map[string]interface{}{
			"path":        resolvedSource,
			"destination": resolvedDestination,
			"action":      "moved",
		})
	}
	return map[string]interface{}{"ok": true, "source_path": resolvedSource, "destination_path": resolvedDestination}, nil
}

func (e *fileToolExecutor) makeDir(args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(path, true)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(resolved, 0o755); err != nil {
		return nil, err
	}
	if e.emitEvent != nil {
		_ = e.emitEvent("file_changed", map[string]interface{}{
			"path":   resolved,
			"action": "created",
		})
	}
	return map[string]interface{}{"ok": true, "path": resolved, "created": true}, nil
}

func (e *fileToolExecutor) statPath(args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(path, false)
	if err != nil {
		return nil, err
	}
	info, err := os.Stat(resolved)
	if err != nil {
		return nil, err
	}
	return map[string]interface{}{
		"ok":       true,
		"path":     resolved,
		"name":     info.Name(),
		"size":     info.Size(),
		"is_dir":   info.IsDir(),
		"mod_time": info.ModTime().UTC().Format(time.RFC3339),
	}, nil
}

func resultPreview(result map[string]interface{}, limit int) string {
	payload, err := json.Marshal(result)
	if err != nil {
		return ""
	}
	text := string(payload)
	if limit > 0 && len(text) > limit {
		return text[:limit] + "…"
	}
	return text
}
