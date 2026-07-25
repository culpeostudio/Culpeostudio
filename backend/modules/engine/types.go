package engine

import (
	"context"
	"encoding/json"
	"time"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
)

type EngineConfig struct {
	Runtime            string                 `json:"runtime"`
	ContextMode        string                 `json:"context_mode"`
	ContextTokens      *int                   `json:"context_tokens"`
	MaxSequences       int                    `json:"max_sequences"`
	Priority           string                 `json:"priority"`
	KVCachePolicy      string                 `json:"kv_cache_policy"`
	AllowFallback      *bool                  `json:"allow_fallback"`
	Autostart          bool                   `json:"autostart"`
	RuntimeOptions     map[string]interface{} `json:"runtime_options,omitempty"`
	GenerationDefaults map[string]interface{} `json:"generation_defaults,omitempty"`
	TrustRemoteCode    bool                   `json:"trust_remote_code,omitempty"`
}

func defaultEngineConfig() EngineConfig {
	allow := true
	return EngineConfig{
		Runtime: "auto", ContextMode: "auto_max", MaxSequences: 1,
		Priority: "normal", KVCachePolicy: "prefer_4bit", AllowFallback: &allow,
		RuntimeOptions: map[string]interface{}{}, GenerationDefaults: map[string]interface{}{},
	}
}

type ContextPlanView struct {
	ModelContextLimitTokens  int                             `json:"model_context_limit_tokens"`
	GPUOnlyMaxContextTokens  int                             `json:"gpu_only_max_context_tokens"`
	HybridMaxContextTokens   int                             `json:"hybrid_max_context_tokens"`
	EffectiveContextTokens   int                             `json:"effective_context_tokens"`
	RAMRequiredAfterTokens   *int                            `json:"ram_required_after_tokens,omitempty"`
	KVBytesPerTokenAtStart   int64                           `json:"kv_bytes_per_token_at_start"`
	MaxSequences             int                             `json:"max_sequences"`
	KVCacheDType             engineplanner.KVCacheDType      `json:"kv_cache_dtype"`
	Priority                 engineplanner.Priority          `json:"priority"`
	Pinned                   bool                            `json:"pinned"`
	RestartRequired          bool                            `json:"restart_required"`
	UsesRAM                  bool                            `json:"uses_ram"`
	Memory                   engineplanner.ResourceBreakdown `json:"memory"`
	Confidence               engineplanner.Confidence        `json:"confidence"`
	Warnings                 []string                        `json:"warnings,omitempty"`
	AffectedRestartInstances []string                        `json:"affected_restart_instances,omitempty"`
	Preflight                PreflightReport                 `json:"preflight"`
}

// PreflightReport is the user-facing evidence for a memory recommendation.
// It deliberately separates a calculated plan from the checks that are still
// performed immediately before and after a worker starts.
type PreflightReport struct {
	HardwareSnapshotID string           `json:"hardware_snapshot_id,omitempty"`
	ModelFingerprint   string           `json:"model_fingerprint,omitempty"`
	MetadataConfidence string           `json:"metadata_confidence,omitempty"`
	Checks             []PreflightCheck `json:"checks,omitempty"`
}

type PreflightCheck struct {
	ID     string `json:"id"`
	State  string `json:"state"`
	Label  string `json:"label"`
	Detail string `json:"detail"`
}

func planView(plan engineplanner.ContextPlan, warnings []string) ContextPlanView {
	return ContextPlanView{
		ModelContextLimitTokens: plan.ModelLimit, GPUOnlyMaxContextTokens: plan.GPUOnlyMaxContext,
		HybridMaxContextTokens: plan.RAMBackedMaxContext, EffectiveContextTokens: plan.EffectiveContext,
		RAMRequiredAfterTokens: plan.RAMRequiredFromContext, KVBytesPerTokenAtStart: plan.KVBytesPerTokenAtStart,
		MaxSequences: plan.MaxSequences, KVCacheDType: plan.KVCacheDType, Priority: plan.Priority,
		Pinned: plan.Pinned, RestartRequired: plan.RestartRequired, UsesRAM: plan.UsesRAM,
		Memory: plan.Breakdown, Confidence: engineplanner.ConfidenceEstimated, Warnings: append([]string(nil), warnings...),
	}
}

type LastKnownGood struct {
	EffectiveConfig EngineConfig    `json:"effective_config"`
	Plan            ContextPlanView `json:"plan"`
	Runtime         string          `json:"runtime"`
	UpdatedAt       time.Time       `json:"updated_at"`
}

type Placement string

const (
	PlacementGPU     Placement = "gpu"
	PlacementRAM     Placement = "ram"
	PlacementHybrid  Placement = "hybrid"
	PlacementUnknown Placement = "unknown"
)

type GuardState string

const (
	GuardNormal    GuardState = "normal"
	GuardWarning   GuardState = "warning"
	GuardCritical  GuardState = "critical"
	GuardEmergency GuardState = "emergency"
)

type EngineInstance struct {
	ID                    string                      `json:"id"`
	State                 engineruntime.InstanceState `json:"state"`
	ModelID               string                      `json:"model_id"`
	ServedModelName       string                      `json:"served_model_name"`
	RequestedConfig       EngineConfig                `json:"requested_config"`
	EffectiveConfig       EngineConfig                `json:"effective_config"`
	LastKnownGood         *LastKnownGood              `json:"last_known_good,omitempty"`
	Plan                  *ContextPlanView            `json:"plan,omitempty"`
	Runtime               engineruntime.RuntimeKind   `json:"runtime,omitempty"`
	Priority              string                      `json:"priority"`
	Pinned                bool                        `json:"pinned"`
	Autostart             bool                        `json:"autostart"`
	ShowInChatPicker      bool                        `json:"show_in_chat_picker"`
	Placement             Placement                   `json:"placement"`
	ActiveRequests        int                         `json:"active_requests"`
	LastUsedAt            *time.Time                  `json:"last_used_at,omitempty"`
	IdleExpiresAt         *time.Time                  `json:"idle_expires_at,omitempty"`
	GuardState            GuardState                  `json:"guard_state"`
	RestartRequiredFields []string                    `json:"restart_required_fields,omitempty"`
	Fallbacks             []engineruntime.Fallback    `json:"fallbacks,omitempty"`
	Error                 string                      `json:"error,omitempty"`
	ErrorSummary          string                      `json:"error_summary,omitempty"`
	ErrorCode             string                      `json:"error_code,omitempty"`
	SuggestedFix          *SuggestedFix               `json:"suggested_fix,omitempty"`
	Phase                 string                      `json:"phase,omitempty"`
	DetailMessage         string                      `json:"detail_message,omitempty"`
	Progress              float64                     `json:"progress"`
	EndpointName          string                      `json:"endpoint_name"`
	PlanRevision          int64                       `json:"plan_revision"`
	CreatedAt             time.Time                   `json:"created_at"`
	UpdatedAt             time.Time                   `json:"updated_at"`

	BaseURL      string `json:"-"`
	WorkerSecret string `json:"-"`
	// workerGeneration changes only when a newly verified worker is committed.
	// Inference leases use it together with WorkerSecret to ignore stale
	// releases from a stopped/deleted/recreated worker generation.
	workerGeneration uint64
}

type EngineOperation struct {
	ID                          string                 `json:"id"`
	Type                        string                 `json:"type"`
	State                       string                 `json:"state"`
	InstanceID                  string                 `json:"instance_id,omitempty"`
	QueuePosition               int                    `json:"queue_position"`
	Progress                    float64                `json:"progress"`
	Message                     string                 `json:"message,omitempty"`
	DetailMessage               string                 `json:"detail_message,omitempty"`
	Phase                       string                 `json:"phase,omitempty"`
	Error                       string                 `json:"error,omitempty"`
	ErrorSummary                string                 `json:"error_summary,omitempty"`
	ErrorCode                   string                 `json:"error_code,omitempty"`
	SuggestedFix                *SuggestedFix          `json:"suggested_fix,omitempty"`
	ResourceConflict            *ResourceConflictError `json:"resource_conflict,omitempty"`
	CreatedAt                   time.Time              `json:"created_at"`
	UpdatedAt                   time.Time              `json:"updated_at"`
	FinishedAt                  *time.Time             `json:"finished_at,omitempty"`
	EvictedInstanceIDs          []string               `json:"evicted_instance_ids,omitempty"`
	ProtectedInstanceIDs        []string               `json:"-"`
	ReservedEvictionInstanceIDs []string               `json:"-"`

	cancel context.CancelFunc `json:"-"`
}

type persistedEngineState struct {
	SchemaVersion int                `json:"schema_version"`
	PlanRevision  int64              `json:"plan_revision"`
	Instances     []*EngineInstance  `json:"instances"`
	Operations    []*EngineOperation `json:"operations,omitempty"`
}

// SuggestedFix describes a one-click remediation the UI can offer next to a
// failure. Action is machine-readable; Label is the ready-to-render button
// text.
type SuggestedFix struct {
	Action string `json:"action"`
	Label  string `json:"label"`
}

const fixRetryWithRAM = "retry_with_ram"

// suggestedFixForCode derives the automatic remediation for a stable error
// code. It is recomputed on every clone so it can never disagree with
// ErrorCode.
func suggestedFixForCode(code string) *SuggestedFix {
	if code == "" {
		return nil
	}
	if diagnosis, ok := engineruntime.DiagnosisByCode(code); ok && diagnosis.SuggestedFix != "" {
		return &SuggestedFix{Action: diagnosis.SuggestedFix, Label: diagnosis.SuggestedFixLabel}
	}
	switch code {
	case "resource_conflict":
		return &SuggestedFix{Action: fixRetryWithRAM, Label: "Mit System-RAM neu berechnen"}
	case "insufficient_memory", "resource_guard_rejected":
		return &SuggestedFix{Action: engineruntime.FixReduceContext, Label: "Kontext automatisch verkleinern"}
	case "gpu_runtime_unavailable":
		return &SuggestedFix{Action: engineruntime.FixReinstallRuntime, Label: "GPU-Runtime neu einrichten"}
	case "required_file_missing":
		return &SuggestedFix{Action: engineruntime.FixRescanModels, Label: "Modelle neu scannen"}
	}
	return nil
}

func cloneEngineConfig(value EngineConfig) EngineConfig {
	result := value
	result.ContextTokens = cloneIntPointer(value.ContextTokens)
	result.AllowFallback = cloneBoolPointer(value.AllowFallback)
	result.RuntimeOptions = cloneJSONMap(value.RuntimeOptions)
	result.GenerationDefaults = cloneJSONMap(value.GenerationDefaults)
	return result
}

func cloneJSONMap(value map[string]interface{}) map[string]interface{} {
	if value == nil {
		return map[string]interface{}{}
	}
	payload, _ := json.Marshal(value)
	result := map[string]interface{}{}
	_ = json.Unmarshal(payload, &result)
	return result
}

func cloneIntPointer(value *int) *int {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}

func cloneBoolPointer(value *bool) *bool {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}
