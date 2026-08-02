package benchmark

import "testing"

func TestFilterCombinesConstraints(t *testing.T) {
	t.Parallel()

	entries := arenaFixture()
	if got := filter(entries, Query{}); len(got) != 3 {
		t.Fatalf("ohne Filter %d Eintraege, want 3", len(got))
	}

	open := filter(entries, Query{OpenWeightsOnly: true})
	if len(open) != 2 {
		t.Fatalf("nur offene Gewichte = %d, want 2", len(open))
	}

	byType := filter(entries, Query{Types: []string{"proprietary"}})
	if len(byType) != 1 || byType[0].Name != "claude-opus-5" {
		t.Fatalf("Typfilter lieferte %+v", byType)
	}

	byOrgAndType := filter(entries, Query{Orgs: []string{"alibaba"}, Types: []string{"open_weights"}})
	if len(byOrgAndType) != 1 || byOrgAndType[0].Name != "qwen3-235b" {
		t.Fatalf("kombinierter Filter lieferte %+v", byOrgAndType)
	}
}

func TestFilterSearchMatchesEveryToken(t *testing.T) {
	t.Parallel()

	entries := arenaFixture()
	if got := filter(entries, Query{Search: "claude opus"}); len(got) != 1 {
		t.Fatalf("Suche nach zwei Begriffen fand %d Eintraege, want 1", len(got))
	}
	if got := filter(entries, Query{Search: "claude winzig"}); len(got) != 0 {
		t.Fatalf("Suche fand %d Eintraege, obwohl ein Begriff nicht passt", len(got))
	}
	if got := filter(entries, Query{Search: "anthropic"}); len(got) != 1 {
		t.Fatalf("Anbietersuche fand %d Eintraege, want 1", len(got))
	}
	if got := filter(entries, Query{Search: "2386"}); len(got) != 1 {
		t.Fatalf("Suche in den Detailangaben fand %d Eintraege, want 1", len(got))
	}
}

func TestKeepBestPerModelKeepsStrongestEntry(t *testing.T) {
	t.Parallel()

	entries := append(arenaFixture(), Entry{
		Board: BoardArenaText, Key: "claude-opus-5", Name: "claude-opus-5",
		Org: "anthropic", Primary: 1400, Scores: map[string]float64{},
	})

	result := keepBestPerModel(entries)
	if len(result) != 3 {
		t.Fatalf("len(result) = %d, want 3", len(result))
	}
	for _, entry := range result {
		if entry.Name == "claude-opus-5" && entry.Primary != 1511.6 {
			t.Fatalf("schwaecherer Eintrag gewann: %+v", entry)
		}
	}
}

func TestSortEntriesByMetricAndDirection(t *testing.T) {
	t.Parallel()

	entries := arenaFixture()
	sortEntries(entries, "math", "desc")
	if entries[0].Name != "claude-opus-5" {
		t.Fatalf("Sortierung nach Math lieferte %q zuerst", entries[0].Name)
	}

	sortEntries(entries, primaryKey, "asc")
	if entries[0].Name != "tinychat" {
		t.Fatalf("aufsteigende Sortierung lieferte %q zuerst", entries[0].Name)
	}

	sortEntries(entries, "name", "asc")
	if entries[0].Name != "claude-opus-5" {
		t.Fatalf("Namenssortierung lieferte %q zuerst", entries[0].Name)
	}
}

func TestIsSortableChecksTheBoardsOwnMetrics(t *testing.T) {
	t.Parallel()

	metrics := arenaMetrics(arenaTextCategories)
	for _, key := range []string{"", primaryKey, "average", "name", "coding", "math"} {
		if !isSortable(key, metrics) {
			t.Fatalf("isSortable(%q) = false", key)
		}
	}
	for _, key := range []string{"drop table", "ifeval", "params"} {
		if isSortable(key, metrics) {
			t.Fatalf("isSortable(%q) = true, obwohl die Wertung fehlt", key)
		}
	}
}

func TestAssignRanksOrdersByPrimaryScore(t *testing.T) {
	t.Parallel()

	entries := arenaFixture()
	assignRanks(entries)

	ranks := map[string]int{}
	for _, entry := range entries {
		ranks[entry.Name] = entry.Rank
	}
	if ranks["claude-opus-5"] != 1 || ranks["qwen3-235b"] != 2 || ranks["tinychat"] != 3 {
		t.Fatalf("unerwartete Raenge: %+v", ranks)
	}
}

func TestPaginateStaysInsideBounds(t *testing.T) {
	t.Parallel()

	entries := arenaFixture()
	if got := paginate(entries, 0, 2); len(got) != 2 {
		t.Fatalf("len = %d, want 2", len(got))
	}
	if got := paginate(entries, 2, 10); len(got) != 1 {
		t.Fatalf("len = %d, want 1", len(got))
	}
	if got := paginate(entries, 99, 10); len(got) != 0 {
		t.Fatalf("Offset hinter dem Ende lieferte %d Eintraege", len(got))
	}
}

func TestBuildFacetsCountsValues(t *testing.T) {
	t.Parallel()

	facets := buildFacets(arenaFixture())

	total := 0
	for _, value := range facets.Types {
		total += value.Count
	}
	if total != 3 {
		t.Fatalf("Facetten zaehlten %d Eintraege, want 3", total)
	}
	if len(facets.Orgs) != 3 || len(facets.Licenses) != 3 {
		t.Fatalf("Anbieter-/Lizenzfacetten falsch: %+v / %+v", facets.Orgs, facets.Licenses)
	}
}

func TestComputeMetricStatsIgnoresUnscoredModels(t *testing.T) {
	t.Parallel()

	stats := computeMetricStats(arenaFixture(), arenaMetrics(arenaTextCategories))

	byKey := map[string]MetricStats{}
	for _, stat := range stats {
		byKey[stat.Key] = stat
	}

	coding := byKey["coding"]
	if coding.Evaluated != 3 || coding.Max != 1530 || coding.Min != 1150 {
		t.Fatalf("Coding-Verteilung falsch: %+v", coding)
	}
	if coding.TopModel != "claude-opus-5" {
		t.Fatalf("TopModel = %q", coding.TopModel)
	}

	math := byKey["math"]
	if math.Evaluated != 2 || math.Median != 1470 {
		t.Fatalf("Math-Verteilung falsch: %+v", math)
	}

	empty := byKey["longer_query"]
	if empty.Evaluated != 0 || empty.Min != 0 || empty.Max != 0 {
		t.Fatalf("leere Kategorie = %+v", empty)
	}
}
