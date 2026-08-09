package huggingface

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/culpeohq/backend/modules/marketplace/common"
	"github.com/culpeohq/backend/modules/marketplace/types"
)

type HuggingFaceSibling struct {
	RFilename string `json:"rfilename"`
	Size      int64  `json:"size,omitempty"`
}

type HuggingFaceModel struct {
	ID          string                 `json:"id"`
	SHA         string                 `json:"sha,omitempty"`
	Author      string                 `json:"author"`
	Downloads   int64                  `json:"downloads"`
	PipelineTag string                 `json:"pipeline_tag"`
	Tags        []string               `json:"tags"`
	Config      map[string]interface{} `json:"config"`
	Siblings    []HuggingFaceSibling   `json:"siblings"`
}

type BundleDescriptor struct {
	Revision  string   `json:"revision"`
	CommitSHA string   `json:"commit_sha,omitempty"`
	Format    string   `json:"format"`
	Assets    []string `json:"assets"`
}

func SearchHuggingFace(ctx context.Context, httpClient *http.Client, apiBase, query, format string, limit int, token string) ([]types.ModelSummary, error) {
	models, err := fetchHFModels(ctx, httpClient, apiBase, query, limit, token)
	if err != nil {
		return nil, err
	}
	return mapHFModels(models, format), nil
}

func fetchHFModels(ctx context.Context, httpClient *http.Client, apiBase, query string, limit int, token string) ([]HuggingFaceModel, error) {
	params := url.Values{}
	params.Set("limit", fmt.Sprintf("%d", limit))
	params.Set("full", "true")
	if strings.TrimSpace(query) != "" {
		params.Set("search", strings.TrimSpace(query))
	}
	apiURL := strings.TrimRight(apiBase, "/") + "/api/models?" + params.Encode()
	authHeaders := map[string]string{}
	if strings.TrimSpace(token) != "" {
		authHeaders["Authorization"] = "Bearer " + strings.TrimSpace(token)
	}

	var models []HuggingFaceModel
	if err := common.RequestJSON(ctx, httpClient, "GET", apiURL, authHeaders, &models); err != nil {

		if strings.TrimSpace(token) != "" && IsUnauthorizedError(err) {
			if retryErr := common.RequestJSON(ctx, httpClient, "GET", apiURL, nil, &models); retryErr == nil {
				return models, nil
			}
		}
		return nil, err
	}
	return models, nil
}

func mapHFModels(models []HuggingFaceModel, format string) []types.ModelSummary {
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		modelID := strings.TrimSpace(model.ID)
		if modelID == "" {
			continue
		}

		options := BuildHuggfaceFilteredOptions(model.Siblings)
		formats := ExtractFormatsFromHFOptions(options)
		if !types.MatchesFormat(formats, format) {
			continue
		}

		display := modelID
		description := strings.TrimSpace(model.PipelineTag)

		author := strings.TrimSpace(model.Author)
		if author == "" {
			parts := strings.Split(modelID, "/")
			if len(parts) > 1 {
				author = parts[0]
			} else {
				author = "HuggingFace"
			}
		}

		sizeBytes := minOptionSizeBytes(options)
		contextLength := extractContextLength(model.Config, model.Tags)

		out = append(out, types.ModelSummary{
			ID:              types.ProviderHuggingFace + ":" + modelID,
			Provider:        types.ProviderHuggingFace,
			ModelID:         modelID,
			DisplayName:     display,
			Name:            display,
			Description:     description,
			Format:          types.FirstNonEmpty(formats...),
			Formats:         formats,
			Author:          author,
			Downloads:       model.Downloads,
			SizeBytes:       sizeBytes,
			ContextLength:   contextLength,
			DownloadOptions: options,
		})
	}
	return out
}

func DetailHuggingFace(ctx context.Context, httpClient *http.Client, apiBase, modelID string, token string) (types.ModelDetail, error) {
	repoPath := hfRepoPath(modelID)

	apiURL := strings.TrimRight(apiBase, "/") + "/api/models/" + repoPath + "?blobs=true"
	authHeaders := map[string]string{}
	if strings.TrimSpace(token) != "" {
		authHeaders["Authorization"] = "Bearer " + strings.TrimSpace(token)
	}

	model, err := fetchHFDetailModel(ctx, httpClient, apiURL, authHeaders, token)
	if err != nil {
		return types.ModelDetail{}, err
	}

	if strings.TrimSpace(model.ID) == "" {
		return types.ModelDetail{}, fmt.Errorf("model not found")
	}

	options := BuildHuggfaceFilteredOptions(model.Siblings)
	formats := ExtractFormatsFromHFOptions(options)
	author := strings.TrimSpace(model.Author)
	if author == "" {
		parts := strings.Split(model.ID, "/")
		if len(parts) > 1 {
			author = parts[0]
		} else {
			author = "HuggingFace"
		}
	}

	sizeBytes := minOptionSizeBytes(options)
	contextLength := extractContextLength(model.Config, model.Tags)

	summary := types.ModelSummary{
		ID:              types.ProviderHuggingFace + ":" + model.ID,
		Provider:        types.ProviderHuggingFace,
		ModelID:         model.ID,
		DisplayName:     model.ID,
		Name:            model.ID,
		Description:     strings.TrimSpace(model.PipelineTag),
		Format:          types.FirstNonEmpty(formats...),
		Formats:         formats,
		Author:          author,
		Downloads:       model.Downloads,
		SizeBytes:       sizeBytes,
		ContextLength:   contextLength,
		DownloadOptions: options,
	}

	return types.ModelDetail{
		ModelSummary: summary,
		Tags:         types.UniqueNonEmptyLower(model.Tags),
		Metadata: map[string]interface{}{
			"source": "huggingface",
		},
	}, nil
}

var contextKeys = map[string]struct{}{
	"max_position_embeddings": {},
	"max_sequence_length":     {},
	"max_seq_len":             {},
	"model_max_length":        {},
	"n_positions":             {},
	"seq_length":              {},
}

func extractContextLength(config map[string]interface{}, tags []string) int {
	if value := findContextValue(config); value > 0 {
		return value
	}
	for _, tag := range tags {
		clean := strings.ToLower(strings.TrimSpace(tag))
		for _, prefix := range []string{"context:", "context_length:", "max_context:"} {
			if strings.HasPrefix(clean, prefix) {
				if value := parseContextText(strings.TrimPrefix(clean, prefix)); value > 0 {
					return value
				}
			}
		}
	}
	return 0
}

func findContextValue(values map[string]interface{}) int {
	for key, value := range values {
		cleanKey := strings.ToLower(strings.TrimSpace(key))
		if _, ok := contextKeys[cleanKey]; ok {
			if context := parseContextValue(value); context > 0 && context < 20_000_000 {
				return context
			}
		}
		if nested, ok := value.(map[string]interface{}); ok {
			if context := findContextValue(nested); context > 0 {
				return context
			}
		}
	}
	return 0
}

func parseContextValue(value interface{}) int {
	switch typed := value.(type) {
	case float64:
		return int(typed)
	case float32:
		return int(typed)
	case int:
		return typed
	case string:
		return parseContextText(typed)
	default:
		return 0
	}
}

func parseContextText(value string) int {
	clean := strings.ToLower(strings.TrimSpace(value))
	clean = strings.TrimSuffix(clean, "tokens")
	clean = strings.TrimSpace(clean)
	multiplier := 1
	if strings.HasSuffix(clean, "k") {
		multiplier = 1000
		clean = strings.TrimSuffix(clean, "k")
	}
	parsed, err := strconv.ParseFloat(strings.TrimSpace(clean), 64)
	if err != nil || parsed <= 0 {
		return 0
	}
	return int(parsed * float64(multiplier))
}

func fetchHFDetailModel(ctx context.Context, httpClient *http.Client, apiURL string, authHeaders map[string]string, token string) (HuggingFaceModel, error) {
	var model HuggingFaceModel
	if err := common.RequestJSON(ctx, httpClient, "GET", apiURL, authHeaders, &model); err != nil {
		if strings.TrimSpace(token) != "" && IsUnauthorizedError(err) {
			if retryErr := common.RequestJSON(ctx, httpClient, "GET", apiURL, nil, &model); retryErr == nil {
				return model, nil
			}
		}
		return HuggingFaceModel{}, err
	}
	return model, nil
}

func DownloadHuggingFaceRevisionWithStats(ctx context.Context, httpClient *http.Client, apiBase, modelID, revision, assetID, targetDir, token string, onProgress func(int), onStats func(int64, int64, int64)) (string, error) {
	modelID = strings.TrimSpace(modelID)
	if modelID == "" {
		return "", fmt.Errorf("model_id is required")
	}
	assetID = strings.TrimSpace(assetID)

	if assetID == "default-asset" {
		assetID = ""
	}
	if assetID == "" {
		detail, err := DetailHuggingFace(ctx, httpClient, apiBase, modelID, token)
		if err != nil {
			return "", err
		}
		for _, option := range detail.DownloadOptions {
			if strings.EqualFold(option.Format, "gguf") && strings.TrimSpace(option.AssetID) != "" {
				assetID = option.AssetID
				break
			}
		}
		if assetID == "" && len(detail.DownloadOptions) > 0 {
			assetID = detail.DownloadOptions[0].AssetID
		}
		if strings.TrimSpace(assetID) == "" {
			return "", fmt.Errorf("no downloadable asset found for model %s", modelID)
		}
	}

	headers := map[string]string{}
	if strings.TrimSpace(token) != "" {
		headers["Authorization"] = "Bearer " + strings.TrimSpace(token)
	}

	revision = strings.TrimSpace(revision)
	if revision == "" {
		revision = "main"
	}
	sourceURL := assetID
	fileName := ""
	if strings.HasPrefix(assetID, "http://") || strings.HasPrefix(assetID, "https://") {
		parsed, err := url.Parse(assetID)
		if err == nil {
			fileName = filepath.Base(parsed.Path)
		}
	} else {
		sourceURL = fmt.Sprintf("%s/%s/resolve/%s/%s", strings.TrimRight(apiBase, "/"), hfRepoPath(modelID), url.PathEscape(revision), hfAssetPath(assetID))
		fileName = assetID
	}
	if strings.TrimSpace(fileName) == "" {
		fileName = strings.ReplaceAll(modelID, "/", "_") + ".bin"
	}

	candidates := []string{
		sourceURL,
		addDownloadQuery(sourceURL),
	}
	if !strings.HasPrefix(assetID, "http://") && !strings.HasPrefix(assetID, "https://") {
		escaped := fmt.Sprintf(
			"%s/%s/resolve/%s/%s",
			strings.TrimRight(apiBase, "/"),
			url.PathEscape(modelID),
			url.PathEscape(revision),
			url.PathEscape(assetID),
		)
		candidates = append(candidates, escaped, addDownloadQuery(escaped))
	}

	var lastErr error
	for _, candidate := range types.UniqueNonEmpty(candidates) {
		outputPath, err := common.DownloadFileWithStats(ctx, httpClient, candidate, headers, targetDir, fileName, onProgress, onStats)
		if err == nil {
			return outputPath, nil
		}
		lastErr = err
		if strings.TrimSpace(token) != "" && IsUnauthorizedError(err) {
			outputPath, retryErr := common.DownloadFileWithStats(ctx, httpClient, candidate, nil, targetDir, fileName, onProgress, onStats)
			if retryErr == nil {
				return outputPath, nil
			}
			lastErr = retryErr
		}
	}
	if lastErr == nil {
		lastErr = fmt.Errorf("huggingface download failed")
	}
	return "", lastErr
}

func ResolveBundleAssets(ctx context.Context, httpClient *http.Client, apiBase, modelID, revision, token string, requested []string) (BundleDescriptor, error) {
	modelID = strings.TrimSpace(modelID)
	if modelID == "" {
		return BundleDescriptor{}, fmt.Errorf("model_id is required")
	}
	revision = strings.TrimSpace(revision)
	if revision == "" {
		revision = "main"
	}
	apiURL := strings.TrimRight(apiBase, "/") + "/api/models/" + hfRepoPath(modelID)
	if revision != "main" {
		apiURL += "/revision/" + url.PathEscape(revision)
	}
	apiURL += "?blobs=true"
	headers := map[string]string{}
	if strings.TrimSpace(token) != "" {
		headers["Authorization"] = "Bearer " + strings.TrimSpace(token)
	}
	model, err := fetchHFDetailModel(ctx, httpClient, apiURL, headers, token)
	if err != nil {
		return BundleDescriptor{}, err
	}
	available := make(map[string]HuggingFaceSibling, len(model.Siblings))
	for _, sibling := range model.Siblings {
		name := strings.TrimSpace(sibling.RFilename)
		if name != "" {
			available[name] = sibling
		}
	}
	assets := types.UniqueNonEmpty(requested)
	if len(assets) == 0 {
		options := BuildHuggfaceFilteredOptions(model.Siblings)
		if len(options) == 0 {
			return BundleDescriptor{}, fmt.Errorf("no downloadable model weights found")
		}
		assets = append(assets, options[0].AssetIDs...)
		if len(assets) == 0 {
			assets = []string{options[0].AssetID}
		}
	}
	format := "gguf"
	for _, asset := range assets {
		if _, ok := available[asset]; !ok {
			return BundleDescriptor{}, fmt.Errorf("asset %q is not part of repository %s", asset, modelID)
		}
		if strings.EqualFold(filepath.Ext(asset), ".safetensors") {
			format = "safetensors"
		}
	}
	if format == "safetensors" {
		for name := range available {
			if isSafeTensorSupportAsset(name) {
				assets = append(assets, name)
			}
		}
	}
	assets = types.UniqueNonEmpty(assets)
	for _, asset := range assets {
		if _, ok := common.SafeRelativePath(asset); !ok {
			return BundleDescriptor{}, fmt.Errorf("unsafe repository asset path %q", asset)
		}
	}
	return BundleDescriptor{Revision: revision, CommitSHA: strings.TrimSpace(model.SHA), Format: format, Assets: assets}, nil
}

func isSafeTensorSupportAsset(name string) bool {
	clean := strings.ToLower(strings.TrimSpace(filepath.ToSlash(name)))
	base := filepath.Base(clean)
	if clean == "config.json" || clean == "model.safetensors.index.json" || strings.HasSuffix(clean, ".py") {
		return true
	}
	if strings.HasPrefix(base, "tokenizer") || strings.HasPrefix(base, "special_tokens") || strings.HasPrefix(base, "added_tokens") || strings.HasPrefix(base, "chat_template") {
		return true
	}
	if base == "generation_config.json" || base == "preprocessor_config.json" || base == "processor_config.json" || base == "vocab.json" || base == "vocab.txt" || base == "merges.txt" || strings.HasSuffix(base, ".model") {
		return true
	}
	return false
}

func IsUnauthorizedError(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(strings.TrimSpace(err.Error()))
	return strings.Contains(msg, "(401)")
}

func hfRepoPath(modelID string) string {
	parts := strings.Split(strings.TrimSpace(modelID), "/")
	for i, part := range parts {
		parts[i] = url.PathEscape(strings.TrimSpace(part))
	}
	return strings.Join(parts, "/")
}

func hfAssetPath(assetID string) string {
	parts := strings.Split(strings.TrimSpace(assetID), "/")
	for i, part := range parts {
		parts[i] = url.PathEscape(strings.TrimSpace(part))
	}
	return strings.Join(parts, "/")
}

func addDownloadQuery(rawURL string) string {
	if strings.TrimSpace(rawURL) == "" {
		return rawURL
	}
	parsed, err := url.Parse(rawURL)
	if err != nil {
		return rawURL
	}
	query := parsed.Query()
	query.Set("download", "true")
	parsed.RawQuery = query.Encode()
	return parsed.String()
}

func minOptionSizeBytes(options []types.DownloadOption) int64 {
	var best int64
	for _, option := range options {
		if option.SizeBytes <= 0 {
			continue
		}
		if best == 0 || option.SizeBytes < best {
			best = option.SizeBytes
		}
	}
	return best
}
