package engines

import (
	"context"
	"encoding/json"
	"net/url"
	"strings"

	"github.com/culpeohq/backend/internal/metasearch"
)

type wikipediaEngine struct {
	client *metasearch.HttpClient
	meta   metasearch.EngineInfo
}

func newWikipedia(client *metasearch.HttpClient) metasearch.Engine {
	return &wikipediaEngine{
		client: client,
		meta: metasearch.EngineInfo{
			Name:     "wikipedia",
			Category: "text",
			Provider: "wikipedia",
			Priority: 2.0,
		},
	}
}

func (e *wikipediaEngine) Info() metasearch.EngineInfo { return e.meta }

var wikipediaLanguages = map[string]struct{}{
	"ar": {}, "cs": {}, "da": {}, "de": {}, "el": {}, "en": {}, "es": {},
	"fa": {}, "fi": {}, "fr": {}, "he": {}, "hi": {}, "hu": {}, "id": {},
	"it": {}, "ja": {}, "ko": {}, "nl": {}, "no": {}, "pl": {}, "pt": {},
	"ro": {}, "ru": {}, "sv": {}, "th": {}, "tr": {}, "uk": {}, "vi": {},
	"zh": {},
}

func wikipediaLang(lang string) string {
	lang = strings.ToLower(strings.TrimSpace(lang))
	if _, ok := wikipediaLanguages[lang]; ok {
		return lang
	}
	return "en"
}

func (e *wikipediaEngine) Search(ctx context.Context, p metasearch.SearchParams) ([]metasearch.Result, error) {
	if p.Region == "" {
		p.Region = "us-en"
	}
	_, lang := splitRegion(p.Region)
	lang = wikipediaLang(lang)

	encodedQuery := url.QueryEscape(p.Query)
	opensearchURL := "https://" + lang + ".wikipedia.org/w/api.php?action=opensearch&profile=fuzzy&limit=1&search=" + encodedQuery

	resp, err := e.client.Get(ctx, opensearchURL, nil)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != 200 || resp.Text == "" {
		return nil, nil
	}

	var raw []json.RawMessage
	if err := json.Unmarshal([]byte(resp.Text), &raw); err != nil {
		return nil, metasearch.NewError(err, "wikipedia opensearch json decode")
	}
	if len(raw) < 4 {
		return nil, nil
	}
	var titles []string
	if err := json.Unmarshal(raw[1], &titles); err != nil {
		return nil, metasearch.NewError(err, "wikipedia titles decode")
	}
	if len(titles) == 0 {
		return nil, nil
	}
	var hrefs []string
	if err := json.Unmarshal(raw[3], &hrefs); err != nil {
		return nil, metasearch.NewError(err, "wikipedia hrefs decode")
	}
	if len(hrefs) == 0 {
		return nil, nil
	}

	result := metasearch.Result{Category: "text"}
	result.Set("title", titles[0])
	result.Set("href", hrefs[0])

	encodedTitle := url.QueryEscape(titles[0])
	queryURL := "https://" + lang + ".wikipedia.org/w/api.php?action=query&format=json&prop=extracts&titles=" +
		encodedTitle + "&explaintext=0&exintro=0&redirects=1"
	qResp, err := e.client.Get(ctx, queryURL, nil)
	if err == nil && qResp != nil && qResp.StatusCode == 200 && qResp.Text != "" {
		var doc struct {
			Query struct {
				Pages map[string]struct {
					Extract string `json:"extract"`
				} `json:"pages"`
			} `json:"query"`
		}
		if err := json.Unmarshal([]byte(qResp.Text), &doc); err == nil {
			for _, page := range doc.Query.Pages {
				if page.Extract != "" {

					result.Set("body", page.Extract)
				}
				break
			}
		}
	}

	if strings.Contains(result.Body, "may refer to:") {
		return nil, nil
	}

	return []metasearch.Result{result}, nil
}
