package engine

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func (m *EngineModule) monitorWorker(instanceID string, handle *engineruntime.InstanceHandle, baseURL, secret string) {
	<-handle.Done()
	snapshot := handle.Snapshot()
	m.mu.Lock()
	instance := m.instances[instanceID]
	if instance == nil || instance.BaseURL != baseURL || instance.WorkerSecret != secret || instance.State != engineruntime.StateReady {
		m.mu.Unlock()
		return
	}
	instance.State = engineruntime.StateFailed
	instance.Progress = 1
	instance.Phase = "worker_exited"
	instance.BaseURL = ""
	instance.WorkerSecret = ""
	instance.ActiveRequests = 0
	instance.IdleExpiresAt = nil
	instance.Error = snapshot.Error
	if instance.Error == "" {
		instance.Error = "Model-Worker wurde unerwartet beendet"
	}
	instance.ErrorCode, instance.ErrorSummary = classifyEngineError(errors.New(instance.Error))
	instance.DetailMessage = instance.ErrorSummary
	instance.UpdatedAt = time.Now().UTC()
	copy := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	log.Printf("[engine-instance] id=%s state=%s phase=%s progress=%.2f detail=%q error_code=%s error_summary=%q",
		copy.ID, copy.State, copy.Phase, copy.Progress, sanitizeEngineLogText(copy.DetailMessage), copy.ErrorCode, sanitizeEngineLogText(copy.ErrorSummary))
	m.events.publish("instance_changed", copy)
	// Detecting the exit is only half the job: without this the instance stays
	// failed until somebody presses start again.
	m.considerCrashRestart(instanceID)
}

// nextKVCacheFallback walks down the quantised cache ladder when a start
// fails: q4_0 to q8_0 to f16. f16 is the end of the line, it always works.
func nextKVCacheFallback(current string) (string, bool) {
	switch strings.ToLower(strings.TrimSpace(current)) {
	case "q4_0", "q4_1", "iq4_nl", "q5_0", "q5_1":
		return "q8_0", true
	case "q8_0":
		return "f16", true
	}
	return "", false
}

func (m *EngineModule) retryKVCache(ctx context.Context, instanceID string, config EngineConfig, plan ContextPlanView, operationID, from, to string, workerErr error) error {
	fallbackConfig := cloneEngineConfig(config)
	fallbackConfig.RuntimeOptions["kv_cache_dtype"] = to
	if to == "f16" || to == "bf16" || to == "f32" {
		fallbackConfig.KVCachePolicy = "native"
	}
	m.mu.RLock()
	instance := m.instances[instanceID]
	modelID := ""
	if instance != nil {
		modelID = instance.ModelID
	}
	m.mu.RUnlock()
	if modelID == "" {
		return os.ErrNotExist
	}
	replanned, _, planErr := m.recommendation(ctx, modelID, instanceID, fallbackConfig)
	if planErr != nil {
		return fmt.Errorf("KV-Cache-Fallback %s passt nicht in das aktuelle Hardwarebudget: %w", to, planErr)
	}
	if len(replanned.AffectedRestartInstances) > 0 {
		return fmt.Errorf("KV-Cache-Fallback %s wuerde zusaetzliche laufende Instanzen neu starten; Transaktion wird sicher zurueckgerollt", to)
	}
	plan = replanned
	m.setOperation(operationID, "running", 0.68, "KV-Cache "+from+" fehlgeschlagen; Fallback "+to+" wird geprueft", nil)
	if err := m.startOne(ctx, instanceID, fallbackConfig, plan, operationID); err != nil {
		return err
	}
	m.mu.Lock()
	if instance := m.instances[instanceID]; instance != nil {
		instance.Fallbacks = append([]engineruntime.Fallback{{Setting: "kv_cache_dtype", From: from, To: to, Reason: "Worker-Start oder Mini-Inferenztest fehlgeschlagen: " + workerErr.Error()}}, instance.Fallbacks...)
		_ = m.persistLocked()
	}
	m.mu.Unlock()
	return nil
}

func fallbackEnabled(config EngineConfig) bool {
	return config.AllowFallback == nil || *config.AllowFallback
}

func forceCPURequested(config EngineConfig) bool {
	forced, _ := boolOption(config.RuntimeOptions, "force_cpu_runtime")
	if forced {
		return true
	}
	if offload, _ := stringOption(config.RuntimeOptions, "offload"); offload == "cpu" {
		return true
	}
	if gpuLayers, exists := intOption(config.RuntimeOptions, "gpu_layers"); exists && gpuLayers != nil && *gpuLayers == 0 {
		return true
	}
	return false
}

const (
	contextFloorTokens          = 2048
	contextSearchStepTokens     = 256
	contextSearchModeOption     = "context_search_mode"
	contextSearchFloorOption    = "_context_search_floor_tokens"
	contextSearchCeilingOption  = "_context_search_ceiling_tokens"
	contextSearchMaximizeStable = "maximize_stable"
)

func contextSearchRequested(config EngineConfig) bool {
	mode, _ := stringOption(config.RuntimeOptions, contextSearchModeOption)
	return strings.EqualFold(mode, contextSearchMaximizeStable)
}

func contextSearchBound(config EngineConfig, key string) int {
	value, ok := intOption(config.RuntimeOptions, key)
	if !ok || value == nil || *value <= 0 {
		return 0
	}
	return *value
}

func setContextSearchBounds(config *EngineConfig, floor, ceiling int) {
	if config.RuntimeOptions == nil {
		config.RuntimeOptions = map[string]interface{}{}
	}
	config.RuntimeOptions[contextSearchModeOption] = contextSearchMaximizeStable
	if floor > 0 {
		config.RuntimeOptions[contextSearchFloorOption] = floor
	} else {
		delete(config.RuntimeOptions, contextSearchFloorOption)
	}
	if ceiling > 0 {
		config.RuntimeOptions[contextSearchCeilingOption] = ceiling
	} else {
		delete(config.RuntimeOptions, contextSearchCeilingOption)
	}
}

func clearContextSearchOptions(config *EngineConfig) {
	if config.RuntimeOptions == nil {
		return
	}
	delete(config.RuntimeOptions, contextSearchModeOption)
	delete(config.RuntimeOptions, contextSearchFloorOption)
	delete(config.RuntimeOptions, contextSearchCeilingOption)
}

func stableContextRequest(original EngineConfig, contextTokens int) EngineConfig {
	result := cloneEngineConfig(original)
	result.ContextMode = "fixed"
	result.ContextTokens = intPointer(contextTokens)
	clearContextSearchOptions(&result)
	return result
}

func contextSearchMidpoint(lower, upper int) int {
	if lower < contextFloorTokens {
		lower = contextFloorTokens
	}
	if upper-lower <= contextSearchStepTokens {
		return 0
	}
	middle := lower + (upper-lower)/2
	middle -= middle % contextSearchStepTokens
	if middle <= lower {
		middle = (lower/contextSearchStepTokens + 1) * contextSearchStepTokens
	}
	if middle >= upper {
		return 0
	}
	return middle
}

func nextContextAfterFailure(current int, kvBytesPerToken int64, cause error, verifiedFloor int, search bool) int {
	reduced := computeReducedContext(current, kvBytesPerToken, cause)
	if !search || verifiedFloor <= 0 {
		return reduced
	}
	if verifiedFloor >= current {
		return 0
	}
	if midpoint := contextSearchMidpoint(verifiedFloor, current); midpoint > 0 {
		return midpoint
	}
	return verifiedFloor
}

func nextContextAfterSuccess(current, failedCeiling int) int {
	if failedCeiling <= current {
		return 0
	}
	return contextSearchMidpoint(current, failedCeiling)
}

func computeReducedContext(current int, kvBytesPerToken int64, cause error) int {
	if current <= contextFloorTokens {
		return 0
	}
	reduced := current / 2
	var conflict *ResourceConflictError
	if errors.As(cause, &conflict) && kvBytesPerToken > 0 {
		deficit := conflict.RequiredBytes - conflict.AvailableBytes
		if deficit > 0 {

			tokensToCut := int((deficit + deficit/4 + kvBytesPerToken - 1) / kvBytesPerToken)
			computed := current - tokensToCut

			if computed > reduced {
				reduced = computed
			}
		}
	}
	reduced -= reduced % 256
	if reduced < contextFloorTokens {
		reduced = contextFloorTokens
	}
	if reduced >= current {
		return 0
	}
	return reduced
}

func isMemoryExhaustionError(err error) bool {
	if err == nil {
		return false
	}
	var conflict *ResourceConflictError
	if errors.As(err, &conflict) {
		return true
	}
	text := err.Error()
	code, _, ok := engineruntime.ParseDiagnosisMarker(text)
	if !ok {
		if diagnosis, matched := engineruntime.DiagnoseWorkerOutput(text); matched {
			code = diagnosis.Code
		}
	}
	return code == "ram_out_of_memory" || code == "gpu_out_of_memory"
}
