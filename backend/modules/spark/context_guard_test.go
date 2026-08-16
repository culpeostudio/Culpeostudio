package spark

import (
	"context"
	"strings"
	"testing"
)

// A tool result as driveToolLoop writes it, long enough to matter.
func toolResult(name string, payloadChars int) Message {
	return Message{
		Role:    "user",
		Content: "[TOOL_RESULT " + name + "]\n" + strings.Repeat("x", payloadChars),
	}
}

func TestShrinkToolResultsDoesNothingWithoutABudget(t *testing.T) {
	convo := []Message{toolResult("read_file", 40000), toolResult("read_file", 40000)}
	got, shrunk := shrinkToolResults(convo, "prompt", ContextBudget{})
	if shrunk {
		t.Error("ohne bekanntes Fenster wurde gekuerzt")
	}
	if got[0].Content != convo[0].Content {
		t.Error("Inhalt ohne Budget veraendert")
	}
}

func TestShrinkToolResultsKeepsTheNewestWhole(t *testing.T) {
	// Five results of 8000 characters each are 10.000 Tokens; against a 8192er
	// window the loop may use 60 % - so this has to shrink.
	convo := []Message{{Role: "user", Content: "Lies die Dateien"}}
	for i := 0; i < 5; i++ {
		convo = append(convo,
			Message{Role: "assistant", Content: "read_file"},
			toolResult("read_file", 8000),
		)
	}
	before := estimateConversation(convo, "prompt")

	got, shrunk := shrinkToolResults(convo, "prompt", ContextBudget{LimitTokens: 8192})
	if !shrunk {
		t.Fatal("volle Schleife wurde nicht gekuerzt")
	}
	after := estimateConversation(got, "prompt")
	if after >= before {
		t.Fatalf("Kuerzen hat nichts gebracht: %d -> %d Tokens", before, after)
	}

	// The two newest results stay whole; the agent is still working on them.
	var results []string
	for _, message := range got {
		if strings.HasPrefix(message.Content, toolResultPrefix) {
			results = append(results, message.Content)
		}
	}
	if len(results) != 5 {
		t.Fatalf("%d Ergebnisse, want 5 - es darf keines verschwinden", len(results))
	}
	for _, whole := range results[len(results)-toolResultsKeptVerbatim:] {
		if strings.Contains(whole, shortenedMarker) {
			t.Error("das juengste Ergebnis wurde gekuerzt")
		}
	}
	if !strings.Contains(results[0], shortenedMarker) {
		t.Error("das aelteste Ergebnis wurde nicht gekuerzt")
	}
	// A shortened result still says which tool it came from.
	if !strings.HasPrefix(results[0], "[TOOL_RESULT read_file]") {
		t.Errorf("Kopfzeile ging verloren: %q", results[0][:40])
	}
}

func TestShrinkToolResultsLeavesASmallConversationAlone(t *testing.T) {
	convo := []Message{toolResult("read_file", 100)}
	if _, shrunk := shrinkToolResults(convo, "prompt", ContextBudget{LimitTokens: 131072}); shrunk {
		t.Error("kurze Unterhaltung wurde gekuerzt")
	}
}

// A model that keeps calling a tool that returns a lot: without the guard this
// is the run that grows past the window and dies on a provider refusal.
func TestToolLoopShrinksInsteadOfOverrunningTheWindow(t *testing.T) {
	longest := 0
	chatTurn := func(convo []Message, systemPrompt string, emit func(string) error) (string, error) {
		if size := estimateConversation(convo, systemPrompt); size > longest {
			longest = size
		}
		if len(convo) > 12 {
			return "Fertig.", nil
		}
		return `<tool_call>{"name":"read_file","arguments":{"path":"a.txt"}}</tool_call>`, nil
	}
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		return map[string]interface{}{"ok": true, "content": strings.Repeat("y", 20000)}
	}

	budget := ContextBudget{LimitTokens: 32768, Source: "local"}
	reply, err := driveToolLoop(context.Background(), nil, "prompt", nil, nil, chatTurn, dispatch, 12, budget)
	if err != nil {
		t.Fatalf("driveToolLoop: %v", err)
	}
	if reply != "Fertig." {
		t.Fatalf("Antwort = %q, want die fertige Antwort", reply)
	}
	if longest > budget.LimitTokens {
		t.Errorf("Unterhaltung wuchs auf %d Tokens, Fenster ist %d", longest, budget.LimitTokens)
	}
}

func TestToolLoopReportsUsageWhileItWorks(t *testing.T) {
	calls := 0
	chatTurn := func(convo []Message, systemPrompt string, emit func(string) error) (string, error) {
		calls++
		if calls > 3 {
			return "Fertig.", nil
		}
		return `<tool_call>{"name":"read_file","arguments":{"path":"a.txt"}}</tool_call>`, nil
	}
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		return map[string]interface{}{"ok": true, "content": "kurz"}
	}

	readings := 0
	emitEvent := func(eventType string, data interface{}) error {
		if eventType == "context_usage" {
			readings++
			payload, _ := data.(map[string]interface{})
			if payload["limit_tokens"] != 32768 {
				t.Errorf("Messung ohne Limit: %+v", payload)
			}
			if payload["source"] != "local" {
				t.Errorf("Messung ohne Quelle: %+v", payload)
			}
		}
		return nil
	}

	_, err := driveToolLoop(context.Background(), nil, "prompt", nil, emitEvent, chatTurn, dispatch, 12,
		ContextBudget{LimitTokens: 32768, Source: "local"})
	if err != nil {
		t.Fatalf("driveToolLoop: %v", err)
	}
	// One before every model call, so the meter moves with the run.
	if readings != calls {
		t.Errorf("%d Messungen bei %d Modell-Aufrufen", readings, calls)
	}
}
