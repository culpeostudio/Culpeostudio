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
	detailed, _ := planData["plan_steps"].([]map[string]interface{})
	if len(detailed) != 2 || detailed[1]["number"] != 2 || detailed[1]["title"] != "Schreiben" {
		t.Fatalf("Schrittliste im Event falsch: %v", planData["plan_steps"])
	}

	if strings.Contains(visible.String(), "summary") {
		t.Errorf("Plan-JSON sollte nicht sichtbar gestreamt werden: %q", visible.String())
	}
}

func TestPlanRunnerProposeGibtDasGespraechMit(t *testing.T) {
	model := &fakeModel{replies: []string{
		`{"summary":"Eins","steps":[{"title":"Export bauen"}]}`,
	}}
	runner := &planRunner{
		chatTurn: model.turn,
		history: []Message{
			{Role: "user", Content: "Das Projekt liegt in /tmp/demo"},
			{Role: "assistant", Content: "Verstanden."},
			{Role: "user", Content: "Bau den Export"},
		},
		projectPath: "/tmp/demo",
		roots:       []string{"/tmp/demo"},
		sessionID:   "s",
	}

	if _, err := runner.propose(context.Background(), "Bau den Export"); err != nil {
		t.Fatalf("propose: %v", err)
	}

	convo := model.convos[0]
	if len(convo) != 3 {
		t.Fatalf("Planung braucht das Gespraech, bekam %d Nachrichten: %+v", len(convo), convo)
	}
	if convo[0].Content != "Das Projekt liegt in /tmp/demo" {
		t.Errorf("frueherer Kontext fehlt: %+v", convo[0])
	}
	if last := convo[len(convo)-1]; last.Role != "user" || last.Content != "Bau den Export" {
		t.Errorf("die Aufgabe muss das letzte Wort haben, war %+v", last)
	}
	if !strings.Contains(model.prompts[0], "/tmp/demo") {
		t.Error("der gebundene Projekt-Ordner fehlt im Planungs-Prompt")
	}
}

func TestPlanningConversationKuerztUndEntdoppelt(t *testing.T) {
	var history []Message
	for i := 0; i < 12; i++ {
		history = append(history, Message{Role: "user", Content: strings.Repeat("x", 40)})
	}
	history = append(history,
		Message{Role: "assistant", Content: strings.Repeat("y", maxPlanContextChars+200)},
		Message{Role: "user", Content: "Letzte Aufgabe"},
	)

	convo := planningConversation(history, "Letzte Aufgabe")

	if len(convo) != maxPlanContextMessages+1 {
		t.Fatalf("erwartete %d Nachrichten, bekam %d", maxPlanContextMessages+1, len(convo))
	}
	if last := convo[len(convo)-1]; last.Content != "Letzte Aufgabe" {
		t.Errorf("die Aufgabe darf nicht doppelt am Ende stehen: %+v", convo[len(convo)-2:])
	}
	long := convo[len(convo)-2]
	if len([]rune(long.Content)) > maxPlanContextChars+1 {
		t.Errorf("lange Nachricht wurde nicht gekuerzt: %d Zeichen", len([]rune(long.Content)))
	}
}

func TestPlanningConversationOhneVerlauf(t *testing.T) {
	convo := planningConversation(nil, "  Nur die Aufgabe  ")
	if len(convo) != 1 || convo[0].Content != "Nur die Aufgabe" {
		t.Fatalf("ohne Verlauf bleibt nur die Aufgabe, bekam %+v", convo)
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

func TestPlanRunnerExecuteRahmtDieAbarbeitungEin(t *testing.T) {
	model := &fakeModel{replies: []string{"eins", "zwei", "Bericht"}}
	var events []string
	var started, finished map[string]interface{}

	runner := &planRunner{
		chatTurn: model.turn,
		emitEvent: func(eventType string, data interface{}) error {
			events = append(events, eventType)
			payload, _ := data.(map[string]interface{})
			switch eventType {
			case "plan_started":
				started = payload
			case "plan_finished":
				finished = payload
			}
			return nil
		},
		sessionID: "s",
	}
	plan := &agentplan.Plan{
		Goal:    "Ziel",
		Summary: "S",
		Steps: []agentplan.Step{
			{Number: 1, Title: "Erst", Detail: "Datei lesen", Status: agentplan.StatusPending},
			{Number: 2, Title: "Dann", Status: agentplan.StatusPending},
		},
	}

	if _, err := runner.execute(context.Background(), plan); err != nil {
		t.Fatalf("execute: %v", err)
	}

	if len(events) == 0 || events[0] != "plan_started" {
		t.Fatalf("plan_started muss vor dem ersten Schritt kommen, bekam %v", events)
	}
	if events[len(events)-1] != "plan_finished" {
		t.Fatalf("plan_finished muss die Abarbeitung abschliessen, bekam %v", events)
	}

	planning, _ := started["planning"].(map[string]interface{})
	steps, _ := planning["plan_steps"].([]map[string]interface{})
	if len(steps) != 2 {
		t.Fatalf("plan_started ohne vollstaendige Liste: %v", planning["plan_steps"])
	}
	if steps[0]["detail"] != "Datei lesen" || steps[0]["status"] != agentplan.StatusPending {
		t.Errorf("erster Schritt im Startereignis falsch: %v", steps[0])
	}

	if finished["done"] != 2 || finished["failed"] != 0 || finished["pending"] != 0 {
		t.Errorf("Abschlusszaehlung falsch: %v", finished)
	}
}

func TestPlanRunnerExecuteArbeitetNachEinemLimitWeiter(t *testing.T) {
	var finished map[string]interface{}
	var attempts int
	runner := &planRunner{
		chatTurn: func(convo []Message, prompt string, filterEmit func(string) error) (string, error) {
			if strings.Contains(prompt, "Abschlussbericht") {
				return "Bericht", nil
			}
			// The step's own task line, not the prompt: the prompt of step 2
			// names step 1 as well, in the list of what is already done.
			if len(convo) > 0 && strings.Contains(convo[0].Content, "Schritt 1") {
				attempts++
				return "halb fertig", errToolLoopExhausted
			}
			return "Schritt zwei erledigt", nil
		},
		emitEvent: func(eventType string, data interface{}) error {
			if eventType == "plan_finished" {
				finished, _ = data.(map[string]interface{})
			}
			return nil
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
		t.Fatalf("execute: %v", err)
	}
	if attempts != maxPlanStepAttempts {
		t.Errorf("ein Schritt am Limit braucht %d Anlaeufe, hatte %d", maxPlanStepAttempts, attempts)
	}
	if plan.Steps[0].Status != agentplan.StatusFailed {
		t.Errorf("Schritt 1 sollte als offen markiert sein, ist %q", plan.Steps[0].Status)
	}
	if plan.Steps[1].Status != agentplan.StatusDone {
		t.Errorf("Schritt 2 muss trotzdem laufen, ist %q", plan.Steps[1].Status)
	}
	if finished["failed"] != 1 || finished["done"] != 1 {
		t.Errorf("Abschlusszaehlung falsch: %v", finished)
	}
}

func TestPlanRunnerExecuteHaeltDenPlanNachHartemFehlerOffen(t *testing.T) {
	var stored *agentplan.Plan
	cleared := false
	runner := &planRunner{
		chatTurn: func(convo []Message, prompt string, filterEmit func(string) error) (string, error) {
			return "", context.DeadlineExceeded
		},
		storeActive: func(plan *agentplan.Plan) { stored = plan },
		clearActive: func() { cleared = true },
		sessionID:   "s",
	}
	plan := &agentplan.Plan{
		Goal: "Ziel",
		Steps: []agentplan.Step{
			{Number: 1, Title: "Erst", Status: agentplan.StatusPending},
			{Number: 2, Title: "Dann", Status: agentplan.StatusPending},
		},
	}

	if _, err := runner.execute(context.Background(), plan); err == nil {
		t.Fatal("ein harter Fehler muss durchgereicht werden")
	}
	if plan.Steps[0].Status != agentplan.StatusPending {
		t.Errorf("der abgebrochene Schritt muss wieder offen sein, ist %q", plan.Steps[0].Status)
	}
	if stored == nil || stored.Unfinished() != 2 {
		t.Errorf("der angefangene Plan muss hinterlegt bleiben: %+v", stored)
	}
	if cleared {
		t.Error("ein offener Plan darf nicht geloescht werden")
	}
}

func TestPlanRunnerExecuteUeberspringtGrueneSchritte(t *testing.T) {
	model := &fakeModel{replies: []string{"Schritt zwei erledigt", "Bericht"}}
	cleared := false
	var starts []int
	runner := &planRunner{
		chatTurn: model.turn,
		emitEvent: func(eventType string, data interface{}) error {
			if eventType == "plan_step_start" {
				payload, _ := data.(map[string]interface{})
				if number, ok := payload["step"].(int); ok {
					starts = append(starts, number)
				}
			}
			return nil
		},
		clearActive: func() { cleared = true },
		sessionID:   "s",
	}
	plan := &agentplan.Plan{
		Goal: "Ziel",
		Steps: []agentplan.Step{
			{Number: 1, Title: "Erst", Status: agentplan.StatusDone, Result: "war schon"},
			{Number: 2, Title: "Dann", Status: agentplan.StatusPending},
		},
	}

	if _, err := runner.execute(context.Background(), plan); err != nil {
		t.Fatalf("execute: %v", err)
	}
	if len(starts) != 1 || starts[0] != 2 {
		t.Errorf("nur der offene Schritt darf starten, gestartet wurden %v", starts)
	}
	if plan.Steps[0].Result != "war schon" {
		t.Errorf("das Ergebnis des gruenen Schritts wurde ueberschrieben: %q", plan.Steps[0].Result)
	}
	if !cleared {
		t.Error("ein vollstaendig gruener Plan muss aus der Sitzung verschwinden")
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
