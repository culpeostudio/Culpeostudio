// Package engineruntime installs and supervises the local llama.cpp server and
// reports the disk space its installation needs.
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

// SupportedCacheTypes is what upstream llama-server accepts for --cache-type-k
// and --cache-type-v. It is only the fallback: the installer asks the binary
// itself (see ParseSupportedCacheTypes) and stores the answer, so a build that
// implements sub-4-bit caches can use them without a code change here.
//
// Notably absent from upstream are q2_k and q3_k. Anything outside the list the
// binary reports is rejected at argument parsing with "Unsupported cache type",
// which is why the planner must never budget for a type the build does not have.
func SupportedCacheTypes() []string {
	return []string{"q4_0", "q4_1", "iq4_nl", "q5_0", "q5_1", "q8_0", "f16", "bf16", "f32"}
}

// ParseSupportedCacheTypes reads the cache types out of `llama-server --help`,
// which prints them as an "allowed values:" line under --cache-type-k:
//
//	-ctk,  --cache-type-k TYPE              KV cache data type for K
//	                                        allowed values: f32, f16, bf16, q8_0, ...
//
// The draft-model flag (--cache-type-k-draft) prints its own list further down;
// only the main one counts. An empty result means the output did not look like
// this, and the caller should keep the static list rather than guess.
func ParseSupportedCacheTypes(help string) []string {
	lines := strings.Split(help, "\n")
	for index, line := range lines {
		if !strings.Contains(line, "--cache-type-k") || strings.Contains(line, "draft") {
			continue
		}
		// The values sit on a continuation line, before the next flag starts.
		for _, candidate := range lines[index+1:] {
			trimmed := strings.TrimSpace(candidate)
			if trimmed == "" || strings.HasPrefix(trimmed, "-") {
				break
			}
			_, values, found := strings.Cut(trimmed, "allowed values:")
			if !found {
				continue
			}
			result := []string{}
			for _, value := range strings.Split(values, ",") {
				if value = strings.TrimSpace(value); value != "" {
					result = append(result, value)
				}
			}
			if len(result) > 0 {
				return result
			}
		}
	}
	return nil
}

// ParseSupportedFlags reads every long option out of `llama-server --help`.
// The help text lists them as "-ot,   --override-tensor <pattern>" or plain
// "--swa-full", sometimes several to a line, and interleaves prose that also
// contains dashes; only tokens that begin a word and look like a flag count.
//
// The result is what an extra-args passthrough is validated against. An empty
// result means the output did not parse, and the caller should refuse to
// validate rather than assume every flag is fine.
func ParseSupportedFlags(help string) []string {
	seen := map[string]bool{}
	result := []string{}
	for _, field := range strings.FieldsFunc(help, func(r rune) bool {
		return r == ' ' || r == '\t' || r == '\n' || r == '\r' || r == ',' || r == '='
	}) {
		if !strings.HasPrefix(field, "--") || len(field) < 4 {
			continue
		}
		flag := strings.TrimRight(field, ".:;)")
		if !validFlagSpelling(flag) || seen[flag] {
			continue
		}
		seen[flag] = true
		result = append(result, flag)
	}
	return result
}

// validFlagSpelling keeps prose like "--" or "--(more" out of the flag list.
func validFlagSpelling(flag string) bool {
	body := strings.TrimPrefix(flag, "--")
	if body == "" || !(body[0] >= 'a' && body[0] <= 'z') {
		return false
	}
	for index := 0; index < len(body); index++ {
		char := body[index]
		switch {
		case char >= 'a' && char <= 'z', char >= '0' && char <= '9', char == '-':
		default:
			return false
		}
	}
	return !strings.HasSuffix(body, "-")
}

// reservedFlags are the ones the engine owns. Letting a caller pass them again
// through extra args would either contradict the plan the memory budget was
// built from or unbind the worker from loopback.
var reservedFlags = map[string]bool{
	"--model": true, "--alias": true, "--host": true, "--port": true,
	"--api-key": true, "--api-key-file": true, "--ctx-size": true,
	"--n-gpu-layers": true, "--gpu-layers": true, "--parallel": true,
	"--cache-type-k": true, "--cache-type-v": true, "--flash-attn": true,
	"--path": true, "--ssl-key-file": true, "--ssl-cert-file": true,
	"--n-cpu-moe": true, "--cpu-moe": true, "--tensor-split": true,
	"--no-mmap": true, "--mlock": true, "--batch-size": true, "--ubatch-size": true,
}

// ValidateExtraArgs checks a passthrough list against the flags the installed
// binary reports. It is deliberately strict: a typo that would only surface as
// a failed spawn minutes later is worth catching while the user is still
// looking at the field they typed it into.
func ValidateExtraArgs(capability RuntimeCapability, args []string) error {
	if len(args) == 0 {
		return nil
	}
	if len(capability.Flags) == 0 {
		return errors.New("die zusaetzlichen Startargumente koennen nicht geprueft werden, weil der installierte llama-server-Build keine Flag-Liste gemeldet hat")
	}
	known := make(map[string]bool, len(capability.Flags))
	for _, flag := range capability.Flags {
		known[flag] = true
	}
	for _, arg := range args {
		if !strings.HasPrefix(arg, "-") {
			// A value belonging to the flag before it.
			continue
		}
		flag, _, _ := strings.Cut(arg, "=")
		if reservedFlags[flag] {
			return fmt.Errorf("%s wird von der Engine selbst gesetzt und darf nicht zusaetzlich uebergeben werden", flag)
		}
		if !known[flag] {
			return fmt.Errorf("der installierte llama-server-Build kennt das Argument %s nicht", flag)
		}
	}
	return nil
}

type AdapterPaths struct {
	// Server is the absolute path to the installed llama-server binary.
	Server string
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

func DefaultCapability(variant BuildVariant) RuntimeCapability {
	fields := map[string]ChangeMode{
		"context_length":    ChangeRestartRequired,
		"max_sequences":     ChangeRestartRequired,
		"kv_cache_dtype":    ChangeRestartRequired,
		"gpu_ids":           ChangeRestartRequired,
		"offload":           ChangeRestartRequired,
		"priority":          ChangeRestartRequired,
		"gpu_layers":        ChangeRestartRequired,
		"threads":           ChangeRestartRequired,
		"split_mode":        ChangeRestartRequired,
		"main_gpu":          ChangeRestartRequired,
		"flash_attention":   ChangeRestartRequired,
		"allow_ram_offload": ChangeRestartRequired,
		"sampling_defaults": ChangeLive,
		"autostart":         ChangeLive,

		"tensor_split":         ChangeRestartRequired,
		"cpu_moe_layers":       ChangeRestartRequired,
		"batch_size":           ChangeRestartRequired,
		"ubatch_size":          ChangeRestartRequired,
		"threads_batch":        ChangeRestartRequired,
		"memory_lock":          ChangeRestartRequired,
		"disable_mmap":         ChangeRestartRequired,
		"cache_reuse":          ChangeRestartRequired,
		"keep_tokens":          ChangeRestartRequired,
		"continuous_batching":  ChangeRestartRequired,
		"swa_full":             ChangeRestartRequired,
		"jinja":                ChangeRestartRequired,
		"chat_template":        ChangeRestartRequired,
		"chat_template_file":   ChangeRestartRequired,
		"lora_adapters":        ChangeRestartRequired,
		"multimodal_projector": ChangeRestartRequired,
		"embeddings":           ChangeRestartRequired,
		"reranking":            ChangeRestartRequired,
		"pooling_type":         ChangeRestartRequired,
		"numa":                 ChangeRestartRequired,
		"draft_model_path":     ChangeRestartRequired,
		"extra_args":           ChangeRestartRequired,

		// The gateway and the idle sweep read these from the stored config on
		// every request, so they take effect without a restart.
		"gateway_autostart":    ChangeLive,
		"idle_timeout_seconds": ChangeLive,
	}
	return RuntimeCapability{
		Kind:         RuntimeLlamaCPP,
		Variant:      variant,
		Version:      LlamaBuildTag,
		ConfigFields: fields,
		KVCaches:     SupportedCacheTypes(),
	}
}

func BuildAdapterCommand(capability RuntimeCapability, requested RequestedConfig, paths AdapterPaths) (AdapterCommand, error) {
	if requested.Runtime == "" {
		requested.Runtime = RuntimeLlamaCPP
	}
	if requested.Runtime != RuntimeLlamaCPP {
		return AdapterCommand{}, fmt.Errorf("unsupported runtime %q", requested.Runtime)
	}
	if capability.Kind == "" {
		capability = DefaultCapability(capability.Variant)
	}
	if strings.TrimSpace(requested.ModelPath) == "" {
		return AdapterCommand{}, errors.New("model path is required")
	}
	if strings.TrimSpace(paths.Server) == "" {
		return AdapterCommand{}, errors.New("llama-server executable path is required")
	}
	if requested.ContextLength != nil && *requested.ContextLength < 0 {
		return AdapterCommand{}, errors.New("context length may be zero (loaded from the model) but not negative")
	}
	if requested.MaxSequences != nil && *requested.MaxSequences < 0 {
		return AdapterCommand{}, errors.New("max sequences must not be negative")
	}
	if requested.MainGPU != nil && *requested.MainGPU < 0 {
		return AdapterCommand{}, errors.New("main GPU index must not be negative")
	}
	for _, limit := range requested.GPUMemoryBytes {
		if limit <= 0 {
			return AdapterCommand{}, errors.New("GPU memory limits must be positive byte values")
		}
	}
	if requested.CPUMemoryBytes != nil && *requested.CPUMemoryBytes <= 0 {
		return AdapterCommand{}, errors.New("CPU memory limit must be a positive byte value")
	}
	splitMode, err := canonicalSplitMode(requested.SplitMode)
	if err != nil {
		return AdapterCommand{}, err
	}
	flashAttention, err := canonicalFlashAttention(requested.FlashAttention)
	if err != nil {
		return AdapterCommand{}, err
	}
	if err := validateExtendedConfig(requested); err != nil {
		return AdapterCommand{}, err
	}
	pooling, err := canonicalPoolingType(requested.PoolingType)
	if err != nil {
		return AdapterCommand{}, err
	}
	numa, err := canonicalNUMA(requested.NUMA)
	if err != nil {
		return AdapterCommand{}, err
	}
	continuousBatching, err := canonicalToggle(requested.ContinuousBatching, "cont-batching")
	if err != nil {
		return AdapterCommand{}, err
	}
	if err := ValidateExtraArgs(capability, requested.ExtraArgs); err != nil {
		return AdapterCommand{}, err
	}

	if capability.KVCaches == nil {
		capability.KVCaches = SupportedCacheTypes()
	}
	cache, fallbacks, err := resolveKVCache(capability, requested)
	if err != nil {
		return AdapterCommand{}, err
	}
	// Refuse the contradiction rather than emit it and let the server quietly
	// use a cache far larger than the planner budgeted for.
	if flashAttention == "off" && requiresFlashAttention(cache) {
		return AdapterCommand{}, fmt.Errorf("KV cache %s requires flash attention; it cannot be turned off", cache)
	}
	effective := EffectiveConfig{
		Runtime:        RuntimeLlamaCPP,
		Variant:        capability.Variant,
		ModelPath:      requested.ModelPath,
		ContextLength:  cloneInt(requested.ContextLength),
		GPULayers:      cloneInt(requested.GPULayers),
		Threads:        cloneInt(requested.Threads),
		MaxSequences:   cloneInt(requested.MaxSequences),
		KVCacheDType:   cache,
		FlashAttention: resolveFlashAttention(flashAttention, cache),
		SplitMode:      splitMode,
		MainGPU:        cloneInt(requested.MainGPU),

		TensorSplit:  append([]float64(nil), requested.TensorSplit...),
		CPUMoELayers: cloneInt(requested.CPUMoELayers),
		BatchSize:    cloneInt(requested.BatchSize),
		UBatchSize:   cloneInt(requested.UBatchSize),
		ThreadsBatch: cloneInt(requested.ThreadsBatch),

		MemoryLock:  requested.MemoryLock,
		DisableMmap: requested.DisableMmap,

		CacheReuse:         cloneInt(requested.CacheReuse),
		KeepTokens:         cloneInt(requested.KeepTokens),
		ContinuousBatching: continuousBatching,
		SWAFull:            requested.SWAFull,

		Jinja:            requested.Jinja,
		ChatTemplate:     strings.TrimSpace(requested.ChatTemplate),
		ChatTemplateFile: strings.TrimSpace(requested.ChatTemplateFile),

		LoRAAdapters:        append([]LoRAAdapter(nil), requested.LoRAAdapters...),
		MultimodalProjector: strings.TrimSpace(requested.MultimodalProjector),

		Embeddings:  requested.Embeddings,
		Reranking:   requested.Reranking,
		PoolingType: pooling,
		NUMA:        numa,
		Metrics:     requested.Metrics,

		DraftModelPath: strings.TrimSpace(requested.DraftModelPath),
		DraftMaxTokens: cloneInt(requested.DraftMaxTokens),
		DraftMinTokens: cloneInt(requested.DraftMinTokens),
		DraftGPULayers: cloneInt(requested.DraftGPULayers),

		ExtraArgs: append([]string(nil), requested.ExtraArgs...),

		GPUMemoryBytes: append([]int64(nil), requested.GPUMemoryBytes...),
		CPUMemoryBytes: cloneInt64(requested.CPUMemoryBytes),
		Fallbacks:      fallbacks,
	}
	internalAPIKey, err := randomSecret(32)
	if err != nil {
		return AdapterCommand{}, fmt.Errorf("create internal worker credential: %w", err)
	}

	return AdapterCommand{
		HealthPath:     "/health",
		InternalAPIKey: internalAPIKey,
		HealthHeaders:  map[string]string{"Authorization": "Bearer " + internalAPIKey},
		Effective:      effective,
		Argv:           llamaServerArgv(paths.Server, internalAPIKey, effective, capability),
		Env: map[string]string{
			// llama-server reads models from disk only; keep any hub client that
			// might be linked in from reaching the network.
			"HF_HUB_OFFLINE":         "1",
			"LLAMA_ARG_NO_WEBUI":     "1",
			"TOKENIZERS_PARALLELISM": "false",
		},
	}, nil
}

func canonicalFlashAttention(value string) (string, error) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "", "auto", "on", "off":
		return strings.ToLower(strings.TrimSpace(value)), nil
	case "true", "1", "enabled":
		return "on", nil
	case "false", "0", "disabled":
		return "off", nil
	default:
		return "", fmt.Errorf("unsupported flash attention setting %q", value)
	}
}

// resolveFlashAttention settles the flag actually passed to llama-server. A
// quantised cache needs Flash Attention, so an unset choice becomes "on" there;
// asking for it off with such a cache is refused earlier by the caller rather
// than silently ignored here.
func resolveFlashAttention(requested, cacheType string) string {
	if requested != "" {
		return requested
	}
	if requiresFlashAttention(cacheType) {
		return "on"
	}
	return "auto"
}

func canonicalSplitMode(value string) (string, error) {
	trimmed := strings.ToLower(strings.TrimSpace(value))
	switch trimmed {
	case "", "none", "layer", "row":
		return trimmed, nil
	default:
		return "", fmt.Errorf("unsupported split mode %q", value)
	}
}

func canonicalPoolingType(value string) (string, error) {
	trimmed := strings.ToLower(strings.TrimSpace(value))
	switch trimmed {
	case "", "none", "mean", "cls", "last", "rank":
		return trimmed, nil
	default:
		return "", fmt.Errorf("unsupported pooling type %q", value)
	}
}

func canonicalNUMA(value string) (string, error) {
	trimmed := strings.ToLower(strings.TrimSpace(value))
	switch trimmed {
	case "", "distribute", "isolate", "numactl":
		return trimmed, nil
	default:
		return "", fmt.Errorf("unsupported NUMA strategy %q", value)
	}
}

// canonicalToggle reads a tri-state switch: on, off, or unset for whatever the
// server defaults to.
func canonicalToggle(value, name string) (string, error) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "":
		return "", nil
	case "on", "true", "1", "enabled":
		return "on", nil
	case "off", "false", "0", "disabled":
		return "off", nil
	default:
		return "", fmt.Errorf("unsupported %s setting %q", name, value)
	}
}

// validateExtendedConfig rejects the values llama-server would either refuse at
// argument parsing or silently reinterpret.
func validateExtendedConfig(requested RequestedConfig) error {
	for _, entry := range []struct {
		name  string
		value *int
	}{
		{"batch size", requested.BatchSize},
		{"micro-batch size", requested.UBatchSize},
		{"batch thread count", requested.ThreadsBatch},
	} {
		if entry.value != nil && *entry.value <= 0 {
			return fmt.Errorf("%s must be positive", entry.name)
		}
	}
	if requested.BatchSize != nil && requested.UBatchSize != nil && *requested.UBatchSize > *requested.BatchSize {
		return errors.New("the micro-batch size must not exceed the batch size")
	}
	if requested.CacheReuse != nil && *requested.CacheReuse < 0 {
		return errors.New("cache reuse must not be negative")
	}
	if requested.KeepTokens != nil && *requested.KeepTokens < -1 {
		return errors.New("keep tokens may be -1 (keep the whole prompt) but not less")
	}
	for _, share := range requested.TensorSplit {
		if share < 0 {
			return errors.New("tensor split proportions must not be negative")
		}
	}
	if len(requested.TensorSplit) > 0 {
		total := 0.0
		for _, share := range requested.TensorSplit {
			total += share
		}
		if total <= 0 {
			return errors.New("tensor split proportions must not all be zero")
		}
	}
	for _, adapter := range requested.LoRAAdapters {
		if strings.TrimSpace(adapter.Path) == "" {
			return errors.New("a LoRA adapter needs a file path")
		}
		if strings.ContainsAny(adapter.Path, ",:") {
			// --lora-scaled is a comma and colon separated list, so a path
			// containing either cannot be expressed on the command line.
			return fmt.Errorf("the LoRA adapter path %q may not contain a comma or a colon", adapter.Path)
		}
	}
	if requested.Embeddings && requested.Reranking {
		return errors.New("a server runs either in embedding or in reranking mode, not both")
	}
	if requested.PoolingType != "" && !requested.Embeddings && !requested.Reranking {
		return errors.New("a pooling type only applies to an embedding or reranking server")
	}
	if requested.ChatTemplate != "" && requested.ChatTemplateFile != "" {
		return errors.New("a chat template may be given inline or as a file, not both")
	}
	if requested.DraftModelPath == "" {
		for _, entry := range []struct {
			name  string
			value *int
		}{
			{"draft-max", requested.DraftMaxTokens},
			{"draft-min", requested.DraftMinTokens},
			{"draft GPU layers", requested.DraftGPULayers},
		} {
			if entry.value != nil {
				return fmt.Errorf("%s only applies together with a draft model", entry.name)
			}
		}
	}
	if requested.DraftMaxTokens != nil && requested.DraftMinTokens != nil && *requested.DraftMinTokens > *requested.DraftMaxTokens {
		return errors.New("the minimum draft length must not exceed the maximum")
	}
	return nil
}

func resolveKVCache(capability RuntimeCapability, requested RequestedConfig) (string, []Fallback, error) {
	candidates := nativeCacheCandidates(requested.KVPolicy)
	wanted := candidates[0]
	if requested.KVCacheDType != nil {
		wanted = canonicalKVCacheDType(*requested.KVCacheDType)
		if wanted == "" {
			return "", nil, errors.New("explicit KV cache dtype may not be empty")
		}
		candidates = explicitCacheCandidates(wanted)
	}
	if supports(capability.KVCaches, wanted) {
		return wanted, nil, nil
	}
	if !requested.fallbackAllowed() {
		return "", nil, fmt.Errorf("KV cache mode %q is unavailable for this llama.cpp build and fallback is disabled", wanted)
	}
	for _, candidate := range candidates[1:] {
		if supports(capability.KVCaches, candidate) {
			return candidate, []Fallback{{
				Setting: "kv_cache_dtype",
				From:    wanted,
				To:      candidate,
				Reason:  "der installierte llama.cpp-Build akzeptiert diesen KV-Cache-Typ nicht",
			}}, nil
		}
	}
	return "", nil, errors.New("this llama.cpp build reports no supported KV cache mode")
}

// canonicalKVCacheDType maps the planner's dtype names, and the aliases older
// configs stored, onto the spellings llama-server expects.
func canonicalKVCacheDType(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "q4", "q4_0", "quanto_4bit", "turboquant_4bit_nc":
		return "q4_0"
	case "q4_1":
		return "q4_1"
	case "iq4_nl":
		return "iq4_nl"
	case "q5_0":
		return "q5_0"
	case "q5_1":
		return "q5_1"
	case "q8", "q8_0", "fp8":
		// llama.cpp has no fp8 cache; q8_0 is the nearest type it does have.
		return "q8_0"
	case "f16", "fp16", "native", "auto", "offloaded":
		return "f16"
	case "bf16":
		return "bf16"
	case "f32", "fp32":
		return "f32"
	case "q3_k", "q3":
		return "q3_k"
	case "q2_k", "q2":
		return "q2_k"
	default:
		return strings.ToLower(strings.TrimSpace(value))
	}
}

// cacheTypesBySize orders every cache type the engine knows about from smallest
// to largest on device. Fallback always walks up this list: a type that is not
// available is replaced by the next larger one, never a smaller one, so a
// fallback can only ever need more memory than was planned, and the planner's
// budget stays an upper bound.
var cacheTypesBySize = []string{
	"q2_k", "q3_k", "q4_0", "q4_1", "iq4_nl", "q5_0", "q5_1", "q8_0", "f16", "bf16", "f32",
}

// explicitCacheCandidates is the ladder starting at the requested type. An
// unknown type is tried first and then falls back to the full ladder.
func explicitCacheCandidates(wanted string) []string {
	for index, candidate := range cacheTypesBySize {
		if strings.EqualFold(candidate, wanted) {
			return append([]string(nil), cacheTypesBySize[index:]...)
		}
	}
	return append([]string{wanted}, cacheTypesBySize...)
}

// nativeCacheCandidates is the ladder when the caller expressed only a policy.
// q4_0 is the smallest type upstream supports, so it is where a compact cache
// starts; a build with sub-4-bit caches is reached by naming one explicitly.
func nativeCacheCandidates(policy KVPolicy) []string {
	if policy == "" || policy == KVPolicyPrefer4Bit {
		return explicitCacheCandidates("q4_0")
	}
	return []string{"f16", "bf16", "f32"}
}

func supports(values []string, candidate string) bool {
	for _, value := range values {
		if strings.EqualFold(value, candidate) {
			return true
		}
	}
	return false
}

func llamaServerArgv(server, internalAPIKey string, cfg EffectiveConfig, capability RuntimeCapability) []string {
	argv := []string{
		server,
		"--model", cfg.ModelPath,
		"--alias", InstancePlaceholder,
		"--host", "127.0.0.1",
		"--port", PortPlaceholder,
		"--api-key", internalAPIKey,
	}
	argv = appendIntFlag(argv, "--ctx-size", cfg.ContextLength)
	argv = appendIntFlag(argv, "--n-gpu-layers", cfg.GPULayers)
	argv = appendIntFlag(argv, "--threads", cfg.Threads)
	argv = appendIntFlag(argv, "--parallel", cfg.MaxSequences)
	argv = appendIntFlag(argv, "--main-gpu", cfg.MainGPU)
	if cfg.SplitMode != "" {
		argv = append(argv, "--split-mode", cfg.SplitMode)
	}
	if cfg.KVCacheDType != "" {
		argv = append(argv, "--cache-type-k", cfg.KVCacheDType, "--cache-type-v", cfg.KVCacheDType)
	}
	if cfg.FlashAttention != "" {
		// Quantised V caches only work with Flash Attention, so this is "on"
		// for them: leaving it at "auto" lets the server fall back to a bigger
		// cache than the planner budgeted for.
		argv = append(argv, "--flash-attn", cfg.FlashAttention)
	}

	// Placement beyond the layer count.
	if len(cfg.TensorSplit) > 0 {
		argv = append(argv, "--tensor-split", formatTensorSplit(cfg.TensorSplit))
	}
	if cfg.CPUMoELayers != nil {
		if *cfg.CPUMoELayers < 0 {
			argv = append(argv, "--cpu-moe")
		} else if *cfg.CPUMoELayers > 0 {
			argv = append(argv, "--n-cpu-moe", strconv.Itoa(*cfg.CPUMoELayers))
		}
	}
	if cfg.MemoryLock {
		argv = append(argv, "--mlock")
	}
	if cfg.DisableMmap {
		argv = append(argv, "--no-mmap")
	}
	if cfg.NUMA != "" {
		argv = append(argv, "--numa", cfg.NUMA)
	}

	// Throughput and cache reuse.
	argv = appendIntFlag(argv, "--batch-size", cfg.BatchSize)
	argv = appendIntFlag(argv, "--ubatch-size", cfg.UBatchSize)
	argv = appendIntFlag(argv, "--threads-batch", cfg.ThreadsBatch)
	argv = appendIntFlag(argv, "--cache-reuse", cfg.CacheReuse)
	argv = appendIntFlag(argv, "--keep", cfg.KeepTokens)
	switch cfg.ContinuousBatching {
	case "on":
		argv = append(argv, "--cont-batching")
	case "off":
		argv = append(argv, "--no-cont-batching")
	}
	if cfg.SWAFull {
		argv = append(argv, "--swa-full")
	}

	// The chat template. Tool calling on most current GGUFs needs --jinja,
	// because without it the server falls back to a generic template that drops
	// the tool-call sections the model was trained to emit.
	if cfg.Jinja {
		argv = append(argv, "--jinja")
	}
	if cfg.ChatTemplate != "" {
		argv = append(argv, "--chat-template", cfg.ChatTemplate)
	}
	if cfg.ChatTemplateFile != "" {
		argv = append(argv, "--chat-template-file", cfg.ChatTemplateFile)
	}

	// Adapters and extra weights.
	for _, adapter := range cfg.LoRAAdapters {
		if adapter.Scale != nil {
			argv = append(argv, "--lora-scaled", adapter.Path+":"+strconv.FormatFloat(*adapter.Scale, 'g', -1, 64))
			continue
		}
		argv = append(argv, "--lora", adapter.Path)
	}
	if cfg.MultimodalProjector != "" {
		argv = append(argv, "--mmproj", cfg.MultimodalProjector)
	}

	// Non-chat serving modes.
	if cfg.Embeddings {
		argv = append(argv, "--embeddings")
	}
	if cfg.Reranking {
		argv = append(argv, "--reranking")
	}
	if cfg.PoolingType != "" {
		argv = append(argv, "--pooling", cfg.PoolingType)
	}
	if cfg.Metrics {
		argv = append(argv, "--metrics")
	}

	// Speculative decoding. The flag names moved between builds, so use the
	// spelling the installed binary actually reports.
	if cfg.DraftModelPath != "" {
		argv = append(argv, draftFlag(capability, "--spec-draft-model", "--model-draft"), cfg.DraftModelPath)
		argv = appendIntFlag(argv, draftFlag(capability, "--spec-draft-n-max", "--draft-max"), cfg.DraftMaxTokens)
		argv = appendIntFlag(argv, draftFlag(capability, "--spec-draft-n-min", "--draft-min"), cfg.DraftMinTokens)
		argv = appendIntFlag(argv, "--gpu-layers-draft", cfg.DraftGPULayers)
	}

	return append(argv, cfg.ExtraArgs...)
}

// draftFlag picks the spelling the installed build lists, preferring the
// current one. A build that reports neither gets the current spelling and will
// say so itself.
func draftFlag(capability RuntimeCapability, preferred, legacy string) string {
	for _, flag := range capability.Flags {
		if flag == preferred {
			return preferred
		}
	}
	for _, flag := range capability.Flags {
		if flag == legacy {
			return legacy
		}
	}
	return preferred
}

func formatTensorSplit(shares []float64) string {
	parts := make([]string, 0, len(shares))
	for _, share := range shares {
		parts = append(parts, strconv.FormatFloat(share, 'g', -1, 64))
	}
	return strings.Join(parts, ",")
}

// requiresFlashAttention reports whether a cache type is quantised. Quantised
// V caches are only implemented on the Flash Attention path.
func requiresFlashAttention(cacheType string) bool {
	switch strings.ToLower(strings.TrimSpace(cacheType)) {
	case "f16", "bf16", "f32", "":
		return false
	default:
		return true
	}
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
