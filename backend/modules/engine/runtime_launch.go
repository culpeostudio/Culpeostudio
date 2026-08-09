package engine

import (
	"context"
	"errors"
	"os"
	"strings"

	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
)

func (m *EngineModule) prepareRuntime(ctx context.Context, instanceID string, config EngineConfig, operationID string) (runtimeLaunch, error) {
	m.mu.RLock()
	instance := m.instances[instanceID]
	if instance == nil {
		m.mu.RUnlock()
		return runtimeLaunch{}, os.ErrNotExist
	}
	m.mu.RUnlock()

	snapshot, _ := m.liveHardware(ctx)
	forceCPURuntime := forceCPURequested(config)
	if forceCPURuntime {
		snapshot.GPUs = nil
	}

	// A machine with GPUs but no published build for any of them can only run on
	// the CPU. Say so before falling back, unless the caller already opted into
	// RAM offload.
	if !forceCPURuntime && len(snapshot.GPUs) > 0 && !snapshotHasUsableGPU(snapshot) {
		if !ramOffloadAllowed(config) {
			return runtimeLaunch{}, &gpuRuntimeUnavailableError{
				Reason:      unsupportedGPUReason(snapshot),
				Remediation: "use_cpu_runtime",
			}
		}
		forceCPURuntime = true
	}

	build, fallbacks, err := m.selectBuild(snapshot, forceCPURuntime)
	if err != nil {
		return runtimeLaunch{}, err
	}
	if build.Variant == engineruntime.BuildCPU {
		forceCPURuntime = true
	}

	launch, err := m.prepareBuild(ctx, instanceID, build, fallbacks, operationID)
	if err == nil {
		launch.forceCPU = forceCPURuntime
		return launch, nil
	}

	// A GPU build that will not download or will not start is still recoverable:
	// the CPU build runs the same model, just slower.
	if forceCPURuntime || !fallbackEnabled(config) || build.Variant == engineruntime.BuildCPU {
		return runtimeLaunch{}, err
	}
	if !ramOffloadAllowed(config) {
		return runtimeLaunch{}, &gpuRuntimeUnavailableError{
			Reason:      "Der " + string(build.Variant) + "-Build von llama-server konnte nicht vorbereitet werden: " + err.Error(),
			Remediation: "reinstall_runtime",
		}
	}
	cpuBuild, cpuErr := m.selectBuildForCPU()
	if cpuErr != nil {
		return runtimeLaunch{}, err
	}
	cpuFallback := engineruntime.Fallback{
		Setting: "compute_backend",
		From:    string(build.Variant),
		To:      string(engineruntime.BuildCPU),
		Reason:  "der GPU-Build von llama-server liess sich nicht vorbereiten: " + err.Error(),
	}
	cpuLaunch, cpuLaunchErr := m.prepareBuild(ctx, instanceID, cpuBuild, append(fallbacks, cpuFallback), operationID)
	cpuLaunch.forceCPU = cpuLaunchErr == nil
	return cpuLaunch, cpuLaunchErr
}

func (m *EngineModule) selectBuildForCPU() (engineruntime.Build, error) {
	build, _, err := m.selectBuild(hardware.Snapshot{}, true)
	return build, err
}

// unsupportedGPUReason explains why detected GPUs cannot be used, naming them so
// the message is actionable rather than generic.
func unsupportedGPUReason(snapshot hardware.Snapshot) string {
	names := []string{}
	for _, gpu := range snapshot.GPUs {
		name := gpu.Name
		if name == "" {
			name = gpu.Vendor
		}
		if name != "" {
			names = append(names, name)
		}
	}
	reason := "Für die erkannte Grafikhardware ist kein llama-server-Build verfügbar"
	if len(names) > 0 {
		reason += " (" + strings.Join(uniqueStrings(names), ", ") + ")"
	}
	return reason + "."
}

// prepareBuild makes sure the build is downloaded and verified, then reports
// where its binary lives.
func (m *EngineModule) prepareBuild(ctx context.Context, instanceID string, build engineruntime.Build, fallbacks []engineruntime.Fallback, operationID string) (runtimeLaunch, error) {
	if m.installer == nil {
		return runtimeLaunch{}, errors.New("der Runtime-Installer ist nicht verfuegbar; llama-server kann nicht vorbereitet werden")
	}
	capability := m.installer.Capability(build, engineruntime.DefaultCapability(build.Variant))
	if !capability.Installed {
		if previous, exists := m.installer.Latest(build); exists && previous.Status == engineruntime.InstallFailed {
			return runtimeLaunch{}, errors.New(previous.Message + ": " + previous.ErrorSummary)
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
		job, err := m.startRuntimeInstall(ctx, build)
		if err != nil {
			return runtimeLaunch{}, err
		}
		if _, waitErr := m.waitRuntimeInstall(ctx, operationID, progressInstanceID, job, "llama-server ("+string(build.Variant)+") wird vorbereitet"); waitErr != nil {
			return runtimeLaunch{}, waitErr
		}
		capability = m.installer.Capability(build, engineruntime.DefaultCapability(build.Variant))
	}
	if !capability.Healthy || capability.ServerPath == "" {
		reason := capability.ProbeError
		if reason == "" {
			reason = "die Installation wurde nicht als einsatzbereit bestaetigt"
		}
		return runtimeLaunch{}, errors.New("llama-server (" + string(build.Variant) + ") ist nicht einsatzbereit: " + reason)
	}
	return runtimeLaunch{
		kind:       engineruntime.RuntimeLlamaCPP,
		build:      build,
		capability: capability,
		server:     capability.ServerPath,
		fallbacks:  fallbacks,
	}, nil
}
