// search.go enthaelt den PhiloSearch-Aggregator: er nimmt eine
// vordefinierte Engine-Menge pro Kategorie je Engine, sammelt die
// Treffer, dedupliziert ueber die Cache-Fields, bewertet sie ueber
// den SimpleFilterRanker und liefert die besten max_results Treffer.
//
// Der Aggregator ist die Go-Entsprechung der Python-Klasse DDGS.
// Statt Python ThreadPoolExecutor nutzen wir Go-Goroutines mit
// context.Context und sync.WaitGroup.

package metasearch

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"sort"
	"sync"
	"time"
)

// Search ist der zentrale Metasearch-Aggregator. Er ersetzt die
// Python-Klasse DDGS und wird einmal pro Prozess/VL angelegt.
type Search struct {
	client  *HttpClient
	engines map[string][]Engine // category -> engines
	threads int                 // optional: Max Goroutines parallel
	ranker  *SimpleFilterRanker
}

// SearchOptions vervollstaendigt die Konfiguration des Aggregators.
type SearchOptions struct {
	// Threads beschraenkt die maximale Anzahl paralleler Engine-Calls.
	// 0 = automatisch (min(len(engines), (max_results/10)+1)).
	Threads int

	// Ranker ist optional; bei nil wird der Standard-SimpleFilterRanker genutzt.
	Ranker *SimpleFilterRanker
}

// NewSearch erzeugt einen Aggregator mit konfigurierten Engines pro
// Kategorie. Der Aufrufer ist zustaendig dafuer, die Engines vorher
// via engines.Build() zu erzeugen - damit bleibt metasearchfrei
// von Engines-Imports (kein zyklischer Import).
func NewSearch(client *HttpClient, enginesByCategory map[string][]Engine, opts SearchOptions) *Search {
	ranker := opts.Ranker
	if ranker == nil {
		ranker = NewSimpleFilterRanker()
	}
	return &Search{
		client:  client,
		engines: enginesByCategory,
		threads: opts.Threads,
		ranker:  ranker,
	}
}

// Run ist die allgemeine Suche nach Kategorie. Die darunterliegenden
// Methoden Text/News/Images/Videos/Books sind Convenience-Wrapper.
func (s *Search) Run(ctx context.Context, category string, p SearchParams) ([]Result, error) {
	p.Query = trim(p.Query)
	if p.Query == "" {
		return nil, NewError(nil, "query is mandatory")
	}
	return s.run(ctx, category, p)
}

// Text sucht ueber die konfigurierten Text-Engines und liefert die
// aggregierten Treffer zurueck.
func (s *Search) Text(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "text", p)
}

// News sucht ueber die konfigurierten News-Engines.
func (s *Search) News(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "news", p)
}

// Images sucht ueber die konfigurierten Images-Engines.
func (s *Search) Images(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "images", p)
}

// Videos sucht ueber die konfigurierten Videos-Engines.
func (s *Search) Videos(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "videos", p)
}

// Books sucht ueber die konfigurierten Books-Engines.
func (s *Search) Books(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "books", p)
}

// run ist der gemeinsame Such-Kern fuer alle Kategorien.
func (s *Search) run(ctx context.Context, category string, p SearchParams) ([]Result, error) {
	engines := s.engines[category]
	if len(engines) == 0 {
		return nil, NewError(nil, "no engines available for category "+category)
	}
	// Kopieren, damit die Sortierung nicht das Original durcheinanderbringt.
	engines = append([]Engine(nil), engines...)

	// Sortierung nach Priority: hoechste zuerst. Zusaetzlich mischen
	// wir Engines gleicher Priority, so dass verschiedene Kategorien nicht
	// deterministisch dieselbe Reihenfolge liefern.
	shuffleByPriority(engines)

	if p.Max <= 0 {
		p.Max = 10
	}

	// Pro Engine eine Goroutine. Early-Exit, sobald max_results
	// erreicht sind oder alle Engines erledigt sind.
	cacheFields := cacheFieldsForCategory(category)
	agg := NewAggregator(cacheFields)

	maxWorkers := s.threads
	if maxWorkers <= 0 {
		// Grob an Python angelehnt: min(unique-providers, max_results/10 + 1)
		uniqProviders := countUniqueProviders(engines)
		maxWorkers = uniqProviders
		if maxWorkers > p.Max/10+1 {
			maxWorkers = p.Max/10 + 1
		}
		if maxWorkers < 1 {
			maxWorkers = 1
		}
	}
	if maxWorkers > len(engines) {
		maxWorkers = len(engines)
	}

	var wg sync.WaitGroup
	sem := make(chan struct{}, maxWorkers)
	seenProviders := make(map[string]struct{})
	resCh := make(chan []Result, len(engines))
	errCh := make(chan error, len(engines))

	for _, eng := range engines {
		if _, ok := seenProviders[eng.Info().Provider]; ok {
			continue
		}
		seenProviders[eng.Info().Provider] = struct{}{}

		wg.Add(1)
		go func(e Engine) {
			defer wg.Done()
			select {
			case sem <- struct{}{}:
				defer func() { <-sem }()
			case <-ctx.Done():
				return
			}
			res, err := e.Search(ctx, p)
			if err != nil {
				errCh <- err
				return
			}
			resCh <- res
		}(eng)
	}

	// Warten auf alle Engines und Channels schliessen. Wir behalten
	// zusaetzliche Referenzen auf die Channels, damit eine Zuweisung
	// in der消费-Schleife (resCh=nil frueher Versuch) nicht dazu
	// fuehrt, dass dieser Goroutine ein nil-Channel vorliegt und
	// close() panicked.
	resChInner := resCh
	errChInner := errCh
	go func() {
		wg.Wait()
		close(resChInner)
		close(errChInner)
	}()

	// Stream: sobald alle Engines fertig sind (Channels geschlossen)
	// oder der Kontext abbricht, verlassen wir die Schleife.
readLoop:
	for {
		select {
		case items, ok := <-resCh:
			if !ok {
				break readLoop
			}
			agg.Extend(items)
		case <-ctx.Done():
			// Sobald der Kontext abbricht, koennen weitere Treffer
			// ignoriert werden. Die Engines merken den Abbruch und
			// liefern kontextfehler; das ist OK.
			break readLoop
		}
	}

	// Fehler sammeln (nur fuer Logging; wir liefern immer Treffer,
	// wenn mindestens ein Engine erfolgreich war).
	for err := range errCh {
		// Quietly loggen; evtl. Rate-Limit/Timeout.
		log.Printf("[metasearch] engine-fehler: %v", err)
	}

	results := agg.Extract()
	results = CleanupText(results) // Leere herausfiltern
	results = s.ranker.Rank(results, p.Query)

	if p.Max > 0 && len(results) > p.Max {
		results = results[:p.Max]
	}

	if len(results) == 0 {
		// Pruefen, ob ein Timeout vorlag.
		if ctx.Err() == context.DeadlineExceeded {
			return nil, ErrTimeout
		}
		return nil, fmt.Errorf("%w: no results found", ErrSearch)
	}
	return results, nil
}

// cacheFieldsForCategory waehlt die Dedup-Felder pro Kategorie.
func cacheFieldsForCategory(category string) []string {
	switch category {
	case "text":
		return []string{"href"}
	case "images":
		return []string{"image", "thumbnail", "url"}
	case "videos":
		return []string{"content", "embed_url"}
	case "news":
		return []string{"url"}
	case "books":
		return []string{"url"}
	default:
		return []string{"href"}
	}
}

// countUniqueProviders zaehlt einzigartige Provider in der Engine-Liste.
func countUniqueProviders(engines []Engine) int {
	set := map[string]struct{}{}
	for _, e := range engines {
		set[e.Info().Provider] = struct{}{}
	}
	return len(set)
}

// shuffleByPriority sortiert die Engine-Liste absteigend nach Priority
// und mischt Engines gleicher Priority zufaellig durch.
func shuffleByPriority(engines []Engine) {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	sort.SliceStable(engines, func(i, j int) bool {
		pi, pj := engines[i].Info().Priority, engines[j].Info().Priority
		if pi != pj {
			return pi > pj
		}
		// Bei gleicher Prio ansvarloser Misch-Kriterium
		return r.Intn(2) == 0
	})
}

// trim ist ein Hilfs-Wrapper, vermeidet strings-Import ROUND-TRIP in Tests.
func trim(s string) string {
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t' || s[0] == '\n' || s[0] == '\r') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == ' ' || s[len(s)-1] == '\t' || s[len(s)-1] == '\n' || s[len(s)-1] == '\r') {
		s = s[:len(s)-1]
	}
	return s
}
