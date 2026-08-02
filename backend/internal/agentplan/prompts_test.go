package agentplan

import (
	"strings"
	"testing"
)

func TestDecomposePromptNenntAufgabeUndFormat(t *testing.T) {
	prompt := DecomposePrompt("Timeout erhoehen", true)
	for _, want := range []string{"Timeout erhoehen", "summary", "steps", "AUSSCHLIESSLICH"} {
		if !strings.Contains(prompt, want) {
			t.Errorf("Prompt enthaelt %q nicht", want)
		}
	}
	if !strings.Contains(prompt, "konkrete Dateien") {
		t.Error("mit Datei-Werkzeugen sollte der Prompt Dateibezug erlauben")
	}
	if strings.Contains(DecomposePrompt("X", false), "Du darfst dich auf konkrete Dateien") {
		t.Error("ohne Datei-Werkzeuge darf der Prompt keinen Dateibezug anbieten")
	}
}

func TestStepPromptIsoliertKontext(t *testing.T) {
	plan := Plan{
		Goal: "Timeout erhoehen",
		Steps: []Step{
			{Number: 1, Title: "Config lesen", Status: StatusDone, Result: "Timeout steht auf 10s"},
			{Number: 2, Title: "Wert setzen", Status: StatusRunning},
			{Number: 3, Title: "Test schreiben", Status: StatusPending, Result: "darf hier nicht auftauchen"},
		},
	}
	prompt := StepPrompt(plan, plan.Steps[1])

	if !strings.Contains(prompt, "Timeout erhoehen") {
		t.Error("Gesamtziel fehlt")
	}
	if !strings.Contains(prompt, "Wert setzen") {
		t.Error("eigener Auftrag fehlt")
	}
	if !strings.Contains(prompt, "Timeout steht auf 10s") {
		t.Error("Ergebnis des Vorschritts fehlt")
	}
	if strings.Contains(prompt, "darf hier nicht auftauchen") {
		t.Error("Ergebnis eines spaeteren Schritts darf nicht durchsickern")
	}
	if !strings.Contains(prompt, "Test schreiben") {
		t.Error("kommende Schritte sollten als Abgrenzung genannt werden")
	}
	if !strings.Contains(prompt, "Schritt 2 von 3") {
		t.Error("Position im Plan fehlt")
	}
}

func TestStepPromptOhneVorgeschichte(t *testing.T) {
	plan := Plan{Goal: "Ziel", Steps: []Step{{Number: 1, Title: "Einziger Schritt", Status: StatusRunning}}}
	prompt := StepPrompt(plan, plan.Steps[0])
	if strings.Contains(prompt, "Was bereits erledigt ist") {
		t.Error("ohne Vorschritte sollte der Abschnitt entfallen")
	}
	if strings.Contains(prompt, "Was danach noch kommt") {
		t.Error("ohne Folgeschritte sollte der Abschnitt entfallen")
	}
}

func TestStepPromptKuerztLangeErgebnisse(t *testing.T) {
	lang := strings.Repeat("x", maxResultChars*3)
	plan := Plan{
		Goal: "Ziel",
		Steps: []Step{
			{Number: 1, Title: "Erst", Status: StatusDone, Result: lang},
			{Number: 2, Title: "Dann", Status: StatusRunning},
		},
	}
	prompt := StepPrompt(plan, plan.Steps[1])
	if strings.Contains(prompt, lang) {
		t.Error("langes Ergebnis sollte gekuerzt einfliessen")
	}
	if !strings.Contains(prompt, "[…]") {
		t.Error("Kuerzung sollte markiert sein")
	}
}

func TestReportPromptNenntStatusJedesSchritts(t *testing.T) {
	plan := Plan{
		Goal: "Ziel",
		Steps: []Step{
			{Number: 1, Title: "Klappte", Status: StatusDone, Result: "fertig"},
			{Number: 2, Title: "Ging schief", Status: StatusFailed, Result: "Fehler: kaputt"},
			{Number: 3, Title: "Kam nicht dran", Status: StatusPending},
		},
	}
	prompt := ReportPrompt(plan)
	for _, want := range []string{"erledigt", "fehlgeschlagen", "nicht ausgefuehrt", "Beschoenige nichts"} {
		if !strings.Contains(prompt, want) {
			t.Errorf("Bericht-Prompt enthaelt %q nicht", want)
		}
	}
}
