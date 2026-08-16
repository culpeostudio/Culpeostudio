package scout

import (
	"log"
	"strings"

	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/contexttokens"
	"github.com/culpeohq/backend/internal/localinference"
)

const (
	// How text is measured against a window lives in contexttokens, because
	// the agent loop has to arrive at the same number for the same
	// conversation - see the package comment there.
	charactersPerToken       = contexttokens.CharactersPerToken
	tokensPerMessageOverhead = contexttokens.PerMessageOverhead

	// Last resort when neither the model, the provider connection nor the
	// catalogue reports a window - and the catalogue is empty too, so there is
	// nothing to average.
	fallbackContextTokens = 32768
)

// Where a session's context window came from. It travels to the UI with the
// usage, so the meter can say whether the number is the model's own or an
// estimate standing in for one.
const (
	// The engine started this local instance with exactly this many tokens.
	contextSourceLocal = "local"
	// The user's own provider connection reported it during catalogue sync.
	contextSourceProvider = "provider"
	// The OpenRouter catalogue - the same snapshot the thinking levels come
	// from - reported it for this model.
	contextSourceCatalog = "catalog"
	// Nothing reported one, so the mean over every model the catalogue does
	// know stands in.
	contextSourceAverage = "average"
)

// contextBudget is how much a session's model can hold, and where that number
// was read from.
type contextBudget struct {
	LimitTokens int
	Source      string
}

// contextUsage is what the chat currently occupies of that budget. It is an
// estimate on both sides: the limit may be an average, and the used tokens are
// counted by the character rule rather than by the model's own tokenizer.
type contextUsage struct {
	LimitTokens int
	UsedTokens  int
	Source      string
	// ModelLimitTokens is what the model itself would allow where LimitTokens
	// is only what this instance was started with. Zero when the two are the
	// same or nothing reported a separate maximum.
	ModelLimitTokens int
	// Compactions is how often this session has been folded so far, so the UI
	// can explain a meter that just dropped.
	Compactions int
	// Compacted marks the turn that did the folding.
	Compacted bool
}

func (u contextUsage) payload() map[string]interface{} {
	return map[string]interface{}{
		"limit_tokens":       u.LimitTokens,
		"used_tokens":        u.UsedTokens,
		"source":             u.Source,
		"model_limit_tokens": u.ModelLimitTokens,
		"compactions":        u.Compactions,
		"compacted":          u.Compacted,
	}
}

// emitContextUsage reports one reading to the client. A dropped reading is not
// worth failing a turn over: the next one corrects it, and GetHistory carries
// the same number for a client that reconnects.
func emitContextUsage(emitEvent func(string, interface{}) error, usage contextUsage) {
	if emitEvent == nil || usage.LimitTokens <= 0 {
		return
	}
	if err := emitEvent("context_usage", usage.payload()); err != nil {
		log.Printf("[scout] Kontextauslastung konnte nicht gemeldet werden: %v", err)
	}
}

func estimateTokens(text string) int { return contexttokens.Estimate(text) }

func estimateMessageTokens(messages []chatMessage) int {
	total := 0
	for _, message := range messages {
		total += contexttokens.EstimateMessage(message.Content)
	}
	return total
}

// resolveContextBudget answers how large the window of the model that is about
// to be asked is. A local instance knows its own number because the engine
// started it with one; a hosted model is looked up where its thinking levels
// come from; anything left over is measured against the catalogue average
// rather than a made-up constant, which would be either far too small for a
// modern model or far too large for a tiny one.
func (m *ScoutModule) resolveContextBudget(userID, provider, connectionID, modelID string, localLimit int) contextBudget {
	if apimodels.NormalizeProvider(provider) == localinference.ProviderLocal {
		if localLimit > 0 {
			return contextBudget{LimitTokens: localLimit, Source: contextSourceLocal}
		}
		// A local instance id means nothing to the hosted catalogue, so the
		// average is the honest answer until the engine has started it.
		return m.averageContextBudget()
	}

	if window := m.connectionContextWindow(userID, connectionID, modelID); window > 0 {
		return contextBudget{LimitTokens: window, Source: contextSourceProvider}
	}

	if m.reasoningCatalog != nil {
		if length := m.reasoningCatalog.ContextLengthFor(modelID); length > 0 {
			return contextBudget{LimitTokens: length, Source: contextSourceCatalog}
		}
	}
	return m.averageContextBudget()
}

func (m *ScoutModule) averageContextBudget() contextBudget {
	if m.reasoningCatalog != nil {
		if average := m.reasoningCatalog.AverageContextLength(); average > 0 {
			return contextBudget{LimitTokens: average, Source: contextSourceAverage}
		}
	}
	return contextBudget{LimitTokens: fallbackContextTokens, Source: contextSourceAverage}
}

// connectionContextWindow reads the window a user-configured endpoint reported
// for one of its models during catalogue sync. It goes through ListModels so
// no API key is handled here.
func (m *ScoutModule) connectionContextWindow(userID, connectionID, modelID string) int {
	if m.providerConnections == nil {
		return 0
	}
	connectionID = strings.TrimSpace(connectionID)
	modelID = strings.TrimSpace(modelID)
	if connectionID == "" || modelID == "" {
		return 0
	}
	_, models, err := m.providerConnections.ListModels(userID, connectionID)
	if err != nil {
		return 0
	}
	for _, model := range models {
		if model.ID == modelID {
			return model.ContextWindow
		}
	}
	return 0
}

// contextUsageForSession measures a session against a budget. The caller must
// not hold m.mu.
func (m *ScoutModule) contextUsageForSession(userID, sessionID string, budget contextBudget, compacted bool) contextUsage {
	m.mu.Lock()
	defer m.mu.Unlock()
	usage := contextUsage{LimitTokens: budget.LimitTokens, Source: budget.Source, Compacted: compacted}
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		return usage
	}
	usage.UsedTokens = sessionUsedTokensLocked(session)
	usage.Compactions = session.Compactions
	if session.ModelContextLimit > usage.LimitTokens {
		usage.ModelLimitTokens = session.ModelContextLimit
	}
	return usage
}

// sessionCompactions is how often this session has been folded so far. The
// agent loop reports it back with its own readings, so the meter does not
// forget mid-run.
func (m *ScoutModule) sessionCompactions(userID, sessionID string) int {
	m.mu.Lock()
	defer m.mu.Unlock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		return 0
	}
	return session.Compactions
}

// sessionUsedTokensLocked is what the next turn will actually send: the running
// summary of everything already folded, plus every message since.
func sessionUsedTokensLocked(session *scoutSession) int {
	pending := session.Messages
	if session.SummarizedThrough > 0 && session.SummarizedThrough <= len(pending) {
		pending = pending[session.SummarizedThrough:]
	}
	used := estimateMessageTokens(pending)
	if summary := strings.TrimSpace(session.Summary); summary != "" {
		used += estimateTokens(summary) + tokensPerMessageOverhead
	}
	return used
}
