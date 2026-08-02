package engine

import (
	"context"
	"errors"
	"log"
	"os"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
)

func (m *EngineModule) applyTargetPlansLocked(views map[string]ContextPlanView) {
	for id, view := range views {
		instance := m.instances[id]
		if instance == nil {
			continue
		}
		if instance.State != engineruntime.StateReady {
			copy := view
			instance.Plan = &copy
		}
		instance.PlanRevision = m.planRevision
		instance.UpdatedAt = time.Now().UTC()
	}
}

func (m *EngineModule) newOperationLocked(kind, instanceID, message string) (*EngineOperation, context.Context) {
	idSuffix, _ := randomHex(8)
	ctx, cancel := context.WithCancel(context.Background())
	now := time.Now().UTC()
	operation := &EngineOperation{
		ID: "op_" + idSuffix, Type: kind, State: "queued", InstanceID: strings.Clone(instanceID),
		Progress: 0, Phase: "queued", Message: message, DetailMessage: message,
		CreatedAt: now, UpdatedAt: now, cancel: cancel,
	}
	m.operations[operation.ID] = operation
	return operation, ctx
}

func (m *EngineModule) activeStartOperationLocked(instanceID string) *EngineOperation {
	if operationID := m.startExecutions[instanceID]; operationID != "" {
		if operation := m.operations[operationID]; operation != nil {
			return operation
		}
	}
	for _, operation := range m.operations {
		if operation.InstanceID != instanceID || terminalOperationState(operation.State) {
			continue
		}
		switch operation.Type {
		case "start", "restart", "ensure_ready", "autostart", "legacy_start":
			return operation
		}
	}
	return nil
}

func (m *EngineModule) enqueueStartOperationLocked(operation *EngineOperation, priority string) {
	if operation == nil || m.startQueue == nil {
		return
	}
	positions := m.startQueue.enqueue(operation.ID, priority)
	for operationID, position := range positions {
		if queued := m.operations[operationID]; queued != nil {
			queued.QueuePosition = position
		}
	}
}

func (m *EngineModule) syncStartQueuePositions(positions map[string]int) {
	m.mu.Lock()
	changed := make([]*EngineOperation, 0, len(positions))
	for operationID, position := range positions {
		if operation := m.operations[operationID]; operation != nil && operation.QueuePosition != position {
			operation.QueuePosition = position
			operation.UpdatedAt = time.Now().UTC()
			changed = append(changed, cloneOperation(operation))
		}
	}
	_ = m.persistLocked()
	m.mu.Unlock()
	for _, operation := range changed {
		m.events.publish("operation", operation)
	}
}

func (m *EngineModule) operation(id string) (*EngineOperation, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	operation := m.operations[id]
	return cloneOperation(operation), operation != nil
}

func cloneOperation(operation *EngineOperation) *EngineOperation {
	if operation == nil {
		return nil
	}
	copy := *operation
	copy.EvictedInstanceIDs = append([]string(nil), operation.EvictedInstanceIDs...)
	copy.ProtectedInstanceIDs = append([]string(nil), operation.ProtectedInstanceIDs...)
	copy.ReservedEvictionInstanceIDs = append([]string(nil), operation.ReservedEvictionInstanceIDs...)
	copy.SuggestedFix = suggestedFixForCode(operation.ErrorCode)
	copy.cancel = nil
	return &copy
}

func (m *EngineModule) setOperation(id, state string, progress float64, message string, operationErr error) {
	m.setOperationDetail(id, state, progress, state, message, message, operationErr)
}

func (m *EngineModule) setOperationDetail(id, state string, progress float64, phase, message, detail string, operationErr error) {
	m.mu.Lock()
	operation := m.operations[id]
	if operation == nil {
		m.mu.Unlock()
		return
	}
	if terminalOperationState(operation.State) && state != operation.State {
		m.mu.Unlock()
		return
	}
	previousState := operation.State
	previousPhase := operation.Phase
	operation.State = state
	if progress >= 0 {
		progress = clampProgress(progress)
		if !terminalOperationState(state) && progress < operation.Progress {
			progress = operation.Progress
		}
		operation.Progress = progress
	}
	if phase != "" {
		operation.Phase = phase
	}
	if message != "" {
		operation.Message = message
	}
	if detail != "" {
		operation.DetailMessage = detail
	}
	if operationErr != nil {
		operation.Error = operationErr.Error()
		operation.ErrorCode, operation.ErrorSummary = classifyEngineError(operationErr)
		if operation.DetailMessage == "" || operation.DetailMessage == operation.Message {
			operation.DetailMessage = operation.ErrorSummary
		}

		var conflict *ResourceConflictError
		if errors.As(operationErr, &conflict) {
			operation.ResourceConflict = conflict
		}
	} else if state == "completed" {
		operation.Error = ""
		operation.ErrorCode = ""
		operation.ErrorSummary = ""
		operation.ResourceConflict = nil
	}
	operation.UpdatedAt = time.Now().UTC()
	if terminalOperationState(state) {
		now := time.Now().UTC()
		operation.FinishedAt = &now
		operation.cancel = nil
	}
	copy := cloneOperation(operation)
	_ = m.persistLocked()
	m.mu.Unlock()
	if previousState != copy.State || previousPhase != copy.Phase || terminalOperationState(copy.State) {
		log.Printf("[engine-operation] id=%s instance=%s state=%s phase=%s progress=%.2f message=%q detail=%q error_code=%s error_summary=%q",
			copy.ID, copy.InstanceID, copy.State, copy.Phase, copy.Progress,
			sanitizeEngineLogText(copy.Message), sanitizeEngineLogText(copy.DetailMessage), copy.ErrorCode, sanitizeEngineLogText(copy.ErrorSummary))
	}
	m.events.publish("operation", copy)
}

func terminalOperationState(state string) bool {
	return state == "completed" || state == "failed" || state == "cancelled"
}

func clampProgress(progress float64) float64 {
	if progress < 0 {
		return 0
	}
	if progress > 1 {
		return 1
	}
	return progress
}

func sanitizeEngineLogText(value string) string {
	value = strings.Join(strings.Fields(value), " ")
	for _, key := range []string{"HF_TOKEN", "HUGGINGFACE_TOKEN", "OPENROUTER_TOKEN", "FEATHERLESS_TOKEN", "OPENAI_API_KEY", "ANTHROPIC_API_KEY"} {
		if secret := os.Getenv(key); secret != "" {
			value = strings.ReplaceAll(value, secret, "[redacted]")
		}
	}
	for cursor := 0; cursor < len(value); {
		indexFromCursor := strings.Index(strings.ToLower(value[cursor:]), "bearer ")
		if indexFromCursor < 0 {
			break
		}
		index := cursor + indexFromCursor
		if index < 0 {
			break
		}
		end := index + len("bearer ")
		for end < len(value) && value[end] != ' ' && value[end] != '\t' && value[end] != ',' && value[end] != ';' {
			end++
		}
		replacement := "Bearer [redacted]"
		value = value[:index] + replacement + value[end:]
		cursor = index + len(replacement)
	}
	if len(value) > 500 {
		value = value[:500] + "..."
	}
	return value
}

func (m *EngineModule) cancelOperation(id string) (*EngineOperation, error) {
	m.mu.Lock()
	operation := m.operations[id]
	if operation == nil {
		m.mu.Unlock()
		return nil, os.ErrNotExist
	}
	if operation.State == "completed" || operation.State == "failed" || operation.State == "cancelled" {
		copy := cloneOperation(operation)
		m.mu.Unlock()
		return copy, nil
	}
	cancel := operation.cancel
	operation.State = "cancelled"
	operation.Phase = "cancelled"
	operation.Message = "Vorgang wurde abgebrochen"
	operation.DetailMessage = "Der laufende Schritt wird beendet und bereits aktive Modelle bleiben nach Moeglichkeit verfuegbar."
	now := time.Now().UTC()
	operation.UpdatedAt = now
	operation.FinishedAt = &now
	copy := cloneOperation(operation)
	_ = m.persistLocked()
	m.mu.Unlock()
	if cancel != nil {
		cancel()
	}
	m.events.publish("operation", copy)
	return copy, nil
}
