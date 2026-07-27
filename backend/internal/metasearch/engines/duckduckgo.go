package engines

import (
	"strconv"

	"github.com/fillyengine/backend/internal/metasearch"
)

// newDuckduckgo erzeugt den DuckDuckGo-Text-Engine.
// Der Engine fragt das vereinfachte HTML-Interface
// https://html.duckduckgo.com/html/ via POST ab. Der Python-Code nutzt
// dafuer einen HTTP/2-Fingerprint-Worker httpx+Patching, weil der
// Hauptendpunkt nicht-fingerprintete Clients zunehmend blockt. Wir
// nehmen den html-Endpoint mit normalem HTTP; das funktioniert
// erfahrungsgemaess in den meisten Faellen, ist aber im Gegensatz zu
// primp nicht robust gegenueber Rate-Limiting.
func newDuckduckgo(client *metasearch.HttpClient) metasearch.Engine {
	return &metasearch.XPathEngine{
		Meta: metasearch.EngineInfo{
			Name:     "duckduckgo",
			Category: "text",
			Provider: "bing", // DuckDuckGo nutzt Bing als Backend
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
				// Ad-Links ueberspringen
				if len(r.Href) > 0 && hasPrefix(r.Href, "https://duckduckgo.com/y.js?") {
					continue
				}
				out = append(out, r)
			}
			return out
		},
	}
}

// hasPrefix ist ein schmeller strings.HasPrefix-Wrapper, duerfen inline.
func hasPrefix(s, prefix string) bool {
	return len(s) >= len(prefix) && s[:len(prefix)] == prefix
}
