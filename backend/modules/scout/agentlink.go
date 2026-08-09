package scout

import (
	"strings"

	"github.com/culpeohq/backend/internal/agentplan"
	"github.com/culpeohq/backend/modules/spark"
)

// toAgentMessages converts the stored history into the shape the agent expects.
func toAgentMessages(messages []chatMessage) []spark.Message {
	out := make([]spark.Message, 0, len(messages))
	for _, message := range messages {
		out = append(out, spark.Message{Role: message.Role, Content: message.Content})
	}
	return out
}

// fromAgentMessages converts an agent conversation back for the provider call.
func fromAgentMessages(messages []spark.Message) []chatMessage {
	out := make([]chatMessage, 0, len(messages))
	for _, message := range messages {
		out = append(out, chatMessage{Role: message.Role, Content: message.Content})
	}
	return out
}

// projectPathForSessionLocked resolves the folder a session works in. The
// caller holds m.mu; the lookup itself goes to Spark, which owns projects.
func (m *ScoutModule) projectPathForSessionLocked(userID string, session *scoutSession) string {
	if session == nil || m.agent == nil {
		return ""
	}
	projectID := strings.TrimSpace(session.ProjectID)
	if projectID == "" {
		return ""
	}
	return m.agent.ProjectPath(userID, projectID)
}

// StorePendingPlan keeps a proposed plan on the session, so it survives a
// restart. Spark calls this through its PlanStore.
func (m *ScoutModule) StorePendingPlan(userID, sessionID string, plan *agentplan.Plan) {
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session != nil && session.UserID == userID {
		session.PendingPlan = plan
	}
	m.mu.Unlock()
	m.persistSession(sessionID)
}

// TakePendingPlan hands the stored plan to Spark and clears it.
func (m *ScoutModule) TakePendingPlan(userID, sessionID string) *agentplan.Plan {
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

// DetachProject releases every session bound to a project Spark just deleted.
func (m *ScoutModule) DetachProject(userID, projectID string) {
	m.mu.Lock()
	affected := make([]string, 0)
	for _, session := range m.sessions {
		if session != nil && session.UserID == userID && session.ProjectID == projectID {
			session.ProjectID = ""
			affected = append(affected, session.ID)
		}
	}
	m.mu.Unlock()
	for _, sessionID := range affected {
		m.persistSession(sessionID)
	}
}
