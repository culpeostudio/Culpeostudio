package marktplatz

import (
	"fmt"
	"strings"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

func (m *MarktplatzModule) defaultSuggestions(provider string, limit int) []types.ModelSummary {
	if limit <= 0 {
		limit = 20
	}

	switch provider {
	case types.ProviderHuggingFace:
		return trimModels(defaultHuggingFaceSuggestions(), limit)
	case types.ProviderOpenRouter:
		return trimModels(defaultOpenRouterSuggestions(), limit)
	case types.ProviderFeatherless:
		return trimModels(defaultFeatherlessSuggestions(), limit)
	case types.ProviderAll:
		all := make([]types.ModelSummary, 0, limit)
		all = append(all, defaultHuggingFaceSuggestions()...)
		all = append(all, defaultOpenRouterSuggestions()...)
		all = append(all, defaultFeatherlessSuggestions()...)
		return trimModels(deduplicateModels(all), limit)
	default:
		return []types.ModelSummary{}
	}
}

func (m *MarktplatzModule) staticDetail(provider string, modelID string) (types.ModelDetail, error) {
	for _, summary := range m.defaultSuggestions(provider, 100) {
		if strings.EqualFold(summary.ModelID, strings.TrimSpace(modelID)) {
			profile := detectHardwareProfile()
			enriched := enrichMarketplaceMetadata([]types.ModelSummary{summary}, profile)
			return types.ModelDetail{
				ModelSummary: enriched[0],
				Tags:         enriched[0].CapabilityTags,
				Metadata: map[string]interface{}{
					"source": provider,
				},
			}, nil
		}
	}
	return types.ModelDetail{}, fmt.Errorf("model not found on %s: %s", provider, modelID)
}

func mergeModelLists(primary []types.ModelSummary, secondary []types.ModelSummary, limit int) []types.ModelSummary {
	merged := make([]types.ModelSummary, 0, len(primary)+len(secondary))
	merged = append(merged, primary...)
	merged = append(merged, secondary...)
	merged = deduplicateModels(merged)
	return trimModels(merged, limit)
}

func trimModels(models []types.ModelSummary, limit int) []types.ModelSummary {
	if limit <= 0 || len(models) <= limit {
		return models
	}
	return models[:limit]
}

func deduplicateModels(models []types.ModelSummary) []types.ModelSummary {
	seen := make(map[string]struct{}, len(models))
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		key := strings.ToLower(strings.TrimSpace(model.Provider + ":" + model.ModelID))
		if key == ":" || key == "" {
			key = strings.ToLower(strings.TrimSpace(model.ID))
		}
		if key == "" {
			continue
		}
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, model)
	}
	return out
}

func defaultHuggingFaceSuggestions() []types.ModelSummary {
	return []types.ModelSummary{
		{
			ID:            types.ProviderHuggingFace + ":bartowski/Llama-3.2-3B-Instruct-GGUF",
			Provider:      types.ProviderHuggingFace,
			ModelID:       "bartowski/Llama-3.2-3B-Instruct-GGUF",
			DisplayName:   "Llama 3.2 3B Instruct GGUF",
			Name:          "Llama 3.2 3B Instruct GGUF",
			Description:   "Popular GGUF instruct model",
			Format:        "gguf",
			Formats:       []string{"gguf"},
			Quantizations: []string{"q4_k_m", "q8_0"},
			Author:        "bartowski",
			Downloads:     52400,
			SizeBytes:     3220000000,
			ContextLength: 128000,
			DownloadOptions: []types.DownloadOption{
				{Label: "Q4_K_M GGUF", AssetID: "Llama-3.2-3B-Instruct-Q4_K_M.gguf", Format: "gguf", SizeBytes: 3220000000},
				{Label: "Q8_0 GGUF", AssetID: "Llama-3.2-3B-Instruct-Q8_0.gguf", Format: "gguf", SizeBytes: 6100000000},
			},
		},
		{
			ID:            types.ProviderHuggingFace + ":bartowski/Qwen2.5-7B-Instruct-GGUF",
			Provider:      types.ProviderHuggingFace,
			ModelID:       "bartowski/Qwen2.5-7B-Instruct-GGUF",
			DisplayName:   "Qwen2.5 7B Instruct GGUF",
			Name:          "Qwen2.5 7B Instruct GGUF",
			Description:   "Popular GGUF instruct model",
			Format:        "gguf",
			Formats:       []string{"gguf"},
			Quantizations: []string{"q4_k_m", "q8_0"},
			Author:        "bartowski",
			Downloads:     28450,
			SizeBytes:     5820000000,
			ContextLength: 32768,
			DownloadOptions: []types.DownloadOption{
				{Label: "Q4_K_M GGUF", AssetID: "Qwen2.5-7B-Instruct-Q4_K_M.gguf", Format: "gguf", SizeBytes: 5820000000},
				{Label: "Q8_0 GGUF", AssetID: "Qwen2.5-7B-Instruct-Q8_0.gguf", Format: "gguf", SizeBytes: 8200000000},
			},
		},
		{
			ID:            types.ProviderHuggingFace + ":TheBloke/Mistral-7B-Instruct-v0.2-GGUF",
			Provider:      types.ProviderHuggingFace,
			ModelID:       "TheBloke/Mistral-7B-Instruct-v0.2-GGUF",
			DisplayName:   "Mistral 7B Instruct v0.2 GGUF",
			Name:          "Mistral 7B Instruct v0.2 GGUF",
			Description:   "Popular GGUF instruct model",
			Format:        "gguf",
			Formats:       []string{"gguf"},
			Quantizations: []string{"q4_k_m", "q8_0"},
			Author:        "TheBloke",
			Downloads:     873900,
			SizeBytes:     4370000000,
			ContextLength: 32768,
			DownloadOptions: []types.DownloadOption{
				{Label: "Q4_K_M GGUF", AssetID: "mistral-7b-instruct-v0.2.Q4_K_M.gguf", Format: "gguf", SizeBytes: 4370000000},
				{Label: "Q8_0 GGUF", AssetID: "mistral-7b-instruct-v0.2.Q8_0.gguf", Format: "gguf", SizeBytes: 7700000000},
			},
		},
	}
}

func defaultOpenRouterSuggestions() []types.ModelSummary {
	return []types.ModelSummary{
		{
			ID:          types.ProviderOpenRouter + ":google/gemini-2.5-pro",
			Provider:    types.ProviderOpenRouter,
			ModelID:     "google/gemini-2.5-pro",
			DisplayName: "Gemini 2.5 Pro",
			Name:        "Gemini 2.5 Pro",
			Description: "Google's flagship reasoning model",
			Format:      "api",
			Formats:     []string{"api"},
			Author:      "google",
			Downloads:   245000,
			SizeBytes:   0,
			DownloadOptions: []types.DownloadOption{
				{
					Label:   "OpenRouter API: google/gemini-2.5-pro",
					AssetID: "google/gemini-2.5-pro",
					Format:  "api",
				},
			},
		},
		{
			ID:          types.ProviderOpenRouter + ":openai/gpt-4o",
			Provider:    types.ProviderOpenRouter,
			ModelID:     "openai/gpt-4o",
			DisplayName: "GPT-4o",
			Name:        "GPT-4o",
			Description: "OpenAI's high-intelligence flagship model",
			Format:      "api",
			Formats:     []string{"api"},
			Author:      "openai",
			Downloads:   523000,
			SizeBytes:   0,
			DownloadOptions: []types.DownloadOption{
				{
					Label:   "OpenRouter API: openai/gpt-4o",
					AssetID: "openai/gpt-4o",
					Format:  "api",
				},
			},
		},
		{
			ID:          types.ProviderOpenRouter + ":meta-llama/llama-3.3-70b-instruct",
			Provider:    types.ProviderOpenRouter,
			ModelID:     "meta-llama/llama-3.3-70b-instruct",
			DisplayName: "Llama 3.3 70B Instruct",
			Name:        "Llama 3.3 70B Instruct",
			Description: "State-of-the-art open weights 70B model from Meta",
			Format:      "api",
			Formats:     []string{"api"},
			Author:      "meta-llama",
			Downloads:   184000,
			SizeBytes:   0,
			DownloadOptions: []types.DownloadOption{
				{
					Label:   "OpenRouter API: meta-llama/llama-3.3-70b-instruct",
					AssetID: "meta-llama/llama-3.3-70b-instruct",
					Format:  "api",
				},
			},
		},
	}
}

func defaultFeatherlessSuggestions() []types.ModelSummary {
	return []types.ModelSummary{
		{
			ID:          types.ProviderFeatherless + ":vicgalle/Roleplay-Llama-3-8B",
			Provider:    types.ProviderFeatherless,
			ModelID:     "vicgalle/Roleplay-Llama-3-8B",
			DisplayName: "Roleplay Llama 3 8B",
			Name:        "Roleplay Llama 3 8B",
			Description: "Llama-3 8B fine-tuned for roleplay applications",
			Format:      "api",
			Formats:     []string{"api"},
			Author:      "vicgalle",
			Downloads:   32000,
			SizeBytes:   0,
			DownloadOptions: []types.DownloadOption{
				{
					Label:   "Featherless API: vicgalle/Roleplay-Llama-3-8B",
					AssetID: "vicgalle/Roleplay-Llama-3-8B",
					Format:  "api",
				},
			},
		},
		{
			ID:          types.ProviderFeatherless + ":meta-llama/Meta-Llama-3-8B-Instruct",
			Provider:    types.ProviderFeatherless,
			ModelID:     "meta-llama/Meta-Llama-3-8B-Instruct",
			DisplayName: "Llama 3 8B Instruct",
			Name:        "Llama 3 8B Instruct",
			Description: "Meta's standard 8B instruct model",
			Format:      "api",
			Formats:     []string{"api"},
			Author:      "meta-llama",
			Downloads:   74000,
			SizeBytes:   0,
			DownloadOptions: []types.DownloadOption{
				{
					Label:   "Featherless API: meta-llama/Meta-Llama-3-8B-Instruct",
					AssetID: "meta-llama/Meta-Llama-3-8B-Instruct",
					Format:  "api",
				},
			},
		},
	}
}
