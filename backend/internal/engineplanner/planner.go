package engineplanner

import (
	"fmt"
	"math"
	"sort"
)

const (
	DefaultMinimumContext       = 4096
	DefaultContextStepSize      = 256
	DefaultRuntimeOverheadBytes = 256 * MiB
)

// Planner can be reused with an immutable hardware snapshot and reserve
// policy. Plan itself has no side effects and is safe for concurrent calls.
type Planner struct {
	hardware Hardware
	policy   ReservePolicy
}

func New(hardware Hardware, policy ReservePolicy) *Planner {
	return &Planner{hardware: hardware, policy: policy}
}

// Allocate is a convenience wrapper around New(hardware, policy).Plan.
func Allocate(hardware Hardware, requests []Request, policy ReservePolicy) ([]ContextPlan, error) {
	return New(hardware, policy).Plan(requests)
}

type resourceState struct {
	ramBudget    int64
	ramRemaining int64
	ramReserve   int64
	gpuBudget    map[string]int64
	gpuRemaining map[string]int64
	gpuReserve   map[string]int64
	gpuUnified   map[string]bool
	knownGPU     map[string]struct{}
}

type preparedRequest struct {
	request      Request
	eligibleGPUs []string
	allowRAM     bool
	sequences    int
	dtype        KVCacheDType
	weight       int
	runtimeBytes int64
	minimum      int
	maximum      int
	current      int
	extra        MemoryAllocation
	plan         ContextPlan
}

// Plan first reserves every minimum (pinned current plans first), then grants
// 256-token chunks using weighted dominant-resource fairness. A minimum
// conflict returns no partial plans.
func (p *Planner) Plan(requests []Request) ([]ContextPlan, error) {
	state, err := buildResourceState(p.hardware, p.policy)
	if err != nil {
		return nil, err
	}
	if len(requests) == 0 {
		return []ContextPlan{}, nil
	}
	prepared := make([]*preparedRequest, 0, len(requests))
	seenIDs := make(map[string]struct{}, len(requests))
	for _, request := range requests {
		if request.InstanceID == "" {
			return nil, fmt.Errorf("engine instance ID is empty")
		}
		if _, duplicate := seenIDs[request.InstanceID]; duplicate {
			return nil, fmt.Errorf("duplicate engine instance ID %q", request.InstanceID)
		}
		seenIDs[request.InstanceID] = struct{}{}
		item, err := prepareRequest(request, state)
		if err != nil {
			return nil, err
		}
		prepared = append(prepared, item)
	}

	// The ordering protects fixed pinned plans, GPU-only requests and narrow
	// device selections before more flexible requests consume shared devices.
	sort.Slice(prepared, func(i, j int) bool {
		a, b := prepared[i], prepared[j]
		aPinned := a.request.Pinned && a.request.CurrentContext > 0
		bPinned := b.request.Pinned && b.request.CurrentContext > 0
		if aPinned != bPinned {
			return aPinned
		}
		if a.allowRAM != b.allowRAM {
			return !a.allowRAM
		}
		if len(a.eligibleGPUs) != len(b.eligibleGPUs) {
			return len(a.eligibleGPUs) < len(b.eligibleGPUs)
		}
		return a.request.InstanceID < b.request.InstanceID
	})

	for _, item := range prepared {
		weights, ok := allocateWeights(state, item)
		if !ok {
			return nil, minimumConflict(item, state, item.request.Model.WeightBytes, "model weights do not fit after safety reserves")
		}
		weights.Confidence = confidenceOr(item.request.Model.WeightConfidence, ConfidenceMeasured)
		item.plan.Breakdown.Weights = weights

		runtime, ok := state.allocate(item.runtimeBytes, item.eligibleGPUs, item.allowRAM)
		if !ok {
			return nil, minimumConflict(item, state, item.runtimeBytes, "runtime overhead does not fit after model weights")
		}
		runtime.Confidence = ConfidenceEstimated
		item.plan.Breakdown.Runtime = runtime

		minimumKV, err := KVBytesForContext(item.request.Model, item.minimum, item.sequences, item.dtype)
		if err != nil {
			return nil, err
		}
		kv, ok := state.allocate(minimumKV, item.eligibleGPUs, item.allowRAM)
		if !ok {
			return nil, minimumConflict(item, state, minimumKV, fmt.Sprintf("minimum context %d does not fit", item.minimum))
		}
		kv.Confidence = ConfidenceEstimated
		item.plan.Breakdown.KVCache = kv
		item.current = item.minimum
		item.plan.EffectiveContext = item.minimum
	}

	step := DefaultContextStepSize
	for {
		var selected *preparedRequest
		var selectedAllocation MemoryAllocation
		selectedScore := math.Inf(1)
		for _, item := range prepared {
			if item.current >= item.maximum {
				continue
			}
			next := item.current + step
			if next > item.maximum {
				next = item.maximum
			}
			currentBytes, err := KVBytesForContext(item.request.Model, item.current, item.sequences, item.dtype)
			if err != nil {
				return nil, err
			}
			nextBytes, err := KVBytesForContext(item.request.Model, next, item.sequences, item.dtype)
			if err != nil {
				return nil, err
			}
			delta := nextBytes - currentBytes
			allocation, ok := state.preview(delta, item.eligibleGPUs, item.allowRAM)
			if !ok {
				continue
			}
			score := dominantShare(item.extra, state) / float64(item.weight)
			if selected == nil || score < selectedScore || (score == selectedScore && item.request.InstanceID < selected.request.InstanceID) {
				selected = item
				selectedAllocation = allocation
				selectedScore = score
			}
		}
		if selected == nil {
			break
		}
		next := selected.current + step
		if next > selected.maximum {
			next = selected.maximum
		}
		state.consume(selectedAllocation)
		addAllocation(&selected.extra, selectedAllocation)
		addAllocation(&selected.plan.Breakdown.KVCache, selectedAllocation)
		selected.current = next
		selected.plan.EffectiveContext = next
	}

	plans := make([]ContextPlan, 0, len(prepared))
	for _, item := range prepared {
		item.plan.Breakdown.Reserve = reserveFor(item, state)
		item.plan.Breakdown.Total = sumActualAllocations(item.plan.Breakdown)
		item.plan.UsesRAM = item.plan.Breakdown.Total.RAMBytes > 0
		item.plan.RestartRequired = item.request.CurrentContext > 0 && item.request.CurrentContext != item.plan.EffectiveContext
		plans = append(plans, item.plan)
	}
	sort.Slice(plans, func(i, j int) bool { return plans[i].InstanceID < plans[j].InstanceID })
	return plans, nil
}

func allocateWeights(state *resourceState, item *preparedRequest) (MemoryAllocation, bool) {
	if item.request.WeightGPUBytes == nil {
		return state.allocate(item.request.Model.WeightBytes, item.eligibleGPUs, item.allowRAM)
	}
	gpuBytes := *item.request.WeightGPUBytes
	if gpuBytes < 0 || gpuBytes > item.request.Model.WeightBytes {
		return MemoryAllocation{}, false
	}
	result := MemoryAllocation{GPUBytes: map[string]int64{}, Confidence: confidenceOr(item.request.Model.WeightConfidence, ConfidenceMeasured)}
	if gpuBytes > 0 {
		allocation, ok := state.allocate(gpuBytes, item.eligibleGPUs, false)
		if !ok {
			return MemoryAllocation{}, false
		}
		addAllocation(&result, allocation)
	}
	ramBytes := item.request.Model.WeightBytes - gpuBytes
	if ramBytes > 0 {
		allocation, ok := state.allocate(ramBytes, nil, item.allowRAM)
		if !ok {
			return MemoryAllocation{}, false
		}
		addAllocation(&result, allocation)
	}
	result.TotalBytes = item.request.Model.WeightBytes
	return result, true
}

func prepareRequest(request Request, state *resourceState) (*preparedRequest, error) {
	if err := validateModel(request.Model); err != nil {
		return nil, err
	}
	weight := PriorityWeight(request.Priority)
	if weight == 0 {
		return nil, fmt.Errorf("instance %s has invalid priority %q", request.InstanceID, request.Priority)
	}
	priority := request.Priority
	if priority == "" {
		priority = PriorityNormal
	}
	dtype := request.KVCacheDType
	if dtype == "" {
		dtype = KVCacheQ4
	}
	if _, err := bitsPerElement(dtype); err != nil {
		return nil, fmt.Errorf("instance %s: %w", request.InstanceID, err)
	}
	sequences := request.MaxSequences
	if sequences <= 0 {
		sequences = 1
	}
	allowRAM := true
	if request.AllowRAMOffload != nil {
		allowRAM = *request.AllowRAMOffload
	}
	runtimeBytes := int64(DefaultRuntimeOverheadBytes)
	if request.RuntimeOverheadBytes != nil {
		runtimeBytes = *request.RuntimeOverheadBytes
		if runtimeBytes < 0 {
			return nil, fmt.Errorf("instance %s has negative runtime overhead", request.InstanceID)
		}
	}
	eligible, err := selectedDedicatedGPUs(request.SelectedGPUIDs, state)
	if err != nil {
		return nil, fmt.Errorf("instance %s: %w", request.InstanceID, err)
	}
	if request.ForceCPU {
		eligible = []string{}
	}

	requested := request.Model.ContextLimit
	if request.RequestedContext != nil {
		requested = *request.RequestedContext
		if requested <= 0 {
			return nil, fmt.Errorf("instance %s requested context must be positive", request.InstanceID)
		}
		if requested > request.Model.ContextLimit {
			return nil, fmt.Errorf("instance %s requested context %d exceeds model hard limit %d", request.InstanceID, requested, request.Model.ContextLimit)
		}
	}
	minimum := request.MinimumContext
	if minimum <= 0 {
		minimum = minInt(DefaultMinimumContext, requested)
	}
	if minimum <= 0 || minimum > requested {
		return nil, fmt.Errorf("instance %s minimum context %d exceeds requested context %d", request.InstanceID, minimum, requested)
	}
	if request.Pinned && request.CurrentContext > 0 {
		if request.CurrentContext > request.Model.ContextLimit {
			return nil, fmt.Errorf("pinned instance %s current context exceeds model hard limit", request.InstanceID)
		}
		minimum = request.CurrentContext
		requested = request.CurrentContext
	}

	gpuCapacity := sumSelectedBudget(state.gpuBudget, eligible)
	if request.WeightGPUBytes != nil && (*request.WeightGPUBytes < 0 || *request.WeightGPUBytes > request.Model.WeightBytes) {
		return nil, fmt.Errorf("instance %s weight_gpu_bytes must be between zero and total weight bytes", request.InstanceID)
	}
	fixed, err := checkedAdd(request.Model.WeightBytes, runtimeBytes)
	if err != nil {
		return nil, fmt.Errorf("instance %s fixed memory overflow", request.InstanceID)
	}
	gpuFixed := fixed
	weightsRequireRAM := false
	if request.WeightGPUBytes != nil {
		gpuFixed, err = checkedAdd(*request.WeightGPUBytes, runtimeBytes)
		if err != nil {
			return nil, fmt.Errorf("instance %s fixed GPU memory overflow", request.InstanceID)
		}
		weightsRequireRAM = *request.WeightGPUBytes < request.Model.WeightBytes
	}
	gpuMax := capacityContextLimit(request.Model, sequences, dtype, gpuCapacity, gpuFixed)
	combinedCapacity := gpuCapacity
	if allowRAM {
		combinedCapacity, err = checkedAdd(combinedCapacity, state.ramBudget)
		if err != nil {
			combinedCapacity = math.MaxInt64
		}
	}
	ramMax := capacityContextLimit(request.Model, sequences, dtype, combinedCapacity, fixed)
	if !allowRAM {
		ramMax = gpuMax
	}
	maximum := minInt(requested, ramMax)
	if maximum < minimum {
		requiredKV, _ := KVBytesForContext(request.Model, minimum, sequences, dtype)
		required, addErr := checkedAdd(fixed, requiredKV)
		if addErr != nil {
			required = math.MaxInt64
		}
		return nil, &ConflictError{
			InstanceID: request.InstanceID, Resource: "memory", RequiredBytes: required,
			AvailableBytes: combinedCapacity,
			Reason:         fmt.Sprintf("minimum context %d cannot fit; maximum is %d", minimum, ramMax),
		}
	}

	var ramThreshold *int
	if weightsRequireRAM {
		threshold := 0
		ramThreshold = &threshold
	} else if gpuMax < request.Model.ContextLimit {
		threshold := gpuMax + 1
		if fixed > gpuCapacity {
			threshold = 0
		}
		ramThreshold = &threshold
	}
	oneToken, err := KVBytesForContext(request.Model, 1, sequences, dtype)
	if err != nil {
		return nil, err
	}
	plan := ContextPlan{
		InstanceID:             request.InstanceID,
		ModelLimit:             request.Model.ContextLimit,
		GPUOnlyMaxContext:      gpuMax,
		RAMBackedMaxContext:    ramMax,
		RAMRequiredFromContext: ramThreshold,
		KVBytesPerTokenAtStart: oneToken,
		MaxSequences:           sequences,
		KVCacheDType:           dtype,
		Priority:               priority,
		Pinned:                 request.Pinned,
	}
	return &preparedRequest{
		request: request, eligibleGPUs: eligible, allowRAM: allowRAM, sequences: sequences,
		dtype: dtype, weight: weight, runtimeBytes: runtimeBytes, minimum: minimum,
		maximum: maximum, plan: plan,
		extra: MemoryAllocation{GPUBytes: make(map[string]int64), Confidence: ConfidenceEstimated},
	}, nil
}

func buildResourceState(hardware Hardware, policy ReservePolicy) (*resourceState, error) {
	if hardware.RAMTotalBytes <= 0 {
		return nil, fmt.Errorf("hardware snapshot has no physical RAM total")
	}
	if hardware.EngineRAMUsedBytes < 0 {
		return nil, fmt.Errorf("hardware snapshot has negative engine RAM usage")
	}
	ramReserve := defaultReserve(hardware.RAMTotalBytes, 15, 4*GiB)
	if policy.RAMBytes != nil {
		ramReserve = *policy.RAMBytes
	}
	if ramReserve < 0 {
		return nil, fmt.Errorf("RAM reserve must not be negative")
	}
	ramAvailable := availableWithReclaim(hardware.RAMTotalBytes, hardware.RAMAvailableBytes, hardware.EngineRAMUsedBytes)
	state := &resourceState{
		ramBudget:    subtractFloor(ramAvailable, ramReserve),
		ramReserve:   ramReserve,
		gpuBudget:    make(map[string]int64),
		gpuRemaining: make(map[string]int64),
		gpuReserve:   make(map[string]int64),
		gpuUnified:   make(map[string]bool),
		knownGPU:     make(map[string]struct{}),
	}
	state.ramRemaining = state.ramBudget
	for _, gpu := range hardware.GPUs {
		if gpu.ID == "" {
			return nil, fmt.Errorf("hardware snapshot contains a GPU without stable ID")
		}
		if _, duplicate := state.knownGPU[gpu.ID]; duplicate {
			return nil, fmt.Errorf("duplicate GPU ID %q", gpu.ID)
		}
		if gpu.TotalBytes < 0 || gpu.EngineUsedBytes < 0 {
			return nil, fmt.Errorf("GPU %s has a negative memory value", gpu.ID)
		}
		state.knownGPU[gpu.ID] = struct{}{}
		state.gpuUnified[gpu.ID] = gpu.UnifiedMemory
		if gpu.UnifiedMemory {
			continue
		}
		reserve := defaultReserve(gpu.TotalBytes, 10, 512*MiB)
		if policy.GPUBytes != nil {
			reserve = *policy.GPUBytes
		}
		if override, ok := policy.GPUBytesByID[gpu.ID]; ok {
			reserve = override
		}
		if reserve < 0 {
			return nil, fmt.Errorf("GPU %s reserve must not be negative", gpu.ID)
		}
		available := availableWithReclaim(gpu.TotalBytes, gpu.AvailableBytes, gpu.EngineUsedBytes)
		budget := subtractFloor(available, reserve)
		state.gpuReserve[gpu.ID] = reserve
		state.gpuBudget[gpu.ID] = budget
		state.gpuRemaining[gpu.ID] = budget
	}
	return state, nil
}

func defaultReserve(total int64, percent int64, floor int64) int64 {
	percentage := total / 100 * percent
	if remainder := total % 100; remainder > 0 {
		percentage += (remainder*percent + 99) / 100
	}
	if percentage < floor {
		return floor
	}
	return percentage
}

func availableWithReclaim(total int64, available *int64, engineUsed int64) int64 {
	value := total
	if available != nil {
		value = *available
		if value < 0 {
			value = 0
		}
	}
	if value > total {
		value = total
	}
	if engineUsed > total-value {
		return total
	}
	return value + engineUsed
}

func subtractFloor(value, subtract int64) int64 {
	if subtract >= value {
		return 0
	}
	return value - subtract
}

func selectedDedicatedGPUs(selected []string, state *resourceState) ([]string, error) {
	if len(selected) == 0 {
		result := make([]string, 0, len(state.gpuBudget))
		for id := range state.gpuBudget {
			result = append(result, id)
		}
		sort.Strings(result)
		return result, nil
	}
	seen := make(map[string]struct{}, len(selected))
	result := make([]string, 0, len(selected))
	for _, id := range selected {
		if _, duplicate := seen[id]; duplicate {
			continue
		}
		seen[id] = struct{}{}
		if _, known := state.knownGPU[id]; !known {
			return nil, fmt.Errorf("unknown GPU ID %q", id)
		}
		if !state.gpuUnified[id] {
			result = append(result, id)
		}
	}
	sort.Strings(result)
	return result, nil
}

func capacityContextLimit(model Model, sequences int, dtype KVCacheDType, capacity, fixed int64) int {
	if capacity < fixed {
		return 0
	}
	budget := capacity - fixed
	low, high := 0, model.ContextLimit
	for low < high {
		mid := low + (high-low+1)/2
		bytes, err := KVBytesForContext(model, mid, sequences, dtype)
		if err == nil && bytes <= budget {
			low = mid
		} else {
			high = mid - 1
		}
	}
	return low
}

func sumSelectedBudget(budgets map[string]int64, selected []string) int64 {
	var total int64
	for _, id := range selected {
		value := budgets[id]
		if total > math.MaxInt64-value {
			return math.MaxInt64
		}
		total += value
	}
	return total
}

func (state *resourceState) preview(bytes int64, eligible []string, allowRAM bool) (MemoryAllocation, bool) {
	allocation := MemoryAllocation{GPUBytes: make(map[string]int64), Confidence: ConfidenceEstimated}
	if bytes < 0 {
		return allocation, false
	}
	remaining := bytes
	available := make(map[string]int64, len(eligible))
	for _, id := range eligible {
		available[id] = state.gpuRemaining[id]
	}
	for remaining > 0 && len(available) > 0 {
		selected := ""
		var most int64 = -1
		for id, value := range available {
			if value > most || (value == most && (selected == "" || id < selected)) {
				selected, most = id, value
			}
		}
		delete(available, selected)
		if most <= 0 {
			continue
		}
		used := minInt64(remaining, most)
		allocation.GPUBytes[selected] += used
		remaining -= used
	}
	if remaining > 0 && allowRAM {
		used := minInt64(remaining, state.ramRemaining)
		allocation.RAMBytes = used
		remaining -= used
	}
	if remaining > 0 {
		return MemoryAllocation{}, false
	}
	allocation.TotalBytes = bytes
	return allocation, true
}

func (state *resourceState) allocate(bytes int64, eligible []string, allowRAM bool) (MemoryAllocation, bool) {
	allocation, ok := state.preview(bytes, eligible, allowRAM)
	if !ok {
		return MemoryAllocation{}, false
	}
	state.consume(allocation)
	return allocation, true
}

func (state *resourceState) consume(allocation MemoryAllocation) {
	for id, bytes := range allocation.GPUBytes {
		state.gpuRemaining[id] -= bytes
	}
	state.ramRemaining -= allocation.RAMBytes
}

func dominantShare(allocation MemoryAllocation, state *resourceState) float64 {
	share := 0.0
	if allocation.RAMBytes > 0 && state.ramBudget > 0 {
		share = float64(allocation.RAMBytes) / float64(state.ramBudget)
	}
	for id, bytes := range allocation.GPUBytes {
		if budget := state.gpuBudget[id]; budget > 0 {
			candidate := float64(bytes) / float64(budget)
			if candidate > share {
				share = candidate
			}
		}
	}
	return share
}

func addAllocation(target *MemoryAllocation, addition MemoryAllocation) {
	if target.GPUBytes == nil {
		target.GPUBytes = make(map[string]int64)
	}
	for id, bytes := range addition.GPUBytes {
		target.GPUBytes[id] += bytes
	}
	target.RAMBytes += addition.RAMBytes
	target.TotalBytes += addition.TotalBytes
	if target.Confidence == "" {
		target.Confidence = addition.Confidence
	}
}

func reserveFor(item *preparedRequest, state *resourceState) MemoryAllocation {
	reserve := MemoryAllocation{GPUBytes: make(map[string]int64), RAMBytes: state.ramReserve, Confidence: ConfidenceMeasured}
	for _, id := range item.eligibleGPUs {
		reserve.GPUBytes[id] = state.gpuReserve[id]
	}
	reserve.TotalBytes = reserve.RAMBytes
	for _, bytes := range reserve.GPUBytes {
		reserve.TotalBytes = saturatingAdd64(reserve.TotalBytes, bytes)
	}
	return reserve
}

func sumActualAllocations(breakdown ResourceBreakdown) MemoryAllocation {
	total := MemoryAllocation{GPUBytes: make(map[string]int64), Confidence: ConfidenceEstimated}
	addAllocation(&total, breakdown.Weights)
	addAllocation(&total, breakdown.KVCache)
	addAllocation(&total, breakdown.Runtime)
	return total
}

func minimumConflict(item *preparedRequest, state *resourceState, required int64, reason string) *ConflictError {
	available := state.ramRemaining
	if !item.allowRAM {
		available = 0
	}
	for _, id := range item.eligibleGPUs {
		available = saturatingAdd64(available, state.gpuRemaining[id])
	}
	return &ConflictError{InstanceID: item.request.InstanceID, Resource: "gpu_or_ram", RequiredBytes: required, AvailableBytes: available, Reason: reason}
}

func confidenceOr(value, fallback Confidence) Confidence {
	if value == "" {
		return fallback
	}
	return value
}

func saturatingAdd64(a, b int64) int64 {
	if b > 0 && a > math.MaxInt64-b {
		return math.MaxInt64
	}
	return a + b
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func minInt64(a, b int64) int64 {
	if a < b {
		return a
	}
	return b
}
