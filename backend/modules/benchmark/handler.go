package benchmark

import (
	"context"
	"errors"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/fillyengine/backend/internal/appsettings"
)

const (
	liveMaxAge     = 24 * time.Hour
	archivedMaxAge = 7 * 24 * time.Hour

	incompleteMaxAge = time.Hour

	hubCacheTTL      = 15 * time.Minute
	hubCacheCapacity = 500

	stateEmpty   = "empty"
	stateLoading = "loading"
	stateReady   = "ready"
	stateError   = "error"
)

type hubCacheEntry struct {
	stats    *HubStats
	results  []CardResult
	storedAt time.Time
}

type boardState struct {
	entries     []Entry
	metricStats []MetricStats
	byModel     map[string][]int

	fetchedAt   time.Time
	publishedAt string
	fromCache   bool
	state       string
	loadErr     string
	loadedRows  int
	expected    int
}

func newBoardState() *boardState {
	return &boardState{byModel: map[string][]int{}, state: stateEmpty}
}

type Module struct {
	mu    sync.RWMutex
	state map[string]*boardState

	loadMu  sync.Mutex
	loading map[string]bool

	hubMu    sync.Mutex
	hubCache map[string]hubCacheEntry

	client    *http.Client
	endpoints endpoints
	cacheDir  string
	settings  *appsettings.Store

	lifecycle context.Context
	stop      context.CancelFunc
}

func New(cacheDir, settingsFile string) *Module {
	lifecycle, stop := context.WithCancel(context.Background())

	state := make(map[string]*boardState, len(boards))
	for key := range boards {
		state[key] = newBoardState()
	}

	return &Module{
		state:     state,
		loading:   map[string]bool{},
		hubCache:  make(map[string]hubCacheEntry),
		client:    &http.Client{Timeout: 60 * time.Second},
		endpoints: defaultEndpoints(),
		cacheDir:  strings.TrimSpace(cacheDir),
		settings:  appsettings.NewStore(settingsFile),
		lifecycle: lifecycle,
		stop:      stop,
	}
}

func (m *Module) Name() string { return "benchmark" }

func (m *Module) Initialize() error {
	stale := make([]string, 0, len(boards))

	for _, key := range BoardOrder {
		entry, ok := knownBoard(key)
		if !ok {
			continue
		}

		snapshot, err := loadSnapshot(m.snapshotPath(key))
		if err != nil {

			log.Printf("[benchmark] Abzug %q unbrauchbar, wird neu geladen: %v", key, err)
		}
		if snapshot != nil {
			m.replaceEntries(key, snapshot.Entries, snapshot.FetchedAt, snapshot.PublishedAt, true)
		}

		maxAge := archivedMaxAge
		if entry.info.Source.Live {
			maxAge = liveMaxAge
		}
		if snapshot != nil {
			if gaps := m.missingMetrics(key); len(gaps) > 0 {
				log.Printf("[benchmark] Abzug %q fehlen %d Wertungen (%s), Abgleich vorgezogen",
					key, len(gaps), strings.Join(gaps, ", "))
				maxAge = incompleteMaxAge
			}
		}
		if snapshot == nil || time.Since(snapshot.FetchedAt) > maxAge {
			stale = append(stale, key)
		}
	}

	if len(stale) > 0 {
		go m.refreshBoards(m.lifecycle, stale)
	}
	return nil
}

func (m *Module) Shutdown() error {
	m.stop()
	return nil
}

func (m *Module) snapshotPath(boardKey string) string {
	if m.cacheDir == "" {
		return ""
	}
	return snapshotFilePath(m.cacheDir, boardKey)
}

func (m *Module) replaceEntries(boardKey string, entries []Entry, fetchedAt time.Time, publishedAt string, fromCache bool) {
	assignRanks(entries)

	index := make(map[string][]int, len(entries))
	for i := range entries {
		index[modelKey(entries[i])] = append(index[modelKey(entries[i])], i)
	}
	stats := computeMetricStats(entries, boardMetrics(boardKey))

	m.mu.Lock()
	defer m.mu.Unlock()

	state, ok := m.state[boardKey]
	if !ok {
		state = newBoardState()
		m.state[boardKey] = state
	}
	state.entries = entries
	state.byModel = index
	state.metricStats = stats
	state.fetchedAt = fetchedAt
	state.publishedAt = publishedAt
	state.fromCache = fromCache
	state.loadedRows = len(entries)
	state.state = stateReady
	state.loadErr = ""
}

func (m *Module) refreshBoards(ctx context.Context, keys []string) {
	for _, key := range keys {
		if err := ctx.Err(); err != nil {
			return
		}
		m.refreshBoard(ctx, key)
	}
}

func (m *Module) refreshBoard(ctx context.Context, boardKey string) {
	entry, ok := knownBoard(boardKey)
	if !ok {
		return
	}

	m.loadMu.Lock()
	if m.loading[boardKey] {
		m.loadMu.Unlock()
		return
	}
	m.loading[boardKey] = true
	m.loadMu.Unlock()

	defer func() {
		m.loadMu.Lock()
		delete(m.loading, boardKey)
		m.loadMu.Unlock()
	}()

	m.mu.Lock()
	if state, exists := m.state[boardKey]; exists {
		if len(state.entries) == 0 {
			state.state = stateLoading
		}
		state.loadedRows = 0
	}
	m.mu.Unlock()

	entries, publishedAt, err := entry.fetch(ctx, m.client, m.endpoints, m.sourceToken())
	if err != nil {
		if errors.Is(err, context.Canceled) {
			return
		}
		log.Printf("[benchmark] Abgleich von %q fehlgeschlagen: %v", boardKey, err)
		m.mu.Lock()
		if state, exists := m.state[boardKey]; exists {
			state.loadErr = describeError(err)
			if len(state.entries) == 0 {
				state.state = stateError
			} else {

				state.state = stateReady
			}
		}
		m.mu.Unlock()
		return
	}

	fetchedAt := time.Now().UTC()
	m.replaceEntries(boardKey, entries, fetchedAt, publishedAt, false)

	if path := m.snapshotPath(boardKey); path != "" {
		if err := saveSnapshot(path, boardKey, entries, fetchedAt, publishedAt); err != nil {
			log.Printf("[benchmark] Abzug %q konnte nicht geschrieben werden: %v", boardKey, err)
		}
	}
	log.Printf("[benchmark] %s: %d Eintraege geladen (Stand %s)", boardKey, len(entries), publishedAt)
}

func (m *Module) sourceToken() string {
	if m.settings == nil {
		return ""
	}
	if err := m.settings.Load(); err != nil {
		return ""
	}
	return strings.TrimSpace(m.settings.Get().HuggingFaceToken)
}

func (m *Module) snapshotState(boardKey string) ([]Entry, BoardInfo) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	state, ok := m.state[boardKey]
	if !ok {
		return nil, m.boardInfoLocked(boardKey)
	}
	entries := make([]Entry, len(state.entries))
	copy(entries, state.entries)
	return entries, m.boardInfoLocked(boardKey)
}

func (m *Module) boardInfoLocked(boardKey string) BoardInfo {
	entry, ok := knownBoard(boardKey)
	if !ok {
		return BoardInfo{Key: boardKey, Source: SourceInfo{State: stateEmpty}}
	}

	info := entry.info
	source := info.Source
	source.State = stateEmpty

	if state, exists := m.state[boardKey]; exists {
		source.FromCache = state.fromCache
		source.Entries = len(state.entries)
		source.Models = len(state.byModel)
		source.State = state.state
		source.Error = state.loadErr
		if state.publishedAt != "" {
			source.PublishedAt = state.publishedAt
		}
		if !state.fetchedAt.IsZero() {
			source.FetchedAt = state.fetchedAt.UTC().Format(time.RFC3339)
		}
	}
	info.Source = source
	return info
}

func (m *Module) allBoards() []BoardInfo {
	m.mu.RLock()
	defer m.mu.RUnlock()

	infos := make([]BoardInfo, 0, len(BoardOrder))
	for _, key := range BoardOrder {
		infos = append(infos, m.boardInfoLocked(key))
	}
	return infos
}

func (m *Module) metricStats(boardKey string) []MetricStats {
	m.mu.RLock()
	defer m.mu.RUnlock()

	state, ok := m.state[boardKey]
	if !ok {
		return nil
	}
	stats := make([]MetricStats, len(state.metricStats))
	copy(stats, state.metricStats)
	return stats
}

func (m *Module) missingMetrics(boardKey string) []string {
	m.mu.RLock()
	defer m.mu.RUnlock()

	state, ok := m.state[boardKey]
	if !ok || len(state.entries) == 0 {
		return nil
	}
	gaps := make([]string, 0, len(state.metricStats))
	for _, stat := range state.metricStats {
		if stat.Evaluated == 0 {
			gaps = append(gaps, stat.Key)
		}
	}
	return gaps
}

func (m *Module) hubStats(ctx context.Context, modelID string) (*HubStats, []CardResult) {
	key := strings.ToLower(strings.TrimSpace(modelID))
	if key == "" || !strings.Contains(key, "/") {

		return nil, nil
	}

	m.hubMu.Lock()
	cached, found := m.hubCache[key]
	m.hubMu.Unlock()
	if found && time.Since(cached.storedAt) < hubCacheTTL {
		return cached.stats, cached.results
	}

	token := ""
	if m.settings != nil {
		if err := m.settings.Load(); err == nil {
			token = m.settings.Get().HuggingFaceToken
		}
	}

	stats, results, err := fetchHubStats(ctx, m.client, m.endpoints.hub, modelID, token)
	if err != nil {

		log.Printf("[benchmark] Hub-Abfrage fuer %q fehlgeschlagen: %v", modelID, err)
		return nil, nil
	}

	m.hubMu.Lock()
	if len(m.hubCache) >= hubCacheCapacity {
		m.hubCache = make(map[string]hubCacheEntry, hubCacheCapacity)
	}
	m.hubCache[key] = hubCacheEntry{stats: stats, results: results, storedAt: time.Now()}
	m.hubMu.Unlock()

	return stats, results
}
