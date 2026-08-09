package marketplace

import (
	"regexp"
	"strings"

	"github.com/culpeohq/backend/modules/marketplace/types"
)

var quantizationQPattern = regexp.MustCompile(`(?i)i?q[1-8](?:[_-][0-9])?(?:[_-][a-z0-9]{1,3}){0,2}`)
var quantizationOtherPattern = regexp.MustCompile(`(?i)\b(int[348]|fp(?:8|16|32)|bf16|nf4|gptq|awq)\b`)

func normalizeQuantization(input string) string {
	q := strings.ToLower(strings.TrimSpace(input))
	if q == "" || q == "all" {
		return ""
	}

	q = strings.ReplaceAll(q, "-", "_")
	switch q {
	case "8bit":
		return "int8"
	case "4bit":
		return "int4"
	case "3bit":
		return "int3"
	case "q4km":
		return "q4_k_m"
	case "q5km":
		return "q5_k_m"
	}
	return q
}

func extractQuantizationsFromText(text string) []string {
	clean := strings.TrimSpace(text)
	matches := make([]string, 0)
	matches = append(matches, quantizationQPattern.FindAllString(clean, -1)...)
	matches = append(matches, quantizationOtherPattern.FindAllString(clean, -1)...)
	if len(matches) == 0 {
		return nil
	}
	out := make([]string, 0, len(matches))
	for _, match := range matches {
		norm := normalizeQuantization(match)
		if norm != "" {
			out = append(out, norm)
		}
	}
	return types.UniqueNonEmptyLower(out)
}

func deriveQuantizations(model types.ModelSummary) []string {
	collected := make([]string, 0, 12)
	collected = append(collected, extractQuantizationsFromText(model.ModelID)...)
	collected = append(collected, extractQuantizationsFromText(model.Name)...)
	collected = append(collected, extractQuantizationsFromText(model.DisplayName)...)
	collected = append(collected, extractQuantizationsFromText(model.Description)...)

	for _, option := range model.DownloadOptions {
		collected = append(collected, extractQuantizationsFromText(option.Label)...)
		collected = append(collected, extractQuantizationsFromText(option.AssetID)...)
		collected = append(collected, extractQuantizationsFromText(option.URL)...)
	}
	return types.UniqueNonEmptyLower(collected)
}

func enrichModelMetadata(models []types.ModelSummary) []types.ModelSummary {
	out := make([]types.ModelSummary, len(models))
	copy(out, models)
	for i := range out {
		quantizations := deriveQuantizations(out[i])
		out[i].Quantizations = quantizations
	}
	return out
}

func matchesQuantization(quantizations []string, requested string) bool {
	req := normalizeQuantization(requested)
	if req == "" {
		return true
	}
	for _, q := range quantizations {
		norm := normalizeQuantization(q)
		if norm == req {
			return true
		}

		if strings.HasPrefix(req, "q") && !strings.Contains(req, "_") && strings.HasPrefix(norm, req) {
			return true
		}
	}
	return false
}

func filterModelsByQuantization(models []types.ModelSummary, requested string) []types.ModelSummary {
	req := normalizeQuantization(requested)
	if req == "" {
		return models
	}
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		matched := matchesQuantization(model.Quantizations, req)
		if !matched && req == "safetensors" {
			formats := model.Formats
			if len(formats) == 0 && strings.TrimSpace(model.Format) != "" {
				formats = []string{model.Format}
			}
			matched = types.MatchesFormat(formats, "safetensors")
		}
		if matched {
			out = append(out, model)
		}
	}
	return out
}
