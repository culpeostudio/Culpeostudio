package metasearch

import (
	"context"
	"errors"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

type mockEngine struct {
	info    EngineInfo
	results []Result
	err     error
	calls   int32
	delay   time.Duration
}

func (m *mockEngine) Info() EngineInfo { return m.info }
func (m *mockEngine) Search(ctx context.Context, p SearchParams) ([]Result, error) {
	atomic.AddInt32(&m.calls, 1)
	if m.delay > 0 {
		select {
		case <-time.After(m.delay):
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}
	if m.err != nil {
		return nil, m.err
	}
	return m.results, nil
}

func TestSearchRunAggregatesAndRanks(t *testing.T) {
	engA := &mockEngine{
		info: EngineInfo{Name: "a", Category: "text", Provider: "A", Priority: 1},
		results: []Result{
			{Title: "Rust async", Href: "https://blog.example.com/rust", Body: "tokio async runtime"},
			{Title: "Tokio runtime", Href: "https://en.wikipedia.org/wiki/Tokio", Body: "tokio is the de-facto async runtime in rust"},
		},
	}
	engB := &mockEngine{
		info: EngineInfo{Name: "b", Category: "text", Provider: "B", Priority: 1},
		results: []Result{
			{Title: "Tokio runtime", Href: "https://en.wikipedia.org/wiki/Tokio", Body: "the tokio runtime"},
			{Title: "rust", Href: "https://rust-lang.org", Body: "rust-lang homepage"},
		},
	}
	client, err := NewHttpClient(ClientOptions{Timeout: 2 * time.Second})
	if err != nil {
		t.Fatalf("client: %v", err)
	}
	s := NewSearch(client, map[string][]Engine{
		"text": {engA, engB},
	}, SearchOptions{})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	out, err := s.Text(ctx, SearchParams{Query: "rust tokio", Max: 10})
	if err != nil {
		t.Fatalf("Text: %v", err)
	}
	if len(out) < 3 {
		t.Fatalf("erwartet >= 3 unique Treffer, got %d", len(out))
	}

	if !strings.Contains(out[0].Href, "wikipedia.org") {
		t.Errorf("erster Treffer sollte Wikipedia sein: %+v", out[0])
	}
}

func TestSearchRunIgnoresFailingEngines(t *testing.T) {
	ok := &mockEngine{
		info:    EngineInfo{Name: "ok", Category: "text", Provider: "OK", Priority: 1},
		results: []Result{{Title: "OK", Href: "https://ok.example.com", Body: "OK"}},
	}
	bad := &mockEngine{
		info: EngineInfo{Name: "bad", Category: "text", Provider: "BAD", Priority: 1},
		err:  errors.New("boom"),
	}
	client, _ := NewHttpClient(ClientOptions{})
	s := NewSearch(client, map[string][]Engine{
		"text": {ok, bad},
	}, SearchOptions{})

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	out, err := s.Text(ctx, SearchParams{Query: "anything", Max: 5})
	if err != nil {
		t.Fatalf("Text: %v", err)
	}
	if len(out) != 1 || out[0].Title != "OK" {
		t.Errorf("erwartet nur OK-Treffer, got %+v", out)
	}
}

func TestSearchRunRespectsMax(t *testing.T) {
	eng := &mockEngine{
		info: EngineInfo{Name: "e", Category: "text", Provider: "E", Priority: 1},
		results: []Result{
			{Title: "t1", Href: "https://u1"},
			{Title: "t2", Href: "https://u2"},
			{Title: "t3", Href: "https://u3"},
			{Title: "t4", Href: "https://u4"},
		},
	}
	client, _ := NewHttpClient(ClientOptions{})
	s := NewSearch(client, map[string][]Engine{"text": {eng}}, SearchOptions{})

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	out, err := s.Text(ctx, SearchParams{Query: "x", Max: 2})
	if err != nil {
		t.Fatalf("Text: %v", err)
	}
	if len(out) > 2 {
		t.Errorf("erwartet <= 2 Treffer, got %d", len(out))
	}
}

func TestSearchRunEmptyQuery(t *testing.T) {
	client, _ := NewHttpClient(ClientOptions{})
	s := NewSearch(client, map[string][]Engine{"text": {}}, SearchOptions{})
	if _, err := s.Text(context.Background(), SearchParams{}); err == nil {
		t.Error("leere Query sollte einen Fehler liefern")
	}
}

func TestSearchCtxTimeout(t *testing.T) {
	eng := &mockEngine{
		info:    EngineInfo{Name: "slow", Category: "text", Provider: "SLOW", Priority: 1},
		delay:   500 * time.Millisecond,
		results: []Result{{Title: "slow", Href: "https://slow.example.com"}},
	}
	client, _ := NewHttpClient(ClientOptions{})
	s := NewSearch(client, map[string][]Engine{"text": {eng}}, SearchOptions{})

	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	_, err := s.Text(ctx, SearchParams{Query: "x", Max: 3})
	if err == nil {
		t.Error("Timeoutfall nicht erkannt")
	}
}
