package modelcatalog

import "context"

type Format string

// FormatGGUF is the only format the catalogue reports. The engine runs
// llama.cpp, which loads GGUF and nothing else.
const FormatGGUF Format = "gguf"

type Severity string

const (
	SeverityWarning Severity = "warning"
	SeverityError   Severity = "error"
)

type ValidationIssue struct {
	Code        string   `json:"code"`
	Severity    Severity `json:"severity"`
	Message     string   `json:"message"`
	Remediation string   `json:"remediation,omitempty"`
}

type Metadata struct {
	Name                 string `json:"name,omitempty"`
	Architecture         string `json:"architecture,omitempty"`
	Layers               int    `json:"layers,omitempty"`
	AttentionHeads       int    `json:"attention_heads,omitempty"`
	KVHeads              int    `json:"kv_heads,omitempty"`
	HeadDimension        int    `json:"head_dimension,omitempty"`
	EmbeddingDimension   int    `json:"embedding_dimension,omitempty"`
	ContextLength        int    `json:"context_length,omitempty"`
	SlidingWindow        int    `json:"sliding_window,omitempty"`
	ParameterCount       int64  `json:"parameter_count,omitempty"`
	Quantization         string `json:"quantization,omitempty"`
	StoredTensorDataType string `json:"stored_tensor_data_type,omitempty"`

	// ExpertWeightBytes is how many bytes of this model are Mixture-of-Experts
	// weight, and ExpertLayers how many blocks carry any. Zero for a dense
	// model, which is what makes them a reliable test for "is this MoE".
	//
	// They exist so an expert offload can be budgeted. On an MoE model the
	// experts dominate the weights but are read sparsely, so moving them to
	// system RAM costs far less speed than moving whole layers - but only if
	// the planner knows how many bytes it just moved.
	ExpertWeightBytes int64 `json:"expert_weight_bytes,omitempty"`
	ExpertLayers      int   `json:"expert_layers,omitempty"`
}

type ModelRecord struct {
	ID                string            `json:"id"`
	Fingerprint       string            `json:"fingerprint"`
	Name              string            `json:"name"`
	RelativePath      string            `json:"relative_path"`
	Format            Format            `json:"format"`
	Complete          bool              `json:"complete"`
	Startable         bool              `json:"startable"`
	SizeBytes         int64             `json:"size_bytes"`
	Files             []string          `json:"files"`
	Metadata          Metadata          `json:"metadata"`
	RuntimeCandidates []string          `json:"runtime_candidates"`
	Issues            []ValidationIssue `json:"issues,omitempty"`
}

type Scanner struct {
	root string
}

func NewScanner(modelDir string) *Scanner { return &Scanner{root: modelDir} }

func Scan(ctx context.Context, modelDir string) ([]ModelRecord, error) {
	return NewScanner(modelDir).Scan(ctx)
}
