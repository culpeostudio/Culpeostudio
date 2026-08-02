// Package bus carries process-local events between modules so they do not have
// to import one another.
package bus

import (
	"log"
	"sync"
	"time"
)

type Event struct {
	Source    string                 `json:"source"`
	Type      string                 `json:"type"`
	Data      map[string]interface{} `json:"data"`
	Timestamp time.Time              `json:"timestamp"`
}

type Handler func(Event)

type EventBus struct {
	mu       sync.RWMutex
	handlers map[string][]Handler
	global   []Handler
}

var (
	instance *EventBus
	once     sync.Once
)

func Get() *EventBus {
	once.Do(func() {
		instance = &EventBus{
			handlers: make(map[string][]Handler),
		}
	})
	return instance
}

func (b *EventBus) Emit(source, eventType string, data map[string]interface{}) {
	event := Event{
		Source:    source,
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now(),
	}

	b.mu.RLock()
	defer b.mu.RUnlock()

	if handlers, ok := b.handlers[eventType]; ok {
		for _, h := range handlers {
			go dispatch(h, event)
		}
	}

	for _, h := range b.global {
		go dispatch(h, event)
	}
}

func dispatch(h Handler, event Event) {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[Bus] Handler-Panic bei %s -> %s: %v", event.Source, event.Type, r)
		}
	}()
	h(event)
}

func (b *EventBus) On(eventType string, handler Handler) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.handlers[eventType] = append(b.handlers[eventType], handler)
}

func (b *EventBus) OnAll(handler Handler) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.global = append(b.global, handler)
}

const (
	EventUserLoggedIn  = "user_logged_in"
	EventUserLoggedOut = "user_logged_out"

	EventModelDownloaded = "model_downloaded"
	EventModelDeleted    = "model_deleted"

	EventEngineStarted = "engine_started"
	EventEngineStopped = "engine_stopped"
	EventModelLoaded   = "model_loaded"

	EventPhiloBotSessionCreated = "philobot_session_created"
	EventPhiloBotMessageSent    = "philobot_message_sent"

	EventSettingsChanged = "settings_changed"
)
