// The conversion layer between the engine's own types and the wire. It is a
// separate file from grpc.go so the service reads as the sequence of steps each
// call takes, rather than as field assignments.

package engine

import (
	"encoding/json"
	"strings"
	"time"

	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	hardwarev1 "github.com/culpeohq/backend/gen/go/culpeostudio/hardware/v1"
	"github.com/culpeohq/backend/internal/engineplanner"
	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/internal/modelcatalog"
)

// timestampOrNil leaves a zero time unset. The HTTP API wrote the zero time as
// "0001-01-01T00:00:00Z" and the client had to know that meant "never"; an
// unset field says it outright.
func timestampOrNil(value time.Time) *timestamppb.Timestamp {
	if value.IsZero() {
		return nil
	}
	return timestamppb.New(value)
}

func timestampPointerOrNil(value *time.Time) *timestamppb.Timestamp {
	if value == nil {
		return nil
	}
	return timestampOrNil(*value)
}

// structFromMap carries a free-form JSON object across. A value structpb
// refuses (a NaN, or a type it has no case for) would otherwise fail the whole
// response, so the map is round-tripped through JSON first, which is the shape
// it came from and the shape it is going back to.
func structFromMap(value map[string]interface{}) *structpb.Struct {
	if len(value) == 0 {
		return nil
	}
	payload, err := json.Marshal(value)
	if err != nil {
		return nil
	}
	result := &structpb.Struct{}
	if err := result.UnmarshalJSON(payload); err != nil {
		return nil
	}
	return result
}

func mapFromStruct(value *structpb.Struct) map[string]interface{} {
	if value == nil {
		return nil
	}
	return value.AsMap()
}

func runtimeKindToProto(value string) enginev1.RuntimeKind {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "auto":
		return enginev1.RuntimeKind_RUNTIME_KIND_AUTO
	case string(engineruntime.RuntimeLlamaCPP):
		return enginev1.RuntimeKind_RUNTIME_KIND_LLAMA_CPP
	default:
		return enginev1.RuntimeKind_RUNTIME_KIND_UNSPECIFIED
	}
}

// runtimeKindFromProto maps back. An unspecified runtime stays empty rather
// than becoming "auto": in a config normalizeConfig fills it in, and on an
// instance it genuinely means no runtime has been chosen yet.
func runtimeKindFromProto(value enginev1.RuntimeKind) string {
	switch value {
	case enginev1.RuntimeKind_RUNTIME_KIND_AUTO:
		return "auto"
	case enginev1.RuntimeKind_RUNTIME_KIND_LLAMA_CPP:
		return string(engineruntime.RuntimeLlamaCPP)
	default:
		return ""
	}
}

func contextModeToProto(value string) enginev1.ContextMode {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "auto_max":
		return enginev1.ContextMode_CONTEXT_MODE_AUTO_MAX
	case "fixed":
		return enginev1.ContextMode_CONTEXT_MODE_FIXED
	default:
		return enginev1.ContextMode_CONTEXT_MODE_UNSPECIFIED
	}
}

func contextModeFromProto(value enginev1.ContextMode) string {
	switch value {
	case enginev1.ContextMode_CONTEXT_MODE_AUTO_MAX:
		return "auto_max"
	case enginev1.ContextMode_CONTEXT_MODE_FIXED:
		return "fixed"
	default:
		return ""
	}
}

func priorityToProto(value string) enginev1.Priority {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "low":
		return enginev1.Priority_PRIORITY_LOW
	case "normal":
		return enginev1.Priority_PRIORITY_NORMAL
	case "high":
		return enginev1.Priority_PRIORITY_HIGH
	case "pinned":
		return enginev1.Priority_PRIORITY_PINNED
	default:
		return enginev1.Priority_PRIORITY_UNSPECIFIED
	}
}

func priorityFromProto(value enginev1.Priority) string {
	switch value {
	case enginev1.Priority_PRIORITY_LOW:
		return "low"
	case enginev1.Priority_PRIORITY_NORMAL:
		return "normal"
	case enginev1.Priority_PRIORITY_HIGH:
		return "high"
	case enginev1.Priority_PRIORITY_PINNED:
		return "pinned"
	default:
		return ""
	}
}

func plannerPriorityToProto(value engineplanner.Priority) enginev1.Priority {
	return priorityToProto(string(value))
}

func kvCachePolicyToProto(value string) enginev1.KvCachePolicy {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case string(engineruntime.KVPolicyNative):
		return enginev1.KvCachePolicy_KV_CACHE_POLICY_NATIVE
	case string(engineruntime.KVPolicyPrefer4Bit):
		return enginev1.KvCachePolicy_KV_CACHE_POLICY_PREFER_4BIT
	default:
		return enginev1.KvCachePolicy_KV_CACHE_POLICY_UNSPECIFIED
	}
}

func kvCachePolicyFromProto(value enginev1.KvCachePolicy) string {
	switch value {
	case enginev1.KvCachePolicy_KV_CACHE_POLICY_NATIVE:
		return string(engineruntime.KVPolicyNative)
	case enginev1.KvCachePolicy_KV_CACHE_POLICY_PREFER_4BIT:
		return string(engineruntime.KVPolicyPrefer4Bit)
	default:
		return ""
	}
}

func kvCacheDtypeToProto(value engineplanner.KVCacheDType) enginev1.KvCacheDtype {
	switch value {
	case engineplanner.KVCacheQ4:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_Q4
	case engineplanner.KVCacheQ41:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_Q4_1
	case engineplanner.KVCacheIQ4NL:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_IQ4_NL
	case engineplanner.KVCacheQ50:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_Q5_0
	case engineplanner.KVCacheQ51:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_Q5_1
	case engineplanner.KVCacheQ8:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_Q8_0
	case engineplanner.KVCacheQ2K:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_Q2_K
	case engineplanner.KVCacheFP16:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_FP16
	case engineplanner.KVCacheBF16:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_BF16
	case engineplanner.KVCacheFP32:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_FP32
	default:
		return enginev1.KvCacheDtype_KV_CACHE_DTYPE_UNSPECIFIED
	}
}

func instanceStateToProto(value engineruntime.InstanceState) enginev1.InstanceState {
	switch value {
	case engineruntime.StateInstalling:
		return enginev1.InstanceState_INSTANCE_STATE_INSTALLING
	case engineruntime.StateQueued:
		return enginev1.InstanceState_INSTANCE_STATE_QUEUED
	case engineruntime.StateStarting:
		return enginev1.InstanceState_INSTANCE_STATE_STARTING
	case engineruntime.StateReady:
		return enginev1.InstanceState_INSTANCE_STATE_READY
	case engineruntime.StateDraining:
		return enginev1.InstanceState_INSTANCE_STATE_DRAINING
	case engineruntime.StateRestarting:
		return enginev1.InstanceState_INSTANCE_STATE_RESTARTING
	case engineruntime.StateStopped:
		return enginev1.InstanceState_INSTANCE_STATE_STOPPED
	case engineruntime.StateFailed:
		return enginev1.InstanceState_INSTANCE_STATE_FAILED
	case engineruntime.StateFailedRollback:
		return enginev1.InstanceState_INSTANCE_STATE_FAILED_ROLLBACK
	default:
		return enginev1.InstanceState_INSTANCE_STATE_UNSPECIFIED
	}
}

func operationStateToProto(value string) enginev1.OperationState {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "queued":
		return enginev1.OperationState_OPERATION_STATE_QUEUED
	case "running":
		return enginev1.OperationState_OPERATION_STATE_RUNNING
	case "completed":
		return enginev1.OperationState_OPERATION_STATE_COMPLETED
	case "failed":
		return enginev1.OperationState_OPERATION_STATE_FAILED
	case "cancelled":
		return enginev1.OperationState_OPERATION_STATE_CANCELLED
	default:
		return enginev1.OperationState_OPERATION_STATE_UNSPECIFIED
	}
}

func placementToProto(value Placement) enginev1.Placement {
	switch value {
	case PlacementGPU:
		return enginev1.Placement_PLACEMENT_GPU
	case PlacementRAM:
		return enginev1.Placement_PLACEMENT_RAM
	case PlacementHybrid:
		return enginev1.Placement_PLACEMENT_HYBRID
	default:
		return enginev1.Placement_PLACEMENT_UNSPECIFIED
	}
}

func guardStateToProto(value GuardState) enginev1.GuardState {
	switch value {
	case GuardNormal:
		return enginev1.GuardState_GUARD_STATE_NORMAL
	case GuardWarning:
		return enginev1.GuardState_GUARD_STATE_WARNING
	case GuardCritical:
		return enginev1.GuardState_GUARD_STATE_CRITICAL
	case GuardEmergency:
		return enginev1.GuardState_GUARD_STATE_EMERGENCY
	default:
		return enginev1.GuardState_GUARD_STATE_UNSPECIFIED
	}
}

func modelFormatToProto(value modelcatalog.Format) enginev1.ModelFormat {
	switch value {
	case modelcatalog.FormatGGUF:
		return enginev1.ModelFormat_MODEL_FORMAT_GGUF
	default:
		return enginev1.ModelFormat_MODEL_FORMAT_UNSPECIFIED
	}
}

func issueSeverityToProto(value modelcatalog.Severity) enginev1.IssueSeverity {
	switch value {
	case modelcatalog.SeverityWarning:
		return enginev1.IssueSeverity_ISSUE_SEVERITY_WARNING
	case modelcatalog.SeverityError:
		return enginev1.IssueSeverity_ISSUE_SEVERITY_ERROR
	default:
		return enginev1.IssueSeverity_ISSUE_SEVERITY_UNSPECIFIED
	}
}

func changeModeToProto(value engineruntime.ChangeMode) enginev1.ChangeMode {
	switch value {
	case engineruntime.ChangeLive:
		return enginev1.ChangeMode_CHANGE_MODE_LIVE
	case engineruntime.ChangeRestartRequired:
		return enginev1.ChangeMode_CHANGE_MODE_RESTART_REQUIRED
	default:
		return enginev1.ChangeMode_CHANGE_MODE_UNSPECIFIED
	}
}

func confidenceToProto(value engineplanner.Confidence) enginev1.Confidence {
	switch value {
	case engineplanner.ConfidenceMeasured:
		return enginev1.Confidence_CONFIDENCE_MEASURED
	case engineplanner.ConfidenceEstimated:
		return enginev1.Confidence_CONFIDENCE_ESTIMATED
	default:
		return enginev1.Confidence_CONFIDENCE_UNSPECIFIED
	}
}

// modelStatusToProto derives the same three-way status the HTTP response
// carried next to the flags it was derived from.
func modelStatusToProto(record modelcatalog.ModelRecord) enginev1.ModelStatus {
	switch {
	case record.Startable:
		return enginev1.ModelStatus_MODEL_STATUS_READY
	case record.Complete:
		return enginev1.ModelStatus_MODEL_STATUS_INVALID
	default:
		return enginev1.ModelStatus_MODEL_STATUS_INCOMPLETE
	}
}

func engineConfigToProto(config EngineConfig) *enginev1.EngineConfig {
	message := &enginev1.EngineConfig{
		Runtime:            runtimeKindToProto(config.Runtime),
		ContextMode:        contextModeToProto(config.ContextMode),
		MaxSequences:       int32(config.MaxSequences),
		Priority:           priorityToProto(config.Priority),
		KvCachePolicy:      kvCachePolicyToProto(config.KVCachePolicy),
		Autostart:          config.Autostart,
		GatewayAutostart:   config.GatewayAutostart,
		RestartOnCrash:     config.RestartOnCrash,
		RuntimeOptions:     structFromMap(config.RuntimeOptions),
		GenerationDefaults: structFromMap(config.GenerationDefaults),
	}
	if config.ContextTokens != nil {
		tokens := int32(*config.ContextTokens)
		message.ContextTokens = &tokens
	}
	if config.IdleTimeoutSeconds != nil {
		seconds := int32(*config.IdleTimeoutSeconds)
		message.IdleTimeoutSeconds = &seconds
	}
	if config.AllowFallback != nil {
		allow := *config.AllowFallback
		message.AllowFallback = &allow
	}
	return message
}

// engineConfigFromProto reads a config off the wire. Every field left unset
// lands as the Go zero value, which is exactly what normalizeConfig fills in,
// so an omitted field means "the engine default" here as it did over HTTP.
func engineConfigFromProto(message *enginev1.EngineConfig) EngineConfig {
	if message == nil {
		return normalizeConfig(EngineConfig{})
	}
	config := EngineConfig{
		Runtime:            runtimeKindFromProto(message.GetRuntime()),
		ContextMode:        contextModeFromProto(message.GetContextMode()),
		MaxSequences:       int(message.GetMaxSequences()),
		Priority:           priorityFromProto(message.GetPriority()),
		KVCachePolicy:      kvCachePolicyFromProto(message.GetKvCachePolicy()),
		Autostart:          message.GetAutostart(),
		GatewayAutostart:   message.GetGatewayAutostart(),
		RestartOnCrash:     message.GetRestartOnCrash(),
		RuntimeOptions:     mapFromStruct(message.GetRuntimeOptions()),
		GenerationDefaults: mapFromStruct(message.GetGenerationDefaults()),
	}
	if message.ContextTokens != nil {
		config.ContextTokens = intPointer(int(message.GetContextTokens()))
	}
	if message.IdleTimeoutSeconds != nil {
		config.IdleTimeoutSeconds = intPointer(int(message.GetIdleTimeoutSeconds()))
	}
	if message.AllowFallback != nil {
		allow := message.GetAllowFallback()
		config.AllowFallback = &allow
	}
	return normalizeConfig(config)
}

// mergeEngineConfigOverBase applies an incoming config to the one an instance
// already holds. The scalars replace, because every one of them arrives
// normalised; the two free-form maps merge key by key, because they are handed
// through to the runtime and to the sampler and a caller setting one option
// does not mean to drop the rest.
func mergeEngineConfigOverBase(base EngineConfig, incoming EngineConfig) EngineConfig {
	merged := incoming
	merged.RuntimeOptions = mergeJSONMaps(base.RuntimeOptions, incoming.RuntimeOptions)
	merged.GenerationDefaults = mergeJSONMaps(base.GenerationDefaults, incoming.GenerationDefaults)
	return normalizeConfig(merged)
}

func mergeJSONMaps(base, patch map[string]interface{}) map[string]interface{} {
	merged := cloneJSONMap(base)
	for key, value := range patch {
		merged[key] = value
	}
	return merged
}

func modelRecordToProto(record modelcatalog.ModelRecord) *enginev1.ModelRecord {
	candidates := make([]enginev1.RuntimeKind, 0, len(record.RuntimeCandidates))
	for _, candidate := range record.RuntimeCandidates {
		candidates = append(candidates, runtimeKindToProto(candidate))
	}
	issues := make([]*enginev1.ValidationIssue, 0, len(record.Issues))
	for _, issue := range record.Issues {
		issues = append(issues, &enginev1.ValidationIssue{
			Code:        issue.Code,
			Severity:    issueSeverityToProto(issue.Severity),
			Message:     issue.Message,
			Remediation: issue.Remediation,
		})
	}
	return &enginev1.ModelRecord{
		Id:                record.ID,
		Fingerprint:       record.Fingerprint,
		Name:              record.Name,
		RelativePath:      record.RelativePath,
		Format:            modelFormatToProto(record.Format),
		Complete:          record.Complete,
		Startable:         record.Startable,
		SizeBytes:         record.SizeBytes,
		Files:             append([]string{}, record.Files...),
		RuntimeCandidates: candidates,
		Issues:            issues,
		Status:            modelStatusToProto(record),
		Metadata: &enginev1.ModelMetadata{
			Name:                 record.Metadata.Name,
			Architecture:         record.Metadata.Architecture,
			Layers:               int32(record.Metadata.Layers),
			AttentionHeads:       int32(record.Metadata.AttentionHeads),
			KvHeads:              int32(record.Metadata.KVHeads),
			HeadDimension:        int32(record.Metadata.HeadDimension),
			EmbeddingDimension:   int32(record.Metadata.EmbeddingDimension),
			ContextLength:        int32(record.Metadata.ContextLength),
			SlidingWindow:        int32(record.Metadata.SlidingWindow),
			ParameterCount:       record.Metadata.ParameterCount,
			Quantization:         record.Metadata.Quantization,
			StoredTensorDataType: record.Metadata.StoredTensorDataType,
			ExpertWeightBytes:    record.Metadata.ExpertWeightBytes,
			ExpertLayers:         int32(record.Metadata.ExpertLayers),
		},
	}
}

func modelRecordsToProto(records []modelcatalog.ModelRecord) []*enginev1.ModelRecord {
	models := make([]*enginev1.ModelRecord, 0, len(records))
	for _, record := range records {
		models = append(models, modelRecordToProto(record))
	}
	return models
}

func hardwareSnapshotToProto(snapshot hardware.Snapshot) *enginev1.HardwareSnapshot {
	gpus := make([]*hardwarev1.EngineGpu, 0, len(snapshot.GPUs))
	for _, gpu := range snapshot.GPUs {
		gpus = append(gpus, &hardwarev1.EngineGpu{
			Id:                       gpu.ID,
			Index:                    int32(gpu.Index),
			Name:                     gpu.Name,
			Vendor:                   gpu.Vendor,
			Backend:                  gpu.Backend,
			VramTotalBytes:           gpu.VRAMTotalBytes,
			VramUsedBytes:            gpu.VRAMUsedBytes,
			VramFreeBytes:            gpu.VRAMFreeBytes,
			VramTelemetryUnavailable: gpu.VRAMTelemetryUnavailable,
			SharedMemory:             gpu.SharedMemory,
			ComputeCapability:        gpu.ComputeCapability,
			DriverVersion:            gpu.DriverVersion,
			MemoryBandwidthGbps:      gpu.MemoryBandwidth,
		})
	}
	return &enginev1.HardwareSnapshot{
		Os:                     snapshot.OS,
		Arch:                   snapshot.Arch,
		CpuName:                snapshot.CPUName,
		CpuCores:               int32(snapshot.CPUCores),
		RamTotalBytes:          snapshot.RAMTotalBytes,
		RamAvailableBytes:      snapshot.RAMAvailableBytes,
		DiskFreeBytes:          snapshot.DiskFreeBytes,
		Gpus:                   gpus,
		GpuTelemetryIncomplete: snapshot.GPUTelemetryIncomplete,
		CapturedAt:             timestampOrNil(snapshot.CapturedAt),
		Source:                 snapshot.Source,
	}
}

func runtimeCapabilityToProto(capability engineruntime.RuntimeCapability) *enginev1.RuntimeCapability {
	fields := make(map[string]enginev1.ChangeMode, len(capability.ConfigFields))
	for name, mode := range capability.ConfigFields {
		fields[name] = changeModeToProto(mode)
	}
	return &enginev1.RuntimeCapability{
		Kind:          runtimeKindToProto(string(capability.Kind)),
		Version:       capability.Version,
		Installed:     capability.Installed,
		Healthy:       capability.Healthy,
		Environment:   capability.Environment,
		GpuBackends:   append([]string{}, capability.GPUBackends...),
		KvCacheModes:  append([]string{}, capability.KVCaches...),
		ConfigFields:  fields,
		ProbeError:    capability.ProbeError,
		LastProbedAt:  timestampPointerOrNil(capability.LastProbedAt),
		Status:        capability.Status,
		StatusMessage: capability.StatusMessage,
		Progress:      capability.Progress,
		ErrorCode:     capability.ErrorCode,
	}
}

func runtimeCapabilitiesToProto(capabilities []engineruntime.RuntimeCapability) []*enginev1.RuntimeCapability {
	runtimes := make([]*enginev1.RuntimeCapability, 0, len(capabilities))
	for _, capability := range capabilities {
		runtimes = append(runtimes, runtimeCapabilityToProto(capability))
	}
	return runtimes
}

func memoryAllocationToProto(allocation engineplanner.MemoryAllocation) *enginev1.MemoryAllocation {
	gpuBytes := make(map[string]int64, len(allocation.GPUBytes))
	for id, bytes := range allocation.GPUBytes {
		gpuBytes[id] = bytes
	}
	return &enginev1.MemoryAllocation{RamBytes: allocation.RAMBytes, GpuBytes: gpuBytes}
}

func resourceBreakdownToProto(breakdown engineplanner.ResourceBreakdown) *enginev1.ResourceBreakdown {
	return &enginev1.ResourceBreakdown{
		Weights: memoryAllocationToProto(breakdown.Weights),
		KvCache: memoryAllocationToProto(breakdown.KVCache),
		Runtime: memoryAllocationToProto(breakdown.Runtime),
		Reserve: memoryAllocationToProto(breakdown.Reserve),
		Total:   memoryAllocationToProto(breakdown.Total),
	}
}

func preflightReportToProto(report PreflightReport) *enginev1.PreflightReport {
	checks := make([]*enginev1.PreflightCheck, 0, len(report.Checks))
	for _, check := range report.Checks {
		checks = append(checks, &enginev1.PreflightCheck{
			Id:     check.ID,
			State:  check.State,
			Label:  check.Label,
			Detail: check.Detail,
		})
	}
	return &enginev1.PreflightReport{
		HardwareSnapshotId: report.HardwareSnapshotID,
		ModelFingerprint:   report.ModelFingerprint,
		MetadataConfidence: report.MetadataConfidence,
		Checks:             checks,
	}
}

func contextPlanToProto(plan *ContextPlanView) *enginev1.ContextPlan {
	if plan == nil {
		return nil
	}
	message := &enginev1.ContextPlan{
		ModelContextLimitTokens:  int32(plan.ModelContextLimitTokens),
		GpuOnlyMaxContextTokens:  int32(plan.GPUOnlyMaxContextTokens),
		HybridMaxContextTokens:   int32(plan.HybridMaxContextTokens),
		EffectiveContextTokens:   int32(plan.EffectiveContextTokens),
		KvBytesPerTokenAtStart:   plan.KVBytesPerTokenAtStart,
		MaxSequences:             int32(plan.MaxSequences),
		KvCacheDtype:             kvCacheDtypeToProto(plan.KVCacheDType),
		Priority:                 plannerPriorityToProto(plan.Priority),
		Pinned:                   plan.Pinned,
		RestartRequired:          plan.RestartRequired,
		UsesRam:                  plan.UsesRAM,
		Memory:                   resourceBreakdownToProto(plan.Memory),
		Confidence:               confidenceToProto(plan.Confidence),
		Warnings:                 append([]string{}, plan.Warnings...),
		AffectedRestartInstances: append([]string{}, plan.AffectedRestartInstances...),
		Preflight:                preflightReportToProto(plan.Preflight),
	}
	if plan.RAMRequiredAfterTokens != nil {
		tokens := int32(*plan.RAMRequiredAfterTokens)
		message.RamRequiredAfterTokens = &tokens
	}
	return message
}

func suggestedFixToProto(fix *SuggestedFix) *enginev1.SuggestedFix {
	if fix == nil {
		return nil
	}
	return &enginev1.SuggestedFix{Action: fix.Action, Label: fix.Label}
}

func resourceConflictToProto(conflict *ResourceConflictError) *enginev1.ResourceConflict {
	if conflict == nil {
		return nil
	}
	return &enginev1.ResourceConflict{
		Resource:       conflict.Resource,
		RequiredBytes:  conflict.RequiredBytes,
		AvailableBytes: conflict.AvailableBytes,
		ReserveBytes:   conflict.ReserveBytes,
		TotalBytes:     conflict.TotalBytes,
		Reason:         conflict.Reason,
	}
}

func plannerConflictToProto(conflict *engineplanner.ConflictError) *enginev1.ResourceConflict {
	if conflict == nil {
		return nil
	}
	return &enginev1.ResourceConflict{
		InstanceId:     conflict.InstanceID,
		Resource:       conflict.Resource,
		RequiredBytes:  conflict.RequiredBytes,
		AvailableBytes: conflict.AvailableBytes,
		Reason:         conflict.Reason,
	}
}

func instanceToProto(instance *EngineInstance) *enginev1.EngineInstance {
	if instance == nil {
		return nil
	}
	fallbacks := make([]*enginev1.Fallback, 0, len(instance.Fallbacks))
	for _, fallback := range instance.Fallbacks {
		fallbacks = append(fallbacks, &enginev1.Fallback{
			Setting: fallback.Setting,
			From:    fallback.From,
			To:      fallback.To,
			Reason:  fallback.Reason,
		})
	}
	return &enginev1.EngineInstance{
		Id:                    instance.ID,
		State:                 instanceStateToProto(instance.State),
		ModelId:               instance.ModelID,
		ServedModelName:       instance.ServedModelName,
		RequestedConfig:       engineConfigToProto(instance.RequestedConfig),
		EffectiveConfig:       engineConfigToProto(instance.EffectiveConfig),
		Plan:                  contextPlanToProto(instance.Plan),
		Runtime:               runtimeKindToProto(string(instance.Runtime)),
		Priority:              priorityToProto(instance.Priority),
		Pinned:                instance.Pinned,
		Autostart:             instance.Autostart,
		GatewayAutostart:      instance.GatewayAutostart,
		RestartOnCrash:        instance.RestartOnCrash,
		IdleTimeoutSeconds:    int32PointerOrNil(instance.IdleTimeoutSeconds),
		ShowInChatPicker:      instance.ShowInChatPicker,
		Placement:             placementToProto(instance.Placement),
		ActiveRequests:        int32(instance.ActiveRequests),
		LastUsedAt:            timestampPointerOrNil(instance.LastUsedAt),
		IdleExpiresAt:         timestampPointerOrNil(instance.IdleExpiresAt),
		GuardState:            guardStateToProto(instance.GuardState),
		RestartRequiredFields: append([]string{}, instance.RestartRequiredFields...),
		Fallbacks:             fallbacks,
		Error:                 instance.Error,
		ErrorSummary:          instance.ErrorSummary,
		ErrorCode:             instance.ErrorCode,
		SuggestedFix:          suggestedFixToProto(instance.SuggestedFix),
		Phase:                 instance.Phase,
		DetailMessage:         instance.DetailMessage,
		Progress:              instance.Progress,
		EndpointName:          instance.EndpointName,
		PlanRevision:          instance.PlanRevision,
		CreatedAt:             timestampOrNil(instance.CreatedAt),
		UpdatedAt:             timestampOrNil(instance.UpdatedAt),
	}
}

func instancesToProto(instances []*EngineInstance) []*enginev1.EngineInstance {
	result := make([]*enginev1.EngineInstance, 0, len(instances))
	for _, instance := range instances {
		result = append(result, instanceToProto(instance))
	}
	return result
}

func operationToProto(operation *EngineOperation) *enginev1.EngineOperation {
	if operation == nil {
		return nil
	}
	return &enginev1.EngineOperation{
		Id:                 operation.ID,
		Type:               operation.Type,
		State:              operationStateToProto(operation.State),
		InstanceId:         operation.InstanceID,
		QueuePosition:      int32(operation.QueuePosition),
		Progress:           operation.Progress,
		Message:            operation.Message,
		DetailMessage:      operation.DetailMessage,
		Phase:              operation.Phase,
		Error:              operation.Error,
		ErrorSummary:       operation.ErrorSummary,
		ErrorCode:          operation.ErrorCode,
		SuggestedFix:       suggestedFixToProto(operation.SuggestedFix),
		ResourceConflict:   resourceConflictToProto(operation.ResourceConflict),
		CreatedAt:          timestampOrNil(operation.CreatedAt),
		UpdatedAt:          timestampOrNil(operation.UpdatedAt),
		FinishedAt:         timestampPointerOrNil(operation.FinishedAt),
		EvictedInstanceIds: append([]string{}, operation.EvictedInstanceIDs...),
	}
}

func installJobToProto(job engineruntime.InstallJobSnapshot) *enginev1.RuntimeInstallJob {
	return &enginev1.RuntimeInstallJob{
		Id:            job.ID,
		BuildDigest:   job.BuildDigest,
		Runtime:       runtimeKindToProto(string(job.Runtime)),
		Version:       job.Version,
		Variant:       string(job.Variant),
		InstallPath:   job.InstallPath,
		ServerPath:    job.ServerPath,
		Status:        string(job.Status),
		Phase:         string(job.Phase),
		Progress:      job.Progress,
		Message:       job.Message,
		DetailMessage: job.DetailMessage,
		Log:           job.Log,
		Error:         job.Error,
		ErrorSummary:  job.ErrorSummary,
		ErrorCode:     job.ErrorCode,
		CreatedAt:     timestampOrNil(job.CreatedAt),
		UpdatedAt:     timestampOrNil(job.UpdatedAt),
		FinishedAt:    timestampPointerOrNil(job.FinishedAt),
	}
}

func installJobsToProto(jobs []engineruntime.InstallJobSnapshot) []*enginev1.RuntimeInstallJob {
	result := make([]*enginev1.RuntimeInstallJob, 0, len(jobs))
	for _, job := range jobs {
		result = append(result, installJobToProto(job))
	}
	return result
}

func gatewayKeyToProto(key engineKeyPublic) *enginev1.GatewayKey {
	return &enginev1.GatewayKey{
		Id:          key.ID,
		Name:        key.Name,
		InstanceIds: append([]string{}, key.InstanceIDs...),
		CreatedAt:   timestampOrNil(key.CreatedAt),
		LastUsedAt:  timestampPointerOrNil(key.LastUsedAt),
		RevokedAt:   timestampPointerOrNil(key.RevokedAt),
	}
}

func nowTimestamp() *timestamppb.Timestamp {
	return timestamppb.New(time.Now().UTC())
}

func simulatedModelsToProto(models []simulatedModel) []*enginev1.SimulatedModel {
	result := make([]*enginev1.SimulatedModel, 0, len(models))
	for _, model := range models {
		result = append(result, &enginev1.SimulatedModel{
			Model:                  model.Model,
			Fits:                   model.Fits,
			EffectiveContextTokens: int32(model.EffectiveContextTokens),
			Placement:              placementToProto(model.Placement),
			Memory:                 memoryAllocationToProto(model.Memory),
			Warnings:               append([]string{}, model.Warnings...),
			Reason:                 model.Reason,
		})
	}
	return result
}

func simulatedHostToProto(host simulatedHost) *enginev1.SimulatedHost {
	gpus := make([]*enginev1.SimulatedGpuBudget, 0, len(host.GPUs))
	for _, gpu := range host.GPUs {
		gpus = append(gpus, &enginev1.SimulatedGpuBudget{
			Id:             gpu.ID,
			Name:           gpu.Name,
			VramTotalBytes: gpu.VRAMTotalBytes,
			VramFreeBytes:  gpu.VRAMFreeBytes,
			PlannedBytes:   gpu.PlannedBytes,
		})
	}
	return &enginev1.SimulatedHost{
		RamTotalBytes:     host.RAMTotalBytes,
		RamAvailableBytes: host.RAMAvailableBytes,
		RamReserveBytes:   host.RAMReserveBytes,
		Gpus:              gpus,
	}
}

// engineEventToProto maps one event of the hub onto the streaming wire. The
// free-form kinds without a dedicated case become a GenericEvent, which the
// client is expected to ignore rather than choke on - the escape hatch the
// old feed had by carrying arbitrary JSON.
func engineEventToProto(m *EngineModule, event engineEvent) *enginev1.StreamEventsResponse {
	response := &enginev1.StreamEventsResponse{Timestamp: nowTimestamp()}
	switch event.Type {
	case "instance_created":
		switch value := event.Data.(type) {
		case *EngineInstance:
			if value != nil {
				response.Event = &enginev1.StreamEventsResponse_InstanceCreated{InstanceCreated: instanceToProto(value)}
				return response
			}
		case *enginev1.EngineInstance:
			// A node's instance arrives already in wire form, qualified with
			// the node it came from. It is passed through rather than
			// converted back into a local shape it never had.
			if value != nil {
				response.Event = &enginev1.StreamEventsResponse_InstanceCreated{InstanceCreated: value}
				return response
			}
		}
	case "instance_changed":
		switch value := event.Data.(type) {
		case *EngineInstance:
			if value != nil {
				response.Event = &enginev1.StreamEventsResponse_InstanceChanged{InstanceChanged: instanceToProto(value)}
				return response
			}
		case EngineInstance:
			response.Event = &enginev1.StreamEventsResponse_InstanceChanged{InstanceChanged: instanceToProto(&value)}
			return response
		case *enginev1.EngineInstance:
			if value != nil {
				response.Event = &enginev1.StreamEventsResponse_InstanceChanged{InstanceChanged: value}
				return response
			}
		}
	case "instance_deleted":
		if id := instanceIDString(event.Data, "id"); id != "" {
			response.Event = &enginev1.StreamEventsResponse_InstanceDeleted{InstanceDeleted: &enginev1.InstanceDeleted{InstanceId: id}}
			return response
		}
	case "operation":
		if operation, ok := event.Data.(*EngineOperation); ok && operation != nil {
			response.Event = &enginev1.StreamEventsResponse_Operation{Operation: operationToProto(operation)}
			return response
		}
	case "models_rescanned":
		message := &enginev1.ModelsRescanned{}
		switch data := event.Data.(type) {
		case map[string]interface{}:
			if count, ok := data["count"].(float64); ok {
				message.Count = int32(count)
			}
			if reason, ok := data["reason"].(string); ok {
				message.Reason = reason
			}
		case map[string]string:
			message.Reason = data["reason"]
		}
		response.Event = &enginev1.StreamEventsResponse_ModelsRescanned{ModelsRescanned: message}
		return response
	case "model_deleted":
		message := &enginev1.ModelDeleted{ModelId: instanceIDString(event.Data, "id"), Name: instanceIDString(event.Data, "name")}
		response.Event = &enginev1.StreamEventsResponse_ModelDeleted{ModelDeleted: message}
		return response
	case "guard_state":
		state := guardStateFromProtoValue(event.Data)
		response.Event = &enginev1.StreamEventsResponse_GuardState{GuardState: &enginev1.GuardStateChanged{State: state}}
		return response
	default:
		generic := &enginev1.GenericEvent{Type: event.Type, Data: structFromMap(eventDataMap(event.Data))}
		response.Event = &enginev1.StreamEventsResponse_Generic{Generic: generic}
		return response
	}
	return nil
}

func instanceIDString(data interface{}, key string) string {
	switch value := data.(type) {
	case map[string]string:
		return value[key]
	case map[string]interface{}:
		if item, ok := value[key].(string); ok {
			return item
		}
	}
	return ""
}

func eventDataMap(data interface{}) map[string]interface{} {
	switch value := data.(type) {
	case map[string]string:
		result := make(map[string]interface{}, len(value))
		for key, item := range value {
			result[key] = item
		}
		return result
	case map[string]interface{}:
		return value
	}
	return nil
}

// guardStateFromProtoValue reads GuardState out of the payload the guard
// publishes ("state" is the GuardState type itself, which is a string).
func guardStateFromProtoValue(data interface{}) enginev1.GuardState {
	switch value := data.(type) {
	case map[string]interface{}:
		if state, ok := value["state"].(GuardState); ok {
			return guardStateToProto(state)
		}
		if state, ok := value["state"].(string); ok {
			return guardStateToProto(GuardState(state))
		}
	case GuardState:
		return guardStateToProto(value)
	case string:
		return guardStateToProto(GuardState(value))
	}
	return enginev1.GuardState_GUARD_STATE_UNSPECIFIED
}

func int32PointerOrNil(value *int) *int32 {
	if value == nil {
		return nil
	}
	converted := int32(*value)
	return &converted
}

func quantizationTypesToProto(types []engineruntime.QuantizationType) []*enginev1.QuantizationType {
	result := make([]*enginev1.QuantizationType, 0, len(types))
	for _, entry := range types {
		result = append(result, &enginev1.QuantizationType{
			Name:               entry.Name,
			Description:        entry.Description,
			SizeGibAtReference: entry.SizeGiBAtReference,
			PerplexityDelta:    entry.PerplexityDelta,
			ReferenceModel:     entry.ReferenceModel,
			BitsPerWeight:      entry.BitsPerWeight,
			Alias:              entry.Alias,
		})
	}
	return result
}

func quantizeRequestFromProto(message *enginev1.QuantizationRequest) QuantizeRequest {
	if message == nil {
		return QuantizeRequest{}
	}
	return QuantizeRequest{
		SourceModelID:     strings.TrimSpace(message.GetSourceModelId()),
		TargetType:        strings.TrimSpace(message.GetTargetType()),
		TargetName:        strings.TrimSpace(message.GetTargetName()),
		AllowRequantize:   message.GetAllowRequantize(),
		LeaveOutputTensor: message.GetLeaveOutputTensor(),
		Threads:           int(message.GetThreads()),
	}
}

func quantizePreflightToProto(report QuantizePreflight) *enginev1.QuantizationPreflight {
	return &enginev1.QuantizationPreflight{
		SourceModelId:       report.SourceModelID,
		SourceName:          report.SourceName,
		SourceQuantization:  report.SourceQuantization,
		SourceBytes:         report.SourceBytes,
		TargetType:          report.TargetType,
		TargetName:          report.TargetName,
		TargetRelativePath:  report.TargetRelativePath,
		EstimatedBytes:      report.EstimatedBytes,
		FreeDiskBytes:       report.FreeDiskBytes,
		RequiredDiskBytes:   report.RequiredDiskBytes,
		SourceBitsPerWeight: report.SourceBitsPerWeight,
		TargetBitsPerWeight: report.TargetBitsPerWeight,
		IsRequantization:    report.IsRequantization,
		Feasible:            report.Feasible,
		Blockers:            append([]string{}, report.Blockers...),
		Warnings:            append([]string{}, report.Warnings...),
	}
}
