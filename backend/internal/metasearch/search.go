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

type Search struct {
	client  *HttpClient
	engines map[string][]Engine
	threads int
	ranker  *SimpleFilterRanker
}

type SearchOptions struct {
	Threads int

	Ranker *SimpleFilterRanker
}

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

func (s *Search) Run(ctx context.Context, category string, p SearchParams) ([]Result, error) {
	p.Query = trim(p.Query)
	if p.Query == "" {
		return nil, NewError(nil, "query is mandatory")
	}
	return s.run(ctx, category, p)
}

func (s *Search) Text(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "text", p)
}

func (s *Search) News(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "news", p)
}

func (s *Search) Images(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "images", p)
}

func (s *Search) Videos(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "videos", p)
}

func (s *Search) Books(ctx context.Context, p SearchParams) ([]Result, error) {
	return s.Run(ctx, "books", p)
}

func (s *Search) run(ctx context.Context, category string, p SearchParams) ([]Result, error) {
	engines := s.engines[category]
	if len(engines) == 0 {
		return nil, NewError(nil, "no engines available for category "+category)
	}

	engines = append([]Engine(nil), engines...)

	shuffleByPriority(engines)

	if p.Max <= 0 {
		p.Max = 10
	}

	cacheFields := cacheFieldsForCategory(category)
	agg := NewAggregator(cacheFields)

	maxWorkers := s.threads
	if maxWorkers <= 0 {

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

	resChInner := resCh
	errChInner := errCh
	go func() {
		wg.Wait()
		close(resChInner)
		close(errChInner)
	}()

readLoop:
	for {
		select {
		case items, ok := <-resCh:
			if !ok {
				break readLoop
			}
			agg.Extend(items)
		case <-ctx.Done():

			break readLoop
		}
	}

	for err := range errCh {

		log.Printf("[metasearch] engine-fehler: %v", err)
	}

	results := agg.Extract()
	results = CleanupText(results)
	results = s.ranker.Rank(results, p.Query)

	if p.Max > 0 && len(results) > p.Max {
		results = results[:p.Max]
	}

	if len(results) == 0 {

		if ctx.Err() == context.DeadlineExceeded {
			return nil, ErrTimeout
		}
		return nil, fmt.Errorf("%w: no results found", ErrSearch)
	}
	return results, nil
}

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

func countUniqueProviders(engines []Engine) int {
	set := map[string]struct{}{}
	for _, e := range engines {
		set[e.Info().Provider] = struct{}{}
	}
	return len(set)
}

func shuffleByPriority(engines []Engine) {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	sort.SliceStable(engines, func(i, j int) bool {
		pi, pj := engines[i].Info().Priority, engines[j].Info().Priority
		if pi != pj {
			return pi > pj
		}

		return r.Intn(2) == 0
	})
}

func trim(s string) string {
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t' || s[0] == '\n' || s[0] == '\r') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == ' ' || s[len(s)-1] == '\t' || s[len(s)-1] == '\n' || s[len(s)-1] == '\r') {
		s = s[:len(s)-1]
	}
	return s
}
