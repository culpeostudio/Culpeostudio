package marktplatz

import (
	"math"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

const (
	categoryAll       = ""
	categoryChat      = "chat"
	categoryCode      = "code"
	categoryReasoning = "reasoning"
	categoryVision    = "vision"
	categoryEmbedding = "embedding"
)

var parameterPattern = regexp.MustCompile(`(?i)(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)\s*b|(\d+(?:\.\d+)?)\s*b`)
var contextPattern = regexp.MustCompile(`(?i)(\d+(?:\.\d+)?)\s*(m|k)`)

func normalizeCategory(input string) string {
	c := strings.ToLower(strings.TrimSpace(input))
	c = strings.ReplaceAll(c, "-", "_")
	c = strings.ReplaceAll(c, " ", "_")
	switch c {
	case "", "all", "alle":
		return categoryAll
	case "chat", "code", "reasoning", "vision", "embedding":
		return c
	case "embed", "embeddings":
		return categoryEmbedding
	default:

		return categoryAll
	}
}

func filterModelsByQuery(models []types.ModelSummary, query string) []types.ModelSummary {
	q := strings.ToLower(strings.TrimSpace(query))
	if q == "" {
		return models
	}
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		if strings.Contains(strings.ToLower(model.ModelID), q) ||
			strings.Contains(strings.ToLower(model.Name), q) ||
			strings.Contains(strings.ToLower(model.DisplayName), q) {
			out = append(out, model)
		}
	}
	return out
}

func filterModelsByCategory(models []types.ModelSummary, category string) []types.ModelSummary {
	c := normalizeCategory(category)
	if c == "" {
		return models
	}
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		if normalizeCategory(model.Category) == c || hasCategoryTag(model.CapabilityTags, c) {
			out = append(out, model)
		}
	}
	return out
}

func hasCategoryTag(tags []string, category string) bool {
	for _, tag := range tags {
		if normalizeCategory(tag) == category {
			return true
		}
	}
	return false
}

func filterModelsByFormat(models []types.ModelSummary, format string) []types.ModelSummary {
	if types.NormalizeFormat(format) == "" {
		return models
	}
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		formats := model.Formats
		if len(formats) == 0 && strings.TrimSpace(model.Format) != "" {
			formats = []string{model.Format}
		}
		if types.MatchesFormat(formats, format) {
			out = append(out, model)
		}
	}
	return out
}

func filterModelsByGPUFit(models []types.ModelSummary, gpuOnly bool, profile HardwareProfile, quantization string) []types.ModelSummary {
	if !gpuOnly {
		return models
	}
	out := make([]types.ModelSummary, 0, len(models))
	requestedQuantization := normalizeQuantization(quantization)
	for _, model := range models {
		if model.LocalModel && modelFitsDetectedGPU(model, profile, requestedQuantization) {
			out = append(out, model)
		}
	}
	return out
}

func filterModelsByLocalOnly(models []types.ModelSummary, localOnly bool) []types.ModelSummary {
	if !localOnly {
		return models
	}
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		if model.LocalModel {
			out = append(out, model)
		}
	}
	return out
}

func enrichMarketplaceMetadata(models []types.ModelSummary, profile HardwareProfile) []types.ModelSummary {
	out := enrichModelMetadata(models)
	for i := range out {
		model := &out[i]
		model.ProviderBadge = providerBadge(model.Provider)
		model.LocalModel = isLocalProvider(model.Provider)
		if model.ParameterBadge == "" || model.ParameterCountB == 0 {
			badge, count := deriveParameterBadge(*model)
			if model.ParameterBadge == "" {
				model.ParameterBadge = badge
			}
			if model.ParameterCountB == 0 {
				model.ParameterCountB = count
			}
		}
		if model.Category == "" {
			model.Category = deriveCategory(*model)
		}
		if len(model.CapabilityTags) == 0 {
			model.CapabilityTags = deriveCapabilityTags(*model)
		}
		if model.ContextLength == 0 {
			model.ContextLength = deriveContextLength(*model)
		}
		if model.PricePer1M == "" {
			if model.PriceKnown || model.PricePer1MInput > 0 || model.PricePer1MOutput > 0 {
				model.PricePer1M = formatMarketplacePrice(*model)
			} else {
				model.PricePer1M = unknownPriceLabel(*model)
			}
		}
		if model.IntelligenceScore == 0 {
			model.IntelligenceScore = deriveIntelligenceScore(*model)
		}
		if model.LocalModel {
			recommendation := marketplaceRecommendation(*model, profile, "")
			if recommendation.Fit == "" {

				model.RuntimeFit = "unknown"
			} else {
				hadRealSize := hasRealSizeMetadata(*model)
				if model.EstimatedVRAMGB == 0 && recommendation.VRAMRequiredBytes > 0 {
					model.EstimatedVRAMGB = bytesToGiBFloat(recommendation.VRAMRequiredBytes)
					model.VRAMEstimated = !hadRealSize
				}
				model.FitsDetectedGPU = modelHasFullGPUFit(*model, profile, "")
				model.RuntimeFit = string(recommendation.Fit)
				model.RuntimeWarnings = recommendation.Warnings
				model.RecommendationScore = recommendation.Score
				model.RuntimeRAMOffloadGB = runtimeRAMOffloadGB(recommendation, model.EstimatedVRAMGB)
			}
		}
		if model.NewScore == 0 {
			model.NewScore = deriveNewScore(*model)
		}
	}
	return out
}

func sortModels(models []types.ModelSummary, sortMode string) []types.ModelSummary {
	mode := normalizeSortMode(sortMode)
	out := append([]types.ModelSummary(nil), models...)
	if isPriceSortMode(mode) {
		out = filterModelsByPriceProviders(out)
	}
	sort.SliceStable(out, func(i, j int) bool {
		a, b := out[i], out[j]
		switch mode {
		case "intelligence", "intelligence_score", "score":
			return a.IntelligenceScore > b.IntelligenceScore
		case "price", "preis", "price_low_high", "price_low_to_high", "low_high", "low_to_high", "price_high_low", "price_high_to_low", "high_low", "high_to_low":
			return comparePriceModels(a, b, isDescendingPriceSortMode(mode))
		case "context", "kontext":
			return a.ContextLength > b.ContextLength
		case "new", "newest", "neu", "neu_zuerst":
			return a.NewScore > b.NewScore
		case "popularity", "popularitaet", "beliebtheit", "":
			fallthrough
		default:
			return a.Downloads > b.Downloads
		}
	})
	return out
}

func filterModelsByPriceProviders(models []types.ModelSummary) []types.ModelSummary {
	out := make([]types.ModelSummary, 0, len(models))
	for _, model := range models {
		if isPriceSortProvider(model.Provider) && !model.LocalModel && hasKnownPrice(model) {
			out = append(out, model)
		}
	}
	return out
}

func isPriceSortProvider(provider string) bool {
	switch types.NormalizeProvider(provider) {
	case types.ProviderOpenRouter, types.ProviderFeatherless:
		return true
	default:
		return false
	}
}

func hasKnownPrice(model types.ModelSummary) bool {
	if model.PriceKnown || model.PricePer1MInput > 0 || model.PricePer1MOutput > 0 {
		return true
	}
	switch strings.ToLower(strings.TrimSpace(model.PricePer1M)) {
	case "gratis", "free", "$0":
		return true
	default:
		return false
	}
}

func normalizeSortMode(sortMode string) string {
	mode := strings.ToLower(strings.TrimSpace(sortMode))
	mode = strings.ReplaceAll(mode, "-", "_")
	mode = strings.ReplaceAll(mode, " ", "_")
	return mode
}

func isPriceSortMode(mode string) bool {
	switch mode {
	case "price", "preis", "price_low_high", "price_low_to_high", "low_high", "low_to_high", "price_high_low", "price_high_to_low", "high_low", "high_to_low":
		return true
	default:
		return false
	}
}

func isDescendingPriceSortMode(mode string) bool {
	switch mode {
	case "price_high_low", "price_high_to_low", "high_low", "high_to_low":
		return true
	default:
		return false
	}
}

func comparePriceModels(a, b types.ModelSummary, descending bool) bool {
	aPrice := effectivePrice(a)
	bPrice := effectivePrice(b)
	if aPrice == bPrice {
		return a.Downloads > b.Downloads
	}
	if descending {
		return aPrice > bPrice
	}
	return aPrice < bPrice
}

func providerBadge(provider string) string {
	switch types.NormalizeProvider(provider) {
	case types.ProviderHuggingFace:
		return "HuggingFace"
	case types.ProviderOpenRouter:
		return "OpenRouter"
	case types.ProviderFeatherless:
		return "Featherless"
	default:
		return strings.TrimSpace(provider)
	}
}

func isLocalProvider(provider string) bool {
	switch types.NormalizeProvider(provider) {
	case types.ProviderHuggingFace:
		return true
	default:
		return false
	}
}

func deriveParameterBadge(model types.ModelSummary) (string, float64) {
	text := strings.Join([]string{model.DisplayName, model.Name, model.ModelID, model.Description}, " ")
	matches := parameterPattern.FindStringSubmatch(text)
	if len(matches) == 0 {
		return "", 0
	}
	if matches[1] != "" && matches[2] != "" {
		left, _ := strconv.ParseFloat(matches[1], 64)
		right, _ := strconv.ParseFloat(matches[2], 64)
		total := left * right
		return trimFloat(total) + "B", total
	}
	value, _ := strconv.ParseFloat(matches[3], 64)
	return trimFloat(value) + "B", value
}

func deriveCategory(model types.ModelSummary) string {
	text := strings.ToLower(strings.Join([]string{
		model.DisplayName,
		model.Name,
		model.ModelID,
		model.Description,
		model.Format,
		strings.Join(model.Formats, " "),
	}, " "))
	switch {
	case strings.Contains(text, "embedding") || strings.Contains(text, "embed"):
		return categoryEmbedding
	case strings.Contains(text, "vision") || strings.Contains(text, "vl") || strings.Contains(text, "multimodal") || strings.Contains(text, "image"):
		return categoryVision
	case strings.Contains(text, "coder") || strings.Contains(text, "code") || strings.Contains(text, "devstral"):
		return categoryCode
	case strings.Contains(text, "reason") || strings.Contains(text, "thinking") || strings.Contains(text, "r1") || strings.Contains(text, "qwq"):
		return categoryReasoning
	default:
		return categoryChat
	}
}

func deriveCapabilityTags(model types.ModelSummary) []string {
	tags := []string{deriveCategory(model)}
	if model.LocalModel || isLocalProvider(model.Provider) {
		tags = append(tags, "local")
	} else {
		tags = append(tags, "api")
	}
	if model.ContextLength >= 128000 {
		tags = append(tags, "long-context")
	}
	if len(model.Quantizations) > 0 {
		tags = append(tags, model.Quantizations...)
	}
	if model.Format != "" {
		tags = append(tags, model.Format)
	}
	return types.UniqueNonEmptyLower(tags)
}

func deriveContextLength(model types.ModelSummary) int {
	text := strings.ToLower(strings.Join([]string{model.DisplayName, model.Name, model.ModelID, model.Description}, " "))
	best := 0
	for _, match := range contextPattern.FindAllStringSubmatch(text, -1) {
		value, _ := strconv.ParseFloat(match[1], 64)
		if strings.EqualFold(match[2], "m") {
			value *= 1000000
		} else {
			value *= 1000
		}
		if int(value) > best {
			best = int(value)
		}
	}
	if best > 0 {
		return best
	}

	return 0
}

func deriveIntelligenceScore(model types.ModelSummary) int {
	score := 55
	if model.ParameterCountB > 0 {
		score += int(math.Min(25, model.ParameterCountB/3))
	}
	switch model.Category {
	case categoryReasoning:
		score += 12
	case categoryCode:
		score += 8
	case categoryVision:
		score += 6
	}
	if model.ContextLength >= 128000 {
		score += 5
	}
	if strings.Contains(strings.ToLower(model.Name+" "+model.ModelID), "pro") {
		score += 4
	}
	if score > 99 {
		return 99
	}
	return score
}

func modelFitsDetectedGPU(model types.ModelSummary, profile HardwareProfile, requestedQuantization string) bool {
	return modelHasFullGPUFit(model, profile, requestedQuantization)
}

func bytesToGiBFloat(bytes int64) float64 {
	if bytes <= 0 {
		return 0
	}
	return math.Ceil((float64(bytes)/float64(1024*1024*1024))*10) / 10
}

func deriveNewScore(model types.ModelSummary) int64 {
	text := strings.ToLower(model.ModelID + " " + model.Name)
	score := int64(0)
	for _, token := range []string{"3.3", "3.2", "2.5", "2.1", "2025", "2024"} {
		if strings.Contains(text, token) {
			score += 10
		}
	}
	score += int64(model.IntelligenceScore)
	return score
}

func effectivePrice(model types.ModelSummary) float64 {
	price := model.PricePer1MInput + model.PricePer1MOutput
	if price <= 0 {
		return 0
	}
	return price
}

func formatMarketplacePrice(model types.ModelSummary) string {
	if model.PricePer1MInput == 0 && model.PricePer1MOutput == 0 {
		if isLocalProvider(model.Provider) {
			return "lokal"
		}
		if model.PriceKnown {
			return "gratis"
		}
	}
	return formatPricePerMillion(model.PricePer1MInput, model.PricePer1MOutput)
}

func unknownPriceLabel(model types.ModelSummary) string {
	if isLocalProvider(model.Provider) {
		return "lokal"
	}
	return ""
}

func formatPricePerMillion(inPrice, outPrice float64) string {
	if inPrice == 0 && outPrice == 0 {
		return "$0"
	}
	if inPrice == outPrice {
		return "$" + trimFloat(inPrice)
	}
	return "$" + trimFloat(inPrice) + " / $" + trimFloat(outPrice)
}

func trimFloat(value float64) string {
	return strconv.FormatFloat(value, 'f', -1, 64)
}
