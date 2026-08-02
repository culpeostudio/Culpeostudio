package news

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
)

func newTestSavedStore(t *testing.T) (*SavedStore, string) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "news_saved.json")
	store := NewSavedStore(path)
	if err := store.Load(); err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	return store, path
}

func sampleItem(id string) NewsItem {
	return NewsItem{
		ID:       id,
		Title:    "Speicherkrise verschärft sich",
		Content:  "Speicher könnte nächstes Jahr teurer werden.",
		Author:   "heise online",
		Category: "Hardware",
		Tags:     []string{"heise", "Tech"},
		URL:      "https://www.heise.de/news/" + id,
	}
}

func TestSavedStoreKeepsUsersApart(t *testing.T) {
	store, _ := newTestSavedStore(t)

	if _, err := store.Save("anna", sampleItem("heise-1"), time.Now()); err != nil {
		t.Fatalf("Save(anna) error = %v", err)
	}
	if _, err := store.Save("bert", sampleItem("golem-1"), time.Now()); err != nil {
		t.Fatalf("Save(bert) error = %v", err)
	}

	anna := store.List("anna")
	if len(anna) != 1 || anna[0].ID != "heise-1" {
		t.Fatalf("List(anna) = %+v, want nur heise-1", anna)
	}
	bert := store.List("bert")
	if len(bert) != 1 || bert[0].ID != "golem-1" {
		t.Fatalf("List(bert) = %+v, want nur golem-1", bert)
	}
	if len(store.List("carla")) != 0 {
		t.Fatal("List(carla) liefert Eintraege, obwohl nichts gespeichert wurde")
	}
}

func TestSavedStoreSurvivesReload(t *testing.T) {
	store, path := newTestSavedStore(t)
	if _, err := store.Save("anna", sampleItem("heise-1"), time.Now()); err != nil {
		t.Fatalf("Save() error = %v", err)
	}

	reloaded := NewSavedStore(path)
	if err := reloaded.Load(); err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	articles := reloaded.List("anna")
	if len(articles) != 1 {
		t.Fatalf("len(articles) = %d, want 1", len(articles))
	}
	if articles[0].Title != "Speicherkrise verschärft sich" {
		t.Fatalf("Title = %q", articles[0].Title)
	}
	if articles[0].SavedAt.IsZero() {
		t.Fatal("SavedAt ist leer, want Zeitstempel")
	}

	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("Stat() error = %v", err)
	}
	if mode := info.Mode().Perm(); mode != 0o600 {
		t.Fatalf("Dateirechte = %o, want 600", mode)
	}
}

func TestSavedStoreSavesSameArticleOnlyOnce(t *testing.T) {
	store, _ := newTestSavedStore(t)
	first := time.Now().Add(-time.Hour)

	if _, err := store.Save("anna", sampleItem("heise-1"), first); err != nil {
		t.Fatalf("Save() error = %v", err)
	}
	if _, err := store.Save("anna", sampleItem("heise-1"), first.Add(time.Hour)); err != nil {
		t.Fatalf("Save() zweiter Aufruf error = %v", err)
	}

	articles := store.List("anna")
	if len(articles) != 1 {
		t.Fatalf("len(articles) = %d, want 1", len(articles))
	}
	if !articles[0].SavedAt.After(first) {
		t.Fatalf("SavedAt = %v, want aktualisiert", articles[0].SavedAt)
	}
}

func TestSavedStoreListsNewestFirst(t *testing.T) {
	store, _ := newTestSavedStore(t)
	base := time.Now().Add(-3 * time.Hour)

	for index, id := range []string{"a", "b", "c"} {
		when := base.Add(time.Duration(index) * time.Hour)
		if _, err := store.Save("anna", sampleItem(id), when); err != nil {
			t.Fatalf("Save(%s) error = %v", id, err)
		}
	}

	articles := store.List("anna")
	if len(articles) != 3 {
		t.Fatalf("len(articles) = %d, want 3", len(articles))
	}
	if articles[0].ID != "c" || articles[2].ID != "a" {
		t.Fatalf("Reihenfolge = %s,%s,%s, want c,b,a", articles[0].ID, articles[1].ID, articles[2].ID)
	}
}

func TestSavedStoreRejectsIncompleteArticle(t *testing.T) {
	store, _ := newTestSavedStore(t)

	if _, err := store.Save("anna", NewsItem{Title: "Ohne ID"}, time.Now()); err == nil {
		t.Fatal("Save() ohne ID akzeptiert, want Fehler")
	}
	if _, err := store.Save("anna", NewsItem{ID: "ohne-titel"}, time.Now()); err == nil {
		t.Fatal("Save() ohne Titel akzeptiert, want Fehler")
	}
}

func TestSavedStoreStripsMarkupFromArticle(t *testing.T) {
	store, _ := newTestSavedStore(t)
	item := sampleItem("heise-1")
	item.Title = "<b>Fetter</b> Titel"
	item.Content = "<script>alert(1)</script>Text"

	if _, err := store.Save("anna", item, time.Now()); err != nil {
		t.Fatalf("Save() error = %v", err)
	}
	articles := store.List("anna")
	if articles[0].Title != "Fetter Titel" {
		t.Fatalf("Title = %q", articles[0].Title)
	}
	if articles[0].Content != "alert(1) Text" {
		t.Fatalf("Content = %q", articles[0].Content)
	}
}

func TestSavedStoreDeleteReportsWhetherArticleWasStored(t *testing.T) {
	store, _ := newTestSavedStore(t)
	if _, err := store.Save("anna", sampleItem("heise-1"), time.Now()); err != nil {
		t.Fatalf("Save() error = %v", err)
	}

	removed, err := store.Delete("anna", "heise-1")
	if err != nil {
		t.Fatalf("Delete() error = %v", err)
	}
	if !removed {
		t.Fatal("Delete() = false, want true")
	}
	if len(store.List("anna")) != 0 {
		t.Fatal("Merkliste ist nach dem Loeschen nicht leer")
	}

	removed, err = store.Delete("anna", "heise-1")
	if err != nil {
		t.Fatalf("Delete() zweiter Aufruf error = %v", err)
	}
	if removed {
		t.Fatal("Delete() = true fuer nicht gemerkten Beitrag")
	}
}

func newSavedTestApp(t *testing.T) (*NewsModule, *fiber.App) {
	t.Helper()
	module := New(filepath.Join(t.TempDir(), "news_saved.json"))
	if err := module.saved.Load(); err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	app := fiber.New()
	api := app.Group("/api", func(c *fiber.Ctx) error {

		if user := c.Get("X-Test-User"); user != "" {
			c.Locals("user_id", strings.Clone(user))
		}
		return c.Next()
	})
	module.RegisterRoutes(api)
	return module, app
}

func savedRequest(t *testing.T, app *fiber.App, method, path, user string, body any) *http.Response {
	t.Helper()
	var payload *bytes.Reader
	if body == nil {
		payload = bytes.NewReader(nil)
	} else {
		encoded, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("Marshal() error = %v", err)
		}
		payload = bytes.NewReader(encoded)
	}

	req := httptest.NewRequest(method, path, payload)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if user != "" {
		req.Header.Set("X-Test-User", user)
	}
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Test(%s %s) error = %v", method, path, err)
	}
	return resp
}

func decodeSavedArticles(t *testing.T, resp *http.Response) []SavedArticle {
	t.Helper()
	defer resp.Body.Close()
	var articles []SavedArticle
	if err := json.NewDecoder(resp.Body).Decode(&articles); err != nil {
		t.Fatalf("Decode() error = %v", err)
	}
	return articles
}

func TestSavedRoutesKeepListsPerUser(t *testing.T) {
	_, app := newSavedTestApp(t)

	resp := savedRequest(t, app, http.MethodPost, "/api/news/saved", "anna", sampleItem("heise-1"))
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("POST /saved status = %d, want 201", resp.StatusCode)
	}
	resp.Body.Close()

	anna := decodeSavedArticles(t, savedRequest(t, app, http.MethodGet, "/api/news/saved", "anna", nil))
	if len(anna) != 1 || anna[0].ID != "heise-1" {
		t.Fatalf("Merkliste von anna = %+v", anna)
	}

	bert := decodeSavedArticles(t, savedRequest(t, app, http.MethodGet, "/api/news/saved", "bert", nil))
	if len(bert) != 0 {
		t.Fatalf("Merkliste von bert = %+v, want leer", bert)
	}
}

func TestSavedRoutesRequireAuthentication(t *testing.T) {
	_, app := newSavedTestApp(t)

	for _, tc := range []struct {
		method string
		path   string
		body   any
	}{
		{http.MethodGet, "/api/news/saved", nil},
		{http.MethodPost, "/api/news/saved", sampleItem("heise-1")},
		{http.MethodDelete, "/api/news/saved/heise-1", nil},
	} {
		resp := savedRequest(t, app, tc.method, tc.path, "", tc.body)
		if resp.StatusCode != http.StatusUnauthorized {
			t.Fatalf("%s %s status = %d, want 401", tc.method, tc.path, resp.StatusCode)
		}
		resp.Body.Close()
	}
}

func TestSavedRoutePrefersCachedArticleOverClientPayload(t *testing.T) {
	module, app := newSavedTestApp(t)
	module.mu.Lock()
	module.items = []NewsItem{{
		ID:     "heise-1",
		Title:  "Titel aus dem Feed",
		Author: "heise online",
		URL:    "https://www.heise.de/news/heise-1",
	}}
	module.mu.Unlock()

	manipulated := sampleItem("heise-1")
	manipulated.Title = "Untergeschobener Titel"
	resp := savedRequest(t, app, http.MethodPost, "/api/news/saved", "anna", manipulated)
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("POST /saved status = %d, want 201", resp.StatusCode)
	}
	resp.Body.Close()

	articles := decodeSavedArticles(t, savedRequest(t, app, http.MethodGet, "/api/news/saved", "anna", nil))
	if len(articles) != 1 {
		t.Fatalf("len(articles) = %d, want 1", len(articles))
	}
	if articles[0].Title != "Titel aus dem Feed" {
		t.Fatalf("Title = %q, want den Titel aus dem Cache", articles[0].Title)
	}
}

func TestSavedRouteStoresArticleThatLeftTheFeed(t *testing.T) {
	_, app := newSavedTestApp(t)

	resp := savedRequest(t, app, http.MethodPost, "/api/news/saved", "anna", sampleItem("golem-42"))
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("POST /saved status = %d, want 201", resp.StatusCode)
	}
	resp.Body.Close()

	articles := decodeSavedArticles(t, savedRequest(t, app, http.MethodGet, "/api/news/saved", "anna", nil))
	if len(articles) != 1 || articles[0].ID != "golem-42" {
		t.Fatalf("Merkliste = %+v, want den mitgeschickten Beitrag", articles)
	}
}

func TestSavedRouteDeleteRemovesOnlyOwnArticle(t *testing.T) {
	_, app := newSavedTestApp(t)

	for _, user := range []string{"anna", "bert"} {
		resp := savedRequest(t, app, http.MethodPost, "/api/news/saved", user, sampleItem("heise-1"))
		resp.Body.Close()
	}

	resp := savedRequest(t, app, http.MethodDelete, "/api/news/saved/heise-1", "anna", nil)
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("DELETE status = %d, want 204", resp.StatusCode)
	}
	resp.Body.Close()

	resp = savedRequest(t, app, http.MethodDelete, "/api/news/saved/heise-1", "anna", nil)
	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("zweiter DELETE status = %d, want 404", resp.StatusCode)
	}
	resp.Body.Close()

	bert := decodeSavedArticles(t, savedRequest(t, app, http.MethodGet, "/api/news/saved", "bert", nil))
	if len(bert) != 1 {
		t.Fatalf("Merkliste von bert = %+v, want unveraendert", bert)
	}
}
