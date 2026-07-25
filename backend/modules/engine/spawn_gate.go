package engine

import (
	"context"
	"fmt"
	"sync"

	"github.com/fillyengine/backend/internal/localinference"
)

func (m *EngineModule) acquireWorkerSpawn(ctx context.Context) (func(), error) {
	m.spawnGateMu.Lock()
	if err := ctx.Err(); err != nil {
		m.spawnGateMu.Unlock()
		return nil, err
	}
	m.mu.RLock()
	guard := m.guardState
	shuttingDown := m.shuttingDown
	m.mu.RUnlock()
	if shuttingDown {
		m.spawnGateMu.Unlock()
		return nil, fmt.Errorf("Engine wird heruntergefahren")
	}
	// Warning no longer blocks spawns: the byte-exact peak validation has
	// already admitted this start, and a tight-but-sufficient budget is the
	// normal state on a host with one loaded GPU.
	if guard == GuardCritical || guard == GuardEmergency {
		m.spawnGateMu.Unlock()
		return nil, fmt.Errorf("%w: Prozessstart ist bei Guard-Zustand %s pausiert", localinference.ErrGuardRejected, guard)
	}
	var once sync.Once
	return func() { once.Do(func() { m.spawnGateMu.Unlock() }) }, nil
}
