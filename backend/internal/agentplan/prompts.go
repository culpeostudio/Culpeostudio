package agentplan

import (
	"fmt"
	"strings"
)

// DecomposePrompt liefert die Anweisung, mit der ein Modell eine Aufgabe
// in Schritte zerlegt.
//
// Zwei Dinge entscheiden hier ueber die Qualitaet: Das Modell muss
// erstens ausschliesslich JSON liefern (sonst ist die Antwort nicht
// verwertbar), und es muss zweitens verstehen, dass jeder Schritt fuer
// sich verstaendlich sein muss - der Subagent, der ihn spaeter abarbeitet,
// sieht das Gespraech nicht, aus dem der Plan entstanden ist.
func DecomposePrompt(task string, hasFileTools bool) string {
	var b strings.Builder
	b.WriteString("## Auftrag: Plan erstellen\n")
	b.WriteString("Zerlege die folgende Aufgabe in nachvollziehbare Arbeitsschritte. ")
	b.WriteString("Fuehre nichts davon aus - in dieser Runde planst du nur.\n\n")
	b.WriteString("Aufgabe des Nutzers:\n")
	b.WriteString(strings.TrimSpace(task))
	b.WriteString("\n\n### Regeln\n")
	b.WriteString(fmt.Sprintf("- Zwischen %d und %d Schritte. Lieber wenige grosse als viele winzige.\n", MinSteps, MaxSteps))
	b.WriteString("- Jeder Schritt muss fuer sich allein verstaendlich sein: wer ihn abarbeitet, kennt weder dieses Gespraech noch die anderen Schritte.\n")
	b.WriteString("- Schreibe, WAS zu tun ist und WORAN man erkennt, dass es fertig ist — nicht, wie du dich dabei fuehlst.\n")
	b.WriteString("- Die Reihenfolge ist die Ausfuehrungsreihenfolge. Was aufeinander aufbaut, gehoert hintereinander.\n")
	if hasFileTools {
		b.WriteString("- Du darfst dich auf konkrete Dateien und Pfade des Projekts beziehen, wenn du sie kennst.\n")
	} else {
		b.WriteString("- Es ist kein Projekt geoeffnet: plane ohne Bezug auf konkrete Dateien.\n")
	}

	b.WriteString("\n### Wenn dir Angaben fehlen\n")
	b.WriteString("Rate nicht. Kannst du ohne weitere Angaben nur einen Plan erfinden, den der Nutzer ")
	b.WriteString("hinterher muehsam korrigieren muesste, dann frag lieber nach — das kostet eine Runde ")
	b.WriteString("und spart viel Arbeit.\n")
	b.WriteString(fmt.Sprintf("Stelle hoechstens %d Fragen, und nur solche, deren Antwort den Plan wirklich veraendert. ", MaxQuestions))
	b.WriteString("Was du dir selbst erarbeiten kannst, fragst du nicht.\n")

	b.WriteString("\n### Antwortformat\n")
	b.WriteString("Antworte AUSSCHLIESSLICH mit einem JSON-Objekt, ohne Text davor oder danach.\n")
	b.WriteString("Kannst du planen:\n")
	b.WriteString(`{
  "summary": "Ein Satz, der den Loesungsweg begruendet",
  "steps": [
    {"title": "Kurzer Titel des Schritts", "detail": "Was konkret zu tun ist und woran man das Ergebnis erkennt"}
  ]
}`)
	b.WriteString("\n\nFehlen dir Angaben:\n")
	b.WriteString(`{
  "reason": "Ein Satz, warum du noch nicht planen kannst",
  "questions": ["Erste Frage?", "Zweite Frage?"]
}`)
	b.WriteString("\n\nBeides zusammen geht nicht — entweder du planst, oder du fragst.")
	return b.String()
}

// StepPrompt baut den Auftrag fuer den Subagenten eines Schritts.
//
// Der Subagent bekommt bewusst nicht die Chat-Historie, sondern nur das
// Ziel, seinen Schritt und die Ergebnisse der Vorschritte. Das haelt
// seinen Kontext klein und verhindert, dass er sich an einer frueheren
// Zwischenantwort festbeisst statt seine Aufgabe zu erledigen.
func StepPrompt(plan Plan, step Step) string {
	var b strings.Builder
	b.WriteString("## Dein Arbeitsschritt\n")
	b.WriteString(fmt.Sprintf("Du bearbeitest Schritt %d von %d eines abgestimmten Plans.\n\n", step.Number, len(plan.Steps)))

	b.WriteString("Gesamtziel:\n")
	b.WriteString(plan.Goal)
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

// ReportPrompt baut den Auftrag fuer die Abschlussmeldung an den Nutzer.
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

// completedSteps liefert die abgeschlossenen Schritte vor number.
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

// remainingSteps liefert die Schritte nach number.
func remainingSteps(plan Plan, number int) []Step {
	var out []Step
	for _, step := range plan.Steps {
		if step.Number > number {
			out = append(out, step)
		}
	}
	return out
}
