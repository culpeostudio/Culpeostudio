package philox

import (
	"encoding/json"
	"fmt"
	"strings"
)

type planningEnvelope struct {
	Phase         string                     `json:"phase"`
	Summary       string                     `json:"summary"`
	ResearchNotes []string                   `json:"research_notes"`
	Questions     []planningQuestionEnvelope `json:"questions"`
	Plan          *planningPlanEnvelope      `json:"plan"`
}

type planningQuestionEnvelope struct {
	ID          string                   `json:"id"`
	Prompt      string                   `json:"prompt"`
	Options     []planningOptionEnvelope `json:"options"`
	AllowCustom bool                     `json:"allow_custom"`
}

type planningOptionEnvelope struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Description string `json:"description"`
}

type planningPlanEnvelope struct {
	Summary           string   `json:"summary"`
	Goal              string   `json:"goal"`
	ResearchNotes     []string `json:"research_notes"`
	Steps             []string `json:"steps"`
	Risks             []string `json:"risks"`
	Tests             []string `json:"tests"`
	ReadyForExecution bool     `json:"ready_for_execution"`
}

func ensurePlanningState(session *PersistedSession) *PlanningState {
	if session.Planning == nil {
		session.Planning = defaultPlanningState()
	}
	if session.Planning.Questions == nil {
		session.Planning.Questions = []PlanningQuestion{}
	}
	return session.Planning
}

func planningSystemInstruction() string {
	return strings.TrimSpace(`Interaktiver Planungsmodus ist aktiv.
Arbeite in der Reihenfolge Analyse -> Recherche mit read-only Tools -> Rueckfragen -> finaler Plan.
Du darfst in diesem Modus nur read-only Tools benutzen, um Dateien, Ordner und Metadaten zu untersuchen.
Fuehre niemals Schreib-, Loesch- oder Move-Aktionen aus, solange Planungsmodus aktiv ist.
Wenn Informationen fehlen, stelle gezielte Rueckfragen. Pro Antwort darfst du hoechstens 3 Fragen stellen. Jede Frage darf hoechstens 3 konkrete Vorschlaege mit kurzer Beschreibung enthalten. Erlaube zusaetzlich immer eine freie Nutzerantwort.
Wenn du Rueckfragen brauchst, antworte AUSSCHLIESSLICH mit gueltigem JSON in genau dieser Struktur:
{"phase":"questions","summary":"kurze Lageeinschaetzung","research_notes":["kurze Recherche"],"questions":[{"id":"scope","prompt":"Frage","allow_custom":true,"options":[{"id":"a","label":"Option A","description":"kurze Beschreibung"},{"id":"b","label":"Option B","description":"kurze Beschreibung"},{"id":"c","label":"Option C","description":"kurze Beschreibung"}]}]}
Wenn du alle noetigen Informationen hast, antworte AUSSCHLIESSLICH mit gueltigem JSON in genau dieser Struktur:
{"phase":"plan","summary":"kurze Zusammenfassung","research_notes":["kurze Recherche"],"plan":{"summary":"Plan in einem Satz","goal":"Ziel","steps":["Schritt 1","Schritt 2"],"risks":["Risiko"],"tests":["Test"],"ready_for_execution":true}}
Gib niemals Markdown ausserhalb dieses JSON aus.
Behaupte im Planungsmodus nie, dass du etwas schon umgesetzt hast.`)
}

func planningStatePrompt(state *PlanningState) string {
	if state == nil {
		return ""
	}
	parts := []string{fmt.Sprintf("Aktueller Planungsstatus: %s", state.Status)}
	if strings.TrimSpace(state.Summary) != "" {
		parts = append(parts, "Letzte Zusammenfassung: "+strings.TrimSpace(state.Summary))
	}
	if len(state.Questions) > 0 {
		lines := make([]string, 0, len(state.Questions))
		for _, question := range state.Questions {
			lines = append(lines, fmt.Sprintf("%s: %s", question.ID, question.Prompt))
		}
		parts = append(parts, "Offene Fragen: "+strings.Join(lines, " | "))
	}
	if state.Draft != nil {
		draftParts := []string{}
		if strings.TrimSpace(state.Draft.Goal) != "" {
			draftParts = append(draftParts, "Ziel="+state.Draft.Goal)
		}
		if len(state.Draft.Steps) > 0 {
			draftParts = append(draftParts, "Schritte="+strings.Join(state.Draft.Steps, " | "))
		}
		if len(draftParts) > 0 {
			parts = append(parts, "Letzter Plan: "+strings.Join(draftParts, "; "))
		}
	}
	return strings.Join(parts, "\n")
}

func processPlanningResponse(session *PersistedSession, raw string) string {
	content := strings.TrimSpace(raw)
	if content == "" {
		return ""
	}
	envelope, err := parsePlanningEnvelope(content)
	if err != nil {
		return content
	}
	state := ensurePlanningState(session)
	state.Summary = envelope.Summary
	state.UpdatedAt = nowUTC()

	switch envelope.Phase {
	case "questions":
		state.Status = PlanningStatusNeedsAnswers
		state.Draft = nil
		state.Questions = make([]PlanningQuestion, 0, len(envelope.Questions))
		for index, question := range envelope.Questions {
			state.Questions = append(state.Questions, PlanningQuestion{
				ID:          fallbackID(question.ID, fmt.Sprintf("q%d", index+1)),
				Prompt:      strings.TrimSpace(question.Prompt),
				Options:     sanitizePlanningOptions(question.Options),
				AllowCustom: true,
			})
		}
	case "plan":
		state.Status = PlanningStatusReady
		state.Questions = []PlanningQuestion{}
		state.Draft = &PlanningDraft{
			Summary: firstNonEmpty(envelope.Plan.Summary, envelope.Summary),
			Goal:    strings.TrimSpace(envelope.Plan.Goal),
			ResearchNotes: compactLines(
				append(
					append([]string{}, envelope.ResearchNotes...),
					envelope.Plan.ResearchNotes...,
				),
			),
			Steps:             compactLines(envelope.Plan.Steps),
			Risks:             compactLines(envelope.Plan.Risks),
			Tests:             compactLines(envelope.Plan.Tests),
			ReadyForExecution: envelope.Plan.ReadyForExecution || len(envelope.Plan.Steps) > 0,
		}
	default:
		return content
	}

	return renderPlanningEnvelope(envelope)
}

func parsePlanningEnvelope(raw string) (*planningEnvelope, error) {
	normalized := strings.TrimSpace(stripJSONCodeFence(raw))
	var envelope planningEnvelope
	if err := json.Unmarshal([]byte(normalized), &envelope); err == nil {
		return sanitizePlanningEnvelope(&envelope)
	}

	start := strings.Index(normalized, "{")
	end := strings.LastIndex(normalized, "}")
	if start < 0 || end <= start {
		return nil, fmt.Errorf("planning json fehlt")
	}
	if err := json.Unmarshal([]byte(normalized[start:end+1]), &envelope); err != nil {
		return nil, err
	}
	return sanitizePlanningEnvelope(&envelope)
}

func sanitizePlanningEnvelope(envelope *planningEnvelope) (*planningEnvelope, error) {
	if envelope == nil {
		return nil, fmt.Errorf("planning envelope fehlt")
	}
	envelope.Phase = strings.ToLower(strings.TrimSpace(envelope.Phase))
	envelope.Summary = strings.TrimSpace(envelope.Summary)
	envelope.ResearchNotes = compactLines(envelope.ResearchNotes)

	switch envelope.Phase {
	case "questions":
		if len(envelope.Questions) == 0 {
			return nil, fmt.Errorf("planning questions fehlen")
		}
		if len(envelope.Questions) > 3 {
			envelope.Questions = envelope.Questions[:3]
		}
		for index := range envelope.Questions {
			question := &envelope.Questions[index]
			question.ID = fallbackID(question.ID, fmt.Sprintf("q%d", index+1))
			question.Prompt = strings.TrimSpace(question.Prompt)
			if question.Prompt == "" {
				return nil, fmt.Errorf("planning question ohne prompt")
			}
			if len(question.Options) > 3 {
				question.Options = question.Options[:3]
			}
			for optionIndex := range question.Options {
				option := &question.Options[optionIndex]
				option.ID = fallbackID(option.ID, fmt.Sprintf("%s_o%d", question.ID, optionIndex+1))
				option.Label = strings.TrimSpace(option.Label)
				option.Description = strings.TrimSpace(option.Description)
			}
		}
	case "plan":
		if envelope.Plan == nil {
			return nil, fmt.Errorf("planning plan fehlt")
		}
		envelope.Plan.Summary = strings.TrimSpace(envelope.Plan.Summary)
		envelope.Plan.Goal = strings.TrimSpace(envelope.Plan.Goal)
		envelope.Plan.ResearchNotes = compactLines(envelope.Plan.ResearchNotes)
		envelope.Plan.Steps = compactLines(envelope.Plan.Steps)
		envelope.Plan.Risks = compactLines(envelope.Plan.Risks)
		envelope.Plan.Tests = compactLines(envelope.Plan.Tests)
	default:
		return nil, fmt.Errorf("unbekannte planning phase")
	}
	return envelope, nil
}

func renderPlanningEnvelope(envelope *planningEnvelope) string {
	if envelope == nil {
		return ""
	}
	var builder strings.Builder
	builder.WriteString("## Planungsmodus\n")
	if envelope.Summary != "" {
		builder.WriteString(envelope.Summary)
		builder.WriteString("\n")
	}

	notes := compactLines(append([]string{}, envelope.ResearchNotes...))
	if envelope.Plan != nil {
		notes = compactLines(append(notes, envelope.Plan.ResearchNotes...))
	}
	if len(notes) > 0 {
		builder.WriteString("\n### Recherche\n")
		for _, note := range notes {
			builder.WriteString("- ")
			builder.WriteString(note)
			builder.WriteString("\n")
		}
	}

	if envelope.Phase == "questions" {
		builder.WriteString("\n### Offene Fragen\n")
		for index, question := range envelope.Questions {
			builder.WriteString(fmt.Sprintf("%d. %s\n", index+1, strings.TrimSpace(question.Prompt)))
			for _, option := range question.Options {
				if strings.TrimSpace(option.Label) == "" {
					continue
				}
				builder.WriteString("- ")
				builder.WriteString(option.Label)
				if strings.TrimSpace(option.Description) != "" {
					builder.WriteString(": ")
					builder.WriteString(option.Description)
				}
				builder.WriteString("\n")
			}
		}
		builder.WriteString("\nBeantworte die Fragen ueber das Auswahlfenster oder frei im Chat.")
		return strings.TrimSpace(builder.String())
	}

	if envelope.Plan != nil {
		if strings.TrimSpace(envelope.Plan.Goal) != "" {
			builder.WriteString("\n### Ziel\n")
			builder.WriteString(envelope.Plan.Goal)
			builder.WriteString("\n")
		}
		if len(envelope.Plan.Steps) > 0 {
			builder.WriteString("\n### Plan\n")
			for index, step := range envelope.Plan.Steps {
				builder.WriteString(fmt.Sprintf("%d. %s\n", index+1, step))
			}
		}
		if len(envelope.Plan.Risks) > 0 {
			builder.WriteString("\n### Risiken\n")
			for _, risk := range envelope.Plan.Risks {
				builder.WriteString("- ")
				builder.WriteString(risk)
				builder.WriteString("\n")
			}
		}
		if len(envelope.Plan.Tests) > 0 {
			builder.WriteString("\n### Tests\n")
			for _, test := range envelope.Plan.Tests {
				builder.WriteString("- ")
				builder.WriteString(test)
				builder.WriteString("\n")
			}
		}
		builder.WriteString("\nNutze `Plan ausfuehren` oder bestaetige im Chat, damit ich mit der Umsetzung starte.")
	}

	return strings.TrimSpace(builder.String())
}

func sanitizePlanningOptions(options []planningOptionEnvelope) []PlanningOption {
	sanitized := make([]PlanningOption, 0, len(options))
	for index, option := range options {
		label := strings.TrimSpace(option.Label)
		if label == "" {
			continue
		}
		sanitized = append(sanitized, PlanningOption{
			ID:          fallbackID(option.ID, fmt.Sprintf("option_%d", index+1)),
			Label:       label,
			Description: strings.TrimSpace(option.Description),
		})
	}
	return sanitized
}

func compactLines(lines []string) []string {
	compact := make([]string, 0, len(lines))
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		compact = append(compact, trimmed)
	}
	return compact
}

func stripJSONCodeFence(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if strings.HasPrefix(trimmed, "```json") {
		trimmed = strings.TrimPrefix(trimmed, "```json")
		trimmed = strings.TrimSpace(trimmed)
	}
	if strings.HasPrefix(trimmed, "```") {
		trimmed = strings.TrimPrefix(trimmed, "```")
		trimmed = strings.TrimSpace(trimmed)
	}
	if strings.HasSuffix(trimmed, "```") {
		trimmed = strings.TrimSuffix(trimmed, "```")
	}
	return strings.TrimSpace(trimmed)
}

func fallbackID(raw, fallback string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return fallback
	}
	return trimmed
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}
