package philobot

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"

	"github.com/fillyengine/backend/internal/agentplan"
)

type planningRequest struct {
	userID       string
	sessionID    string
	provider     string
	modelID      string
	message      string
	systemPrompt string
	thinking     string
	projectPath  string
	options      chatOptions
	emitText     func(string) error
	emitEvent    func(eventType string, data interface{}) error
}

func (m *PhiloBotModule) runPlanningFlow(ctx context.Context, req planningRequest) (handled bool, reply string, err error) {
	switch {
	case req.options.ApprovePlan:
		plan := m.takePendingPlan(req.userID, req.sessionID)
		if plan == nil {

			log.Printf("[philobot] Freigabe ohne hinterlegten Plan (session=%s)", req.sessionID)
			return false, "", nil
		}
		reply, err = m.executePlan(ctx, req, plan)
		return true, reply, err

	case req.options.Planning:
		log.Printf("[philobot] Planungsmodus aktiv (session=%s)", req.sessionID)
		return m.proposePlan(ctx, req)

	default:
		return false, "", nil
	}
}

func (m *PhiloBotModule) proposePlan(ctx context.Context, req planningRequest) (bool, string, error) {
	runner := m.newPlanRunner(ctx, req)
	plan, err := runner.propose(ctx, req.message)

	var questions *planQuestionsError
	if errors.As(err, &questions) {
		return m.askPlanningQuestions(req, questions.questions)
	}
	if err != nil {

		log.Printf("[philobot] Planung uebersprungen, Modell lieferte keinen verwertbaren Plan (session=%s): %v",
			req.sessionID, err)
		if req.emitEvent != nil {
			_ = req.emitEvent("plan_skipped", map[string]interface{}{
				"session_id": req.sessionID,
				"reason":     "Das Modell hat keinen verwertbaren Plan geliefert; die Frage wird direkt beantwortet.",
			})
		}
		return false, "", nil
	}

	m.storePendingPlan(req.userID, req.sessionID, plan)

	var b strings.Builder
	b.WriteString(plan.Summary)
	b.WriteString("\n\n")
	for _, title := range plan.StepTitles() {
		b.WriteString(title)
		b.WriteString("\n")
	}
	b.WriteString("\nSag mir Bescheid, wenn ich so vorgehen soll.")
	text := b.String()
	if req.emitText != nil {
		if err := req.emitText(text); err != nil {
			return true, "", err
		}
	}
	return true, text, nil
}

func (m *PhiloBotModule) askPlanningQuestions(req planningRequest, questions agentplan.Questions) (bool, string, error) {
	var b strings.Builder
	b.WriteString(questions.Reason)
	b.WriteString("\n\n")
	for i, question := range questions.Items {
		b.WriteString(fmt.Sprintf("%d. %s\n", i+1, question))
	}
	b.WriteString("\nBeantworte was du kannst, dann plane ich damit.")
	text := b.String()

	if req.emitEvent != nil {
		_ = req.emitEvent("planning_questions", map[string]interface{}{
			"session_id": req.sessionID,
			"planning": map[string]interface{}{
				"plan_summary": questions.Reason,
				"steps":        questions.Items,
			},
		})
	}
	if req.emitText != nil {
		if err := req.emitText(text); err != nil {
			return true, "", err
		}
	}
	log.Printf("[philobot] Planung stellt %d Rueckfragen (session=%s)", len(questions.Items), req.sessionID)
	return true, text, nil
}

func (m *PhiloBotModule) executePlan(ctx context.Context, req planningRequest, plan *agentplan.Plan) (string, error) {
	log.Printf("[philobot] Plan freigegeben, starte Ausfuehrung (%d Schritte, session=%s)",
		len(plan.Steps), req.sessionID)
	runner := m.newPlanRunner(ctx, req)
	return runner.execute(ctx, plan)
}

func (m *PhiloBotModule) newPlanRunner(ctx context.Context, req planningRequest) *planRunner {
	var asker permissionAsker

	roots := resolveToolRoots(req.projectPath, req.message)
	if len(roots) > 0 {
		broker := newPermissionBroker()
		m.mu.Lock()
		m.permissionBrokers[req.sessionID] = broker
		m.mu.Unlock()
		asker = broker
		context.AfterFunc(ctx, func() {
			m.mu.Lock()
			delete(m.permissionBrokers, req.sessionID)
			m.mu.Unlock()
			broker.Close()
		})
	}

	return &planRunner{
		chatTurn: func(convo []chatMessage, prompt string, filterEmit func(string) error) (string, error) {
			emitReasoning := func(chunk string) error {
				if req.emitEvent == nil {
					return nil
				}
				return req.emitEvent("reasoning_delta", map[string]interface{}{"chunk": chunk})
			}
			thinkFilter := newThinkTagFilter(filterEmit, emitReasoning)
			out, streamErr := m.streamProviderChat(ctx, req.provider, req.modelID, convo, prompt,
				req.thinking, thinkFilter.Emit, emitReasoning)
			if streamErr == nil {
				streamErr = thinkFilter.Flush()
			}
			return out, streamErr
		},
		emitText:  req.emitText,
		emitEvent: req.emitEvent,
		roots:     roots,
		asker:     asker,
		sessionID: req.sessionID,
	}
}

func (m *PhiloBotModule) storePendingPlan(userID, sessionID string, plan *agentplan.Plan) {
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session != nil && session.UserID == userID {
		session.PendingPlan = plan
	}
	m.mu.Unlock()
	m.persistSession(sessionID)
}

func (m *PhiloBotModule) takePendingPlan(userID, sessionID string) *agentplan.Plan {
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID || session.PendingPlan == nil {
		m.mu.Unlock()
		return nil
	}
	plan := session.PendingPlan
	session.PendingPlan = nil
	m.mu.Unlock()
	m.persistSession(sessionID)
	return plan
}
