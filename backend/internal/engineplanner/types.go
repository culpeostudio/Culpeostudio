package engineplanner

import "fmt"

const (
	MiB int64 = 1024 * 1024
	GiB int64 = 1024 * MiB
)

type Confidence string

const (
	ConfidenceMeasured  Confidence = "measured"
	ConfidenceEstimated Confidence = "estimated"
)

type Priority string

const (
	PriorityLow    Priority = "low"
	PriorityNormal Priority = "normal"
	PriorityHigh   Priority = "high"
)

func PriorityWeight(priority Priority) int {
	switch priority {
	case PriorityLow:
		return 1
	case PriorityHigh:
		return 4
	case PriorityNormal, "":
		return 2
	default:
		return 0
	}
}

type KVCacheDType string

const (
	KVCacheQ4   KVCacheDType = "q4"
	KVCacheFP8  KVCacheDType = "fp8"
	KVCacheFP16 KVCacheDType = "fp16"
	KVCacheBF16 KVCacheDType = "bf16"
	KVCacheFP32 KVCacheDType = "fp32"
)

type GPU struct {
	ID              string     `json:"id"`
	Name            string     `json:"name,omitempty"`
	Backend         string     `json:"backend,omitempty"`
	TotalBytes      int64      `json:"total_bytes"`
	AvailableBytes  *int64     `json:"available_bytes,omitempty"`
	EngineUsedBytes int64      `json:"engine_used_bytes,omitempty"`
	UnifiedMemory   bool       `json:"unified_memory,omitempty"`
	Confidence      Confidence `json:"confidence,omitempty"`
}

type Hardware struct {
	RAMTotalBytes      int64      `json:"ram_total_bytes"`
	RAMAvailableBytes  *int64     `json:"ram_available_bytes,omitempty"`
	EngineRAMUsedBytes int64      `json:"engine_ram_used_bytes,omitempty"`
	RAMConfidence      Confidence `json:"ram_confidence,omitempty"`
	GPUs               []GPU      `json:"gpus,omitempty"`
}

type ReservePolicy struct {
	RAMBytes     *int64           `json:"ram_bytes,omitempty"`
	GPUBytes     *int64           `json:"gpu_bytes,omitempty"`
	GPUBytesByID map[string]int64 `json:"gpu_bytes_by_id,omitempty"`
}

type Model struct {
	ID                    string     `json:"id"`
	WeightBytes           int64      `json:"weight_bytes"`
	WeightConfidence      Confidence `json:"weight_confidence,omitempty"`
	ContextLimit          int        `json:"context_limit"`
	Layers                int        `json:"layers"`
	KVHeads               int        `json:"kv_heads"`
	AttentionHeads        int        `json:"attention_heads,omitempty"`
	HeadDimension         int        `json:"head_dimension"`
	SlidingWindow         int        `json:"sliding_window,omitempty"`
	GlobalAttentionLayers int        `json:"global_attention_layers,omitempty"`
}

type Request struct {
	InstanceID       string       `json:"instance_id"`
	Model            Model        `json:"model"`
	RequestedContext *int         `json:"requested_context,omitempty"`
	MinimumContext   int          `json:"minimum_context,omitempty"`
	CurrentContext   int          `json:"current_context,omitempty"`
	MaxSequences     int          `json:"max_sequences,omitempty"`
	KVCacheDType     KVCacheDType `json:"kv_cache_dtype,omitempty"`
	Priority         Priority     `json:"priority,omitempty"`
	Pinned           bool         `json:"pinned,omitempty"`
	SelectedGPUIDs   []string     `json:"selected_gpu_ids,omitempty"`
	ForceCPU         bool         `json:"force_cpu,omitempty"`

	WeightGPUBytes       *int64 `json:"weight_gpu_bytes,omitempty"`
	AllowRAMOffload      *bool  `json:"allow_ram_offload,omitempty"`
	RuntimeOverheadBytes *int64 `json:"runtime_overhead_bytes,omitempty"`
}

type MemoryAllocation struct {
	TotalBytes int64            `json:"total_bytes"`
	GPUBytes   map[string]int64 `json:"gpu_bytes,omitempty"`
	RAMBytes   int64            `json:"ram_bytes,omitempty"`
	Confidence Confidence       `json:"confidence"`
}

type ResourceBreakdown struct {
	Weights MemoryAllocation `json:"weights"`
	KVCache MemoryAllocation `json:"kv_cache"`
	Runtime MemoryAllocation `json:"runtime"`
	Reserve MemoryAllocation `json:"reserve"`
	Total   MemoryAllocation `json:"total"`
}

type ContextPlan struct {
	InstanceID             string            `json:"instance_id"`
	ModelLimit             int               `json:"model_limit"`
	GPUOnlyMaxContext      int               `json:"gpu_only_max_context"`
	RAMBackedMaxContext    int               `json:"ram_backed_max_context"`
	EffectiveContext       int               `json:"effective_context"`
	RAMRequiredFromContext *int              `json:"ram_required_from_context,omitempty"`
	KVBytesPerTokenAtStart int64             `json:"kv_bytes_per_token_at_start"`
	MaxSequences           int               `json:"max_sequences"`
	KVCacheDType           KVCacheDType      `json:"kv_cache_dtype"`
	Priority               Priority          `json:"priority"`
	Pinned                 bool              `json:"pinned"`
	RestartRequired        bool              `json:"restart_required"`
	UsesRAM                bool              `json:"uses_ram"`
	Breakdown              ResourceBreakdown `json:"breakdown"`
}

type ConflictError struct {
	InstanceID     string `json:"instance_id,omitempty"`
	Resource       string `json:"resource"`
	RequiredBytes  int64  `json:"required_bytes"`
	AvailableBytes int64  `json:"available_bytes"`
	Reason         string `json:"reason"`
}

func (e *ConflictError) Error() string {
	if e.InstanceID == "" {
		return fmt.Sprintf("engine plan conflict on %s: %s", e.Resource, e.Reason)
	}
	return fmt.Sprintf("engine plan conflict for %s on %s: %s", e.InstanceID, e.Resource, e.Reason)
}
