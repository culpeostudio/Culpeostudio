package philobot

import (
	"bufio"
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/localinference"
)

func (m *PhiloBotModule) handleMessage(c *fiber.Ctx) error {
	var body struct {
		SessionID    string   `json:"session_id"`
		Message      string   `json:"message"`
		Thinking     string   `json:"thinking_level"`
		Style        string   `json:"response_style"`
		EditIndex    *int     `json:"edit_message_index"`
		AgenticMode  string   `json:"mode"`
		AllowedRoots []string `json:"allowed_roots"`
		ApprovePlan  bool     `json:"approve_plan"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}

	sessionID := strings.TrimSpace(body.SessionID)
	message := strings.TrimSpace(body.Message)
	if sessionID == "" || message == "" {
		return c.Status(400).JSON(fiber.Map{"error": "session_id und message sind erforderlich"})
	}
	userID := philoBotRequestUserID(c)
	if err := m.acquireSessionMutation(sessionID, userID); err != nil {
		status, code := localChatErrorStatus(err)
		if status == http.StatusTooManyRequests {
			c.Set(fiber.HeaderRetryAfter, "1")
		}
		return c.Status(status).JSON(fiber.Map{"error": err.Error(), "code": code})
	}
	defer m.releaseSessionMutation(sessionID, userID)

	options := normalizeChatOptions(body.Thinking, body.Style, body.EditIndex, body.AgenticMode, body.AllowedRoots, body.ApprovePlan)
	var reply, botID, botName string
	var createdBot *BotConfig
	var err error
	if options.Thinking == "agentic" {
		reply, botID, botName, err = m.generateAgenticReply(c.UserContext(), userID, sessionID, message, options, nil, nil)
	} else {
		reply, botID, botName, createdBot, err = m.generateReply(c.UserContext(), userID, sessionID, message, options, nil, nil, nil, nil)
	}
	if err != nil {
		status, code := localChatErrorStatus(err)
		if status == http.StatusTooManyRequests {
			c.Set(fiber.HeaderRetryAfter, "120")
		}
		return c.Status(status).JSON(fiber.Map{"error": err.Error(), "code": code})
	}
	effectiveStyle := m.responseStyleForBot(userID, botID, body.Style)
	res := fiber.Map{
		"session_id":     sessionID,
		"reply":          reply,
		"bot_id":         botID,
		"bot_name":       botName,
		"thinking_level": normalizeThinkingLevel(body.Thinking),
		"response_style": effectiveStyle,
		"status":         "ok",
	}
	if createdBot != nil {
		res["created_bot"] = createdBot
	}
	return c.JSON(res)
}

func (m *PhiloBotModule) handleStream(c *fiber.Ctx) error {
	var body struct {
		SessionID    string   `json:"session_id"`
		Message      string   `json:"message"`
		Thinking     string   `json:"thinking_level"`
		Style        string   `json:"response_style"`
		EditIndex    *int     `json:"edit_message_index"`
		AgenticMode  string   `json:"mode"`
		AllowedRoots []string `json:"allowed_roots"`
		ApprovePlan  bool     `json:"approve_plan"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	sessionID := strings.TrimSpace(body.SessionID)
	message := strings.TrimSpace(body.Message)
	if sessionID == "" || message == "" {
		return c.Status(400).JSON(fiber.Map{"error": "session_id und message sind erforderlich"})
	}
	userID := philoBotRequestUserID(c)
	if err := m.acquireSessionMutation(sessionID, userID); err != nil {
		status, code := localChatErrorStatus(err)
		if status == http.StatusTooManyRequests {
			c.Set(fiber.HeaderRetryAfter, "1")
		}
		return c.Status(status).JSON(fiber.Map{"error": err.Error(), "code": code})
	}

	c.Set("Content-Type", "text/event-stream")
	c.Set("Cache-Control", "no-cache")
	c.Set("Connection", "keep-alive")
	c.Set("X-Accel-Buffering", "no")

	requestContext := c.UserContext()
	if requestContext == nil {
		requestContext = context.Background()
	}

	c.Context().SetBodyStreamWriter(func(w *bufio.Writer) {
		defer m.releaseSessionMutation(sessionID, userID)
		options := normalizeChatOptions(body.Thinking, body.Style, body.EditIndex, body.AgenticMode, body.AllowedRoots, body.ApprovePlan)
		if options.Thinking == "agentic" {
			_, _, _, err := m.generateAgenticReply(requestContext, userID, sessionID, message, options, func(botID, botName string) {
				_ = writeSSE(w, "bot_selected", fiber.Map{"id": botID, "name": botName})
			}, func(eventType string, data interface{}) error {
				return writeSSE(w, eventType, data)
			})
			if err != nil {
				status, code := localChatErrorStatus(err)
				data := fiber.Map{"message": err.Error(), "code": code, "status": status}
				if status == http.StatusTooManyRequests {
					data["retry_after"] = 120
				}
				_ = writeSSE(w, "error", data)
			}
			return
		}
		textEmitter := newStreamingTextEmitter(func(character string) error {
			return writeSSE(w, "text_delta", fiber.Map{"chunk": character})
		})
		writeSSE(w, "status", fiber.Map{"action": "starting"})
		_, botID, _, createdBot, err := m.generateReply(requestContext, userID, sessionID, message, options, func(botID, botName string) {
			_ = writeSSE(w, "bot_selected", fiber.Map{"id": botID, "name": botName})
		}, func(chunk string) error {
			return textEmitter.Emit(chunk)
		}, func(progress localinference.WarmupProgress) error {
			return writeSSE(w, "model_warmup", progress)
		}, func(eventType string, data interface{}) error {
			// Projekt-Datei-Tools melden tool_start/tool_result; das Frontend
			// rendert sie modus-unabhaengig als agentic_events. Vor dem Event
			// gepufferten Text flushen, damit die Reihenfolge im Stream stimmt.
			if err := textEmitter.Flush(); err != nil {
				return err
			}
			return writeSSE(w, eventType, data)
		})
		if err == nil {
			err = textEmitter.Flush()
		}
		if err != nil {
			status, code := localChatErrorStatus(err)
			data := fiber.Map{"message": err.Error(), "code": code, "status": status}
			if status == http.StatusTooManyRequests {
				data["retry_after"] = 120
			}
			_ = writeSSE(w, "error", data)
			return
		}
		if createdBot != nil {
			_ = writeSSE(w, "bot_created", fiber.Map{"bot": createdBot})
		}
		_ = writeSSE(w, "done", fiber.Map{
			"session_id":     sessionID,
			"thinking_level": normalizeThinkingLevel(body.Thinking),
			"response_style": m.responseStyleForBot(userID, botID, body.Style),
		})
	})
	return nil
}

func localChatErrorStatus(err error) (int, string) {
	switch {
	case errors.Is(err, errPhiloBotSessionNotFound):
		return http.StatusNotFound, "session_not_found"
	case errors.Is(err, errPhiloBotBotNotFound):
		return http.StatusNotFound, "bot_not_found"
	case errors.Is(err, errPhiloBotSessionBusy):
		return http.StatusTooManyRequests, "session_busy"
	case errors.Is(err, errModelBindingMissing):
		return http.StatusNotFound, "model_binding_missing"
	case errors.Is(err, errInvalidModelBinding):
		return http.StatusUnprocessableEntity, "model_binding_invalid"
	case errors.Is(err, localinference.ErrGuardRejected):
		return http.StatusServiceUnavailable, "resource_guard_rejected"
	case errors.Is(err, localinference.ErrQueueTimeout):
		return http.StatusGatewayTimeout, "model_queue_timeout"
	case errors.Is(err, localinference.ErrWarmupCanceled):
		return http.StatusConflict, "model_warmup_canceled"
	case errors.Is(err, localinference.ErrInferenceBusy):
		return http.StatusTooManyRequests, "local_inference_busy"
	case errors.Is(err, localinference.ErrNotFound):
		return http.StatusNotFound, "local_model_not_found"
	case errors.Is(err, localinference.ErrNotReady):
		return http.StatusConflict, "local_model_not_ready"
	case errors.Is(err, localinference.ErrContextLimit):
		return http.StatusUnprocessableEntity, "context_length_exceeded"
	case errors.Is(err, localinference.ErrInvalidRequest):
		return http.StatusBadRequest, "invalid_local_request"
	case errors.Is(err, localinference.ErrWorkerUnavailable):
		return http.StatusBadGateway, "local_model_unavailable"
	default:
		return http.StatusBadGateway, "provider_error"
	}
}
