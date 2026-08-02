// Package engines holds one adapter per search engine and the registry that
// selects them.
package engines

import (
	"encoding/base64"
	"strconv"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/metasearch"
)

func unwrapBingURL(rawURL string) string {
	idx := strings.Index(rawURL, "u=")
	if idx < 0 {
		return rawURL
	}
	tail := rawURL[idx+2:]
	if end := strings.IndexAny(tail, "&"); end >= 0 {
		tail = tail[:end]
	}
	if len(tail) <= 2 {
		return rawURL
	}

	b64part := tail[2:]
	pad := (-len(b64part)) % 4
	if pad < 0 {
		pad += 4
	}
	decoded, err := base64.URLEncoding.DecodeString(b64part + strings.Repeat("=", pad))
	if err != nil {
		return rawURL
	}
	return string(decoded)
}

func newBing(client *metasearch.HttpClient) metasearch.Engine {
	return &metasearch.XPathEngine{
		Meta: metasearch.EngineInfo{
			Name:     "bing",
			Category: "text",
			Provider: "bing",
			Priority: 1.0,
		},
		Client:     client,
		URL:        "https://www.bing.com/search",
		Method:     "GET",
		ItemsXPath: "//li[contains(@class, 'b_algo')]",
		ElementsXPath: map[string]string{
			"title": ".//h2/a//text()",
			"href":  ".//h2/a/@href",
			"body":  ".//p//text()",
		},
		BuildPayload: func(p metasearch.SearchParams) (map[string]string, map[string]map[string]string, string) {
			country, lang := splitRegion(p.Region)
			payload := map[string]string{
				"q":  p.Query,
				"pq": p.Query,
				"cc": lang,
			}
			cookies := map[string]map[string]string{
				"https://www.bing.com": {
					"_EDGE_CD": "m=" + lang + "-" + country + "&u=" + lang + "-" + country,
					"_EDGE_S":  "mkt=" + lang + "-" + country + "&ui=" + lang + "-" + country,
				},
			}
			if p.Timelimit != "" {
				d := int(time.Now().Unix() / 86400)
				var code string
				switch p.Timelimit {
				case "y":
					code = "ez5_" + strconv.Itoa(d-365) + "_" + strconv.Itoa(d)
				case "d":
					code = "ez1"
				case "w":
					code = "ez2"
				case "m":
					code = "ez3"
				default:
					code = "ez1"
				}
				payload["filters"] = "ex1:\"" + code + "\""
			}
			if p.Page > 1 {
				payload["first"] = strconv.Itoa((p.Page - 1) * 10)
				form := "PERE"
				if p.Page > 2 {
					form += strconv.Itoa(p.Page - 2)
				}
				payload["FORM"] = form
			}
			return payload, cookies, ""
		},
		PostProcessResults: func(results []metasearch.Result) []metasearch.Result {
			out := make([]metasearch.Result, 0, len(results))
			for _, r := range results {
				if strings.HasPrefix(r.Href, "https://www.bing.com/aclick?") {
					continue
				}
				if strings.HasPrefix(r.Href, "https://www.bing.com/ck/a?") {
					r.Href = unwrapBingURL(r.Href)
				}
				out = append(out, r)
			}
			return out
		},
	}
}

func splitRegion(region string) (country, lang string) {
	region = strings.ToLower(strings.TrimSpace(region))
	if region == "" {
		return "us", "en"
	}
	idx := strings.Index(region, "-")
	if idx < 0 {
		return region, "en"
	}
	country = region[:idx]
	lang = region[idx+1:]
	if country == "" {
		country = "us"
	}
	if lang == "" {
		lang = "en"
	}
	return country, lang
}
