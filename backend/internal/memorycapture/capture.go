// Package memorycapture derives storable memories from a conversation turn.
package memorycapture

import (
	"encoding/json"
	"fmt"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memorychat"
)

type Service struct {
	memory         *memory.Service
	chatCompressor *memorychat.Compressor
}

type AssistantReplyInput struct {
	UserID    string `json:"user_id"`
	SessionID string `json:"session_id"`
	Reply     string `json:"reply"`
}

type EventBusInput struct {
	UserID    string                 `json:"user_id"`
	SessionID string                 `json:"session_id"`
	Project   string                 `json:"project"`
	Source    string                 `json:"source"`
	Type      string                 `json:"type"`
	Data      map[string]interface{} `json:"data"`
}

func New(service *memory.Service, chatWindow ...int) *Service {
	windowSize := 6
	overlapSize := 2
	if len(chatWindow) > 0 {
		windowSize = chatWindow[0]
	}
	if len(chatWindow) > 1 {
		overlapSize = chatWindow[1]
	}
	return &Service{
		memory:         service,
		chatCompressor: memorychat.NewCompressor(windowSize, overlapSize),
	}
}

func (s *Service) ClearSession(sessionID string) {
	if s.chatCompressor != nil {
		s.chatCompressor.ClearSession(sessionID)
	}
}

func (s *Service) CaptureAssistantReply(input AssistantReplyInput, source string) (*memory.Observation, error) {
	source = strings.TrimSpace(source)
	if source == "" {
		source = "spark"
	}
	if _, err := s.memory.EnsureSession(memory.CreateSessionInput{
		SessionID: input.SessionID,
		UserID:    input.UserID,
		Source:    source,
	}); err != nil {
		return nil, err
	}
	if _, _, err := s.memory.AddPrompt(input.SessionID, memory.AddPromptInput{
		UserID: input.UserID,
		Role:   memory.PromptRoleAssistant,
		Text:   input.Reply,
	}); err != nil {
		return nil, err
	}
	return s.memory.AddObservation(input.SessionID, memory.AddObservationInput{
		Source:    source,
		UserID:    input.UserID,
		Layer:     memory.LayerProjectData,
		Category:  memory.CategoryStatus,
		Type:      "assistant_reply",
		Title:     "Assistant reply",
		Narrative: input.Reply,
		Tags:      []string{source, "assistant"},
	})
}

func (s *Service) CaptureChatMessage(userID, sessionID, project, prompt, reply string) (*memory.ContextEnvelope, error) {
	prompt = sanitizeString("chat_prompt", prompt)
	reply = sanitizeString("chat_reply", reply)
	if _, err := s.memory.EnsureSession(memory.CreateSessionInput{
		UserID:    userID,
		SessionID: sessionID,
		Project:   project,
		Source:    "chat",
	}); err != nil {
		return nil, err
	}
	_, context, err := s.memory.AddPrompt(sessionID, memory.AddPromptInput{
		UserID: userID,
		Role:   memory.PromptRoleUser,
		Text:   prompt,
	})
	if err != nil {
		return nil, err
	}
	if strings.TrimSpace(reply) != "" {
		if _, _, err := s.memory.AddPrompt(sessionID, memory.AddPromptInput{
			UserID: userID,
			Role:   memory.PromptRoleAssistant,
			Text:   reply,
		}); err != nil {
			return nil, err
		}
	}
	for _, observationInput := range s.chatCompressor.CompressPair(sessionID, prompt, reply, time.Now().UTC()) {
		observationInput.UserID = userID
		observationInput.Project = project
		if _, err := s.memory.AddObservation(sessionID, observationInput); err != nil {
			return nil, err
		}
	}
	return context, nil
}

func (s *Service) CaptureEventBus(input EventBusInput) (*memory.Observation, error) {
	source := strings.TrimSpace(input.Source)
	if source == "" {
		source = "event-bus"
	}
	project := strings.TrimSpace(input.Project)
	if _, err := s.memory.EnsureSession(memory.CreateSessionInput{
		SessionID: input.SessionID,
		UserID:    input.UserID,
		Project:   project,
		Source:    source,
	}); err != nil {
		return nil, err
	}
	sanitized := sanitizeMap(input.Data)
	title := fmt.Sprintf("%s: %s", source, strings.TrimSpace(input.Type))
	narrative := renderEventNarrative(source, strings.TrimSpace(input.Type), sanitized)
	return s.memory.AddObservation(input.SessionID, memory.AddObservationInput{
		Project:   project,
		Source:    source,
		UserID:    input.UserID,
		Layer:     memory.LayerProjectData,
		Category:  categoryForEvent(source, input.Type),
		Type:      "event",
		Title:     title,
		Narrative: narrative,
		Tags:      []string{source, strings.TrimSpace(input.Type), "event"},
	})
}

func sanitizeMap(input map[string]interface{}) map[string]interface{} {
	if len(input) == 0 {
		return map[string]interface{}{}
	}
	result := map[string]interface{}{}
	keys := make([]string, 0, len(input))
	for key := range input {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		result[key] = sanitizeValue(key, input[key])
	}
	return result
}

func sanitizeValue(key string, value interface{}) interface{} {
	lowerKey := strings.ToLower(strings.TrimSpace(key))
	if isSensitiveKey(lowerKey) {
		return "[redacted]"
	}
	switch typed := value.(type) {
	case string:
		return sanitizeString(lowerKey, typed)
	case map[string]interface{}:
		return sanitizeMap(typed)
	case []interface{}:
		result := make([]interface{}, 0, len(typed))
		for _, item := range typed {
			result = append(result, sanitizeValue(lowerKey, item))
		}
		return result
	default:
		return value
	}
}

var (
	bearerRegex   = regexp.MustCompile(`(?i)(bearer\s+)([a-zA-Z0-9_\-\.\~\+\/\=]+)`)
	keyValueRegex = regexp.MustCompile(`(?i)(password|secret|totp|api_key|apikey|token|auth|authorization|cookie|otp)(\s*(?:[:=]|\b(?:is|ist)\b)\s*)([a-zA-Z0-9_\-\.\~\+\/\=]+|"[^"]*"|'[^']*')`)
)

func sanitizeString(key, value string) string {
	if isSensitiveKey(key) {
		return "[redacted]"
	}
	value = bearerRegex.ReplaceAllString(value, `${1}[redacted]`)
	value = keyValueRegex.ReplaceAllString(value, `${1}${2}[redacted]`)
	return value
}

func isSensitiveKey(key string) bool {
	sensitive := []string{"password", "secret", "token", "auth", "authorization", "cookie", "totp", "otp", "apikey", "api_key"}
	for _, item := range sensitive {
		if strings.Contains(key, item) {
			return true
		}
	}
	return false
}

func renderEventNarrative(source, eventType string, data map[string]interface{}) string {
	if strings.Contains(strings.ToLower(source), "login") {
		return "Login-bezogenes Event erfasst (redigiert)."
	}
	payload, _ := json.Marshal(data)
	if len(payload) == 0 || string(payload) == "null" || string(payload) == "{}" {
		return fmt.Sprintf("Event %s from %s", eventType, source)
	}
	return fmt.Sprintf("Event %s from %s with data %s", eventType, source, string(payload))
}

func categoryForEvent(source, eventType string) memory.MemoryCategory {
	lower := strings.ToLower(source + " " + eventType)
	switch {
	case strings.Contains(lower, "brainstorm"):
		return memory.CategoryBrainstorming
	case strings.Contains(lower, "aenderungsantrag"), strings.Contains(lower, "änderungsantrag"), strings.Contains(lower, "change_request"):
		return memory.CategoryChangeRequest
	default:
		return memory.CategoryStatus
	}
}
