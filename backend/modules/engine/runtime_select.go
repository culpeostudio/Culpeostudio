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

func (m *EngineModule) runtimeRecipe(kind engineruntime.RuntimeKind, snapshot hardware.Snapshot) (engineruntime.Recipe, error) {
	switch kind {
	case engineruntime.RuntimeLlamaCPP:
		environment := map[string]string{}
		for _, gpu := range snapshot.GPUs {
			switch strings.ToLower(gpu.Backend) {
			case "cuda":
				environment["CMAKE_ARGS"] = "-DGGML_CUDA=on"
			case "metal":
				environment["CMAKE_ARGS"] = "-DGGML_METAL=on"
			case "rocm":
				environment["CMAKE_ARGS"] = "-DGGML_HIPBLAS=on"
			case "vulkan":
				environment["CMAKE_ARGS"] = "-DGGML_VULKAN=on"
			}
			if environment["CMAKE_ARGS"] != "" {
				break
			}
		}
		recipe := engineruntime.DefaultLlamaCPPRecipe(environment)
		if environment["CMAKE_ARGS"] != "" {
			// pip's wheel cache is keyed by package/platform, not by CMAKE_ARGS.
			// A CPU wheel built earlier can otherwise be reused for a Vulkan/CUDA
			// recipe and only fail at the GPU-offload smoke test. Accelerator
			// recipes must therefore perform a fresh native build.
			recipe.Environment["FORCE_CMAKE"] = "1"
			recipe.PipArgs = append(recipe.PipArgs,
				"--no-cache-dir",
				"--no-binary=llama-cpp-python",
			)
		}
		probe := "import llama_cpp; from llama_cpp import llama_cpp as low; print(llama_cpp.__version__)"
		if environment["CMAKE_ARGS"] != "" {
			probe += "; assert bool(low.llama_supports_gpu_offload()), 'GPU offload smoke test failed'"
		}
		recipe.SmokeTestArgs = []string{"-c", probe}
		return recipe, nil
	case engineruntime.RuntimeVLLM:
		recipe := engineruntime.DefaultVLLMRecipe()
		recipe.SmokeTestArgs = []string{"-c", "from vllm.platforms import current_platform; assert current_platform is not None; print(current_platform.device_name)"}
		return recipe, nil
	case engineruntime.RuntimeTransformers:
		torchPackage := strings.TrimSpace(os.Getenv("ENGINE_TORCH_PACKAGE"))
		if torchPackage == "" {
			torchPackage = "torch==2.13.0"
		}
		pipArgs := []string{}
		for _, gpu := range snapshot.GPUs {
			if strings.EqualFold(gpu.Backend, "rocm") {
				index := strings.TrimSpace(os.Getenv("ENGINE_TORCH_ROCM_INDEX_URL"))
				if index == "" {
					index = "https://download.pytorch.org/whl/rocm7.1"
				}
				pipArgs = []string{"--extra-index-url", index}
				break
			}
			if strings.EqualFold(gpu.Backend, "cuda") {
				if index := strings.TrimSpace(os.Getenv("ENGINE_TORCH_CUDA_INDEX_URL")); index != "" {
					pipArgs = []string{"--extra-index-url", index}
				}
				break
			}
		}
		recipe, err := engineruntime.DefaultTransformersRecipe(torchPackage, pipArgs)
		if err == nil {
			recipe.SmokeTestArgs = []string{"-c", "import torch; value=torch.ones(1)+torch.ones(1); assert float(value[0]) == 2.0; print(torch.__version__)"}
		}
		return recipe, err
	default:
		return engineruntime.Recipe{}, fmt.Errorf("unbekannte Runtime %q", kind)
	}
}

func (m *EngineModule) selectRuntime(record modelcatalog.ModelRecord, config EngineConfig, snapshot hardware.Snapshot) (engineruntime.RuntimeKind, []engineruntime.Fallback, error) {
	requested := strings.ToLower(strings.TrimSpace(config.Runtime))
	allowFallback := config.AllowFallback == nil || *config.AllowFallback
	automatic := func() engineruntime.RuntimeKind {
		if record.Format == modelcatalog.FormatGGUF {
			return engineruntime.RuntimeLlamaCPP
		}
		if vllmCompatible(snapshot) {
			return engineruntime.RuntimeVLLM
		}
		return engineruntime.RuntimeTransformers
	}
	if requested == "" || requested == "auto" {
		return automatic(), nil, nil
	}
	kind := engineruntime.RuntimeKind(requested)
	validFormat := (record.Format == modelcatalog.FormatGGUF && kind == engineruntime.RuntimeLlamaCPP) ||
		(record.Format == modelcatalog.FormatSafeTensors && (kind == engineruntime.RuntimeVLLM || kind == engineruntime.RuntimeTransformers))
	compatible := kind != engineruntime.RuntimeVLLM || vllmCompatible(snapshot)
	if validFormat && compatible {
		return kind, nil, nil
	}
	if !allowFallback {
		return "", nil, fmt.Errorf("Runtime %s ist fuer Format/Hardware nicht kompatibel und Fallback ist deaktiviert", requested)
	}
	fallback := automatic()
	return fallback, []engineruntime.Fallback{{Setting: "runtime", From: requested, To: string(fallback), Reason: "Runtime ist fuer dieses Modell, Betriebssystem oder Compute-Backend nicht bestaetigt"}}, nil
}

func vllmCompatible(snapshot hardware.Snapshot) bool {
	if snapshot.OS != "linux" {
		return false
	}
	for _, gpu := range snapshot.GPUs {
		if !gpu.SharedMemory && (strings.EqualFold(gpu.Backend, "cuda") || strings.EqualFold(gpu.Backend, "rocm")) {
			return true
		}
	}
	return false
}

func (m *EngineModule) runtimeCapabilities(ctx context.Context) (hardware.Snapshot, []engineruntime.RuntimeCapability) {
	snapshot, _ := m.liveHardware(ctx)
	result := []engineruntime.RuntimeCapability{}
	for _, kind := range []engineruntime.RuntimeKind{engineruntime.RuntimeLlamaCPP, engineruntime.RuntimeVLLM, engineruntime.RuntimeTransformers} {
		capability := engineruntime.DefaultCapability(kind)
		runtimeSnapshot := snapshot
		buildWarnings := []string{}
		if kind == engineruntime.RuntimeLlamaCPP {
			runtimeSnapshot, buildWarnings = usableLlamaBuildSnapshot(snapshot)
		}
		recipe, err := m.runtimeRecipe(kind, runtimeSnapshot)
		if err != nil {
			capability.ProbeError = err.Error()
			result = append(result, capability)
			continue
		}
		if m.installer == nil {
			capability.ProbeError = "Python 3 fehlt; automatische Runtime-Installation ist nicht verfuegbar"
		} else {
			capability = m.installer.Capability(recipe, capability)
		}
		if capability.Installed && capability.Healthy {
			capability.Status = "ready"
			capability.StatusMessage = "Runtime ist installiert und einsatzbereit"
			capability.Progress = 1
		} else {
			capability.Status = "missing"
			capability.StatusMessage = "Wird bei Bedarf automatisch vorbereitet"
		}
		if m.installer != nil {
			jobs := m.installer.Jobs()
			digest, _ := recipe.Digest()
			if job, exists := preferredRuntimeJob(jobs, kind, digest); exists {
				capability.Status = string(job.Status)
				capability.StatusMessage = job.Message
				if job.DetailMessage != "" {
					capability.StatusMessage = job.DetailMessage
				}
				switch job.Status {
				case engineruntime.InstallQueued:
					capability.Progress = 0.05
				case engineruntime.InstallCreating:
					capability.Progress = 0.15
				case engineruntime.InstallPackages:
					// Live pip progress instead of one static phase value.
					capability.Progress = job.Progress
					if capability.Progress <= 0 {
						capability.Progress = 0.15
					}
				case engineruntime.InstallProbing:
					capability.Progress = 0.9
				case engineruntime.InstallReady:
					capability.Progress = 1
				case engineruntime.InstallFailed, engineruntime.InstallCanceled:
					capability.Progress = 1
					if job.ErrorSummary != "" {
						capability.ProbeError = job.ErrorSummary
					}
				}
				capability.ErrorCode = job.ErrorCode
				if job.Status == engineruntime.InstallReady {
					capability.Installed = true
					capability.Healthy = true
					capability.Environment = job.EnvironmentPath
				}
			}
		}
		if kind == engineruntime.RuntimeVLLM && !vllmCompatible(snapshot) {
			capability.Healthy = false
			capability.Status = "incompatible"
			capability.StatusMessage = "Auf dieser Hardware nicht erforderlich"
			capability.ProbeError = "vLLM benoetigt auf dieser Plattform eine bestaetigte CUDA- oder ROCm-GPU-Runtime"
			capability.Progress = 0
		}
		if len(buildWarnings) > 0 {
			capability.StatusMessage = strings.TrimSpace(capability.StatusMessage + ". " + strings.Join(buildWarnings, "; "))
		}
		backends := []string{}
		for _, gpu := range runtimeSnapshot.GPUs {
			if gpu.Backend != "" && runtimeSupportsBackend(kind, gpu.Backend) {
				backends = append(backends, gpu.Backend)
			}
		}
		capability.GPUBackends = uniqueStrings(backends)
		result = append(result, capability)
	}
	return snapshot, result
}

func preferredRuntimeJob(jobs []engineruntime.InstallJobSnapshot, kind engineruntime.RuntimeKind, preferredDigest string) (engineruntime.InstallJobSnapshot, bool) {
	var exact *engineruntime.InstallJobSnapshot
	var alternateActive *engineruntime.InstallJobSnapshot
	var alternateReady *engineruntime.InstallJobSnapshot
	for index := range jobs {
		job := jobs[index]
		if job.Runtime != kind {
			continue
		}
		copy := job
		if job.RecipeDigest == preferredDigest {
			exact = &copy
			continue
		}
		switch job.Status {
		case engineruntime.InstallReady:
			alternateReady = &copy
		case engineruntime.InstallQueued, engineruntime.InstallCreating, engineruntime.InstallPackages, engineruntime.InstallProbing:
			alternateActive = &copy
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

func runtimeSupportsBackend(kind engineruntime.RuntimeKind, backend string) bool {
	backend = strings.ToLower(strings.TrimSpace(backend))
	switch kind {
	case engineruntime.RuntimeLlamaCPP:
		return backend == "cuda" || backend == "rocm" || backend == "vulkan" || backend == "metal"
	case engineruntime.RuntimeVLLM:
		return backend == "cuda" || backend == "rocm"
	case engineruntime.RuntimeTransformers:
		return backend == "cuda" || backend == "rocm" || backend == "metal"
	default:
		return false
	}
}
