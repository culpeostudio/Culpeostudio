package engine

import (
	"context"
	"errors"
	"os"
	"time"

	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/engineruntime"
)

func (m *EngineModule) scheduleStop(instanceID string) (*EngineOperation, error) {
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.Unlock()
		return nil, os.ErrNotExist
	}
	operation, ctx := m.newOperationLocked("stop", instanceID, "Instanz wird bis zu 30 Sekunden drainiert")
	activeStartID := ""
	if active := m.activeStartOperationLocked(instanceID); active != nil {
		activeStartID = active.ID
	}
	alreadyStopped := instance.State == engineruntime.StateStopped || instance.State == engineruntime.StateFailed || instance.State == engineruntime.StateFailedRollback
	_ = m.persistLocked()
	m.mu.Unlock()
	if activeStartID != "" {
		_, _ = m.cancelOperation(activeStartID)
	}
	go func() {
		releaseLifecycle, err := m.acquireLifecycle(ctx, false)
		if err != nil {
			m.setOperationDetail(operation.ID, "cancelled", 1, "shutdown", "Stop-Vorgang wurde waehrend Shutdown uebernommen", err.Error(), err)
			return
		}
		defer releaseLifecycle()
		if alreadyStopped {
			m.setInstanceState(instanceID, engineruntime.StateStopped, 0, "")
			m.setOperation(operation.ID, "completed", 1, "Instanz war bereits gestoppt", nil)
			return
		}
		m.setOperation(operation.ID, "running", 0.2, "Anfragen werden drainiert", nil)
		m.setInstanceState(instanceID, engineruntime.StateDraining, 0.2, "")
		stopCtx, cancel := context.WithTimeout(ctx, 32*time.Second)
		err = m.waitForInstanceDrain(stopCtx, instanceID)

		if err == nil || errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
			err = m.stopSupervisorConfirmed(stopCtx, instanceID)
		}
		cancel()
		if err != nil {
			m.markStopUnconfirmed(instanceID, "stop_unconfirmed", "Der Modellprozess ist gesperrt, aber seine Beendigung konnte noch nicht bestaetigt werden.", err)
			m.setOperation(operation.ID, "failed", 1, "Stoppen fehlgeschlagen", err)
			return
		}
		m.mu.Lock()
		if current := m.instances[instanceID]; current != nil {
			current.State = engineruntime.StateStopped
			current.Progress = 0
			current.Phase = "stopped"
			current.DetailMessage = defaultInstanceDetail(engineruntime.StateStopped)
			current.BaseURL = ""
			current.WorkerSecret = ""
			current.ActiveRequests = 0
			current.IdleExpiresAt = nil
			current.UpdatedAt = time.Now().UTC()
			instance = current
		}
		snapshot := cloneInstance(instance)
		_ = m.persistLocked()
		m.mu.Unlock()
		m.events.publish("instance_changed", snapshot)
		if ctx.Err() != nil {
			return
		}
		m.setOperation(operation.ID, "completed", 1, "Instanz wurde gestoppt", nil)
		bus.Get().Emit("engine", bus.EventEngineStopped, map[string]interface{}{"instance_id": instanceID})
	}()
	return cloneOperation(operation), nil
}

func (m *EngineModule) scheduleStopWithReason(instanceID, phase, message string) (*EngineOperation, error) {
	operation, err := m.scheduleStop(instanceID)
	if err != nil {
		return nil, err
	}
	m.mu.Lock()
	if current := m.operations[operation.ID]; current != nil {
		current.Phase = phase
		current.Message = message
		current.DetailMessage = message
		current.UpdatedAt = time.Now().UTC()
		operation = cloneOperation(current)
		_ = m.persistLocked()
	}
	m.mu.Unlock()
	m.events.publish("operation", operation)
	return operation, nil
}

func (m *EngineModule) waitForInstanceDrain(ctx context.Context, instanceID string) error {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()
	for {
		m.mu.RLock()
		instance := m.instances[instanceID]
		active := 0
		if instance != nil {
			active = instance.ActiveRequests
		}
		m.mu.RUnlock()
		if active == 0 {
			return nil
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
		}
	}
}

func (m *EngineModule) scheduleDelete(instanceID string) (*EngineInstance, *EngineOperation, error) {
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.Unlock()
		return nil, nil, os.ErrNotExist
	}
	snapshot := cloneInstance(instance)
	operation, ctx := m.newOperationLocked("delete", instanceID, "Instanz wird gestoppt und entfernt")
	_ = m.persistLocked()
	m.mu.Unlock()
	go func() {
		releaseLifecycle, err := m.acquireLifecycle(ctx, false)
		if err != nil {
			m.setOperationDetail(operation.ID, "cancelled", 1, "shutdown", "Loeschen wurde waehrend Shutdown abgebrochen", err.Error(), err)
			return
		}
		defer releaseLifecycle()
		m.setOperation(operation.ID, "running", 0.2, "Instanz wird drainiert", nil)
		m.setInstanceState(instanceID, engineruntime.StateDraining, 0.2, "")
		stopCtx, cancel := context.WithTimeout(ctx, 32*time.Second)
		drainErr := m.waitForInstanceDrain(stopCtx, instanceID)
		stopErr := drainErr
		if drainErr == nil || errors.Is(drainErr, context.DeadlineExceeded) || errors.Is(drainErr, context.Canceled) {
			stopErr = m.stopSupervisorConfirmed(stopCtx, instanceID)
		}
		cancel()
		if stopErr != nil {
			m.markStopUnconfirmed(instanceID, "delete_stop_unconfirmed", "Die Instanz bleibt erhalten, weil die Beendigung ihres Modellprozesses nicht bestaetigt ist.", stopErr)
			m.setOperation(operation.ID, "failed", 1, "Loeschen gestoppt: Prozessbeendigung ist unbestaetigt", stopErr)
			return
		}
		if ctx.Err() != nil {
			m.setOperation(operation.ID, "cancelled", 1, "Loeschen wurde abgebrochen", ctx.Err())
			return
		}
		m.mu.Lock()
		delete(m.instances, instanceID)
		_ = m.persistLocked()
		m.mu.Unlock()
		m.events.publish("instance_deleted", map[string]string{"id": instanceID})
		m.setOperation(operation.ID, "completed", 1, "Instanz wurde entfernt", nil)
	}()
	return snapshot, cloneOperation(operation), nil
}

func (m *EngineModule) currentPlanRevision() int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.planRevision
}

func intPointer(value int) *int { return &value }

func restartRequiredFields() []string {
	return []string{"runtime", "context_tokens", "gpu_layers", "threads", "tensor_parallel_size", "gpu_ids", "offload", "kv_cache_dtype", "max_sequences", "trust_remote_code"}
}
