package thinking

import "strings"

// ModeMax — "Extra": maximum, systematic multi-step reasoning. On models
// without native thinking this instruction is what makes them reason explicitly
// in text before answering.
func init() {
	register(definition{
		mode:            ModeMax,
		label:           "Extra",
		inDevelopment:   false,
		reasoningEffort: "high",
		temperature:     0.7,
		topP:            0.95,
		chat:          "- Thinking: Max. Denke ausfuehrlich in mehreren Schritten. Pruefe Annahmen, Zielkonflikte und Risiken gruendlich, bevor du antwortest.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Gruendlich
Gehe systematisch in mehreren Schritten vor:
1. ANALYSE: Lies alle relevanten Dateien. Verstehe die bestehende Architektur, Patterns, Namenskonventionen und Abhaengigkeiten.
2. PLAN: Formuliere einen konkreten Plan mit allen Dateien die geaendert werden und warum. Benenne Risiken und Seiteneffekte.
3. UMSETZUNG: Fuehre Aenderungen Schritt fuer Schritt aus. Bevorzuge patch_file fuer praezise Aenderungen.
4. VERIFIKATION: Pruefe nach jeder Aenderung ob sie konsistent mit dem Rest der Codebasis ist.
Lege Annahmen offen. Wenn du unsicher bist, lies mehr Code bevor du schreibst.`),
	})
}
