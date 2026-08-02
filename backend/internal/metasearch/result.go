package metasearch

import (
	"sort"
	"strings"
)

type Result struct {
	Category string `json:"-"`

	Title string `json:"title,omitempty"`
	Href  string `json:"href,omitempty"`
	Body  string `json:"body,omitempty"`

	Image     string `json:"image,omitempty"`
	Thumbnail string `json:"thumbnail,omitempty"`
	URL       string `json:"url,omitempty"`
	Height    string `json:"height,omitempty"`
	Width     string `json:"width,omitempty"`
	Source    string `json:"source,omitempty"`

	Date string `json:"date,omitempty"`

	Content     string `json:"content,omitempty"`
	Description string `json:"description,omitempty"`
	Duration    string `json:"duration,omitempty"`
	EmbedHTML   string `json:"embed_html,omitempty"`
	EmbedURL    string `json:"embed_url,omitempty"`
	ImageToken  string `json:"image_token,omitempty"`
	Provider    string `json:"provider,omitempty"`
	Published   string `json:"published,omitempty"`
	Publisher   string `json:"publisher,omitempty"`
	Uploader    string `json:"uploader,omitempty"`

	Author string `json:"author,omitempty"`
	Info   string `json:"info,omitempty"`
}

func (r *Result) Set(field, value string) {
	if value == "" {
		return
	}
	switch field {
	case "title", "body", "author", "publisher", "uploader", "info":
		r.setField(field, NormalizeText(value))
	case "href", "url", "thumbnail", "image", "embed_url":
		r.setField(field, NormalizeURL(value))
	case "date":
		r.setField(field, value)
	default:
		r.setField(field, value)
	}
}

func (r *Result) setField(field, value string) {
	switch field {
	case "title":
		r.Title = value
	case "body":
		r.Body = value
	case "href":
		r.Href = value
	case "image":
		r.Image = value
	case "thumbnail":
		r.Thumbnail = value
	case "url":
		r.URL = value
	case "height":
		r.Height = value
	case "width":
		r.Width = value
	case "source":
		r.Source = value
	case "date":
		r.Date = value
	case "content":
		r.Content = value
	case "description":
		r.Description = value
	case "duration":
		r.Duration = value
	case "embed_html":
		r.EmbedHTML = value
	case "embed_url":
		r.EmbedURL = value
	case "image_token":
		r.ImageToken = value
	case "provider":
		r.Provider = value
	case "published":
		r.Published = value
	case "publisher":
		r.Publisher = value
	case "uploader":
		r.Uploader = value
	case "author":
		r.Author = value
	case "info":
		r.Info = value
	}
}

func (r *Result) Get(field string) string {
	switch field {
	case "title":
		return r.Title
	case "body":
		return r.Body
	case "href":
		return r.Href
	case "image":
		return r.Image
	case "thumbnail":
		return r.Thumbnail
	case "url":
		return r.URL
	case "height":
		return r.Height
	case "width":
		return r.Width
	case "source":
		return r.Source
	case "date":
		return r.Date
	case "content":
		return r.Content
	case "description":
		return r.Description
	case "duration":
		return r.Duration
	case "embed_html":
		return r.EmbedHTML
	case "embed_url":
		return r.EmbedURL
	case "image_token":
		return r.ImageToken
	case "provider":
		return r.Provider
	case "published":
		return r.Published
	case "publisher":
		return r.Publisher
	case "uploader":
		return r.Uploader
	case "author":
		return r.Author
	case "info":
		return r.Info
	}
	return ""
}

func (r *Result) CacheKey(cacheFields []string) (string, bool) {
	for _, f := range cacheFields {
		if v := r.Get(f); v != "" {
			return v, true
		}
	}
	return "", false
}

func (r *Result) ToMap() map[string]any {
	out := make(map[string]any, 24)
	add := func(key, value string) {
		if value != "" {
			out[key] = value
		}
	}
	add("title", r.Title)
	add("body", r.Body)
	add("href", r.Href)
	add("image", r.Image)
	add("thumbnail", r.Thumbnail)
	add("url", r.URL)
	add("height", r.Height)
	add("width", r.Width)
	add("source", r.Source)
	add("date", r.Date)
	add("content", r.Content)
	add("description", r.Description)
	add("duration", r.Duration)
	add("embed_html", r.EmbedHTML)
	add("embed_url", r.EmbedURL)
	add("image_token", r.ImageToken)
	add("provider", r.Provider)
	add("published", r.Published)
	add("publisher", r.Publisher)
	add("uploader", r.Uploader)
	add("author", r.Author)
	add("info", r.Info)
	return out
}

type ResultList []Result

func (l ResultList) SortByFrequency(counts map[string]int) {
	sort.SliceStable(l, func(i, j int) bool {
		ki := primaryCacheKey(&l[i])
		kj := primaryCacheKey(&l[j])
		if counts[ki] != counts[kj] {
			return counts[ki] > counts[kj]
		}
		return len(l[j].Body) < len(l[i].Body)
	})
}

func primaryCacheKey(r *Result) string {
	for _, f := range []string{"href", "image", "url", "embed_url"} {
		if v := r.Get(f); v != "" {
			return v
		}
	}
	if r.Title != "" {
		return r.Title
	}
	return ""
}

func DedupByCacheFields(results []Result, cacheFields []string) []Result {
	seen := make(map[string]struct{}, len(results))
	out := make([]Result, 0, len(results))
	for _, r := range results {
		key, ok := r.CacheKey(cacheFields)
		if !ok {
			out = append(out, r)
			continue
		}
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, r)
	}
	return out
}

func CleanupText(results []Result) []Result {
	out := make([]Result, 0, len(results))
	for _, r := range results {
		if strings.TrimSpace(r.Title) == "" || strings.TrimSpace(r.Href) == "" {
			continue
		}
		out = append(out, r)
	}
	return out
}
