package scout

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	scoutv1 "github.com/culpeohq/backend/gen/go/culpeostudio/scout/v1"
	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/modules/scout/bots"
	"github.com/culpeohq/backend/modules/spark"
)

type grpcService struct {
	scoutv1.UnimplementedScoutServiceServer
	module *ScoutModule
}

func (m *ScoutModule) RegisterGRPC(server *grpc.Server) {
	scoutv1.RegisterScoutServiceServer(server, &grpcService{module: m})
}

// scoutUserID keeps the fallback the request-scoped helper had: without an
// authenticated caller everything belongs to the single local user, which is
// how a loopback install without accounts works.
func scoutUserID(ctx context.Context) string {
	if userID := bots.NormalizeUserID(grpcmw.UserIDFromContext(ctx)); userID != "" {
		return userID
	}
	return "local"
}

// chatErrorStatus is the gRPC counterpart of the HTTP status mapping. The code
// string is kept unchanged: the client dispatches on it to tell a warm-up
// problem from a real failure.
func chatErrorStatus(err error) (codes.Code, string) {
	switch {
	case errors.Is(err, errScoutSessionNotFound):
		return codes.NotFound, "session_not_found"
	case errors.Is(err, errScoutBotNotFound):
		return codes.NotFound, "bot_not_found"
	case errors.Is(err, errScoutSessionBusy):
		return codes.ResourceExhausted, "session_busy"
	case errors.Is(err, errModelBindingMissing):
		return codes.NotFound, "model_binding_missing"
	case errors.Is(err, bots.ErrInvalidModelBinding):
		return codes.InvalidArgument, "model_binding_invalid"
	case errors.Is(err, localinference.ErrGuardRejected):
		return codes.Unavailable, "resource_guard_rejected"
	case errors.Is(err, localinference.ErrQueueTimeout):
		return codes.DeadlineExceeded, "model_queue_timeout"
	case errors.Is(err, localinference.ErrWarmupCanceled):
		return codes.Aborted, "model_warmup_canceled"
	case errors.Is(err, localinference.ErrInferenceBusy):
		return codes.ResourceExhausted, "local_inference_busy"
	case errors.Is(err, localinference.ErrNotFound):
		return codes.NotFound, "local_model_not_found"
	case errors.Is(err, localinference.ErrNotReady):
		return codes.FailedPrecondition, "local_model_not_ready"
	case errors.Is(err, localinference.ErrContextLimit):
		return codes.InvalidArgument, "context_length_exceeded"
	case errors.Is(err, localinference.ErrInvalidRequest):
		return codes.InvalidArgument, "invalid_local_request"
	case errors.Is(err, localinference.ErrWorkerUnavailable):
		return codes.Unavailable, "local_model_unavailable"
	default:
		return codes.Unavailable, "provider_error"
	}
}

// retryAfterSeconds is how long the client is told to wait, for the conditions
// that pass on their own.
func retryAfterSeconds(code string) int32 {
	switch code {
	case "session_busy":
		return 1
	case "local_inference_busy":
		return 120
	default:
		return 0
	}
}

func (s *grpcService) CreateSession(
	ctx context.Context,
	req *scoutv1.CreateSessionRequest,
) (*scoutv1.CreateSessionResponse, error) {
	userID := scoutUserID(ctx)
	if err := s.module.botStore.EnsureUser(userID); err != nil {
		return nil, status.Error(codes.Internal, "Bots konnten nicht geladen werden")
	}

	session := scoutSession{
		ID:       newChatSessionID(),
		UserID:   userID,
		ModelRef: strings.TrimSpace(req.GetModelRef()),
		Provider: apimodels.NormalizeProvider(req.GetProvider()),
		ModelID:  strings.TrimSpace(req.GetModelId()),
		Messages: []chatMessage{},
		Thinking: normalizeThinkingLevel(req.GetThinkingLevel()),
		Style:    bots.NormalizeResponseStyle(req.GetResponseStyle()),
	}

	instanceID := strings.TrimSpace(req.GetInstanceId())
	var lockedBot *bots.Config
	if botID := strings.TrimSpace(req.GetBotId()); botID != "" {
		bot, ok := s.module.botStore.GetBotForUser(userID, botID)
		if !ok {
			return nil, status.Error(codes.NotFound, "Bot wurde nicht gefunden")
		}
		lockedBot = &bot
		session.LockedBotID = bot.ID
		session.ActiveBotID = bot.ID
		if bot.ModelBinding != nil {
			binding, err := bots.NormalizeModelBinding(bot.ModelBinding)
			if err != nil {
				return nil, status.Error(codes.InvalidArgument, err.Error())
			}
			session.ModelRef = binding.ModelRef
			session.Provider = binding.Provider
			session.ModelID = binding.ModelID
			session.DisplayName = binding.DisplayName
			if binding.Kind == "local" {
				instanceID = binding.InstanceID
			} else {
				instanceID = ""
			}
		}
	}

	if strings.HasPrefix(strings.ToLower(session.ModelRef), localinference.ProviderLocal+":") {
		refID := strings.TrimSpace(session.ModelRef[len(localinference.ProviderLocal)+1:])
		if refID == "" && instanceID == "" && session.ModelID == "" {
			return nil, status.Error(codes.InvalidArgument, "instance_id ist fuer ein lokales Modell erforderlich")
		}
		if instanceID == "" {
			instanceID = refID
		}
		session.Provider = localinference.ProviderLocal
	}
	if session.Provider == localinference.ProviderLocal && instanceID == "" {
		instanceID = session.ModelID
	}
	if instanceID != "" {
		if err := s.configureLocalModel(&session, instanceID); err != nil {
			return nil, err
		}
	}

	if err := s.configureHostedModel(&session); err != nil {
		return nil, err
	}

	if session.DisplayName == "" {
		session.DisplayName = session.ModelID
	}
	session.SelectedModelRef = session.ModelRef
	session.SelectedProvider = session.Provider
	session.SelectedModelID = session.ModelID
	session.SelectedDisplayName = session.DisplayName
	session.SelectedContextLimit = session.ContextLimit

	if projectID := strings.TrimSpace(req.GetProjectId()); projectID != "" {
		if s.module.agent == nil || !s.module.agent.HasProject(userID, projectID) {
			return nil, status.Error(codes.NotFound, "Projekt wurde nicht gefunden")
		}
		session.ProjectID = projectID
	}

	s.module.mu.Lock()
	s.module.sessions[session.ID] = &session
	s.module.mu.Unlock()
	s.module.persistSession(session.ID)

	bus.Get().Emit("scout", bus.EventScoutSessionCreated, map[string]interface{}{
		"session_id": session.ID,
		"user_id":    session.UserID,
		"model_ref":  session.ModelRef,
		"provider":   session.Provider,
		"model_id":   session.ModelID,
		"thinking":   session.Thinking,
		"style":      session.Style,
	})

	response := &scoutv1.CreateSessionResponse{
		SessionId:   session.ID,
		ModelRef:    session.ModelRef,
		Provider:    session.Provider,
		ModelId:     session.ModelID,
		DisplayName: session.DisplayName,
		Thinking:    session.Thinking,
		Style:       session.Style,
	}
	if lockedBot != nil {
		response.BotId = lockedBot.ID
		response.BotName = lockedBot.Name
		response.LockedBotId = lockedBot.ID
	}
	if session.Provider == localinference.ProviderLocal {
		response.InstanceId = session.ModelID
		response.ContextLimit = int32(session.ContextLimit)
	}
	return response, nil
}

// configureLocalModel resolves the engine instance a session runs on. A model
// that is not ready yet is accepted when the engine can warm it up, because the
// first message then waits for it instead of the session refusing to open.
func (s *grpcService) configureLocalModel(session *scoutSession, instanceID string) error {
	session.Provider = localinference.ProviderLocal
	if s.module.localModels == nil {
		return status.Error(codes.Unavailable, "Lokale Modell-Engine ist nicht verfuegbar")
	}

	localModel, err := s.module.localModels.ResolveLocalModel(instanceID)
	if err != nil {
		if errors.Is(err, localinference.ErrNotReady) {
			if _, canWarm := s.module.localModels.(localinference.WarmupProvider); canWarm {
				session.ModelID = instanceID
				session.ModelRef = localinference.ProviderLocal + ":" + instanceID
				if session.DisplayName == "" {
					session.DisplayName = instanceID
				}
				return nil
			}
		}
		if errors.Is(err, localinference.ErrNotFound) {
			return status.Error(codes.NotFound, err.Error())
		}
		return status.Error(codes.FailedPrecondition, err.Error())
	}

	session.ModelID = localModel.InstanceID
	session.ModelRef = localinference.ProviderLocal + ":" + localModel.InstanceID
	session.DisplayName = localModel.DisplayName
	session.ContextLimit = localModel.ContextLimit
	return nil
}

// configureHostedModel makes sure a hosted model is actually started for chat,
// starting it when the caller named a provider and model it may use.
func (s *grpcService) configureHostedModel(session *scoutSession) error {
	if session.Provider == localinference.ProviderLocal {
		return nil
	}

	if session.ModelRef == "" && session.Provider != "" && session.ModelID != "" {
		session.ModelRef = apimodels.ModelRef(session.Provider, session.ModelID)
	}
	if session.ModelRef == "" {
		if session.ModelID == "" {
			session.ModelID = "default-model"
			session.DisplayName = "default-model"
		}
		return nil
	}

	active, ok, err := s.module.activeModels.Touch(session.ModelRef)
	if err != nil {
		return status.Error(codes.Internal, "Aktive API-Modelle konnten nicht geladen werden")
	}
	if !ok {
		if session.Provider == "" || session.ModelID == "" {
			return status.Error(codes.NotFound,
				"API-Modell ist nicht fuer Chat gestartet. Bitte im Marketplace erneut 'Im Chat starten' ausfuehren.")
		}
		if !apimodels.IsSupportedProvider(session.Provider) {
			return status.Error(codes.InvalidArgument, "provider wird fuer API-Chat nicht unterstuetzt")
		}
		started, startErr := s.module.activeModels.Start(session.Provider, session.ModelID, session.DisplayName)
		if startErr != nil {
			return status.Error(codes.Internal, startErr.Error())
		}
		active = started
	}
	session.Provider = active.Provider
	session.ModelID = active.ModelID
	session.DisplayName = active.DisplayName
	return nil
}

func (s *grpcService) ListSessions(
	ctx context.Context,
	req *scoutv1.ListSessionsRequest,
) (*scoutv1.ListSessionsResponse, error) {
	userID := scoutUserID(ctx)

	s.module.mu.Lock()
	summaries := make([]scoutSessionSummary, 0, len(s.module.sessions))
	for _, session := range s.module.sessions {
		if session == nil || session.UserID != userID || len(session.Messages) == 0 {
			continue
		}
		summaries = append(summaries, summarizeSession(session))
	}
	s.module.mu.Unlock()

	sort.Slice(summaries, func(i, j int) bool {
		return summaries[i].UpdatedAt.After(summaries[j].UpdatedAt)
	})

	sessions := make([]*scoutv1.SessionSummary, 0, len(summaries))
	for _, summary := range summaries {
		sessions = append(sessions, sessionSummaryToProto(summary))
	}
	return &scoutv1.ListSessionsResponse{Sessions: sessions}, nil
}

func (s *grpcService) GetHistory(
	ctx context.Context,
	req *scoutv1.GetHistoryRequest,
) (*scoutv1.GetHistoryResponse, error) {
	sessionID := strings.TrimSpace(req.GetSessionId())
	userID := scoutUserID(ctx)

	s.module.mu.Lock()
	session := s.module.sessions[sessionID]
	if session == nil || session.UserID != userID {
		s.module.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Session wurde nicht gefunden")
	}
	response := &scoutv1.GetHistoryResponse{
		SessionId:    sessionID,
		Provider:     session.Provider,
		ModelId:      session.ModelID,
		ModelRef:     session.ModelRef,
		DisplayName:  session.DisplayName,
		ContextLimit: int32(session.ContextLimit),
		LockedBotId:  session.LockedBotID,
		ActiveBotId:  session.ActiveBotID,
	}
	response.Messages = make([]*scoutv1.ChatMessage, 0, len(session.Messages))
	for _, message := range session.Messages {
		response.Messages = append(response.Messages, chatMessageToProto(message))
	}
	s.module.mu.Unlock()

	return response, nil
}

func (s *grpcService) RenameSession(
	ctx context.Context,
	req *scoutv1.RenameSessionRequest,
) (*scoutv1.RenameSessionResponse, error) {
	sessionID := strings.TrimSpace(req.GetSessionId())
	userID := scoutUserID(ctx)

	title := strings.TrimSpace(req.GetTitle())
	if utf8.RuneCountInString(title) > 120 {
		title = string([]rune(title)[:120])
	}

	s.module.mu.Lock()
	session := s.module.sessions[sessionID]
	if session == nil || session.UserID != userID {
		s.module.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Session wurde nicht gefunden")
	}
	session.Title = title
	summary := summarizeSession(session)
	s.module.mu.Unlock()
	s.module.persistSession(sessionID)

	return &scoutv1.RenameSessionResponse{Session: sessionSummaryToProto(summary)}, nil
}

func (s *grpcService) DeleteSession(
	ctx context.Context,
	req *scoutv1.DeleteSessionRequest,
) (*scoutv1.DeleteSessionResponse, error) {
	sessionID := strings.TrimSpace(req.GetSessionId())
	userID := scoutUserID(ctx)

	s.module.mu.Lock()
	session := s.module.sessions[sessionID]
	if session == nil || session.UserID != userID {
		s.module.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Session wurde nicht gefunden")
	}
	delete(s.module.sessions, sessionID)
	s.module.mu.Unlock()

	if err := s.module.storage.Delete(sessionID); err != nil {
		log.Printf("[scout] Session %s loeschen fehlgeschlagen: %v", sessionID, err)
	}
	return &scoutv1.DeleteSessionResponse{}, nil
}

func (s *grpcService) SetSessionProject(
	ctx context.Context,
	req *scoutv1.SetSessionProjectRequest,
) (*scoutv1.SetSessionProjectResponse, error) {
	sessionID := strings.TrimSpace(req.GetSessionId())
	projectID := strings.TrimSpace(req.GetProjectId())
	userID := scoutUserID(ctx)

	if projectID != "" && (s.module.agent == nil || !s.module.agent.HasProject(userID, projectID)) {
		return nil, status.Error(codes.NotFound, "Projekt wurde nicht gefunden")
	}

	s.module.mu.Lock()
	session := s.module.sessions[sessionID]
	if session == nil || session.UserID != userID {
		s.module.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Session wurde nicht gefunden")
	}
	session.ProjectID = projectID
	summary := summarizeSession(session)
	s.module.mu.Unlock()
	s.module.persistSession(sessionID)

	return &scoutv1.SetSessionProjectResponse{Session: sessionSummaryToProto(summary)}, nil
}

func (s *grpcService) SetSessionModel(
	ctx context.Context,
	req *scoutv1.SetSessionModelRequest,
) (*scoutv1.SetSessionModelResponse, error) {
	provider := strings.TrimSpace(req.GetProvider())
	modelID := strings.TrimSpace(req.GetModelId())
	if provider == "" || modelID == "" {
		return nil, status.Error(codes.InvalidArgument, "provider und model_id sind erforderlich")
	}

	sessionID := strings.TrimSpace(req.GetSessionId())
	userID := scoutUserID(ctx)

	s.module.mu.Lock()
	session := s.module.sessions[sessionID]
	if session == nil || session.UserID != userID {
		s.module.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Session wurde nicht gefunden")
	}
	session.SelectedProvider = provider
	session.SelectedModelID = modelID
	session.SelectedModelRef = strings.TrimSpace(req.GetModelRef())
	session.SelectedDisplayName = strings.TrimSpace(req.GetDisplayName())
	session.SelectedContextLimit = int(req.GetContextLimit())
	summary := summarizeSession(session)
	s.module.mu.Unlock()
	s.module.persistSession(sessionID)

	return &scoutv1.SetSessionModelResponse{Session: sessionSummaryToProto(summary)}, nil
}

func (s *grpcService) GetSessionTree(
	ctx context.Context,
	req *scoutv1.GetSessionTreeRequest,
) (*scoutv1.GetSessionTreeResponse, error) {
	sessionID := strings.TrimSpace(req.GetSessionId())
	userID := scoutUserID(ctx)

	s.module.mu.Lock()
	session := s.module.sessions[sessionID]
	if session == nil || session.UserID != userID {
		s.module.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Session wurde nicht gefunden")
	}
	root := s.module.projectPathForSessionLocked(userID, session)
	s.module.mu.Unlock()

	if root == "" {
		return nil, status.Error(codes.FailedPrecondition, "Session hat kein Projekt mit Projektpfad")
	}
	info, err := os.Stat(root)
	if err != nil || !info.IsDir() {
		return nil, status.Error(codes.NotFound, "Projektpfad existiert nicht")
	}

	tree, truncated := spark.DirTree(root)
	return &scoutv1.GetSessionTreeResponse{
		Root:      root,
		Tree:      fileNodeToProto(tree),
		Truncated: truncated,
	}, nil
}

func (s *grpcService) SendMessage(
	ctx context.Context,
	req *scoutv1.SendMessageRequest,
) (*scoutv1.SendMessageResponse, error) {
	sessionID := strings.TrimSpace(req.GetSessionId())
	message := strings.TrimSpace(req.GetMessage())
	if sessionID == "" || message == "" {
		return nil, status.Error(codes.InvalidArgument, "session_id und message sind erforderlich")
	}

	userID := scoutUserID(ctx)
	if err := s.module.acquireSessionMutation(sessionID, userID); err != nil {
		code, _ := chatErrorStatus(err)
		return nil, status.Error(code, err.Error())
	}
	defer s.module.releaseSessionMutation(sessionID, userID)

	options := chatOptionsFromProto(req.GetOptions())
	var reply, botID, botName string
	var createdBot *bots.Config
	var err error
	if options.Thinking == "agentic" {
		reply, botID, botName, err = s.module.generateAgenticReply(ctx, userID, sessionID, message, options, nil, nil)
	} else {
		reply, botID, botName, createdBot, err = s.module.generateReply(ctx, userID, sessionID, message, options, nil, nil, nil, nil)
	}
	if err != nil {
		code, _ := chatErrorStatus(err)
		return nil, status.Error(code, err.Error())
	}

	response := &scoutv1.SendMessageResponse{
		SessionId:     sessionID,
		Reply:         reply,
		BotId:         botID,
		BotName:       botName,
		ThinkingLevel: normalizeThinkingLevel(req.GetOptions().GetThinkingLevel()),
		ResponseStyle: s.module.responseStyleForBot(userID, botID, req.GetOptions().GetResponseStyle()),
	}
	if createdBot != nil {
		response.CreatedBot = botToProto(*createdBot)
	}
	return response, nil
}

func (s *grpcService) StreamMessage(
	req *scoutv1.StreamMessageRequest,
	stream grpc.ServerStreamingServer[scoutv1.StreamMessageResponse],
) error {
	sessionID := strings.TrimSpace(req.GetSessionId())
	message := strings.TrimSpace(req.GetMessage())
	if sessionID == "" || message == "" {
		return status.Error(codes.InvalidArgument, "session_id und message sind erforderlich")
	}

	ctx := stream.Context()
	userID := scoutUserID(ctx)
	emitter := &streamEmitter{stream: stream}

	// Everything from here on is reported as an error event rather than as a
	// call failure: the reply may already be half-written when it happens, and
	// the client needs the code to tell a warm-up problem from a real failure.
	if err := s.module.acquireSessionMutation(sessionID, userID); err != nil {
		return emitter.emitError(err)
	}
	defer s.module.releaseSessionMutation(sessionID, userID)

	options := chatOptionsFromProto(req.GetOptions())
	if options.Thinking == "agentic" {
		_, _, _, err := s.module.generateAgenticReply(ctx, userID, sessionID, message, options,
			func(botID, botName string) { _ = emitter.botSelected(botID, botName) },
			emitter.emitAgentEvent,
		)
		if err != nil {
			return emitter.emitError(err)
		}
		return nil
	}

	textEmitter := newStreamingTextEmitter(emitter.textDelta)

	if err := emitter.status("starting"); err != nil {
		return err
	}

	_, botID, _, createdBot, err := s.module.generateReply(ctx, userID, sessionID, message, options,
		func(botID, botName string) { _ = emitter.botSelected(botID, botName) },
		textEmitter.Emit,
		emitter.modelWarmup,
		func(eventType string, data interface{}) error {
			// Whatever the agent reports comes after the text written so far,
			// so the buffered characters go out first.
			if err := textEmitter.Flush(); err != nil {
				return err
			}
			return emitter.emitAgentEvent(eventType, data)
		},
	)
	if err == nil {
		err = textEmitter.Flush()
	}
	if err != nil {
		return emitter.emitError(err)
	}

	if createdBot != nil {
		if sendErr := emitter.botCreated(*createdBot); sendErr != nil {
			return sendErr
		}
	}
	return emitter.done(&scoutv1.StreamDone{
		SessionId:     sessionID,
		ThinkingLevel: normalizeThinkingLevel(req.GetOptions().GetThinkingLevel()),
		ResponseStyle: s.module.responseStyleForBot(userID, botID, req.GetOptions().GetResponseStyle()),
	})
}

// streamEmitter wraps the response stream so each event reads as one line at
// the call site instead of repeating the oneof envelope every time.
type streamEmitter struct {
	stream grpc.ServerStreamingServer[scoutv1.StreamMessageResponse]
}

func (e *streamEmitter) textDelta(chunk string) error {
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_TextDelta{
			TextDelta: &scoutv1.TextDelta{Chunk: chunk},
		},
	})
}

func (e *streamEmitter) reasoningDelta(chunk string) error {
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_ReasoningDelta{
			ReasoningDelta: &scoutv1.ReasoningDelta{Chunk: chunk},
		},
	})
}

func (e *streamEmitter) botSelected(botID, botName string) error {
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_BotSelected{
			BotSelected: &scoutv1.BotSelected{Id: botID, Name: botName},
		},
	})
}

func (e *streamEmitter) botCreated(bot bots.Config) error {
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_BotCreated{
			BotCreated: &scoutv1.BotCreated{Bot: botToProto(bot)},
		},
	})
}

func (e *streamEmitter) status(action string) error {
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_Status{
			Status: &scoutv1.StatusUpdate{Action: action},
		},
	})
}

func (e *streamEmitter) modelWarmup(progress localinference.WarmupProgress) error {
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_ModelWarmup{
			ModelWarmup: warmupToProto(progress),
		},
	})
}

func (e *streamEmitter) done(done *scoutv1.StreamDone) error {
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_Done{Done: done},
	})
}

// emitAgentEvent routes what the agent loop reports. The delegating reply path
// sends its text through this same generic emitter, so the two delta kinds are
// unwrapped back onto their own events rather than travelling as payloads.
func (e *streamEmitter) emitAgentEvent(eventType string, data interface{}) error {
	switch eventType {
	case "text_delta":
		return e.textDelta(chunkOf(data))
	case "reasoning_delta":
		return e.reasoningDelta(chunkOf(data))
	case "model_warmup":
		if progress, ok := data.(localinference.WarmupProgress); ok {
			return e.modelWarmup(progress)
		}
	case "done":
		return e.done(&scoutv1.StreamDone{
			SessionId:     stringField(data, "session_id"),
			ThinkingLevel: stringField(data, "thinking_level"),
			ResponseStyle: stringField(data, "response_style"),
		})
	}

	payload, err := agentPayloadToProto(data)
	if err != nil {
		// The turn itself is fine; only this one report cannot be carried, and
		// dropping it beats failing the whole reply.
		log.Printf("[scout] Agent-Ereignis %q konnte nicht uebertragen werden: %v", eventType, err)
		return nil
	}
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_Agent{
			Agent: &scoutv1.AgentEvent{Type: eventType, Data: payload},
		},
	})
}

// emitError ends the stream with a reason the client can act on. The chat
// failure travels as an event rather than as a call status because the reply
// may already be half-written when it happens.
func (e *streamEmitter) emitError(err error) error {
	_, reason := chatErrorStatus(err)
	return e.stream.Send(&scoutv1.StreamMessageResponse{
		Event: &scoutv1.StreamMessageResponse_Error{
			Error: &scoutv1.StreamError{
				Message:    err.Error(),
				Code:       reason,
				RetryAfter: retryAfterSeconds(reason),
			},
		},
	})
}

// stringField reads one value out of the map an event travelled in.
func stringField(data interface{}, key string) string {
	payload, ok := data.(map[string]interface{})
	if !ok {
		return ""
	}
	value, _ := payload[key].(string)
	return value
}

// chunkOf reads the character out of the map the delegating reply path emits.
func chunkOf(data interface{}) string {
	switch payload := data.(type) {
	case map[string]interface{}:
		if chunk, ok := payload["chunk"].(string); ok {
			return chunk
		}
	case map[string]string:
		return payload["chunk"]
	}
	return ""
}

func (s *grpcService) ListBots(
	ctx context.Context,
	req *scoutv1.ListBotsRequest,
) (*scoutv1.ListBotsResponse, error) {
	userID := scoutUserID(ctx)
	if err := s.module.botStore.EnsureUser(userID); err != nil {
		return nil, status.Error(codes.Internal, "Bots konnten nicht geladen werden")
	}

	stored := s.module.botStore.GetBotsForUser(userID)
	list := make([]*scoutv1.Bot, 0, len(stored))
	for _, bot := range stored {
		list = append(list, botToProto(bot))
	}
	return &scoutv1.ListBotsResponse{Bots: list}, nil
}

func (s *grpcService) SaveBot(
	ctx context.Context,
	req *scoutv1.SaveBotRequest,
) (*scoutv1.SaveBotResponse, error) {
	bot := botFromProto(req.GetBot())
	if strings.TrimSpace(bot.ID) == "" {
		bot.ID = fmt.Sprintf("bot-%d", time.Now().UnixNano())
	}
	if strings.TrimSpace(bot.Name) == "" {
		return nil, status.Error(codes.InvalidArgument, "Name ist erforderlich")
	}

	userID := scoutUserID(ctx)
	if err := s.module.botStore.EnsureUser(userID); err != nil {
		return nil, status.Error(codes.Internal, "Bots konnten nicht geladen werden")
	}
	if err := s.module.botStore.SaveBotForUser(userID, bot); err != nil {
		switch {
		case errors.Is(err, bots.ErrBotBuilderLocked):
			return nil, status.Error(codes.PermissionDenied, err.Error())
		case errors.Is(err, bots.ErrInvalidModelBinding):
			return nil, status.Error(codes.InvalidArgument, err.Error())
		default:
			return nil, status.Error(codes.Internal, err.Error())
		}
	}

	saved, _ := s.module.botStore.GetBotForUser(userID, bot.ID)
	return &scoutv1.SaveBotResponse{Bot: botToProto(saved)}, nil
}

func (s *grpcService) DeleteBot(
	ctx context.Context,
	req *scoutv1.DeleteBotRequest,
) (*scoutv1.DeleteBotResponse, error) {
	id := strings.TrimSpace(req.GetId())
	// The two built-in bots are what a user falls back to, so removing them
	// would leave a session with nothing to answer it.
	if id == "scout" || id == "botbuilder" {
		return nil, status.Error(codes.InvalidArgument, "Standard-Bot kann nicht geloescht werden")
	}

	userID := scoutUserID(ctx)
	if err := s.module.botStore.EnsureUser(userID); err != nil {
		return nil, status.Error(codes.Internal, "Bots konnten nicht geladen werden")
	}
	if err := s.module.botStore.DeleteBotForUser(userID, id); err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	return &scoutv1.DeleteBotResponse{}, nil
}
