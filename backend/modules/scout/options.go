package scout

import (
	"github.com/culpeohq/backend/modules/scout/bots"
	"strings"

	"github.com/google/uuid"
)

func normalizeChatOptions(thinking, style string, editIndex *int, agenticMode string, allowedRoots []string, approvePlan, planning bool) chatOptions {
	index := -1
	if editIndex != nil {
		index = *editIndex
	}
	mode := normalizeAgenticMode(agenticMode)
	return chatOptions{
		Thinking:         normalizeThinkingLevel(thinking),
		Style:            bots.NormalizeResponseStyle(style),
		EditMessageIndex: index,
		AgenticMode:      mode,
		AllowedRoots:     bots.NormalizeAllowedRoots(allowedRoots),
		ApprovePlan:      approvePlan,

		Planning: planning || mode == "planning",
	}
}

func normalizeThinkingLevel(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "none", "off", "aus":
		return "none"
	case "max", "extra":
		return "max"
	case "dual", "deep":
		return "deep"
	case "agent", "agents", "agentic":
		return "agentic"
	case "medium", "fast", "balanced":
		return "medium"
	default:
		return "medium"
	}
}

func normalizeAgenticMode(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "planning", "plan":
		return "planning"
	default:
		return "execute"
	}
}

func (m *ScoutModule) acquireSessionMutation(sessionID, userID string) error {
	userID = bots.NormalizeUserID(userID)
	m.mu.Lock()
	defer m.mu.Unlock()
	session := m.sessions[strings.TrimSpace(sessionID)]
	if session == nil || session.UserID != userID {
		return errScoutSessionNotFound
	}
	if session.MutationInFlight {
		return errScoutSessionBusy
	}
	session.MutationInFlight = true
	return nil
}

func (m *ScoutModule) releaseSessionMutation(sessionID, userID string) {
	userID = bots.NormalizeUserID(userID)
	m.mu.Lock()
	defer m.mu.Unlock()
	session := m.sessions[strings.TrimSpace(sessionID)]
	if session != nil && session.UserID == userID {
		session.MutationInFlight = false
	}
}

func newChatSessionID() string {
	return "chat-" + uuid.New().String()
}

func (m *ScoutModule) responseStyleForBot(userID, botID, fallback string) string {
	for _, bot := range m.botStore.GetBotsForUser(userID) {
		if bot.ID == botID && strings.TrimSpace(bot.ResponseStyle) != "" {
			return bots.NormalizeResponseStyle(bot.ResponseStyle)
		}
	}
	return bots.NormalizeResponseStyle(fallback)
}
