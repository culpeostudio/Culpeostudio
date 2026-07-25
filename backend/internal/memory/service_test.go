package memory_test

import (
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/memory"
	"github.com/fillyengine/backend/internal/memoryembed"
	"github.com/fillyengine/backend/internal/memorystore"
	"github.com/fillyengine/backend/internal/memoryvector"
)

func newTestService(t *testing.T) *memory.Service {
	t.Helper()
	baseDir := t.TempDir()
	store := memorystore.NewSQLiteStore(baseDir + "/memory.db")
	hashBackend := memoryembed.NewHashBackend(64)
	vector := memoryvector.New(store, hashBackend, hashBackend, baseDir+"/vector.json")
	policy := memory.DefaultCompressionPolicy()
	policy.ProjectStatusThreshold = 10

	options := memory.Options{
		ProjectTag:          "myphiloengine",
		DefaultUserID:       "local",
		ContextBudgetTokens: 320,
		Policy:              policy,
	}
	service := memory.NewService(store, vector, nil, options)
	if err := service.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	t.Cleanup(func() {
		_ = service.Close()
	})
	return service
}

// BuildUserContext muss Fakten aus einer frueheren Session finden, ohne dass die
// aktuelle (neue) Session im Gedaechtnis existiert – genau der PhiloBot-Fall
// "Bot hat meinen Namen nach Neustart vergessen".
func TestBuildUserContextRecallsAcrossSessions(t *testing.T) {
	service := newTestService(t)

	first, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "chat"})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	if _, err := service.AddObservation(first.ID, memory.AddObservationInput{
		Source: "chat",
		Type:   "dialogue_pair",
		// Der echte Chat-Compressor routet "mein "-Fakten nach LayerUserData;
		// die "mein "-Query unten routet ebenso dorthin (routeIntent).
		Layer:     memory.LayerUserData,
		Category:  memory.CategoryStatus,
		Title:     "Chat: Name",
		Narrative: "User request: Mein Name ist David. Assistant answer: Freut mich, David.",
	}); err != nil {
		t.Fatalf("add observation failed: %v", err)
	}

	// Nutzerweiter Recall: kein session-gebundener GetSession-Aufruf.
	envelope, err := service.BuildUserContext("local", "Wie ist mein Name David", 0)
	if err != nil {
		t.Fatalf("build user context failed: %v", err)
	}
	if envelope == nil || strings.TrimSpace(envelope.InjectionPrompt) == "" {
		t.Fatalf("erwartete Recall-Kontext, bekam leeren InjectionPrompt")
	}
	if !strings.Contains(envelope.InjectionPrompt, "David") {
		t.Fatalf("Recall enthielt den Namen nicht: %q", envelope.InjectionPrompt)
	}
	if strings.Contains(envelope.InjectionPrompt, "memory_search") {
		t.Fatalf("Chat-Recall darf keine Tool-Hinweise enthalten: %q", envelope.InjectionPrompt)
	}
}

// Wenn der Recall noch nicht aktiv war, hat der Bot fruehere "Wie heiße ich?"-
// Fragen mit "Ich weiß deinen Namen nicht" beantwortet. Diese Anti-Fakten sind
// gespeichert und ranken lexikalisch ganz oben – der Recall muss sie
// herausfiltern, sonst verleitet er das Modell zur falschen Antwort.
func TestBuildUserContextFiltersIgnoranceAntiFacts(t *testing.T) {
	service := newTestService(t)

	first, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "chat"})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	add := func(narrative string) {
		if _, err := service.AddObservation(first.ID, memory.AddObservationInput{
			Source:    "chat",
			Type:      "chat_memory",
			Layer:     memory.LayerUserData,
			Category:  memory.CategoryStatus,
			Title:     "Chat memory",
			Narrative: narrative,
		}); err != nil {
			t.Fatalf("add observation failed: %v", err)
		}
	}
	// Anti-Fakten (aus der Zeit ohne Recall):
	add("User request: wie lautet mein name Assistant answer: Ich weiß leider nicht, wie dein Name ist.")
	add("User request: wer bin ich Assistant answer: Ich kenne deinen Namen leider nicht.")
	// Der echte Fakt:
	add("User request: david Assistant answer: Dein Name ist David.")

	envelope, err := service.BuildUserContext("local", "wie lautet mein name", 0)
	if err != nil {
		t.Fatalf("build user context failed: %v", err)
	}
	prompt := envelope.InjectionPrompt
	if !strings.Contains(prompt, "David") {
		t.Fatalf("Recall enthielt den Namen nicht: %q", prompt)
	}
	if strings.Contains(strings.ToLower(prompt), "weiß leider nicht") ||
		strings.Contains(strings.ToLower(prompt), "kenne deinen namen") {
		t.Fatalf("Anti-Fakten wurden nicht herausgefiltert: %q", prompt)
	}
}

func TestBuildUserContextEmptyQueryIsEmpty(t *testing.T) {
	service := newTestService(t)
	envelope, err := service.BuildUserContext("local", "   ", 0)
	if err != nil {
		t.Fatalf("build user context failed: %v", err)
	}
	if envelope == nil || envelope.InjectionPrompt != "" {
		t.Fatalf("leere Query sollte leeren Recall liefern, bekam: %#v", envelope)
	}
}

// TestBuildScopedContextIsolatesProjects beweist die Grid-Semantik: ein
// projekt-gebundener Fakt (project_data) wird nur im eigenen Projekt erinnert,
// waehrend ein globaler Nutzer-Fakt (user_data) in jedem Projekt-Grid auftaucht.
func TestBuildScopedContextIsolatesProjects(t *testing.T) {
	service := newTestService(t)

	// Hilfsfunktion: legt eine Session im gegebenen Projekt an und haengt eine
	// Observation an. Der Observation-Layer entscheidet ueber die Sichtbarkeit.
	addFact := func(project string, layer memory.MemoryLayer, title, narrative string) {
		t.Helper()
		session, err := service.CreateSession(memory.CreateSessionInput{Project: project, Source: "chat"})
		if err != nil {
			t.Fatalf("create session (%s) failed: %v", project, err)
		}
		if _, err := service.AddObservation(session.ID, memory.AddObservationInput{
			Source:    "chat",
			Type:      "dialogue_pair",
			Layer:     layer,
			Category:  memory.CategoryStatus,
			Title:     title,
			Narrative: narrative,
		}); err != nil {
			t.Fatalf("add observation (%s) failed: %v", project, err)
		}
	}

	// Projektspezifische Fakten mit fast identischen Keywords – nur die Sprache
	// unterscheidet sie, sodass der Scope allein den Treffer bestimmt.
	langQuery := "welche programmiersprache nutzen wir in diesem projekt"
	addFact("proj-A", memory.LayerProjectData, "Projekt A: Sprache",
		"User request: "+langQuery+" Assistant answer: In diesem Projekt nutzen wir Golang.")
	addFact("proj-B", memory.LayerProjectData, "Projekt B: Sprache",
		"User request: "+langQuery+" Assistant answer: In diesem Projekt nutzen wir Rustlang.")
	// Globaler Nutzer-Fakt (user_data), im Projekt A erfasst, aber projektuebergreifend gueltig.
	addFact("proj-A", memory.LayerUserData, "Nutzer: Name",
		"User request: Mein Name ist David. Assistant answer: Freut mich, David.")

	// Grid A sieht Golang, nicht Rustlang.
	ctxA, err := service.BuildScopedContext("local", "proj-A", langQuery, 0)
	if err != nil {
		t.Fatalf("scoped context A failed: %v", err)
	}
	if !strings.Contains(ctxA.InjectionPrompt, "Golang") {
		t.Fatalf("Projekt A sollte den eigenen Fakt erinnern: %q", ctxA.InjectionPrompt)
	}
	if strings.Contains(ctxA.InjectionPrompt, "Rustlang") {
		t.Fatalf("Projekt A darf den Fakt aus Projekt B nicht sehen: %q", ctxA.InjectionPrompt)
	}

	// Grid B sieht Rustlang, nicht Golang.
	ctxB, err := service.BuildScopedContext("local", "proj-B", langQuery, 0)
	if err != nil {
		t.Fatalf("scoped context B failed: %v", err)
	}
	if !strings.Contains(ctxB.InjectionPrompt, "Rustlang") {
		t.Fatalf("Projekt B sollte den eigenen Fakt erinnern: %q", ctxB.InjectionPrompt)
	}
	if strings.Contains(ctxB.InjectionPrompt, "Golang") {
		t.Fatalf("Projekt B darf den Fakt aus Projekt A nicht sehen: %q", ctxB.InjectionPrompt)
	}

	// Der globale Nutzer-Fakt taucht in BEIDEN Projekt-Grids auf.
	for _, project := range []string{"proj-A", "proj-B"} {
		nameCtx, err := service.BuildScopedContext("local", project, "Wie ist mein Name David", 0)
		if err != nil {
			t.Fatalf("scoped name context (%s) failed: %v", project, err)
		}
		if !strings.Contains(nameCtx.InjectionPrompt, "David") {
			t.Fatalf("Nutzer-Name sollte in Projekt %s erinnert werden: %q", project, nameCtx.InjectionPrompt)
		}
	}
}

func TestAddObservationDeduplicatesWithinWindow(t *testing.T) {
	service := newTestService(t)

	session, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "philox"})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}

	first, err := service.AddObservation(session.ID, memory.AddObservationInput{
		Source:    "philox",
		Type:      "tool_result",
		Title:     "Server gelesen",
		Narrative: "cmd/server/main.go registriert Module.",
	})
	if err != nil {
		t.Fatalf("first observation failed: %v", err)
	}

	second, err := service.AddObservation(session.ID, memory.AddObservationInput{
		Source:    "philox",
		Type:      "tool_result",
		Title:     "Server gelesen",
		Narrative: "cmd/server/main.go registriert Module.",
	})
	if err != nil {
		t.Fatalf("second observation failed: %v", err)
	}

	if first.ID != second.ID {
		t.Fatalf("expected duplicate observation to reuse same id, got %s and %s", first.ID, second.ID)
	}
}

func TestCompressionKeepsRecentObservationsActive(t *testing.T) {
	service := newTestService(t)

	session, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "philox"})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}

	for index := 0; index < 12; index++ {
		_, err := service.AddObservation(session.ID, memory.AddObservationInput{
			Source:    "philox",
			Type:      "insight",
			Title:     "Beobachtung",
			Narrative: "Dies ist eine ausfuehrliche Beobachtung fuer die Kompression und den Suchindex Nummer " + string(rune('A'+index)) + ".",
		})
		if err != nil {
			t.Fatalf("add observation %d failed: %v", index, err)
		}
	}

	loaded, err := service.GetSession(session.ID)
	if err != nil {
		t.Fatalf("load session failed: %v", err)
	}
	if len(loaded.Memories) == 0 {
		t.Fatalf("expected at least one compressed memory")
	}
	// Compression keeps ActiveWindow observations and re-fills until the next
	// threshold trigger, so the invariant is "always below the threshold".
	if len(loaded.ActiveObservations) >= 10 {
		t.Fatalf("expected active observations below threshold 10, got %d", len(loaded.ActiveObservations))
	}
	if len(loaded.ArchivedObservations) == 0 {
		t.Fatalf("expected archived observations after compression")
	}
}

func TestOpenChangeRequestStaysUncompressedUntilDecided(t *testing.T) {
	service := newTestService(t)
	session, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "philox"})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	for index := 0; index < 12; index++ {
		_, err := service.AddObservation(session.ID, memory.AddObservationInput{
			Source:   "philox",
			Layer:    memory.LayerProjectData,
			Category: memory.CategoryChangeRequest,
			Title:    "Aenderungsantrag",
			ChangeRequest: &memory.ChangeRequestState{
				Status:      memory.ChangeRequestOpen,
				Proposal:    "Vorschlag " + string(rune('A'+index)),
				ReasonShort: "Test",
			},
		})
		if err != nil {
			t.Fatalf("add change request failed: %v", err)
		}
	}
	loaded, err := service.GetSession(session.ID)
	if err != nil {
		t.Fatalf("load session failed: %v", err)
	}
	if len(loaded.Memories) != 0 {
		t.Fatalf("expected open change requests to stay uncompressed")
	}
}

func TestChangeRequestCategoryUsesCompactSchema(t *testing.T) {
	service := newTestService(t)
	session, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "philox"})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	observation, err := service.AddObservation(session.ID, memory.AddObservationInput{
		Source:    "philox",
		Category:  memory.CategoryChangeRequest,
		Title:     "Aenderungsantrag",
		Narrative: "Bitte Viewer-Timeline farblich hervorheben.",
	})
	if err != nil {
		t.Fatalf("add change request failed: %v", err)
	}
	if observation.ChangeRequest == nil {
		t.Fatalf("expected compact change request state")
	}
	if observation.ChangeRequest.Status != memory.ChangeRequestOpen {
		t.Fatalf("expected open status, got %s", observation.ChangeRequest.Status)
	}
	if observation.Narrative != memory.RenderChangeRequestNarrative(observation.ChangeRequest) {
		t.Fatalf("expected compact narrative, got %q", observation.Narrative)
	}
}

func TestSearchReturnsHybridResult(t *testing.T) {
	service := newTestService(t)

	session, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "chat"})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	_, _, err = service.AddPrompt(session.ID, memory.AddPromptInput{
		Role: memory.PromptRoleUser,
		Text: "Suche nach Fiber Modulstruktur",
	})
	if err != nil {
		t.Fatalf("add prompt failed: %v", err)
	}
	_, err = service.AddObservation(session.ID, memory.AddObservationInput{
		Source:    "chat",
		Type:      "insight",
		Title:     "Fiber routing",
		Narrative: "Das Projekt nutzt Fiber Router Gruppen fuer API und Viewer.",
		Tags:      []string{"fiber", "routing"},
	})
	if err != nil {
		t.Fatalf("add observation failed: %v", err)
	}

	results, err := service.Search("fiber routing", memory.SearchFilters{Limit: 5})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(results) == 0 {
		t.Fatalf("expected search results")
	}
	if results[0].Kind != "observation" {
		t.Fatalf("expected top result to be observation, got %s", results[0].Kind)
	}
	if results[0].Score <= 0 {
		t.Fatalf("expected positive score, got %f", results[0].Score)
	}
}

func TestSearchIsScopedByUserID(t *testing.T) {
	service := newTestService(t)

	aliceSession, err := service.CreateSession(memory.CreateSessionInput{UserID: "alice", Project: "myphiloengine", Source: "chat"})
	if err != nil {
		t.Fatalf("create alice session failed: %v", err)
	}
	bobSession, err := service.CreateSession(memory.CreateSessionInput{UserID: "bob", Project: "myphiloengine", Source: "chat"})
	if err != nil {
		t.Fatalf("create bob session failed: %v", err)
	}
	if _, err := service.AddObservation(aliceSession.ID, memory.AddObservationInput{
		UserID:    "alice",
		Source:    "chat",
		Type:      "insight",
		Title:     "Alice private memory",
		Narrative: "aliceonly preference",
	}); err != nil {
		t.Fatalf("add alice observation failed: %v", err)
	}
	if _, err := service.AddObservation(bobSession.ID, memory.AddObservationInput{
		UserID:    "bob",
		Source:    "chat",
		Type:      "insight",
		Title:     "Bob private memory",
		Narrative: "bobonly preference",
	}); err != nil {
		t.Fatalf("add bob observation failed: %v", err)
	}

	aliceResults, err := service.Search("bobonly", memory.SearchFilters{UserID: "alice", Limit: 5})
	if err != nil {
		t.Fatalf("alice search failed: %v", err)
	}
	// The property under test is user isolation: alice must never see bob's
	// memory. We assert exactly that, not "zero results" – the hash-v2 embedding
	// uses character trigrams, so alice's own "aliceonly" can fuzzy-match the
	// query "bobonly" via the shared "only" suffix. That is her own data (the
	// user_id filter is enforced in SQL), so it is fine; a bob-owned hit would
	// not be.
	for _, result := range aliceResults {
		if result.UserID == "bob" || strings.Contains(result.Title, "Bob") {
			t.Fatalf("alice must not see bob's memory, got %+v", result)
		}
	}

	bobResults, err := service.Search("bobonly", memory.SearchFilters{UserID: "bob", Limit: 5})
	if err != nil {
		t.Fatalf("bob search failed: %v", err)
	}
	if len(bobResults) == 0 {
		t.Fatalf("expected bob to see his own memory")
	}
}

func TestBuildContextRespectsBudget(t *testing.T) {
	service := newTestService(t)

	session, err := service.CreateSession(memory.CreateSessionInput{Project: "myphiloengine", Source: "philox", Goals: []string{"Kontext kompakt halten"}})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}
	_, _, err = service.AddPrompt(session.ID, memory.AddPromptInput{
		Role: memory.PromptRoleUser,
		Text: "Bitte erklaere das Memory-System mit allen Details und langem Kontext.",
	})
	if err != nil {
		t.Fatalf("add prompt failed: %v", err)
	}
	for index := 0; index < 8; index++ {
		_, err := service.AddObservation(session.ID, memory.AddObservationInput{
			Source:    "philox",
			Type:      "insight",
			Title:     "Sehr lange Beobachtung",
			Narrative: "Dies ist eine sehr lange Beobachtung mit vielen Details ueber Fiber, SQLite, SSE, Timeline und Hybrid Search fuer den Injektionskontext.",
		})
		if err != nil {
			t.Fatalf("add observation failed: %v", err)
		}
	}
	context, err := service.BuildContext(session.ID, "", 8)
	if err != nil {
		t.Fatalf("build context failed: %v", err)
	}
	if context.UsedTokens > context.BudgetTokens {
		t.Fatalf("expected context to stay within budget, got %d > %d", context.UsedTokens, context.BudgetTokens)
	}
	if context.InjectionPrompt == "" {
		t.Fatalf("expected non-empty injection prompt")
	}
}

type mockBackend struct {
	model string
	dim   int
}

func (m *mockBackend) Name() string  { return "mock" }
func (m *mockBackend) Model() string { return m.model }
func (m *mockBackend) Dim() int      { return m.dim }
func (m *mockBackend) Embed(text string) ([]float32, error) {
	vec := make([]float32, m.dim)
	val := float32(len(text))
	for i := range vec {
		vec[i] = val
	}
	return vec, nil
}

func TestParallelCompression(t *testing.T) {
	service := newTestService(t)
	session, err := service.CreateSession(memory.CreateSessionInput{
		Project: "myphiloengine",
		Source:  "test",
	})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}

	for i := 0; i < 15; i++ {
		_, err := service.AddObservation(session.ID, memory.AddObservationInput{
			Source:    "philox",
			Type:      "insight",
			Title:     fmt.Sprintf("Obs %d", i),
			Narrative: fmt.Sprintf("Beobachtung Nummer %d fuer den Parallel-Kompressionstest.", i),
		})
		if err != nil {
			t.Fatalf("add observation failed: %v", err)
		}
	}

	var wg sync.WaitGroup
	errs := make(chan error, 5)

	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := service.TriggerCompression("local", session.ID); err != nil {
				errs <- err
			}
		}()
	}

	wg.Wait()
	close(errs)

	for err := range errs {
		t.Errorf("parallel compression failed: %v", err)
	}
}

func TestBackendSwitchSearch(t *testing.T) {
	baseDir := t.TempDir()
	store := memorystore.NewSQLiteStore(baseDir + "/memory.db")

	hashBackend := &mockBackend{model: "hash-v1", dim: 16}
	activeBackend := &mockBackend{model: "onnx-v2", dim: 32}

	vector := memoryvector.New(store, activeBackend, hashBackend, baseDir+"/vector.json")
	options := memory.Options{
		ProjectTag:          "myphiloengine",
		DefaultUserID:       "local",
		ContextBudgetTokens: 1000,
	}
	service := memory.NewService(store, vector, nil, options)
	if err := service.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	defer service.Close()

	session, err := service.CreateSession(memory.CreateSessionInput{
		Project: "myphiloengine",
		Source:  "test",
	})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}

	// Add an observation using active backend (onnx-v2)
	_, err = service.AddObservation(session.ID, memory.AddObservationInput{
		Source:    "philox",
		Type:      "insight",
		Title:     "Dokument A",
		Narrative: "Das ist die erste Test-Beobachtung.",
	})
	if err != nil {
		t.Fatalf("add observation failed: %v", err)
	}

	// Verify search works
	hits, err := service.Search("Test-Beobachtung", memory.SearchFilters{Limit: 5})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(hits) == 0 {
		t.Fatalf("expected search hits, got 0")
	}
}

func TestReindexUnderLoad(t *testing.T) {
	baseDir := t.TempDir()
	store := memorystore.NewSQLiteStore(baseDir + "/memory.db")

	hashBackend := &mockBackend{model: "hash-v1", dim: 16}
	activeBackend := &mockBackend{model: "onnx-v2", dim: 32}

	vector := memoryvector.New(store, activeBackend, hashBackend, baseDir+"/vector.json")
	options := memory.Options{
		ProjectTag:          "myphiloengine",
		DefaultUserID:       "local",
		ContextBudgetTokens: 1000,
	}
	service := memory.NewService(store, vector, nil, options)
	if err := service.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	defer service.Close()

	session, err := service.CreateSession(memory.CreateSessionInput{
		Project: "myphiloengine",
		Source:  "test",
	})
	if err != nil {
		t.Fatalf("create session failed: %v", err)
	}

	// Add legacy document directly into store (mocking pre-existing hash embeddings)
	err = store.UpsertEmbedding(memorystore.EmbeddingRecord{
		DocID:     "obs:old-1",
		Embedding: make([]float32, 16),
		Model:     "hash-v1",
	})
	if err != nil {
		t.Fatalf("upsert failed: %v", err)
	}

	stop := make(chan struct{})
	done := make(chan struct{})
	go func() {
		defer close(done)
		vector.RunReindexer(stop, 10*time.Millisecond, 1, 2)
	}()

	// Concurrently add new observations
	for i := 0; i < 5; i++ {
		_, err := service.AddObservation(session.ID, memory.AddObservationInput{
			Source:    "philox",
			Type:      "insight",
			Title:     fmt.Sprintf("Obs %d", i),
			Narrative: fmt.Sprintf("Neue Beobachtung %d", i),
		})
		if err != nil {
			t.Errorf("concurrent add observation failed: %v", err)
		}
		time.Sleep(5 * time.Millisecond)
	}

	close(stop)
	<-done
}
