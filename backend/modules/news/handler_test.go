package news

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestParseFeedItemsRSS(t *testing.T) {
	data := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>GPU launch</title>
      <link>https://example.com/articles/gpu-launch</link>
      <description><![CDATA[<p>Hello <strong>world</strong></p>]]></description>
      <pubDate>Mon, 08 Jul 2026 12:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>`)

	items, err := parseFeedItems(data, "Test Feed", []string{"Hardware"})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}

	item := items[0]
	if item.Title != "GPU launch" {
		t.Fatalf("Title = %q, want %q", item.Title, "GPU launch")
	}
	if item.Content != "Hello world" {
		t.Fatalf("Content = %q, want %q", item.Content, "Hello world")
	}
	if item.URL != "https://example.com/articles/gpu-launch" {
		t.Fatalf("URL = %q, want article URL", item.URL)
	}
	if item.ImageURL != "" {
		t.Fatalf("ImageURL = %q, want empty image URL when feed has no image", item.ImageURL)
	}
	if item.PublishedAt.IsZero() {
		t.Fatal("PublishedAt is zero, want parsed timestamp")
	}
	if item.Category != "Hardware" {
		t.Fatalf("Category = %q, want %q", item.Category, "Hardware")
	}
}

func TestParseFeedItemsAtom(t *testing.T) {
	data := []byte(`<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <title>OpenAI ships new tools</title>
    <summary type="html">&lt;p&gt;Fast rollout for teams&lt;/p&gt;&lt;img src=&quot;https://cdn.example.com/openai.png?quality=90&amp;strip=all&quot; /&gt;</summary>
    <updated>2026-07-09T13:32:30-04:00</updated>
    <link rel="alternate" href="https://example.com/openai-tools" />
  </entry>
</feed>`)

	items, err := parseFeedItems(data, "The Verge AI", []string{"The Verge", "AI"})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}

	item := items[0]
	if item.Title != "OpenAI ships new tools" {
		t.Fatalf("Title = %q", item.Title)
	}
	if item.Content != "Fast rollout for teams" {
		t.Fatalf("Content = %q", item.Content)
	}
	if item.URL != "https://example.com/openai-tools" {
		t.Fatalf("URL = %q", item.URL)
	}
	if item.ImageURL != "https://cdn.example.com/openai.png?quality=90&strip=all" {
		t.Fatalf("ImageURL = %q", item.ImageURL)
	}
	expected := time.Date(2026, 7, 9, 17, 32, 30, 0, time.UTC)
	if !item.PublishedAt.Equal(expected) {
		t.Fatalf("PublishedAt = %v, want %v", item.PublishedAt, expected)
	}
}

func TestParseFeedItemsRSSExtractsMediaImage(t *testing.T) {
	data := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <item>
      <title>Chip launch</title>
      <link>https://example.com/articles/chip-launch</link>
      <description>Article body</description>
      <pubDate>Mon, 08 Jul 2026 12:00:00 GMT</pubDate>
      <media:content url="https://cdn.example.com/chip.jpg" medium="image"></media:content>
    </item>
  </channel>
</rss>`)

	items, err := parseFeedItems(data, "Tom's Hardware", []string{"Hardware"})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}
	if items[0].ImageURL != "https://cdn.example.com/chip.jpg" {
		t.Fatalf("ImageURL = %q", items[0].ImageURL)
	}
}

func TestCollectFeedItemsContinuesAfterHTTPError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/forbidden":
			http.Error(w, "blocked", http.StatusForbidden)
		case "/ok":
			w.Header().Set("Content-Type", "application/rss+xml")
			fmt.Fprint(w, `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Still works</title>
      <link>https://example.com/still-works</link>
      <description>Healthy source</description>
      <pubDate>Mon, 08 Jul 2026 12:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>`)
		default:
			http.NotFound(w, r)
		}
	}))
	defer server.Close()

	sources := []feedSource{
		{
			URL:         server.URL + "/forbidden",
			Author:      "Blocked Feed",
			DefaultTags: []string{"Hardware"},
		},
		{
			URL:         server.URL + "/ok",
			Author:      "Healthy Feed",
			DefaultTags: []string{"AI"},
		},
	}

	items := collectFeedItems(server.Client(), sources)
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}
	if items[0].Author != "Healthy Feed" {
		t.Fatalf("Author = %q, want %q", items[0].Author, "Healthy Feed")
	}
}

func TestInvalidPublishedDateFallsBackToZeroTime(t *testing.T) {
	data := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Broken date</title>
      <link>https://example.com/broken-date</link>
      <description>Article body</description>
      <pubDate>not-a-date</pubDate>
    </item>
  </channel>
</rss>`)

	items, err := parseFeedItems(data, "Test Feed", []string{"AI"})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}
	if !items[0].PublishedAt.IsZero() {
		t.Fatalf("PublishedAt = %v, want zero time", items[0].PublishedAt)
	}
}

func TestTrimPreviewContentUsesFallbackForEmptyMarkup(t *testing.T) {
	content := trimPreviewContent(strings.Repeat(" ", 3) + "<p></p>")
	if content != "Keine Vorschau verfügbar. Bitte besuche den Originalartikel über den Link." {
		t.Fatalf("trimPreviewContent() = %q", content)
	}
}

func TestBuildNewsItemIDStripsTrackingQuery(t *testing.T) {
	id := buildNewsItemID(
		"OpenAI News",
		"https://openai.com/index/introducing-gpt-5/?utm_source=rss&utm_medium=rss",
	)
	if id != "openai-openai-com-index-introducing-gpt-5" {
		t.Fatalf("buildNewsItemID() = %q", id)
	}
}

func TestBuildNewsItemIDUsesFullPathToAvoidBasenameCollisions(t *testing.T) {
	first := buildNewsItemID("The Verge AI", "https://example.com/ai/foo/post")
	second := buildNewsItemID("The Verge AI", "https://example.com/tech/bar/post")
	if first == second {
		t.Fatalf("expected distinct IDs, got %q and %q", first, second)
	}
}

func TestStripHTMLPreservesWordBoundaries(t *testing.T) {
	got := stripHTML("<p>Foo</p><p>Bar</p><strong>Baz</strong>")
	if got != "Foo Bar Baz" {
		t.Fatalf("stripHTML() = %q", got)
	}
}

func TestExtractImageURLFromHTMLPrefersNonDecorativeImage(t *testing.T) {
	content := `
		<p>Text</p>
		<img src="https://cdn.example.com/disclosure-label.png" />
		<img src="https://cdn.example.com/articles/hero-image.jpg" />
	`
	got := extractImageURLFromHTML(content)
	if got != "https://cdn.example.com/articles/hero-image.jpg" {
		t.Fatalf("extractImageURLFromHTML() = %q", got)
	}
}

func TestNewFallbackItemsDoNotUsePlaceholderImages(t *testing.T) {
	module := New()
	for _, item := range module.items {
		if strings.Contains(item.ImageURL, "picsum.photos") {
			t.Fatalf("fallback item %q still uses placeholder image %q", item.ID, item.ImageURL)
		}
	}
}
