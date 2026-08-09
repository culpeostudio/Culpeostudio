package benchmark

type Detail struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

type Entry struct {
	Board string `json:"board"`

	Key     string `json:"key"`
	Name    string `json:"name"`
	ModelID string `json:"model_id,omitempty"`
	Org     string `json:"org,omitempty"`
	License string `json:"license,omitempty"`
	URL     string `json:"url,omitempty"`

	Type        string `json:"type,omitempty"`
	OpenWeights bool   `json:"open_weights"`
	EvalDate    string `json:"eval_date,omitempty"`

	Primary float64            `json:"primary"`
	Scores  map[string]float64 `json:"scores"`

	Rank int `json:"rank"`

	Details []Detail `json:"details,omitempty"`
}

func (e Entry) ScoreOf(key string) float64 {
	if key == "" || key == primaryKey {
		return e.Primary
	}
	return e.Scores[key]
}

type MetricInfo struct {
	Key     string `json:"key"`
	Label   string `json:"label"`
	Family  string `json:"family"`
	Shots   string `json:"shots,omitempty"`
	Dataset string `json:"dataset,omitempty"`
	URL     string `json:"url,omitempty"`
}

type MetricStats struct {
	Key       string  `json:"key"`
	Min       float64 `json:"min"`
	Max       float64 `json:"max"`
	Mean      float64 `json:"mean"`
	Median    float64 `json:"median"`
	TopModel  string  `json:"top_model"`
	TopScore  float64 `json:"top_score"`
	Evaluated int     `json:"evaluated"`
}

type BoardInfo struct {
	Key   string `json:"key"`
	Label string `json:"label"`

	Kind string `json:"kind"`

	ScoreKind string `json:"score_kind"`

	PrimaryLabel string `json:"primary_label"`

	ScoreMax float64 `json:"score_max"`

	Metrics []MetricInfo `json:"metrics"`
	Source  SourceInfo   `json:"source"`
}

type SourceInfo struct {
	Provider string `json:"provider"`
	Dataset  string `json:"dataset"`
	URL      string `json:"url"`

	Live       bool   `json:"live"`
	Archived   bool   `json:"archived"`
	ArchivedAt string `json:"archived_at,omitempty"`

	PublishedAt string `json:"published_at,omitempty"`
	FetchedAt   string `json:"fetched_at,omitempty"`
	FromCache   bool   `json:"from_cache"`

	Entries int `json:"entries"`
	Models  int `json:"models"`

	State string `json:"state"`
	Error string `json:"error,omitempty"`
}

type HubStats struct {
	ModelID          string   `json:"model_id"`
	Likes            int      `json:"likes"`
	Downloads30d     int64    `json:"downloads_30d"`
	DownloadsAllTime int64    `json:"downloads_all_time"`
	TrendingScore    float64  `json:"trending_score"`
	LastModified     string   `json:"last_modified,omitempty"`
	PipelineTag      string   `json:"pipeline_tag,omitempty"`
	Gated            bool     `json:"gated"`
	ParamsTotal      int64    `json:"params_total,omitempty"`
	Tags             []string `json:"tags,omitempty"`
	Providers        []string `json:"inference_providers,omitempty"`
	Missing          bool     `json:"missing"`
}

type CardResult struct {
	Task    string  `json:"task,omitempty"`
	Dataset string  `json:"dataset,omitempty"`
	Metric  string  `json:"metric"`
	Value   float64 `json:"value"`
	Verifed bool    `json:"verified"`
}

type ModelDetail struct {
	Board       string           `json:"board"`
	ModelID     string           `json:"model_id"`
	Name        string           `json:"name"`
	Entries     []Entry          `json:"entries"`
	Best        *Entry           `json:"best,omitempty"`
	MetricRanks map[string]int   `json:"metric_ranks"`
	Percentile  float64          `json:"percentile"`
	Peers       []Entry          `json:"peers,omitempty"`
	Hub         *HubStats        `json:"hub,omitempty"`
	CardResults []CardResult     `json:"card_results,omitempty"`
	Deltas      map[string]Delta `json:"deltas,omitempty"`
	Metrics     []MetricInfo     `json:"metrics"`
	Source      SourceInfo       `json:"source"`
	Totals      map[string]int   `json:"totals,omitempty"`
	ScoreKind   string           `json:"score_kind"`
}

type Delta struct {
	Value  float64 `json:"value"`
	Median float64 `json:"median"`
	Diff   float64 `json:"diff"`
}

type Facets struct {
	Types    []FacetValue `json:"types"`
	Orgs     []FacetValue `json:"orgs"`
	Licenses []FacetValue `json:"licenses"`
}

type FacetValue struct {
	Value string `json:"value"`
	Label string `json:"label,omitempty"`
	Count int    `json:"count"`
}
