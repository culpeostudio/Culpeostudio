package philox

import (
	"context"
	"sync"
)

type sessionRequestRegistry struct {
	mu      sync.Mutex
	cancels map[string]*sessionRequest
}

type sessionRequest struct {
	cancel context.CancelFunc
}

func newSessionRequestRegistry() *sessionRequestRegistry {
	return &sessionRequestRegistry{
		cancels: map[string]*sessionRequest{},
	}
}

func (r *sessionRequestRegistry) Begin(sessionID string) (context.Context, *sessionRequest) {
	ctx, cancel := context.WithCancel(context.Background())
	request := &sessionRequest{cancel: cancel}
	r.mu.Lock()
	r.cancels[sessionID] = request
	r.mu.Unlock()
	return ctx, request
}

func (r *sessionRequestRegistry) Finish(sessionID string, request *sessionRequest) {
	r.mu.Lock()
	if current, ok := r.cancels[sessionID]; ok && current == request {
		delete(r.cancels, sessionID)
	}
	r.mu.Unlock()
}

func (r *sessionRequestRegistry) Cancel(sessionID string) bool {
	r.mu.Lock()
	request, ok := r.cancels[sessionID]
	r.mu.Unlock()
	if !ok {
		return false
	}
	request.cancel()
	return true
}
