package engine

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func (m *EngineModule) retryReducedContext(ctx context.Context, instanceID string, config EngineConfig, plan ContextPlanView, operationID string, cause error) error {
	current := plan.EffectiveContextTokens
	m.mu.RLock()
	instance := m.instances[instanceID]
	modelID := ""
	verifiedFloor := contextSearchBound(config, contextSearchFloorOption)
	if instance != nil {
		modelID = instance.ModelID
		if instance.LastKnownGood != nil {
			knownGood := instance.LastKnownGood.Plan.EffectiveContextTokens
			if knownGood > verifiedFloor && knownGood < current {
				verifiedFloor = knownGood
			}
		}
	}
	m.mu.RUnlock()
	searching := contextSearchRequested(config)
	reduced := nextContextAfterFailure(current, plan.KVBytesPerTokenAtStart, cause, verifiedFloor, searching)
	if reduced <= 0 {
		if searching && verifiedFloor >= current {
			return fmt.Errorf("Der zuletzt bestaetigte Kontext von %d Token war im aktuellen Suchlauf nicht mehr stabil. Die vorherige funktionierende Konfiguration wird wiederhergestellt: %w", verifiedFloor, cause)
		}
		return fmt.Errorf("Auch mit dem minimalen Kontext von %d Token reicht der Speicher nicht aus. Bitte andere Modelle stoppen, Programme schliessen oder ein kleineres Modell verwenden: %w", contextFloorTokens, cause)
	}
	if modelID == "" {
		return cause
	}
	fallbackConfig := cloneEngineConfig(config)
	fallbackConfig.ContextMode = "fixed"
	fallbackConfig.ContextTokens = intPointer(reduced)
	detail := fmt.Sprintf("Der Speicher reicht fuer %d Token nicht aus. Der Start wird automatisch mit %d Token Kontext wiederholt.", current, reduced)
	title := "Kontext wird automatisch reduziert"
	if searching {
		title = "Stabilen Kontext automatisch suchen"
		setContextSearchBounds(&fallbackConfig, verifiedFloor, current)
		if verifiedFloor > 0 {
			detail = fmt.Sprintf("%d Token waren nicht stabil. Zwischen dem bestaetigten Wert %d und dieser Obergrenze wird jetzt mit %d Token weitergesucht.", current, verifiedFloor, reduced)
		}
	}
	m.setOperationDetail(operationID, "running", 0.58, "reducing_context",
		title, detail, nil)

	deadline := time.Now().Add(10 * time.Second)
	for {
		select {
		case <-time.After(2 * time.Second):
		case <-ctx.Done():
			return ctx.Err()
		}
		m.mu.RLock()
		guard := m.guardState
		m.mu.RUnlock()
		if guard == GuardNormal || time.Now().After(deadline) {
			break
		}
		m.setOperationDetail(operationID, "running", 0.58, "reducing_context",
			"Speicher wird freigegeben",
			"Der Speicher des beendeten Modellprozesses wird freigegeben; der automatische Neuversuch wartet kurz.", nil)
	}
	reducedPlan, _, planErr := m.recommendation(ctx, modelID, instanceID, fallbackConfig)
	if planErr != nil {
		return cause
	}
	if len(reducedPlan.AffectedRestartInstances) > 0 {

		return cause
	}
	if err := m.startOne(ctx, instanceID, fallbackConfig, reducedPlan, operationID); err != nil {
		return err
	}
	m.mu.Lock()
	var changed *EngineInstance
	if instance := m.instances[instanceID]; instance != nil {
		reason := "Kontext wurde wegen Speicher-Engpass automatisch reduziert."
		if searching {
			reason = "Suchschritt zum hoechsten stabilen Kontext nach einem Speicher-Engpass."
		}
		instance.Fallbacks = append([]engineruntime.Fallback{{
			Setting: "context_tokens",
			From:    fmt.Sprintf("%d", current),
			To:      fmt.Sprintf("%d", reduced),
			Reason:  reason,
		}}, instance.Fallbacks...)
		changed = cloneInstance(instance)
		_ = m.persistLocked()
	}
	m.mu.Unlock()
	if changed != nil {
		m.events.publish("instance_changed", changed)
	}
	return nil
}

func (m *EngineModule) retryLlamaCPU(ctx context.Context, instanceID string, config EngineConfig, plan ContextPlanView, operationID string, gpuErr error) error {
	if !ramOffloadAllowed(config) {
		var conflict *ResourceConflictError
		if errors.As(gpuErr, &conflict) {
			return gpuErr
		}
		if isMemoryExhaustionError(gpuErr) {
			return &ramOffloadRequiredError{Cause: gpuErr}
		}
		return &gpuRuntimeUnavailableError{
			Reason:      "Der GPU-Start ist fehlgeschlagen und CPU/System-RAM wurden fuer diesen Plan nicht freigegeben: " + gpuErr.Error(),
			Remediation: "rebuild_gpu_runtime",
		}
	}
	fallbackConfig := cloneEngineConfig(config)
	fallbackConfig.Runtime = string(engineruntime.RuntimeLlamaCPP)
	fallbackConfig.RuntimeOptions["force_cpu_runtime"] = true
	fallbackConfig.RuntimeOptions["offload"] = "cpu"
	fallbackConfig.RuntimeOptions["gpu_layers"] = 0
	m.setOperation(operationID, "running", 0.65, "llama.cpp GPU-Backend fehlgeschlagen; CPU-Fallback wird gestartet", nil)
	if err := m.startOne(ctx, instanceID, fallbackConfig, plan, operationID); err != nil {
		return fmt.Errorf("llama.cpp GPU-Backend fehlgeschlagen (%v), CPU-Fallback ebenfalls fehlgeschlagen: %w", gpuErr, err)
	}
	m.mu.Lock()
	if instance := m.instances[instanceID]; instance != nil {
		instance.Fallbacks = append([]engineruntime.Fallback{{Setting: "compute_backend", From: "gpu", To: "cpu", Reason: "GPU-Start oder Mini-Inferenztest fehlgeschlagen: " + gpuErr.Error()}}, instance.Fallbacks...)
		_ = m.persistLocked()
	}
	m.mu.Unlock()
	return nil
}

func effectiveEngineConfig(requested EngineConfig, effective engineruntime.EffectiveConfig, plan ContextPlanView) EngineConfig {
	result := cloneEngineConfig(requested)
	result.Runtime = string(effective.Runtime)
	result.ContextMode = "fixed"
	result.ContextTokens = intPointer(plan.EffectiveContextTokens)
	result.RuntimeOptions["kv_cache_dtype"] = effective.KVCacheDType
	setOptionalInt(result.RuntimeOptions, "gpu_layers", effective.GPULayers)
	setOptionalInt(result.RuntimeOptions, "threads", effective.Threads)
	setOptionalInt(result.RuntimeOptions, "main_gpu", effective.MainGPU)
	if effective.FlashAttention != "" {
		result.RuntimeOptions["flash_attention"] = effective.FlashAttention
	} else {
		delete(result.RuntimeOptions, "flash_attention")
	}
	if effective.SplitMode != "" {
		result.RuntimeOptions["split_mode"] = effective.SplitMode
	} else {
		delete(result.RuntimeOptions, "split_mode")
	}
	if len(effective.GPUMemoryBytes) > 0 {
		result.RuntimeOptions["gpu_memory_bytes"] = append([]int64(nil), effective.GPUMemoryBytes...)
	} else {
		delete(result.RuntimeOptions, "gpu_memory_bytes")
	}
	if effective.CPUMemoryBytes != nil {
		result.RuntimeOptions["cpu_memory_bytes"] = *effective.CPUMemoryBytes
	} else {
		delete(result.RuntimeOptions, "cpu_memory_bytes")
	}
	return result
}

func setOptionalInt(values map[string]interface{}, key string, value *int) {
	if value == nil {
		delete(values, key)
		return
	}
	values[key] = *value
}

func verifyWorker(ctx context.Context, baseURL, secret, instanceID string) error {
	verifyCtx, cancel := context.WithTimeout(ctx, 90*time.Second)
	defer cancel()
	payload, _ := json.Marshal(map[string]interface{}{"model": instanceID, "prompt": " ", "max_tokens": 1, "temperature": 0})
	request, err := http.NewRequestWithContext(verifyCtx, http.MethodPost, strings.TrimRight(baseURL, "/")+"/v1/completions", bytes.NewReader(payload))
	if err != nil {
		return err
	}
	request.Header.Set("Authorization", "Bearer "+secret)
	request.Header.Set("Content-Type", "application/json")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(response.Body, 4096))
		return fmt.Errorf("Worker HTTP %d: %s", response.StatusCode, strings.TrimSpace(string(body)))
	}
	_, _ = io.Copy(io.Discard, response.Body)
	return nil
}
