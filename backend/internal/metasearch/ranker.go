package metasearch

import (
	"regexp"
	"strings"
)

type SimpleFilterRanker struct {
	MinTokenLength int

	PreferWikipedia bool

	splitter *regexp.Regexp
}

func NewSimpleFilterRanker() *SimpleFilterRanker {
	return &SimpleFilterRanker{
		MinTokenLength:  3,
		PreferWikipedia: true,
		splitter:        regexp.MustCompile(`\W+`),
	}
}

func NewRelevanceRanker() *SimpleFilterRanker {
	r := NewSimpleFilterRanker()
	r.PreferWikipedia = false
	return r
}

func (r *SimpleFilterRanker) extractTokens(query string) map[string]struct{} {
	tokens := map[string]struct{}{}
	for _, tok := range r.splitter.Split(strings.ToLower(query), -1) {
		if len(tok) >= r.MinTokenLength {
			tokens[tok] = struct{}{}
		}
	}
	return tokens
}

func (r *SimpleFilterRanker) hasAnyToken(text string, tokens map[string]struct{}) bool {
	if len(tokens) == 0 {
		return false
	}
	lower := strings.ToLower(text)
	for tok := range tokens {
		if strings.Contains(lower, tok) {
			return true
		}
	}
	return false
}

func (r *SimpleFilterRanker) Rank(docs []Result, query string) []Result {
	tokens := r.extractTokens(query)

	var wikiHits, both, titleOnly, bodyOnly, neither []Result
	for _, doc := range docs {
		title := doc.Title
		body := doc.Body
		if body == "" {
			body = doc.Description
		}

		if strings.Contains(title, "Category:") && strings.Contains(title, "Wikimedia") {
			continue
		}

		if r.PreferWikipedia && strings.Contains(doc.Href, "wikipedia.org") {
			wikiHits = append(wikiHits, doc)
			continue
		}

		hitTitle := r.hasAnyToken(title, tokens)
		hitBody := r.hasAnyToken(body, tokens)

		switch {
		case hitTitle && hitBody:
			both = append(both, doc)
		case hitTitle:
			titleOnly = append(titleOnly, doc)
		case hitBody:
			bodyOnly = append(bodyOnly, doc)
		default:
			neither = append(neither, doc)
		}
	}

	out := make([]Result, 0, len(docs))
	out = append(out, wikiHits...)
	out = append(out, both...)
	out = append(out, titleOnly...)
	out = append(out, bodyOnly...)
	out = append(out, neither...)
	return out
}
