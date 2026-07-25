package engine

import (
	"context"
	"sort"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
)

func (m *EngineModule) failTransaction(operationID, primaryID string, backups map[string]*EngineInstance, started []string, cause error) {
	m.failTransactionScoped(operationID, primaryID, backups, started, cause, nil, nil)
}

func (m *EngineModule) failTransactionBlocked(operationID, primaryID string, backups map[string]*EngineInstance, started []string, cause error, blocked map[string]bool) {
	m.failTransactionScoped(operationID, primaryID, backups, started, cause, blocked, nil)
}

// failTransactionScoped rolls back only workers whose previous process was
// observably stopped. When eligible is non-nil, Ready backups outside that set
// are still-running old workers and are restored in-place without spawning a
// duplicate process.
func (m *EngineModule) failTransactionScoped(operationID, primaryID string, backups map[string]*EngineInstance, started []string, cause error, blocked, eligible map[string]bool) {
	if blocked == nil {
		blocked = map[string]bool{}
	}
	scoped := eligible != nil
	if eligible == nil {
		eligible = map[string]bool{}
		for id, backup := range backups {
			if backup != nil && backup.State == engineruntime.StateReady {
				eligible[id] = true
			}
		}
	}
	m.mu.RLock()
	operationWasCancelled := m.operations[operationID] != nil && m.operations[operationID].State == "cancelled"
	m.mu.RUnlock()
	for _, id := range started {
		stopCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		stopErr := m.stopSupervisorConfirmed(stopCtx, id)
		cancel()
		if stopErr != nil {
			blocked[id] = true
			m.markStopUnconfirmed(id, "rollback_stop_unconfirmed", "Rollback wurde fuer diese Instanz angehalten, weil ihr neuer Modellprozess nicht bestaetigt beendet ist.", stopErr)
		} else {
			eligible[id] = true
		}
	}
	ids := make([]string, 0, len(backups))
	for id := range backups {
		ids = append(ids, id)
	}
	sort.Strings(ids)

	if m.isShuttingDown() {
		for _, id := range ids {
			backup := backups[id]
			if backup == nil || blocked[id] {
				continue
			}
			if scoped && !eligible[id] && backup.State == engineruntime.StateReady {
				m.restoreInstanceSnapshot(id, backup)
				continue
			}
			if eligible[id] {
				m.finalizeConfirmedStop(id, "shutdown", "Die Instanz bleibt nach dem Engine-Shutdown gestoppt; ein Rollback wurde nicht neu gestartet.")
			}
		}
		if backup := backups[primaryID]; backup == nil || backup.State != engineruntime.StateReady {
			m.setInstanceState(primaryID, engineruntime.StateStopped, 0, "")
		}
		m.setOperationDetail(operationID, "cancelled", 1, "shutdown", "Vorgang wegen Engine-Shutdown ohne Respawn beendet", "Zum sicheren Herunterfahren wurde kein Rollback-Prozess neu gestartet.", context.Canceled)
		return
	}

	rollbackFailed := len(blocked) > 0
	restored := map[string]bool{}
	for _, id := range ids {
		if blocked[id] {
			continue
		}
		backup := backups[id]
		if backup == nil || backup.State != engineruntime.StateReady {
			continue
		}
		if scoped && !eligible[id] {
			m.restoreInstanceSnapshot(id, backup)
			restored[id] = true
			continue
		}
		if backup.LastKnownGood == nil {
			rollbackFailed = true
			m.setInstanceState(id, engineruntime.StateFailedRollback, 1, "Letzter funktionierender Plan fuer Rollback fehlt")
			continue
		}
		lkg := backup.LastKnownGood
		m.mu.Lock()
		if current := m.instances[id]; current != nil {
			current.RequestedConfig = cloneEngineConfig(backup.RequestedConfig)
			current.Autostart = backup.Autostart
			current.Priority = backup.Priority
			current.Pinned = backup.Pinned
			current.PlanRevision = backup.PlanRevision
		}
		m.mu.Unlock()
		rollbackCtx, cancelRollback := context.WithTimeout(context.Background(), 2*time.Minute)
		err := m.startOne(rollbackCtx, id, lkg.EffectiveConfig, lkg.Plan, operationID)
		cancelRollback()
		if err != nil {
			rollbackFailed = true
			m.setInstanceState(id, engineruntime.StateFailedRollback, 1, err.Error())
		} else {
			restored[id] = true
		}
	}
	primaryRestored := restored[primaryID]
	if !primaryRestored {
		if blocked[primaryID] {
			if !operationWasCancelled {
				m.setOperation(operationID, "failed", 1, "Zielplan fehlgeschlagen; Prozessbeendigung fuer Rollback unbestaetigt", cause)
			}
			return
		}
		if operationWasCancelled && !rollbackFailed {
			m.setInstanceState(primaryID, engineruntime.StateStopped, 0, "Vorgang wurde abgebrochen")
			return
		}
		state := engineruntime.StateFailed
		if rollbackFailed {
			state = engineruntime.StateFailedRollback
		}
		m.setInstanceState(primaryID, state, 1, cause.Error())
	}
	if !operationWasCancelled {
		m.setOperation(operationID, "failed", 1, "Zielplan fehlgeschlagen; letzter funktionierender Plan wurde wiederhergestellt", cause)
	}
}

func (m *EngineModule) restoreInstanceSnapshot(instanceID string, backup *EngineInstance) {
	if backup == nil {
		return
	}
	m.mu.Lock()
	if m.instances[instanceID] == nil {
		m.mu.Unlock()
		return
	}
	merged := mergeLiveWorkerRollback(m.instances[instanceID], backup)
	m.instances[instanceID] = merged
	snapshot := cloneInstance(merged)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
}

// mergeLiveWorkerRollback restores requested config/plan fields without
// rewinding volatile accounting which may have changed while a Ready restart
// deliberately kept the old worker routable during queue/runtime preparation.
func mergeLiveWorkerRollback(current, backup *EngineInstance) *EngineInstance {
	if backup == nil {
		return nil
	}
	if current == nil || backup.State != engineruntime.StateReady {
		return cloneInstance(backup)
	}
	if current.workerGeneration != backup.workerGeneration {
		// A newer verified worker owns all current metadata. A stale transaction
		// must not rewrite its model/config while attempting to restore the old
		// generation.
		return cloneInstance(current)
	}
	routingMatches := current.WorkerSecret == backup.WorkerSecret &&
		current.BaseURL == backup.BaseURL
	routingCleared := current.WorkerSecret == "" && current.BaseURL == ""
	if !routingMatches && !routingCleared {
		// A non-empty, different endpoint/secret is another worker identity even
		// if a buggy or legacy caller failed to advance the generation marker.
		return cloneInstance(current)
	}
	transactionDrain := current.State == engineruntime.StateDraining && current.Phase == "draining"
	if routingCleared || (current.State != engineruntime.StateReady && !transactionDrain) {
		// Emergency/stop state wins absolutely. The unchanged generation proves
		// this is still the old worker, so only requested transaction metadata may
		// be rolled back; stale routing is never resurrected.
		restored := cloneInstance(current)
		restored.ModelID = backup.ModelID
		restored.RequestedConfig = cloneEngineConfig(backup.RequestedConfig)
		restored.Priority = backup.Priority
		restored.Pinned = backup.Pinned
		restored.Autostart = backup.Autostart
		restored.PlanRevision = backup.PlanRevision
		return restored
	}
	restored := cloneInstance(backup)
	restored.ActiveRequests = current.ActiveRequests
	restored.LastUsedAt = cloneTimePointer(current.LastUsedAt)
	restored.IdleExpiresAt = cloneTimePointer(current.IdleExpiresAt)
	restored.BaseURL = current.BaseURL
	restored.WorkerSecret = current.WorkerSecret
	restored.workerGeneration = current.workerGeneration
	restored.GuardState = current.GuardState
	restored.UpdatedAt = current.UpdatedAt
	// A Draining state with the generic transaction phase was set immediately
	// before waiting and can safely reopen because the worker identity matches.
	// Emergency/pressure phases took the non-resurrection branch above.
	restored.State = engineruntime.StateReady
	return restored
}

func cloneTimePointer(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}
