package agentplan

import (
	"errors"
	"strings"
	"testing"
)

func TestParsePlanAcceptsPlainJSON(t *testing.T) {
	reply := `{"summary":"Erst lesen, dann aendern","steps":[
		{"title":"Konfiguration lesen","detail":"config.go oeffnen"},
		{"title":"Wert anpassen","detail":"Timeout auf 30s setzen"}]}`

	plan, err := ParsePlan("Timeout erhoehen", reply)
	if err != nil {
		t.Fatalf("ParsePlan: %v", err)
	}
	if plan.Goal != "Timeout erhoehen" {
		t.Errorf("Goal = %q", plan.Goal)
	}
	if plan.Summary != "Erst lesen, dann aendern" {
		t.Errorf("Summary = %q", plan.Summary)
	}
	if len(plan.Steps) != 2 {
		t.Fatalf("erwartete 2 Schritte, bekam %d", len(plan.Steps))
	}
	for i, step := range plan.Steps {
		if step.Number != i+1 {
			t.Errorf("Schritt %d hat Number %d", i, step.Number)
		}
		if step.Status != StatusPending {
			t.Errorf("Schritt %d startet mit Status %q", step.Number, step.Status)
		}
	}
}

func TestParsePlanToleriertVerpackung(t *testing.T) {
	cases := map[string]string{
		"markdown-block": "Hier ist mein Plan:\n```json\n{\"summary\":\"S\",\"steps\":[{\"title\":\"A\"}]}\n```\n",
		"einleitung":     "Klar, ich schlage vor: {\"summary\":\"S\",\"steps\":[{\"title\":\"A\"}]} — passt das?",
		"nur-json":       `{"summary":"S","steps":[{"title":"A"}]}`,
	}
	for name, reply := range cases {
		t.Run(name, func(t *testing.T) {
			plan, err := ParsePlan("Ziel", reply)
			if err != nil {
				t.Fatalf("ParsePlan: %v", err)
			}
			if len(plan.Steps) != 1 || plan.Steps[0].Title != "A" {
				t.Fatalf("unerwarteter Plan: %+v", plan.Steps)
			}
		})
	}
}

func TestParsePlanKlammerImText(t *testing.T) {
	reply := `{"summary":"Nutze {} als Platzhalter","steps":[{"title":"A","detail":"schreibe {\"k\":1}"}]}`
	plan, err := ParsePlan("Ziel", reply)
	if err != nil {
		t.Fatalf("ParsePlan: %v", err)
	}
	if plan.Summary != "Nutze {} als Platzhalter" {
		t.Errorf("Summary = %q", plan.Summary)
	}
	if len(plan.Steps) != 1 {
		t.Fatalf("erwartete 1 Schritt, bekam %d", len(plan.Steps))
	}
}

func TestParsePlanFehlerfaelle(t *testing.T) {
	cases := map[string]string{
		"kein json":        "Ich habe keinen Plan, sorry.",
		"leere schritte":   `{"summary":"S","steps":[]}`,
		"titel leer":       `{"summary":"S","steps":[{"title":"   "}]}`,
		"kaputtes json":    `{"summary":"S","steps":[{"title":`,
		"falsche struktur": `{"summary":"S","steps":"keine liste"}`,
	}
	for name, reply := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := ParsePlan("Ziel", reply); !errors.Is(err, ErrNoPlan) {
				t.Fatalf("erwartete ErrNoPlan, bekam %v", err)
			}
		})
	}
}

func TestParsePlanDeckeltSchritte(t *testing.T) {
	var b strings.Builder
	b.WriteString(`{"summary":"S","steps":[`)
	for i := 0; i < MaxSteps+8; i++ {
		if i > 0 {
			b.WriteString(",")
		}
		b.WriteString(`{"title":"Schritt"}`)
	}
	b.WriteString(`]}`)

	plan, err := ParsePlan("Ziel", b.String())
	if err != nil {
		t.Fatalf("ParsePlan: %v", err)
	}
	if len(plan.Steps) != MaxSteps {
		t.Fatalf("erwartete Deckelung auf %d, bekam %d", MaxSteps, len(plan.Steps))
	}
}

func TestParsePlanErgaenztFehlendeZusammenfassung(t *testing.T) {
	plan, err := ParsePlan("Ziel", `{"steps":[{"title":"A"},{"title":"B"}]}`)
	if err != nil {
		t.Fatalf("ParsePlan: %v", err)
	}
	if plan.Summary == "" {
		t.Error("Summary sollte ersatzweise gefuellt werden")
	}
}

func TestStepTitlesUndPending(t *testing.T) {
	plan := Plan{Steps: []Step{
		{Number: 1, Title: "Erst", Status: StatusDone},
		{Number: 2, Title: "Dann", Status: StatusPending},
	}}
	titles := plan.StepTitles()
	if len(titles) != 2 || titles[0] != "1. Erst" || titles[1] != "2. Dann" {
		t.Fatalf("StepTitles = %q", titles)
	}
	next, ok := plan.Pending()
	if !ok || next.Number != 2 {
		t.Fatalf("Pending = %+v, ok=%v", next, ok)
	}

	plan.Steps[1].Status = StatusDone
	if _, ok := plan.Pending(); ok {
		t.Error("nach Abschluss aller Schritte darf Pending nichts liefern")
	}
	if (Plan{}).IsEmpty() != true {
		t.Error("leerer Plan sollte IsEmpty=true melden")
	}
}

func TestShorten(t *testing.T) {
	if got := shorten("kurz", 100); got != "kurz" {
		t.Errorf("shorten = %q", got)
	}
	got := shorten(strings.Repeat("ä", 50), 10)
	if !strings.HasSuffix(got, "[…]") {
		t.Errorf("shorten sollte kuerzen: %q", got)
	}
	if len([]rune(strings.TrimSuffix(got, " […]"))) != 10 {
		t.Errorf("shorten schneidet Mehrbyte-Zeichen falsch: %q", got)
	}
}

func TestParseErkenntRueckfragen(t *testing.T) {
	reply := `{"reason":"Mir fehlt das Zielformat","questions":["JSON oder YAML?","Wohin soll die Datei?"]}`
	result, err := Parse("Export bauen", reply)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if !result.NeedsAnswers() {
		t.Fatal("erwartete Rueckfragen")
	}
	if result.Questions.Reason != "Mir fehlt das Zielformat" {
		t.Errorf("Reason = %q", result.Questions.Reason)
	}
	if len(result.Questions.Items) != 2 {
		t.Fatalf("erwartete 2 Fragen, bekam %v", result.Questions.Items)
	}
	if !result.Plan.IsEmpty() {
		t.Error("bei Rueckfragen darf kein Plan geliefert werden")
	}
}

func TestParseRueckfragenHabenVorrang(t *testing.T) {
	reply := `{"summary":"S","steps":[{"title":"Raten"}],"questions":["Was genau?"]}`
	result, err := Parse("Ziel", reply)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if !result.NeedsAnswers() {
		t.Fatal("Rueckfragen sollten Vorrang haben")
	}
}

func TestParseDeckeltRueckfragen(t *testing.T) {
	var items []string
	for i := 0; i < MaxQuestions+5; i++ {
		items = append(items, `"Frage?"`)
	}
	reply := `{"reason":"R","questions":[` + strings.Join(items, ",") + `]}`
	result, err := Parse("Ziel", reply)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if len(result.Questions.Items) != MaxQuestions {
		t.Fatalf("erwartete Deckelung auf %d, bekam %d", MaxQuestions, len(result.Questions.Items))
	}
}

func TestParseErgaenztFehlendenGrund(t *testing.T) {
	result, err := Parse("Ziel", `{"questions":["Was denn?"]}`)
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if result.Questions.Reason == "" {
		t.Error("Reason sollte ersatzweise gefuellt werden")
	}
}

func TestParseIgnoriertLeereFragen(t *testing.T) {

	if _, err := Parse("Ziel", `{"reason":"R","questions":["  ",""]}`); !errors.Is(err, ErrNoPlan) {
		t.Fatalf("erwartete ErrNoPlan, bekam %v", err)
	}
}

func TestParsePlanLehntRueckfragenAb(t *testing.T) {
	if _, err := ParsePlan("Ziel", `{"reason":"R","questions":["Was?"]}`); !errors.Is(err, ErrNoPlan) {
		t.Fatalf("erwartete ErrNoPlan, bekam %v", err)
	}
}
