package scout

import (
	"encoding/json"
	"fmt"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	scoutv1 "github.com/culpeohq/backend/gen/go/culpeostudio/scout/v1"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/modules/scout/bots"
	sparktools "github.com/culpeohq/backend/modules/spark/tools"
)

func chatMessageToProto(message chatMessage) *scoutv1.ChatMessage {
	return &scoutv1.ChatMessage{
		Role:    message.Role,
		Content: message.Content,
		BotId:   message.BotID,
		BotName: message.BotName,
	}
}

func modelBindingToProto(binding *bots.ModelBinding) *scoutv1.ModelBinding {
	if binding == nil {
		return nil
	}
	return &scoutv1.ModelBinding{
		Kind:         binding.Kind,
		ModelRef:     binding.ModelRef,
		Provider:     binding.Provider,
		ModelId:      binding.ModelID,
		InstanceId:   binding.InstanceID,
		DisplayName:  binding.DisplayName,
		ConnectionId: binding.ConnectionID,
	}
}

func modelBindingFromProto(binding *scoutv1.ModelBinding) *bots.ModelBinding {
	if binding == nil {
		return nil
	}
	return &bots.ModelBinding{
		Kind:         binding.GetKind(),
		ModelRef:     binding.GetModelRef(),
		Provider:     binding.GetProvider(),
		ModelID:      binding.GetModelId(),
		InstanceID:   binding.GetInstanceId(),
		DisplayName:  binding.GetDisplayName(),
		ConnectionID: binding.GetConnectionId(),
	}
}

func botToProto(bot bots.Config) *scoutv1.Bot {
	return &scoutv1.Bot{
		Id:             bot.ID,
		Name:           bot.Name,
		SystemPrompt:   bot.SystemPrompt,
		Keywords:       append([]string{}, bot.Keywords...),
		ResponseStyle:  bot.ResponseStyle,
		AgenticEnabled: bot.AgenticEnabled,
		AllowedRoots:   append([]string{}, bot.AllowedRoots...),
		IsDefault:      bot.IsDefault,
		ModelBinding:   modelBindingToProto(bot.ModelBinding),
	}
}

func botFromProto(bot *scoutv1.Bot) bots.Config {
	if bot == nil {
		return bots.Config{}
	}
	return bots.Config{
		ID:             bot.GetId(),
		Name:           bot.GetName(),
		SystemPrompt:   bot.GetSystemPrompt(),
		Keywords:       append([]string{}, bot.GetKeywords()...),
		ResponseStyle:  bot.GetResponseStyle(),
		AgenticEnabled: bot.GetAgenticEnabled(),
		AllowedRoots:   append([]string{}, bot.GetAllowedRoots()...),
		IsDefault:      bot.GetIsDefault(),
		ModelBinding:   modelBindingFromProto(bot.GetModelBinding()),
	}
}

func sessionSummaryToProto(summary scoutSessionSummary) *scoutv1.SessionSummary {
	message := &scoutv1.SessionSummary{
		SessionId:    summary.SessionID,
		Title:        summary.Title,
		Preview:      summary.Preview,
		Provider:     summary.Provider,
		ModelId:      summary.ModelID,
		DisplayName:  summary.DisplayName,
		LockedBotId:  summary.LockedBotID,
		ProjectId:    summary.ProjectID,
		MessageCount: int32(summary.MessageCount),
		ConnectionId: summary.ConnectionID,
	}
	if !summary.UpdatedAt.IsZero() {
		message.UpdatedAt = timestamppb.New(summary.UpdatedAt)
	}
	return message
}

// fileNodeToProto walks the folder listing the spark tools built. The HTTP API
// handed this out as an untyped tree; the shape was always this one.
func fileNodeToProto(node *sparktools.DirTreeEntry) *scoutv1.FileNode {
	if node == nil {
		return nil
	}
	message := &scoutv1.FileNode{
		Name:  node.Name,
		Path:  node.Path,
		IsDir: node.IsDir,
	}
	message.Children = make([]*scoutv1.FileNode, 0, len(node.Children))
	for _, child := range node.Children {
		if converted := fileNodeToProto(child); converted != nil {
			message.Children = append(message.Children, converted)
		}
	}
	return message
}

func warmupToProto(progress localinference.WarmupProgress) *scoutv1.ModelWarmup {
	return &scoutv1.ModelWarmup{
		OperationId:   progress.OperationID,
		InstanceId:    progress.InstanceID,
		Status:        progress.Status,
		Phase:         progress.Phase,
		Progress:      progress.Progress,
		QueuePosition: int32(progress.QueuePosition),
		Placement:     progress.Placement,
		Message:       progress.Message,
	}
}

func contextUsageToProto(usage contextUsage) *scoutv1.ContextUsage {
	return &scoutv1.ContextUsage{
		LimitTokens:      int32(usage.LimitTokens),
		UsedTokens:       int32(usage.UsedTokens),
		Source:           usage.Source,
		Compactions:      int32(usage.Compactions),
		Compacted:        usage.Compacted,
		ModelLimitTokens: int32(usage.ModelLimitTokens),
	}
}

// contextUsageFromPayload reads back the map the reply path emits its readings
// as. The emitter is the generic event channel shared with the agent loop, so
// the typed value has to survive a trip through interface{}.
func contextUsageFromPayload(data interface{}) (contextUsage, bool) {
	payload, ok := data.(map[string]interface{})
	if !ok {
		return contextUsage{}, false
	}
	usage := contextUsage{
		LimitTokens:      intField(payload, "limit_tokens"),
		UsedTokens:       intField(payload, "used_tokens"),
		Compactions:      intField(payload, "compactions"),
		ModelLimitTokens: intField(payload, "model_limit_tokens"),
	}
	usage.Source, _ = payload["source"].(string)
	usage.Compacted, _ = payload["compacted"].(bool)
	return usage, usage.LimitTokens > 0
}

func intField(payload map[string]interface{}, key string) int {
	switch value := payload[key].(type) {
	case int:
		return value
	case int32:
		return int(value)
	case int64:
		return int(value)
	case float64:
		return int(value)
	}
	return 0
}

// chatOptionsFromProto keeps the normalisation the query body went through, so
// an unset field still lands on the same default it always did.
func chatOptionsFromProto(options *scoutv1.ChatOptions) chatOptions {
	if options == nil {
		return normalizeChatOptions("", "", nil, "", nil, false, false, "", "")
	}

	var editIndex *int
	if options.EditMessageIndex != nil {
		index := int(options.GetEditMessageIndex())
		editIndex = &index
	}
	return normalizeChatOptions(
		options.GetThinkingLevel(),
		options.GetResponseStyle(),
		editIndex,
		options.GetMode(),
		options.GetAllowedRoots(),
		options.GetApprovePlan(),
		options.GetPlanning(),
		options.GetReasoningEffort(),
		options.GetOutputLevel(),
	)
}

// agentPayloadToProto carries an agent-loop payload as it is. The values come
// from the tool layer in the spark module, where a tool decides for itself what
// its result looks like, so they are converted through JSON rather than being
// enumerated here.
func agentPayloadToProto(data interface{}) (*structpb.Struct, error) {
	if data == nil {
		return nil, nil
	}

	raw, err := json.Marshal(data)
	if err != nil {
		return nil, fmt.Errorf("Agent-Ereignis konnte nicht serialisiert werden: %w", err)
	}
	payload := &structpb.Struct{}
	if err := protojson.Unmarshal(raw, payload); err != nil {
		// A payload that is not a JSON object cannot be a Struct. No emitter
		// sends one today; carrying it under a key beats dropping the event.
		wrapped, wrapErr := structpb.NewStruct(map[string]interface{}{"value": string(raw)})
		if wrapErr != nil {
			return nil, fmt.Errorf("Agent-Ereignis konnte nicht uebertragen werden: %w", err)
		}
		return wrapped, nil
	}
	return payload, nil
}
