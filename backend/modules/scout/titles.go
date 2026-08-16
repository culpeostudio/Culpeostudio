package scout

import (
	"context"
	"log"
	"strings"
	"time"
	"unicode"
)

const (
	// A title is a label in a sidebar, not a sentence. Past this the list would
	// only show an ellipsis anyway.
	sessionTitleMaxRunes = 46

	// How much of the opening exchange the model is shown. The first question
	// and the start of the answer already say what a chat is about; the rest
	// only costs tokens on a call the user is waiting behind.
	sessionTitleSourceRunes = 900

	// The label is asked for in a handful of words, so the ceiling only has to
	// stop a model that ignores that and starts writing prose.
	sessionTitleMaxOutputTokens = 32

	// Naming a chat must never outlive the answer it belongs to by much.
	sessionTitleTimeout = 45 * time.Second
)

const sessionTitleSystemPrompt = `Du benennst einen Chat, damit der Nutzer ihn spaeter in einer Liste wiederfindet.

Antworte mit genau einem Titel und sonst nichts:
- Drei bis fuenf Woerter, hoechstens 46 Zeichen.
- Benenne das Thema, nicht die Handlung: "Docker-Compose fuer Postgres" statt "Nutzer fragt nach Docker".
- Nimm das Konkrete auf: Namen, Technologien, Dateien, Zahlen.
- Keine Anfuehrungszeichen, kein Punkt am Ende, keine Emojis, keine Einleitung, keine Rueckfrage.
- Schreibe in der Sprache des Nutzers.`

// titleSessionAfterReply gives a fresh chat its name once the first exchange is
// on record.
//
// Before this the sidebar showed the first user message cut off at sixty
// characters, which is the one line in a chat that says the least about it: a
// chat that opens with a pasted stack trace was called by that stack trace. The
// model that just answered writes the label instead, because it has read both
// sides of the exchange and answers in the same language.
//
// It runs after the reply, not before it: the answer is part of what the label
// is drawn from, and the turn must not wait behind a second round trip. Failing
// is fine - [summarizeSession] still falls back to the opening message, and the
// user can always rename.
func (m *ScoutModule) titleSessionAfterReply(ctx context.Context, userID, sessionID string, emitEvent func(string, interface{}) error) {
	source, provider, connectionID, modelID, ok := m.claimSessionTitle(userID, sessionID)
	if !ok {
		return
	}

	// Detached from the request: the client has its answer and may hang up the
	// moment it arrives, but the name belongs to the stored chat either way.
	callCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), sessionTitleTimeout)
	defer cancel()

	// No emit callbacks and no thinking - this is a mechanical label, and a
	// reasoning model would spend more tokens deliberating than writing it.
	raw, _, err := m.streamProviderChat(callCtx, providerTurn{
		UserID:          userID,
		Provider:        provider,
		ConnectionID:    connectionID,
		ModelID:         modelID,
		Messages:        []chatMessage{{Role: "user", Content: source}},
		SystemPrompt:    sessionTitleSystemPrompt,
		ThinkingLevel:   "none",
		MaxOutputTokens: sessionTitleMaxOutputTokens,
	})
	if err != nil {
		log.Printf("[scout] Titel fuer Session %s konnte nicht erzeugt werden (model=%s): %v", sessionID, modelID, err)
		return
	}

	title := sanitizeSessionTitle(raw)
	if title == "" {
		log.Printf("[scout] Titelvorschlag fuer Session %s war unbrauchbar: %q", sessionID, raw)
		return
	}
	if !m.applySessionTitle(userID, sessionID, title) {
		return
	}
	m.persistSession(sessionID)
	log.Printf("[scout] Session %s benannt: %q", sessionID, title)

	if emitEvent == nil {
		return
	}
	if err := emitEvent("session_title", map[string]interface{}{
		"session_id": sessionID,
		"title":      title,
	}); err != nil {
		// The name is stored; only this one report did not make it, and the
		// client picks it up with the next session list.
		log.Printf("[scout] Titel fuer Session %s konnte nicht gesendet werden: %v", sessionID, err)
	}
}

// claimSessionTitle decides whether this session still needs a name and marks
// the attempt in the same lock, so two turns finishing at once cannot both go
// asking for one. It reports the opening exchange to name it from, along with
// the model that answered it.
func (m *ScoutModule) claimSessionTitle(userID, sessionID string) (source, provider, connectionID, modelID string, ok bool) {
	m.mu.Lock()
	defer m.mu.Unlock()

	session := m.sessions[strings.TrimSpace(sessionID)]
	if session == nil || session.UserID != userID {
		return "", "", "", "", false
	}
	// A name the user typed, or one written after an earlier turn, stands.
	if strings.TrimSpace(session.Title) != "" || session.TitleAttempted {
		return "", "", "", "", false
	}
	// The same condition the reply path uses to tell a real model from the stub
	// answer: without one there is nothing that could write a label.
	if strings.TrimSpace(session.ModelID) == "" ||
		(strings.TrimSpace(session.Provider) == "" && strings.TrimSpace(session.ConnectionID) == "") {
		return "", "", "", "", false
	}
	source = openingExchange(session.Messages)
	if source == "" {
		return "", "", "", "", false
	}
	// Only ever one attempt per session: a provider that cannot write a label
	// would otherwise be asked again on every single turn. The flag is not
	// persisted on failure, so a restart is worth one more try.
	session.TitleAttempted = true
	return source, session.Provider, session.ConnectionID, session.ModelID, true
}

// applySessionTitle stores the generated name unless something claimed the
// title while the model was writing it - a rename typed in the meantime is the
// user's decision and outranks a suggestion.
func (m *ScoutModule) applySessionTitle(userID, sessionID, title string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()

	session := m.sessions[strings.TrimSpace(sessionID)]
	if session == nil || session.UserID != userID {
		return false
	}
	if strings.TrimSpace(session.Title) != "" {
		return false
	}
	session.Title = title
	return true
}

// openingExchange is the first question and the beginning of its answer, which
// is what a chat is about often enough to name it from.
func openingExchange(messages []chatMessage) string {
	var question, answer string
	for _, message := range messages {
		content := strings.TrimSpace(message.Content)
		if content == "" {
			continue
		}
		switch message.Role {
		case "user":
			if question == "" {
				question = content
			}
		case "assistant":
			if question != "" && answer == "" {
				answer = content
			}
		}
		if question != "" && answer != "" {
			break
		}
	}
	if question == "" {
		return ""
	}

	var builder strings.Builder
	builder.WriteString("Nachricht des Nutzers:\n")
	builder.WriteString(truncateRunes(question, sessionTitleSourceRunes))
	if answer != "" {
		builder.WriteString("\n\nAntwort des Assistenten:\n")
		builder.WriteString(truncateRunes(answer, sessionTitleSourceRunes))
	}
	return builder.String()
}

// sanitizeSessionTitle turns whatever the model wrote into a label. Small
// models add quotes, a "Titel:" prefix or a second line of explanation however
// plainly the prompt forbids it, and a sidebar entry is not the place to find
// that out.
func sanitizeSessionTitle(raw string) string {
	title := strings.TrimSpace(stripThinkBlocks(raw))
	if index := strings.IndexAny(title, "\r\n"); index >= 0 {
		title = title[:index]
	}
	title = strings.TrimSpace(title)

	// Quotes first: the label often arrives wrapped whole, prefix included, as
	// in "Titel: Fehler im Login-Flow".
	title = trimTitleDecoration(title)
	lower := strings.ToLower(title)
	for _, prefix := range []string{"titel:", "title:", "chattitel:"} {
		if strings.HasPrefix(lower, prefix) {
			title = trimTitleDecoration(title[len(prefix):])
			break
		}
	}

	title = collapseWhitespace(title)
	title = strings.TrimRight(title, ".!?;:, ")
	if !strings.ContainsFunc(title, func(r rune) bool {
		return unicode.IsLetter(r) || unicode.IsDigit(r)
	}) {
		return ""
	}
	return truncateTitle(title, sessionTitleMaxRunes)
}

func trimTitleDecoration(text string) string {
	return strings.Trim(strings.TrimSpace(text), "\"'“”„«»*`_ ")
}

func collapseWhitespace(text string) string {
	return strings.Join(strings.Fields(text), " ")
}

func truncateRunes(text string, max int) string {
	runes := []rune(text)
	if max <= 0 || len(runes) <= max {
		return text
	}
	return strings.TrimSpace(string(runes[:max])) + " […]"
}

// truncateTitle cuts on a word boundary rather than mid-word: a list of chats
// is read at a glance, and a broken-off word reads as a rendering fault.
func truncateTitle(text string, max int) string {
	text = strings.TrimSpace(text)
	runes := []rune(text)
	if max <= 0 || len(runes) <= max {
		return text
	}
	cut := string(runes[:max])
	if index := strings.LastIndex(cut, " "); index > max/2 {
		cut = cut[:index]
	}
	return strings.TrimRight(strings.TrimSpace(cut), ".,;:!?-–—") + "…"
}
