package memorymodule

import (
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/internal/memory"
	"github.com/fillyengine/backend/internal/memoryembed"
)

func newTestModule(t *testing.T) *MemoryModule {
	t.Helper()
	m := New(
		t.TempDir()+"/memory.db",
		t.TempDir()+"/vector.json",
		memoryembed.Config{Backend: "hash"},
		"myphiloengine",
		"dev-memory-token",
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
		Source:    "marktplatz",
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

func TestCaptureBusEventSkipsPhilox(t *testing.T) {
	m := newTestModule(t)

	for _, eventType := range []string{bus.EventPhiloxSessionCreated, bus.EventPhiloxMessageSent} {
		err := m.captureBusEvent(bus.Event{
			Source:    "philox",
			Type:      eventType,
			Data:      map[string]interface{}{"session_id": "philox-sess-1", "message": "hi", "reply": "ok"},
			Timestamp: time.Now(),
		})
		if err != nil {
			t.Fatalf("captureBusEvent(%s) failed: %v", eventType, err)
		}
	}

	if _, err := m.service.GetSessionForUser("local", "philox-sess-1"); err == nil {
		t.Fatalf("philox events must not be captured over the bus (direct integration)")
	}
}

func TestCaptureBusEventPhiloBotChat(t *testing.T) {
	m := newTestModule(t)

	err := m.captureBusEvent(bus.Event{
		Source: "philobot",
		Type:   bus.EventPhiloBotMessageSent,
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

func TestPhiloxDirectCapture(t *testing.T) {
	m := newTestModule(t)

	m.PhiloxSessionStarted("philox-direct-1", []string{"Memory integrieren"})
	if _, err := m.service.GetSessionForUser("local", "philox-direct-1"); err != nil {
		t.Fatalf("expected philox session, got error: %v", err)
	}

	if context := m.PhiloxPromptContext("philox-direct-1", "Baue den Viewer um"); context == "" {
		t.Fatalf("expected non-empty injection prompt")
	}

	m.PhiloxToolObserved("philox-direct-1", "read_file", map[string]interface{}{"path": "/tmp/x"}, "inhalt", true)
	m.PhiloxReplyFinished("philox-direct-1", "Der Viewer wurde umgebaut.")

	session, err := m.service.GetSessionForUser("local", "philox-direct-1")
	if err != nil {
		t.Fatalf("session lookup failed: %v", err)
	}
	if session.ObservationCount == 0 {
		t.Fatalf("expected tool/reply observations, got none")
	}
}
