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

func (m *ScoutModule) streamProviderChat(ctx context.Context, provider, modelID string, messages []chatMessage, systemPrompt, thinkingLevel string, emit func(string) error, emitReasoning func(string) error) (string, error) {
	reasoning := thinking.ReasoningFor(thinking.Normalize(thinkingLevel))
	if apimodels.NormalizeProvider(provider) == localinference.ProviderLocal {
		if m.localModels == nil {
			return "", fmt.Errorf("lokale Modell-Engine ist nicht verfuegbar")
		}
		localMessages := make([]localinference.Message, 0, len(messages)+1)
		localMessages = append(localMessages, localinference.Message{Role: "system", Content: systemPrompt})
		for _, message := range messages {
			localMessages = append(localMessages, localinference.Message{Role: message.Role, Content: message.Content})
		}
		temperature := reasoning.Temperature
		return m.localModels.StreamLocalChat(ctx, modelID, localinference.ChatRequest{
			Messages: localMessages, Temperature: &temperature,
		}, emit)
	}
	settings, err := m.loadSettings()
	if err != nil {
		return "", err
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
		return "", fmt.Errorf("provider wird fuer API-Chat nicht unterstuetzt")
	}
	if token == "" {
		return "", fmt.Errorf("%s API-Key fehlt in den Einstellungen", providerDisplayName(provider))
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

	if apimodels.NormalizeProvider(provider) == apimodels.ProviderOpenRouter && reasoning.Effort != "" {
		payload["reasoning"] = map[string]interface{}{"effort": reasoning.Effort}
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, bytes.NewReader(data))
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "text/event-stream")
	req.Header.Set("User-Agent", "culpeostudio-scout/1.0")

	resp, err := m.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return "", &providerChatHTTPError{
			Provider:   provider,
			StatusCode: resp.StatusCode,
			Detail:     formatProviderError(provider, resp.StatusCode, body),
		}
	}

	return readOpenAIStream(resp.Body, emit, emitReasoning)
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

func readOpenAIStream(r io.Reader, emit func(string) error, emitReasoning func(string) error) (string, error) {
	reader := bufio.NewReader(r)
	var reply strings.Builder
	var eventData bytes.Buffer
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

	for {
		line, err := reader.ReadBytes('\n')
		if len(line) > 0 {
			line = bytes.TrimRight(line, "\r\n")
			trimmedLine := bytes.TrimSpace(line)
			switch {
			case len(trimmedLine) == 0:
				done, flushErr := flushEvent()
				if flushErr != nil {
					return "", flushErr
				}
				if done {
					goto streamDone
				}
			case bytes.HasPrefix(trimmedLine, []byte(":")),
				bytes.HasPrefix(trimmedLine, []byte("event:")):

			case bytes.HasPrefix(trimmedLine, []byte("data:")):
				dataLine := bytes.TrimSpace(bytes.TrimPrefix(trimmedLine, []byte("data:")))
				if len(dataLine) == 0 {
					continue
				}
				if eventData.Len() > 0 {
					eventData.WriteByte('\n')
				}
				eventData.Write(dataLine)
			}
		}
		if err != nil {
			if errors.Is(err, io.EOF) {
				done, flushErr := flushEvent()
				if flushErr != nil {
					return "", flushErr
				}
				if done {
					break
				}
				break
			}
			return "", err
		}
	}

streamDone:
	cleanReply := strings.TrimSpace(reply.String())
	if cleanReply == "" {
		return "", fmt.Errorf("Provider hat keine Chat-Antwort geliefert. Bitte ein anderes API-Modell waehlen oder Provider-Key/Modell pruefen")
	}
	return reply.String(), nil
}

type openAIChunk struct {
	Content   string
	Reasoning string
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
			Text string `json:"text"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(raw, &payload); err != nil {
		return openAIChunk{}
	}
	var content, reasoning strings.Builder
	for _, choice := range payload.Choices {
		content.WriteString(choice.Delta.Content)
		content.WriteString(choice.Message.Content)
		content.WriteString(choice.Text)
		reasoning.WriteString(choice.Delta.Reasoning)
		reasoning.WriteString(choice.Message.Reasoning)
	}
	return openAIChunk{Content: content.String(), Reasoning: reasoning.String()}
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
