package philosearch

type searchRequest struct {
	Query      string `json:"query"`
	Region     string `json:"region"`
	Safesearch string `json:"safesearch"`
	Timelimit  string `json:"timelimit"`
	Page       int    `json:"page"`
	MaxResults int    `json:"max_results"`
	Backend    string `json:"backend"`
}

type extractRequest struct {
	URL    string `json:"url"`
	Format string `json:"format"`
}
