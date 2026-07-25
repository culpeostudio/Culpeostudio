package engine

import (
	"context"
	"errors"
	"fmt"
	"sync/atomic"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
)

type unconfirmedSupervisorStopError struct {
	handle *engineruntime.InstanceHandle
	cause  error
}

func (e *unconfirmedSupervisorStopError) Error() string { return e.cause.Error() }
func (e *unconfirmedSupervisorStopError) Unwrap() error { return e.cause }

type engineStopMarker struct {
	state            engineruntime.InstanceState
	phase            string
	workerGeneration uint64
	instance         *EngineInstance
}

type confirmedStopTarget struct {
	supervisor    *engineruntime.Supervisor
	handle        *engineruntime.InstanceHandle
	engineMarker  engineStopMarker
	hadSupervisor bool
	receiptID     uint64
}

const confirmedStopReceiptTTL = 2 * time.Minute

var confirmedStopReceiptSequence atomic.Uint64

func (m *EngineModule) captureStopTarget(instanceID string) confirmedStopTarget {
	target := confirmedStopTarget{supervisor: m.supervisor, hadSupervisor: m.supervisor != nil}
	if m.supervisor != nil {
		target.handle, _ = m.supervisor.Instance(instanceID)
	}
	m.mu.RLock()
	if instance := m.instances[instanceID]; instance != nil {
		target.engineMarker = engineStopMarker{
			state:            instance.State,
			phase:            instance.Phase,
			workerGeneration: instance.workerGeneration,
			instance:         instance,
		}
	}
	m.mu.RUnlock()
	return target
}

func (m *EngineModule) clearConfirmedStop(instanceID string) {
	m.confirmedStopMu.Lock()
	delete(m.confirmedStops, instanceID)
	m.confirmedStopMu.Unlock()
}

func (m *EngineModule) recordConfirmedStop(instanceID string, target confirmedStopTarget) {
	target.receiptID = confirmedStopReceiptSequence.Add(1)
	m.confirmedStopMu.Lock()
	if m.confirmedStops == nil {
		m.confirmedStops = map[string]confirmedStopTarget{}
	}
	m.confirmedStops[instanceID] = target
	m.confirmedStopMu.Unlock()
	time.AfterFunc(confirmedStopReceiptTTL, func() {
		m.expireConfirmedStop(instanceID, target.receiptID)
	})
}

func (m *EngineModule) expireConfirmedStop(instanceID string, receiptID uint64) {
	m.confirmedStopMu.Lock()
	if current, exists := m.confirmedStops[instanceID]; exists && current.receiptID == receiptID {
		delete(m.confirmedStops, instanceID)
	}
	m.confirmedStopMu.Unlock()
}

func (m *EngineModule) takeConfirmedStop(instanceID string) (confirmedStopTarget, bool) {
	m.confirmedStopMu.Lock()
	target, exists := m.confirmedStops[instanceID]
	delete(m.confirmedStops, instanceID)
	m.confirmedStopMu.Unlock()
	return target, exists
}

// stopSupervisorConfirmed never treats a timeout as proof that memory was
// released. A successful return requires either no managed handle or an
// observable terminal Supervisor snapshot whose process watcher has reaped the
// worker.
func (m *EngineModule) stopSupervisorConfirmed(ctx context.Context, instanceID string) error {
	m.clearConfirmedStop(instanceID)
	target := m.captureStopTarget(instanceID)
	if target.supervisor == nil {
		m.recordConfirmedStop(instanceID, target)
		return nil
	}
	handle := target.handle
	if handle == nil {
		m.recordConfirmedStop(instanceID, target)
		return nil
	}
	stopErr := target.supervisor.StopHandle(ctx, handle)
	snapshot := handle.Snapshot()
	if terminalSupervisorState(snapshot.State) {
		m.recordConfirmedStop(instanceID, target)
		return nil
	}
	if stopErr != nil {
		return &unconfirmedSupervisorStopError{
			handle: handle,
			cause:  fmt.Errorf("Modellprozess %s konnte nicht bestaetigt beendet werden (Supervisor-Zustand %s): %w", instanceID, snapshot.State, stopErr),
		}
	}
	return &unconfirmedSupervisorStopError{
		handle: handle,
		cause:  fmt.Errorf("Modellprozess %s meldete keinen Stop-Fehler, ist aber weiterhin %s", instanceID, snapshot.State),
	}
}

func (m *EngineModule) forceStopSupervisorConfirmed(ctx context.Context, instanceID string) error {
	m.clearConfirmedStop(instanceID)
	target := m.captureStopTarget(instanceID)
	if target.supervisor == nil {
		m.recordConfirmedStop(instanceID, target)
		return nil
	}
	handle := target.handle
	if handle == nil {
		m.recordConfirmedStop(instanceID, target)
		return nil
	}
	stopErr := target.supervisor.ForceStopHandle(ctx, handle)
	snapshot := handle.Snapshot()
	if terminalSupervisorState(snapshot.State) {
		m.recordConfirmedStop(instanceID, target)
		return nil
	}
	if stopErr != nil {
		return &unconfirmedSupervisorStopError{
			handle: handle,
			cause:  fmt.Errorf("Modellprozess %s konnte nicht bestaetigt zwangsbeendet werden (Supervisor-Zustand %s): %w", instanceID, snapshot.State, stopErr),
		}
	}
	return &unconfirmedSupervisorStopError{
		handle: handle,
		cause:  fmt.Errorf("Modellprozess %s meldete keinen Force-Stop-Fehler, ist aber weiterhin %s", instanceID, snapshot.State),
	}
}

func (m *EngineModule) markStopUnconfirmed(instanceID, phase, detail string, cause error) {
	// Capture the supervisor generation before publishing the unconfirmed
	// state. A later Start is allowed to replace a terminal handle under the
	// same instance ID, so a background reaper must never resolve the handle by
	// ID again.
	var stopHandle *engineruntime.InstanceHandle
	var stopFailure *unconfirmedSupervisorStopError
	if errors.As(cause, &stopFailure) {
		stopHandle = stopFailure.handle
	} else if m.supervisor != nil {
		stopHandle, _ = m.supervisor.Instance(instanceID)
	}
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil || instance.State == engineruntime.StateStopped {
		m.mu.Unlock()
		return
	}
	instance.State = engineruntime.StateDraining
	instance.Phase = phase
	instance.DetailMessage = detail
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.IdleExpiresAt = nil
	if cause != nil {
		instance.Error = cause.Error()
		instance.ErrorCode = "worker_stop_unconfirmed"
		instance.ErrorSummary = "Der Modellprozess ist fuer neue Anfragen gesperrt, seine Beendigung wurde aber noch nicht bestaetigt."
	}
	instance.UpdatedAt = time.Now().UTC()
	marker := unconfirmedStopMarker{
		phase:            phase,
		updatedAt:        instance.UpdatedAt,
		workerGeneration: instance.workerGeneration,
		instance:         instance,
	}
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
	m.requestConfirmedStopReaper(instanceID, stopHandle, marker)
}

// finalizeConfirmedStop must only be called after stopSupervisorConfirmed (or
// a terminal Supervisor watcher event) established that no worker remains.
func (m *EngineModule) finalizeConfirmedStop(instanceID, phase, detail string) {
	target, exists := m.takeConfirmedStop(instanceID)
	if !exists {
		return
	}
	m.finalizeStopTarget(instanceID, target, phase, detail)
}

func (m *EngineModule) finalizeStopTarget(instanceID string, target confirmedStopTarget, phase, detail string) bool {
	if target.hadSupervisor {
		// The EngineModule never swaps supervisors during normal operation, but
		// treat doing so as a generation change instead of trusting an old
		// receipt.
		if m.supervisor != target.supervisor || target.supervisor == nil {
			return false
		}
		current, currentExists := target.supervisor.Instance(instanceID)
		if target.handle == nil {
			if currentExists {
				return false
			}
		} else {
			if !currentExists || current != target.handle || !terminalSupervisorState(target.handle.Snapshot().State) {
				return false
			}
		}
	}

	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil ||
		instance != target.engineMarker.instance ||
		instance.State != target.engineMarker.state ||
		instance.Phase != target.engineMarker.phase ||
		instance.workerGeneration != target.engineMarker.workerGeneration {
		m.mu.Unlock()
		return false
	}
	instance.State = engineruntime.StateStopped
	instance.Phase = phase
	instance.DetailMessage = detail
	instance.Progress = 0
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.ActiveRequests = 0
	instance.IdleExpiresAt = nil
	instance.Error = ""
	instance.ErrorCode = ""
	instance.ErrorSummary = ""
	instance.UpdatedAt = time.Now().UTC()
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
	return true
}

type unconfirmedStopMarker struct {
	phase            string
	updatedAt        time.Time
	workerGeneration uint64
	instance         *EngineInstance
}

func (m *EngineModule) requestConfirmedStopReaper(instanceID string, handle *engineruntime.InstanceHandle, marker unconfirmedStopMarker) {
	// A stop error without a managed process cannot occur in the normal engine
	// lifecycle. More importantly, looking a handle up later by instance ID
	// could target a replacement generation.
	if handle == nil {
		return
	}
	reaperID := fmt.Sprintf("%s/%d/%d/%p", instanceID, marker.workerGeneration, marker.updatedAt.UnixNano(), handle)
	m.stopReaperMu.Lock()
	if m.stopReapers == nil {
		m.stopReapers = map[string]bool{}
	}
	if m.stopReapers[reaperID] {
		m.stopReaperMu.Unlock()
		return
	}
	m.stopReapers[reaperID] = true
	m.stopReaperMu.Unlock()
	go m.reapUnconfirmedStop(instanceID, handle, marker, reaperID)
}

func (m *EngineModule) reapUnconfirmedStop(instanceID string, handle *engineruntime.InstanceHandle, marker unconfirmedStopMarker, reaperID string) {
	defer func() {
		m.stopReaperMu.Lock()
		delete(m.stopReapers, reaperID)
		m.stopReaperMu.Unlock()
	}()
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()
	for {
		select {
		case <-m.maintenanceStop:
			return
		case <-handle.Done():
		case <-ticker.C:
		}
		if terminalSupervisorState(handle.Snapshot().State) {
			m.finalizeReapedStop(instanceID, handle, marker)
			return
		}
	}
}

// finalizeReapedStop is a compare-and-swap over both the supervisor handle and
// the engine-side unconfirmed-stop marker. A stale watcher is therefore unable
// to turn a newly committed Ready worker into Stopped.
func (m *EngineModule) finalizeReapedStop(instanceID string, handle *engineruntime.InstanceHandle, marker unconfirmedStopMarker) bool {
	return m.finalizeStopTarget(instanceID, confirmedStopTarget{
		supervisor:    m.supervisor,
		handle:        handle,
		hadSupervisor: m.supervisor != nil,
		engineMarker: engineStopMarker{
			state:            engineruntime.StateDraining,
			phase:            marker.phase,
			workerGeneration: marker.workerGeneration,
			instance:         marker.instance,
		},
	}, "stop_confirmed", "Die Beendigung des Modellprozesses wurde nachtraeglich vom Prozesswaechter bestaetigt.")
}
