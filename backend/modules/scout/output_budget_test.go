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

func TestNormalizeOutputLevel(t *testing.T) {
	cases := map[string]string{
		"":        OutputLevelNormal,
		"normal":  OutputLevelNormal,
		"quatsch": OutputLevelNormal,
		"short":   OutputLevelShort,
		"kurz":    OutputLevelShort,
		" MAX ":   OutputLevelMax,
		"maximum": OutputLevelMax,
	}
	for input, want := range cases {
		if got := normalizeOutputLevel(input); got != want {
			t.Errorf("normalizeOutputLevel(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestResolveOutputBudgetLevels(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	// A local instance with a roomy window: its ceiling is whatever the window
	// has left, so the level is what decides here rather than a model limit.
	window := contextBudget{LimitTokens: 200000, Source: contextSourceLocal}
	budgetFor := func(level string) outputBudget {
		return module.resolveOutputBudget("user", localinference.ProviderLocal, "", "inst-a", level, window, 100)
	}

	if got := budgetFor(OutputLevelShort).MaxTokens; got != outputShortTokens {
		t.Errorf("kurzes Budget = %d, want %d", got, outputShortTokens)
	}
	if got := budgetFor("").MaxTokens; got != outputNormalTokens {
		t.Errorf("normales Budget = %d, want %d", got, outputNormalTokens)
	}

	maximum := budgetFor(OutputLevelMax)
	if want := 200000 - 100 - outputSafetyMarginTokens; maximum.MaxTokens != want {
		t.Errorf("maximales Budget = %d, want %d", maximum.MaxTokens, want)
	}
	if maximum.Capped {
		t.Error("Budget meldet sich als gedeckelt, obwohl das Fenster nahezu leer war")
	}
}

func TestResolveOutputBudgetNeverExceedsTheModelCeiling(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	window := contextBudget{LimitTokens: 200000, Source: contextSourceCatalog}

	// Nothing knows this model, so the fallback ceiling stands in - and a model
	// that only writes that much must not be asked for a longer answer, however
	// the level is set.
	for _, level := range []string{OutputLevelShort, OutputLevelNormal, OutputLevelMax} {
		budget := module.resolveOutputBudget("user", "openrouter", "", "vendor/unbekannt", level, window, 100)
		if budget.MaxTokens > fallbackMaxOutputTokens {
			t.Errorf("Budget fuer %q = %d, ueberschreitet die Modellgrenze %d",
				level, budget.MaxTokens, fallbackMaxOutputTokens)
		}
		if budget.Source != contextSourceAverage {
			t.Errorf("Quelle fuer %q = %q, want %q", level, budget.Source, contextSourceAverage)
		}
	}
}

func TestResolveOutputBudgetIsCappedByRemainingWindow(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	// 8192 window with 7000 tokens of conversation already in it: what is left
	// decides, not what the model would write.
	window := contextBudget{LimitTokens: 8192, Source: contextSourceLocal}

	budget := module.resolveOutputBudget("user", "openrouter", "", "vendor/unbekannt", OutputLevelMax, window, 7000)
	want := 8192 - 7000 - outputSafetyMarginTokens
	if budget.MaxTokens != want {
		t.Errorf("gedeckeltes Budget = %d, want %d", budget.MaxTokens, want)
	}
	if !budget.Capped {
		t.Error("Budget war gedeckelt, meldet es aber nicht")
	}

	// A window that is full to the brim still leaves the model room to answer,
	// because a zero ceiling would be refused outright.
	full := module.resolveOutputBudget("user", "openrouter", "", "vendor/unbekannt", OutputLevelMax, window, 8192)
	if full.MaxTokens != minimumOutputTokens {
		t.Errorf("Budget im vollen Fenster = %d, want %d", full.MaxTokens, minimumOutputTokens)
	}
}

func TestResolveOutputBudgetLocalSharesTheWindow(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	window := contextBudget{LimitTokens: 16384, Source: contextSourceLocal}

	budget := module.resolveOutputBudget("user", localinference.ProviderLocal, "", "inst-a", OutputLevelMax, window, 4000)
	want := 16384 - 4000 - outputSafetyMarginTokens
	if budget.MaxTokens != want || budget.Source != contextSourceLocal {
		t.Errorf("lokales Budget = %+v, want %d/%s", budget, want, contextSourceLocal)
	}
}

// truncatingLocalModels reports that it ran into its output limit for the first
// truncateFor replies, which is how a model that cannot finish in one response
// behaves.
type truncatingLocalModels struct {
	model       localinference.Model
	truncateFor int
	// padCharacters makes each part long enough to eat into the window, which
	// is how a real long answer squeezes out its own continuations.
	padCharacters int

	mu       sync.Mutex
	calls    int
	requests []localinference.ChatRequest
}

func (f *truncatingLocalModels) ReadyLocalModels() []localinference.Model {
	return []localinference.Model{f.model}
}

func (f *truncatingLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	return f.model, nil
}

func (f *truncatingLocalModels) StreamLocalChat(ctx context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	reply, _, err := f.StreamLocalChatWithReason(ctx, instanceID, request, emit)
	return reply, err
}

func (f *truncatingLocalModels) StreamLocalChatWithReason(_ context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, string, error) {
	if instanceID != f.model.InstanceID {
		return "", "", localinference.ErrNotFound
	}
	f.mu.Lock()
	f.calls++
	call := f.calls
	f.requests = append(f.requests, request)
	f.mu.Unlock()

	part := "Teil" + string(rune('0'+call)) + " " + strings.Repeat("x", f.padCharacters)
	if emit != nil {
		if err := emit(part); err != nil {
			return "", "", err
		}
	}
	if call <= f.truncateFor {
		return part, localinference.FinishLength, nil
	}
	return part, "stop", nil
}

func (f *truncatingLocalModels) recorded() []localinference.ChatRequest {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]localinference.ChatRequest(nil), f.requests...)
}

func TestTruncatedAnswerIsContinuedIntoOneReply(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &truncatingLocalModels{
		model:       localinference.Model{InstanceID: "inst-ready", DisplayName: "Lokal", ContextLimit: 16384},
		truncateFor: 2,
	}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	response, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Schreib was Langes",
	})
	if err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	// Two truncated parts plus the one that finished, joined into one answer.
	if want := "Teil1 Teil2 Teil3 "; response.GetReply() != want {
		t.Fatalf("Antwort = %q, want %q", response.GetReply(), want)
	}
	if strings.Contains(response.GetReply(), "abgeschnitten") {
		t.Error("fertige Antwort traegt einen Abschneide-Hinweis")
	}

	requests := local.recorded()
	if len(requests) != 3 {
		t.Fatalf("%d Anfragen, want 3", len(requests))
	}
	// Each continuation hands the model back what it wrote so far.
	second := requests[1].Messages
	if len(second) < 2 {
		t.Fatalf("Fortsetzung ohne Verlauf: %+v", second)
	}
	if last := second[len(second)-1]; last.Role != "user" || !strings.Contains(last.Content, "abgeschnitten") {
		t.Errorf("letzte Nachricht der Fortsetzung = %+v, want Fortsetzungsanweisung", last)
	}
	if resumed := second[len(second)-2]; resumed.Role != "assistant" || resumed.Content != "Teil1 " {
		t.Errorf("Fortsetzung kennt den bisherigen Text nicht: %+v", resumed)
	}
}

func TestStillTruncatedAnswerSaysSo(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	// Never stops on its own, so every continuation runs out too.
	local := &truncatingLocalModels{
		model:       localinference.Model{InstanceID: "inst-ready", DisplayName: "Lokal", ContextLimit: 16384},
		truncateFor: 99,
	}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	response, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Schreib endlos",
	})
	if err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	if !strings.Contains(response.GetReply(), "abgeschnitten") {
		t.Errorf("Antwort ohne Abschneide-Hinweis: %q", response.GetReply())
	}
	if got, want := len(local.recorded()), 1+maxOutputContinuations; got != want {
		t.Errorf("%d Anfragen, want %d", got, want)
	}
}

func TestContinuationStopsWhenTheWindowIsUsedUp(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	// A small window plus parts long enough to fill it: the first answer alone
	// leaves no room for a continuation, so asking for one would only earn a
	// refusal from the provider.
	local := &truncatingLocalModels{
		model:         localinference.Model{InstanceID: "inst-ready", DisplayName: "Lokal", ContextLimit: 4096},
		truncateFor:   99,
		padCharacters: 12000,
	}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	response, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Schreib endlos",
		Options: &scoutv1.ChatOptions{OutputLevel: OutputLevelMax},
	})
	if err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	if got := len(local.recorded()); got != 1 {
		t.Errorf("%d Anfragen, want 1 - die Fortsetzung haette keinen Platz gehabt", got)
	}
	if !strings.Contains(response.GetReply(), "abgeschnitten") {
		t.Error("Antwort ohne Abschneide-Hinweis")
	}
}

func TestOutputLevelReachesTheProvider(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &truncatingLocalModels{
		model:       localinference.Model{InstanceID: "inst-ready", DisplayName: "Lokal", ContextLimit: 200000},
		truncateFor: 0,
	}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Kurz bitte",
		Options: &scoutv1.ChatOptions{OutputLevel: OutputLevelShort},
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	requests := local.recorded()
	if len(requests) != 1 {
		t.Fatalf("%d Anfragen, want 1", len(requests))
	}
	if requests[0].MaxTokens == nil {
		t.Fatal("max_tokens wurde nicht gesetzt")
	}
	if *requests[0].MaxTokens != outputShortTokens {
		t.Errorf("max_tokens = %d, want %d", *requests[0].MaxTokens, outputShortTokens)
	}
}
