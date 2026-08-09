package benchmark

import (
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
)

type Query struct {
	Search          string
	Types           []string
	Orgs            []string
	Licenses        []string
	OpenWeightsOnly bool

	BestPerModel bool

	Sort   string
	Order  string
	Offset int
	Limit  int
}

func sortValue(entry Entry, key string) float64 {
	if key == "" || key == primaryKey || key == "average" {
		return entry.Primary
	}
	return entry.ScoreOf(key)
}

func isSortable(key string, metrics []MetricInfo) bool {
	switch key {
	case "", primaryKey, "average", "name":
		return true
	}
	for _, metric := range metrics {
		if metric.Key == key {
			return true
		}
	}
	return false
}

func matchesAny(value string, allowed []string) bool {
	if len(allowed) == 0 {
		return true
	}
	value = strings.ToLower(strings.TrimSpace(value))
	for _, candidate := range allowed {
		if strings.ToLower(strings.TrimSpace(candidate)) == value {
			return true
		}
	}
	return false
}

func (q Query) matches(entry Entry) bool {
	if q.OpenWeightsOnly && !entry.OpenWeights {
		return false
	}
	if !matchesAny(entry.Type, q.Types) {
		return false
	}
	if !matchesAny(entry.Org, q.Orgs) {
		return false
	}
	if !matchesAny(entry.License, q.Licenses) {
		return false
	}
	if search := strings.ToLower(strings.TrimSpace(q.Search)); search != "" {
		haystack := strings.ToLower(entry.Name + " " + entry.ModelID + " " + entry.Org + " " + detailText(entry))
		for _, token := range strings.Fields(search) {
			if !strings.Contains(haystack, token) {
				return false
			}
		}
	}
	return true
}

func detailText(entry Entry) string {
	if len(entry.Details) == 0 {
		return ""
	}
	parts := make([]string, 0, len(entry.Details))
	for _, detail := range entry.Details {
		parts = append(parts, detail.Value)
	}
	return strings.Join(parts, " ")
}

func filter(entries []Entry, q Query) []Entry {
	result := make([]Entry, 0, len(entries))
	for i := range entries {
		if q.matches(entries[i]) {
			result = append(result, entries[i])
		}
	}
	return result
}

func keepBestPerModel(entries []Entry) []Entry {
	bestIndex := make(map[string]int, len(entries))
	result := make([]Entry, 0, len(entries))
	for i := range entries {
		key := modelKey(entries[i])
		existing, found := bestIndex[key]
		if !found {
			bestIndex[key] = len(result)
			result = append(result, entries[i])
			continue
		}
		if entries[i].Primary > result[existing].Primary {
			result[existing] = entries[i]
		}
	}
	return result
}

func modelKey(entry Entry) string {
	if entry.ModelID != "" {
		return strings.ToLower(entry.ModelID)
	}
	return strings.ToLower(entry.Name)
}

func sortEntries(entries []Entry, key, order string) {
	descending := !strings.EqualFold(order, "asc")
	sort.SliceStable(entries, func(i, j int) bool {
		if key == "name" {
			less := strings.ToLower(entries[i].Name) < strings.ToLower(entries[j].Name)
			if descending {
				return !less
			}
			return less
		}
		left, right := sortValue(entries[i], key), sortValue(entries[j], key)
		if left == right {
			return strings.ToLower(entries[i].Name) < strings.ToLower(entries[j].Name)
		}
		if descending {
			return left > right
		}
		return left < right
	})
}

func paginate(entries []Entry, offset, limit int) []Entry {
	if offset < 0 {
		offset = 0
	}
	if offset >= len(entries) {
		return []Entry{}
	}
	end := len(entries)
	if limit > 0 && offset+limit < end {
		end = offset + limit
	}
	return entries[offset:end]
}

func buildFacets(entries []Entry) Facets {
	types := map[string]int{}
	orgs := map[string]int{}
	licenses := map[string]int{}

	for i := range entries {
		if entries[i].Type != "" {
			types[entries[i].Type]++
		}
		if entries[i].Org != "" {
			orgs[entries[i].Org]++
		}
		if entries[i].License != "" {
			licenses[entries[i].License]++
		}
	}

	return Facets{
		Types:    topFacets(types, 0),
		Orgs:     topFacets(orgs, 20),
		Licenses: topFacets(licenses, 15),
	}
}

func topFacets(counts map[string]int, limit int) []FacetValue {
	values := make([]FacetValue, 0, len(counts))
	for value, count := range counts {
		values = append(values, FacetValue{Value: value, Count: count})
	}
	sort.Slice(values, func(i, j int) bool {
		if values[i].Count == values[j].Count {
			return values[i].Value < values[j].Value
		}
		return values[i].Count > values[j].Count
	})
	if limit > 0 && len(values) > limit {
		values = values[:limit]
	}
	return values
}

func assignRanks(entries []Entry) {
	ordered := make([]*Entry, 0, len(entries))
	for i := range entries {
		ordered = append(ordered, &entries[i])
	}
	sort.SliceStable(ordered, func(i, j int) bool {
		if ordered[i].Primary == ordered[j].Primary {
			return strings.ToLower(ordered[i].Name) < strings.ToLower(ordered[j].Name)
		}
		return ordered[i].Primary > ordered[j].Primary
	})
	for position, entry := range ordered {
		entry.Rank = position + 1
	}
}

func appendDetail(details []Detail, key, value string) []Detail {
	value = strings.TrimSpace(value)
	if value == "" {
		return details
	}
	return append(details, Detail{Key: key, Value: value})
}

func formatFloat(value float64, decimals int) string {
	return strconv.FormatFloat(value, 'f', decimals, 64)
}

func round2(value float64) float64 {
	return math.Round(value*100) / 100
}

func describeError(err error) string {
	if err == nil {
		return ""
	}
	text := err.Error()
	if len(text) > 300 {
		return text[:300] + "…"
	}
	return fmt.Sprint(text)
}
