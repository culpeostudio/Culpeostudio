// Package memoryvector implements the vector search layer on top of SQLite using sqlite-vec.
package memoryvector

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/fillyengine/backend/internal/memory"
	"github.com/fillyengine/backend/internal/memoryembed"
	"github.com/fillyengine/backend/internal/memorystore"
)

const (
	candidateFill             = 256
	defaultReindexBatch       = 64
	defaultReindexConcurrency = 4
)

type Index struct {
	store          *memorystore.SQLiteStore
	active         memoryembed.Backend
	hash           memoryembed.Backend
	legacyJSONPath string

	embeddingHits uint64
	hashHits      uint64
}

func New(store *memorystore.SQLiteStore, active, hash memoryembed.Backend, legacyJSONPath string) *Index {
	if hash == nil {
		hash = memoryembed.NewHashBackend(128)
	}
	if active == nil {
		active = hash
	}
	return &Index{
		store:          store,
		active:         active,
		hash:           hash,
		legacyJSONPath: legacyJSONPath,
	}
}

func (i *Index) ActiveBackend() memoryembed.Backend { return i.active }

// Initialize dynamically creates/recreates the virtual tables vec_active and vec_hash
// based on backend dimensions, and runs the legacy JSON migration if required.
func (i *Index) Initialize() error {
	log.Printf("[memory-vector] Initialisiere Vektor-Index mit Backend=%s, Modell=%s, Dimension=%d", i.active.Name(), i.active.Model(), i.active.Dim())
	// 1. Setup vec_hash virtual table
	hashDim := i.hash.Dim()
	if err := i.store.CreateVectorIndexTable("vec_hash", hashDim); err != nil {
		return fmt.Errorf("failed to initialize vec_hash: %w", err)
	}
	if err := i.store.SyncVectorIndex("vec_hash", i.hash.Model()); err != nil {
		return fmt.Errorf("failed to sync vec_hash: %w", err)
	}

	// 2. Setup vec_active virtual table
	activeDim := i.active.Dim()
	if err := i.store.CreateVectorIndexTable("vec_active", activeDim); err != nil {
		return fmt.Errorf("failed to initialize vec_active: %w", err)
	}
	if err := i.store.SyncVectorIndex("vec_active", i.active.Model()); err != nil {
		return fmt.Errorf("failed to sync vec_active: %w", err)
	}

	// 3. Migrate legacy JSON sidecar index if it exists
	if strings.TrimSpace(i.legacyJSONPath) == "" {
		return nil
	}
	content, err := os.ReadFile(i.legacyJSONPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	var legacy map[string][]float64
	if err := json.Unmarshal(content, &legacy); err != nil {
		return fmt.Errorf("legacy vector index unlesbar: %w", err)
	}
	vectors := make(map[string][]float32, len(legacy))
	for docID, values := range legacy {
		vector := make([]float32, len(values))
		for idx, value := range values {
			vector[idx] = float32(value)
		}
		vectors[docID] = vector
	}
	model := i.hash.Model()
	imported, err := i.store.ImportLegacyVectors(vectors, model)
	if err != nil {
		return fmt.Errorf("legacy vector migration failed: %w", err)
	}
	migratedPath := i.legacyJSONPath + ".migrated"
	if err := os.Rename(i.legacyJSONPath, migratedPath); err != nil {
		return fmt.Errorf("legacy vector index rename failed: %w", err)
	}
	log.Printf("[memory-vector] JSON-Index migriert: %d/%d Vektoren nach SQLite uebernommen, Datei -> %s", imported, len(vectors), migratedPath)
	return nil
}

// Upsert embeds the document body with the active backend and stores vector,
// model metadata and populates virtual tables.
func (i *Index) Upsert(document memory.SearchDocument) error {
	backend := i.active
	vector, err := backend.Embed(document.Body)
	if err != nil && backend.Model() != i.hash.Model() {
		log.Printf("[memory-vector] embed via %s fehlgeschlagen (%v), nutze hash fallback fuer doc=%s", backend.Name(), err, document.DocID)
		backend = i.hash
		vector, err = backend.Embed(document.Body)
	}
	if err != nil {
		return err
	}
	return i.store.UpsertEmbedding(memorystore.EmbeddingRecord{
		DocID:     document.DocID,
		Embedding: vector,
		Model:     backend.Model(),
	})
}

func (i *Index) Delete(docID string) error {
	return i.store.DeleteEmbedding(docID)
}

// Search queries the active model's virtual table, and if a model switch is in flight,
// also queries the hash fallback table, then merges the similarity scores.
func (i *Index) Search(query string, filters memory.SearchFilters, limit int) ([]memory.VectorHit, error) {
	if strings.TrimSpace(query) == "" {
		return []memory.VectorHit{}, nil
	}
	if limit <= 0 {
		limit = 10
	}
	merged := map[string]memory.VectorHit{}

	activeModel := i.active.Model()
	queryVector, err := i.active.Embed(query)
	if err != nil {
		log.Printf("[memory-vector] query embed via %s fehlgeschlagen (%v), suche nur ueber hash", i.active.Name(), err)
	} else {
		if err := i.scoreModel(activeModel, queryVector, filters, "embedding", merged); err != nil {
			return nil, err
		}
	}

	if activeModel != i.hash.Model() {
		hashVector, hashErr := i.hash.Embed(query)
		if hashErr == nil {
			if err := i.scoreModel(i.hash.Model(), hashVector, filters, "hash", merged); err != nil {
				return nil, err
			}
		}
	}

	results := make([]memory.VectorHit, 0, len(merged))
	for _, hit := range merged {
		results = append(results, hit)
	}
	sort.Slice(results, func(a, b int) bool {
		return results[a].Score > results[b].Score
	})
	if len(results) > limit {
		results = results[:limit]
	}
	for _, hit := range results {
		if hit.ScoredBy == "hash" {
			atomic.AddUint64(&i.hashHits, 1)
		} else {
			atomic.AddUint64(&i.embeddingHits, 1)
		}
	}
	return results, nil
}

func (i *Index) scoreModel(model string, queryVector []float32, filters memory.SearchFilters, scoredBy string, merged map[string]memory.VectorHit) error {
	candidates, err := i.store.CandidateDocuments(model, queryVector, filters, candidateFill)
	if err != nil {
		return err
	}
	for _, candidate := range candidates {
		score := memoryembed.CosineSimilarity(queryVector, candidate.Embedding)
		if score <= 0 {
			continue
		}
		existing, ok := merged[candidate.Document.DocID]
		if ok && existing.Score >= score {
			continue
		}
		merged[candidate.Document.DocID] = memory.VectorHit{
			DocID:    candidate.Document.DocID,
			Score:    score,
			ScoredBy: scoredBy,
		}
	}
	return nil
}

// ReindexBatch re-embeds one batch of documents whose stored embedding does
// not come from the active model. Embeds run concurrently (bounded by
// concurrency) since the embedding call is the slow, network-bound step for
// the sidecar/Ollama/API backends; the actual write stays a single SQLite
// transaction. A document whose embed call fails is logged and skipped
// rather than aborting the whole batch, so one flaky call cannot stall an
// entire model migration.
func (i *Index) ReindexBatch(batchSize, concurrency int) (int, int, error) {
	if batchSize <= 0 {
		batchSize = defaultReindexBatch
	}
	if concurrency <= 0 {
		concurrency = defaultReindexConcurrency
	}
	activeModel := i.active.Model()
	documents, err := i.store.ListDocsForReindex(activeModel, batchSize)
	if err != nil {
		return 0, 0, err
	}
	if len(documents) == 0 {
		return i.remaining(activeModel), 0, nil
	}

	records := make([]memorystore.EmbeddingRecord, len(documents))
	ok := make([]bool, len(documents))
	sem := make(chan struct{}, concurrency)
	var wg sync.WaitGroup
	for idx, document := range documents {
		wg.Add(1)
		sem <- struct{}{}
		go func(idx int, document memory.SearchDocument) {
			defer wg.Done()
			defer func() { <-sem }()
			vector, embedErr := i.active.Embed(document.Body)
			if embedErr != nil {
				log.Printf("[memory-reindex] embed fehlgeschlagen fuer doc=%s: %v", document.DocID, embedErr)
				return
			}
			records[idx] = memorystore.EmbeddingRecord{
				DocID:     document.DocID,
				Embedding: vector,
				Model:     activeModel,
			}
			ok[idx] = true
		}(idx, document)
	}
	wg.Wait()

	successful := make([]memorystore.EmbeddingRecord, 0, len(records))
	for idx, record := range records {
		if ok[idx] {
			successful = append(successful, record)
		}
	}
	if err := i.store.UpsertEmbeddingBatch(successful); err != nil {
		return i.remaining(activeModel), 0, err
	}
	return i.remaining(activeModel), len(successful), nil
}

// RunReindexer drives ReindexBatch until stop closes.
func (i *Index) RunReindexer(stop <-chan struct{}, interval time.Duration, batchSize, concurrency int) {
	if interval <= 0 {
		interval = 2 * time.Second
	}
	idleInterval := 30 * time.Second
	for {
		remaining, processed, err := i.ReindexBatch(batchSize, concurrency)
		wait := interval
		switch {
		case err != nil:
			log.Printf("[memory-reindex] batch fehlgeschlagen: %v (remaining=%d)", err, remaining)
			wait = idleInterval
		case processed == 0:
			wait = idleInterval
		default:
			log.Printf("[memory-reindex] batch ok: %d docs reindexiert, remaining=%d (model=%s)", processed, remaining, i.active.Model())
		}
		select {
		case <-stop:
			return
		case <-time.After(wait):
		}
	}
}

func (i *Index) remaining(model string) int {
	count, err := i.store.CountDocsNotEmbeddedWith(model)
	if err != nil {
		return -1
	}
	return count
}

func (i *Index) Metrics() memory.VectorMetrics {
	byModel, _ := i.store.CountEmbeddingsByModel()
	return memory.VectorMetrics{
		Backend:          i.active.Name(),
		Model:            i.active.Model(),
		Dim:              i.active.Dim(),
		EmbeddingHits:    atomic.LoadUint64(&i.embeddingHits),
		HashFallbackHits: atomic.LoadUint64(&i.hashHits),
		ReindexRemaining: i.remaining(i.active.Model()),
		DocsByModel:      byModel,
	}
}
