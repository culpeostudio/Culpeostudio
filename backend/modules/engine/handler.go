package engine

import (
	"fmt"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func effectiveReserveBytes(override *int64, total, percent, floor int64) int64 {
	if override != nil {
		return *override
	}
	percentage := total / 100 * percent
	if remainder := total % 100; remainder > 0 {
		percentage += (remainder*percent + 99) / 100
	}
	if percentage < floor {
		return floor
	}
	return percentage
}

func (m *EngineModule) configForFix(instance *EngineInstance, fix string) (EngineConfig, error) {
	config := cloneEngineConfig(instance.RequestedConfig)
	switch fix {
	case engineruntime.FixReduceContext:

		current := 0
		if instance.Plan != nil {
			current = instance.Plan.EffectiveContextTokens
		}
		if current <= 0 && instance.EffectiveConfig.ContextTokens != nil {
			current = *instance.EffectiveConfig.ContextTokens
		}
		if current <= 0 {
			current = 8192
		}
		reduced := current / 2
		if reduced < 2048 {
			reduced = 2048
		}
		config.ContextMode = "fixed"
		config.ContextTokens = &reduced
		return config, nil
	case engineruntime.FixRetryOnCPU:
		if config.RuntimeOptions == nil {
			config.RuntimeOptions = map[string]interface{}{}
		}
		config.RuntimeOptions["offload"] = "cpu"
		config.RuntimeOptions["gpu_layers"] = 0
		config.RuntimeOptions["allow_ram_offload"] = true
		return config, nil
	case fixRetryWithRAM:
		if config.RuntimeOptions == nil {
			config.RuntimeOptions = map[string]interface{}{}
		}
		config.RuntimeOptions["allow_ram_offload"] = true
		return config, nil
	default:
		return EngineConfig{}, fmt.Errorf("Fix %q wird nicht unterstuetzt; unterstuetzt sind reduce_context, retry_on_cpu und retry_with_ram", fix)
	}
}
