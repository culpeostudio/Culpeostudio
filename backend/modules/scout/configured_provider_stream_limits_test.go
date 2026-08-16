package scout

import (
	"strings"
	"testing"
)

// These tests intentionally exercise the readers directly.  A configured
// OpenAI-compatible connection reaches readOpenAIStream, while Anthropic and
// Gemini reach readConfiguredSSEStream; both must fail closed before buffering
// an unbounded provider-controlled response.
func TestConfiguredProviderSSERejectsOversizedLine(t *testing.T) {
	input := "data: " + strings.Repeat("x", maxConfiguredStreamLineBytes+1) + "\n\n"

	_, _, err := readConfiguredSSEStream(strings.NewReader(input), nil, nil, configuredSSEIgnoreEvent)
	if err == nil || !strings.Contains(err.Error(), "Provider-Stream-Zeile ist zu groß") {
		t.Fatalf("readConfiguredSSEStream error = %v, want oversized-line rejection", err)
	}
}

func TestConfiguredProviderOpenAISSERejectsOversizedLine(t *testing.T) {
	input := "data: " + strings.Repeat("x", maxConfiguredStreamLineBytes+1) + "\n\n"

	_, _, err := readOpenAIStream(strings.NewReader(input), nil, nil)
	if err == nil || !strings.Contains(err.Error(), "Provider-Stream-Zeile ist zu groß") {
		t.Fatalf("readOpenAIStream error = %v, want oversized-line rejection", err)
	}
}

func TestConfiguredProviderSSERejectsOversizedTotalStream(t *testing.T) {
	_, _, err := readConfiguredSSEStream(strings.NewReader(configuredSSEOverTotalLimit()), nil, nil, configuredSSEIgnoreEvent)
	if err == nil || !strings.Contains(err.Error(), "Provider-Stream ist zu groß") {
		t.Fatalf("readConfiguredSSEStream error = %v, want total-size rejection", err)
	}
}

func TestConfiguredProviderOpenAISSERejectsOversizedTotalStream(t *testing.T) {
	_, _, err := readOpenAIStream(strings.NewReader(configuredSSEOverTotalLimit()), nil, nil)
	if err == nil || !strings.Contains(err.Error(), "Provider-Stream ist zu groß") {
		t.Fatalf("readOpenAIStream error = %v, want total-size rejection", err)
	}
}

func configuredSSEIgnoreEvent(_ []byte) (configuredSSEEvent, error) {
	return configuredSSEEvent{}, nil
}

func configuredSSEOverTotalLimit() string {
	// Keep every physical SSE line tiny.  This proves the aggregate cap rather
	// than merely retesting the per-line guard.
	event := "data: " + strings.Repeat("x", 4096) + "\n\n"
	return strings.Repeat(event, maxConfiguredStreamBytes/len(event)+1)
}
