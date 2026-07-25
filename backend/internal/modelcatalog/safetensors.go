package modelcatalog

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

const maxSafeTensorsHeaderBytes = 256 * 1024 * 1024

type safeTensorsIndex struct {
	Metadata  map[string]any    `json:"metadata"`
	WeightMap map[string]string `json:"weight_map"`
}

type modelConfig struct {
	ModelType             string          `json:"model_type"`
	Architectures         []string        `json:"architectures"`
	NumHiddenLayers       int             `json:"num_hidden_layers"`
	NLayer                int             `json:"n_layer"`
	NumAttentionHeads     int             `json:"num_attention_heads"`
	NHead                 int             `json:"n_head"`
	NumKeyValueHeads      int             `json:"num_key_value_heads"`
	NHeadKV               int             `json:"n_head_kv"`
	HiddenSize            int             `json:"hidden_size"`
	NEmbd                 int             `json:"n_embd"`
	HeadDim               int             `json:"head_dim"`
	MaxPositionEmbeddings int             `json:"max_position_embeddings"`
	NPositions            int             `json:"n_positions"`
	SlidingWindow         json.RawMessage `json:"sliding_window"`
	TorchDType            string          `json:"torch_dtype"`
	QuantizationConfig    struct {
		QuantMethod string          `json:"quant_method"`
		Bits        json.RawMessage `json:"bits"`
	} `json:"quantization_config"`
}

type safeTensorDescriptor struct {
	DType       string  `json:"dtype"`
	Shape       []int64 `json:"shape"`
	DataOffsets []int64 `json:"data_offsets"`
}

type safeTensorSummary struct {
	parameters int64
	dtypes     map[string]struct{}
}

func scanSafeTensorsDirectory(root, dir string, discovered []discoveredFile) ModelRecord {
	relDir, _ := filepath.Rel(root, dir)
	relDir = filepath.ToSlash(relDir)
	if relDir == "." {
		relDir = ""
	}
	logicalRel := relDir
	if logicalRel == "" {
		logicalRel = "."
	}
	record := ModelRecord{
		ID:                stableID(FormatSafeTensors, logicalRel),
		Name:              filepath.Base(dir),
		RelativePath:      logicalRel,
		Format:            FormatSafeTensors,
		RuntimeCandidates: []string{"vllm", "transformers"},
	}

	discoveredByAbs := make(map[string]discoveredFile, len(discovered))
	for _, file := range discovered {
		discoveredByAbs[filepath.Clean(file.abs)] = file
	}
	configPath := filepath.Join(dir, "config.json")
	config, configErr := readModelConfig(configPath)
	if configErr != nil {
		record.Issues = append(record.Issues, ValidationIssue{
			Code:        "missing_or_invalid_config",
			Severity:    SeverityError,
			Message:     fmt.Sprintf("SafeTensors bundle has no readable config.json: %v", configErr),
			Remediation: "Download config.json from the same model revision.",
		})
	} else {
		record.Metadata = metadataFromConfig(config)
	}

	if !hasTokenizerAsset(dir) {
		record.Issues = append(record.Issues, ValidationIssue{
			Code:        "tokenizer_missing",
			Severity:    SeverityError,
			Message:     "SafeTensors bundle has no tokenizer vocabulary/model file.",
			Remediation: "Download tokenizer.json, tokenizer.model, spiece.model, or the vocabulary files from the same revision.",
		})
	}
	if !hasChatTemplate(dir) {
		record.Issues = append(record.Issues, ValidationIssue{
			Code:        "chat_template_missing",
			Severity:    SeverityWarning,
			Message:     "No chat template was detected; completion mode remains available.",
			Remediation: "Add the repository's tokenizer_config.json or chat_template.jinja before using chat mode.",
		})
	}

	indexPath := filepath.Join(dir, "model.safetensors.index.json")
	weightFiles := make([]discoveredFile, 0, len(discovered))
	if fileExists(indexPath) {
		index, err := readSafeTensorsIndex(indexPath)
		if err != nil {
			record.Issues = append(record.Issues, ValidationIssue{
				Code:        "invalid_safetensors_index",
				Severity:    SeverityError,
				Message:     fmt.Sprintf("model.safetensors.index.json is invalid: %v", err),
				Remediation: "Re-download the index from the same model revision.",
			})
		} else {
			expected := uniqueIndexFiles(index.WeightMap)
			if len(expected) == 0 {
				record.Issues = append(record.Issues, ValidationIssue{
					Code:        "empty_safetensors_index",
					Severity:    SeverityError,
					Message:     "The SafeTensors index does not reference any weight shards.",
					Remediation: "Re-download the complete model snapshot.",
				})
			}
			for _, referenced := range expected {
				cleanRef := filepath.Clean(filepath.FromSlash(referenced))
				candidate := filepath.Join(dir, cleanRef)
				if filepath.IsAbs(cleanRef) || !withinRoot(dir, candidate) || !withinRoot(root, candidate) || !strings.EqualFold(filepath.Ext(candidate), ".safetensors") {
					record.Issues = append(record.Issues, ValidationIssue{
						Code:        "unsafe_safetensors_shard_path",
						Severity:    SeverityError,
						Message:     fmt.Sprintf("Index references an unsafe shard path %q.", referenced),
						Remediation: "Use an unmodified index from the model provider.",
					})
					continue
				}
				resolved, evalErr := filepath.EvalSymlinks(candidate)
				if evalErr != nil || !withinRoot(root, resolved) || !withinRoot(dir, resolved) {
					record.Issues = append(record.Issues, ValidationIssue{
						Code:        "missing_safetensors_shard",
						Severity:    SeverityError,
						Message:     fmt.Sprintf("SafeTensors index references missing shard %q.", referenced),
						Remediation: "Download every shard listed in model.safetensors.index.json.",
					})
					continue
				}
				info, statErr := os.Stat(resolved)
				if statErr != nil || !info.Mode().IsRegular() {
					record.Issues = append(record.Issues, ValidationIssue{Code: "invalid_safetensors_shard", Severity: SeverityError, Message: fmt.Sprintf("Referenced shard %q is not a regular file.", referenced), Remediation: "Re-download this shard."})
					continue
				}
				rel, _ := filepath.Rel(root, resolved)
				weightFiles = append(weightFiles, discoveredFile{abs: resolved, rel: filepath.ToSlash(rel)})
			}
			referencedSet := make(map[string]struct{}, len(weightFiles))
			for _, file := range weightFiles {
				referencedSet[filepath.Clean(file.abs)] = struct{}{}
			}
			for abs := range discoveredByAbs {
				if _, ok := referencedSet[abs]; !ok {
					rel, _ := filepath.Rel(root, abs)
					record.Issues = append(record.Issues, ValidationIssue{
						Code:        "unreferenced_safetensors_shard",
						Severity:    SeverityWarning,
						Message:     fmt.Sprintf("Weight file %q is not referenced by the index and will not be loaded.", filepath.ToSlash(rel)),
						Remediation: "Remove stale shards or restore the matching index.",
					})
				}
			}
		}
	} else {
		weightFiles = append(weightFiles, discovered...)
		if len(weightFiles) == 0 {
			record.Issues = append(record.Issues, ValidationIssue{Code: "safetensors_weights_missing", Severity: SeverityError, Message: "No SafeTensors weight file was found.", Remediation: "Download the model weights."})
		} else if len(weightFiles) > 1 {
			record.Issues = append(record.Issues, ValidationIssue{
				Code:        "safetensors_index_missing",
				Severity:    SeverityError,
				Message:     "Multiple SafeTensors shards exist but model.safetensors.index.json is missing.",
				Remediation: "Download the index from the same model revision.",
			})
		}
	}

	inspectionFiles := weightFiles
	if len(inspectionFiles) == 0 {
		// An invalid or empty index must keep the bundle non-startable, but the
		// files already on disk remain useful for size display and repair hints.
		inspectionFiles = discovered
	}
	var parameterCount int64
	dtypes := make(map[string]struct{})
	seenWeights := make(map[string]struct{})
	for _, file := range inspectionFiles {
		clean := filepath.Clean(file.abs)
		if _, duplicate := seenWeights[clean]; duplicate {
			continue
		}
		seenWeights[clean] = struct{}{}
		summary, err := parseSafeTensorsHeader(clean)
		if err != nil {
			record.Issues = append(record.Issues, ValidationIssue{
				Code:        "invalid_safetensors_file",
				Severity:    SeverityError,
				Message:     fmt.Sprintf("%s has an invalid SafeTensors header: %v", file.rel, err),
				Remediation: "Re-download this weight shard.",
			})
			continue
		}
		parameterCount = saturatingAdd(parameterCount, summary.parameters)
		for dtype := range summary.dtypes {
			dtypes[dtype] = struct{}{}
		}
	}
	if parameterCount > 0 {
		record.Metadata.ParameterCount = parameterCount
	}
	if headerDTypes := joinedDTypes(dtypes); headerDTypes != "" {
		record.Metadata.StoredTensorDataType = headerDTypes
	}
	if record.Metadata.Quantization == "" {
		record.Metadata.Quantization = record.Metadata.StoredTensorDataType
	}

	fingerprintFiles := make([]string, 0, len(inspectionFiles)+12)
	for _, file := range inspectionFiles {
		fingerprintFiles = append(fingerprintFiles, file.rel)
		if info, err := os.Stat(file.abs); err == nil {
			record.SizeBytes = saturatingAdd(record.SizeBytes, info.Size())
		}
	}
	for _, name := range safeTensorsSidecarNames() {
		path := filepath.Join(dir, name)
		if !fileExists(path) {
			continue
		}
		rel, _ := filepath.Rel(root, path)
		fingerprintFiles = append(fingerprintFiles, filepath.ToSlash(rel))
	}
	fingerprintFiles = uniqueSorted(fingerprintFiles)
	record.Files = append(record.Files, fingerprintFiles...)
	record.Fingerprint = sampledFingerprint(root, fingerprintFiles)
	record.Complete = !hasBlockingIssue(record.Issues)
	record.Startable = record.Complete
	if record.Metadata.Name != "" {
		record.Name = record.Metadata.Name
	}
	return record
}

func readModelConfig(path string) (modelConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return modelConfig{}, err
	}
	var config modelConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return modelConfig{}, err
	}
	return config, nil
}

func metadataFromConfig(config modelConfig) Metadata {
	layers := firstPositive(config.NumHiddenLayers, config.NLayer)
	heads := firstPositive(config.NumAttentionHeads, config.NHead)
	kvHeads := firstPositive(config.NumKeyValueHeads, config.NHeadKV, heads)
	hidden := firstPositive(config.HiddenSize, config.NEmbd)
	headDim := config.HeadDim
	if headDim <= 0 && hidden > 0 && heads > 0 {
		headDim = hidden / heads
	}
	architecture := strings.TrimSpace(config.ModelType)
	name := ""
	if len(config.Architectures) > 0 {
		name = strings.TrimSpace(config.Architectures[0])
	}
	quantization := strings.ToUpper(strings.TrimSpace(config.QuantizationConfig.QuantMethod))
	if quantization != "" {
		if bits := rawInt(config.QuantizationConfig.Bits); bits > 0 {
			quantization += "_" + strconv.Itoa(bits) + "BIT"
		}
	}
	return Metadata{
		Name:                 name,
		Architecture:         architecture,
		Layers:               layers,
		AttentionHeads:       heads,
		KVHeads:              kvHeads,
		HeadDimension:        headDim,
		EmbeddingDimension:   hidden,
		ContextLength:        firstPositive(config.MaxPositionEmbeddings, config.NPositions),
		SlidingWindow:        rawInt(config.SlidingWindow),
		Quantization:         quantization,
		StoredTensorDataType: normalizeTensorDType(config.TorchDType),
	}
}

func normalizeTensorDType(dtype string) string {
	switch strings.ToLower(strings.TrimSpace(dtype)) {
	case "float16", "half", "fp16", "f16":
		return "F16"
	case "bfloat16", "bf16":
		return "BF16"
	case "float32", "float", "fp32", "f32":
		return "F32"
	case "float64", "double", "fp64", "f64":
		return "F64"
	default:
		return strings.ToUpper(strings.TrimSpace(dtype))
	}
}

func readSafeTensorsIndex(path string) (safeTensorsIndex, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return safeTensorsIndex{}, err
	}
	var index safeTensorsIndex
	if err := json.Unmarshal(data, &index); err != nil {
		return safeTensorsIndex{}, err
	}
	if index.WeightMap == nil {
		return safeTensorsIndex{}, fmt.Errorf("weight_map is missing")
	}
	return index, nil
}

func uniqueIndexFiles(weightMap map[string]string) []string {
	seen := make(map[string]struct{})
	for _, path := range weightMap {
		path = filepath.ToSlash(strings.TrimSpace(path))
		if path != "" {
			seen[path] = struct{}{}
		}
	}
	files := make([]string, 0, len(seen))
	for path := range seen {
		files = append(files, path)
	}
	sort.Strings(files)
	return files
}

func parseSafeTensorsHeader(path string) (safeTensorSummary, error) {
	file, err := os.Open(path)
	if err != nil {
		return safeTensorSummary{}, err
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return safeTensorSummary{}, err
	}
	var headerLength uint64
	if err := binary.Read(file, binary.LittleEndian, &headerLength); err != nil {
		return safeTensorSummary{}, err
	}
	if headerLength == 0 || headerLength > maxSafeTensorsHeaderBytes || headerLength > uint64(maxInt64(0, info.Size()-8)) {
		return safeTensorSummary{}, fmt.Errorf("invalid header length %d for %d-byte file", headerLength, info.Size())
	}
	header := make([]byte, int(headerLength))
	if _, err := io.ReadFull(file, header); err != nil {
		return safeTensorSummary{}, err
	}
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(header, &raw); err != nil {
		return safeTensorSummary{}, err
	}
	summary := safeTensorSummary{dtypes: make(map[string]struct{})}
	dataBytes := info.Size() - 8 - int64(headerLength)
	for name, encoded := range raw {
		if name == "__metadata__" {
			continue
		}
		var descriptor safeTensorDescriptor
		if err := json.Unmarshal(encoded, &descriptor); err != nil {
			return safeTensorSummary{}, fmt.Errorf("tensor %q: %w", name, err)
		}
		if strings.TrimSpace(descriptor.DType) == "" || descriptor.Shape == nil || len(descriptor.DataOffsets) != 2 {
			return safeTensorSummary{}, fmt.Errorf("tensor %q has an incomplete descriptor", name)
		}
		if descriptor.DataOffsets[0] < 0 || descriptor.DataOffsets[1] < descriptor.DataOffsets[0] || descriptor.DataOffsets[1] > dataBytes {
			return safeTensorSummary{}, fmt.Errorf("tensor %q has out-of-range data offsets", name)
		}
		parameters := int64(1)
		for _, dimension := range descriptor.Shape {
			if dimension < 0 {
				return safeTensorSummary{}, fmt.Errorf("tensor %q has a negative shape", name)
			}
			if dimension == 0 {
				parameters = 0
				continue
			}
			if parameters > math.MaxInt64/dimension {
				parameters = math.MaxInt64
			} else if parameters != math.MaxInt64 {
				parameters *= dimension
			}
		}
		if bits := safeTensorDTypeBits(descriptor.DType); bits > 0 {
			expectedBits, overflowErr := checkedSafeTensorMul(parameters, int64(bits))
			if overflowErr != nil || expectedBits > math.MaxInt64-7 {
				return safeTensorSummary{}, fmt.Errorf("tensor %q byte size overflows", name)
			}
			expectedBytes := (expectedBits + 7) / 8
			if descriptor.DataOffsets[1]-descriptor.DataOffsets[0] != expectedBytes {
				return safeTensorSummary{}, fmt.Errorf("tensor %q payload is %d bytes, want %d for %s%v", name, descriptor.DataOffsets[1]-descriptor.DataOffsets[0], expectedBytes, descriptor.DType, descriptor.Shape)
			}
		}
		summary.parameters = saturatingAdd(summary.parameters, parameters)
		summary.dtypes[strings.ToUpper(strings.TrimSpace(descriptor.DType))] = struct{}{}
	}
	if len(summary.dtypes) == 0 {
		return safeTensorSummary{}, fmt.Errorf("header contains no tensors")
	}
	return summary, nil
}

func safeTensorDTypeBits(dtype string) int {
	switch strings.ToUpper(strings.TrimSpace(dtype)) {
	case "BOOL", "I8", "U8", "F8_E5M2", "F8_E4M3FN", "F8_E8M0":
		return 8
	case "I16", "U16", "F16", "BF16":
		return 16
	case "I32", "U32", "F32":
		return 32
	case "I64", "U64", "F64":
		return 64
	case "I4", "U4", "F4":
		return 4
	default:
		return 0
	}
}

func checkedSafeTensorMul(a, b int64) (int64, error) {
	if a < 0 || b < 0 || (a != 0 && b > math.MaxInt64/a) {
		return 0, fmt.Errorf("integer overflow")
	}
	return a * b, nil
}

func hasTokenizerAsset(dir string) bool {
	for _, name := range []string{"tokenizer.json", "tokenizer.model", "spiece.model", "sentencepiece.bpe.model", "vocab.json"} {
		if fileExists(filepath.Join(dir, name)) {
			return true
		}
	}
	return false
}

func hasChatTemplate(dir string) bool {
	if fileExists(filepath.Join(dir, "chat_template.jinja")) {
		return true
	}
	data, err := os.ReadFile(filepath.Join(dir, "tokenizer_config.json"))
	if err != nil {
		return false
	}
	var config struct {
		ChatTemplate json.RawMessage `json:"chat_template"`
	}
	if json.Unmarshal(data, &config) != nil {
		return false
	}
	trimmed := strings.TrimSpace(string(config.ChatTemplate))
	return trimmed != "" && trimmed != "null" && trimmed != `""`
}

func safeTensorsSidecarNames() []string {
	return []string{
		"config.json", "generation_config.json", "model.safetensors.index.json",
		"tokenizer.json", "tokenizer.model", "spiece.model", "sentencepiece.bpe.model",
		"tokenizer_config.json", "special_tokens_map.json", "chat_template.jinja",
		"vocab.json", "merges.txt",
	}
}

func firstPositive(values ...int) int {
	for _, value := range values {
		if value > 0 {
			return value
		}
	}
	return 0
}

func rawInt(raw json.RawMessage) int {
	if len(raw) == 0 || string(raw) == "null" {
		return 0
	}
	var integer int
	if json.Unmarshal(raw, &integer) == nil {
		return integer
	}
	var numbers []int
	if json.Unmarshal(raw, &numbers) == nil && len(numbers) > 0 {
		return numbers[0]
	}
	return 0
}

func joinedDTypes(values map[string]struct{}) string {
	if len(values) == 0 {
		return ""
	}
	result := make([]string, 0, len(values))
	for value := range values {
		result = append(result, value)
	}
	sort.Strings(result)
	return strings.Join(result, "+")
}

func uniqueSorted(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		seen[value] = struct{}{}
	}
	result := make([]string, 0, len(seen))
	for value := range seen {
		result = append(result, value)
	}
	sort.Strings(result)
	return result
}

func maxInt64(a, b int64) int64 {
	if a > b {
		return a
	}
	return b
}
