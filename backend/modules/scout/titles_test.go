package scout

import (
	"context"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	scoutv1 "github.com/culpeohq/backend/gen/go/culpeostudio/scout/v1"
	"github.com/culpeohq/backend/internal/localinference"
)

// titlingLocalModels answers a naming request differently from a chat turn, so
// a test can tell the two calls apart and see what the title was drawn from.
type titlingLocalModels struct {
	model localinference.Model
	title string

	mu           sync.Mutex
	requests     []localinference.ChatRequest
	titleRequest string
}

func (f *titlingLocalModels) ReadyLocalModels() []localinference.Model {
	return []localinference.Model{f.model}
}

func (f *titlingLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	return f.model, nil
}

func (f *titlingLocalModels) StreamLocalChat(_ context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	naming := systemPromptOf(request) == sessionTitleSystemPrompt

	f.mu.Lock()
	f.requests = append(f.requests, request)
	if naming {
		for _, message := range request.Messages {
			if message.Role == "user" {
				f.titleRequest = message.Content
			}
		}
	}
	f.mu.Unlock()

	reply := "Antwort"
	if naming {
		reply = f.title
	}
	if emit != nil {
		if err := emit(reply); err != nil {
			return "", err
		}
	}
	return reply, nil
}

func (f *titlingLocalModels) namingCalls() (int, string) {
	f.mu.Lock()
	defer f.mu.Unlock()
	count := 0
	for _, request := range f.requests {
		if systemPromptOf(request) == sessionTitleSystemPrompt {
			count++
		}
	}
	return count, f.titleRequest
}

func newTitlingService(t *testing.T, title string) (*grpcService, *ScoutModule, *titlingLocalModels) {
	t.Helper()
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &titlingLocalModels{
		model: localinference.Model{InstanceID: "inst-ready", DisplayName: "Lokal", ContextLimit: 8192},
		title: title,
	}
	module.SetLocalModels(local)
	return newTestService(t, module), module, local
}

func streamedTitle(stream *recordingStream) string {
	for _, event := range stream.recorded() {
		agent := event.GetAgent()
		if agent == nil || agent.GetType() != "session_title" {
			continue
		}
		fields := agent.GetData().GetFields()
		return fields["title"].GetStringValue()
	}
	return ""
}

func sessionTitleOf(t *testing.T, module *ScoutModule, sessionID string) string {
	t.Helper()
	module.mu.Lock()
	defer module.mu.Unlock()
	session := module.sessions[sessionID]
	if session == nil {
		t.Fatalf("Session %s fehlt", sessionID)
	}
	return session.Title
}

func TestStreamedChatIsNamedByTheModel(t *testing.T) {
	service, module, local := newTitlingService(t, "\"Titel: Postgres im Docker-Compose.\"")

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	sessionID := created.GetSessionId()

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: sessionID, Message: "Wie richte ich Postgres in Docker-Compose ein?",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}

	const want = "Postgres im Docker-Compose"
	if got := streamedTitle(stream); got != want {
		t.Fatalf("gesendeter Titel = %q, want %q", got, want)
	}
	if got := sessionTitleOf(t, module, sessionID); got != want {
		t.Fatalf("gespeicherter Titel = %q, want %q", got, want)
	}
	if got := summarizeSession(module.sessions[sessionID]).Title; got != want {
		t.Fatalf("Titel in der Uebersicht = %q, want %q", got, want)
	}

	// The name is written from both sides of the opening exchange.
	calls, request := local.namingCalls()
	if calls != 1 {
		t.Fatalf("%d Titelanfragen, want 1", calls)
	}
	if !strings.Contains(request, "Postgres in Docker-Compose") || !strings.Contains(request, "Antwort") {
		t.Fatalf("Titelanfrage traegt den Austausch nicht: %q", request)
	}

	// The title event comes after done, so the client is never left waiting for
	// its input to unlock behind a second round trip.
	events := stream.recorded()
	doneAt, titleAt := -1, -1
	for index, event := range events {
		if event.GetDone() != nil {
			doneAt = index
		}
		if agent := event.GetAgent(); agent != nil && agent.GetType() == "session_title" {
			titleAt = index
		}
	}
	if doneAt < 0 || titleAt < doneAt {
		t.Fatalf("Titel-Ereignis (%d) kam nicht nach done (%d)", titleAt, doneAt)
	}
}

func TestNamedChatIsNotRenamedByTheModel(t *testing.T) {
	service, module, local := newTitlingService(t, "Ein neuer Titel")

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	sessionID := created.GetSessionId()
	if _, err := service.RenameSession(context.Background(), &scoutv1.RenameSessionRequest{
		SessionId: sessionID, Title: "Mein Projekt",
	}); err != nil {
		t.Fatalf("RenameSession: %v", err)
	}

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: sessionID, Message: "Hallo",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}

	if calls, _ := local.namingCalls(); calls != 0 {
		t.Fatalf("benannter Chat wurde neu benannt: %d Anfragen", calls)
	}
	if got := sessionTitleOf(t, module, sessionID); got != "Mein Projekt" {
		t.Fatalf("Titel = %q, want %q", got, "Mein Projekt")
	}
}

func TestChatIsNamedOnlyOnce(t *testing.T) {
	service, _, local := newTitlingService(t, "Erster Austausch")

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	for _, message := range []string{"Hallo", "Und weiter?"} {
		if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
			SessionId: created.GetSessionId(), Message: message,
		}, newRecordingStream()); err != nil {
			t.Fatalf("StreamMessage(%q): %v", message, err)
		}
	}

	if calls, _ := local.namingCalls(); calls != 1 {
		t.Fatalf("%d Titelanfragen fuer zwei Runden, want 1", calls)
	}
}

func TestUnusableTitleLeavesTheFallback(t *testing.T) {
	service, module, _ := newTitlingService(t, "\"...\"")

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	sessionID := created.GetSessionId()

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: sessionID, Message: "Wie lese ich eine CSV-Datei?",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}

	if got := streamedTitle(stream); got != "" {
		t.Fatalf("unbrauchbarer Titel wurde gesendet: %q", got)
	}
	if got := sessionTitleOf(t, module, sessionID); got != "" {
		t.Fatalf("unbrauchbarer Titel wurde gespeichert: %q", got)
	}
	if got := summarizeSession(module.sessions[sessionID]).Title; got != "Wie lese ich eine CSV-Datei?" {
		t.Fatalf("Ersatztitel = %q", got)
	}
}

func TestSanitizeSessionTitle(t *testing.T) {
	cases := map[string]string{
		"Postgres im Docker-Compose":                                 "Postgres im Docker-Compose",
		"  \"Titel: Fehler im Login-Flow\"  ":                        "Fehler im Login-Flow",
		"**Migration auf Go 1.25**":                                  "Migration auf Go 1.25",
		"Zwei Zeilen\nund noch ein Kommentar dazu":                   "Zwei Zeilen",
		"<think>kurz ueberlegen</think>\nCSV-Import":                 "CSV-Import",
		"Der Nutzer fragt nach sehr vielen Details zu seinem Aufbau": "Der Nutzer fragt nach sehr vielen Details zu…",
		"   ":     "",
		"\"...\"": "",
	}
	for raw, want := range cases {
		if got := sanitizeSessionTitle(raw); got != want {
			t.Errorf("sanitizeSessionTitle(%q) = %q, want %q", raw, got, want)
		}
	}
}

func TestFallbackSessionTitleSkipsWhatSaysNothing(t *testing.T) {
	cases := map[string]string{
		"Hallo Welt": "Hallo Welt",
		"```dart\nvoid main() {}\n```\nWas macht das hier?": "Was macht das hier?",
		"- Bitte pruefe den Build":                          "Bitte pruefe den Build",
		"\n\n  Warum bricht der Build ab?  ":                "Warum bricht der Build ab?",
	}
	for raw, want := range cases {
		if got := fallbackSessionTitle(raw); got != want {
			t.Errorf("fallbackSessionTitle(%q) = %q, want %q", raw, got, want)
		}
	}

	long := strings.Repeat("Wort ", 30)
	got := fallbackSessionTitle(long)
	if !strings.HasSuffix(got, "…") {
		t.Errorf("langer Titel wurde nicht gekuerzt: %q", got)
	}
	if strings.HasSuffix(strings.TrimSuffix(got, "…"), " ") {
		t.Errorf("Titel endet auf einem Leerzeichen: %q", got)
	}
}
