package news

import (
	"strings"
	"testing"
	"time"

	"github.com/antchfx/htmlquery"
)

const anthropicFixture = `<html><body>
<div class="FeaturedGrid-module-scss-module__W1FydW__grid">
  <a href="/news/claude-opus-5" class="FeaturedGrid-module-scss-module__W1FydW__content">
    <img alt="Claude Opus 5" decoding="async" src="/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F54b7ab1d2c2521f83ae5d2da5f9d99321c370d24-2880x1620.png&amp;w=3840&amp;q=75"/>
    <h2 class="headline-4 FeaturedGrid-module-scss-module__W1FydW__featuredTitle">Introducing Claude Opus 5</h2>
    <div class="FeaturedGrid-module-scss-module__W1FydW__featuredItemContent">
      <div class="FeaturedGrid-module-scss-module__W1FydW__meta">
        <span class="caption bold">Product</span>
        <time class="FeaturedGrid-module-scss-module__W1FydW__date caption bold">Jul 24, 2026</time>
      </div>
      <p class="body-3 serif">Opus 5 is a step change improvement for the Opus tier powering long-running agents.</p>
    </div>
  </a>
</div>
<div class="FeaturedGrid-module-scss-module__W1FydW__sideItems">
  <a href="/news/hard-questions" class="FeaturedGrid-module-scss-module__W1FydW__sideLink">
    <div class="FeaturedGrid-module-scss-module__W1FydW__meta">
      <span class="caption bold">Announcements</span>
      <time class="FeaturedGrid-module-scss-module__W1FydW__date caption bold">Jul 9, 2026</time>
    </div>
    <h4 class="headline-6 FeaturedGrid-module-scss-module__W1FydW__title">Inviting hard questions</h4>
    <p class="body-3 serif">We&#39;re asking the public for their hardest questions about AI.</p>
  </a>
</div>
<ul>
  <li><a href="/news/investigating-incidents-cybersecurity-evals" class="PublicationList-module-scss-module__KxYrHG__listItem"><div class="PublicationList-module-scss-module__KxYrHG__meta"><time class="PublicationList-module-scss-module__KxYrHG__date body-3">Jul 30, 2026</time><span class="PublicationList-module-scss-module__KxYrHG__subject body-3">Frontier Red Team</span></div><span class="PublicationList-module-scss-module__KxYrHG__title body-3">Investigating three real-world incidents in our cybersecurity evaluations</span></a></li>
  <li><a href="/news/claude-opus-5" class="PublicationList-module-scss-module__KxYrHG__listItem"><div class="PublicationList-module-scss-module__KxYrHG__meta"><time class="PublicationList-module-scss-module__KxYrHG__date body-3">Jul 24, 2026</time><span class="PublicationList-module-scss-module__KxYrHG__subject body-3">Product</span></div><span class="PublicationList-module-scss-module__KxYrHG__title body-3">Introducing Claude Opus 5</span></a></li>
</ul>
<a href="/news">Alle Meldungen</a>
</body></html>`

func parseAnthropicFixture(t *testing.T, markup string) []NewsItem {
	t.Helper()
	doc, err := htmlquery.Parse(strings.NewReader(markup))
	if err != nil {
		t.Fatalf("Parse() error = %v", err)
	}
	return parseAnthropicNews(doc)
}

func TestParseAnthropicNewsReadsFeaturedAndListEntries(t *testing.T) {
	items := parseAnthropicFixture(t, anthropicFixture)

	if len(items) != 3 {
		t.Fatalf("len(items) = %d, want 3", len(items))
	}

	side := items[1]
	if side.Title != "Inviting hard questions" {
		t.Fatalf("Titel der Seitenspalte = %q, want die Ueberschrift statt der Rubrik", side.Title)
	}
	if side.Tags[0] != "Announcements" {
		t.Fatalf("Tags der Seitenspalte = %v", side.Tags)
	}

	featured := items[0]
	if featured.Title != "Introducing Claude Opus 5" {
		t.Fatalf("Title = %q", featured.Title)
	}
	if featured.URL != "https://www.anthropic.com/news/claude-opus-5" {
		t.Fatalf("URL = %q", featured.URL)
	}
	if featured.Author != "Anthropic News" {
		t.Fatalf("Author = %q", featured.Author)
	}
	if !strings.HasPrefix(featured.Content, "Opus 5 is a step change improvement") {
		t.Fatalf("Content = %q", featured.Content)
	}
	if featured.Tags[0] != "Product" {
		t.Fatalf("Tags = %v, want die Rubrik zuerst", featured.Tags)
	}
	expected := time.Date(2026, 7, 24, 0, 0, 0, 0, time.UTC)
	if !featured.PublishedAt.Equal(expected) {
		t.Fatalf("PublishedAt = %v, want %v", featured.PublishedAt, expected)
	}
	wantImage := "https://www-cdn.anthropic.com/images/4zrzovbb/website/54b7ab1d2c2521f83ae5d2da5f9d99321c370d24-2880x1620.png"
	if featured.ImageURL != wantImage {
		t.Fatalf("ImageURL = %q, want decodierte CDN-URL %q", featured.ImageURL, wantImage)
	}

	listed := items[2]
	if listed.Title != "Investigating three real-world incidents in our cybersecurity evaluations" {
		t.Fatalf("Titel des Listeneintrags = %q", listed.Title)
	}
	if listed.Tags[0] != "Frontier Red Team" {
		t.Fatalf("Tags = %v", listed.Tags)
	}
	if listed.PublishedAt.IsZero() {
		t.Fatal("PublishedAt ist leer")
	}
	if listed.ImageURL != "" {
		t.Fatalf("ImageURL des Listeneintrags = %q, want leer", listed.ImageURL)
	}
}

func TestResolveAnthropicImageURL(t *testing.T) {
	cases := []struct {
		name string
		raw  string
		want string
	}{
		{
			name: "next/image-Pfad liefert die dekorierte CDN-URL",
			raw:  "/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2Fopus.png&w=3840&q=75",
			want: "https://www-cdn.anthropic.com/images/opus.png",
		},
		{
			name: "absolute URL bleibt unverändert",
			raw:  "https://www-cdn.anthropic.com/images/opus.png",
			want: "https://www-cdn.anthropic.com/images/opus.png",
		},
		{
			name: "relative URL wird auf die Artikelbasis gehoben",
			raw:  "/images/opus.png",
			want: "https://www.anthropic.com/images/opus.png",
		},
		{
			name: "leerer Eingabewert bleibt leer",
			raw:  "",
			want: "",
		},
	}
	for _, tc := range cases {
		if got := resolveAnthropicImageURL(tc.raw); got != tc.want {
			t.Fatalf("%s: resolveAnthropicImageURL(%q) = %q, want %q", tc.name, tc.raw, got, tc.want)
		}
	}
}

func TestParseAnthropicNewsSurvivesLayoutChange(t *testing.T) {

	items := parseAnthropicFixture(t, `<html><body><div><a href="/news/etwas"></a></div></body></html>`)
	if len(items) != 0 {
		t.Fatalf("len(items) = %d, want 0", len(items))
	}
}

func TestParseAnthropicDateAcceptsTheUsualFormats(t *testing.T) {
	if got := parseAnthropicDate("Jul 24, 2026"); got.IsZero() {
		t.Fatal("kurzes Monatsformat wurde nicht gelesen")
	}
	if got := parseAnthropicDate("January 2, 2026"); got.IsZero() {
		t.Fatal("langes Monatsformat wurde nicht gelesen")
	}
	if got := parseAnthropicDate("gestern"); !got.IsZero() {
		t.Fatalf("unbekanntes Format ergab %v, want Nullzeit", got)
	}
}
