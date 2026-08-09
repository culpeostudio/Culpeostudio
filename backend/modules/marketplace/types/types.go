// Package types holds the model and provider shapes shared between the
// marketplace and its providers.
package types

import "strings"

const (
	ProviderAll         = "all"
	ProviderHuggingFace = "huggingface"
	ProviderOpenRouter  = "openrouter"
	ProviderFeatherless = "featherless"
)

type DownloadOption struct {
	Label   string `json:"label"`
	AssetID string `json:"asset_id,omitempty"`

	AssetIDs  []string `json:"asset_ids,omitempty"`
	Format    string   `json:"format,omitempty"`
	SizeBytes int64    `json:"size_bytes,omitempty"`
	URL       string   `json:"url,omitempty"`
}

type ModelSummary struct {
	ID                string   `json:"id"`
	Provider          string   `json:"provider"`
	ModelID           string   `json:"model_id"`
	DisplayName       string   `json:"display_name"`
	Name              string   `json:"name"`
	Description       string   `json:"description,omitempty"`
	Format            string   `json:"format,omitempty"`
	Formats           []string `json:"formats,omitempty"`
	Quantizations     []string `json:"quantizations,omitempty"`
	Author            string   `json:"author,omitempty"`
	Downloads         int64    `json:"downloads,omitempty"`
	SizeBytes         int64    `json:"size_bytes,omitempty"`
	ParameterBadge    string   `json:"parameter_badge,omitempty"`
	ParameterCountB   float64  `json:"parameter_count_b,omitempty"`
	ProviderBadge     string   `json:"provider_badge,omitempty"`
	Category          string   `json:"category,omitempty"`
	CapabilityTags    []string `json:"capability_tags,omitempty"`
	PricePer1M        string   `json:"price_per_1m,omitempty"`
	PricePer1MInput   float64  `json:"price_per_1m_input,omitempty"`
	PricePer1MOutput  float64  `json:"price_per_1m_output,omitempty"`
	PriceKnown        bool     `json:"-"`
	ContextLength     int      `json:"context_length,omitempty"`
	IntelligenceScore int      `json:"intelligence_score,omitempty"`
	EstimatedVRAMGB   float64  `json:"estimated_vram_gb,omitempty"`

	VRAMEstimated   bool `json:"vram_estimated,omitempty"`
	FitsDetectedGPU bool `json:"fits_detected_gpu"`

	RuntimeFit      string   `json:"runtime_fit,omitempty"`
	RuntimeWarnings []string `json:"runtime_warnings,omitempty"`

	RuntimeRAMOffloadGB float64          `json:"runtime_ram_offload_gb,omitempty"`
	RecommendationScore float64          `json:"recommendation_score,omitempty"`
	LocalModel          bool             `json:"local_model"`
	NewScore            int64            `json:"new_score,omitempty"`
	DownloadOptions     []DownloadOption `json:"download_options,omitempty"`
}

type ModelDetail struct {
	ModelSummary
	Tags     []string               `json:"tags,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

func NormalizeProvider(input string) string {
	p := strings.ToLower(strings.TrimSpace(input))
	p = strings.ReplaceAll(p, "-", "_")
	p = strings.ReplaceAll(p, " ", "_")
	if p == "" {
		return ProviderAll
	}
	switch p {
	case "hf":
		return ProviderHuggingFace
	case "open_router":
		return ProviderOpenRouter
	}
	return p
}

func FirstNonEmpty(items ...string) string {
	for _, item := range items {
		v := strings.TrimSpace(item)
		if v != "" {
			return v
		}
	}
	return ""
}

func UniqueNonEmptyLower(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	out := make([]string, 0, len(values))
	for _, v := range values {
		clean := strings.TrimSpace(v)
		if clean == "" {
			continue
		}
		key := strings.ToLower(clean)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, clean)
	}
	return out
}

func UniqueNonEmpty(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	out := make([]string, 0, len(values))
	for _, v := range values {
		clean := strings.TrimSpace(v)
		if clean == "" {
			continue
		}
		if _, ok := seen[clean]; ok {
			continue
		}
		seen[clean] = struct{}{}
		out = append(out, clean)
	}
	return out
}

func MatchesFormat(formats []string, requested string) bool {
	req := NormalizeFormat(strings.TrimSpace(requested))
	if req == "" {
		return true
	}
	for _, format := range formats {
		if NormalizeFormat(strings.TrimSpace(format)) == req {
			return true
		}
	}
	return false
}

func NormalizeFormat(input string) string {
	format := strings.ToLower(strings.TrimSpace(input))
	if format == "" {
		return ""
	}

	switch format {
	case "safe-tensors", "safe_tensors", "safetensor", "safetensors":
		return "safetensors"
	case "onnx":
		return "onnx"
	case "mlx", "apple mlx", "apple-mlx":
		return "mlx"
	case "nemo", "nvidia nemo", "nvidia-nemo", "nvidia_nemo":
		return "nemo"
	case "gguf":
		return "gguf"
	case "ollama":
		return "ollama"
	default:
		return format
	}
}
