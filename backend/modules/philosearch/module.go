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

type Module struct {
	search  *metasearch.Search
	client  *metasearch.HttpClient
	limiter *security.RateLimiter
	initErr error
}

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

		limiter: security.NewRateLimiter(getEnvInt("PHILOSEARCH_RATE_LIMIT", 60), time.Minute),
	}
}

func (m *Module) Name() string { return "philosearch" }

func (m *Module) Initialize() error {
	if m.search == nil {
		return errors.Join(errors.New("philosearch: HttpClient nicht initialisiert"), m.initErr)
	}
	return nil
}

func (m *Module) Shutdown() error {
	if m.limiter != nil {
		m.limiter.Close()
	}
	return nil
}

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

func (m *Module) handleListEngines(c *fiber.Ctx) error {
	categories := []string{"text", "images", "videos", "news", "books"}
	out := map[string][]string{}
	for _, cat := range categories {
		out[cat] = engines.Available(cat, "auto")
	}
	return c.JSON(fiber.Map{"engines": out})
}

func (m *Module) runCategory(category string) fiber.Handler {
	return func(c *fiber.Ctx) error { return m.handleSearch(c, category) }
}

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

func parseSearchRequest(c *fiber.Ctx) (searchRequest, error) {
	req := searchRequest{
		Region:     "us-en",
		Safesearch: "moderate",
		Page:       1,
		MaxResults: 10,
		Backend:    "auto",
	}

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

func getEnv(key, def string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return def
}

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
