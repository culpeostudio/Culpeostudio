package engine

import (
	"sync"
	"time"
)

type engineEvent struct {
	Type      string      `json:"type"`
	Data      interface{} `json:"data,omitempty"`
	Timestamp time.Time   `json:"timestamp"`
}

type engineEventHub struct {
	mu          sync.Mutex
	subscribers map[int]chan engineEvent
	nextID      int
	tickets     map[string]engineEventTicket
}

type engineEventTicket struct {
	UserID    string
	ExpiresAt time.Time
}

func newEngineEventHub() *engineEventHub {
	return &engineEventHub{subscribers: map[int]chan engineEvent{}, tickets: map[string]engineEventTicket{}}
}

func (h *engineEventHub) publish(eventType string, data interface{}) {
	event := engineEvent{Type: eventType, Data: data, Timestamp: time.Now().UTC()}
	h.mu.Lock()
	defer h.mu.Unlock()
	for _, subscriber := range h.subscribers {
		select {
		case subscriber <- event:
		default:

		}
	}
}

func (h *engineEventHub) subscribe() (<-chan engineEvent, func()) {
	h.mu.Lock()
	id := h.nextID
	h.nextID++
	channel := make(chan engineEvent, 32)
	h.subscribers[id] = channel
	h.mu.Unlock()
	return channel, func() {
		h.mu.Lock()
		if existing := h.subscribers[id]; existing != nil {
			delete(h.subscribers, id)
			close(existing)
		}
		h.mu.Unlock()
	}
}

func (m *EngineModule) engineEventForUser(event engineEvent, userID string) engineEvent {
	switch value := event.Data.(type) {
	case *EngineInstance:
		event.Data = m.instanceForUser(value, userID)
	case EngineInstance:
		event.Data = m.instanceForUser(&value, userID)
	case []*EngineInstance:
		instances := make([]*EngineInstance, 0, len(value))
		for _, instance := range value {
			instances = append(instances, m.instanceForUser(instance, userID))
		}
		event.Data = instances
	}
	return event
}
