package engine

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/localinference"
)

func (m *EngineModule) executePlanTransaction(ctx context.Context, operationID, primaryID string, views map[string]ContextPlanView, primaryConfig EngineConfig, seedBackups map[string]*EngineInstance) {
	// The UI status may become terminal immediately on cancellation, while the
	// physical transaction still owns queue/lifecycle cleanup and rollback.
	// Keep the instance reserved until every deferred queue action has run.
	defer m.finishStartExecution(primaryID, operationID)
	if m.startQueue != nil {
		waitTimeout := m.startQueueTimeout
		if waitTimeout <= 0 {
			waitTimeout = 10 * time.Minute
		}
		waitContext, cancelWait := context.WithTimeout(ctx, waitTimeout)
		waitErr := m.startQueue.wait(waitContext, operationID)
		cancelWait()
		if waitErr != nil {
			m.syncStartQueuePositions(m.startQueue.cancel(operationID))
			restoredReady := m.restoreQueuedStartBackup(primaryID, seedBackups)
			if errors.Is(waitErr, context.DeadlineExceeded) {
				queueErr := fmt.Errorf("%w: Modellstart wartete laenger als %s", localinference.ErrQueueTimeout, waitTimeout)
				if !restoredReady {
					m.setInstanceState(primaryID, engineruntime.StateFailed, 1, queueErr.Error())
				}
				m.setOperationDetail(operationID, "failed", 1, "queue_timeout", "Start-Warteschlange abgelaufen", queueErr.Error(), queueErr)
			} else if !restoredReady {
				m.markCancelledInstance(primaryID)
			}
			return
		}
		m.syncStartQueuePositions(m.startQueue.positions())
		defer func() { m.syncStartQueuePositions(m.startQueue.done(operationID)) }()
	}
	releaseLifecycle, lifecycleErr := m.acquireLifecycle(ctx, false)
	if lifecycleErr != nil {
		m.restoreBeforeDrainCancellation(primaryID, seedBackups)
		if m.isShuttingDown() {
			m.setOperationDetail(operationID, "cancelled", 1, "shutdown", "Start wegen Engine-Shutdown abgebrochen", lifecycleErr.Error(), lifecycleErr)
		}
		return
	}
	defer releaseLifecycle()
	m.setOperationDetail(operationID, "running", 0.05, "preparing_runtime", "Lokale Runtime wird vorbereitet", "Eine passende, isolierte Laufzeitumgebung wird gesucht oder installiert.", nil)
	m.mu.RLock()
	primary := m.instances[primaryID]
	if primary == nil {
		m.mu.RUnlock()
		m.setOperation(operationID, "failed", 1, "Instanz fehlt", os.ErrNotExist)
		return
	}
	primaryTarget := views[primaryID]
	restartIDs := append([]string(nil), primaryTarget.AffectedRestartInstances...)
	restartIDs = append(restartIDs, primaryID)
	restartIDs = uniqueStrings(restartIDs)
	backups := map[string]*EngineInstance{}
	for id, backup := range seedBackups {
		backups[id] = cloneInstance(backup)
	}
	configs := map[string]EngineConfig{}
	for _, id := range restartIDs {
		if existing := m.instances[id]; existing != nil {
			if backups[id] == nil {
				backups[id] = cloneInstance(existing)
			}
			configs[id] = cloneEngineConfig(existing.RequestedConfig)
		}
	}
	configs[primaryID] = cloneEngineConfig(primaryConfig)
	m.mu.RUnlock()
	m.setOperationProtectedInstances(operationID, restartIDs)

	preparedRuntime := map[string]bool{}
	for index, id := range restartIDs {
		if ctx.Err() != nil {
			m.restoreBeforeDrainCancellation(primaryID, backups)
			return
		}
		launch, err := m.prepareRuntime(ctx, id, configs[id], operationID)
		if err != nil {
			m.failBeforeDrain(operationID, primaryID, backups, err)
			return
		}
		if launch.forceCPU {
			config := cloneEngineConfig(configs[id])
			config.RuntimeOptions["force_cpu_runtime"] = true
			config.RuntimeOptions["offload"] = "cpu"
			configs[id] = config
			if id == primaryID {
				primaryConfig = config
			}
		}
		preparedRuntime[id] = true
		m.setOperationDetail(operationID, "running", 0.1+0.2*float64(index+1)/float64(len(restartIDs)), "runtime_ready", "Runtime ist bereit", "Die lokale Laufzeitumgebung wurde geprueft. Das aktuelle Speicherbudget wird jetzt noch einmal gemessen.", nil)
	}
	// Runtime-Installation can take minutes. Refresh byte-exact free RAM/VRAM
	// immediately before draining so foreign GPU load cannot make a stale plan
	// evict or shrink an existing model unexpectedly.
	m.mu.RLock()
	primaryNow := m.instances[primaryID]
	primaryModelID := ""
	if primaryNow != nil {
		primaryModelID = primaryNow.ModelID
	}
	m.mu.RUnlock()
	m.setOperationDetail(operationID, "running", 0.32, "refreshing_plan", "Speicherbudget wird aktualisiert", "Freier RAM und VRAM werden direkt vor dem Modellstart erneut gemessen.", nil)
	freshPrimary, freshViews, refreshErr := m.recommendationWithNormalLRUEviction(ctx, primaryModelID, primaryID, primaryConfig, operationID)
	if refreshErr != nil {
		m.failBeforeDrain(operationID, primaryID, backups, fmt.Errorf("Hardwarebudget hat sich waehrend der Vorbereitung geaendert: %w", refreshErr))
		return
	}
	views = freshViews
	restartIDs = uniqueStrings(append(append([]string(nil), freshPrimary.AffectedRestartInstances...), primaryID))
	m.setOperationProtectedInstances(operationID, restartIDs)
	m.mu.Lock()
	for _, id := range restartIDs {
		if existing := m.instances[id]; existing != nil {
			if backups[id] == nil {
				backups[id] = cloneInstance(existing)
			}
			if _, exists := configs[id]; !exists {
				configs[id] = cloneEngineConfig(existing.RequestedConfig)
			}
		}
	}
	m.applyTargetPlansLocked(views)
	_ = m.persistLocked()
	m.mu.Unlock()
	for _, id := range restartIDs {
		if preparedRuntime[id] {
			continue
		}
		launch, err := m.prepareRuntime(ctx, id, configs[id], operationID)
		if err != nil {
			m.failBeforeDrain(operationID, primaryID, backups, err)
			return
		}
		if launch.forceCPU {
			config := cloneEngineConfig(configs[id])
			config.RuntimeOptions["force_cpu_runtime"] = true
			config.RuntimeOptions["offload"] = "cpu"
			configs[id] = config
		}
		preparedRuntime[id] = true
	}

	started := []string{}
	stoppedOldIDs := map[string]bool{}
	for _, id := range restartIDs {
		backup := backups[id]
		if backup != nil && resourceHoldingState(backup.State) && m.supervisor != nil {
			m.setInstanceState(id, engineruntime.StateRestarting, 0.3, "")
			m.setInstanceState(id, engineruntime.StateDraining, 0.35, "")
			stopCtx, cancel := context.WithTimeout(ctx, 32*time.Second)
			drainErr := m.waitForInstanceDrain(stopCtx, id)
			if ctx.Err() != nil {
				cancel()
				m.failTransactionScoped(operationID, primaryID, backups, nil, ctx.Err(), nil, stoppedOldIDs)
				return
			}
			if drainErr != nil && !errors.Is(drainErr, context.DeadlineExceeded) {
				cancel()
				m.failTransactionScoped(operationID, primaryID, backups, nil, fmt.Errorf("Drain von %s fehlgeschlagen: %w", id, drainErr), nil, stoppedOldIDs)
				return
			}
			stopErr := m.stopSupervisorConfirmed(stopCtx, id)
			cancel()
			if stopErr != nil {
				m.markStopUnconfirmed(id, "restart_stop_unconfirmed", "Der Neustart wurde angehalten, weil die Beendigung des bisherigen Modellprozesses nicht bestaetigt ist.", stopErr)
				m.failTransactionScoped(operationID, primaryID, backups, nil, fmt.Errorf("Neustart von %s gestoppt: %w", id, stopErr), map[string]bool{id: true}, stoppedOldIDs)
				return
			}
			stoppedOldIDs[id] = true
		}
	}
	m.setOperationDetail(operationID, "running", 0.4, "starting_instances", "Modelle werden gestartet", "Die reservierte Zielkonfiguration wird jetzt lokal aktiviert.", nil)
	for index, id := range restartIDs {
		plan, ok := views[id]
		if !ok {
			continue
		}
		if err := m.startOne(ctx, id, configs[id], plan, operationID); err != nil {
			var unconfirmedStop *unconfirmedSupervisorStopError
			if errors.As(err, &unconfirmedStop) {
				m.failTransactionBlocked(operationID, primaryID, backups, started, err, map[string]bool{id: true})
			} else {
				m.failTransaction(operationID, primaryID, backups, started, err)
			}
			return
		}
		started = append(started, id)
		m.setOperationDetail(operationID, "running", 0.45+0.5*float64(index+1)/float64(len(restartIDs)), "instance_verified", "Modell wurde erfolgreich geprueft", "Der lokale Modellserver antwortet und der kurze Funktionstest war erfolgreich.", nil)
	}
	m.setOperationDetail(operationID, "completed", 1, "completed", "Modell ist bereit", "Die Konfiguration wurde aktiviert und das Modell kann jetzt verwendet werden.", nil)
	bus.Get().Emit("engine", bus.EventEngineStarted, map[string]interface{}{"instance_id": primaryID, "plan_revision": m.currentPlanRevision()})
}

func (m *EngineModule) finishStartExecution(instanceID, operationID string) {
	m.mu.Lock()
	if m.startExecutions[instanceID] == operationID {
		delete(m.startExecutions, instanceID)
	}
	m.mu.Unlock()
}

func (m *EngineModule) restoreBeforeDrainCancellation(primaryID string, backups map[string]*EngineInstance) {
	m.mu.Lock()
	restored := make([]*EngineInstance, 0, len(backups))
	for id, backup := range backups {
		current := m.instances[id]
		if backup == nil || current == nil {
			continue
		}
		merged := mergeLiveWorkerRollback(current, backup)
		m.instances[id] = merged
		restored = append(restored, cloneInstance(merged))
	}
	primaryWasReady := backups[primaryID] != nil && backups[primaryID].State == engineruntime.StateReady
	_ = m.persistLocked()
	m.mu.Unlock()
	for _, instance := range restored {
		m.events.publish("instance_changed", instance)
	}
	if primaryWasReady {
		return
	}
	m.markCancelledInstance(primaryID)
}

// restoreQueuedStartBackup restores every instance whose target plan was
// mutated before queue admission. A previously ready restart target remains
// exactly as routable and resource-holding as it was; no worker lifecycle
// action has happened yet.
func (m *EngineModule) restoreQueuedStartBackup(primaryID string, backups map[string]*EngineInstance) bool {
	m.mu.Lock()
	restored := make([]*EngineInstance, 0, len(backups))
	for id, backup := range backups {
		if backup == nil || m.instances[id] == nil {
			continue
		}
		merged := mergeLiveWorkerRollback(m.instances[id], backup)
		m.instances[id] = merged
		restored = append(restored, cloneInstance(merged))
	}
	_ = m.persistLocked()
	m.mu.Unlock()
	for _, instance := range restored {
		m.events.publish("instance_changed", instance)
	}
	backup := backups[primaryID]
	return backup != nil && backup.State == engineruntime.StateReady
}

func (m *EngineModule) failBeforeDrain(operationID, primaryID string, backups map[string]*EngineInstance, cause error) {
	m.mu.RLock()
	operationCancelled := m.operations[operationID] != nil && m.operations[operationID].State == "cancelled"
	m.mu.RUnlock()

	m.mu.Lock()
	restored := []*EngineInstance{}
	primaryBackup := backups[primaryID]
	for id, backup := range backups {
		current := m.instances[id]
		if backup == nil || current == nil {
			continue
		}
		if id == primaryID && backup.State != engineruntime.StateReady {
			continue
		}
		merged := mergeLiveWorkerRollback(current, backup)
		m.instances[id] = merged
		restored = append(restored, cloneInstance(merged))
	}
	_ = m.persistLocked()
	m.mu.Unlock()
	for _, instance := range restored {
		m.events.publish("instance_changed", instance)
	}

	if primaryBackup == nil || primaryBackup.State != engineruntime.StateReady {
		if operationCancelled {
			m.setInstanceState(primaryID, engineruntime.StateStopped, 0, "Vorgang wurde abgebrochen")
		} else {
			m.setInstanceState(primaryID, engineruntime.StateFailed, 1, cause.Error())
		}
	}
	if !operationCancelled {
		m.setOperation(operationID, "failed", 1, "Vorbereitung fehlgeschlagen; laufende Modelle wurden nicht unterbrochen", cause)
	}
}
