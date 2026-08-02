package marktplatz

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

const maxSearchWindow = 1000

type searchParams struct {
	Provider               string
	Query                  string
	Format                 string
	Quantization           string
	NormalizedQuantization string
	Category               string
	SortMode               string
	Page                   int
	PageSize               int
	GPUOnly                bool
	LocalOnly              bool
}

type fiberErr struct {
	status int
	msg    string
}

func (e *fiberErr) Error() string { return e.msg }

func parseSearchParams(c *fiber.Ctx) (searchParams, error) {
	provider := types.NormalizeProvider(c.Query("provider", types.ProviderAll))
	if !types.IsSupportedProvider(provider) {
		return searchParams{}, &fiberErr{status: 400, msg: "ungueltiger provider"}
	}

	page := 1
	if raw := strings.TrimSpace(c.Query("page", "")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed <= 0 {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltige page"}
		}
		page = parsed
	}

	pageSize := 20
	if raw := strings.TrimSpace(c.Query("limit", "")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed <= 0 {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltiges limit"}
		}
		if parsed > 1000 {
			parsed = 1000
		}
		pageSize = parsed
	}

	query := strings.TrimSpace(c.Query("q", ""))
	format := strings.TrimSpace(c.Query("format", ""))
	quantization := strings.TrimSpace(c.Query("quantization", ""))
	normalizedQuantization := normalizeQuantization(quantization)
	category := normalizeCategory(c.Query("category", ""))
	sortMode := strings.TrimSpace(c.Query("sort", "popularity"))

	gpuOnly := false
	if raw := strings.TrimSpace(c.Query("gpu_fit", "")); raw != "" {
		parsed, err := strconv.ParseBool(raw)
		if err != nil {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltiger gpu_fit wert"}
		}
		gpuOnly = parsed
	}

	localOnly := false
	if raw := strings.TrimSpace(c.Query("local_only", "")); raw != "" {
		parsed, err := strconv.ParseBool(raw)
		if err != nil {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltiger local_only wert"}
		}
		localOnly = parsed
	}

	if (localOnly || gpuOnly || normalizedQuantization != "") &&
		provider != types.ProviderAll && provider != types.ProviderHuggingFace {
		return searchParams{}, &fiberErr{
			status: 400,
			msg:    "local_only, gpu_fit und quantization sind nur fuer HuggingFace-Modelle verfuegbar",
		}
	}

	return searchParams{
		Provider:               provider,
		Query:                  query,
		Format:                 format,
		Quantization:           quantization,
		NormalizedQuantization: normalizedQuantization,
		Category:               category,
		SortMode:               sortMode,
		Page:                   page,
		PageSize:               pageSize,
		GPUOnly:                gpuOnly,
		LocalOnly:              localOnly,
	}, nil
}

func (p searchParams) resolvedProvider() string {
	if p.Provider == types.ProviderAll && (p.LocalOnly || p.GPUOnly || p.NormalizedQuantization != "") {
		return types.ProviderHuggingFace
	}
	return p.Provider
}

func (p searchParams) isPostFilteredSearch() bool {
	if p.Category != "" || p.Format != "" {
		return true
	}
	return p.resolvedProvider() == types.ProviderHuggingFace &&
		(p.LocalOnly || p.GPUOnly || p.NormalizedQuantization != "")
}

func computeSearchLimit(p searchParams) int {
	searchLimit := p.PageSize * p.Page
	if searchLimit > maxSearchWindow {
		searchLimit = maxSearchWindow
	}
	if p.isPostFilteredSearch() {
		expandedSearchLimit := p.PageSize * p.Page * 8
		if expandedSearchLimit < 160 {
			expandedSearchLimit = 160
		}
		if expandedSearchLimit > maxSearchWindow {
			expandedSearchLimit = maxSearchWindow
		}
		if searchLimit < expandedSearchLimit {
			searchLimit = expandedSearchLimit
		}
	}
	return searchLimit
}

func expandSearchLimit(current int) (int, bool) {
	if current >= maxSearchWindow {
		return current, false
	}
	next := current * 2
	if next > maxSearchWindow {
		next = maxSearchWindow
	}
	if next <= current {
		return current, false
	}
	return next, true
}
