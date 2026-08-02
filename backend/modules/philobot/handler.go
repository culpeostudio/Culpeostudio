package philobot

import (
	"errors"
	"log"
	"net/http"
	"sort"
	"strings"
	"unicode/utf8"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/apimodels"
	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/internal/localinference"
)

func (m *PhiloBotModule) handleCreateSession(c *fiber.Ctx) error {
	var body struct {
		ModelRef   string `json:"model_ref"`
		Provider   string `json:"provider"`
		ModelID    string `json:"model_id"`
		InstanceID string `json:"instance_id"`
		BotID      string `json:"bot_id"`
		Thinking   string `json:"thinking_level"`
		Style      string `json:"response_style"`
		ProjectID  string `json:"project_id"`
	}
	if len(c.Body()) > 0 {
		if err := c.BodyParser(&body); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
		}
	}

	userID := philoBotRequestUserID(c)
	if err := m.botStore.EnsureUser(userID); err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"error": "Bots konnten nicht geladen werden"})
	}
	session := philoBotSession{
		ID:       newChatSessionID(),
		UserID:   userID,
		ModelRef: strings.TrimSpace(body.ModelRef),
		Provider: apimodels.NormalizeProvider(body.Provider),
		ModelID:  strings.TrimSpace(body.ModelID),
		Messages: []chatMessage{},
		Thinking: normalizeThinkingLevel(body.Thinking),
		Style:    normalizeResponseStyle(body.Style),
	}
	var lockedBot *BotConfig
	if botID := strings.TrimSpace(body.BotID); botID != "" {
		bot, ok := m.botStore.GetBotForUser(userID, botID)
		if !ok {
			return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Bot wurde nicht gefunden", "code": "bot_not_found"})
		}
		lockedBot = &bot
		session.LockedBotID = bot.ID
		session.ActiveBotID = bot.ID
		if bot.ModelBinding != nil {
			binding, err := normalizeModelBinding(bot.ModelBinding)
			if err != nil {
				return c.Status(http.StatusUnprocessableEntity).JSON(fiber.Map{"error": err.Error(), "code": "model_binding_invalid"})
			}
			session.ModelRef = binding.ModelRef
			session.Provider = binding.Provider
			session.ModelID = binding.ModelID
			session.DisplayName = binding.DisplayName
			if binding.Kind == "local" {
				body.InstanceID = binding.InstanceID
			} else {
				body.InstanceID = ""
			}
		}
	}
	localInstanceID := strings.TrimSpace(body.InstanceID)
	if strings.HasPrefix(strings.ToLower(session.ModelRef), localinference.ProviderLocal+":") {
		refID := strings.TrimSpace(session.ModelRef[len(localinference.ProviderLocal)+1:])
		if refID == "" && localInstanceID == "" && session.ModelID == "" {
			return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "instance_id ist fuer ein lokales Modell erforderlich", "code": "instance_id_required"})
		}
		if localInstanceID == "" {
			localInstanceID = refID
		}
		session.Provider = localinference.ProviderLocal
	}
	if session.Provider == localinference.ProviderLocal && localInstanceID == "" {
		localInstanceID = session.ModelID
	}
	if localInstanceID != "" {
		session.Provider = localinference.ProviderLocal
		if m.localModels == nil {
			return c.Status(http.StatusServiceUnavailable).JSON(fiber.Map{"error": "Lokale Modell-Engine ist nicht verfuegbar"})
		}
		localModel, resolveErr := m.localModels.ResolveLocalModel(localInstanceID)
		if resolveErr != nil {
			if errors.Is(resolveErr, localinference.ErrNotReady) {
				if _, canWarm := m.localModels.(localinference.WarmupProvider); canWarm {
					session.ModelID = localInstanceID
					session.ModelRef = localinference.ProviderLocal + ":" + localInstanceID
					if session.DisplayName == "" {
						session.DisplayName = localInstanceID
					}
					goto localModelConfigured
				}
			}
			status := http.StatusConflict
			code := "local_model_not_ready"
			if errors.Is(resolveErr, localinference.ErrNotFound) {
				status = http.StatusNotFound
				code = "local_model_not_found"
				if lockedBot != nil && lockedBot.ModelBinding != nil {
					code = "model_binding_missing"
				}
			}
			return c.Status(status).JSON(fiber.Map{"error": resolveErr.Error(), "code": code})
		}
		session.ModelID = localModel.InstanceID
		session.ModelRef = localinference.ProviderLocal + ":" + localModel.InstanceID
		session.DisplayName = localModel.DisplayName
		session.ContextLimit = localModel.ContextLimit
	}

localModelConfigured:

	if session.Provider != localinference.ProviderLocal && session.ModelRef == "" && session.Provider != "" && session.ModelID != "" {
		session.ModelRef = apimodels.ModelRef(session.Provider, session.ModelID)
	}
	if session.Provider != localinference.ProviderLocal && session.ModelRef != "" {
		active, ok, err := m.activeModels.Touch(session.ModelRef)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Aktive API-Modelle konnten nicht geladen werden"})
		}
		if !ok {
			if session.Provider == "" || session.ModelID == "" {
				return c.Status(404).JSON(fiber.Map{"error": "API-Modell ist nicht fuer Chat gestartet. Bitte im Marketplace erneut 'Im Chat starten' ausfuehren."})
			}
			if !apimodels.IsSupportedProvider(session.Provider) {
				return c.Status(400).JSON(fiber.Map{"error": "provider wird fuer API-Chat nicht unterstuetzt"})
			}
			started, startErr := m.activeModels.Start(session.Provider, session.ModelID, session.DisplayName)
			if startErr != nil {
				return c.Status(500).JSON(fiber.Map{"error": startErr.Error()})
			}
			active = started
		}
		session.Provider = active.Provider
		session.ModelID = active.ModelID
		session.DisplayName = active.DisplayName
	} else if session.Provider != localinference.ProviderLocal && session.ModelID == "" {
		session.ModelID = "default-model"
		session.DisplayName = "default-model"
	}
	if session.DisplayName == "" {
		session.DisplayName = session.ModelID
	}
	session.SelectedModelRef = session.ModelRef
	session.SelectedProvider = session.Provider
	session.SelectedModelID = session.ModelID
	session.SelectedDisplayName = session.DisplayName
	session.SelectedContextLimit = session.ContextLimit

	if projectID := strings.TrimSpace(body.ProjectID); projectID != "" {
		m.mu.Lock()
		project := m.projects[projectID]
		owned := project != nil && project.UserID == userID
		m.mu.Unlock()
		if !owned {
			return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Projekt wurde nicht gefunden", "code": "project_not_found"})
		}
		session.ProjectID = projectID
	}

	m.mu.Lock()
	m.sessions[session.ID] = &session
	m.mu.Unlock()
	m.persistSession(session.ID)

	bus.Get().Emit("philobot", bus.EventPhiloBotSessionCreated, map[string]interface{}{
		"session_id": session.ID,
		"user_id":    session.UserID,
		"model_ref":  session.ModelRef,
		"provider":   session.Provider,
		"model_id":   session.ModelID,
		"thinking":   session.Thinking,
		"style":      session.Style,
	})

	response := fiber.Map{
		"session_id":   session.ID,
		"status":       "created",
		"model_ref":    session.ModelRef,
		"provider":     session.Provider,
		"model_id":     session.ModelID,
		"display_name": session.DisplayName,
		"thinking":     session.Thinking,
		"style":        session.Style,
	}
	if lockedBot != nil {
		response["bot_id"] = lockedBot.ID
		response["bot_name"] = lockedBot.Name
		response["locked_bot_id"] = lockedBot.ID
	}
	if session.Provider == localinference.ProviderLocal {
		response["instance_id"] = session.ModelID
		response["context_limit"] = session.ContextLimit
	}
	return c.JSON(response)
}

func (m *PhiloBotModule) handleListSessions(c *fiber.Ctx) error {
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	summaries := make([]philoBotSessionSummary, 0, len(m.sessions))
	for _, session := range m.sessions {
		if session == nil || session.UserID != userID || len(session.Messages) == 0 {
			continue
		}
		summaries = append(summaries, summarizeSession(session))
	}
	m.mu.Unlock()
	sort.Slice(summaries, func(i, j int) bool {
		return summaries[i].UpdatedAt.After(summaries[j].UpdatedAt)
	})
	return c.JSON(fiber.Map{"sessions": summaries})
}

func (m *PhiloBotModule) handleRenameSession(c *fiber.Ctx) error {
	var body struct {
		Title string `json:"title"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	sessionID := strings.TrimSpace(c.Params("session_id"))
	userID := philoBotRequestUserID(c)
	title := strings.TrimSpace(body.Title)
	if utf8.RuneCountInString(title) > 120 {
		title = string([]rune(title)[:120])
	}
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Session wurde nicht gefunden", "code": "session_not_found"})
	}
	session.Title = title
	summary := summarizeSession(session)
	m.mu.Unlock()
	m.persistSession(sessionID)
	return c.JSON(fiber.Map{"status": "ok", "session": summary})
}

func (m *PhiloBotModule) handleSetSessionModel(c *fiber.Ctx) error {
	var body struct {
		Provider     string `json:"provider"`
		ModelID      string `json:"model_id"`
		ModelRef     string `json:"model_ref"`
		DisplayName  string `json:"display_name"`
		ContextLimit int    `json:"context_limit"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	provider := strings.TrimSpace(body.Provider)
	modelID := strings.TrimSpace(body.ModelID)
	if provider == "" || modelID == "" {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "provider und model_id sind erforderlich", "code": "model_required"})
	}
	sessionID := strings.TrimSpace(c.Params("session_id"))
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Session wurde nicht gefunden", "code": "session_not_found"})
	}
	session.SelectedProvider = provider
	session.SelectedModelID = modelID
	session.SelectedModelRef = strings.TrimSpace(body.ModelRef)
	session.SelectedDisplayName = strings.TrimSpace(body.DisplayName)
	session.SelectedContextLimit = body.ContextLimit
	summary := summarizeSession(session)
	m.mu.Unlock()
	m.persistSession(sessionID)
	return c.JSON(fiber.Map{"status": "ok", "session": summary})
}

func (m *PhiloBotModule) handleDeleteSession(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Params("session_id"))
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Session wurde nicht gefunden", "code": "session_not_found"})
	}
	delete(m.sessions, sessionID)
	m.mu.Unlock()
	if err := m.storage.Delete(sessionID); err != nil {
		log.Printf("[philobot] Session %s loeschen fehlgeschlagen: %v", sessionID, err)
	}
	return c.JSON(fiber.Map{"status": "deleted"})
}

func (m *PhiloBotModule) handleHistory(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Params("session_id"))
	userID := philoBotRequestUserID(c)

	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Session wurde nicht gefunden", "code": "session_not_found"})
	}
	var history []fiber.Map
	provider := ""
	modelID := ""
	modelRef := ""
	displayName := ""
	contextLimit := 0
	provider = session.Provider
	modelID = session.ModelID
	modelRef = session.ModelRef
	displayName = session.DisplayName
	contextLimit = session.ContextLimit
	history = make([]fiber.Map, 0, len(session.Messages))
	for _, message := range session.Messages {
		history = append(history, fiber.Map{
			"role":     message.Role,
			"content":  message.Content,
			"bot_id":   message.BotID,
			"bot_name": message.BotName,
		})
	}
	lockedBotID := session.LockedBotID
	activeBotID := session.ActiveBotID
	m.mu.Unlock()

	return c.JSON(fiber.Map{
		"session_id":    sessionID,
		"provider":      provider,
		"model_id":      modelID,
		"model_ref":     modelRef,
		"display_name":  displayName,
		"context_limit": contextLimit,
		"locked_bot_id": lockedBotID,
		"active_bot_id": activeBotID,
		"messages":      history,
	})
}
