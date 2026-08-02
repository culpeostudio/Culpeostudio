// Package engineruntime installs and supervises the local inference runtimes and
// reports the disk space their installation needs.
package engineruntime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"strings"
)

const (
	PortPlaceholder     = "{port}"
	InstancePlaceholder = "{instance_id}"
)

type AdapterPaths struct {
	Python             string
	TransformersWorker string
}

type AdapterCommand struct {
	Argv           []string          `json:"-"`
	Env            map[string]string `json:"-"`
	HealthPath     string            `json:"health_path"`
	HealthHeaders  map[string]string `json:"-"`
	InternalAPIKey string            `json:"-"`
	Effective      EffectiveConfig   `json:"effective_config"`
}

func (c AdapterCommand) ProcessSpec(instanceID string) ProcessSpec {
	return ProcessSpec{
		InstanceID:    strings.Clone(instanceID),
		Argv:          replaceInstance(c.Argv, instanceID),
		Environment:   cloneStringMap(c.Env),
		HealthPath:    c.HealthPath,
		HealthHeaders: cloneStringMap(c.HealthHeaders),
	}
}

func DefaultCapability(kind RuntimeKind) RuntimeCapability {
	fields := map[string]ChangeMode{
		"context_length":    ChangeRestartRequired,
		"max_sequences":     ChangeRestartRequired,
		"kv_cache_dtype":    ChangeRestartRequired,
		"gpu_ids":           ChangeRestartRequired,
		"offload":           ChangeRestartRequired,
		"priority":          ChangeRestartRequired,
		"trust_remote_code": ChangeRestartRequired,
		"sampling_defaults": ChangeLive,
		"autostart":         ChangeLive,
	}
	capability := RuntimeCapability{Kind: kind, ConfigFields: fields}
	switch kind {
	case RuntimeLlamaCPP:
		fields["gpu_layers"] = ChangeRestartRequired
		fields["threads"] = ChangeRestartRequired
		fields["tensor_parallelism"] = ChangeRestartRequired
		capability.Version = LlamaCPPVersion
		capability.KVCaches = []string{"q4_0", "f16"}
	case RuntimeTransformers:
		capability.Version = TransformersVersion
		capability.KVCaches = []string{"quanto_4bit", "offloaded", "native"}
	case RuntimeVLLM:
		fields["tensor_parallelism"] = ChangeRestartRequired
		capability.Version = VLLMVersion
		capability.KVCaches = []string{"turboquant_4bit_nc", "fp8", "auto"}
	}
	return capability
}

func BuildAdapterCommand(capability RuntimeCapability, requested RequestedConfig, paths AdapterPaths) (AdapterCommand, error) {
	if requested.Runtime == "" {
		requested.Runtime = capability.Kind
	}
	if capability.Kind == "" {
		capability = DefaultCapability(requested.Runtime)
	}
	if requested.Runtime != capability.Kind {
		return AdapterCommand{}, fmt.Errorf("requested runtime %q does not match capability %q", requested.Runtime, capability.Kind)
	}
	if strings.TrimSpace(requested.ModelPath) == "" {
		return AdapterCommand{}, errors.New("model path is required")
	}
	if strings.TrimSpace(paths.Python) == "" {
		return AdapterCommand{}, errors.New("runtime Python executable is required")
	}
	if requested.ContextLength != nil && *requested.ContextLength < 0 {
		return AdapterCommand{}, errors.New("context length may be zero (explicit backend default) but not negative")
	}
	for _, limit := range requested.GPUMemoryBytes {
		if limit <= 0 {
			return AdapterCommand{}, errors.New("GPU memory limits must be positive byte values")
		}
	}
	if requested.CPUMemoryBytes != nil && *requested.CPUMemoryBytes <= 0 {
		return AdapterCommand{}, errors.New("CPU memory limit must be a positive byte value")
	}
	if requested.GPUMemoryUtilization != nil && (*requested.GPUMemoryUtilization <= 0 || *requested.GPUMemoryUtilization > 1) {
		return AdapterCommand{}, errors.New("GPU memory utilization must be greater than zero and at most one")
	}

	if capability.KVCaches == nil {
		capability.KVCaches = DefaultCapability(requested.Runtime).KVCaches
	}
	cache, fallbacks, err := resolveKVCache(capability, requested)
	if err != nil {
		return AdapterCommand{}, err
	}
	effective := EffectiveConfig{
		Runtime:              requested.Runtime,
		ModelPath:            requested.ModelPath,
		ContextLength:        cloneInt(requested.ContextLength),
		GPULayers:            cloneInt(requested.GPULayers),
		Threads:              cloneInt(requested.Threads),
		TensorParallelism:    cloneInt(requested.TensorParallelism),
		MaxSequences:         cloneInt(requested.MaxSequences),
		KVCacheDType:         cache,
		TrustRemoteCode:      requested.TrustRemoteCode,
		CPUOffloadGB:         cloneFloat(requested.CPUOffloadGB),
		GPUMemoryBytes:       append([]int64(nil), requested.GPUMemoryBytes...),
		GPUMemoryUtilization: cloneFloat(requested.GPUMemoryUtilization),
		CPUMemoryBytes:       cloneInt64(requested.CPUMemoryBytes),
		Fallbacks:            fallbacks,
	}
	internalAPIKey, err := randomSecret(32)
	if err != nil {
		return AdapterCommand{}, fmt.Errorf("create internal worker credential: %w", err)
	}

	command := AdapterCommand{
		HealthPath:     runtimeHealthPath(requested.Runtime),
		InternalAPIKey: internalAPIKey,
		HealthHeaders:  map[string]string{"Authorization": "Bearer " + internalAPIKey},
		Effective:      effective,
		Env: map[string]string{
			"HF_HUB_OFFLINE":         "1",
			"TRANSFORMERS_OFFLINE":   "1",
			"TOKENIZERS_PARALLELISM": "false",
		},
	}
	switch requested.Runtime {
	case RuntimeLlamaCPP:
		command.Argv = llamaCPPArgv(paths.Python, internalAPIKey, effective)
	case RuntimeTransformers:
		if strings.TrimSpace(paths.TransformersWorker) == "" {
			return AdapterCommand{}, errors.New("transformers worker path is required")
		}
		command.Argv = transformersArgv(paths.Python, paths.TransformersWorker, internalAPIKey, effective)
	case RuntimeVLLM:
		command.Argv = vllmArgv(paths.Python, internalAPIKey, effective)
	default:
		return AdapterCommand{}, fmt.Errorf("unsupported runtime %q", requested.Runtime)
	}
	return command, nil
}

func runtimeHealthPath(kind RuntimeKind) string {

	if kind == RuntimeLlamaCPP || kind == RuntimeVLLM {
		return "/v1/models"
	}
	return "/health"
}

func resolveKVCache(capability RuntimeCapability, requested RequestedConfig) (string, []Fallback, error) {
	candidates := nativeCacheCandidates(requested.Runtime, requested.KVPolicy)
	wanted := candidates[0]
	if requested.KVCacheDType != nil {
		wanted = canonicalKVCacheDType(requested.Runtime, *requested.KVCacheDType)
		if wanted == "" {
			return "", nil, errors.New("explicit KV cache dtype may not be empty")
		}
		candidates = explicitCacheCandidates(requested.Runtime, wanted)
	}
	if supports(capability.KVCaches, wanted) {
		return wanted, nil, nil
	}
	if !requested.fallbackAllowed() {
		return "", nil, fmt.Errorf("KV cache mode %q is unavailable for %s and fallback is disabled", wanted, requested.Runtime)
	}
	for _, candidate := range candidates[1:] {
		if supports(capability.KVCaches, candidate) {
			return candidate, []Fallback{{
				Setting: "kv_cache_dtype",
				From:    wanted,
				To:      candidate,
				Reason:  "requested KV-cache mode was not confirmed by the runtime smoke test",
			}}, nil
		}
	}
	return "", nil, fmt.Errorf("runtime %s has no supported KV cache mode", requested.Runtime)
}

func canonicalKVCacheDType(kind RuntimeKind, value string) string {
	value = strings.TrimSpace(value)
	switch strings.ToLower(value) {
	case "q4", "q4_0", "quanto_4bit", "turboquant_4bit_nc":

		switch kind {
		case RuntimeLlamaCPP:
			return "q4_0"
		case RuntimeTransformers:
			return "quanto_4bit"
		case RuntimeVLLM:
			return "turboquant_4bit_nc"
		}
	}
	return value
}

func explicitCacheCandidates(kind RuntimeKind, wanted string) []string {
	preferred := nativeCacheCandidates(kind, KVPolicyPrefer4Bit)
	for index, candidate := range preferred {
		if strings.EqualFold(candidate, wanted) {
			return append([]string(nil), preferred[index:]...)
		}
	}
	result := []string{wanted}
	for _, candidate := range nativeCacheCandidates(kind, KVPolicyNative) {
		if !strings.EqualFold(candidate, wanted) {
			result = append(result, candidate)
		}
	}
	return result
}

func nativeCacheCandidates(kind RuntimeKind, policy KVPolicy) []string {
	prefer4 := policy == "" || policy == KVPolicyPrefer4Bit
	switch kind {
	case RuntimeLlamaCPP:
		if prefer4 {
			return []string{"q4_0", "f16"}
		}
		return []string{"f16"}
	case RuntimeTransformers:
		if prefer4 {
			return []string{"quanto_4bit", "offloaded", "native"}
		}
		return []string{"native"}
	case RuntimeVLLM:
		if prefer4 {
			return []string{"turboquant_4bit_nc", "fp8", "auto"}
		}
		return []string{"auto"}
	default:
		return []string{"native"}
	}
}

func supports(values []string, candidate string) bool {
	for _, value := range values {
		if strings.EqualFold(value, candidate) {
			return true
		}
	}
	return false
}

func llamaCPPArgv(python, internalAPIKey string, cfg EffectiveConfig) []string {
	argv := []string{python, "-m", "llama_cpp.server", "--model", cfg.ModelPath, "--model_alias", InstancePlaceholder, "--host", "127.0.0.1", "--port", PortPlaceholder, "--api_key", internalAPIKey}
	argv = appendIntFlag(argv, "--n_ctx", cfg.ContextLength)
	argv = appendIntFlag(argv, "--n_gpu_layers", cfg.GPULayers)
	argv = appendIntFlag(argv, "--n_threads", cfg.Threads)
	if cfg.KVCacheDType != "" {

		cacheType := llamaCPPTypeCode(cfg.KVCacheDType)
		argv = append(argv, "--type_k", cacheType, "--type_v", cacheType)
		if strings.EqualFold(strings.TrimSpace(cfg.KVCacheDType), "q4_0") || strings.EqualFold(strings.TrimSpace(cfg.KVCacheDType), "q4") {

			argv = append(argv, "--flash_attn", "True")
		}
	}
	return argv
}

func llamaCPPTypeCode(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "f32", "fp32":
		return "0"
	case "f16", "fp16", "native", "auto":
		return "1"
	case "q4_0", "q4":
		return "2"
	case "q8_0", "q8":
		return "8"
	default:

		if _, err := strconv.Atoi(strings.TrimSpace(value)); err == nil {
			return strings.TrimSpace(value)
		}
		return value
	}
}

func transformersArgv(python, worker, internalAPIKey string, cfg EffectiveConfig) []string {
	argv := []string{python, worker, "--model", cfg.ModelPath, "--served-model-name", InstancePlaceholder, "--host", "127.0.0.1", "--port", PortPlaceholder, "--api-key", internalAPIKey, "--kv-cache", cfg.KVCacheDType}
	argv = appendIntFlag(argv, "--context-length", cfg.ContextLength)
	argv = appendIntFlag(argv, "--max-sequences", cfg.MaxSequences)
	for _, limit := range cfg.GPUMemoryBytes {
		argv = append(argv, "--gpu-max-memory-bytes", strconv.FormatInt(limit, 10))
	}
	if cfg.CPUMemoryBytes != nil {
		argv = append(argv, "--cpu-max-memory-bytes", strconv.FormatInt(*cfg.CPUMemoryBytes, 10))
	}
	if cfg.TrustRemoteCode {
		argv = append(argv, "--trust-remote-code")
	}
	return argv
}

func vllmArgv(python, internalAPIKey string, cfg EffectiveConfig) []string {
	argv := []string{python, "-m", "vllm.entrypoints.openai.api_server", "--model", cfg.ModelPath, "--served-model-name", InstancePlaceholder, "--host", "127.0.0.1", "--port", PortPlaceholder, "--api-key", internalAPIKey, "--kv-cache-dtype", cfg.KVCacheDType}
	argv = appendIntFlag(argv, "--max-model-len", cfg.ContextLength)
	argv = appendIntFlag(argv, "--tensor-parallel-size", cfg.TensorParallelism)
	argv = appendIntFlag(argv, "--max-num-seqs", cfg.MaxSequences)
	if cfg.CPUOffloadGB != nil && *cfg.CPUOffloadGB > 0 {
		argv = append(argv, "--cpu-offload-gb", strconv.FormatFloat(*cfg.CPUOffloadGB, 'f', 3, 64))
	}
	if cfg.GPUMemoryUtilization != nil {
		argv = append(argv, "--gpu-memory-utilization", strconv.FormatFloat(*cfg.GPUMemoryUtilization, 'f', 6, 64))
	}
	if cfg.TrustRemoteCode {
		argv = append(argv, "--trust-remote-code")
	}
	return argv
}

func appendIntFlag(argv []string, flag string, value *int) []string {
	if value == nil {
		return argv
	}
	return append(argv, flag, strconv.Itoa(*value))
}

func cloneInt(value *int) *int {
	if value == nil {
		return nil
	}
	cloned := *value
	return &cloned
}

func cloneFloat(value *float64) *float64 {
	if value == nil {
		return nil
	}
	cloned := *value
	return &cloned
}

func cloneInt64(value *int64) *int64 {
	if value == nil {
		return nil
	}
	cloned := *value
	return &cloned
}

func randomSecret(byteCount int) (string, error) {
	secret := make([]byte, byteCount)
	if _, err := rand.Read(secret); err != nil {
		return "", err
	}
	return hex.EncodeToString(secret), nil
}

func replaceInstance(argv []string, instanceID string) []string {
	result := make([]string, len(argv))
	for index, arg := range argv {
		result[index] = strings.ReplaceAll(arg, InstancePlaceholder, instanceID)
	}
	return result
}
