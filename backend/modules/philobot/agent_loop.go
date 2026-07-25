package philobot

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
)

// toolCallOpen ist das Sentinel, mit dem eine Modell-Antwort beginnen MUSS, wenn
// sie ein Datei-Tool aufrufen will. Alles andere gilt als normale Endantwort.
const toolCallOpen = "<tool_call>"

// maxToolLoopIterations begrenzt die Anzahl der Tool-Runden pro Nutzernachricht,
// damit ein sich wiederholendes Modell nicht endlos Tools aufruft.
const maxToolLoopIterations = 12

// toolInvocation ist ein aus der Modell-Ausgabe geparster Tool-Aufruf.
type toolInvocation struct {
	Name      string
	Arguments map[string]interface{}
}

// projectFileToolNames listet die im Projekt-Kontext verfuegbaren Datei-Tools.
var projectFileToolNames = []string{
	"list_dir", "read_file", "stat_path",
	"write_file", "patch_file", "make_dir", "move_path", "delete_path",
	"grep_search", "find_files", "run_command",
}

// buildToolLoopSystemPrompt haengt an den Basis-System-Prompt die Tool-Anleitung
// an: das Aufruf-Protokoll, die verfuegbaren Tools und den Projekt-Root. Der
// Bot behaelt seine Persoenlichkeit (Basis-Prompt), bekommt aber die Faehigkeit,
// im Projekt-Ordner zu arbeiten.
func buildToolLoopSystemPrompt(base string, roots []string) string {
	var b strings.Builder
	b.WriteString(strings.TrimSpace(base))
	if b.Len() > 0 {
		b.WriteString("\n\n")
	}
	b.WriteString("## Datei-Werkzeuge (Projekt-Modus)\n")
	b.WriteString("Du arbeitest an einem Projekt und kannst dessen Dateien lesen und aendern. ")
	b.WriteString("Alle Pfade sind relativ zum Projekt-Ordner und duerfen ihn nicht verlassen. Projekt-Root:\n")
	for _, root := range roots {
		b.WriteString("- " + root + "\n")
	}
	b.WriteString("\nVerfuegbare Tools (Argumente als JSON-Objekt):\n")
	b.WriteString("- list_dir {\"path\":\"...\"} — Verzeichnis auflisten\n")
	b.WriteString("- read_file {\"path\":\"...\"} — Datei lesen (immer VOR dem Aendern lesen)\n")
	b.WriteString("- stat_path {\"path\":\"...\"} — Metadaten einer Datei/eines Ordners\n")
	b.WriteString("- write_file {\"path\":\"...\",\"content\":\"...\"} — Datei komplett schreiben/anlegen\n")
	b.WriteString("- patch_file {\"path\":\"...\",\"old_text\":\"...\",\"new_text\":\"...\"} — Textstelle ersetzen\n")
	b.WriteString("- make_dir {\"path\":\"...\"} — Ordner anlegen\n")
	b.WriteString("- move_path {\"source_path\":\"...\",\"destination_path\":\"...\"} — verschieben/umbenennen\n")
	b.WriteString("- delete_path {\"path\":\"...\"} — loeschen\n")
	b.WriteString("- grep_search {\"pattern\":\"...\"} — Volltextsuche im Projekt (optional \"glob\":\"*.dart\", \"is_regex\":true)\n")
	b.WriteString("- find_files {\"pattern\":\"*.dart\"} — Dateien per Muster finden (** fuer beliebige Tiefe)\n")
	b.WriteString("- run_command {\"command\":\"...\",\"args\":[...]} — Befehl ohne Shell im Projekt-Root ausfuehren\n")
	b.WriteString("\nZugriffe ausserhalb des Projekt-Roots loesen beim Nutzer eine Erlaubnis-Anfrage aus. ")
	b.WriteString("Wenn sie abgelehnt wird, arbeite im Projekt-Ordner weiter statt es erneut zu versuchen.\n")
	b.WriteString("\n## Aufruf-Protokoll\n")
	b.WriteString("Wenn du ein Tool nutzen willst, antworte AUSSCHLIESSLICH mit genau einem Aufruf, ")
	b.WriteString("beginnend mit dem Sentinel als allererstem Zeichen, ohne Text davor oder danach:\n")
	b.WriteString(toolCallOpen + "{\"name\":\"read_file\",\"arguments\":{\"path\":\"README.md\"}}</tool_call>\n")
	b.WriteString("Du bekommst das Tool-Ergebnis als [TOOL_RESULT ...] zurueck und kannst dann das naechste ")
	b.WriteString("Tool aufrufen. Wenn die Aufgabe erledigt ist, antworte NORMAL in natuerlicher Sprache ")
	b.WriteString("(ohne Sentinel) — das ist deine Endantwort an den Nutzer.")
	return b.String()
}

// parseToolCall erkennt einen Tool-Aufruf in der Modell-Ausgabe. Der Sentinel
// darf an beliebiger Stelle stehen: viele Modelle stellen dem Aufruf eine kurze
// Einleitung voran ("Los geht's: <tool_call>...") statt strikt mit dem Sentinel
// zu beginnen. Entscheidend ist ein vollstaendiger <tool_call>{...} Block mit
// gueltigem JSON und Tool-Namen. Der Stream-Filter blendet den rohen JSON-Block
// passend ab dem Sentinel aus, egal ob Prosa davor steht.
func parseToolCall(reply string) (toolInvocation, bool) {
	sentinel := strings.Index(reply, toolCallOpen)
	if sentinel == -1 {
		return toolInvocation{}, false
	}
	jsonStart := strings.Index(reply[sentinel:], "{")
	if jsonStart == -1 {
		return toolInvocation{}, false
	}
	jsonStart += sentinel
	jsonEnd, ok := findJSONObjectEnd(reply, jsonStart)
	if !ok {
		return toolInvocation{}, false
	}
	var payload struct {
		Name      string                 `json:"name"`
		Arguments map[string]interface{} `json:"arguments"`
	}
	if err := json.Unmarshal([]byte(reply[jsonStart:jsonEnd]), &payload); err != nil {
		return toolInvocation{}, false
	}
	if strings.TrimSpace(payload.Name) == "" {
		return toolInvocation{}, false
	}
	if payload.Arguments == nil {
		payload.Arguments = map[string]interface{}{}
	}
	return toolInvocation{Name: strings.TrimSpace(payload.Name), Arguments: payload.Arguments}, true
}

// toolCallStreamFilter entscheidet waehrend des Streamings, welcher Teil der
// Modell-Antwort beim Nutzer ankommt: normaler Text wird durchgereicht, der
// eigentliche <tool_call>{...} Aufruf wird ab dem Sentinel unterdrueckt — egal
// ob er am Anfang steht oder nach einer kurzen Einleitung ("Los geht's: ..."),
// damit der rohe JSON-Aufruf nie im Chat auftaucht. Ein am Chunk-Ende erst
// angefangener Sentinel wird zurueckgehalten, bis der naechste Chunk ihn
// bestaetigt oder verwirft.
type toolCallStreamFilter struct {
	emit       func(string) error
	buf        strings.Builder
	emitted    int  // bereits sichtbar ausgegebene Bytes von buf
	suppressed bool // Sentinel gesehen: alles ab dort bleibt unsichtbar
}

func newToolCallStreamFilter(emit func(string) error) *toolCallStreamFilter {
	if emit == nil {
		emit = func(string) error { return nil }
	}
	return &toolCallStreamFilter{emit: emit}
}

func (f *toolCallStreamFilter) Emit(chunk string) error {
	if f.suppressed {
		return nil // Tool-Aufruf laeuft: roher JSON-Text bleibt unsichtbar.
	}
	f.buf.WriteString(chunk)
	s := f.buf.String()
	if idx := strings.Index(s, toolCallOpen); idx != -1 {
		f.suppressed = true
		return f.flushVisibleUpTo(idx)
	}
	// Kein vollstaendiger Sentinel: alles ausser einem evtl. angefangenen
	// Sentinel am Ende sichtbar machen.
	return f.flushVisibleUpTo(len(s) - trailingTagPrefixLen(s, toolCallOpen))
}

// Flush gibt am Rundenende den zurueckgehaltenen Rest sichtbar aus — ausser es
// lief ein Tool-Aufruf, dann bleibt der unterdrueckte Teil unsichtbar.
func (f *toolCallStreamFilter) Flush() error {
	if f.suppressed {
		return nil
	}
	return f.flushVisibleUpTo(f.buf.Len())
}

// flushVisibleUpTo streamt buf[emitted:end] an den Nutzer und merkt sich den
// Fortschritt. end liegt stets auf einer ASCII-Grenze (Sentinel-Anfang, Puffer-
// Ende oder direkt vor einem angefangenen Sentinel), also nie mitten in einer
// Mehrbyte-Rune.
func (f *toolCallStreamFilter) flushVisibleUpTo(end int) error {
	if end <= f.emitted {
		return nil
	}
	out := f.buf.String()[f.emitted:end]
	f.emitted = end
	return f.emit(out)
}

// runProjectToolLoop treibt den Datei-Tool-Loop im Projekt-Kontext. Es ist ein
// duenner Wrapper um runToolLoop, der die Modell-Runde an streamProviderChat
// bindet; die eigentliche Schleifenlogik ist so ohne echtes Modell testbar.
// asker/sessionID verdrahten die Permission-Anfragen bei Zugriffen ausserhalb
// des Projekt-Roots (nil = harter Sandbox-Fehler wie bisher).
func (m *PhiloBotModule) runProjectToolLoop(
	ctx context.Context,
	provider, modelID string,
	history []chatMessage,
	baseSystemPrompt, thinking string,
	roots []string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	asker permissionAsker,
	sessionID string,
) (string, error) {
	return runToolLoop(ctx, history, baseSystemPrompt, roots, emitText, emitEvent,
		func(convo []chatMessage, systemPrompt string, filterEmit func(string) error) (string, error) {
			emitReasoning := func(chunk string) error {
				if emitEvent == nil {
					return nil
				}
				return emitEvent("reasoning_delta", map[string]interface{}{"chunk": chunk})
			}
			// thinkFilter sitzt VOR dem Tool-Call-Filter: ein Denkblock kann einem
			// <tool_call> vorausgehen, muss also zuerst herausgeloest werden, bevor
			// filterEmit entscheidet, ob der Rest ein Tool-Aufruf oder Endantwort ist.
			thinkFilter := newThinkTagFilter(filterEmit, emitReasoning)
			reply, err := m.streamProviderChat(ctx, provider, modelID, convo, systemPrompt, thinking, thinkFilter.Emit, emitReasoning)
			if err == nil {
				err = thinkFilter.Flush()
			}
			return reply, err
		}, asker, sessionID)
}

// chatTurnFunc fuehrt eine einzelne Modell-Runde aus: sichtbarer Text geht ueber
// filterEmit an den Nutzer, der volle Antworttext wird zurueckgegeben.
type chatTurnFunc func(convo []chatMessage, systemPrompt string, filterEmit func(string) error) (string, error)

// runToolLoop treibt die Schleife: Modell aufrufen, evtl. Tool ausfuehren,
// Ergebnis zurueckspeisen, bis das Modell eine normale Antwort gibt oder das
// Iterationslimit erreicht ist. emitText streamt sichtbaren Text an den Nutzer,
// emitEvent (optional) meldet tool_start/tool_result ans Frontend.
func runToolLoop(
	ctx context.Context,
	history []chatMessage,
	baseSystemPrompt string,
	roots []string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn chatTurnFunc,
	asker permissionAsker,
	sessionID string,
) (string, error) {
	executor, err := newFileToolExecutorWithPermissions(ctx, roots, asker, emitEvent, sessionID)
	if err != nil {
		return "", err
	}
	systemPrompt := buildToolLoopSystemPrompt(baseSystemPrompt, executor.roots)
	convo := append([]chatMessage{}, history...)

	for iteration := 0; iteration < maxToolLoopIterations; iteration++ {
		filter := newToolCallStreamFilter(emitText)
		reply, err := chatTurn(convo, systemPrompt, filter.Emit)
		if err != nil {
			return "", err
		}
		// Zurueckgehaltenen Rest sichtbar machen (bei einer normalen Endantwort
		// den evtl. gepufferten Sentinel-Praefix; bei einem Tool-Aufruf nichts).
		if err := filter.Flush(); err != nil {
			return "", err
		}

		call, ok := parseToolCall(reply)
		if !ok {
			// Normale Endantwort — wurde vom Filter bereits gestreamt.
			return reply, nil
		}

		if emitEvent != nil {
			_ = emitEvent("tool_start", map[string]interface{}{
				"tool":      call.Name,
				"arguments": call.Arguments,
			})
		}
		result := executor.Execute(call.Name, call.Arguments)
		okFlag, _ := result["ok"].(bool)
		log.Printf("[philobot] Projekt-Tool ausgefuehrt (tool=%s, ok=%v, iter=%d)", call.Name, okFlag, iteration+1)
		if emitEvent != nil {
			_ = emitEvent("tool_result", map[string]interface{}{
				"tool":    call.Name,
				"ok":      okFlag,
				"preview": resultPreview(result, 400),
			})
		}

		resultJSON, _ := json.Marshal(result)
		// Assistant-Tool-Turn + Ergebnis als user-Nachricht anhaengen. role "user"
		// ist der robusteste Kanal fuer Tool-Ergebnisse ueber lokale Modelle und
		// API-Provider hinweg (nicht alle akzeptieren role "tool").
		convo = append(convo,
			chatMessage{Role: "assistant", Content: reply},
			chatMessage{Role: "user", Content: fmt.Sprintf("[TOOL_RESULT %s]\n%s", call.Name, string(resultJSON))},
		)
	}

	// Iterationslimit erreicht: saubere Abschlussnachricht statt rohem Tool-JSON.
	final := "Ich habe das Schrittlimit fuer Datei-Operationen erreicht und die Aufgabe moeglicherweise nicht vollstaendig abgeschlossen. Sag mir, wie ich weitermachen soll."
	if emitText != nil {
		_ = emitText(final)
	}
	log.Printf("[philobot] Projekt-Tool-Loop hat das Iterationslimit (%d) erreicht", maxToolLoopIterations)
	return final, nil
}
