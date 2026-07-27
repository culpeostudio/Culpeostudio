package metasearch

import (
	"context"
	"strings"

	"github.com/antchfx/htmlquery"
	"golang.org/x/net/html"
)

// Engine ist das Interface, das alle Such-Backends implementieren.
// Es ersetzt die abstrakte Python-Basisklasse BaseSearchEngine durch
// das fuer Go typische kleine Interface.
type Engine interface {
	// Info liefert die statischen Metadaten des Engines.
	Info() EngineInfo

	// Search fuehrt eine Suche durch. params.Query ist Pflicht.
	// Bei Engine-Fehlern (Rate-Limit, Timeout, HTTP != 200) wird ein
	// Fehler geliefert; ein leeres result-Set ohne Fehler bedeutet,
	// dass der Engine erfolgreich suchte, aber keine Treffer hat.
	Search(ctx context.Context, p SearchParams) ([]Result, error)
}

// EngineInfo beschreibt die statische Konfiguration eines Engines.
type EngineInfo struct {
	Name     string
	Category string // text|images|videos|news|books
	Provider string // wer liefert die Daten (z.B. "bing" fuer DuckDuckGo)
	Disabled bool
	Priority float64
}

// SearchParams fasst alle Engine-relevanten Such-Parameter zusammen.
// Engines muessen nicht alle nutzen, muessen aber unknown values
// tolerant ignorieren.
type SearchParams struct {
	Query      string
	Region     string // "us-en"
	Safesearch string // "on"|"moderate"|"off"
	Timelimit  string // "d"|"w"|"m"|"y"
	Page       int
	Max        int
	Backend    string // legacy: kommagetrennte Engine-Liste, Aufgaben des Aggregators
	Extra      map[string]string
}

// XPathEngine ist die Hilfs-Implementierung fuer Engines, die HTML via
// XPath-Scraping verarbeiten. Es entspricht direkt dem Python-Fluss
//
//	build_payload -> request -> extract_results -> post_extract_results.
//
// Engines, die JSON liefern (z.B. Wikipedia), implementieren Engine
// direkt und umgehen XPathEngine.
type XPathEngine struct {
	Meta          EngineInfo
	Client        *HttpClient
	URL           string
	Method        string // GET oder POST; default GET
	Headers       map[string]string
	ItemsXPath    string
	ElementsXPath map[string]string

	// BuildPayload liefert die Query/Form-Parameter sowie
	// optionale Cookies (pro URL). Wenn requestURL nicht-leer ist,
	// wird es statt URL benutzt (fuer Engines wie Wikipedia, die
	// ihre URL in BuildPayload anpassen).
	BuildPayload func(p SearchParams) (payload map[string]string, cookies map[string]map[string]string, requestURL string)

	// PreProcessHTML kapselt die Python-Version pre_process_html und wird
	// vor dem Parsen ausgefuehrt. Z.B. Anna's Archive strippt Kommentare.
	PreProcessHTML func(htmlText string) string

	// PostProcessResults kapselt post_extract_results (z.B. Bing URL-Unwrapping).
	PostProcessResults func(results []Result) []Result
}

// Info liefert die EngineInfo.
func (e *XPathEngine) Info() EngineInfo { return e.Meta }

// Search fuehrt den XPath-basierten Such-Fluss aus.
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

// extractResults parsed htmlText, iteriert itemsXPath und fuellt je
// Result die Felder anhand von elementsXPath. Entspricht der gleich-
// lautenden Python-Methode in ddgs/base.py.
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

// extractXPathText wertet xpath in Bezug auf base aus und fasst die
// Treffer-Texte mit " " zusammen. htmlquery.InnerText liefert fuer
// Attribut-XPath (.//a/@href) automatisch den Wert des Attributs:
// antchfx/htmlquery kapselt Attribute-Nodes intern als
// ElementNode{Data: name, FirstChild: TextNode{Data: value}}.
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
