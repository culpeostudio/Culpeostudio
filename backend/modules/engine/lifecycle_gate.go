package engine

import (
	"context"
	"errors"
	"sync"
)

func (m *EngineModule) acquireLifecycle(ctx context.Context, allowShutdown bool) (func(), error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if !allowShutdown {
		m.mu.RLock()
		shuttingDown := m.shuttingDown
		m.mu.RUnlock()
		if shuttingDown {
			return nil, errors.New("Engine wird heruntergefahren")
		}
	}
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	case <-m.lifecycleGate:
	}
	if !allowShutdown {
		m.mu.RLock()
		shuttingDown := m.shuttingDown
		m.mu.RUnlock()
		if shuttingDown {
			m.lifecycleGate <- struct{}{}
			return nil, errors.New("Engine wird heruntergefahren")
		}
	}
	var once sync.Once
	return func() { once.Do(func() { m.lifecycleGate <- struct{}{} }) }, nil
}

func (m *EngineModule) isShuttingDown() bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.shuttingDown
}
