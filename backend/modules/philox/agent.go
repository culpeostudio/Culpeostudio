package philox

import (
	"context"
	"errors"
)

// errPhiloxAgentDisabled is returned by the Philox agent entry points. The
// external model backend that powered the agent has been removed; the Philox
// tab now only carries the thinking-level UI. Normal PhiloBot chat is
// unaffected — it runs on local models + Featherless, not on Philox.
var errPhiloxAgentDisabled = errors.New("Philox-Agent ist deaktiviert: es ist kein Modell-Backend mehr angebunden")

type agentResult struct {
	Reply            string            `json:"reply"`
	ToolEvents       []ToolAuditEntry  `json:"tool_events,omitempty"`
	CompressionEvent *CompressionEvent `json:"compression_event,omitempty"`
}

// runAgent previously drove the synchronous agent tool loop. The backend was
// removed, so it now simply reports that the agent is disabled.
func (m *PhiloxModule) runAgent(ctx context.Context, session *PersistedSession, userMessage, thinkingOverride, modeOverride string) (*agentResult, error) {
	return nil, errPhiloxAgentDisabled
}

// runAgentStreaming previously drove the SSE tool loop. It now emits a single
// error event (and a terminating done event) so both the HTTP stream and the
// agentic gRPC path get an immediate, clean signal instead of calling a dead API.
func (m *PhiloxModule) runAgentStreaming(ctx context.Context, session *PersistedSession, userMessage, thinkingOverride, modeOverride string, sink *EventSink) {
	defer sink.Close()
	sink.Emit(EventError, ErrorData{Message: errPhiloxAgentDisabled.Error()})
	sink.Emit(EventDone, DoneData{
		SessionID:     session.ID,
		Reply:         errPhiloxAgentDisabled.Error(),
		Mode:          session.Mode,
		ThinkingLevel: session.ThinkingLevel,
	})
}
