package benchmark

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	benchmarkv1 "github.com/culpeohq/backend/gen/go/culpeostudio/benchmark/v1"
)

// newTestService calls the service directly, the way the other migrated
// modules test theirs: the interceptors it sits behind on a real listener are
// covered in internal/grpcmw.
func newTestService(t *testing.T) *grpcService {
	t.Helper()
	return &grpcService{module: newTestModule(t)}
}

func requireCode(t *testing.T, err error, want codes.Code) {
	t.Helper()

	if err == nil {
		t.Fatalf("erwartet %s, bekam keinen Fehler", want)
	}
	if got := status.Code(err); got != want {
		t.Fatalf("Statuscode = %s, want %s (%v)", got, want, err)
	}
}

func TestListBoardsDescribesTheSource(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	response, err := service.ListBoards(context.Background(), &benchmarkv1.ListBoardsRequest{})
	if err != nil {
		t.Fatalf("ListBoards: %v", err)
	}
	if len(response.GetBoards()) != 1 || response.GetDefaultBoard() != DefaultBoard {
		t.Fatalf("unerwartete Ranglisten: %+v (default %q)", response.GetBoards(), response.GetDefaultBoard())
	}

	arena := response.GetBoards()[0]
	if arena.GetKey() != BoardArenaText {
		t.Fatalf("Key = %q", arena.GetKey())
	}
	if !arena.GetSource().GetLive() || arena.GetSource().GetArchived() {
		t.Fatalf("Arena muss als lebende Quelle gelten: %+v", arena.GetSource())
	}
	if arena.GetScoreKind() != "elo" || arena.GetPrimaryLabel() != "Elo" {
		t.Fatalf("Arena-Darstellung falsch: %+v", arena)
	}
	if len(arena.GetMetrics()) != len(arenaTextCategories) {
		t.Fatalf("len(Metrics) = %d, want %d", len(arena.GetMetrics()), len(arenaTextCategories))
	}
	if arena.GetSource().GetState() != benchmarkv1.BoardState_BOARD_STATE_READY ||
		arena.GetSource().GetEntries() != 3 {
		t.Fatalf("Arena-Zustand falsch: %+v", arena.GetSource())
	}
}

func TestLeaderboardRanksByElo(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	page, err := service.GetLeaderboard(context.Background(), &benchmarkv1.GetLeaderboardRequest{})
	if err != nil {
		t.Fatalf("GetLeaderboard: %v", err)
	}
	if page.GetBoard().GetKey() != DefaultBoard {
		t.Fatalf("Board = %q, want %q", page.GetBoard().GetKey(), DefaultBoard)
	}
	if page.GetTotal() != 3 || page.GetItems()[0].GetName() != "claude-opus-5" {
		t.Fatalf("Rangliste falsch: %+v", page.GetItems())
	}

	// A board the registry does not know still answers with the default one,
	// so a stale bookmark keeps working.
	fallback, err := service.GetLeaderboard(context.Background(), &benchmarkv1.GetLeaderboardRequest{
		Board: "gibtsnicht",
	})
	if err != nil {
		t.Fatalf("GetLeaderboard mit unbekanntem Board: %v", err)
	}
	if fallback.GetBoard().GetKey() != DefaultBoard {
		t.Fatalf("Rueckfall-Board = %q", fallback.GetBoard().GetKey())
	}
}

func TestLeaderboardAppliesFiltersAndSorting(t *testing.T) {
	t.Parallel()

	service := newTestService(t)
	load := func(request *benchmarkv1.GetLeaderboardRequest) *benchmarkv1.GetLeaderboardResponse {
		t.Helper()
		page, err := service.GetLeaderboard(context.Background(), request)
		if err != nil {
			t.Fatalf("GetLeaderboard(%+v): %v", request, err)
		}
		return page
	}

	openOnly := load(&benchmarkv1.GetLeaderboardRequest{OpenWeightsOnly: true})
	if openOnly.GetTotal() != 2 {
		t.Fatalf("nur offene Gewichte = %d, want 2", openOnly.GetTotal())
	}
	for _, item := range openOnly.GetItems() {
		if !item.GetOpenWeights() {
			t.Fatalf("geschlossenes Modell im Ergebnis: %+v", item)
		}
	}

	// The comma-joined parameter is gone: each value travels on its own.
	byOrg := load(&benchmarkv1.GetLeaderboardRequest{Orgs: []string{"alibaba"}})
	if byOrg.GetTotal() != 1 || byOrg.GetItems()[0].GetName() != "qwen3-235b" {
		t.Fatalf("Anbieterfilter lieferte %+v", byOrg.GetItems())
	}

	byMath := load(&benchmarkv1.GetLeaderboardRequest{Sort: "math"})
	if byMath.GetItems()[0].GetName() != "claude-opus-5" || byMath.GetSort() != "math" {
		t.Fatalf("Sortierung nach Math lieferte %q (sort=%q)", byMath.GetItems()[0].GetName(), byMath.GetSort())
	}

	ascending := load(&benchmarkv1.GetLeaderboardRequest{Order: benchmarkv1.SortOrder_SORT_ORDER_ASC})
	if ascending.GetItems()[0].GetName() != "tinychat" {
		t.Fatalf("aufsteigende Sortierung lieferte %q zuerst", ascending.GetItems()[0].GetName())
	}
	if ascending.GetOrder() != benchmarkv1.SortOrder_SORT_ORDER_ASC {
		t.Fatalf("Order = %v, want ASC", ascending.GetOrder())
	}

	// An unset order is descending, which is what every board opens with.
	unset := load(&benchmarkv1.GetLeaderboardRequest{})
	if unset.GetOrder() != benchmarkv1.SortOrder_SORT_ORDER_DESC {
		t.Fatalf("unbestellte Order = %v, want DESC", unset.GetOrder())
	}
}

// best_per_model defaults to true, so an omitted flag must not start showing
// every duplicate entry of a model. Only an explicit false does that, which is
// why the field is optional rather than a plain bool.
func TestLeaderboardKeepsBestPerModelUnlessTurnedOff(t *testing.T) {
	t.Parallel()

	module := newTestModule(t)
	// A second entry for a model the board already ranks, which is exactly
	// what best-per-model collapses.
	duplicate := arenaFixture()[0]
	duplicate.Primary = 1400
	duplicate.Key = "claude-opus-5-preview"
	module.replaceEntries(BoardArenaText, append(arenaFixture(), duplicate),
		time.Date(2026, 7, 30, 12, 0, 0, 0, time.UTC), "2026-07-30", true)
	service := &grpcService{module: module}

	byDefault, err := service.GetLeaderboard(context.Background(), &benchmarkv1.GetLeaderboardRequest{})
	if err != nil {
		t.Fatalf("GetLeaderboard: %v", err)
	}
	if byDefault.GetTotal() != 3 {
		t.Fatalf("ohne Angabe = %d Eintraege, want 3 (nur der beste je Modell)", byDefault.GetTotal())
	}

	turnedOff := false
	all, err := service.GetLeaderboard(context.Background(), &benchmarkv1.GetLeaderboardRequest{
		BestPerModel: &turnedOff,
	})
	if err != nil {
		t.Fatalf("GetLeaderboard(best_per_model=false): %v", err)
	}
	if all.GetTotal() != 4 {
		t.Fatalf("ausdrueckliches false = %d Eintraege, want 4", all.GetTotal())
	}
}

func TestLeaderboardRejectsUnknownSortKey(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	page, err := service.GetLeaderboard(context.Background(), &benchmarkv1.GetLeaderboardRequest{
		Sort: "; DROP TABLE",
	})
	if err != nil {
		t.Fatalf("GetLeaderboard: %v", err)
	}
	if page.GetSort() != primaryKey {
		t.Fatalf("Sort = %q, want %q als Rueckfall", page.GetSort(), primaryKey)
	}
}

func TestLeaderboardLimitIsCapped(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	page, err := service.GetLeaderboard(context.Background(), &benchmarkv1.GetLeaderboardRequest{
		Limit: 100000,
	})
	if err != nil {
		t.Fatalf("GetLeaderboard: %v", err)
	}
	if page.GetLimit() != maxLimit {
		t.Fatalf("Limit = %d, want %d", page.GetLimit(), maxLimit)
	}
}

func TestModelDetailReportsRanksAndPeers(t *testing.T) {
	t.Parallel()

	service := newTestService(t)
	withoutHub := false

	response, err := service.GetModel(context.Background(), &benchmarkv1.GetModelRequest{
		Id:      "CLAUDE-opus-5",
		WithHub: &withoutHub,
	})
	if err != nil {
		t.Fatalf("GetModel: %v", err)
	}

	detail := response.GetDetail()
	if detail.GetName() != "claude-opus-5" {
		t.Fatalf("Name = %q, want die Schreibweise der Quelle", detail.GetName())
	}
	if detail.GetBest() == nil || detail.GetBest().GetPrimary() != 1511.6 {
		t.Fatalf("Best = %+v", detail.GetBest())
	}
	if detail.GetMetricRanks()["coding"] != 1 {
		t.Fatalf("Coding-Rang = %d, want 1", detail.GetMetricRanks()["coding"])
	}
	if rank, exists := detail.GetMetricRanks()["hard_prompts"]; exists {
		t.Fatalf("unbewertete Kategorie meldet Platz %d", rank)
	}
	if detail.GetDeltas()[primaryKey].GetDiff() == 0 {
		t.Fatalf("Delta zum Median fehlt: %+v", detail.GetDeltas()[primaryKey])
	}
	if detail.GetPercentile() <= 0 || detail.GetPercentile() > 100 {
		t.Fatalf("Percentile = %v", detail.GetPercentile())
	}
	if len(detail.GetPeers()) != 2 {
		t.Fatalf("len(Peers) = %d, want 2", len(detail.GetPeers()))
	}
	if len(detail.GetMetrics()) != len(arenaTextCategories) {
		t.Fatalf("Detail ohne Wertungsbeschreibung: %+v", detail.GetMetrics())
	}
	if detail.GetScoreKind() != "elo" {
		t.Fatalf("ScoreKind = %q", detail.GetScoreKind())
	}
}

func TestModelDetailRequiresID(t *testing.T) {
	t.Parallel()

	service := newTestService(t)
	_, err := service.GetModel(context.Background(), &benchmarkv1.GetModelRequest{})
	requireCode(t, err, codes.InvalidArgument)
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
	service := &grpcService{module: module}

	response, err := service.GetModel(context.Background(), &benchmarkv1.GetModelRequest{
		Id: "claude-opus-5",
	})
	if err != nil {
		t.Fatalf("GetModel: %v", err)
	}
	if calls != 0 {
		t.Fatalf("Hub wurde %d mal fuer einen Anzeigenamen befragt", calls)
	}
	if response.GetDetail().GetBest() == nil || response.GetDetail().GetBest().GetPrimary() != 1511.6 {
		t.Fatalf("Arena-Eintrag fehlt: %+v", response.GetDetail().GetBest())
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
	service := &grpcService{module: module}

	response, err := service.GetModel(context.Background(), &benchmarkv1.GetModelRequest{Id: "brand/new"})
	if err != nil {
		t.Fatalf("GetModel: %v", err)
	}

	detail := response.GetDetail()
	// The JSON had to spell out an empty array here so the client would not
	// trip over a null; a repeated field is empty by construction.
	if len(detail.GetEntries()) != 0 {
		t.Fatalf("Board kennt das Modell nicht, meldet aber Eintraege: %+v", detail.GetEntries())
	}
	if detail.GetHub() == nil || detail.GetHub().GetLikes() != 42 ||
		detail.GetHub().GetParamsTotal() != 8030000000 {
		t.Fatalf("Hub-Zahlen fehlen: %+v", detail.GetHub())
	}
	if len(detail.GetHub().GetInferenceProviders()) != 1 ||
		detail.GetHub().GetInferenceProviders()[0] != "together" {
		t.Fatalf("nur aktive Anbieter erwartet, got %+v", detail.GetHub().GetInferenceProviders())
	}
}

func TestModelDetailIsNotFoundWhenNowhereKnown(t *testing.T) {
	t.Parallel()

	hub := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer hub.Close()

	module := newTestModule(t)
	module.endpoints.hub = hub.URL
	module.client = hub.Client()
	service := &grpcService{module: module}

	_, err := service.GetModel(context.Background(), &benchmarkv1.GetModelRequest{Id: "ghost/model"})
	requireCode(t, err, codes.NotFound)
}

func TestCompareLimitsModelCount(t *testing.T) {
	t.Parallel()

	service := newTestService(t)
	withoutHub := false

	ids := []string{"claude-opus-5", "qwen3-235b", "tinychat"}
	for i := 0; i < maxCompare; i++ {
		ids = append(ids, fmt.Sprintf("filler-%d", i))
	}

	response, err := service.CompareModels(context.Background(), &benchmarkv1.CompareModelsRequest{
		Ids:     ids,
		WithHub: &withoutHub,
	})
	if err != nil {
		t.Fatalf("CompareModels: %v", err)
	}
	if len(response.GetModels()) != maxCompare {
		t.Fatalf("len(models) = %d, want %d", len(response.GetModels()), maxCompare)
	}
	if response.GetModels()[0].GetBest() == nil {
		t.Fatal("erstes Vergleichsmodell ohne Eintrag")
	}
	if response.GetBoard().GetKey() != BoardArenaText {
		t.Fatalf("Board = %q", response.GetBoard().GetKey())
	}
}

func TestCompareRequiresIDs(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	_, err := service.CompareModels(context.Background(), &benchmarkv1.CompareModelsRequest{})
	requireCode(t, err, codes.InvalidArgument)

	// Blank entries are dropped before the count is taken, so a list of them
	// is as empty as none at all.
	_, blankErr := service.CompareModels(context.Background(), &benchmarkv1.CompareModelsRequest{
		Ids: []string{"", "   "},
	})
	requireCode(t, blankErr, codes.InvalidArgument)
}

func TestOverviewSummarisesTheBoard(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	overview, err := service.GetOverview(context.Background(), &benchmarkv1.GetOverviewRequest{})
	if err != nil {
		t.Fatalf("GetOverview: %v", err)
	}
	if overview.GetTotalModels() != 3 || overview.GetTotalEntries() != 3 {
		t.Fatalf("Kennzahlen falsch: %d Modelle, %d Eintraege",
			overview.GetTotalModels(), overview.GetTotalEntries())
	}
	if len(overview.GetBoard().GetMetrics()) != len(arenaTextCategories) {
		t.Fatalf("len(Metrics) = %d", len(overview.GetBoard().GetMetrics()))
	}
	if len(overview.GetTopOverall()) == 0 || overview.GetTopOverall()[0].GetName() != "claude-opus-5" {
		t.Fatalf("Spitzenreiter fehlen: %+v", overview.GetTopOverall())
	}
	if len(overview.GetOrgShare()) != 3 {
		t.Fatalf("Anbieteruebersicht = %+v", overview.GetOrgShare())
	}
	if len(overview.GetMetricStats()) != len(arenaTextCategories) {
		t.Fatalf("Verteilungen unvollstaendig: %+v", overview.GetMetricStats())
	}
}

func TestOverviewSkipsMetricsWithoutMeasurements(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	overview, err := service.GetOverview(context.Background(), &benchmarkv1.GetOverviewRequest{})
	if err != nil {
		t.Fatalf("GetOverview: %v", err)
	}
	if _, exists := overview.GetTopByMetric()["coding"]; !exists {
		t.Fatal("gemessene Kategorie fehlt in der Bestenliste")
	}
	if _, exists := overview.GetTopByMetric()["longer_query"]; exists {
		t.Fatal("Kategorie ohne einen einzigen Messwert sollte fehlen")
	}
}

func TestStatusReportsBoardState(t *testing.T) {
	t.Parallel()

	service := newTestService(t)

	response, err := service.GetStatus(context.Background(), &benchmarkv1.GetStatusRequest{})
	if err != nil {
		t.Fatalf("GetStatus: %v", err)
	}
	if response.GetState() != benchmarkv1.BoardState_BOARD_STATE_READY {
		t.Fatalf("State = %v, want READY", response.GetState())
	}
	if response.GetSource().GetModels() != 3 {
		t.Fatalf("Source.Models = %d, want 3", response.GetSource().GetModels())
	}
	if response.GetSource().GetFetchedAt() == "" ||
		response.GetSource().GetPublishedAt() != "2026-07-30" {
		t.Fatalf("Zeitangaben fehlen: %+v", response.GetSource())
	}
	if len(response.GetBoards()) != 1 {
		t.Fatalf("Status nennt %d Boards", len(response.GetBoards()))
	}
}

func TestRefreshAcceptsTheBoard(t *testing.T) {
	t.Parallel()

	module := newTestModule(t)
	module.endpoints = endpoints{hub: "http://127.0.0.1:1"}
	service := &grpcService{module: module}

	response, err := service.RefreshBoards(context.Background(), &benchmarkv1.RefreshBoardsRequest{
		Board: BoardArenaText,
	})
	if err != nil {
		t.Fatalf("RefreshBoards: %v", err)
	}
	if len(response.GetBoards()) != 1 || response.GetBoards()[0] != BoardArenaText {
		t.Fatalf("Antwort nennt das Board nicht: %+v", response.GetBoards())
	}
}

// An unknown board refreshes everything rather than nothing, which is what the
// query parameter did.
func TestRefreshWithoutBoardCoversAll(t *testing.T) {
	t.Parallel()

	module := newTestModule(t)
	module.endpoints = endpoints{hub: "http://127.0.0.1:1"}
	service := &grpcService{module: module}

	response, err := service.RefreshBoards(context.Background(), &benchmarkv1.RefreshBoardsRequest{})
	if err != nil {
		t.Fatalf("RefreshBoards: %v", err)
	}
	if len(response.GetBoards()) != len(BoardOrder) {
		t.Fatalf("Antwort nennt %d Boards, want %d", len(response.GetBoards()), len(BoardOrder))
	}
}
