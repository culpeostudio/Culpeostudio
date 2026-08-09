package marketplace

import (
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/modules/marketplace/types"
)

const (
	maxSearchWindow = 1000

	defaultPageSize = 20
	maxPageSize     = 1000
)

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

// searchParamsFromRequest turns the request into the internal parameters the
// filters work on. Most of what the query-string parser used to reject - an
// unknown provider, a non-numeric page, "maybe" for a boolean - the schema now
// rules out, so only the value ranges and the provider/filter combination are
// still checked here.
func searchParamsFromRequest(req *marketplacev1.SearchModelsRequest) (searchParams, error) {
	provider, err := searchProviderFromProto(req.GetProvider())
	if err != nil {
		return searchParams{}, err
	}

	page := int(req.GetPage())
	if page < 0 {
		return searchParams{}, status.Error(codes.InvalidArgument, "page darf nicht negativ sein")
	}
	if page == 0 {
		page = 1
	}

	pageSize := int(req.GetPageSize())
	if pageSize < 0 {
		return searchParams{}, status.Error(codes.InvalidArgument, "page_size darf nicht negativ sein")
	}
	if pageSize == 0 {
		pageSize = defaultPageSize
	}
	if pageSize > maxPageSize {
		pageSize = maxPageSize
	}

	quantization := strings.TrimSpace(req.GetQuantization())
	normalizedQuantization := normalizeQuantization(quantization)

	if (req.GetLocalOnly() || req.GetGpuFit() || normalizedQuantization != "") &&
		provider != types.ProviderAll && provider != types.ProviderHuggingFace {
		return searchParams{}, status.Error(
			codes.InvalidArgument,
			"local_only, gpu_fit und quantization sind nur fuer HuggingFace-Modelle verfuegbar",
		)
	}

	return searchParams{
		Provider:               provider,
		Query:                  strings.TrimSpace(req.GetQuery()),
		Format:                 strings.TrimSpace(req.GetFormat()),
		Quantization:           quantization,
		NormalizedQuantization: normalizedQuantization,
		Category:               categoryFromProto(req.GetCategory()),
		SortMode:               sortModeFromProto(req.GetSort()),
		Page:                   page,
		PageSize:               pageSize,
		GPUOnly:                req.GetGpuFit(),
		LocalOnly:              req.GetLocalOnly(),
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
