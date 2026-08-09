package memory

import (
	"fmt"
	"strings"

	"github.com/culpeohq/backend/internal/memorytoken"
)

func (s *Service) publish(eventType string, payload interface{}) {
	if s.publisher != nil {
		s.publisher.Publish(eventType, payload)
	}
}

func renderInjectionPrompt(query string, goals []string, summary *SessionSummary, memories []CompressedMemory, observations []Observation, budgetTokens int) string {
	toolsLine := "Available memory tools: memory_search, memory_timeline, memory_get_observations"
	remaining := budgetTokens - memorytoken.Estimate(toolsLine)

	sections := []string{}
	appendSection := func(text string) bool {
		text = strings.TrimSpace(text)
		if text == "" {
			return true
		}
		cost := memorytoken.Estimate(text)
		if cost > remaining {
			return false
		}
		sections = append(sections, text)
		remaining -= cost
		return true
	}

	if strings.TrimSpace(query) != "" {
		appendSection("Memory query: " + previewText(query, 260))
	}
	if len(goals) > 0 {
		appendSection("Session goals: " + strings.Join(goals, " | "))
	}
	if summary != nil {
		appendSection("Latest summary learned: " + strings.Join(summary.Learned, " | "))
		if len(summary.NextSteps) > 0 {
			appendSection("Latest next steps: " + strings.Join(summary.NextSteps, " | "))
		}
	}
	for _, memoryItem := range memories {
		appendSection("Compressed memory: " + previewText(memoryItem.Summary, 320))
	}

	overflow := []string{}
	for _, observation := range observations {
		line := fallbackTitle(observation.Title, observation.Type)
		if observation.Narrative != "" {
			line += ": " + previewText(observation.Narrative, 220)
		}
		if observation.Topic != "" {
			line += " [topic: " + previewText(observation.Topic, 80) + "]"
		}
		if len(observation.Keywords) > 0 {
			line += " [keywords: " + previewText(strings.Join(observation.Keywords, ", "), 100) + "]"
		}
		if len(overflow) == 0 && appendSection("Observation: "+line) {
			continue
		}
		overflow = append(overflow, summarizeOverflowObservation(observation))
	}
	if len(overflow) > 0 && remaining > 8 {
		condensed := fmt.Sprintf("Weitere Observations (%d, zusammengefasst): %s", len(overflow), strings.Join(overflow, "; "))
		sections = append(sections, softTrim(condensed, remaining))
	}
	sections = append(sections, toolsLine)
	return strings.TrimSpace(strings.Join(sections, "\n"))
}

func summarizeOverflowObservation(observation Observation) string {
	if strings.TrimSpace(observation.Topic) != "" {
		return previewText(observation.Topic, 60)
	}
	return previewText(fallbackTitle(observation.Title, observation.Type), 60)
}

func softTrim(text string, maxTokens int) string {
	if memorytoken.Estimate(text) <= maxTokens {
		return text
	}
	sentences := splitSentences(text)
	builder := strings.Builder{}
	used := 0
	for _, sentence := range sentences {
		cost := memorytoken.Estimate(sentence)
		if used+cost > maxTokens {
			break
		}
		builder.WriteString(sentence)
		used += cost
	}
	if builder.Len() > 0 {
		return strings.TrimSpace(builder.String())
	}
	words := strings.Fields(text)
	builder.Reset()
	used = 0
	for _, word := range words {
		cost := memorytoken.Estimate(word)
		if used+cost > maxTokens {
			break
		}
		builder.WriteString(word)
		builder.WriteString(" ")
		used += cost
	}
	return strings.TrimSpace(builder.String()) + "…"
}

func splitSentences(text string) []string {
	result := []string{}
	start := 0
	for idx, r := range text {
		if r == '.' || r == '!' || r == '?' || r == ';' || r == '\n' {
			result = append(result, text[start:idx+1])
			start = idx + 1
		}
	}
	if start < len(text) {
		result = append(result, text[start:])
	}
	return result
}

func searchResultsFromDocuments(documents []SearchDocument) []SearchResult {
	results := make([]SearchResult, 0, len(documents))
	for _, document := range documents {
		results = append(results, SearchResult{
			DocID:     document.DocID,
			UserID:    document.UserID,
			SessionID: document.SessionID,
			RefID:     document.RefID,
			Kind:      document.Kind,
			Project:   document.Project,
			Source:    document.Source,
			Layer:     document.Layer,
			Category:  document.Category,
			Type:      document.Type,
			Title:     document.Title,
			Snippet:   previewText(document.Body, 220),
			Score:     0.1 + recencyBoost(document.CreatedAt) + typeBoost(document.Type, document.Layer) + sourceBoost(document.Source, document.Layer),
			CreatedAt: document.CreatedAt,
		})
	}
	return results
}
