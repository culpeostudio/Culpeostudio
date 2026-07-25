package engine

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/localinference"
)

func inferenceWaitingLimit(maxSequences int) int {
	limit := 2 * maxSequences
	if limit < 2 {
		limit = 2
	}
	if limit > 8 {
		limit = 8
	}
	return limit
}

func (m *EngineModule) acquireInference(ctx context.Context, instanceID string) (func(), error) {
	m.mu.RLock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.RUnlock()
		return nil, localinference.ErrNotFound
	}
	if instance.State != engineruntime.StateReady || instance.BaseURL == "" || instance.WorkerSecret == "" {
		m.mu.RUnlock()
		return nil, localinference.ErrNotReady
	}
	if m.guardState == GuardEmergency {
		m.mu.RUnlock()
		return nil, fmt.Errorf("%w: Host befindet sich im Notfallschutz", localinference.ErrGuardRejected)
	}
	expectedGeneration := instance.workerGeneration
	expectedSecret := instance.WorkerSecret
	maxActive := instance.EffectiveConfig.MaxSequences
	if maxActive < 1 {
		maxActive = instance.RequestedConfig.MaxSequences
	}
	m.mu.RUnlock()
	if maxActive < 1 {
		maxActive = 1
	}

	m.inferenceMu.Lock()
	gate := m.inferenceGates[instanceID]
	if gate == nil {
		gate = &inferenceGate{}
		m.inferenceGates[instanceID] = gate
	}
	m.inferenceMu.Unlock()
	releaseGate, err := gate.acquire(ctx, maxActive, inferenceWaitingLimit(maxActive), m.inferenceQueueTimeout)
	if err != nil {
		return nil, err
	}

	m.mu.Lock()
	instance = m.instances[instanceID]
	if instance == nil || instance.State != engineruntime.StateReady || instance.BaseURL == "" || instance.WorkerSecret == "" || instance.workerGeneration != expectedGeneration || instance.WorkerSecret != expectedSecret {
		m.mu.Unlock()
		releaseGate()
		return nil, localinference.ErrNotReady
	}
	// The request may have waited behind another inference while the watchdog
	// entered Emergency. Revalidate after admission so queued work cannot begin
	// consuming memory based on the stale pre-queue guard observation.
	if m.guardState == GuardEmergency {
		m.mu.Unlock()
		releaseGate()
		return nil, fmt.Errorf("%w: Host befindet sich im Notfallschutz", localinference.ErrGuardRejected)
	}
	now := time.Now().UTC()
	leaseGeneration := expectedGeneration
	leaseSecret := expectedSecret
	instance.ActiveRequests++
	instance.LastUsedAt = &now
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = now
	snapshot := cloneInstance(instance)
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)

	var once sync.Once
	return func() {
		once.Do(func() {
			releaseGate()
			m.mu.Lock()
			current := m.instances[instanceID]
			if current == nil {
				m.mu.Unlock()
				return
			}
			if current.workerGeneration != leaseGeneration || current.WorkerSecret != leaseSecret {
				m.mu.Unlock()
				return
			}
			if current.ActiveRequests > 0 {
				current.ActiveRequests--
			}
			now := time.Now().UTC()
			current.LastUsedAt = &now
			if current.State == engineruntime.StateReady && current.ActiveRequests == 0 && !current.Autostart && !current.Pinned {
				expires := now.Add(m.effectiveIdleTimeout())
				current.IdleExpiresAt = &expires
			}
			current.UpdatedAt = now
			snapshot := cloneInstance(current)
			_ = m.persistLocked()
			m.mu.Unlock()
			m.events.publish("instance_changed", snapshot)
		})
	}, nil
}

func (m *EngineModule) effectiveIdleTimeout() time.Duration {
	if m.idleTimeout <= 0 {
		return 15 * time.Minute
	}
	return m.idleTimeout
}

func (m *EngineModule) gatewayAcquireInference(ctx context.Context, instanceID string) (func(), error) {
	return m.acquireInference(ctx, instanceID)
}
