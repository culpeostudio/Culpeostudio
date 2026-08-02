package philobot

import (
	"strings"
	"testing"
)

func TestNormalizeToolArgumentsUebersetztVarianten(t *testing.T) {
	cases := []struct {
		tool     string
		in       map[string]interface{}
		wantKey  string
		wantVal  interface{}
		goneKeys []string
	}{
		{"find_files", map[string]interface{}{"glob": "*.go"}, "pattern", "*.go", []string{"glob"}},
		{"find_files", map[string]interface{}{"query": "*.go"}, "pattern", "*.go", []string{"query"}},
		{"grep_search", map[string]interface{}{"query": "func main"}, "pattern", "func main", []string{"query"}},
		{"read_file", map[string]interface{}{"file": "a.go"}, "path", "a.go", []string{"file"}},
		{"list_dir", map[string]interface{}{"directory": "/tmp"}, "path", "/tmp", []string{"directory"}},
		{"write_file", map[string]interface{}{"path": "a.go", "text": "x"}, "content", "x", []string{"text"}},
		{"patch_file", map[string]interface{}{"path": "a.go", "old": "a", "new": "b"}, "old_text", "a", []string{"old"}},
		{"move_path", map[string]interface{}{"from": "a", "to": "b"}, "source_path", "a", []string{"from"}},
		{"run_command", map[string]interface{}{"cmd": "go"}, "command", "go", []string{"cmd"}},
	}
	for _, tc := range cases {
		t.Run(tc.tool+"/"+tc.wantKey, func(t *testing.T) {
			got := normalizeToolArguments(tc.tool, tc.in)
			if got[tc.wantKey] != tc.wantVal {
				t.Errorf("%s = %v, erwartet %v (%v)", tc.wantKey, got[tc.wantKey], tc.wantVal, got)
			}
			for _, gone := range tc.goneKeys {
				if _, still := got[gone]; still {
					t.Errorf("Alias %q sollte entfernt sein: %v", gone, got)
				}
			}
		})
	}
}

func TestNormalizeToolArgumentsBehaeltGlobBeiGrep(t *testing.T) {
	got := normalizeToolArguments("grep_search", map[string]interface{}{
		"pattern": "func main", "glob": "*.go",
	})
	if got["pattern"] != "func main" {
		t.Errorf("pattern = %v", got["pattern"])
	}
	if got["glob"] != "*.go" {
		t.Errorf("glob muss bei grep_search erhalten bleiben: %v", got)
	}
}

func TestNormalizeToolArgumentsKanonischerNameGewinnt(t *testing.T) {
	got := normalizeToolArguments("read_file", map[string]interface{}{
		"path": "richtig.go", "file": "falsch.go",
	})
	if got["path"] != "richtig.go" {
		t.Errorf("path = %v, der kanonische Name muss gewinnen", got["path"])
	}
	if _, still := got["file"]; still {
		t.Error("der verworfene Alias sollte entfernt sein")
	}
}

func TestNormalizeToolArgumentsLeererKanonischerName(t *testing.T) {
	got := normalizeToolArguments("read_file", map[string]interface{}{
		"path": "   ", "file": "echt.go",
	})
	if got["path"] != "echt.go" {
		t.Errorf("path = %v, der Alias sollte den leeren Wert ersetzen", got["path"])
	}
}

func TestNormalizeToolArgumentsUnbekanntesToolUnveraendert(t *testing.T) {
	in := map[string]interface{}{"irgendwas": 1}
	got := normalizeToolArguments("gibts_nicht", in)
	if len(got) != 1 || got["irgendwas"] != 1 {
		t.Errorf("unbekanntes Tool sollte unveraendert bleiben: %v", got)
	}
	if got := normalizeToolArguments("read_file", nil); len(got) != 0 {
		t.Errorf("nil-Argumente sollten leer bleiben: %v", got)
	}
}

func TestNormalizeToolArgumentsAendertEingabeNicht(t *testing.T) {
	in := map[string]interface{}{"glob": "*.go"}
	normalizeToolArguments("find_files", in)
	if _, still := in["glob"]; !still {
		t.Error("die uebergebene Map darf nicht veraendert werden")
	}
}

func TestTruncationAwareHintErkenntAbschneiden(t *testing.T) {
	langerText := strings.Repeat("x", truncationSuspicionChars+100)
	hint := truncationAwareHint("patch_file", map[string]interface{}{
		"path":     "a.go",
		"old_text": langerText,
	})
	if !strings.Contains(hint, "abgeschnitten") {
		t.Errorf("Hinweis sollte das Abschneiden benennen: %q", hint)
	}
	if !strings.Contains(hint, "kleinste eindeutige Stelle") {
		t.Errorf("Hinweis sollte die Loesung nennen: %q", hint)
	}
}

func TestTruncationAwareHintBleibtGenerisch(t *testing.T) {
	hint := truncationAwareHint("patch_file", map[string]interface{}{
		"path": "a.go", "old_text": "kurz",
	})
	if strings.Contains(hint, "abgeschnitten") {
		t.Errorf("bei kurzem Text sollte nicht auf Abschneiden getippt werden: %q", hint)
	}
	if hint != fileToolArgumentHint("patch_file") {
		t.Errorf("erwartet den Standardhinweis, war: %q", hint)
	}
}

func TestTruncationAwareHintNurFuerSchreibwerkzeuge(t *testing.T) {
	langerText := strings.Repeat("x", truncationSuspicionChars+100)
	hint := truncationAwareHint("grep_search", map[string]interface{}{"pattern": langerText})
	if hint != fileToolArgumentHint("grep_search") {
		t.Errorf("erwartet den Standardhinweis, war: %q", hint)
	}
}
