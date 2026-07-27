package philobot

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/webtools"
)

// toolCallOpen ist das Sentinel, mit dem eine Modell-Antwort beginnen MUSS, wenn
// sie ein Datei-Tool aufrufen will. Alles andere gilt als normale Endantwort.
const toolCallOpen = "<tool_call>"

// maxToolLoopIterations begrenzt die Anzahl der Tool-Runden pro Nutzernachricht,
// damit ein sich wiederholendes Modell nicht endlos Tools aufruft.
const maxToolLoopIterations = 12

// maxConsecutiveToolFailures bricht ab, wenn dasselbe Werkzeug mehrfach
// hintereinander fehlschlaegt. Ein Modell, das dreimal am selben Aufruf
// scheitert, findet die Loesung auch beim vierten Versuch nicht - es
// verbraucht nur das Rundenbudget, das dem restlichen Auftrag fehlt.
const maxConsecutiveToolFailures = 3

// errToolLoopExhausted meldet, dass die Schleife am Rundenlimit oder an
// wiederholten Werkzeug-Fehlern abgebrochen ist, statt fertig zu werden.
//
// Im freien Chat ist das kein Fehler: der Nutzer bekommt den bis dahin
// erarbeiteten Text und kann nachfassen. Fuer einen Planschritt schon —
// er darf nicht als erledigt gelten, nur weil das Budget aufgebraucht ist.
var errToolLoopExhausted = errors.New("philobot: werkzeug-schleife ohne abschluss beendet")

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
// im Projekt-Ordner zu arbeiten und im Web zu recherchieren.
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
	b.WriteString("  Wichtig: old_text muss ZEICHENGENAU aus einem vorherigen read_file stammen (Einrueckung, Zeilenumbrueche). ")
	b.WriteString("Nimm die kleinste eindeutige Stelle, meist 2-5 Zeilen — nie eine ganze Funktion, ")
	b.WriteString("sonst wird deine Antwort abgeschnitten und new_text fehlt. Grosse Aenderungen: mehrere Aufrufe nacheinander.\n")
	b.WriteString("- make_dir {\"path\":\"...\"} — Ordner anlegen\n")
	b.WriteString("- move_path {\"source_path\":\"...\",\"destination_path\":\"...\"} — verschieben/umbenennen\n")
	b.WriteString("- delete_path {\"path\":\"...\"} — loeschen\n")
	b.WriteString("- grep_search {\"pattern\":\"...\"} — Volltextsuche im Projekt (optional \"glob\":\"*.dart\", \"is_regex\":true)\n")
	b.WriteString("- find_files {\"pattern\":\"*.dart\"} — Dateien per Muster finden (** fuer beliebige Tiefe)\n")
	b.WriteString("- run_command {\"command\":\"...\",\"args\":[...]} — Befehl ohne Shell im Projekt-Root ausfuehren\n")
	b.WriteString("\nZugriffe ausserhalb des Projekt-Roots loesen beim Nutzer eine Erlaubnis-Anfrage aus. ")
	b.WriteString("Wenn sie abgelehnt wird, arbeite im Projekt-Ordner weiter statt es erneut zu versuchen.\n")
	b.WriteString("\n" + webtools.PromptSection(true))
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

// buildWebOnlySystemPrompt haengt nur die Web-Werkzeuge an den Basis-Prompt.
// Er gilt im Chat ohne Projekt: dort gibt es keinen Sandbox-Root und damit
// keine Datei-Werkzeuge, recherchieren soll der Bot trotzdem koennen.
func buildWebOnlySystemPrompt(base string) string {
	var b strings.Builder
	b.WriteString(strings.TrimSpace(base))
	if b.Len() > 0 {
		b.WriteString("\n\n")
	}
	b.WriteString(webtools.PromptSection(false))
	b.WriteString("\n## Aufruf-Protokoll\n")
	b.WriteString("Wenn du ein Tool nutzen willst, antworte AUSSCHLIESSLICH mit genau einem Aufruf, ")
	b.WriteString("beginnend mit dem Sentinel als allererstem Zeichen, ohne Text davor oder danach:\n")
	b.WriteString(toolCallOpen + `{"name":"web_search","arguments":{"query":"flutter 4 release datum"}}</tool_call>` + "\n")
	b.WriteString("Du bekommst das Tool-Ergebnis als [TOOL_RESULT ...] zurueck und kannst dann das naechste ")
	b.WriteString("Tool aufrufen. Wenn du die Antwort hast, antworte NORMAL in natuerlicher Sprache ")
	b.WriteString("(ohne Sentinel) — das ist deine Endantwort an den Nutzer.")
	return b.String()
}

// newWebTools erzeugt die Web-Werkzeuge fuer eine Agenten-Schleife. Ein
// Fehler ist nicht toedlich: die Schleife laeuft dann ohne Recherche
// weiter, statt die Antwort komplett zu verweigern.
func newWebTools() *webtools.Tools {
	tools, err := webtools.New(webtools.Options{
		Proxy:   strings.TrimSpace(os.Getenv("PHILOSEARCH_PROXY")),
		Timeout: 10 * time.Second,
		// Suchregion und Budgets sind konfigurierbar - wie im ganzen
		// Backend ueber Environment-Variablen, nicht ueber eine eigene
		// Konfigurationsdatei.
		Region:     strings.TrimSpace(os.Getenv("WEBTOOLS_REGION")),
		MaxResults: envInt("WEBTOOLS_MAX_RESULTS"),
		FetchChars: envInt("WEBTOOLS_FETCH_CHARS"),
	})
	if err != nil {
		log.Printf("[philobot] Web-Werkzeuge nicht verfuegbar: %v", err)
		return nil
	}
	return tools
}

// envInt liest eine Environment-Variable als Zahl. 0 bedeutet "nicht
// gesetzt" und ueberlaesst dem Aufgerufenen seinen Standardwert.
func envInt(key string) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return 0
	}
	n, err := strconv.Atoi(value)
	if err != nil {
		log.Printf("[philobot] %s=%q ist keine Zahl, Standardwert wird genutzt", key, value)
		return 0
	}
	return n
}

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
	return swallowExhausted(runToolLoopWithLimit(ctx, history, baseSystemPrompt, roots, emitText, emitEvent,
		chatTurn, asker, sessionID, maxToolLoopIterations))
}

// runToolLoopWithLimit ist runToolLoop mit eigenem Iterationslimit. Ein
// einzelner Planschritt bekommt weniger Runden als eine freie Unterhaltung.
func runToolLoopWithLimit(
	ctx context.Context,
	history []chatMessage,
	baseSystemPrompt string,
	roots []string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn chatTurnFunc,
	asker permissionAsker,
	sessionID string,
	maxIterations int,
) (string, error) {
	executor, err := newFileToolExecutorWithPermissions(ctx, roots, asker, emitEvent, sessionID)
	if err != nil {
		return "", err
	}
	web := newWebTools()
	systemPrompt := buildToolLoopSystemPrompt(baseSystemPrompt, executor.roots)
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		if web != nil && web.Handles(name) {
			return web.Execute(ctx, name, args)
		}
		return executor.Execute(name, args)
	}
	return driveToolLoop(ctx, history, systemPrompt, emitText, emitEvent, chatTurn, dispatch, maxIterations)
}

// runWebOnlyToolLoop treibt dieselbe Schleife ohne Datei-Werkzeuge. Er gilt
// im Chat ohne Projekt-Kontext: ohne Sandbox-Root darf nichts auf die Platte
// zugreifen, recherchieren im Web ist aber gefahrlos moeglich.
func runWebOnlyToolLoop(
	ctx context.Context,
	history []chatMessage,
	baseSystemPrompt string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn chatTurnFunc,
) (string, error) {
	return swallowExhausted(runWebOnlyToolLoopWithLimit(ctx, history, baseSystemPrompt, emitText, emitEvent,
		chatTurn, maxToolLoopIterations))
}

// runWebOnlyToolLoopWithLimit ist runWebOnlyToolLoop mit eigenem
// Iterationslimit.
func runWebOnlyToolLoopWithLimit(
	ctx context.Context,
	history []chatMessage,
	baseSystemPrompt string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn chatTurnFunc,
	maxIterations int,
) (string, error) {
	web := newWebTools()
	if web == nil {
		// Ohne Web-Werkzeuge bleibt nichts zu tun: eine einzelne Modell-Runde
		// ohne Tool-Anleitung im Prompt.
		filter := newToolCallStreamFilter(emitText)
		reply, err := chatTurn(history, baseSystemPrompt, filter.Emit)
		if err != nil {
			return "", err
		}
		return reply, filter.Flush()
	}
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		if !web.Handles(name) {
			return map[string]interface{}{
				"ok":         false,
				"error":      "Tool \"" + name + "\" steht ohne geoeffnetes Projekt nicht zur Verfuegung",
				"error_code": "tool_unavailable",
				"hint":       "Ohne Projekt-Kontext gibt es nur web_search und web_fetch.",
			}
		}
		return web.Execute(ctx, name, args)
	}
	return driveToolLoop(ctx, history, buildWebOnlySystemPrompt(baseSystemPrompt),
		emitText, emitEvent, chatTurn, dispatch, maxIterations)
}

// driveToolLoop ist die gemeinsame Schleifenmechanik von Projekt- und
// Web-Modus. Sie ruft das Modell, fuehrt angeforderte Tools ueber dispatch
// aus und speist die Ergebnisse zurueck, bis eine normale Antwort kommt
// oder das Iterationslimit greift.
func driveToolLoop(
	ctx context.Context,
	history []chatMessage,
	systemPrompt string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn chatTurnFunc,
	dispatch func(name string, args map[string]interface{}) map[string]interface{},
	maxIterations int,
) (string, error) {
	if maxIterations <= 0 {
		maxIterations = maxToolLoopIterations
	}
	convo := append([]chatMessage{}, history...)
	// Zaehlt, wie oft dasselbe Werkzeug in Folge fehlgeschlagen ist.
	failedTool := ""
	failureStreak := 0

	for iteration := 0; iteration < maxIterations; iteration++ {
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
		result := dispatch(call.Name, call.Arguments)
		okFlag, _ := result["ok"].(bool)
		if okFlag {
			log.Printf("[philobot] Tool ausgefuehrt (tool=%s, ok=true, iter=%d)", call.Name, iteration+1)
			failedTool, failureStreak = "", 0
		} else {
			// Den Fehlertext mitloggen: ohne ihn ist im Nachhinein nicht
			// nachvollziehbar, woran ein Werkzeug gescheitert ist. Bei
			// Argumentfehlern zusaetzlich, was das Modell geschickt hat -
			// sonst bleibt offen, welchen Feldnamen es stattdessen nutzt.
			errText, _ := result["error"].(string)
			if code, _ := result["error_code"].(string); code == "invalid_tool_arguments" {
				argsJSON, _ := json.Marshal(call.Arguments)
				log.Printf("[philobot] Tool fehlgeschlagen (tool=%s, iter=%d): %s | Argumente: %s",
					call.Name, iteration+1, errText, string(argsJSON))
			} else {
				log.Printf("[philobot] Tool fehlgeschlagen (tool=%s, iter=%d): %s", call.Name, iteration+1, errText)
			}
			if call.Name == failedTool {
				failureStreak++
			} else {
				failedTool, failureStreak = call.Name, 1
			}
		}
		if emitEvent != nil {
			_ = emitEvent("tool_result", map[string]interface{}{
				"tool":    call.Name,
				"ok":      okFlag,
				"preview": resultPreview(result, 400),
			})
		}

		if failureStreak >= maxConsecutiveToolFailures {
			final := fmt.Sprintf("Das Werkzeug %s ist %d Mal hintereinander fehlgeschlagen. Ich breche hier ab, statt es weiter zu versuchen.", call.Name, failureStreak)
			if emitText != nil {
				_ = emitText(final)
			}
			log.Printf("[philobot] Abbruch: %s scheiterte %dx in Folge", call.Name, failureStreak)
			return final, errToolLoopExhausted
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
	final := "Ich habe das Schrittlimit fuer Werkzeug-Aufrufe erreicht und die Aufgabe moeglicherweise nicht vollstaendig abgeschlossen. Sag mir, wie ich weitermachen soll."
	if emitText != nil {
		_ = emitText(final)
	}
	log.Printf("[philobot] Werkzeug-Schleife hat das Iterationslimit (%d) erreicht", maxIterations)
	return final, errToolLoopExhausted
}

// swallowExhausted behandelt einen Schleifen-Abbruch im freien Chat als
// Erfolg: der Nutzer bekommt den erarbeiteten Text und kann nachfassen.
// Die *WithLimit-Varianten reichen den Abbruch dagegen durch, damit ein
// Planschritt nicht faelschlich als erledigt gilt.
func swallowExhausted(reply string, err error) (string, error) {
	if errors.Is(err, errToolLoopExhausted) {
		return reply, nil
	}
	return reply, err
}
