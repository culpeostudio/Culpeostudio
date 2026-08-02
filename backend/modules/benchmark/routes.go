package benchmark

import (
	"math"
	"sort"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

const (
	defaultLimit = 50
	maxLimit     = 200

	maxCompare = 12
)

func (m *Module) RegisterRoutes(r fiber.Router) {
	g := r.Group("/benchmark")
	g.Get("/boards", m.handleBoards)
	g.Get("/status", m.handleStatus)
	g.Get("/overview", m.handleOverview)
	g.Get("/leaderboard", m.handleLeaderboard)
	g.Get("/model", m.handleModel)
	g.Get("/compare", m.handleCompare)
	g.Post("/refresh", m.handleRefresh)
}

func boardParam(c *fiber.Ctx) string {
	key := strings.TrimSpace(c.Query("board"))
	if _, ok := knownBoard(key); ok {
		return key
	}
	return DefaultBoard
}

func (m *Module) handleBoards(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"boards":  m.allBoards(),
		"default": DefaultBoard,
	})
}

func (m *Module) handleStatus(c *fiber.Ctx) error {
	boardKey := boardParam(c)
	infos := m.allBoards()

	status := Status{Boards: infos, State: stateEmpty}
	for _, info := range infos {
		if info.Key == boardKey {
			status.Source = info.Source
			status.State = info.Source.State
			status.Error = info.Source.Error
		}
	}

	m.mu.RLock()
	if state, ok := m.state[boardKey]; ok {
		status.Loaded = state.loadedRows
		status.Expected = state.expected
	}
	m.mu.RUnlock()

	m.loadMu.Lock()
	status.Refreshing = m.loading[boardKey]
	m.loadMu.Unlock()

	return c.JSON(status)
}

func (m *Module) handleRefresh(c *fiber.Ctx) error {
	requested := strings.TrimSpace(c.Query("board"))
	keys := make([]string, 0, len(BoardOrder))
	if _, ok := knownBoard(requested); ok {
		keys = append(keys, requested)
	} else {
		keys = append(keys, BoardOrder...)
	}

	go m.refreshBoards(m.lifecycle, keys)
	return c.Status(fiber.StatusAccepted).JSON(fiber.Map{
		"started": true,
		"boards":  keys,
	})
}

func (m *Module) handleLeaderboard(c *fiber.Ctx) error {
	boardKey := boardParam(c)
	entries, info := m.snapshotState(boardKey)
	query := parseQuery(c, info.Metrics)

	matched := filter(entries, query)
	if query.BestPerModel {
		matched = keepBestPerModel(matched)
	}
	facets := buildFacets(matched)
	sortEntries(matched, query.Sort, query.Order)

	page := LeaderboardPage{
		Board:  info,
		Items:  paginate(matched, query.Offset, query.Limit),
		Total:  len(matched),
		Offset: query.Offset,
		Limit:  query.Limit,
		Sort:   query.Sort,
		Order:  query.Order,
		Facets: facets,
	}
	if info.Source.State != stateReady {
		page.Warning = info.Source.State
	}
	return c.JSON(page)
}

func (m *Module) handleOverview(c *fiber.Ctx) error {
	boardKey := boardParam(c)
	entries, info := m.snapshotState(boardKey)

	unique := keepBestPerModel(filter(entries, Query{}))
	sortEntries(unique, primaryKey, "desc")

	open := filter(unique, Query{OpenWeightsOnly: true})

	overview := Overview{
		Board:           info,
		Boards:          m.allBoards(),
		TotalEntries:    len(entries),
		TotalModels:     len(unique),
		MetricStats:     m.metricStats(boardKey),
		TopOverall:      headOf(unique, 10),
		TopByMetric:     topByMetric(unique, info.Metrics, 5),
		TopOpenWeights:  headOf(open, 10),
		TopOpenByMetric: topByMetric(open, info.Metrics, 5),
		TypeShare:       shareOf(unique, func(entry Entry) string { return entry.Type }),
		OrgShare:        shareOf(unique, func(entry Entry) string { return entry.Org }),
	}
	return c.JSON(overview)
}

func (m *Module) handleModel(c *fiber.Ctx) error {
	modelID := strings.TrimSpace(c.Query("id"))
	if modelID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Parameter 'id' ist erforderlich",
		})
	}

	boardKey := boardParam(c)
	entries, info := m.snapshotState(boardKey)
	detail := buildDetail(entries, modelID, info, true)

	if strings.EqualFold(c.Query("hub", "true"), "true") {
		lookup := detail.ModelID
		if lookup == "" {
			lookup = modelID
		}
		stats, cardResults := m.hubStats(c.UserContext(), lookup)
		detail.Hub = stats
		detail.CardResults = cardResults
	}

	if len(detail.Entries) == 0 && (detail.Hub == nil || detail.Hub.Missing) {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":    "Modell weder in dieser Rangliste noch auf dem Hub gefunden",
			"model_id": modelID,
			"board":    info,
		})
	}
	return c.JSON(detail)
}

func (m *Module) handleCompare(c *fiber.Ctx) error {
	raw := strings.TrimSpace(c.Query("ids"))
	if raw == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Parameter 'ids' ist erforderlich",
		})
	}

	ids := splitList(raw)
	if len(ids) > maxCompare {
		ids = ids[:maxCompare]
	}

	boardKey := boardParam(c)
	entries, info := m.snapshotState(boardKey)
	withHub := strings.EqualFold(c.Query("hub", "true"), "true")

	details := make([]ModelDetail, 0, len(ids))
	for _, id := range ids {
		detail := buildDetail(entries, id, info, false)
		if withHub && detail.ModelID != "" {
			detail.Hub, detail.CardResults = m.hubStats(c.UserContext(), detail.ModelID)
		}
		details = append(details, detail)
	}

	return c.JSON(fiber.Map{
		"models": details,
		"board":  info,
	})
}

func buildDetail(entries []Entry, modelID string, info BoardInfo, withPeers bool) ModelDetail {
	detail := ModelDetail{
		Board:   info.Key,
		ModelID: "",
		Name:    modelID,

		Entries:     []Entry{},
		MetricRanks: map[string]int{},
		Deltas:      map[string]Delta{},
		Metrics:     info.Metrics,
		Source:      info.Source,
		ScoreKind:   info.ScoreKind,
		Totals: map[string]int{
			"entries": len(entries),
		},
	}

	wanted := strings.ToLower(strings.TrimSpace(modelID))
	own := make([]Entry, 0, 4)
	for i := range entries {
		if strings.ToLower(entries[i].ModelID) != wanted &&
			strings.ToLower(entries[i].Name) != wanted &&
			strings.ToLower(entries[i].Key) != wanted {
			continue
		}

		detail.Name = entries[i].Name
		if entries[i].ModelID != "" {
			detail.ModelID = entries[i].ModelID
		}
		own = append(own, entries[i])
	}
	if len(own) == 0 {
		return detail
	}

	sort.SliceStable(own, func(i, j int) bool { return own[i].Primary > own[j].Primary })
	detail.Entries = own
	best := own[0]
	detail.Best = &best

	for _, metric := range info.Metrics {
		value := best.ScoreOf(metric.Key)
		better := 0
		values := make([]float64, 0, len(entries))
		for i := range entries {
			other := entries[i].ScoreOf(metric.Key)
			if other > 0 {
				values = append(values, other)
			}
			if other > value {
				better++
			}
		}

		if value > 0 {
			detail.MetricRanks[metric.Key] = better + 1
		}
		metricMedian := median(values)
		detail.Deltas[metric.Key] = Delta{
			Value:  round2(value),
			Median: round2(metricMedian),
			Diff:   round2(value - metricMedian),
		}
	}

	primaries := make([]float64, 0, len(entries))
	for i := range entries {
		primaries = append(primaries, entries[i].Primary)
	}
	primaryMedian := median(primaries)
	detail.Deltas[primaryKey] = Delta{
		Value:  round2(best.Primary),
		Median: round2(primaryMedian),
		Diff:   round2(best.Primary - primaryMedian),
	}

	if len(entries) > 0 {
		detail.Percentile = round2(100 * (1 - float64(best.Rank-1)/float64(len(entries))))
	}
	if withPeers {
		detail.Peers = peersOf(entries, best, 6)
	}
	return detail
}

func peersOf(entries []Entry, best Entry, limit int) []Entry {
	candidates := make([]Entry, 0, 32)
	seen := map[string]bool{modelKey(best): true}

	for i := range entries {
		key := modelKey(entries[i])
		if seen[key] {
			continue
		}
		seen[key] = true
		candidates = append(candidates, entries[i])
	}

	sort.SliceStable(candidates, func(i, j int) bool {
		return math.Abs(candidates[i].Primary-best.Primary) < math.Abs(candidates[j].Primary-best.Primary)
	})
	if len(candidates) > limit {
		candidates = candidates[:limit]
	}
	sort.SliceStable(candidates, func(i, j int) bool { return candidates[i].Primary > candidates[j].Primary })
	return candidates
}

func shareOf(unique []Entry, pick func(Entry) string) []FacetValue {
	counts := map[string]int{}
	for i := range unique {
		if value := pick(unique[i]); value != "" {
			counts[value]++
		}
	}
	return topFacets(counts, 12)
}

func topByMetric(unique []Entry, metrics []MetricInfo, limit int) map[string][]Entry {
	result := make(map[string][]Entry, len(metrics))
	for _, metric := range metrics {
		ranked := make([]Entry, len(unique))
		copy(ranked, unique)
		sortEntries(ranked, metric.Key, "desc")
		best := headOf(ranked, limit)

		if len(best) > 0 && best[0].ScoreOf(metric.Key) <= 0 {
			continue
		}
		result[metric.Key] = best
	}
	return result
}

func headOf(entries []Entry, limit int) []Entry {
	if limit <= 0 || len(entries) <= limit {
		out := make([]Entry, len(entries))
		copy(out, entries)
		return out
	}
	out := make([]Entry, limit)
	copy(out, entries[:limit])
	return out
}

func parseQuery(c *fiber.Ctx, metrics []MetricInfo) Query {
	query := Query{
		Search:          strings.TrimSpace(c.Query("query")),
		Types:           splitList(c.Query("type")),
		Orgs:            splitList(c.Query("org")),
		Licenses:        splitList(c.Query("license")),
		OpenWeightsOnly: boolQuery(c, "open_weights", false),
		BestPerModel:    boolQuery(c, "best_per_model", true),
		Sort:            strings.TrimSpace(c.Query("sort", primaryKey)),
		Order:           strings.TrimSpace(c.Query("order", "desc")),
		Offset:          parseInt(c.Query("offset"), 0),
		Limit:           parseInt(c.Query("limit"), defaultLimit),
	}

	if !isSortable(query.Sort, metrics) || query.Sort == "average" {
		query.Sort = primaryKey
	}
	if !strings.EqualFold(query.Order, "asc") {
		query.Order = "desc"
	} else {
		query.Order = "asc"
	}
	if query.Limit <= 0 {
		query.Limit = defaultLimit
	}
	if query.Limit > maxLimit {
		query.Limit = maxLimit
	}
	if query.Offset < 0 {
		query.Offset = 0
	}
	return query
}

func splitList(raw string) []string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	values := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed == "" {
			continue
		}
		values = append(values, strings.Clone(trimmed))
	}
	return values
}

func parseInt(raw string, fallback int) int {
	value, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil {
		return fallback
	}
	return value
}

func boolQuery(c *fiber.Ctx, name string, fallback bool) bool {
	raw := strings.TrimSpace(c.Query(name))
	if raw == "" {
		return fallback
	}
	value, err := strconv.ParseBool(raw)
	if err != nil {
		return fallback
	}
	return value
}
