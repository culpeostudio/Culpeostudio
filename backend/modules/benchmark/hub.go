package benchmark

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
)

type hubModel struct {
	ID               string                 `json:"id"`
	Likes            int                    `json:"likes"`
	Downloads        int64                  `json:"downloads"`
	DownloadsAllTime int64                  `json:"downloadsAllTime"`
	TrendingScore    float64                `json:"trendingScore"`
	LastModified     string                 `json:"lastModified"`
	PipelineTag      string                 `json:"pipeline_tag"`
	Gated            interface{}            `json:"gated"`
	Tags             []string               `json:"tags"`
	Safetensors      *hubSafetensors        `json:"safetensors"`
	CardData         map[string]interface{} `json:"cardData"`
	Providers        map[string]interface{} `json:"inferenceProviderMapping"`
}

type hubSafetensors struct {
	Total int64 `json:"total"`
}

var hubExpandFields = []string{
	"likes", "downloads", "downloadsAllTime", "trendingScore", "lastModified",
	"pipeline_tag", "gated", "tags", "safetensors", "cardData",
	"inferenceProviderMapping",
}

func fetchHubStats(ctx context.Context, client *http.Client, hubBase, modelID, token string) (*HubStats, []CardResult, error) {
	modelID = strings.TrimSpace(modelID)
	if modelID == "" {
		return nil, nil, fmt.Errorf("leere Modellkennung")
	}

	params := url.Values{}
	for _, field := range hubExpandFields {
		params.Add("expand[]", field)
	}
	endpoint := strings.TrimRight(hubBase, "/") + "/api/models/" + encodeModelPath(modelID) + "?" + params.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, nil, err
	}
	req.Header.Set("Accept", "application/json")
	if strings.TrimSpace(token) != "" {
		req.Header.Set("Authorization", "Bearer "+strings.TrimSpace(token))
	}

	res, err := client.Do(req)
	if err != nil {
		return nil, nil, err
	}
	defer res.Body.Close()

	if res.StatusCode == http.StatusNotFound || res.StatusCode == http.StatusUnauthorized {
		return &HubStats{ModelID: modelID, Missing: true}, nil, nil
	}
	if res.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 512))
		return nil, nil, fmt.Errorf("hub antwortete mit %d: %s", res.StatusCode, strings.TrimSpace(string(body)))
	}

	var parsed hubModel
	if err := json.NewDecoder(res.Body).Decode(&parsed); err != nil {
		return nil, nil, fmt.Errorf("hub-antwort unlesbar: %w", err)
	}

	stats := &HubStats{
		ModelID:          modelID,
		Likes:            parsed.Likes,
		Downloads30d:     parsed.Downloads,
		DownloadsAllTime: parsed.DownloadsAllTime,
		TrendingScore:    parsed.TrendingScore,
		LastModified:     parsed.LastModified,
		PipelineTag:      parsed.PipelineTag,
		Gated:            isGated(parsed.Gated),
		Tags:             parsed.Tags,
		Providers:        liveProviders(parsed.Providers),
	}
	if parsed.Safetensors != nil {
		stats.ParamsTotal = parsed.Safetensors.Total
	}
	return stats, parseCardResults(parsed.CardData), nil
}

func encodeModelPath(modelID string) string {
	parts := strings.Split(modelID, "/")
	for i, part := range parts {
		parts[i] = url.PathEscape(part)
	}
	return strings.Join(parts, "/")
}

func isGated(value interface{}) bool {
	switch typed := value.(type) {
	case bool:
		return typed
	case string:
		return strings.TrimSpace(typed) != "" && !strings.EqualFold(typed, "false")
	}
	return false
}

func liveProviders(mapping map[string]interface{}) []string {
	if len(mapping) == 0 {
		return nil
	}
	providers := make([]string, 0, len(mapping))
	for name, raw := range mapping {
		entry, ok := raw.(map[string]interface{})
		if !ok {
			continue
		}
		if status, _ := entry["status"].(string); !strings.EqualFold(status, "live") {
			continue
		}
		providers = append(providers, name)
	}
	sort.Strings(providers)
	return providers
}

func parseCardResults(cardData map[string]interface{}) []CardResult {
	if len(cardData) == 0 {
		return nil
	}
	index, ok := cardData["model-index"].([]interface{})
	if !ok {
		return nil
	}

	results := make([]CardResult, 0, 8)
	for _, rawModel := range index {
		model, ok := rawModel.(map[string]interface{})
		if !ok {
			continue
		}
		rawResults, ok := model["results"].([]interface{})
		if !ok {
			continue
		}
		for _, rawResult := range rawResults {
			result, ok := rawResult.(map[string]interface{})
			if !ok {
				continue
			}
			taskName := nestedString(result, "task", "name", "type")
			datasetName := nestedString(result, "dataset", "name", "type")
			rawMetrics, ok := result["metrics"].([]interface{})
			if !ok {
				continue
			}
			for _, rawMetric := range rawMetrics {
				metric, ok := rawMetric.(map[string]interface{})
				if !ok {
					continue
				}
				value, ok := metric["value"].(float64)
				if !ok {
					continue
				}
				name, _ := metric["name"].(string)
				if strings.TrimSpace(name) == "" {
					name, _ = metric["type"].(string)
				}
				verified, _ := metric["verified"].(bool)
				results = append(results, CardResult{
					Task:    taskName,
					Dataset: datasetName,
					Metric:  strings.TrimSpace(name),
					Value:   value,
					Verifed: verified,
				})
			}
		}
	}
	if len(results) == 0 {
		return nil
	}
	return results
}

func nestedString(source map[string]interface{}, object string, keys ...string) string {
	nested, ok := source[object].(map[string]interface{})
	if !ok {
		return ""
	}
	for _, key := range keys {
		if value, ok := nested[key].(string); ok && strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}
