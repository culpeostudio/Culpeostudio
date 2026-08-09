package scout

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	scoutv1 "github.com/culpeohq/backend/gen/go/culpeostudio/scout/v1"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/modules/scout/bots"
)

func requireCode(t *testing.T, err error, want codes.Code) {
	t.Helper()

	if err == nil {
		t.Fatalf("erwartet %s, bekam keinen Fehler", want)
	}
	if got := status.Code(err); got != want {
		t.Fatalf("Statuscode = %s, want %s (%v)", got, want, err)
	}
}

func writeSettings(t *testing.T, contents string) string {
	t.Helper()

	dir := t.TempDir()
	path := filepath.Join(dir, "settings.json")
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatalf("Einstellungen schreiben: %v", err)
	}
	return path
}

func TestScoutLocalEngineSessionAndMessage(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &fakeLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", ModelID: "catalog-id", DisplayName: "Qwythos lokal", ContextLimit: 8192,
	}}
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if created.GetProvider() != "local" || created.GetInstanceId() != "inst-ready" ||
		created.GetContextLimit() != 8192 {
		t.Fatalf("unerwartete lokale Session: %+v", created)
	}

	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Hallo",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}
	if len(local.requestSeen.Messages) < 2 ||
		local.requestSeen.Messages[0].Role != "system" ||
		local.requestSeen.Messages[len(local.requestSeen.Messages)-1].Content != "Hallo" {
		t.Fatalf("Engine bekam System-Prompt und Nachricht nicht: %#v", local.requestSeen.Messages)
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if history.GetModelRef() != "local:inst-ready" || history.GetProvider() != "local" ||
		history.GetDisplayName() != "Qwythos lokal" || history.GetContextLimit() != 8192 {
		t.Fatalf("Verlauf verlor die Modell-Metadaten: %+v", history)
	}
}

func TestScoutLocalEngineSessionReportsNotFoundAndNotReady(t *testing.T) {
	for _, tc := range []struct {
		name string
		err  error
		want codes.Code
	}{
		{name: "not found", err: localinference.ErrNotFound, want: codes.NotFound},
		{name: "not ready", err: localinference.ErrNotReady, want: codes.FailedPrecondition},
	} {
		t.Run(tc.name, func(t *testing.T) {
			module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
			module.SetLocalModels(&fakeLocalModels{resolveErr: tc.err})
			service := newTestService(t, module)

			_, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
				Provider: "local", ModelId: "inst-x",
			})
			requireCode(t, err, tc.want)
		})
	}
}

// The code strings survive the move: the client dispatches on them to tell a
// warm-up problem from a real failure.
func TestChatErrorStatusKeepsTheClientFacingCodes(t *testing.T) {
	for _, tc := range []struct {
		err  error
		code codes.Code
		want string
	}{
		{localinference.ErrContextLimit, codes.InvalidArgument, "context_length_exceeded"},
		{localinference.ErrGuardRejected, codes.Unavailable, "resource_guard_rejected"},
		{localinference.ErrQueueTimeout, codes.DeadlineExceeded, "model_queue_timeout"},
		{localinference.ErrWarmupCanceled, codes.Aborted, "model_warmup_canceled"},
		{localinference.ErrInferenceBusy, codes.ResourceExhausted, "local_inference_busy"},
		{errScoutSessionBusy, codes.ResourceExhausted, "session_busy"},
		{errModelBindingMissing, codes.NotFound, "model_binding_missing"},
	} {
		code, reason := chatErrorStatus(tc.err)
		if code != tc.code || reason != tc.want {
			t.Fatalf("%v => (%s,%s), want (%s,%s)", tc.err, code, reason, tc.code, tc.want)
		}
	}
}

func TestScoutRejectsConcurrentMutationOfSameSession(t *testing.T) {
	local := &blockingLocalModels{
		model:   localinference.Model{InstanceID: "serialized", DisplayName: "Serialized", ContextLimit: 2048},
		started: make(chan struct{}),
		release: make(chan struct{}),
	}
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	module.SetLocalModels(local)
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:serialized",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	sessionID := created.GetSessionId()

	firstDone := make(chan error, 1)
	go func() {
		_, sendErr := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
			SessionId: sessionID, Message: "first",
		})
		firstDone <- sendErr
	}()

	select {
	case <-local.started:
	case <-time.After(2 * time.Second):
		t.Fatal("erste Anfrage erreichte die Modellgenerierung nicht")
	}

	// A second turn on the same session is refused while the first one runs,
	// and says how long to wait rather than failing the call outright.
	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: sessionID, Message: "duplicate",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	failure := stream.failure()
	if failure == nil || failure.GetCode() != "session_busy" || failure.GetRetryAfter() != 1 {
		t.Fatalf("gleichzeitige Anfrage meldete %+v", failure)
	}

	close(local.release)
	select {
	case err := <-firstDone:
		if err != nil {
			t.Fatalf("erste Anfrage: %v", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("erste Anfrage endete nach dem Freigeben nicht")
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{SessionId: sessionID})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if len(history.GetMessages()) != 2 {
		t.Fatalf("abgewiesene Anfrage veraenderte den Verlauf: %+v", history.GetMessages())
	}
}

func TestScoutInferenceBusyIsReportedAsExhausted(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	module.SetLocalModels(&fakeLocalModels{
		model:     localinference.Model{InstanceID: "busy", DisplayName: "Busy", ContextLimit: 2048},
		streamErr: localinference.ErrInferenceBusy,
	})
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:busy",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	_, err = service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "hello",
	})
	requireCode(t, err, codes.ResourceExhausted)

	// The same condition on the streamed path carries the wait as a field, the
	// way the Retry-After header did.
	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(), Message: "hello",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	failure := stream.failure()
	if failure == nil || failure.GetCode() != "local_inference_busy" || failure.GetRetryAfter() != 120 {
		t.Fatalf("erwartete Wartezeit im Fehlerereignis, bekam %+v", failure)
	}
}

func TestScoutCreateMessageAndHistory(t *testing.T) {
	service := newTestService(t, newTestModule(t))

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelId: "scout-v1",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	reply, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Hallo",
	})
	if err != nil {
		t.Fatalf("SendMessage: %v", err)
	}
	if reply.GetReply() == "" {
		t.Fatal("erwartete eine nicht-leere Antwort")
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if len(history.GetMessages()) != 2 {
		t.Fatalf("erwartete 2 Verlaufseintraege, bekam %d", len(history.GetMessages()))
	}
}

func TestScoutMessageRequiresSessionAndText(t *testing.T) {
	service := newTestService(t, newTestModule(t))

	_, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{})
	requireCode(t, err, codes.InvalidArgument)

	// The streamed path rejects the same thing as a call failure: an empty
	// request is a programming error, not a chat condition.
	streamErr := service.StreamMessage(&scoutv1.StreamMessageRequest{}, newRecordingStream())
	requireCode(t, streamErr, codes.InvalidArgument)
}

func TestScoutEditMessageTruncatesHistoryAndRegenerates(t *testing.T) {
	service := newTestService(t, newTestModule(t))

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelId: "scout-v1",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	sessionID := created.GetSessionId()

	for _, message := range []string{"erste frage", "zweite frage"} {
		if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
			SessionId: sessionID, Message: message,
		}); err != nil {
			t.Fatalf("SendMessage(%q): %v", message, err)
		}
	}

	editIndex := int32(0)
	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: sessionID,
		Message:   "bearbeitete frage",
		Options:   &scoutv1.ChatOptions{EditMessageIndex: &editIndex},
	}); err != nil {
		t.Fatalf("bearbeitete Nachricht: %v", err)
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{SessionId: sessionID})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if len(history.GetMessages()) != 2 {
		t.Fatalf("erwartete gekuerzten Verlauf mit 2 Eintraegen, bekam %d", len(history.GetMessages()))
	}
	if history.GetMessages()[0].GetContent() != "bearbeitete frage" {
		t.Fatalf("erste Nachricht wurde nicht ersetzt: %q", history.GetMessages()[0].GetContent())
	}
}

// An edit index of zero has to be distinguishable from "no edit", which is why
// the field is optional: without it every message would rewrite the history
// from its first turn.
func TestScoutOmittedEditIndexAppends(t *testing.T) {
	service := newTestService(t, newTestModule(t))

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{ModelId: "scout-v1"})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	for _, message := range []string{"erste", "zweite"} {
		if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
			SessionId: created.GetSessionId(),
			Message:   message,
			Options:   &scoutv1.ChatOptions{},
		}); err != nil {
			t.Fatalf("SendMessage(%q): %v", message, err)
		}
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if len(history.GetMessages()) != 4 {
		t.Fatalf("ohne edit_message_index muss angehaengt werden, Verlauf hat %d Eintraege",
			len(history.GetMessages()))
	}
}

func TestScoutStreamActiveOpenRouterModel(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/chat/completions" {
			http.NotFound(w, r)
			return
		}
		if r.Header.Get("Authorization") != "Bearer mock-token" {
			t.Errorf("unerwarteter Authorization-Header %q", r.Header.Get("Authorization"))
		}
		body, _ := io.ReadAll(r.Body)
		if !strings.Contains(string(body), "Thinking: Dual") || !strings.Contains(string(body), "Stil: Kritisch") {
			t.Errorf("Thinking-/Stil-Anweisungen fehlen im Provider-Payload: %s", body)
		}
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\"Hallo\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\" Welt\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	module := newTestModule(t, writeSettings(t, `{"openrouter_token":"mock-token"}`))
	module.orAPIBase = providerServer.URL
	if err := module.botStore.SaveBot(bots.Config{
		ID:            "critic",
		Name:          "Critic",
		SystemPrompt:  "Du bist ein kritischer Bot.",
		Keywords:      []string{"hi"},
		ResponseStyle: "critical",
	}); err != nil {
		t.Fatalf("kritischen Bot speichern: %v", err)
	}
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("aktives Modell starten: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: active.ModelRef,
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(),
		Message:   "Hi",
		Options:   &scoutv1.ChatOptions{ThinkingLevel: "deep", ResponseStyle: "critical"},
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	// The reply arrives one grapheme per event, which is what makes the text
	// appear character by character in the UI.
	if got := stream.text(); got != "Hallo Welt" {
		t.Fatalf("gestreamter Text = %q", got)
	}
	if stream.finished() == nil {
		t.Fatal("Stream endete ohne done-Ereignis")
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if len(history.GetMessages()) != 2 || history.GetMessages()[1].GetContent() != "Hallo Welt" {
		t.Fatalf("gestreamte Antwort fehlt im Verlauf: %+v", history.GetMessages())
	}
}

func TestScoutStreamProviderErrorDoesNotSaveAssistantReply(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "model unavailable", http.StatusNotFound)
	}))
	defer providerServer.Close()

	module := newTestModule(t, writeSettings(t, `{"openrouter_token":"mock-token"}`))
	module.orAPIBase = providerServer.URL
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("aktives Modell starten: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: active.ModelRef,
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(), Message: "Hi",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	failure := stream.failure()
	if failure == nil || failure.GetCode() != "provider_error" {
		t.Fatalf("ein 404 ohne Bindung muss provider_error bleiben: %+v", failure)
	}

	history, err := service.GetHistory(context.Background(), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if len(history.GetMessages()) != 0 {
		t.Fatalf("nach einem Provider-Fehler darf nichts gespeichert sein: %+v", history.GetMessages())
	}
}

func TestScoutStreamOpenRouterUserNotFoundShowsActionableError(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = io.WriteString(w, `{"error":{"message":"User not found.","code":401}}`)
	}))
	defer providerServer.Close()

	module := newTestModule(t, writeSettings(t, `{"openrouter_token":"mock-token"}`))
	module.orAPIBase = providerServer.URL
	active, err := module.activeModels.Start("openrouter", "google/gemma-4-26b-a4b-it:free", "Gemma")
	if err != nil {
		t.Fatalf("aktives Modell starten: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: active.ModelRef,
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(), Message: "Hi",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	failure := stream.failure()
	if failure == nil {
		t.Fatal("Stream endete ohne Fehlerereignis")
	}
	if !strings.Contains(failure.GetMessage(), "OpenRouter API-Key ist ungueltig oder gehoert zu keinem OpenRouter-Konto") {
		t.Fatalf("erwartete umsetzbare OpenRouter-Meldung, bekam %q", failure.GetMessage())
	}
	if strings.Contains(failure.GetMessage(), "User not found.") {
		t.Fatalf("rohes Provider-JSON darf nicht durchgereicht werden: %q", failure.GetMessage())
	}
}

func TestScoutBotBuilderAutoSavesGeneratedBotAndHidesMarker(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/chat/completions" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/event-stream")
		reply := `Erstellt. Du findest den Bot jetzt in der Verwaltung.
[SAVE_BOT: {"name":"EhrlichBot","system_prompt":"Du bist ein direkter Devil-Advocate. Zerlege schwache Argumente sachlich und gib konkrete Verbesserungen.","keywords":["ehrlich","devil advocate","kritik"],"is_default":false}]`
		_, _ = io.WriteString(w, `data: {"choices":[{"delta":{"content":`+strconv.Quote(reply)+`}}]}`+"\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	module := newTestModule(t, writeSettings(t, `{"openrouter_token":"mock-token"}`))
	module.orAPIBase = providerServer.URL
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("aktives Modell starten: %v", err)
	}
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: active.ModelRef,
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	stream := newRecordingStream()
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(),
		Message:   "botbuilder bau mir einen ehrlichen devil advocate",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}

	text := stream.text()
	if strings.Contains(text, "SAVE_BOT") {
		t.Fatalf("der Speicher-Marker muss verborgen bleiben: %q", text)
	}
	if !strings.HasPrefix(text, "Erstellt.") {
		t.Fatalf("gestreamter Text = %q", text)
	}

	// The bot has to be announced only after the text it belongs to, so the
	// user reads the explanation before the notification appears.
	recorded := stream.recorded()
	firstDelta, createdAt := -1, -1
	for index, event := range recorded {
		if firstDelta < 0 && event.GetTextDelta() != nil {
			firstDelta = index
		}
		if createdAt < 0 && event.GetBotCreated() != nil {
			createdAt = index
		}
	}
	if firstDelta < 0 || createdAt < 0 || firstDelta > createdAt {
		t.Fatalf("erwartete Zeichen-Deltas vor bot_created, bekam %d und %d", firstDelta, createdAt)
	}
	if stream.createdBot().GetName() != "EhrlichBot" {
		t.Fatalf("bot_created nannte %q", stream.createdBot().GetName())
	}

	list, err := service.ListBots(context.Background(), &scoutv1.ListBotsRequest{})
	if err != nil {
		t.Fatalf("ListBots: %v", err)
	}
	found := false
	for _, bot := range list.GetBots() {
		if bot.GetName() == "EhrlichBot" {
			found = true
			break
		}
	}
	if !found {
		t.Fatalf("erzeugter Bot fehlt in der Verwaltung: %+v", list.GetBots())
	}
}

func TestScoutBotsManagementAndKeywordRouting(t *testing.T) {
	module := newTestModule(t, writeSettings(t, `{}`))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	service := newTestService(t, module)

	list, err := service.ListBots(context.Background(), &scoutv1.ListBotsRequest{})
	if err != nil {
		t.Fatalf("ListBots: %v", err)
	}
	if len(list.GetBots()) == 0 {
		t.Fatal("erwartete eine nicht-leere Bot-Liste")
	}

	if _, err := service.SaveBot(context.Background(), &scoutv1.SaveBotRequest{
		Bot: &scoutv1.Bot{
			Id:           "mathbot",
			Name:         "MathBot",
			SystemPrompt: "Du bist ein Mathe-Experte.",
			Keywords:     []string{"mathe", "rechnen"},
		},
	}); err != nil {
		t.Fatalf("SaveBot: %v", err)
	}

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{ModelId: "mock"})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	reply, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "Kannst du mir bei Mathe helfen?",
	})
	if err != nil {
		t.Fatalf("SendMessage: %v", err)
	}
	if reply.GetBotId() != "mathbot" || reply.GetBotName() != "MathBot" {
		t.Fatalf("Stichwort waehlte %q/%q", reply.GetBotId(), reply.GetBotName())
	}

	if _, err := service.DeleteBot(context.Background(), &scoutv1.DeleteBotRequest{Id: "mathbot"}); err != nil {
		t.Fatalf("DeleteBot: %v", err)
	}
}

func TestScoutBotBuilderIsLocked(t *testing.T) {
	module := newTestModule(t, writeSettings(t, `{}`))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	service := newTestService(t, module)

	_, err := service.SaveBot(context.Background(), &scoutv1.SaveBotRequest{
		Bot: &scoutv1.Bot{
			Id:            "botbuilder",
			Name:          "Bot-Builder",
			SystemPrompt:  "Manipulated prompt",
			Keywords:      []string{"locked"},
			ResponseStyle: "critical",
		},
	})
	requireCode(t, err, codes.PermissionDenied)

	list, err := service.ListBots(context.Background(), &scoutv1.ListBotsRequest{})
	if err != nil {
		t.Fatalf("ListBots: %v", err)
	}
	found := false
	for _, bot := range list.GetBots() {
		if bot.GetId() == "botbuilder" {
			found = true
			if !strings.Contains(bot.GetSystemPrompt(), "gesperrt") {
				t.Fatalf("erwartete den gesperrten Standard-Prompt, bekam %q", bot.GetSystemPrompt())
			}
			break
		}
	}
	if !found {
		t.Fatal("botbuilder fehlt in der Bot-Liste")
	}
}

func TestScoutIsolatesBotsAndSessionsByUser(t *testing.T) {
	module := newTestModule(t, writeSettings(t, `{}`))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	service := newTestService(t, module)

	if _, err := service.SaveBot(userContext("Alice"), &scoutv1.SaveBotRequest{
		Bot: &scoutv1.Bot{
			Id: "alice-only", Name: "Alice Only", SystemPrompt: "secret", Keywords: []string{"alice"},
		},
	}); err != nil {
		t.Fatalf("SaveBot fuer Alice: %v", err)
	}

	bobBots, err := service.ListBots(userContext("bob"), &scoutv1.ListBotsRequest{})
	if err != nil {
		t.Fatalf("ListBots fuer bob: %v", err)
	}
	for _, bot := range bobBots.GetBots() {
		if bot.GetId() == "alice-only" {
			t.Fatal("Alices Bot ist in Bobs Namensraum sichtbar")
		}
	}

	// The user id is compared case-insensitively, so the same account reaches
	// its session however the token spelled the name.
	created, err := service.CreateSession(userContext("ALICE"), &scoutv1.CreateSessionRequest{ModelId: "stub"})
	if err != nil {
		t.Fatalf("CreateSession fuer ALICE: %v", err)
	}
	sessionID := created.GetSessionId()

	_, err = service.GetHistory(userContext("bob"), &scoutv1.GetHistoryRequest{SessionId: sessionID})
	requireCode(t, err, codes.NotFound)

	_, err = service.SendMessage(userContext("bob"), &scoutv1.SendMessageRequest{
		SessionId: sessionID, Message: "steal",
	})
	requireCode(t, err, codes.NotFound)

	bobStream := newRecordingStreamForUser("bob")
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: sessionID, Message: "steal",
	}, bobStream); err != nil {
		t.Fatalf("StreamMessage fuer bob: %v", err)
	}
	if failure := bobStream.failure(); failure == nil || failure.GetCode() != "session_not_found" {
		t.Fatalf("fremde Session muss abgewiesen werden, bekam %+v", failure)
	}

	if _, err := service.SendMessage(userContext("alice"), &scoutv1.SendMessageRequest{
		SessionId: sessionID, Message: "same account despite case",
	}); err != nil {
		t.Fatalf("Besitzer in Kleinschreibung: %v", err)
	}
}

func TestLockedBotLocalBindingWarmsAndForwardsOriginalMessageOnce(t *testing.T) {
	local := &fakeWarmupLocalModels{model: localinference.Model{
		InstanceID: "inst-warm", ModelID: "catalog", DisplayName: "Warm Local", ContextLimit: 4096,
	}}
	module := newTestModule(t, writeSettings(t, `{}`))
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if err := module.botStore.SaveBotForUser("alice", bots.Config{
		ID: "bound", Name: "Bound", SystemPrompt: "bound prompt",
		ModelBinding: &bots.ModelBinding{Kind: "local", InstanceID: "inst-warm", DisplayName: "Warm Local"},
	}); err != nil {
		t.Fatalf("gebundenen Bot speichern: %v", err)
	}
	if err := module.botStore.SaveBotForUser("alice", bots.Config{
		ID: "rival", Name: "Rival", SystemPrompt: "rival prompt", Keywords: []string{"switch-now"},
	}); err != nil {
		t.Fatalf("Rivalen speichern: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(userContext("Alice"), &scoutv1.CreateSessionRequest{
		BotId: "bound", ModelId: "ignored",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if created.GetLockedBotId() != "bound" || created.GetProvider() != "local" {
		t.Fatalf("gesperrte Bindung fehlt in der Session: %+v", created)
	}

	original := "switch-now but stay locked"
	stream := newRecordingStreamForUser("Alice")
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(), Message: original,
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}

	placements := make([]string, 0, 2)
	for _, event := range stream.recorded() {
		if warmup := event.GetModelWarmup(); warmup != nil {
			placements = append(placements, warmup.GetPlacement())
		}
	}
	if len(placements) == 0 || placements[0] != "gpu" {
		t.Fatalf("Warmlauf-Fortschritt fehlt im Stream: %v", placements)
	}
	if selected := stream.selectedBot(); selected == nil || selected.GetId() != "bound" {
		t.Fatalf("das Stichwort hat den gesperrten Bot verdraengt: %+v", selected)
	}

	local.mu.Lock()
	ensureCalls, streamCalls := local.ensureCalls, local.streamCalls
	seen := append([]string(nil), local.seenUserMessages...)
	local.mu.Unlock()
	if ensureCalls != 1 || streamCalls != 1 {
		t.Fatalf("ensure=%d stream=%d, want je genau 1", ensureCalls, streamCalls)
	}
	if len(seen) != 1 || seen[0] != original {
		t.Fatalf("die urspruengliche Nachricht ging nicht genau einmal raus: %#v", seen)
	}

	history, err := service.GetHistory(userContext("alice"), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if history.GetModelRef() != "local:inst-warm" || history.GetDisplayName() != "Warm Local" ||
		history.GetContextLimit() != 4096 {
		t.Fatalf("gebundene Modell-Metadaten wurden nicht gespeichert: %+v", history)
	}
}

func TestAgenticLockedLocalBindingUsesWarmupPipeline(t *testing.T) {
	local := &fakeWarmupLocalModels{model: localinference.Model{
		InstanceID: "agentic-local", DisplayName: "Agentic Local", ContextLimit: 4096,
	}}
	module := newTestModule(t, writeSettings(t, `{}`))
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if err := module.botStore.SaveBotForUser("alice", bots.Config{
		ID: "agentic-bound", Name: "Agentic Bound", SystemPrompt: "bound",
		ModelBinding: &bots.ModelBinding{Kind: "local", InstanceID: "agentic-local"},
	}); err != nil {
		t.Fatalf("gebundenen Bot speichern: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{
		BotId: "agentic-bound",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	original := "agentic must honor binding"
	stream := newRecordingStreamForUser("alice")
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(),
		Message:   original,
		Options:   &scoutv1.ChatOptions{ThinkingLevel: "agentic"},
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	if len(stream.warmupPhases()) == 0 || stream.text() == "" || stream.finished() == nil {
		t.Fatalf("der gebundene agentische Stream ist unvollstaendig: %d Ereignisse", len(stream.recorded()))
	}

	local.mu.Lock()
	ensureCalls, streamCalls := local.ensureCalls, local.streamCalls
	seen := append([]string(nil), local.seenUserMessages...)
	local.mu.Unlock()
	if ensureCalls != 1 || streamCalls != 1 || len(seen) != 1 || seen[0] != original {
		t.Fatalf("gebundene agentische Weiterleitung ensure=%d stream=%d seen=%#v", ensureCalls, streamCalls, seen)
	}
}

func TestAgenticMissingLockedBindingReturnsStructuredError(t *testing.T) {
	local := &fakeWarmupLocalModels{ready: true, model: localinference.Model{
		InstanceID: "bound-then-removed", DisplayName: "Removed", ContextLimit: 4096,
	}}
	module := newTestModule(t, writeSettings(t, `{}`))
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if err := module.botStore.SaveBotForUser("alice", bots.Config{
		ID: "removed-bound", Name: "Removed Bound", SystemPrompt: "bound",
		ModelBinding: &bots.ModelBinding{Kind: "local", InstanceID: "bound-then-removed"},
	}); err != nil {
		t.Fatalf("gebundenen Bot speichern: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{
		BotId: "removed-bound",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	local.mu.Lock()
	local.model.InstanceID = "different-instance"
	local.mu.Unlock()

	stream := newRecordingStreamForUser("alice")
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(),
		Message:   "hello",
		Options:   &scoutv1.ChatOptions{ThinkingLevel: "agentic"},
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	failure := stream.failure()
	if failure == nil || failure.GetCode() != "model_binding_missing" {
		t.Fatalf("das fehlende gebundene Modell ergab keinen strukturierten Fehler: %+v", failure)
	}
	if strings.Contains(stream.text(), "warm reply") {
		t.Fatalf("die fehlende Bindung fiel stillschweigend durch: %q", stream.text())
	}
}

func TestPersistedInvalidBindingReturnsStructuredSessionError(t *testing.T) {
	settingsPath := writeSettings(t, `{}`)
	stored := bots.StoreFile{
		Version: bots.StoreSchemaVersion,
		Users: map[string]bots.StoreUser{
			"alice": {Bots: []bots.Config{{
				ID: "invalid-bound", Name: "Invalid Bound", SystemPrompt: "bound", ResponseStyle: "balanced",
				ModelBinding: &bots.ModelBinding{Kind: "api", Provider: "removed-provider", ModelID: "vendor/model"},
			}}},
		},
	}
	payload, err := json.Marshal(stored)
	if err != nil {
		t.Fatalf("Bots serialisieren: %v", err)
	}
	if err := os.WriteFile(filepath.Join(filepath.Dir(settingsPath), "bots.json"), payload, 0o600); err != nil {
		t.Fatalf("Bots schreiben: %v", err)
	}

	module := newTestModule(t, settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	service := newTestService(t, module)

	_, err = service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{
		BotId: "invalid-bound",
	})
	requireCode(t, err, codes.InvalidArgument)

	// Validating at request time must not rewrite what is stored, so the user
	// can still see and repair the binding.
	bot, _ := module.botStore.GetBotForUser("alice", "invalid-bound")
	if bot.ModelBinding == nil || bot.ModelBinding.Provider != "removed-provider" {
		t.Fatalf("die gespeicherte Bindung wurde geloescht: %#v", bot.ModelBinding)
	}
}

func TestAutomaticKeywordInvalidBindingAnnouncesBotBeforeError(t *testing.T) {
	settingsPath := writeSettings(t, `{}`)
	stored := bots.StoreFile{
		Version: bots.StoreSchemaVersion,
		Users: map[string]bots.StoreUser{
			"alice": {Bots: []bots.Config{{
				ID: "invalid-keyword", Name: "Invalid Keyword", SystemPrompt: "bound",
				Keywords: []string{"route-invalid"}, ResponseStyle: "balanced",
				ModelBinding: &bots.ModelBinding{Kind: "api", Provider: "removed-provider", ModelID: "vendor/model"},
			}}},
		},
	}
	payload, err := json.Marshal(stored)
	if err != nil {
		t.Fatalf("Bots serialisieren: %v", err)
	}
	if err := os.WriteFile(filepath.Join(filepath.Dir(settingsPath), "bots.json"), payload, 0o600); err != nil {
		t.Fatalf("Bots schreiben: %v", err)
	}

	module := newTestModule(t, settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{ModelId: "stub"})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	stream := newRecordingStreamForUser("alice")
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(), Message: "route-invalid now",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}

	// Who was going to answer has to be on the wire before why it failed, or
	// the UI cannot attribute the error.
	selectedAt, errorAt := -1, -1
	for index, event := range stream.recorded() {
		if selectedAt < 0 && event.GetBotSelected() != nil {
			selectedAt = index
		}
		if errorAt < 0 && event.GetError() != nil {
			errorAt = index
		}
	}
	if selectedAt < 0 || errorAt < 0 || errorAt <= selectedAt {
		t.Fatalf("die Bot-Identitaet muss vor dem Bindungsfehler kommen: %d und %d", selectedAt, errorAt)
	}
	if selected := stream.selectedBot(); selected == nil || selected.GetId() != "invalid-keyword" {
		t.Fatalf("es wurde der falsche Bot angekuendigt: %+v", selected)
	}
	if failure := stream.failure(); failure == nil || failure.GetCode() != "model_binding_invalid" {
		t.Fatalf("Fehlerereignis = %+v", stream.failure())
	}
}

func TestAutomaticKeywordBotSwitchesEffectiveSessionModel(t *testing.T) {
	local := &fakeWarmupLocalModels{model: localinference.Model{
		InstanceID: "keyword-local", DisplayName: "Keyword Local", ContextLimit: 3072,
	}}
	module := newTestModule(t, writeSettings(t, `{}`))
	module.SetLocalModels(local)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if err := module.botStore.SaveBotForUser("alice", bots.Config{
		ID: "keyword-bound", Name: "Keyword Bound", SystemPrompt: "bound",
		Keywords:     []string{"use-keyword-model"},
		ModelBinding: &bots.ModelBinding{Kind: "local", InstanceID: "keyword-local"},
	}); err != nil {
		t.Fatalf("gebundenen Bot speichern: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{
		ModelId: "normal-selection",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if created.GetLockedBotId() != "" {
		t.Fatalf("die automatische Session wurde unerwartet gesperrt: %+v", created)
	}

	if _, err := service.SendMessage(userContext("alice"), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "please use-keyword-model",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	history, err := service.GetHistory(userContext("alice"), &scoutv1.GetHistoryRequest{
		SessionId: created.GetSessionId(),
	})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if history.GetActiveBotId() != "keyword-bound" || history.GetModelRef() != "local:keyword-local" ||
		history.GetContextLimit() != 3072 {
		t.Fatalf("die Stichwort-Bindung hat das effektive Sessionmodell nicht gewechselt: %+v", history)
	}
}

func TestAPIBoundBotRoutesDirectlyToBoundModel(t *testing.T) {
	var requestBody string
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		requestBody = string(body)
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\"bound api reply\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	module := newTestModule(t, writeSettings(t, `{"openrouter_token":"token"}`))
	module.orAPIBase = providerServer.URL
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if err := module.botStore.SaveBotForUser("alice", bots.Config{
		ID: "api-bound", Name: "API Bound", SystemPrompt: "api bound",
		ModelBinding: &bots.ModelBinding{
			Kind: "api", Provider: "openrouter", ModelID: "vendor/bound-model", DisplayName: "Bound Model",
		},
	}); err != nil {
		t.Fatalf("gebundenen Bot speichern: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{
		BotId: "api-bound", Provider: "featherless", ModelId: "ignored/model",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if created.GetProvider() != "openrouter" || created.GetModelId() != "vendor/bound-model" {
		t.Fatalf("die API-Bindung hat das angefragte Modell nicht ueberschrieben: %+v", created)
	}

	if _, err := service.SendMessage(userContext("alice"), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "hello",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}
	if !strings.Contains(requestBody, `"model":"vendor/bound-model"`) ||
		strings.Contains(requestBody, "ignored/model") {
		t.Fatalf("der Provider bekam das falsche Modell: %s", requestBody)
	}
}

func TestAPIBoundBotProviderNotFoundReturnsStructuredMissingBinding(t *testing.T) {
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		_, _ = io.WriteString(w, `{"error":{"message":"model not found"}}`)
	}))
	defer providerServer.Close()

	module := newTestModule(t, writeSettings(t, `{"openrouter_token":"token"}`))
	module.orAPIBase = providerServer.URL
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	if err := module.botStore.SaveBotForUser("alice", bots.Config{
		ID: "missing-api", Name: "Missing API", SystemPrompt: "bound",
		ModelBinding: &bots.ModelBinding{Kind: "api", Provider: "openrouter", ModelID: "vendor/missing"},
	}); err != nil {
		t.Fatalf("gebundenen Bot speichern: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{
		BotId: "missing-api",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}

	_, err = service.SendMessage(userContext("alice"), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "hello",
	})
	requireCode(t, err, codes.NotFound)

	// The streamed path is where the client reads the code, and it has to name
	// the binding rather than a generic provider failure.
	stream := newRecordingStreamForUser("alice")
	if err := service.StreamMessage(&scoutv1.StreamMessageRequest{
		SessionId: created.GetSessionId(), Message: "hello",
	}, stream); err != nil {
		t.Fatalf("StreamMessage: %v", err)
	}
	if failure := stream.failure(); failure == nil || failure.GetCode() != "model_binding_missing" {
		t.Fatalf("Fehlercode = %+v, want model_binding_missing", stream.failure())
	}
}

func TestScoutInjectsMemoryRecallIntoLocalModel(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	local := &fakeLocalModels{model: localinference.Model{
		InstanceID: "inst-ready", ModelID: "catalog-id", DisplayName: "Lokal", ContextLimit: 8192,
	}}
	module.SetLocalModels(local)
	attachTestAgent(module).SetMemory(&fakeMemoryProvider{recall: "- Der Nutzer heisst David."})
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: "local:inst-ready",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "wie heisse ich",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	if len(local.requestSeen.Messages) == 0 || local.requestSeen.Messages[0].Role != "system" {
		t.Fatalf("kein System-Prompt beim lokalen Modell: %#v", local.requestSeen.Messages)
	}
	system := local.requestSeen.Messages[0].Content
	if !strings.Contains(system, "David") || !strings.Contains(system, scoutMemoryPreamble) {
		t.Fatalf("Recall nicht im System-Prompt des lokalen Modells: %q", system)
	}
}

func TestScoutInjectsMemoryRecallIntoAPIModel(t *testing.T) {
	var requestBody string
	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		requestBody = string(body)
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = io.WriteString(w, "data: {\"choices\":[{\"delta\":{\"content\":\"ok\"}}]}\n\n")
		_, _ = io.WriteString(w, "data: [DONE]\n\n")
	}))
	defer providerServer.Close()

	module := newTestModule(t, writeSettings(t, `{"openrouter_token":"token"}`))
	module.orAPIBase = providerServer.URL
	attachTestAgent(module).SetMemory(&fakeMemoryProvider{recall: "- Der Nutzer trinkt Tee."})
	active, err := module.activeModels.Start("openrouter", "openai/gpt-4o", "GPT-4o")
	if err != nil {
		t.Fatalf("aktives Modell starten: %v", err)
	}
	service := newTestService(t, module)

	created, err := service.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelRef: active.ModelRef,
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if _, err := service.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: created.GetSessionId(), Message: "was trinke ich",
	}); err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	if !strings.Contains(requestBody, "Tee") || !strings.Contains(requestBody, scoutMemoryPreamble) {
		t.Fatalf("Recall nicht im Provider-Payload: %s", requestBody)
	}
}
