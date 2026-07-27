package philobot

import (
	"context"
	"errors"
	"strings"
	"testing"
)

// TestWebOnlyLoopRejectsFileTools stellt sicher, dass ein Modell ohne
// Projekt-Kontext keine Datei-Werkzeuge bekommt: der Aufruf muss als
// Fehler zurueckkommen, nicht auf die Platte durchschlagen.
func TestWebOnlyLoopRejectsFileTools(t *testing.T) {
	var results []string
	callCount := 0
	chatTurn := func(convo []chatMessage, systemPrompt string, filterEmit func(string) error) (string, error) {
		callCount++
		if callCount == 1 {
			return `<tool_call>{"name":"read_file","arguments":{"path":"/etc/passwd"}}</tool_call>`, nil
		}
		// Das Tool-Ergebnis der ersten Runde steckt in der letzten Nachricht.
		results = append(results, convo[len(convo)-1].Content)
		return "Ich kann ohne Projekt keine Dateien lesen.", nil
	}

	final, err := runWebOnlyToolLoop(context.Background(), nil, "Basis-Prompt", nil, nil, chatTurn)
	if err != nil {
		t.Fatalf("runWebOnlyToolLoop: %v", err)
	}
	if callCount != 2 {
		t.Fatalf("erwartete 2 Modell-Runden, bekam %d", callCount)
	}
	if len(results) != 1 || !strings.Contains(results[0], "tool_unavailable") {
		t.Fatalf("Datei-Tool sollte als tool_unavailable abgewiesen werden, bekam: %v", results)
	}
	if final != "Ich kann ohne Projekt keine Dateien lesen." {
		t.Fatalf("unerwartete Endantwort: %q", final)
	}
}

// TestWebOnlyLoopPassesThroughPlainAnswer prueft den Normalfall: das Modell
// entscheidet, dass keine Recherche noetig ist, und antwortet direkt.
func TestWebOnlyLoopPassesThroughPlainAnswer(t *testing.T) {
	var visible strings.Builder
	chatTurn := func(convo []chatMessage, systemPrompt string, filterEmit func(string) error) (string, error) {
		if !strings.Contains(systemPrompt, "web_search") {
			t.Error("System-Prompt sollte die Web-Werkzeuge nennen")
		}
		if strings.Contains(systemPrompt, "Datei-Werkzeuge") {
			t.Error("System-Prompt darf ohne Projekt keine Datei-Werkzeuge nennen")
		}
		const answer = "2 plus 2 ergibt 4."
		_ = filterEmit(answer)
		return answer, nil
	}

	final, err := runWebOnlyToolLoop(context.Background(), nil, "Basis-Prompt",
		func(s string) error { visible.WriteString(s); return nil }, nil, chatTurn)
	if err != nil {
		t.Fatalf("runWebOnlyToolLoop: %v", err)
	}
	if final != "2 plus 2 ergibt 4." {
		t.Fatalf("unerwartete Endantwort: %q", final)
	}
	if visible.String() != "2 plus 2 ergibt 4." {
		t.Fatalf("sichtbarer Text falsch: %q", visible.String())
	}
}

// TestWebOnlySystemPromptStructure sichert die Bestandteile, auf die sich das
// Modell verlaesst: Werkzeugliste, Abwaege-Kriterien und Aufruf-Protokoll.
func TestWebOnlySystemPromptStructure(t *testing.T) {
	prompt := buildWebOnlySystemPrompt("Du bist PhiloBot.")
	for _, want := range []string{"Du bist PhiloBot.", "web_search", "web_fetch", "Wann du NICHT suchen sollst", toolCallOpen} {
		if !strings.Contains(prompt, want) {
			t.Errorf("Prompt enthaelt %q nicht", want)
		}
	}
}

// TestProjectPromptOffersBothToolsets: im Projekt-Modus muss beides drinstehen.
func TestProjectPromptOffersBothToolsets(t *testing.T) {
	prompt := buildToolLoopSystemPrompt("Basis", []string{"/tmp/projekt"})
	for _, want := range []string{"read_file", "web_search", "/tmp/projekt"} {
		if !strings.Contains(prompt, want) {
			t.Errorf("Projekt-Prompt enthaelt %q nicht", want)
		}
	}
}

// TestToolLoopBrichtBeiWiederholtemFehlerAb: ein Modell, das dreimal am
// selben Werkzeug scheitert, verbraucht sonst das ganze Rundenbudget.
func TestToolLoopBrichtBeiWiederholtemFehlerAb(t *testing.T) {
	calls := 0
	chatTurn := func(convo []chatMessage, systemPrompt string, filterEmit func(string) error) (string, error) {
		calls++
		return `<tool_call>{"name":"kaputt","arguments":{}}</tool_call>`, nil
	}
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		return map[string]interface{}{"ok": false, "error": "geht nicht"}
	}

	reply, err := driveToolLoop(context.Background(), nil, "prompt", nil, nil, chatTurn, dispatch, 20)
	if !errors.Is(err, errToolLoopExhausted) {
		t.Fatalf("erwartete errToolLoopExhausted, bekam %v", err)
	}
	if calls != maxConsecutiveToolFailures {
		t.Fatalf("erwartete Abbruch nach %d Versuchen, bekam %d", maxConsecutiveToolFailures, calls)
	}
	if !strings.Contains(reply, "fehlgeschlagen") {
		t.Errorf("Abbruchmeldung sollte den Grund nennen: %q", reply)
	}
}

// TestToolLoopZaehlerSetztBeiErfolgZurueck: vereinzelte Fehlschlaege
// zwischen erfolgreichen Aufrufen duerfen nicht zum Abbruch fuehren.
func TestToolLoopZaehlerSetztBeiErfolgZurueck(t *testing.T) {
	calls := 0
	chatTurn := func(convo []chatMessage, systemPrompt string, filterEmit func(string) error) (string, error) {
		calls++
		if calls > 6 {
			return "fertig", nil
		}
		return `<tool_call>{"name":"wechselhaft","arguments":{}}</tool_call>`, nil
	}
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		// Jeder zweite Aufruf klappt.
		return map[string]interface{}{"ok": calls%2 == 0, "error": "mal so mal so"}
	}

	if _, err := driveToolLoop(context.Background(), nil, "prompt", nil, nil, chatTurn, dispatch, 20); err != nil {
		t.Fatalf("abwechselnde Fehlschlaege sollten nicht abbrechen: %v", err)
	}
}

// TestToolLoopMeldetIterationslimit stellt sicher, dass das Rundenlimit als
// Abbruch erkennbar ist — ein Planschritt darf dann nicht als erledigt gelten.
func TestToolLoopMeldetIterationslimit(t *testing.T) {
	chatTurn := func(convo []chatMessage, systemPrompt string, filterEmit func(string) error) (string, error) {
		return `<tool_call>{"name":"endlos","arguments":{}}</tool_call>`, nil
	}
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		return map[string]interface{}{"ok": true}
	}

	_, err := driveToolLoop(context.Background(), nil, "prompt", nil, nil, chatTurn, dispatch, 3)
	if !errors.Is(err, errToolLoopExhausted) {
		t.Fatalf("erwartete errToolLoopExhausted, bekam %v", err)
	}
}

// TestSwallowExhausted: im freien Chat ist ein Abbruch kein Fehler.
func TestSwallowExhausted(t *testing.T) {
	reply, err := swallowExhausted("teilergebnis", errToolLoopExhausted)
	if err != nil || reply != "teilergebnis" {
		t.Fatalf("swallowExhausted = (%q, %v), erwartet den Text ohne Fehler", reply, err)
	}
	if _, err := swallowExhausted("x", context.DeadlineExceeded); err == nil {
		t.Error("andere Fehler muessen durchgereicht werden")
	}
}
