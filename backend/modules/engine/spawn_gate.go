package engine

import (
	"context"
	"fmt"
	"sync"

	"github.com/culpeohq/backend/internal/localinference"
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

	if guard == GuardCritical || guard == GuardEmergency {
		m.spawnGateMu.Unlock()
		return nil, fmt.Errorf("%w: Prozessstart ist bei Guard-Zustand %s pausiert", localinference.ErrGuardRejected, guard)
	}
	var once sync.Once
	return func() { once.Do(func() { m.spawnGateMu.Unlock() }) }, nil
}
