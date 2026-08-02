package philobot

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"

	"github.com/fillyengine/backend/internal/agentplan"
)

const maxPlanStepIterations = 14

type planRunner struct {
	chatTurn chatTurnFunc

	emitText func(string) error

	emitEvent func(eventType string, data interface{}) error

	roots []string

	asker permissionAsker

	sessionID string
}

func (r *planRunner) hasFileTools() bool { return len(r.roots) > 0 }

func (r *planRunner) propose(ctx context.Context, goal string) (*agentplan.Plan, error) {
	prompt := agentplan.DecomposePrompt(goal, r.hasFileTools())

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

type planQuestionsError struct {
	questions agentplan.Questions
}

func (e *planQuestionsError) Error() string {
	return "philobot: das Modell hat Rueckfragen zur Aufgabe"
}

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

			if errors.Is(err, errToolLoopExhausted) {
				step.Result = "Abgebrochen ohne Abschluss: " + strings.TrimSpace(result)
			} else {
				step.Result = "Fehler: " + err.Error()
			}
			r.emitStep("plan_step_result", *step, len(plan.Steps), step.Result)
			log.Printf("[philobot] Planschritt %d fehlgeschlagen: %v", step.Number, err)

			break
		}

		step.Status = agentplan.StatusDone
		step.Result = strings.TrimSpace(result)
		r.emitStep("plan_step_result", *step, len(plan.Steps), step.Result)
		log.Printf("[philobot] Planschritt %d erledigt (session=%s)", step.Number, r.sessionID)
	}

	return r.report(ctx, *plan)
}

func (r *planRunner) runStep(ctx context.Context, plan agentplan.Plan, step agentplan.Step) (string, error) {
	prompt := agentplan.StepPrompt(plan, step)
	history := []chatMessage{{
		Role:    "user",
		Content: fmt.Sprintf("Fuehre Schritt %d aus: %s", step.Number, step.Title),
	}}

	var buf strings.Builder
	quiet := func(chunk string) error { buf.WriteString(chunk); return nil }

	if r.hasFileTools() {
		return runToolLoopWithLimit(ctx, history, prompt, r.roots, quiet, r.emitEvent,
			r.chatTurn, r.asker, r.sessionID, maxPlanStepIterations)
	}
	return runWebOnlyToolLoopWithLimit(ctx, history, prompt, quiet, r.emitEvent,
		r.chatTurn, maxPlanStepIterations)
}

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

func previewLine(s string, limit int) string {
	s = strings.TrimSpace(strings.ReplaceAll(s, "\n", " "))
	runes := []rune(s)
	if len(runes) <= limit {
		return s
	}
	return strings.TrimSpace(string(runes[:limit])) + "…"
}
