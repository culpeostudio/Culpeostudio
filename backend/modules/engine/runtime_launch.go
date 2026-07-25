package engine

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

func (m *EngineModule) prepareRuntime(ctx context.Context, instanceID string, config EngineConfig, operationID string) (runtimeLaunch, error) {
	m.mu.RLock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.RUnlock()
		return runtimeLaunch{}, os.ErrNotExist
	}
	modelID := instance.ModelID
	record := m.modelsByID[modelID]
	m.mu.RUnlock()
	snapshot, _ := m.liveHardware(ctx)
	forceCPURuntime := forceCPURequested(config)
	if forceCPURuntime {
		snapshot.GPUs = nil
	}
	kind, runtimeFallbacks, err := m.selectRuntime(record, config, snapshot)
	if err != nil {
		return runtimeLaunch{}, err
	}
	if kind == engineruntime.RuntimeLlamaCPP && !forceCPURuntime {
		usableSnapshot, buildWarnings := usableLlamaBuildSnapshot(snapshot)
		useInstalledGPUEnvironment := len(usableSnapshot.GPUs) != len(snapshot.GPUs) && m.healthyLlamaGPUCapability(snapshot)
		if len(usableSnapshot.GPUs) != len(snapshot.GPUs) && !useInstalledGPUEnvironment {
			from := "gpu"
			if len(snapshot.GPUs) > 0 && snapshot.GPUs[0].Backend != "" {
				from = snapshot.GPUs[0].Backend
			}
			reason := strings.Join(buildWarnings, "; ")
			if reason == "" {
				reason = "Entwicklungsdateien fuer das erkannte Compute-Backend fehlen"
			}
			runtimeFallbacks = append(runtimeFallbacks, engineruntime.Fallback{Setting: "compute_backend", From: from, To: "cpu", Reason: reason})
		}
		if !useInstalledGPUEnvironment {
			snapshot = usableSnapshot
		}
		if len(snapshot.GPUs) == 0 {
			if !ramOffloadAllowed(config) {
				reason := strings.Join(buildWarnings, "; ")
				if reason == "" {
					reason = "Die GPU-Build-Abhaengigkeiten sind nicht einsatzbereit."
				}
				return runtimeLaunch{}, &gpuRuntimeUnavailableError{
					Reason:      reason,
					Remediation: "install_vulkan_dependencies",
				}
			}
			forceCPURuntime = true
		}
	}
	launch, err := m.prepareSelectedRuntime(ctx, instanceID, kind, snapshot, runtimeFallbacks, operationID)
	if err == nil {
		launch.forceCPU = forceCPURuntime
		return launch, nil
	}
	if kind == engineruntime.RuntimeLlamaCPP && fallbackEnabled(config) && !forceCPURuntime && len(snapshot.GPUs) > 0 {
		if !ramOffloadAllowed(config) {
			return runtimeLaunch{}, &gpuRuntimeUnavailableError{
				Reason:      "Der llama.cpp-GPU-Build oder sein GPU-Funktionstest ist fehlgeschlagen: " + err.Error(),
				Remediation: "rebuild_gpu_runtime",
			}
		}
		cpuSnapshot := snapshot
		cpuSnapshot.GPUs = nil
		fallback := engineruntime.Fallback{Setting: "compute_backend", From: snapshot.GPUs[0].Backend, To: "cpu", Reason: "llama.cpp GPU-Build oder Runtime-Probe ist fehlgeschlagen: " + err.Error()}
		cpuLaunch, cpuErr := m.prepareSelectedRuntime(ctx, instanceID, kind, cpuSnapshot, append(runtimeFallbacks, fallback), operationID)
		cpuLaunch.forceCPU = cpuErr == nil
		return cpuLaunch, cpuErr
	}
	if kind == engineruntime.RuntimeTransformers && fallbackEnabled(config) && !forceCPURuntime && len(snapshot.GPUs) > 0 {
		cpuSnapshot := snapshot
		cpuSnapshot.GPUs = nil
		fallback := engineruntime.Fallback{Setting: "compute_backend", From: snapshot.GPUs[0].Backend, To: "cpu", Reason: "accelerator-spezifische Torch-Installation oder Probe ist fehlgeschlagen: " + err.Error()}
		cpuLaunch, cpuErr := m.prepareSelectedRuntime(ctx, instanceID, kind, cpuSnapshot, append(runtimeFallbacks, fallback), operationID)
		cpuLaunch.forceCPU = cpuErr == nil
		return cpuLaunch, cpuErr
	}
	if kind != engineruntime.RuntimeVLLM || !fallbackEnabled(config) || record.Format != modelcatalog.FormatSafeTensors {
		return launch, err
	}
	fallback := engineruntime.Fallback{Setting: "runtime", From: string(kind), To: string(engineruntime.RuntimeTransformers), Reason: "vLLM-Installation oder Runtime-Probe ist fehlgeschlagen: " + err.Error()}
	return m.prepareSelectedRuntime(ctx, instanceID, engineruntime.RuntimeTransformers, snapshot, append(runtimeFallbacks, fallback), operationID)
}

func (m *EngineModule) prepareSelectedRuntime(ctx context.Context, instanceID string, kind engineruntime.RuntimeKind, snapshot hardware.Snapshot, runtimeFallbacks []engineruntime.Fallback, operationID string) (runtimeLaunch, error) {
	recipe, err := m.runtimeRecipe(kind, snapshot)
	if err != nil {
		return runtimeLaunch{}, err
	}
	if m.installer == nil {
		return runtimeLaunch{}, fmt.Errorf("Python 3 fehlt; Runtime %s kann nicht automatisch installiert werden", kind)
	}
	capability := m.installer.Capability(recipe, engineruntime.DefaultCapability(kind))
	if !capability.Installed {
		if previous, exists := m.installer.Latest(recipe); exists && previous.Status == engineruntime.InstallFailed {
			return runtimeLaunch{}, fmt.Errorf("%s: %s", previous.Message, previous.ErrorSummary)
		}
		m.mu.RLock()
		current := m.instances[instanceID]
		keepServing := current != nil && current.State == engineruntime.StateReady && current.BaseURL != ""
		m.mu.RUnlock()
		progressInstanceID := ""
		if !keepServing {
			m.setInstanceState(instanceID, engineruntime.StateInstalling, 0.1, "")
			progressInstanceID = instanceID
		}
		releaseForeground, err := m.beginForegroundRuntime(ctx)
		if err != nil {
			return runtimeLaunch{}, err
		}
		defer releaseForeground()
		job, err := m.startRuntimeInstall(ctx, recipe)
		if err != nil {
			return runtimeLaunch{}, err
		}
		_, waitErr := m.waitRuntimeInstall(ctx, operationID, progressInstanceID, job, "Runtime "+string(kind)+" wird vorbereitet")
		if waitErr != nil {
			return runtimeLaunch{}, waitErr
		}
		capability = m.installer.Capability(recipe, engineruntime.DefaultCapability(kind))
	}
	if !capability.Healthy {
		return runtimeLaunch{}, fmt.Errorf("Runtime-Probe fuer %s ist nicht gesund: %s", kind, capability.ProbeError)
	}
	return runtimeLaunch{kind: kind, recipe: recipe, capability: capability, python: runtimeEnvironmentPython(capability.Environment), fallbacks: runtimeFallbacks}, nil
}
