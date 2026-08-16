package spark

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParseToolCall(t *testing.T) {
	call, ok := parseToolCall(`<tool_call>{"name":"read_file","arguments":{"path":"README.md"}}</tool_call>`)
	if !ok {
		t.Fatalf("gueltiger Tool-Aufruf sollte erkannt werden")
	}
	if call.Name != "read_file" {
		t.Fatalf("falscher Tool-Name: %q", call.Name)
	}
	if got, _ := call.Arguments["path"].(string); got != "README.md" {
		t.Fatalf("Argument path nicht geparst: %v", call.Arguments)
	}

	if _, ok := parseToolCall("Hallo, das ist eine ganz normale Antwort."); ok {
		t.Fatalf("normaler Text darf kein Tool-Aufruf sein")
	}

	preambleCall, ok := parseToolCall(`Los geht's: <tool_call>{"name":"read_file","arguments":{"path":"config.json"}}</tool_call>`)
	if !ok {
		t.Fatalf("Tool-Aufruf mit Einleitung sollte erkannt werden")
	}
	if preambleCall.Name != "read_file" {
		t.Fatalf("falscher Tool-Name bei Einleitung: %q", preambleCall.Name)
	}
	if got, _ := preambleCall.Arguments["path"].(string); got != "config.json" {
		t.Fatalf("Argument path bei Einleitung nicht geparst: %v", preambleCall.Arguments)
	}
}

func filterVisible(reply string) string {
	var sb strings.Builder
	f := newToolCallStreamFilter(func(s string) error { sb.WriteString(s); return nil })
	for _, r := range reply {
		_ = f.Emit(string(r))
	}
	_ = f.Flush()
	return sb.String()
}

func TestToolCallStreamFilter(t *testing.T) {

	if visible := filterVisible(`<tool_call>{"name":"read_file","arguments":{"path":"a"}}</tool_call>`); visible != "" {
		t.Fatalf("Tool-Aufruf sollte unsichtbar bleiben, sichtbar: %q", visible)
	}

	answer := "Das ist die finale Antwort an den Nutzer."
	if visible := filterVisible(answer); visible != answer {
		t.Fatalf("normale Antwort sollte komplett gestreamt werden, bekam: %q", visible)
	}

	if visible := filterVisible(`Los geht's: <tool_call>{"name":"read_file","arguments":{"path":"a"}}</tool_call>`); visible != "Los geht's: " {
		t.Fatalf("nur die Einleitung sollte sichtbar sein, bekam: %q", visible)
	}

	tail := "Fertig. Kleiner Hinweis: <t"
	if visible := filterVisible(tail); visible != tail {
		t.Fatalf("Text der wie ein angefangener Sentinel endet, sollte beim Flush sichtbar werden, bekam: %q", visible)
	}
}

func TestRunToolLoopExecutesToolThenAnswers(t *testing.T) {
	root := t.TempDir()

	replies := []string{
		`<tool_call>{"name":"write_file","arguments":{"path":"out.txt","content":"fertig"}}</tool_call>`,
		"Erledigt! Ich habe out.txt angelegt.",
	}
	callCount := 0
	chatTurn := func(convo []Message, systemPrompt string, filterEmit func(string) error) (string, error) {
		if !strings.Contains(systemPrompt, "Datei-Werkzeuge") {
			t.Fatalf("System-Prompt sollte die Tool-Anleitung enthalten")
		}
		reply := replies[callCount]
		callCount++
		_ = filterEmit(reply)
		return reply, nil
	}

	var visible strings.Builder
	var events []string
	emitEvent := func(eventType string, data interface{}) error {
		events = append(events, eventType)
		return nil
	}

	final, err := runToolLoop(
		context.Background(),
		[]Message{{Role: "user", Content: "lege out.txt an"}},
		"Du bist ein hilfreicher Bot.",
		[]string{root},
		func(s string) error { visible.WriteString(s); return nil },
		emitEvent,
		chatTurn,
		nil,
		"",
		ContextBudget{},
	)
	if err != nil {
		t.Fatalf("runToolLoop: %v", err)
	}
	if final != "Erledigt! Ich habe out.txt angelegt." {
		t.Fatalf("unerwartete Endantwort: %q", final)
	}
	if callCount != 2 {
		t.Fatalf("Modell sollte genau zweimal aufgerufen werden, war %d", callCount)
	}
	if visible.String() != "Erledigt! Ich habe out.txt angelegt." {
		t.Fatalf("sichtbarer Text sollte nur die Endantwort sein, war: %q", visible.String())
	}
	content, err := os.ReadFile(filepath.Join(root, "out.txt"))
	if err != nil {
		t.Fatalf("Datei sollte im Root angelegt sein: %v", err)
	}
	if string(content) != "fertig" {
		t.Fatalf("falscher Datei-Inhalt: %q", string(content))
	}
	if len(events) != 3 || events[0] != "tool_start" || events[1] != "file_changed" || events[2] != "tool_result" {
		t.Fatalf("erwartete tool_start + file_changed + tool_result, bekam: %v", events)
	}
}

func TestRunToolLoopStopsAtIterationCap(t *testing.T) {
	root := t.TempDir()
	callCount := 0
	chatTurn := func(convo []Message, systemPrompt string, filterEmit func(string) error) (string, error) {
		callCount++
		return `<tool_call>{"name":"list_dir","arguments":{"path":"."}}</tool_call>`, nil
	}

	final, err := runToolLoop(context.Background(), nil, "", []string{root}, nil, nil, chatTurn, nil, "", ContextBudget{})
	if err != nil {
		t.Fatalf("runToolLoop: %v", err)
	}
	if callCount != maxToolLoopIterations {
		t.Fatalf("erwartete genau %d Modell-Aufrufe, bekam %d", maxToolLoopIterations, callCount)
	}
	if !strings.Contains(final, "Schrittlimit") {
		t.Fatalf("Abschlussnachricht sollte das Limit erwaehnen, war: %q", final)
	}
}

func TestRunToolLoopRejectsMissingRoot(t *testing.T) {
	_, err := runToolLoop(context.Background(), nil, "", []string{"   "}, nil, nil,
		func(convo []Message, systemPrompt string, filterEmit func(string) error) (string, error) {
			t.Fatalf("chatTurn darf ohne gueltigen Root nicht aufgerufen werden")
			return "", nil
		}, nil, "", ContextBudget{})
	if err == nil {
		t.Fatalf("erwartete Fehler bei leerem Root")
	}
}
