package engine

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"time"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

type normalLRUCandidate struct {
	ID       string
	LastUsed time.Time
}

var errInstanceLRUReserved = errors.New("Instanz ist fuer eine laufende LRU-Freigabe reserviert")

func isRetryablePlanningConflict(err error) bool {
	var conflict *engineplanner.ConflictError
	return errors.As(err, &conflict)
}

// planWithNormalLRUExclusions is side-effect free. It incrementally simulates
// removing eligible instances in stable LRU order and stops at the smallest
// eviction set that makes the target plan feasible.
func planWithNormalLRUExclusions(candidates []normalLRUCandidate, attempt func(map[string]bool) error) ([]string, error) {
	excluded := map[string]bool{}
	var lastConflict error
	for index := 0; ; index++ {
		err := attempt(excluded)
		if err == nil {
			result := make([]string, 0, len(excluded))
			for _, candidate := range candidates {
				if excluded[candidate.ID] {
					result = append(result, candidate.ID)
				}
			}
			return result, nil
		}
		if !isRetryablePlanningConflict(err) {
			return nil, err
		}
		lastConflict = err
		if index >= len(candidates) {
			return nil, lastConflict
		}
		excluded[candidates[index].ID] = true
	}
}

func (m *EngineModule) normalLRUCandidates(primaryID string) []normalLRUCandidate {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.normalLRUCandidatesLocked(primaryID)
}

func (m *EngineModule) normalLRUCandidatesLocked(primaryID string) []normalLRUCandidate {
	return m.normalLRUCandidatesExcludingLocked(map[string]bool{primaryID: true})
}

func (m *EngineModule) normalLRUCandidatesExcludingLocked(excluded map[string]bool) []normalLRUCandidate {
	candidates := []normalLRUCandidate{}
	for _, instance := range m.instances {
		if excluded[instance.ID] || instance.State != engineruntime.StateReady || instance.ActiveRequests != 0 || instance.Autostart || instance.Pinned || m.activeOperationProtectsInstanceLocked(instance.ID) {
			continue
		}
		lastUsed := instance.CreatedAt
		if instance.LastUsedAt != nil {
			lastUsed = *instance.LastUsedAt
		}
		candidates = append(candidates, normalLRUCandidate{ID: instance.ID, LastUsed: lastUsed})
	}
	sort.Slice(candidates, func(left, right int) bool {
		if candidates[left].LastUsed.Equal(candidates[right].LastUsed) {
			return candidates[left].ID < candidates[right].ID
		}
		return candidates[left].LastUsed.Before(candidates[right].LastUsed)
	})
	return candidates
}

func (m *EngineModule) recommendationWithNormalLRU(ctx context.Context, modelID, instanceID string, config EngineConfig) (ContextPlanView, map[string]ContextPlanView, []string, error) {
	candidates := m.normalLRUCandidates(instanceID)
	var view ContextPlanView
	var views map[string]ContextPlanView
	evictions, err := planWithNormalLRUExclusions(candidates, func(excluded map[string]bool) error {
		var attemptErr error
		view, views, attemptErr = m.recommendationExcluding(ctx, modelID, instanceID, config, excluded)
		return attemptErr
	})
	return view, views, evictions, err
}

// recommendationWithNormalLRUEviction runs only after this operation owns the
// global start-admission slot and lifecycle mutex. Candidate claiming changes
// Ready->Draining under m.mu, atomically excluding new inference admissions.
func (m *EngineModule) recommendationWithNormalLRUEviction(ctx context.Context, modelID, instanceID string, config EngineConfig, operationID string) (ContextPlanView, map[string]ContextPlanView, error) {
	var view ContextPlanView
	var views map[string]ContextPlanView
	_, err := m.evictNormalLRUUntilPlannedWithClaim(ctx, func() *EngineInstance {
		return m.claimNormalLRUCandidateForOperation(operationID, instanceID)
	}, func() error {
		var attemptErr error
		view, views, attemptErr = m.recommendation(ctx, modelID, instanceID, config)
		return attemptErr
	}, func(candidate *EngineInstance) error {
		m.setOperationDetail(operationID, "running", 0.34, "lru_evicting", "Ungenutztes Modell wird entladen", "Die aelteste ungenutzte, nicht reservierte Instanz wird fuer den neuen Startplan freigegeben.", nil)
		if stopErr := m.stopClaimedNormalLRU(candidate.ID); stopErr != nil {
			return fmt.Errorf("LRU-Instanz %s konnte nicht sicher entladen werden: %w", candidate.ID, stopErr)
		}
		m.recordOperationLRUEviction(operationID, candidate.ID)
		return nil
	})
	return view, views, err
}

func (m *EngineModule) evictNormalLRUUntilPlanned(ctx context.Context, primaryID string, attempt func() error, evict func(*EngineInstance) error) ([]string, error) {
	return m.evictNormalLRUUntilPlannedWithClaim(ctx, func() *EngineInstance {
		return m.claimNormalLRUCandidate(primaryID)
	}, attempt, evict)
}

func (m *EngineModule) evictNormalLRUUntilPlannedWithClaim(ctx context.Context, claim func() *EngineInstance, attempt func() error, evict func(*EngineInstance) error) ([]string, error) {
	evicted := []string{}
	for {
		err := attempt()
		if err == nil || !isRetryablePlanningConflict(err) {
			return evicted, err
		}
		if ctx.Err() != nil {
			return evicted, ctx.Err()
		}
		candidate := claim()
		if candidate == nil {
			return evicted, err
		}
		if evictErr := evict(candidate); evictErr != nil {
			return evicted, evictErr
		}
		evicted = append(evicted, candidate.ID)
	}
}

func (m *EngineModule) validateLoadPeakWithNormalLRU(ctx context.Context, kind engineruntime.RuntimeKind, record modelcatalog.ModelRecord, plan ContextPlanView, operationID, primaryID string) (int64, error) {
	return m.evictNormalLRUUntilPeakAdmittedWithClaim(ctx, func() *EngineInstance {
		return m.claimNormalLRUCandidateForOperation(operationID, primaryID)
	}, func() (int64, error) {
		return m.validateLoadPeak(ctx, kind, record, plan)
	}, func(candidate *EngineInstance) error {
		m.setOperationDetail(operationID, "running", 0.63, "lru_peak_evicting", "Speicher fuer Lade-Peak wird freigegeben", "Eine weitere ungenutzte, nicht reservierte Instanz wird entladen, damit der konservative Lade-Peak die Hostreserve einhaelt.", nil)
		if err := m.stopClaimedNormalLRU(candidate.ID); err != nil {
			return err
		}
		m.recordOperationLRUEviction(operationID, candidate.ID)
		return m.validateOperationLRUEvictionsReleased(operationID)
	})
}

func (m *EngineModule) evictNormalLRUUntilPeakAdmitted(ctx context.Context, primaryID string, attempt func() (int64, error), evict func(*EngineInstance) error) (int64, error) {
	return m.evictNormalLRUUntilPeakAdmittedWithClaim(ctx, func() *EngineInstance {
		return m.claimNormalLRUCandidate(primaryID)
	}, attempt, evict)
}

func (m *EngineModule) evictNormalLRUUntilPeakAdmittedWithClaim(ctx context.Context, claim func() *EngineInstance, attempt func() (int64, error), evict func(*EngineInstance) error) (int64, error) {
	for {
		limit, err := attempt()
		if err == nil {
			return limit, nil
		}
		var peakConflict *ResourceConflictError
		if !errors.As(err, &peakConflict) {
			return 0, err
		}
		if ctx.Err() != nil {
			return 0, ctx.Err()
		}
		candidate := claim()
		if candidate == nil {
			return 0, err
		}
		if evictErr := evict(candidate); evictErr != nil {
			return 0, evictErr
		}
	}
}

// claimNormalLRUCandidate performs the final eligibility check immediately
// before eviction. ActiveRequests must still be exactly zero while holding the
// same mutex used by inference admission.
func (m *EngineModule) claimNormalLRUCandidate(primaryID string) *EngineInstance {
	m.mu.Lock()
	instance, snapshot := m.claimNormalLRUCandidateLocked(map[string]bool{primaryID: true})
	m.mu.Unlock()
	if snapshot != nil {
		m.events.publish("instance_changed", snapshot)
	}
	return instance
}

func (m *EngineModule) claimNormalLRUCandidateForOperation(operationID, primaryID string) *EngineInstance {
	m.mu.Lock()
	operation := m.operations[operationID]
	if operation == nil || terminalOperationState(operation.State) {
		m.mu.Unlock()
		return nil
	}
	protected := map[string]bool{primaryID: true}
	for _, id := range operation.ProtectedInstanceIDs {
		protected[id] = true
	}
	instance, snapshot := m.claimNormalLRUCandidateLocked(protected)
	if instance != nil {
		operation.ReservedEvictionInstanceIDs = uniqueStrings(append(operation.ReservedEvictionInstanceIDs, instance.ID))
		operation.UpdatedAt = time.Now().UTC()
		_ = m.persistLocked()
	}
	m.mu.Unlock()
	if snapshot != nil {
		m.events.publish("instance_changed", snapshot)
	}
	return instance
}

func (m *EngineModule) claimNormalLRUCandidateLocked(protected map[string]bool) (*EngineInstance, *EngineInstance) {
	candidates := m.normalLRUCandidatesExcludingLocked(protected)
	if len(candidates) == 0 {
		return nil, nil
	}
	instance := m.instances[candidates[0].ID]
	if instance == nil || instance.State != engineruntime.StateReady || instance.ActiveRequests != 0 || instance.Autostart || instance.Pinned {
		return nil, nil
	}
	instance.State = engineruntime.StateDraining
	instance.Phase = "lru_evicting"
	instance.DetailMessage = "Die Instanz wird als aeltestes ungenutztes Modell fuer einen neuen Startplan entladen."
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = time.Now().UTC()
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	return snapshot, snapshot
}

func (m *EngineModule) stopClaimedNormalLRU(instanceID string) error {
	if m.supervisor != nil {
		if handle, exists := m.supervisor.Instance(instanceID); exists {
			stopContext, cancel := context.WithTimeout(context.Background(), 32*time.Second)
			err := m.supervisor.Stop(stopContext, instanceID)
			cancel()
			if !terminalSupervisorState(handle.Snapshot().State) {
				if err == nil {
					err = fmt.Errorf("Prozess-Supervisor hat den LRU-Stopp nicht als beendet bestaetigt")
				}
				m.restoreClaimedNormalLRU(instanceID, handle, err)
				return err
			}
		}
	}
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.Unlock()
		return nil
	}
	if instance.State != engineruntime.StateDraining || instance.ActiveRequests != 0 {
		m.mu.Unlock()
		return fmt.Errorf("LRU-Kandidat hat sich waehrend des Stoppens geaendert")
	}
	instance.State = engineruntime.StateStopped
	instance.Progress = 0
	instance.Phase = "lru_evicted"
	instance.DetailMessage = "Die ungenutzte Instanz wurde fuer einen neuen Modellstart entladen."
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = time.Now().UTC()
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
	return nil
}

func terminalSupervisorState(state engineruntime.InstanceState) bool {
	return state == engineruntime.StateStopped || state == engineruntime.StateFailed || state == engineruntime.StateFailedRollback
}

// A stop timeout is not proof that resources were released. Keep the instance
// Draining/resource-holding (and therefore closed to new inference admission)
// until the Supervisor handle confirms its eventual exit.
func (m *EngineModule) restoreClaimedNormalLRU(instanceID string, handle *engineruntime.InstanceHandle, stopErr error) {
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.Unlock()
		return
	}
	instance.State = engineruntime.StateDraining
	instance.Progress = 1
	instance.Phase = "lru_stop_failed"
	instance.Error = stopErr.Error()
	instance.ErrorCode, instance.ErrorSummary = classifyEngineError(stopErr)
	instance.DetailMessage = instance.ErrorSummary
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = time.Now().UTC()
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
	go m.finishUnconfirmedNormalLRUStop(instanceID, handle)
}

func (m *EngineModule) finishUnconfirmedNormalLRUStop(instanceID string, handle *engineruntime.InstanceHandle) {
	if handle == nil {
		return
	}
	<-handle.Done()
	process := handle.Snapshot()
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil || instance.State != engineruntime.StateDraining || instance.Phase != "lru_stop_failed" {
		m.mu.Unlock()
		return
	}
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.ActiveRequests = 0
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = time.Now().UTC()
	if process.State == engineruntime.StateStopped {
		instance.State = engineruntime.StateStopped
		instance.Progress = 0
		instance.Phase = "lru_stop_confirmed"
		instance.Error = ""
		instance.ErrorCode = ""
		instance.ErrorSummary = ""
		instance.DetailMessage = "Der verzoegerte LRU-Stopp wurde vom Prozess-Supervisor bestaetigt."
	} else {
		instance.State = engineruntime.StateFailed
		instance.Progress = 1
		instance.Phase = "lru_worker_exited"
		if process.Error != "" {
			instance.Error = process.Error
		}
		instance.ErrorCode, instance.ErrorSummary = classifyEngineError(errors.New(instance.Error))
		instance.DetailMessage = instance.ErrorSummary
	}
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
}

func (m *EngineModule) setOperationProtectedInstances(operationID string, instanceIDs []string) {
	m.mu.Lock()
	operation := m.operations[operationID]
	if operation != nil && !terminalOperationState(operation.State) {
		operation.ProtectedInstanceIDs = uniqueStrings(append(operation.ProtectedInstanceIDs, instanceIDs...))
		operation.UpdatedAt = time.Now().UTC()
	}
	m.mu.Unlock()
}

func (m *EngineModule) activeLRUEvictionReservationLocked(instanceID string) string {
	for _, operation := range m.operations {
		if operation == nil || (terminalOperationState(operation.State) && !m.physicalStartOperationLocked(operation.ID)) {
			continue
		}
		for _, reservedID := range operation.ReservedEvictionInstanceIDs {
			if reservedID == instanceID {
				return operation.ID
			}
		}
	}
	return ""
}

func (m *EngineModule) recordOperationLRUEviction(operationID, instanceID string) {
	m.mu.Lock()
	operation := m.operations[operationID]
	if operation == nil {
		m.mu.Unlock()
		return
	}
	operation.EvictedInstanceIDs = uniqueStrings(append(operation.EvictedInstanceIDs, instanceID))
	operation.UpdatedAt = time.Now().UTC()
	snapshot := cloneOperation(operation)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("operation", snapshot)
}

func (m *EngineModule) validateOperationLRUEvictionsReleased(operationID string) error {
	m.mu.RLock()
	operation := m.operations[operationID]
	ids := []string{}
	if operation != nil {
		ids = append(ids, operation.EvictedInstanceIDs...)
	}
	for _, id := range ids {
		instance := m.instances[id]
		if instance == nil || instance.State != engineruntime.StateStopped || instance.ActiveRequests != 0 {
			m.mu.RUnlock()
			return fmt.Errorf("LRU-Freigabe fuer Instanz %s ist unmittelbar vor dem Spawn nicht mehr gueltig", id)
		}
	}
	m.mu.RUnlock()
	if m.supervisor != nil {
		for _, id := range ids {
			if handle, exists := m.supervisor.Instance(id); exists && !terminalSupervisorState(handle.Snapshot().State) {
				return fmt.Errorf("LRU-Prozess %s haelt unmittelbar vor dem Spawn weiterhin Ressourcen", id)
			}
		}
	}
	return nil
}
