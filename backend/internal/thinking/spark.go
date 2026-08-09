// Package thinking maps the reasoning modes offered in the interface onto the
// parameters a given provider expects.
package thinking

import "strings"

func init() {
	register(definition{
		mode:            ModeSpark,
		label:           "Spark",
		reasoningEffort: "high",
		temperature:     0.7,
		topP:            0.95,
		chat:            "- Thinking: Spark. Betrachte die Aufgabe aus mehreren fachlichen Blickwinkeln und fuehre sie zu einer klaren Empfehlung zusammen.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Spark
Zerlege die Aufgabe und betrachte sie aus mehreren fachlichen Blickwinkeln.
Arbeite die Teilaspekte einzeln ab und fuehre sie am Ende zu einer klaren, begruendeten Empfehlung zusammen.`),
	})
}
