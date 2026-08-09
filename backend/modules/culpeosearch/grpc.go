package culpeosearch

import (
	"context"
	"errors"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	searchv1 "github.com/culpeohq/backend/gen/go/culpeostudio/search/v1"
	"github.com/culpeohq/backend/internal/metasearch"
	"github.com/culpeohq/backend/internal/metasearch/engines"
	"github.com/culpeohq/backend/internal/security"
)

// searchCategories is every category the module serves, in the order the
// engines were registered.
var searchCategories = map[searchv1.Category]string{
	searchv1.Category_CATEGORY_TEXT:   "text",
	searchv1.Category_CATEGORY_NEWS:   "news",
	searchv1.Category_CATEGORY_IMAGES: "images",
	searchv1.Category_CATEGORY_VIDEOS: "videos",
	searchv1.Category_CATEGORY_BOOKS:  "books",
}

var categoryNames = []string{"text", "images", "videos", "news", "books"}

type grpcService struct {
	searchv1.UnimplementedSearchServiceServer
	module *Module
}

func (m *Module) RegisterGRPC(server *grpc.Server) {
	searchv1.RegisterSearchServiceServer(server, &grpcService{module: m})
}

// Limiter exposes the module's rate limiter so the server can wire it into the
// interceptor chain.
func (m *Module) Limiter() *security.RateLimiter { return m.limiter }

func (s *grpcService) Search(ctx context.Context, req *searchv1.SearchRequest) (*searchv1.SearchResponse, error) {
	if s.module.search == nil {
		return nil, status.Error(codes.Unavailable, "culpeosearch: search nicht initialisiert")
	}

	category, ok := searchCategories[req.GetCategory()]
	if !ok {
		return nil, status.Error(codes.InvalidArgument, "category is required")
	}
	query := strings.TrimSpace(req.GetQuery())
	if query == "" {
		return nil, status.Error(codes.InvalidArgument, "query is required")
	}

	// The per-call budget is three times the per-engine timeout, because the
	// engines run concurrently but the slowest one sets the pace.
	timeoutSec := getEnvInt("CULPEOSEARCH_TIMEOUT_SEC", 10) * 3
	if timeoutSec < 20 {
		timeoutSec = 20
	}
	runCtx, cancel := context.WithTimeout(ctx, time.Duration(timeoutSec)*time.Second)
	defer cancel()

	results, err := s.module.search.Run(runCtx, category, metasearch.SearchParams{
		Query:      query,
		Region:     valueOr(req.GetRegion(), "us-en"),
		Safesearch: valueOr(req.GetSafesearch(), "moderate"),
		Timelimit:  req.GetTimelimit(),
		Page:       intValueOr(int(req.GetPage()), 1),
		Max:        intValueOr(int(req.GetMaxResults()), 10),
		Backend:    valueOr(req.GetBackend(), "auto"),
	})
	if err != nil {
		return nil, status.Error(codes.Unavailable, err.Error())
	}

	items := make([]*searchv1.SearchResult, 0, len(results))
	for _, result := range results {
		items = append(items, resultToProto(result))
	}
	return &searchv1.SearchResponse{
		Query:   query,
		Results: items,
		Count:   int32(len(items)),
	}, nil
}

func (s *grpcService) Extract(ctx context.Context, req *searchv1.ExtractRequest) (*searchv1.ExtractResponse, error) {
	if s.module.client == nil {
		return nil, status.Error(codes.Unavailable, "culpeosearch: client nicht initialisiert")
	}

	target := strings.TrimSpace(req.GetUrl())
	if target == "" {
		return nil, status.Error(codes.InvalidArgument, "url is required")
	}

	format := req.GetFormat()
	if format == searchv1.ExtractFormat_EXTRACT_FORMAT_UNSPECIFIED {
		format = searchv1.ExtractFormat_EXTRACT_FORMAT_TEXT_MARKDOWN
	}

	fetchCtx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()

	response, err := s.module.client.GetGuarded(fetchCtx, target, nil)
	if err != nil {
		// A blocked address is the caller's mistake, not an upstream failure.
		if errors.Is(err, metasearch.ErrBlockedURL) {
			return nil, status.Error(codes.InvalidArgument, err.Error())
		}
		return nil, status.Error(codes.Unavailable, err.Error())
	}
	if response.StatusCode != 200 {
		return nil, status.Errorf(codes.Unavailable, "fetch failed: %d", response.StatusCode)
	}

	extracted := &searchv1.ExtractResponse{Url: target, Format: format}
	switch format {
	case searchv1.ExtractFormat_EXTRACT_FORMAT_TEXT:
		extracted.Content = response.Text
	case searchv1.ExtractFormat_EXTRACT_FORMAT_CONTENT:
		extracted.RawContent = response.Content
	case searchv1.ExtractFormat_EXTRACT_FORMAT_TEXT_PLAIN:
		extracted.Content = metasearch.NormalizeText(response.Text)
	case searchv1.ExtractFormat_EXTRACT_FORMAT_TEXT_RICH,
		searchv1.ExtractFormat_EXTRACT_FORMAT_TEXT_MARKDOWN:
		extracted.Content = metasearch.HTMLToMarkdown(response.Text)
	default:
		return nil, status.Error(codes.InvalidArgument, "unsupported format")
	}
	return extracted, nil
}

func (s *grpcService) ListEngines(ctx context.Context, req *searchv1.ListEnginesRequest) (*searchv1.ListEnginesResponse, error) {
	available := make(map[string]*searchv1.EngineNames, len(categoryNames))
	for _, category := range categoryNames {
		available[category] = &searchv1.EngineNames{Names: engines.Available(category, "auto")}
	}
	return &searchv1.ListEnginesResponse{Engines: available}, nil
}

func valueOr(value, fallback string) string {
	if trimmed := strings.TrimSpace(value); trimmed != "" {
		return trimmed
	}
	return fallback
}

func intValueOr(value, fallback int) int {
	if value > 0 {
		return value
	}
	return fallback
}

func resultToProto(result metasearch.Result) *searchv1.SearchResult {
	return &searchv1.SearchResult{
		Title:       result.Title,
		Href:        result.Href,
		Body:        result.Body,
		Image:       result.Image,
		Thumbnail:   result.Thumbnail,
		Url:         result.URL,
		Height:      result.Height,
		Width:       result.Width,
		Source:      result.Source,
		Date:        result.Date,
		Content:     result.Content,
		Description: result.Description,
		Duration:    result.Duration,
		EmbedHtml:   result.EmbedHTML,
		EmbedUrl:    result.EmbedURL,
		ImageToken:  result.ImageToken,
		Provider:    result.Provider,
		Published:   result.Published,
		Publisher:   result.Publisher,
		Uploader:    result.Uploader,
		Author:      result.Author,
		Info:        result.Info,
	}
}
