package philobot

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"

	"github.com/fillyengine/backend/internal/agentplan"
)

// maxPlanStepIterations begrenzt die Werkzeug-Runden eines einzelnen
// Planschritts.
//
// Ein Schritt braucht regelmaessig mehrere Runden nur zum Orientieren
// (suchen, auflisten, lesen), bevor er zur eigentlichen Aenderung kommt.
// Mit einem zu knappen Budget verpufft die Arbeit genau davor. Gegen ein
// im Kreis laufendes Modell schuetzt maxConsecutiveToolFailures, nicht
// dieses Limit.
const maxPlanStepIterations = 14

// planRunner buendelt alles, was die Planungs- und Ausfuehrungsphase vom
// aufrufenden Chat-Fluss braucht. Die Modell-Runde kommt als Funktion
// herein, damit der Ablauf ohne echtes Modell testbar bleibt.
type planRunner struct {
	// chatTurn fuehrt eine Modell-Runde aus.
	chatTurn chatTurnFunc
	// emitText streamt sichtbaren Text an den Nutzer.
	emitText func(string) error
	// emitEvent meldet Fortschritt ans Frontend (plan_ready, step_start, ...).
	emitEvent func(eventType string, data interface{}) error
	// roots sind die freigegebenen Projekt-Pfade; leer = nur Web-Werkzeuge.
	roots []string
	// asker vermittelt Erlaubnis-Anfragen bei Zugriffen ausserhalb der Roots.
	asker permissionAsker
	// sessionID wird in die Frontend-Events eingebettet.
	sessionID string
}

// hasFileTools meldet, ob in dieser Sitzung Datei-Werkzeuge zur Verfuegung
// stehen.
func (r *planRunner) hasFileTools() bool { return len(r.roots) > 0 }

// propose laesst das Modell die Aufgabe zerlegen und legt den Plan zur
// Freigabe vor. Der Plan wird zurueckgegeben, damit der Aufrufer ihn in
// der Session ablegen kann; ausgefuehrt wird hier noch nichts.
//
// Schlaegt das Zerlegen fehl, ist das kein Abbruch: der Aufrufer faellt
// dann auf die normale Beantwortung zurueck. Eine Aufgabe, die sich
// nicht planen laesst, soll den Nutzer nicht mit einer Fehlermeldung
// abspeisen.
func (r *planRunner) propose(ctx context.Context, goal string) (*agentplan.Plan, error) {
	prompt := agentplan.DecomposePrompt(goal, r.hasFileTools())

	// Der Plan selbst gehoert nicht in den Chat: der Nutzer sieht ihn im
	// Freigabe-Panel, nicht als JSON-Block im Verlauf.
	var raw strings.Builder
	silent := func(chunk string) error { raw.WriteString(chunk); return nil }

	reply, err := r.chatTurn(
		[]chatMessage{{Role: "user", Content: goal}},
		prompt,
		silent,
	)
	if err != nil {
		return nil, err
	}
	if strings.TrimSpace(reply) == "" {
		reply = raw.String()
	}

	result, err := agentplan.Parse(goal, reply)
	if err != nil {
		log.Printf("[philobot] Plan konnte nicht gelesen werden: %v", err)
		return nil, err
	}
	if result.NeedsAnswers() {
		return nil, &planQuestionsError{questions: result.Questions}
	}

	plan := result.Plan
	if r.emitEvent != nil {
		_ = r.emitEvent("plan_ready", map[string]interface{}{
			"session_id": r.sessionID,
			"planning": map[string]interface{}{
				"plan_summary": plan.Summary,
				"steps":        plan.StepTitles(),
			},
		})
	}
	log.Printf("[philobot] Plan vorgelegt (%d Schritte, session=%s)", len(plan.Steps), r.sessionID)
	return &plan, nil
}

// planQuestionsError meldet, dass das Modell nachfragt statt zu planen.
// Kein Fehler im eigentlichen Sinn, sondern ein zweites Ergebnis der
// Planungsrunde — Go's Fehlerkanal ist hier der einfachste Weg, es
// durch propose hindurchzureichen.
type planQuestionsError struct {
	questions agentplan.Questions
}

func (e *planQuestionsError) Error() string {
	return "philobot: das Modell hat Rueckfragen zur Aufgabe"
}

// execute arbeitet einen freigegebenen Plan Schritt fuer Schritt ab und
// liefert den Abschlussbericht.
//
// Jeder Schritt laeuft als eigener Agent mit frischem Kontext: er sieht
// das Ziel, seinen Auftrag und die Ergebnisse der Vorschritte - nicht
// aber die Chat-Historie oder die Werkzeug-Protokolle der anderen
// Schritte. Das haelt den Kontext klein und die Schritte unabhaengig.
func (r *planRunner) execute(ctx context.Context, plan *agentplan.Plan) (string, error) {
	if plan == nil || plan.IsEmpty() {
		return "", fmt.Errorf("philobot: kein Plan zum Ausfuehren")
	}

	for i := range plan.Steps {
		step := &plan.Steps[i]
		if err := ctx.Err(); err != nil {
			step.Status = agentplan.StatusFailed
			step.Result = "abgebrochen"
			return "", err
		}

		step.Status = agentplan.StatusRunning
		r.emitStep("plan_step_start", *step, len(plan.Steps), "")

		result, err := r.runStep(ctx, *plan, *step)
		if err != nil {
			step.Status = agentplan.StatusFailed
			// Bei einem Abbruch am Rundenbudget ist der bis dahin erarbeitete
			// Text die einzige Spur davon, wie weit der Schritt kam.
			if errors.Is(err, errToolLoopExhausted) {
				step.Result = "Abgebrochen ohne Abschluss: " + strings.TrimSpace(result)
			} else {
				step.Result = "Fehler: " + err.Error()
			}
			r.emitStep("plan_step_result", *step, len(plan.Steps), step.Result)
			log.Printf("[philobot] Planschritt %d fehlgeschlagen: %v", step.Number, err)
			// Weiterlaufen waere geraten: die folgenden Schritte bauen in
			// aller Regel auf diesem auf.
			break
		}

		step.Status = agentplan.StatusDone
		step.Result = strings.TrimSpace(result)
		r.emitStep("plan_step_result", *step, len(plan.Steps), step.Result)
		log.Printf("[philobot] Planschritt %d erledigt (session=%s)", step.Number, r.sessionID)
	}

	return r.report(ctx, *plan)
}

// runStep fuehrt einen einzelnen Schritt in einer eigenen Werkzeug-
// Schleife aus. Der sichtbare Text bleibt unterdrueckt: der Nutzer
// bekommt den Abschlussbericht, nicht die Selbstgespraeche jedes
// Subagenten.
func (r *planRunner) runStep(ctx context.Context, plan agentplan.Plan, step agentplan.Step) (string, error) {
	prompt := agentplan.StepPrompt(plan, step)
	history := []chatMessage{{
		Role:    "user",
		Content: fmt.Sprintf("Fuehre Schritt %d aus: %s", step.Number, step.Title),
	}}

	// Zwischenstaende landen im Puffer statt im Chat.
	var buf strings.Builder
	quiet := func(chunk string) error { buf.WriteString(chunk); return nil }

	if r.hasFileTools() {
		return runToolLoopWithLimit(ctx, history, prompt, r.roots, quiet, r.emitEvent,
			r.chatTurn, r.asker, r.sessionID, maxPlanStepIterations)
	}
	return runWebOnlyToolLoopWithLimit(ctx, history, prompt, quiet, r.emitEvent,
		r.chatTurn, maxPlanStepIterations)
}

// report laesst das Modell den Verlauf fuer den Nutzer zusammenfassen.
// Dieser Text ist der einzige, der sichtbar im Chat landet.
func (r *planRunner) report(ctx context.Context, plan agentplan.Plan) (string, error) {
	filter := newToolCallStreamFilter(r.emitText)
	reply, err := r.chatTurn(
		[]chatMessage{{Role: "user", Content: "Fasse das Ergebnis zusammen."}},
		agentplan.ReportPrompt(plan),
		filter.Emit,
	)
	if err != nil {
		return "", err
	}
	if err := filter.Flush(); err != nil {
		return "", err
	}
	return reply, nil
}

// emitStep meldet den Fortschritt eines Schritts ans Frontend.
func (r *planRunner) emitStep(eventType string, step agentplan.Step, total int, result string) {
	if r.emitEvent == nil {
		return
	}
	data := map[string]interface{}{
		"session_id": r.sessionID,
		"step":       step.Number,
		"total":      total,
		"title":      step.Title,
		"status":     step.Status,
	}
	if result != "" {
		data["result"] = previewLine(result, 400)
	}
	_ = r.emitEvent(eventType, data)
}

// previewLine kuerzt einen Text auf eine Vorschau fuer Frontend-Events.
func previewLine(s string, limit int) string {
	s = strings.TrimSpace(strings.ReplaceAll(s, "\n", " "))
	runes := []rune(s)
	if len(runes) <= limit {
		return s
	}
	return strings.TrimSpace(string(runes[:limit])) + "…"
}
