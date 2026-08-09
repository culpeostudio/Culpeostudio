package engines

import (
	"strconv"

	"github.com/culpeohq/backend/internal/metasearch"
)

func newDuckduckgo(client *metasearch.HttpClient) metasearch.Engine {
	return &metasearch.XPathEngine{
		Meta: metasearch.EngineInfo{
			Name:     "duckduckgo",
			Category: "text",
			Provider: "bing",
			Priority: 1.0,
		},
		Client:     client,
		URL:        "https://html.duckduckgo.com/html/",
		Method:     "POST",
		ItemsXPath: "//div[contains(@class, 'body')]",
		ElementsXPath: map[string]string{
			"title": ".//h2//text()",
			"href":  "./a/@href",
			"body":  "./a//text()",
		},
		BuildPayload: func(p metasearch.SearchParams) (map[string]string, map[string]map[string]string, string) {
			payload := map[string]string{
				"q": p.Query,
				"b": "",
				"l": p.Region,
			}
			if p.Page > 1 {
				payload["s"] = strconv.Itoa(10 + (p.Page-2)*15)
			}
			if p.Timelimit != "" {
				payload["df"] = p.Timelimit
			}
			return payload, nil, ""
		},
		PostProcessResults: func(results []metasearch.Result) []metasearch.Result {
			out := make([]metasearch.Result, 0, len(results))
			for _, r := range results {

				if len(r.Href) > 0 && hasPrefix(r.Href, "https://duckduckgo.com/y.js?") {
					continue
				}
				out = append(out, r)
			}
			return out
		},
	}
}

func hasPrefix(s, prefix string) bool {
	return len(s) >= len(prefix) && s[:len(prefix)] == prefix
}
