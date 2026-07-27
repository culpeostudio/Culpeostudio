package philosearch

// searchRequest ist das Request-Modell fuer alle /api/search/* Routen.
//
// Felder entsprechen der Python-API von ddgs:
//   - Query: Pflichtfeld, Suchanfrage
//   - Region: z.B. "us-en", "uk-en", "de-de"
//   - Safesearch: "on" | "moderate" | "off"
//   - Timelimit: "d" | "w" | "m" | "y"
//   - Page: Seitennummer (1-basiert)
//   - MaxResults: maximale Trefferzahl
//   - Backend: kommaseparierte Engine-Liste, "auto" oder "all"
type searchRequest struct {
	Query      string `json:"query"`
	Region     string `json:"region"`
	Safesearch string `json:"safesearch"`
	Timelimit  string `json:"timelimit"`
	Page       int    `json:"page"`
	MaxResults int    `json:"max_results"`
	Backend    string `json:"backend"`
}

// extractRequest ist das Request-Modell fuer /api/search/extract.
type extractRequest struct {
	URL    string `json:"url"`
	Format string `json:"format"` // text_markdown | text_plain | text_rich | text | content
}
