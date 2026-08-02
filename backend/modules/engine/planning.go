package engine

import (
	"context"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

func (m *EngineModule) recommendation(ctx context.Context, modelID, instanceID string, config EngineConfig) (ContextPlanView, map[string]ContextPlanView, error) {
	return m.recommendationExcluding(ctx, modelID, instanceID, config, nil)
}

func (m *EngineModule) recommendationExcluding(ctx context.Context, modelID, instanceID string, config EngineConfig, excluded map[string]bool) (ContextPlanView, map[string]ContextPlanView, error) {
	record, ok := m.getModel(modelID)
	if !ok {
		return ContextPlanView{}, nil, os.ErrNotExist
	}
	if !record.Startable {
		return ContextPlanView{}, nil, fmt.Errorf("Modell ist unvollstaendig oder ungueltig")
	}
	if strings.TrimSpace(instanceID) == "" {
		instanceID = "recommendation"
	}
	hardwareSnapshot, plannerHardware := m.liveHardware(ctx)
	requests := []engineplanner.Request{}
	warningsByID := map[string][]string{}
	m.mu.RLock()
	for _, existing := range m.instances {
		if existing.ID == instanceID || excluded[existing.ID] || !resourceHoldingState(existing.State) {
			continue
		}
		existingRecord, found := m.modelsByID[existing.ModelID]
		if !found || !existingRecord.Startable {
			continue
		}
		planningConfig := cloneEngineConfig(existing.RequestedConfig)
		if forced, _ := boolOption(existing.EffectiveConfig.RuntimeOptions, "force_cpu_runtime"); forced {
			planningConfig.RuntimeOptions["force_cpu_runtime"] = true
			planningConfig.RuntimeOptions["offload"] = "cpu"
		}
		request, warnings, requestErr := plannerRequest(existing.ID, existingRecord, planningConfig, existing.Plan)
		if requestErr != nil {
			m.mu.RUnlock()
			return ContextPlanView{}, nil, requestErr
		}
		if forceCPUForConfig(existingRecord, planningConfig, hardwareSnapshot) {
			request.ForceCPU = true
			zero := int64(0)
			request.WeightGPUBytes = &zero
		}
		if selectionErr := limitPlannerGPUs(&request, existingRecord, planningConfig, hardwareSnapshot); selectionErr != nil {
			m.mu.RUnlock()
			return ContextPlanView{}, nil, selectionErr
		}
		requests = append(requests, request)
		warningsByID[existing.ID] = warnings
	}
	m.mu.RUnlock()
	request, warnings, err := plannerRequest(instanceID, record, normalizeConfig(config), nil)
	if err != nil {
		return ContextPlanView{}, nil, err
	}
	if !ramOffloadAllowed(config) {
		if runtimeErr := m.gpuRuntimePlanningError(record, config, hardwareSnapshot); runtimeErr != nil {
			return ContextPlanView{}, nil, runtimeErr
		}
	}
	if forceCPUForConfig(record, config, hardwareSnapshot) {
		request.ForceCPU = true
		zero := int64(0)
		request.WeightGPUBytes = &zero
	}
	if err := limitPlannerGPUs(&request, record, config, hardwareSnapshot); err != nil {
		return ContextPlanView{}, nil, err
	}
	runtimeSnapshot := hardwareSnapshot
	if request.ForceCPU {
		runtimeSnapshot.GPUs = nil
	}
	plannedRuntime, _, err := m.selectRuntime(record, config, runtimeSnapshot)
	if err != nil {
		return ContextPlanView{}, nil, err
	}
	requests = append(requests, request)
	warningsByID[instanceID] = warnings
	settings := m.settings.Get()
	ramReserve := effectiveReserveBytes(settings.EngineRAMReserveBytes, hardwareSnapshot.RAMTotalBytes, 15, 4<<30)
	ramReserve = maxInt64(ramReserve, emergencyFloor(hardwareSnapshot.RAMTotalBytes, guardRAMFloor))
	gpuReserves := map[string]int64{}
	for _, gpu := range hardwareSnapshot.GPUs {
		if gpu.SharedMemory {
			continue
		}
		reserve := effectiveReserveBytes(settings.EngineGPUReserveBytes, gpu.VRAMTotalBytes, 10, 512<<20)
		gpuReserves[gpu.ID] = maxInt64(reserve, emergencyFloor(gpu.VRAMTotalBytes, guardGPUFloor))
	}
	reservePolicy := engineplanner.ReservePolicy{
		RAMBytes: &ramReserve, GPUBytesByID: gpuReserves,
	}
	plans, err := allocateWithLoadPeak(plannerHardware, requests, reservePolicy, instanceID, plannedRuntime, record)
	if err != nil {
		return ContextPlanView{}, nil, err
	}
	views := make(map[string]ContextPlanView, len(plans))
	for _, plan := range plans {
		views[plan.InstanceID] = planView(plan, warningsByID[plan.InstanceID])
	}
	view, exists := views[instanceID]
	if !exists {
		return ContextPlanView{}, nil, fmt.Errorf("Planer lieferte keinen Kandidatenplan")
	}
	view.Preflight = preflightReport(record, view, hardwareSnapshot)
	affected := []string{}
	for id, candidate := range views {
		if id == instanceID {
			continue
		}
		m.mu.RLock()
		existing := m.instances[id]
		changed := existing != nil && existing.Plan != nil && existing.Plan.EffectiveContextTokens != candidate.EffectiveContextTokens
		m.mu.RUnlock()
		if changed {
			affected = append(affected, id)
		}
	}
	sort.Strings(affected)
	view.AffectedRestartInstances = affected
	views[instanceID] = view
	return view, views, nil
}

func limitPlannerGPUs(request *engineplanner.Request, record modelcatalog.ModelRecord, config EngineConfig, snapshot hardware.Snapshot) error {
	if request.ForceCPU {
		request.SelectedGPUIDs = nil
		return nil
	}
	dedicated := []string{}
	for _, gpu := range snapshot.GPUs {
		if !gpu.SharedMemory && gpu.VRAMTotalBytes > 0 {
			dedicated = append(dedicated, gpu.ID)
		}
	}
	if len(dedicated) == 0 {
		return nil
	}
	runtimeName := strings.ToLower(strings.TrimSpace(config.Runtime))
	usesVLLM := record.Format == modelcatalog.FormatSafeTensors && (runtimeName == "vllm" || (runtimeName == "auto" || runtimeName == "") && vllmCompatible(snapshot))
	limit := 0
	if usesVLLM {
		limit = 1
		if value, ok := intOption(config.RuntimeOptions, "tensor_parallel_size"); ok && *value > 0 {
			limit = *value
		}
	} else if record.Format == modelcatalog.FormatGGUF {
		limit = 1
		if value, ok := intOption(config.RuntimeOptions, "tensor_parallel_size"); ok && *value > 0 {
			limit = *value
		}
	}
	if limit <= 0 {
		return nil
	}
	selected := request.SelectedGPUIDs
	if len(selected) == 0 {
		selected = dedicated
	}
	if usesVLLM && limit > len(selected) {
		return fmt.Errorf("tensor_parallel_size=%d benoetigt %d ausgewaehlte dedizierte GPUs; verfuegbar sind %d", limit, limit, len(selected))
	}
	if len(selected) > limit {
		selected = selected[:limit]
	}
	request.SelectedGPUIDs = append([]string(nil), selected...)
	return nil
}

func forceCPUForConfig(record modelcatalog.ModelRecord, config EngineConfig, snapshot hardware.Snapshot) bool {
	if offload, _ := stringOption(config.RuntimeOptions, "offload"); offload == "cpu" {
		return true
	}
	if forced, _ := boolOption(config.RuntimeOptions, "force_cpu_runtime"); forced {
		return true
	}
	if record.Format == modelcatalog.FormatGGUF {
		usable, _ := usableLlamaBuildSnapshot(snapshot)
		for _, gpu := range usable.GPUs {
			if !gpu.SharedMemory && gpu.VRAMTotalBytes > 0 && runtimeSupportsBackend(engineruntime.RuntimeLlamaCPP, gpu.Backend) {
				return false
			}
		}
		return true
	}
	if record.Format != modelcatalog.FormatSafeTensors {
		return false
	}
	requested := strings.ToLower(strings.TrimSpace(config.Runtime))
	if requested == "vllm" && vllmCompatible(snapshot) {
		return false
	}
	for _, gpu := range snapshot.GPUs {
		if !gpu.SharedMemory && (strings.EqualFold(gpu.Backend, "cuda") || strings.EqualFold(gpu.Backend, "rocm")) {
			return false
		}
	}
	return true
}

type gpuRuntimeUnavailableError struct {
	Reason      string
	Remediation string
}

func (e *gpuRuntimeUnavailableError) Error() string {
	return "GPU-Runtime ist für dieses Modell noch nicht verfügbar: " + e.Reason
}

type ramOffloadRequiredError struct {
	Cause error
}

func (e *ramOffloadRequiredError) Error() string {
	if e == nil || e.Cause == nil {
		return "Der GPU-Speicher reicht nicht aus; System-RAM wurde noch nicht freigegeben."
	}
	return "Der GPU-Speicher reicht nicht aus; System-RAM wurde noch nicht freigegeben: " + e.Cause.Error()
}

func (e *ramOffloadRequiredError) Unwrap() error {
	if e == nil {
		return nil
	}
	return e.Cause
}

func ramOffloadAllowed(config EngineConfig) bool {

	if forceCPURequested(config) {
		return true
	}
	if allowed, exists := boolOption(config.RuntimeOptions, "allow_ram_offload"); exists {
		return allowed
	}

	return false
}

func unavailableGPURuntimeReason(record modelcatalog.ModelRecord, config EngineConfig, snapshot hardware.Snapshot) string {
	if offload, _ := stringOption(config.RuntimeOptions, "offload"); offload == "cpu" {
		return ""
	}
	if forced, _ := boolOption(config.RuntimeOptions, "force_cpu_runtime"); forced {
		return ""
	}
	if record.Format != modelcatalog.FormatGGUF {
		return ""
	}
	hasCompatibleGPU := false
	for _, gpu := range snapshot.GPUs {
		if !gpu.SharedMemory && gpu.VRAMTotalBytes > 0 && runtimeSupportsBackend(engineruntime.RuntimeLlamaCPP, gpu.Backend) {
			hasCompatibleGPU = true
			break
		}
	}
	if !hasCompatibleGPU {
		return ""
	}
	usable, warnings := usableLlamaBuildSnapshot(snapshot)
	for _, gpu := range usable.GPUs {
		if !gpu.SharedMemory && gpu.VRAMTotalBytes > 0 && runtimeSupportsBackend(engineruntime.RuntimeLlamaCPP, gpu.Backend) {
			return ""
		}
	}
	if len(warnings) > 0 {
		return strings.Join(warnings, "; ")
	}
	return "die installierte llama.cpp-Runtime hat keine bestätigte GPU-Offload-Unterstützung"
}

func (m *EngineModule) gpuRuntimePlanningError(record modelcatalog.ModelRecord, config EngineConfig, snapshot hardware.Snapshot) *gpuRuntimeUnavailableError {
	if record.Format != modelcatalog.FormatGGUF {
		return nil
	}
	if offload, _ := stringOption(config.RuntimeOptions, "offload"); offload == "cpu" {
		return nil
	}
	if forced, _ := boolOption(config.RuntimeOptions, "force_cpu_runtime"); forced {
		return nil
	}

	if m.healthyLlamaGPUCapability(snapshot) {
		return nil
	}
	if reason := unavailableGPURuntimeReason(record, config, snapshot); reason != "" {
		return &gpuRuntimeUnavailableError{
			Reason:      reason,
			Remediation: "install_vulkan_dependencies",
		}
	}
	if m.installer == nil {
		return nil
	}
	usable, _ := usableLlamaBuildSnapshot(snapshot)
	hasUsableGPU := false
	for _, gpu := range usable.GPUs {
		if !gpu.SharedMemory && gpu.VRAMTotalBytes > 0 && runtimeSupportsBackend(engineruntime.RuntimeLlamaCPP, gpu.Backend) {
			hasUsableGPU = true
			break
		}
	}
	if !hasUsableGPU {
		return nil
	}
	recipe, err := m.runtimeRecipe(engineruntime.RuntimeLlamaCPP, usable)
	if err != nil {
		return &gpuRuntimeUnavailableError{Reason: err.Error(), Remediation: "rebuild_gpu_runtime"}
	}
	capability := m.installer.Capability(recipe, engineruntime.DefaultCapability(engineruntime.RuntimeLlamaCPP))
	if capability.Installed && capability.Healthy {
		return nil
	}
	if latest, exists := m.installer.Latest(recipe); exists && latest.Status == engineruntime.InstallFailed {
		reason := latest.ErrorSummary
		if strings.TrimSpace(reason) == "" {
			reason = "Der letzte GPU-Funktionstest der llama.cpp-Vulkan-Runtime ist fehlgeschlagen."
		}
		return &gpuRuntimeUnavailableError{Reason: reason, Remediation: "rebuild_gpu_runtime"}
	}
	return nil
}

func (m *EngineModule) healthyLlamaGPUCapability(snapshot hardware.Snapshot) bool {
	if m.installer == nil {
		return false
	}
	hasCompatibleGPU := false
	for _, gpu := range snapshot.GPUs {
		if !gpu.SharedMemory && gpu.VRAMTotalBytes > 0 && runtimeSupportsBackend(engineruntime.RuntimeLlamaCPP, gpu.Backend) {
			hasCompatibleGPU = true
			break
		}
	}
	if !hasCompatibleGPU {
		return false
	}
	recipe, err := m.runtimeRecipe(engineruntime.RuntimeLlamaCPP, snapshot)
	if err != nil || recipe.Environment["CMAKE_ARGS"] == "" {
		return false
	}
	capability := m.installer.Capability(recipe, engineruntime.DefaultCapability(engineruntime.RuntimeLlamaCPP))
	return capability.Installed && capability.Healthy
}

func plannerRequest(instanceID string, record modelcatalog.ModelRecord, config EngineConfig, current *ContextPlanView) (engineplanner.Request, []string, error) {
	config = normalizeConfig(config)
	metadata := record.Metadata
	warnings := []string{}
	contextLimit := metadata.ContextLength
	if contextLimit <= 0 {
		contextLimit = 4096
		warnings = append(warnings, "Das Modell meldet kein verifiziertes Kontextlimit; konservativ werden 4096 Token verwendet.")
	}
	layers := metadata.Layers
	if layers <= 0 {
		layers = 32
		warnings = append(warnings, "Layerzahl fehlt und wurde fuer die Speicherplanung geschaetzt.")
	}
	kvHeads := metadata.KVHeads
	if kvHeads <= 0 {
		kvHeads = metadata.AttentionHeads
	}
	if kvHeads <= 0 {
		kvHeads = 8
		warnings = append(warnings, "KV-Head-Anzahl fehlt und wurde fuer die Speicherplanung geschaetzt.")
	}
	headDimension := metadata.HeadDimension
	if headDimension <= 0 && metadata.EmbeddingDimension > 0 && metadata.AttentionHeads > 0 {
		headDimension = metadata.EmbeddingDimension / metadata.AttentionHeads
	}
	if headDimension <= 0 {
		headDimension = 128
		warnings = append(warnings, "Head-Dimension fehlt und wurde fuer die Speicherplanung geschaetzt.")
	}
	model := engineplanner.Model{
		ID: record.ID, WeightBytes: record.SizeBytes, WeightConfidence: engineplanner.ConfidenceMeasured,
		ContextLimit: contextLimit, Layers: layers, KVHeads: kvHeads, AttentionHeads: metadata.AttentionHeads,
		HeadDimension: headDimension, SlidingWindow: metadata.SlidingWindow,
	}
	if metadata.SlidingWindow > 0 && strings.Contains(strings.ToLower(metadata.Architecture), "gemma") {
		model.GlobalAttentionLayers = maxInt(1, layers/2)
		warnings = append(warnings, "Das Verhaeltnis globaler zu Sliding-Window-Layern wurde aus der Architektur geschaetzt.")
	}
	request := engineplanner.Request{
		InstanceID: instanceID, Model: model, MaxSequences: config.MaxSequences,
		KVCacheDType: plannerKVType(config), Priority: plannerPriority(config.Priority), Pinned: config.Priority == "pinned",
		SelectedGPUIDs: stringSliceOption(config.RuntimeOptions, "gpu_ids"),
	}
	if offload, _ := stringOption(config.RuntimeOptions, "offload"); offload == "cpu" {
		request.ForceCPU = true
	}
	if forced, _ := boolOption(config.RuntimeOptions, "force_cpu_runtime"); forced {
		request.ForceCPU = true
	}
	if request.ForceCPU {
		zero := int64(0)
		request.WeightGPUBytes = &zero
	} else if record.Format == modelcatalog.FormatGGUF {
		if gpuLayers, exists := intOption(config.RuntimeOptions, "gpu_layers"); exists {
			switch {
			case *gpuLayers == 0:
				zero := int64(0)
				request.WeightGPUBytes = &zero
				request.ForceCPU = true
			case *gpuLayers < 0 || *gpuLayers >= layers:
				all := record.SizeBytes
				request.WeightGPUBytes = &all
			default:
				partial := record.SizeBytes * int64(*gpuLayers) / int64(layers)
				request.WeightGPUBytes = &partial
			}
		}
	}
	allowRAM := ramOffloadAllowed(config)
	request.AllowRAMOffload = &allowRAM
	if strings.EqualFold(config.ContextMode, "fixed") {
		if config.ContextTokens == nil {
			return request, warnings, fmt.Errorf("context_tokens ist bei context_mode=fixed erforderlich")
		}
		request.RequestedContext = cloneIntPointer(config.ContextTokens)
	}
	requestedMax := contextLimit
	if request.RequestedContext != nil {
		requestedMax = *request.RequestedContext
	}
	request.MinimumContext = minInt(4096, requestedMax)
	if current != nil {
		request.CurrentContext = current.EffectiveContextTokens
	}
	if config.KVCachePolicy == "prefer_4bit" {
		warnings = append(warnings, "4-Bit-KV-Cache kann Qualitaet und Durchsatz gegenueber nativen Cache-Typen beeinflussen; Modellgewichte bleiben unveraendert.")
	}
	return request, warnings, nil
}
