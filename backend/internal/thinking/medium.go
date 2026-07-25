package thinking

import "strings"

// ModeMedium — "Fast Thinking": balanced everyday reasoning. This is the
// default mode.
func init() {
	register(definition{
		mode:            ModeMedium,
		label:           "Fast Thinking",
		inDevelopment:   false,
		reasoningEffort: "medium",
		temperature:     0.5,
		topP:            0.9,
		chat:          "- Thinking: Medium. Antworte mit normaler Sorgfalt und guter Struktur. Denke kurz nach, bevor du antwortest.",
		agent: strings.TrimSpace(`## Arbeitsmodus: Ausgewogen
Arbeite gruendlich aber pragmatisch:
1. Lies zuerst relevante Dateien um den Kontext zu verstehen.
2. Plane die Aenderung kurz durch bevor du sie ausfuehrst.
3. Bevorzuge patch_file fuer gezielte Aenderungen statt ganze Dateien neu zu schreiben.
4. Pruefe ob deine Aenderung mit bestehenden Patterns konsistent ist.`),
	})
}
