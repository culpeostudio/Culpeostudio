package engine

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/internal/noderouting"
)

var _ localinference.Provider = (*EngineModule)(nil)

func (m *EngineModule) ReadyLocalModels() []localinference.Model {
	instances := m.listInstances()
	models := make([]localinference.Model, 0, len(instances))
	for _, instance := range instances {
		if instance.State != engineruntime.StateReady || strings.TrimSpace(instance.BaseURL) == "" || strings.TrimSpace(instance.WorkerSecret) == "" {
			continue
		}
		models = append(models, localModelView(instance))
	}
	// A model loaded on a node is as usable from the chat as one loaded here,
	// so it belongs in the same picker.
	return append(models, m.nodeReadyModels()...)
}

func (m *EngineModule) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	instanceID = strings.TrimSpace(instanceID)
	if nodeID, localID, remote := noderouting.Split(instanceID); remote {
		_, model, err := m.resolveNodeModel(context.Background(), nodeID, localID)
		return model, err
	}
	instance, ok := m.getInstance(instanceID)
	if !ok {
		return localinference.Model{}, localinference.ErrNotFound
	}
	if instance.State != engineruntime.StateReady || strings.TrimSpace(instance.BaseURL) == "" || strings.TrimSpace(instance.WorkerSecret) == "" {
		return localinference.Model{}, localinference.ErrNotReady
	}
	return localModelView(instance), nil
}

func localModelView(instance *EngineInstance) localinference.Model {
	contextLimit := 0
	modelContextLimit := 0
	if instance.Plan != nil {
		contextLimit = instance.Plan.EffectiveContextTokens
		modelContextLimit = instance.Plan.ModelContextLimitTokens
	}
	displayName := strings.TrimSpace(instance.ServedModelName)
	if displayName == "" {
		displayName = strings.TrimSpace(instance.EndpointName)
	}
	if displayName == "" {
		displayName = instance.ID
	}
	return localinference.Model{
		InstanceID: instance.ID, ModelID: instance.ModelID,
		DisplayName: displayName, ContextLimit: contextLimit,
		ModelContextLimit: modelContextLimit,
	}
}

func (m *EngineModule) StreamLocalChat(ctx context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	reply, _, err := m.StreamLocalChatWithReason(ctx, instanceID, request, emit)
	return reply, err
}

// StreamLocalChatWithReason is StreamLocalChat plus the model's finish reason,
// which is how the chat tells a reply that ended from one that hit its output
// limit and is worth continuing.
func (m *EngineModule) StreamLocalChatWithReason(ctx context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, string, error) {
	// An instance on a node is answered by that node's gateway. Everything
	// below this line - the worker URL, the admission gate, the local
	// statistics - describes a process on this machine.
	if nodeID, localID, remote := noderouting.Split(strings.TrimSpace(instanceID)); remote {
		return m.streamNodeChat(ctx, nodeID, localID, request, emit)
	}
	instance, model, err := m.localChatTarget(instanceID)
	if err != nil {
		return "", "", err
	}
	if len(request.Messages) == 0 {
		return "", "", fmt.Errorf("%w: mindestens eine Chat-Nachricht ist erforderlich", localinference.ErrInvalidRequest)
	}
	messages := make([]interface{}, 0, len(request.Messages))
	for _, message := range request.Messages {
		role := strings.ToLower(strings.TrimSpace(message.Role))
		if role != "system" && role != "user" && role != "assistant" {
			return "", "", fmt.Errorf("%w: ungueltige Chat-Rolle %q", localinference.ErrInvalidRequest, message.Role)
		}
		messages = append(messages, map[string]interface{}{
			"role": role, "content": message.Content,
		})
	}
	payload := map[string]interface{}{
		"model": instance.ID, "messages": messages, "stream": true,
	}
	for key, value := range instance.EffectiveConfig.GenerationDefaults {
		if _, exists := payload[key]; !exists {
			payload[key] = value
		}
	}
	if request.Temperature != nil {
		payload["temperature"] = *request.Temperature
	}
	if request.MaxTokens != nil {
		if *request.MaxTokens < 0 {
			return "", "", fmt.Errorf("%w: max_tokens darf nicht negativ sein", localinference.ErrInvalidRequest)
		}
		payload["max_tokens"] = *request.MaxTokens
	}
	if exceedsApproximateContext(payload, model.ContextLimit) {
		return "", "", fmt.Errorf("%w: maximal %d Tokens", localinference.ErrContextLimit, model.ContextLimit)
	}
	release, err := m.acquireInference(ctx, instance.ID)
	if err != nil {
		return "", "", err
	}
	defer release()
	data, err := json.Marshal(payload)
	if err != nil {
		return "", "", err
	}
	upstreamURL, err := localWorkerURL(instance.BaseURL, "/v1/chat/completions")
	if err != nil {
		return "", "", err
	}
	httpRequest, err := http.NewRequestWithContext(ctx, http.MethodPost, upstreamURL, bytes.NewReader(data))
	if err != nil {
		return "", "", err
	}
	httpRequest.Header.Set("Content-Type", "application/json")
	httpRequest.Header.Set("Accept", "text/event-stream")
	httpRequest.Header.Set("Authorization", "Bearer "+instance.WorkerSecret)
	client := m.localClient
	if client == nil {
		client = newLoopbackHTTPClient()
		defer client.CloseIdleConnections()
	}
	requestStart := time.Now()
	response, err := client.Do(httpRequest)
	if err != nil {
		if errors.Is(ctx.Err(), context.Canceled) {
			return "", "", ctx.Err()
		}
		return "", "", localinference.ErrWorkerUnavailable
	}
	defer response.Body.Close()
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		return "", "", localWorkerError(response)
	}

	var firstToken time.Time
	tokens := 0
	measuredEmit := func(chunk string) error {
		if tokens == 0 {
			firstToken = time.Now()
		}
		tokens++
		return emit(chunk)
	}
	result, finishReason, streamErr := localinference.ReadOpenAIStreamWithReason(response.Body, measuredEmit)
	if streamErr == nil {
		m.recordInferenceSample(instance.ID, requestStart, firstToken, tokens)
	}
	return result, finishReason, streamErr
}

func (m *EngineModule) EnsureLocalModelReady(ctx context.Context, instanceID string, emit func(localinference.WarmupProgress) error) (localinference.Model, error) {
	if nodeID, localID, remote := noderouting.Split(strings.TrimSpace(instanceID)); remote {
		return m.ensureNodeModelReady(ctx, nodeID, localID, emit)
	}
	instance, operation, err := m.ensureReady(strings.TrimSpace(instanceID))
	if err != nil {
		return localinference.Model{}, normalizeWarmupError(err)
	}
	emitProgress := func(instance *EngineInstance, operation *EngineOperation) error {
		if emit == nil || instance == nil {
			return nil
		}
		progress := localinference.WarmupProgress{
			InstanceID: instance.ID, Status: string(instance.State), Phase: instance.Phase,
			Progress: instance.Progress, Placement: string(placementForPlan(instance.Plan)), Message: instance.DetailMessage,
		}
		if operation != nil {
			progress.OperationID = operation.ID
			progress.Status = operation.State
			progress.QueuePosition = operation.QueuePosition
			if operation.Phase != "" {
				progress.Phase = operation.Phase
			}
			if operation.Progress > progress.Progress {
				progress.Progress = operation.Progress
			}
			if operation.DetailMessage != "" {
				progress.Message = operation.DetailMessage
			}
		}
		return emit(progress)
	}
	if err := emitProgress(instance, operation); err != nil {
		return localinference.Model{}, err
	}
	if operation == nil {
		return localModelView(instance), nil
	}

	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()
	lastState, lastPhase, lastPosition := "", "", -1
	lastProgress := -1.0
	for {
		select {
		case <-ctx.Done():
			return localinference.Model{}, fmt.Errorf("%w: %v", localinference.ErrWarmupCanceled, ctx.Err())
		case <-ticker.C:
			currentInstance, exists := m.getInstance(instance.ID)
			if !exists {
				return localinference.Model{}, localinference.ErrNotFound
			}
			currentOperation, exists := m.operation(operation.ID)
			if !exists {
				return localinference.Model{}, localinference.ErrNotFound
			}
			if currentOperation.State != lastState || currentOperation.Phase != lastPhase || currentOperation.QueuePosition != lastPosition || currentOperation.Progress != lastProgress {
				if err := emitProgress(currentInstance, currentOperation); err != nil {
					return localinference.Model{}, err
				}
				lastState, lastPhase, lastPosition, lastProgress = currentOperation.State, currentOperation.Phase, currentOperation.QueuePosition, currentOperation.Progress
			}
			switch currentOperation.State {
			case "completed":
				return m.ResolveLocalModel(instance.ID)
			case "cancelled":
				return localinference.Model{}, localinference.ErrWarmupCanceled
			case "failed":
				return localinference.Model{}, normalizeWarmupOperationError(currentOperation)
			}
		}
	}
}

func normalizeWarmupOperationError(operation *EngineOperation) error {
	if operation == nil {
		return localinference.ErrWorkerUnavailable
	}
	message := strings.TrimSpace(operation.ErrorSummary)
	if message == "" {
		message = strings.TrimSpace(operation.Error)
	}
	if message == "" {
		message = "Modell-Warmup ist fehlgeschlagen"
	}
	switch operation.ErrorCode {
	case "resource_guard_rejected":
		return fmt.Errorf("%w: %s", localinference.ErrGuardRejected, message)
	case "queue_timeout":
		return fmt.Errorf("%w: %s", localinference.ErrQueueTimeout, message)
	case "operation_cancelled":
		return fmt.Errorf("%w: %s", localinference.ErrWarmupCanceled, message)
	default:
		return fmt.Errorf("%w: %s", localinference.ErrWorkerUnavailable, message)
	}
}

func normalizeWarmupError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, localinference.ErrGuardRejected) || errors.Is(err, localinference.ErrQueueTimeout) || errors.Is(err, localinference.ErrWarmupCanceled) || errors.Is(err, localinference.ErrNotFound) {
		return err
	}
	return err
}

func (m *EngineModule) localChatTarget(instanceID string) (*EngineInstance, localinference.Model, error) {
	instance, ok := m.getInstance(strings.TrimSpace(instanceID))
	if !ok {
		return nil, localinference.Model{}, localinference.ErrNotFound
	}
	if instance.State != engineruntime.StateReady || strings.TrimSpace(instance.BaseURL) == "" || strings.TrimSpace(instance.WorkerSecret) == "" {
		return nil, localinference.Model{}, localinference.ErrNotReady
	}
	return instance, localModelView(instance), nil
}

func localWorkerURL(baseURL, path string) (string, error) {
	parsed, err := url.Parse(strings.TrimSpace(baseURL))
	if err != nil || parsed.Scheme != "http" || parsed.Host == "" || parsed.Port() == "" || parsed.User != nil {
		return "", fmt.Errorf("ungueltige lokale Worker-Adresse")
	}
	host := parsed.Hostname()
	ip := net.ParseIP(host)
	if !strings.EqualFold(host, "localhost") && (ip == nil || !ip.IsLoopback()) {
		return "", fmt.Errorf("Worker-Adresse liegt nicht auf Loopback")
	}
	parsed.Path = path
	parsed.RawPath = ""
	parsed.RawQuery = ""
	parsed.Fragment = ""
	return parsed.String(), nil
}

func localWorkerError(response *http.Response) error {
	body, _ := io.ReadAll(io.LimitReader(response.Body, 4096))
	var payload struct {
		Error struct {
			Message string `json:"message"`
		} `json:"error"`
	}
	decodeErr := json.Unmarshal(body, &payload)
	message := strings.TrimSpace(payload.Error.Message)
	if decodeErr != nil || message == "" {
		message = fmt.Sprintf("lokales Modell hat die Anfrage abgelehnt (%d)", response.StatusCode)
	}

	if diagnosis, ok := engineruntime.DiagnoseWorkerOutput(string(body)); ok {
		message = diagnosis.Message
	}
	sentinel := error(nil)
	switch response.StatusCode {
	case http.StatusBadRequest:
		sentinel = localinference.ErrInvalidRequest
	case http.StatusNotFound:
		sentinel = localinference.ErrNotFound
	case http.StatusConflict:
		sentinel = localinference.ErrNotReady
	case http.StatusUnprocessableEntity:
		sentinel = localinference.ErrContextLimit
	case http.StatusServiceUnavailable:
		sentinel = localinference.ErrWorkerUnavailable
	}
	if sentinel != nil {
		return fmt.Errorf("%w: %s", sentinel, message)
	}
	return fmt.Errorf("lokales Modell: %s", message)
}
