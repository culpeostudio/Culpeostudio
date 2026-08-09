package engine

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/internal/modelcatalog"
)

type EngineModule struct {
	settingsFile string
	settings     *appsettings.Store
	dataDir      string
	stateFile    string
	runtimeRoot  string
	gatewayBind  string

	mu                  sync.RWMutex
	lifecycleGate       chan struct{}
	spawnGateMu         sync.Mutex
	startScheduleMu     sync.Mutex
	modelDir            string
	models              []modelcatalog.ModelRecord
	modelsByID          map[string]modelcatalog.ModelRecord
	instances           map[string]*EngineInstance
	operations          map[string]*EngineOperation
	prewarmRecipes      map[string]bool
	planRevision        int64
	shuttingDown        bool
	guardState          GuardState
	prewarmMu           sync.Mutex
	prewarmPending      map[string]queuedRuntimePrewarm
	prewarmActive       *activeRuntimePrewarm
	prewarmWorker       bool
	prewarmForeground   int
	prewarmPauseRunning bool
	prewarmWake         chan struct{}
	prewarmHardware     func(context.Context) hardware.Snapshot

	installer   *engineruntime.Installer
	supervisor  *engineruntime.Supervisor
	keys        *engineKeyStore
	trust       *remoteCodeStore
	preferences *enginePreferenceStore
	presets     *enginePresetStore
	events      *engineEventHub
	gateway     *localGateway
	gatewayURL  string
	localClient *http.Client

	startQueue                *startAdmissionQueue
	startQueueTimeout         time.Duration
	startExecutions           map[string]string
	inferenceMu               sync.Mutex
	inferenceGates            map[string]*inferenceGate
	inferenceQueueTimeout     time.Duration
	inferenceStatsMu          sync.Mutex
	inferenceStats            map[string]*instanceInferenceStats
	runtimeInstallMu          sync.Mutex
	runtimeInstallWaiters     map[string]int
	runtimeInstallCanceling   map[string]bool
	runtimeInstallGuardCancel bool
	stopReaperMu              sync.Mutex
	stopReapers               map[string]bool
	confirmedStopMu           sync.Mutex
	confirmedStops            map[string]confirmedStopTarget
	idleTimeout               time.Duration
	maintenanceStop           chan struct{}
	maintenanceStopOnce       sync.Once

	crashMu      sync.Mutex
	crashHistory map[string]*crashHistory

	quantizeMu    sync.Mutex
	quantizeJobs  map[string]*quantizeJob
	quantizeTypes []engineruntime.QuantizationType
}

func New(settingsFile ...string) *EngineModule {
	path := appsettings.DefaultSettingsFile
	if len(settingsFile) > 0 && strings.TrimSpace(settingsFile[0]) != "" {
		path = strings.TrimSpace(settingsFile[0])
	}
	dataDir := filepath.Dir(path)
	gatewayBind := strings.TrimSpace(os.Getenv("ENGINE_GATEWAY_ADDR"))
	if gatewayBind == "" {
		gatewayBind = "127.0.0.1:8091"
	}
	module := &EngineModule{
		settingsFile: path, settings: appsettings.NewStore(path), dataDir: dataDir,
		stateFile:   filepath.Join(dataDir, "engine_instances.json"),
		runtimeRoot: filepath.Join(dataDir, "engine-runtimes"),
		gatewayBind: gatewayBind, modelsByID: map[string]modelcatalog.ModelRecord{},
		instances: map[string]*EngineInstance{}, operations: map[string]*EngineOperation{},
		prewarmRecipes: map[string]bool{}, prewarmPending: map[string]queuedRuntimePrewarm{}, prewarmWake: make(chan struct{}, 1),
		events:      newEngineEventHub(),
		localClient: newLoopbackHTTPClient(),
		startQueue:  newStartAdmissionQueue(), startQueueTimeout: 10 * time.Minute, startExecutions: map[string]string{},
		inferenceGates: map[string]*inferenceGate{}, inferenceQueueTimeout: 120 * time.Second,
		runtimeInstallWaiters: map[string]int{}, runtimeInstallCanceling: map[string]bool{}, stopReapers: map[string]bool{},
		idleTimeout: 15 * time.Minute, guardState: GuardNormal, maintenanceStop: make(chan struct{}),
		crashHistory: map[string]*crashHistory{}, quantizeJobs: map[string]*quantizeJob{},
	}
	if configured := engineDurationFromEnv("ENGINE_IDLE_TIMEOUT"); configured != nil {
		module.idleTimeout = *configured
	}
	if configured := engineDurationFromEnv("ENGINE_START_QUEUE_TIMEOUT"); configured != nil {
		module.startQueueTimeout = *configured
	}
	if configured := engineDurationFromEnv("ENGINE_INFERENCE_QUEUE_TIMEOUT"); configured != nil {
		module.inferenceQueueTimeout = *configured
	}
	module.lifecycleGate = make(chan struct{}, 1)
	module.lifecycleGate <- struct{}{}
	return module
}

func (m *EngineModule) Name() string { return "engine" }

// engineDurationFromEnv reads one of the timeouts that used to be compiled in.
// An unparsable or non-positive value is ignored rather than fatal: a typo in
// an environment variable should not stop the engine from starting.
func engineDurationFromEnv(name string) *time.Duration {
	raw := strings.TrimSpace(os.Getenv(name))
	if raw == "" {
		return nil
	}
	value, err := time.ParseDuration(raw)
	if err != nil || value <= 0 {
		log.Printf("[engine] ignoring %s=%q: expected a positive duration such as 20m", name, raw)
		return nil
	}
	return &value
}

func (m *EngineModule) Initialize() error {
	if err := m.settings.Load(); err != nil {
		return fmt.Errorf("Engine-Settings laden: %w", err)
	}
	settings := m.settings.Get()
	modelDir := strings.TrimSpace(settings.ModelDir)
	if modelDir == "" {
		modelDir = appsettings.DefaultModelDir
	}
	if runtime.GOOS != "windows" && appsettings.LooksLikeWindowsPath(modelDir) {
		return fmt.Errorf("model_dir ist ein Windows-Pfad; bitte einen lokalen %s-Pfad konfigurieren", runtime.GOOS)
	}
	absModelDir, err := filepath.Abs(filepath.Clean(modelDir))
	if err != nil {
		return err
	}
	if err := os.MkdirAll(absModelDir, 0o755); err != nil {
		return fmt.Errorf("Modellordner anlegen: %w", err)
	}
	if resolved, resolveErr := filepath.EvalSymlinks(absModelDir); resolveErr == nil {
		absModelDir = resolved
	}
	m.modelDir = absModelDir
	if cleanupErr := cleanupStagedModelDeletions(absModelDir); cleanupErr != nil {
		log.Printf("engine model deletion cleanup will be retried later: %v", cleanupErr)
	}

	if _, err := os.Stat(m.settingsFile); err == nil {
		_ = os.Chmod(m.settingsFile, 0o600)
	}
	if err := os.MkdirAll(m.dataDir, 0o700); err != nil {
		return err
	}
	if m.keys, err = newEngineKeyStore(filepath.Join(m.dataDir, "engine_keys.json")); err != nil {
		return err
	}
	if m.trust, err = newRemoteCodeStore(filepath.Join(m.dataDir, "engine_remote_code_trust.json")); err != nil {
		return err
	}
	if m.preferences, err = newEnginePreferenceStore(filepath.Join(m.dataDir, "engine_user_preferences.json")); err != nil {
		return err
	}
	if m.presets, err = newEnginePresetStore(filepath.Join(m.dataDir, "engine_presets.json")); err != nil {
		return err
	}
	if m.installer, err = engineruntime.NewInstaller(m.runtimeRoot, nil, nil); err != nil {
		return err
	}
	m.installer.SetSpawnAdmission(m.acquireWorkerSpawn)
	// A large model on a slow disk can take far longer than ten minutes to
	// report healthy, and there was no way to say so.
	healthTimeout := 10 * time.Minute
	if configured := engineDurationFromEnv("ENGINE_HEALTH_TIMEOUT"); configured != nil {
		healthTimeout = *configured
	}
	m.supervisor = engineruntime.NewSupervisor(engineruntime.SupervisorOptions{

		HealthTimeout: healthTimeout, HealthInterval: 300 * time.Millisecond, GracePeriod: 30 * time.Second,
		ResourceLimiter: engineruntime.NewNativeResourceLimiter(),
	})
	if err := m.loadState(); err != nil {
		return err
	}
	if _, err := m.rescan(context.Background()); err != nil {
		return err
	}
	if !strings.EqualFold(m.gatewayBind, "disabled") {
		m.gateway = newLocalGateway(m.keys, gatewayDependencies{
			lookup:      m.gatewayLookup,
			list:        m.gatewayList,
			acquire:     m.gatewayAcquireInference,
			ensureReady: m.gatewayEnsureReady,
			recordUsage: m.gatewayRecordUsage,
		})
		address, err := m.gateway.start(m.gatewayBind)
		if err != nil {
			return fmt.Errorf("lokales OpenAI-Gateway starten: %w", err)
		}
		m.gatewayURL = "http://" + address
	}
	bus.Get().On(bus.EventModelDownloaded, func(bus.Event) {
		m.mu.RLock()
		stopping := m.shuttingDown
		m.mu.RUnlock()
		if !stopping {
			_, _ = m.rescan(context.Background())
			m.events.publish("models_rescanned", map[string]interface{}{"reason": "download_completed"})
			m.scheduleRuntimePrewarm("neues Modell")
		}
	})
	m.scheduleRuntimePrewarm("App-Start")
	go m.runResourceMaintenance()
	go m.restoreAutostart()
	return nil
}

func (m *EngineModule) Shutdown() error {
	m.maintenanceStopOnce.Do(func() { close(m.maintenanceStop) })
	m.spawnGateMu.Lock()
	m.mu.Lock()
	m.shuttingDown = true
	cancels := []context.CancelFunc{}
	for _, operation := range m.operations {
		if operation.cancel != nil && operation.State != "completed" && operation.State != "failed" && operation.State != "cancelled" {
			cancels = append(cancels, operation.cancel)
		}
	}
	_ = m.persistLocked()
	m.mu.Unlock()
	m.spawnGateMu.Unlock()
	for _, cancelOperation := range cancels {
		cancelOperation()
	}
	ctx, cancel := context.WithTimeout(context.Background(), 35*time.Second)
	defer cancel()
	var failures []string
	lifecycleCtx, cancelLifecycle := context.WithTimeout(ctx, 5*time.Second)
	releaseLifecycle, lifecycleErr := m.acquireLifecycle(lifecycleCtx, true)
	cancelLifecycle()
	if lifecycleErr != nil {
		failures = append(failures, "Engine-Lifecycle wurde nicht rechtzeitig frei: "+lifecycleErr.Error())
	} else {
		defer releaseLifecycle()
	}
	if m.installer != nil {
		if err := m.installer.CloseContext(ctx); err != nil {
			failures = append(failures, err.Error())
		}
	}
	if m.gateway != nil {
		if err := m.gateway.shutdown(ctx); err != nil {
			failures = append(failures, err.Error())
		}
	}
	if m.supervisor != nil {
		if err := m.supervisor.Shutdown(ctx); err != nil {
			failures = append(failures, err.Error())
		}
	}
	if m.localClient != nil {
		m.localClient.CloseIdleConnections()
	}
	if len(failures) > 0 {
		return errors.New(strings.Join(failures, "; "))
	}
	return nil
}

func (m *EngineModule) rescan(ctx context.Context) ([]modelcatalog.ModelRecord, error) {
	if err := m.settings.Load(); err != nil {
		return nil, err
	}
	dir := strings.TrimSpace(m.settings.Get().ModelDir)
	if dir == "" {
		dir = appsettings.DefaultModelDir
	}
	abs, err := filepath.Abs(filepath.Clean(dir))
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(abs, 0o755); err != nil {
		return nil, err
	}
	if resolved, resolveErr := filepath.EvalSymlinks(abs); resolveErr == nil {
		abs = resolved
	}
	records, err := modelcatalog.Scan(ctx, abs)
	if err != nil {
		return nil, err
	}
	byID := make(map[string]modelcatalog.ModelRecord, len(records))
	for _, record := range records {
		byID[record.ID] = record
	}
	m.mu.Lock()
	m.modelDir = abs
	m.models = append([]modelcatalog.ModelRecord(nil), records...)
	m.modelsByID = byID
	m.mu.Unlock()
	return records, nil
}
