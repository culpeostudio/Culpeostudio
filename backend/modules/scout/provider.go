package scout

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/internal/thinking"
)

// providerTurn is one request to whatever model answers this session. It grew
// into a struct when the answer ceiling joined the thinking knobs: a positional
// call with a dozen arguments stops saying which string is which.
type providerTurn struct {
	UserID          string
	Provider        string
	ConnectionID    string
	ModelID         string
	Messages        []chatMessage
	SystemPrompt    string
	ThinkingLevel   string
	ReasoningEffort string
	// MaxOutputTokens caps the answer. Zero leaves it to the provider, which is
	// what every path did before the ceiling was resolved per model.
	MaxOutputTokens int
	Emit            func(string) error
	EmitReasoning   func(string) error
}

// streamProviderChat runs one turn and reports both the reply and why the model
// stopped, so a caller can tell an answer that ended from one that ran out of
// output budget.
func (m *ScoutModule) streamProviderChat(ctx context.Context, turn providerTurn) (string, string, error) {
	if strings.TrimSpace(turn.ConnectionID) != "" {
		connection, _, err := m.configuredConnectionForChat(turn.UserID, turn.ConnectionID, turn.ModelID)
		if err != nil {
			return "", "", err
		}
		return m.streamConfiguredProviderChat(ctx, connection, turn)
	}
	reasoning := thinking.ReasoningFor(thinking.Normalize(turn.ThinkingLevel))
	if turn.ReasoningEffort != "" {
		reasoning.Effort = turn.ReasoningEffort
	}
	provider := turn.Provider
	modelID := turn.ModelID
	messages := turn.Messages
	systemPrompt := turn.SystemPrompt
	emit := turn.Emit
	emitReasoning := turn.EmitReasoning
	if apimodels.NormalizeProvider(provider) == localinference.ProviderLocal {
		if m.localModels == nil {
			return "", "", fmt.Errorf("lokale Modell-Engine ist nicht verfuegbar")
		}
		localMessages := make([]localinference.Message, 0, len(messages)+1)
		localMessages = append(localMessages, localinference.Message{Role: "system", Content: systemPrompt})
		for _, message := range messages {
			localMessages = append(localMessages, localinference.Message{Role: message.Role, Content: message.Content})
		}
		temperature := reasoning.Temperature
		request := localinference.ChatRequest{Messages: localMessages, Temperature: &temperature}
		if turn.MaxOutputTokens > 0 {
			maxTokens := turn.MaxOutputTokens
			request.MaxTokens = &maxTokens
		}
		// Only the engine reports a finish reason; a provider that predates the
		// optional interface simply never says its answer was cut short.
		if reporter, ok := m.localModels.(localinference.FinishReasonProvider); ok {
			reply, reason, err := reporter.StreamLocalChatWithReason(ctx, modelID, request, emit)
			return reply, normalizeFinishReason(reason), err
		}
		reply, err := m.localModels.StreamLocalChat(ctx, modelID, request, emit)
		return reply, "", err
	}
	settings, err := m.loadSettings()
	if err != nil {
		return "", "", err
	}

	apiURL := ""
	token := ""
	switch apimodels.NormalizeProvider(provider) {
	case apimodels.ProviderOpenRouter:
		apiURL = strings.TrimRight(m.orAPIBase, "/") + "/api/v1/chat/completions"
		token = strings.TrimSpace(settings.OpenRouterToken)
	case apimodels.ProviderFeatherless:
		apiURL = strings.TrimRight(m.flAPIBase, "/") + "/v1/chat/completions"
		token = strings.TrimSpace(settings.FeatherlessToken)
	default:
		return "", "", fmt.Errorf("provider wird fuer API-Chat nicht unterstuetzt")
	}
	if token == "" {
		return "", "", fmt.Errorf("%s API-Key fehlt in den Einstellungen", providerDisplayName(provider))
	}

	providerMessages := make([]chatMessage, 0, len(messages)+1)
	providerMessages = append(providerMessages, chatMessage{
		Role:    "system",
		Content: systemPrompt,
	})
	for _, msg := range messages {
		providerMessages = append(providerMessages, chatMessage{
			Role:    msg.Role,
			Content: msg.Content,
		})
	}

	payload := map[string]interface{}{
		"model":       strings.TrimSpace(modelID),
		"messages":    providerMessages,
		"stream":      true,
		"temperature": reasoning.Temperature,
		"top_p":       reasoning.TopP,
	}

	// Both OpenRouter and Featherless speak the OpenAI request shape, where an
	// omitted max_tokens leaves the ceiling to the provider - which is what
	// silently cut long answers short.
	if turn.MaxOutputTokens > 0 {
		payload["max_tokens"] = turn.MaxOutputTokens
	}

	if apimodels.NormalizeProvider(provider) == apimodels.ProviderOpenRouter && reasoning.Effort != "" {
		payload["reasoning"] = map[string]interface{}{"effort": reasoning.Effort}
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return "", "", err
	}

	// The turn itself may take as long as it takes; only silence ends it.
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, bytes.NewReader(data))
	if err != nil {
		return "", "", err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "text/event-stream")
	req.Header.Set("User-Agent", "culpeostudio-scout/1.0")

	resp, err := m.httpClient.Do(req)
	if err != nil {
		return "", "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return "", "", &providerChatHTTPError{
			Provider:   provider,
			StatusCode: resp.StatusCode,
			Detail:     formatProviderError(provider, resp.StatusCode, body),
		}
	}

	body, stopWatch := watchProviderStall(resp.Body, provider, cancel, providerStreamIdleTimeout)
	defer stopWatch()
	return readOpenAIStream(body, emit, emitReasoning)
}

func formatProviderError(provider string, statusCode int, body []byte) string {
	raw := strings.TrimSpace(string(body))
	if raw == "" {
		return http.StatusText(statusCode)
	}

	var providerErr struct {
		Error struct {
			Message string `json:"message"`
			Code    any    `json:"code"`
		} `json:"error"`
		Message string `json:"message"`
	}
	if err := json.Unmarshal(body, &providerErr); err == nil {
		message := strings.TrimSpace(providerErr.Error.Message)
		if message == "" {
			message = strings.TrimSpace(providerErr.Message)
		}
		if message != "" {
			if apimodels.NormalizeProvider(provider) == apimodels.ProviderOpenRouter &&
				statusCode == http.StatusUnauthorized &&
				strings.EqualFold(message, "User not found.") {
				return "OpenRouter API-Key ist ungueltig oder gehoert zu keinem OpenRouter-Konto. Bitte in den Einstellungen einen neuen OpenRouter-Key hinterlegen."
			}
			return message
		}
	}

	return raw
}

// providerStreamCounter keeps the scanner's input bounded even when a remote
// endpoint streams forever. The one extra byte lets callers distinguish a
// clean stream at the exact limit from an oversized stream without buffering
// the rest of the provider response.
type providerStreamCounter struct {
	reader io.Reader
	read   int64
}

func (r *providerStreamCounter) Read(payload []byte) (int, error) {
	n, err := r.reader.Read(payload)
	r.read += int64(n)
	return n, err
}

func newBoundedProviderStreamScanner(r io.Reader) (*bufio.Scanner, *providerStreamCounter) {
	counter := &providerStreamCounter{reader: r}
	scanner := bufio.NewScanner(io.LimitReader(counter, int64(maxConfiguredStreamBytes)+1))
	scanner.Buffer(make([]byte, 16*1024), maxConfiguredStreamLineBytes+1)
	return scanner, counter
}

func boundedProviderStreamError(scannerErr error, counter *providerStreamCounter) error {
	if errors.Is(scannerErr, bufio.ErrTooLong) {
		return errors.New("Provider-Stream-Zeile ist zu groß")
	}
	if counter != nil && counter.read > int64(maxConfiguredStreamBytes) {
		return errors.New("Provider-Stream ist zu groß")
	}
	return scannerErr
}

// readOpenAIStream returns the reply and why the model stopped. An empty reason
// means the stream never said, which counts as a normal end - guessing at
// truncation would cut complete answers in half.
func readOpenAIStream(r io.Reader, emit func(string) error, emitReasoning func(string) error) (string, string, error) {
	scanner, counter := newBoundedProviderStreamScanner(r)
	var reply strings.Builder
	var eventData bytes.Buffer
	finishReason := ""
	flushEvent := func() (bool, error) {
		raw := bytes.TrimSpace(eventData.Bytes())
		eventData.Reset()
		if len(raw) == 0 {
			return false, nil
		}
		if bytes.Equal(raw, []byte("[DONE]")) {
			return true, nil
		}
		chunk := extractOpenAIChunk(raw)
		// It rides on the final chunk, which normally carries no text of its own.
		if chunk.FinishReason != "" {
			finishReason = chunk.FinishReason
		}
		if chunk.Reasoning != "" && emitReasoning != nil {
			if err := emitReasoning(chunk.Reasoning); err != nil {
				return false, err
			}
		}
		if chunk.Content == "" {
			return false, nil
		}
		reply.WriteString(chunk.Content)
		if emit != nil {
			if err := emit(chunk.Content); err != nil {
				return false, err
			}
		}
		return false, nil
	}

	for scanner.Scan() {
		trimmedLine := bytes.TrimSpace(scanner.Bytes())
		switch {
		case len(trimmedLine) == 0:
			done, flushErr := flushEvent()
			if flushErr != nil {
				return "", "", flushErr
			}
			if done {
				return openAIStreamReply(reply.String(), finishReason)
			}
		case bytes.HasPrefix(trimmedLine, []byte(":")),
			bytes.HasPrefix(trimmedLine, []byte("event:")):

		case bytes.HasPrefix(trimmedLine, []byte("data:")):
			dataLine := bytes.TrimSpace(bytes.TrimPrefix(trimmedLine, []byte("data:")))
			if len(dataLine) == 0 {
				continue
			}
			if eventData.Len()+len(dataLine)+1 > maxConfiguredStreamLineBytes {
				return "", "", errors.New("Provider-Stream-Zeile ist zu groß")
			}
			if eventData.Len() > 0 {
				eventData.WriteByte('\n')
			}
			eventData.Write(dataLine)
		}
	}
	if err := boundedProviderStreamError(scanner.Err(), counter); err != nil {
		return "", "", err
	}
	if _, flushErr := flushEvent(); flushErr != nil {
		return "", "", flushErr
	}
	return openAIStreamReply(reply.String(), finishReason)
}

func openAIStreamReply(reply, finishReason string) (string, string, error) {
	cleanReply := strings.TrimSpace(reply)
	if cleanReply == "" {
		return "", "", fmt.Errorf("Provider hat keine Chat-Antwort geliefert. Bitte ein anderes API-Modell waehlen oder Provider-Key/Modell pruefen")
	}
	return reply, normalizeFinishReason(finishReason), nil
}

type openAIChunk struct {
	Content      string
	Reasoning    string
	FinishReason string
}

func extractOpenAIChunk(raw []byte) openAIChunk {
	var payload struct {
		Choices []struct {
			Delta struct {
				Content   string `json:"content"`
				Reasoning string `json:"reasoning"`
			} `json:"delta"`
			Message struct {
				Content   string `json:"content"`
				Reasoning string `json:"reasoning"`
			} `json:"message"`
			Text         string `json:"text"`
			FinishReason string `json:"finish_reason"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(raw, &payload); err != nil {
		return openAIChunk{}
	}
	var content, reasoning strings.Builder
	chunk := openAIChunk{}
	for _, choice := range payload.Choices {
		content.WriteString(choice.Delta.Content)
		content.WriteString(choice.Message.Content)
		content.WriteString(choice.Text)
		reasoning.WriteString(choice.Delta.Reasoning)
		reasoning.WriteString(choice.Message.Reasoning)
		if choice.FinishReason != "" {
			chunk.FinishReason = choice.FinishReason
		}
	}
	chunk.Content = content.String()
	chunk.Reasoning = reasoning.String()
	return chunk
}

// finishReasonLength marks a reply that ran into its output limit rather than
// ending on its own. The three chat protocols spell that differently; this is
// the OpenAI token, which two of them already use.
const finishReasonLength = "length"

// normalizeFinishReason maps each protocol's wording onto one vocabulary, so
// the continuation logic has a single thing to compare against.
func normalizeFinishReason(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "length", "max_tokens", "maxtokens", "max_output_tokens", "model_length":
		return finishReasonLength
	default:
		return strings.ToLower(strings.TrimSpace(raw))
	}
}

func (m *ScoutModule) loadSettings() (appsettings.Settings, error) {
	if err := m.settingsStore.Load(); err != nil && !os.IsNotExist(err) {
		return appsettings.Settings{}, err
	}
	return m.settingsStore.Get(), nil
}

func providerDisplayName(provider string) string {
	switch apimodels.NormalizeProvider(provider) {
	case localinference.ProviderLocal:
		return "Lokales Modell"
	case apimodels.ProviderOpenRouter:
		return "OpenRouter"
	case apimodels.ProviderFeatherless:
		return "Featherless"
	default:
		return strings.TrimSpace(provider)
	}
}
