package thinking

import "strings"

func init() {
	register(definition{
		mode:            ModeNone,
		label:           "Fast",
		inDevelopment:   false,
		reasoningEffort: "",
		temperature:     0.3,
		topP:            0.9,
		chat:            "- Thinking: Aus. Antworte sofort und direkt, ohne Vorrede und ohne sichtbares Nachdenken.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Direkt
Antworte knapp und handle sofort. Fuehre einfache Aufgaben ohne langes Vorplanen aus.
Aber auch im direkten Modus: lies bestehende Dateien vor Aenderungen und pruefe dein Ergebnis auf Korrektheit.
Ueberspringe keine Fehlerbehandlung und keine Validierung.`),
	})
}
