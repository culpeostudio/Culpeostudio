// Package modelcatalog discovers local model bundles without importing or
// executing any model-provided code.
package modelcatalog

import "context"

// Format identifies the on-disk representation of a model.
type Format string

const (
	FormatGGUF        Format = "gguf"
	FormatSafeTensors Format = "safetensors"
)

// Severity controls whether a catalog problem prevents a model from starting.
type Severity string

const (
	SeverityWarning Severity = "warning"
	SeverityError   Severity = "error"
)

// ValidationIssue is actionable and safe to display directly in the UI.
type ValidationIssue struct {
	Code        string   `json:"code"`
	Severity    Severity `json:"severity"`
	Message     string   `json:"message"`
	Remediation string   `json:"remediation,omitempty"`
}

// Metadata is the normalized subset needed by runtime selection and context
// planning. Zero values mean that the source did not expose the value.
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

// ModelRecord represents one logical model. Files contains paths relative to
// the configured root and uses slash separators on every platform.
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

// Scanner is reusable; every Scan performs a fresh recursive snapshot.
type Scanner struct {
	root string
}

// NewScanner creates a scanner rooted at modelDir. The root itself may be a
// symlink, but discovered symlinks are accepted only when their target remains
// inside the resolved root.
func NewScanner(modelDir string) *Scanner { return &Scanner{root: modelDir} }

// Scan is a convenience wrapper around NewScanner(modelDir).Scan(ctx).
func Scan(ctx context.Context, modelDir string) ([]ModelRecord, error) {
	return NewScanner(modelDir).Scan(ctx)
}
