// Package benchmark serves public model leaderboards. Only the LMArena text
// board is registered; its Parquet snapshot is cached locally and refreshed on a
// schedule.
package benchmark

import (
	"context"
	"net/http"
)

const primaryKey = "primary"

const BoardArenaText = "arena_text"

const DefaultBoard = BoardArenaText

type fetchFunc func(ctx context.Context, client *http.Client, ep endpoints, token string) ([]Entry, string, error)

type board struct {
	info  BoardInfo
	fetch fetchFunc
}

var BoardOrder = []string{
	BoardArenaText,
}

var boards = map[string]*board{
	BoardArenaText: {
		info: BoardInfo{
			Key:          BoardArenaText,
			Label:        "LMArena · Text",
			Kind:         "arena",
			ScoreKind:    "elo",
			PrimaryLabel: "Elo",
			ScoreMax:     1600,
			Metrics:      arenaMetrics(arenaTextCategories),
			Source: SourceInfo{
				Provider: "LMArena",
				Dataset:  arenaDataset,
				URL:      "https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset",
				Live:     true,
			},
		},
		fetch: fetchArena,
	},
}

func knownBoard(key string) (*board, bool) {
	entry, ok := boards[key]
	return entry, ok
}

func boardMetrics(key string) []MetricInfo {
	if entry, ok := boards[key]; ok {
		return entry.info.Metrics
	}
	return nil
}
