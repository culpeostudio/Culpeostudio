package culpeosearch

import (
	"errors"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/metasearch"
	"github.com/culpeohq/backend/internal/metasearch/engines"
	"github.com/culpeohq/backend/internal/security"
)

type Module struct {
	search  *metasearch.Search
	client  *metasearch.HttpClient
	limiter *security.RateLimiter
	initErr error
}

func New() *Module {
	proxy := getEnv("CULPEOSEARCH_PROXY", "")
	timeoutSec := getEnvInt("CULPEOSEARCH_TIMEOUT_SEC", 10)
	verify := getEnvBool("CULPEOSEARCH_VERIFY", true)

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

		limiter: security.NewRateLimiter(getEnvInt("CULPEOSEARCH_RATE_LIMIT", 60), time.Minute),
	}
}

func (m *Module) Name() string { return "culpeosearch" }

func (m *Module) Initialize() error {
	if m.search == nil {
		return errors.Join(errors.New("culpeosearch: HttpClient nicht initialisiert"), m.initErr)
	}
	return nil
}

func (m *Module) Shutdown() error {
	if m.limiter != nil {
		m.limiter.Close()
	}
	return nil
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
