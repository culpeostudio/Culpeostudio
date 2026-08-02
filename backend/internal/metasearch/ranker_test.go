package metasearch

import (
	"strings"
	"testing"
)

func TestRelevanceRankerIgnoriertWikipediaBonus(t *testing.T) {
	docs := []Result{
		{Title: "Go (Spiel)", Href: "https://de.wikipedia.org/wiki/Go_(Spiel)", Body: "Brettspiel"},
		{Title: "Go 1.25 Release Notes", Href: "https://go.dev/doc/go1.25", Body: "Release Notes fuer Go 1.25"},
	}
	const query = "go 1.25 release notes"

	relevance := NewRelevanceRanker().Rank(append([]Result{}, docs...), query)
	if len(relevance) != 2 || relevance[0].Href != "https://go.dev/doc/go1.25" {
		t.Fatalf("Relevanz-Ranker sollte go.dev zuerst liefern, bekam: %+v", relevance)
	}

	standard := NewSimpleFilterRanker().Rank(append([]Result{}, docs...), query)
	if len(standard) != 2 || !strings.Contains(standard[0].Href, "wikipedia.org") {
		t.Fatalf("Standard-Ranker sollte Wikipedia zuerst liefern, bekam: %+v", standard)
	}
}

func TestRankerFiltertWikimediaKategorien(t *testing.T) {
	docs := []Result{
		{Title: "Category:Go — Wikimedia", Href: "https://commons.wikimedia.org/wiki/Category:Go"},
		{Title: "Go Doku", Href: "https://go.dev/doc", Body: "Doku"},
	}
	out := NewRelevanceRanker().Rank(docs, "go doku")
	if len(out) != 1 || out[0].Href != "https://go.dev/doc" {
		t.Fatalf("Wikimedia-Kategorieseite sollte entfallen, bekam: %+v", out)
	}
}
