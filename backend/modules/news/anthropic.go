// Package news aggregates AI and technology feeds, deduplicates them, and keeps
// per-user saved articles. Some sources are best-effort scrapers rather than
// feeds.
package news

import (
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/antchfx/htmlquery"
	"golang.org/x/net/html"
)

const (
	anthropicNewsURL = "https://www.anthropic.com/news"
	anthropicBaseURL = "https://www.anthropic.com"
	anthropicAuthor  = "Anthropic News"
)

var anthropicDefaultTags = []string{"Anthropic", "AI"}

func fetchAnthropicNews(client *http.Client) []NewsItem {
	req, err := http.NewRequest("GET", anthropicNewsURL, nil)
	if err != nil {
		log.Printf("[NEWS] Konnte Request für %s nicht erstellen: %v", anthropicAuthor, err)
		return nil
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("[NEWS] Ladefehler für %s: %v", anthropicAuthor, err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Printf("[NEWS] Statusfehler für %s: %d", anthropicAuthor, resp.StatusCode)
		return nil
	}

	doc, err := htmlquery.Parse(resp.Body)
	if err != nil {
		log.Printf("[NEWS] Parsing-Fehler für %s: %v", anthropicAuthor, err)
		return nil
	}

	items := parseAnthropicNews(doc)
	if len(items) == 0 {
		log.Printf("[NEWS] %s lieferte keine Beiträge -- vermutlich hat sich das Seitenlayout geändert.", anthropicAuthor)
	}
	return items
}

func parseAnthropicNews(doc *html.Node) []NewsItem {
	nodes, err := htmlquery.QueryAll(doc, "//a[starts-with(@href, '/news/')]")
	if err != nil {
		log.Printf("[NEWS] XPath-Fehler für %s: %v", anthropicAuthor, err)
		return nil
	}

	var items []NewsItem
	seen := make(map[string]struct{}, len(nodes))
	for _, node := range nodes {
		href := strings.TrimSpace(htmlquery.SelectAttr(node, "href"))

		if href == "" || href == "/news" || href == "/news/" {
			continue
		}
		if _, exists := seen[href]; exists {
			continue
		}

		title, subject, dateText, teaser := anthropicEntryFields(node)
		if title == "" {
			continue
		}
		seen[href] = struct{}{}

		tags := anthropicDefaultTags
		if subject != "" {
			tags = append([]string{subject}, anthropicDefaultTags...)
		}

		link := anthropicBaseURL + href
		items = append(items, NewsItem{
			ID:          buildNewsItemID(anthropicAuthor, link),
			Title:       title,
			Content:     trimPreviewContent(teaser),
			Author:      anthropicAuthor,
			PublishedAt: parseAnthropicDate(dateText),
			Tags:        tags,
			ImageURL:    normalizeImageURL(anthropicImageURL(node)),
			URL:         link,
			Category:    classifyCategory(title, teaser, anthropicAuthor, tags),
		})
	}
	return items
}

func anthropicEntryFields(node *html.Node) (title, subject, dateText, teaser string) {
	dateText = anthropicText(node, ".//time")
	teaser = anthropicText(node, ".//p")

	headings, _ := htmlquery.QueryAll(node, ".//h1|.//h2|.//h3|.//h4|.//h5|.//h6")
	spans, _ := htmlquery.QueryAll(node, ".//span")

	spanTexts := make([]string, 0, len(spans))
	for _, span := range spans {
		if text := strings.TrimSpace(htmlquery.InnerText(span)); text != "" {
			spanTexts = append(spanTexts, text)
		}
	}

	if len(headings) > 0 {
		title = strings.TrimSpace(htmlquery.InnerText(headings[0]))
		if len(spanTexts) > 0 {
			subject = spanTexts[0]
		}
		return title, subject, dateText, teaser
	}

	if len(spanTexts) > 0 {
		title = spanTexts[len(spanTexts)-1]
	}
	if len(spanTexts) > 1 {
		subject = spanTexts[0]
	}
	return title, subject, dateText, teaser
}

func anthropicText(node *html.Node, xpath string) string {
	found, err := htmlquery.Query(node, xpath)
	if err != nil || found == nil {
		return ""
	}
	return strings.TrimSpace(htmlquery.InnerText(found))
}

// anthropicImageURL extractiert das Artikelbild aus einer Eintrags-Karte.
// Anthropic rendert Bilder über next/image, die echte Asset-URL steckt dann
// URL-encodiert im "url"-Query-Parameter; auch direkte URLs sind möglich.
// Dekorative Bilder (Logos, Icons) werden übersprungen.
func anthropicImageURL(node *html.Node) string {
	imgs, err := htmlquery.QueryAll(node, ".//img")
	if err != nil {
		return ""
	}
	for _, img := range imgs {
		for _, attr := range []string{"src", "data-src"} {
			raw := strings.TrimSpace(htmlquery.SelectAttr(img, attr))
			if raw == "" {
				continue
			}
			candidate := resolveAnthropicImageURL(raw)
			if candidate == "" || looksDecorativeImageURL(candidate) {
				continue
			}
			return candidate
		}
	}
	return ""
}

func resolveAnthropicImageURL(raw string) string {
	if strings.HasPrefix(raw, "/_next/image") {
		if parsed, err := url.Parse(raw); err == nil {
			if target := strings.TrimSpace(parsed.Query().Get("url")); target != "" {
				return target
			}
		}
	}
	if strings.HasPrefix(raw, "/") {
		return anthropicBaseURL + raw
	}
	return raw
}

func parseAnthropicDate(value string) time.Time {
	value = strings.TrimSpace(value)
	if value == "" {
		return time.Time{}
	}
	for _, layout := range []string{"Jan 2, 2006", "January 2, 2006", "2006-01-02"} {
		if parsed, err := time.Parse(layout, value); err == nil {
			return parsed.UTC()
		}
	}
	log.Printf("[NEWS] Konnte Veröffentlichungsdatum für %s nicht parsen: %q", anthropicAuthor, value)
	return time.Time{}
}
