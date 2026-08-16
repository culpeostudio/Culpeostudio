package agentplan

import (
	"fmt"
	"strings"
)

// Context is what the planner already knows before it asks the user anything:
// the folder the session is bound to, every folder it may touch, and whether it
// has file tools at all. It exists because the planner used to open with
// questions whose answers were already on the table.
type Context struct {
	HasFileTools bool

	// ProjectPath is the folder the session is bound to, empty when the chat
	// runs without a project.
	ProjectPath string

	// Roots is everything the agent may touch, including folders the user named
	// in the conversation.
	Roots []string
}

func DecomposePrompt(task string, c Context) string {
	var b strings.Builder
	b.WriteString("## Auftrag: Plan erstellen\n")
	b.WriteString("Zerlege die folgende Aufgabe in nachvollziehbare Arbeitsschritte. ")
	b.WriteString("Fuehre nichts davon aus - in dieser Runde planst du nur.\n\n")
	b.WriteString("Aufgabe des Nutzers:\n")
	b.WriteString(strings.TrimSpace(task))

	b.WriteString("\n\n### Was du bereits weisst\n")
	b.WriteString("Ueber diesem Auftrag steht das bisherige Gespraech. Was dort schon gesagt wurde, ")
	b.WriteString("ist gesagt — frag es nicht noch einmal ab.\n")
	if strings.TrimSpace(c.ProjectPath) != "" {
		b.WriteString("- Projekt-Ordner: " + strings.TrimSpace(c.ProjectPath) + "\n")
	} else {
		b.WriteString("- Projekt-Ordner: keiner gebunden\n")
	}
	if extra := otherRoots(c); len(extra) > 0 {
		b.WriteString("- Zusaetzlich freigegeben: " + strings.Join(extra, ", ") + "\n")
	}

	b.WriteString("\n### Regeln\n")
	b.WriteString(fmt.Sprintf("- Zwischen %d und %d Schritte. Lieber wenige grosse als viele winzige.\n", MinSteps, MaxSteps))
	b.WriteString("- Jeder Schritt muss fuer sich allein verstaendlich sein: wer ihn abarbeitet, kennt weder dieses Gespraech noch die anderen Schritte.\n")
	b.WriteString("- Schreibe, WAS zu tun ist und WORAN man erkennt, dass es fertig ist — nicht, wie du dich dabei fuehlst.\n")
	b.WriteString("- Die Reihenfolge ist die Ausfuehrungsreihenfolge. Was aufeinander aufbaut, gehoert hintereinander.\n")
	if c.HasFileTools {
		b.WriteString("- Du darfst dich auf konkrete Dateien und Pfade des Projekts beziehen, wenn du sie kennst.\n")
	} else {
		b.WriteString("- Es ist kein Projekt geoeffnet: plane ohne Bezug auf konkrete Dateien.\n")
	}

	b.WriteString("\n### Bevor du fragst\n")
	b.WriteString("Der Nutzer hat dir gesagt, was er will. Er erwartet einen Plan, keine Befragung. ")
	b.WriteString("Geh alles, was dir zu fehlen scheint, erst diese Liste entlang:\n")
	b.WriteString("1. " + pathRule(c))
	b.WriteString("2. Steht die Angabe schon im Gespraech? Dann nimm sie.\n")
	if c.HasFileTools {
		b.WriteString("3. Kannst du sie dir mit deinen Werkzeugen selbst holen? Dann mach daraus einen ersten Schritt, statt zu fragen.\n")
		b.WriteString("4. Aendert die Angabe den Plan gar nicht? Dann entscheide selbst und schreib die Annahme in den summary.\n")
	} else {
		b.WriteString("3. Aendert die Angabe den Plan gar nicht? Dann entscheide selbst und schreib die Annahme in den summary.\n")
	}
	b.WriteString(fmt.Sprintf(
		"\nNur was danach uebrig bleibt und ohne das du keinen einzigen Schritt anfangen kannst, ist eine Frage wert — hoechstens %d.\n",
		MaxQuestions))

	b.WriteString("\n### Antwortformat\n")
	b.WriteString("Antworte AUSSCHLIESSLICH mit einem JSON-Objekt, ohne Text davor oder danach.\n")
	b.WriteString("Kannst du planen:\n")
	b.WriteString(`{
  "summary": "Ein Satz, der den Loesungsweg begruendet, plus jede Annahme, die du getroffen hast",
  "steps": [
    {"title": "Kurzer Titel des Schritts", "detail": "Was konkret zu tun ist und woran man das Ergebnis erkennt"}
  ]
}`)
	b.WriteString("\n\nNur wenn ohne Antwort wirklich kein Schritt moeglich ist:\n")
	b.WriteString(`{
  "reason": "Ein Satz, warum du noch nicht planen kannst",
  "questions": ["Erste Frage?"]
}`)
	b.WriteString("\n\nBeides zusammen geht nicht — entweder du planst, oder du fragst.")
	return b.String()
}

// pathRule is the first item of that list because the folder is what the
// planner asked for most often, and least justified: a bound project already
// answers it.
func pathRule(c Context) string {
	if strings.TrimSpace(c.ProjectPath) != "" {
		return "Pfad: steht fest, der Projekt-Ordner oben ist gemeint. Frag nicht danach und schlag keinen anderen vor.\n"
	}
	if len(otherRoots(c)) > 0 {
		return "Pfad: kein Projekt gebunden, aber die oben freigegebenen Ordner sind gemeint. Arbeite darin.\n"
	}
	return "Pfad: hat der Nutzer irgendwo im Gespraech einen Ordner genannt, ist das der Pfad. " +
		"Nur wenn nirgends einer steht und die Aufgabe ohne Ordner nicht geht, frag genau danach — einmal.\n"
}

func otherRoots(c Context) []string {
	project := strings.TrimSpace(c.ProjectPath)
	var out []string
	for _, root := range c.Roots {
		root = strings.TrimSpace(root)
		if root == "" || root == project {
			continue
		}
		out = append(out, root)
	}
	return out
}

func StepPrompt(plan Plan, step Step) string {
	var b strings.Builder
	b.WriteString("## Dein Arbeitsschritt\n")
	b.WriteString(fmt.Sprintf("Du bearbeitest Schritt %d von %d eines abgestimmten Plans.\n\n", step.Number, len(plan.Steps)))

	b.WriteString("Gesamtziel:\n")
	b.WriteString(plan.Goal)
	if summary := strings.TrimSpace(plan.Summary); summary != "" {
		// The summary carries the agreed approach and every assumption the
		// planner made instead of asking. Without it here, a step re-decides
		// what was already settled.
		b.WriteString("\n\nAbgestimmtes Vorgehen:\n")
		b.WriteString(summary)
	}
	b.WriteString("\n\nDein Schritt: ")
	b.WriteString(step.Title)
	if step.Detail != "" {
		b.WriteString("\n")
		b.WriteString(step.Detail)
	}

	if done := completedSteps(plan, step.Number); len(done) > 0 {
		b.WriteString("\n\n### Was bereits erledigt ist\n")
		for _, prev := range done {
			b.WriteString(fmt.Sprintf("- Schritt %d (%s): %s\n", prev.Number, prev.Title, shorten(prev.Result, maxResultChars)))
		}
	}

	if remaining := remainingSteps(plan, step.Number); len(remaining) > 0 {
		b.WriteString("\n### Was danach noch kommt (nicht deine Aufgabe)\n")
		for _, next := range remaining {
			b.WriteString(fmt.Sprintf("- Schritt %d: %s\n", next.Number, next.Title))
		}
	}

	b.WriteString("\n### Regeln\n")
	b.WriteString("- Erledige genau diesen Schritt, nicht mehr und nicht weniger.\n")
	b.WriteString("- Greife den kommenden Schritten nicht vor.\n")
	b.WriteString("- Nutze deine Werkzeuge, wenn sie helfen.\n")
	b.WriteString("- Aenderst du Code, MUSST du ihn danach pruefen: uebersetzt er noch? ")
	b.WriteString("Nutze run_command (z.B. \"go build ./...\", \"flutter analyze\"). ")
	b.WriteString("Ein Schritt, der nicht uebersetzbaren Code hinterlaesst, ist nicht erledigt.\n")
	b.WriteString("- Aendere nur, was du vorher gelesen hast. Benennst du etwas um, passe ALLE Verwendungsstellen an — ")
	b.WriteString("sonst hinterlaesst du einen kaputten Zwischenstand.\n")
	b.WriteString("- Scheitert ein Werkzeug zweimal am selben Aufruf, versuch etwas anderes statt es zu wiederholen.\n")
	b.WriteString("- Antworte am Ende knapp: was du getan hast und was dabei herauskam. ")
	b.WriteString("Dieser Text ist alles, was die folgenden Schritte von dir sehen.\n")
	b.WriteString("- Kommst du nicht weiter, sag klar woran es liegt, statt etwas zu erfinden.\n")
	return b.String()
}

func ReportPrompt(plan Plan) string {
	var b strings.Builder
	b.WriteString("## Abschlussbericht\n")
	b.WriteString("Der Plan ist abgearbeitet. Fasse fuer den Nutzer zusammen, was dabei herauskam.\n\n")
	b.WriteString("Ursprüngliche Aufgabe:\n")
	b.WriteString(plan.Goal)
	b.WriteString("\n\n### Ergebnisse der Schritte\n")
	for _, step := range plan.Steps {
		status := "erledigt"
		if step.Status == StatusFailed {
			status = "fehlgeschlagen"
		} else if step.Status != StatusDone {
			status = "nicht ausgefuehrt"
		}
		b.WriteString(fmt.Sprintf("- Schritt %d (%s, %s): %s\n",
			step.Number, step.Title, status, shorten(step.Result, maxResultChars)))
	}
	b.WriteString("\n### Regeln\n")
	b.WriteString("- Schreibe an den Nutzer, nicht ueber dich selbst.\n")
	b.WriteString("- Nenne, was erreicht wurde und was offen blieb. Beschoenige nichts.\n")
	b.WriteString("- Halte dich kurz; Details stehen bereits im Verlauf.\n")
	b.WriteString("- Rufe keine Werkzeuge mehr auf.\n")
	return b.String()
}

func completedSteps(plan Plan, number int) []Step {
	var out []Step
	for _, step := range plan.Steps {
		if step.Number >= number {
			break
		}
		if step.Result != "" {
			out = append(out, step)
		}
	}
	return out
}

func remainingSteps(plan Plan, number int) []Step {
	var out []Step
	for _, step := range plan.Steps {
		if step.Number > number {
			out = append(out, step)
		}
	}
	return out
}
