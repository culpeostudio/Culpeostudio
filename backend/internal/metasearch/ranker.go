package metasearch

import (
	"regexp"
	"strings"
)

// SimpleFilterRanker implementiert das ranking aus ddgs/similarity.py:
//  1. Wikipedia-Treffer landen ganz oben.
//  2. Der Rest wird bucketaet: beide (Titel+Treffer), nur Titel, nur Body, nichts.
//  3. Wikimedia-"Category:"-Seiten werden komplett entfernt.
type SimpleFilterRanker struct {
	MinTokenLength int

	// PreferWikipedia hebt Wikipedia-Treffer unabhaengig von ihrer
	// Passung an die Spitze. Das ist fuer eine Nachschlage-Suche
	// sinnvoll, schadet aber der Recherche zu konkreten technischen
	// Fragen: bei "go 1.25 release notes" landet dann der Artikel
	// "Go (Spiel)" vor go.dev. Aufrufer, die Relevanz brauchen,
	// setzen das Feld auf false.
	PreferWikipedia bool

	splitter *regexp.Regexp
}

// NewSimpleFilterRanker erzeugt einen Ranker mit der Standardkonfiguration
// (minTokenLength = 3, Wikipedia-Treffer bevorzugt).
func NewSimpleFilterRanker() *SimpleFilterRanker {
	return &SimpleFilterRanker{
		MinTokenLength:  3,
		PreferWikipedia: true,
		splitter:        regexp.MustCompile(`\W+`),
	}
}

// NewRelevanceRanker erzeugt einen Ranker, der ausschliesslich nach der
// Passung zur Suchanfrage sortiert - ohne Sonderrolle fuer Wikipedia.
func NewRelevanceRanker() *SimpleFilterRanker {
	r := NewSimpleFilterRanker()
	r.PreferWikipedia = false
	return r
}

// extractTokens zerlegt die Query am non-word-Splitter und behaelt nur
// Tokens mit Mindestlaenge.
func (r *SimpleFilterRanker) extractTokens(query string) map[string]struct{} {
	tokens := map[string]struct{}{}
	for _, tok := range r.splitter.Split(strings.ToLower(query), -1) {
		if len(tok) >= r.MinTokenLength {
			tokens[tok] = struct{}{}
		}
	}
	return tokens
}

// hasAnyToken prueft, ob einer der Tokens als Substring in text vorkommt.
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

// Rank sortiert die Treffer-Liste nach dem beschriebenen Schema und
// filtert Wikimedia-Category-Seiten heraus.
func (r *SimpleFilterRanker) Rank(docs []Result, query string) []Result {
	tokens := r.extractTokens(query)

	var wikiHits, both, titleOnly, bodyOnly, neither []Result
	for _, doc := range docs {
		title := doc.Title
		body := doc.Body
		if body == "" {
			body = doc.Description
		}

		// Wikimedia Category-Skip
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
