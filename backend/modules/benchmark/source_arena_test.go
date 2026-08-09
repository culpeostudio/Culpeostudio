package benchmark

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"github.com/parquet-go/parquet-go"
)

func arenaRowFor(model, org, license, category string, rating float64) arenaRow {
	return arenaRow{
		Model:     model,
		Org:       org,
		License:   license,
		Category:  category,
		Rating:    rating,
		Lower:     rating - 8,
		Upper:     rating + 8,
		Variance:  40.4,
		Votes:     2386,
		Rank:      1,
		Published: "2026-07-30",
	}
}

type arenaHub struct {
	*httptest.Server

	mu    sync.Mutex
	calls int
}

func (h *arenaHub) requests() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.calls
}

func newArenaHub(t *testing.T, rows []arenaRow, shards int) *arenaHub {
	t.Helper()
	if shards < 1 {
		shards = 1
	}

	files := make(map[string][]byte, shards)
	tree := make([]treeEntry, 0, shards)
	for shard := 0; shard < shards; shard++ {
		part := make([]arenaRow, 0, len(rows))
		for i := shard; i < len(rows); i += shards {
			part = append(part, rows[i])
		}
		var buffer bytes.Buffer
		if err := parquet.Write(&buffer, part); err != nil {
			t.Fatalf("Parquet schreiben: %v", err)
		}
		path := fmt.Sprintf("%s/%s-%05d-of-%05d.parquet", arenaConfig, arenaSplit, shard, shards)
		files[path] = buffer.Bytes()
		tree = append(tree, treeEntry{Type: "file", Path: path, Size: int64(buffer.Len())})
	}

	tree = append(tree, treeEntry{Type: "file", Path: arenaConfig + "/full-00000-of-00001.parquet", Size: 1})

	hub := &arenaHub{}
	hub.Server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hub.mu.Lock()
		hub.calls++
		hub.mu.Unlock()

		if strings.HasPrefix(r.URL.Path, "/api/datasets/") && strings.Contains(r.URL.Path, "/tree/") {
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(tree)
			return
		}
		for path, payload := range files {
			if strings.HasSuffix(r.URL.Path, "/"+path) {
				_, _ = w.Write(payload)
				return
			}
		}
		w.WriteHeader(http.StatusNotFound)
	}))
	t.Cleanup(hub.Close)
	return hub
}

func fetchArenaFrom(t *testing.T, hub *arenaHub) ([]Entry, string, error) {
	t.Helper()
	return fetchArena(context.Background(), hub.Client(), endpoints{hub: hub.URL}, "")
}

func TestFetchArenaFillsEveryCategoryInOneRequest(t *testing.T) {
	t.Parallel()

	rows := []arenaRow{arenaRowFor("claude-opus-5", "anthropic", "Proprietary", arenaPrimaryCategory, 1511.6)}
	for i, category := range arenaTextCategories {
		rows = append(rows, arenaRowFor("claude-opus-5", "anthropic", "Proprietary",
			category.Key, 1400+float64(i)))
	}
	hub := newArenaHub(t, rows, 1)

	entries, _, err := fetchArenaFrom(t, hub)
	if err != nil {
		t.Fatalf("fetchArena() error = %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("len(entries) = %d, want 1", len(entries))
	}
	for i, category := range arenaTextCategories {
		if got := entries[0].ScoreOf(category.Key); got != 1400+float64(i) {
			t.Errorf("Wertung %q = %v, want %v", category.Key, got, 1400+float64(i))
		}
	}

	if hub.requests() != 2 {
		t.Fatalf("%d Anfragen an den Hub, want 2", hub.requests())
	}
}

func TestFetchArenaReadsEveryShard(t *testing.T) {
	t.Parallel()

	rows := []arenaRow{
		arenaRowFor("claude-opus-5", "anthropic", "Proprietary", arenaPrimaryCategory, 1511.6),
		arenaRowFor("qwen3-235b", "alibaba", "Apache 2.0", arenaPrimaryCategory, 1402.1),
		arenaRowFor("claude-opus-5", "anthropic", "Proprietary", "coding", 1530.0),
		arenaRowFor("qwen3-235b", "alibaba", "Apache 2.0", "math", 1450.0),
	}
	hub := newArenaHub(t, rows, 3)

	entries, _, err := fetchArenaFrom(t, hub)
	if err != nil {
		t.Fatalf("fetchArena() error = %v", err)
	}
	if len(entries) != 2 {
		t.Fatalf("len(entries) = %d, want 2", len(entries))
	}
	byName := map[string]Entry{}
	for _, entry := range entries {
		byName[entry.Name] = entry
	}
	if byName["claude-opus-5"].ScoreOf("coding") != 1530 {
		t.Fatalf("Wertung aus einer anderen Datei fehlt: %+v", byName["claude-opus-5"].Scores)
	}
	if byName["qwen3-235b"].ScoreOf("math") != 1450 {
		t.Fatalf("Wertung aus einer anderen Datei fehlt: %+v", byName["qwen3-235b"].Scores)
	}
}

func TestFetchArenaKeepsTheBoardWhenACategoryIsGone(t *testing.T) {
	t.Parallel()

	hub := newArenaHub(t, []arenaRow{
		arenaRowFor("claude-opus-5", "anthropic", "Proprietary", arenaPrimaryCategory, 1511.6),
		arenaRowFor("claude-opus-5", "anthropic", "Proprietary", "creative_writing", 1500.0),
	}, 1)

	entries, _, err := fetchArenaFrom(t, hub)
	if err != nil {
		t.Fatalf("fetchArena() error = %v", err)
	}
	if len(entries) != 1 || entries[0].Primary != 1511.6 {
		t.Fatalf("Hauptwertung verloren: %+v", entries)
	}
	if entries[0].ScoreOf("creative_writing") != 1500 {
		t.Fatalf("vorhandene Wertung fehlt: %+v", entries[0].Scores)
	}

	if _, present := entries[0].Scores["coding"]; present {
		t.Fatalf("fehlende Wertung wurde erfunden: %+v", entries[0].Scores)
	}
}

func TestFetchArenaReadsColumnsAndOrigin(t *testing.T) {
	t.Parallel()

	hub := newArenaHub(t, []arenaRow{
		arenaRowFor("claude-opus-5", "anthropic", "Proprietary", arenaPrimaryCategory, 1511.6),
		arenaRowFor("qwen3-235b", "alibaba", "Apache 2.0", arenaPrimaryCategory, 1402.1),

		arenaRowFor("unbekannt/modell", "x", "MIT", "coding", 1200.0),
	}, 1)

	entries, published, err := fetchArenaFrom(t, hub)
	if err != nil {
		t.Fatalf("fetchArena() error = %v", err)
	}
	if published != "2026-07-30" {
		t.Fatalf("published = %q", published)
	}
	if len(entries) != 2 {
		t.Fatalf("len(entries) = %d, want 2 (nur Modelle der Gesamtwertung)", len(entries))
	}

	byName := map[string]Entry{}
	for _, entry := range entries {
		byName[entry.Name] = entry
	}

	opus := byName["claude-opus-5"]
	if opus.Primary != 1511.6 || opus.Board != BoardArenaText || opus.EvalDate != "2026-07-30" {
		t.Fatalf("Spalten falsch gelesen: %+v", opus)
	}
	if opus.OpenWeights || opus.Type != "proprietary" {
		t.Fatalf("geschlossenes Modell falsch eingeordnet: %+v", opus)
	}
	details := detailMap(opus)
	if details["votes"] != "2386" || details["variance"] != "40.4" ||
		!strings.Contains(details["confidence"], "–") {
		t.Fatalf("Arena-Details fehlen: %+v", details)
	}

	qwen := byName["qwen3-235b"]
	if !qwen.OpenWeights || qwen.Type != "open_weights" {
		t.Fatalf("offenes Modell falsch eingeordnet: %+v", qwen)
	}
	if qwen.ScoreOf("coding") != 0 {
		t.Fatalf("fehlende Kategorie sollte 0 bleiben, ist %v", qwen.ScoreOf("coding"))
	}
}

func TestFetchArenaFailsWithoutOverall(t *testing.T) {
	t.Parallel()

	hub := newArenaHub(t, []arenaRow{
		arenaRowFor("claude-opus-5", "anthropic", "Proprietary", "coding", 1530.0),
	}, 1)

	if _, _, err := fetchArenaFrom(t, hub); err == nil {
		t.Fatal("fetchArena() lieferte keinen Fehler, obwohl die Gesamtwertung fehlt")
	}
}

func TestIsOpenLicenseSeparatesProprietaryModels(t *testing.T) {
	t.Parallel()

	if isOpenLicense("Proprietary") || isOpenLicense("proprietary") || isOpenLicense("") {
		t.Fatal("geschlossene Lizenzen wurden als offen gewertet")
	}
	for _, license := range []string{"Apache 2.0", "MIT", "Llama 3.1 Community", "Gemma"} {
		if !isOpenLicense(license) {
			t.Fatalf("%q sollte als offen gelten", license)
		}
	}
}

func detailMap(entry Entry) map[string]string {
	result := make(map[string]string, len(entry.Details))
	for _, detail := range entry.Details {
		result[detail.Key] = detail.Value
	}
	return result
}
