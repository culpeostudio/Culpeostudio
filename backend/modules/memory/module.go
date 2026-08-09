// Package memorymodule serves the memory service over gRPC and wires it into
// the chat flow. What is left on HTTP is the memory viewer and the queries the
// page makes; see viewer.go.
package memorymodule

import (
	"sync"
	"time"

	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memorycapture"
	"github.com/culpeohq/backend/internal/memoryembed"
	"github.com/culpeohq/backend/internal/memorystore"
	"github.com/culpeohq/backend/internal/memorytoken"
	"github.com/culpeohq/backend/internal/memoryvector"
	"github.com/culpeohq/backend/internal/memoryviewer"
	"github.com/culpeohq/backend/internal/security"
)

type MaintenanceConfig struct {
	ReindexInterval     time.Duration
	ReindexBatchSize    int
	ReindexConcurrency  int
	SoftDeleteRetention time.Duration
}

type MemoryModule struct {
	store            *memorystore.SQLiteStore
	vector           *memoryvector.Index
	hub              *memoryviewer.Hub
	service          *memory.Service
	capture          *memorycapture.Service
	apiToken         string
	defaultUserID    string
	captureRateLimit int
	captureLimiter   *security.RateLimiter
	chatWindowSize   int
	chatOverlapSize  int
	viewerTitle      string
	maintenance      MaintenanceConfig

	stopReindex     chan struct{}
	stopMaintenance chan struct{}

	ticketsMu sync.Mutex
	tickets   map[string]ticketInfo
}

func New(sqlitePath, vectorPath string, embedCfg memoryembed.Config, projectTag, apiToken, defaultUserID string, contextBudget int, policy memory.CompressionPolicy, captureRateLimit int, chatWindowSize int, chatOverlapSize int, viewerTitle string, maintenance MaintenanceConfig, tokenizerFamily, tokenizerModelPath string) *MemoryModule {
	store := memorystore.NewSQLiteStore(sqlitePath)
	activeBackend, hashBackend := memoryembed.Select(embedCfg)
	vector := memoryvector.New(store, activeBackend, hashBackend, vectorPath)
	hub := memoryviewer.NewHub()

	options := memory.Options{
		ProjectTag:          projectTag,
		DefaultUserID:       defaultUserID,
		ContextBudgetTokens: contextBudget,
		Policy:              policy,
		TokenizerFamily:     memorytoken.Family(tokenizerFamily),
		TokenizerModelPath:  tokenizerModelPath,
	}
	service := memory.NewService(store, vector, hub, options)
	capture := memorycapture.New(service, chatWindowSize, chatOverlapSize)
	service.RegisterCleanupHandler(func(sessionID string) {
		capture.ClearSession(sessionID)
	})
	captureLimiter := security.NewRateLimiter(captureRateLimit, time.Minute)
	return &MemoryModule{
		store:            store,
		vector:           vector,
		hub:              hub,
		service:          service,
		capture:          capture,
		apiToken:         apiToken,
		defaultUserID:    defaultUserID,
		captureRateLimit: captureRateLimit,
		captureLimiter:   captureLimiter,
		chatWindowSize:   chatWindowSize,
		chatOverlapSize:  chatOverlapSize,
		viewerTitle:      viewerTitle,
		maintenance:      maintenance,
		tickets:          make(map[string]ticketInfo),
	}
}

func (m *MemoryModule) Name() string { return "memory" }

// CaptureLimiter is the budget the capture calls share. The gRPC interceptor
// applies it to the capture methods, the way the Fiber middleware applied it to
// the capture route group.
func (m *MemoryModule) CaptureLimiter() *security.RateLimiter { return m.captureLimiter }

func (m *MemoryModule) Initialize() error {
	if err := m.service.Initialize(); err != nil {
		return err
	}

	m.stopReindex = make(chan struct{})
	go m.vector.RunReindexer(m.stopReindex, m.maintenance.ReindexInterval, m.maintenance.ReindexBatchSize, m.maintenance.ReindexConcurrency)

	m.stopMaintenance = make(chan struct{})
	go m.store.RunMaintenance(m.stopMaintenance, memorystore.MaintenanceConfig{
		SoftDeleteRetention: m.maintenance.SoftDeleteRetention,
	})
	return nil
}

func (m *MemoryModule) Shutdown() error {
	if m.stopReindex != nil {
		close(m.stopReindex)
	}
	if m.stopMaintenance != nil {
		close(m.stopMaintenance)
	}
	if m.captureLimiter != nil {
		m.captureLimiter.Close()
	}
	if m.hub != nil {
		m.hub.Close()
	}
	return m.service.Close()
}
