package engine

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/fillyengine/backend/internal/localinference"
)

type startAdmissionEntry struct {
	id       string
	priority int
	sequence uint64
	ready    chan struct{}
}

// startAdmissionQueue serializes memory-changing starts. Unlike a mutex it
// exposes deterministic queue positions, supports cancellation before spawn,
// and can pause admission while the host is under memory pressure.
type startAdmissionQueue struct {
	mu      sync.Mutex
	active  *startAdmissionEntry
	waiting []*startAdmissionEntry
	entries map[string]*startAdmissionEntry
	next    uint64
	paused  bool
}

func newStartAdmissionQueue() *startAdmissionQueue {
	return &startAdmissionQueue{entries: map[string]*startAdmissionEntry{}}
}

func (q *startAdmissionQueue) enqueue(id, priority string) map[string]int {
	q.mu.Lock()
	defer q.mu.Unlock()
	if _, exists := q.entries[id]; exists {
		return q.positionsLocked()
	}
	q.next++
	entry := &startAdmissionEntry{id: id, priority: startPriority(priority), sequence: q.next, ready: make(chan struct{})}
	q.entries[id] = entry
	if q.active == nil && !q.paused {
		q.active = entry
		close(entry.ready)
		return q.positionsLocked()
	}
	q.waiting = append(q.waiting, entry)
	for index := len(q.waiting) - 1; index > 0; index-- {
		left := q.waiting[index-1]
		right := q.waiting[index]
		if left.priority > right.priority || (left.priority == right.priority && left.sequence < right.sequence) {
			break
		}
		q.waiting[index-1], q.waiting[index] = right, left
	}
	return q.positionsLocked()
}

func startPriority(value string) int {
	switch value {
	case "pinned", "high":
		return 3
	case "low":
		return 1
	default:
		return 2
	}
}

func (q *startAdmissionQueue) wait(ctx context.Context, id string) error {
	q.mu.Lock()
	entry := q.entries[id]
	q.mu.Unlock()
	if entry == nil {
		return errors.New("Startvorgang fehlt in der Admission-Queue")
	}
	select {
	case <-entry.ready:
		return nil
	case <-ctx.Done():
		q.mu.Lock()
		// Promotion and cancellation can become ready simultaneously. Once the
		// entry is active, admission owns the lifecycle slot and the caller must
		// run its deferred done path instead of stranding q.active forever.
		if q.active == entry {
			q.mu.Unlock()
			return nil
		}
		if q.entries[id] == entry {
			for index, queued := range q.waiting {
				if queued == entry {
					q.waiting = append(q.waiting[:index], q.waiting[index+1:]...)
					break
				}
			}
			delete(q.entries, id)
		}
		q.mu.Unlock()
		return ctx.Err()
	}
}

func (q *startAdmissionQueue) cancel(id string) map[string]int {
	q.mu.Lock()
	defer q.mu.Unlock()
	entry := q.entries[id]
	if entry == nil || q.active == entry {
		return q.positionsLocked()
	}
	for index, queued := range q.waiting {
		if queued == entry {
			q.waiting = append(q.waiting[:index], q.waiting[index+1:]...)
			break
		}
	}
	delete(q.entries, id)
	return q.positionsLocked()
}

func (q *startAdmissionQueue) done(id string) map[string]int {
	q.mu.Lock()
	defer q.mu.Unlock()
	entry := q.entries[id]
	delete(q.entries, id)
	if q.active == entry {
		q.active = nil
	}
	q.promoteLocked()
	return q.positionsLocked()
}

func (q *startAdmissionQueue) setPaused(paused bool) map[string]int {
	q.mu.Lock()
	defer q.mu.Unlock()
	q.paused = paused
	q.promoteLocked()
	return q.positionsLocked()
}

func (q *startAdmissionQueue) promoteLocked() {
	if q.paused || q.active != nil || len(q.waiting) == 0 {
		return
	}
	q.active = q.waiting[0]
	q.waiting = q.waiting[1:]
	close(q.active.ready)
}

func (q *startAdmissionQueue) positions() map[string]int {
	q.mu.Lock()
	defer q.mu.Unlock()
	return q.positionsLocked()
}

func (q *startAdmissionQueue) positionsLocked() map[string]int {
	result := map[string]int{}
	if q.active != nil {
		result[q.active.id] = 0
	}
	for index, entry := range q.waiting {
		result[entry.id] = index + 1
	}
	return result
}

type inferenceWaiter struct {
	ready   chan struct{}
	granted bool
}

type inferenceGate struct {
	mu         sync.Mutex
	active     int
	maxActive  int
	maxWaiting int
	waiting    []*inferenceWaiter
}

type inferenceAdmissionError struct {
	code string
	err  error
}

func (e *inferenceAdmissionError) Error() string { return e.err.Error() }
func (e *inferenceAdmissionError) Unwrap() error { return e.err }

func (g *inferenceGate) acquire(ctx context.Context, maxActive, maxWaiting int, timeout time.Duration) (func(), error) {
	if maxActive < 1 {
		maxActive = 1
	}
	if maxWaiting < 1 {
		maxWaiting = 1
	}
	if timeout <= 0 {
		timeout = 120 * time.Second
	}
	g.mu.Lock()
	g.maxActive = maxActive
	g.maxWaiting = maxWaiting
	if g.active < g.maxActive && len(g.waiting) == 0 {
		g.active++
		g.mu.Unlock()
		return g.releaseFunc(), nil
	}
	if len(g.waiting) >= g.maxWaiting {
		g.mu.Unlock()
		return nil, &inferenceAdmissionError{code: "inference_queue_full", err: localinference.ErrInferenceBusy}
	}
	waiter := &inferenceWaiter{ready: make(chan struct{})}
	g.waiting = append(g.waiting, waiter)
	g.mu.Unlock()

	timer := time.NewTimer(timeout)
	defer timer.Stop()
	select {
	case <-waiter.ready:
		return g.releaseFunc(), nil
	case <-ctx.Done():
		if g.removeWaiter(waiter) {
			return nil, ctx.Err()
		}
		<-waiter.ready
		return g.releaseFunc(), nil
	case <-timer.C:
		if g.removeWaiter(waiter) {
			return nil, &inferenceAdmissionError{code: "inference_queue_timeout", err: localinference.ErrInferenceBusy}
		}
		<-waiter.ready
		return g.releaseFunc(), nil
	}
}

func (g *inferenceGate) removeWaiter(wanted *inferenceWaiter) bool {
	g.mu.Lock()
	defer g.mu.Unlock()
	if wanted.granted {
		return false
	}
	for index, waiter := range g.waiting {
		if waiter == wanted {
			g.waiting = append(g.waiting[:index], g.waiting[index+1:]...)
			return true
		}
	}
	return false
}

func (g *inferenceGate) releaseFunc() func() {
	var once sync.Once
	return func() {
		once.Do(func() {
			g.mu.Lock()
			if g.active > 0 {
				g.active--
			}
			if len(g.waiting) > 0 && g.active < g.maxActive {
				waiter := g.waiting[0]
				g.waiting = g.waiting[1:]
				g.active++
				waiter.granted = true
				close(waiter.ready)
			}
			g.mu.Unlock()
		})
	}
}
