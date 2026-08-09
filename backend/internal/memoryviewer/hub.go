// Package memoryviewer publishes memory changes to connected clients so the
// viewer can follow them live.
package memoryviewer

import (
	"sync"
	"time"
)

type UserIDProvider interface {
	GetUserID() string
}

type Event struct {
	Type      string      `json:"type"`
	Timestamp time.Time   `json:"timestamp"`
	Data      interface{} `json:"data"`
}

type Hub struct {
	mu          sync.RWMutex
	subscribers map[chan Event]struct{}
	closeOnce   sync.Once
}

func NewHub() *Hub {
	return &Hub{
		subscribers: map[chan Event]struct{}{},
	}
}

func (h *Hub) Publish(eventType string, payload interface{}) {
	event := Event{
		Type:      eventType,
		Timestamp: time.Now().UTC(),
		Data:      payload,
	}
	h.mu.RLock()
	defer h.mu.RUnlock()
	for subscriber := range h.subscribers {
		select {
		case subscriber <- event:
		default:
		}
	}
}

func (h *Hub) Subscribe(buffer int) chan Event {
	if buffer <= 0 {
		buffer = 32
	}
	channel := make(chan Event, buffer)
	h.mu.Lock()
	h.subscribers[channel] = struct{}{}
	h.mu.Unlock()
	return channel
}

func (h *Hub) Unsubscribe(channel chan Event) {
	h.mu.Lock()
	if _, ok := h.subscribers[channel]; ok {
		delete(h.subscribers, channel)
		close(channel)
	}
	h.mu.Unlock()
}

func (h *Hub) Close() {
	h.closeOnce.Do(func() {
		h.mu.Lock()
		defer h.mu.Unlock()
		for ch := range h.subscribers {
			close(ch)
			delete(h.subscribers, ch)
		}
	})
}
