package scout

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/modules/scout/bots"
)

type fakeLocalModels struct {
	model       localinference.Model
	resolveErr  error
	streamErr   error
	requestSeen localinference.ChatRequest
}

type fakeWarmupLocalModels struct {
	mu               sync.Mutex
	model            localinference.Model
	ready            bool
	ensureCalls      int
	streamCalls      int
	seenUserMessages []string
}

type blockingLocalModels struct {
	model   localinference.Model
	started chan struct{}
	release chan struct{}
	once    sync.Once
}

func (f *blockingLocalModels) ReadyLocalModels() []localinference.Model {
	return []localinference.Model{f.model}
}

func (f *blockingLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	return f.model, nil
}

func (f *blockingLocalModels) StreamLocalChat(ctx context.Context, instanceID string, _ localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	f.once.Do(func() { close(f.started) })
	select {
	case <-ctx.Done():
		return "", ctx.Err()
	case <-f.release:
	}
	if emit != nil {
		if err := emit("serialized reply"); err != nil {
			return "", err
		}
	}
	return "serialized reply", nil
}

func (f *fakeWarmupLocalModels) ReadyLocalModels() []localinference.Model {
	f.mu.Lock()
	defer f.mu.Unlock()
	if !f.ready {
		return nil
	}
	return []localinference.Model{f.model}
}

func (f *fakeWarmupLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	if !f.ready {
		return localinference.Model{}, localinference.ErrNotReady
	}
	return f.model, nil
}

func (f *fakeWarmupLocalModels) EnsureLocalModelReady(_ context.Context, instanceID string, emit func(localinference.WarmupProgress) error) (localinference.Model, error) {
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	f.mu.Lock()
	f.ensureCalls++
	f.mu.Unlock()
	for _, progress := range []localinference.WarmupProgress{
		{OperationID: "op-1", InstanceID: instanceID, Status: "queued", Phase: "admission", Progress: 0.1, QueuePosition: 1, Placement: "gpu"},
		{OperationID: "op-1", InstanceID: instanceID, Status: "ready", Phase: "healthcheck", Progress: 1, Placement: "gpu"},
	} {
		if emit != nil {
			if err := emit(progress); err != nil {
				return localinference.Model{}, err
			}
		}
	}
	f.mu.Lock()
	f.ready = true
	f.mu.Unlock()
	return f.model, nil
}

func (f *fakeWarmupLocalModels) StreamLocalChat(_ context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	// Naming the chat reaches the same model right after the reply, but it is
	// not a turn: counted here it would look like the message went out twice.
	if systemPromptOf(request) == sessionTitleSystemPrompt {
		const title = "Warmes Thema"
		if emit != nil {
			if err := emit(title); err != nil {
				return "", err
			}
		}
		return title, nil
	}
	f.mu.Lock()
	f.streamCalls++
	for _, message := range request.Messages {
		if message.Role == "user" {
			f.seenUserMessages = append(f.seenUserMessages, message.Content)
		}
	}
	f.mu.Unlock()
	if emit != nil {
		if err := emit("warm reply"); err != nil {
			return "", err
		}
	}
	return "warm reply", nil
}

func (f *fakeLocalModels) ReadyLocalModels() []localinference.Model {
	if f.resolveErr != nil {
		return nil
	}
	return []localinference.Model{f.model}
}

func (f *fakeLocalModels) ResolveLocalModel(instanceID string) (localinference.Model, error) {
	if f.resolveErr != nil {
		return localinference.Model{}, f.resolveErr
	}
	if instanceID != f.model.InstanceID {
		return localinference.Model{}, localinference.ErrNotFound
	}
	return f.model, nil
}

func (f *fakeLocalModels) StreamLocalChat(_ context.Context, instanceID string, request localinference.ChatRequest, emit func(string) error) (string, error) {
	if instanceID != f.model.InstanceID {
		return "", localinference.ErrNotFound
	}
	f.requestSeen = request
	if f.streamErr != nil {
		return "", f.streamErr
	}
	if emit != nil {
		if err := emit("Antwort vom lokalen Modell"); err != nil {
			return "", err
		}
	}
	return "Antwort vom lokalen Modell", nil
}

func TestReadOpenAIStreamBuffersSplitUTF8Chunks(t *testing.T) {
	stream := []byte("data: {\"choices\":[{\"delta\":{\"content\":\"Hallo 🚀 Welt\"}}]}\n\ndata: [DONE]\n\n")
	splitIndex := bytes.Index(stream, []byte("🚀"))
	if splitIndex < 0 {
		t.Fatalf("expected rocket emoji in test stream")
	}
	reader := io.MultiReader(
		bytes.NewReader(stream[:splitIndex+1]),
		bytes.NewReader(stream[splitIndex+1:]),
	)

	reply, _, err := readOpenAIStream(reader, nil, nil)
	if err != nil {
		t.Fatalf("readOpenAIStream failed: %v", err)
	}
	if reply != "Hallo 🚀 Welt" {
		t.Fatalf("expected utf-8 safe reply, got %q", reply)
	}
}

func TestReadOpenAIStreamParsesMultilineSSEDataBlocks(t *testing.T) {
	stream := strings.NewReader(
		"event: message\n" +
			"data: {\"choices\":[\n" +
			"data: {\"delta\":{\"content\":\"Hallo\"}},\n" +
			"data: {\"delta\":{\"content\":\" Welt\"}}]}\n\n" +
			"data: [DONE]\n\n",
	)

	reply, _, err := readOpenAIStream(stream, nil, nil)
	if err != nil {
		t.Fatalf("readOpenAIStream failed: %v", err)
	}
	if reply != "Hallo Welt" {
		t.Fatalf("expected multiline SSE payload to decode, got %q", reply)
	}
}

func TestReadOpenAIStreamRoutesNativeReasoningSeparately(t *testing.T) {
	stream := strings.NewReader(
		"data: {\"choices\":[{\"delta\":{\"reasoning\":\"Ich ueberlege...\"}}]}\n\n" +
			"data: {\"choices\":[{\"delta\":{\"content\":\"Antwort\"}}]}\n\n" +
			"data: [DONE]\n\n",
	)
	var reasoning strings.Builder
	reply, _, err := readOpenAIStream(stream, nil, func(chunk string) error {
		reasoning.WriteString(chunk)
		return nil
	})
	if err != nil {
		t.Fatalf("readOpenAIStream failed: %v", err)
	}
	if reply != "Antwort" {
		t.Fatalf("reasoning darf nicht im sichtbaren Reply landen, bekam: %q", reply)
	}
	if reasoning.String() != "Ich ueberlege..." {
		t.Fatalf("unerwarteter Reasoning-Text: %q", reasoning.String())
	}
}

func TestStreamingTextEmitterBuffersIncompleteGraphemeAcrossChunks(t *testing.T) {
	var got []string
	emitter := newStreamingTextEmitter(func(chunk string) error {
		got = append(got, chunk)
		return nil
	})

	if err := emitter.Emit("A👩‍"); err != nil {
		t.Fatalf("Emit first chunk failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "A" {
		t.Fatalf("expected only complete graphemes after first chunk, got %q", joined)
	}

	if err := emitter.Emit("💻B"); err != nil {
		t.Fatalf("Emit second chunk failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "A👩‍💻" {
		t.Fatalf("expected combined grapheme after second chunk, got %q", joined)
	}

	if err := emitter.Flush(); err != nil {
		t.Fatalf("Flush failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "A👩‍💻B" {
		t.Fatalf("expected flushed text, got %q", joined)
	}
}

func TestStreamingTextEmitterBuffersIncompleteUTF8BytesAcrossChunks(t *testing.T) {
	var got []string
	emitter := newStreamingTextEmitter(func(chunk string) error {
		got = append(got, chunk)
		return nil
	})

	if err := emitter.Emit(string([]byte{0xe2, 0x82})); err != nil {
		t.Fatalf("Emit first chunk failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "" {
		t.Fatalf("expected incomplete utf-8 bytes to be buffered, got %q", joined)
	}

	if err := emitter.Emit(string([]byte{0xac, ' ', 'o', 'k'})); err != nil {
		t.Fatalf("Emit second chunk failed: %v", err)
	}
	if err := emitter.Flush(); err != nil {
		t.Fatalf("Flush failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "€ ok" {
		t.Fatalf("expected reconstructed utf-8 sequence, got %q", joined)
	}
}

func TestStreamingTextEmitterDropsInvalidUTF8Bytes(t *testing.T) {
	var got []string
	emitter := newStreamingTextEmitter(func(chunk string) error {
		got = append(got, chunk)
		return nil
	})

	if err := emitter.Emit(string([]byte{'A', 0xff, 'B'})); err != nil {
		t.Fatalf("Emit failed: %v", err)
	}
	if err := emitter.Flush(); err != nil {
		t.Fatalf("Flush failed: %v", err)
	}
	if joined := strings.Join(got, ""); joined != "AB" {
		t.Fatalf("expected invalid utf-8 byte to be dropped, got %q", joined)
	}
}

func TestBuildRuntimeSystemPromptAvoidsMarkdownCodeFences(t *testing.T) {
	prompt := buildRuntimeSystemPrompt("Du bist Scout.", "medium", "balanced")

	if !strings.Contains(prompt, "Verpacke niemals reines Markdown in einen ```markdown Block") {
		t.Fatalf("expected markdown code-fence instruction in prompt, got %q", prompt)
	}
	if !strings.Contains(prompt, "Listen, Tabellen, Checkboxen") {
		t.Fatalf("expected direct markdown structure instruction in prompt, got %q", prompt)
	}
	if !strings.Contains(prompt, "Verwende niemals Inline-HTML-Tags wie <kbd>, <br>") {
		t.Fatalf("expected inline-html ban in prompt, got %q", prompt)
	}
}

func TestBuildBotRuntimeSystemPromptMakesSelectedBotIdentityAuthoritative(t *testing.T) {
	prompt := buildBotRuntimeSystemPrompt(bots.Config{
		ID:           "mathbot",
		Name:         "MathBot",
		SystemPrompt: "Du hilfst bei Mathematik.",
	}, "medium", "balanced")

	for _, expected := range []string{"Aktiver Bot: MathBot (ID: mathbot)", "ausschliesslich als dieser Bot", "Bezeichne dich nicht als ein allgemeines Basismodell, ChatGPT", "Du hilfst bei Mathematik."} {
		if !strings.Contains(prompt, expected) {
			t.Fatalf("expected bot identity instruction %q in prompt, got %q", expected, prompt)
		}
	}
}

type fakeMemoryProvider struct {
	lastUser    string
	lastProject string
	lastQuery   string
	recall      string
}

func (f *fakeMemoryProvider) ProjectMemoryContext(userID, project, query string) string {
	f.lastUser = userID
	f.lastProject = project
	f.lastQuery = query
	return f.recall
}

func (f *fakeMemoryProvider) EnsureProjectScope(string, string) error { return nil }

func (f *fakeMemoryProvider) PurgeProjectScope(string, string) error { return nil }

func TestAppendMemoryRecall(t *testing.T) {
	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	base := "SYSTEM-PROMPT"

	if got := module.appendMemoryRecall("local", "", "wie heisse ich", base); got != base {
		t.Fatalf("ohne Memory sollte der Prompt unveraendert bleiben, bekam %q", got)
	}

	fake := &fakeMemoryProvider{recall: "- Der Nutzer heisst David."}
	attachTestAgent(module).SetMemory(fake)
	got := module.appendMemoryRecall("david", "proj-42", "wie heisse ich", base)
	if !strings.HasPrefix(got, base) {
		t.Fatalf("Basis-Prompt muss erhalten bleiben: %q", got)
	}
	if !strings.Contains(got, scoutMemoryPreamble) || !strings.Contains(got, "David") {
		t.Fatalf("Recall wurde nicht angehaengt: %q", got)
	}
	if fake.lastUser != "david" || fake.lastProject != "proj-42" || fake.lastQuery != "wie heisse ich" {
		t.Fatalf("User/Projekt/Query nicht durchgereicht: user=%q project=%q query=%q", fake.lastUser, fake.lastProject, fake.lastQuery)
	}

	fake.recall = "   "
	if got := module.appendMemoryRecall("david", "", "hi", base); got != base {
		t.Fatalf("leerer Recall sollte nichts anhaengen, bekam %q", got)
	}
}

func TestWindowMessagesKeepsMostRecent(t *testing.T) {
	msgs := make([]chatMessage, 0, 30)
	for i := 0; i < 30; i++ {
		msgs = append(msgs, chatMessage{Role: "user", Content: fmt.Sprintf("m%d", i)})
	}

	if got := windowMessages(msgs[:10], maxModelHistoryMessages); len(got) != 10 {
		t.Fatalf("erwartete 10 Nachrichten, bekam %d", len(got))
	}

	got := windowMessages(msgs, maxModelHistoryMessages)
	if len(got) != maxModelHistoryMessages {
		t.Fatalf("erwartete %d Nachrichten, bekam %d", maxModelHistoryMessages, len(got))
	}
	if got[0].Content != fmt.Sprintf("m%d", 30-maxModelHistoryMessages) {
		t.Fatalf("Fenster begann falsch: %q", got[0].Content)
	}
	if got[len(got)-1].Content != "m29" {
		t.Fatalf("Fenster endete falsch: %q", got[len(got)-1].Content)
	}
}

func TestScoutSessionCustomTitlePersists(t *testing.T) {
	settings := filepath.Join(t.TempDir(), "settings.json")
	module := newTestModule(t, settings)
	session := &scoutSession{
		ID:       "chat-rename-1",
		UserID:   "local",
		Messages: []chatMessage{{Role: "user", Content: "Hallo Welt"}},
	}
	module.mu.Lock()
	module.sessions[session.ID] = session
	module.mu.Unlock()

	if got := summarizeSession(session).Title; got != "Hallo Welt" {
		t.Fatalf("abgeleiteter Titel falsch: %q", got)
	}

	session.Title = "Mein Projekt"
	module.persistSession(session.ID)
	if got := summarizeSession(session).Title; got != "Mein Projekt" {
		t.Fatalf("Custom-Titel wurde nicht genutzt: %q", got)
	}

	restarted := newTestModule(t, settings)
	restarted.loadPersistedSessions()
	restarted.mu.Lock()
	loaded := restarted.sessions[session.ID]
	restarted.mu.Unlock()
	if loaded == nil || loaded.Title != "Mein Projekt" {
		t.Fatalf("Custom-Titel nicht persistiert: %#v", loaded)
	}
}

func TestScoutSessionPersistenceRoundTrip(t *testing.T) {
	settings := filepath.Join(t.TempDir(), "settings.json")

	first := newTestModule(t, settings)
	session := &scoutSession{
		ID:          "chat-persist-1",
		UserID:      "local",
		Provider:    "openrouter",
		ModelID:     "model-x",
		DisplayName: "Model X",
		Messages: []chatMessage{
			{Role: "user", Content: "Mein Name ist David"},
			{Role: "assistant", Content: "Hallo David"},
		},
		MutationInFlight: true,
	}
	first.mu.Lock()
	first.sessions[session.ID] = session
	first.mu.Unlock()
	first.persistSession(session.ID)

	second := newTestModule(t, settings)
	second.loadPersistedSessions()
	second.mu.Lock()
	loaded := second.sessions[session.ID]
	second.mu.Unlock()

	if loaded == nil {
		t.Fatalf("Session wurde nach Neustart nicht geladen")
	}
	if len(loaded.Messages) != 2 || loaded.Messages[0].Content != "Mein Name ist David" {
		t.Fatalf("Nachrichten nicht korrekt persistiert: %#v", loaded.Messages)
	}
	if loaded.MutationInFlight {
		t.Fatalf("MutationInFlight darf nicht persistiert werden")
	}
	if loaded.UpdatedAt.IsZero() {
		t.Fatalf("UpdatedAt sollte beim Speichern gesetzt werden")
	}

	summary := summarizeSession(loaded)
	if summary.Title != "Mein Name ist David" {
		t.Fatalf("Titel sollte aus erster Nutzernachricht stammen, war %q", summary.Title)
	}
	if summary.MessageCount != 2 {
		t.Fatalf("MessageCount falsch: %d", summary.MessageCount)
	}

	if err := second.storage.Delete(session.ID); err != nil {
		t.Fatalf("delete fehlgeschlagen: %v", err)
	}
	third := newTestModule(t, settings)
	third.loadPersistedSessions()
	third.mu.Lock()
	_, stillThere := third.sessions[session.ID]
	third.mu.Unlock()
	if stillThere {
		t.Fatalf("geloeschte Session sollte nach Neustart weg sein")
	}
}
