package metasearch

import (
	"context"
	"strings"

	"github.com/antchfx/htmlquery"
	"golang.org/x/net/html"
)

type Engine interface {
	Info() EngineInfo

	Search(ctx context.Context, p SearchParams) ([]Result, error)
}

type EngineInfo struct {
	Name     string
	Category string
	Provider string
	Disabled bool
	Priority float64
}

type SearchParams struct {
	Query      string
	Region     string
	Safesearch string
	Timelimit  string
	Page       int
	Max        int
	Backend    string
	Extra      map[string]string
}

type XPathEngine struct {
	Meta          EngineInfo
	Client        *HttpClient
	URL           string
	Method        string
	Headers       map[string]string
	ItemsXPath    string
	ElementsXPath map[string]string

	BuildPayload func(p SearchParams) (payload map[string]string, cookies map[string]map[string]string, requestURL string)

	PreProcessHTML func(htmlText string) string

	PostProcessResults func(results []Result) []Result
}

func (e *XPathEngine) Info() EngineInfo { return e.Meta }

func (e *XPathEngine) Search(ctx context.Context, p SearchParams) ([]Result, error) {
	if p.Region == "" {
		p.Region = "us-en"
	}
	if p.Safesearch == "" {
		p.Safesearch = "moderate"
	}
	if p.Page < 1 {
		p.Page = 1
	}

	var (
		payload    map[string]string
		cookies    map[string]map[string]string
		requestURL string
	)
	if e.BuildPayload != nil {
		payload, cookies, requestURL = e.BuildPayload(p)
	}
	if cookies != nil {
		for host, c := range cookies {
			if err := e.Client.SetCookies(host, c); err != nil {
				return nil, NewError(err, "cookies setzen")
			}
		}
	}

	if requestURL == "" {
		requestURL = e.URL
	}

	method := strings.ToUpper(e.Method)
	if method == "" {
		method = "GET"
	}

	var (
		resp *Response
		err  error
	)
	if method == "POST" {
		resp, err = e.Client.Post(ctx, requestURL, payload)
	} else {
		resp, err = e.Client.Get(ctx, requestURL, payload)
	}
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != 200 {
		return nil, nil
	}

	htmlText := resp.Text
	if e.PreProcessHTML != nil {
		htmlText = e.PreProcessHTML(htmlText)
	}

	results, err := e.extractResults(htmlText)
	if err != nil {
		return nil, NewError(err, "xpath extract")
	}

	if e.PostProcessResults != nil {
		results = e.PostProcessResults(results)
	}
	return results, nil
}

func (e *XPathEngine) extractResults(htmlText string) ([]Result, error) {
	doc, err := htmlquery.Parse(strings.NewReader(htmlText))
	if err != nil {
		return nil, err
	}
	nodes, err := htmlquery.QueryAll(doc, e.ItemsXPath)
	if err != nil {
		return nil, err
	}

	results := make([]Result, 0, len(nodes))
	for _, n := range nodes {
		var r Result
		r.Category = e.Meta.Category
		for field, xPath := range e.ElementsXPath {
			value := extractXPathText(n, xPath)
			if value != "" {
				r.Set(field, value)
			}
		}
		results = append(results, r)
	}
	return results, nil
}

func extractXPathText(base *html.Node, xPath string) string {
	nodes, err := htmlquery.QueryAll(base, xPath)
	if err != nil {
		return ""
	}
	if len(nodes) == 0 {
		return ""
	}
	parts := make([]string, 0, len(nodes))
	for _, n := range nodes {
		text := strings.TrimSpace(htmlquery.InnerText(n))
		if text != "" {
			parts = append(parts, text)
		}
	}
	return strings.Join(parts, " ")
}
