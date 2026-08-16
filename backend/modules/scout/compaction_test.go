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

// recordingLocalModels keeps every request it was asked with, because a
// compacted turn makes two: the summarisation and the reply itself.
type recordingLocalModels struct {
	model localinference.Model

	mu       sync.Mutex
	requests []localinference.ChatRequest
}

func (f *recordingLocalModels) ReadyLocalModels() []localinference.Model {
	return []localinference.Model{f.model}
}

func (f *recordingLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	return f.model, nil
}

func (f *recordingLocalModels) StreamLocalChat(_ context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	f.mu.Lock()
	f.requests = append(f.requests, request)
	f.mu.Unlock()

	reply := "Antwort"
	if emit != nil {
		if err := emit(reply); err != nil {
			return "", err
		}
	}
	return reply, nil
}

func (f *recordingLocalModels) recorded() []localinference.ChatRequest {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]localinference.ChatRequest(nil), f.requests...)
}

// systemPromptOf returns the leading system message every provider path
// prepends to a request.
func systemPromptOf(request localinference.ChatRequest) string {
	for _, message := range request.Messages {
		if message.Role == "system" {
			return message.Content
		}
	}
	return ""
}

func TestEstimateTokens(t *testing.T) {
	cases := map[string]int{
		"":                       0,
		"abcd":                   1,
		"abcde":                  2,
		strings.Repeat("x", 400): 100,
	}
	for text, want := range cases {
		if got := estimateTokens(text); got != want {
			t.Errorf("estimateTokens(%d Zeichen) = %d, want %d", len(text), got, want)
		}
	}

	messages := []chatMessage{{Role: "user", Content: strings.Repeat("x", 400)}}
	if got, want := estimateMessageTokens(messages), 100+tokensPerMessageOverhead; got != want {
		t.Errorf("estimateMessageTokens = %d, want %d", got, want)
	}
}

func TestResolveContextBudgetSources(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))

	local := module.resolveContextBudget("user", localinference.ProviderLocal, "", "inst-a", 8192)
	if local.LimitTokens != 8192 || local.Source != contextSourceLocal {
		t.Fatalf("lokales Budget = %+v, want 8192/%s", local, contextSourceLocal)
	}

	// A local instance the engine has not started yet knows no window, and its
	// instance id means nothing to the hosted catalogue.
	pending := module.resolveContextBudget("user", localinference.ProviderLocal, "", "inst-a", 0)
	if pending.Source != contextSourceAverage {
		t.Fatalf("ungestartetes lokales Budget = %+v, want Quelle %s", pending, contextSourceAverage)
	}

	// Nothing knows this model and the catalogue is empty in a test module, so
	// the fallback stands in for the average.
	unknown := module.resolveContextBudget("user", "openrouter", "", "vendor/unbekannt", 0)
	if unknown.LimitTokens != fallbackContextTokens || unknown.Source != contextSourceAverage {
		t.Fatalf("unbekanntes Budget = %+v, want %d/%s", unknown, fallbackContextTokens, contextSourceAverage)
	}
}

func TestCompactionFoldsOlderTurnsIntoSystemPrompt(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	// A window this small is what a tiny local model has; it makes the
	// conversation below overflow after a handful of turns.
	local := &recordingLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", ModelID: "catalog-id", DisplayName: "Klein lokal", ContextLimit: 512,
	}}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	sessionID := created.GetSessionId()

	// Twelve turns of 200 characters each: over the 512-token window, and over
	// the ten-message floor compaction needs.
	module.mu.Lock()
	session := module.sessions[sessionID]
	for i := 0; i < 12; i++ {
		role := "user"
		if i%2 == 1 {
			role = "assistant"
		}
		session.Messages = append(session.Messages, chatMessage{
			Role: role, Content: strings.Repeat("wort ", 40),
		})
	}
	messageCount := len(session.Messages)
	module.mu.Unlock()

	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: sessionID, Message: "Und jetzt?",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	requests := local.recorded()
	if len(requests) != 2 {
		t.Fatalf("erwartet Verdichtung + Antwort, bekam %d Anfragen", len(requests))
	}
	if prompt := systemPromptOf(requests[0]); prompt != compactionSystemPrompt {
		t.Fatalf("erste Anfrage war keine Verdichtung: %q", prompt)
	}
	if prompt := systemPromptOf(requests[1]); !strings.Contains(prompt, compactionRecallPreamble) {
		t.Fatalf("Antwort-Anfrage traegt keinen verdichteten Verlauf: %q", prompt)
	}

	module.mu.Lock()
	session = module.sessions[sessionID]
	summary := session.Summary
	summarizedThrough := session.SummarizedThrough
	compactions := session.Compactions
	stored := len(session.Messages)
	module.mu.Unlock()

	if strings.TrimSpace(summary) == "" {
		t.Fatal("Zusammenfassung wurde nicht gespeichert")
	}
	if want := messageCount - compactionKeepRecent; summarizedThrough != want {
		t.Fatalf("SummarizedThrough = %d, want %d", summarizedThrough, want)
	}
	if compactions != 1 {
		t.Fatalf("Compactions = %d, want 1", compactions)
	}
	// The user keeps the full transcript; only the model sees the folded one.
	if want := messageCount + 2; stored != want {
		t.Fatalf("gespeicherte Nachrichten = %d, want %d", stored, want)
	}
}

func TestCompactionSkippedForShortConversation(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &recordingLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", DisplayName: "Klein lokal", ContextLimit: 512,
	}}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Hallo",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	if requests := local.recorded(); len(requests) != 1 {
		t.Fatalf("kurzer Chat wurde verdichtet: %d Anfragen", len(requests))
	}
}

func TestGetHistoryReportsContextUsage(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &recordingLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", DisplayName: "Lokal", ContextLimit: 8192,
	}}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Hallo",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	usage := history.GetContextUsage()
	if usage.GetLimitTokens() != 8192 || usage.GetSource() != contextSourceLocal {
		t.Fatalf("Kontextauslastung = %+v, want 8192/%s", usage, contextSourceLocal)
	}
	if usage.GetUsedTokens() <= 0 {
		t.Fatalf("verbrauchte Tokens = %d, want > 0", usage.GetUsedTokens())
	}
}

func TestStreamMessageEmitsContextUsage(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &recordingLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", DisplayName: "Lokal", ContextLimit: 8192,
	}}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(), Message: "Hallo",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}

	var readings []*scoutv1.ContextUsage
	for _, event := range stream.recorded() {
		if usage := event.GetContextUsage(); usage != nil {
			readings = append(readings, usage)
		}
	}
	if len(readings) < 2 {
		t.Fatalf("erwartet Messung vor und nach der Antwort, bekam %d", len(readings))
	}
	first, last := readings[0], readings[len(readings)-1]
	if last.GetLimitTokens() != 8192 || last.GetSource() != contextSourceLocal {
		t.Fatalf("letzte Messung = %+v, want 8192/%s", last, contextSourceLocal)
	}
	if last.GetUsedTokens() <= first.GetUsedTokens() {
		t.Fatalf("Auslastung stieg nicht mit der Antwort: %d -> %d", first.GetUsedTokens(), last.GetUsedTokens())
	}
}
