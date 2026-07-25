package thinking

import "strings"

// ModeNone — "Fast": the model answers immediately without deliberate,
// multi-step reasoning. On models with native thinking this is best-effort
// (the model may still emit some reasoning); Philox additionally routes this to
// the fast model.
func init() {
	register(definition{
		mode:            ModeNone,
		label:           "Fast",
		inDevelopment:   false,
		reasoningEffort: "", // no native reasoning — answer directly
		temperature:     0.3,
		topP:            0.9,
		chat:          "- Thinking: Aus. Antworte sofort und direkt, ohne Vorrede und ohne sichtbares Nachdenken.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Direkt
Antworte knapp und handle sofort. Fuehre einfache Aufgaben ohne langes Vorplanen aus.
Aber auch im direkten Modus: lies bestehende Dateien vor Aenderungen und pruefe dein Ergebnis auf Korrektheit.
Ueberspringe keine Fehlerbehandlung und keine Validierung.`),
	})
}
