package benchmark

import (
	"context"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"
)

func liveClient(t *testing.T) (*http.Client, endpoints, string, context.Context, context.CancelFunc) {
	t.Helper()
	if os.Getenv("BENCHMARK_LIVE") != "1" {
		t.Skip("Netztest: mit BENCHMARK_LIVE=1 aktivieren")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 600*time.Second)
	return &http.Client{Timeout: 90 * time.Second}, defaultEndpoints(),
		strings.TrimSpace(os.Getenv("BENCHMARK_LIVE_TOKEN")), ctx, cancel
}

func TestLiveArenaSchema(t *testing.T) {
	client, ep, token, ctx, cancel := liveClient(t)
	defer cancel()

	entries, published, err := fetchArena(ctx, client, ep, token)
	if err != nil {
		t.Fatalf("fetchArena() error = %v", err)
	}
	if len(entries) < 50 {
		t.Fatalf("nur %d Modelle in der Gesamtwertung", len(entries))
	}
	if published == "" {
		t.Fatal("Veroeffentlichungsdatum fehlt")
	}
	if entries[0].Name == "" || entries[0].Primary <= 0 {
		t.Fatalf("Arena-Spalten passen nicht mehr: %+v", entries[0])
	}

	for _, category := range arenaTextCategories {
		scored := 0
		for i := range entries {
			if entries[i].ScoreOf(category.Key) > 0 {
				scored++
			}
		}
		t.Logf("%-24s %d von %d Modellen bewertet", category.Key, scored, len(entries))
		if scored == 0 {
			t.Errorf("Wertung %q ist im Abzug leer", category.Key)
		}
	}
}

func TestLiveHubStats(t *testing.T) {
	client, ep, token, ctx, cancel := liveClient(t)
	defer cancel()

	stats, _, err := fetchHubStats(ctx, client, ep.hub, "Qwen/Qwen2.5-7B-Instruct", token)
	if err != nil {
		t.Fatalf("fetchHubStats() error = %v", err)
	}
	if stats == nil || stats.Missing {
		t.Fatalf("Modell nicht gefunden: %+v", stats)
	}
	if stats.Likes <= 0 || stats.DownloadsAllTime <= 0 || stats.ParamsTotal <= 0 {
		t.Fatalf("Live-Zahlen unvollstaendig: %+v", stats)
	}
}
