package benchmark

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"
)

const (
	arenaDataset = "lmarena-ai/leaderboard-dataset"

	arenaConfig = "text"

	arenaSplit = "latest"
)

type arenaRow struct {
	Model     string  `parquet:"model_name"`
	Org       string  `parquet:"organization"`
	License   string  `parquet:"license"`
	Rating    float64 `parquet:"rating"`
	Lower     float64 `parquet:"rating_lower"`
	Upper     float64 `parquet:"rating_upper"`
	Variance  float64 `parquet:"variance"`
	Votes     float64 `parquet:"vote_count"`
	Rank      float64 `parquet:"rank"`
	Category  string  `parquet:"category"`
	Published string  `parquet:"leaderboard_publish_date"`
}

func fetchArena(ctx context.Context, client *http.Client, ep endpoints, token string) ([]Entry, string, error) {
	rows, err := fetchParquetRows[arenaRow](ctx, client, ep.hub, parquetQuery{
		dataset: arenaDataset,
		config:  arenaConfig,
		split:   arenaSplit,
		token:   token,
	})
	if err != nil {
		return nil, "", err
	}

	byCategory := make(map[string][]arenaRow, 32)
	for _, row := range rows {
		category := strings.TrimSpace(row.Category)
		if category == "" {
			continue
		}
		byCategory[category] = append(byCategory[category], row)
	}

	overall := byCategory[arenaPrimaryCategory]
	if len(overall) == 0 {
		return nil, "", fmt.Errorf("arena-rangliste ist leer")
	}

	published := ""
	entries := make([]Entry, 0, len(overall))
	index := make(map[string]int, len(overall))

	for _, row := range overall {
		name := strings.TrimSpace(row.Model)
		if name == "" {
			continue
		}
		if published == "" {
			published = strings.TrimSpace(row.Published)
		}

		license := strings.TrimSpace(row.License)
		entry := Entry{
			Board:       BoardArenaText,
			Key:         name,
			Name:        name,
			Org:         strings.TrimSpace(row.Org),
			License:     license,
			OpenWeights: isOpenLicense(license),
			Type:        arenaType(license),
			Primary:     row.Rating,
			Scores:      make(map[string]float64, len(arenaTextCategories)),
			EvalDate:    strings.TrimSpace(row.Published),
			URL:         "https://lmarena.ai/leaderboard",
		}

		if row.Votes > 0 {
			entry.Details = appendDetail(entry.Details, "votes", formatFloat(row.Votes, 0))
		}
		if row.Lower > 0 && row.Upper > 0 {
			entry.Details = appendDetail(entry.Details, "confidence",
				fmt.Sprintf("%s – %s", formatFloat(row.Lower, 0), formatFloat(row.Upper, 0)))
		}

		if row.Variance > 0 {
			entry.Details = appendDetail(entry.Details, "variance", formatFloat(row.Variance, 1))
		}
		entry.Details = appendDetail(entry.Details, "arena_rank", formatFloat(row.Rank, 0))

		index[strings.ToLower(name)] = len(entries)
		entries = append(entries, entry)
	}

	missing := make([]string, 0, len(arenaTextCategories))
	for _, category := range arenaTextCategories {
		categoryRows := byCategory[category.Key]
		if len(categoryRows) == 0 {
			missing = append(missing, category.Key)
			continue
		}
		for _, row := range categoryRows {
			position, found := index[strings.ToLower(strings.TrimSpace(row.Model))]
			if !found {
				continue
			}
			entries[position].Scores[category.Key] = row.Rating
		}
	}

	if len(missing) > 0 {
		log.Printf("[benchmark] Arena fuehrt %d von %d Wertungen nicht mehr: %s",
			len(missing), len(arenaTextCategories), strings.Join(missing, ", "))
	}

	return entries, published, nil
}

func isOpenLicense(license string) bool {
	clean := strings.ToLower(strings.TrimSpace(license))
	if clean == "" {
		return false
	}
	return !strings.Contains(clean, "proprietary")
}

func arenaType(license string) string {
	if isOpenLicense(license) {
		return "open_weights"
	}
	return "proprietary"
}
