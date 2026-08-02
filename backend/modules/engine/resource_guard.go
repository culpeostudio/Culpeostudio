package engine

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"time"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/localinference"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

const (
	guardRAMFloor = int64(1 << 30)
	guardGPUFloor = int64(256 << 20)
)

type ResourceConflictError struct {
	Resource string `json:"resource"`

	RequiredBytes int64 `json:"required_bytes"`

	AvailableBytes int64 `json:"available_bytes"`

	ReserveBytes int64 `json:"reserve_bytes,omitempty"`

	TotalBytes int64  `json:"total_bytes,omitempty"`
	Reason     string `json:"reason"`
}

func (e *ResourceConflictError) Error() string {
	return fmt.Sprintf("%s: %s (benoetigt %s, nutzbar %s)",
		e.Resource, e.Reason, formatMemoryBytes(e.RequiredBytes), formatMemoryBytes(e.AvailableBytes))
}

func formatMemoryBytes(bytes int64) string {
	if bytes < 0 {
		bytes = 0
	}
	return fmt.Sprintf("%.1f GB", float64(bytes)/float64(1<<30))
}

func emergencyFloor(total, floor int64) int64 {
	percentage := (total*5 + 99) / 100
	if floor == guardGPUFloor {
		percentage = (total*3 + 99) / 100
	}
	if percentage < floor {
		return floor
	}
	return percentage
}

func maxInt64(left, right int64) int64 {
	if left > right {
		return left
	}
	return right
}

func loadPeakReserveBytes(configured *int64, total int64, percentage int64, minimum, emergencyMinimum int64) int64 {
	return maxInt64(effectiveReserveBytes(configured, total, percentage, minimum), emergencyFloor(total, emergencyMinimum))
}

func loadPeakBytes(kind engineruntime.RuntimeKind, record modelcatalog.ModelRecord, plan ContextPlanView) (ram int64, gpu map[string]int64) {
	modelBytes := record.SizeBytes
	if modelBytes < 0 {
		modelBytes = 0
	}
	ram = plan.Memory.Total.RAMBytes
	switch kind {
	case engineruntime.RuntimeLlamaCPP:

		gpuWeightBytes := modelBytes - plan.Memory.Weights.RAMBytes
		if gpuWeightBytes < 0 {
			gpuWeightBytes = 0
		}
		ram += gpuWeightBytes + maxInt64(2<<30, modelBytes/10)
	case engineruntime.RuntimeTransformers, engineruntime.RuntimeVLLM:
		ram += modelBytes + maxInt64(1<<30, modelBytes/5)
	default:
		ram += maxInt64(1<<30, modelBytes/5)
	}
	gpu = map[string]int64{}
	for id, planned := range plan.Memory.Total.GPUBytes {
		if planned <= 0 {
			continue
		}
		gpu[id] = planned + maxInt64(512<<20, planned/10)
	}
	return ram, gpu
}

func loadPeakReserveAdditions(kind engineruntime.RuntimeKind, record modelcatalog.ModelRecord, plan ContextPlanView) (int64, map[string]int64) {
	ramRequired, gpuRequired := loadPeakBytes(kind, record, plan)
	ramExtra := ramRequired - plan.Memory.Total.RAMBytes
	if ramExtra < 0 {
		ramExtra = 0
	}
	gpuExtra := make(map[string]int64, len(gpuRequired))
	for id, required := range gpuRequired {
		extra := required - plan.Memory.Total.GPUBytes[id]
		if extra > 0 {
			gpuExtra[id] = extra
		}
	}
	return ramExtra, gpuExtra
}

func allocateWithLoadPeak(
	hardwarePlan engineplanner.Hardware,
	requests []engineplanner.Request,
	basePolicy engineplanner.ReservePolicy,
	targetID string,
	kind engineruntime.RuntimeKind,
	record modelcatalog.ModelRecord,
) ([]engineplanner.ContextPlan, error) {
	firstPass, err := engineplanner.Allocate(hardwarePlan, requests, basePolicy)
	if err != nil {
		return nil, err
	}
	target, ok := plannerContextPlan(firstPass, targetID)
	if !ok {
		return nil, fmt.Errorf("Planer lieferte keinen Kandidatenplan fuer %s", targetID)
	}
	ramExtra, gpuExtra := loadPeakReserveAdditions(kind, record, planView(target, nil))
	peakPolicy := reservePolicyWithLoadPeak(basePolicy, ramExtra, gpuExtra)
	peakRequests := requests
	if kind == engineruntime.RuntimeLlamaCPP {
		peakRequests = llamaRequestsWithPeakWeightSplit(
			requests,
			targetID,
			target,
			gpuPeakAllocationReductions(hardwarePlan, firstPass, basePolicy, gpuExtra),
		)
	}
	secondPass, err := engineplanner.Allocate(hardwarePlan, peakRequests, peakPolicy)
	if err != nil {
		return nil, err
	}
	if err := validatePeakAwareAllocation(hardwarePlan, secondPass, basePolicy, targetID, kind, record); err != nil {
		return nil, err
	}
	return secondPass, nil
}

func llamaRequestsWithPeakWeightSplit(requests []engineplanner.Request, targetID string, target engineplanner.ContextPlan, gpuReduction map[string]int64) []engineplanner.Request {
	result := append([]engineplanner.Request(nil), requests...)
	for index := range result {
		request := &result[index]
		if request.InstanceID != targetID || request.WeightGPUBytes != nil || request.AllowRAMOffload == nil || !*request.AllowRAMOffload {
			continue
		}
		gpuWeightBytes := int64(0)
		peakHeadroom := int64(0)
		for id, planned := range target.Breakdown.Weights.GPUBytes {
			gpuWeightBytes = addMemoryBytes(gpuWeightBytes, planned)
			peakHeadroom = addMemoryBytes(peakHeadroom, gpuReduction[id])
		}
		if gpuWeightBytes <= 0 || peakHeadroom <= 0 {
			continue
		}
		gpuWeightBytes -= peakHeadroom
		if gpuWeightBytes < 0 {
			gpuWeightBytes = 0
		}
		request.WeightGPUBytes = &gpuWeightBytes
	}
	return result
}

func gpuPeakAllocationReductions(hardwarePlan engineplanner.Hardware, plans []engineplanner.ContextPlan, basePolicy engineplanner.ReservePolicy, gpuExtra map[string]int64) map[string]int64 {
	totalGPU := map[string]int64{}
	for _, plan := range plans {
		for id, planned := range plan.Breakdown.Total.GPUBytes {
			totalGPU[id] = addMemoryBytes(totalGPU[id], planned)
		}
	}
	result := make(map[string]int64, len(gpuExtra))
	for id, extra := range gpuExtra {
		gpu, exists := plannerGPU(hardwarePlan.GPUs, id)
		if !exists || gpu.UnifiedMemory || extra <= 0 {
			continue
		}
		reserve := effectiveReserveBytes(basePolicy.GPUBytes, gpu.TotalBytes, 10, 512<<20)
		if value, configured := basePolicy.GPUBytesByID[id]; configured {
			reserve = value
		}
		budget := subtractAvailable(plannerAvailableBytes(gpu.TotalBytes, gpu.AvailableBytes, gpu.EngineUsedBytes), reserve)
		slack := budget - totalGPU[id]
		if slack < 0 {
			slack = 0
		}
		if extra > slack {
			result[id] = extra - slack
		}
	}
	return result
}

func plannerContextPlan(plans []engineplanner.ContextPlan, instanceID string) (engineplanner.ContextPlan, bool) {
	for _, plan := range plans {
		if plan.InstanceID == instanceID {
			return plan, true
		}
	}
	return engineplanner.ContextPlan{}, false
}

func reservePolicyWithLoadPeak(base engineplanner.ReservePolicy, ramExtra int64, gpuExtra map[string]int64) engineplanner.ReservePolicy {
	result := base
	result.GPUBytesByID = make(map[string]int64, len(base.GPUBytesByID)+len(gpuExtra))
	for id, reserve := range base.GPUBytesByID {
		result.GPUBytesByID[id] = reserve
	}
	if ramExtra > 0 {
		reserve := int64(0)
		if base.RAMBytes != nil {
			reserve = *base.RAMBytes
		}
		reserve = addMemoryBytes(reserve, ramExtra)
		result.RAMBytes = &reserve
	}
	for id, extra := range gpuExtra {
		reserve, exists := result.GPUBytesByID[id]
		if !exists && base.GPUBytes != nil {
			reserve = *base.GPUBytes
		}
		result.GPUBytesByID[id] = addMemoryBytes(reserve, extra)
	}
	return result
}

func addMemoryBytes(base, extra int64) int64 {
	const maxMemoryBytes = int64(1<<63 - 1)
	if extra <= 0 {
		return base
	}
	if base > maxMemoryBytes-extra {
		return maxMemoryBytes
	}
	return base + extra
}

func validatePeakAwareAllocation(
	hardwarePlan engineplanner.Hardware,
	plans []engineplanner.ContextPlan,
	basePolicy engineplanner.ReservePolicy,
	targetID string,
	kind engineruntime.RuntimeKind,
	record modelcatalog.ModelRecord,
) error {
	target, ok := plannerContextPlan(plans, targetID)
	if !ok {
		return fmt.Errorf("Planer lieferte keinen Kandidatenplan fuer %s", targetID)
	}
	ramExtra, gpuExtra := loadPeakReserveAdditions(kind, record, planView(target, nil))
	totalRAM := int64(0)
	totalGPU := map[string]int64{}
	for _, plan := range plans {
		totalRAM = addMemoryBytes(totalRAM, plan.Breakdown.Total.RAMBytes)
		for id, planned := range plan.Breakdown.Total.GPUBytes {
			totalGPU[id] = addMemoryBytes(totalGPU[id], planned)
		}
	}
	ramReserve := effectiveReserveBytes(basePolicy.RAMBytes, hardwarePlan.RAMTotalBytes, 15, 4<<30)
	ramBudget := subtractAvailable(plannerAvailableBytes(hardwarePlan.RAMTotalBytes, hardwarePlan.RAMAvailableBytes, hardwarePlan.EngineRAMUsedBytes), ramReserve)
	ramRequired := addMemoryBytes(totalRAM, ramExtra)
	if ramRequired > ramBudget {
		return &engineplanner.ConflictError{
			InstanceID: targetID, Resource: "ram", RequiredBytes: ramRequired, AvailableBytes: ramBudget,
			Reason: "conservative load peak does not fit after safety reserves",
		}
	}
	for id, planned := range totalGPU {
		gpu, exists := plannerGPU(hardwarePlan.GPUs, id)
		if !exists || gpu.UnifiedMemory {
			return &engineplanner.ConflictError{
				InstanceID: targetID, Resource: "gpu:" + id, RequiredBytes: addMemoryBytes(planned, gpuExtra[id]),
				Reason: "planned GPU is unavailable for load-peak validation",
			}
		}
		reserve := effectiveReserveBytes(basePolicy.GPUBytes, gpu.TotalBytes, 10, 512<<20)
		if value, configured := basePolicy.GPUBytesByID[id]; configured {
			reserve = value
		}
		budget := subtractAvailable(plannerAvailableBytes(gpu.TotalBytes, gpu.AvailableBytes, gpu.EngineUsedBytes), reserve)
		required := addMemoryBytes(planned, gpuExtra[id])
		if required > budget {
			return &engineplanner.ConflictError{
				InstanceID: targetID, Resource: "gpu:" + id, RequiredBytes: required, AvailableBytes: budget,
				Reason: "conservative load peak does not fit after safety reserves",
			}
		}
	}
	return nil
}

func plannerGPU(gpus []engineplanner.GPU, id string) (engineplanner.GPU, bool) {
	for _, gpu := range gpus {
		if gpu.ID == id {
			return gpu, true
		}
	}
	return engineplanner.GPU{}, false
}

func plannerAvailableBytes(total int64, available *int64, engineUsed int64) int64 {
	value := total
	if available != nil {
		value = *available
		if value < 0 {
			value = 0
		}
		if value > total {
			value = total
		}
	}
	if engineUsed < 0 {
		engineUsed = 0
	}
	if engineUsed > total-value {
		return total
	}
	return value + engineUsed
}

func subtractAvailable(value, reserve int64) int64 {
	if reserve >= value {
		return 0
	}
	return value - reserve
}

func (m *EngineModule) validateLoadPeak(ctx context.Context, kind engineruntime.RuntimeKind, record modelcatalog.ModelRecord, plan ContextPlanView) (int64, error) {
	m.mu.RLock()
	guard := m.guardState
	m.mu.RUnlock()

	if guard == GuardCritical || guard == GuardEmergency {
		return 0, fmt.Errorf("%w: neue Starts sind bei Guard-Zustand %s pausiert", localinference.ErrGuardRejected, guard)
	}
	snapshot, _ := m.liveHardware(ctx)
	ramRequired, gpuRequired := loadPeakBytes(kind, record, plan)
	ramReserve := loadPeakReserveBytes(nil, snapshot.RAMTotalBytes, 15, 4<<30, guardRAMFloor)
	var gpuConfiguredReserve *int64
	if m.settings != nil {
		settings := m.settings.Get()
		ramReserve = loadPeakReserveBytes(settings.EngineRAMReserveBytes, snapshot.RAMTotalBytes, 15, 4<<30, guardRAMFloor)
		gpuConfiguredReserve = settings.EngineGPUReserveBytes
	}
	ramAvailable := snapshot.RAMAvailableBytes - ramReserve
	if ramAvailable < 0 {
		ramAvailable = 0
	}
	if ramRequired > ramAvailable {
		return 0, fmt.Errorf("%w: %w", localinference.ErrGuardRejected, &ResourceConflictError{
			Resource: "ram", RequiredBytes: ramRequired, AvailableBytes: ramAvailable,
			ReserveBytes: ramReserve, TotalBytes: snapshot.RAMTotalBytes,
			Reason: "konservativer Lade-Peak wuerde die konfigurierte oder nicht abschaltbare RAM-Reserve unterschreiten",
		})
	}
	for id, required := range gpuRequired {
		available := int64(-1)
		total := int64(0)
		for _, gpu := range snapshot.GPUs {
			if gpu.ID == id && !gpu.SharedMemory {
				available = gpu.VRAMFreeBytes
				total = gpu.VRAMTotalBytes
				break
			}
		}
		if available < 0 {
			return 0, fmt.Errorf("%w: GPU %s ist fuer die Peak-Pruefung nicht mehr vorhanden", localinference.ErrGuardRejected, id)
		}
		gpuReserve := loadPeakReserveBytes(gpuConfiguredReserve, total, 10, 512<<20, guardGPUFloor)
		available -= gpuReserve
		if available < 0 {
			available = 0
		}
		if required > available {
			return 0, fmt.Errorf("%w: %w", localinference.ErrGuardRejected, &ResourceConflictError{
				Resource: "gpu:" + id, RequiredBytes: required, AvailableBytes: available,
				ReserveBytes: gpuReserve, TotalBytes: total,
				Reason: "konservativer Lade-Peak wuerde die konfigurierte oder nicht abschaltbare VRAM-Reserve unterschreiten",
			})
		}
	}
	return ramRequired, nil
}

func guardStateForSnapshot(snapshot hardware.Snapshot) GuardState {
	state := GuardNormal
	apply := func(available, floor int64) {
		candidate := GuardNormal
		switch {
		case available <= floor:
			candidate = GuardEmergency
		case available <= floor+floor/2:
			candidate = GuardCritical
		case available <= floor*2:
			candidate = GuardWarning
		}
		if guardRank(candidate) > guardRank(state) {
			state = candidate
		}
	}
	if snapshot.RAMTotalBytes <= 0 {

		state = GuardWarning
	} else if snapshot.RAMAvailableBytes <= 0 {

		apply(0, emergencyFloor(snapshot.RAMTotalBytes, guardRAMFloor))
	} else {
		apply(snapshot.RAMAvailableBytes, emergencyFloor(snapshot.RAMTotalBytes, guardRAMFloor))
	}
	if snapshot.GPUTelemetryIncomplete && guardRank(state) < guardRank(GuardWarning) {

		state = GuardWarning
	}
	for _, gpu := range snapshot.GPUs {
		if gpu.SharedMemory || gpu.VRAMTelemetryUnavailable {

			continue
		}
		if gpu.VRAMTotalBytes <= 0 {
			if guardRank(state) < guardRank(GuardWarning) {
				state = GuardWarning
			}
		} else if gpu.VRAMFreeBytes <= 0 {
			apply(0, emergencyFloor(gpu.VRAMTotalBytes, guardGPUFloor))
		} else {
			apply(gpu.VRAMFreeBytes, emergencyFloor(gpu.VRAMTotalBytes, guardGPUFloor))
		}
	}
	return state
}

func guardRank(state GuardState) int {
	switch state {
	case GuardWarning:
		return 1
	case GuardCritical:
		return 2
	case GuardEmergency:
		return 3
	default:
		return 0
	}
}

func (m *EngineModule) runResourceMaintenance() {
	sampler := newHardwareSampler(nil)
	defer sampler.Close()
	pressureTicker := time.NewTicker(500 * time.Millisecond)
	idleTicker := time.NewTicker(30 * time.Second)
	defer pressureTicker.Stop()
	defer idleTicker.Stop()
	lastReadySample := time.Time{}
	lastPressureAction := time.Time{}
	for {
		select {
		case <-m.maintenanceStop:
			return
		case now := <-idleTicker.C:
			m.runIdleSweep(now.UTC())
		case now := <-pressureTicker.C:
			fast := m.hasStartingInstance()
			if !fast && now.Sub(lastReadySample) < 2*time.Second {
				continue
			}
			lastReadySample = now
			sampler.ExpectDedicatedGPUs(m.plannedDedicatedGPUIds())
			snapshot, _ := sampler.Sample()
			state := guardStateForSnapshot(snapshot)
			m.setGuardState(state)
			if guardRank(state) >= guardRank(GuardCritical) && now.Sub(lastPressureAction) >= 2*time.Second {
				lastPressureAction = now
				m.relievePressure(state == GuardEmergency)
			}
		}
	}
}

func (m *EngineModule) plannedDedicatedGPUIds() []string {
	m.mu.RLock()
	seen := map[string]bool{}
	for _, instance := range m.instances {
		if instance == nil || instance.Plan == nil || !resourceHoldingState(instance.State) {
			continue
		}
		for id, bytes := range instance.Plan.Memory.Total.GPUBytes {
			if bytes > 0 {
				seen[id] = true
			}
		}
	}
	m.mu.RUnlock()
	ids := make([]string, 0, len(seen))
	for id := range seen {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	return ids
}

func (m *EngineModule) hasStartingInstance() bool {
	m.prewarmMu.Lock()
	prewarming := m.prewarmActive != nil
	m.prewarmMu.Unlock()
	if prewarming {
		return true
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	for _, instance := range m.instances {
		if instance.State == engineruntime.StateInstalling || instance.State == engineruntime.StateQueued || instance.State == engineruntime.StateStarting || instance.State == engineruntime.StateRestarting {
			return true
		}
	}
	return false
}

func (m *EngineModule) setGuardState(state GuardState) {
	if state == "" {
		state = GuardNormal
	}

	m.prewarmMu.Lock()
	m.spawnGateMu.Lock()
	m.mu.Lock()
	if m.guardState == state {
		m.mu.Unlock()
		m.spawnGateMu.Unlock()
		m.prewarmMu.Unlock()

		if state != GuardNormal {
			m.requestRuntimePrewarmPause()
			if guardRank(state) >= guardRank(GuardCritical) {
				m.requestCancelAllRuntimeInstallJobs()
			}
		}
		return
	}
	m.guardState = state
	instances := make([]*EngineInstance, 0, len(m.instances))
	for _, instance := range m.instances {
		instance.GuardState = state
		instances = append(instances, cloneInstance(instance))
	}
	_ = m.persistLocked()
	m.mu.Unlock()
	m.spawnGateMu.Unlock()
	m.prewarmMu.Unlock()
	if m.startQueue != nil {
		m.syncStartQueuePositions(m.startQueue.setPaused(state != GuardNormal))
	}
	if state != GuardNormal {
		m.requestRuntimePrewarmPause()
		if guardRank(state) >= guardRank(GuardCritical) {
			m.requestCancelAllRuntimeInstallJobs()
		}
	} else {
		m.signalRuntimePrewarm()
	}
	for _, instance := range instances {
		m.events.publish("instance_changed", instance)
	}
	m.events.publish("guard_state", map[string]interface{}{"state": state})
}

func (m *EngineModule) runIdleSweep(now time.Time) []string {
	ids := m.idleSweepCandidates(now)
	stopped := make([]string, 0, len(ids))
	for _, id := range ids {
		if !m.claimIdleStop(id, now) {
			continue
		}
		if _, err := m.scheduleStopWithReason(id, "idle_timeout", "Instanz wurde nach 15 Minuten ohne Nutzung automatisch entladen"); err == nil {
			stopped = append(stopped, id)
		}
	}
	return stopped
}

func (m *EngineModule) idleSweepCandidates(now time.Time) []string {
	m.mu.RLock()
	ids := []string{}
	for _, instance := range m.instances {
		if instance.State != engineruntime.StateReady || instance.Autostart || instance.Pinned || instance.ActiveRequests > 0 || instance.IdleExpiresAt == nil || instance.IdleExpiresAt.After(now) || m.activeOperationProtectsInstanceLocked(instance.ID) {
			continue
		}
		ids = append(ids, instance.ID)
	}
	m.mu.RUnlock()
	sort.Strings(ids)
	return ids
}

func (m *EngineModule) claimIdleStop(instanceID string, now time.Time) bool {
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil || instance.State != engineruntime.StateReady || instance.Autostart || instance.Pinned || instance.ActiveRequests > 0 || instance.IdleExpiresAt == nil || instance.IdleExpiresAt.After(now) || m.activeOperationProtectsInstanceLocked(instanceID) {
		m.mu.Unlock()
		return false
	}
	instance.State = engineruntime.StateDraining
	instance.Phase = "idle_timeout"
	instance.DetailMessage = "Die ungenutzte Instanz wird nach Ablauf der Leerlaufzeit sicher entladen."
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = time.Now().UTC()
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
	return true
}

func (m *EngineModule) relievePressure(emergency bool) {
	if operationID := m.youngestWarmupOperation(); operationID != "" {
		_, _ = m.cancelOperation(operationID)
	}
	if emergency {
		if instanceID := m.emergencyStartingCandidate(); instanceID != "" {
			m.emergencyTerminate(instanceID)
			return
		}
	}
	id, active := m.pressureEvictionCandidate(emergency)
	if id == "" {
		return
	}
	if emergency && active {
		m.emergencyTerminate(id)
		return
	}
	claimed, activeNow := m.claimPressureStop(id, emergency)
	if !claimed {
		if emergency && activeNow {
			m.emergencyTerminate(id)
		}
		return
	}
	_, _ = m.scheduleStopWithReason(id, "resource_pressure", "Ressourcenwaechter entlaedt die am laengsten ungenutzte Instanz")
}

func (m *EngineModule) claimPressureStop(instanceID string, emergency bool) (claimed bool, active bool) {
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil || instance.State != engineruntime.StateReady {
		m.mu.Unlock()
		return false, false
	}
	if instance.ActiveRequests > 0 {
		m.mu.Unlock()
		return false, true
	}
	if !emergency && (instance.Autostart || instance.Pinned || m.activeOperationProtectsInstanceLocked(instanceID)) {
		m.mu.Unlock()
		return false, false
	}
	instance.State = engineruntime.StateDraining
	instance.Phase = "resource_pressure"
	instance.DetailMessage = "Der Ressourcenwaechter entlaedt diese derzeit ungenutzte Instanz."
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = time.Now().UTC()
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)
	return true, false
}

func (m *EngineModule) youngestWarmupOperation() string {
	m.mu.RLock()
	defer m.mu.RUnlock()
	var selected *EngineOperation
	for _, operation := range m.operations {
		if operation.State != "running" || terminalOperationState(operation.State) {
			continue
		}
		switch operation.Type {
		case "start", "restart", "ensure_ready", "autostart", "legacy_start":
			if selected == nil || operation.CreatedAt.After(selected.CreatedAt) {
				selected = operation
			}
		}
	}
	if selected == nil {
		return ""
	}
	return selected.ID
}

func (m *EngineModule) emergencyStartingCandidate() string {
	m.mu.RLock()
	type candidate struct {
		id        string
		updatedAt time.Time
	}
	candidates := []candidate{}
	for _, instance := range m.instances {
		switch instance.State {
		case engineruntime.StateInstalling, engineruntime.StateStarting, engineruntime.StateRestarting:
			if m.supervisor != nil {
				if handle, exists := m.supervisor.Instance(instance.ID); exists && !terminalSupervisorState(handle.Snapshot().State) {
					candidates = append(candidates, candidate{id: instance.ID, updatedAt: instance.UpdatedAt})
				}
			}
		}
	}
	m.mu.RUnlock()
	sort.Slice(candidates, func(i, j int) bool { return candidates[i].updatedAt.After(candidates[j].updatedAt) })
	if len(candidates) == 0 {
		return ""
	}
	return candidates[0].id
}

func (m *EngineModule) pressureEvictionCandidate(emergency bool) (string, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	type candidate struct {
		id       string
		active   int
		priority int
		used     time.Time
	}
	candidates := []candidate{}
	for _, instance := range m.instances {
		if instance.State != engineruntime.StateReady {
			continue
		}
		if !emergency && (instance.Autostart || instance.Pinned || instance.ActiveRequests > 0 || m.activeOperationProtectsInstanceLocked(instance.ID)) {
			continue
		}
		used := instance.CreatedAt
		if instance.LastUsedAt != nil {
			used = *instance.LastUsedAt
		}
		candidates = append(candidates, candidate{id: instance.ID, active: instance.ActiveRequests, priority: startPriority(instance.Priority), used: used})
	}
	sort.Slice(candidates, func(i, j int) bool {
		if emergency {
			leftActive := candidates[i].active > 0
			rightActive := candidates[j].active > 0
			if leftActive != rightActive {
				return !leftActive
			}

			if leftActive && candidates[i].priority != candidates[j].priority {
				return candidates[i].priority < candidates[j].priority
			}
			if candidates[i].active != candidates[j].active {
				return candidates[i].active < candidates[j].active
			}
		}
		return candidates[i].used.Before(candidates[j].used)
	})
	if len(candidates) == 0 {
		return "", false
	}
	return candidates[0].id, candidates[0].active > 0
}

func (m *EngineModule) activeOperationProtectsInstanceLocked(instanceID string) bool {
	if m.startExecutions[instanceID] != "" {
		return true
	}
	for _, operation := range m.operations {
		if operation == nil || (terminalOperationState(operation.State) && !m.physicalStartOperationLocked(operation.ID)) {
			continue
		}
		for _, id := range operation.ProtectedInstanceIDs {
			if id == instanceID {
				return true
			}
		}
		for _, id := range operation.ReservedEvictionInstanceIDs {
			if id == instanceID {
				return true
			}
		}
	}
	return false
}

func (m *EngineModule) physicalStartOperationLocked(operationID string) bool {
	for _, activeOperationID := range m.startExecutions {
		if activeOperationID == operationID {
			return true
		}
	}
	return false
}

func (m *EngineModule) emergencyTerminate(instanceID string) {
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil || instance.State == engineruntime.StateStopped || instance.State == engineruntime.StateFailed || instance.State == engineruntime.StateFailedRollback {
		m.mu.Unlock()
		return
	}

	instance.State = engineruntime.StateDraining
	instance.Phase = "guard_emergency_stopping"
	instance.DetailMessage = "Notabschaltung laeuft; der Modellprozess wird zwangsweise beendet und anschliessend bestaetigt."
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.IdleExpiresAt = nil
	instance.UpdatedAt = time.Now().UTC()
	snapshot := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", snapshot)

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	err := m.forceStopSupervisorConfirmed(ctx, instanceID)
	cancel()
	if err == nil {
		m.finalizeConfirmedStop(instanceID, "guard_emergency", "Die aktive Instanz wurde zum Schutz des Hosts im Notfall beendet.")
		return
	}
	m.markStopUnconfirmed(instanceID, "guard_emergency_unconfirmed", "Die Instanz ist gesperrt. Der Ressourcenwaechter bestaetigt die Prozessbeendigung weiter im Hintergrund.", err)
}

func (m *EngineModule) waitForNormalGuard(ctx context.Context) error {
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()
	for {
		m.mu.RLock()
		normal := m.guardState == GuardNormal
		m.mu.RUnlock()
		if normal {
			return nil
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-m.maintenanceStop:
			return errors.New("Engine wird heruntergefahren")
		case <-ticker.C:
		}
	}
}
