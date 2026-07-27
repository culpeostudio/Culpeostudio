// Package agentplan stellt das Datenmodell und die Prompts fuer die
// zweistufige Aufgabenbearbeitung von PhiloEngine bereit: erst zerlegt
// ein Modell die Aufgabe in nachvollziehbare Schritte, dann arbeitet je
// ein Subagent einen Schritt ab.
//
// Der Zuschnitt folgt einer Beobachtung aus der Praxis: ein Agent, der
// eine grosse Aufgabe in einem Rutsch bearbeitet, verliert nach wenigen
// Werkzeugaufrufen den roten Faden und produziert Arbeit, die niemand
// bestellt hat. Deshalb
//
//   - liegt zwischen Zerlegung und Ausfuehrung die Freigabe des Nutzers,
//   - bekommt jeder Schritt einen eigenen, frischen Kontext statt der
//     gesamten Chat-Historie,
//   - und traegt jeder Schritt sein Ergebnis, damit der naechste darauf
//     aufbauen kann, ohne alles noch einmal zu lesen.
//
// Das Paket ist bewusst frei von HTTP, Streaming und Modell-Anbindung:
// es beschreibt den Plan und die Prompts, die Ausfuehrung liegt beim
// Aufrufer.
package agentplan

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

// Zustaende eines Schritts.
const (
	StatusPending = "pending"
	StatusRunning = "running"
	StatusDone    = "done"
	StatusFailed  = "failed"
)

// Grenzen fuer einen Plan. Sie halten die Zerlegung in einem Bereich,
// den ein Nutzer noch ueberblicken und freigeben mag.
const (
	MinSteps = 1
	MaxSteps = 12
	// maxResultChars begrenzt, wie viel Ergebnistext eines Schritts in
	// den Kontext des naechsten Schritts wandert.
	maxResultChars = 800
)

// ErrNoPlan meldet, dass in einer Modellantwort kein Plan steckt.
var ErrNoPlan = errors.New("agentplan: kein Plan in der Antwort gefunden")

// MaxQuestions deckelt die Rueckfragen. Wer mehr als eine Handvoll
// Fragen gestellt bekommt, haette die Aufgabe schneller selbst erklaert.
const MaxQuestions = 4

// Step ist ein einzelner Arbeitsschritt.
type Step struct {
	// Number ist die 1-basierte Position im Plan.
	Number int `json:"number"`
	// Title ist die knappe Bezeichnung, die der Nutzer zur Freigabe sieht.
	Title string `json:"title"`
	// Detail beschreibt, was in diesem Schritt konkret zu tun ist.
	Detail string `json:"detail,omitempty"`
	// Status ist der Fortschritt; siehe die Status-Konstanten.
	Status string `json:"status"`
	// Result haelt fest, was der Subagent berichtet hat.
	Result string `json:"result,omitempty"`
}

// Plan ist die zerlegte Aufgabe.
type Plan struct {
	// Goal ist die urspruengliche Aufgabe in der Formulierung des Nutzers.
	Goal string `json:"goal"`
	// Summary ist die Zusammenfassung, mit der das Modell seinen
	// Loesungsweg begruendet.
	Summary string `json:"summary"`
	// Steps sind die Arbeitsschritte in Ausfuehrungsreihenfolge.
	Steps []Step `json:"steps"`
}

// StepTitles liefert die Schritt-Titel als Liste. Das Freigabe-Panel im
// Frontend zeigt genau diese Zeilen an.
func (p Plan) StepTitles() []string {
	titles := make([]string, 0, len(p.Steps))
	for _, step := range p.Steps {
		titles = append(titles, fmt.Sprintf("%d. %s", step.Number, step.Title))
	}
	return titles
}

// IsEmpty meldet, ob der Plan keine Schritte enthaelt.
func (p Plan) IsEmpty() bool { return len(p.Steps) == 0 }

// Pending liefert den naechsten unerledigten Schritt.
func (p Plan) Pending() (Step, bool) {
	for _, step := range p.Steps {
		if step.Status == StatusPending || step.Status == StatusRunning {
			return step, true
		}
	}
	return Step{}, false
}

// Questions sind Rueckfragen, die das Modell stellt, statt eine unklare
// Aufgabe zu erraten. Ist das Feld gefuellt, enthaelt der Plan keine
// Schritte: erst antwortet der Nutzer, dann wird geplant.
type Questions struct {
	// Reason erklaert in einem Satz, warum noch nicht geplant werden kann.
	Reason string `json:"reason"`
	// Items sind die eigentlichen Fragen.
	Items []string `json:"items"`
}

// ParseResult ist das Ergebnis einer Planungsrunde: entweder ein Plan
// oder Rueckfragen.
type ParseResult struct {
	Plan      Plan
	Questions Questions
}

// NeedsAnswers meldet, ob das Modell Rueckfragen gestellt hat.
func (r ParseResult) NeedsAnswers() bool { return len(r.Questions.Items) > 0 }

// ParsePlan liest einen Plan aus einer Modellantwort.
//
// Erwartet wird ein JSON-Objekt mit "summary" und "steps"; Modelle
// verpacken es gern in einen Markdown-Codeblock oder stellen ihm eine
// Einleitung voran, beides wird toleriert. Fehlt ein brauchbares
// Objekt, kommt ErrNoPlan zurueck - der Aufrufer entscheidet dann, ob
// er nachfragt oder ohne Plan weitermacht.
func ParsePlan(goal, reply string) (Plan, error) {
	result, err := Parse(goal, reply)
	if err != nil {
		return Plan{}, err
	}
	if result.NeedsAnswers() {
		return Plan{}, ErrNoPlan
	}
	return result.Plan, nil
}

// Parse liest eine Planungsantwort: entweder Schritte oder Rueckfragen.
//
// Rueckfragen haben Vorrang. Ein Modell, das eine unklare Aufgabe
// bemerkt, soll nachfragen duerfen, statt einen Plan zu erfinden, den
// der Nutzer dann muehsam korrigiert.
func Parse(goal, reply string) (ParseResult, error) {
	raw, ok := extractJSONObject(reply)
	if !ok {
		return ParseResult{}, ErrNoPlan
	}

	var parsed struct {
		Summary string `json:"summary"`
		Steps   []struct {
			Title  string `json:"title"`
			Detail string `json:"detail"`
		} `json:"steps"`
		Reason    string   `json:"reason"`
		Questions []string `json:"questions"`
	}
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil {
		return ParseResult{}, fmt.Errorf("%w: %v", ErrNoPlan, err)
	}

	if questions := cleanQuestions(parsed.Questions); len(questions) > 0 {
		reason := strings.TrimSpace(parsed.Reason)
		if reason == "" {
			reason = "Zur Aufgabe fehlen mir noch Angaben."
		}
		return ParseResult{Questions: Questions{Reason: reason, Items: questions}}, nil
	}

	plan := Plan{
		Goal:    strings.TrimSpace(goal),
		Summary: strings.TrimSpace(parsed.Summary),
	}
	for _, item := range parsed.Steps {
		title := strings.TrimSpace(item.Title)
		if title == "" {
			continue
		}
		if len(plan.Steps) >= MaxSteps {
			break
		}
		plan.Steps = append(plan.Steps, Step{
			Number: len(plan.Steps) + 1,
			Title:  title,
			Detail: strings.TrimSpace(item.Detail),
			Status: StatusPending,
		})
	}
	if len(plan.Steps) < MinSteps {
		return ParseResult{}, ErrNoPlan
	}
	if plan.Summary == "" {
		plan.Summary = fmt.Sprintf("Plan mit %d Schritten", len(plan.Steps))
	}
	return ParseResult{Plan: plan}, nil
}

// cleanQuestions verwirft leere Eintraege und deckelt die Anzahl.
func cleanQuestions(raw []string) []string {
	out := make([]string, 0, len(raw))
	for _, question := range raw {
		trimmed := strings.TrimSpace(question)
		if trimmed == "" {
			continue
		}
		out = append(out, trimmed)
		if len(out) >= MaxQuestions {
			break
		}
	}
	return out
}

// extractJSONObject findet das erste vollstaendige JSON-Objekt in text.
// Es zaehlt Klammern und ueberspringt dabei Zeichenketten, damit eine
// Klammer im Fliesstext eines Feldes die Zaehlung nicht verschiebt.
func extractJSONObject(text string) (string, bool) {
	start := strings.Index(text, "{")
	if start < 0 {
		return "", false
	}
	depth := 0
	inString := false
	escaped := false
	for i := start; i < len(text); i++ {
		c := text[i]
		if inString {
			switch {
			case escaped:
				escaped = false
			case c == '\\':
				escaped = true
			case c == '"':
				inString = false
			}
			continue
		}
		switch c {
		case '"':
			inString = true
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return text[start : i+1], true
			}
		}
	}
	return "", false
}

// shorten kuerzt einen Ergebnistext auf das Kontextbudget eines Schritts.
func shorten(s string, limit int) string {
	s = strings.TrimSpace(s)
	runes := []rune(s)
	if limit <= 0 || len(runes) <= limit {
		return s
	}
	return strings.TrimSpace(string(runes[:limit])) + " […]"
}
