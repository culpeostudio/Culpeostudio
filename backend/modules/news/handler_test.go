package news

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"path/filepath"
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

	items, err := parseFeedItems(data, feedSource{Author: "Test Feed", DefaultTags: []string{"Hardware"}})
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

	items, err := parseFeedItems(data, feedSource{Author: "The Verge AI", DefaultTags: []string{"The Verge", "AI"}})
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

	items, err := parseFeedItems(data, feedSource{Author: "Tom's Hardware", DefaultTags: []string{"Hardware"}})
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

func TestParseFeedItemsDecodesISO88591Feed(t *testing.T) {

	latin1 := func(s string) []byte {
		out := make([]byte, 0, len(s))
		for _, r := range s {
			out = append(out, byte(r))
		}
		return out
	}

	data := latin1(`<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Prozessoren für Rechenzentren angekündigt</title>
      <link>https://www.golem.de/news/prozessoren-2607-211431.html</link>
      <description>Größere Fertigungskapazitäten für Serverchips.</description>
      <pubDate>Thu, 30 Jul 2026 18:00:02 +0200</pubDate>
    </item>
  </channel>
</rss>`)

	items, err := parseFeedItems(data, feedSource{Author: "Golem.de", DefaultTags: []string{"Golem", "Tech"}})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}
	if items[0].Title != "Prozessoren für Rechenzentren angekündigt" {
		t.Fatalf("Title = %q, want umlauts decoded", items[0].Title)
	}
	if items[0].Content != "Größere Fertigungskapazitäten für Serverchips." {
		t.Fatalf("Content = %q, want umlauts decoded", items[0].Content)
	}
	if items[0].ID != "golem-de-www-golem-de-news-prozessoren-2607-211431-html" {
		t.Fatalf("ID = %q", items[0].ID)
	}
}

func TestParseFeedItemsPrefersEncodedContentImageOverTrackingPixel(t *testing.T) {

	data := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <item>
      <title>Serverchips</title>
      <link>https://www.golem.de/news/serverchips-2607-211464.html</link>
      <description>Text &lt;img src="https://cpx.golem.de/cpx.php?class=17&amp;amp;aid=211464" width="1" height="1" /&gt;</description>
      <content:encoded><![CDATA[<img src="https://www.golem.de/2607/211464-590635_rc.jpg" width="416" height="234">Text <img src="https://cpx.golem.de/cpx.php?class=17&amp;aid=211464" width="1" height="1" />]]></content:encoded>
      <pubDate>Thu, 30 Jul 2026 17:37:02 +0200</pubDate>
    </item>
  </channel>
</rss>`)

	items, err := parseFeedItems(data, feedSource{Author: "Golem.de", DefaultTags: []string{"Golem", "Tech"}})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}
	if items[0].ImageURL != "https://www.golem.de/2607/211464-590635_rc.jpg" {
		t.Fatalf("ImageURL = %q, want article image", items[0].ImageURL)
	}
}

func TestParseFeedItemsReadsAtomContentImage(t *testing.T) {

	data := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <title type="html"><![CDATA[Speicherkrise verschärft sich]]></title>
    <link href="https://www.heise.de/news/Speicherkrise-11387501.html"/>
    <published>2026-07-30T18:00:00+02:00</published>
    <summary type="html"><![CDATA[Speicher könnte nächstes Jahr teurer werden.]]></summary>
    <content type="html"><![CDATA[<p><a href="https://www.heise.de/news/Speicherkrise-11387501.html"><img src="https://www.heise.de/scale/geometry/450/q80//imgs/18/5/RAM-16-9.jpg"></a></p>]]></content>
  </entry>
</feed>`)

	items, err := parseFeedItems(data, feedSource{Author: "heise online", DefaultTags: []string{"heise", "Tech"}})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1", len(items))
	}
	if items[0].Title != "Speicherkrise verschärft sich" {
		t.Fatalf("Title = %q", items[0].Title)
	}
	if items[0].Content != "Speicher könnte nächstes Jahr teurer werden." {
		t.Fatalf("Content = %q", items[0].Content)
	}
	if items[0].ImageURL != "https://www.heise.de/scale/geometry/450/q80//imgs/18/5/RAM-16-9.jpg" {
		t.Fatalf("ImageURL = %q", items[0].ImageURL)
	}
	if items[0].URL != "https://www.heise.de/news/Speicherkrise-11387501.html" {
		t.Fatalf("URL = %q", items[0].URL)
	}
}

func TestParseFeedItemsSkipsSponsoredEntries(t *testing.T) {
	data := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Anzeige: Powerbank zum Bestpreis bei Amazon</title>
      <link>https://www.golem.de/news/anzeige-powerbank-2607-211461.html</link>
      <description>Affiliate-Deal</description>
      <pubDate>Thu, 30 Jul 2026 17:23:02 +0200</pubDate>
    </item>
    <item>
      <title>Rechenzentrum: Betreiber meldet Ausfall</title>
      <link>https://www.golem.de/news/rechenzentrum-2607-211462.html</link>
      <description>Meldung</description>
      <pubDate>Thu, 30 Jul 2026 17:37:02 +0200</pubDate>
    </item>
  </channel>
</rss>`)

	items, err := parseFeedItems(data, feedSource{Author: "Golem.de", DefaultTags: []string{"Golem", "Tech"}})
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("len(items) = %d, want 1 (Anzeige gefiltert)", len(items))
	}
	if items[0].Title != "Rechenzentrum: Betreiber meldet Ausfall" {
		t.Fatalf("Title = %q", items[0].Title)
	}
}

func TestClassifyCategoryUnderstandsGermanHeadlines(t *testing.T) {
	cases := []struct {
		name    string
		title   string
		content string
		author  string
		tags    []string
		want    string
	}{
		{
			name:    "hardware",
			title:   "Neue Grafikkarte mit mehr Arbeitsspeicher",
			content: "Der Hersteller nennt Preise und Termine.",
			author:  "Golem.de",
			tags:    []string{"Golem", "Tech"},
			want:    "Hardware",
		},
		{
			name:    "research",
			title:   "Studie zu Sprachmodellen",
			content: "Die Forscher werteten Millionen Antworten aus.",
			author:  "heise online",
			tags:    []string{"heise", "Tech"},
			want:    "Research",
		},
		{
			name:    "open source",
			title:   "Quelloffene Alternative erschienen",
			content: "Das Projekt steht unter freier Lizenz bereit.",
			author:  "heise online",
			tags:    []string{"heise", "Tech"},
			want:    "Open Source",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := classifyCategory(tc.title, tc.content, tc.author, tc.tags); got != tc.want {
				t.Fatalf("classifyCategory() = %q, want %q", got, tc.want)
			}
		})
	}
}

func TestSourceCategoryBeatsKeywordGuessing(t *testing.T) {

	data := []byte(`<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Angriff auf Rechenzentren</title>
      <link>https://www.golem.de/news/angriff-2607-1.html</link>
      <description>Forscher fanden eine Luecke in einer Open-Source-Bibliothek auf Nvidia-Servern.</description>
      <pubDate>Thu, 30 Jul 2026 18:00:02 +0200</pubDate>
    </item>
  </channel>
</rss>`)

	source := feedSource{
		Author:      "Golem.de",
		DefaultTags: []string{"Golem", "Security"},
		Category:    categorySecurity,
	}
	items, err := parseFeedItems(data, source)
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if items[0].Category != categorySecurity {
		t.Fatalf("Category = %q, want %q", items[0].Category, categorySecurity)
	}

	source.Category = ""
	items, err = parseFeedItems(data, source)
	if err != nil {
		t.Fatalf("parseFeedItems() error = %v", err)
	}
	if items[0].Category == categorySecurity {
		t.Fatal("ohne Category der Quelle sollte die Stichwortsuche greifen")
	}
}

func TestEveryTopicSourceCarriesAKnownCategory(t *testing.T) {
	known := map[string]bool{
		categoryReleases:   true,
		categoryHardware:   true,
		categorySoftware:   true,
		categorySecurity:   true,
		categoryOpenSource: true,
		categoryResearch:   true,
	}

	seen := map[string]bool{}
	for _, source := range liveFeedSources {
		if source.Category == "" {
			continue
		}
		if !known[source.Category] {
			t.Fatalf("Quelle %s nutzt die unbekannte Kategorie %q", source.URL, source.Category)
		}
		seen[source.Category] = true
	}

	for _, category := range []string{categorySecurity, categorySoftware, categoryHardware, categoryOpenSource, categoryResearch, categoryReleases} {
		if !seen[category] {
			t.Fatalf("keine Quelle liefert die Kategorie %q", category)
		}
	}
}

func TestClassifyCategoryMatchesWholeWordsOnly(t *testing.T) {

	cases := []struct {
		name    string
		title   string
		content string
		notWant string
	}{
		{
			name:    "intelligence ist kein Intel",
			title:   "How GPT-5.6 fuses frontier intelligence with frontier efficiency",
			content: "A look at the tradeoffs.",
			notWant: categoryHardware,
		},
		{
			name:    "scorecard ist keine Karte",
			title:   "A scorecard for the AI age",
			content: "How we measure progress.",
			notWant: categoryHardware,
		},
		{
			name:    "cpc ist kein pc",
			title:   "New ways to buy ChatGPT ads",
			content: "Advertisers can bid on cpc campaigns.",
			notWant: categoryHardware,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := classifyCategory(tc.title, tc.content, "OpenAI News", []string{"OpenAI", "AI"})
			if got == tc.notWant {
				t.Fatalf("classifyCategory() = %q, want etwas anderes", got)
			}
		})
	}

	if got := classifyCategory("Techniques for training on GPUs", "", "OpenAI News", nil); got != categoryHardware {
		t.Fatalf("classifyCategory(GPUs) = %q, want %q", got, categoryHardware)
	}
	if got := classifyCategory("Nvidia ships new silicon", "", "OpenAI News", nil); got != categoryHardware {
		t.Fatalf("classifyCategory(Nvidia) = %q, want %q", got, categoryHardware)
	}
}

func TestClassifyCategoryKnowsSecurityAndSoftware(t *testing.T) {
	if got := classifyCategory("Ransomware legt Klinik lahm", "Die Angreifer nutzten eine Schwachstelle.", "heise online", nil); got != categorySecurity {
		t.Fatalf("classifyCategory(Ransomware) = %q, want %q", got, categorySecurity)
	}
	if got := classifyCategory("Neues SDK für Kubernetes", "Der Compiler bekommt ein Update.", "heise online", nil); got != categorySoftware {
		t.Fatalf("classifyCategory(SDK) = %q, want %q", got, categorySoftware)
	}
}

func TestLiveFeedSourcesAreWellFormed(t *testing.T) {
	seenURL := map[string]bool{}
	seenAuthor := map[string]bool{}

	for _, source := range liveFeedSources {
		if strings.TrimSpace(source.Author) == "" {
			t.Fatalf("Quelle %q hat keinen Author", source.URL)
		}
		parsed, err := url.Parse(source.URL)
		if err != nil || parsed.Scheme != "https" || parsed.Host == "" {
			t.Fatalf("Quelle %s hat keine absolute HTTPS-URL: %q", source.Author, source.URL)
		}

		if seenURL[source.URL] {
			t.Fatalf("Feed-URL doppelt eingetragen: %s", source.URL)
		}
		seenURL[source.URL] = true
		seenAuthor[source.Author] = true
		if len(source.DefaultTags) == 0 {
			t.Fatalf("Quelle %s hat keine DefaultTags", source.Author)
		}
		if source.Disabled && strings.TrimSpace(source.DisableReason) == "" {
			t.Fatalf("Deaktivierte Quelle %s nennt keinen Grund", source.Author)
		}
	}

	for _, author := range []string{"VentureBeat", "Tom's Hardware", "Golem.de", "heise online"} {
		if !seenAuthor[author] {
			t.Fatalf("Quelle %s fehlt in liveFeedSources", author)
		}
	}
}

func TestGolemUsesTopicFeedsInsteadOfTheFullFeed(t *testing.T) {
	sources := golemTopicSources()
	if len(sources) != len(golemTopics) {
		t.Fatalf("len(sources) = %d, want %d", len(sources), len(golemTopics))
	}

	for _, source := range liveFeedSources {
		if strings.Contains(source.URL, "golem.de") && !strings.Contains(source.URL, "?ms=") {
			t.Fatalf("Golem-Gesamtfeed ist wieder eingetragen: %s", source.URL)
		}
	}

	if sources[0].URL != "https://rss.golem.de/rss.php?ms=ki" {
		t.Fatalf("erste Golem-Quelle = %q, want den KI-Themenfeed", sources[0].URL)
	}
	if sources[0].Author != "Golem.de" {
		t.Fatalf("Author = %q", sources[0].Author)
	}
}

func TestHeiseUsesSectionFeedsInsteadOfTheFullNewsticker(t *testing.T) {
	sources := heiseSectionSources()
	if len(sources) != len(heiseSections) {
		t.Fatalf("len(sources) = %d, want %d", len(sources), len(heiseSections))
	}

	for _, source := range liveFeedSources {
		if strings.Contains(source.URL, "heise.de/rss/heise-atom.xml") {
			t.Fatalf("heise-Gesamtfeed ist wieder eingetragen: %s", source.URL)
		}
	}

	wanted := map[string]bool{"KI": false, "Hardware": false, "Developer": false, "Security": false}
	for _, source := range sources {
		if source.Author != "heise online" {
			t.Fatalf("Author = %q", source.Author)
		}
		if len(source.DefaultTags) != 2 {
			t.Fatalf("DefaultTags = %v, want Quelle und Fachgebiet", source.DefaultTags)
		}
		if _, tracked := wanted[source.DefaultTags[1]]; tracked {
			wanted[source.DefaultTags[1]] = true
		}
	}
	for tag, found := range wanted {
		if !found {
			t.Fatalf("heise-Fachgebiet %q fehlt", tag)
		}
	}
}

func TestDedupeByIDKeepsTheFirstOccurrence(t *testing.T) {
	items := []NewsItem{
		{ID: "golem-a", Title: "Aus dem KI-Feed", Tags: []string{"Golem", "KI"}},
		{ID: "golem-b", Title: "Nur im Security-Feed"},
		{ID: "golem-a", Title: "Derselbe Beitrag aus dem Security-Feed", Tags: []string{"Golem", "Security"}},
	}

	unique := dedupeByID(items)
	if len(unique) != 2 {
		t.Fatalf("len(unique) = %d, want 2", len(unique))
	}
	if unique[0].Title != "Aus dem KI-Feed" {
		t.Fatalf("Titel = %q, want den Treffer aus dem ersten Themenfeed", unique[0].Title)
	}
	if unique[1].ID != "golem-b" {
		t.Fatalf("zweiter Eintrag = %q", unique[1].ID)
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

	items, err := parseFeedItems(data, feedSource{Author: "Test Feed", DefaultTags: []string{"AI"}})
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
	module := New(filepath.Join(t.TempDir(), "news_saved.json"))
	for _, item := range module.items {
		if strings.Contains(item.ImageURL, "picsum.photos") {
			t.Fatalf("fallback item %q still uses placeholder image %q", item.ID, item.ImageURL)
		}
	}
}
