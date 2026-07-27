// Package webtools stellt Websuche und Seitenabruf als Agenten-Werkzeuge
// bereit. Es sitzt zwischen der Metasuch-Engine (internal/metasearch) und
// den Agenten-Schleifen in modules/philobot und modules/philox, damit
// beide dieselben Werkzeuge mit identischem Verhalten anbieten.
//
// Der Zuschnitt ist bewusst auf Sprachmodelle ausgelegt:
//
//   - Ergebnisse sind knapp. Ein Suchtreffer kostet ~60 Token statt ~400,
//     weil Snippets gekuerzt und Bild-/Video-Felder weggelassen werden.
//   - Abgerufene Seiten werden auf ein Zeichenbudget beschnitten und
//     melden die Kuerzung explizit, statt den Kontext zu sprengen.
//   - Fehler kommen als strukturierte Antwort mit error_code und hint
//     zurueck, damit das Modell sie korrigieren kann, statt abzubrechen.
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

// Werkzeugnamen, wie das Modell sie aufruft.
const (
	ToolWebSearch = "web_search"
	ToolWebFetch  = "web_fetch"
)

// Budgets fuer die Antwortgroesse. Sie bestimmen, wie viel Kontext ein
// einzelner Werkzeugaufruf verbraucht. Die Default-Werte lassen sich
// ueber Options ueberschreiben, die Obergrenzen nicht: sie schuetzen
// den Kontext des Modells auch vor einer unbedachten Konfiguration.
const (
	DefaultMaxResults = 5
	MaxAllowedResults = 10
	SnippetLimit      = 280
	DefaultFetchChars = 6000
	MaxFetchChars     = 20000
	// DefaultRegion ist die Regionskennung der Suchmaschinen im
	// DuckDuckGo-Format (Land-Sprache).
	DefaultRegion = "us-en"
)

// Options konfiguriert die Werkzeuge.
type Options struct {
	// Proxy fuer alle ausgehenden Anfragen (leer = direkt).
	Proxy string
	// Timeout je HTTP-Anfrage (0 = 10s).
	Timeout time.Duration
	// CacheTTL bestimmt, wie lange gleiche Anfragen aus dem Cache
	// bedient werden (0 = 5min, negativ = Cache aus).
	CacheTTL time.Duration
	// Region ist die Suchregion im Format Land-Sprache, z.B. "de-de"
	// (leer = DefaultRegion).
	Region string
	// MaxResults ist die Trefferzahl, wenn das Modell keine angibt
	// (0 = DefaultMaxResults). Wird auf MaxAllowedResults gedeckelt.
	MaxResults int
	// FetchChars ist das Zeichenbudget eines Seitenabrufs, wenn das
	// Modell keins angibt (0 = DefaultFetchChars). Wird auf
	// MaxFetchChars gedeckelt.
	FetchChars int
}

// Tools buendelt Websuche und Seitenabruf.
type Tools struct {
	search   *metasearch.Search
	client   *metasearch.HttpClient
	cacheTTL time.Duration

	// Aus Options uebernommene Vorgaben.
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

// New erzeugt die Werkzeuge mit eigener Metasuch-Instanz.
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
		// Relevanz-Ranking statt der Wikipedia-Bevorzugung: ein Agent
		// recherchiert meist Konkretes, wo der thematisch verwandte
		// Wikipedia-Artikel die eigentliche Quelle verdraengen wuerde.
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

// firstNonEmpty liefert den ersten nicht-leeren Wert.
func firstNonEmpty(value, fallback string) string {
	if value != "" {
		return value
	}
	return fallback
}

// clamp haelt einen konfigurierten Wert in seinen Grenzen. 0 bedeutet
// "nicht gesetzt" und faellt auf fallback zurueck.
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

// Names liefert die Namen aller bereitgestellten Werkzeuge.
func (t *Tools) Names() []string { return []string{ToolWebSearch, ToolWebFetch} }

// Handles meldet, ob name von diesem Paket ausgefuehrt wird.
func (t *Tools) Handles(name string) bool {
	return name == ToolWebSearch || name == ToolWebFetch
}

// Execute fuehrt einen Werkzeugaufruf aus. Das Ergebnis folgt der
// Konvention der Datei-Werkzeuge: immer ein "ok"-Feld, im Fehlerfall
// zusaetzlich "error", "error_code" und "hint".
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

// webSearch sucht im Web und liefert eine knappe Trefferliste.
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

// webFetch laedt eine Seite und liefert sie als Markdown.
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
	// In Zeichen, nicht in Bytes messen: sonst gilt ein deutscher Text
	// mit Umlauten als gekuerzt, obwohl er vollstaendig ist.
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

// fromCache liefert ein noch gueltiges Ergebnis aus dem Cache.
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
	// Kopie, damit ein Aufrufer den Cache-Eintrag nicht veraendern kann.
	out := make(map[string]interface{}, len(entry.result)+1)
	for k, v := range entry.result {
		out[k] = v
	}
	out["cached"] = true
	return out, true
}

// toCache legt ein Ergebnis mit Ablaufzeit ab.
func (t *Tools) toCache(key string, result map[string]interface{}) {
	if t.cacheTTL < 0 {
		return
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	// Einfache Obergrenze statt Verdraengungsstrategie: die Schleife eines
	// Agenten macht selten mehr als eine Handvoll Abfragen.
	if len(t.cache) > 128 {
		t.cache = map[string]cacheEntry{}
	}
	t.cache[key] = cacheEntry{result: result, expires: time.Now().Add(t.cacheTTL)}
}

// failure baut eine strukturierte Fehlerantwort.
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

// truncate kuerzt s auf hoechstens limit Zeichen an einer Runengrenze
// und haengt eine Ellipse an.
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

// stringArg liest ein String-Argument aus der Modell-Ausgabe.
func stringArg(args map[string]interface{}, key string) string {
	if v, ok := args[key].(string); ok {
		return v
	}
	return ""
}

// intArg liest ein Zahl-Argument. Modelle liefern Zahlen mal als
// float64 (JSON), mal als String - beides wird akzeptiert.
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
