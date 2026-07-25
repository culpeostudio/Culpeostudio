package philox

import (
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

type ThinkingLevel string

type SessionMode string
type PlanningStatus string

const (
	ThinkingFast     ThinkingLevel = "fast"
	ThinkingBalanced ThinkingLevel = "balanced"
	ThinkingDeep     ThinkingLevel = "deep"

	ModeExecute SessionMode = "execute"
	ModePlan    SessionMode = "plan"

	PlanningStatusIdle         PlanningStatus = "idle"
	PlanningStatusNeedsAnswers PlanningStatus = "needs_answers"
	PlanningStatusReady        PlanningStatus = "ready"
	PlanningStatusApproved     PlanningStatus = "approved"
)

type PlanningOption struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Description string `json:"description,omitempty"`
}

type PlanningQuestion struct {
	ID          string           `json:"id"`
	Prompt      string           `json:"prompt"`
	Options     []PlanningOption `json:"options,omitempty"`
	AllowCustom bool             `json:"allow_custom"`
}

type PlanningDraft struct {
	Summary           string   `json:"summary,omitempty"`
	Goal              string   `json:"goal,omitempty"`
	ResearchNotes     []string `json:"research_notes,omitempty"`
	Steps             []string `json:"steps,omitempty"`
	Risks             []string `json:"risks,omitempty"`
	Tests             []string `json:"tests,omitempty"`
	ReadyForExecution bool     `json:"ready_for_execution"`
}

type PlanningState struct {
	Status    PlanningStatus     `json:"status"`
	Summary   string             `json:"summary,omitempty"`
	Questions []PlanningQuestion `json:"questions,omitempty"`
	Draft     *PlanningDraft     `json:"draft,omitempty"`
	UpdatedAt time.Time          `json:"updated_at"`
}

type ToolFunctionCall struct {
	Name      string `json:"name"`
	Arguments string `json:"arguments"`
}

type ToolCall struct {
	ID       string           `json:"id,omitempty"`
	Index    int              `json:"index,omitempty"`
	Type     string           `json:"type,omitempty"`
	Function ToolFunctionCall `json:"function"`
}

type ConversationMessage struct {
	Role       string                 `json:"role"`
	Content    string                 `json:"content,omitempty"`
	Name       string                 `json:"name,omitempty"`
	ToolCallID string                 `json:"tool_call_id,omitempty"`
	ToolCalls  []ToolCall             `json:"tool_calls,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt  time.Time              `json:"created_at"`
}

type CompressedMemory struct {
	ID                 string    `json:"id"`
	Summary            string    `json:"summary"`
	Goals              []string  `json:"goals"`
	OpenTasks          []string  `json:"open_tasks"`
	AllowedRoots       []string  `json:"allowed_roots"`
	SourceMessageCount int       `json:"source_message_count"`
	CreatedAt          time.Time `json:"created_at"`
}

type ToolAuditEntry struct {
	ToolName      string                 `json:"tool_name"`
	Arguments     map[string]interface{} `json:"arguments,omitempty"`
	Success       bool                   `json:"success"`
	ErrorCode     string                 `json:"error_code,omitempty"`
	ErrorMessage  string                 `json:"error_message,omitempty"`
	ResultPreview string                 `json:"result_preview,omitempty"`
	Timestamp     time.Time              `json:"timestamp"`
}

type CompressionEvent struct {
	Triggered          bool    `json:"triggered"`
	Threshold          float64 `json:"threshold"`
	UsageBefore        float64 `json:"usage_before"`
	UsageAfter         float64 `json:"usage_after"`
	CompressedMessages int     `json:"compressed_messages"`
	MemoryID           string  `json:"memory_id"`
}

type PersistedSession struct {
	mu                 sync.Mutex            `json:"-"`
	ID                 string                `json:"id"`
	UserID             string                `json:"user_id,omitempty"`
	ModelID            string                `json:"model_id,omitempty"`
	EffectiveModel     string                `json:"effective_model"`
	ThinkingLevel      ThinkingLevel         `json:"thinking_level"`
	Mode               SessionMode           `json:"mode"`
	AllowedRoots       []string              `json:"allowed_roots"`
	Messages           []ConversationMessage `json:"messages"`
	ArchivedMessages   []ConversationMessage `json:"archived_messages,omitempty"`
	CompressedMemories []CompressedMemory    `json:"compressed_memories,omitempty"`
	Planning           *PlanningState        `json:"planning,omitempty"`
	ToolAudit          []ToolAuditEntry      `json:"tool_audit,omitempty"`
	// MemoryContext haelt den Injektions-Prompt aus dem Projektgedaechtnis
	// fuer den aktuellen Lauf; bewusst nicht persistiert.
	MemoryContext string `json:"-"`
	// Bot identity is supplied by PhiloBot for the active request. It remains
	// runtime-only so a later, unrelated Philox session never inherits it.
	ActiveBotID           string    `json:"-"`
	ActiveBotName         string    `json:"-"`
	ActiveBotSystemPrompt string    `json:"-"`
	ContextUsageEstimate  float64   `json:"context_usage_estimate"`
	CreatedAt             time.Time `json:"created_at"`
	UpdatedAt             time.Time `json:"updated_at"`
}

type SessionSummary struct {
	ID                   string        `json:"id"`
	EffectiveModel       string        `json:"effective_model"`
	ThinkingLevel        ThinkingLevel `json:"thinking_level"`
	Mode                 SessionMode   `json:"mode"`
	AllowedRoots         []string      `json:"allowed_roots"`
	MessageCount         int           `json:"message_count"`
	CompressedCount      int           `json:"compressed_count"`
	ContextUsageEstimate float64       `json:"context_usage_estimate"`
	LastPreview          string        `json:"last_preview,omitempty"`
	CreatedAt            time.Time     `json:"created_at"`
	UpdatedAt            time.Time     `json:"updated_at"`
}

// normalizeThinkingLevel maps any raw or legacy UI value onto Philox's internal
// ThinkingLevel, which drives both the model swap and the request preset:
//   - none         -> Fast     ("no thinking", fast model)
//   - medium/fast  -> Balanced
//   - max/extra/deep/dual -> Deep
func normalizeThinkingLevel(raw string) ThinkingLevel {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "none", "off", "aus", "fast":
		return ThinkingFast
	case "max", "extra", "deep", "dual":
		return ThinkingDeep
	default: // medium, balanced, agent(s), unknown
		return ThinkingBalanced
	}
}

func normalizeSessionMode(raw string) SessionMode {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case string(ModePlan):
		return ModePlan
	default:
		return ModeExecute
	}
}

// effectiveModelForThinking returns the model selected for the session. The
// former hardcoded model-name defaults were removed; the model now comes purely
// from the request (empty when no model was selected).
func effectiveModelForThinking(modelID string) string {
	return strings.TrimSpace(modelID)
}

func defaultPlanningState() *PlanningState {
	return &PlanningState{
		Status:    PlanningStatusIdle,
		Questions: []PlanningQuestion{},
		UpdatedAt: nowUTC(),
	}
}

func (s *PersistedSession) Summary() SessionSummary {
	lastPreview := ""
	for i := len(s.Messages) - 1; i >= 0; i-- {
		if strings.TrimSpace(s.Messages[i].Content) != "" {
			lastPreview = previewText(s.Messages[i].Content, 120)
			break
		}
	}
	if lastPreview == "" && len(s.CompressedMemories) > 0 {
		lastPreview = previewText(s.CompressedMemories[len(s.CompressedMemories)-1].Summary, 120)
	}
	return SessionSummary{
		ID:                   s.ID,
		EffectiveModel:       s.EffectiveModel,
		ThinkingLevel:        s.ThinkingLevel,
		Mode:                 s.Mode,
		AllowedRoots:         append([]string{}, s.AllowedRoots...),
		MessageCount:         len(s.Messages),
		CompressedCount:      len(s.CompressedMemories),
		ContextUsageEstimate: s.ContextUsageEstimate,
		LastPreview:          lastPreview,
		CreatedAt:            s.CreatedAt,
		UpdatedAt:            s.UpdatedAt,
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// Agentic Types (für PhiloxAgenticService gRPC)
// ═══════════════════════════════════════════════════════════════════════════════

// AgenticMode definiert den Ausführungsmodus für agentic Requests
type AgenticMode string

const (
	AgenticModePlanning AgenticMode = "planning"
	AgenticModeExecute  AgenticMode = "execute"
)

// AgenticRequest entspricht proto.AgenticRequest
type AgenticRequest struct {
	SessionID     string            `json:"session_id"`
	UserMessage   string            `json:"user_message"`
	ThinkingLevel string            `json:"thinking_level"` // "agentic"
	Mode          AgenticMode       `json:"mode"`
	AllowedRoots  []string          `json:"allowed_roots"`
	Context       map[string]string `json:"context"`
}

// AgenticResponseType für Streaming-Events
type AgenticResponseType string

const (
	AgenticTextDelta         AgenticResponseType = "text_delta"
	AgenticToolStart         AgenticResponseType = "tool_start"
	AgenticToolResult        AgenticResponseType = "tool_result"
	AgenticPlanningQuestions AgenticResponseType = "planning_questions"
	AgenticPlanReady         AgenticResponseType = "plan_ready"
	AgenticApprovalNeeded    AgenticResponseType = "approval_needed"
	AgenticCompression       AgenticResponseType = "compression"
	AgenticError             AgenticResponseType = "error"
	AgenticDone              AgenticResponseType = "done"
)

// AgenticToolCall für Tool-Events
type AgenticToolCall struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	Arguments     string `json:"arguments"` // JSON
	ResultPreview string `json:"result_preview"`
	Success       bool   `json:"success"`
	Error         string `json:"error"`
}

// AgenticPlanningState für Planning-Events
type AgenticPlanningState struct {
	Status      string                    `json:"status"`
	Questions   []AgenticPlanningQuestion `json:"questions"`
	PlanSummary string                    `json:"plan_summary"`
	Steps       []string                  `json:"steps"`
	Risks       []string                  `json:"risks"`
	Tests       []string                  `json:"tests"`
}

type AgenticPlanningQuestion struct {
	ID          string                  `json:"id"`
	Prompt      string                  `json:"prompt"`
	Options     []AgenticPlanningOption `json:"options"`
	AllowCustom bool                    `json:"allow_custom"`
}

type AgenticPlanningOption struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Description string `json:"description"`
}

// AgenticCompressionEvent für Compression-Events
type AgenticCompressionEvent struct {
	Triggered          bool    `json:"triggered"`
	UsageBefore        float64 `json:"usage_before"`
	UsageAfter         float64 `json:"usage_after"`
	CompressedMessages int     `json:"compressed_messages"`
	MemoryID           string  `json:"memory_id"`
}

// AgenticResponse - vereinheitlicht für gRPC + HTTP SSE
type AgenticResponse struct {
	Type        AgenticResponseType      `json:"type"`
	Text        string                   `json:"text,omitempty"`
	ToolCall    *AgenticToolCall         `json:"tool_call,omitempty"`
	Planning    *AgenticPlanningState    `json:"planning,omitempty"`
	Compression *AgenticCompressionEvent `json:"compression,omitempty"`
	Error       string                   `json:"error,omitempty"`
	Done        bool                     `json:"done,omitempty"`
}

func newChatSessionID() string {
	return "chat-" + uuid.New().String()
}

func sessionID() string {
	return newChatSessionID()
}
