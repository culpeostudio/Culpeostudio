package engineplanner

import (
	"fmt"
	"math"
)

// KVBytesForContext returns the exact packed byte count for K and V across all
// cached layers and sequences. Q4 uses four bits per scalar; the final partial
// byte, if any, is rounded up exactly once.
func KVBytesForContext(model Model, context, sequences int, dtype KVCacheDType) (int64, error) {
	if err := validateModel(model); err != nil {
		return 0, err
	}
	if context < 0 {
		return 0, fmt.Errorf("context must not be negative")
	}
	if sequences <= 0 {
		return 0, fmt.Errorf("sequences must be positive")
	}
	bits, err := bitsPerElement(dtype)
	if err != nil {
		return 0, err
	}
	globalLayers := model.Layers
	slidingLayers := 0
	if model.SlidingWindow > 0 {
		globalLayers = model.GlobalAttentionLayers
		if globalLayers < 0 || globalLayers > model.Layers {
			return 0, fmt.Errorf("global attention layers must be between 0 and %d", model.Layers)
		}
		slidingLayers = model.Layers - globalLayers
	}
	slidingContext := context
	if model.SlidingWindow > 0 && slidingContext > model.SlidingWindow {
		slidingContext = model.SlidingWindow
	}

	globalPositions, err := checkedMul(int64(globalLayers), int64(context))
	if err != nil {
		return 0, err
	}
	slidingPositions, err := checkedMul(int64(slidingLayers), int64(slidingContext))
	if err != nil {
		return 0, err
	}
	positions, err := checkedAdd(globalPositions, slidingPositions)
	if err != nil {
		return 0, err
	}
	elements, err := checkedMul(2, int64(model.KVHeads))
	if err != nil {
		return 0, err
	}
	for _, factor := range []int64{int64(model.HeadDimension), int64(sequences), positions, int64(bits)} {
		elements, err = checkedMul(elements, factor)
		if err != nil {
			return 0, fmt.Errorf("KV cache size overflow: %w", err)
		}
	}
	// elements currently means bits.
	if elements > math.MaxInt64-7 {
		return 0, fmt.Errorf("KV cache size overflow")
	}
	return (elements + 7) / 8, nil
}

func bitsPerElement(dtype KVCacheDType) (int, error) {
	switch dtype {
	case "", KVCacheQ4:
		return 4, nil
	case KVCacheFP8:
		return 8, nil
	case KVCacheFP16, KVCacheBF16:
		return 16, nil
	case KVCacheFP32:
		return 32, nil
	default:
		return 0, fmt.Errorf("unsupported KV cache dtype %q", dtype)
	}
}

func validateModel(model Model) error {
	if model.ID == "" {
		return fmt.Errorf("model ID is empty")
	}
	if model.WeightBytes <= 0 {
		return fmt.Errorf("model %s has no usable weight size", model.ID)
	}
	if model.ContextLimit <= 0 || model.Layers <= 0 || model.KVHeads <= 0 || model.HeadDimension <= 0 {
		return fmt.Errorf("model %s lacks context/KV architecture metadata", model.ID)
	}
	if model.SlidingWindow < 0 {
		return fmt.Errorf("model %s has a negative sliding window", model.ID)
	}
	return nil
}

func checkedMul(a, b int64) (int64, error) {
	if a < 0 || b < 0 {
		return 0, fmt.Errorf("negative size")
	}
	if a == 0 || b == 0 {
		return 0, nil
	}
	if a > math.MaxInt64/b {
		return 0, fmt.Errorf("integer overflow")
	}
	return a * b, nil
}

func checkedAdd(a, b int64) (int64, error) {
	if a < 0 || b < 0 || a > math.MaxInt64-b {
		return 0, fmt.Errorf("integer overflow")
	}
	return a + b, nil
}
