package featherless

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/fillyengine/backend/modules/marktplatz/common"
	"github.com/fillyengine/backend/modules/marktplatz/types"
)

type featherlessModel struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	ModelClass string `json:"model_class"`
}

type featherlessResponse struct {
	Data []featherlessModel `json:"data"`
}

// catalogCacheTTL: Katalog bleibt 15min gueltig; vermeidet, dass pro Request
// die gesamte Featherless-Modelliste neu geladen+decodiert wird. Siehe H8.
const catalogCacheTTL = 15 * time.Minute

// catalogCache haelt die rohe Provider-Antwort mit Zeitstempel vor.
// Schreibzugriff nur unter catalogMu.
var (
	catalogMu     sync.Mutex
	cachedCatalog []featherlessModel
	cachedAt      time.Time
)

// staticPublicFallback ist eine kleine eingebaute Liste fuer den Fall, dass
// Featherless nur noch Public-Access ermoeglicht (401 mit gespeichertem
// Token). Frueher wurde bei JEDEM Fehler (5xx, Netzwerk, etc.) dieser Fallback
// geliefert und der User bekam eine scheinbar aktuelle, in Wahrheit stale
// Liste – `partial` wurde nie gesetzt. M2.
func staticPublicFallback() []featherlessModel {
	return []featherlessModel{
		{ID: "vicgalle/Roleplay-Llama-3-8B", Name: "Roleplay Llama 3 8B", ModelClass: "llama3-8b"},
		{ID: "meta-llama/Meta-Llama-3-8B-Instruct", Name: "Llama 3 8B Instruct", ModelClass: "llama3-8b"},
		{ID: "meta-llama/Meta-Llama-3-70B-Instruct", Name: "Llama 3 70B Instruct", ModelClass: "llama3-70b"},
		{ID: "meta-llama/Meta-Llama-3.1-8B-Instruct", Name: "Llama 3.1 8B Instruct", ModelClass: "llama3.1-8b"},
		{ID: "meta-llama/Meta-Llama-3.1-70B-Instruct", Name: "Llama 3.1 70B Instruct", ModelClass: "llama3.1-70b"},
		{ID: "mistralai/Mistral-7B-Instruct-v0.3", Name: "Mistral 7B Instruct v0.3", ModelClass: "mistral-7b"},
		{ID: "mistralai/Mixtral-8x7B-Instruct-v0.1", Name: "Mixtral 8x7B Instruct", ModelClass: "mixtral-8x7b"},
		{ID: "Qwen/Qwen2.5-7B-Instruct", Name: "Qwen 2.5 7B Instruct", ModelClass: "qwen2.5-7b"},
		{ID: "Qwen/Qwen2.5-14B-Instruct", Name: "Qwen 2.5 14B Instruct", ModelClass: "qwen2.5-14b"},
		{ID: "Qwen/Qwen2.5-72B-Instruct", Name: "Qwen 2.5 72B Instruct", ModelClass: "qwen2.5-72b"},
		{ID: "google/gemma-2-9b-it", Name: "Gemma 2 9B IT", ModelClass: "gemma2-9b"},
		{ID: "google/gemma-2-27b-it", Name: "Gemma 2 27B IT", ModelClass: "gemma2-27b"},
		{ID: "microsoft/Phi-3-mini-128k-instruct", Name: "Phi 3 Mini 128K Instruct", ModelClass: "phi3-3b"},
		{ID: "microsoft/Phi-3-medium-128k-instruct", Name: "Phi 3 Medium 128K Instruct", ModelClass: "phi3-14b"},
		{ID: "Sao10K/Llama-3-8B-Instruct-Gradient-1048k", Name: "Llama 3 8B Gradient 1M", ModelClass: "llama3-8b"},
		{ID: "Sao10K/Fimbulvetr-11B-v1.2.2", Name: "Fimbulvetr 11B", ModelClass: "fimbulvetr-11b"},
		{ID: "Undi95/Toppy-M-7B", Name: "Toppy M 7B", ModelClass: "toppy-7b"},
		{ID: "Gryphe/Mythalion-13b", Name: "Mythalion 13B", ModelClass: "mythalion-13b"},
		{ID: "Gryphe/Mythomax-L2-13b", Name: "Mythomax L2 13B", ModelClass: "mythomax-13b"},
		{ID: "jondurbin/airoboros-l3-8b-gpt4-1.4.1", Name: "Airoboros L3 8B GPT4", ModelClass: "airoboros-8b"},
		{ID: "alpindale/goliath-120b", Name: "Goliath 120B", ModelClass: "goliath-120b"},
		{ID: "NeverSleep/Llama-3-Lumimaid-8B-v0.1", Name: "Llama 3 Lumimaid 8B", ModelClass: "lumimaid-8b"},
		{ID: "NeverSleep/Noromaid-20b-v0.1.1", Name: "Noromaid 20B", ModelClass: "noromaid-20b"},
		{ID: "cognitivecomputations/dolphin-2.9-llama3-8b", Name: "Dolphin 2.9 Llama 3 8B", ModelClass: "dolphin-8b"},
		{ID: "cognitivecomputations/dolphin-2.9.1-yi-1.5-34b", Name: "Dolphin 2.9.1 Yi 34B", ModelClass: "dolphin-34b"},
		{ID: "NousResearch/Hermes-3-Llama-3.1-8B", Name: "Hermes 3 Llama 3.1 8B", ModelClass: "hermes-8b"},
		{ID: "NousResearch/Hermes-3-Llama-3.1-70B", Name: "Hermes 3 Llama 3.1 70B", ModelClass: "hermes-70b"},
		{ID: "NousResearch/Nous-Hermes-2-Yi-34B", Name: "Hermes 2 Yi 34B", ModelClass: "hermes-34b"},
		{ID: "shenzhi-wang/Llama3-8B-Chinese-Chat", Name: "Llama 3 8B Chinese Chat", ModelClass: "llama3-8b"},
	}
}

// loadCatalog laedt den Featherless-Katalog (mit TTL-Cache) und liefert die
// rohen Eintraege. Bei 401 wird der staticPublicFallback geliefert; bei
// anderen Fehlern (5xx, Netzwerk) wird der Fehler durchgereicht, damit der
// Handler `partial=true` und die Fehlermeldung melden kann. M2.
func loadCatalog(ctx context.Context, httpClient *http.Client, apiBase, token string) ([]featherlessModel, error) {
	catalogMu.Lock()
	if len(cachedCatalog) > 0 && time.Since(cachedAt) < catalogCacheTTL {
		out := cachedCatalog
		catalogMu.Unlock()
		return out, nil
	}
	catalogMu.Unlock()

	apiURL := strings.TrimRight(apiBase, "/") + "/v1/models"
	headers := map[string]string{}
	if strings.TrimSpace(token) != "" {
		headers["Authorization"] = "Bearer " + strings.TrimSpace(token)
	}

	var response featherlessResponse
	if err := common.RequestJSON(ctx, httpClient, "GET", apiURL, headers, &response); err != nil {
		// Nur 401 (public access limit) -> Fallback; andere Fehler weiterreichen.
		if isUnauthorizedErr(err) {
			return staticPublicFallback(), nil
		}
		return nil, err
	}
	if len(response.Data) == 0 {
		// Kein Fehler, aber leere Antwort – einmalig Fallback, nicht cachen.
		return staticPublicFallback(), nil
	}

	catalogMu.Lock()
	cachedCatalog = response.Data
	cachedAt = time.Now()
	catalogMu.Unlock()
	return response.Data, nil
}

// InvalidateCache ist ein Test-Hook, um den Katalog-Cache zwischen Tests
// zurueckzusetzen. Produktivcode sollte ihn nicht aufrufen.
func InvalidateCache() {
	catalogMu.Lock()
	cachedCatalog = nil
	cachedAt = time.Time{}
	catalogMu.Unlock()
}

func SearchFeatherless(ctx context.Context, httpClient *http.Client, apiBase, query, format string, limit int, token string) ([]types.ModelSummary, error) {
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
		if name == "" {
			name = modelID
		}

		// Filter by query
		if q != "" {
			if !strings.Contains(strings.ToLower(modelID), q) && !strings.Contains(strings.ToLower(name), q) {
				continue
			}
		}

		author := "Featherless"
		parts := strings.Split(modelID, "/")
		if len(parts) > 1 {
			author = parts[0]
		}

		out = append(out, types.ModelSummary{
			ID:          types.ProviderFeatherless + ":" + modelID,
			Provider:    types.ProviderFeatherless,
			ModelID:     modelID,
			DisplayName: name,
			Name:        name,
			Description: "Featherless " + model.ModelClass + " model",
			Format:      "api",
			Formats:     []string{"api"},
			Author:      author,
			Downloads:   45000,
			SizeBytes:   0,
			DownloadOptions: []types.DownloadOption{
				{
					Label:   "Featherless API: " + modelID,
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

// DetailFeatherless sucht ein einzelnes Modell im (ggf. gecachten) Katalog.
// Liefert reichere Metadaten als ein teurer Remote-Aufruf und vermeidet,
// dass fuer jede Detail-Anzeige der komplette Katalog neu geladen wird. H8.
func DetailFeatherless(ctx context.Context, httpClient *http.Client, apiBase string, modelID string, token string) (types.ModelDetail, error) {
	list, err := SearchFeatherless(ctx, httpClient, apiBase, modelID, "", 0, token)
	if err != nil {
		return types.ModelDetail{}, err
	}
	for _, summary := range list {
		if strings.EqualFold(summary.ModelID, modelID) {
			return types.ModelDetail{
				ModelSummary: summary,
				Tags:         []string{"api", "cloud", "featherless"},
				Metadata: map[string]interface{}{
					"source": "featherless",
				},
			}, nil
		}
	}
	return types.ModelDetail{}, fmt.Errorf("model not found on Featherless: %s", modelID)
}

// isUnauthorizedErr erkennt 401-Antworten von Featherless (gleicher Stil wie
// HuggingFace).
func isUnauthorizedErr(err error) bool {
	if err == nil {
		return false
	}
	return strings.Contains(strings.ToLower(err.Error()), "(401)")
}
