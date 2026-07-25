package bus

import (
	"log"
	"sync"
	"time"
)

// Event repräsentiert ein Modul-übergreifendes Event.
type Event struct {
	Source    string                 `json:"source"`
	Type      string                 `json:"type"`
	Data      map[string]interface{} `json:"data"`
	Timestamp time.Time              `json:"timestamp"`
}

// Handler ist eine Callback-Funktion für Events.
type Handler func(Event)

// EventBus ermöglicht Inter-Modul-Kommunikation im Backend.
// Module können Events publizieren und subscriben ohne sich direkt zu kennen.
type EventBus struct {
	mu       sync.RWMutex
	handlers map[string][]Handler // eventType -> handlers
	global   []Handler            // Handler die ALLE Events bekommen
}

var (
	instance *EventBus
	once     sync.Once
)

// Get gibt die Singleton-Instanz des EventBus zurück.
func Get() *EventBus {
	once.Do(func() {
		instance = &EventBus{
			handlers: make(map[string][]Handler),
		}
	})
	return instance
}

// Emit sendet ein Event an alle registrierten Handler.
func (b *EventBus) Emit(source, eventType string, data map[string]interface{}) {
	event := Event{
		Source:    source,
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now(),
	}

	b.mu.RLock()
	defer b.mu.RUnlock()

	// Typ-spezifische Handler
	if handlers, ok := b.handlers[eventType]; ok {
		for _, h := range handlers {
			go dispatch(h, event)
		}
	}

	// Globale Handler
	for _, h := range b.global {
		go dispatch(h, event)
	}
}

// dispatch fuehrt einen Handler in seiner Goroutine aus und faengt Panics ab.
// Ohne dieses recover wuerde ein Panic in IRGENDEINEM Event-Handler den
// gesamten Prozess beenden (in Go killt ein nicht abgefangener Panic in einer
// Goroutine die ganze App, nicht nur diese Goroutine) — ein fehlerhafter
// Handler koennte so das komplette Backend mitreissen.
func dispatch(h Handler, event Event) {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[Bus] Handler-Panic bei %s -> %s: %v", event.Source, event.Type, r)
		}
	}()
	h(event)
}

// On registriert einen Handler für einen bestimmten Event-Typ.
func (b *EventBus) On(eventType string, handler Handler) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.handlers[eventType] = append(b.handlers[eventType], handler)
}

// OnAll registriert einen Handler der ALLE Events bekommt.
func (b *EventBus) OnAll(handler Handler) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.global = append(b.global, handler)
}

// ── Vordefinierte Event-Typen ──────────────────────────

const (
	// Login
	EventUserLoggedIn  = "user_logged_in"
	EventUserLoggedOut = "user_logged_out"

	// Marktplatz
	EventModelDownloaded = "model_downloaded"
	EventModelDeleted    = "model_deleted"

	// Engine
	EventEngineStarted = "engine_started"
	EventEngineStopped = "engine_stopped"
	EventModelLoaded   = "model_loaded"

	// Chat (PhiloBot / Philox)
	EventPhiloBotSessionCreated = "philobot_session_created"
	EventPhiloBotMessageSent    = "philobot_message_sent"
	EventPhiloxSessionCreated   = "philox_session_created"
	EventPhiloxMessageSent      = "philox_message_sent"

	// Settings
	EventSettingsChanged = "settings_changed"
)
