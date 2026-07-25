package engine

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
)

func normalizeConfig(config EngineConfig) EngineConfig {
	defaults := defaultEngineConfig()
	if strings.TrimSpace(config.Runtime) == "" {
		config.Runtime = defaults.Runtime
	}
	if strings.TrimSpace(config.ContextMode) == "" {
		config.ContextMode = defaults.ContextMode
	}
	if config.MaxSequences <= 0 {
		config.MaxSequences = 1
	}
	if strings.TrimSpace(config.Priority) == "" {
		config.Priority = defaults.Priority
	}
	if strings.TrimSpace(config.KVCachePolicy) == "" {
		config.KVCachePolicy = defaults.KVCachePolicy
	}
	if config.AllowFallback == nil {
		config.AllowFallback = defaults.AllowFallback
	}
	if config.RuntimeOptions == nil {
		config.RuntimeOptions = map[string]interface{}{}
	}
	if config.GenerationDefaults == nil {
		config.GenerationDefaults = map[string]interface{}{}
	}
	return config
}

func plannerKVType(config EngineConfig) engineplanner.KVCacheDType {
	value, explicit := stringOption(config.RuntimeOptions, "kv_cache_dtype")
	switch strings.ToLower(value) {
	case "fp8":
		return engineplanner.KVCacheFP8
	case "native", "f16", "fp16", "offloaded":
		return engineplanner.KVCacheFP16
	case "bf16":
		return engineplanner.KVCacheBF16
	case "fp32":
		return engineplanner.KVCacheFP32
	case "q4", "q4_0", "quanto_4bit", "turboquant_4bit_nc":
		return engineplanner.KVCacheQ4
	default:
		if !explicit || value == "" || value == "auto" {
			if config.KVCachePolicy == "prefer_4bit" {
				return engineplanner.KVCacheQ4
			}
			return engineplanner.KVCacheFP16
		}
		return engineplanner.KVCacheQ4
	}
}

func plannerPriority(value string) engineplanner.Priority {
	switch strings.ToLower(value) {
	case "low":
		return engineplanner.PriorityLow
	case "high":
		return engineplanner.PriorityHigh
	default:
		return engineplanner.PriorityNormal
	}
}

func resourceHoldingState(state engineruntime.InstanceState) bool {
	switch state {
	case engineruntime.StateInstalling, engineruntime.StateQueued, engineruntime.StateStarting, engineruntime.StateReady, engineruntime.StateDraining, engineruntime.StateRestarting:
		return true
	default:
		return false
	}
}

func findBootstrapPython() (string, error) {
	if configured := strings.TrimSpace(os.Getenv("ENGINE_BOOTSTRAP_PYTHON")); configured != "" {
		return configured, nil
	}
	for _, name := range []string{"python3", "python"} {
		if path, err := exec.LookPath(name); err == nil {
			return path, nil
		}
	}
	return "", fmt.Errorf("Python 3 wurde fuer Runtime-Installation nicht gefunden")
}

func runtimeEnvironmentPython(environment string) string {
	if runtime.GOOS == "windows" {
		return filepath.Join(environment, "Scripts", "python.exe")
	}
	return filepath.Join(environment, "bin", "python")
}
