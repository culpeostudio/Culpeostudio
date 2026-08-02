package benchmark

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
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

func newTestApp(t *testing.T, module *Module) *fiber.App {
	t.Helper()

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	return app
}

func getRaw(t *testing.T, app *fiber.App, target string) string {
	t.Helper()

	res, err := app.Test(httptest.NewRequest(http.MethodGet, target, nil), 5000)
	if err != nil {
		t.Fatalf("GET %s: %v", target, err)
	}
	defer res.Body.Close()

	body, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatalf("Antwort lesen: %v", err)
	}
	return string(body)
}

func getJSON(t *testing.T, app *fiber.App, target string, out interface{}) int {
	t.Helper()

	res, err := app.Test(httptest.NewRequest(http.MethodGet, target, nil), 5000)
	if err != nil {
		t.Fatalf("GET %s: %v", target, err)
	}
	defer res.Body.Close()

	body, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatalf("Antwort lesen: %v", err)
	}
	if out != nil {
		if err := json.Unmarshal(body, out); err != nil {
			t.Fatalf("GET %s lieferte kein gueltiges JSON: %v (%s)", target, err, string(body))
		}
	}
	return res.StatusCode
}

func TestBoardsEndpointDescribesTheSource(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var response struct {
		Boards  []BoardInfo `json:"boards"`
		Default string      `json:"default"`
	}
	if code := getJSON(t, app, "/api/benchmark/boards", &response); code != http.StatusOK {
		t.Fatalf("Status = %d, want 200", code)
	}
	if len(response.Boards) != 1 || response.Default != DefaultBoard {
		t.Fatalf("unerwartete Ranglisten: %+v (default %q)", response.Boards, response.Default)
	}

	arena := response.Boards[0]
	if arena.Key != BoardArenaText {
		t.Fatalf("Key = %q", arena.Key)
	}
	if !arena.Source.Live || arena.Source.Archived {
		t.Fatalf("Arena muss als lebende Quelle gelten: %+v", arena.Source)
	}
	if arena.ScoreKind != "elo" || arena.PrimaryLabel != "Elo" {
		t.Fatalf("Arena-Darstellung falsch: %+v", arena)
	}
	if len(arena.Metrics) != len(arenaTextCategories) {
		t.Fatalf("len(Metrics) = %d, want %d", len(arena.Metrics), len(arenaTextCategories))
	}
	if arena.Source.State != stateReady || arena.Source.Entries != 3 {
		t.Fatalf("Arena-Zustand falsch: %+v", arena.Source)
	}
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

func TestLeaderboardRanksByElo(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var page LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard", &page)
	if page.Board.Key != DefaultBoard {
		t.Fatalf("Board = %q, want %q", page.Board.Key, DefaultBoard)
	}
	if page.Total != 3 || page.Items[0].Name != "claude-opus-5" {
		t.Fatalf("Rangliste falsch: %+v", page.Items)
	}

	var fallback LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard?board=gibtsnicht", &fallback)
	if fallback.Board.Key != DefaultBoard {
		t.Fatalf("Rueckfall-Board = %q", fallback.Board.Key)
	}
}

func TestLeaderboardAppliesFiltersAndSorting(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var openOnly LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard?open_weights=true", &openOnly)
	if openOnly.Total != 2 {
		t.Fatalf("nur offene Gewichte = %d, want 2", openOnly.Total)
	}
	for _, item := range openOnly.Items {
		if !item.OpenWeights {
			t.Fatalf("geschlossenes Modell im Ergebnis: %+v", item)
		}
	}

	var byOrg LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard?org=alibaba", &byOrg)
	if byOrg.Total != 1 || byOrg.Items[0].Name != "qwen3-235b" {
		t.Fatalf("Anbieterfilter lieferte %+v", byOrg.Items)
	}

	var byMath LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard?sort=math", &byMath)
	if byMath.Items[0].Name != "claude-opus-5" || byMath.Sort != "math" {
		t.Fatalf("Sortierung nach Math lieferte %q (sort=%q)", byMath.Items[0].Name, byMath.Sort)
	}

	var ascending LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard?order=asc", &ascending)
	if ascending.Items[0].Name != "tinychat" {
		t.Fatalf("aufsteigende Sortierung lieferte %q zuerst", ascending.Items[0].Name)
	}
}

func TestLeaderboardRejectsUnknownSortKey(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var page LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard?sort=%3B%20DROP%20TABLE", &page)
	if page.Sort != primaryKey {
		t.Fatalf("Sort = %q, want %q als Rueckfall", page.Sort, primaryKey)
	}
}

func TestLeaderboardLimitIsCapped(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var page LeaderboardPage
	getJSON(t, app, "/api/benchmark/leaderboard?limit=100000", &page)
	if page.Limit != maxLimit {
		t.Fatalf("Limit = %d, want %d", page.Limit, maxLimit)
	}
}

func TestModelDetailReportsRanksAndPeers(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var detail ModelDetail
	if code := getJSON(t, app, "/api/benchmark/model?id=CLAUDE-opus-5&hub=false", &detail); code != http.StatusOK {
		t.Fatalf("Status = %d, want 200", code)
	}
	if detail.Name != "claude-opus-5" {
		t.Fatalf("Name = %q, want die Schreibweise der Quelle", detail.Name)
	}
	if detail.Best == nil || detail.Best.Primary != 1511.6 {
		t.Fatalf("Best = %+v", detail.Best)
	}
	if detail.MetricRanks["coding"] != 1 {
		t.Fatalf("Coding-Rang = %d, want 1", detail.MetricRanks["coding"])
	}

	if rank, exists := detail.MetricRanks["hard_prompts"]; exists {
		t.Fatalf("unbewertete Kategorie meldet Platz %d", rank)
	}
	if detail.Deltas[primaryKey].Diff == 0 {
		t.Fatalf("Delta zum Median fehlt: %+v", detail.Deltas[primaryKey])
	}
	if detail.Percentile <= 0 || detail.Percentile > 100 {
		t.Fatalf("Percentile = %v", detail.Percentile)
	}
	if len(detail.Peers) != 2 {
		t.Fatalf("len(Peers) = %d, want 2", len(detail.Peers))
	}
	if len(detail.Metrics) != len(arenaTextCategories) {
		t.Fatalf("Detail ohne Wertungsbeschreibung: %+v", detail.Metrics)
	}
	if detail.ScoreKind != "elo" {
		t.Fatalf("ScoreKind = %q", detail.ScoreKind)
	}
}

func TestModelDetailRequiresID(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))
	if code := getJSON(t, app, "/api/benchmark/model", nil); code != http.StatusBadRequest {
		t.Fatalf("Status = %d, want 400", code)
	}
}

func TestModelDetailSkipsHubForNamesWithoutNamespace(t *testing.T) {
	t.Parallel()

	calls := 0
	hub := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls++
		w.WriteHeader(http.StatusNotFound)
	}))
	defer hub.Close()

	module := newTestModule(t)
	module.endpoints.hub = hub.URL
	module.client = hub.Client()
	app := newTestApp(t, module)

	var detail ModelDetail
	if code := getJSON(t, app, "/api/benchmark/model?id=claude-opus-5", &detail); code != http.StatusOK {
		t.Fatalf("Status = %d, want 200", code)
	}
	if calls != 0 {

		t.Fatalf("Hub wurde %d mal fuer einen Anzeigenamen befragt", calls)
	}
	if detail.Best == nil || detail.Best.Primary != 1511.6 {
		t.Fatalf("Arena-Eintrag fehlt: %+v", detail.Best)
	}
}

func TestModelDetailFallsBackToHubForUnknownModel(t *testing.T) {
	t.Parallel()

	hub := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"id":"brand/new","likes":42,"downloads":1000,"trendingScore":7,
			"safetensors":{"total":8030000000},"tags":["text-generation"],
			"inferenceProviderMapping":{"together":{"status":"live"},"cold":{"status":"staging"}}}`))
	}))
	defer hub.Close()

	module := newTestModule(t)
	module.endpoints.hub = hub.URL
	module.client = hub.Client()
	app := newTestApp(t, module)

	raw := getRaw(t, app, "/api/benchmark/model?id=brand/new")
	if !strings.Contains(raw, `"entries":[]`) {

		t.Fatalf("Antwort meldet keine leere Eintragsliste: %s", raw)
	}

	var detail ModelDetail
	if err := json.Unmarshal([]byte(raw), &detail); err != nil {
		t.Fatalf("Antwort unlesbar: %v", err)
	}
	if detail.Hub == nil || detail.Hub.Likes != 42 || detail.Hub.ParamsTotal != 8030000000 {
		t.Fatalf("Hub-Zahlen fehlen: %+v", detail.Hub)
	}
	if len(detail.Hub.Providers) != 1 || detail.Hub.Providers[0] != "together" {
		t.Fatalf("nur aktive Anbieter erwartet, got %+v", detail.Hub.Providers)
	}
}

func TestModelDetailReturns404WhenNowhereKnown(t *testing.T) {
	t.Parallel()

	hub := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer hub.Close()

	module := newTestModule(t)
	module.endpoints.hub = hub.URL
	module.client = hub.Client()
	app := newTestApp(t, module)

	if code := getJSON(t, app, "/api/benchmark/model?id=ghost/model", nil); code != http.StatusNotFound {
		t.Fatalf("Status = %d, want 404", code)
	}
}

func TestCompareLimitsModelCount(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var response struct {
		Models []ModelDetail `json:"models"`
		Board  BoardInfo     `json:"board"`
	}
	ids := []string{"claude-opus-5", "qwen3-235b", "tinychat"}
	for i := 0; i < maxCompare; i++ {
		ids = append(ids, fmt.Sprintf("filler-%d", i))
	}
	getJSON(t, app, "/api/benchmark/compare?ids="+strings.Join(ids, ",")+"&hub=false", &response)
	if len(response.Models) != maxCompare {
		t.Fatalf("len(models) = %d, want %d", len(response.Models), maxCompare)
	}
	if response.Models[0].Best == nil {
		t.Fatal("erstes Vergleichsmodell ohne Eintrag")
	}
	if response.Board.Key != BoardArenaText {
		t.Fatalf("Board = %q", response.Board.Key)
	}
}

func TestCompareRequiresIDs(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))
	if code := getJSON(t, app, "/api/benchmark/compare", nil); code != http.StatusBadRequest {
		t.Fatalf("Status = %d, want 400", code)
	}
}

func TestOverviewSummarisesTheBoard(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var overview Overview
	getJSON(t, app, "/api/benchmark/overview", &overview)
	if overview.TotalModels != 3 || overview.TotalEntries != 3 {
		t.Fatalf("Kennzahlen falsch: %d Modelle, %d Eintraege", overview.TotalModels, overview.TotalEntries)
	}
	if len(overview.Board.Metrics) != len(arenaTextCategories) {
		t.Fatalf("len(Metrics) = %d", len(overview.Board.Metrics))
	}
	if len(overview.TopOverall) == 0 || overview.TopOverall[0].Name != "claude-opus-5" {
		t.Fatalf("Spitzenreiter fehlen: %+v", overview.TopOverall)
	}
	if len(overview.OrgShare) != 3 {
		t.Fatalf("Anbieteruebersicht = %+v", overview.OrgShare)
	}
	if len(overview.MetricStats) != len(arenaTextCategories) {
		t.Fatalf("Verteilungen unvollstaendig: %+v", overview.MetricStats)
	}
}

func TestOverviewSkipsMetricsWithoutMeasurements(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var overview Overview
	getJSON(t, app, "/api/benchmark/overview", &overview)
	if _, exists := overview.TopByMetric["coding"]; !exists {
		t.Fatal("gemessene Kategorie fehlt in der Bestenliste")
	}
	if _, exists := overview.TopByMetric["longer_query"]; exists {
		t.Fatal("Kategorie ohne einen einzigen Messwert sollte fehlen")
	}
}

func TestStatusReportsBoardState(t *testing.T) {
	t.Parallel()

	app := newTestApp(t, newTestModule(t))

	var status Status
	getJSON(t, app, "/api/benchmark/status", &status)
	if status.State != stateReady {
		t.Fatalf("State = %q, want ready", status.State)
	}
	if status.Source.Models != 3 {
		t.Fatalf("Source.Models = %d, want 3", status.Source.Models)
	}
	if status.Source.FetchedAt == "" || status.Source.PublishedAt != "2026-07-30" {
		t.Fatalf("Zeitangaben fehlen: %+v", status.Source)
	}
	if len(status.Boards) != 1 {
		t.Fatalf("Status nennt %d Boards", len(status.Boards))
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

func TestRefreshEndpointAcceptsTheBoard(t *testing.T) {
	t.Parallel()

	module := newTestModule(t)
	module.endpoints = endpoints{hub: "http://127.0.0.1:1"}
	app := newTestApp(t, module)

	res, err := app.Test(httptest.NewRequest(http.MethodPost, "/api/benchmark/refresh?board=arena_text", nil), 5000)
	if err != nil {
		t.Fatalf("POST refresh: %v", err)
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusAccepted {
		t.Fatalf("Status = %d, want 202", res.StatusCode)
	}

	body, _ := io.ReadAll(res.Body)
	if !strings.Contains(string(body), BoardArenaText) {
		t.Fatalf("Antwort nennt das Board nicht: %s", body)
	}
}
