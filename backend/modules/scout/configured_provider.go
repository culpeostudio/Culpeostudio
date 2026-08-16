package scout

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/culpeohq/backend/internal/providerconn"
	"github.com/culpeohq/backend/internal/thinking"
)

const (
	maxConfiguredStreamLineBytes = 1 << 20
	maxConfiguredStreamBytes     = 16 << 20
)

// streamConfiguredProviderChat runs a turn through a provider connection that
// was configured by the current user. The connection comes from
// providerconn.Manager, where its API key is encrypted at rest. This package
// never writes that key to a session, event, error, or log line.
func (m *ScoutModule) streamConfiguredProviderChat(
	ctx context.Context,
	connection providerconn.Connection,
	turn providerTurn,
) (string, string, error) {
	// A user-configured endpoint is still an external dependency, but the bound
	// is silence, not duration: a stream that keeps delivering may run as long
	// as the work takes, one that stops delivering is dropped. A wall-clock cap
	// here used to end agent runs that were still making progress.
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	if !connection.Enabled {
		return "", "", errors.New("Provider-Verbindung ist deaktiviert")
	}
	turn.ModelID = strings.TrimSpace(turn.ModelID)
	if turn.ModelID == "" {
		return "", "", errors.New("Provider-Modell fehlt")
	}

	reasoning := thinking.ReasoningFor(thinking.Normalize(turn.ThinkingLevel))
	if turn.ReasoningEffort != "" {
		reasoning.Effort = turn.ReasoningEffort
	}
	switch providerconn.NormalizeProtocol(connection.Protocol) {
	case providerconn.ProtocolOpenAICompatible:
		return m.streamConfiguredOpenAI(ctx, connection, turn, reasoning)
	case providerconn.ProtocolAnthropic:
		return m.streamConfiguredAnthropic(ctx, connection, turn, reasoning)
	case providerconn.ProtocolGoogleGenAI:
		return m.streamConfiguredGemini(ctx, connection, turn, reasoning)
	default:
		return "", "", errors.New("Provider-Protokoll wird für Chat nicht unterstützt")
	}
}

// configuredConnectionForChat re-checks the active-model decision immediately
// before a network request. A selected model may have been removed, disabled,
// or had its key cleared since the session was opened, so session persistence
// alone is never authorization to use a provider connection.
func (m *ScoutModule) configuredConnectionForChat(userID, connectionID, modelID string) (providerconn.Connection, providerconn.ActiveModel, error) {
	if m.providerConnections == nil {
		return providerconn.Connection{}, providerconn.ActiveModel{}, errors.New("Provider-Verwaltung ist nicht verfügbar")
	}
	connectionID = strings.TrimSpace(connectionID)
	modelID = strings.TrimSpace(modelID)
	if connectionID == "" || modelID == "" {
		return providerconn.Connection{}, providerconn.ActiveModel{}, errors.New("Provider-Verbindung und Modell sind erforderlich")
	}
	connection, err := m.providerConnections.GetConnection(userID, connectionID)
	if err != nil {
		return providerconn.Connection{}, providerconn.ActiveModel{}, err
	}
	if !connection.Enabled {
		return providerconn.Connection{}, providerconn.ActiveModel{}, errors.New("Provider-Verbindung ist deaktiviert")
	}
	if !providerconn.IsChatProtocol(connection.Protocol) {
		return providerconn.Connection{}, providerconn.ActiveModel{}, errors.New("Provider-Verbindung unterstützt keinen Text-Chat")
	}
	if preset, known := providerconn.FindPreset(connection.PresetID); known && preset.APIKeyRequired && strings.TrimSpace(connection.APIKey) == "" {
		return providerconn.Connection{}, providerconn.ActiveModel{}, errors.New("API-Key fehlt für diese Provider-Verbindung")
	}
	modelVerified := false
	for _, model := range connection.Models {
		if model.ID != modelID {
			continue
		}
		if !model.ChatSupported {
			return providerconn.Connection{}, providerconn.ActiveModel{}, errors.New("dieses Modell unterstützt keinen Text-Chat über die konfigurierte API")
		}
		modelVerified = true
		break
	}
	if !modelVerified {
		return providerconn.Connection{}, providerconn.ActiveModel{}, providerconn.ErrActiveModelMissing
	}

	modelRef := providerconn.ModelRef(connectionID, modelID)
	active, found, err := m.providerConnections.TouchActiveModel(userID, modelRef)
	if err != nil {
		return providerconn.Connection{}, providerconn.ActiveModel{}, err
	}
	if !found || active.ConnectionID != connectionID || active.ModelID != modelID {
		return providerconn.Connection{}, providerconn.ActiveModel{}, providerconn.ErrActiveModelMissing
	}
	return connection, active, nil
}

func (m *ScoutModule) streamConfiguredOpenAI(
	ctx context.Context,
	connection providerconn.Connection,
	turn providerTurn,
	reasoning thinking.ReasoningConfig,
) (string, string, error) {
	endpoint, err := providerconn.ChatCompletionsURL(connection.BaseURL)
	if err != nil {
		return "", "", err
	}
	payload := map[string]interface{}{
		"model":       turn.ModelID,
		"messages":    configuredOpenAIMessages(turn.Messages, turn.SystemPrompt),
		"stream":      true,
		"temperature": reasoning.Temperature,
		"top_p":       reasoning.TopP,
	}
	if turn.MaxOutputTokens > 0 {
		payload["max_tokens"] = turn.MaxOutputTokens
	}
	// OpenRouter is the one OpenAI-compatible preset whose documented chat
	// protocol supports this field. Sending it to every compatible endpoint
	// would make otherwise valid providers reject the request.
	if connection.PresetID == "openrouter" && reasoning.Effort != "" {
		payload["reasoning"] = map[string]interface{}{"effort": reasoning.Effort}
	}

	// Its own cancel, so the stall watch below can drop a silent stream without
	// touching the caller's context.
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	body, err := m.startConfiguredProviderStream(ctx, connection, endpoint, payload, configuredBearerHeaders(connection.APIKey))
	if err != nil {
		return "", "", err
	}
	defer body.Close()
	watched, stopWatch := watchProviderStall(body, connection.PresetID, cancel, providerStreamIdleTimeout)
	defer stopWatch()
	return readOpenAIStream(watched, turn.Emit, turn.EmitReasoning)
}

func (m *ScoutModule) streamConfiguredAnthropic(
	ctx context.Context,
	connection providerconn.Connection,
	turn providerTurn,
	reasoning thinking.ReasoningConfig,
) (string, string, error) {
	endpoint, err := providerconn.AnthropicMessagesURL(connection.BaseURL)
	if err != nil {
		return "", "", err
	}
	// The Anthropic API requires max_tokens - unlike the OpenAI shape there is
	// no "leave it to the provider". This used to be a flat 4096 for every
	// model, which is a fraction of what the current ones can write.
	maxTokens := turn.MaxOutputTokens
	if maxTokens <= 0 {
		maxTokens = fallbackMaxOutputTokens
	}
	payload := map[string]interface{}{
		"model":       turn.ModelID,
		"max_tokens":  maxTokens,
		"system":      turn.SystemPrompt,
		"messages":    configuredAnthropicMessages(turn.Messages),
		"stream":      true,
		"temperature": reasoning.Temperature,
	}
	headers := make(http.Header)
	headers.Set("x-api-key", strings.TrimSpace(connection.APIKey))
	headers.Set("anthropic-version", "2023-06-01")
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	body, err := m.startConfiguredProviderStream(ctx, connection, endpoint, payload, headers)
	if err != nil {
		return "", "", err
	}
	defer body.Close()
	watched, stopWatch := watchProviderStall(body, connection.PresetID, cancel, providerStreamIdleTimeout)
	defer stopWatch()
	return readAnthropicStream(watched, turn.Emit, turn.EmitReasoning)
}

func (m *ScoutModule) streamConfiguredGemini(
	ctx context.Context,
	connection providerconn.Connection,
	turn providerTurn,
	reasoning thinking.ReasoningConfig,
) (string, string, error) {
	endpoint, err := configuredGeminiSSEURL(connection.BaseURL, turn.ModelID)
	if err != nil {
		return "", "", err
	}
	generation := map[string]interface{}{
		"temperature": reasoning.Temperature,
		"topP":        reasoning.TopP,
	}
	if turn.MaxOutputTokens > 0 {
		generation["maxOutputTokens"] = turn.MaxOutputTokens
	}
	payload := map[string]interface{}{
		"systemInstruction": map[string]interface{}{
			"parts": []map[string]string{{"text": turn.SystemPrompt}},
		},
		"contents":         configuredGeminiMessages(turn.Messages),
		"generationConfig": generation,
	}
	headers := make(http.Header)
	headers.Set("x-goog-api-key", strings.TrimSpace(connection.APIKey))
	body, err := m.startConfiguredProviderStream(ctx, connection, endpoint, payload, headers)
	if err != nil {
		return "", "", err
	}
	defer body.Close()
	return readGeminiStream(body, turn.Emit, turn.EmitReasoning)
}

func configuredOpenAIMessages(messages []chatMessage, systemPrompt string) []chatMessage {
	providerMessages := make([]chatMessage, 0, len(messages)+1)
	if strings.TrimSpace(systemPrompt) != "" {
		providerMessages = append(providerMessages, chatMessage{Role: "system", Content: systemPrompt})
	}
	for _, message := range messages {
		role := strings.ToLower(strings.TrimSpace(message.Role))
		if role != "user" && role != "assistant" && role != "system" {
			continue
		}
		providerMessages = append(providerMessages, chatMessage{Role: role, Content: message.Content})
	}
	return providerMessages
}

func configuredAnthropicMessages(messages []chatMessage) []map[string]string {
	providerMessages := make([]map[string]string, 0, len(messages))
	for _, message := range messages {
		role := strings.ToLower(strings.TrimSpace(message.Role))
		if role != "user" && role != "assistant" {
			continue
		}
		providerMessages = append(providerMessages, map[string]string{"role": role, "content": message.Content})
	}
	return providerMessages
}

func configuredGeminiMessages(messages []chatMessage) []map[string]interface{} {
	contents := make([]map[string]interface{}, 0, len(messages))
	for _, message := range messages {
		role := strings.ToLower(strings.TrimSpace(message.Role))
		if role != "user" && role != "assistant" {
			continue
		}
		geminiRole := "user"
		if role == "assistant" {
			geminiRole = "model"
		}
		contents = append(contents, map[string]interface{}{
			"role":  geminiRole,
			"parts": []map[string]string{{"text": message.Content}},
		})
	}
	return contents
}

func configuredBearerHeaders(apiKey string) http.Header {
	headers := make(http.Header)
	if key := strings.TrimSpace(apiKey); key != "" {
		headers.Set("Authorization", "Bearer "+key)
	}
	return headers
}

func (m *ScoutModule) startConfiguredProviderStream(
	ctx context.Context,
	connection providerconn.Connection,
	endpoint string,
	payload interface{},
	headers http.Header,
) (io.ReadCloser, error) {
	if err := validateConfiguredProviderEndpoint(endpoint); err != nil {
		return nil, err
	}
	if err := providerconn.ValidateConnectionOutboundURL(ctx, connection, endpoint); err != nil {
		return nil, fmt.Errorf("Provider-Endpunkt kann nicht sicher erreicht werden: %w", err)
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, errors.New("Provider-Anfrage konnte nicht erstellt werden")
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return nil, errors.New("Provider-Anfrage konnte nicht erstellt werden")
	}
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Accept", "text/event-stream, application/json")
	request.Header.Set("User-Agent", "culpeostudio-scout/1.0")
	for name, values := range headers {
		for _, value := range values {
			request.Header.Add(name, value)
		}
	}

	// This uses the same guarded transport as catalogue discovery, but no
	// whole-response timeout: a legitimate answer stream can last longer than
	// the short metadata-fetch budget. The caller's chat context still owns
	// cancellation and the transport still blocks redirects, proxies, DNS
	// rebinding, and private-network targets.
	response, err := providerconn.NewStreamingHTTPClientForConnection(connection).Do(request)
	if err != nil {
		return nil, fmt.Errorf("%s ist nicht erreichbar", configuredProviderDisplayName(connection))
	}
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		defer response.Body.Close()
		// Never return a raw provider error body. Some gateways echo request
		// material in their diagnostic response, which must not expose an API
		// key or prompt through the Scout stream.
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 4096))
		return nil, &providerChatHTTPError{
			Provider:   configuredProviderDisplayName(connection),
			StatusCode: response.StatusCode,
			Detail:     configuredProviderHTTPDetail(response.StatusCode),
		}
	}
	return response.Body, nil
}

func configuredProviderDisplayName(connection providerconn.Connection) string {
	if name := strings.TrimSpace(connection.Name); name != "" {
		return name
	}
	if name := strings.TrimSpace(connection.PresetID); name != "" {
		return name
	}
	return "Konfigurierter Anbieter"
}

func configuredProviderHTTPDetail(statusCode int) string {
	switch statusCode {
	case http.StatusUnauthorized, http.StatusForbidden:
		return "API-Key wurde abgelehnt. Bitte die Provider-Verbindung in den Einstellungen prüfen."
	case http.StatusNotFound:
		return "Modell oder Chat-Endpunkt wurde nicht gefunden. Bitte den Provider-Katalog synchronisieren."
	case http.StatusTooManyRequests:
		return "Rate-Limit des Anbieters erreicht. Bitte später erneut versuchen."
	default:
		return fmt.Sprintf("Provider antwortet mit HTTP %d", statusCode)
	}
}

func validateConfiguredProviderEndpoint(raw string) error {
	endpoint, err := url.Parse(strings.TrimSpace(raw))
	if err != nil || endpoint.Scheme == "" || endpoint.Host == "" {
		return errors.New("Provider-Endpunkt ist ungültig")
	}
	if endpoint.Scheme != "https" && endpoint.Scheme != "http" {
		return errors.New("Provider-Endpunkt verwendet kein HTTP(S)")
	}
	if endpoint.User != nil || endpoint.Fragment != "" {
		return errors.New("Provider-Endpunkt enthält unzulässige Zugangsdaten oder Fragmente")
	}
	return nil
}

func configuredGeminiSSEURL(baseURL, modelID string) (string, error) {
	endpoint, err := providerconn.GeminiStreamURL(baseURL, modelID)
	if err != nil {
		return "", err
	}
	parsed, err := url.Parse(endpoint)
	if err != nil {
		return "", errors.New("Gemini-Streaming-Endpunkt ist ungültig")
	}
	query := parsed.Query()
	query.Set("alt", "sse")
	parsed.RawQuery = query.Encode()
	return parsed.String(), nil
}

func readAnthropicStream(r io.Reader, emit func(string) error, emitReasoning func(string) error) (string, string, error) {
	return readConfiguredSSEStream(r, emit, emitReasoning, func(raw []byte) (configuredSSEEvent, error) {
		var event struct {
			Type  string `json:"type"`
			Delta struct {
				Text string `json:"text"`
				// message_delta carries the stop reason on the same field name
				// the text deltas use for their payload, which is why both are
				// decoded from one struct.
				Thinking   string `json:"thinking"`
				StopReason string `json:"stop_reason"`
			} `json:"delta"`
			ContentBlock struct {
				Text string `json:"text"`
			} `json:"content_block"`
		}
		if err := json.Unmarshal(raw, &event); err != nil {
			return configuredSSEEvent{}, nil
		}
		if event.Type == "message_stop" {
			return configuredSSEEvent{Done: true}, nil
		}
		return configuredSSEEvent{
			Content:      event.Delta.Text + event.ContentBlock.Text,
			Reasoning:    event.Delta.Thinking,
			FinishReason: event.Delta.StopReason,
		}, nil
	})
}

func readGeminiStream(r io.Reader, emit func(string) error, emitReasoning func(string) error) (string, string, error) {
	return readConfiguredSSEStream(r, emit, emitReasoning, func(raw []byte) (configuredSSEEvent, error) {
		var event struct {
			Candidates []struct {
				Content struct {
					Parts []struct {
						Text    string `json:"text"`
						Thought bool   `json:"thought"`
					} `json:"parts"`
				} `json:"content"`
				FinishReason string `json:"finishReason"`
			} `json:"candidates"`
		}
		if err := json.Unmarshal(raw, &event); err != nil {
			return configuredSSEEvent{}, nil
		}
		var content, reasoning strings.Builder
		decoded := configuredSSEEvent{}
		for _, candidate := range event.Candidates {
			for _, part := range candidate.Content.Parts {
				if part.Thought {
					reasoning.WriteString(part.Text)
				} else {
					content.WriteString(part.Text)
				}
			}
			if candidate.FinishReason != "" {
				decoded.FinishReason = candidate.FinishReason
			}
		}
		decoded.Content = content.String()
		decoded.Reasoning = reasoning.String()
		return decoded, nil
	})
}

// configuredSSEEvent is what one decoded SSE payload contributed.
type configuredSSEEvent struct {
	Done         bool
	Content      string
	Reasoning    string
	FinishReason string
}

type configuredSSEHandler func(raw []byte) (configuredSSEEvent, error)

func readConfiguredSSEStream(r io.Reader, emit func(string) error, emitReasoning func(string) error, handler configuredSSEHandler) (string, string, error) {
	scanner, counter := newBoundedProviderStreamScanner(r)
	var reply strings.Builder
	var eventData bytes.Buffer
	finishReason := ""
	flush := func() (bool, error) {
		raw := bytes.TrimSpace(eventData.Bytes())
		eventData.Reset()
		if len(raw) == 0 {
			return false, nil
		}
		if bytes.Equal(raw, []byte("[DONE]")) {
			return true, nil
		}
		decoded, err := handler(raw)
		if err != nil {
			return false, err
		}
		if decoded.FinishReason != "" {
			finishReason = decoded.FinishReason
		}
		if decoded.Reasoning != "" && emitReasoning != nil {
			if err := emitReasoning(decoded.Reasoning); err != nil {
				return false, err
			}
		}
		if decoded.Content != "" {
			reply.WriteString(decoded.Content)
			if emit != nil {
				if err := emit(decoded.Content); err != nil {
					return false, err
				}
			}
		}
		return decoded.Done, nil
	}

	for scanner.Scan() {
		trimmed := bytes.TrimSpace(scanner.Bytes())
		switch {
		case len(trimmed) == 0:
			done, flushErr := flush()
			if flushErr != nil {
				return "", "", flushErr
			}
			if done {
				return configuredStreamReply(reply.String(), finishReason)
			}
		case bytes.HasPrefix(trimmed, []byte("data:")):
			data := bytes.TrimSpace(bytes.TrimPrefix(trimmed, []byte("data:")))
			if len(data) > 0 {
				// An SSE event may legally use several physical data lines. Bound
				// the assembled JSON payload as well, so many small lines cannot
				// bypass the scanner's individual-line ceiling.
				if eventData.Len()+len(data)+1 > maxConfiguredStreamLineBytes {
					return "", "", errors.New("Provider-Stream-Zeile ist zu groß")
				}
				if eventData.Len() > 0 {
					eventData.WriteByte('\n')
				}
				eventData.Write(data)
			}
		}
	}
	if err := boundedProviderStreamError(scanner.Err(), counter); err != nil {
		return "", "", err
	}
	if _, flushErr := flush(); flushErr != nil {
		return "", "", flushErr
	}
	return configuredStreamReply(reply.String(), finishReason)
}

func configuredStreamReply(reply, finishReason string) (string, string, error) {
	if strings.TrimSpace(reply) == "" {
		return "", "", errors.New("Provider hat keine Chat-Antwort geliefert. Bitte ein anderes API-Modell wählen oder Provider-Key/Modell prüfen")
	}
	return reply, normalizeFinishReason(finishReason), nil
}
