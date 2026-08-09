package engine

import (
	"testing"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func newCrashTestModule(instance *EngineInstance) *EngineModule {
	module := &EngineModule{
		instances:       map[string]*EngineInstance{},
		operations:      map[string]*EngineOperation{},
		crashHistory:    map[string]*crashHistory{},
		maintenanceStop: make(chan struct{}),
		events:          newEngineEventHub(),
		idleTimeout:     15 * time.Minute,
	}
	if instance != nil {
		module.instances[instance.ID] = instance
	}
	return module
}

// A crashed instance is left alone unless its owner asked for the restart. The
// alternative - restarting by default - turns a model that cannot load into a
// loop nobody chose.
func TestCrashRestartIsOptIn(t *testing.T) {
	config := defaultEngineConfig()
	instance := &EngineInstance{
		ID: "inst", State: engineruntime.StateFailed,
		RequestedConfig: config, EffectiveConfig: config,
		workerGeneration: 3,
	}
	module := newCrashTestModule(instance)

	module.considerCrashRestart("inst")
	module.crashMu.Lock()
	history := module.crashHistory["inst"]
	module.crashMu.Unlock()
	if history != nil {
		t.Fatal("a restart must not be scheduled without the opt-in")
	}

	// With the box ticked the backoff starts counting.
	config.RestartOnCrash = true
	module.mu.Lock()
	module.instances["inst"].RequestedConfig = config
	module.mu.Unlock()

	module.considerCrashRestart("inst")
	module.crashMu.Lock()
	history = module.crashHistory["inst"]
	failures, restarting := 0, false
	if history != nil {
		failures, restarting = history.failures, history.restarting
	}
	module.crashMu.Unlock()
	if history == nil || failures != 1 || !restarting {
		t.Fatalf("expected one pending restart, got %+v", history)
	}

	// A second crash while the first restart is still pending must not stack a
	// second timer on top of it.
	module.considerCrashRestart("inst")
	module.crashMu.Lock()
	failures = module.crashHistory["inst"].failures
	module.crashMu.Unlock()
	if failures != 1 {
		t.Fatalf("a pending restart must not be scheduled twice, failures=%d", failures)
	}

	close(module.maintenanceStop)
}

func TestCrashBackoffGrowsAndResetsOnRecovery(t *testing.T) {
	config := defaultEngineConfig()
	config.RestartOnCrash = true
	instance := &EngineInstance{
		ID: "inst", State: engineruntime.StateFailed,
		RequestedConfig: config, EffectiveConfig: config,
	}
	module := newCrashTestModule(instance)
	defer close(module.maintenanceStop)

	// Drive the counter directly: the delays themselves are minutes long, and
	// what matters here is that repeated failures climb the ladder.
	for attempt := 1; attempt <= 3; attempt++ {
		module.considerCrashRestart("inst")
		module.crashMu.Lock()
		module.crashHistory["inst"].restarting = false
		failures := module.crashHistory["inst"].failures
		module.crashMu.Unlock()
		if failures != attempt {
			t.Fatalf("attempt %d recorded as %d", attempt, failures)
		}
	}

	delayFor := func(failures int) time.Duration {
		return crashRestartBackoff[minInt(failures, len(crashRestartBackoff)-1)]
	}
	if delayFor(0) >= delayFor(2) {
		t.Fatal("the backoff must grow with repeated failures")
	}
	// The ladder must not run off its end.
	if delayFor(99) != crashRestartBackoff[len(crashRestartBackoff)-1] {
		t.Fatal("the last backoff step should repeat rather than panic")
	}

	// An instance that came up again starts from scratch, so an unrelated crash
	// an hour later is not treated as the fourth attempt of an old incident.
	module.noteInstanceRecovered("inst")
	module.crashMu.Lock()
	_, exists := module.crashHistory["inst"]
	module.crashMu.Unlock()
	if exists {
		t.Fatal("a recovered instance keeps no crash history")
	}
}

// The reconcile pass is a safety net, not a second opinion: it must never touch
// an instance whose own operation is mid-flight.
func TestReconcileLeavesInstancesWithActiveOperationsAlone(t *testing.T) {
	instance := &EngineInstance{ID: "inst", State: engineruntime.StateReady, BaseURL: "http://127.0.0.1:1"}
	module := newCrashTestModule(instance)
	defer close(module.maintenanceStop)
	module.startExecutions = map[string]string{"inst": "op_1"}
	module.operations["op_1"] = &EngineOperation{ID: "op_1", InstanceID: "inst", Type: "start", State: "running"}

	module.mu.Lock()
	protected := module.activeStartOperationLocked("inst") != nil
	module.mu.Unlock()
	if !protected {
		t.Fatal("a running start operation must be visible to the reconcile pass")
	}

	// No supervisor at all: the pass has nothing to compare against and must
	// leave the state exactly as it found it.
	module.reconcileWorkers()
	if got, _ := module.getInstance("inst"); got.State != engineruntime.StateReady || got.BaseURL == "" {
		t.Fatalf("reconcile altered an instance it should not have touched: %+v", got)
	}
}
