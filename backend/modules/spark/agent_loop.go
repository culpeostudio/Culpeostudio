package spark

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

	"github.com/culpeohq/backend/modules/spark/tools"

	"github.com/culpeohq/backend/internal/pathmention"
	"github.com/culpeohq/backend/internal/streamtext"
	"github.com/culpeohq/backend/internal/webtools"
)

// resolveToolRoots collects the folders the agent may touch: the project folder
// the session is bound to plus any path the user named in the message.
func resolveToolRoots(projectPath, message string) []string {
	var roots []string
	if strings.TrimSpace(projectPath) != "" {
		roots = append(roots, projectPath)
	}
	mentioned := pathmention.Extract(message)
	if len(mentioned) > 0 {
		log.Printf("[spark] In der Nachricht genannte Ordner freigegeben: %v", mentioned)
	}
	return append(roots, mentioned...)
}

const toolCallOpen = "<tool_call>"

const maxToolLoopIterations = 12

const maxConsecutiveToolFailures = 3

var errToolLoopExhausted = errors.New("spark: werkzeug-schleife ohne abschluss beendet")

type toolInvocation struct {
	Name      string
	Arguments map[string]interface{}
}

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
	jsonEnd, ok := streamtext.FindJSONObjectEnd(reply, jsonStart)
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

type toolCallStreamFilter struct {
	emit       func(string) error
	buf        strings.Builder
	emitted    int
	suppressed bool
}

func newToolCallStreamFilter(emit func(string) error) *toolCallStreamFilter {
	if emit == nil {
		emit = func(string) error { return nil }
	}
	return &toolCallStreamFilter{emit: emit}
}

func (f *toolCallStreamFilter) Emit(chunk string) error {
	if f.suppressed {
		return nil
	}
	f.buf.WriteString(chunk)
	s := f.buf.String()
	if idx := strings.Index(s, toolCallOpen); idx != -1 {
		f.suppressed = true
		return f.flushVisibleUpTo(idx)
	}

	return f.flushVisibleUpTo(len(s) - streamtext.TrailingTagPrefixLen(s, toolCallOpen))
}

func (f *toolCallStreamFilter) Flush() error {
	if f.suppressed {
		return nil
	}
	return f.flushVisibleUpTo(f.buf.Len())
}

func (f *toolCallStreamFilter) flushVisibleUpTo(end int) error {
	if end <= f.emitted {
		return nil
	}
	out := f.buf.String()[f.emitted:end]
	f.emitted = end
	return f.emit(out)
}

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

func newWebTools() *webtools.Tools {
	tools, err := webtools.New(webtools.Options{
		Proxy:   strings.TrimSpace(os.Getenv("CULPEOSEARCH_PROXY")),
		Timeout: 10 * time.Second,

		Region:     strings.TrimSpace(os.Getenv("WEBTOOLS_REGION")),
		MaxResults: envInt("WEBTOOLS_MAX_RESULTS"),
		FetchChars: envInt("WEBTOOLS_FETCH_CHARS"),
	})
	if err != nil {
		log.Printf("[spark] Web-Werkzeuge nicht verfuegbar: %v", err)
		return nil
	}
	return tools
}

func envInt(key string) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return 0
	}
	n, err := strconv.Atoi(value)
	if err != nil {
		log.Printf("[spark] %s=%q ist keine Zahl, Standardwert wird genutzt", key, value)
		return 0
	}
	return n
}

func runToolLoop(
	ctx context.Context,
	history []Message,
	baseSystemPrompt string,
	roots []string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn ChatTurn,
	asker tools.Asker,
	sessionID string,
) (string, error) {
	return swallowExhausted(runToolLoopWithLimit(ctx, history, baseSystemPrompt, roots, emitText, emitEvent,
		chatTurn, asker, sessionID, maxToolLoopIterations))
}

func runToolLoopWithLimit(
	ctx context.Context,
	history []Message,
	baseSystemPrompt string,
	roots []string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn ChatTurn,
	asker tools.Asker,
	sessionID string,
	maxIterations int,
) (string, error) {
	executor, err := tools.NewExecutor(ctx, roots, asker, emitEvent, sessionID)
	if err != nil {
		return "", err
	}
	web := newWebTools()
	systemPrompt := buildToolLoopSystemPrompt(baseSystemPrompt, executor.Roots())
	dispatch := func(name string, args map[string]interface{}) map[string]interface{} {
		if web != nil && web.Handles(name) {
			return web.Execute(ctx, name, args)
		}
		return executor.Execute(name, args)
	}
	return driveToolLoop(ctx, history, systemPrompt, emitText, emitEvent, chatTurn, dispatch, maxIterations)
}

func runWebOnlyToolLoop(
	ctx context.Context,
	history []Message,
	baseSystemPrompt string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn ChatTurn,
) (string, error) {
	return swallowExhausted(runWebOnlyToolLoopWithLimit(ctx, history, baseSystemPrompt, emitText, emitEvent,
		chatTurn, maxToolLoopIterations))
}

func runWebOnlyToolLoopWithLimit(
	ctx context.Context,
	history []Message,
	baseSystemPrompt string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn ChatTurn,
	maxIterations int,
) (string, error) {
	web := newWebTools()
	if web == nil {

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

func driveToolLoop(
	ctx context.Context,
	history []Message,
	systemPrompt string,
	emitText func(string) error,
	emitEvent func(eventType string, data interface{}) error,
	chatTurn ChatTurn,
	dispatch func(name string, args map[string]interface{}) map[string]interface{},
	maxIterations int,
) (string, error) {
	if maxIterations <= 0 {
		maxIterations = maxToolLoopIterations
	}
	convo := append([]Message{}, history...)

	failedTool := ""
	failureStreak := 0

	for iteration := 0; iteration < maxIterations; iteration++ {
		filter := newToolCallStreamFilter(emitText)
		reply, err := chatTurn(convo, systemPrompt, filter.Emit)
		if err != nil {
			return "", err
		}

		if err := filter.Flush(); err != nil {
			return "", err
		}

		call, ok := parseToolCall(reply)
		if !ok {

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
			log.Printf("[spark] Tool ausgefuehrt (tool=%s, ok=true, iter=%d)", call.Name, iteration+1)
			failedTool, failureStreak = "", 0
		} else {

			errText, _ := result["error"].(string)
			if code, _ := result["error_code"].(string); code == "invalid_tool_arguments" {
				argsJSON, _ := json.Marshal(call.Arguments)
				log.Printf("[spark] Tool fehlgeschlagen (tool=%s, iter=%d): %s | Argumente: %s",
					call.Name, iteration+1, errText, string(argsJSON))
			} else {
				log.Printf("[spark] Tool fehlgeschlagen (tool=%s, iter=%d): %s", call.Name, iteration+1, errText)
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
				"preview": tools.ResultPreview(result, 400),
			})
		}

		if failureStreak >= maxConsecutiveToolFailures {
			final := fmt.Sprintf("Das Werkzeug %s ist %d Mal hintereinander fehlgeschlagen. Ich breche hier ab, statt es weiter zu versuchen.", call.Name, failureStreak)
			if emitText != nil {
				_ = emitText(final)
			}
			log.Printf("[spark] Abbruch: %s scheiterte %dx in Folge", call.Name, failureStreak)
			return final, errToolLoopExhausted
		}

		resultJSON, _ := json.Marshal(result)

		convo = append(convo,
			Message{Role: "assistant", Content: reply},
			Message{Role: "user", Content: fmt.Sprintf("[TOOL_RESULT %s]\n%s", call.Name, string(resultJSON))},
		)
	}

	final := "Ich habe das Schrittlimit fuer Werkzeug-Aufrufe erreicht und die Aufgabe moeglicherweise nicht vollstaendig abgeschlossen. Sag mir, wie ich weitermachen soll."
	if emitText != nil {
		_ = emitText(final)
	}
	log.Printf("[spark] Werkzeug-Schleife hat das Iterationslimit (%d) erreicht", maxIterations)
	return final, errToolLoopExhausted
}

func swallowExhausted(reply string, err error) (string, error) {
	if errors.Is(err, errToolLoopExhausted) {
		return reply, nil
	}
	return reply, err
}
