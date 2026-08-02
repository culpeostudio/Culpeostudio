// Package openrouter adapts the OpenRouter catalogue to the marketplace provider
// interface.
package openrouter

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/fillyengine/backend/modules/marktplatz/common"
	"github.com/fillyengine/backend/modules/marktplatz/types"
)

type openRouterModel struct {
	ID            string            `json:"id"`
	Name          string            `json:"name"`
	Description   string            `json:"description"`
	ContextLength int               `json:"context_length"`
	Pricing       openRouterPricing `json:"pricing"`
}

type openRouterPricing struct {
	Prompt     string `json:"prompt"`
	Completion string `json:"completion"`
}

type openRouterResponse struct {
	Data []openRouterModel `json:"data"`
}

const catalogCacheTTL = 15 * time.Minute

var (
	catalogMu     sync.Mutex
	cachedCatalog []openRouterModel
	cachedAt      time.Time
)

func loadCatalog(ctx context.Context, httpClient *http.Client, apiBase, token string) ([]openRouterModel, error) {
	catalogMu.Lock()
	if len(cachedCatalog) > 0 && time.Since(cachedAt) < catalogCacheTTL {
		out := cachedCatalog
		catalogMu.Unlock()
		return out, nil
	}
	catalogMu.Unlock()

	apiURL := strings.TrimRight(apiBase, "/") + "/api/v1/models"
	headers := map[string]string{}
	if strings.TrimSpace(token) != "" {
		headers["Authorization"] = "Bearer " + strings.TrimSpace(token)
	}

	var response openRouterResponse
	if err := common.RequestJSON(ctx, httpClient, "GET", apiURL, headers, &response); err != nil {
		return nil, err
	}

	catalogMu.Lock()
	cachedCatalog = response.Data
	cachedAt = time.Now()
	catalogMu.Unlock()
	return response.Data, nil
}

func InvalidateCache() {
	catalogMu.Lock()
	cachedCatalog = nil
	cachedAt = time.Time{}
	catalogMu.Unlock()
}

func SearchOpenRouter(ctx context.Context, httpClient *http.Client, apiBase, query, format string, limit int, token string) ([]types.ModelSummary, error) {
	models, err := loadCatalog(ctx, httpClient, apiBase, token)
	if err != nil {
		return nil, err
	}

	out := make([]types.ModelSummary, 0)
	q := strings.ToLower(strings.TrimSpace(query))

	for _, model := range models {
		modelID := strings.TrimSpace(model.ID)
		if modelID == "" {
			continue
		}

		name := strings.TrimSpace(model.Name)
		desc := strings.TrimSpace(model.Description)

		if q != "" {
			if !strings.Contains(strings.ToLower(modelID), q) && !strings.Contains(strings.ToLower(name), q) {
				continue
			}
		}

		author := "OpenRouter"
		parts := strings.Split(modelID, "/")
		if len(parts) > 1 {
			author = parts[0]
		}
		promptPrice, promptKnown := parseOpenRouterPricePerMillion(model.Pricing.Prompt)
		completionPrice, completionKnown := parseOpenRouterPricePerMillion(model.Pricing.Completion)

		out = append(out, types.ModelSummary{
			ID:               types.ProviderOpenRouter + ":" + modelID,
			Provider:         types.ProviderOpenRouter,
			ModelID:          modelID,
			DisplayName:      name,
			Name:             name,
			Description:      desc,
			Format:           "api",
			Formats:          []string{"api"},
			Author:           author,
			Downloads:        150000,
			SizeBytes:        0,
			ContextLength:    model.ContextLength,
			PricePer1MInput:  promptPrice,
			PricePer1MOutput: completionPrice,
			PriceKnown:       promptKnown || completionKnown,
			DownloadOptions: []types.DownloadOption{
				{
					Label:   "OpenRouter API: " + modelID,
					AssetID: modelID,
					Format:  "api",
				},
			},
		})
		if limit > 0 && len(out) >= limit {
			break
		}
	}

	return out, nil
}

func parseOpenRouterPricePerMillion(raw string) (float64, bool) {
	clean := strings.TrimSpace(raw)
	if clean == "" {
		return 0, false
	}
	value, err := strconv.ParseFloat(clean, 64)
	if err != nil {
		return 0, false
	}
	return value * 1_000_000, true
}

func DetailOpenRouter(ctx context.Context, httpClient *http.Client, apiBase string, modelID string, token string) (types.ModelDetail, error) {
	list, err := SearchOpenRouter(ctx, httpClient, apiBase, modelID, "", 0, token)
	if err != nil {
		return types.ModelDetail{}, err
	}
	for _, summary := range list {
		if strings.EqualFold(summary.ModelID, modelID) {
			return types.ModelDetail{
				ModelSummary: summary,
				Tags:         []string{"api", "cloud", "llm"},
				Metadata: map[string]interface{}{
					"source": "openrouter",
				},
			}, nil
		}
	}
	return types.ModelDetail{}, fmt.Errorf("model not found on OpenRouter: %s", modelID)
}
