package philox

import (
	"encoding/json"
	"fmt"
	"time"
)

// ── SSE Event Types ─────────────────────────────────────────────────────────

const (
	EventStatus      = "status"
	EventToolStart   = "tool_start"
	EventToolResult  = "tool_result"
	EventTextDelta   = "text_delta"
	EventThinking    = "thinking"
	EventCompression = "compression"
	EventPlanning    = "planning"
	EventDone        = "done"
	EventError       = "error"
)

// StreamEvent is a single SSE event sent to the frontend.
type StreamEvent struct {
	Type      string      `json:"type"`
	Data      interface{} `json:"data"`
	Timestamp time.Time   `json:"timestamp"`
}

// StatusData signals what the agent is currently doing.
type StatusData struct {
	Action string `json:"action"`
	Detail string `json:"detail,omitempty"`
	Round  int    `json:"round,omitempty"`
}

// ToolStartData signals a tool invocation is starting.
type ToolStartData struct {
	ToolName  string                 `json:"tool_name"`
	Arguments map[string]interface{} `json:"arguments,omitempty"`
	CallID    string                 `json:"call_id,omitempty"`
	Round     int                    `json:"round"`
}

// ToolResultData signals a tool invocation has finished.
type ToolResultData struct {
	ToolName      string `json:"tool_name"`
	CallID        string `json:"call_id,omitempty"`
	Success       bool   `json:"success"`
	ResultPreview string `json:"result_preview,omitempty"`
	Round         int    `json:"round"`
}

// TextDeltaData delivers a chunk of the assistant's reply.
type TextDeltaData struct {
	Chunk string `json:"chunk"`
}

// ThinkingData delivers reasoning/thinking content.
type ThinkingData struct {
	Content string `json:"content"`
}

// DoneData is the final event with full result metadata.
type DoneData struct {
	SessionID      string         `json:"session_id"`
	Reply          string         `json:"reply"`
	Mode           SessionMode    `json:"mode"`
	ThinkingLevel  ThinkingLevel  `json:"thinking_level"`
	EffectiveModel string         `json:"effective_model"`
	Planning       *PlanningState `json:"planning,omitempty"`
	ToolEventCount int            `json:"tool_event_count"`
	ContextUsage   float64        `json:"context_usage"`
}

// ErrorData carries an error message.
type ErrorData struct {
	Message string `json:"message"`
}

// ── Event Emitter ───────────────────────────────────────────────────────────

// EventSink receives stream events. The agent loop writes to it,
// the HTTP handler reads from it and writes SSE lines.
type EventSink struct {
	ch     chan StreamEvent
	closed bool
}

func newEventSink(bufferSize int) *EventSink {
	return &EventSink{
		ch: make(chan StreamEvent, bufferSize),
	}
}

// Emit sends an event into the sink. Safe to call after Close (no-op).
func (s *EventSink) Emit(eventType string, data interface{}) {
	if s.closed {
		return
	}
	select {
	case s.ch <- StreamEvent{
		Type:      eventType,
		Data:      data,
		Timestamp: nowUTC(),
	}:
	default:
		// Buffer full — drop event rather than block the agent.
	}
}

// Close signals no more events will be sent.
func (s *EventSink) Close() {
	if s.closed {
		return
	}
	s.closed = true
	close(s.ch)
}

// Events returns the receive-only channel for consumers.
func (s *EventSink) Events() <-chan StreamEvent {
	return s.ch
}

// ── SSE formatting ──────────────────────────────────────────────────────────

// FormatSSE encodes a StreamEvent as an SSE text block:
//
//	event: <type>\ndata: <json>\n\n
func FormatSSE(event StreamEvent) []byte {
	payload, err := json.Marshal(event)
	if err != nil {
		payload = []byte(fmt.Sprintf(`{"type":"error","data":{"message":%q},"timestamp":"%s"}`, err.Error(), event.Timestamp.Format(time.RFC3339Nano)))
	}
	return []byte(fmt.Sprintf("event: %s\ndata: %s\n\n", event.Type, payload))
}
