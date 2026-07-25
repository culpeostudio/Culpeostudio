package philox

import (
	"strings"
	"testing"
)

func TestSystemPromptForSessionUsesActiveBotIdentity(t *testing.T) {
	prompt := systemPromptForSession(&PersistedSession{
		ActiveBotID:           "researcher",
		ActiveBotName:         "ResearchBot",
		ActiveBotSystemPrompt: "Du pruefst Quellen kritisch.",
		Mode:                  ModeExecute,
	})

	for _, expected := range []string{"ausschliesslich als ResearchBot", "Bot-ID: researcher", "ChatGPT oder Philox", "Du pruefst Quellen kritisch."} {
		if !strings.Contains(prompt, expected) {
			t.Fatalf("expected active bot identity instruction %q in prompt, got %q", expected, prompt)
		}
	}
}
