package philox

import (
	"fmt"
	"strings"
)

const (
	compressionThreshold = 0.70
	activeMessageWindow  = 8
)

const defaultModelContextLimit = 128000

// contextLimitForModel returns the assumed context window used to estimate
// session usage. Model-specific overrides can be added here as needed; for now
// every model falls back to a conservative default.
func contextLimitForModel(model string) int {
	return defaultModelContextLimit
}

func estimateMessageTokens(message ConversationMessage) int {
	total := len(message.Content)/4 + 16
	for _, toolCall := range message.ToolCalls {
		total += len(toolCall.Function.Name)/4 + len(toolCall.Function.Arguments)/4 + 24
	}
	for key, value := range message.Metadata {
		total += len(key)/4 + len(fmt.Sprint(value))/4 + 8
	}
	return total
}

func estimateSessionUsage(session *PersistedSession) float64 {
	totalTokens := 0
	for _, memory := range session.CompressedMemories {
		totalTokens += len(memory.Summary)/4 + 64
		for _, value := range memory.Goals {
			totalTokens += len(value)/4 + 8
		}
		for _, value := range memory.OpenTasks {
			totalTokens += len(value)/4 + 8
		}
	}
	for _, message := range session.Messages {
		totalTokens += estimateMessageTokens(message)
	}
	limit := contextLimitForModel(session.EffectiveModel)
	if limit == 0 {
		return 0
	}
	return float64(totalTokens) / float64(limit)
}

func maybeCompressSession(session *PersistedSession) *CompressionEvent {
	usageBefore := estimateSessionUsage(session)
	session.ContextUsageEstimate = usageBefore
	if usageBefore < compressionThreshold || len(session.Messages) <= activeMessageWindow {
		return nil
	}

	compressCount := len(session.Messages) - activeMessageWindow
	toCompress := append([]ConversationMessage{}, session.Messages[:compressCount]...)
	memory := CompressedMemory{
		ID:                 fmt.Sprintf("memory-%d", nowUTC().UnixNano()),
		Summary:            buildSummary(toCompress),
		Goals:              extractMessageHighlights(toCompress, "user", 4),
		OpenTasks:          extractOpenTasks(toCompress, 4),
		AllowedRoots:       append([]string{}, session.AllowedRoots...),
		SourceMessageCount: len(toCompress),
		CreatedAt:          nowUTC(),
	}

	session.ArchivedMessages = append(session.ArchivedMessages, toCompress...)
	session.CompressedMemories = append(session.CompressedMemories, memory)
	session.Messages = append([]ConversationMessage{}, session.Messages[compressCount:]...)
	usageAfter := estimateSessionUsage(session)
	session.ContextUsageEstimate = usageAfter

	return &CompressionEvent{
		Triggered:          true,
		Threshold:          compressionThreshold,
		UsageBefore:        usageBefore,
		UsageAfter:         usageAfter,
		CompressedMessages: len(toCompress),
		MemoryID:           memory.ID,
	}
}

func buildSummary(messages []ConversationMessage) string {
	if len(messages) == 0 {
		return "Keine frueheren Nachrichten wurden komprimiert."
	}
	parts := make([]string, 0, len(messages))
	for _, message := range messages {
		content := previewText(message.Content, 220)
		if content == "" {
			if len(message.ToolCalls) > 0 {
				content = fmt.Sprintf("Tool-Aufruf %s", message.ToolCalls[0].Function.Name)
			} else {
				continue
			}
		}
		parts = append(parts, fmt.Sprintf("%s: %s", message.Role, content))
		if len(parts) == 8 {
			break
		}
	}
	if len(parts) == 0 {
		return "Der bisherige Verlauf enthielt nur technische Tool-Nachrichten."
	}
	return strings.Join(parts, " | ")
}

func extractMessageHighlights(messages []ConversationMessage, role string, limit int) []string {
	results := make([]string, 0, limit)
	seen := map[string]struct{}{}
	for i := len(messages) - 1; i >= 0 && len(results) < limit; i-- {
		message := messages[i]
		if message.Role != role {
			continue
		}
		text := previewText(message.Content, 160)
		if text == "" {
			continue
		}
		if _, ok := seen[text]; ok {
			continue
		}
		seen[text] = struct{}{}
		results = append(results, text)
	}
	for i, j := 0, len(results)-1; i < j; i, j = i+1, j-1 {
		results[i], results[j] = results[j], results[i]
	}
	return results
}

func extractOpenTasks(messages []ConversationMessage, limit int) []string {
	results := make([]string, 0, limit)
	for i := len(messages) - 1; i >= 0 && len(results) < limit; i-- {
		message := messages[i]
		if message.Role != "user" {
			continue
		}
		text := strings.TrimSpace(message.Content)
		if text == "" {
			continue
		}
		lower := strings.ToLower(text)
		if strings.Contains(text, "?") || strings.Contains(lower, "bitte") || strings.Contains(lower, "mach") {
			results = append(results, previewText(text, 160))
		}
	}
	for i, j := 0, len(results)-1; i < j; i, j = i+1, j-1 {
		results[i], results[j] = results[j], results[i]
	}
	return results
}
