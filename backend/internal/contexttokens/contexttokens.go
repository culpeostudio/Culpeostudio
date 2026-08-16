// Package contexttokens is the one place that decides how a piece of text is
// measured against a model's context window.
//
// It exists because two packages have to agree on that number: the chat, which
// folds older turns away once the conversation no longer fits, and the agent
// loop, which trims its tool results for the same reason. If they measured
// differently, one would report a window as three quarters full while the other
// still thought there was room, and the disagreement would only surface as a
// provider refusing a request.
//
// The rule is deliberately the cheap one - four characters per token - and not
// a real tokenizer. It is applied to whole conversations on every turn, it has
// to hold for models with different vocabularies, and the numbers it guards
// (when to compact, how much answer to allow) all carry their own safety
// margin. See internal/memorytoken for the accurate, more expensive count used
// where a single text is measured once.
package contexttokens

// CharactersPerToken is the same ratio the engine gateway measures a request
// against before it forwards it to a local worker.
const CharactersPerToken = 4

// PerMessageOverhead covers the role marker and separators a provider wraps
// each message in. Leaving it out is what makes a conversation overrun a window
// it looked to fit in.
const PerMessageOverhead = 4

// Estimate returns how many tokens a text is worth, rounded up. Empty text
// costs nothing.
func Estimate(text string) int {
	characters := len([]rune(text))
	if characters <= 0 {
		return 0
	}
	return (characters + CharactersPerToken - 1) / CharactersPerToken
}

// EstimateMessage is Estimate plus the per-message overhead, for text that
// travels as its own conversation turn.
func EstimateMessage(text string) int {
	return Estimate(text) + PerMessageOverhead
}
