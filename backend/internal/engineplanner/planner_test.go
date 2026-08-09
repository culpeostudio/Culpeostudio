package engineplanner

import (
	"errors"
	"reflect"
	"testing"
)

func TestKVBytesForContextChargesBlockHeaderOverhead(t *testing.T) {
	// 2 (K+V) * 2 layers * 4 KV heads * 64 head dim * 10 tokens = 10240 elements.
	model := Model{ID: "gqa", WeightBytes: 1, ContextLimit: 100, Layers: 2, AttentionHeads: 16, KVHeads: 4, HeadDimension: 64}
	const elements = 10_240

	// q4_0 packs 32 elements into 18 bytes, so 0.5625 bytes each rather than the
	// nominal 0.5: the fp16 block scale is not free.
	q4, err := KVBytesForContext(model, 10, 1, KVCacheQ4)
	if err != nil {
		t.Fatal(err)
	}
	if q4 != elements*9/16 {
		t.Fatalf("q4_0 bytes = %d, want %d", q4, elements*9/16)
	}
	// q8_0 packs 32 elements into 34 bytes: 1.0625 bytes each.
	q8, err := KVBytesForContext(model, 10, 1, KVCacheQ8)
	if err != nil {
		t.Fatal(err)
	}
	if q8 != elements*17/16 {
		t.Fatalf("q8_0 bytes = %d, want %d", q8, elements*17/16)
	}
	fp16, err := KVBytesForContext(model, 10, 1, KVCacheFP16)
	if err != nil {
		t.Fatal(err)
	}
	if fp16 != elements*2 {
		t.Fatalf("fp16 bytes = %d, want %d", fp16, elements*2)
	}
	// q2_k is 0.35 bytes per element including its block header.
	q2, err := KVBytesForContext(model, 10, 1, KVCacheQ2K)
	if err != nil {
		t.Fatal(err)
	}
	if q2 != elements*35/100 {
		t.Fatalf("q2_k bytes = %d, want %d", q2, elements*35/100)
	}

	if _, err := KVBytesForContext(model, 10, 1, KVCacheDType("fp8")); err == nil {
		t.Fatal("fp8 is not a llama.cpp cache type and must be rejected")
	}
}

func TestKVBytesForContextCountsSlidingWindowLayersAtWindowSize(t *testing.T) {
	// One global layer sees all 10 tokens, three sliding layers see only their
	// 4-token window: 1*10 + 3*4 = 22 positions.
	hybrid := Model{
		ID: "hybrid", WeightBytes: 1, ContextLimit: 100, Layers: 4, KVHeads: 2,
		HeadDimension: 8, SlidingWindow: 4, GlobalAttentionLayers: 1,
	}
	bytes, err := KVBytesForContext(hybrid, 10, 2, KVCacheFP16)
	if err != nil {
		t.Fatal(err)
	}
	if bytes != 2_816 {
		t.Fatalf("hybrid bytes = %d, want 2816", bytes)
	}
}

func TestMaxTokensForContextBudgetInvertsKVSizing(t *testing.T) {
	model := Model{ID: "invert", WeightBytes: 1, ContextLimit: 1 << 20, Layers: 32, KVHeads: 8, HeadDimension: 128}
	for _, dtype := range []KVCacheDType{KVCacheQ4, KVCacheQ8, KVCacheFP16, KVCacheQ2K} {
		budget := int64(4 << 30)
		tokens, err := MaxTokensForContextBudget(model, 1, dtype, budget)
		if err != nil {
			t.Fatal(err)
		}
		used, err := KVBytesForContext(model, tokens, 1, dtype)
		if err != nil {
			t.Fatal(err)
		}
		if used > budget {
			t.Fatalf("%s: %d tokens need %d bytes, over the %d budget", dtype, tokens, used, budget)
		}
		next, err := KVBytesForContext(model, tokens+1, 1, dtype)
		if err != nil {
			t.Fatal(err)
		}
		if next <= budget {
			t.Fatalf("%s: %d tokens left room for another token", dtype, tokens)
		}
	}

	// A sliding window makes growth non-linear, so the inverse has to agree with
	// the forward function there too.
	sliding := Model{
		ID: "sliding", WeightBytes: 1, ContextLimit: 1 << 20, Layers: 32, KVHeads: 8,
		HeadDimension: 128, SlidingWindow: 4096, GlobalAttentionLayers: 8,
	}
	tokens, err := MaxTokensForContextBudget(sliding, 1, KVCacheQ4, 1<<30)
	if err != nil {
		t.Fatal(err)
	}
	used, err := KVBytesForContext(sliding, tokens, 1, KVCacheQ4)
	if err != nil {
		t.Fatal(err)
	}
	if used > 1<<30 {
		t.Fatalf("sliding window: %d tokens need %d bytes", tokens, used)
	}
	if tokens < sliding.SlidingWindow {
		t.Fatalf("sliding window: %d tokens should exceed the window", tokens)
	}
}

func TestMaxTokensForContextBudgetClampsToModelLimit(t *testing.T) {
	model := Model{ID: "small", WeightBytes: 1, ContextLimit: 8192, Layers: 1, KVHeads: 1, HeadDimension: 64}
	tokens, err := MaxTokensForContextBudget(model, 1, KVCacheQ4, 1<<40)
	if err != nil {
		t.Fatal(err)
	}
	if tokens != model.ContextLimit {
		t.Fatalf("tokens = %d, want the model limit %d", tokens, model.ContextLimit)
	}
	if tokens, err := MaxTokensForContextBudget(model, 1, KVCacheQ4, 0); err != nil || tokens != 0 {
		t.Fatalf("empty budget = %d, %v; want 0, nil", tokens, err)
	}
}

func TestPlanReportsGPUOnlyAndRAMBackedContextBoundaries(t *testing.T) {
	zero := int64(0)
	runtimeBytes := int64(0)
	requested := 3_000_000
	hardware := Hardware{
		RAMTotalBytes: 16 * GiB,
		GPUs:          []GPU{{ID: "gpu0", TotalBytes: 8 * GiB}},
	}
	model := Model{ID: "large", WeightBytes: 6 * GiB, ContextLimit: 4_000_000, Layers: 1, KVHeads: 1, HeadDimension: 1024}
	plans, err := Allocate(hardware, []Request{{
		InstanceID: "one", Model: model, RequestedContext: &requested,
		RuntimeOverheadBytes: &runtimeBytes,
	}}, ReservePolicy{RAMBytes: &zero, GPUBytes: &zero})
	if err != nil {
		t.Fatal(err)
	}
	plan := plans[0]
	// 2 (K+V) * 1 layer * 1 KV head * 1024 head dim = 2048 elements per token,
	// at q4_0's 0.5625 bytes each.
	const bytesPerToken = 1152
	// 8 GiB card minus 6 GiB of weights leaves 2 GiB for the cache.
	const gpuOnlyMax = int(2 * GiB / bytesPerToken)
	if plan.KVBytesPerTokenAtStart != bytesPerToken {
		t.Fatalf("KV bytes/token = %d, want %d", plan.KVBytesPerTokenAtStart, bytesPerToken)
	}
	if plan.GPUOnlyMaxContext != gpuOnlyMax {
		t.Fatalf("GPU maximum = %d, want %d", plan.GPUOnlyMaxContext, gpuOnlyMax)
	}
	if plan.RAMBackedMaxContext != model.ContextLimit || plan.EffectiveContext != requested {
		t.Fatalf("RAM/effective maxima = %d/%d", plan.RAMBackedMaxContext, plan.EffectiveContext)
	}
	if plan.RAMRequiredFromContext == nil || *plan.RAMRequiredFromContext != gpuOnlyMax+1 {
		t.Fatalf("RAM threshold = %v, want %d", plan.RAMRequiredFromContext, gpuOnlyMax+1)
	}
	if !plan.UsesRAM || plan.Breakdown.Weights.TotalBytes != 6*GiB || plan.Breakdown.KVCache.TotalBytes != int64(requested)*bytesPerToken {
		t.Fatalf("breakdown = %#v", plan.Breakdown)
	}
}

func TestUnifiedMemoryIsNotCountedTwice(t *testing.T) {
	zero := int64(0)
	runtimeBytes := int64(0)
	requested := 3_000_000
	hardware := Hardware{
		RAMTotalBytes: 8 * GiB,
		GPUs:          []GPU{{ID: "unified", TotalBytes: 8 * GiB, UnifiedMemory: true}},
	}
	model := Model{ID: "unified-model", WeightBytes: 6 * GiB, ContextLimit: 4_000_000, Layers: 1, KVHeads: 1, HeadDimension: 1024}
	plans, err := Allocate(hardware, []Request{{InstanceID: "one", Model: model, RequestedContext: &requested, RuntimeOverheadBytes: &runtimeBytes}}, ReservePolicy{RAMBytes: &zero, GPUBytes: &zero})
	if err != nil {
		t.Fatal(err)
	}
	plan := plans[0]
	// Unified memory is RAM, so the whole 2 GiB left after the weights is
	// RAM-backed at q4_0's 1152 bytes per token.
	const bytesPerToken = 1152
	const ramBackedMax = int(2 * GiB / bytesPerToken)
	if plan.GPUOnlyMaxContext != 0 || plan.RAMBackedMaxContext != ramBackedMax || plan.EffectiveContext != ramBackedMax {
		t.Fatalf("unified-memory limits = gpu %d, RAM %d, effective %d", plan.GPUOnlyMaxContext, plan.RAMBackedMaxContext, plan.EffectiveContext)
	}
	wantRAM := 6*GiB + int64(ramBackedMax)*bytesPerToken
	if len(plan.Breakdown.Total.GPUBytes) != 0 || plan.Breakdown.Total.RAMBytes != wantRAM {
		t.Fatalf("unified memory was double-counted: %#v, want %d RAM bytes", plan.Breakdown.Total, wantRAM)
	}
}

func TestForceCPUDoesNotAllocateDedicatedGPU(t *testing.T) {
	zero := int64(0)
	availableRAM := int64(32 * GiB)
	availableGPU := int64(16 * GiB)
	plans, err := Allocate(Hardware{
		RAMTotalBytes: 32 * GiB, RAMAvailableBytes: &availableRAM,
		GPUs: []GPU{{ID: "gpu", TotalBytes: 16 * GiB, AvailableBytes: &availableGPU}},
	}, []Request{{
		InstanceID: "cpu", ForceCPU: true,
		Model: Model{ID: "m", WeightBytes: 1 * GiB, ContextLimit: 4096, Layers: 2, KVHeads: 2, HeadDimension: 64},
	}}, ReservePolicy{RAMBytes: &zero, GPUBytes: &zero})
	if err != nil {
		t.Fatal(err)
	}
	if len(plans) != 1 || len(plans[0].Breakdown.Total.GPUBytes) != 0 || plans[0].Breakdown.Total.RAMBytes == 0 {
		t.Fatalf("force CPU plan allocated GPU: %#v", plans)
	}
}

func TestExplicitGPUWeightSplitPlacesRemainingWeightsInRAM(t *testing.T) {
	zero := int64(0)
	half := int64(2 * GiB)
	plans, err := Allocate(Hardware{
		RAMTotalBytes: 8 * GiB,
		GPUs:          []GPU{{ID: "gpu", TotalBytes: 8 * GiB}},
	}, []Request{{
		InstanceID: "split", WeightGPUBytes: &half,
		Model: Model{ID: "m", WeightBytes: 4 * GiB, ContextLimit: 4096, Layers: 2, KVHeads: 1, HeadDimension: 64},
	}}, ReservePolicy{RAMBytes: &zero, GPUBytes: &zero})
	if err != nil {
		t.Fatal(err)
	}
	weights := plans[0].Breakdown.Weights
	if weights.GPUBytes["gpu"] != 2*GiB || weights.RAMBytes != 2*GiB {
		t.Fatalf("explicit split = %#v", weights)
	}
}

func TestDefaultSafetyReservesUseFloorsAndPercentages(t *testing.T) {
	state, err := buildResourceState(Hardware{
		RAMTotalBytes: 16 * GiB,
		GPUs:          []GPU{{ID: "gpu0", TotalBytes: 8 * GiB}, {ID: "gpu1", TotalBytes: 32 * GiB}},
	}, ReservePolicy{})
	if err != nil {
		t.Fatal(err)
	}
	if state.ramReserve != 4*GiB || state.ramBudget != 12*GiB {
		t.Fatalf("RAM reserve/budget = %d/%d", state.ramReserve, state.ramBudget)
	}
	wantGPU0Reserve := int64(858_993_460)
	if state.gpuReserve["gpu0"] != wantGPU0Reserve || state.gpuBudget["gpu0"] != 8*GiB-wantGPU0Reserve {
		t.Fatalf("8 GiB GPU reserve/budget = %d/%d", state.gpuReserve["gpu0"], state.gpuBudget["gpu0"])
	}
	if state.gpuReserve["gpu1"] != 3_435_973_837 {
		t.Fatalf("32 GiB GPU reserve = %d", state.gpuReserve["gpu1"])
	}
}

func TestWeightedFairAllocationAndPinnedContext(t *testing.T) {
	zero := int64(0)
	runtimeBytes := int64(0)
	requested := 10_000
	model := Model{ID: "tiny", WeightBytes: 1, ContextLimit: requested, Layers: 1, KVHeads: 1, HeadDimension: 1}
	// 2 elements per token at q4_0's 0.5625 bytes: a 256-token step costs 288.
	const stepBytes = 288

	hardware := Hardware{RAMTotalBytes: 2 + 2*stepBytes + 10*stepBytes}
	requests := []Request{
		{InstanceID: "low", Model: model, RequestedContext: &requested, MinimumContext: 256, Priority: PriorityLow, RuntimeOverheadBytes: &runtimeBytes},
		{InstanceID: "high", Model: model, RequestedContext: &requested, MinimumContext: 256, Priority: PriorityHigh, RuntimeOverheadBytes: &runtimeBytes},
	}
	plans, err := Allocate(hardware, requests, ReservePolicy{RAMBytes: &zero})
	if err != nil {
		t.Fatal(err)
	}
	byID := plansByID(plans)
	lowExtra := byID["low"].EffectiveContext - 256
	highExtra := byID["high"].EffectiveContext - 256
	if lowExtra != 2*256 || highExtra != 8*256 {
		t.Fatalf("weighted extras low/high = %d/%d, want %d/%d", lowExtra, highExtra, 2*256, 8*256)
	}

	pinnedRequest := 512
	pinnedHardware := Hardware{RAMTotalBytes: 1 + 4*stepBytes + stepBytes}
	pinnedPlans, err := Allocate(pinnedHardware, []Request{{
		InstanceID: "pinned", Model: model, RequestedContext: &pinnedRequest,
		CurrentContext: 1024, Pinned: true, RuntimeOverheadBytes: &runtimeBytes,
	}}, ReservePolicy{RAMBytes: &zero})
	if err != nil {
		t.Fatal(err)
	}
	if pinnedPlans[0].EffectiveContext != 1024 || pinnedPlans[0].RestartRequired {
		t.Fatalf("pinned plan changed: %#v", pinnedPlans[0])
	}
}

func TestMinimumConflictReturnsNoPartialPlan(t *testing.T) {
	zero := int64(0)
	runtimeBytes := int64(0)
	model := Model{ID: "does-not-fit", WeightBytes: 1000, ContextLimit: 4096, Layers: 1, KVHeads: 1, HeadDimension: 1}
	plans, err := Allocate(Hardware{RAMTotalBytes: 999}, []Request{{InstanceID: "one", Model: model, RuntimeOverheadBytes: &runtimeBytes}}, ReservePolicy{RAMBytes: &zero})
	if err == nil || plans != nil {
		t.Fatalf("Allocate() = %#v, %v; want nil conflict", plans, err)
	}
	var conflict *ConflictError
	if !errors.As(err, &conflict) || conflict.InstanceID != "one" {
		t.Fatalf("error = %#v", err)
	}
}

func TestMultiGPUSelectionAndDeterministicInputOrder(t *testing.T) {
	zero := int64(0)
	runtimeBytes := int64(0)
	requested := 1024
	model := Model{ID: "selected", WeightBytes: 1024, ContextLimit: requested, Layers: 1, KVHeads: 1, HeadDimension: 1}
	hardware := Hardware{RAMTotalBytes: 4096, GPUs: []GPU{{ID: "gpu-a", TotalBytes: 4096}, {ID: "gpu-b", TotalBytes: 4096}}}
	requests := []Request{
		{InstanceID: "b", Model: model, RequestedContext: &requested, SelectedGPUIDs: []string{"gpu-b"}, RuntimeOverheadBytes: &runtimeBytes},
		{InstanceID: "a", Model: model, RequestedContext: &requested, SelectedGPUIDs: []string{"gpu-a"}, RuntimeOverheadBytes: &runtimeBytes},
	}
	policy := ReservePolicy{RAMBytes: &zero, GPUBytes: &zero}
	first, err := Allocate(hardware, requests, policy)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Allocate(hardware, []Request{requests[1], requests[0]}, policy)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, second) {
		t.Fatalf("input order changed plan:\n%#v\n%#v", first, second)
	}
	byID := plansByID(first)
	if byID["a"].Breakdown.Total.GPUBytes["gpu-a"] == 0 || byID["a"].Breakdown.Total.GPUBytes["gpu-b"] != 0 {
		t.Fatalf("instance a placement = %#v", byID["a"].Breakdown.Total)
	}
	if byID["b"].Breakdown.Total.GPUBytes["gpu-b"] == 0 || byID["b"].Breakdown.Total.GPUBytes["gpu-a"] != 0 {
		t.Fatalf("instance b placement = %#v", byID["b"].Breakdown.Total)
	}
}

func plansByID(plans []ContextPlan) map[string]ContextPlan {
	result := make(map[string]ContextPlan, len(plans))
	for _, plan := range plans {
		result[plan.InstanceID] = plan
	}
	return result
}
