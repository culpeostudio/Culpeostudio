// Package providers exposes user-owned AI provider connections over gRPC.
//
// It keeps credentials and provider metadata behind a single generic contract:
// a new OpenAI-compatible vendor does not need a client enum or a schema
// migration. The backing Manager encrypts API keys before writing them to
// disk; this module only exposes redacted connection data.
package providers

import (
	"context"
	"errors"
	"log"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/internal/providerconn"
	"github.com/culpeohq/backend/internal/security"
)

const (
	providerRefreshInterval          = 6 * time.Hour
	providerRefreshTimeout           = 45 * time.Second
	providerBackgroundRefreshTimeout = 20 * time.Second
	maxProviderBackgroundTargets     = 64
	providerBackgroundSyncWorkers    = 4
)

// Module owns the provider connection manager and its bounded catalogue
// refresh loop. Synchronisation only fetches metadata; it never downloads a
// cloud model and never activates one for chat without an explicit user
// action.
type Module struct {
	manager *providerconn.Manager
	limiter *security.RateLimiter
	initErr error

	refreshContext context.Context
	refreshCancel  context.CancelFunc
	done           chan struct{}
	stopOnce       sync.Once
	lifecycleMu    sync.Mutex
	started        bool
}

func New(settingsFile, encryptionSecret string) *Module {
	settingsFile = strings.TrimSpace(settingsFile)
	if settingsFile == "" {
		settingsFile = appsettings.DefaultSettingsFile
	}
	manager, err := providerconn.NewManager(
		filepath.Join(filepath.Dir(settingsFile), "provider_connections.json"),
		encryptionSecret,
	)
	refreshContext, refreshCancel := context.WithCancel(context.Background())
	return &Module{
		manager:        manager,
		limiter:        security.NewRateLimiter(30, time.Minute),
		initErr:        err,
		refreshContext: refreshContext,
		refreshCancel:  refreshCancel,
		done:           make(chan struct{}),
	}
}

func (m *Module) Name() string { return "providers" }

// Manager is intentionally exported for Scout, which needs the decrypted
// connection only while it opens a chat stream. It is not exposed to gRPC
// clients or the Flutter app.
func (m *Module) Manager() *providerconn.Manager {
	if m == nil {
		return nil
	}
	return m.manager
}

func (m *Module) Limiter() *security.RateLimiter {
	if m == nil {
		return nil
	}
	return m.limiter
}

func (m *Module) Initialize() error {
	if m == nil {
		return errors.New("Provider-Modul ist nicht initialisiert")
	}
	m.lifecycleMu.Lock()
	defer m.lifecycleMu.Unlock()
	if m.started {
		return nil
	}
	if m.initErr != nil {
		return m.initErr
	}
	if m.manager == nil {
		return errors.New("Provider-Verwaltung ist nicht initialisiert")
	}
	if err := m.manager.Load(); err != nil {
		return err
	}
	m.started = true
	go m.refreshLoop()
	return nil
}

func (m *Module) Shutdown() error {
	if m == nil {
		return nil
	}
	m.stopOnce.Do(func() {
		if m.refreshCancel != nil {
			m.refreshCancel()
		}
	})
	m.lifecycleMu.Lock()
	started := m.started
	m.lifecycleMu.Unlock()
	if started {
		select {
		case <-m.done:
		case <-time.After(2 * time.Second):
			log.Printf("[providers] Modell-Synchronisierung beendet nicht rechtzeitig")
		}
	}
	if m.limiter != nil {
		m.limiter.Close()
	}
	return nil
}

func (m *Module) refreshLoop() {
	defer close(m.done)
	m.refreshAllCatalogues(m.refreshContext)

	ticker := time.NewTicker(providerRefreshInterval)
	defer ticker.Stop()
	for {
		select {
		case <-m.refreshContext.Done():
			return
		case <-ticker.C:
			m.refreshAllCatalogues(m.refreshContext)
		}
	}
}

func (m *Module) refreshAllCatalogues(ctx context.Context) {
	if m.manager == nil {
		return
	}
	targets, err := m.manager.SyncTargets()
	if err != nil {
		log.Printf("[providers] Synchronisierungsziele konnten nicht gelesen werden: %v", err)
		return
	}
	if ctx == nil || ctx.Err() != nil {
		return
	}
	sort.Slice(targets, func(i, j int) bool {
		if targets[i].UserID == targets[j].UserID {
			return targets[i].ConnectionID < targets[j].ConnectionID
		}
		return targets[i].UserID < targets[j].UserID
	})
	if len(targets) > maxProviderBackgroundTargets {
		log.Printf("[providers] Hintergrund-Synchronisierung auf %d Verbindungen pro Lauf begrenzt", maxProviderBackgroundTargets)
		targets = targets[:maxProviderBackgroundTargets]
	}
	if len(targets) == 0 {
		return
	}

	workers := providerBackgroundSyncWorkers
	if workers > len(targets) {
		workers = len(targets)
	}
	jobs := make(chan providerconn.SyncTarget)
	var waitGroup sync.WaitGroup
	for index := 0; index < workers; index++ {
		waitGroup.Add(1)
		go func() {
			defer waitGroup.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case target, open := <-jobs:
					if !open {
						return
					}
					syncCtx, cancel := context.WithTimeout(ctx, providerBackgroundRefreshTimeout)
					_, _, syncErr := m.manager.SyncConnection(syncCtx, target.UserID, target.ConnectionID)
					cancel()
					if syncErr != nil && ctx.Err() == nil {
						// The Manager stores a short, redacted reason on the
						// connection. Do not include endpoints or key material in
						// process logs.
						log.Printf("[providers] Modellkatalog für Verbindung %s konnte nicht aktualisiert werden", target.ConnectionID)
					}
				}
			}
		}()
	}

	for _, target := range targets {
		select {
		case <-ctx.Done():
			close(jobs)
			waitGroup.Wait()
			return
		case jobs <- target:
		}
	}
	close(jobs)
	waitGroup.Wait()
}
