package engine

import (
	"context"
	"fmt"
	"os"
	"runtime"
	"strings"

	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
)

// variantOverrideEnv pins the build variant, bypassing hardware detection. It
// exists for support cases where the detected vendor picks a build the machine
// cannot actually run.
const variantOverrideEnv = "ENGINE_LLAMA_VARIANT"

// preferredVariant picks the llama-server build for this machine. GPUs are
// considered in the order the probe reported them, and the first one with a
// published build wins; a machine with no usable accelerator gets the CPU build.
func preferredVariant(snapshot hardware.Snapshot) engineruntime.BuildVariant {
	if override := strings.ToLower(strings.TrimSpace(os.Getenv(variantOverrideEnv))); override != "" {
		for _, variant := range engineruntime.KnownBuildVariants() {
			if string(variant) == override {
				return variant
			}
		}
	}
	for _, gpu := range snapshot.GPUs {
		// Integrated parts that report no memory of their own are not worth a
		// GPU build; Apple is the exception, where shared memory is the design.
		if gpu.SharedMemory && !strings.EqualFold(gpu.Vendor, "apple") {
			continue
		}
		variant := engineruntime.VariantForVendor(runtime.GOOS, runtime.GOARCH, gpu.Vendor, gpu.Backend)
		if variant != engineruntime.BuildCPU {
			return variant
		}
	}
	return engineruntime.BuildCPU
}

// selectBuild resolves the build to install and run. When the preferred variant
// has no published archive for this platform it degrades to CPU and records why,
// so the reason reaches the instance rather than being swallowed.
func (m *EngineModule) selectBuild(snapshot hardware.Snapshot, forceCPU bool) (engineruntime.Build, []engineruntime.Fallback, error) {
	variant := engineruntime.BuildCPU
	if !forceCPU {
		variant = preferredVariant(snapshot)
	}
	build, err := engineruntime.BuildFor(runtime.GOOS, runtime.GOARCH, variant)
	if err == nil {
		return build, nil, nil
	}
	if variant == engineruntime.BuildCPU {
		return engineruntime.Build{}, nil, fmt.Errorf("fuer %s/%s ist kein llama-server-Build hinterlegt: %w", runtime.GOOS, runtime.GOARCH, err)
	}
	cpuBuild, cpuErr := engineruntime.BuildFor(runtime.GOOS, runtime.GOARCH, engineruntime.BuildCPU)
	if cpuErr != nil {
		return engineruntime.Build{}, nil, fmt.Errorf("fuer %s/%s ist kein llama-server-Build hinterlegt: %w", runtime.GOOS, runtime.GOARCH, cpuErr)
	}
	fallback := engineruntime.Fallback{
		Setting: "compute_backend",
		From:    string(variant),
		To:      string(engineruntime.BuildCPU),
		Reason:  err.Error(),
	}
	return cpuBuild, []engineruntime.Fallback{fallback}, nil
}

// gpuUsableForLlama reports whether a detected GPU maps to a real GPU build on
// this platform. It replaces the old check for compiler and header
// availability, which prebuilt binaries make irrelevant.
func gpuUsableForLlama(gpu hardware.GPU) bool {
	if gpu.SharedMemory && !strings.EqualFold(gpu.Vendor, "apple") {
		return false
	}
	if gpu.VRAMTotalBytes <= 0 && !strings.EqualFold(gpu.Vendor, "apple") {
		return false
	}
	return engineruntime.VariantForVendor(runtime.GOOS, runtime.GOARCH, gpu.Vendor, gpu.Backend) != engineruntime.BuildCPU
}

// snapshotHasUsableGPU reports whether any detected GPU has a published build.
func snapshotHasUsableGPU(snapshot hardware.Snapshot) bool {
	for _, gpu := range snapshot.GPUs {
		if gpuUsableForLlama(gpu) {
			return true
		}
	}
	return false
}

func (m *EngineModule) runtimeCapabilities(ctx context.Context) (hardware.Snapshot, []engineruntime.RuntimeCapability) {
	snapshot, _ := m.liveHardware(ctx)
	variant := preferredVariant(snapshot)
	build, buildErr := engineruntime.BuildFor(runtime.GOOS, runtime.GOARCH, variant)
	capability := engineruntime.DefaultCapability(variant)
	if buildErr != nil {
		capability.ProbeError = buildErr.Error()
		capability.Status = "incompatible"
		capability.StatusMessage = "Fuer diese Plattform ist kein passender llama-server-Build hinterlegt"
		return snapshot, []engineruntime.RuntimeCapability{capability}
	}
	if m.installer == nil {
		capability.ProbeError = "Der Runtime-Installer ist nicht verfuegbar"
		capability.Status = "incompatible"
		capability.StatusMessage = "llama-server kann nicht automatisch vorbereitet werden"
		return snapshot, []engineruntime.RuntimeCapability{capability}
	}

	capability = m.installer.Capability(build, capability)
	if capability.Installed && capability.Healthy {
		capability.Status = "ready"
		capability.StatusMessage = "llama-server ist installiert und einsatzbereit"
		capability.Progress = 1
	} else {
		capability.Status = "missing"
		capability.StatusMessage = "Wird bei Bedarf automatisch heruntergeladen"
	}
	digest, _ := build.Digest()
	if job, exists := preferredRuntimeJob(m.installer.Jobs(), digest); exists {
		capability.Status = string(job.Status)
		capability.StatusMessage = job.Message
		if job.DetailMessage != "" {
			capability.StatusMessage = job.DetailMessage
		}
		capability.Progress = job.Progress
		capability.ErrorCode = job.ErrorCode
		if job.Status == engineruntime.InstallFailed || job.Status == engineruntime.InstallCanceled {
			if job.ErrorSummary != "" {
				capability.ProbeError = job.ErrorSummary
			}
		}
		if job.Status == engineruntime.InstallReady {
			capability.Installed = true
			capability.Healthy = true
			capability.Environment = job.InstallPath
			capability.ServerPath = job.ServerPath
		}
	}
	backends := []string{}
	for _, gpu := range snapshot.GPUs {
		if gpu.Backend != "" && gpuUsableForLlama(gpu) {
			backends = append(backends, gpu.Backend)
		}
	}
	capability.GPUBackends = uniqueStrings(backends)
	return snapshot, []engineruntime.RuntimeCapability{capability}
}

// preferredRuntimeJob picks the install job that best describes the current
// state of a build: the one for this exact digest, unless it has already failed
// and another install of the same runtime is ready or still running.
func preferredRuntimeJob(jobs []engineruntime.InstallJobSnapshot, preferredDigest string) (engineruntime.InstallJobSnapshot, bool) {
	var exact *engineruntime.InstallJobSnapshot
	var alternateActive *engineruntime.InstallJobSnapshot
	var alternateReady *engineruntime.InstallJobSnapshot
	for index := range jobs {
		job := jobs[index]
		candidate := job
		if job.BuildDigest == preferredDigest {
			exact = &candidate
			continue
		}
		switch job.Status {
		case engineruntime.InstallReady:
			alternateReady = &candidate
		case engineruntime.InstallQueued, engineruntime.InstallDownloading, engineruntime.InstallVerifying,
			engineruntime.InstallExtracting, engineruntime.InstallProbing:
			alternateActive = &candidate
		}
	}
	if exact != nil && exact.Status != engineruntime.InstallFailed && exact.Status != engineruntime.InstallCanceled {
		return *exact, true
	}
	if alternateReady != nil {
		return *alternateReady, true
	}
	if alternateActive != nil {
		return *alternateActive, true
	}
	if exact != nil {
		return *exact, true
	}
	return engineruntime.InstallJobSnapshot{}, false
}
