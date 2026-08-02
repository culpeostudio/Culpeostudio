package benchmark

import (
	"math"
	"sort"
)

type arenaCategory struct {
	Key    string
	Label  string
	Family string
}

const arenaPrimaryCategory = "overall"

var arenaTextCategories = []arenaCategory{
	{Key: "hard_prompts", Label: "Hard Prompts", Family: "reasoning"},
	{Key: "coding", Label: "Coding", Family: "coding"},
	{Key: "math", Label: "Math", Family: "math"},
	{Key: "creative_writing", Label: "Creative Writing", Family: "creative"},
	{Key: "instruction_following", Label: "Instruction Following", Family: "instruction"},
	{Key: "multi_turn", Label: "Multi-Turn", Family: "conversation"},
	{Key: "longer_query", Label: "Longer Query", Family: "conversation"},
	{Key: "non_english", Label: "Non-English", Family: "language"},
}

func arenaMetrics(categories []arenaCategory) []MetricInfo {
	metrics := make([]MetricInfo, 0, len(categories))
	for _, category := range categories {
		metrics = append(metrics, MetricInfo{
			Key:    category.Key,
			Label:  category.Label,
			Family: category.Family,
			URL:    "https://lmarena.ai/leaderboard",
		})
	}
	return metrics
}

func computeMetricStats(entries []Entry, metrics []MetricInfo) []MetricStats {
	stats := make([]MetricStats, 0, len(metrics))
	for _, metric := range metrics {
		values := make([]float64, 0, len(entries))
		stat := MetricStats{Key: metric.Key, Min: math.MaxFloat64}
		for i := range entries {
			value := entries[i].ScoreOf(metric.Key)
			if value <= 0 {
				continue
			}
			values = append(values, value)
			if value < stat.Min {
				stat.Min = value
			}
			if value > stat.Max {
				stat.Max = value
				stat.TopScore = value
				stat.TopModel = entries[i].Name
			}
		}
		if len(values) == 0 {
			stat.Min = 0
			stats = append(stats, stat)
			continue
		}
		sum := 0.0
		for _, value := range values {
			sum += value
		}
		stat.Mean = sum / float64(len(values))
		stat.Median = median(values)
		stat.Evaluated = len(values)
		stats = append(stats, stat)
	}
	return stats
}

func median(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	sorted := make([]float64, len(values))
	copy(sorted, values)
	sort.Float64s(sorted)
	middle := len(sorted) / 2
	if len(sorted)%2 == 1 {
		return sorted[middle]
	}
	return (sorted[middle-1] + sorted[middle]) / 2
}
