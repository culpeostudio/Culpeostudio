package spark

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"

	"github.com/culpeohq/backend/modules/spark/tools"

	"github.com/culpeohq/backend/internal/agentplan"
)

func (m *Module) runPlanningFlow(ctx context.Context, req Request, turn ChatTurn) (handled bool, reply string, err error) {
	switch {
	case req.ApprovePlan:
		plan := m.takePendingPlan(req.UserID, req.SessionID)
		if plan == nil {

			log.Printf("[spark] Freigabe ohne hinterlegten Plan (session=%s)", req.SessionID)
			return false, "", nil
		}
		reply, err = m.executePlan(ctx, req, turn, plan)
		return true, reply, err

	case req.Planning:
		log.Printf("[spark] Planungsmodus aktiv (session=%s)", req.SessionID)
		return m.proposePlan(ctx, req, turn)

	default:
		return false, "", nil
	}
}

func (m *Module) proposePlan(ctx context.Context, req Request, turn ChatTurn) (bool, string, error) {
	runner := m.newPlanRunner(ctx, req, turn)
	plan, err := runner.propose(ctx, req.Message)

	var questions *planQuestionsError
	if errors.As(err, &questions) {
		return m.askPlanningQuestions(req, questions.questions)
	}
	if err != nil {

		log.Printf("[spark] Planung uebersprungen, Modell lieferte keinen verwertbaren Plan (session=%s): %v",
			req.SessionID, err)
		if req.EmitEvent != nil {
			_ = req.EmitEvent("plan_skipped", map[string]interface{}{
				"session_id": req.SessionID,
				"reason":     "Das Modell hat keinen verwertbaren Plan geliefert; die Frage wird direkt beantwortet.",
			})
		}
		return false, "", nil
	}

	m.storePendingPlan(req.UserID, req.SessionID, plan)

	var b strings.Builder
	b.WriteString(plan.Summary)
	b.WriteString("\n\n")
	for _, title := range plan.StepTitles() {
		b.WriteString(title)
		b.WriteString("\n")
	}
	b.WriteString("\nSag mir Bescheid, wenn ich so vorgehen soll.")
	text := b.String()
	if req.EmitText != nil {
		if err := req.EmitText(text); err != nil {
			return true, "", err
		}
	}
	return true, text, nil
}

func (m *Module) askPlanningQuestions(req Request, questions agentplan.Questions) (bool, string, error) {
	var b strings.Builder
	b.WriteString(questions.Reason)
	b.WriteString("\n\n")
	for i, question := range questions.Items {
		b.WriteString(fmt.Sprintf("%d. %s\n", i+1, question))
	}
	b.WriteString("\nBeantworte was du kannst, dann plane ich damit.")
	text := b.String()

	if req.EmitEvent != nil {
		_ = req.EmitEvent("planning_questions", map[string]interface{}{
			"session_id": req.SessionID,
			"planning": map[string]interface{}{
				"plan_summary": questions.Reason,
				"steps":        questions.Items,
			},
		})
	}
	if req.EmitText != nil {
		if err := req.EmitText(text); err != nil {
			return true, "", err
		}
	}
	log.Printf("[spark] Planung stellt %d Rueckfragen (session=%s)", len(questions.Items), req.SessionID)
	return true, text, nil
}

func (m *Module) executePlan(ctx context.Context, req Request, turn ChatTurn, plan *agentplan.Plan) (string, error) {
	log.Printf("[spark] Plan freigegeben, starte Ausfuehrung (%d Schritte, session=%s)",
		len(plan.Steps), req.SessionID)
	runner := m.newPlanRunner(ctx, req, turn)
	return runner.execute(ctx, plan)
}

func (m *Module) newPlanRunner(ctx context.Context, req Request, turn ChatTurn) *planRunner {
	var asker tools.Asker

	roots := resolveToolRoots(req.ProjectPath, req.Message)
	if len(roots) > 0 {
		broker := tools.NewBroker()
		m.attachBroker(req.SessionID, broker)
		asker = broker
		context.AfterFunc(ctx, func() {
			m.releaseBroker(req.SessionID, broker)
		})
	}

	return &planRunner{
		chatTurn:  turn,
		emitText:  req.EmitText,
		emitEvent: req.EmitEvent,
		roots:     roots,
		asker:     asker,
		sessionID: req.SessionID,
	}
}

func (m *Module) storePendingPlan(userID, sessionID string, plan *agentplan.Plan) {
	if m.plans == nil {
		return
	}
	m.plans.StorePendingPlan(userID, sessionID, plan)
}

func (m *Module) takePendingPlan(userID, sessionID string) *agentplan.Plan {
	if m.plans == nil {
		return nil
	}
	return m.plans.TakePendingPlan(userID, sessionID)
}
