package thinking

import "strings"

// ModeDual — "Dual": in development. Intended to weigh a task from two opposing
// angles and reconcile them. Gated in the UI; the text below is a placeholder
// for when the mode is built out.
func init() {
	register(definition{
		mode:            ModeDual,
		label:           "Dual",
		inDevelopment:   true,
		reasoningEffort: "high",
		temperature:     0.7,
		topP:            0.95,
		chat:          "- Thinking: Dual. Betrachte die Aufgabe aus zwei gegensaetzlichen Blickwinkeln und fuehre sie zu einer klaren Antwort zusammen.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Dual
Betrachte die Aufgabe aus zwei gegensaetzlichen Blickwinkeln (z. B. Sicherheit vs. Einfachheit),
lege beide Perspektiven offen und fuehre sie zu einer begruendeten Entscheidung zusammen.`),
	})
}
