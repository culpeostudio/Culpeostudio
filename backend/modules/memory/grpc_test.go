package memorymodule

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"sync"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	memoryv1 "github.com/culpeohq/backend/gen/go/culpeostudio/memory/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/memory"
)

// deriveUserToken builds the per-user token the bearer check expects, the same
// way a tool that was issued one would have received it.
func deriveUserToken(master, userID string) string {
	mac := hmac.New(sha256.New, []byte(master))
	mac.Write([]byte(userID))
	return hex.EncodeToString(mac.Sum(nil))
}

// newTestService calls the service directly, the way the other migrated modules
// test theirs: the interceptors it sits behind on a real listener are covered
// in internal/grpcmw.
func newTestService(t *testing.T) (*grpcService, *MemoryModule) {
	t.Helper()
	module := newTestModule(t)
	return &grpcService{module: module}, module
}

// userContext builds the context an authenticated call carries.
func userContext(userID string) context.Context {
	return grpcmw.ContextWithUserForTest(context.Background(), userID, userID)
}

func requireCode(t *testing.T, err error, want codes.Code) {
	t.Helper()

	if err == nil {
		t.Fatalf("erwartet %s, bekam keinen Fehler", want)
	}
	if got := status.Code(err); got != want {
		t.Fatalf("Statuscode = %s, want %s (%v)", got, want, err)
	}
}

func TestSessionCarriesWhatWasAddedToIt(t *testing.T) {
	service, _ := newTestService(t)
	ctx := userContext("anna")

	created, err := service.CreateSession(ctx, &memoryv1.CreateSessionRequest{
		Project: "culpeostudio",
		Source:  "test",
		Goals:   []string{"Memory ueber gRPC bedienen"},
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	sessionID := created.GetSession().GetId()
	if sessionID == "" {
		t.Fatal("CreateSession hat keine Session-ID geliefert")
	}
	if created.GetSession().GetStatus() != memoryv1.SessionStatus_SESSION_STATUS_ACTIVE {
		t.Fatalf("Status = %s, erwartet ACTIVE", created.GetSession().GetStatus())
	}

	if _, err := service.AddPrompt(ctx, &memoryv1.AddPromptRequest{
		SessionId: sessionID,
		Role:      memoryv1.PromptRole_PROMPT_ROLE_USER,
		Text:      "Wie funktioniert der Viewer?",
	}); err != nil {
		t.Fatalf("AddPrompt: %v", err)
	}

	added, err := service.AddObservation(ctx, &memoryv1.AddObservationRequest{
		SessionId: sessionID,
		Type:      "decision",
		Title:     "Viewer bleibt auf HTTP",
		Narrative: "Ein Browser spricht kein gRPC.",
		Keywords:  []string{"viewer", "http"},
	})
	if err != nil {
		t.Fatalf("AddObservation: %v", err)
	}
	if added.GetObservation().GetLayer() != memoryv1.MemoryLayer_MEMORY_LAYER_PROJECT_DATA {
		t.Fatalf("Layer = %s, erwartet PROJECT_DATA fuer eine ungesetzte Ebene", added.GetObservation().GetLayer())
	}
	if added.GetObservation().GetCategory() != memoryv1.MemoryCategory_MEMORY_CATEGORY_STATUS {
		t.Fatalf("Kategorie = %s, erwartet STATUS fuer eine ungesetzte Kategorie", added.GetObservation().GetCategory())
	}

	session, err := service.GetSession(ctx, &memoryv1.GetSessionRequest{SessionId: sessionID})
	if err != nil {
		t.Fatalf("GetSession: %v", err)
	}
	if got := len(session.GetSession().GetPrompts()); got != 1 {
		t.Fatalf("Prompts = %d, erwartet 1", got)
	}
	if got := len(session.GetSession().GetActiveObservations()); got != 1 {
		t.Fatalf("Beobachtungen = %d, erwartet 1", got)
	}

	found, err := service.Search(ctx, &memoryv1.SearchRequest{Query: "Viewer"})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(found.GetResults()) == 0 {
		t.Fatal("Search hat die Beobachtung nicht gefunden")
	}

	fetched, err := service.GetObservations(ctx, &memoryv1.GetObservationsRequest{
		Ids: []string{added.GetObservation().GetId()},
	})
	if err != nil {
		t.Fatalf("GetObservations: %v", err)
	}
	if got := len(fetched.GetObservations()); got != 1 {
		t.Fatalf("GetObservations = %d, erwartet 1", got)
	}
	if fetched.GetObservations()[0].GetTitle() != "Viewer bleibt auf HTTP" {
		t.Fatalf("falsche Beobachtung: %q", fetched.GetObservations()[0].GetTitle())
	}
}

// The user comes from the credential, never from the request, so one account
// cannot read another's memory.
func TestSessionsStayWithTheirUser(t *testing.T) {
	service, _ := newTestService(t)

	created, err := service.CreateSession(userContext("anna"), &memoryv1.CreateSessionRequest{Project: "culpeostudio"})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	_, err = service.GetSession(userContext("bob"), &memoryv1.GetSessionRequest{
		SessionId: created.GetSession().GetId(),
	})
	requireCode(t, err, codes.NotFound)

	sessions, err := service.ListSessions(userContext("bob"), &memoryv1.ListSessionsRequest{})
	if err != nil {
		t.Fatalf("ListSessions: %v", err)
	}
	if len(sessions.GetSessions()) != 0 {
		t.Fatalf("bob sieht %d fremde Sessions", len(sessions.GetSessions()))
	}
}

func TestGetSessionReportsAMissingOneAsNotFound(t *testing.T) {
	service, _ := newTestService(t)

	_, err := service.GetSession(userContext("anna"), &memoryv1.GetSessionRequest{SessionId: "memsess-gibtsnicht"})
	requireCode(t, err, codes.NotFound)
}

func TestTimelineRequiresASession(t *testing.T) {
	service, _ := newTestService(t)

	_, err := service.GetTimeline(userContext("anna"), &memoryv1.GetTimelineRequest{})
	requireCode(t, err, codes.InvalidArgument)
}

// A change request is a proposal plus a decision. The German wire values the
// store keeps are now an enum, so the round trip has to survive both mappings.
func TestChangeRequestDecisionRoundTrip(t *testing.T) {
	service, _ := newTestService(t)
	ctx := userContext("anna")

	created, err := service.CreateSession(ctx, &memoryv1.CreateSessionRequest{Project: "culpeostudio"})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	added, err := service.AddObservation(ctx, &memoryv1.AddObservationRequest{
		SessionId: created.GetSession().GetId(),
		Category:  memoryv1.MemoryCategory_MEMORY_CATEGORY_CHANGE_REQUEST,
		Title:     "Viewer auf gRPC umstellen",
		Narrative: "Waere ohne Browser-Proxy nicht erreichbar.",
	})
	if err != nil {
		t.Fatalf("AddObservation: %v", err)
	}
	request := added.GetObservation().GetChangeRequest()
	if request == nil {
		t.Fatal("die Kategorie CHANGE_REQUEST hat keinen Antrag erzeugt")
	}
	if request.GetStatus() != memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_OPEN {
		t.Fatalf("Status = %s, erwartet OPEN", request.GetStatus())
	}

	decided, err := service.UpdateChangeRequestStatus(ctx, &memoryv1.UpdateChangeRequestStatusRequest{
		ObservationId: added.GetObservation().GetId(),
		Status:        memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_REJECTED,
		ReasonShort:   "Browser spricht kein gRPC",
	})
	if err != nil {
		t.Fatalf("UpdateChangeRequestStatus: %v", err)
	}
	if got := decided.GetObservation().GetChangeRequest().GetStatus(); got != memoryv1.ChangeRequestStatus_CHANGE_REQUEST_STATUS_REJECTED {
		t.Fatalf("Status = %s, erwartet REJECTED", got)
	}
}

// A list that was not sent must be left alone, and one sent empty must clear
// what is stored. A bare repeated field cannot tell the two apart, which is
// what StringList is for.
func TestMemoryPatchDistinguishesUnsetFromEmpty(t *testing.T) {
	untouched := memoryPatchFromProto(&memoryv1.UpdateMemoryRequest{Id: "memory-1"})
	if untouched.Summary != nil || untouched.Learned != nil || untouched.OpenTasks != nil {
		t.Fatalf("ein leerer Patch aendert etwas: %+v", untouched)
	}

	cleared := memoryPatchFromProto(&memoryv1.UpdateMemoryRequest{
		Id:      "memory-1",
		Summary: stringPtr("neue Zusammenfassung"),
		Learned: &memoryv1.StringList{},
	})
	if cleared.Summary == nil || *cleared.Summary != "neue Zusammenfassung" {
		t.Fatalf("Summary wurde nicht uebernommen: %+v", cleared.Summary)
	}
	if cleared.Learned == nil || len(*cleared.Learned) != 0 {
		t.Fatalf("eine leer gesendete Liste soll leeren, bekam: %+v", cleared.Learned)
	}
	if cleared.OpenTasks != nil {
		t.Fatal("eine nicht gesendete Liste wurde angefasst")
	}
}

func stringPtr(value string) *string { return &value }

func TestRateLimitedGRPCMethodSelectsOnlyCapture(t *testing.T) {
	limited := []string{
		"/" + GRPCServiceName + "/CaptureChatMessage",
		"/" + GRPCServiceName + "/CaptureEvent",
	}
	for _, method := range limited {
		if !RateLimitedGRPCMethod(method) {
			t.Fatalf("%s sollte gedrosselt werden", method)
		}
	}

	open := []string{
		"/" + GRPCServiceName + "/Search",
		"/" + GRPCServiceName + "/GetContext",
		"/culpeostudio.search.v1.SearchService/Search",
	}
	for _, method := range open {
		if RateLimitedGRPCMethod(method) {
			t.Fatalf("%s sollte nicht gedrosselt werden", method)
		}
	}
}

func tokenContext(token, userID string) context.Context {
	pairs := []string{}
	if userID != "" {
		pairs = append(pairs, metadataUserIDKey, userID)
	}
	if len(pairs) == 0 {
		return context.Background()
	}
	return metadata.NewIncomingContext(context.Background(), metadata.Pairs(pairs...))
}

func TestAPITokenActsForTheUserItNames(t *testing.T) {
	const master = "memory-master-token-long-enough-for-hmac"
	module := newTestModuleWithToken(t, master)
	method := "/" + GRPCServiceName + "/Search"

	userID, ok := module.AuthenticateGRPCToken(tokenContext(master, "anna"), method, master)
	if !ok {
		t.Fatal("das Master-Token wurde abgelehnt")
	}
	if userID != "anna" {
		t.Fatalf("Nutzer = %q, erwartet %q", userID, "anna")
	}

	// Without a named user it acts for the module's default user, which is how
	// a loopback install without accounts works.
	userID, ok = module.AuthenticateGRPCToken(tokenContext(master, ""), method, master)
	if !ok || userID != "local" {
		t.Fatalf("Standardnutzer = %q (ok=%v), erwartet %q", userID, ok, "local")
	}
}

// A per-user token names its own user, and naming another in the metadata must
// not move it.
func TestPerUserTokenCannotActForAnotherUser(t *testing.T) {
	const master = "memory-master-token-long-enough-for-hmac"
	module := newTestModuleWithToken(t, master)
	method := "/" + GRPCServiceName + "/Search"

	annasToken := deriveUserToken(master, "anna") + ":anna"

	userID, ok := module.AuthenticateGRPCToken(tokenContext(annasToken, "bob"), method, annasToken)
	if !ok {
		t.Fatal("das Nutzer-Token wurde abgelehnt")
	}
	if userID != "anna" {
		t.Fatalf("Nutzer = %q, erwartet %q", userID, "anna")
	}

	forged := deriveUserToken(master, "anna") + ":bob"
	if _, ok := module.AuthenticateGRPCToken(tokenContext(forged, ""), method, forged); ok {
		t.Fatal("ein auf anna ausgestelltes Token wurde fuer bob akzeptiert")
	}
}

func TestAPITokenIsRejectedElsewhere(t *testing.T) {
	const master = "memory-master-token-long-enough-for-hmac"
	module := newTestModuleWithToken(t, master)

	if _, ok := module.AuthenticateGRPCToken(tokenContext(master, ""), "/culpeostudio.settings.v1.SettingsService/GetSettings", master); ok {
		t.Fatal("das Memory-Token wurde fuer ein anderes Modul akzeptiert")
	}
	if _, ok := module.AuthenticateGRPCToken(tokenContext("falsch", ""), "/"+GRPCServiceName+"/Search", "falsch"); ok {
		t.Fatal("ein falsches Token wurde akzeptiert")
	}
}

// recordingStream stands in for the event stream and keeps everything it was
// sent, so a test can assert on it after the call rather than racing it.
type recordingStream struct {
	grpc.ServerStream

	ctx context.Context

	mu     sync.Mutex
	events []*memoryv1.StreamEventsResponse
}

func (s *recordingStream) Context() context.Context { return s.ctx }

func (s *recordingStream) Send(event *memoryv1.StreamEventsResponse) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.events = append(s.events, event)
	return nil
}

func (s *recordingStream) received() []*memoryv1.StreamEventsResponse {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]*memoryv1.StreamEventsResponse(nil), s.events...)
}

// The hub broadcasts to every subscriber, so the feed itself is what keeps one
// user's memory out of another's.
func TestStreamEventsCarriesOnlyTheCallersEvents(t *testing.T) {
	service, module := newTestService(t)

	ctx, cancel := context.WithCancel(userContext("anna"))
	defer cancel()
	stream := &recordingStream{ctx: ctx}

	done := make(chan error, 1)
	go func() { done <- service.StreamEvents(&memoryv1.StreamEventsRequest{}, stream) }()

	// The stream subscribes inside the call, so the events are republished
	// until one arrives rather than slept towards.
	deadline := time.Now().Add(5 * time.Second)
	for {
		module.hub.Publish("observation_added", &memory.Observation{UserID: "bob", ID: "obs-bob", Title: "bobs Notiz"})
		module.hub.Publish("observation_added", &memory.Observation{UserID: "anna", ID: "obs-anna", Title: "annas Notiz"})
		module.hub.Publish("session_deleted", map[string]string{"user_id": "anna", "session_id": "memsess-1"})
		if len(stream.received()) > 0 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("das Ereignis kam nicht am Stream an")
		}
		time.Sleep(10 * time.Millisecond)
	}
	cancel()
	if err := <-done; err != nil {
		t.Fatalf("StreamEvents: %v", err)
	}

	var sawTypedPayload, sawJSONPayload bool
	for _, event := range stream.received() {
		if observation := event.GetObservation(); observation != nil {
			if observation.GetId() != "obs-anna" {
				t.Fatalf("fremdes Ereignis zugestellt: %s", observation.GetId())
			}
			sawTypedPayload = true
		}
		if data := event.GetData(); data != nil {
			if data.GetFields()["user_id"].GetStringValue() != "anna" {
				t.Fatalf("fremdes JSON-Ereignis zugestellt: %v", data.AsMap())
			}
			sawJSONPayload = true
		}
	}
	if !sawTypedPayload {
		t.Fatal("die typisierte Beobachtung fehlt im Stream")
	}
	if !sawJSONPayload {
		t.Fatal("das Ereignis ohne eigenen Typ fehlt im Stream")
	}
}
