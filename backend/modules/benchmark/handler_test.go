package benchmark

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func arenaFixture() []Entry {
	return []Entry{
		{
			Board: BoardArenaText, Key: "claude-opus-5", Name: "claude-opus-5", Org: "anthropic",
			License: "Proprietary", Type: "proprietary", Primary: 1511.6,
			Scores:  map[string]float64{"coding": 1530, "math": 1490},
			Details: []Detail{{Key: "votes", Value: "2386"}},
		},
		{
			Board: BoardArenaText, Key: "qwen3-235b", Name: "qwen3-235b", Org: "alibaba",
			License: "Apache 2.0", Type: "open_weights", OpenWeights: true, Primary: 1402.1,
			Scores: map[string]float64{"coding": 1380, "math": 1450},
		},
		{
			Board: BoardArenaText, Key: "tinychat", Name: "tinychat", Org: "small",
			License: "MIT", Type: "open_weights", OpenWeights: true, Primary: 1180.0,
			Scores: map[string]float64{"coding": 1150},
		},
	}
}

func newTestModule(t *testing.T) *Module {
	t.Helper()

	module := New(t.TempDir(), filepath.Join(t.TempDir(), "settings.json"))
	loaded := time.Date(2026, 7, 30, 12, 0, 0, 0, time.UTC)
	module.replaceEntries(BoardArenaText, arenaFixture(), loaded, "2026-07-30", true)
	t.Cleanup(func() { _ = module.Shutdown() })
	return module
}

func TestUnloadedBoardReportsItsStateInsteadOfLookingEmpty(t *testing.T) {
	t.Parallel()

	module := New(t.TempDir(), filepath.Join(t.TempDir(), "settings.json"))
	t.Cleanup(func() { _ = module.Shutdown() })

	for _, info := range module.allBoards() {
		if info.Source.State != stateEmpty {
			t.Fatalf("Board %q meldet %q, want %q", info.Key, info.Source.State, stateEmpty)
		}
	}
}

func TestSnapshotRoundTrip(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	path := snapshotFilePath(dir, BoardArenaText)
	fetchedAt := time.Date(2026, 7, 30, 12, 0, 0, 0, time.UTC)
	if err := saveSnapshot(path, BoardArenaText, arenaFixture(), fetchedAt, "2026-07-30"); err != nil {
		t.Fatalf("saveSnapshot() error = %v", err)
	}

	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("Abzug fehlt: %v", err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("Berechtigungen = %v, want 0600", info.Mode().Perm())
	}

	snapshot, err := loadSnapshot(path)
	if err != nil || snapshot == nil {
		t.Fatalf("loadSnapshot() = %v, %v", snapshot, err)
	}
	if len(snapshot.Entries) != 3 || snapshot.Board != BoardArenaText {
		t.Fatalf("Abzug unvollstaendig: %+v", snapshot)
	}
	if snapshot.PublishedAt != "2026-07-30" || !snapshot.FetchedAt.Equal(fetchedAt) {
		t.Fatalf("Zeitangaben verloren: %+v", snapshot)
	}
	if snapshot.Entries[0].Scores["coding"] != 1530 {
		t.Fatalf("Wertungen verloren: %+v", snapshot.Entries[0].Scores)
	}
}

func TestLoadSnapshotIgnoresMissingFileAndRejectsForeignSchema(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	snapshot, err := loadSnapshot(filepath.Join(dir, "nichts.json"))
	if err != nil || snapshot != nil {
		t.Fatalf("fehlende Datei = %v, %v", snapshot, err)
	}

	foreign := filepath.Join(dir, "fremd.json")
	if err := os.WriteFile(foreign, []byte(`{"schema_version":99,"entries":[{"name":"a"}]}`), 0o600); err != nil {
		t.Fatalf("Datei schreiben: %v", err)
	}
	if _, err := loadSnapshot(foreign); err == nil {
		t.Fatal("fremdes Schema wurde akzeptiert")
	}
}

func TestInitializeUsesSnapshotWithoutNetwork(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	if err := saveSnapshot(snapshotFilePath(dir, BoardArenaText), BoardArenaText,
		arenaFixture(), time.Now().UTC(), "2026-07-30"); err != nil {
		t.Fatalf("saveSnapshot() error = %v", err)
	}

	module := New(dir, filepath.Join(t.TempDir(), "settings.json"))

	module.endpoints = endpoints{hub: "http://127.0.0.1:1"}
	defer func() { _ = module.Shutdown() }()

	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize() error = %v", err)
	}
	entries, info := module.snapshotState(BoardArenaText)
	if len(entries) != 3 || info.Source.State != stateReady || !info.Source.FromCache {
		t.Fatalf("Abzug wurde nicht uebernommen: %d Eintraege, %+v", len(entries), info.Source)
	}
}

func startWithSnapshot(t *testing.T, entries []Entry, age time.Duration) *Module {
	t.Helper()

	dir := t.TempDir()
	if err := saveSnapshot(snapshotFilePath(dir, BoardArenaText), BoardArenaText,
		entries, time.Now().UTC().Add(-age), "2026-07-30"); err != nil {
		t.Fatalf("saveSnapshot() error = %v", err)
	}

	module := New(dir, filepath.Join(t.TempDir(), "settings.json"))
	module.endpoints = endpoints{hub: "http://127.0.0.1:1"}
	t.Cleanup(func() { _ = module.Shutdown() })

	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize() error = %v", err)
	}
	return module
}

func refreshAttempted(module *Module, within time.Duration) bool {
	deadline := time.Now().Add(within)
	for time.Now().Before(deadline) {
		if _, info := module.snapshotState(BoardArenaText); info.Source.Error != "" {
			return true
		}
		time.Sleep(5 * time.Millisecond)
	}
	return false
}

func crippledFixture() []Entry {
	entries := arenaFixture()
	for i := range entries {
		entries[i].Scores = map[string]float64{"creative_writing": 1500 - float64(i)}
	}
	return entries
}

func TestIncompleteSnapshotIsRefreshedBeforeItsTime(t *testing.T) {
	t.Parallel()

	module := startWithSnapshot(t, crippledFixture(), 2*time.Hour)

	gaps := module.missingMetrics(BoardArenaText)
	if len(gaps) != len(arenaTextCategories)-1 {
		t.Fatalf("erkannte Luecken = %v, want alle ausser creative_writing", gaps)
	}
	for _, gap := range gaps {
		if gap == "creative_writing" {
			t.Fatalf("die einzig gefuellte Wertung wurde als Luecke gemeldet: %v", gaps)
		}
	}
	if !refreshAttempted(module, 3*time.Second) {
		t.Fatal("unvollstaendiger Abzug loeste keinen Abgleich aus")
	}

	entries, info := module.snapshotState(BoardArenaText)
	if len(entries) != 3 || info.Source.State != stateReady {
		t.Fatalf("Abzug wurde verworfen: %d Eintraege, %+v", len(entries), info.Source)
	}
}

func TestCompleteSnapshotIsLeftAloneWithinTheDay(t *testing.T) {
	t.Parallel()

	complete := arenaFixture()
	for i := range complete {
		complete[i].Scores = map[string]float64{}
		for _, category := range arenaTextCategories {
			complete[i].Scores[category.Key] = 1400 - float64(i)
		}
	}

	module := startWithSnapshot(t, complete, 2*time.Hour)
	if gaps := module.missingMetrics(BoardArenaText); len(gaps) != 0 {
		t.Fatalf("Luecken gemeldet, wo keine sind: %v", gaps)
	}
	if refreshAttempted(module, 300*time.Millisecond) {
		t.Fatal("vollstaendiger Abzug wurde ohne Not erneuert")
	}
}

func TestHubStatsAreCached(t *testing.T) {
	t.Parallel()

	calls := 0
	hub := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls++
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"id":"acme/large","likes":5,
			"cardData":{"model-index":[{"name":"large","results":[
				{"task":{"type":"text-generation"},"dataset":{"name":"MMLU"},
				 "metrics":[{"name":"acc","value":61.2}]}]}]}}`))
	}))
	defer hub.Close()

	module := newTestModule(t)
	module.endpoints.hub = hub.URL
	module.client = hub.Client()

	stats, results := module.hubStats(t.Context(), "acme/large")
	if stats == nil || stats.Likes != 5 {
		t.Fatalf("Hub-Zahlen = %+v", stats)
	}
	if len(results) != 1 || results[0].Value != 61.2 || results[0].Dataset != "MMLU" {
		t.Fatalf("selbstgemeldete Werte = %+v", results)
	}

	if _, _ = module.hubStats(t.Context(), "acme/large"); calls != 1 {
		t.Fatalf("Hub wurde %d mal befragt, want 1 (Zwischenspeicher)", calls)
	}
}
