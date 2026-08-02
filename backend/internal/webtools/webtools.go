package webtools

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/fillyengine/backend/internal/metasearch"
	"github.com/fillyengine/backend/internal/metasearch/engines"
)

const (
	ToolWebSearch = "web_search"
	ToolWebFetch  = "web_fetch"
)

const (
	DefaultMaxResults = 5
	MaxAllowedResults = 10
	SnippetLimit      = 280
	DefaultFetchChars = 6000
	MaxFetchChars     = 20000

	DefaultRegion = "us-en"
)

type Options struct {
	Proxy string

	Timeout time.Duration

	CacheTTL time.Duration

	Region string

	MaxResults int

	FetchChars int
}

type Tools struct {
	search   *metasearch.Search
	client   *metasearch.HttpClient
	cacheTTL time.Duration

	region     string
	maxResults int
	fetchChars int

	mu    sync.Mutex
	cache map[string]cacheEntry
}

type cacheEntry struct {
	result  map[string]interface{}
	expires time.Time
}

func New(opts Options) (*Tools, error) {
	timeout := opts.Timeout
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	client, err := metasearch.NewHttpClient(metasearch.ClientOptions{
		Proxy:   metasearch.ExpandProxyTBAlias(opts.Proxy),
		Timeout: timeout,
		Verify:  true,
	})
	if err != nil {
		return nil, fmt.Errorf("webtools: http-client: %w", err)
	}

	categories := []string{"text", "news"}
	byCategory := make(map[string][]metasearch.Engine, len(categories))
	for _, category := range categories {
		byCategory[category] = engines.Build(category, "auto", client)
	}

	ttl := opts.CacheTTL
	if ttl == 0 {
		ttl = 5 * time.Minute
	}

	return &Tools{

		search: metasearch.NewSearch(client, byCategory, metasearch.SearchOptions{
			Ranker: metasearch.NewRelevanceRanker(),
		}),
		client:     client,
		cacheTTL:   ttl,
		region:     firstNonEmpty(strings.TrimSpace(opts.Region), DefaultRegion),
		maxResults: clamp(opts.MaxResults, DefaultMaxResults, 1, MaxAllowedResults),
		fetchChars: clamp(opts.FetchChars, DefaultFetchChars, 500, MaxFetchChars),
		cache:      map[string]cacheEntry{},
	}, nil
}

func firstNonEmpty(value, fallback string) string {
	if value != "" {
		return value
	}
	return fallback
}

func clamp(value, fallback, min, max int) int {
	if value == 0 {
		value = fallback
	}
	if value < min {
		return min
	}
	if value > max {
		return max
	}
	return value
}

func (t *Tools) Names() []string { return []string{ToolWebSearch, ToolWebFetch} }

func (t *Tools) Handles(name string) bool {
	return name == ToolWebSearch || name == ToolWebFetch
}

func (t *Tools) Execute(ctx context.Context, name string, args map[string]interface{}) map[string]interface{} {
	if args == nil {
		args = map[string]interface{}{}
	}
	switch name {
	case ToolWebSearch:
		return t.webSearch(ctx, args)
	case ToolWebFetch:
		return t.webFetch(ctx, args)
	default:
		return failure("unbekanntes Tool: "+name, "unknown_tool", "")
	}
}

func (t *Tools) webSearch(ctx context.Context, args map[string]interface{}) map[string]interface{} {
	query := strings.TrimSpace(stringArg(args, "query"))
	if query == "" {
		return failure("Argument \"query\" fehlt oder ist leer", "invalid_tool_arguments",
			`{"query":"suchbegriffe","max_results":5}`)
	}

	category := strings.ToLower(strings.TrimSpace(stringArg(args, "category")))
	switch category {
	case "", "text":
		category = "text"
	case "news":
	default:
		return failure("unbekannte category: "+category, "invalid_tool_arguments",
			`"category" akzeptiert nur "text" oder "news"`)
	}

	maxResults := intArg(args, "max_results", t.maxResults)
	if maxResults < 1 {
		maxResults = 1
	}
	if maxResults > MaxAllowedResults {
		maxResults = MaxAllowedResults
	}

	cacheKey := fmt.Sprintf("search\x00%s\x00%s\x00%d", category, strings.ToLower(query), maxResults)
	if cached, ok := t.fromCache(cacheKey); ok {
		return cached
	}

	results, err := t.search.Run(ctx, category, metasearch.SearchParams{
		Query:      query,
		Region:     t.region,
		Safesearch: "moderate",
		Page:       1,
		Max:        maxResults,
		Backend:    "auto",
	})
	if err != nil {
		return failure("Suche fehlgeschlagen: "+err.Error(), "search_failed",
			"Formuliere die Suchanfrage um oder beantworte die Frage aus deinem Wissen.")
	}
	if len(results) == 0 {
		return map[string]interface{}{
			"ok":      true,
			"query":   query,
			"count":   0,
			"results": []interface{}{},
			"note":    "Keine Treffer. Versuche andere Suchbegriffe.",
		}
	}

	if len(results) > maxResults {
		results = results[:maxResults]
	}
	compact := make([]map[string]interface{}, 0, len(results))
	for _, r := range results {
		href := r.Href
		if href == "" {
			href = r.URL
		}
		entry := map[string]interface{}{
			"title":   metasearch.NormalizeText(r.Title),
			"url":     href,
			"snippet": truncate(metasearch.NormalizeText(r.Body), SnippetLimit),
		}
		if r.Date != "" {
			entry["date"] = r.Date
		}
		compact = append(compact, entry)
	}

	out := map[string]interface{}{
		"ok":      true,
		"query":   query,
		"count":   len(compact),
		"results": compact,
		"hint":    "Snippets sind gekuerzt. Fuer den vollen Text einer Seite web_fetch mit deren url aufrufen.",
	}
	t.toCache(cacheKey, out)
	return out
}

func (t *Tools) webFetch(ctx context.Context, args map[string]interface{}) map[string]interface{} {
	target := strings.TrimSpace(stringArg(args, "url"))
	if target == "" {
		return failure("Argument \"url\" fehlt oder ist leer", "invalid_tool_arguments",
			`{"url":"https://example.com","max_chars":6000}`)
	}

	maxChars := intArg(args, "max_chars", t.fetchChars)
	if maxChars < 500 {
		maxChars = 500
	}
	if maxChars > MaxFetchChars {
		maxChars = MaxFetchChars
	}

	cacheKey := fmt.Sprintf("fetch\x00%s\x00%d", target, maxChars)
	if cached, ok := t.fromCache(cacheKey); ok {
		return cached
	}

	resp, err := t.client.GetGuarded(ctx, target, nil)
	if err != nil {
		if errors.Is(err, metasearch.ErrBlockedURL) {
			return failure("URL abgelehnt: "+err.Error(), "blocked_url",
				"Nur oeffentliche http/https-Adressen sind erlaubt. Lokale und interne Adressen sind gesperrt.")
		}
		return failure("Abruf fehlgeschlagen: "+err.Error(), "fetch_failed",
			"Pruefe die URL oder nutze web_search, um eine erreichbare Quelle zu finden.")
	}
	if resp.StatusCode != 200 {
		return failure(fmt.Sprintf("Server antwortete mit HTTP %d", resp.StatusCode), "http_error",
			"Die Seite ist nicht abrufbar. Suche eine andere Quelle.")
	}

	content := metasearch.HTMLToMarkdown(resp.Text)
	if strings.TrimSpace(content) == "" {
		content = metasearch.NormalizeText(resp.Text)
	}

	truncated := utf8.RuneCountInString(content) > maxChars
	if truncated {
		content = truncate(content, maxChars)
	}

	out := map[string]interface{}{
		"ok":        true,
		"url":       target,
		"content":   content,
		"chars":     utf8.RuneCountInString(content),
		"truncated": truncated,
	}
	if truncated {
		out["hint"] = "Inhalt gekuerzt. Bei Bedarf mit hoeherem max_chars erneut abrufen."
	}
	t.toCache(cacheKey, out)
	return out
}

func (t *Tools) fromCache(key string) (map[string]interface{}, bool) {
	if t.cacheTTL < 0 {
		return nil, false
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	entry, ok := t.cache[key]
	if !ok || time.Now().After(entry.expires) {
		if ok {
			delete(t.cache, key)
		}
		return nil, false
	}

	out := make(map[string]interface{}, len(entry.result)+1)
	for k, v := range entry.result {
		out[k] = v
	}
	out["cached"] = true
	return out, true
}

func (t *Tools) toCache(key string, result map[string]interface{}) {
	if t.cacheTTL < 0 {
		return
	}
	t.mu.Lock()
	defer t.mu.Unlock()

	if len(t.cache) > 128 {
		t.cache = map[string]cacheEntry{}
	}
	t.cache[key] = cacheEntry{result: result, expires: time.Now().Add(t.cacheTTL)}
}

func failure(message, code, hint string) map[string]interface{} {
	out := map[string]interface{}{
		"ok":         false,
		"error":      message,
		"error_code": code,
	}
	if hint != "" {
		out["hint"] = hint
	}
	return out
}

func truncate(s string, limit int) string {
	if limit <= 0 || len(s) <= limit {
		return s
	}
	runes := []rune(s)
	if len(runes) <= limit {
		return s
	}
	return strings.TrimSpace(string(runes[:limit])) + "…"
}

func stringArg(args map[string]interface{}, key string) string {
	if v, ok := args[key].(string); ok {
		return v
	}
	return ""
}

func intArg(args map[string]interface{}, key string, def int) int {
	switch v := args[key].(type) {
	case float64:
		return int(v)
	case int:
		return v
	case string:
		var n int
		if _, err := fmt.Sscanf(strings.TrimSpace(v), "%d", &n); err == nil {
			return n
		}
	}
	return def
}
