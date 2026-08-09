package engine

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func (m *EngineModule) loadState() error {
	data, err := os.ReadFile(m.stateFile)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return err
	}
	var state persistedEngineState
	if err := json.Unmarshal(data, &state); err != nil {
		return fmt.Errorf("Engine-Zustand ungueltig: %w", err)
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	m.planRevision = state.PlanRevision
	for _, instance := range state.Instances {
		if instance == nil || strings.TrimSpace(instance.ID) == "" {
			continue
		}
		instance.State = engineruntime.StateStopped
		instance.Progress = 0
		instance.Phase = "stopped"
		instance.DetailMessage = "Das Backend wurde neu gestartet; lokale Modelle werden nur bei aktiviertem Autostart erneut geladen."
		instance.BaseURL = ""
		instance.WorkerSecret = ""
		instance.ShowInChatPicker = false
		instance.ActiveRequests = 0
		instance.LastUsedAt = nil
		instance.IdleExpiresAt = nil
		instance.GuardState = m.guardState
		instance.Placement = placementForPlan(instance.Plan)
		if instance.RuntimeOptionsNil() {
			instance.RequestedConfig.RuntimeOptions = map[string]interface{}{}
		}
		if instance.RequestedConfig.GenerationDefaults == nil {
			instance.RequestedConfig.GenerationDefaults = map[string]interface{}{}
		}
		m.instances[instance.ID] = instance
	}
	for _, operation := range state.Operations {
		if operation == nil || operation.ID == "" {
			continue
		}
		if operation.State == "queued" || operation.State == "running" {
			operation.State = "failed"
			operation.Phase = "backend_restarted"
			operation.Error = "Backend wurde waehrend des Vorgangs beendet"
			operation.ErrorCode = "backend_restarted"
			operation.ErrorSummary = "Das Backend wurde waehrend dieses Vorgangs beendet. Der Vorgang kann sicher erneut gestartet werden."
			operation.DetailMessage = operation.ErrorSummary
			operation.Progress = 1
			now := time.Now().UTC()
			operation.FinishedAt = &now
		}
		if operation.Phase == "" {
			operation.Phase = operation.State
		}
		if operation.Error != "" && operation.ErrorSummary == "" {
			operation.ErrorCode, operation.ErrorSummary = classifyEngineError(errors.New(operation.Error))
		}
		if operation.DetailMessage == "" {
			if operation.ErrorSummary != "" {
				operation.DetailMessage = operation.ErrorSummary
			} else {
				operation.DetailMessage = operation.Message
			}
		}
		m.operations[operation.ID] = operation
	}
	return m.persistLocked()
}

func (instance *EngineInstance) RuntimeOptionsNil() bool {
	return instance.RequestedConfig.RuntimeOptions == nil
}

func (m *EngineModule) persistLocked() error {
	state := persistedEngineState{SchemaVersion: 1, PlanRevision: m.planRevision}
	ids := make([]string, 0, len(m.instances))
	for id := range m.instances {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	for _, id := range ids {
		copy := cloneInstance(m.instances[id])
		copy.BaseURL = ""
		copy.WorkerSecret = ""
		copy.ShowInChatPicker = false
		copy.ActiveRequests = 0
		copy.IdleExpiresAt = nil
		state.Instances = append(state.Instances, copy)
	}
	operations := make([]*EngineOperation, 0, len(m.operations))
	for _, operation := range m.operations {
		copy := *operation
		copy.cancel = nil
		operations = append(operations, &copy)
	}
	sort.Slice(operations, func(i, j int) bool { return operations[i].CreatedAt.Before(operations[j].CreatedAt) })
	if len(operations) > 100 {
		operations = operations[len(operations)-100:]
	}
	state.Operations = operations
	payload, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}
	return atomicPrivateWrite(m.stateFile, append(payload, '\n'))
}

func cloneInstance(instance *EngineInstance) *EngineInstance {
	if instance == nil {
		return nil
	}
	copy := *instance
	copy.RequestedConfig = cloneEngineConfig(instance.RequestedConfig)
	copy.EffectiveConfig = cloneEngineConfig(instance.EffectiveConfig)
	copy.RestartRequiredFields = append([]string(nil), instance.RestartRequiredFields...)
	copy.Fallbacks = append([]engineruntime.Fallback(nil), instance.Fallbacks...)
	if instance.Plan != nil {
		plan := *instance.Plan
		plan.Warnings = append([]string(nil), instance.Plan.Warnings...)
		plan.AffectedRestartInstances = append([]string(nil), instance.Plan.AffectedRestartInstances...)
		copy.Plan = &plan
	}
	if instance.LastKnownGood != nil {
		lkg := *instance.LastKnownGood
		lkg.EffectiveConfig = cloneEngineConfig(instance.LastKnownGood.EffectiveConfig)
		copy.LastKnownGood = &lkg
	}
	copy.SuggestedFix = suggestedFixForCode(instance.ErrorCode)
	return &copy
}

func (m *EngineModule) listInstances() []*EngineInstance {
	m.mu.RLock()
	defer m.mu.RUnlock()
	result := make([]*EngineInstance, 0, len(m.instances))
	for _, instance := range m.instances {
		copy := cloneInstance(instance)
		copy.ShowInChatPicker = false
		copy.Placement = placementForPlan(copy.Plan)
		copy.GuardState = m.guardState
		result = append(result, copy)
	}
	sort.Slice(result, func(i, j int) bool { return result[i].CreatedAt.Before(result[j].CreatedAt) })
	return result
}

func (m *EngineModule) listInstancesForUser(userID string) []*EngineInstance {
	instances := m.listInstances()
	for _, instance := range instances {
		instance.ShowInChatPicker = m.preferences != nil && m.preferences.visible(userID, instance.ID)
	}
	return instances
}

func (m *EngineModule) instanceForUser(instance *EngineInstance, userID string) *EngineInstance {
	copy := cloneInstance(instance)
	if copy == nil {
		return nil
	}
	copy.ShowInChatPicker = m.preferences != nil && m.preferences.visible(userID, copy.ID)
	copy.Placement = placementForPlan(copy.Plan)
	m.mu.RLock()
	copy.GuardState = m.guardState
	m.mu.RUnlock()
	return copy
}
