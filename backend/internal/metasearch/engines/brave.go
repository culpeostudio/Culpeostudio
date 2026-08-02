package engines

import (
	"strconv"

	"github.com/fillyengine/backend/internal/metasearch"
)

func newBrave(client *metasearch.HttpClient) metasearch.Engine {
	return &metasearch.XPathEngine{
		Meta: metasearch.EngineInfo{
			Name:     "brave",
			Category: "text",
			Provider: "brave",
			Priority: 1.0,
		},
		Client:     client,
		URL:        "https://search.brave.com/search",
		Method:     "GET",
		ItemsXPath: "//div[@data-type='web']",
		ElementsXPath: map[string]string{
			"title": ".//div[(contains(@class,'title') or contains(@class,'sitename-container')) and position()=last()]//text()",
			"href":  ".//a[div[contains(@class, 'title')]]/@href",
			"body":  ".//div[contains(@class, 'snippet')]//div[contains(@class, 'content')]//text()",
		},
		BuildPayload: func(p metasearch.SearchParams) (map[string]string, map[string]map[string]string, string) {
			country, _ := splitRegion(p.Region)
			payload := map[string]string{
				"q":      p.Query,
				"source": "web",
			}
			cookies := map[string]string{
				country:       country,
				"useLocation": "0",
			}
			if p.Safesearch != "moderate" {
				if p.Safesearch == "on" {
					cookies["safesearch"] = "strict"
				} else {
					cookies["safesearch"] = "off"
				}
			}
			if p.Timelimit != "" {
				m := map[string]string{"d": "pd", "w": "pw", "m": "pm", "y": "py"}
				if v, ok := m[p.Timelimit]; ok {
					payload["tf"] = v
				}
			}
			if p.Page > 1 {
				payload["offset"] = strconv.Itoa(p.Page - 1)
			}
			return payload, map[string]map[string]string{"https://search.brave.com": cookies}, ""
		},
	}
}
