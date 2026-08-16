package scout

import (
	"context"
	"fmt"
	"log"
	"strings"
)

const (
	// Compaction runs once the conversation fills this much of the window. The
	// remaining fifth is headroom for the system prompt, the memory recall and
	// the answer itself, none of which are part of what gets folded.
	compactionTriggerRatio = 0.8

	// The newest messages a compaction always leaves verbatim. Folding the turn
	// the user is still talking about is what makes a compacted chat read as
	// amnesic.
	compactionKeepRecent = 6

	// Under this a chat is not worth a summarisation round trip, whatever the
	// window says - a tiny local model with a 2k context would otherwise fold
	// after two questions.
	compactionMinMessages = 10

	// The retelling is lossy by nature; letting it grow with the chat would
	// give back the space compaction just freed.
	compactionSummaryMaxCharacters = 4000
)

const compactionSystemPrompt = `Du verdichtest den aelteren Teil einer Unterhaltung, damit sie in das Kontextfenster des Modells passt.

Schreibe eine Zusammenfassung, die als alleiniger Ersatz fuer die urspruenglichen Nachrichten dienen kann:
- Halte fest, worum es geht, was entschieden wurde, welche Fakten der Nutzer genannt hat und was noch offen ist.
- Bewahre Namen, Pfade, Zahlen, Versionen und Codebezeichner woertlich; sie sind spaeter nicht mehr nachschlagbar.
- Behalte die Perspektive der Unterhaltung bei: "Der Nutzer ...", "Der Assistent ...".
- Keine Anrede, keine Einleitung, keine Rueckfrage, kein Kommentar zur Aufgabe selbst.
- Hoechstens 400 Woerter, dichte Stichpunkte statt Fliesstext.`

// compactSessionIfNeeded folds the older half of a conversation into a running
// summary when it no longer fits the model's context window comfortably.
//
// It is best effort by design: a failed summarisation is logged and the turn
// continues on the sliding message window it used before, because losing the
// answer is worse than sending a conversation that is slightly too long.
// Returns whether this call actually folded anything.
func (m *ScoutModule) compactSessionIfNeeded(
	ctx context.Context,
	userID, sessionID string,
	budget contextBudget,
	provider, connectionID, modelID string,
) bool {
	if budget.LimitTokens <= 0 {
		return false
	}

	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return false
	}
	messages := append([]chatMessage{}, session.Messages...)
	previousSummary := session.Summary
	summarizedThrough := session.SummarizedThrough
	used := sessionUsedTokensLocked(session)
	m.mu.Unlock()

	if len(messages) < compactionMinMessages {
		return false
	}
	if used < int(float64(budget.LimitTokens)*compactionTriggerRatio) {
		return false
	}
	if summarizedThrough < 0 || summarizedThrough > len(messages) {
		summarizedThrough = 0
	}
	foldThrough := len(messages) - compactionKeepRecent
	if foldThrough <= summarizedThrough {
		// Everything foldable is already folded - the recent turns alone fill
		// the window. Nothing left to win here; the message window still caps
		// what goes out.
		return false
	}

	block := messages[summarizedThrough:foldThrough]
	summary, err := m.summarizeConversationBlock(ctx, userID, provider, connectionID, modelID, previousSummary, block)
	if err != nil {
		log.Printf("[scout] Verdichtung fehlgeschlagen (session=%s, model=%s): %v", sessionID, modelID, err)
		return false
	}
	if strings.TrimSpace(summary) == "" {
		return false
	}

	m.mu.Lock()
	session = m.sessions[sessionID]
	if session == nil || session.UserID != userID || len(session.Messages) < foldThrough {
		// The session was edited out from under the summary - dropping it is
		// the only safe move, the folded messages may no longer exist.
		m.mu.Unlock()
		return false
	}
	session.Summary = summary
	session.SummarizedThrough = foldThrough
	session.Compactions++
	compactions := session.Compactions
	m.mu.Unlock()
	m.persistSession(sessionID)

	log.Printf("[scout] Verlauf verdichtet (session=%s, %d Nachrichten -> %d Zeichen, %d. Verdichtung, Limit %d Tokens/%s)",
		sessionID, len(block), len(summary), compactions, budget.LimitTokens, budget.Source)
	return true
}

// summarizeConversationBlock asks the session's own model to retell a block of
// messages. Using the same model keeps the summary in the language and register
// of the chat, and needs no second provider to be configured.
func (m *ScoutModule) summarizeConversationBlock(
	ctx context.Context,
	userID, provider, connectionID, modelID string,
	previousSummary string,
	block []chatMessage,
) (string, error) {
	if len(block) == 0 {
		return "", nil
	}
	request := buildCompactionRequest(previousSummary, block)
	// No emit callbacks: the retelling is internal and must never appear in the
	// chat. Thinking is off - this is a mechanical task and the reasoning would
	// only cost tokens on a window that is already full. The ceiling matches
	// what truncateSummary keeps, so the model is not asked to write text that
	// is thrown away, and never continued: a summary that hits its limit is
	// already longer than it should be.
	summary, _, err := m.streamProviderChat(ctx, providerTurn{
		UserID:          userID,
		Provider:        provider,
		ConnectionID:    connectionID,
		ModelID:         modelID,
		Messages:        []chatMessage{{Role: "user", Content: request}},
		SystemPrompt:    compactionSystemPrompt,
		ThinkingLevel:   "none",
		MaxOutputTokens: compactionSummaryMaxCharacters / charactersPerToken,
	})
	if err != nil {
		return "", err
	}
	return truncateSummary(stripThinkBlocks(summary)), nil
}

func buildCompactionRequest(previousSummary string, block []chatMessage) string {
	var builder strings.Builder
	if summary := strings.TrimSpace(previousSummary); summary != "" {
		builder.WriteString("Bisherige Zusammenfassung der noch aelteren Unterhaltung:\n")
		builder.WriteString(summary)
		builder.WriteString("\n\nArbeite die folgenden Nachrichten in diese Zusammenfassung ein und gib die vollstaendige, aktualisierte Fassung aus:\n\n")
	} else {
		builder.WriteString("Fasse die folgenden Nachrichten zusammen:\n\n")
	}
	for _, message := range block {
		builder.WriteString(compactionSpeaker(message))
		builder.WriteString(": ")
		builder.WriteString(strings.TrimSpace(message.Content))
		builder.WriteString("\n\n")
	}
	return strings.TrimSpace(builder.String())
}

func compactionSpeaker(message chatMessage) string {
	switch strings.ToLower(strings.TrimSpace(message.Role)) {
	case "user":
		return "Nutzer"
	case "assistant":
		if name := strings.TrimSpace(message.BotName); name != "" {
			return "Assistent (" + name + ")"
		}
		return "Assistent"
	case "system":
		return "System"
	default:
		return "Unbekannt"
	}
}

func truncateSummary(summary string) string {
	summary = strings.TrimSpace(summary)
	runes := []rune(summary)
	if len(runes) <= compactionSummaryMaxCharacters {
		return summary
	}
	return strings.TrimSpace(string(runes[:compactionSummaryMaxCharacters])) + " […]"
}

// modelHistory is the conversation as the model gets to see it: the running
// summary of what was folded away, plus the messages since, still capped by the
// sliding window so a chat that grows faster than compaction can fold it stays
// bounded.
func (m *ScoutModule) modelHistory(userID, sessionID string) (string, []chatMessage) {
	m.mu.Lock()
	defer m.mu.Unlock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		return "", nil
	}
	pending := session.Messages
	if session.SummarizedThrough > 0 && session.SummarizedThrough <= len(pending) {
		pending = pending[session.SummarizedThrough:]
	}
	return session.Summary, windowMessages(pending, maxModelHistoryMessages)
}

// appendConversationSummary carries the folded history in the system prompt
// rather than as an extra message. Not every provider protocol keeps a second
// system message - the Anthropic and Gemini paths drop every role that is not
// user or assistant - and a summary that silently disappears for two of three
// providers would be worse than none.
func appendConversationSummary(systemPrompt, summary string) string {
	summary = strings.TrimSpace(summary)
	if summary == "" {
		return systemPrompt
	}
	return fmt.Sprintf("%s\n\n%s\n%s", systemPrompt, compactionRecallPreamble, summary)
}

const compactionRecallPreamble = "Verdichteter Verlauf dieser Unterhaltung (die aelteren Nachrichten wurden zusammengefasst, weil das Kontextfenster voll war). Behandle diese Punkte als bereits Gesagtes und beziehe dich darauf, als staende es woertlich im Verlauf:"
