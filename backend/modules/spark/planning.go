package spark

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/culpeohq/backend/modules/spark/tools"

	"github.com/culpeohq/backend/internal/agentplan"
)

const maxPlanStepIterations = 14

// A step that runs out of tool calls gets a second pass instead of taking the
// rest of the plan down with it.
const maxPlanStepAttempts = 2

type planRunner struct {
	chatTurn ChatTurn

	emitText func(string) error

	emitEvent func(eventType string, data interface{}) error

	roots []string

	// projectPath is the folder the session is bound to, empty without a
	// project. It is the answer to the question the planner asked most often.
	projectPath string

	// history is the conversation so far. Planning used to see only the current
	// message, which is why it kept asking for things the user had already
	// answered two turns earlier.
	history []Message

	asker tools.Asker

	// budget is the window the plan steps run against, same as for a plain
	// agent turn - a step that reads files fills it just as fast.
	budget ContextBudget

	sessionID string

	// storeActive writes the worklist back to the session after every step, so
	// an interrupted run can be picked up where it stopped. clearActive drops
	// it once every step is green. Both are nil when no plan store is wired up.
	storeActive func(plan *agentplan.Plan)
	clearActive func()
}

func (r *planRunner) hasFileTools() bool { return len(r.roots) > 0 }

func (r *planRunner) storePlan(plan *agentplan.Plan) {
	if r.storeActive == nil || plan == nil {
		return
	}
	r.storeActive(plan)
}

func (r *planRunner) clearPlan() {
	if r.clearActive == nil {
		return
	}
	r.clearActive()
}

func (r *planRunner) propose(ctx context.Context, goal string) (*agentplan.Plan, error) {
	prompt := agentplan.DecomposePrompt(goal, agentplan.Context{
		HasFileTools: r.hasFileTools(),
		ProjectPath:  r.projectPath,
		Roots:        r.roots,
	})

	var raw strings.Builder
	silent := func(chunk string) error { raw.WriteString(chunk); return nil }

	reply, err := r.chatTurn(
		planningConversation(r.history, goal),
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
		log.Printf("[spark] Plan konnte nicht gelesen werden: %v", err)
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
				"plan_steps":   stepsPayload(plan.Steps),
			},
		})
	}
	log.Printf("[spark] Plan vorgelegt (%d Schritte, session=%s)", len(plan.Steps), r.sessionID)
	return &plan, nil
}

type planQuestionsError struct {
	questions agentplan.Questions
}

func (e *planQuestionsError) Error() string {
	return "spark: das Modell hat Rueckfragen zur Aufgabe"
}

func (r *planRunner) execute(ctx context.Context, plan *agentplan.Plan) (string, error) {
	if plan == nil || plan.IsEmpty() {
		return "", fmt.Errorf("spark: kein Plan zum Ausfuehren")
	}

	r.storePlan(plan)

	// The full list goes out once before the first step, so the client can put
	// the whole worklist on screen and then only tick items off; the per-step
	// events that follow carry no list of their own.
	if r.emitEvent != nil {
		_ = r.emitEvent("plan_started", map[string]interface{}{
			"session_id": r.sessionID,
			"total":      len(plan.Steps),
			"open":       plan.Unfinished(),
			"planning": map[string]interface{}{
				"plan_summary": plan.Summary,
				"steps":        plan.StepTitles(),
				"plan_steps":   stepsPayload(plan.Steps),
			},
		})
	}

	for i := range plan.Steps {
		step := &plan.Steps[i]
		// A resumed run leaves green steps alone: redoing them would undo
		// finished work and spend a model call on something already reported.
		if step.Status == agentplan.StatusDone {
			continue
		}
		if err := ctx.Err(); err != nil {
			step.Status = agentplan.StatusPending
			r.storePlan(plan)
			return "", err
		}

		step.Status = agentplan.StatusRunning
		r.emitStep("plan_step_start", *step, len(plan.Steps), "")
		r.storePlan(plan)

		started := time.Now()
		result, err := r.runStepWithRetries(ctx, *plan, *step)
		if err != nil {
			if !errors.Is(err, errToolLoopExhausted) {
				// The model or the connection is gone. The step goes back to
				// pending so a later run starts it over instead of skipping it,
				// and the plan stays on the session.
				step.Status = agentplan.StatusPending
				r.storePlan(plan)
				log.Printf("[spark] Planschritt %d abgebrochen, Plan bleibt offen (session=%s): %v",
					step.Number, r.sessionID, err)
				return "", err
			}

			// Out of tool budget even after the second attempt. That is this
			// step's problem, not the plan's: the remaining steps still run and
			// this one stays open for another go.
			step.Status = agentplan.StatusFailed
			step.Result = "Abgebrochen ohne Abschluss: " + strings.TrimSpace(result)
			r.emitStep("plan_step_result", *step, len(plan.Steps), step.Result)
			r.storePlan(plan)
			log.Printf("[spark] Planschritt %d ohne Abschluss, weiter mit dem naechsten (session=%s)",
				step.Number, r.sessionID)
			continue
		}

		step.Status = agentplan.StatusDone
		step.Result = strings.TrimSpace(result)
		r.emitStep("plan_step_result", *step, len(plan.Steps), step.Result)
		r.storePlan(plan)
		// The duration is here because it is the one number that says whether a
		// slow run is the model or us: everything between two model calls is a
		// file write and a JSON parse.
		log.Printf("[spark] Planschritt %d erledigt in %s (session=%s)",
			step.Number, time.Since(started).Round(time.Second), r.sessionID)
	}

	r.emitFinished(*plan)
	if plan.Unfinished() == 0 {
		r.clearPlan()
	}
	return r.report(ctx, *plan)
}

// runStepWithRetries gives a step a second pass when it ran out of tool calls.
// One pass is a fixed number of calls, and a step like "build the header, the
// navigation and the hero section" spends that on the first couple of files -
// a single limit hit used to end the entire plan there.
func (r *planRunner) runStepWithRetries(
	ctx context.Context,
	plan agentplan.Plan,
	step agentplan.Step,
) (string, error) {
	var lastResult string
	var lastErr error
	for attempt := 1; attempt <= maxPlanStepAttempts; attempt++ {
		result, err := r.runStep(ctx, plan, step, attempt, lastResult)
		if err == nil {
			return result, nil
		}
		// A cancelled run is the user's decision and stops here. Everything
		// else - a provider that sent nothing, a stream that went silent, a
		// step out of tool budget - gets one more go before the step is put
		// down as open.
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			return result, err
		}
		lastResult, lastErr = result, err
		if attempt < maxPlanStepAttempts {
			log.Printf("[spark] Planschritt %d gescheitert, zweiter Anlauf (session=%s): %v",
				step.Number, r.sessionID, err)
		}
	}
	return lastResult, lastErr
}

// emitFinished closes the worklist off. Steps still pending here are the ones
// after a failure that were never started - they keep that status rather than
// being reported as skipped, because the client is the one that decides how a
// step that never ran should read.
func (r *planRunner) emitFinished(plan agentplan.Plan) {
	if r.emitEvent == nil {
		return
	}
	var done, failed, pending int
	for _, step := range plan.Steps {
		switch step.Status {
		case agentplan.StatusDone:
			done++
		case agentplan.StatusFailed:
			failed++
		default:
			pending++
		}
	}
	_ = r.emitEvent("plan_finished", map[string]interface{}{
		"session_id": r.sessionID,
		"total":      len(plan.Steps),
		"done":       done,
		"failed":     failed,
		"pending":    pending,
		"planning": map[string]interface{}{
			"plan_summary": plan.Summary,
			"plan_steps":   stepsPayload(plan.Steps),
		},
	})
	log.Printf("[spark] Plan abgearbeitet (%d erledigt, %d fehlgeschlagen, %d offen, session=%s)",
		done, failed, pending, r.sessionID)
}

func stepsPayload(steps []agentplan.Step) []map[string]interface{} {
	out := make([]map[string]interface{}, 0, len(steps))
	for _, step := range steps {
		entry := map[string]interface{}{
			"number": step.Number,
			"title":  step.Title,
			"status": step.Status,
		}
		if step.Detail != "" {
			entry["detail"] = step.Detail
		}
		if step.Result != "" {
			entry["result"] = previewLine(step.Result, 400)
		}
		out = append(out, entry)
	}
	return out
}

func (r *planRunner) runStep(
	ctx context.Context,
	plan agentplan.Plan,
	step agentplan.Step,
	attempt int,
	previous string,
) (string, error) {
	prompt := agentplan.StepPrompt(plan, step)
	task := fmt.Sprintf("Fuehre Schritt %d aus: %s", step.Number, step.Title)
	if attempt > 1 {
		task = fmt.Sprintf(
			"Du hast Schritt %d (%s) begonnen und dabei das Werkzeug-Limit erreicht. "+
				"Bisher: %s\n\nMach genau dort weiter und bring den Schritt zu Ende. "+
				"Wiederhole nichts, was schon steht.",
			step.Number, step.Title, previewLine(previous, 600))
	}
	history := []Message{{Role: "user", Content: task}}

	var buf strings.Builder
	quiet := func(chunk string) error { buf.WriteString(chunk); return nil }

	if r.hasFileTools() {
		return runToolLoopWithLimit(ctx, history, prompt, r.roots, quiet, r.emitEvent,
			r.chatTurn, r.asker, r.sessionID, maxPlanStepIterations, r.budget)
	}
	return runWebOnlyToolLoopWithLimit(ctx, history, prompt, quiet, r.emitEvent,
		r.chatTurn, maxPlanStepIterations, r.budget)
}

func (r *planRunner) report(ctx context.Context, plan agentplan.Plan) (string, error) {
	filter := newToolCallStreamFilter(r.emitText)
	reply, err := r.chatTurn(
		[]Message{{Role: "user", Content: "Fasse das Ergebnis zusammen."}},
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

const (
	// How much of the conversation the planner gets. The tail is what matters:
	// what was agreed a few turns ago, not the whole session.
	maxPlanContextMessages = 8
	maxPlanContextChars    = 1200
)

// planningConversation hands the planner the recent conversation with the goal
// as the last word. Without it the planner saw a single message and asked back
// for everything around it - the folder, the target, decisions the user had
// already made.
func planningConversation(history []Message, goal string) []Message {
	trimmedGoal := strings.TrimSpace(goal)

	// The caller appends the current message to the history before the run, so
	// the tail is normally the goal itself. It comes off here and goes back on
	// at the end untruncated, as the last word.
	if len(history) > 0 {
		last := history[len(history)-1]
		if last.Role == "user" && strings.TrimSpace(last.Content) == trimmedGoal {
			history = history[:len(history)-1]
		}
	}

	if len(history) > maxPlanContextMessages {
		history = history[len(history)-maxPlanContextMessages:]
	}

	convo := make([]Message, 0, len(history)+1)
	for _, msg := range history {
		content := strings.TrimSpace(msg.Content)
		if content == "" {
			continue
		}
		convo = append(convo, Message{Role: msg.Role, Content: clip(content, maxPlanContextChars)})
	}
	return append(convo, Message{Role: "user", Content: trimmedGoal})
}

func clip(s string, limit int) string {
	runes := []rune(s)
	if len(runes) <= limit {
		return s
	}
	return strings.TrimSpace(string(runes[:limit])) + "…"
}

func previewLine(s string, limit int) string {
	s = strings.TrimSpace(strings.ReplaceAll(s, "\n", " "))
	runes := []rune(s)
	if len(runes) <= limit {
		return s
	}
	return strings.TrimSpace(string(runes[:limit])) + "…"
}
