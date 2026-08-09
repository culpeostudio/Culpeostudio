package memorymodule

import (
	"encoding/json"
	"fmt"
	"time"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	memoryv1 "github.com/culpeohq/backend/gen/go/culpeostudio/memory/v1"
	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memoryviewer"
)

func sessionStatusToProto(status memory.SessionStatus) memoryv1.SessionStatus {
	switch status {
	case memory.SessionActive:
		return memoryv1.SessionStatus_SESSION_STATUS_ACTIVE
	case memory.SessionCompleted:
		return memoryv1.SessionStatus_SESSION_STATUS_COMPLETED
	default:
		return memoryv1.SessionStatus_SESSION_STATUS_UNSPECIFIED
	}
}

func promptRoleToProto(role memory.PromptRole) memoryv1.PromptRole {
	switch role {
	case memory.PromptRoleAssistant:
		return memoryv1.PromptRole_PROMPT_ROLE_ASSISTANT
	case memory.PromptRoleSystem:
		return memoryv1.PromptRole_PROMPT_ROLE_SYSTEM
	case memory.PromptRoleUser:
		return memoryv1.PromptRole_PROMPT_ROLE_USER
	default:
		return memoryv1.PromptRole_PROMPT_ROLE_UNSPECIFIED
	}
}

func promptRoleFromProto(role memoryv1.PromptRole) memory.PromptRole {
	switch role {
	case memoryv1.PromptRole_PROMPT_ROLE_ASSISTANT:
		return memory.PromptRoleAssistant
	case memoryv1.PromptRole_PROMPT_ROLE_SYSTEM:
		return memory.PromptRoleSystem
	default:
		return memory.PromptRoleUser
	}
}

func layerToProto(layer memory.MemoryLayer) memoryv1.MemoryLayer {
	switch layer {
	case memory.LayerUserData:
		return memoryv1.MemoryLayer_MEMORY_LAYER_USER_DATA
	case memory.LayerProjectData:
		return memoryv1.MemoryLayer_MEMORY_LAYER_PROJECT_DATA
	default:
		return memoryv1.MemoryLayer_MEMORY_LAYER_UNSPECIFIED
	}
}

// layerFromProto leaves an unspecified layer empty rather than picking one.
// What that emptiness means is decided further in: a write normalises it to the
// project layer, a filter reads it as "any layer" and lets the query decide.
func layerFromProto(layer memoryv1.MemoryLayer) memory.MemoryLayer {
	switch layer {
	case memoryv1.MemoryLayer_MEMORY_LAYER_USER_DATA:
		return memory.LayerUserData
	case memoryv1.MemoryLayer_MEMORY_LAYER_PROJECT_DATA:
		return memory.LayerProjectData
	default:
		return ""
	}
}

func categoryToProto(category memory.MemoryCategory) memoryv1.MemoryCategory {
	switch category {
	case memory.CategoryStatus:
		return memoryv1.MemoryCategory_MEMORY_CATEGORY_STATUS
	case memory.CategoryBrainstorming:
		return memoryv1.MemoryCategory_MEMORY_CATEGORY_BRAINSTORMING
	case memory.CategoryChangeRequest:
		return memoryv1.MemoryCategory_MEMORY_CATEGORY_CHANGE_REQUEST
	default:
		return memoryv1.MemoryCategory_MEMORY_CATEGORY_UNSPECIFIED
	}
}

// categoryFromProto leaves an unspecified category empty, for the same reason
// layerFromProto does.
func categoryFromProto(category memoryv1.MemoryCategory) memory.MemoryCategory {
	switch category {
	case memoryv1.MemoryCategory_MEMORY_CATEGORY_STATUS:
		return memory.CategoryStatus
	case memoryv1.MemoryCategory_MEMORY_CATEGORY_BRAINSTORMING:
		return memory.CategoryBrainstorming
	case memoryv1.MemoryCategory_MEMORY_CATEGORY_CHANGE_REQUEST:
		return memory.CategoryChangeRequest
	default:
		return ""
	}
}

func changeRequestStatusToProto(status memory.ChangeRequestStatus) memoryv1.ChangeRequestStatus {
	switch status {
	case memory.ChangeRequestOpen:
		return memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_OPEN
	case memory.ChangeRequestAccepted:
		return memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_ACCEPTED
	case memory.ChangeRequestRejected:
		return memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_REJECTED
	default:
		return memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_UNSPECIFIED
	}
}

// changeRequestStatusFromProto reads an unspecified status as open, which is
// the state the store normalises an unknown one to.
func changeRequestStatusFromProto(status memoryv1.ChangeRequestStatus) memory.ChangeRequestStatus {
	switch status {
	case memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_ACCEPTED:
		return memory.ChangeRequestAccepted
	case memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_REJECTED:
		return memory.ChangeRequestRejected
	default:
		return memory.ChangeRequestOpen
	}
}

func changeRequestToProto(state *memory.ChangeRequestState) *memoryv1.ChangeRequestState {
	if state == nil {
		return nil
	}
	return &memoryv1.ChangeRequestState{
		Status:      changeRequestStatusToProto(state.Status),
		Proposal:    state.Proposal,
		ReasonShort: state.ReasonShort,
		DecidedAt:   state.DecidedAt,
	}
}

func changeRequestFromProto(state *memoryv1.ChangeRequestState) *memory.ChangeRequestState {
	if state == nil {
		return nil
	}
	return &memory.ChangeRequestState{
		Status:      changeRequestStatusFromProto(state.GetStatus()),
		Proposal:    state.GetProposal(),
		ReasonShort: state.GetReasonShort(),
		DecidedAt:   state.GetDecidedAt(),
	}
}

func promptToProto(prompt *memory.Prompt) *memoryv1.Prompt {
	if prompt == nil {
		return nil
	}
	return &memoryv1.Prompt{
		Id:        prompt.ID,
		SessionId: prompt.SessionID,
		Role:      promptRoleToProto(prompt.Role),
		Text:      prompt.Text,
		CreatedAt: timestampToProto(prompt.CreatedAt),
	}
}

func promptsToProto(prompts []memory.Prompt) []*memoryv1.Prompt {
	if len(prompts) == 0 {
		return nil
	}
	messages := make([]*memoryv1.Prompt, 0, len(prompts))
	for index := range prompts {
		messages = append(messages, promptToProto(&prompts[index]))
	}
	return messages
}

func observationToProto(observation *memory.Observation) *memoryv1.Observation {
	if observation == nil {
		return nil
	}
	return &memoryv1.Observation{
		Id:            observation.ID,
		SessionId:     observation.SessionID,
		Project:       observation.Project,
		Source:        observation.Source,
		Layer:         layerToProto(observation.Layer),
		Category:      categoryToProto(observation.Category),
		Type:          observation.Type,
		Title:         observation.Title,
		Narrative:     observation.Narrative,
		ChangeRequest: changeRequestToProto(observation.ChangeRequest),
		Speaker:       observation.Speaker,
		DialogueId:    int32(observation.DialogueID),
		Keywords:      observation.Keywords,
		Persons:       observation.Persons,
		Entities:      observation.Entities,
		Topic:         observation.Topic,
		Location:      observation.Location,
		ValidFrom:     observation.ValidFrom,
		Importance:    observation.Importance,
		Confidence:    observation.Confidence,
		SupersededBy:  observation.SupersededBy,
		ToolName:      observation.ToolName,
		SourcePath:    observation.SourcePath,
		Tags:          observation.Tags,
		ContentHash:   observation.ContentHash,
		Archived:      observation.Archived,
		MemoryId:      observation.MemoryID,
		DeletedAt:     observation.DeletedAt,
		CreatedAt:     timestampToProto(observation.CreatedAt),
	}
}

func observationsToProto(observations []memory.Observation) []*memoryv1.Observation {
	if len(observations) == 0 {
		return nil
	}
	messages := make([]*memoryv1.Observation, 0, len(observations))
	for index := range observations {
		messages = append(messages, observationToProto(&observations[index]))
	}
	return messages
}

func compressedMemoryToProto(item *memory.CompressedMemory) *memoryv1.CompressedMemory {
	if item == nil {
		return nil
	}
	return &memoryv1.CompressedMemory{
		Id:              item.ID,
		SessionId:       item.SessionID,
		Layer:           layerToProto(item.Layer),
		Category:        categoryToProto(item.Category),
		Summary:         item.Summary,
		Learned:         item.Learned,
		OpenTasks:       item.OpenTasks,
		ObservationIds:  item.ObservationIDs,
		CorrectedByUser: item.CorrectedByUser,
		CreatedAt:       timestampToProto(item.CreatedAt),
	}
}

func compressedMemoriesToProto(items []memory.CompressedMemory) []*memoryv1.CompressedMemory {
	if len(items) == 0 {
		return nil
	}
	messages := make([]*memoryv1.CompressedMemory, 0, len(items))
	for index := range items {
		messages = append(messages, compressedMemoryToProto(&items[index]))
	}
	return messages
}

func sessionSummaryToProto(summary *memory.SessionSummary) *memoryv1.SessionSummary {
	if summary == nil {
		return nil
	}
	return &memoryv1.SessionSummary{
		Id:        summary.ID,
		SessionId: summary.SessionID,
		Learned:   summary.Learned,
		Completed: summary.Completed,
		NextSteps: summary.NextSteps,
		CreatedAt: timestampToProto(summary.CreatedAt),
	}
}

func sessionSummariesToProto(summaries []memory.SessionSummary) []*memoryv1.SessionSummary {
	if len(summaries) == 0 {
		return nil
	}
	messages := make([]*memoryv1.SessionSummary, 0, len(summaries))
	for index := range summaries {
		messages = append(messages, sessionSummaryToProto(&summaries[index]))
	}
	return messages
}

func sessionToProto(session *memory.Session) *memoryv1.Session {
	if session == nil {
		return nil
	}
	return &memoryv1.Session{
		Id:                    session.ID,
		Project:               session.Project,
		Source:                session.Source,
		Status:                sessionStatusToProto(session.Status),
		Goals:                 session.Goals,
		Prompts:               promptsToProto(session.Prompts),
		ActiveObservations:    observationsToProto(session.ActiveObservations),
		ArchivedObservations:  observationsToProto(session.ArchivedObservations),
		Memories:              compressedMemoriesToProto(session.Memories),
		Summaries:             sessionSummariesToProto(session.Summaries),
		ContextUsageEstimate:  session.ContextUsageEstimate,
		PromptCount:           int32(session.PromptCount),
		ObservationCount:      int32(session.ObservationCount),
		CompressedMemoryCount: int32(session.CompressedMemoryCount),
		SummaryCount:          int32(session.SummaryCount),
		CreatedAt:             timestampToProto(session.CreatedAt),
		UpdatedAt:             timestampToProto(session.UpdatedAt),
	}
}

func sessionsToProto(sessions []*memory.Session) []*memoryv1.Session {
	if len(sessions) == 0 {
		return nil
	}
	messages := make([]*memoryv1.Session, 0, len(sessions))
	for _, session := range sessions {
		messages = append(messages, sessionToProto(session))
	}
	return messages
}

func searchResultsToProto(results []memory.SearchResult) []*memoryv1.SearchResult {
	if len(results) == 0 {
		return nil
	}
	messages := make([]*memoryv1.SearchResult, 0, len(results))
	for _, result := range results {
		messages = append(messages, &memoryv1.SearchResult{
			DocId:       result.DocID,
			SessionId:   result.SessionID,
			RefId:       result.RefID,
			Kind:        result.Kind,
			Project:     result.Project,
			Source:      result.Source,
			Layer:       layerToProto(result.Layer),
			Category:    categoryToProto(result.Category),
			Type:        result.Type,
			Title:       result.Title,
			Snippet:     result.Snippet,
			Score:       result.Score,
			TextScore:   result.TextScore,
			VectorScore: result.VectorScore,
			CreatedAt:   timestampToProto(result.CreatedAt),
		})
	}
	return messages
}

func toolHintsToProto(hints []memory.ToolDefinition) []*memoryv1.ToolDefinition {
	if len(hints) == 0 {
		return nil
	}
	messages := make([]*memoryv1.ToolDefinition, 0, len(hints))
	for _, hint := range hints {
		messages = append(messages, &memoryv1.ToolDefinition{
			Name:        hint.Name,
			Description: hint.Description,
			JsonShape:   hint.JSONShape,
		})
	}
	return messages
}

func contextEnvelopeToProto(envelope *memory.ContextEnvelope) *memoryv1.ContextEnvelope {
	if envelope == nil {
		return nil
	}
	return &memoryv1.ContextEnvelope{
		SessionId:       envelope.SessionID,
		Query:           envelope.Query,
		BudgetTokens:    int32(envelope.BudgetTokens),
		UsedTokens:      int32(envelope.UsedTokens),
		InjectionPrompt: envelope.InjectionPrompt,
		Memories:        compressedMemoriesToProto(envelope.Memories),
		Observations:    observationsToProto(envelope.Observations),
		Summary:         sessionSummaryToProto(envelope.Summary),
		ToolHints:       toolHintsToProto(envelope.ToolHints),
	}
}

func observationInputFromProto(req *memoryv1.AddObservationRequest) memory.AddObservationInput {
	return memory.AddObservationInput{
		Project:       req.GetProject(),
		Source:        req.GetSource(),
		Layer:         layerFromProto(req.GetLayer()),
		Category:      categoryFromProto(req.GetCategory()),
		Type:          req.GetType(),
		Title:         req.GetTitle(),
		Narrative:     req.GetNarrative(),
		ChangeRequest: changeRequestFromProto(req.GetChangeRequest()),
		Speaker:       req.GetSpeaker(),
		DialogueID:    int(req.GetDialogueId()),
		Keywords:      req.GetKeywords(),
		Persons:       req.GetPersons(),
		Entities:      req.GetEntities(),
		Topic:         req.GetTopic(),
		Location:      req.GetLocation(),
		ValidFrom:     req.GetValidFrom(),
		Importance:    req.GetImportance(),
		Confidence:    req.GetConfidence(),
		SupersededBy:  req.GetSupersededBy(),
		ToolName:      req.GetToolName(),
		SourcePath:    req.GetSourcePath(),
		Tags:          req.GetTags(),
	}
}

// memoryPatchFromProto turns the set fields of an update into the patch the
// store applies. A list that was not sent stays nil and is left alone; a list
// sent empty clears the stored one.
func memoryPatchFromProto(req *memoryv1.UpdateMemoryRequest) memory.MemoryPatch {
	patch := memory.MemoryPatch{}
	if req.Summary != nil {
		summary := req.GetSummary()
		patch.Summary = &summary
	}
	if list := req.GetLearned(); list != nil {
		values := list.GetValues()
		if values == nil {
			values = []string{}
		}
		patch.Learned = &values
	}
	if list := req.GetOpenTasks(); list != nil {
		values := list.GetValues()
		if values == nil {
			values = []string{}
		}
		patch.OpenTasks = &values
	}
	return patch
}

// eventToProto types the payloads the store publishes and carries the rest as
// the JSON object the feed already delivered. Both value and pointer forms are
// handled because the publishers use both.
func eventToProto(event memoryviewer.Event) (*memoryv1.StreamEventsResponse, error) {
	message := &memoryv1.StreamEventsResponse{
		Type:      event.Type,
		Timestamp: timestampToProto(event.Timestamp),
	}

	switch data := event.Data.(type) {
	case nil:
	case *memory.Session:
		message.Payload = &memoryv1.StreamEventsResponse_Session{Session: sessionToProto(data)}
	case memory.Session:
		message.Payload = &memoryv1.StreamEventsResponse_Session{Session: sessionToProto(&data)}
	case *memory.Prompt:
		message.Payload = &memoryv1.StreamEventsResponse_Prompt{Prompt: promptToProto(data)}
	case memory.Prompt:
		message.Payload = &memoryv1.StreamEventsResponse_Prompt{Prompt: promptToProto(&data)}
	case *memory.Observation:
		message.Payload = &memoryv1.StreamEventsResponse_Observation{Observation: observationToProto(data)}
	case memory.Observation:
		message.Payload = &memoryv1.StreamEventsResponse_Observation{Observation: observationToProto(&data)}
	case *memory.CompressedMemory:
		message.Payload = &memoryv1.StreamEventsResponse_Memory{Memory: compressedMemoryToProto(data)}
	case memory.CompressedMemory:
		message.Payload = &memoryv1.StreamEventsResponse_Memory{Memory: compressedMemoryToProto(&data)}
	case *memory.SessionSummary:
		message.Payload = &memoryv1.StreamEventsResponse_Summary{Summary: sessionSummaryToProto(data)}
	case memory.SessionSummary:
		message.Payload = &memoryv1.StreamEventsResponse_Summary{Summary: sessionSummaryToProto(&data)}
	default:
		payload, err := structFromValue(event.Data)
		if err != nil {
			return nil, err
		}
		if payload != nil {
			message.Payload = &memoryv1.StreamEventsResponse_Data{Data: payload}
		}
	}
	return message, nil
}

// structFromValue converts through JSON rather than enumerating the payloads:
// they are maps a publisher assembled for the viewer, not types this module
// owns.
func structFromValue(value interface{}) (*structpb.Struct, error) {
	if value == nil {
		return nil, nil
	}
	raw, err := json.Marshal(value)
	if err != nil {
		return nil, fmt.Errorf("Memory-Ereignis konnte nicht serialisiert werden: %w", err)
	}
	payload := &structpb.Struct{}
	if err := protojson.Unmarshal(raw, payload); err != nil {
		// Not a JSON object, so not a Struct. No publisher sends one today;
		// carrying it under a key beats dropping the event.
		wrapped, wrapErr := structpb.NewStruct(map[string]interface{}{"value": string(raw)})
		if wrapErr != nil {
			return nil, fmt.Errorf("Memory-Ereignis konnte nicht uebertragen werden: %w", err)
		}
		return wrapped, nil
	}
	return payload, nil
}

// timestampToProto leaves a never-set time unset rather than reporting the
// epoch.
func timestampToProto(value time.Time) *timestamppb.Timestamp {
	if value.IsZero() {
		return nil
	}
	return timestamppb.New(value)
}
