package news

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	newsv1 "github.com/culpeohq/backend/gen/go/culpeostudio/news/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
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

func newSavedTestService(t *testing.T) (*NewsModule, *grpcService) {
	t.Helper()
	module := New(filepath.Join(t.TempDir(), "news_saved.json"))
	if err := module.saved.Load(); err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	return module, &grpcService{module: module}
}

// userContext is what the auth interceptor hands a handler for a signed-in
// caller; the empty name stands for an unauthenticated one.
func userContext(user string) context.Context {
	if user == "" {
		return context.Background()
	}
	return grpcmw.ContextWithUserForTest(context.Background(), user, user)
}

func savedTitles(t *testing.T, service *grpcService, user string) []*newsv1.SavedArticle {
	t.Helper()
	response, err := service.ListSavedArticles(userContext(user), &newsv1.ListSavedArticlesRequest{})
	if err != nil {
		t.Fatalf("ListSavedArticles(%s) error = %v", user, err)
	}
	return response.GetArticles()
}

func saveSample(t *testing.T, service *grpcService, user string, item NewsItem) error {
	t.Helper()
	_, err := service.SaveArticle(userContext(user), &newsv1.SaveArticleRequest{
		Item: newsItemToProto(item),
	})
	return err
}

func TestSavedRoutesKeepListsPerUser(t *testing.T) {
	_, service := newSavedTestService(t)

	if err := saveSample(t, service, "anna", sampleItem("heise-1")); err != nil {
		t.Fatalf("SaveArticle() error = %v", err)
	}

	anna := savedTitles(t, service, "anna")
	if len(anna) != 1 || anna[0].GetItem().GetId() != "heise-1" {
		t.Fatalf("Merkliste von anna = %+v", anna)
	}

	if bert := savedTitles(t, service, "bert"); len(bert) != 0 {
		t.Fatalf("Merkliste von bert = %+v, want leer", bert)
	}
}

func TestSavedRoutesRequireAuthentication(t *testing.T) {
	_, service := newSavedTestService(t)
	anonymous := userContext("")

	if _, err := service.ListSavedArticles(anonymous, &newsv1.ListSavedArticlesRequest{}); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("ListSavedArticles code = %v, want Unauthenticated", status.Code(err))
	}
	if err := saveSample(t, service, "", sampleItem("heise-1")); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("SaveArticle code = %v, want Unauthenticated", status.Code(err))
	}
	if _, err := service.DeleteSavedArticle(anonymous, &newsv1.DeleteSavedArticleRequest{Id: "heise-1"}); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("DeleteSavedArticle code = %v, want Unauthenticated", status.Code(err))
	}
}

// A client must not be able to store a doctored copy of an article the backend
// already knows.
func TestSavedRoutePrefersCachedArticleOverClientPayload(t *testing.T) {
	module, service := newSavedTestService(t)
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
	if err := saveSample(t, service, "anna", manipulated); err != nil {
		t.Fatalf("SaveArticle() error = %v", err)
	}

	articles := savedTitles(t, service, "anna")
	if len(articles) != 1 {
		t.Fatalf("len(articles) = %d, want 1", len(articles))
	}
	if articles[0].GetItem().GetTitle() != "Titel aus dem Feed" {
		t.Fatalf("Title = %q, want den Titel aus dem Cache", articles[0].GetItem().GetTitle())
	}
}

func TestSavedRouteStoresArticleThatLeftTheFeed(t *testing.T) {
	_, service := newSavedTestService(t)

	if err := saveSample(t, service, "anna", sampleItem("golem-42")); err != nil {
		t.Fatalf("SaveArticle() error = %v", err)
	}

	articles := savedTitles(t, service, "anna")
	if len(articles) != 1 || articles[0].GetItem().GetId() != "golem-42" {
		t.Fatalf("Merkliste = %+v, want den mitgeschickten Beitrag", articles)
	}
}

func TestSavedRouteDeleteRemovesOnlyOwnArticle(t *testing.T) {
	_, service := newSavedTestService(t)

	for _, user := range []string{"anna", "bert"} {
		if err := saveSample(t, service, user, sampleItem("heise-1")); err != nil {
			t.Fatalf("SaveArticle(%s) error = %v", user, err)
		}
	}

	if _, err := service.DeleteSavedArticle(userContext("anna"), &newsv1.DeleteSavedArticleRequest{Id: "heise-1"}); err != nil {
		t.Fatalf("DeleteSavedArticle() error = %v", err)
	}

	_, err := service.DeleteSavedArticle(userContext("anna"), &newsv1.DeleteSavedArticleRequest{Id: "heise-1"})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("zweiter Delete code = %v, want NotFound", status.Code(err))
	}

	if bert := savedTitles(t, service, "bert"); len(bert) != 1 {
		t.Fatalf("Merkliste von bert = %+v, want unveraendert", bert)
	}
}
