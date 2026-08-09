package scout

import (
	"context"
	"strings"
	"sync"
	"testing"

	"google.golang.org/grpc"

	scoutv1 "github.com/culpeohq/backend/gen/go/culpeostudio/scout/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/modules/spark"
)

// newTestModule builds the chat module with a real Spark agent attached, the
// way the server wires the two.
func newTestModule(t *testing.T, settingsFile ...string) *ScoutModule {
	t.Helper()
	chat := New(settingsFile...)
	attachTestAgent(chat, settingsFile...)
	return chat
}

// attachTestAgent wires an agent onto an existing chat module and returns it,
// so a test can reach past the interface, e.g. to install a memory stub.
func attachTestAgent(chat *ScoutModule, settingsFile ...string) *spark.Module {
	agent := spark.New(settingsFile...)
	agent.SetPlanStore(chat)
	agent.SetProjectDetachedHook(chat.DetachProject)
	chat.SetAgent(agent)
	return agent
}

// newTestService calls the service directly, the way the other migrated modules
// test theirs: the interceptors it sits behind on a real listener are covered
// in internal/grpcmw.
func newTestService(t *testing.T, module *ScoutModule) *grpcService {
	t.Helper()
	return &grpcService{module: module}
}

// userContext builds the context an authenticated call carries, for the tests
// that check one user cannot see another's sessions or bots.
func userContext(userID string) context.Context {
	return grpcmw.ContextWithUserForTest(context.Background(), userID, userID)
}

// recordingStream stands in for the response stream of a streamed reply and
// keeps every event, so a test can assert on the whole exchange after the call
// returns rather than racing it.
type recordingStream struct {
	grpc.ServerStream

	ctx context.Context

	mu     sync.Mutex
	events []*scoutv1.StreamMessageResponse

	// sendErr is returned from Send once it has been set, which is how a test
	// simulates a client that went away mid-reply.
	sendErr error
}

func newRecordingStream() *recordingStream {
	return &recordingStream{ctx: context.Background()}
}

func newRecordingStreamForUser(userID string) *recordingStream {
	return &recordingStream{ctx: userContext(userID)}
}

func (s *recordingStream) Context() context.Context { return s.ctx }

func (s *recordingStream) Send(event *scoutv1.StreamMessageResponse) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.sendErr != nil {
		return s.sendErr
	}
	s.events = append(s.events, event)
	return nil
}

func (s *recordingStream) recorded() []*scoutv1.StreamMessageResponse {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]*scoutv1.StreamMessageResponse(nil), s.events...)
}

// text joins every text delta, which is the reply as the user sees it.
func (s *recordingStream) text() string {
	var builder strings.Builder
	for _, event := range s.recorded() {
		if delta := event.GetTextDelta(); delta != nil {
			builder.WriteString(delta.GetChunk())
		}
	}
	return builder.String()
}

// failure returns the error event that ended the stream, or nil.
func (s *recordingStream) failure() *scoutv1.StreamError {
	for _, event := range s.recorded() {
		if failure := event.GetError(); failure != nil {
			return failure
		}
	}
	return nil
}

func (s *recordingStream) finished() *scoutv1.StreamDone {
	for _, event := range s.recorded() {
		if done := event.GetDone(); done != nil {
			return done
		}
	}
	return nil
}

func (s *recordingStream) createdBot() *scoutv1.Bot {
	for _, event := range s.recorded() {
		if created := event.GetBotCreated(); created != nil {
			return created.GetBot()
		}
	}
	return nil
}

func (s *recordingStream) selectedBot() *scoutv1.BotSelected {
	for _, event := range s.recorded() {
		if selected := event.GetBotSelected(); selected != nil {
			return selected
		}
	}
	return nil
}

func (s *recordingStream) warmupPhases() []string {
	phases := make([]string, 0, 4)
	for _, event := range s.recorded() {
		if warmup := event.GetModelWarmup(); warmup != nil {
			phases = append(phases, warmup.GetPhase())
		}
	}
	return phases
}
