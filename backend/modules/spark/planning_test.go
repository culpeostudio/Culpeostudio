package spark

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/culpeohq/backend/internal/agentplan"
)

type fakeModel struct {
	replies []string
	calls   int
	prompts []string
	convos  [][]Message
}

func (f *fakeModel) turn(convo []Message, systemPrompt string, filterEmit func(string) error) (string, error) {
	f.prompts = append(f.prompts, systemPrompt)
	f.convos = append(f.convos, append([]Message{}, convo...))
	reply := "fertig"
	if f.calls < len(f.replies) {
		reply = f.replies[f.calls]
	}
	f.calls++
	if filterEmit != nil {
		_ = filterEmit(reply)
	}
	return reply, nil
}

func TestPlanRunnerProposeLegtPlanVor(t *testing.T) {
	model := &fakeModel{replies: []string{
		`{"summary":"Zwei Schritte","steps":[{"title":"Lesen"},{"title":"Schreiben"}]}`,
	}}
	var events []string
	var planData map[string]interface{}
	var visible strings.Builder

	runner := &planRunner{
		chatTurn: model.turn,
		emitText: func(s string) error { visible.WriteString(s); return nil },
		emitEvent: func(eventType string, data interface{}) error {
			events = append(events, eventType)
			if eventType == "plan_ready" {
				if m, ok := data.(map[string]interface{}); ok {
					planData, _ = m["planning"].(map[string]interface{})
				}
			}
			return nil
		},
		sessionID: "sess-1",
	}

	plan, err := runner.propose(context.Background(), "Datei umbauen")
	if err != nil {
		t.Fatalf("propose: %v", err)
	}
	if len(plan.Steps) != 2 {
		t.Fatalf("erwartete 2 Schritte, bekam %d", len(plan.Steps))
	}
	if len(events) != 1 || events[0] != "plan_ready" {
		t.Fatalf("erwartete plan_ready, bekam %v", events)
	}
	if planData == nil || planData["plan_summary"] != "Zwei Schritte" {
		t.Fatalf("Event-Daten unvollstaendig: %v", planData)
	}
	steps, _ := planData["steps"].([]string)
	if len(steps) != 2 || steps[0] != "1. Lesen" {
		t.Fatalf("Schritt-Titel im Event falsch: %v", planData["steps"])
	}

	if strings.Contains(visible.String(), "summary") {
		t.Errorf("Plan-JSON sollte nicht sichtbar gestreamt werden: %q", visible.String())
	}
}

func TestPlanRunnerProposeMeldetUnbrauchbareAntwort(t *testing.T) {
	model := &fakeModel{replies: []string{"Ich weiss nicht, was du willst."}}
	runner := &planRunner{chatTurn: model.turn, sessionID: "sess-1"}

	if _, err := runner.propose(context.Background(), "???"); err == nil {
		t.Fatal("erwartete einen Fehler bei unbrauchbarer Antwort")
	}
}

func TestPlanRunnerExecuteArbeitetSchritteAb(t *testing.T) {
	model := &fakeModel{replies: []string{
		"Schritt eins erledigt",
		"Schritt zwei erledigt",
		"Alles fertig, hier der Bericht.",
	}}
	var events []string
	var visible strings.Builder

	runner := &planRunner{
		chatTurn: model.turn,
		emitText: func(s string) error { visible.WriteString(s); return nil },
		emitEvent: func(eventType string, data interface{}) error {
			events = append(events, eventType)
			return nil
		},
		sessionID: "sess-1",
	}

	plan := &agentplan.Plan{
		Goal:    "Ziel",
		Summary: "S",
		Steps: []agentplan.Step{
			{Number: 1, Title: "Erst", Status: agentplan.StatusPending},
			{Number: 2, Title: "Dann", Status: agentplan.StatusPending},
		},
	}

	report, err := runner.execute(context.Background(), plan)
	if err != nil {
		t.Fatalf("execute: %v", err)
	}
	if model.calls != 3 {
		t.Fatalf("erwartete 2 Schritte + 1 Bericht = 3 Modell-Aufrufe, bekam %d", model.calls)
	}
	for _, step := range plan.Steps {
		if step.Status != agentplan.StatusDone {
			t.Errorf("Schritt %d hat Status %q", step.Number, step.Status)
		}
		if step.Result == "" {
			t.Errorf("Schritt %d hat kein Ergebnis", step.Number)
		}
	}
	if report != "Alles fertig, hier der Bericht." {
		t.Errorf("Bericht = %q", report)
	}

	if visible.String() != "Alles fertig, hier der Bericht." {
		t.Errorf("sichtbarer Text = %q", visible.String())
	}

	var starts, results int
	for _, e := range events {
		switch e {
		case "plan_step_start":
			starts++
		case "plan_step_result":
			results++
		}
	}
	if starts != 2 || results != 2 {
		t.Errorf("erwartete 2 start- und 2 result-Events, bekam %d/%d (%v)", starts, results, events)
	}
}

func TestPlanRunnerExecuteGibtErgebnisWeiter(t *testing.T) {
	model := &fakeModel{replies: []string{
		"Der Timeout steht auf 10 Sekunden",
		"Auf 30 gesetzt",
		"Bericht",
	}}
	runner := &planRunner{chatTurn: model.turn, sessionID: "s"}
	plan := &agentplan.Plan{
		Goal: "Timeout erhoehen",
		Steps: []agentplan.Step{
			{Number: 1, Title: "Lesen", Status: agentplan.StatusPending},
			{Number: 2, Title: "Setzen", Status: agentplan.StatusPending},
		},
	}
	if _, err := runner.execute(context.Background(), plan); err != nil {
		t.Fatalf("execute: %v", err)
	}
	if len(model.prompts) < 2 {
		t.Fatalf("zu wenige Aufrufe: %d", len(model.prompts))
	}
	if !strings.Contains(model.prompts[1], "Der Timeout steht auf 10 Sekunden") {
		t.Error("Ergebnis von Schritt 1 fehlt im Prompt von Schritt 2")
	}

	if len(model.convos[1]) != 1 {
		t.Errorf("Schritt 2 sollte mit frischem Kontext starten, hatte %d Nachrichten", len(model.convos[1]))
	}
}

func TestPlanRunnerExecuteLehntLeerenPlanAb(t *testing.T) {
	runner := &planRunner{chatTurn: (&fakeModel{}).turn, sessionID: "s"}
	if _, err := runner.execute(context.Background(), nil); err == nil {
		t.Error("nil-Plan sollte einen Fehler liefern")
	}
	if _, err := runner.execute(context.Background(), &agentplan.Plan{}); err == nil {
		t.Error("leerer Plan sollte einen Fehler liefern")
	}
}

func TestPlanRunnerExecuteBrichtNachFehlerAb(t *testing.T) {
	runner := &planRunner{
		chatTurn: func(convo []Message, prompt string, filterEmit func(string) error) (string, error) {
			if strings.Contains(prompt, "Abschlussbericht") {
				return "Bericht", nil
			}
			return "", context.DeadlineExceeded
		},
		sessionID: "s",
	}
	plan := &agentplan.Plan{
		Goal: "Ziel",
		Steps: []agentplan.Step{
			{Number: 1, Title: "Erst", Status: agentplan.StatusPending},
			{Number: 2, Title: "Dann", Status: agentplan.StatusPending},
		},
	}
	if _, err := runner.execute(context.Background(), plan); err != nil {
		t.Fatalf("execute sollte den Bericht trotzdem liefern: %v", err)
	}
	if plan.Steps[0].Status != agentplan.StatusFailed {
		t.Errorf("Schritt 1 sollte als fehlgeschlagen markiert sein, ist %q", plan.Steps[0].Status)
	}
	if plan.Steps[1].Status != agentplan.StatusPending {
		t.Errorf("Schritt 2 sollte nicht mehr ausgefuehrt werden, ist %q", plan.Steps[1].Status)
	}
}

func TestPlanRunnerExecuteBrichtBeiAbbruchAb(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	model := &fakeModel{}
	runner := &planRunner{chatTurn: model.turn, sessionID: "s"}
	plan := &agentplan.Plan{
		Goal:  "Ziel",
		Steps: []agentplan.Step{{Number: 1, Title: "Erst", Status: agentplan.StatusPending}},
	}
	if _, err := runner.execute(ctx, plan); err == nil {
		t.Error("abgebrochener Kontext sollte einen Fehler liefern")
	}
	if model.calls != 0 {
		t.Errorf("bei abgebrochenem Kontext darf kein Modell-Aufruf erfolgen, waren %d", model.calls)
	}
}

func TestPreviewLine(t *testing.T) {
	if got := previewLine("  a\nb  ", 100); got != "a b" {
		t.Errorf("previewLine = %q, erwartet %q", got, "a b")
	}
	got := previewLine(strings.Repeat("x", 50), 10)
	if !strings.HasSuffix(got, "…") || len([]rune(got)) != 11 {
		t.Errorf("previewLine = %q", got)
	}
}

func TestPlanRunnerProposeReichtRueckfragenDurch(t *testing.T) {
	model := &fakeModel{replies: []string{
		`{"reason":"Mir fehlt das Zielformat","questions":["JSON oder YAML?"]}`,
	}}
	var events []string
	runner := &planRunner{
		chatTurn:  model.turn,
		emitEvent: func(eventType string, data interface{}) error { events = append(events, eventType); return nil },
		sessionID: "s",
	}

	_, err := runner.propose(context.Background(), "Export bauen")
	var questions *planQuestionsError
	if !errors.As(err, &questions) {
		t.Fatalf("erwartete planQuestionsError, bekam %v", err)
	}
	if len(questions.questions.Items) != 1 || questions.questions.Items[0] != "JSON oder YAML?" {
		t.Fatalf("Fragen falsch durchgereicht: %+v", questions.questions)
	}

	for _, e := range events {
		if e == "plan_ready" {
			t.Error("plan_ready darf bei Rueckfragen nicht kommen")
		}
	}
}
