package spark

import (
	"log"
	"strings"

	"github.com/culpeohq/backend/internal/contexttokens"
)

// ContextBudget is how much room the model answering a run has. The zero value
// means "unknown", and every guard below then does nothing - which is what the
// tool loop did before it was told about windows at all.
type ContextBudget struct {
	LimitTokens int
	// Source and Compactions are carried only so a reading emitted from inside
	// the loop says the same thing as one emitted by the chat around it - a
	// meter that forgets how often the chat was folded would flicker for the
	// length of an agent run.
	Source      string
	Compactions int
}

func (b ContextBudget) known() bool { return b.LimitTokens > 0 }

const (
	// The share of the window the tool loop's own conversation may occupy
	// before older results are shortened. The remaining share is headroom for
	// the system prompt, the tool instructions and the answer - none of which
	// are part of what gets shortened.
	toolLoopContextShare = 0.6

	// How many of the newest tool results stay whole. The agent is working on
	// the last one or two; the older ones it only needs to remember having
	// seen.
	toolResultsKeptVerbatim = 2

	// What a shortened result is cut down to. Enough to keep a path, an exit
	// code or the first lines of a file, which is what a later step refers back
	// to.
	shortenedToolResultChars = 600

	// toolResultPrefix marks the messages that carry a tool's output, which are
	// the only ones worth shortening: the model's own turns are what it needs
	// to stay coherent.
	toolResultPrefix = "[TOOL_RESULT "

	// shortenedMarker keeps a shortened result honest - the model is told the
	// text was cut, so it re-reads instead of assuming it saw everything.
	shortenedMarker = "\n… [gekuerzt, um im Kontextfenster zu bleiben. Bei Bedarf erneut lesen.]"
)

// estimateConversation is what the loop's conversation currently costs. It uses
// the same rule the chat measures its own history with, so the two agree on how
// full one window is.
func estimateConversation(convo []Message, systemPrompt string) int {
	total := contexttokens.Estimate(systemPrompt)
	for _, message := range convo {
		total += contexttokens.EstimateMessage(message.Content)
	}
	return total
}

// shrinkToolResults folds older tool output down until the conversation fits
// the share of the window the loop is allowed, and reports whether it had to.
//
// It shortens rather than drops: a step that reads three files and then writes
// one has to remember that it read them, but it does not need all three in full
// while it writes. Dropping the messages outright would leave the model with an
// assistant turn calling a tool and no result after it, which reads as a failed
// call.
func shrinkToolResults(convo []Message, systemPrompt string, budget ContextBudget) ([]Message, bool) {
	if !budget.known() {
		return convo, false
	}
	allowed := int(float64(budget.LimitTokens) * toolLoopContextShare)
	if allowed <= 0 || estimateConversation(convo, systemPrompt) <= allowed {
		return convo, false
	}

	// Newest results first would shorten exactly what the agent is working on,
	// so the walk goes oldest to newest and stops as soon as it fits.
	resultIndexes := make([]int, 0, len(convo))
	for index, message := range convo {
		if strings.HasPrefix(message.Content, toolResultPrefix) {
			resultIndexes = append(resultIndexes, index)
		}
	}
	if len(resultIndexes) <= toolResultsKeptVerbatim {
		return convo, false
	}

	shortened := append([]Message{}, convo...)
	changed := false
	for _, index := range resultIndexes[:len(resultIndexes)-toolResultsKeptVerbatim] {
		clipped := clipToolResult(shortened[index].Content)
		if clipped == shortened[index].Content {
			continue
		}
		shortened[index].Content = clipped
		changed = true
		if estimateConversation(shortened, systemPrompt) <= allowed {
			break
		}
	}
	if !changed {
		return convo, false
	}
	log.Printf("[spark] Werkzeug-Ergebnisse gekuerzt: %d -> %d Tokens (erlaubt %d von %d)",
		estimateConversation(convo, systemPrompt), estimateConversation(shortened, systemPrompt),
		allowed, budget.LimitTokens)
	return shortened, true
}

// clipToolResult keeps the header line - it names the tool the result belongs
// to - and shortens the payload under it.
func clipToolResult(content string) string {
	header, payload, found := strings.Cut(content, "\n")
	if !found {
		return content
	}
	runes := []rune(payload)
	if len(runes) <= shortenedToolResultChars {
		return content
	}
	return header + "\n" + string(runes[:shortenedToolResultChars]) + shortenedMarker
}

// emitLoopContextUsage reports how full the window is from inside the loop, so
// the meter in the composer keeps moving during a long agent run instead of
// standing still until the run is over.
func emitLoopContextUsage(
	emitEvent func(eventType string, data interface{}) error,
	convo []Message,
	systemPrompt string,
	budget ContextBudget,
) {
	if emitEvent == nil || !budget.known() {
		return
	}
	_ = emitEvent("context_usage", map[string]interface{}{
		"limit_tokens": budget.LimitTokens,
		"used_tokens":  estimateConversation(convo, systemPrompt),
		"source":       budget.Source,
		"compactions":  budget.Compactions,
		"compacted":    false,
	})
}
