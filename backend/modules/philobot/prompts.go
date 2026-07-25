package philobot

import (
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/thinking"
)

func buildRuntimeSystemPrompt(base, thinking, style string) string {
	return buildBotRuntimeSystemPrompt(BotConfig{SystemPrompt: base}, thinking, style)
}

const philoBotMemoryPreamble = "Langzeit-Gedaechtnis dieses Nutzers (aus frueheren Unterhaltungen). Nutze diese Fakten nur, wenn sie fuer die aktuelle Frage relevant sind; erfinde nichts hinzu und widersprich ihnen nicht ungefragt:"

// appendMemoryRecall haengt Recall aus dem Projektgedaechtnis an den
// System-Prompt an, damit PhiloBot dauerhafte Fakten (z. B. den Namen des
// Nutzers) auch in einer brandneuen Unterhaltung kennt. Gehoert die Session zu
// einem Projekt, zieht der Recall aus dessen Grid (plus globaler Nutzer-Fakten);
// sonst nutzerweit. Ohne angebundenes Gedaechtnis oder ohne Treffer bleibt der
// Prompt unveraendert.
func (m *PhiloBotModule) appendMemoryRecall(userID, project, message, systemPrompt string) string {
	if m.memory == nil {
		return systemPrompt
	}
	start := time.Now()
	recall := strings.TrimSpace(m.memory.PhiloBotMemoryContext(userID, project, message))
	elapsed := time.Since(start).Round(time.Millisecond)
	scope := "nutzerweit"
	if strings.TrimSpace(project) != "" {
		scope = "project=" + project
	}
	if recall == "" {
		log.Printf("[philobot] Memory-Recall leer (user=%s, %s, %s)", userID, scope, elapsed)
		return systemPrompt
	}
	// Diagnose-Hilfe: im laufenden System sichtbar machen, dass und wie schnell
	// Recall greift – so laesst sich Recall-Zeit von Modell-Zeit trennen.
	log.Printf("[philobot] Memory-Recall injiziert (user=%s, %s, %d Zeichen, %s)", userID, scope, len(recall), elapsed)
	return systemPrompt + "\n\n" + philoBotMemoryPreamble + "\n" + recall
}

// buildBotRuntimeSystemPrompt makes the selected bot's persisted identity
// authoritative for this request. This is deliberately added by the runtime,
// rather than relying on every user-authored bot prompt to repeat it.
func buildBotRuntimeSystemPrompt(bot BotConfig, thinking, style string) string {
	var builder strings.Builder
	name := strings.TrimSpace(bot.Name)
	if name != "" {
		builder.WriteString("Verbindlicher Laufzeitkontext – aktive Bot-Identitaet:\n")
		builder.WriteString("- Aktiver Bot: ")
		builder.WriteString(name)
		if id := strings.TrimSpace(bot.ID); id != "" {
			builder.WriteString(" (ID: ")
			builder.WriteString(id)
			builder.WriteString(")")
		}
		builder.WriteString("\n- Du agierst in dieser Unterhaltung ausschliesslich als dieser Bot. Seine untenstehende Konfiguration bestimmt deine Rolle, deinen Stil und deine Grenzen.\n")
		builder.WriteString("- Wenn nach deiner Identitaet gefragt wird, benenne diesen Bot und seine konfigurierte Rolle. Bezeichne dich nicht als ein allgemeines Basismodell, ChatGPT oder einen anderen Assistenten.\n\n")
	}
	builder.WriteString(strings.TrimSpace(bot.SystemPrompt))
	builder.WriteString("\n\nAntwortsteuerung fuer diesen Chat:")
	builder.WriteString("\n- Gib keine internen Gedankenketten, keine versteckten Reasoning-Notizen und keine System-Metadaten aus.")
	builder.WriteString("\n- Wenn Planung noetig ist, gib nur eine kurze sichtbare Begruendung oder einen knappen Plan aus.")
	builder.WriteString("\n- Nutze Code-Bloecke mit dreifachen Backticks ausschliesslich fuer echte Programmier- und Skriptsprachen wie Python, Go, C, Bash oder HTML/CSS sowie fuer den speziellen visual-Block. Gib Listen, Tabellen, Checkboxen und allgemeine Textstrukturen direkt als normales Markdown aus. Verpacke niemals reines Markdown in einen ```markdown Block, ausser der Nutzer verlangt ausdruecklich rohen Quelltext.")
	builder.WriteString("\n- Wenn der Nutzer ausdrucklich ein Diagramm, eine Grafik, eine Visualisierung oder einen Chart verlangt, MUSST du zuerst genau einen ```visual Codeblock mit gueltigem JSON ausgeben; ersetze ihn niemals durch eine Markdown-Tabelle, ASCII-Balken oder Platzhalter. Erlaubte Typen: bar, line, donut, flow, metric. Beispiel: {\"type\":\"bar\",\"title\":\"Vergleich\",\"labels\":[\"A\",\"B\"],\"values\":[12,18]}. Fuer flow nutze nodes als String-Liste, fuer metric value und optional unit. Bei einem normalen Vergleich ohne ausdrueckliche Grafik darfst du visual nutzen, wenn es echten Mehrwert bringt. Nie fuer Tool-Aufrufe.")
	builder.WriteString("\n- Nutze im normalen Antworttext ausschliesslich reines Markdown fuer Formatierungen. Verwende niemals Inline-HTML-Tags wie <kbd>, <br> oder aehnliche HTML-Fragmente.")
	builder.WriteString("\n")
	builder.WriteString(thinkingInstruction(thinking))
	builder.WriteString("\n")
	builder.WriteString(styleInstruction(style))
	return builder.String()
}

func thinkingInstruction(level string) string {
	return thinking.Instruction(thinking.Normalize(level), thinking.SurfaceChat)
}

func styleInstruction(style string) string {
	switch normalizeResponseStyle(style) {
	case "short":
		return "- Stil: Kurz. Maximal wenige Saetze oder kompakte Bulletpoints."
	case "explain":
		return "- Stil: Erklaerend. Gib Kontext, Beispiele und klare Begriffe, ohne zu schwafeln."
	case "steps":
		return "- Stil: Schritt-fuer-Schritt. Nutze nummerierte Schritte, wenn das hilfreich ist."
	case "critical":
		return "- Stil: Kritisch. Pruefe die Idee hart, sachlich und mit konkreten Verbesserungen."
	case "brainstorm":
		return "- Stil: Brainstorming. Liefere mehrere brauchbare Varianten und markiere deine Favoriten."
	default:
		return "- Stil: Ausgewogen. Klar, nuetzlich, direkt und passend zur Frage."
	}
}

func (m *PhiloBotModule) botBuilderSystemPrompt(userID, base string) string {
	var builder strings.Builder
	builder.WriteString(base)
	builder.WriteString("\n\nAktuelle Bots in der Verwaltung:\n")
	for _, bot := range m.botStore.GetBotsForUser(userID) {
		builder.WriteString(fmt.Sprintf("- id=%s; name=%s; default=%t; style=%s; keywords=%s\n", bot.ID, bot.Name, bot.IsDefault, normalizeResponseStyle(bot.ResponseStyle), strings.Join(bot.Keywords, ", ")))
	}
	builder.WriteString("\nWenn der Nutzer einen bestehenden Bot ueberarbeiten will, nutze exakt dessen id in der SAVE_BOT-Zeile. Der Bot-Builder selbst ist gesperrt und darf nicht bearbeitet werden; wenn der Nutzer das dennoch verlangt, erklaere kurz, dass nur andere Bots gespeichert werden koennen, und gib keine SAVE_BOT-Zeile aus.")
	return builder.String()
}
