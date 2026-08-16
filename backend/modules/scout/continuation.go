package scout

import (
	"context"
	"log"
	"strings"
)

// maxOutputContinuations bounds how often one turn may be resumed. A model that
// never stops would otherwise keep buying itself another round at the user's
// expense; three is enough for an answer that genuinely needs the room.
const maxOutputContinuations = 3

const continuationInstruction = `Deine vorige Antwort wurde mitten im Text abgeschnitten, weil das Ausgabelimit erreicht war.

Schreibe exakt dort weiter, wo sie aufgehoert hat:
- Keine Wiederholung des bereits Geschriebenen, keine Zusammenfassung davon.
- Keine Einleitung, keine Entschuldigung, kein "Fortsetzung:".
- Setze mitten im Satz fort, wenn er mitten im Satz endet. Ein offener Codeblock bleibt offen und wird einfach weitergeschrieben.`

// streamTurnWithContinuation runs one provider turn and resumes it while the
// model keeps reporting that it ran into its output limit.
//
// The parts are concatenated and streamed into the same message, so the user
// sees one answer rather than three - which is the whole point: an answer that
// is longer than one response allows should not look different from one that
// fits.
func (m *ScoutModule) streamTurnWithContinuation(ctx context.Context, turn providerTurn) (string, bool, error) {
	reply, finishReason, err := m.streamProviderChat(ctx, turn)
	if err != nil {
		return "", false, err
	}
	if finishReason != finishReasonLength {
		return reply, false, nil
	}

	assembled := reply
	for round := 1; round <= maxOutputContinuations; round++ {
		// Every continuation carries what was written so far back into the
		// prompt, so it eats into the same window the answer has to fit in.
		// Charging it against the ceiling is what keeps the last round from
		// asking for room that no longer exists.
		remaining := turn.MaxOutputTokens - estimateTokens(assembled)
		if turn.MaxOutputTokens > 0 && remaining < minimumOutputTokens {
			log.Printf("[scout] Fortsetzung ausgelassen: kein Platz mehr im Fenster (model=%s)", turn.ModelID)
			return assembled, true, nil
		}

		// The model is handed what it wrote so far as its own last message, so
		// it resumes rather than restarts. The instruction goes in as a user
		// turn because that is the only role every protocol accepts after an
		// assistant message.
		next := turn
		next.MaxOutputTokens = remaining
		next.Messages = append(append([]chatMessage{}, turn.Messages...),
			chatMessage{Role: "assistant", Content: assembled},
			chatMessage{Role: "user", Content: continuationInstruction},
		)

		part, partReason, partErr := m.streamProviderChat(ctx, next)
		if partErr != nil {
			// The continuation failed, but what came before is a real answer.
			// Returning it truncated beats failing the whole turn.
			log.Printf("[scout] Fortsetzung %d fehlgeschlagen (model=%s): %v", round, turn.ModelID, partErr)
			return assembled, true, nil
		}
		assembled += part
		if partReason != finishReasonLength {
			return assembled, false, nil
		}
	}

	log.Printf("[scout] Antwort nach %d Fortsetzungen immer noch abgeschnitten (model=%s)", maxOutputContinuations, turn.ModelID)
	return assembled, true, nil
}

// truncationNotice is appended to an answer that is still cut off after the
// last continuation, because an answer that simply stops mid-sentence with no
// explanation reads like a bug.
func truncationNotice(reply string) string {
	if strings.TrimSpace(reply) == "" {
		return reply
	}
	return reply + "\n\n_Die Antwort wurde abgeschnitten: das Ausgabelimit des Modells ist auch nach mehreren Fortsetzungen erreicht. Frage gezielt nach dem fehlenden Teil._"
}
