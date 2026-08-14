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
	"strings"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/modules/node"
)

// nodeProbeTimeout bounds the listing behind the chat model picker. It is
// shorter even than a list call, because a node that has gone quiet must not
// hold up a menu that is opening.
const nodeProbeTimeout = 3 * time.Second

// nodeChatClient carries the streamed answers back from a node.
//
// It has no overall timeout: a generation legitimately runs for minutes, and a
// deadline on the whole request would cut a long answer off mid-sentence. The
// dial and the response headers are bounded instead, which is what actually
// tells an unreachable node apart from a slow one.
func newNodeChatClient() *http.Client {
	return &http.Client{Transport: &http.Transport{
		Proxy: nil,
		DialContext: (&net.Dialer{
			Timeout:   10 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		ResponseHeaderTimeout: 120 * time.Second,
		DisableCompression:    true,
		MaxIdleConnsPerHost:   4,
	}}
}

// nodeReadyModels lists what the nodes have loaded, for the chat picker.
func (m *EngineModule) nodeReadyModels() []localinference.Model {
	ctx, cancel := context.WithTimeout(context.Background(), nodeProbeTimeout)
	defer cancel()
	return fanOutToNodes(ctx, m, "geladene Modelle", func(ctx context.Context, target node.Target, client enginev1.EngineServiceClient) ([]localinference.Model, error) {
		response, err := client.ListInstances(ctx, &enginev1.ListInstancesRequest{})
		if err != nil {
			return nil, err
		}
		var models []localinference.Model
		for _, instance := range response.GetInstances() {
			if instance.GetState() != enginev1.InstanceState_INSTANCE_STATE_READY {
				continue
			}
			models = append(models, nodeModelView(target, instance))
		}
		return models, nil
	})
}

// nodeModelView describes a node's instance in the terms the chat uses. The
// node's name goes into the label, because in a picker that mixes machines
// "Qwen3 8B" twice over is not a choice.
func nodeModelView(target node.Target, instance *enginev1.EngineInstance) localinference.Model {
	displayName := strings.TrimSpace(instance.GetServedModelName())
	if displayName == "" {
		displayName = strings.TrimSpace(instance.GetEndpointName())
	}
	if displayName == "" {
		displayName = instance.GetId()
	}
	if name := strings.TrimSpace(target.Name); name != "" {
		displayName = displayName + " (" + name + ")"
	}
	return localinference.Model{
		InstanceID:   node.Qualify(target.ID, instance.GetId()),
		ModelID:      node.Qualify(target.ID, instance.GetModelId()),
		DisplayName:  displayName,
		ContextLimit: int(instance.GetPlan().GetEffectiveContextTokens()),
	}
}

// resolveNodeModel reads one node instance back and reports whether it can
// take a request right now.
func (m *EngineModule) resolveNodeModel(ctx context.Context, nodeID, instanceID string) (node.Target, localinference.Model, error) {
	target, client, err := m.nodeEngine(nodeID)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return node.Target{}, localinference.Model{}, localinference.ErrNotFound
		}
		return node.Target{}, localinference.Model{}, fmt.Errorf("%w: %v", localinference.ErrWorkerUnavailable, err)
	}
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.GetInstance(callCtx, &enginev1.GetInstanceRequest{InstanceId: instanceID})
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return node.Target{}, localinference.Model{}, localinference.ErrNotFound
		}
		return node.Target{}, localinference.Model{}, fmt.Errorf("%w: %v", localinference.ErrWorkerUnavailable, err)
	}
	instance := response.GetInstance()
	if instance == nil {
		return node.Target{}, localinference.Model{}, localinference.ErrNotFound
	}
	if instance.GetState() != enginev1.InstanceState_INSTANCE_STATE_READY {
		return node.Target{}, localinference.Model{}, localinference.ErrNotReady
	}
	if strings.TrimSpace(target.GatewayURL()) == "" || strings.TrimSpace(target.GatewayKey) == "" {
		// The node runs the model but has handed out no gateway key, so there
		// is nothing to stream through yet. Saying that plainly is better than
		// a connection error the user cannot act on.
		return node.Target{}, localinference.Model{}, fmt.Errorf(
			"%w: der Node %s hat noch keinen Gateway-Zugang ausgestellt; bitte den Node in den Einstellungen aktualisieren",
			localinference.ErrNotReady, target.Name)
	}
	return target, nodeModelView(target, instance), nil
}

// streamNodeChat runs one chat turn on a node.
//
// The request goes to the node's OpenAI gateway rather than through gRPC. That
// gateway is already the thing that proxies to a worker, applies the sampler
// defaults and streams the answer back chunk by chunk - putting the same job
// on a second protocol would only mean a second implementation of it. What
// crosses the tunnel is the prompt and the tokens, which is as little as this
// can be.
func (m *EngineModule) streamNodeChat(
	ctx context.Context,
	nodeID, instanceID string,
	request localinference.ChatRequest,
	emit func(string) error,
) (string, error) {
	target, model, err := m.resolveNodeModel(ctx, nodeID, instanceID)
	if err != nil {
		return "", err
	}
	if len(request.Messages) == 0 {
		return "", fmt.Errorf("%w: mindestens eine Chat-Nachricht ist erforderlich", localinference.ErrInvalidRequest)
	}
	messages := make([]interface{}, 0, len(request.Messages))
	for _, message := range request.Messages {
		role := strings.ToLower(strings.TrimSpace(message.Role))
		if role != "system" && role != "user" && role != "assistant" {
			return "", fmt.Errorf("%w: ungueltige Chat-Rolle %q", localinference.ErrInvalidRequest, message.Role)
		}
		messages = append(messages, map[string]interface{}{"role": role, "content": message.Content})
	}
	// The node knows the instance by its own id, whatever it is called here.
	payload := map[string]interface{}{
		"model": instanceID, "messages": messages, "stream": true,
	}
	if request.Temperature != nil {
		payload["temperature"] = *request.Temperature
	}
	if request.MaxTokens != nil {
		if *request.MaxTokens < 0 {
			return "", fmt.Errorf("%w: max_tokens darf nicht negativ sein", localinference.ErrInvalidRequest)
		}
		payload["max_tokens"] = *request.MaxTokens
	}
	if exceedsApproximateContext(payload, model.ContextLimit) {
		return "", fmt.Errorf("%w: maximal %d Tokens", localinference.ErrContextLimit, model.ContextLimit)
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	httpRequest, err := http.NewRequestWithContext(
		ctx, http.MethodPost, target.GatewayURL()+"/v1/chat/completions", bytes.NewReader(body),
	)
	if err != nil {
		return "", err
	}
	httpRequest.Header.Set("Content-Type", "application/json")
	httpRequest.Header.Set("Accept", "text/event-stream")
	httpRequest.Header.Set("Authorization", "Bearer "+target.GatewayKey)

	client := m.nodeChatClient
	if client == nil {
		client = newNodeChatClient()
		defer client.CloseIdleConnections()
	}
	response, err := client.Do(httpRequest)
	if err != nil {
		if errors.Is(ctx.Err(), context.Canceled) {
			return "", ctx.Err()
		}
		return "", fmt.Errorf("%w: Node %s antwortet nicht", localinference.ErrWorkerUnavailable, target.Name)
	}
	defer response.Body.Close()
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		return "", nodeGatewayError(target, response)
	}
	return localinference.ReadOpenAIStream(response.Body, emit)
}

// nodeGatewayError turns what the node's gateway refused with into the same
// sentinels a local worker's refusal produces, so the chat handles both alike.
func nodeGatewayError(target node.Target, response *http.Response) error {
	body, _ := io.ReadAll(io.LimitReader(response.Body, 4096))
	var payload struct {
		Error struct {
			Message string `json:"message"`
		} `json:"error"`
	}
	message := ""
	if json.Unmarshal(body, &payload) == nil {
		message = strings.TrimSpace(payload.Error.Message)
	}
	if message == "" {
		message = fmt.Sprintf("Node %s hat die Anfrage abgelehnt (%d)", target.Name, response.StatusCode)
	} else {
		message = "Node " + target.Name + ": " + message
	}

	switch response.StatusCode {
	case http.StatusBadRequest:
		return fmt.Errorf("%w: %s", localinference.ErrInvalidRequest, message)
	case http.StatusUnauthorized, http.StatusForbidden:
		// The key the node issued is no longer accepted, which a refresh of the
		// node fixes by asking for a new one.
		return fmt.Errorf("%w: %s", localinference.ErrWorkerUnavailable, message)
	case http.StatusNotFound:
		return fmt.Errorf("%w: %s", localinference.ErrNotFound, message)
	case http.StatusUnprocessableEntity:
		return fmt.Errorf("%w: %s", localinference.ErrContextLimit, message)
	case http.StatusTooManyRequests:
		return fmt.Errorf("%w: %s", localinference.ErrInferenceBusy, message)
	case http.StatusServiceUnavailable:
		return fmt.Errorf("%w: %s", localinference.ErrNotReady, message)
	default:
		return errors.New(message)
	}
}

// ensureNodeModelReady loads a model on a node and reports how far it has got,
// in the same shape the local warm-up reports.
//
// The node schedules the start and answers at once; what follows is the same
// polling the local path does against its own operation store, only over the
// tunnel. Polling rather than a stream keeps the node's surface to the calls it
// already has.
func (m *EngineModule) ensureNodeModelReady(
	ctx context.Context,
	nodeID, instanceID string,
	emit func(localinference.WarmupProgress) error,
) (localinference.Model, error) {
	target, client, err := m.nodeEngine(nodeID)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return localinference.Model{}, localinference.ErrNotFound
		}
		return localinference.Model{}, fmt.Errorf("%w: %v", localinference.ErrWorkerUnavailable, err)
	}

	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	started, err := client.EnsureInstanceReady(callCtx, &enginev1.EnsureInstanceReadyRequest{InstanceId: instanceID})
	cancel()
	if err != nil {
		return localinference.Model{}, translateNodeWarmupError(target, err)
	}

	qualifiedInstance := node.Qualify(nodeID, instanceID)
	report := func(state string, phase string, progress float64, message string, queuePosition int32, operationID string) error {
		if emit == nil {
			return nil
		}
		return emit(localinference.WarmupProgress{
			OperationID:   node.Qualify(nodeID, operationID),
			InstanceID:    qualifiedInstance,
			Status:        state,
			Phase:         phase,
			Progress:      progress,
			QueuePosition: int(queuePosition),
			Message:       message,
		})
	}
	if err := report(
		instanceStateLabel(started.GetInstance()), started.GetInstance().GetPhase(),
		started.GetInstance().GetProgress(), started.GetInstance().GetDetailMessage(),
		started.GetQueuePosition(), started.GetOperationId(),
	); err != nil {
		return localinference.Model{}, err
	}
	if started.GetAlreadyReady() || strings.TrimSpace(started.GetOperationId()) == "" {
		_, model, resolveErr := m.resolveNodeModel(ctx, nodeID, instanceID)
		return model, resolveErr
	}

	ticker := time.NewTicker(400 * time.Millisecond)
	defer ticker.Stop()
	lastState, lastPhase := "", ""
	lastProgress := -1.0
	for {
		select {
		case <-ctx.Done():
			return localinference.Model{}, fmt.Errorf("%w: %v", localinference.ErrWarmupCanceled, ctx.Err())
		case <-ticker.C:
			pollCtx, pollCancel := context.WithTimeout(ctx, nodeCallTimeout)
			current, pollErr := client.GetOperation(pollCtx, &enginev1.GetOperationRequest{
				OperationId: started.GetOperationId(),
			})
			pollCancel()
			if pollErr != nil {
				return localinference.Model{}, translateNodeWarmupError(target, pollErr)
			}
			operation := current.GetOperation()
			state := operationStateLabel(operation.GetState())
			if state != lastState || operation.GetPhase() != lastPhase || operation.GetProgress() != lastProgress {
				if err := report(
					state, operation.GetPhase(), operation.GetProgress(),
					operation.GetDetailMessage(), operation.GetQueuePosition(), operation.GetId(),
				); err != nil {
					return localinference.Model{}, err
				}
				lastState, lastPhase, lastProgress = state, operation.GetPhase(), operation.GetProgress()
			}
			switch operation.GetState() {
			case enginev1.OperationState_OPERATION_STATE_COMPLETED:
				_, model, resolveErr := m.resolveNodeModel(ctx, nodeID, instanceID)
				return model, resolveErr
			case enginev1.OperationState_OPERATION_STATE_CANCELLED:
				return localinference.Model{}, localinference.ErrWarmupCanceled
			case enginev1.OperationState_OPERATION_STATE_FAILED:
				return localinference.Model{}, nodeOperationError(target, operation)
			}
		}
	}
}

// translateNodeWarmupError maps a failed call onto the sentinels the chat
// already knows.
func translateNodeWarmupError(target node.Target, err error) error {
	switch status.Code(err) {
	case codes.NotFound:
		return localinference.ErrNotFound
	case codes.Unavailable:
		return fmt.Errorf("%w: Node %s antwortet nicht", localinference.ErrWorkerUnavailable, target.Name)
	case codes.DeadlineExceeded:
		return fmt.Errorf("%w: Node %s", localinference.ErrQueueTimeout, target.Name)
	default:
		message := err.Error()
		if statusErr, ok := status.FromError(err); ok {
			message = statusErr.Message()
		}
		return fmt.Errorf("%w: Node %s: %s", localinference.ErrWorkerUnavailable, target.Name, message)
	}
}

func nodeOperationError(target node.Target, operation *enginev1.EngineOperation) error {
	message := strings.TrimSpace(operation.GetErrorSummary())
	if message == "" {
		message = strings.TrimSpace(operation.GetError())
	}
	if message == "" {
		message = "Modell-Warmup ist fehlgeschlagen"
	}
	message = "Node " + target.Name + ": " + message
	switch operation.GetErrorCode() {
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

// instanceStateLabel and operationStateLabel put the proto enums back into the
// lower-case words the local warm-up reports, so a client cannot tell the two
// paths apart by their vocabulary.
func instanceStateLabel(instance *enginev1.EngineInstance) string {
	if instance == nil {
		return ""
	}
	name := instance.GetState().String()
	return strings.ToLower(strings.TrimPrefix(name, "INSTANCE_STATE_"))
}

func operationStateLabel(state enginev1.OperationState) string {
	return strings.ToLower(strings.TrimPrefix(state.String(), "OPERATION_STATE_"))
}
