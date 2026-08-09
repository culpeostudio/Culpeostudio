package engineruntime

import "time"

type RuntimeKind string

// RuntimeLlamaCPP is the only runtime the engine drives. It is kept as a named
// type rather than dropped outright because instance state persisted by earlier
// versions carries it, and the gRPC surface still reports it.
const RuntimeLlamaCPP RuntimeKind = "llama_cpp"

type ChangeMode string

const (
	ChangeLive            ChangeMode = "live"
	ChangeRestartRequired ChangeMode = "restart_required"
)

type RuntimeCapability struct {
	Kind    RuntimeKind  `json:"kind"`
	Variant BuildVariant `json:"variant,omitempty"`
	Version string       `json:"version"`
	// BuildVersion is what the installed binary reported for --version.
	BuildVersion string   `json:"build_version,omitempty"`
	Installed    bool     `json:"installed"`
	Healthy      bool     `json:"healthy"`
	Environment  string   `json:"environment,omitempty"`
	ServerPath   string   `json:"server_path,omitempty"`
	GPUBackends  []string `json:"gpu_backends,omitempty"`
	KVCaches     []string `json:"kv_cache_modes,omitempty"`
	// Flags is every long option the installed binary's --help lists. It is what
	// an extra-args passthrough is checked against, so an unknown flag is
	// refused while the config is written rather than when the process spawns.
	Flags         []string              `json:"flags,omitempty"`
	ConfigFields  map[string]ChangeMode `json:"config_fields,omitempty"`
	ProbeError    string                `json:"probe_error,omitempty"`
	LastProbedAt  *time.Time            `json:"last_probed_at,omitempty"`
	Status        string                `json:"status,omitempty"`
	StatusMessage string                `json:"status_message,omitempty"`
	Progress      float64               `json:"progress,omitempty"`
	ErrorCode     string                `json:"error_code,omitempty"`
}

type InstanceState string

const (
	StateInstalling     InstanceState = "installing"
	StateQueued         InstanceState = "queued"
	StateStarting       InstanceState = "starting"
	StateReady          InstanceState = "ready"
	StateDraining       InstanceState = "draining"
	StateRestarting     InstanceState = "restarting"
	StateStopped        InstanceState = "stopped"
	StateFailed         InstanceState = "failed"
	StateFailedRollback InstanceState = "failed_rollback"
)

type KVPolicy string

const (
	KVPolicyNative     KVPolicy = "native"
	KVPolicyPrefer4Bit KVPolicy = "prefer_4bit"
)

type Fallback struct {
	Setting string `json:"setting"`
	From    string `json:"from"`
	To      string `json:"to"`
	Reason  string `json:"reason"`
}

// LoRAAdapter is one adapter layered onto the base weights at load time. Scale
// is optional: without it the adapter is applied at its own strength.
type LoRAAdapter struct {
	Path  string   `json:"path"`
	Scale *float64 `json:"scale,omitempty"`
}

type RequestedConfig struct {
	Runtime       RuntimeKind `json:"runtime"`
	ModelPath     string      `json:"model_path"`
	ContextLength *int        `json:"context_length"`
	GPULayers     *int        `json:"gpu_layers"`
	Threads       *int        `json:"threads"`
	MaxSequences  *int        `json:"max_sequences"`
	KVPolicy      KVPolicy    `json:"kv_policy"`
	KVCacheDType  *string     `json:"kv_cache_dtype"`
	AllowFallback *bool       `json:"allow_fallback"`

	// FlashAttention is "on", "off" or "auto". Empty means the adapter decides:
	// on for a quantised cache, which needs it, and auto otherwise.
	FlashAttention string `json:"flash_attention,omitempty"`

	// SplitMode and MainGPU steer multi-GPU placement. They replace the
	// tensor-parallelism knob the removed runtimes used.
	SplitMode string `json:"split_mode,omitempty"`
	MainGPU   *int   `json:"main_gpu,omitempty"`

	// TensorSplit is the per-GPU share of the model, as proportions. Without it
	// llama.cpp splits evenly, which is wrong on a machine with unequal cards.
	TensorSplit []float64 `json:"tensor_split,omitempty"`

	// CPUMoELayers keeps the Mixture-of-Experts weights of the first N layers in
	// system RAM. On an MoE model this is a far finer lever than GPULayers:
	// attention and the dense path stay on the GPU while the experts, which
	// dominate the weights but are only sparsely read, move to RAM. A negative
	// value keeps every expert layer on the CPU.
	CPUMoELayers *int `json:"cpu_moe_layers,omitempty"`

	// BatchSize and UBatchSize trade prompt-processing throughput against the
	// compute buffer, which the planner budgets for.
	BatchSize    *int `json:"batch_size,omitempty"`
	UBatchSize   *int `json:"ubatch_size,omitempty"`
	ThreadsBatch *int `json:"threads_batch,omitempty"`

	// MemoryLock pins the weights into RAM; DisableMmap reads them into private
	// memory instead of mapping the file. Both change what the resource guard
	// sees, because mapped weights are page cache rather than process RSS.
	MemoryLock  bool `json:"memory_lock,omitempty"`
	DisableMmap bool `json:"disable_mmap,omitempty"`

	// CacheReuse and KeepTokens govern how much of a previous prompt survives
	// into the next request. They are the largest lever on felt chat latency.
	CacheReuse *int `json:"cache_reuse,omitempty"`
	KeepTokens *int `json:"keep_tokens,omitempty"`

	// ContinuousBatching is "on", "off" or empty for the server default.
	ContinuousBatching string `json:"continuous_batching,omitempty"`

	// SWAFull keeps the full sliding-window cache rather than the trimmed one.
	SWAFull bool `json:"swa_full,omitempty"`

	// Jinja switches on the model's own chat template, which tool calling needs.
	// ChatTemplate and ChatTemplateFile override that template.
	Jinja            bool   `json:"jinja,omitempty"`
	ChatTemplate     string `json:"chat_template,omitempty"`
	ChatTemplateFile string `json:"chat_template_file,omitempty"`

	LoRAAdapters []LoRAAdapter `json:"lora_adapters,omitempty"`

	// MultimodalProjector is the mmproj file that turns a text model into a
	// vision one.
	MultimodalProjector string `json:"multimodal_projector,omitempty"`

	// Embeddings and Reranking put the server into its embedding or rerank mode.
	// PoolingType only applies to the former.
	Embeddings  bool   `json:"embeddings,omitempty"`
	Reranking   bool   `json:"reranking,omitempty"`
	PoolingType string `json:"pooling_type,omitempty"`

	NUMA string `json:"numa,omitempty"`

	// Metrics exposes the server's own Prometheus counters. The engine turns
	// this on so instance metrics are measured rather than estimated.
	Metrics bool `json:"metrics,omitempty"`

	// Draft speculative decoding. The flag names for this moved between builds,
	// so the adapter emits the spelling the installed binary reports.
	DraftModelPath string `json:"draft_model_path,omitempty"`
	DraftMaxTokens *int   `json:"draft_max_tokens,omitempty"`
	DraftMinTokens *int   `json:"draft_min_tokens,omitempty"`
	DraftGPULayers *int   `json:"draft_gpu_layers,omitempty"`

	// ExtraArgs is the escape hatch: flags the engine has no field for, checked
	// against what the installed binary's own --help lists before they are used.
	ExtraArgs []string `json:"extra_args,omitempty"`

	GPUMemoryBytes []int64 `json:"gpu_memory_bytes,omitempty"`

	CPUMemoryBytes *int64 `json:"cpu_memory_bytes,omitempty"`
}

func (c RequestedConfig) fallbackAllowed() bool {
	return c.AllowFallback == nil || *c.AllowFallback
}

type EffectiveConfig struct {
	Runtime        RuntimeKind  `json:"runtime"`
	Variant        BuildVariant `json:"variant,omitempty"`
	ModelPath      string       `json:"model_path"`
	ContextLength  *int         `json:"context_length"`
	GPULayers      *int         `json:"gpu_layers"`
	Threads        *int         `json:"threads"`
	MaxSequences   *int         `json:"max_sequences"`
	KVCacheDType   string       `json:"kv_cache_dtype"`
	FlashAttention string       `json:"flash_attention,omitempty"`
	SplitMode      string       `json:"split_mode,omitempty"`
	MainGPU        *int         `json:"main_gpu,omitempty"`

	TensorSplit  []float64 `json:"tensor_split,omitempty"`
	CPUMoELayers *int      `json:"cpu_moe_layers,omitempty"`
	BatchSize    *int      `json:"batch_size,omitempty"`
	UBatchSize   *int      `json:"ubatch_size,omitempty"`
	ThreadsBatch *int      `json:"threads_batch,omitempty"`

	MemoryLock  bool `json:"memory_lock,omitempty"`
	DisableMmap bool `json:"disable_mmap,omitempty"`

	CacheReuse         *int   `json:"cache_reuse,omitempty"`
	KeepTokens         *int   `json:"keep_tokens,omitempty"`
	ContinuousBatching string `json:"continuous_batching,omitempty"`
	SWAFull            bool   `json:"swa_full,omitempty"`

	Jinja            bool   `json:"jinja,omitempty"`
	ChatTemplate     string `json:"chat_template,omitempty"`
	ChatTemplateFile string `json:"chat_template_file,omitempty"`

	LoRAAdapters        []LoRAAdapter `json:"lora_adapters,omitempty"`
	MultimodalProjector string        `json:"multimodal_projector,omitempty"`

	Embeddings  bool   `json:"embeddings,omitempty"`
	Reranking   bool   `json:"reranking,omitempty"`
	PoolingType string `json:"pooling_type,omitempty"`
	NUMA        string `json:"numa,omitempty"`
	Metrics     bool   `json:"metrics,omitempty"`

	DraftModelPath string `json:"draft_model_path,omitempty"`
	DraftMaxTokens *int   `json:"draft_max_tokens,omitempty"`
	DraftMinTokens *int   `json:"draft_min_tokens,omitempty"`
	DraftGPULayers *int   `json:"draft_gpu_layers,omitempty"`

	ExtraArgs []string `json:"extra_args,omitempty"`

	GPUMemoryBytes []int64    `json:"gpu_memory_bytes,omitempty"`
	CPUMemoryBytes *int64     `json:"cpu_memory_bytes,omitempty"`
	Fallbacks      []Fallback `json:"fallbacks,omitempty"`
}
