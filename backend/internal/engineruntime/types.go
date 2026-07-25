// Package engineruntime contains the process and environment management used by
// the local model engine.  It deliberately has no dependency on the HTTP layer
// so the same implementation can be used by REST handlers and future services.
package engineruntime

import "time"

// RuntimeKind identifies a supported inference implementation.
type RuntimeKind string

const (
	RuntimeLlamaCPP     RuntimeKind = "llama_cpp"
	RuntimeTransformers RuntimeKind = "transformers"
	RuntimeVLLM         RuntimeKind = "vllm"
)

// ChangeMode tells clients whether a setting can be changed on a live model.
type ChangeMode string

const (
	ChangeLive            ChangeMode = "live"
	ChangeRestartRequired ChangeMode = "restart_required"
)

// RuntimeCapability is the serializable result of installing and probing a
// runtime. KVCaches contains only cache modes proven usable by the probe; it
// never describes or requests a model-weight conversion.
type RuntimeCapability struct {
	Kind          RuntimeKind           `json:"kind"`
	Version       string                `json:"version"`
	Installed     bool                  `json:"installed"`
	Healthy       bool                  `json:"healthy"`
	Environment   string                `json:"environment,omitempty"`
	GPUBackends   []string              `json:"gpu_backends,omitempty"`
	KVCaches      []string              `json:"kv_cache_modes,omitempty"`
	ConfigFields  map[string]ChangeMode `json:"config_fields,omitempty"`
	ProbeError    string                `json:"probe_error,omitempty"`
	LastProbedAt  *time.Time            `json:"last_probed_at,omitempty"`
	Status        string                `json:"status,omitempty"`
	StatusMessage string                `json:"status_message,omitempty"`
	Progress      float64               `json:"progress,omitempty"`
	ErrorCode     string                `json:"error_code,omitempty"`
}

// InstanceState is shared by supervisor snapshots and the API-facing engine
// instance. Some transitions (installing/restarting/rollback) are orchestrated
// by the service above this package, while the process supervisor owns the
// queued/starting/ready/draining/stopped/failed transitions.
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

// KVPolicy is an intent, not a promise. Adapters resolve it to a concrete
// backend cache mode and record every fallback in EffectiveConfig.
type KVPolicy string

const (
	KVPolicyNative     KVPolicy = "native"
	KVPolicyPrefer4Bit KVPolicy = "prefer_4bit"
)

// Fallback records why an adapter could not honor a requested setting.
type Fallback struct {
	Setting string `json:"setting"`
	From    string `json:"from"`
	To      string `json:"to"`
	Reason  string `json:"reason"`
}

// RequestedConfig is kept free of weight-quantization settings by design.
// Pointer-valued numerics preserve the API contract: nil is automatic and zero
// is an explicit expert value.
type RequestedConfig struct {
	Runtime           RuntimeKind `json:"runtime"`
	ModelPath         string      `json:"model_path"`
	ContextLength     *int        `json:"context_length"`
	GPULayers         *int        `json:"gpu_layers"`
	Threads           *int        `json:"threads"`
	TensorParallelism *int        `json:"tensor_parallelism"`
	MaxSequences      *int        `json:"max_sequences"`
	KVPolicy          KVPolicy    `json:"kv_policy"`
	KVCacheDType      *string     `json:"kv_cache_dtype"`
	AllowFallback     *bool       `json:"allow_fallback"`
	TrustRemoteCode   bool        `json:"trust_remote_code"`
	CPUOffloadGB      *float64    `json:"cpu_offload_gb,omitempty"`
	// GPUMemoryBytes contains one hard placement budget for each GPU visible
	// to the worker, in CUDA/ROCm runtime ordinal order. It is derived from the
	// engine's byte-exact plan and is never accepted directly from an API user.
	GPUMemoryBytes []int64 `json:"gpu_memory_bytes,omitempty"`
	// GPUMemoryUtilization is vLLM's per-device allocation fraction. The engine
	// derives it conservatively from planned bytes / physical device bytes.
	GPUMemoryUtilization *float64 `json:"gpu_memory_utilization,omitempty"`
	// CPUMemoryBytes accompanies GPU max_memory entries only for a planned
	// Transformers hybrid placement, so CPU-only loading keeps its old behavior.
	CPUMemoryBytes *int64 `json:"cpu_memory_bytes,omitempty"`
}

func (c RequestedConfig) fallbackAllowed() bool {
	return c.AllowFallback == nil || *c.AllowFallback
}

// EffectiveConfig is the fully resolved launch configuration. Requested is
// embedded so callers can return both requested_config and effective_config.
type EffectiveConfig struct {
	Runtime              RuntimeKind `json:"runtime"`
	ModelPath            string      `json:"model_path"`
	ContextLength        *int        `json:"context_length"`
	GPULayers            *int        `json:"gpu_layers"`
	Threads              *int        `json:"threads"`
	TensorParallelism    *int        `json:"tensor_parallelism"`
	MaxSequences         *int        `json:"max_sequences"`
	KVCacheDType         string      `json:"kv_cache_dtype"`
	TrustRemoteCode      bool        `json:"trust_remote_code"`
	CPUOffloadGB         *float64    `json:"cpu_offload_gb,omitempty"`
	GPUMemoryBytes       []int64     `json:"gpu_memory_bytes,omitempty"`
	GPUMemoryUtilization *float64    `json:"gpu_memory_utilization,omitempty"`
	CPUMemoryBytes       *int64      `json:"cpu_memory_bytes,omitempty"`
	Fallbacks            []Fallback  `json:"fallbacks,omitempty"`
}
