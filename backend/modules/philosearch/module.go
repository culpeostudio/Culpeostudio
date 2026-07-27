// Package philosearch ist das Fiber-Modul von PhiloEngine, das die
// Metasuch-Engine unter /api/search/* verfuegbar macht. Es ersetzt
// den FastAPI-Server aus dem urspruenglichen ddgs-Python-Projekt
// durch das PhiloEngine-Standardmodul-Pattern.
//
// Der eigentliche Engine-Code liegt in internal/metasearch und
// internal/metasearch/engines; dieses Paket hier ist nur die
// duenne HTTP-Huelle mit Request/Response-Modellen.
package philosearch

import (
	"errors"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/metasearch"
	"github.com/fillyengine/backend/internal/metasearch/engines"
	"github.com/fillyengine/backend/internal/security"
)

// Module implementiert das PhiloEngine modules.Module-Interface.
type Module struct {
	search  *metasearch.Search
	client  *metasearch.HttpClient
	limiter *security.RateLimiter
	initErr error
}

// New erzeugt ein neues PhiloSearch-Modul mit Standard-Konfiguration.
// Aus dem Environment gelesene Variablen:
//
//   - PHILOSEARCH_PROXY: Proxy-URL fuer alle Engines
//   - PHILOSEARCH_TIMEOUT_SEC: HTTP-Timeout in Sekunden (Default 10)
//   - PHILOSEARCH_VERIFY: TLS-Verifikation ("true"|"false", Default true)
//   - PHILOSEARCH_RATE_LIMIT: Anfragen pro Minute und Nutzer (Default 60)
func New() *Module {
	proxy := getEnv("PHILOSEARCH_PROXY", "")
	timeoutSec := getEnvInt("PHILOSEARCH_TIMEOUT_SEC", 10)
	verify := getEnvBool("PHILOSEARCH_VERIFY", true)

	client, err := metasearch.NewHttpClient(metasearch.ClientOptions{
		Proxy:   metasearch.ExpandProxyTBAlias(proxy),
		Timeout: time.Duration(timeoutSec) * time.Second,
		Verify:  verify,
	})
	if err != nil {
		// Wirf nicht - stattdessen liefert Initialize den Fehler.
		return &Module{initErr: err}
	}

	allCategories := []string{"text", "images", "videos", "news", "books"}
	enginesByCategory := make(map[string][]metasearch.Engine, len(allCategories))
	for _, cat := range allCategories {
		enginesByCategory[cat] = engines.Build(cat, "auto", client)
	}

	return &Module{
		search: metasearch.NewSearch(client, enginesByCategory, metasearch.SearchOptions{}),
		client: client,
		// Jede Anfrage loest mehrere ausgehende Requests an fremde
		// Suchmaschinen aus; ohne Deckel handelt man sich dort Sperren ein.
		limiter: security.NewRateLimiter(getEnvInt("PHILOSEARCH_RATE_LIMIT", 60), time.Minute),
	}
}

// Name liefert den Modulnamen fuer die Backend-Registrierung.
func (m *Module) Name() string { return "philosearch" }

// Initialize validiert die Konfiguration; ein hier entdeckter Client-Fehler
// bricht den Server-Start ab.
func (m *Module) Initialize() error {
	if m.search == nil {
		return errors.Join(errors.New("philosearch: HttpClient nicht initialisiert"), m.initErr)
	}
	return nil
}

// Shutdown stoppt den Janitor des Rate-Limiters; der HttpClient beendet
// sich selbststaendig via GC.
func (m *Module) Shutdown() error {
	if m.limiter != nil {
		m.limiter.Close()
	}
	return nil
}

// RegisterRoutes registriert alle HTTP-Routen des Moduls. Die
// Suchrouten akzeptieren GET (Query-Parameter) und POST (JSON-Body).
func (m *Module) RegisterRoutes(r fiber.Router) {
	g := r.Group("/search")
	if m.limiter != nil {
		g.Use(m.limiter.Middleware())
	}
	for _, category := range []string{"text", "news", "images", "videos", "books"} {
		h := m.runCategory(category)
		g.Get("/"+category, h)
		g.Post("/"+category, h)
	}
	g.Get("/extract", m.handleExtract)
	g.Post("/extract", m.handleExtract)
	g.Get("/engines", m.handleListEngines)
}

// handleListEngines liefert die verfuegbaren Engines pro Kategorie.
func (m *Module) handleListEngines(c *fiber.Ctx) error {
	categories := []string{"text", "images", "videos", "news", "books"}
	out := map[string][]string{}
	for _, cat := range categories {
		out[cat] = engines.Available(cat, "auto")
	}
	return c.JSON(fiber.Map{"engines": out})
}

// runCategory ist ein Factory-Wrapper, der die Kategorie fest thunkt.
func (m *Module) runCategory(category string) fiber.Handler {
	return func(c *fiber.Ctx) error { return m.handleSearch(c, category) }
}

// handleSearch verarbeitet die Suchanfragen aller Kategorien.
func (m *Module) handleSearch(c *fiber.Ctx, category string) error {
	if m.search == nil {
		return c.Status(503).JSON(fiber.Map{"error": "philosearch: search nicht initialisiert"})
	}

	req, err := parseSearchRequest(c)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	timeoutSec := getEnvInt("PHILOSEARCH_TIMEOUT_SEC", 10) * 3
	if timeoutSec < 20 {
		timeoutSec = 20
	}
	ctx, cancel := contextWithTimeout(c, time.Duration(timeoutSec)*time.Second)
	defer cancel()

	results, err := m.search.Run(ctx, category, metasearch.SearchParams{
		Query:      req.Query,
		Region:     req.Region,
		Safesearch: req.Safesearch,
		Timelimit:  req.Timelimit,
		Page:       req.Page,
		Max:        req.MaxResults,
		Backend:    req.Backend,
	})
	if err != nil {
		return c.Status(502).JSON(fiber.Map{"error": err.Error()})
	}
	if results == nil {
		results = []metasearch.Result{}
	}
	return c.JSON(fiber.Map{
		"query":   req.Query,
		"results": results,
		"count":   len(results),
	})
}

// parseSearchRequest vereinigt JSON-Body, Form-Body und Query-Parameter.
// Body-Felder haben Prioritaet vor Query-Parametern.
func parseSearchRequest(c *fiber.Ctx) (searchRequest, error) {
	req := searchRequest{
		Region:     "us-en",
		Safesearch: "moderate",
		Page:       1,
		MaxResults: 10,
		Backend:    "auto",
	}
	// Query-Parameter als Basis, weil sie auch ohne Body funktionieren.
	if v := strings.TrimSpace(c.Query("q")); v != "" {
		req.Query = v
	}
	if v := c.Query("query"); v != "" && req.Query == "" {
		req.Query = v
	}
	if v := c.Query("region"); v != "" {
		req.Region = v
	}
	if v := c.Query("safesearch"); v != "" {
		req.Safesearch = v
	}
	if v := c.Query("timelimit"); v != "" {
		req.Timelimit = v
	}
	if v := c.Query("backend"); v != "" {
		req.Backend = v
	}
	if v := c.QueryInt("page"); v > 0 {
		req.Page = v
	}
	if v := c.QueryInt("max_results"); v > 0 {
		req.MaxResults = v
	}
	// JSON-Body ueberschreibt Query-Parameter, wenn vorhanden.
	if c.Body() != nil && len(c.Body()) > 0 {
		var body searchRequest
		if err := c.BodyParser(&body); err == nil {
			if body.Query != "" {
				req.Query = body.Query
			}
			if body.Region != "" {
				req.Region = body.Region
			}
			if body.Safesearch != "" {
				req.Safesearch = body.Safesearch
			}
			if body.Timelimit != "" {
				req.Timelimit = body.Timelimit
			}
			if body.Backend != "" {
				req.Backend = body.Backend
			}
			if body.Page > 0 {
				req.Page = body.Page
			}
			if body.MaxResults > 0 {
				req.MaxResults = body.MaxResults
			}
		}
	}
	if strings.TrimSpace(req.Query) == "" {
		return req, errors.New("query is required")
	}
	return req, nil
}

// getEnv liest eine Environment-Variable mit Default-Wert.
func getEnv(key, def string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return def
}

// getEnvInt liest eine Environment-Variable als int mit Default-Wert.
func getEnvInt(key string, def int) int {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return n
}

// getEnvBool liest eine Environment-Variable als bool mit Default-Wert.
func getEnvBool(key string, def bool) bool {
	v := strings.ToLower(strings.TrimSpace(os.Getenv(key)))
	switch v {
	case "true", "1", "yes", "on":
		return true
	case "false", "0", "no", "off":
		return false
	case "":
		return def
	default:
		return def
	}
}
