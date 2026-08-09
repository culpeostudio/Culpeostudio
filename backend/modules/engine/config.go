package engine

import (
	"strings"

	"github.com/culpeohq/backend/internal/engineplanner"
	"github.com/culpeohq/backend/internal/engineruntime"
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

// kvCacheForQuantization picks the cache type that suits a model's own weight
// quantisation. Sizing the cache far more precisely than the weights spends
// memory on precision the model no longer carries; sizing it far below them
// costs quality the weights still have. Matching the two is the useful default.
//
// The returned type is a wish. The adapter resolves it against what the
// installed build actually accepts and walks up the ladder if it is missing, so
// naming q2_k here is safe even on a build without it.
func kvCacheForQuantization(quantization string) engineplanner.KVCacheDType {
	name := strings.ToUpper(strings.TrimSpace(quantization))
	switch {
	case name == "":
		// Nothing known about the weights: q4_0 is the smallest type every
		// upstream build supports, and the historical default.
		return engineplanner.KVCacheQ4
	case strings.HasPrefix(name, "F32"), strings.HasPrefix(name, "F16"), strings.HasPrefix(name, "BF16"):
		return engineplanner.KVCacheFP16
	case strings.HasPrefix(name, "Q8"), strings.HasPrefix(name, "Q6"), strings.HasPrefix(name, "Q5"):
		return engineplanner.KVCacheQ8
	case strings.HasPrefix(name, "Q4"), strings.HasPrefix(name, "IQ4"), strings.HasPrefix(name, "MXFP4"):
		return engineplanner.KVCacheQ4
	case strings.HasPrefix(name, "Q3"), strings.HasPrefix(name, "IQ3"):
		return engineplanner.KVCacheQ3K
	// Two-bit and below. Only a build that reports these can use them; the
	// fallback ladder covers the rest.
	case strings.HasPrefix(name, "Q2"), strings.HasPrefix(name, "IQ2"),
		strings.HasPrefix(name, "IQ1"), strings.HasPrefix(name, "TQ"):
		return engineplanner.KVCacheQ2K
	default:
		return engineplanner.KVCacheQ4
	}
}

// kvCacheSizeRank orders cache types from smallest to largest on device. It
// mirrors engineruntime's fallback ladder and exists so the compact-cache
// policy can cap a derived type without duplicating the byte factors.
func kvCacheSizeRank(dtype engineplanner.KVCacheDType) int {
	order := []engineplanner.KVCacheDType{
		engineplanner.KVCacheQ2K, engineplanner.KVCacheQ3K, engineplanner.KVCacheQ4,
		engineplanner.KVCacheQ41, engineplanner.KVCacheIQ4NL, engineplanner.KVCacheQ50,
		engineplanner.KVCacheQ51, engineplanner.KVCacheQ8, engineplanner.KVCacheFP16,
		engineplanner.KVCacheBF16, engineplanner.KVCacheFP32,
	}
	for rank, candidate := range order {
		if candidate == dtype {
			return rank
		}
	}
	return len(order)
}

// plannerKVType decides the cache type the planner sizes against. An explicit
// choice always wins; otherwise the model's quantisation decides, bounded by
// the configured policy.
func plannerKVType(config EngineConfig, quantization string) engineplanner.KVCacheDType {
	value, explicit := stringOption(config.RuntimeOptions, "kv_cache_dtype")
	switch strings.ToLower(value) {
	case "native", "f16", "fp16", "offloaded":
		return engineplanner.KVCacheFP16
	case "bf16":
		return engineplanner.KVCacheBF16
	case "f32", "fp32":
		return engineplanner.KVCacheFP32
	case "q8", "q8_0", "fp8":
		// llama.cpp has no fp8 cache; q8_0 is what such a config resolves to.
		return engineplanner.KVCacheQ8
	case "q4_1":
		return engineplanner.KVCacheQ41
	case "iq4_nl":
		return engineplanner.KVCacheIQ4NL
	case "q5_0":
		return engineplanner.KVCacheQ50
	case "q5_1":
		return engineplanner.KVCacheQ51
	case "q3_k":
		return engineplanner.KVCacheQ3K
	case "q2_k":
		return engineplanner.KVCacheQ2K
	case "q4", "q4_0", "quanto_4bit", "turboquant_4bit_nc":
		return engineplanner.KVCacheQ4
	default:
		if explicit && value != "" && value != "auto" {
			// An unrecognised explicit value: size conservatively rather than
			// assume it is small.
			return engineplanner.KVCacheFP16
		}
		// "native" keeps the full-precision cache whatever the weights are.
		if config.KVCachePolicy == "native" {
			return engineplanner.KVCacheFP16
		}
		derived := kvCacheForQuantization(quantization)
		// The compact policy is a ceiling, not a target: a two-bit model may go
		// below q4_0, an f16 model is still held at it.
		if kvCacheSizeRank(derived) > kvCacheSizeRank(engineplanner.KVCacheQ4) {
			return engineplanner.KVCacheQ4
		}
		return derived
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
