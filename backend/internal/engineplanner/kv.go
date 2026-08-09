// Package engineplanner works out whether a model fits the machine: it sizes the
// KV cache, proposes a context length that will hold, and produces the fallbacks
// to try when the first plan does not.
package engineplanner

import (
	"fmt"
	"math"
)

// KV cache sizing follows the byte-per-element model:
//
//	kv_bytes = 2 * tokens * layers * kv_heads * head_dim * sequences * bytes_per_element
//
// The leading 2 covers keys and values, both of which stay resident. The
// byte-per-element factor is not the raw bit width: ggml stores quantised cache
// entries in blocks that carry their own scale, so the block header counts. A
// q4_0 block holds 32 elements in 18 bytes (16 bytes of nibbles plus one fp16
// scale), which is 0.5625 bytes per element rather than the nominal 0.5.
//
// Factors are kept as exact rationals so that sizing stays in integer
// arithmetic and the overflow guards below remain meaningful.
type byteFactor struct {
	numerator   int64
	denominator int64
}

const byteFactorDenominator = 2000

// bytesPerElement maps a cache dtype to its effective on-device size, block
// header included. The values mirror the ggml block layouts in ggml-common.h.
func bytesPerElement(dtype KVCacheDType) (byteFactor, error) {
	switch dtype {
	// 32 elements in 18 bytes: qs[16] + fp16 scale.
	case "", KVCacheQ4, KVCacheIQ4NL:
		return byteFactor{1125, byteFactorDenominator}, nil
	// 32 elements in 20 bytes: qs[16] + fp16 scale + fp16 min.
	case KVCacheQ41:
		return byteFactor{1250, byteFactorDenominator}, nil
	// 32 elements in 22 bytes: qs[16] + qh[4] + fp16 scale.
	case KVCacheQ50:
		return byteFactor{1375, byteFactorDenominator}, nil
	// 32 elements in 24 bytes: qs[16] + qh[4] + fp16 scale + fp16 min.
	case KVCacheQ51:
		return byteFactor{1500, byteFactorDenominator}, nil
	// 32 elements in 34 bytes: qs[32] + fp16 scale.
	case KVCacheQ8:
		return byteFactor{2125, byteFactorDenominator}, nil
	case KVCacheFP16, KVCacheBF16:
		return byteFactor{4000, byteFactorDenominator}, nil
	case KVCacheFP32:
		return byteFactor{8000, byteFactorDenominator}, nil

	// Sub-4-bit K-quants. Upstream llama.cpp accepts neither for
	// --cache-type-k/v; they apply only to a build that reports them, which is
	// why the installer asks the binary rather than assuming.
	//
	// Both factors sit deliberately above the raw block arithmetic (q3_k packs
	// 256 elements into 110 bytes, or 0.4297; q2_k into 84, or 0.3281). Sizing
	// the cache too small is the dangerous direction: it plans a context the
	// device cannot hold and the model dies partway through loading. Rounding up
	// costs a little context and nothing else.
	case KVCacheQ3K:
		return byteFactor{900, byteFactorDenominator}, nil
	case KVCacheQ2K:
		return byteFactor{700, byteFactorDenominator}, nil
	default:
		return byteFactor{}, fmt.Errorf("unsupported KV cache dtype %q", dtype)
	}
}

// KVElementsForContext counts the cache entries a context needs, before the
// dtype has any say. Sliding-window models only keep the window for their local
// layers, so those layers are counted at the window size rather than the full
// context.
func KVElementsForContext(model Model, context, sequences int) (int64, error) {
	if err := validateModel(model); err != nil {
		return 0, err
	}
	if context < 0 {
		return 0, fmt.Errorf("context must not be negative")
	}
	if sequences <= 0 {
		return 0, fmt.Errorf("sequences must be positive")
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
	for _, factor := range []int64{int64(model.HeadDimension), int64(sequences), positions} {
		elements, err = checkedMul(elements, factor)
		if err != nil {
			return 0, fmt.Errorf("KV cache size overflow: %w", err)
		}
	}
	return elements, nil
}

func KVBytesForContext(model Model, context, sequences int, dtype KVCacheDType) (int64, error) {
	factor, err := bytesPerElement(dtype)
	if err != nil {
		return 0, err
	}
	elements, err := KVElementsForContext(model, context, sequences)
	if err != nil {
		return 0, err
	}
	scaled, err := checkedMul(elements, factor.numerator)
	if err != nil {
		return 0, fmt.Errorf("KV cache size overflow: %w", err)
	}
	if scaled > math.MaxInt64-(factor.denominator-1) {
		return 0, fmt.Errorf("KV cache size overflow")
	}
	// Round up: a partially filled block still occupies a whole one.
	return (scaled + factor.denominator - 1) / factor.denominator, nil
}

// MaxTokensForContextBudget inverts KVBytesForContext: given the bytes left
// after weights and runtime overhead, it reports how many tokens of context the
// cache can hold. The result is clamped to the model's own hard limit.
//
// For a model without a sliding window this is the closed form
//
//	max_tokens = budget / (2 * layers * kv_heads * head_dim * sequences * bytes_per_element)
//
// A sliding window makes cache growth non-linear in the context length once the
// window is full, so that case is resolved by search over the forward function.
func MaxTokensForContextBudget(model Model, sequences int, dtype KVCacheDType, budgetBytes int64) (int, error) {
	if err := validateModel(model); err != nil {
		return 0, err
	}
	if sequences <= 0 {
		return 0, fmt.Errorf("sequences must be positive")
	}
	factor, err := bytesPerElement(dtype)
	if err != nil {
		return 0, err
	}
	if budgetBytes <= 0 {
		return 0, nil
	}
	if model.SlidingWindow > 0 {
		return searchMaxTokens(model, sequences, dtype, budgetBytes), nil
	}
	perToken, err := KVElementsForContext(model, 1, sequences)
	if err != nil {
		return 0, err
	}
	if perToken <= 0 {
		return model.ContextLimit, nil
	}
	scaledBudget, err := checkedMul(budgetBytes, factor.denominator)
	if err != nil {
		// A budget this large outruns any context the model admits.
		return model.ContextLimit, nil
	}
	perTokenBytes, err := checkedMul(perToken, factor.numerator)
	if err != nil {
		return 0, fmt.Errorf("KV cache size overflow: %w", err)
	}
	tokens := scaledBudget / perTokenBytes
	if tokens > int64(model.ContextLimit) {
		return model.ContextLimit, nil
	}
	return int(tokens), nil
}

func searchMaxTokens(model Model, sequences int, dtype KVCacheDType, budgetBytes int64) int {
	low, high := 0, model.ContextLimit
	for low < high {
		mid := low + (high-low+1)/2
		bytes, err := KVBytesForContext(model, mid, sequences, dtype)
		if err == nil && bytes <= budgetBytes {
			low = mid
		} else {
			high = mid - 1
		}
	}
	return low
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
