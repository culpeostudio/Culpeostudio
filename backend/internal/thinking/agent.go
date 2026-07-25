package thinking

import "strings"

// ModeAgent — "Agent": in development. Intended to approach a task from several
// specialist viewpoints and converge on one recommendation. Gated in the UI;
// the text below is a placeholder for when the mode is built out.
func init() {
	register(definition{
		mode:            ModeAgent,
		label:           "Agent",
		inDevelopment:   true,
		reasoningEffort: "high",
		temperature:     0.7,
		topP:            0.95,
		chat:          "- Thinking: Agent. Betrachte die Aufgabe aus mehreren fachlichen Blickwinkeln und fuehre sie zu einer klaren Empfehlung zusammen.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Agent
Zerlege die Aufgabe und betrachte sie aus mehreren fachlichen Blickwinkeln.
Arbeite die Teilaspekte einzeln ab und fuehre sie am Ende zu einer klaren, begruendeten Empfehlung zusammen.`),
	})
}
