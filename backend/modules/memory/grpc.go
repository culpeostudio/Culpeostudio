package memorymodule

import (
	"context"
	"crypto/subtle"
	"errors"
	"os"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	memoryv1 "github.com/culpeohq/backend/gen/go/culpeostudio/memory/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memorycapture"
	"github.com/culpeohq/backend/internal/security"
)

// metadataUserIDKey names the user a call with the module's API token acts for.
// It is the metadata counterpart of the X-Memory-User-ID header, and gRPC
// lowercases metadata keys, so it must be written in lower case here.
const metadataUserIDKey = "x-memory-user-id"

// GRPCServiceName is the service every memory method lives under. It is what
// tells an API-token call apart from one aimed at another module.
var GRPCServiceName = memoryv1.MemoryService_ServiceDesc.ServiceName

type grpcService struct {
	memoryv1.UnimplementedMemoryServiceServer
	module *MemoryModule
}

func (m *MemoryModule) RegisterGRPC(server *grpc.Server) {
	memoryv1.RegisterMemoryServiceServer(server, &grpcService{module: m})
}

// RateLimitedGRPCMethod selects the capture methods for throttling. They are
// the ones a chat loop calls on every turn, and each one can write to the
// store, which is what the HTTP capture group was rate limited for.
func RateLimitedGRPCMethod(fullMethod string) bool {
	switch fullMethod {
	case "/" + GRPCServiceName + "/CaptureChatMessage",
		"/" + GRPCServiceName + "/CaptureEvent":
		return true
	default:
		return false
	}
}

// AuthenticateGRPCToken authenticates a call carrying the module's own API
// token rather than a session JWT, and reports the user it acts for. Tools
// outside the app hold that token and have no account to log in with, so this
// is the credential they have.
//
// It mirrors what the HTTP bearer middleware accepted: the master token, which
// acts for the user named in the metadata, or a per-user token of the form
// secret:user, which names its own user and can act for no other.
func (m *MemoryModule) AuthenticateGRPCToken(ctx context.Context, fullMethod, token string) (string, bool) {
	// Only this module's methods. The token says nothing about anyone's right
	// to reach the rest of the backend.
	if !strings.HasPrefix(fullMethod, "/"+GRPCServiceName+"/") {
		return "", false
	}

	master := strings.TrimSpace(m.apiToken)
	token = strings.TrimSpace(token)
	if master == "" || token == "" {
		return "", false
	}

	requested := security.SanitizeUserID(metadataValue(ctx, metadataUserIDKey))
	if requested == "" {
		requested = m.defaultUserID
	}

	if secret, user, found := strings.Cut(token, ":"); found {
		user = security.SanitizeUserID(user)
		if user == "" {
			user = requested
		}
		if !security.VerifyUserToken(master, strings.TrimSpace(secret), user) {
			return "", false
		}
		return user, true
	}

	if subtle.ConstantTimeCompare([]byte(token), []byte(master)) != 1 {
		return "", false
	}
	return requested, true
}

func metadataValue(ctx context.Context, key string) string {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return ""
	}
	values := md.Get(key)
	if len(values) == 0 {
		return ""
	}
	return values[0]
}

// callerID is the user a call acts for. It comes from whichever credential the
// call carried, and never from the request, so no caller can write into
// another user's memory by naming them in a field.
func (m *MemoryModule) callerID(ctx context.Context) string {
	if userID := security.SanitizeUserID(grpcmw.UserIDFromContext(ctx)); userID != "" {
		return userID
	}
	// The fallback the HTTP handlers had: without a named user everything
	// belongs to the single local user, which is how a loopback install
	// without accounts works.
	return "local"
}

// statusFromError maps a store error onto a gRPC code. Only a missing resource
// is distinguished by the store; the rest were rejected requests under HTTP and
// stay that way.
func statusFromError(err error) error {
	switch {
	case errors.Is(err, os.ErrNotExist):
		return status.Error(codes.NotFound, "ressource nicht gefunden")
	case errors.Is(err, memory.ErrCorrectedByUser):
		return status.Error(codes.FailedPrecondition, err.Error())
	default:
		return status.Error(codes.InvalidArgument, err.Error())
	}
}

func (s *grpcService) CreateSession(
	ctx context.Context,
	req *memoryv1.CreateSessionRequest,
) (*memoryv1.CreateSessionResponse, error) {
	session, err := s.module.service.CreateSession(memory.CreateSessionInput{
		UserID:    s.module.callerID(ctx),
		SessionID: req.GetSessionId(),
		Project:   req.GetProject(),
		Source:    req.GetSource(),
		Goals:     req.GetGoals(),
	})
	if err != nil {
		// Opening a session fails on the store, not on the request, which is
		// why this one is Internal where the reads below are not.
		return nil, status.Error(codes.Internal, err.Error())
	}
	return &memoryv1.CreateSessionResponse{Session: sessionToProto(session)}, nil
}

func (s *grpcService) ListSessions(
	ctx context.Context,
	req *memoryv1.ListSessionsRequest,
) (*memoryv1.ListSessionsResponse, error) {
	sessions, err := s.module.service.ListSessionsForUser(s.module.callerID(ctx))
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	return &memoryv1.ListSessionsResponse{Sessions: sessionsToProto(sessions)}, nil
}

func (s *grpcService) GetSession(
	ctx context.Context,
	req *memoryv1.GetSessionRequest,
) (*memoryv1.GetSessionResponse, error) {
	session, err := s.module.service.GetSessionForUser(s.module.callerID(ctx), req.GetSessionId())
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.GetSessionResponse{Session: sessionToProto(session)}, nil
}

func (s *grpcService) DeleteSession(
	ctx context.Context,
	req *memoryv1.DeleteSessionRequest,
) (*memoryv1.DeleteSessionResponse, error) {
	if err := s.module.service.DeleteSessionForUser(s.module.callerID(ctx), req.GetSessionId()); err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.DeleteSessionResponse{}, nil
}

func (s *grpcService) AddPrompt(
	ctx context.Context,
	req *memoryv1.AddPromptRequest,
) (*memoryv1.AddPromptResponse, error) {
	prompt, envelope, err := s.module.service.AddPrompt(req.GetSessionId(), memory.AddPromptInput{
		UserID: s.module.callerID(ctx),
		Role:   promptRoleFromProto(req.GetRole()),
		Text:   req.GetText(),
	})
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.AddPromptResponse{
		Prompt:  promptToProto(prompt),
		Context: contextEnvelopeToProto(envelope),
	}, nil
}

func (s *grpcService) AddObservation(
	ctx context.Context,
	req *memoryv1.AddObservationRequest,
) (*memoryv1.AddObservationResponse, error) {
	input := observationInputFromProto(req)
	input.UserID = s.module.callerID(ctx)
	observation, err := s.module.service.AddObservation(req.GetSessionId(), input)
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.AddObservationResponse{Observation: observationToProto(observation)}, nil
}

func (s *grpcService) CompleteSession(
	ctx context.Context,
	req *memoryv1.CompleteSessionRequest,
) (*memoryv1.CompleteSessionResponse, error) {
	summary, err := s.module.service.CompleteSession(req.GetSessionId(), memory.CompleteSessionInput{
		UserID:    s.module.callerID(ctx),
		Learned:   req.GetLearned(),
		Completed: req.GetCompleted(),
		NextSteps: req.GetNextSteps(),
	})
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.CompleteSessionResponse{Summary: sessionSummaryToProto(summary)}, nil
}

func (s *grpcService) Search(
	ctx context.Context,
	req *memoryv1.SearchRequest,
) (*memoryv1.SearchResponse, error) {
	results, err := s.module.service.Search(req.GetQuery(), memory.SearchFilters{
		UserID:   s.module.callerID(ctx),
		Project:  req.GetProject(),
		Source:   req.GetSource(),
		Layer:    layerFromProto(req.GetLayer()),
		Category: categoryFromProto(req.GetCategory()),
		Type:     req.GetType(),
		Limit:    int(req.GetLimit()),
	})
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.SearchResponse{Results: searchResultsToProto(results)}, nil
}

func (s *grpcService) GetTimeline(
	ctx context.Context,
	req *memoryv1.GetTimelineRequest,
) (*memoryv1.GetTimelineResponse, error) {
	sessionID := strings.TrimSpace(req.GetSessionId())
	if sessionID == "" {
		return nil, status.Error(codes.InvalidArgument, "session_id ist erforderlich")
	}
	observations, err := s.module.service.TimelineForUser(s.module.callerID(ctx), sessionID, memory.TimelineQuery{
		ObservationID: req.GetObservationId(),
		Query:         req.GetQuery(),
		Before:        intOrDefault(req.GetBefore(), 2),
		After:         intOrDefault(req.GetAfter(), 2),
	})
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.GetTimelineResponse{Observations: observationsToProto(observations)}, nil
}

func (s *grpcService) GetObservations(
	ctx context.Context,
	req *memoryv1.GetObservationsRequest,
) (*memoryv1.GetObservationsResponse, error) {
	observations, err := s.module.service.GetObservationsForUser(s.module.callerID(ctx), req.GetIds())
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.GetObservationsResponse{Observations: observationsToProto(observations)}, nil
}

func (s *grpcService) GetContext(
	ctx context.Context,
	req *memoryv1.GetContextRequest,
) (*memoryv1.GetContextResponse, error) {
	envelope, err := s.module.service.BuildContextForUser(
		s.module.callerID(ctx),
		req.GetSessionId(),
		req.GetQuery(),
		intOrDefault(req.GetLimit(), 8),
	)
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.GetContextResponse{Context: contextEnvelopeToProto(envelope)}, nil
}

func (s *grpcService) UpdateChangeRequestStatus(
	ctx context.Context,
	req *memoryv1.UpdateChangeRequestStatusRequest,
) (*memoryv1.UpdateChangeRequestStatusResponse, error) {
	userID := s.module.callerID(ctx)
	observation, err := s.module.service.UpdateChangeRequestStatus(userID, req.GetObservationId(), memory.UpdateChangeRequestInput{
		UserID:      userID,
		Status:      changeRequestStatusFromProto(req.GetStatus()),
		ReasonShort: req.GetReasonShort(),
	})
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.UpdateChangeRequestStatusResponse{Observation: observationToProto(observation)}, nil
}

func (s *grpcService) DeleteObservation(
	ctx context.Context,
	req *memoryv1.DeleteObservationRequest,
) (*memoryv1.DeleteObservationResponse, error) {
	observation, tombstoned, err := s.module.service.DeleteObservationForUser(s.module.callerID(ctx), req.GetId())
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.DeleteObservationResponse{
		Observation: observationToProto(observation),
		Tombstoned:  tombstoned,
	}, nil
}

func (s *grpcService) UpdateMemory(
	ctx context.Context,
	req *memoryv1.UpdateMemoryRequest,
) (*memoryv1.UpdateMemoryResponse, error) {
	item, err := s.module.service.UpdateMemoryForUser(s.module.callerID(ctx), req.GetId(), memoryPatchFromProto(req))
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.UpdateMemoryResponse{Memory: compressedMemoryToProto(item)}, nil
}

func (s *grpcService) CaptureChatMessage(
	ctx context.Context,
	req *memoryv1.CaptureChatMessageRequest,
) (*memoryv1.CaptureChatMessageResponse, error) {
	envelope, err := s.module.capture.CaptureChatMessage(
		s.module.callerID(ctx),
		req.GetSessionId(),
		req.GetProject(),
		req.GetPrompt(),
		req.GetReply(),
	)
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.CaptureChatMessageResponse{Context: contextEnvelopeToProto(envelope)}, nil
}

func (s *grpcService) CaptureEvent(
	ctx context.Context,
	req *memoryv1.CaptureEventRequest,
) (*memoryv1.CaptureEventResponse, error) {
	observation, err := s.module.capture.CaptureEventBus(memorycapture.EventBusInput{
		UserID:    s.module.callerID(ctx),
		SessionID: req.GetSessionId(),
		Project:   req.GetProject(),
		Source:    req.GetSource(),
		Type:      req.GetType(),
		Data:      req.GetData().AsMap(),
	})
	if err != nil {
		return nil, statusFromError(err)
	}
	return &memoryv1.CaptureEventResponse{Observation: observationToProto(observation)}, nil
}

// StreamEvents follows the store for as long as the caller stays connected.
// Where the SSE feed needs a ticket, because EventSource cannot send a header,
// this call carries its credential in metadata like every other.
func (s *grpcService) StreamEvents(
	req *memoryv1.StreamEventsRequest,
	stream grpc.ServerStreamingServer[memoryv1.StreamEventsResponse],
) error {
	ctx := stream.Context()
	userID := s.module.callerID(ctx)

	subscriber := s.module.hub.Subscribe(64)
	defer s.module.hub.Unsubscribe(subscriber)

	for {
		select {
		case <-ctx.Done():
			return nil
		case event, ok := <-subscriber:
			if !ok {
				// The hub closed, which happens on shutdown.
				return nil
			}
			if eventUserID(event) != userID {
				continue
			}
			message, err := eventToProto(event)
			if err != nil {
				// One unconvertible payload does not end the feed, the same
				// way the SSE writer skips one it cannot marshal.
				continue
			}
			if err := stream.Send(message); err != nil {
				return err
			}
		}
	}
}

// intOrDefault keeps what the query parameters did: a value that is not a
// positive number falls back rather than being rejected.
func intOrDefault(value int32, fallback int) int {
	if value > 0 {
		return int(value)
	}
	return fallback
}
