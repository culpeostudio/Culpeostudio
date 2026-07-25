package philox

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const (
	toolAuditErrorInvalidArguments = "invalid_tool_arguments"
	toolAuditErrorExecution        = "tool_execution_error"
)

type toolExecutor struct{}

func newToolExecutor() *toolExecutor {
	return &toolExecutor{}
}

func (e *toolExecutor) NormalizeRoots(roots []string) ([]string, error) {
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

func (e *toolExecutor) resolvePath(session *PersistedSession, rawPath string, allowMissing bool) (string, error) {
	trimmed := strings.TrimSpace(rawPath)
	if trimmed == "" {
		return "", errors.New("Pfad fehlt")
	}

	candidate := trimmed
	if !filepath.IsAbs(candidate) {
		if len(session.AllowedRoots) == 0 {
			return "", errors.New("relativer Pfad ohne freigegebenen Root nicht erlaubt")
		}
		candidate = filepath.Join(session.AllowedRoots[0], candidate)
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

	for _, root := range session.AllowedRoots {
		rootAbs := filepath.Clean(root)
		rel, err := filepath.Rel(rootAbs, resolved)
		if err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
			return resolved, nil
		}
	}
	return "", fmt.Errorf("Pfad ausserhalb erlaubter Roots: %s", resolved)
}

func (e *toolExecutor) Execute(session *PersistedSession, call ToolCall) (ConversationMessage, ToolAuditEntry) {
	audit := ToolAuditEntry{
		ToolName:  call.Function.Name,
		Success:   false,
		Timestamp: nowUTC(),
	}

	normalizedCall, args, err := normalizeToolCall(call)
	if err != nil {
		audit.ErrorCode = toolAuditErrorInvalidArguments
		audit.ErrorMessage = "ungueltige Tool-Argumente: " + err.Error()
		hint := toolArgumentHint(call.Function.Name)
		if strings.Contains(err.Error(), "EOF") || strings.Contains(err.Error(), "unexpected end") {
			hint = "Die Tool-Argumente wurden abgeschnitten (truncated). Verwende patch_file mit kleineren Aenderungen statt write_file mit grossem Content. Teile grosse Dateien in mehrere patch_file Aufrufe auf."
		}
		result := map[string]interface{}{
			"ok":         false,
			"error":      audit.ErrorMessage,
			"error_code": toolAuditErrorInvalidArguments,
			"hint":       hint,
		}
		payload, _ := json.Marshal(result)
		audit.ResultPreview = previewText(string(payload), 220)
		return ConversationMessage{
			Role:       "tool",
			ToolCallID: call.ID,
			Name:       call.Function.Name,
			Content:    string(payload),
			CreatedAt:  nowUTC(),
		}, audit
	}
	call = normalizedCall
	audit.Arguments = args

	if err := validateToolArguments(call.Function.Name, args); err != nil {
		audit.ErrorCode = toolAuditErrorInvalidArguments
		audit.ErrorMessage = "ungueltige Tool-Argumente: " + err.Error()
		result := map[string]interface{}{
			"ok":         false,
			"error":      audit.ErrorMessage,
			"error_code": toolAuditErrorInvalidArguments,
			"hint":       toolArgumentHint(call.Function.Name),
		}
		payload, _ := json.Marshal(result)
		audit.ResultPreview = previewText(string(payload), 220)
		return ConversationMessage{
			Role:       "tool",
			ToolCallID: call.ID,
			Name:       call.Function.Name,
			Content:    string(payload),
			CreatedAt:  nowUTC(),
		}, audit
	}

	result := map[string]interface{}{"ok": true}
	switch call.Function.Name {
	case "list_dir":
		result, err = e.listDir(session, args)
	case "read_file":
		result, err = e.readFile(session, args)
	case "write_file":
		result, err = e.writeFile(session, args)
	case "patch_file":
		result, err = e.patchFile(session, args)
	case "delete_path":
		result, err = e.deletePath(session, args)
	case "move_path":
		result, err = e.movePath(session, args)
	case "make_dir":
		result, err = e.makeDir(session, args)
	case "stat_path":
		result, err = e.statPath(session, args)
	default:
		err = fmt.Errorf("unbekanntes Tool: %s", call.Function.Name)
	}
	if err != nil {
		audit.ErrorCode = toolAuditErrorExecution
		audit.ErrorMessage = err.Error()
		result = map[string]interface{}{"ok": false, "error": err.Error()}
	} else {
		audit.Success = true
	}
	payload, _ := json.Marshal(result)
	audit.ResultPreview = previewText(string(payload), 220)
	return ConversationMessage{
		Role:       "tool",
		ToolCallID: call.ID,
		Name:       call.Function.Name,
		Content:    string(payload),
		CreatedAt:  nowUTC(),
	}, audit
}

func validateToolArguments(toolName string, args map[string]interface{}) error {
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

func toolArgumentHint(toolName string) string {
	switch toolName {
	case "write_file":
		return `Erwarte {"path":"<datei>","content":"<vollstaendiger inhalt>"}. Wenn der Inhalt zu lang ist, verwende stattdessen patch_file mit mehreren Aufrufen.`
	case "patch_file":
		return `Erwarte {"path":"<datei>","old_text":"<alt>","new_text":"<neu>"}. Backslashes in Pfaden muessen escaped sein.`
	case "move_path":
		return `Erwarte {"source_path":"<quelle>","destination_path":"<ziel>"}.`
	default:
		return `Tool-Argumente muessen genau ein gueltiges JSON-Objekt sein, ohne Markdown-Codeblock oder Prefix.`
	}
}

func (e *toolExecutor) listDir(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(session, path, false)
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

func (e *toolExecutor) readFile(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(session, path, false)
	if err != nil {
		return nil, err
	}
	content, err := os.ReadFile(resolved)
	if err != nil {
		return nil, err
	}
	// Higher default to give the model more context for better code quality.
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

func (e *toolExecutor) writeFile(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	content, _ := args["content"].(string)
	resolved, err := e.resolvePath(session, path, true)
	if err != nil {
		return nil, err
	}

	// Check if file already exists — if so, warn when it was never read.
	fileExisted := false
	if _, statErr := os.Stat(resolved); statErr == nil {
		fileExisted = true
	}

	if err := os.MkdirAll(filepath.Dir(resolved), 0o755); err != nil {
		return nil, err
	}
	if err := os.WriteFile(resolved, []byte(content), 0o644); err != nil {
		return nil, err
	}
	result := map[string]interface{}{"ok": true, "path": resolved, "bytes_written": len(content)}

	if fileExisted && !wasFileReadInSession(session, resolved) {
		result["warning"] = "Du hast diese bestehende Datei ueberschrieben ohne sie vorher mit read_file zu lesen. Das kann zu Datenverlust fuehren. Lies Dateien immer zuerst bevor du sie aenderst."
	}

	return result, nil
}

func (e *toolExecutor) patchFile(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	search, _ := args["old_text"].(string)
	replace, _ := args["new_text"].(string)
	resolved, err := e.resolvePath(session, path, false)
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

	if !wasFileReadInSession(session, resolved) {
		result["warning"] = "Du hast diese Datei mit patch_file geaendert ohne sie vorher mit read_file zu lesen. Lies Dateien immer zuerst um sicherzustellen dass dein old_text korrekt und aktuell ist."
	}

	return result, nil
}

func (e *toolExecutor) deletePath(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(session, path, false)
	if err != nil {
		return nil, err
	}
	if err := os.RemoveAll(resolved); err != nil {
		return nil, err
	}
	return map[string]interface{}{"ok": true, "path": resolved, "deleted": true}, nil
}

func (e *toolExecutor) movePath(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	source, _ := args["source_path"].(string)
	destination, _ := args["destination_path"].(string)
	resolvedSource, err := e.resolvePath(session, source, false)
	if err != nil {
		return nil, err
	}
	resolvedDestination, err := e.resolvePath(session, destination, true)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(filepath.Dir(resolvedDestination), 0o755); err != nil {
		return nil, err
	}
	if err := os.Rename(resolvedSource, resolvedDestination); err != nil {
		return nil, err
	}
	return map[string]interface{}{"ok": true, "source_path": resolvedSource, "destination_path": resolvedDestination}, nil
}

func (e *toolExecutor) makeDir(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(session, path, true)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(resolved, 0o755); err != nil {
		return nil, err
	}
	return map[string]interface{}{"ok": true, "path": resolved, "created": true}, nil
}

func (e *toolExecutor) statPath(session *PersistedSession, args map[string]interface{}) (map[string]interface{}, error) {
	path, _ := args["path"].(string)
	resolved, err := e.resolvePath(session, path, false)
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

// wasFileReadInSession checks whether the given resolved path was previously
// read via read_file in this session. Used to enforce read-before-write.
func wasFileReadInSession(session *PersistedSession, resolvedPath string) bool {
	normalizedTarget := strings.ToLower(filepath.Clean(resolvedPath))
	for _, audit := range session.ToolAudit {
		if audit.ToolName != "read_file" || !audit.Success {
			continue
		}
		if audit.Arguments == nil {
			continue
		}
		if readPath, ok := audit.Arguments["path"].(string); ok {
			if strings.ToLower(filepath.Clean(readPath)) == normalizedTarget {
				return true
			}
		}
	}
	// Also check recent messages for successful read_file tool results
	// that might not be in the audit yet (same round).
	for _, msg := range session.Messages {
		if msg.Role != "tool" || msg.Name != "read_file" {
			continue
		}
		if strings.Contains(msg.Content, `"ok":true`) || strings.Contains(msg.Content, `"ok": true`) {
			if strings.Contains(strings.ToLower(msg.Content), strings.ToLower(filepath.Base(resolvedPath))) {
				return true
			}
		}
	}
	return false
}

// The provider-specific tool schemas were removed together with the agent backend.
