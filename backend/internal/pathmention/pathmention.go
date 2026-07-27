// Package pathmention findet Dateipfade, die ein Nutzer in seiner
// Nachricht nennt.
//
// Wer "schau mal in /home/nutzer/projekt/main.go" schreibt, meint damit
// ersichtlich, dass der Agent dort nachsehen soll. Ohne diese Erkennung
// muesste er denselben Pfad noch einmal umstaendlich freigeben.
//
// Die Erkennung ist bewusst zurueckhaltend: nur Pfade, die tatsaechlich
// existieren, zaehlen - alles andere waere Rauschen aus Fliesstext,
// Code-Schnipseln oder Beispielen. System-Verzeichnisse bleiben aussen
// vor; sie sind ueber die normale Erlaubnis-Abfrage weiterhin
// erreichbar, werden aber nicht stillschweigend freigegeben.
package pathmention

import (
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"
)

// windowsPath erkennt Laufwerkspfade wie C:\Users\nutzer\projekt.
var windowsPath = regexp.MustCompile(`(?i)\b[a-z]:[\\/][^\s"'<>|*?]*`)

// unixPath erkennt absolute Pfade wie /home/nutzer/projekt und ~/projekt.
var unixPath = regexp.MustCompile(`(?:^|[\s"'(<])(~?/[^\s"'<>|*?:]+)`)

// systemPrefixes werden nie automatisch freigegeben. Ein Agent hat dort
// nichts verloren, solange der Nutzer es nicht ueber die
// Erlaubnis-Abfrage ausdruecklich gestattet.
var systemPrefixes = []string{
	"/etc", "/usr", "/bin", "/sbin", "/lib", "/lib64", "/boot", "/dev",
	"/proc", "/sys", "/run", "/var/log", "/var/lib", "/snap",
	`c:\windows`, `c:\program files`, `c:\program files (x86)`,
	`c:\programdata`,
}

// Extract liefert die Verzeichnisse, die in message genannt werden und
// auf der Platte existieren.
//
// Bei einer genannten Datei kommt deren Verzeichnis zurueck: wer eine
// Datei nennt, meint den Ordner, in dem gearbeitet werden soll. Das
// Ergebnis ist dedupliziert und sortiert, damit es stabil bleibt.
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

// candidates sammelt die Rohtreffer beider Muster.
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
		// Satzzeichen am Ende gehoeren zum Text, nicht zum Pfad.
		trimmed := strings.TrimRight(strings.TrimSpace(raw), `.,;:!?)"'`)
		if trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}

// resolveDir prueft einen Kandidaten und liefert das freizugebende
// Verzeichnis.
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
		// Nicht existierende Pfade sind fast immer Beispiele aus dem
		// Fliesstext und keine echte Absicht.
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
	// Symlinks aufloesen, damit derselbe Ordner nicht unter zwei Namen
	// als getrennter Root landet.
	if eval, err := filepath.EvalSymlinks(resolved); err == nil {
		resolved = eval
	}
	resolved = filepath.Clean(resolved)

	// Das Wurzelverzeichnis freizugeben hiesse, die Sandbox abzuschaffen.
	if resolved == string(filepath.Separator) || isDriveRoot(resolved) {
		return "", false
	}
	if isSystemPath(resolved) {
		return "", false
	}
	// Das Heimatverzeichnis selbst ist zu weit: dort liegen SSH-Schluessel,
	// Browser-Profile und Zugangsdaten. Unterordner davon sind in Ordnung,
	// und ueber die Erlaubnis-Abfrage bleibt auch das Heimatverzeichnis
	// erreichbar - nur eben nicht stillschweigend.
	if home, err := os.UserHomeDir(); err == nil && home != "" {
		if strings.EqualFold(filepath.Clean(home), resolved) {
			return "", false
		}
	}
	return resolved, true
}

// expandHome ersetzt ein fuehrendes ~ durch das Heimatverzeichnis.
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
	// "~andereruser" wird nicht aufgeloest.
	return "", false
}

// isSystemPath meldet, ob der Pfad in einem Systemverzeichnis liegt.
func isSystemPath(path string) bool {
	lower := strings.ToLower(filepath.Clean(path))
	if runtime.GOOS == "windows" {
		lower = strings.ReplaceAll(lower, "/", `\`)
	}
	for _, prefix := range systemPrefixes {
		if lower == prefix || strings.HasPrefix(lower, prefix+string(filepath.Separator)) {
			return true
		}
		// Unter Windows kommen beide Trenner vor.
		if strings.HasPrefix(lower, prefix+"/") || strings.HasPrefix(lower, prefix+`\`) {
			return true
		}
	}
	return false
}

// isDriveRoot erkennt "C:\" und "C:".
func isDriveRoot(path string) bool {
	cleaned := strings.TrimSuffix(strings.TrimSuffix(path, `\`), "/")
	return len(cleaned) == 2 && cleaned[1] == ':'
}
