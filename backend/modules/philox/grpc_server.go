package philox

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"strings"

	pb "github.com/fillyengine/backend/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type PhiloxAgenticServer struct {
	pb.UnimplementedPhiloxAgenticServiceServer
	module *PhiloxModule
}

func (m *PhiloxModule) RegisterGRPC(server *grpc.Server) {
	pb.RegisterPhiloxAgenticServiceServer(server, &PhiloxAgenticServer{module: m})
}

func (s *PhiloxAgenticServer) ExecuteAgentic(req *pb.AgenticRequest, stream pb.PhiloxAgenticService_ExecuteAgenticServer) error {
	return s.runAgentic(stream.Context(), req, stream.Send, string(ModeExecute))
}

func (s *PhiloxAgenticServer) PlanAgentic(req *pb.AgenticRequest, stream pb.PhiloxAgenticService_PlanAgenticServer) error {
	return s.runAgentic(stream.Context(), req, stream.Send, string(ModePlan))
}

func (s *PhiloxAgenticServer) ListTools(ctx context.Context, req *pb.Empty) (*pb.ToolList, error) {
	// The Philox agent backend was removed, so no tools are exposed anymore.
	return &pb.ToolList{Tools: []*pb.ToolDef{}}, nil
}

func (s *PhiloxAgenticServer) runAgentic(ctx context.Context, req *pb.AgenticRequest, send func(*pb.AgenticResponse) error, defaultMode string) error {
	if s.module == nil {
		return status.Error(codes.FailedPrecondition, "Philox module ist nicht verbunden")
	}
	message := strings.TrimSpace(req.GetUserMessage())
	if message == "" {
		return status.Error(codes.InvalidArgument, "user_message ist erforderlich")
	}
	session, err := s.module.getOrCreateAgenticSession(req)
	if err != nil {
		return err
	}

	mode := strings.TrimSpace(req.GetMode())
	if mode == "" {
		mode = defaultMode
	}
	modeOverride := mode
	if strings.EqualFold(mode, string(AgenticModePlanning)) {
		modeOverride = string(ModePlan)
	} else if strings.EqualFold(mode, string(AgenticModeExecute)) {
		modeOverride = string(ModeExecute)
	}

	session.mu.Lock()
	approvePlan := strings.EqualFold(req.GetContext()["approve_plan"], "true")
	preparedMessage, preparedMode, err := preparePlanningInput(session, message, nil, approvePlan, modeOverride)
	if err != nil {
		session.mu.Unlock()
		return status.Error(codes.InvalidArgument, err.Error())
	}
	if strings.TrimSpace(preparedMode) != "" {
		modeOverride = preparedMode
	}

	sink := newEventSink(64)
	go func() {
		defer session.mu.Unlock()
		s.module.runAgentStreaming(ctx, session, preparedMessage, req.GetThinkingLevel(), modeOverride, sink)
	}()

	for event := range sink.Events() {
		protoEvent := toProtoAgenticResponse(event)
		if protoEvent == nil {
			continue
		}
		if err := send(protoEvent); err != nil {
			return err
		}
	}
	return nil
}

func (m *PhiloxModule) getOrCreateAgenticSession(req *pb.AgenticRequest) (*PersistedSession, error) {
	id := strings.TrimSpace(req.GetSessionId())
	if id != "" {
		session, err := m.store.Get(id)
		if err == nil {
			applyAgenticBotContext(session, req)
			roots, normalizeErr := m.executor.NormalizeRoots(req.GetAllowedRoots())
			if normalizeErr != nil {
				return nil, status.Error(codes.InvalidArgument, normalizeErr.Error())
			}
			if len(roots) > 0 {
				session.AllowedRoots = roots
			}
			return session, nil
		}
		if !errors.Is(err, os.ErrNotExist) {
			return nil, status.Error(codes.Internal, err.Error())
		}
	}
	if id == "" {
		id = newChatSessionID()
	}

	roots, err := m.executor.NormalizeRoots(req.GetAllowedRoots())
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	now := nowUTC()
	session := &PersistedSession{
		ID:                 id,
		UserID:             "local",
		ThinkingLevel:      normalizeThinkingLevel(req.GetThinkingLevel()),
		Mode:               normalizeAgenticSessionMode(req.GetMode()),
		AllowedRoots:       roots,
		Messages:           []ConversationMessage{},
		ArchivedMessages:   []ConversationMessage{},
		CompressedMemories: []CompressedMemory{},
		Planning:           defaultPlanningState(),
		ToolAudit:          []ToolAuditEntry{},
		CreatedAt:          now,
		UpdatedAt:          now,
	}
	applyAgenticBotContext(session, req)
	session.EffectiveModel = effectiveModelForThinking(session.ModelID)
	session.ContextUsageEstimate = estimateSessionUsage(session)
	if err := m.store.Create(session); err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	if m.memory != nil {
		m.memory.PhiloxSessionStarted(session.ID, nil)
	}
	return session, nil
}

// applyAgenticBotContext transfers the selected bot's identity into the
// Philox runtime session. Context is intentionally request-scoped: the same
// agentic session can be reused after the user selects a different bot.
func applyAgenticBotContext(session *PersistedSession, req *pb.AgenticRequest) {
	if session == nil || req == nil {
		return
	}
	context := req.GetContext()
	session.ActiveBotID = strings.TrimSpace(context["bot_id"])
	session.ActiveBotName = strings.TrimSpace(context["bot_name"])
	session.ActiveBotSystemPrompt = strings.TrimSpace(context["system_prompt"])
}

func normalizeAgenticSessionMode(raw string) SessionMode {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case string(AgenticModePlanning), string(ModePlan):
		return ModePlan
	default:
		return ModeExecute
	}
}

func toProtoAgenticResponse(event StreamEvent) *pb.AgenticResponse {
	switch event.Type {
	case EventTextDelta:
		if data, ok := event.Data.(TextDeltaData); ok {
			return &pb.AgenticResponse{Type: pb.AgenticResponse_TEXT_DELTA, Text: data.Chunk}
		}
	case EventToolStart:
		if data, ok := event.Data.(ToolStartData); ok {
			arguments := ""
			if len(data.Arguments) > 0 {
				if payload, err := json.Marshal(data.Arguments); err == nil {
					arguments = string(payload)
				}
			}
			return &pb.AgenticResponse{
				Type: pb.AgenticResponse_TOOL_START,
				ToolCall: &pb.ToolCall{
					Id:        data.CallID,
					Name:      data.ToolName,
					Arguments: arguments,
				},
			}
		}
	case EventToolResult:
		if data, ok := event.Data.(ToolResultData); ok {
			return &pb.AgenticResponse{
				Type: pb.AgenticResponse_TOOL_RESULT,
				ToolCall: &pb.ToolCall{
					Id:            data.CallID,
					Name:          data.ToolName,
					ResultPreview: data.ResultPreview,
					Success:       data.Success,
				},
			}
		}
	case EventPlanning:
		if data, ok := event.Data.(*PlanningState); ok {
			return &pb.AgenticResponse{Type: planningResponseType(data), Planning: toProtoPlanningState(data)}
		}
		if data, ok := event.Data.(PlanningState); ok {
			return &pb.AgenticResponse{Type: planningResponseType(&data), Planning: toProtoPlanningState(&data)}
		}
	case EventCompression:
		if data, ok := event.Data.(*CompressionEvent); ok {
			return &pb.AgenticResponse{Type: pb.AgenticResponse_COMPRESSION_EVENT, Compression: toProtoCompressionEvent(data)}
		}
		if data, ok := event.Data.(CompressionEvent); ok {
			return &pb.AgenticResponse{Type: pb.AgenticResponse_COMPRESSION_EVENT, Compression: toProtoCompressionEvent(&data)}
		}
	case EventError:
		if data, ok := event.Data.(ErrorData); ok {
			return &pb.AgenticResponse{Type: pb.AgenticResponse_ERROR, Error: data.Message}
		}
	case EventDone:
		if data, ok := event.Data.(DoneData); ok {
			return &pb.AgenticResponse{
				Type:     pb.AgenticResponse_DONE,
				Text:     data.Reply,
				Planning: toProtoPlanningState(data.Planning),
				Done:     true,
			}
		}
		return &pb.AgenticResponse{Type: pb.AgenticResponse_DONE, Done: true}
	}
	return nil
}

func planningResponseType(state *PlanningState) pb.AgenticResponse_Type {
	if state == nil {
		return pb.AgenticResponse_PLANNING_QUESTIONS
	}
	switch state.Status {
	case PlanningStatusReady:
		return pb.AgenticResponse_PLAN_READY
	case PlanningStatusApproved:
		return pb.AgenticResponse_APPROVAL_NEEDED
	default:
		if len(state.Questions) > 0 {
			return pb.AgenticResponse_PLANNING_QUESTIONS
		}
		return pb.AgenticResponse_PLAN_READY
	}
}

func toProtoPlanningState(state *PlanningState) *pb.PlanningState {
	if state == nil {
		return nil
	}
	result := &pb.PlanningState{
		Status: string(state.Status),
	}
	if state.Draft != nil {
		result.PlanSummary = state.Draft.Summary
		if result.PlanSummary == "" {
			result.PlanSummary = state.Draft.Goal
		}
		result.Steps = append([]string{}, state.Draft.Steps...)
		result.Risks = append([]string{}, state.Draft.Risks...)
		result.Tests = append([]string{}, state.Draft.Tests...)
	} else {
		result.PlanSummary = state.Summary
	}
	for _, question := range state.Questions {
		protoQuestion := &pb.PlanningQuestion{
			Id:          question.ID,
			Prompt:      question.Prompt,
			AllowCustom: question.AllowCustom,
		}
		for _, option := range question.Options {
			protoQuestion.Options = append(protoQuestion.Options, &pb.PlanningOption{
				Id:          option.ID,
				Label:       option.Label,
				Description: option.Description,
			})
		}
		result.Questions = append(result.Questions, protoQuestion)
	}
	return result
}

func toProtoCompressionEvent(event *CompressionEvent) *pb.CompressionEvent {
	if event == nil {
		return nil
	}
	return &pb.CompressionEvent{
		Triggered:          event.Triggered,
		UsageBefore:        float32(event.UsageBefore),
		UsageAfter:         float32(event.UsageAfter),
		CompressedMessages: int32(event.CompressedMessages),
		MemoryId:           event.MemoryID,
	}
}
