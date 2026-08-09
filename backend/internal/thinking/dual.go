package thinking

import "strings"

func init() {
	register(definition{
		mode:            ModeDual,
		label:           "Dual",
		inDevelopment:   true,
		reasoningEffort: "high",
		temperature:     0.7,
		topP:            0.95,
		chat:            "- Thinking: Dual. Betrachte die Aufgabe aus zwei gegensaetzlichen Blickwinkeln und fuehre sie zu einer klaren Antwort zusammen.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Dual
Betrachte die Aufgabe aus zwei gegensaetzlichen Blickwinkeln (z. B. Sicherheit vs. Einfachheit),
lege beide Perspektiven offen und fuehre sie zu einer begruendeten Entscheidung zusammen.`),
	})
}
