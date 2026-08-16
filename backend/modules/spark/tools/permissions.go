package tools

import (
	"context"
	"sync"
	"time"
)

const (
	permissionOnce    = "once"
	permissionSession = "session"
	permissionDeny    = "deny"
)

// How long the agent waits for a decision on an access prompt. This is a human
// on the other end, not a machine: three minutes meant a run died because
// somebody went for coffee. The wait ends when the user answers or when the
// chat is cancelled, which is the ctx below - the clock is only the last resort
// against a prompt nobody will ever see.
const permissionAskTimeout = 30 * time.Minute

type PermissionRequest struct {
	ID   string
	Tool string
	Path string
}

type Asker interface {
	Ask(ctx context.Context, req PermissionRequest) string
}

type Broker struct {
	mu      sync.Mutex
	pending map[string]chan string
	closed  bool
}

func NewBroker() *Broker {
	return &Broker{pending: map[string]chan string{}}
}

func (b *Broker) Ask(ctx context.Context, req PermissionRequest) string {
	ch := make(chan string, 1)
	b.mu.Lock()
	if b.closed {
		b.mu.Unlock()
		return permissionDeny
	}
	b.pending[req.ID] = ch
	b.mu.Unlock()

	defer func() {
		b.mu.Lock()
		delete(b.pending, req.ID)
		b.mu.Unlock()
	}()

	if ctx == nil {
		ctx = context.Background()
	}
	select {
	case decision := <-ch:
		return decision
	case <-ctx.Done():
		return permissionDeny
	case <-time.After(permissionAskTimeout):
		return permissionDeny
	}
}

func (b *Broker) Respond(requestID, decision string) bool {
	switch decision {
	case permissionOnce, permissionSession, permissionDeny:
	default:
		return false
	}
	b.mu.Lock()
	ch, ok := b.pending[requestID]
	b.mu.Unlock()
	if !ok {
		return false
	}

	select {
	case ch <- decision:
	default:
	}
	return true
}

func (b *Broker) Close() {
	b.mu.Lock()
	if b.closed {
		b.mu.Unlock()
		return
	}
	b.closed = true
	pending := b.pending
	b.pending = map[string]chan string{}
	b.mu.Unlock()
	for _, ch := range pending {
		select {
		case ch <- permissionDeny:
		default:
		}
	}
}
