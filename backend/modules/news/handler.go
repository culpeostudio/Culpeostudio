package news

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"html"
	"io"
	"log"
	"net/http"
	"net/url"
	"path"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode"

	"github.com/gofiber/fiber/v2"
)

// NewsItem repräsentiert einen einzelnen News-Eintrag aus externen Quellen.
type NewsItem struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Content     string    `json:"content"`
	Author      string    `json:"author"` // Repräsentiert die Quelle (z.B. "The Verge AI")
	PublishedAt time.Time `json:"published_at"`
	Tags        []string  `json:"tags,omitempty"`
	ImageURL    string    `json:"image_url,omitempty"`
	URL         string    `json:"url"`      // Link zum Originalartikel
	Category    string    `json:"category"` // KI-Releases, Hardware, Open Source, Research
}

// NewsModule verwaltet die externen News-Beiträge thread-safe im Cache.
type NewsModule struct {
	mu              sync.RWMutex
	items           []NewsItem
	refresherMu     sync.Mutex
	refresherStop   chan struct{}
	refresherDone   chan struct{}
	refresherActive bool
}

type feedSource struct {
	URL           string
	Author        string
	DefaultTags   []string
	Disabled      bool
	DisableReason string
}

type feedDocument struct {
	XMLName xml.Name    `xml:""`
	Channel rssChannel  `xml:"channel"`
	Entries []atomEntry `xml:"entry"`
}

type rssChannel struct {
	Items []rssItem `xml:"item"`
}

type rssItem struct {
	Title           string         `xml:"title"`
	Link            string         `xml:"link"`
	Description     string         `xml:"description"`
	Content         string         `xml:"encoded"`
	PubDate         string         `xml:"pubDate"`
	MediaContents   []rssMedia     `xml:"content"`
	MediaThumbnails []rssMedia     `xml:"thumbnail"`
	Enclosures      []rssEnclosure `xml:"enclosure"`
}

type atomEntry struct {
	Title     string     `xml:"title"`
	Summary   atomText   `xml:"summary"`
	Content   atomText   `xml:"content"`
	Updated   string     `xml:"updated"`
	Published string     `xml:"published"`
	Links     []atomLink `xml:"link"`
}

type atomText struct {
	Value string `xml:",innerxml"`
}

type atomLink struct {
	Rel  string `xml:"rel,attr"`
	Href string `xml:"href,attr"`
	Type string `xml:"type,attr"`
}

type rssMedia struct {
	URL    string `xml:"url,attr"`
	Medium string `xml:"medium,attr"`
	Type   string `xml:"type,attr"`
}

type rssEnclosure struct {
	URL  string `xml:"url,attr"`
	Type string `xml:"type,attr"`
}

var liveFeedSources = []feedSource{
	{
		URL:         "https://openai.com/news/rss.xml",
		Author:      "OpenAI News",
		DefaultTags: []string{"OpenAI", "AI"},
	},
	{
		URL:         "https://huggingface.co/blog/feed.xml",
		Author:      "Hugging Face Blog",
		DefaultTags: []string{"Hugging Face", "ML"},
	},
	{
		URL:         "https://www.marktechpost.com/feed/",
		Author:      "MarkTechPost",
		DefaultTags: []string{"MarkTechPost", "Research"},
	},
	{
		URL:         "https://www.tomshardware.com/feeds/all",
		Author:      "Tom's Hardware",
		DefaultTags: []string{"Hardware", "Tech"},
	},
	{
		URL:           "https://videocardz.com/feed",
		Author:        "VideoCardz",
		DefaultTags:   []string{"Hardware", "GPU"},
		Disabled:      true,
		DisableReason: "Feed liefert derzeit HTTP 403 und ist vorläufig deaktiviert.",
	},
	{
		URL:         "https://www.theverge.com/rss/ai-artificial-intelligence/index.xml",
		Author:      "The Verge AI",
		DefaultTags: []string{"The Verge", "AI"},
	},
}

// New erzeugt eine neue Instanz des NewsModule mit Fallback-Daten.
func New() *NewsModule {
	m := &NewsModule{
		items: []NewsItem{
			{
				ID:          "news-hacker-news-01",
				Title:       "Show HN: FillyEngine – Local AI Orchestration in Go",
				Content:     "FillyEngine is an open-source framework written in Go designed to run, quantize, and serve language and image diffusion models locally with minimal overhead. It provides clean gRPC and REST interfaces.",
				Author:      "Hacker News",
				PublishedAt: time.Now().Add(-2 * time.Hour),
				Tags:        []string{"Show HN", "Go", "AI", "OpenSource"},
				URL:         "https://news.ycombinator.com",
				Category:    "Open Source",
			},
			{
				ID:          "news-marktechpost-01",
				Title:       "Meet Llama 3.1: Meta’s Open Source Model Rivals Closed Models",
				Content:     "Meta has officially released Llama 3.1, featuring a 405B parameter flagship model, improved multilingual translation, longer context windows (128K), and state-of-the-art performance across key benchmarks.",
				Author:      "MarkTechPost",
				PublishedAt: time.Now().Add(-6 * time.Hour),
				Tags:        []string{"Meta", "Llama", "LLM"},
				URL:         "https://www.marktechpost.com",
				Category:    "Research",
			},
			{
				ID:          "news-huggingface-01",
				Title:       "Introducing SafeTensors: A new format for storing tensors safely",
				Content:     "We are excited to share SafeTensors, a new format for storing weights that is secure, fast (zero-copy), and supports multiple frameworks. It prevents arbitrary code execution vulnerabilities commonly found in pickle.",
				Author:      "Hugging Face Blog",
				PublishedAt: time.Now().Add(-18 * time.Hour),
				Tags:        []string{"Tensors", "Security", "ML"},
				URL:         "https://huggingface.co/blog",
				Category:    "Open Source",
			},
			{
				ID:          "news-openai-01",
				Title:       "GPT-4o: Reasoning across audio, vision, and text in real-time",
				Content:     "GPT-4o ('o' for omni) is a step towards much more natural human-computer interaction. It accepts as input any combination of text, audio, and image and generates any combination of text, audio, and image outputs.",
				Author:      "OpenAI News",
				PublishedAt: time.Now().Add(-30 * time.Hour),
				Tags:        []string{"GPT-4o", "Multimodal", "Announcements"},
				URL:         "https://openai.com/news",
				Category:    "KI-Releases",
			},
		},
	}
	return m
}

// Name gibt den Namen des Moduls zurück.
func (m *NewsModule) Name() string {
	return "news"
}

// RegisterRoutes registriert alle Routen des News-Moduls unter dem API-Router.
func (m *NewsModule) RegisterRoutes(r fiber.Router) {
	g := r.Group("/news")
	g.Get("/", m.handleGetAll)
	g.Get("/:id", m.handleGetByID)
}

// Initialize wird beim Modulstart aufgerufen.
func (m *NewsModule) Initialize() error {
	m.startRefresher()
	return nil
}

// Shutdown wird beim Stoppen des Servers aufgerufen.
func (m *NewsModule) Shutdown() error {
	m.refresherMu.Lock()
	if !m.refresherActive {
		m.refresherMu.Unlock()
		return nil
	}
	stop := m.refresherStop
	done := m.refresherDone
	m.refresherActive = false
	m.refresherStop = nil
	m.refresherDone = nil
	m.refresherMu.Unlock()

	close(stop)
	<-done
	return nil
}

func (m *NewsModule) handleGetAll(c *fiber.Ctx) error {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return c.JSON(m.items)
}

func (m *NewsModule) handleGetByID(c *fiber.Ctx) error {
	id := c.Params("id")
	m.mu.RLock()
	defer m.mu.RUnlock()
	for _, item := range m.items {
		if item.ID == id {
			return c.JSON(item)
		}
	}
	return c.Status(404).JSON(fiber.Map{"error": "News-Eintrag nicht gefunden"})
}

func (m *NewsModule) startRefresher() {
	m.refresherMu.Lock()
	if m.refresherActive {
		m.refresherMu.Unlock()
		return
	}
	stop := make(chan struct{})
	done := make(chan struct{})
	m.refresherStop = stop
	m.refresherDone = done
	m.refresherActive = true
	m.refresherMu.Unlock()

	logDisabledFeedSources(liveFeedSources)

	go func() {
		defer close(done)
		log.Println("[NEWS] Starte Live-Feeds Refresher Goroutine...")
		// Erster Refresh beim Serverstart
		m.refreshFeeds()

		ticker := time.NewTicker(15 * time.Minute)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				m.refreshFeeds()
			case <-stop:
				return
			}
		}
	}()
}

func (m *NewsModule) refreshFeeds() {
	var newItems []NewsItem
	client := &http.Client{Timeout: 8 * time.Second}

	// 1. Fetch Hacker News (Algolia API: Filter auf >= 100 Punkte)
	hnItems := fetchHackerNews(client)
	newItems = append(newItems, hnItems...)
	newItems = append(newItems, collectFeedItems(client, liveFeedSources)...)

	if len(newItems) > 0 {
		// Sortieren nach Datum (neuste zuerst)
		sort.Slice(newItems, func(i, j int) bool {
			return newItems[i].PublishedAt.After(newItems[j].PublishedAt)
		})

		m.mu.Lock()
		m.items = newItems
		m.mu.Unlock()
		log.Printf("[NEWS] Live-Feeds erfolgreich aktualisiert. Gesamtbeiträge: %d", len(newItems))
	} else {
		log.Println("[NEWS] Warnung: Live-Feeds Aktualisierung lieferte 0 Beiträge. Behalte bestehende Cache-Daten.")
	}
}

// Structs für Algolia Hacker News API
type AlgoliaResponse struct {
	Hits []struct {
		ObjectID  string `json:"objectID"`
		Title     string `json:"title"`
		URL       string `json:"url"`
		Author    string `json:"author"`
		CreatedAt string `json:"created_at"`
		StoryText string `json:"story_text"`
		Points    int    `json:"points"`
	} `json:"hits"`
}

func fetchHackerNews(client *http.Client) []NewsItem {
	var items []NewsItem
	// Hole die neuesten Stories mit >= 100 Punkten
	query := url.Values{}
	query.Set("tags", "story")
	query.Set("numericFilters", "points>=100")
	resp, err := client.Get("https://hn.algolia.com/api/v1/search_by_date?" + query.Encode())
	if err != nil {
		log.Printf("[NEWS] Fehler beim Laden von Hacker News API: %v", err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Printf("[NEWS] HN API Statusfehler: %d", resp.StatusCode)
		return nil
	}

	var data AlgoliaResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		log.Printf("[NEWS] HN JSON Decoding Fehler: %v", err)
		return nil
	}

	for _, hit := range data.Hits {
		// HN stories points >= 100 filter (schon über API-Filter abgedeckt, hier als doppelte Absicherung)
		if hit.Points < 100 {
			continue
		}

		pubTime := parsePublishedAt(hit.CreatedAt, "Hacker News")
		content := hit.StoryText
		if content == "" {
			content = fmt.Sprintf("Top-Story auf Hacker News von %s mit %d Punkten. Diskutiere den Artikel direkt im Web-Interface über den HN-Link.", hit.Author, hit.Points)
		} else {
			content = stripHTML(content)
		}

		link := hit.URL
		if link == "" {
			link = fmt.Sprintf("https://news.ycombinator.com/item?id=%s", hit.ObjectID)
		}

		tags := []string{"HN", "Tech"}
		category := classifyCategory(hit.Title, content, "Hacker News", tags)

		items = append(items, NewsItem{
			ID:          "hn-" + hit.ObjectID,
			Title:       hit.Title,
			Content:     content,
			Author:      "Hacker News",
			PublishedAt: pubTime,
			Tags:        tags,
			URL:         link,
			Category:    category,
		})
	}
	return items
}

func collectFeedItems(client *http.Client, sources []feedSource) []NewsItem {
	var items []NewsItem
	for _, source := range sources {
		if source.Disabled {
			continue
		}
		items = append(items, fetchFeed(client, source)...)
	}
	return items
}

func fetchFeed(client *http.Client, source feedSource) []NewsItem {
	req, err := http.NewRequest("GET", source.URL, nil)
	if err != nil {
		log.Printf("[NEWS] Konnte Request für %s nicht erstellen: %v", source.Author, err)
		return nil
	}

	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("[NEWS] Feed Ladefehler für %s: %v", source.Author, err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Printf("[NEWS] Feed Statusfehler für %s: %d", source.Author, resp.StatusCode)
		return nil
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("[NEWS] Feed Lese-Fehler für %s: %v", source.Author, err)
		return nil
	}

	items, err := parseFeedItems(data, source.Author, source.DefaultTags)
	if err != nil {
		log.Printf("[NEWS] Feed Parsing Fehler für %s: %v", source.Author, err)
		return nil
	}

	return items
}

func parseFeedItems(data []byte, author string, defaultTags []string) ([]NewsItem, error) {
	var feed feedDocument
	if err := xml.Unmarshal(data, &feed); err != nil {
		return nil, err
	}

	switch strings.ToLower(feed.XMLName.Local) {
	case "rss":
		return mapRSSItems(feed.Channel.Items, author, defaultTags), nil
	case "feed":
		return mapAtomEntries(feed.Entries, author, defaultTags), nil
	default:
		return nil, fmt.Errorf("unerwarteter Feed-Typ <%s>", feed.XMLName.Local)
	}
}

func mapRSSItems(rssItems []rssItem, author string, defaultTags []string) []NewsItem {
	var items []NewsItem
	for _, item := range rssItems {
		content := firstNonEmpty(item.Description, item.Content)
		items = append(items, newFeedNewsItem(
			author,
			defaultTags,
			item.Title,
			content,
			item.Link,
			extractImageURLFromRSSItem(item),
			parsePublishedAt(item.PubDate, author),
		))
	}
	return items
}

func mapAtomEntries(entries []atomEntry, author string, defaultTags []string) []NewsItem {
	var items []NewsItem
	for _, entry := range entries {
		content := firstNonEmpty(entry.Summary.Value, entry.Content.Value)
		publishedAt := parsePublishedAt(firstNonEmpty(entry.Updated, entry.Published), author)
		items = append(items, newFeedNewsItem(
			author,
			defaultTags,
			entry.Title,
			content,
			pickAtomLink(entry.Links),
			extractImageURLFromAtomEntry(entry),
			publishedAt,
		))
	}
	return items
}

func newFeedNewsItem(author string, defaultTags []string, title string, rawContent string, link string, imageURL string, publishedAt time.Time) NewsItem {
	title = strings.TrimSpace(stripHTML(title))
	content := trimPreviewContent(rawContent)
	category := classifyCategory(title, content, author, defaultTags)

	return NewsItem{
		ID:          buildNewsItemID(author, link),
		Title:       title,
		Content:     content,
		Author:      author,
		PublishedAt: publishedAt,
		Tags:        defaultTags,
		ImageURL:    normalizeImageURL(imageURL),
		URL:         strings.TrimSpace(link),
		Category:    category,
	}
}

func buildNewsItemID(author string, link string) string {
	prefix := sanitizeIDPart(firstAuthorToken(author))
	if prefix == "" {
		prefix = "news"
	}
	fallbackKey := sanitizeIDPart(firstNonEmpty(strings.TrimSpace(link), author))
	if strings.TrimSpace(link) == "" {
		if fallbackKey == "" {
			return prefix
		}
		return fmt.Sprintf("%s-%s", prefix, fallbackKey)
	}

	parsed, err := url.Parse(strings.TrimSpace(link))
	if err != nil {
		if fallbackKey == "" {
			return prefix
		}
		return fmt.Sprintf("%s-%s", prefix, fallbackKey)
	}

	pathPart := sanitizeIDPart(strings.Trim(strings.TrimSpace(parsed.Path), "/"))
	if pathPart == "" {
		pathPart = sanitizeIDPart(path.Base(parsed.Path))
	}
	hostPart := sanitizeIDPart(parsed.Hostname())
	lastPart := firstNonEmpty(pathPart, hostPart)
	if hostPart != "" && pathPart != "" {
		lastPart = hostPart + "-" + pathPart
	}
	if lastPart == "" {
		if fallbackKey == "" {
			return prefix
		}
		return fmt.Sprintf("%s-%s", prefix, fallbackKey)
	}

	return fmt.Sprintf("%s-%s", prefix, lastPart)
}

func trimPreviewContent(content string) string {
	plain := strings.TrimSpace(stripHTML(content))
	if len(plain) > 300 {
		plain = plain[:297] + "..."
	}
	if plain == "" {
		return "Keine Vorschau verfügbar. Bitte besuche den Originalartikel über den Link."
	}
	return plain
}

func pickAtomLink(links []atomLink) string {
	var fallback string
	for _, link := range links {
		href := strings.TrimSpace(link.Href)
		if href == "" {
			continue
		}
		if fallback == "" {
			fallback = href
		}
		rel := strings.TrimSpace(link.Rel)
		if rel == "" || rel == "alternate" {
			return href
		}
	}
	return fallback
}

func extractImageURLFromRSSItem(item rssItem) string {
	for _, media := range item.MediaContents {
		if isImageCandidate(media.Medium, media.Type, media.URL) {
			return media.URL
		}
	}
	for _, media := range item.MediaThumbnails {
		if normalized := normalizeImageURL(media.URL); normalized != "" {
			return normalized
		}
	}
	for _, enclosure := range item.Enclosures {
		if isImageCandidate("", enclosure.Type, enclosure.URL) {
			return enclosure.URL
		}
	}
	return extractImageURLFromHTML(firstNonEmpty(item.Content, item.Description))
}

func extractImageURLFromAtomEntry(entry atomEntry) string {
	for _, link := range entry.Links {
		linkType := strings.ToLower(strings.TrimSpace(link.Type))
		rel := strings.ToLower(strings.TrimSpace(link.Rel))
		if strings.HasPrefix(linkType, "image/") {
			return normalizeImageURL(link.Href)
		}
		if rel == "enclosure" && isImageCandidate("", linkType, link.Href) {
			return link.Href
		}
	}
	return extractImageURLFromHTML(firstNonEmpty(entry.Content.Value, entry.Summary.Value))
}

func isImageCandidate(medium string, contentType string, candidateURL string) bool {
	normalized := normalizeImageURL(candidateURL)
	if normalized == "" {
		return false
	}

	if strings.EqualFold(strings.TrimSpace(medium), "image") {
		return true
	}

	contentType = strings.ToLower(strings.TrimSpace(contentType))
	return contentType == "" || strings.HasPrefix(contentType, "image/")
}

func extractImageURLFromHTML(content string) string {
	unescaped := html.UnescapeString(content)
	matches := imageSrcPattern.FindAllStringSubmatch(unescaped, -1)
	var fallback string
	for _, match := range matches {
		if len(match) < 2 {
			continue
		}
		candidate := normalizeImageURL(match[1])
		if candidate == "" {
			continue
		}
		if fallback == "" {
			fallback = candidate
		}
		if !looksDecorativeImageURL(candidate) {
			return candidate
		}
	}
	return fallback
}

func normalizeImageURL(raw string) string {
	candidate := strings.TrimSpace(html.UnescapeString(raw))
	if candidate == "" {
		return ""
	}
	if strings.HasPrefix(candidate, "//") {
		candidate = "https:" + candidate
	}
	parsed, err := url.Parse(candidate)
	if err != nil {
		return ""
	}
	if parsed.Scheme != "http" && parsed.Scheme != "https" {
		return ""
	}
	if parsed.Host == "" {
		return ""
	}
	return parsed.String()
}

func sanitizeIDPart(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return ""
	}

	var builder strings.Builder
	lastDash := false
	for _, r := range value {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9':
			builder.WriteRune(r)
			lastDash = false
		case r == '-' || r == '_':
			if !lastDash {
				builder.WriteByte('-')
				lastDash = true
			}
		default:
			if !lastDash {
				builder.WriteByte('-')
				lastDash = true
			}
		}
	}

	return strings.Trim(builder.String(), "-")
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func firstAuthorToken(author string) string {
	fields := strings.Fields(strings.TrimSpace(author))
	if len(fields) == 0 {
		return ""
	}
	return fields[0]
}

func logDisabledFeedSources(sources []feedSource) {
	for _, source := range sources {
		if source.Disabled {
			log.Printf("[NEWS] Quelle %s deaktiviert: %s", source.Author, source.DisableReason)
		}
	}
}

func parsePublishedAt(pubDate string, source string) time.Time {
	layouts := []string{
		time.RFC1123,
		time.RFC1123Z,
		"Mon, 02 Jan 2006 15:04:05 MST",
		"Mon, 02 Jan 2006 15:04:05 -0700",
		time.RFC822,
		time.RFC822Z,
		"2006-01-02T15:04:05Z07:00",
		"2006-01-02T15:04:05-07:00",
		"Mon, 02 Jan 2006 15:04:05 MST",
	}
	t := strings.TrimSpace(pubDate)
	if t == "" {
		return time.Time{}
	}
	for _, layout := range layouts {
		if parsed, err := time.Parse(layout, t); err == nil {
			return parsed
		}
	}
	log.Printf("[NEWS] Konnte Veröffentlichungsdatum für %s nicht parsen: %q", source, t)
	return time.Time{}
}

func stripHTML(input string) string {
	res := stripHTMLTags(input)
	res = html.UnescapeString(res)
	if strings.Contains(res, "<") && strings.Contains(res, ">") {
		res = stripHTMLTags(res)
	}
	return strings.Join(strings.Fields(strings.TrimSpace(res)), " ")
}

var imageSrcPattern = regexp.MustCompile(`(?i)<img[^>]+src=["']([^"' >]+)["']`)

func stripHTMLTags(input string) string {
	var builder strings.Builder
	inTag := false
	lastWasSpace := false
	for _, r := range input {
		if r == '<' {
			if builder.Len() > 0 && !lastWasSpace {
				builder.WriteByte(' ')
				lastWasSpace = true
			}
			inTag = true
			continue
		}
		if r == '>' {
			inTag = false
			if builder.Len() > 0 && !lastWasSpace {
				builder.WriteByte(' ')
				lastWasSpace = true
			}
			continue
		}
		if !inTag {
			if unicode.IsSpace(r) {
				if builder.Len() > 0 && !lastWasSpace {
					builder.WriteByte(' ')
					lastWasSpace = true
				}
				continue
			}
			builder.WriteRune(r)
			lastWasSpace = false
		}
	}
	return builder.String()
}

func looksDecorativeImageURL(raw string) bool {
	normalized := strings.ToLower(strings.TrimSpace(raw))
	if normalized == "" {
		return true
	}

	decorativePatterns := []string{
		"/logo",
		"-logo",
		"_logo",
		"/icon",
		"-icon",
		"_icon",
		"/avatar",
		"-avatar",
		"_avatar",
		"/badge",
		"-badge",
		"_badge",
		"/sprite",
		"-sprite",
		"_sprite",
		"/pixel",
		"-pixel",
		"_pixel",
		"/label",
		"-label",
		"_label",
		"/disclosure",
		"-disclosure",
		"_disclosure",
		"/favicon",
	}
	for _, pattern := range decorativePatterns {
		if strings.Contains(normalized, pattern) {
			return true
		}
	}
	return false
}

func classifyCategory(title, content, author string, tags []string) string {
	t := strings.ToLower(title)
	c := strings.ToLower(content)
	auth := strings.ToLower(author)

	var lTags []string
	for _, tag := range tags {
		lTags = append(lTags, strings.ToLower(tag))
	}

	hasTag := func(k string) bool {
		for _, tag := range lTags {
			if strings.Contains(tag, k) {
				return true
			}
		}
		return false
	}

	// 1. Hardware
	if strings.Contains(auth, "hardware") || strings.Contains(auth, "videocardz") {
		return "Hardware"
	}
	hardwareKeywords := []string{"nvidia", "amd", "intel", "gpu", "cpu", "rtx", "motherboard", "chip", "processor", "hardware", "card", "geforce", "radeon", "ryzen", "pcie", "socket", "laptop", "desktop", "pc", "console"}
	for _, kw := range hardwareKeywords {
		if strings.Contains(t, kw) || strings.Contains(c, kw) || hasTag(kw) {
			return "Hardware"
		}
	}

	// 2. Open Source
	openSourceKeywords := []string{"open-source", "open source", "github", "open weights", "open weight", "openweight", "apache", "mit license", "gpl", "weights release", "hugging face", "huggingface"}
	for _, kw := range openSourceKeywords {
		if strings.Contains(t, kw) || strings.Contains(c, kw) || hasTag(kw) || hasTag("opensource") {
			return "Open Source"
		}
	}

	// 3. Research
	researchKeywords := []string{"paper", "research", "study", "researchers", "scientist", "arxiv", "benchmark", "novel", "method", "dataset", "evaluation", "framework", "marktechpost"}
	for _, kw := range researchKeywords {
		if strings.Contains(t, kw) || strings.Contains(c, kw) || hasTag(kw) {
			return "Research"
		}
	}

	// 4. KI-Releases
	releaseKeywords := []string{"release", "launch", "version", "introduce", "introducing", "announced", "announce", "beta", "public", "gpt-4o", "llama 3", "claude 3", "gemini 1.5", "mistral large"}
	for _, kw := range releaseKeywords {
		if strings.Contains(t, kw) || strings.Contains(c, kw) || hasTag(kw) {
			return "KI-Releases"
		}
	}

	// Fallbacks
	if strings.Contains(auth, "openai") || strings.Contains(auth, "the verge") {
		return "KI-Releases"
	}
	if strings.Contains(auth, "hugging face") {
		return "Open Source"
	}
	if strings.Contains(auth, "marktechpost") {
		return "Research"
	}

	return "KI-Releases" // Fallback Default
}
