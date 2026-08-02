package engineruntime

import "time"

type RuntimeKind string

const (
	RuntimeLlamaCPP     RuntimeKind = "llama_cpp"
	RuntimeTransformers RuntimeKind = "transformers"
	RuntimeVLLM         RuntimeKind = "vllm"
)

type ChangeMode string

const (
	ChangeLive            ChangeMode = "live"
	ChangeRestartRequired ChangeMode = "restart_required"
)

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

	GPUMemoryBytes []int64 `json:"gpu_memory_bytes,omitempty"`

	GPUMemoryUtilization *float64 `json:"gpu_memory_utilization,omitempty"`

	CPUMemoryBytes *int64 `json:"cpu_memory_bytes,omitempty"`
}

func (c RequestedConfig) fallbackAllowed() bool {
	return c.AllowFallback == nil || *c.AllowFallback
}

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
