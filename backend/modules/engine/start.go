package engine

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/internal/modelcatalog"
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
	contextLength := plan.EffectiveContextTokens
	requested := engineruntime.RequestedConfig{
		Runtime: launch.kind, ModelPath: modelPath, ContextLength: &contextLength,
		MaxSequences: intPointer(config.MaxSequences), KVPolicy: engineruntime.KVPolicy(config.KVCachePolicy),
		AllowFallback: cloneBoolPointer(config.AllowFallback),
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
		} else {
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
	requested.MainGPU, _ = intOption(config.RuntimeOptions, "main_gpu")
	requested.SplitMode, _ = stringOption(config.RuntimeOptions, "split_mode")
	requested.FlashAttention, _ = stringOption(config.RuntimeOptions, "flash_attention")
	if dtype, exists := stringOption(config.RuntimeOptions, "kv_cache_dtype"); exists && dtype != "" && dtype != "auto" {
		requested.KVCacheDType = &dtype
	}
	if err := m.applyRuntimeOptions(&requested, config); err != nil {
		return err
	}
	deviceSnapshot, _ := m.liveHardware(ctx)
	workerGPUs, err := resolveWorkerGPUs(config, plan, deviceSnapshot, launch.forceCPU)
	if err != nil {
		return err
	}
	command, err := engineruntime.BuildAdapterCommand(launch.capability, requested, engineruntime.AdapterPaths{Server: launch.server})
	if err != nil {
		return err
	}

	resolvedConfig := cloneEngineConfig(config)
	resolvedConfig.RuntimeOptions["kv_cache_dtype"] = command.Effective.KVCacheDType
	resolvedPlannerType := plannerKVType(resolvedConfig, record.Metadata.Quantization)
	if resolvedPlannerType != plan.KVCacheDType {
		if command.Effective.KVCacheDType == "f16" || command.Effective.KVCacheDType == "bf16" || command.Effective.KVCacheDType == "f32" {
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
	applyWorkerDeviceSelection(command.Env, workerGPUs)
	m.setOperationDetail(operationID, "running", 0.62, "launching_worker", "Modellprozess wird gestartet", "Die Runtime ist bereit. Jetzt werden Modellgewichte und KV-Cache geladen.", nil)
	m.setInstanceStateDetail(instanceID, engineruntime.StateStarting, 0.62, "launching_worker", "Der lokale Modellprozess wird gestartet.", "")
	processSpec := command.ProcessSpec(instanceID)
	processSpec.SpawnAdmission = m.acquireWorkerSpawn
	if err := m.validateOperationLRUEvictionsReleased(operationID); err != nil {
		return err
	}
	memoryLimit, err := m.validateLoadPeakWithNormalLRU(ctx, record, plan, operationID, instanceID)
	if err != nil {

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

		log.Printf("[engine] worker port conflict for %s, retrying with a fresh port: %v", instanceID, err)
		m.setInstanceStateDetail(instanceID, engineruntime.StateStarting, 0.62, "launching_worker", "Der lokale Netzwerk-Port war belegt. Der Start wird automatisch mit einem neuen Port wiederholt.", "")
		handle, err = m.supervisor.Start(ctx, processSpec)
	}
	if err != nil {

		if isMemoryExhaustionError(err) && fallbackEnabled(config) &&
			computeReducedContext(plan.EffectiveContextTokens, plan.KVBytesPerTokenAtStart, err) > 0 {
			return m.retryReducedContext(ctx, instanceID, config, plan, operationID, err)
		}
		if next, ok := nextKVCacheFallback(command.Effective.KVCacheDType); ok && fallbackEnabled(config) {
			return m.retryKVCache(ctx, instanceID, config, plan, operationID, command.Effective.KVCacheDType, next, err)
		}
		if fallbackEnabled(config) && !forceCPURequested(config) {
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
		if next, ok := nextKVCacheFallback(command.Effective.KVCacheDType); ok && fallbackEnabled(config) {
			return m.retryKVCache(ctx, instanceID, config, plan, operationID, command.Effective.KVCacheDType, next, err)
		}
		if fallbackEnabled(config) && !forceCPURequested(config) {
			return m.retryLlamaCPU(ctx, instanceID, config, plan, operationID, err)
		}
		return fmt.Errorf("Mini-Inferenztest fehlgeschlagen: %w", err)
	}

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
		if timeout := m.instanceIdleTimeout(instance); timeout > 0 {
			expires := now.Add(timeout)
			instance.IdleExpiresAt = &expires
		}
	}
	instance.Placement = placementForPlan(&plan)
	instance.GuardState = m.guardState
	instance.LastKnownGood = &LastKnownGood{EffectiveConfig: cloneEngineConfig(effective), Plan: plan, Runtime: string(launch.kind), UpdatedAt: instance.UpdatedAt}

	m.inferenceMu.Lock()
	m.inferenceGates[instanceID] = &inferenceGate{}
	m.inferenceMu.Unlock()
	copy := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	m.events.publish("instance_changed", copy)
	// The instance came up, so whatever crash history it carried is closed.
	m.noteInstanceRecovered(instanceID)
	go m.monitorWorker(instanceID, handle, process.BaseURL, command.InternalAPIKey)
	workerCommitted = true
	return nil
}

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

// resolveWorkerGPUs turns the planner's GPU allocation into the concrete
// devices the worker may see, so the process is confined to what was budgeted.
func resolveWorkerGPUs(config EngineConfig, plan ContextPlanView, snapshot hardware.Snapshot, forceCPU bool) ([]hardware.GPU, error) {
	if forceCPU {
		return nil, nil
	}
	plannedIDs := []string{}
	for id, planned := range plan.Memory.Total.GPUBytes {
		if planned > 0 {
			plannedIDs = append(plannedIDs, id)
		}
	}
	if len(plannedIDs) == 0 {
		return nil, nil
	}
	sort.Strings(plannedIDs)

	selected := stringSliceOption(config.RuntimeOptions, "gpu_ids")
	if len(selected) == 0 {
		selected = plannedIDs
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
	return result, nil
}

func applyWorkerDeviceSelection(environment map[string]string, selected []hardware.GPU) {
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
	if indices := indicesByBackend["vulkan"]; len(indices) > 0 {
		environment["GGML_VK_VISIBLE_DEVICES"] = strings.Join(indices, ",")
	}
}
