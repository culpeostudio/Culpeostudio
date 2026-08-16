package scout

import (
	"strings"

	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/localinference"
)

// How long an answer may get, as the composer offers it. This is deliberately
// three coarse steps rather than a token field: what a user knows is whether
// they want a short answer or the whole thing, not how many tokens that is.
const (
	OutputLevelShort  = "short"
	OutputLevelNormal = "normal"
	OutputLevelMax    = "max"
)

const (
	outputShortTokens  = 2048
	outputNormalTokens = 8192

	// Last resort when neither the model, the connection nor the catalogue
	// reports a ceiling. It is also what the Anthropic path falls back to,
	// where max_tokens is required rather than optional.
	fallbackMaxOutputTokens = 4096

	// Never hand the whole remaining window to the answer: the prompt is
	// measured by a character rule, not by the model's tokenizer, so a request
	// sized to the last token would land over the line often enough to matter.
	outputSafetyMarginTokens = 512

	// Even a nearly full chat must leave the model room to say something -
	// below this a turn would produce a fragment and nothing else.
	minimumOutputTokens = 256
)

// outputBudget is how long the next answer may be, and where the ceiling came
// from. The sources are the same four as for the context window.
type outputBudget struct {
	MaxTokens int
	Source    string
	// Capped marks a budget the remaining context window shortened, rather than
	// the model's own ceiling. That is the case worth surfacing: the model could
	// write more, the conversation is just in the way.
	Capped bool
}

func normalizeOutputLevel(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case OutputLevelShort, "kurz":
		return OutputLevelShort
	case OutputLevelMax, "maximum", "max_tokens":
		return OutputLevelMax
	default:
		return OutputLevelNormal
	}
}

// resolveOutputBudget answers how many tokens the next reply may use.
//
// Two ceilings apply and the lower wins: what the model will write at all, and
// what is left of its context window once the prompt is in it. Sending the
// model maximum into a nearly full window is how a request gets refused with
// context_length_exceeded instead of producing a short answer.
func (m *ScoutModule) resolveOutputBudget(
	userID, provider, connectionID, modelID, level string,
	context contextBudget,
	promptTokens int,
) outputBudget {
	ceiling := m.modelOutputCeiling(userID, provider, connectionID, modelID, context, promptTokens)

	wanted := ceiling.MaxTokens
	switch normalizeOutputLevel(level) {
	case OutputLevelShort:
		wanted = min(wanted, outputShortTokens)
	case OutputLevelNormal:
		wanted = min(wanted, outputNormalTokens)
	}

	budget := outputBudget{MaxTokens: wanted, Source: ceiling.Source}
	if context.LimitTokens > 0 {
		room := context.LimitTokens - promptTokens - outputSafetyMarginTokens
		if room < budget.MaxTokens {
			budget.MaxTokens = room
			budget.Capped = true
		}
	}
	if budget.MaxTokens < minimumOutputTokens {
		budget.MaxTokens = minimumOutputTokens
	}
	return budget
}

// modelOutputCeiling is the longest answer this model will produce at all,
// before the conversation's own length is taken into account.
func (m *ScoutModule) modelOutputCeiling(
	userID, provider, connectionID, modelID string,
	context contextBudget,
	promptTokens int,
) outputBudget {
	if apimodels.NormalizeProvider(provider) == localinference.ProviderLocal {
		// llama.cpp has no separate output limit: prompt and answer share the
		// one window the instance was started with.
		room := context.LimitTokens - promptTokens - outputSafetyMarginTokens
		if room > 0 {
			return outputBudget{MaxTokens: room, Source: contextSourceLocal}
		}
		return outputBudget{MaxTokens: minimumOutputTokens, Source: contextSourceLocal}
	}

	if ceiling := m.connectionMaxOutputTokens(userID, connectionID, modelID); ceiling > 0 {
		return outputBudget{MaxTokens: ceiling, Source: contextSourceProvider}
	}
	if m.reasoningCatalog != nil {
		if ceiling := m.reasoningCatalog.MaxOutputTokensFor(modelID); ceiling > 0 {
			return outputBudget{MaxTokens: ceiling, Source: contextSourceCatalog}
		}
		if average := m.reasoningCatalog.AverageMaxOutputTokens(); average > 0 {
			return outputBudget{MaxTokens: average, Source: contextSourceAverage}
		}
	}
	return outputBudget{MaxTokens: fallbackMaxOutputTokens, Source: contextSourceAverage}
}

// connectionMaxOutputTokens reads what a user-configured endpoint reported for
// one of its models during catalogue sync. Like the context window, it goes
// through ListModels so no API key is handled here.
func (m *ScoutModule) connectionMaxOutputTokens(userID, connectionID, modelID string) int {
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
			return model.MaxOutputTokens
		}
	}
	return 0
}
