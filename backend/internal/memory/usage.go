package memory

import (
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/memorytoken"
)

func EstimateUsage(session *Session) float64 {
	total := 0
	for _, prompt := range session.Prompts {
		total += memorytoken.Estimate(prompt.Text) + 12
	}
	for _, observation := range session.ActiveObservations {
		total += memorytoken.Estimate(observation.Title) + memorytoken.Estimate(observation.Narrative) + 20
	}
	for _, memoryItem := range session.Memories {
		total += memorytoken.Estimate(memoryItem.Summary) + 24
	}
	return float64(total) / float64(usageBudgetTokens)
}

func estimateUsageAfterCompression(session *Session, memoryItem *CompressedMemory) float64 {
	compressed := map[string]struct{}{}
	for _, id := range memoryItem.ObservationIDs {
		compressed[id] = struct{}{}
	}
	projected := &Session{
		Prompts:  session.Prompts,
		Memories: append(append([]CompressedMemory{}, session.Memories...), *memoryItem),
	}
	for _, observation := range session.ActiveObservations {
		if _, ok := compressed[observation.ID]; ok {
			continue
		}
		projected.ActiveObservations = append(projected.ActiveObservations, observation)
	}
	return EstimateUsage(projected)
}

func summarizeObservations(observations []Observation) string {
	if len(observations) == 0 {
		return "Keine Beobachtungen verfuegbar."
	}
	parts := make([]string, 0, len(observations))
	for _, observation := range observations {
		part := fallbackTitle(observation.Title, observation.Type)
		if observation.Narrative != "" {
			part += ": " + previewText(observation.Narrative, 120)
		}
		parts = append(parts, part)
		if len(parts) == 6 {
			break
		}
	}
	return strings.Join(parts, " | ")
}

func extractObservationHighlights(observations []Observation, limit int) []string {
	result := make([]string, 0, limit)
	for _, observation := range observations {
		if strings.TrimSpace(observation.Narrative) == "" {
			continue
		}
		result = append(result, previewText(observation.Narrative, 160))
		if len(result) == limit {
			break
		}
	}
	return normalizeList(result)
}

func extractObservationTasks(observations []Observation, limit int) []string {
	result := make([]string, 0, limit)
	for _, observation := range observations {
		text := strings.TrimSpace(observation.Title + " " + observation.Narrative)
		lower := strings.ToLower(text)
		if strings.Contains(lower, "todo") || strings.Contains(lower, "next") || strings.Contains(text, "?") || strings.Contains(lower, "open") {
			result = append(result, previewText(text, 160))
			if len(result) == limit {
				break
			}
		}
	}
	return normalizeList(result)
}

func collectObservationIDs(observations []Observation) []string {
	result := make([]string, 0, len(observations))
	for _, observation := range observations {
		result = append(result, observation.ID)
	}
	return result
}

func deriveLearned(session *Session) []string {
	result := make([]string, 0, 4)
	for _, memoryItem := range session.Memories {
		result = append(result, memoryItem.Learned...)
		if len(result) >= 4 {
			break
		}
	}
	return normalizeList(result)
}

func deriveCompleted(session *Session) []string {
	result := make([]string, 0, 4)
	for _, observation := range session.ActiveObservations {
		if observation.Type == "decision" || observation.Type == "tool_result" || observation.Type == "assistant_reply" {
			result = append(result, fallbackTitle(observation.Title, observation.Type))
		}
		if len(result) >= 4 {
			break
		}
	}
	return normalizeList(result)
}

func deriveNextSteps(session *Session) []string {
	result := make([]string, 0, 4)
	for _, memoryItem := range session.Memories {
		result = append(result, memoryItem.OpenTasks...)
		if len(result) >= 4 {
			break
		}
	}
	if len(result) == 0 {
		result = append(result, session.Goals...)
	}
	return normalizeList(result)
}

func fallbackString(value, fallback string) string {
	if strings.TrimSpace(value) != "" {
		return strings.TrimSpace(value)
	}
	return strings.TrimSpace(fallback)
}

func fallbackTitle(title, observationType string) string {
	if strings.TrimSpace(title) != "" {
		return strings.TrimSpace(title)
	}
	if strings.TrimSpace(observationType) != "" {
		return fmt.Sprintf("Observation (%s)", strings.TrimSpace(observationType))
	}
	return "Observation"
}

func recencyBoost(createdAt time.Time) float64 {
	ageHours := time.Since(createdAt).Hours()
	if ageHours <= 0 {
		return 0.08
	}
	return math.Max(0, 0.08-(ageHours/24.0)*0.01)
}

func typeBoost(observationType string, layer MemoryLayer) float64 {
	boost := 0.0
	switch observationType {
	case "decision", "tool_result", "summary":
		boost += 0.03
	case "event", "assistant_reply", "chat_memory":
		boost += 0.015
	}
	if layer == LayerUserData {
		boost += 0.10
	}
	return boost
}

func sourceBoost(source string, layer MemoryLayer) float64 {
	boost := 0.0
	switch strings.ToLower(strings.TrimSpace(source)) {
	case "spark", "chat":
		boost += 0.02
	}
	if layer == LayerUserData {
		boost += 0.05
	}
	return boost
}

func normalizeWeight(value float64, fallback float64) float64 {
	if value <= 0 {
		return fallback
	}
	if value > 1 {
		return 1
	}
	return value
}
