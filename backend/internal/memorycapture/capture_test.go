package memorycapture

import (
	"strings"
	"testing"

	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memoryembed"
	"github.com/culpeohq/backend/internal/memorystore"
	"github.com/culpeohq/backend/internal/memoryvector"
)

func newCaptureService(t *testing.T) (*Service, *memory.Service) {
	t.Helper()
	baseDir := t.TempDir()
	store := memorystore.NewSQLiteStore(baseDir + "/memory.db")
	hashBackend := memoryembed.NewHashBackend(64)
	vector := memoryvector.New(store, hashBackend, hashBackend, baseDir+"/vector.json")

	options := memory.Options{
		ProjectTag:          "culpeostudio",
		DefaultUserID:       "local",
		ContextBudgetTokens: 400,
		Policy:              memory.DefaultCompressionPolicy(),
	}
	memService := memory.NewService(store, vector, nil, options)
	if err := memService.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	t.Cleanup(func() {
		_ = memService.Close()
	})
	captureService := New(memService, 6, 2)
	memService.RegisterCleanupHandler(func(sessionID string) {
		captureService.ClearSession(sessionID)
	})
	return captureService, memService
}

func TestChatMemoryRecallAcrossSession(t *testing.T) {
	capture, mem := newCaptureService(t)

	for _, phrasing := range []struct {
		name  string
		user  string
		reply string
		query string
	}{
		{"mein-name", "Mein Name ist David.", "Freut mich, David.", "Wie ist mein Name"},
		{"ich-heisse", "Ich heiße David.", "Hallo David.", "Wie heiße ich"},
	} {
		t.Run(phrasing.name, func(t *testing.T) {
			capture2, mem2 := newCaptureService(t)
			_ = capture
			_ = mem
			if _, err := capture2.CaptureChatMessage("local", "sessionA", "", phrasing.user, phrasing.reply); err != nil {
				t.Fatalf("capture failed: %v", err)
			}
			env, err := mem2.BuildUserContext("local", phrasing.query, 0)
			if err != nil {
				t.Fatalf("build user context failed: %v", err)
			}
			if env == nil || !strings.Contains(env.InjectionPrompt, "David") {
				t.Fatalf("recall fand den Namen nicht: %q", env.InjectionPrompt)
			}
		})
	}
}

func TestCaptureEventBusRedactsSensitiveData(t *testing.T) {
	captureService, memService := newCaptureService(t)

	_, err := captureService.CaptureEventBus(EventBusInput{
		SessionID: "login-session-1",
		Project:   "culpeostudio",
		Source:    "login",
		Type:      "user_logged_in",
		Data: map[string]interface{}{
			"username": "david",
			"password": "super-secret",
			"token":    "Bearer abc",
		},
	})
	if err != nil {
		t.Fatalf("capture event failed: %v", err)
	}

	session, err := memService.GetSession("login-session-1")
	if err != nil {
		t.Fatalf("get session failed: %v", err)
	}
	if len(session.ActiveObservations) == 0 {
		t.Fatalf("expected stored observation")
	}
	narrative := session.ActiveObservations[0].Narrative
	if strings.Contains(narrative, "super-secret") || strings.Contains(narrative, "Bearer abc") {
		t.Fatalf("expected sensitive values to be redacted, got %q", narrative)
	}
}

func TestCaptureChatMessageStoresStructuredMemory(t *testing.T) {
	captureService, memService := newCaptureService(t)

	_, err := captureService.CaptureChatMessage(
		"local",
		"chat-session-1",
		"culpeostudio",
		"Bitte verbessere die Chat-Kompression mit SimpleMem-artigen Keywords.",
		"Ich speichere daraus strukturierte Chat-Memory Observations.",
	)
	if err != nil {
		t.Fatalf("capture chat failed: %v", err)
	}

	session, err := memService.GetSession("chat-session-1")
	if err != nil {
		t.Fatalf("get session failed: %v", err)
	}
	if len(session.ActiveObservations) == 0 {
		t.Fatalf("expected structured chat observation")
	}
	observation := session.ActiveObservations[0]
	if observation.Type != "chat_memory" {
		t.Fatalf("expected chat_memory observation, got %s", observation.Type)
	}
	if observation.Topic == "" || len(observation.Keywords) == 0 {
		t.Fatalf("expected topic and keywords, got topic=%q keywords=%v", observation.Topic, observation.Keywords)
	}
	if observation.Narrative == "" || !strings.Contains(observation.Narrative, "User request:") {
		t.Fatalf("expected compressed dialogue narrative, got %q", observation.Narrative)
	}
}

func TestCaptureChatMessageRedactsSensitiveText(t *testing.T) {
	captureService, memService := newCaptureService(t)

	_, err := captureService.CaptureChatMessage(
		"local",
		"chat-secret-1",
		"culpeostudio",
		"Mein password ist super-secret-token",
		"Nutze Bearer abcdef",
	)
	if err != nil {
		t.Fatalf("capture chat failed: %v", err)
	}

	session, err := memService.GetSession("chat-secret-1")
	if err != nil {
		t.Fatalf("get session failed: %v", err)
	}
	if len(session.ActiveObservations) == 0 {
		t.Fatalf("expected structured chat observation")
	}
	narrative := session.ActiveObservations[0].Narrative
	if strings.Contains(narrative, "super-secret-token") || strings.Contains(narrative, "Bearer abcdef") {
		t.Fatalf("expected sensitive chat text to be redacted, got %q", narrative)
	}
}

func TestCaptureChatMessageRefinedRedaction(t *testing.T) {
	captureService, memService := newCaptureService(t)

	_, err := captureService.CaptureChatMessage(
		"local",
		"chat-refine-1",
		"culpeostudio",
		"The secret to clean code is modularity. My password: super-secret-123. API_KEY=xyz123.",
		"Here is the token, use Bearer abc-def-987 to auth.",
	)
	if err != nil {
		t.Fatalf("capture chat failed: %v", err)
	}

	session, err := memService.GetSession("chat-refine-1")
	if err != nil {
		t.Fatalf("get session failed: %v", err)
	}
	if len(session.ActiveObservations) == 0 {
		t.Fatalf("expected stored observation")
	}
	narrative := session.ActiveObservations[0].Narrative

	if !strings.Contains(narrative, "The secret to clean code is modularity") {
		t.Errorf("expected non-sensitive text to be preserved, but was lost or redacted. Narrative: %q", narrative)
	}
	if !strings.Contains(narrative, "Here is the token") {
		t.Errorf("expected non-sensitive reply text to be preserved, but was lost or redacted. Narrative: %q", narrative)
	}

	if strings.Contains(narrative, "super-secret-123") {
		t.Errorf("expected password to be redacted, got %q", narrative)
	}
	if strings.Contains(narrative, "xyz123") {
		t.Errorf("expected API_KEY value to be redacted, got %q", narrative)
	}
	if strings.Contains(narrative, "abc-def-987") {
		t.Errorf("expected Bearer token to be redacted, got %q", narrative)
	}
}

func TestCompressorClearSession(t *testing.T) {
	captureService, memService := newCaptureService(t)

	sessionID := "temp-session-clear"
	_, err := captureService.CaptureChatMessage(
		"local",
		sessionID,
		"culpeostudio",
		"Hallo",
		"Hallo zurück",
	)
	if err != nil {
		t.Fatalf("capture chat failed: %v", err)
	}

	if !captureService.chatCompressor.HasSession(sessionID) {
		t.Fatalf("expected compressor to have session data")
	}

	_, err = memService.CompleteSession(sessionID, memory.CompleteSessionInput{
		UserID: "local",
	})
	if err != nil {
		t.Fatalf("complete session failed: %v", err)
	}

	if captureService.chatCompressor.HasSession(sessionID) {
		t.Errorf("expected session keys to be deleted from maps after CompleteSession")
	}

	sessionID2 := "temp-session-delete"
	_, _ = captureService.CaptureChatMessage(
		"local",
		sessionID2,
		"culpeostudio",
		"Hallo 2",
		"Hallo 2 zurück",
	)

	if !captureService.chatCompressor.HasSession(sessionID2) {
		t.Fatalf("expected compressor to have session data for session 2")
	}

	err = memService.DeleteSessionForUser("local", sessionID2)
	if err != nil {
		t.Fatalf("delete session failed: %v", err)
	}

	if captureService.chatCompressor.HasSession(sessionID2) {
		t.Errorf("expected session keys to be deleted from maps after DeleteSessionForUser")
	}
}
