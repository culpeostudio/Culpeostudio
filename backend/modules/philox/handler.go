package philox

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/internal/security"
)

type PhiloxModule struct {
	store    *sessionStore
	executor *toolExecutor
	requests *sessionRequestRegistry
	memory   MemoryRecorder
}

type planningAnswerRequest struct {
	QuestionID string `json:"question_id"`
	Answer     string `json:"answer"`
}

func New() *PhiloxModule {
	storageDir := envValue("PHILOX_STORAGE_DIR", "data/philox/sessions")
	storage := newSessionStorage(storageDir)
	return &PhiloxModule{
		store:    newSessionStore(storage),
		executor: newToolExecutor(),
		requests: newSessionRequestRegistry(),
	}
}

func (m *PhiloxModule) Name() string { return "philox" }

func (m *PhiloxModule) RegisterRoutes(r fiber.Router) {
	g := r.Group("/philox")
	g.Post("/session", m.handleCreateSession)
	g.Post("/session/:session_id/cancel", m.handleCancelSession)
	g.Delete("/session/:session_id", m.handleDeleteSession)
	g.Post("/message", m.handleMessage)
	g.Post("/stream", m.handleStream)
	g.Get("/history/:session_id", m.handleHistory)
	g.Get("/session/:session_id", m.handleSession)
	g.Get("/sessions", m.handleSessions)
}

func (m *PhiloxModule) Initialize() error { return m.store.Initialize() }
func (m *PhiloxModule) Shutdown() error   { return nil }

func (m *PhiloxModule) handleCreateSession(c *fiber.Ctx) error {
	var body struct {
		ModelID       string   `json:"model_id"`
		ThinkingLevel string   `json:"thinking_level"`
		Mode          string   `json:"mode"`
		AllowedRoots  []string `json:"allowed_roots"`
	}
	if len(c.Body()) > 0 {
		if err := c.BodyParser(&body); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
		}
	}

	roots, err := m.executor.NormalizeRoots(body.AllowedRoots)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	session := &PersistedSession{
		ID:                 sessionID(),
		UserID:             philoxRequestUserID(c),
		ModelID:            strings.TrimSpace(body.ModelID),
		ThinkingLevel:      normalizeThinkingLevel(body.ThinkingLevel),
		Mode:               normalizeSessionMode(body.Mode),
		AllowedRoots:       roots,
		Messages:           []ConversationMessage{},
		ArchivedMessages:   []ConversationMessage{},
		CompressedMemories: []CompressedMemory{},
		Planning:           defaultPlanningState(),
		ToolAudit:          []ToolAuditEntry{},
		CreatedAt:          nowUTC(),
		UpdatedAt:          nowUTC(),
	}
	session.EffectiveModel = effectiveModelForThinking(session.ModelID)
	session.ContextUsageEstimate = estimateSessionUsage(session)

	if err := m.store.Create(session); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	bus.Get().Emit("philox", bus.EventPhiloxSessionCreated, map[string]interface{}{
		"user_id":         session.UserID,
		"session_id":      session.ID,
		"model_id":        session.ModelID,
		"effective_model": session.EffectiveModel,
		"thinking_level":  session.ThinkingLevel,
		"mode":            session.Mode,
		"allowed_roots":   roots,
	})
	if m.memory != nil {
		m.memory.PhiloxSessionStarted(session.ID, nil)
	}
	return c.JSON(sessionResponse(session, "created"))
}

func philoxRequestUserID(c *fiber.Ctx) string {
	if value, ok := c.Locals("user_id").(string); ok {
		if userID := security.SanitizeUserID(value); userID != "" {
			return userID
		}
	}
	return "local"
}

func (m *PhiloxModule) handleStream(c *fiber.Ctx) error {
	var body struct {
		SessionID       string                  `json:"session_id"`
		Message         string                  `json:"message"`
		ThinkingLevel   string                  `json:"thinking_level"`
		Mode            string                  `json:"mode"`
		PlanningAnswers []planningAnswerRequest `json:"planning_answers"`
		ApprovePlan     bool                    `json:"approve_plan"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	sessionID := strings.TrimSpace(body.SessionID)
	if sessionID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "session_id ist erforderlich"})
	}

	session, err := m.store.Get(sessionID)
	if err != nil {
		if os.IsNotExist(err) {
			return c.Status(404).JSON(fiber.Map{"error": "Session nicht gefunden"})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	session.mu.Lock()

	message, modeOverride, err := preparePlanningInput(session, strings.TrimSpace(body.Message), body.PlanningAnswers, body.ApprovePlan, body.Mode)
	if err != nil {
		session.mu.Unlock()
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	sink := newEventSink(64)
	requestContext, request := m.requests.Begin(sessionID)

	// Run agent in background goroutine — events flow through the sink.
	go func() {
		defer m.requests.Finish(sessionID, request)
		defer session.mu.Unlock()
		m.runAgentStreaming(requestContext, session, message, body.ThinkingLevel, modeOverride, sink)
	}()

	// SSE response headers.
	c.Set("Content-Type", "text/event-stream")
	c.Set("Cache-Control", "no-cache")
	c.Set("Connection", "keep-alive")
	c.Set("X-Accel-Buffering", "no")

	c.Context().SetBodyStreamWriter(func(w *bufio.Writer) {
		for event := range sink.Events() {
			if _, err := w.Write(FormatSSE(event)); err != nil {
				m.requests.Cancel(sessionID)
				return
			}
			if err := w.Flush(); err != nil {
				m.requests.Cancel(sessionID)
				return
			}
		}
	})
	return nil
}

func (m *PhiloxModule) handleCancelSession(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Params("session_id"))
	if sessionID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "session_id ist erforderlich"})
	}

	session, err := m.store.Get(sessionID)
	if err != nil {
		if os.IsNotExist(err) {
			return c.Status(404).JSON(fiber.Map{"error": "Session nicht gefunden"})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	canceled := m.requests.Cancel(sessionID)
	session.mu.Lock()
	session.mu.Unlock()

	status := "idle"
	if canceled {
		status = "canceled"
	}
	return c.JSON(fiber.Map{
		"session_id": sessionID,
		"status":     status,
		"canceled":   canceled,
	})
}

func (m *PhiloxModule) handleDeleteSession(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Params("session_id"))
	if sessionID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "session_id ist erforderlich"})
	}

	session, err := m.store.Get(sessionID)
	if err != nil {
		if os.IsNotExist(err) {
			return c.Status(404).JSON(fiber.Map{"error": "Session nicht gefunden"})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	m.requests.Cancel(sessionID)
	session.mu.Lock()
	defer session.mu.Unlock()

	if err := m.store.Delete(sessionID); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"session_id": sessionID,
		"status":     "deleted",
	})
}

func (m *PhiloxModule) handleMessage(c *fiber.Ctx) error {
	var body struct {
		SessionID       string                  `json:"session_id"`
		Message         string                  `json:"message"`
		ThinkingLevel   string                  `json:"thinking_level"`
		Mode            string                  `json:"mode"`
		PlanningAnswers []planningAnswerRequest `json:"planning_answers"`
		ApprovePlan     bool                    `json:"approve_plan"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	sessionID := strings.TrimSpace(body.SessionID)
	if sessionID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "session_id ist erforderlich"})
	}

	session, err := m.store.Get(sessionID)
	if err != nil {
		if os.IsNotExist(err) {
			return c.Status(404).JSON(fiber.Map{"error": "Session nicht gefunden"})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	session.mu.Lock()
	defer session.mu.Unlock()

	message, modeOverride, err := preparePlanningInput(session, strings.TrimSpace(body.Message), body.PlanningAnswers, body.ApprovePlan, body.Mode)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	result, err := m.runAgent(context.Background(), session, message, body.ThinkingLevel, modeOverride)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	if err := m.store.Save(session); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"session_id":        session.ID,
		"reply":             result.Reply,
		"mode":              session.Mode,
		"thinking_level":    session.ThinkingLevel,
		"effective_model":   session.EffectiveModel,
		"planning":          planningStateForResponse(session),
		"tool_events":       result.ToolEvents,
		"compression_event": result.CompressionEvent,
		"status":            "ok",
	})
}

func (m *PhiloxModule) handleHistory(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Params("session_id"))
	session, err := m.store.Get(sessionID)
	if err != nil {
		if os.IsNotExist(err) {
			return c.Status(404).JSON(fiber.Map{"error": "Session nicht gefunden"})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{
		"session_id":             session.ID,
		"messages":               session.Messages,
		"compressed_memories":    session.CompressedMemories,
		"archived_message_count": len(session.ArchivedMessages),
		"context_usage_estimate": session.ContextUsageEstimate,
		"allowed_roots":          session.AllowedRoots,
		"thinking_level":         session.ThinkingLevel,
		"mode":                   session.Mode,
		"effective_model":        session.EffectiveModel,
		"planning":               planningStateForResponse(session),
	})
}

func (m *PhiloxModule) handleSession(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Params("session_id"))
	session, err := m.store.Get(sessionID)
	if err != nil {
		if os.IsNotExist(err) {
			return c.Status(404).JSON(fiber.Map{"error": "Session nicht gefunden"})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(sessionResponse(session, "ok"))
}

func (m *PhiloxModule) handleSessions(c *fiber.Ctx) error {
	sessions, err := m.store.List()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"sessions": sessions})
}

func sessionResponse(session *PersistedSession, status string) fiber.Map {
	summary := session.Summary()
	return fiber.Map{
		"session_id":             session.ID,
		"effective_model":        session.EffectiveModel,
		"thinking_level":         session.ThinkingLevel,
		"mode":                   session.Mode,
		"allowed_roots":          session.AllowedRoots,
		"context_usage_estimate": session.ContextUsageEstimate,
		"message_count":          summary.MessageCount,
		"compressed_count":       summary.CompressedCount,
		"planning":               planningStateForResponse(session),
		"created_at":             session.CreatedAt,
		"updated_at":             session.UpdatedAt,
		"status":                 status,
	}
}

func preparePlanningInput(session *PersistedSession, message string, answers []planningAnswerRequest, approvePlan bool, requestedMode string) (string, string, error) {
	parts := []string{}
	if formattedAnswers := formatPlanningAnswers(session, answers); formattedAnswers != "" {
		parts = append(parts, formattedAnswers)
	}
	if message != "" {
		parts = append(parts, message)
	}

	modeOverride := requestedMode
	if approvePlan {
		state := ensurePlanningState(session)
		if state.Draft == nil || len(state.Draft.Steps) == 0 {
			return "", "", fmt.Errorf("Es gibt noch keinen Plan zur Freigabe")
		}
		state.Status = PlanningStatusApproved
		state.Questions = []PlanningQuestion{}
		state.UpdatedAt = nowUTC()
		modeOverride = string(ModeExecute)
		parts = append([]string{
			"Der Nutzer hat den letzten Plan freigegeben. Wechsle jetzt in den Ausfuehrungsmodus und setze genau diesen Plan um. Arbeite Schritt fuer Schritt, fuehre notwendige Aenderungen aus und berichte klar ueber den Fortschritt.",
		}, parts...)
	}

	combined := strings.TrimSpace(strings.Join(parts, "\n\n"))
	if combined == "" {
		return "", "", fmt.Errorf("message, planning_answers oder approve_plan sind erforderlich")
	}
	if len(answers) > 0 {
		state := ensurePlanningState(session)
		state.Status = PlanningStatusIdle
		state.Questions = []PlanningQuestion{}
		state.UpdatedAt = nowUTC()
	}
	return combined, modeOverride, nil
}

func formatPlanningAnswers(session *PersistedSession, answers []planningAnswerRequest) string {
	if len(answers) == 0 {
		return ""
	}
	state := ensurePlanningState(session)
	lines := []string{"Antworten des Nutzers fuer den Planungsmodus:"}
	for _, answer := range answers {
		trimmed := strings.TrimSpace(answer.Answer)
		if trimmed == "" {
			continue
		}
		label := strings.TrimSpace(answer.QuestionID)
		for _, question := range state.Questions {
			if question.ID == answer.QuestionID {
				label = question.Prompt
				break
			}
		}
		if label == "" {
			label = "Rueckfrage"
		}
		lines = append(lines, fmt.Sprintf("- %s: %s", label, trimmed))
	}
	if len(lines) == 1 {
		return ""
	}
	return strings.Join(lines, "\n")
}

func planningStateForResponse(session *PersistedSession) *PlanningState {
	if session == nil || session.Planning == nil {
		return &PlanningState{
			Status:    PlanningStatusIdle,
			Questions: []PlanningQuestion{},
		}
	}
	if session.Planning.Questions == nil {
		session.Planning.Questions = []PlanningQuestion{}
	}
	return session.Planning
}
