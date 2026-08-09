// The free-form runtime_options map is where a caller reaches the llama-server
// flags the engine does not model as first-class config. This file is the one
// place that translates it, so every option has a single spelling, a single
// validation, and a single answer to "what does the planner know about it".
//
// Options that change the memory budget (the MoE split, the batch sizes,
// whether the weights are mapped or resident) are read by the planner too;
// options that only change behaviour are read here alone.

package engine

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/culpeohq/backend/internal/engineruntime"
)

// applyRuntimeOptions fills the extended part of a RequestedConfig from the
// caller's runtime options. The narrow, long-standing options (gpu_layers,
// threads, main_gpu, split_mode, flash_attention, kv_cache_dtype) keep being
// read at the call site; everything added later lives here.
func (m *EngineModule) applyRuntimeOptions(requested *engineruntime.RequestedConfig, config EngineConfig) error {
	options := config.RuntimeOptions
	if options == nil {
		return nil
	}

	requested.CPUMoELayers = cpuMoELayersOption(options)
	requested.BatchSize, _ = intOption(options, "batch_size")
	requested.UBatchSize, _ = intOption(options, "ubatch_size")
	requested.ThreadsBatch, _ = intOption(options, "threads_batch")
	requested.CacheReuse, _ = intOption(options, "cache_reuse")
	requested.KeepTokens, _ = intOption(options, "keep_tokens")

	split, err := floatSliceOption(options, "tensor_split")
	if err != nil {
		return err
	}
	requested.TensorSplit = split

	requested.MemoryLock, _ = boolOption(options, "memory_lock")
	requested.DisableMmap, _ = boolOption(options, "disable_mmap")
	requested.SWAFull, _ = boolOption(options, "swa_full")
	requested.Jinja, _ = boolOption(options, "jinja")
	requested.Embeddings, _ = boolOption(options, "embeddings")
	requested.Reranking, _ = boolOption(options, "reranking")

	requested.ContinuousBatching, _ = stringOption(options, "continuous_batching")
	requested.PoolingType, _ = stringOption(options, "pooling_type")
	requested.NUMA, _ = stringOption(options, "numa")
	requested.ChatTemplate, _ = stringOption(options, "chat_template")

	// The server reads its own Prometheus counters out to /metrics. The engine
	// asks for them unconditionally so instance throughput is measured rather
	// than guessed from the shape of the response stream.
	requested.Metrics = true
	if enabled, explicit := boolOption(options, "metrics"); explicit {
		requested.Metrics = enabled
	}

	// Every path a caller supplies is resolved inside the model directory. They
	// arrive as free-form strings, and a start would otherwise read any file the
	// backend process can reach.
	templateFile, err := m.resolveOptionPath(options, "chat_template_file")
	if err != nil {
		return err
	}
	requested.ChatTemplateFile = templateFile

	projector, err := m.resolveOptionPath(options, "multimodal_projector")
	if err != nil {
		return err
	}
	requested.MultimodalProjector = projector

	draftModel, err := m.resolveOptionPath(options, "draft_model_path")
	if err != nil {
		return err
	}
	requested.DraftModelPath = draftModel
	if draftModel != "" {
		requested.DraftMaxTokens, _ = intOption(options, "draft_max_tokens")
		requested.DraftMinTokens, _ = intOption(options, "draft_min_tokens")
		requested.DraftGPULayers, _ = intOption(options, "draft_gpu_layers")
	}

	adapters, err := m.loraAdaptersOption(options)
	if err != nil {
		return err
	}
	requested.LoRAAdapters = adapters

	extra, err := argumentSliceOption(options, "extra_args")
	if err != nil {
		return err
	}
	requested.ExtraArgs = extra
	return nil
}

// cpuMoELayersOption reads the MoE offload. It accepts a layer count, and the
// word "all" or a plain true for "every expert layer", which is what a UI
// toggle produces.
func cpuMoELayersOption(options map[string]interface{}) *int {
	if value, ok := intOption(options, "cpu_moe_layers"); ok {
		return value
	}
	if all, ok := boolOption(options, "cpu_moe"); ok && all {
		every := -1
		return &every
	}
	if text, ok := stringOption(options, "cpu_moe_layers"); ok && strings.EqualFold(text, "all") {
		every := -1
		return &every
	}
	return nil
}

func (m *EngineModule) loraAdaptersOption(options map[string]interface{}) ([]engineruntime.LoRAAdapter, error) {
	raw, ok := options["lora_adapters"]
	if !ok || raw == nil {
		return nil, nil
	}
	entries, ok := raw.([]interface{})
	if !ok {
		return nil, fmt.Errorf("lora_adapters erwartet eine Liste")
	}
	adapters := make([]engineruntime.LoRAAdapter, 0, len(entries))
	for _, entry := range entries {
		var path string
		var scale *float64
		switch typed := entry.(type) {
		case string:
			path = typed
		case map[string]interface{}:
			path, _ = stringOption(typed, "path")
			scale, _ = floatOption(typed, "scale")
		default:
			return nil, fmt.Errorf("ein LoRA-Adapter wird als Pfad oder als Objekt mit path und scale angegeben")
		}
		resolved, err := m.resolveModelDirPath(path)
		if err != nil {
			return nil, fmt.Errorf("LoRA-Adapter: %w", err)
		}
		if resolved == "" {
			return nil, fmt.Errorf("ein LoRA-Adapter braucht einen Dateipfad")
		}
		adapters = append(adapters, engineruntime.LoRAAdapter{Path: resolved, Scale: scale})
	}
	return adapters, nil
}

func (m *EngineModule) resolveOptionPath(options map[string]interface{}, key string) (string, error) {
	value, ok := stringOption(options, key)
	if !ok || strings.TrimSpace(value) == "" {
		return "", nil
	}
	resolved, err := m.resolveModelDirPath(value)
	if err != nil {
		return "", fmt.Errorf("%s: %w", key, err)
	}
	return resolved, nil
}

// resolveModelDirPath confines a caller-supplied file to the configured model
// directory. It mirrors modelPath, which does the same for a catalog record:
// the path is resolved, its symlinks followed, and the result checked to still
// be inside the root, so neither a "../" nor a symlink escapes it.
func (m *EngineModule) resolveModelDirPath(value string) (string, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return "", nil
	}
	m.mu.RLock()
	root := m.modelDir
	m.mu.RUnlock()
	if root == "" {
		return "", fmt.Errorf("der Modellordner ist nicht konfiguriert")
	}
	candidate := value
	if !filepath.IsAbs(candidate) {
		candidate = filepath.Join(root, filepath.FromSlash(value))
	}
	absolute, err := filepath.Abs(candidate)
	if err != nil {
		return "", err
	}
	if !withinModelRoot(root, absolute) {
		return "", fmt.Errorf("%q liegt ausserhalb des Modellordners", value)
	}
	resolved, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		if os.IsNotExist(err) {
			return "", fmt.Errorf("%q wurde nicht gefunden", value)
		}
		return "", err
	}
	if !withinModelRoot(root, resolved) {
		return "", fmt.Errorf("%q verweist aus dem Modellordner heraus", value)
	}
	info, err := os.Stat(resolved)
	if err != nil {
		return "", err
	}
	if !info.Mode().IsRegular() {
		return "", fmt.Errorf("%q ist keine regulaere Datei", value)
	}
	return resolved, nil
}

func withinModelRoot(root, candidate string) bool {
	relative, err := filepath.Rel(filepath.Clean(root), filepath.Clean(candidate))
	if err != nil {
		return false
	}
	return relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator)) && !filepath.IsAbs(relative)
}
