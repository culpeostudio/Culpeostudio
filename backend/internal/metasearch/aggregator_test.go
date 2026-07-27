package metasearch

import (
	"reflect"
	"testing"
)

func TestAggregatorAppendIncrementAndPreferLongerBody(t *testing.T) {
	agg := NewAggregator([]string{"href"})
	agg.Append(Result{Href: "u1", Body: "a"})
	agg.Append(Result{Href: "u1", Body: "ab"}) // same key, longer body -> ueberschreibt
	agg.Append(Result{Href: "u1", Body: ""})   // same key, shorter -> bleibt ab
	agg.Append(Result{Href: "u2", Body: "abc"})
	agg.Append(Result{Href: "u3", Body: "x"})

	if agg.Len() != 3 {
		t.Fatalf("Len = %d, want 3", agg.Len())
	}
	// u1 sollte drei Treffer zaehlen
	got := agg.Counter()
	if got["u1"] != 3 {
		t.Errorf("counter[u1] = %d, want 3", got["u1"])
	}
	out := agg.Extract()
	if len(out) != 3 {
		t.Fatalf("Extract len = %d, want 3", len(out))
	}
	// u1 zuerst weil drei Treffer, dann u2 mit einem Treffer, dann u3
	if out[0].Href != "u1" || out[0].Body != "ab" {
		t.Errorf("first should be u1 with longer body: %+v", out[0])
	}
	// u1 Body sollte 'ab' sein, weil der laengere Body gewinnt
	if out[0].Body != "ab" {
		t.Errorf("longer-body preference failed: out[0].Body = %q", out[0].Body)
	}
}

func TestAggregatorFallbackKeyWithoutCacheFields(t *testing.T) {
	agg := NewAggregator([]string{"href"})
	// Eine Result ohne href sollte ueber primaryCacheKey (Title) gehen.
	agg.Append(Result{Title: "T1", Body: "x"})
	if agg.Len() != 1 {
		t.Errorf("expected 1 entry via title fallback, got %d", agg.Len())
	}
}

func TestSimpleFilterRankerWikipediaFirst(t *testing.T) {
	docs := []Result{
		{Title: "Some Blog", Body: "rust async tokio", Href: "https://blog.example.com/rust-async"},
		{Title: "Tokio runtime", Body: "tokio is async", Href: "https://en.wikipedia.org/wiki/Tokio_(software)"},
		{Title: "Unrelated", Body: "no match", Href: "https://other.example.com/whatever"},
	}
	out := NewSimpleFilterRanker().Rank(docs, "rust tokio runtime")
	if len(out) != 3 {
		t.Fatalf("len(out) = %d, want 3", len(out))
	}
	if !reflect.DeepEqual(out[0], docs[1]) {
		t.Errorf("expected Wikipedia entry first, got %+v", out[0])
	}
}

func TestSimpleFilterRankerBuckets(t *testing.T) {
	docs := []Result{
		{Title: "rust async", Body: "async tokio", Href: "u1"}, // both
		{Title: "rust", Body: "unrelated", Href: "u2"},         // title only
		{Title: "unrelated", Body: "tokio", Href: "u3"},        // body only
		{Title: "unrelated", Body: "unrelated", Href: "u4"},    // neither
	}
	out := NewSimpleFilterRanker().Rank(docs, "rust tokio")
	if len(out) != 4 {
		t.Fatalf("len(out) = %d, want 4", len(out))
	}
	// Reihenfolge: both, title-only, body-only, neither
	if out[0].Href != "u1" || out[1].Href != "u2" || out[2].Href != "u3" || out[3].Href != "u4" {
		t.Errorf("bucket order wrong: %v %v %v %v", out[0].Href, out[1].Href, out[2].Href, out[3].Href)
	}
}

func TestSimpleFilterRankerSkipsWikimediaCategory(t *testing.T) {
	docs := []Result{
		{Title: "Category:Tokio Wikimedia", Body: "skip me", Href: "https://en.wikipedia.org/wiki/Category:Tokio"},
		{Title: "Tokio runtime", Body: "tokio async", Href: "https://en.wikipedia.org/wiki/Tokio"},
	}
	out := NewSimpleFilterRanker().Rank(docs, "tokio async")
	if len(out) != 1 {
		t.Fatalf("expected only 1 hit (Category should be filtered), got %d", len(out))
	}
	if out[0].Title != "Tokio runtime" {
		t.Errorf("expected non-category hit, got %q", out[0].Title)
	}
}
