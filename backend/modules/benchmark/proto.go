package benchmark

import (
	benchmarkv1 "github.com/culpeohq/backend/gen/go/culpeostudio/benchmark/v1"
)

func boardStateToProto(state string) benchmarkv1.BoardState {
	switch state {
	case stateEmpty:
		return benchmarkv1.BoardState_BOARD_STATE_EMPTY
	case stateLoading:
		return benchmarkv1.BoardState_BOARD_STATE_LOADING
	case stateReady:
		return benchmarkv1.BoardState_BOARD_STATE_READY
	case stateError:
		return benchmarkv1.BoardState_BOARD_STATE_ERROR
	default:
		return benchmarkv1.BoardState_BOARD_STATE_UNSPECIFIED
	}
}

// sortOrderFromProto returns the spelling the sorter compares against. An
// unspecified order means descending, which is how every board is read.
func sortOrderFromProto(order benchmarkv1.SortOrder) string {
	if order == benchmarkv1.SortOrder_SORT_ORDER_ASC {
		return "asc"
	}
	return "desc"
}

func sortOrderToProto(order string) benchmarkv1.SortOrder {
	if order == "asc" {
		return benchmarkv1.SortOrder_SORT_ORDER_ASC
	}
	return benchmarkv1.SortOrder_SORT_ORDER_DESC
}

func detailToProto(detail Detail) *benchmarkv1.Detail {
	return &benchmarkv1.Detail{Key: detail.Key, Value: detail.Value}
}

func entryToProto(entry Entry) *benchmarkv1.Entry {
	message := &benchmarkv1.Entry{
		Board:       entry.Board,
		Key:         entry.Key,
		Name:        entry.Name,
		ModelId:     entry.ModelID,
		Org:         entry.Org,
		License:     entry.License,
		Url:         entry.URL,
		Type:        entry.Type,
		OpenWeights: entry.OpenWeights,
		EvalDate:    entry.EvalDate,
		Primary:     entry.Primary,
		Rank:        int32(entry.Rank),
	}

	if len(entry.Scores) > 0 {
		message.Scores = make(map[string]float64, len(entry.Scores))
		for key, value := range entry.Scores {
			message.Scores[key] = value
		}
	}

	message.Details = make([]*benchmarkv1.Detail, 0, len(entry.Details))
	for _, detail := range entry.Details {
		message.Details = append(message.Details, detailToProto(detail))
	}
	return message
}

func entriesToProto(entries []Entry) []*benchmarkv1.Entry {
	out := make([]*benchmarkv1.Entry, 0, len(entries))
	for _, entry := range entries {
		out = append(out, entryToProto(entry))
	}
	return out
}

func entryListsToProto(byMetric map[string][]Entry) map[string]*benchmarkv1.EntryList {
	out := make(map[string]*benchmarkv1.EntryList, len(byMetric))
	for key, entries := range byMetric {
		out[key] = &benchmarkv1.EntryList{Entries: entriesToProto(entries)}
	}
	return out
}

func metricInfoToProto(metric MetricInfo) *benchmarkv1.MetricInfo {
	return &benchmarkv1.MetricInfo{
		Key:     metric.Key,
		Label:   metric.Label,
		Family:  metric.Family,
		Shots:   metric.Shots,
		Dataset: metric.Dataset,
		Url:     metric.URL,
	}
}

func metricsToProto(metrics []MetricInfo) []*benchmarkv1.MetricInfo {
	out := make([]*benchmarkv1.MetricInfo, 0, len(metrics))
	for _, metric := range metrics {
		out = append(out, metricInfoToProto(metric))
	}
	return out
}

func metricStatsToProto(stats []MetricStats) []*benchmarkv1.MetricStats {
	out := make([]*benchmarkv1.MetricStats, 0, len(stats))
	for _, stat := range stats {
		out = append(out, &benchmarkv1.MetricStats{
			Key:       stat.Key,
			Min:       stat.Min,
			Max:       stat.Max,
			Mean:      stat.Mean,
			Median:    stat.Median,
			TopModel:  stat.TopModel,
			TopScore:  stat.TopScore,
			Evaluated: int32(stat.Evaluated),
		})
	}
	return out
}

func sourceInfoToProto(source SourceInfo) *benchmarkv1.SourceInfo {
	return &benchmarkv1.SourceInfo{
		Provider:    source.Provider,
		Dataset:     source.Dataset,
		Url:         source.URL,
		Live:        source.Live,
		Archived:    source.Archived,
		ArchivedAt:  source.ArchivedAt,
		PublishedAt: source.PublishedAt,
		FetchedAt:   source.FetchedAt,
		FromCache:   source.FromCache,
		Entries:     int32(source.Entries),
		Models:      int32(source.Models),
		State:       boardStateToProto(source.State),
		Error:       source.Error,
	}
}

func boardInfoToProto(info BoardInfo) *benchmarkv1.BoardInfo {
	return &benchmarkv1.BoardInfo{
		Key:          info.Key,
		Label:        info.Label,
		Kind:         info.Kind,
		ScoreKind:    info.ScoreKind,
		PrimaryLabel: info.PrimaryLabel,
		ScoreMax:     info.ScoreMax,
		Metrics:      metricsToProto(info.Metrics),
		Source:       sourceInfoToProto(info.Source),
	}
}

func boardInfosToProto(infos []BoardInfo) []*benchmarkv1.BoardInfo {
	out := make([]*benchmarkv1.BoardInfo, 0, len(infos))
	for _, info := range infos {
		out = append(out, boardInfoToProto(info))
	}
	return out
}

func facetValuesToProto(values []FacetValue) []*benchmarkv1.FacetValue {
	out := make([]*benchmarkv1.FacetValue, 0, len(values))
	for _, value := range values {
		out = append(out, &benchmarkv1.FacetValue{
			Value: value.Value,
			Label: value.Label,
			Count: int32(value.Count),
		})
	}
	return out
}

func facetsToProto(facets Facets) *benchmarkv1.Facets {
	return &benchmarkv1.Facets{
		Types:    facetValuesToProto(facets.Types),
		Orgs:     facetValuesToProto(facets.Orgs),
		Licenses: facetValuesToProto(facets.Licenses),
	}
}

func hubStatsToProto(stats *HubStats) *benchmarkv1.HubStats {
	if stats == nil {
		return nil
	}
	return &benchmarkv1.HubStats{
		ModelId:            stats.ModelID,
		Likes:              int32(stats.Likes),
		Downloads_30D:      stats.Downloads30d,
		DownloadsAllTime:   stats.DownloadsAllTime,
		TrendingScore:      stats.TrendingScore,
		LastModified:       stats.LastModified,
		PipelineTag:        stats.PipelineTag,
		Gated:              stats.Gated,
		ParamsTotal:        stats.ParamsTotal,
		Tags:               append([]string{}, stats.Tags...),
		InferenceProviders: append([]string{}, stats.Providers...),
		Missing:            stats.Missing,
	}
}

func cardResultsToProto(results []CardResult) []*benchmarkv1.CardResult {
	out := make([]*benchmarkv1.CardResult, 0, len(results))
	for _, result := range results {
		out = append(out, &benchmarkv1.CardResult{
			Task:     result.Task,
			Dataset:  result.Dataset,
			Metric:   result.Metric,
			Value:    result.Value,
			Verified: result.Verifed,
		})
	}
	return out
}

func modelDetailToProto(detail ModelDetail) *benchmarkv1.ModelDetail {
	message := &benchmarkv1.ModelDetail{
		Board:       detail.Board,
		ModelId:     detail.ModelID,
		Name:        detail.Name,
		Entries:     entriesToProto(detail.Entries),
		Percentile:  detail.Percentile,
		Peers:       entriesToProto(detail.Peers),
		Hub:         hubStatsToProto(detail.Hub),
		CardResults: cardResultsToProto(detail.CardResults),
		Metrics:     metricsToProto(detail.Metrics),
		Source:      sourceInfoToProto(detail.Source),
		ScoreKind:   detail.ScoreKind,
	}

	if detail.Best != nil {
		message.Best = entryToProto(*detail.Best)
	}

	message.MetricRanks = make(map[string]int32, len(detail.MetricRanks))
	for key, rank := range detail.MetricRanks {
		message.MetricRanks[key] = int32(rank)
	}

	message.Deltas = make(map[string]*benchmarkv1.Delta, len(detail.Deltas))
	for key, delta := range detail.Deltas {
		message.Deltas[key] = &benchmarkv1.Delta{
			Value:  delta.Value,
			Median: delta.Median,
			Diff:   delta.Diff,
		}
	}

	message.Totals = make(map[string]int32, len(detail.Totals))
	for key, total := range detail.Totals {
		message.Totals[key] = int32(total)
	}
	return message
}
