package philox

import (
	"fmt"
	"strings"

	"github.com/fillyengine/backend/internal/thinking"
)

// ── Core system prompt builder ──────────────────────────────────────────────

func systemPromptForSession(session *PersistedSession) string {
	var sections []string

	// Identity. A PhiloBot identity, when present, takes precedence over the
	// generic Philox identity for this request.
	sections = append(sections, identityInstruction(session))

	// Mode instruction (plan vs execute).
	if session.Mode == ModePlan {
		sections = append(sections, planningSystemInstruction())
	} else {
		sections = append(sections, executeInstruction())
	}

	// Thinking-level specific behaviour.
	sections = append(sections, thinkingInstruction(session.ThinkingLevel))

	// Reasoning enforcement — always active.
	sections = append(sections, reasoningInstruction())

	// Code quality rules — always active.
	sections = append(sections, codeQualityInstruction())

	// Frontend design injection — only when frontend context is detected.
	if lastUserMessage := lastUserContent(session); lastUserMessage != "" {
		if detectFrontendContext(session, lastUserMessage) {
			sections = append(sections, frontendDesignInstruction())
		}
	}

	// Read-before-write enforcement — always active in execute mode.
	if session.Mode != ModePlan {
		sections = append(sections, readBeforeWriteInstruction())
	}

	// Tool argument format rules.
	sections = append(sections, toolFormatInstruction())

	// Root paths.
	sections = append(sections, rootsInstruction(session.AllowedRoots))

	// Interaction rules.
	sections = append(sections, interactionInstruction())
	sections = append(sections, visualResponseInstruction())

	return strings.Join(sections, "\n\n")
}

func identityInstruction(session *PersistedSession) string {
	if session != nil && strings.TrimSpace(session.ActiveBotName) != "" {
		var builder strings.Builder
		builder.WriteString("## Verbindliche aktive Bot-Identitaet\n")
		builder.WriteString("Du agierst in dieser Unterhaltung ausschliesslich als ")
		builder.WriteString(strings.TrimSpace(session.ActiveBotName))
		if id := strings.TrimSpace(session.ActiveBotID); id != "" {
			builder.WriteString(" (Bot-ID: ")
			builder.WriteString(id)
			builder.WriteString(")")
		}
		builder.WriteString(". Diese Bot-Identitaet und die folgende Konfiguration sind fuer Antworten ueber deine Rolle, Faehigkeiten und Grenzen massgeblich. Stelle dich nicht als allgemeines Basismodell, ChatGPT oder Philox vor.\n\n")
		builder.WriteString("Bot-Konfiguration:\n")
		builder.WriteString(strings.TrimSpace(session.ActiveBotSystemPrompt))
		return builder.String()
	}
	return "Du bist Philox, ein Desktop-Agent fuer einen lokalen Nutzer."
}

// lastUserContent returns the content of the most recent user message in the session.
func lastUserContent(session *PersistedSession) string {
	for i := len(session.Messages) - 1; i >= 0; i-- {
		if session.Messages[i].Role == "user" {
			return session.Messages[i].Content
		}
	}
	return ""
}

// ── Execute mode instruction ────────────────────────────────────────────────

func executeInstruction() string {
	return "Du darfst Tools verwenden, wenn sie wirklich helfen. Nutze nur erlaubte Root-Pfade. Wenn du eine bestehende Datei aenderst, bevorzuge patch_file statt write_file."
}

// ── Thinking-level presets ──────────────────────────────────────────────────

func thinkingInstruction(level ThinkingLevel) string {
	return thinking.Instruction(modeForLevel(level), thinking.SurfaceAgent)
}

// modeForLevel maps Philox's internal ThinkingLevel (which also drives model and
// preset selection) onto the shared thinking taxonomy used to render the prompt.
func modeForLevel(level ThinkingLevel) thinking.Mode {
	switch level {
	case ThinkingFast:
		return thinking.ModeNone
	case ThinkingDeep:
		return thinking.ModeMax
	default:
		return thinking.ModeMedium
	}
}

// ── Reasoning enforcement ───────────────────────────────────────────────────

func reasoningInstruction() string {
	return strings.TrimSpace(`## Denkprozess
Bevor du eine Code-Aenderung vornimmst, durchlaufe IMMER diese Schritte mental:
- WAS ist das Ziel? Was genau soll sich aendern?
- WO greift die Aenderung? Welche Dateien, Funktionen, Typen sind betroffen?
- RISIKO: Was koennte kaputtgehen? Gibt es Abhaengigkeiten die ich noch nicht gesehen habe?
- PATTERN: Welchen Stil und welche Konventionen nutzt der bestehende Code? Halte dich daran.
- MINIMAL: Was ist die kleinstmoegliche Aenderung die das Ziel erreicht?
Ueberspringe diese Analyse niemals, auch nicht bei scheinbar einfachen Aufgaben.`)
}

// ── Code quality rules ──────────────────────────────────────────────────────

func codeQualityInstruction() string {
	return strings.TrimSpace(`## Code-Qualitaet
Schreibe produktionsreifen Code. Halte dich an diese Regeln:
- Fehlerbehandlung: Behandle jeden Fehler explizit. Keine ignorierten Fehler, keine stummen Fehlschlaege.
- Benennung: Verwende klare, beschreibende Namen. Orientiere dich an bestehenden Namenskonventionen im Projekt.
- Funktionsgroesse: Halte Funktionen kurz und fokussiert. Eine Funktion, eine Aufgabe.
- Konsistenz: Passe dich dem Stil des bestehenden Codes an — Einrueckung, Formatierung, Kommentarsprache, Patterns.
- Keine TODOs: Implementiere Dinge vollstaendig oder gar nicht. Hinterlasse keine Platzhalter oder TODO-Kommentare.
- Keine unnoetige Abstraktion: Schreibe nicht mehr Code als noetig. Kein Over-Engineering.
- Imports: Fuege nur Imports hinzu die du wirklich brauchst. Entferne keine bestehenden Imports die noch genutzt werden.
- Typsicherheit: Nutze strenge Typen statt interface{} oder any wo moeglich. Validiere Inputs.`)
}

// ── Read-before-write enforcement ───────────────────────────────────────────

func readBeforeWriteInstruction() string {
	return strings.TrimSpace(`## Pflicht: Lesen vor Schreiben
BEVOR du eine bestehende Datei mit write_file oder patch_file aenderst, MUSST du sie ZUERST mit read_file lesen.
Aendere niemals eine Datei blind — du brauchst den aktuellen Inhalt um:
- den richtigen old_text fuer patch_file zu finden
- sicherzustellen dass deine Aenderung zum bestehenden Code passt
- Konflikte mit anderen Teilen der Datei zu vermeiden
Einzige Ausnahme: Komplett neue Dateien die noch nicht existieren darfst du direkt mit write_file erstellen.
Wenn du in der gleichen Runde eine Datei bereits gelesen hast und seitdem keine Aenderungen daran vorgenommen wurden, darfst du auf das erneute Lesen verzichten.`)
}

// ── Tool argument format ────────────────────────────────────────────────────

func toolFormatInstruction() string {
	return strings.TrimSpace(`## Tool-Argumente Format
KRITISCH: Tool-Argumente muessen exakt ein gueltiges JSON-Objekt sein.
- Kein Markdown-Codeblock drumherum
- Kein Prefix wie 'json' oder 'arguments:'
- Keine Duplikate des JSON-Objekts
- Kein Text davor oder danach
- Backslashes in Windows-Pfaden muessen escaped werden: C:\\Users\\david
- Wenn der Dateiinhalt zu lang fuer einen einzelnen Aufruf ist, teile ihn in mehrere patch_file Aufrufe auf`)
}

// ── Root paths ──────────────────────────────────────────────────────────────

func rootsInstruction(roots []string) string {
	rootList := "Keine Root-Pfade freigegeben."
	if len(roots) > 0 {
		rootList = strings.Join(roots, ", ")
	}
	return fmt.Sprintf("Erlaubte Root-Pfade: %s. Greife niemals auf Pfade ausserhalb dieser Roots zu.", rootList)
}

// ── Interaction rules ───────────────────────────────────────────────────────

func interactionInstruction() string {
	return strings.TrimSpace(`Analysiere zuerst Ziel, Verlauf, vorhandene Session-Infos und bekannte Technik, bevor du Fragen stellst. Frage nicht nach Interface, Technologie, Framework oder Implementierungsstil, wenn die Anfrage oder der bisherige Kontext dafuer schon genug Hinweise geben. Stelle Rueckfragen nur wenn du sonst wirklich blockiert waerst oder eine falsche Aktion hohes Risiko haette. Wenn Pfade fehlen, frage gesammelt nach allen benoetigten Pfaden auf einmal. Wenn der Nutzer Pfade direkt in seiner Nachricht nennt, behandle sie als wichtige Kontextinformation.`)
}

func visualResponseInstruction() string {
	return "Wenn der Nutzer ausdrucklich ein Diagramm, eine Grafik, eine Visualisierung oder einen Chart verlangt, MUSST du zuerst genau einen ```visual Codeblock mit gueltigem JSON ausgeben; ersetze ihn niemals durch eine Markdown-Tabelle, ASCII-Balken oder Platzhalter. Erlaubte Typen: bar, line, donut, flow, metric. Beispiel: {\"type\":\"bar\",\"title\":\"Vergleich\",\"labels\":[\"A\",\"B\"],\"values\":[12,18]}. Fuer flow nutze nodes als String-Liste, fuer metric value und optional unit. Bei einem normalen Vergleich ohne ausdrueckliche Grafik darfst du visual nutzen, wenn es echten Mehrwert bringt. Nie fuer Tool-Aufrufe."
}

// ── Compressed memory prompt ────────────────────────────────────────────────

func compressedMemoryPrompt(memory CompressedMemory) string {
	goals := "-"
	if len(memory.Goals) > 0 {
		goals = strings.Join(memory.Goals, " | ")
	}
	tasks := "-"
	if len(memory.OpenTasks) > 0 {
		tasks = strings.Join(memory.OpenTasks, " | ")
	}
	roots := "-"
	if len(memory.AllowedRoots) > 0 {
		roots = strings.Join(memory.AllowedRoots, ", ")
	}
	return fmt.Sprintf("Komprimierter Verlauf: %s\nWichtige Ziele: %s\nOffene Aufgaben: %s\nErlaubte Roots damals: %s", memory.Summary, goals, tasks, roots)
}
