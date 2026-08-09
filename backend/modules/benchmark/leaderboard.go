package benchmark

import (
	"math"
	"sort"
	"strings"

	benchmarkv1 "github.com/culpeohq/backend/gen/go/culpeostudio/benchmark/v1"
)

const (
	defaultLimit = 50
	maxLimit     = 200

	maxCompare = 12
)

// boardKeyOrDefault keeps the tolerance the query parameter had: a board the
// registry does not know falls back to the default one rather than failing, so
// a stale bookmark still shows a leaderboard.
func boardKeyOrDefault(requested string) string {
	key := strings.TrimSpace(requested)
	if _, ok := knownBoard(key); ok {
		return key
	}
	return DefaultBoard
}

func queryFromRequest(req *benchmarkv1.GetLeaderboardRequest, metrics []MetricInfo) Query {
	query := Query{
		Search:          strings.TrimSpace(req.GetQuery()),
		Types:           trimmedList(req.GetTypes()),
		Orgs:            trimmedList(req.GetOrgs()),
		Licenses:        trimmedList(req.GetLicenses()),
		OpenWeightsOnly: req.GetOpenWeightsOnly(),

		// An absent flag means true, which is what leaving the query parameter
		// off used to mean.
		BestPerModel: req.BestPerModel == nil || req.GetBestPerModel(),

		Sort:   strings.TrimSpace(req.GetSort()),
		Order:  sortOrderFromProto(req.GetOrder()),
		Offset: int(req.GetOffset()),
		Limit:  int(req.GetLimit()),
	}

	// "average" is accepted as a name for the primary score but is not a column
	// of its own, so it collapses onto the primary key like any unknown sort.
	if !isSortable(query.Sort, metrics) || query.Sort == "average" {
		query.Sort = primaryKey
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

func trimmedList(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	out := make([]string, 0, len(values))
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		out = append(out, trimmed)
	}
	if len(out) == 0 {
		return nil
	}
	return out
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
