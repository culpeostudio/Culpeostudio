package modelcatalog

import "context"

type Format string

const (
	FormatGGUF        Format = "gguf"
	FormatSafeTensors Format = "safetensors"
)

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
