package engine

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
)

func TestUnconfirmedStopRemainsDrainingAndResourceHolding(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.maintenanceStopOnce.Do(func() { close(module.maintenanceStop) })
	module.instances["model"] = &EngineInstance{
		ID: "model", State: engineruntime.StateReady, BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret",
		ActiveRequests: 1, CreatedAt: time.Now().UTC(), UpdatedAt: time.Now().UTC(),
	}
	module.markStopUnconfirmed("model", "test_unconfirmed", "termination pending", errors.New("still alive"))
	instance := module.instances["model"]
	if instance.State != engineruntime.StateDraining || instance.Phase != "test_unconfirmed" {
		t.Fatalf("unconfirmed instance = %#v", instance)
	}
	if instance.BaseURL != "" || instance.WorkerSecret != "" {
		t.Fatal("unconfirmed worker remained open to inference")
	}
	if instance.ActiveRequests != 1 {
		t.Fatal("unconfirmed worker resources were incorrectly released")
	}
}

func TestStaleStopCompletionCannotStopReplacementGeneration(t *testing.T) {
	if os.Getenv("PHILOENGINE_ENGINE_HELPER") == "1" {
		return
	}
	supervisor := engineruntime.NewSupervisor(engineruntime.SupervisorOptions{GracePeriod: 30 * time.Second})
	workerSpec := engineruntime.ProcessSpec{
		InstanceID: "model",
		Argv:       []string{os.Args[0], "-test.run=TestEngineEmergencyWorkerHelper"},
		Environment: map[string]string{
			"PHILOENGINE_ENGINE_HELPER": "1",
		},
		HealthPath: "-",
	}
	oldHandle, err := supervisor.Start(context.Background(), workerSpec)
	if err != nil {
		t.Fatal(err)
	}

	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.supervisor = supervisor
	markerTime := time.Now().UTC()
	marker := unconfirmedStopMarker{phase: "stop_unconfirmed", updatedAt: markerTime, workerGeneration: 7}
	markedInstance := &EngineInstance{
		ID: "model", State: engineruntime.StateDraining, Phase: marker.phase,
		workerGeneration: marker.workerGeneration, UpdatedAt: markerTime, CreatedAt: markerTime,
	}
	marker.instance = markedInstance
	module.instances["model"] = markedInstance

	// This terminal old handle represents a stop that was still unconfirmed
	// when the reaper was scheduled but whose watcher completed afterwards.
	stopCtx, cancelOld := context.WithTimeout(context.Background(), 3*time.Second)
	if err := module.forceStopSupervisorConfirmed(stopCtx, "model"); err != nil {
		cancelOld()
		t.Fatal(err)
	}
	cancelOld()
	select {
	case <-oldHandle.Done():
	default:
		t.Fatal("old worker was not terminal before replacement")
	}

	newHandle, err := supervisor.Start(context.Background(), workerSpec)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		_ = supervisor.ForceStop(ctx, "model")
	}()
	if newHandle == oldHandle {
		t.Fatal("supervisor did not create a replacement generation")
	}
	t.Run("exact handle stop", func(t *testing.T) {
		ctx, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		if err := supervisor.StopHandle(ctx, oldHandle); err != nil {
			t.Fatalf("terminal old handle stop: %v", err)
		}
		if err := supervisor.ForceStopHandle(ctx, oldHandle); err != nil {
			t.Fatalf("terminal old handle force-stop: %v", err)
		}
		if state := newHandle.Snapshot().State; state != engineruntime.StateReady {
			t.Fatalf("exact old-handle stop targeted replacement: %s", state)
		}
	})
	newSnapshot := newHandle.Snapshot()
	readyAt := time.Now().UTC()
	module.mu.Lock()
	instance := module.instances["model"]
	instance.State = engineruntime.StateReady
	instance.Phase = "ready"
	instance.BaseURL = newSnapshot.BaseURL
	instance.WorkerSecret = "new-secret"
	instance.workerGeneration = marker.workerGeneration + 1
	instance.UpdatedAt = readyAt
	module.mu.Unlock()

	t.Run("background reaper", func(t *testing.T) {
		// Deterministically execute the stale tick after the supervisor entry and
		// engine state have both moved to the new generation.
		module.stopReaperMu.Lock()
		module.stopReapers["stale-test"] = true
		module.stopReaperMu.Unlock()
		module.reapUnconfirmedStop("model", oldHandle, marker, "stale-test")
	})

	t.Run("direct finalizer", func(t *testing.T) {
		// forceStopSupervisorConfirmed captured this receipt before the
		// replacement generation was committed.
		module.finalizeConfirmedStop("model", "guard_emergency", "old worker stopped")
	})

	if state := newHandle.Snapshot().State; state != engineruntime.StateReady {
		t.Fatalf("stale stop completion stopped replacement worker: %s", state)
	}
	current, _ := module.getInstance("model")
	if current.State != engineruntime.StateReady || current.workerGeneration != marker.workerGeneration+1 || current.WorkerSecret != "new-secret" {
		t.Fatalf("stale stop completion mutated replacement engine state: %#v", current)
	}
}

func TestConfirmedStopReceiptExpiryIsBoundedAndGenerationSafe(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	instance := &EngineInstance{ID: "model", State: engineruntime.StateDraining, Phase: "first"}
	first := confirmedStopTarget{engineMarker: engineStopMarker{
		state: engineruntime.StateDraining, phase: "first", instance: instance,
	}}
	module.recordConfirmedStop("model", first)
	module.confirmedStopMu.Lock()
	firstID := module.confirmedStops["model"].receiptID
	module.confirmedStopMu.Unlock()

	second := confirmedStopTarget{engineMarker: engineStopMarker{
		state: engineruntime.StateDraining, phase: "second", instance: instance,
	}}
	module.recordConfirmedStop("model", second)
	module.confirmedStopMu.Lock()
	secondID := module.confirmedStops["model"].receiptID
	count := len(module.confirmedStops)
	module.confirmedStopMu.Unlock()
	if count != 1 || secondID == firstID {
		t.Fatalf("receipt map is not bounded/generation-tagged: count=%d first=%d second=%d", count, firstID, secondID)
	}

	// An old timer must not remove a newer receipt for the same instance ID.
	module.expireConfirmedStop("model", firstID)
	module.confirmedStopMu.Lock()
	remaining, exists := module.confirmedStops["model"]
	module.confirmedStopMu.Unlock()
	if !exists || remaining.receiptID != secondID {
		t.Fatal("stale receipt expiry removed the replacement receipt")
	}
	module.expireConfirmedStop("model", secondID)
	module.confirmedStopMu.Lock()
	count = len(module.confirmedStops)
	module.confirmedStopMu.Unlock()
	if count != 0 {
		t.Fatalf("expired confirmed-stop receipt leaked: %d", count)
	}
}

func TestBlockedRestartNeverSpawnsRollbackOverGhostWorker(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	config := defaultEngineConfig()
	plan := ContextPlanView{}
	module.instances["model"] = &EngineInstance{
		ID: "model", State: engineruntime.StateDraining, CreatedAt: now, UpdatedAt: now,
	}
	backup := &EngineInstance{
		ID: "model", State: engineruntime.StateReady, RequestedConfig: config,
		LastKnownGood: &LastKnownGood{EffectiveConfig: config, Plan: plan, UpdatedAt: now},
		CreatedAt:     now, UpdatedAt: now,
	}
	module.mu.Lock()
	operation, _ := module.newOperationLocked("restart", "model", "test")
	module.mu.Unlock()
	module.failTransactionBlocked(operation.ID, "model", map[string]*EngineInstance{"model": backup}, nil, errors.New("stop unconfirmed"), map[string]bool{"model": true})
	if instance := module.instances["model"]; instance.State != engineruntime.StateDraining {
		t.Fatalf("ghost worker state was overwritten during rollback: %#v", instance)
	}
	if current, _ := module.operation(operation.ID); current.State != "failed" {
		t.Fatalf("restart operation = %#v", current)
	}
}

func TestScopedMultiRestartRestoresUntouchedWorkerWithoutDuplicateSpawn(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	config := defaultEngineConfig()
	untouchedBackup := &EngineInstance{
		ID: "untouched", State: engineruntime.StateReady, ModelID: "old-model",
		BaseURL: "http://127.0.0.1:9001", WorkerSecret: "old-secret",
		RequestedConfig: config, EffectiveConfig: config,
		LastKnownGood: &LastKnownGood{EffectiveConfig: config, Plan: ContextPlanView{}, UpdatedAt: now},
		CreatedAt:     now, UpdatedAt: now,
	}
	blockedBackup := cloneInstance(untouchedBackup)
	blockedBackup.ID = "blocked"
	module.instances["untouched"] = cloneInstance(untouchedBackup)
	module.instances["untouched"].ModelID = "mutated-target"
	module.instances["blocked"] = &EngineInstance{ID: "blocked", State: engineruntime.StateDraining, CreatedAt: now, UpdatedAt: now}
	module.mu.Lock()
	operation, _ := module.newOperationLocked("restart", "untouched", "test")
	module.mu.Unlock()

	// No old worker was confirmed stopped before the second stop failed.
	// If rollback attempted startOne for untouched, the nil Supervisor would
	// expose the duplicate-spawn bug immediately.
	module.failTransactionScoped(
		operation.ID,
		"untouched",
		map[string]*EngineInstance{"untouched": untouchedBackup, "blocked": blockedBackup},
		nil,
		errors.New("second stop unconfirmed"),
		map[string]bool{"blocked": true},
		map[string]bool{},
	)

	untouched, _ := module.getInstance("untouched")
	if untouched.State != engineruntime.StateReady || untouched.ModelID != "old-model" || untouched.BaseURL != untouchedBackup.BaseURL || untouched.WorkerSecret != untouchedBackup.WorkerSecret {
		t.Fatalf("untouched old worker was not restored in place: %#v", untouched)
	}
	blocked, _ := module.getInstance("blocked")
	if blocked.State != engineruntime.StateDraining {
		t.Fatalf("unconfirmed stop lost its draining state: %#v", blocked)
	}
}

func TestShutdownSkipsRollbackRespawn(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	config := defaultEngineConfig()
	backup := &EngineInstance{
		ID: "model", State: engineruntime.StateReady,
		LastKnownGood: &LastKnownGood{EffectiveConfig: config, Plan: ContextPlanView{}, UpdatedAt: now},
		CreatedAt:     now, UpdatedAt: now,
	}
	module.instances["model"] = &EngineInstance{ID: "model", State: engineruntime.StateStopped, CreatedAt: now, UpdatedAt: now}
	module.operations["op"] = &EngineOperation{ID: "op", InstanceID: "model", Type: "restart", State: "running", CreatedAt: now, UpdatedAt: now}
	module.mu.Lock()
	module.shuttingDown = true
	module.mu.Unlock()
	module.failTransactionScoped("op", "model", map[string]*EngineInstance{"model": backup}, nil, context.Canceled, nil, map[string]bool{"model": true})
	instance, _ := module.getInstance("model")
	if instance.State != engineruntime.StateStopped {
		t.Fatalf("shutdown rollback respawned or changed stopped instance: %#v", instance)
	}
}

func TestEmergencyWithoutManagedHandleFinalizesOnce(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	module.instances["model"] = &EngineInstance{ID: "model", State: engineruntime.StateReady, ActiveRequests: 1, CreatedAt: now, UpdatedAt: now}
	module.emergencyTerminate("model")
	if instance := module.instances["model"]; instance.State != engineruntime.StateStopped || instance.ActiveRequests != 0 {
		t.Fatalf("confirmed emergency stop = %#v", instance)
	}
	module.stopReaperMu.Lock()
	reapers := len(module.stopReapers)
	module.stopReaperMu.Unlock()
	if reapers != 0 {
		t.Fatalf("confirmed emergency stop spawned %d redundant reaper(s)", reapers)
	}
}

func TestEmergencyInterruptsLowPriorityActiveAnswerFirst(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	module.instances["high"] = &EngineInstance{
		ID: "high", State: engineruntime.StateReady, Priority: "high", ActiveRequests: 1,
		CreatedAt: now.Add(-time.Hour), UpdatedAt: now,
	}
	module.instances["low"] = &EngineInstance{
		ID: "low", State: engineruntime.StateReady, Priority: "low", ActiveRequests: 2,
		CreatedAt: now, UpdatedAt: now,
	}
	id, active := module.pressureEvictionCandidate(true)
	if id != "low" || !active {
		t.Fatalf("emergency candidate = %q active=%v, want low-priority active answer", id, active)
	}
}

func TestEmergencyForceStopsStartingWorkerBeforeReadyAnswer(t *testing.T) {
	if os.Getenv("PHILOENGINE_ENGINE_HELPER") == "1" {
		return
	}
	supervisor := engineruntime.NewSupervisor(engineruntime.SupervisorOptions{GracePeriod: 30 * time.Second})
	spec := engineruntime.ProcessSpec{
		InstanceID: "starting",
		Argv:       []string{os.Args[0], "-test.run=TestEngineEmergencyWorkerHelper"},
		Environment: map[string]string{
			"PHILOENGINE_ENGINE_HELPER": "1",
		},
		HealthPath: "-",
	}
	handle, err := supervisor.Start(context.Background(), spec)
	if err != nil {
		t.Fatal(err)
	}
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.supervisor = supervisor
	now := time.Now().UTC()
	module.instances["starting"] = &EngineInstance{ID: "starting", State: engineruntime.StateStarting, UpdatedAt: now, CreatedAt: now}
	module.instances["ready"] = &EngineInstance{ID: "ready", State: engineruntime.StateReady, Priority: "low", ActiveRequests: 1, UpdatedAt: now, CreatedAt: now}

	started := time.Now()
	module.relievePressure(true)
	if time.Since(started) > 3*time.Second {
		t.Fatal("emergency force-stop waited for the 30 second graceful timeout")
	}
	select {
	case <-handle.Done():
	default:
		t.Fatal("starting worker was not reaped before emergency returned")
	}
	starting, _ := module.getInstance("starting")
	ready, _ := module.getInstance("ready")
	if starting.State != engineruntime.StateStopped || ready.State != engineruntime.StateReady {
		t.Fatalf("emergency order starting=%s ready=%s", starting.State, ready.State)
	}
}

func TestEngineEmergencyWorkerHelper(t *testing.T) {
	if os.Getenv("PHILOENGINE_ENGINE_HELPER") != "1" {
		return
	}
	select {}
}
