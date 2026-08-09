package memorymodule

import (
	"testing"
	"time"

	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memoryembed"
)

func newTestModule(t *testing.T) *MemoryModule {
	t.Helper()
	return newTestModuleWithToken(t, "dev-memory-token")
}

func newTestModuleWithToken(t *testing.T, apiToken string) *MemoryModule {
	t.Helper()
	m := New(
		t.TempDir()+"/memory.db",
		t.TempDir()+"/vector.json",
		memoryembed.Config{Backend: "hash"},
		"culpeostudio",
		apiToken,
		"local",
		1000,
		memory.DefaultCompressionPolicy(),
		120,
		6,
		2,
		"Test Memory",
		MaintenanceConfig{},
		"",
		"",
	)
	if err := m.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	t.Cleanup(func() { m.Shutdown() })
	return m
}

func TestCaptureBusEventGeneric(t *testing.T) {
	m := newTestModule(t)

	err := m.captureBusEvent(bus.Event{
		Source:    "marketplace",
		Type:      bus.EventModelDownloaded,
		Data:      map[string]interface{}{"model_id": "test-model"},
		Timestamp: time.Now(),
	})
	if err != nil {
		t.Fatalf("captureBusEvent failed: %v", err)
	}

	session, err := m.service.GetSessionForUser("local", "system-events")
	if err != nil {
		t.Fatalf("expected system-events session, got error: %v", err)
	}
	if session.ObservationCount == 0 {
		t.Fatalf("expected at least one observation in system-events session")
	}
}

func TestCaptureBusEventScoutChat(t *testing.T) {
	m := newTestModule(t)

	err := m.captureBusEvent(bus.Event{
		Source: "scout",
		Type:   bus.EventScoutMessageSent,
		Data: map[string]interface{}{
			"session_id": "bot-sess-1",
			"message":    "Wie funktioniert der Memory-Viewer?",
			"reply":      "Der Viewer zeigt Sessions, Suche und Timeline.",
		},
		Timestamp: time.Now(),
	})
	if err != nil {
		t.Fatalf("captureBusEvent failed: %v", err)
	}

	session, err := m.service.GetSessionForUser("local", "bot-sess-1")
	if err != nil {
		t.Fatalf("expected chat session, got error: %v", err)
	}
	if session.PromptCount < 2 {
		t.Fatalf("expected user+assistant prompts captured, got %d", session.PromptCount)
	}
}
