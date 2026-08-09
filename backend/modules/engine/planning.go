package engine

import (
	"context"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/culpeohq/backend/internal/engineplanner"
	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/internal/modelcatalog"
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
		if runtimeErr := m.gpuRuntimePlanningError(config, hardwareSnapshot); runtimeErr != nil {
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
	plans, err := allocateWithLoadPeak(plannerHardware, requests, reservePolicy, instanceID, record)
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
	// llama.cpp puts the whole model on one device unless it is told to split,
	// so budget for one GPU unless the caller widened it.
	limit := 1
	if value, ok := intOption(config.RuntimeOptions, "gpu_count"); ok && *value > 0 {
		limit = *value
	}
	selected := request.SelectedGPUIDs
	if len(selected) == 0 {
		selected = dedicated
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
	// Without a GPU that maps to a published llama-server build, everything runs
	// on the CPU.
	return !snapshotHasUsableGPU(snapshot)
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

// ramOffloadAllowed reports whether a plan may place weights or KV cache in
// system RAM once VRAM runs out.
//
// The engine can do it, but it does not decide it. Spilling into RAM is the
// difference between a model that answers quickly and one that crawls, and that
// trade is the user's to make: without an explicit yes the planner refuses and
// says why, rather than quietly handing back something slow. An explicit
// CPU-only request already carries the answer.
func ramOffloadAllowed(config EngineConfig) bool {
	if forceCPURequested(config) {
		return true
	}
	if allowed, exists := boolOption(config.RuntimeOptions, "allow_ram_offload"); exists {
		return allowed
	}
	return false
}

// unavailableGPURuntimeReason explains why a machine with GPUs will still run
// on the CPU. It returns an empty string when the GPUs are usable or when the
// caller already asked for CPU execution.
func unavailableGPURuntimeReason(config EngineConfig, snapshot hardware.Snapshot) string {
	if offload, _ := stringOption(config.RuntimeOptions, "offload"); offload == "cpu" {
		return ""
	}
	if forced, _ := boolOption(config.RuntimeOptions, "force_cpu_runtime"); forced {
		return ""
	}
	if len(snapshot.GPUs) == 0 || snapshotHasUsableGPU(snapshot) {
		return ""
	}
	return unsupportedGPUReason(snapshot)
}

// gpuRuntimePlanningError refuses a GPU-only plan the machine cannot deliver,
// rather than silently planning for VRAM that will never be used.
func (m *EngineModule) gpuRuntimePlanningError(config EngineConfig, snapshot hardware.Snapshot) *gpuRuntimeUnavailableError {
	if reason := unavailableGPURuntimeReason(config, snapshot); reason != "" {
		return &gpuRuntimeUnavailableError{Reason: reason, Remediation: "use_cpu_runtime"}
	}
	if m.installer == nil || !snapshotHasUsableGPU(snapshot) {
		return nil
	}
	build, _, err := m.selectBuild(snapshot, false)
	if err != nil {
		return &gpuRuntimeUnavailableError{Reason: err.Error(), Remediation: "use_cpu_runtime"}
	}
	if build.Variant == engineruntime.BuildCPU {
		return nil
	}
	capability := m.installer.Capability(build, engineruntime.DefaultCapability(build.Variant))
	if capability.Installed && capability.Healthy {
		return nil
	}
	// A previous install that failed outright is worth reporting now; one that
	// has simply not run yet will be started when the instance starts.
	if latest, exists := m.installer.Latest(build); exists && latest.Status == engineruntime.InstallFailed {
		reason := latest.ErrorSummary
		if strings.TrimSpace(reason) == "" {
			reason = "Die letzte Vorbereitung des GPU-Builds von llama-server ist fehlgeschlagen."
		}
		return &gpuRuntimeUnavailableError{Reason: reason, Remediation: "reinstall_runtime"}
	}
	return nil
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
		KVCacheDType: plannerKVType(config, metadata.Quantization), Priority: plannerPriority(config.Priority), Pinned: config.Priority == "pinned",
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
		// An expert offload moves a very different amount of weight than the
		// layer count suggests, so it is subtracted from whatever the layer
		// arithmetic above arrived at.
		if moved, note := expertOffloadBytes(record, config); moved > 0 {
			onGPU := record.SizeBytes
			if request.WeightGPUBytes != nil {
				onGPU = *request.WeightGPUBytes
			}
			onGPU -= moved
			if onGPU < 0 {
				onGPU = 0
			}
			request.WeightGPUBytes = &onGPU
			if note != "" {
				warnings = append(warnings, note)
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

// expertOffloadBytes reports how much weight an expert offload moves off the
// accelerator, and a warning when the request cannot be honoured as asked.
//
// The catalog measures the expert tensors per model rather than per layer, so
// the split across layers is taken as even. That holds for every MoE
// architecture in circulation - the expert blocks are identical by
// construction - and it is the difference between a budget that is a few
// percent out and one that is wrong by the whole expert weight.
func expertOffloadBytes(record modelcatalog.ModelRecord, config EngineConfig) (int64, string) {
	requested := cpuMoELayersOption(config.RuntimeOptions)
	if requested == nil {
		return 0, ""
	}
	expertLayers := record.Metadata.ExpertLayers
	expertBytes := record.Metadata.ExpertWeightBytes
	if expertLayers <= 0 || expertBytes <= 0 {
		// Asking for an expert offload on a dense model is a mistake worth
		// naming: llama-server accepts the flag and it does nothing, so without
		// this the user would be left wondering why the placement did not move.
		return 0, "Dieses Modell hat keine Mixture-of-Experts-Gewichte; die Experten-Auslagerung bleibt wirkungslos."
	}
	if *requested < 0 || *requested >= expertLayers {
		return expertBytes, ""
	}
	if *requested == 0 {
		return 0, ""
	}
	return expertBytes * int64(*requested) / int64(expertLayers), ""
}
