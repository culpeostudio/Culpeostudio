package philobot

import (
	"strings"

	"github.com/gofiber/fiber/v2"
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
		Style:            normalizeResponseStyle(style),
		EditMessageIndex: index,
		AgenticMode:      mode,
		AllowedRoots:     normalizeAllowedRoots(allowedRoots),
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

func normalizeAllowedRoots(values []string) []string {
	roots := make([]string, 0, len(values))
	seen := map[string]struct{}{}
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		key := strings.ToLower(trimmed)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		roots = append(roots, trimmed)
	}
	return roots
}

func philoBotRequestUserID(c *fiber.Ctx) string {
	if c != nil {
		if value, ok := c.Locals("user_id").(string); ok {
			if userID := normalizeBotUserID(value); userID != "" {
				return userID
			}
		}
	}

	return "local"
}

func (m *PhiloBotModule) sessionOwnedBy(sessionID, userID string) bool {
	userID = normalizeBotUserID(userID)
	m.mu.Lock()
	session := m.sessions[strings.TrimSpace(sessionID)]
	owned := session != nil && session.UserID == userID
	m.mu.Unlock()
	return owned
}

func (m *PhiloBotModule) acquireSessionMutation(sessionID, userID string) error {
	userID = normalizeBotUserID(userID)
	m.mu.Lock()
	defer m.mu.Unlock()
	session := m.sessions[strings.TrimSpace(sessionID)]
	if session == nil || session.UserID != userID {
		return errPhiloBotSessionNotFound
	}
	if session.MutationInFlight {
		return errPhiloBotSessionBusy
	}
	session.MutationInFlight = true
	return nil
}

func (m *PhiloBotModule) releaseSessionMutation(sessionID, userID string) {
	userID = normalizeBotUserID(userID)
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

func normalizeResponseStyle(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "balanced", "short", "explain", "steps", "critical", "brainstorm":
		return strings.ToLower(strings.TrimSpace(value))
	default:
		return "balanced"
	}
}

func (m *PhiloBotModule) responseStyleForBot(userID, botID, fallback string) string {
	for _, bot := range m.botStore.GetBotsForUser(userID) {
		if bot.ID == botID && strings.TrimSpace(bot.ResponseStyle) != "" {
			return normalizeResponseStyle(bot.ResponseStyle)
		}
	}
	return normalizeResponseStyle(fallback)
}
