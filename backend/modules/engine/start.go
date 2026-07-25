package engine

import (
	"context"
	"errors"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

func (m *EngineModule) startOne(ctx context.Context, instanceID string, config EngineConfig, plan ContextPlanView, operationID string) error {
	launch, err := m.prepareRuntime(ctx, instanceID, config, operationID)
	if err != nil {
		return err
	}
	if launch.forceCPU {
		if !ramOffloadAllowed(config) {
			return &gpuRuntimeUnavailableError{
				Reason:      "Die GPU-Runtime ist nicht einsatzbereit; ein CPU-Start benoetigt die ausdrueckliche Freigabe fuer System-RAM.",
				Remediation: "rebuild_gpu_runtime",
			}
		}
		cpuPlanConfig := cloneEngineConfig(config)
		cpuPlanConfig.RuntimeOptions["force_cpu_runtime"] = true
		cpuPlanConfig.RuntimeOptions["offload"] = "cpu"
		cpuPlanConfig.RuntimeOptions["gpu_layers"] = 0
		m.mu.RLock()
		current := m.instances[instanceID]
		modelID := ""
		if current != nil {
			modelID = current.ModelID
		}
		m.mu.RUnlock()
		cpuPlan, _, planErr := m.recommendation(ctx, modelID, instanceID, cpuPlanConfig)
		if planErr != nil {
			return fmt.Errorf("CPU-Fallback passt nicht in das RAM-Budget: %w", planErr)
		}
		if len(cpuPlan.AffectedRestartInstances) > 0 {
			return fmt.Errorf("CPU-Fallback wuerde zusaetzliche laufende Instanzen neu planen")
		}
		plan = cpuPlan
		config = cpuPlanConfig
	}
	m.mu.RLock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.RUnlock()
		return os.ErrNotExist
	}
	modelID := instance.ModelID
	record := m.modelsByID[modelID]
	m.mu.RUnlock()
	var revalidationErr error
	plan, record, revalidationErr = m.revalidatePlanBeforeLaunch(ctx, instanceID, config, plan, record, operationID)
	if revalidationErr != nil {
		return revalidationErr
	}
	modelPath, err := m.modelPath(record)
	if err != nil {
		return err
	}
	if err := m.validateRemoteCode(record, config); err != nil {
		return err
	}
	contextLength := plan.EffectiveContextTokens
	requested := engineruntime.RequestedConfig{
		Runtime: launch.kind, ModelPath: modelPath, ContextLength: &contextLength,
		MaxSequences: intPointer(config.MaxSequences), KVPolicy: engineruntime.KVPolicy(config.KVCachePolicy),
		AllowFallback: cloneBoolPointer(config.AllowFallback), TrustRemoteCode: config.TrustRemoteCode,
	}
	if explicitOffload, ok := floatOption(config.RuntimeOptions, "cpu_offload_gb"); ok {
		requested.CPUOffloadGB = &explicitOffload
	} else if launch.kind == engineruntime.RuntimeVLLM && plan.Memory.Weights.RAMBytes > 0 {
		offloadGB := float64(plan.Memory.Weights.RAMBytes) / float64(1<<30)
		requested.CPUOffloadGB = &offloadGB
	}
	requested.GPULayers, _ = intOption(config.RuntimeOptions, "gpu_layers")
	if launch.forceCPU {
		requested.GPULayers = intPointer(0)
	} else {
		for _, fallback := range launch.fallbacks {
			if fallback.Setting == "compute_backend" && fallback.To == "cpu" {
				requested.GPULayers = intPointer(0)
			}
		}
	}
	if requested.GPULayers == nil {
		if offload, _ := stringOption(config.RuntimeOptions, "offload"); offload == "cpu" {
			requested.GPULayers = intPointer(0)
		} else if launch.kind == engineruntime.RuntimeLlamaCPP {
			gpuWeightBytes := int64(0)
			for _, value := range plan.Memory.Weights.GPUBytes {
				gpuWeightBytes += value
			}
			switch {
			case gpuWeightBytes <= 0:
				requested.GPULayers = intPointer(0)
			case gpuWeightBytes >= record.SizeBytes:
				requested.GPULayers = intPointer(-1)
			case record.Metadata.Layers > 0 && record.SizeBytes > 0:
				layers := int(gpuWeightBytes * int64(record.Metadata.Layers) / record.SizeBytes)
				requested.GPULayers = intPointer(maxInt(0, layers))
			default:
				requested.GPULayers = intPointer(0)
			}
		}
	}
	requested.Threads, _ = intOption(config.RuntimeOptions, "threads")
	requested.TensorParallelism, _ = intOption(config.RuntimeOptions, "tensor_parallel_size")
	if requested.TensorParallelism == nil {
		requested.TensorParallelism, _ = intOption(config.RuntimeOptions, "tensor_parallelism")
	}
	if dtype, exists := stringOption(config.RuntimeOptions, "kv_cache_dtype"); exists && dtype != "" && dtype != "auto" {
		requested.KVCacheDType = &dtype
	}
	deviceSnapshot, _ := m.liveHardware(ctx)
	workerGPUs, err := resolveWorkerGPUs(launch.kind, config, plan, deviceSnapshot, launch.forceCPU)
	if err != nil {
		return err
	}
	switch launch.kind {
	case engineruntime.RuntimeTransformers:
		requested.GPUMemoryBytes, err = plannedTransformersMemoryBytes(plan, workerGPUs)
		if err != nil {
			return err
		}
		if plan.Memory.Weights.RAMBytes > 0 {
			ramLimit := plan.Memory.Weights.RAMBytes
			requested.CPUMemoryBytes = &ramLimit
		}
	case engineruntime.RuntimeVLLM:
		utilization, limitErr := plannedVLLMMemoryUtilization(plan, workerGPUs)
		if limitErr != nil {
			return limitErr
		}
		requested.GPUMemoryUtilization = &utilization
	}
	paths := engineruntime.AdapterPaths{Python: launch.python, TransformersWorker: m.workerPath}
	if launch.kind == engineruntime.RuntimeTransformers {
		if absolute, err := filepath.Abs(paths.TransformersWorker); err == nil {
			paths.TransformersWorker = absolute
		}
		if info, statErr := os.Stat(paths.TransformersWorker); statErr != nil || !info.Mode().IsRegular() {
			return fmt.Errorf("Transformers-Worker fehlt: %s", paths.TransformersWorker)
		}
	}
	command, err := engineruntime.BuildAdapterCommand(launch.capability, requested, paths)
	if err != nil {
		return err
	}
	// The memory plan and the worker must use the same physical KV-cache
	// representation. Runtime capability negotiation may resolve a requested
	// compact cache to a wider fallback (for example q4_0 -> f16). Replan before
	// spawning so cgroup limits and the displayed context remain byte-exact.
	resolvedConfig := cloneEngineConfig(config)
	resolvedConfig.RuntimeOptions["kv_cache_dtype"] = command.Effective.KVCacheDType
	resolvedPlannerType := plannerKVType(resolvedConfig)
	if resolvedPlannerType != plan.KVCacheDType {
		if command.Effective.KVCacheDType == "f16" || command.Effective.KVCacheDType == "native" || command.Effective.KVCacheDType == "auto" || command.Effective.KVCacheDType == "offloaded" {
			resolvedConfig.KVCachePolicy = "native"
		}
		replanned, _, planErr := m.recommendation(ctx, modelID, instanceID, resolvedConfig)
		if planErr != nil {
			return fmt.Errorf("aufgeloester KV-Cache %s passt nicht in das aktuelle Hardwarebudget: %w", command.Effective.KVCacheDType, planErr)
		}
		if len(replanned.AffectedRestartInstances) > 0 {
			return fmt.Errorf("aufgeloester KV-Cache %s wuerde zusaetzliche laufende Instanzen neu planen", command.Effective.KVCacheDType)
		}
		from := string(plan.KVCacheDType)
		to := command.Effective.KVCacheDType
		m.setOperationDetail(operationID, "running", 0.58, "replanning_kv_cache", "KV-Cache-Plan wird angeglichen", "Die Runtime verwendet "+to+"; das Speicherbudget wird vor dem Modellstart damit neu berechnet.", nil)
		if err := m.startOne(ctx, instanceID, resolvedConfig, replanned, operationID); err != nil {
			return err
		}
		m.mu.Lock()
		var changed *EngineInstance
		if current := m.instances[instanceID]; current != nil {
			current.Fallbacks = append([]engineruntime.Fallback{{
				Setting: "kv_cache_dtype",
				From:    from,
				To:      to,
				Reason:  "Die Runtime-Capability hat einen anderen KV-Cache bestaetigt; der Speicherplan wurde vor dem Start neu berechnet.",
			}}, current.Fallbacks...)
			changed = cloneInstance(current)
			_ = m.persistLocked()
		}
		m.mu.Unlock()
		if changed != nil {
			m.events.publish("instance_changed", changed)
		}
		return nil
	}
	applyWorkerDeviceSelection(command.Env, launch.kind, workerGPUs)
	m.setOperationDetail(operationID, "running", 0.62, "launching_worker", "Modellprozess wird gestartet", "Die Runtime ist bereit. Jetzt werden Modellgewichte und KV-Cache geladen.", nil)
	m.setInstanceStateDetail(instanceID, engineruntime.StateStarting, 0.62, "launching_worker", "Der lokale Modellprozess wird gestartet.", "")
	processSpec := command.ProcessSpec(instanceID)
	processSpec.SpawnAdmission = m.acquireWorkerSpawn
	if err := m.validateOperationLRUEvictionsReleased(operationID); err != nil {
		return err
	}
	memoryLimit, err := m.validateLoadPeakWithNormalLRU(ctx, launch.kind, record, plan, operationID, instanceID)
	if err != nil {
		// Automatic context shrinking: a smaller KV cache often turns a
		// rejected plan into a startable one. Only for memory conflicts and
		// only while fallbacks are allowed. A GPU load-peak conflict is handled
		// first: shrinking the KV cache cannot create the weight-upload headroom
		// that is missing, while a RAM-approved llama.cpp plan can safely fall
		// back to CPU placement.
		var conflict *ResourceConflictError
		if errors.As(err, &conflict) && fallbackEnabled(config) {
			if strings.HasPrefix(conflict.Resource, "gpu") && launch.kind == engineruntime.RuntimeLlamaCPP && !forceCPURequested(config) {
				if !ramOffloadAllowed(config) {
					return err
				}
				return m.retryLlamaCPU(ctx, instanceID, config, plan, operationID, err)
			}
			if computeReducedContext(plan.EffectiveContextTokens, plan.KVBytesPerTokenAtStart, err) > 0 {
				return m.retryReducedContext(ctx, instanceID, config, plan, operationID, err)
			}
		}
		return err
	}
	processSpec.ResourceLimits = engineruntime.ResourceLimits{MemoryMaxBytes: memoryLimit}
	processSpec.Progress = func(progress engineruntime.ProcessProgress) {
		m.setOperationDetail(operationID, "running", progress.Progress, progress.Phase, progress.Message, progress.DetailMessage, nil)
		m.setInstanceStateDetail(instanceID, engineruntime.StateStarting, progress.Progress, progress.Phase, progress.DetailMessage, "")
	}
	if err := m.validateOperationLRUEvictionsReleased(operationID); err != nil {
		return err
	}
	handle, err := m.supervisor.Start(ctx, processSpec)
	if err != nil && isPortConflictError(err) {
		// The randomly allocated loopback port can be stolen between allocation
		// and worker bind, and an orphaned process from a crashed run may still
		// hold it. A fresh Start allocates a new random port.
		log.Printf("[engine] worker port conflict for %s, retrying with a fresh port: %v", instanceID, err)
		m.setInstanceStateDetail(instanceID, engineruntime.StateStarting, 0.62, "launching_worker", "Der lokale Netzwerk-Port war belegt. Der Start wird automatisch mit einem neuen Port wiederholt.", "")
		handle, err = m.supervisor.Start(ctx, processSpec)
	}
	if err != nil {
		// Escalation ladder: memory exhaustion first shrinks the context
		// mathematically. When no reduction remains (or the failure is not
		// memory-related, e.g. a KV-cache incompatibility), fall THROUGH to
		// the KV/runtime/CPU fallbacks instead of giving up — skipping them
		// would kill models that only need the q4_0->f16 fallback.
		if isMemoryExhaustionError(err) && fallbackEnabled(config) &&
			computeReducedContext(plan.EffectiveContextTokens, plan.KVBytesPerTokenAtStart, err) > 0 {
			return m.retryReducedContext(ctx, instanceID, config, plan, operationID, err)
		}
		if next, ok := nextKVCacheFallback(launch.kind, command.Effective.KVCacheDType); ok && fallbackEnabled(config) {
			return m.retryKVCache(ctx, instanceID, config, plan, operationID, command.Effective.KVCacheDType, next, err)
		}
		if launch.kind == engineruntime.RuntimeVLLM && fallbackEnabled(config) {
			return m.retryTransformersAfterVLLM(ctx, instanceID, config, plan, operationID, err)
		}
		if launch.kind == engineruntime.RuntimeLlamaCPP && fallbackEnabled(config) && !forceCPURequested(config) {
			return m.retryLlamaCPU(ctx, instanceID, config, plan, operationID, err)
		}
		return err
	}
	workerCommitted := false
	workerCleaned := false
	defer func() {
		if workerCommitted || workerCleaned {
			return
		}
		stopCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		if stopErr := m.stopSupervisorConfirmed(stopCtx, instanceID); stopErr != nil {
			m.markStopUnconfirmed(instanceID, "cleanup_stop_unconfirmed", "Der fehlgeschlagene Modellstart bleibt gesperrt, bis sein Prozessende bestaetigt ist.", stopErr)
		}
		cancel()
	}()
	process := handle.Snapshot()
	m.setOperationDetail(operationID, "running", 0.86, "verifying_worker", "Modell wird kurz getestet", "Eine lokale Ein-Token-Anfrage prueft, ob das Modell wirklich antworten kann.", nil)
	m.setInstanceStateDetail(instanceID, engineruntime.StateStarting, 0.86, "verifying_worker", "Das geladene Modell wird mit einer kurzen lokalen Anfrage geprueft.", "")
	if err := verifyWorker(ctx, process.BaseURL, command.InternalAPIKey, instanceID); err != nil {
		stopCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		stopErr := m.stopSupervisorConfirmed(stopCtx, instanceID)
		cancel()
		if stopErr != nil {
			m.markStopUnconfirmed(instanceID, "verify_stop_unconfirmed", "Ein Fallback wurde verhindert, weil der vorherige Modellprozess nicht bestaetigt beendet ist.", stopErr)
			workerCleaned = true
			return fmt.Errorf("Mini-Inferenztest fehlgeschlagen (%v); Prozessbeendigung unbestaetigt: %w", err, stopErr)
		}
		workerCleaned = true
		if isMemoryExhaustionError(err) && fallbackEnabled(config) &&
			computeReducedContext(plan.EffectiveContextTokens, plan.KVBytesPerTokenAtStart, err) > 0 {
			return m.retryReducedContext(ctx, instanceID, config, plan, operationID, err)
		}
		if next, ok := nextKVCacheFallback(launch.kind, command.Effective.KVCacheDType); ok && fallbackEnabled(config) {
			return m.retryKVCache(ctx, instanceID, config, plan, operationID, command.Effective.KVCacheDType, next, err)
		}
		if launch.kind == engineruntime.RuntimeVLLM && fallbackEnabled(config) {
			return m.retryTransformersAfterVLLM(ctx, instanceID, config, plan, operationID, err)
		}
		if launch.kind == engineruntime.RuntimeLlamaCPP && fallbackEnabled(config) && !forceCPURequested(config) {
			return m.retryLlamaCPU(ctx, instanceID, config, plan, operationID, err)
		}
		return fmt.Errorf("Mini-Inferenztest fehlgeschlagen: %w", err)
	}
	// An explicit "maximize stable" request does not stop at the first working
	// half-size fallback. A failed upper bound is carried through the retries;
	// after every successful probe we test the midpoint above it until the
	// remaining interval is one 256-token step. Trial workers are never exposed
	// as Ready and are stopped before the next probe starts.
	if contextSearchRequested(config) {
		failedCeiling := contextSearchBound(config, contextSearchCeilingOption)
		currentContext := plan.EffectiveContextTokens
		nextContext := nextContextAfterSuccess(currentContext, failedCeiling)
		if nextContext > currentContext {
			m.setOperationDetail(operationID, "running", 0.9, "optimizing_context",
				"Hoeheren stabilen Kontext pruefen",
				fmt.Sprintf("%d Token wurden erfolgreich bestaetigt. Als naechstes werden %d Token zwischen diesem Wert und der fehlgeschlagenen Obergrenze %d getestet.", currentContext, nextContext, failedCeiling), nil)
			stopCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			stopErr := m.stopSupervisorConfirmed(stopCtx, instanceID)
			cancel()
			if stopErr != nil {
				m.markStopUnconfirmed(instanceID, "context_search_stop_unconfirmed", "Die Kontextsuche wurde angehalten, weil der bestaetigte Testprozess nicht sicher beendet werden konnte.", stopErr)
				workerCleaned = true
				return fmt.Errorf("bestaetigter Suchlauf mit %d Token konnte vor dem naechsten Test nicht beendet werden: %w", currentContext, stopErr)
			}
			workerCleaned = true

			nextConfig := cloneEngineConfig(config)
			nextConfig.ContextMode = "fixed"
			nextConfig.ContextTokens = intPointer(nextContext)
			setContextSearchBounds(&nextConfig, currentContext, failedCeiling)
			nextPlan, _, planErr := m.recommendation(ctx, modelID, instanceID, nextConfig)
			stableConfig := cloneEngineConfig(config)
			stableConfig.ContextMode = "fixed"
			stableConfig.ContextTokens = intPointer(currentContext)
			setContextSearchBounds(&stableConfig, currentContext, currentContext)
			if planErr == nil && len(nextPlan.AffectedRestartInstances) == 0 && nextPlan.EffectiveContextTokens > currentContext && nextPlan.EffectiveContextTokens < failedCeiling {
				nextErr := m.startOne(ctx, instanceID, nextConfig, nextPlan, operationID)
				if nextErr == nil {
					return nil
				}
				var unconfirmedStop *unconfirmedSupervisorStopError
				if ctx.Err() != nil || m.isShuttingDown() || errors.As(nextErr, &unconfirmedStop) {
					return nextErr
				}
				m.setOperationDetail(operationID, "running", 0.91, "restoring_verified_context",
					"Bestaetigten Kontext wiederherstellen",
					fmt.Sprintf("Der hoehere Test mit %d Token ist fehlgeschlagen. Der zuvor bestaetigte Bestwert von %d Token wird wieder gestartet.", nextPlan.EffectiveContextTokens, currentContext), nil)
			}

			// If the refreshed hardware budget no longer admits the next midpoint,
			// or a non-memory probe fails, restart and commit the value that was
			// just verified instead of turning a successful optimization into a
			// failed transaction.
			return m.startOne(ctx, instanceID, stableConfig, plan, operationID)
		}
	}
	effective := effectiveEngineConfig(config, command.Effective, plan)
	clearContextSearchOptions(&effective)
	if launch.forceCPU {
		effective.RuntimeOptions["force_cpu_runtime"] = true
		effective.RuntimeOptions["offload"] = "cpu"
		effective.RuntimeOptions["gpu_layers"] = 0
	}
	fallbacks := append(append([]engineruntime.Fallback(nil), launch.fallbacks...), command.Effective.Fallbacks...)
	m.mu.Lock()
	instance = m.instances[instanceID]
	if instance == nil {
		m.mu.Unlock()
		return os.ErrNotExist
	}
	instance.State = engineruntime.StateReady
	instance.Runtime = launch.kind
	instance.EffectiveConfig = effective
	if contextSearchRequested(config) {
		// Preserve the user's original runtime/KV/offload intent. Recursive
		// search attempts may contain temporary CPU or cache fallbacks that
		// belong only in EffectiveConfig and the fallback history.
		instance.RequestedConfig = stableContextRequest(instance.RequestedConfig, plan.EffectiveContextTokens)
	}
	instance.Plan = &plan
	instance.Fallbacks = fallbacks
	instance.BaseURL = process.BaseURL
	instance.WorkerSecret = command.InternalAPIKey
	instance.Progress = 1
	instance.Error = ""
	instance.ErrorSummary = ""
	instance.ErrorCode = ""
	instance.Phase = "ready"
	instance.DetailMessage = "Das Modell wurde geladen, geprueft und ist lokal einsatzbereit."
	now := time.Now().UTC()
	instance.UpdatedAt = now
	instance.workerGeneration++
	if instance.workerGeneration == 0 {
		instance.workerGeneration = 1
	}
	instance.ActiveRequests = 0
	instance.LastUsedAt = &now
	instance.IdleExpiresAt = nil
	if !instance.Autostart && !instance.Pinned {
		expires := now.Add(m.effectiveIdleTimeout())
		instance.IdleExpiresAt = &expires
	}
	instance.Placement = placementForPlan(&plan)
	instance.GuardState = m.guardState
	instance.LastKnownGood = &LastKnownGood{EffectiveConfig: cloneEngineConfig(effective), Plan: plan, Runtime: string(launch.kind), UpdatedAt: instance.UpdatedAt}
	// A stopped generation may still own deferred HTTP releases. Give the new
	// worker a fresh inference gate so those releases cannot consume its slots.
	m.inferenceMu.Lock()
	m.inferenceGates[instanceID] = &inferenceGate{}
	m.inferenceMu.Unlock()
	copy := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", copy)
	go m.monitorWorker(instanceID, handle, process.BaseURL, command.InternalAPIKey)
	workerCommitted = true
	return nil
}

// revalidatePlanBeforeLaunch closes the longest race in a model start: runtime
// installation can take minutes, during which other applications may consume
// VRAM/RAM or model files may change. A recommendation is therefore only an
// admission estimate; this second calculation is authoritative for spawning
// the worker. It never silently changes the context of another live instance.
func (m *EngineModule) revalidatePlanBeforeLaunch(ctx context.Context, instanceID string, config EngineConfig, previous ContextPlanView, record modelcatalog.ModelRecord, operationID string) (ContextPlanView, modelcatalog.ModelRecord, error) {
	if strings.TrimSpace(record.ID) == "" {
		return previous, record, os.ErrNotExist
	}
	fresh, err := m.freshModelRecord(ctx, record)
	if err != nil {
		return previous, record, err
	}
	if !fresh.Startable {
		return previous, fresh, notStartableError(fresh)
	}

	m.setOperationDetail(operationID, "running", 0.56, "revalidating_plan", "Startplan wird erneut geprüft", "Hardware, Modell-Fingerabdruck und Speicherbudget werden direkt vor dem Workerstart abgeglichen.", nil)
	revalidated, _, err := m.recommendation(ctx, fresh.ID, instanceID, config)
	if err != nil {
		return previous, fresh, fmt.Errorf("Hardwarebudget hat sich waehrend der Vorbereitung geaendert; der Startplan wurde sicher verworfen: %w", err)
	}
	if len(revalidated.AffectedRestartInstances) > 0 {
		return previous, fresh, fmt.Errorf("das aktuelle Hardwarebudget wuerde laufende Modelle neu planen; der Start wurde nicht automatisch fortgesetzt")
	}

	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.Unlock()
		return previous, fresh, os.ErrNotExist
	}
	m.planRevision++
	instance.PlanRevision = m.planRevision
	instance.Plan = &revalidated
	instance.UpdatedAt = time.Now().UTC()
	changed := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", changed)
	return revalidated, fresh, nil
}

func resolveWorkerGPUs(kind engineruntime.RuntimeKind, config EngineConfig, plan ContextPlanView, snapshot hardware.Snapshot, forceCPU bool) ([]hardware.GPU, error) {
	if forceCPU {
		return nil, nil
	}
	plannedIDs := []string{}
	plannedGPUBytes := plan.Memory.Total.GPUBytes
	if kind == engineruntime.RuntimeTransformers {
		plannedGPUBytes = plan.Memory.Weights.GPUBytes
	}
	for id, planned := range plannedGPUBytes {
		if planned > 0 {
			plannedIDs = append(plannedIDs, id)
		}
	}
	if len(plannedIDs) == 0 {
		if kind == engineruntime.RuntimeVLLM {
			return nil, fmt.Errorf("vLLM benoetigt einen geplanten dedizierten GPU-Speicherbereich")
		}
		return nil, nil
	}
	sort.Strings(plannedIDs)

	selected := stringSliceOption(config.RuntimeOptions, "gpu_ids")
	parallelism := 0
	if value, ok := intOption(config.RuntimeOptions, "tensor_parallel_size"); ok && *value > 0 {
		parallelism = *value
	} else if value, ok := intOption(config.RuntimeOptions, "tensor_parallelism"); ok && *value > 0 {
		parallelism = *value
	}
	if kind == engineruntime.RuntimeVLLM && parallelism == 0 {
		parallelism = 1
	}
	if len(selected) == 0 && parallelism > 0 {
		for _, gpu := range snapshot.GPUs {
			if !gpu.SharedMemory && gpu.VRAMTotalBytes > 0 {
				selected = append(selected, gpu.ID)
				if len(selected) == parallelism {
					break
				}
			}
		}
	}
	if len(selected) == 0 {
		selected = append(selected, plannedIDs...)
	}
	if kind == engineruntime.RuntimeVLLM && len(selected) > parallelism {
		selected = selected[:parallelism]
	}
	if kind == engineruntime.RuntimeTransformers {
		// Transformers' device_map must use exactly the devices for which the
		// planner provided a byte budget; otherwise an unbounded visible device
		// could silently become an offload target.
		filtered := make([]string, 0, len(selected))
		seen := map[string]bool{}
		for _, id := range selected {
			if plannedGPUBytes[id] > 0 && !seen[id] {
				filtered = append(filtered, id)
				seen[id] = true
			}
		}
		for _, id := range plannedIDs {
			if !seen[id] {
				filtered = append(filtered, id)
			}
		}
		selected = filtered
	}

	byID := make(map[string]hardware.GPU, len(snapshot.GPUs))
	for _, gpu := range snapshot.GPUs {
		byID[gpu.ID] = gpu
	}
	result := make([]hardware.GPU, 0, len(selected))
	seen := map[string]bool{}
	for _, id := range selected {
		if seen[id] {
			continue
		}
		gpu, exists := byID[id]
		if !exists || gpu.SharedMemory || gpu.VRAMTotalBytes <= 0 {
			return nil, fmt.Errorf("geplante GPU %q ist fuer ein hartes Runtime-Speicherlimit nicht als dedizierte GPU messbar", id)
		}
		seen[id] = true
		result = append(result, gpu)
	}
	if kind == engineruntime.RuntimeVLLM && len(result) != parallelism {
		return nil, fmt.Errorf("vLLM tensor_parallel_size=%d benoetigt %d messbare dedizierte GPUs; ausgewaehlt sind %d", parallelism, parallelism, len(result))
	}
	return result, nil
}

func plannedTransformersMemoryBytes(plan ContextPlanView, selected []hardware.GPU) ([]int64, error) {
	limits := make([]int64, 0, len(selected))
	for _, gpu := range selected {
		planned := plan.Memory.Weights.GPUBytes[gpu.ID]
		if planned <= 0 || gpu.SharedMemory || gpu.VRAMTotalBytes <= 0 || planned > gpu.VRAMTotalBytes {
			return nil, fmt.Errorf("Transformers VRAM-Grenze fuer GPU %q ist ungueltig: geplant=%d, gesamt=%d", gpu.ID, planned, gpu.VRAMTotalBytes)
		}
		limits = append(limits, planned)
	}
	return limits, nil
}

func plannedVLLMMemoryUtilization(plan ContextPlanView, selected []hardware.GPU) (float64, error) {
	if len(selected) == 0 {
		return 0, fmt.Errorf("vLLM benoetigt mindestens eine ausgewaehlte GPU")
	}
	selectedIDs := make(map[string]bool, len(selected))
	utilization := 1.0
	for _, gpu := range selected {
		if gpu.SharedMemory || gpu.VRAMTotalBytes <= 0 {
			return 0, fmt.Errorf("vLLM GPU %q hat keine messbare dedizierte VRAM-Kapazitaet", gpu.ID)
		}
		planned := plan.Memory.Total.GPUBytes[gpu.ID]
		if planned <= 0 || planned > gpu.VRAMTotalBytes {
			return 0, fmt.Errorf("vLLM VRAM-Grenze fuer GPU %q ist ungueltig: geplant=%d, gesamt=%d", gpu.ID, planned, gpu.VRAMTotalBytes)
		}
		selectedIDs[gpu.ID] = true
		fraction := float64(planned) / float64(gpu.VRAMTotalBytes)
		if fraction < utilization {
			utilization = fraction
		}
	}
	for id, planned := range plan.Memory.Total.GPUBytes {
		if planned > 0 && !selectedIDs[id] {
			return 0, fmt.Errorf("vLLM-Plan enthaelt nicht ausgewaehlte GPU %q", id)
		}
	}
	// vLLM exposes one fraction for every tensor-parallel worker. Flooring at
	// six decimals ensures no selected GPU can exceed its individual plan.
	utilization = math.Floor(utilization*1_000_000) / 1_000_000
	if utilization <= 0 || utilization > 1 {
		return 0, fmt.Errorf("vLLM VRAM-Auslastungsgrenze %.6f liegt ausserhalb des gueltigen Bereichs", utilization)
	}
	return utilization, nil
}

func applyWorkerDeviceSelection(environment map[string]string, kind engineruntime.RuntimeKind, selected []hardware.GPU) {
	if environment == nil {
		return
	}
	if len(selected) == 0 {
		environment["CUDA_VISIBLE_DEVICES"] = ""
		environment["ROCR_VISIBLE_DEVICES"] = ""
		environment["HIP_VISIBLE_DEVICES"] = ""
		environment["GGML_VK_VISIBLE_DEVICES"] = ""
		return
	}
	indicesByBackend := map[string][]string{}
	for _, gpu := range selected {
		backend := strings.ToLower(gpu.Backend)
		indicesByBackend[backend] = append(indicesByBackend[backend], fmt.Sprint(gpu.Index))
	}
	if indices := indicesByBackend["cuda"]; len(indices) > 0 {
		environment["CUDA_VISIBLE_DEVICES"] = strings.Join(indices, ",")
	}
	if indices := indicesByBackend["rocm"]; len(indices) > 0 {
		value := strings.Join(indices, ",")
		environment["ROCR_VISIBLE_DEVICES"] = value
		environment["HIP_VISIBLE_DEVICES"] = value
	}
	if kind == engineruntime.RuntimeLlamaCPP {
		if indices := indicesByBackend["vulkan"]; len(indices) > 0 {
			environment["GGML_VK_VISIBLE_DEVICES"] = strings.Join(indices, ",")
		}
	}
}
