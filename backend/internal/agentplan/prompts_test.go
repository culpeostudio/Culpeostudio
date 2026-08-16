package agentplan

import (
	"strings"
	"testing"
)

func TestDecomposePromptNenntAufgabeUndFormat(t *testing.T) {
	prompt := DecomposePrompt("Timeout erhoehen", Context{HasFileTools: true})
	for _, want := range []string{"Timeout erhoehen", "summary", "steps", "AUSSCHLIESSLICH"} {
		if !strings.Contains(prompt, want) {
			t.Errorf("Prompt enthaelt %q nicht", want)
		}
	}
	if !strings.Contains(prompt, "konkrete Dateien") {
		t.Error("mit Datei-Werkzeugen sollte der Prompt Dateibezug erlauben")
	}
	if strings.Contains(DecomposePrompt("X", Context{}), "Du darfst dich auf konkrete Dateien") {
		t.Error("ohne Datei-Werkzeuge darf der Prompt keinen Dateibezug anbieten")
	}
}

func TestDecomposePromptVerbietetDiePfadfrageBeiGebundenemProjekt(t *testing.T) {
	prompt := DecomposePrompt("Timeout erhoehen", Context{
		HasFileTools: true,
		ProjectPath:  "/home/nutzer/projekt",
		Roots:        []string{"/home/nutzer/projekt", "/tmp/vergleich"},
	})

	if !strings.Contains(prompt, "/home/nutzer/projekt") {
		t.Error("der gebundene Projekt-Ordner muss im Prompt stehen")
	}
	if !strings.Contains(prompt, "/tmp/vergleich") {
		t.Error("zusaetzlich freigegebene Ordner fehlen")
	}
	if !strings.Contains(prompt, "Frag nicht danach") {
		t.Error("bei gebundenem Projekt muss die Pfadfrage ausdruecklich verboten sein")
	}
}

func TestDecomposePromptLaesstPfadfrageNurAlsLetztesZu(t *testing.T) {
	prompt := DecomposePrompt("Neues Projekt bauen", Context{})

	if !strings.Contains(prompt, "keiner gebunden") {
		t.Error("ohne Projekt muss der Prompt das benennen")
	}
	if !strings.Contains(prompt, "im Gespraech einen Ordner genannt") {
		t.Error("der Prompt muss zuerst auf das Gespraech verweisen")
	}
	if !strings.Contains(prompt, "frag genau danach — einmal") {
		t.Error("die Pfadfrage muss auf eine einzige Nachfrage begrenzt sein")
	}
}

func TestDecomposePromptStelltPlanenVorFragen(t *testing.T) {
	prompt := DecomposePrompt("Export bauen", Context{HasFileTools: true})

	if !strings.Contains(prompt, "Er erwartet einen Plan, keine Befragung") {
		t.Error("die Haltung 'erst planen' fehlt im Prompt")
	}
	if !strings.Contains(prompt, "Nur was danach uebrig bleibt") {
		t.Error("Rueckfragen muessen als letzter Ausweg formuliert sein")
	}
	if !strings.Contains(prompt, "hoechstens 2") {
		t.Errorf("die Fragen-Obergrenze (%d) steht nicht im Prompt", MaxQuestions)
	}
}

func TestStepPromptTraegtDasAbgestimmteVorgehen(t *testing.T) {
	plan := Plan{
		Goal:    "Timeout erhoehen",
		Summary: "Annahme: gemeint ist der HTTP-Client, nicht der Datenbank-Treiber",
		Steps:   []Step{{Number: 1, Title: "Config lesen", Status: StatusRunning}},
	}

	if !strings.Contains(StepPrompt(plan, plan.Steps[0]), "nicht der Datenbank-Treiber") {
		t.Error("die Annahme aus der Planung muss jeden Schritt begleiten")
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
