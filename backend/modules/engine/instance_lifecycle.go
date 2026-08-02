package engine

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
)

type trustRequiredError struct {
	Fingerprint string
	PythonHash  string
	FileCount   int
}

func (e *trustRequiredError) Error() string {
	return "Dieses Modell verlangt benutzerdefinierten Python-Code. Eine Zustimmung fuer den aktuellen Modell- und Python-Datei-Hash ist erforderlich; der Kindprozess ist keine Sandbox."
}

type runtimeLaunch struct {
	kind       engineruntime.RuntimeKind
	recipe     engineruntime.Recipe
	capability engineruntime.RuntimeCapability
	python     string
	fallbacks  []engineruntime.Fallback
	forceCPU   bool
}

func (m *EngineModule) createInstance(ctx context.Context, modelID, servedName string, config EngineConfig) (*EngineInstance, *EngineOperation, error) {
	instanceSuffix, err := randomHex(8)
	if err != nil {
		return nil, nil, err
	}
	return m.createInstanceWithID(ctx, "inst_"+instanceSuffix, modelID, servedName, config)
}

func (m *EngineModule) createInstanceWithID(ctx context.Context, instanceID, modelID, servedName string, config EngineConfig) (*EngineInstance, *EngineOperation, error) {
	releaseLifecycle, err := m.acquireLifecycle(ctx, false)
	if err != nil {
		return nil, nil, err
	}
	defer releaseLifecycle()

	config = normalizeConfig(config)
	record, ok := m.getModel(modelID)
	if !ok {
		return nil, nil, os.ErrNotExist
	}
	record, err = m.freshModelRecord(ctx, record)
	if err != nil {
		return nil, nil, err
	}
	if !record.Startable {
		return nil, nil, notStartableError(record)
	}
	m.mu.RLock()
	_, duplicate := m.instances[instanceID]
	m.mu.RUnlock()
	if duplicate {
		return nil, nil, fmt.Errorf("Instanz-ID %s existiert bereits", instanceID)
	}
	if strings.TrimSpace(servedName) == "" {
		servedName = record.Name
	}
	if err := m.validateRemoteCode(record, config); err != nil {
		return nil, nil, err
	}
	plan, views, _, err := m.recommendationWithNormalLRU(ctx, modelID, instanceID, config)
	if err != nil {
		return nil, nil, err
	}
	now := time.Now().UTC()
	instance := &EngineInstance{
		ID: instanceID, State: engineruntime.StateQueued, ModelID: modelID,
		ServedModelName: strings.TrimSpace(servedName), RequestedConfig: cloneEngineConfig(config),
		EffectiveConfig: cloneEngineConfig(config), Plan: &plan, Priority: config.Priority,
		Pinned: config.Priority == "pinned", Autostart: config.Autostart,
		RestartRequiredFields: restartRequiredFields(), Progress: 0, Phase: "queued",
		DetailMessage: "Das Hardwarebudget ist reserviert; der lokale Start wird vorbereitet.", EndpointName: instanceID,
		CreatedAt: now, UpdatedAt: now,
	}
	m.mu.Lock()
	if m.shuttingDown {
		m.mu.Unlock()
		return nil, nil, fmt.Errorf("Engine wird heruntergefahren")
	}
	seedBackups := make(map[string]*EngineInstance, len(views))
	for id := range views {
		if existing := m.instances[id]; existing != nil {
			seedBackups[id] = cloneInstance(existing)
		}
	}
	m.planRevision++
	instance.PlanRevision = m.planRevision
	m.instances[instanceID] = instance
	m.applyTargetPlansLocked(views)
	operation, operationContext := m.newOperationLocked("start", instanceID, "Runtime und Kontextplan werden vorbereitet")
	operation.ProtectedInstanceIDs = uniqueStrings(append(append([]string(nil), views[instanceID].AffectedRestartInstances...), instanceID))
	if m.startExecutions == nil {
		m.startExecutions = map[string]string{}
	}
	m.startExecutions[instanceID] = operation.ID
	m.enqueueStartOperationLocked(operation, config.Priority)
	_ = m.persistLocked()
	snapshot := cloneInstance(instance)
	operationSnapshot := cloneOperation(operation)
	m.mu.Unlock()
	m.events.publish("instance_created", snapshot)
	go m.executePlanTransaction(operationContext, operation.ID, instanceID, views, config, seedBackups)
	return snapshot, operationSnapshot, nil
}

func (m *EngineModule) scheduleStart(instanceID string, config EngineConfig, operationType string) (*EngineOperation, error) {
	return m.scheduleStartForModel(instanceID, "", config, operationType)
}

func (m *EngineModule) ensureReady(instanceID string) (*EngineInstance, *EngineOperation, error) {
	instanceID = strings.TrimSpace(instanceID)
	instance, ok := m.getInstance(instanceID)
	if !ok {
		return nil, nil, os.ErrNotExist
	}
	if instance.State == engineruntime.StateReady && strings.TrimSpace(instance.BaseURL) != "" && strings.TrimSpace(instance.WorkerSecret) != "" {
		return instance, nil, nil
	}
	operation, err := m.scheduleStart(instanceID, instance.RequestedConfig, "ensure_ready")
	if err != nil {
		return nil, nil, err
	}
	updated, _ := m.getInstance(instanceID)
	return updated, operation, nil
}

func (m *EngineModule) scheduleStartForModel(instanceID, targetModelID string, config EngineConfig, operationType string) (*EngineOperation, error) {
	m.startScheduleMu.Lock()
	defer m.startScheduleMu.Unlock()
	config = normalizeConfig(config)
	m.mu.RLock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.RUnlock()
		return nil, os.ErrNotExist
	}

	if operationType == "ensure_ready" && instance.State == engineruntime.StateReady && strings.TrimSpace(instance.BaseURL) != "" && strings.TrimSpace(instance.WorkerSecret) != "" {
		m.mu.RUnlock()
		return nil, nil
	}
	if active := m.activeStartOperationLocked(instanceID); active != nil {
		m.mu.RUnlock()
		return cloneOperation(active), nil
	}
	if reservationID := m.activeLRUEvictionReservationLocked(instanceID); reservationID != "" {
		m.mu.RUnlock()
		return nil, fmt.Errorf("%w (operation %s)", errInstanceLRUReserved, reservationID)
	}
	modelID := instance.ModelID
	if strings.TrimSpace(targetModelID) != "" {
		modelID = strings.TrimSpace(targetModelID)
	}
	record, modelExists := m.modelsByID[modelID]
	m.mu.RUnlock()
	if !modelExists {
		return nil, os.ErrNotExist
	}
	record, err := m.freshModelRecord(context.Background(), record)
	if err != nil {
		return nil, err
	}
	if !record.Startable {
		return nil, notStartableError(record)
	}
	if err := m.validateRemoteCode(record, config); err != nil {
		return nil, err
	}
	plan, views, _, err := m.recommendationWithNormalLRU(context.Background(), modelID, instanceID, config)
	if err != nil {
		return nil, err
	}
	m.mu.Lock()
	instance = m.instances[instanceID]
	if instance == nil {
		m.mu.Unlock()
		return nil, os.ErrNotExist
	}
	seedBackups := make(map[string]*EngineInstance, len(views))
	for id := range views {
		if existing := m.instances[id]; existing != nil {
			seedBackups[id] = cloneInstance(existing)
		}
	}
	if seedBackups[instanceID] == nil {
		seedBackups[instanceID] = cloneInstance(instance)
	}
	wasReady := instance.State == engineruntime.StateReady
	m.planRevision++
	instance.ModelID = modelID
	instance.RequestedConfig = cloneEngineConfig(config)
	if !wasReady {
		instance.Plan = &plan
	}
	instance.PlanRevision = m.planRevision
	instance.Priority = config.Priority
	instance.Pinned = config.Priority == "pinned"
	instance.Autostart = config.Autostart
	if !wasReady {
		instance.State = engineruntime.StateQueued
		instance.Progress = 0
		instance.Phase = "queued"
		instance.DetailMessage = "Das Hardwarebudget ist reserviert; der lokale Start wird vorbereitet."
	}
	instance.Error = ""
	instance.ErrorSummary = ""
	instance.ErrorCode = ""
	instance.UpdatedAt = time.Now().UTC()
	m.applyTargetPlansLocked(views)
	operation, operationContext := m.newOperationLocked(operationType, instanceID, "Kontextplan wurde konfliktfrei reserviert")
	operation.ProtectedInstanceIDs = uniqueStrings(append(append([]string(nil), views[instanceID].AffectedRestartInstances...), instanceID))
	if m.startExecutions == nil {
		m.startExecutions = map[string]string{}
	}
	m.startExecutions[instanceID] = operation.ID
	m.enqueueStartOperationLocked(operation, config.Priority)
	_ = m.persistLocked()
	instanceSnapshot := cloneInstance(instance)
	m.mu.Unlock()
	m.events.publish("instance_changed", instanceSnapshot)
	go m.executePlanTransaction(operationContext, operation.ID, instanceID, views, config, seedBackups)
	return cloneOperation(operation), nil
}
