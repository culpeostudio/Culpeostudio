package webtools

import (
	"context"
	"strings"
	"testing"
	"time"
)

func newTestTools(t *testing.T) *Tools {
	t.Helper()
	tools, err := New(Options{Timeout: 5 * time.Second})
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	return tools
}

func TestHandles(t *testing.T) {
	tools := newTestTools(t)
	for _, name := range tools.Names() {
		if !tools.Handles(name) {
			t.Errorf("Handles(%q) = false, erwartet true", name)
		}
	}
	if tools.Handles("read_file") {
		t.Error("Handles(\"read_file\") = true, Datei-Tools gehoeren nicht hierher")
	}
}

func TestExecuteUnknownTool(t *testing.T) {
	res := newTestTools(t).Execute(context.Background(), "nope", nil)
	assertFailure(t, res, "unknown_tool")
}

func TestWebSearchRejectsBadArguments(t *testing.T) {
	tools := newTestTools(t)
	cases := []struct {
		name string
		args map[string]interface{}
	}{
		{"query fehlt", map[string]interface{}{}},
		{"query leer", map[string]interface{}{"query": "   "}},
		{"query kein string", map[string]interface{}{"query": 42}},
		{"unbekannte category", map[string]interface{}{"query": "go", "category": "bilder"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			assertFailure(t, tools.Execute(context.Background(), ToolWebSearch, tc.args), "invalid_tool_arguments")
		})
	}
}

func TestWebFetchRejectsBadArguments(t *testing.T) {
	tools := newTestTools(t)
	assertFailure(t, tools.Execute(context.Background(), ToolWebFetch, map[string]interface{}{}), "invalid_tool_arguments")
	assertFailure(t, tools.Execute(context.Background(), ToolWebFetch, map[string]interface{}{"url": " "}), "invalid_tool_arguments")
}

// TestWebFetchBlocksInternalTargets ist der wichtigste Test hier: ein Modell
// darf sich ueber die Werkzeuge keinen Zugriff auf interne Dienste erschleichen.
func TestWebFetchBlocksInternalTargets(t *testing.T) {
	tools := newTestTools(t)
	for _, target := range []string{
		"http://127.0.0.1:8080/admin",
		"http://localhost:3000/",
		"http://169.254.169.254/latest/meta-data/",
		"http://192.168.1.1/",
		"file:///etc/passwd",
	} {
		t.Run(target, func(t *testing.T) {
			assertFailure(t, tools.Execute(context.Background(), ToolWebFetch,
				map[string]interface{}{"url": target}), "blocked_url")
		})
	}
}

func TestIntArg(t *testing.T) {
	args := map[string]interface{}{
		"aus_json":   float64(7),
		"als_int":    3,
		"als_string": "5",
		"kaputt":     "viele",
	}
	cases := map[string]int{"aus_json": 7, "als_int": 3, "als_string": 5, "kaputt": 9, "fehlt": 9}
	for key, want := range cases {
		if got := intArg(args, key, 9); got != want {
			t.Errorf("intArg(%q) = %d, erwartet %d", key, got, want)
		}
	}
}

func TestTruncate(t *testing.T) {
	if got := truncate("kurz", 10); got != "kurz" {
		t.Errorf("truncate kurz = %q, erwartet unveraendert", got)
	}
	got := truncate("abcdefghij", 5)
	if !strings.HasSuffix(got, "…") {
		t.Errorf("truncate sollte eine Ellipse anhaengen, war %q", got)
	}
	if len([]rune(got)) != 6 {
		t.Errorf("truncate = %q, erwartet 5 Zeichen + Ellipse", got)
	}
	// Mehrbyte-Zeichen duerfen nicht zerschnitten werden.
	if got := truncate("äöüäöüäöü", 4); !strings.HasPrefix(got, "äöüä") {
		t.Errorf("truncate zerschneidet Mehrbyte-Zeichen: %q", got)
	}
}

// TestCacheRoundtrip prueft, dass ein Ergebnis zurueckkommt und als
// zwischengespeichert markiert wird, ohne den Original-Eintrag zu veraendern.
func TestCacheRoundtrip(t *testing.T) {
	tools := newTestTools(t)
	original := map[string]interface{}{"ok": true, "count": 1}
	tools.toCache("k", original)

	got, ok := tools.fromCache("k")
	if !ok {
		t.Fatal("fromCache = false, erwartet Treffer")
	}
	if got["cached"] != true {
		t.Error("Cache-Treffer sollte cached=true tragen")
	}
	if _, exists := original["cached"]; exists {
		t.Error("fromCache darf den abgelegten Eintrag nicht veraendern")
	}
	if _, ok := tools.fromCache("unbekannt"); ok {
		t.Error("fromCache fuer unbekannten Key sollte false liefern")
	}
}

func TestCacheExpiry(t *testing.T) {
	tools := newTestTools(t)
	tools.cacheTTL = time.Nanosecond
	tools.toCache("k", map[string]interface{}{"ok": true})
	time.Sleep(time.Millisecond)
	if _, ok := tools.fromCache("k"); ok {
		t.Error("abgelaufener Eintrag sollte nicht mehr geliefert werden")
	}
}

func TestCacheDisabled(t *testing.T) {
	tools := newTestTools(t)
	tools.cacheTTL = -1
	tools.toCache("k", map[string]interface{}{"ok": true})
	if _, ok := tools.fromCache("k"); ok {
		t.Error("bei negativer TTL darf nichts zwischengespeichert werden")
	}
}

// TestPromptSection sichert Werkzeugnamen und Abwaege-Kriterien: der Prompt
// ist der einzige Weg, auf dem das Modell von den Werkzeugen erfaehrt.
func TestPromptSection(t *testing.T) {
	for _, hasFileTools := range []bool{true, false} {
		section := PromptSection(hasFileTools)
		for _, want := range []string{ToolWebSearch, ToolWebFetch, "Wann du suchen sollst", "Wann du NICHT suchen sollst", "max_results", "max_chars"} {
			if !strings.Contains(section, want) {
				t.Errorf("PromptSection(%v) enthaelt %q nicht", hasFileTools, want)
			}
		}
	}
	// Ohne Datei-Werkzeuge darf der Prompt nicht auf sie verweisen.
	if strings.Contains(PromptSection(false), "dafuer sind die Datei-Werkzeuge da") {
		t.Error("PromptSection(false) verweist auf nicht vorhandene Datei-Werkzeuge")
	}
	if !strings.Contains(PromptSection(true), "dafuer sind die Datei-Werkzeuge da") {
		t.Error("PromptSection(true) sollte auf die Datei-Werkzeuge verweisen")
	}
}

func assertFailure(t *testing.T, res map[string]interface{}, wantCode string) {
	t.Helper()
	if ok, _ := res["ok"].(bool); ok {
		t.Fatalf("erwartete Fehlschlag, bekam ok=true: %v", res)
	}
	if got := res["error_code"]; got != wantCode {
		t.Fatalf("error_code = %v, erwartet %q (%v)", got, wantCode, res)
	}
	if _, ok := res["error"].(string); !ok {
		t.Error("Fehlerantwort braucht ein error-Feld")
	}
}
