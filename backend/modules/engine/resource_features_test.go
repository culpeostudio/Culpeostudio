package engine

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	"github.com/culpeohq/backend/internal/engineplanner"
	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/internal/modelcatalog"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestUserPickerVisibilityIsAtomicPrivateAndCaseInsensitive(t *testing.T) {
	root := t.TempDir()
	storePath := filepath.Join(root, "engine_user_preferences.json")
	store, err := newEnginePreferenceStore(storePath)
	if err != nil {
		t.Fatal(err)
	}
	module := New(filepath.Join(root, "settings.json"))
	module.preferences = store
	module.instances["shared"] = &EngineInstance{ID: "shared", State: engineruntime.StateStopped, CreatedAt: time.Now()}

	service := &grpcService{module: module}
	// The caller is named with mixed case on purpose: visibility is stored per
	// account, and the casing must not open a second bucket.
	ctx := grpcmw.ContextWithUserForTest(context.Background(), "Alice", "Alice")
	if _, err := service.UpdateInstance(ctx, &enginev1.UpdateInstanceRequest{
		InstanceId: "shared",
		Change: &enginev1.UpdateInstanceRequest_Visibility{
			Visibility: &enginev1.SetVisibility{ShowInChatPicker: true},
		},
	}); err != nil {
		t.Fatalf("UpdateInstance failed: %v", err)
	}
	if !store.visible("alice", "shared") || store.visible("bob", "shared") {
		t.Fatal("visibility leaked across logins or username casing")
	}
	info, err := os.Stat(storePath)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("preferences mode = %o", info.Mode().Perm())
	}
	if module.instances["shared"].ShowInChatPicker {
		t.Fatal("per-user overlay mutated shared instance state")
	}
	if !module.listInstancesForUser("ALICE")[0].ShowInChatPicker || module.listInstancesForUser("bob")[0].ShowInChatPicker {
		t.Fatal("handler overlay is not isolated")
	}
}

func TestUserPickerVisibilityRejectsCombinedPatchWithoutPartialMutation(t *testing.T) {
	root := t.TempDir()
	store, err := newEnginePreferenceStore(filepath.Join(root, "engine_user_preferences.json"))
	if err != nil {
		t.Fatal(err)
	}
	module := New(filepath.Join(root, "settings.json"))
	module.preferences = store
	module.instances["shared"] = &EngineInstance{ID: "shared", State: engineruntime.StateStopped, CreatedAt: time.Now()}

	service := &grpcService{module: module}
	ctx := grpcmw.ContextWithUserForTest(context.Background(), "alice", "alice")
	// The schema carries exactly one change, so a request that names none is
	// refused rather than half applied. The JSON body could bundle a visibility
	// flag with an unknown action, which is what this used to guard against.
	if _, err := service.UpdateInstance(ctx, &enginev1.UpdateInstanceRequest{
		InstanceId: "shared",
	}); status.Code(err) != codes.InvalidArgument {
		t.Fatalf("combined patch code = %v, want InvalidArgument", status.Code(err))
	}
	if store.visible("alice", "shared") {
		t.Fatal("invalid combined patch persisted picker visibility")
	}
}

func TestUserPickerVisibilityWriteFailureKeepsMemoryUnchanged(t *testing.T) {
	root := t.TempDir()
	store := &enginePreferenceStore{path: root, users: map[string]engineUserPreferences{}}
	if err := store.setVisible("alice", "shared", true); err == nil {
		t.Fatal("expected private preference write to fail when target is a directory")
	}
	if store.visible("alice", "shared") {
		t.Fatal("failed preference write leaked into the in-memory view")
	}
}

func TestUserPickerVisibilityDoesNotCollapseValidLoginNames(t *testing.T) {
	store, err := newEnginePreferenceStore(filepath.Join(t.TempDir(), "engine_user_preferences.json"))
	if err != nil {
		t.Fatal(err)
	}
	if err := store.setVisible("alice!", "punctuation", true); err != nil {
		t.Fatal(err)
	}
	if err := store.setVisible("Älice", "unicode", true); err != nil {
		t.Fatal(err)
	}
	if store.visible("alice", "punctuation") {
		t.Fatal("punctuation account collided with plain alice")
	}
	if store.visible("local", "unicode") {
		t.Fatal("Unicode account collapsed into the local fallback namespace")
	}
	if !store.visible("ALICE!", "punctuation") || !store.visible("äLICE", "unicode") {
		t.Fatal("case-insensitive lookup no longer follows login normalization")
	}
}

func TestPlacementForPlan(t *testing.T) {
	plan := func(ram int64, gpu map[string]int64) *ContextPlanView {
		return &ContextPlanView{Memory: engineplanner.ResourceBreakdown{Total: engineplanner.MemoryAllocation{RAMBytes: ram, GPUBytes: gpu}}}
	}
	for _, tc := range []struct {
		plan *ContextPlanView
		want Placement
	}{
		{nil, PlacementUnknown}, {plan(1, nil), PlacementRAM}, {plan(0, map[string]int64{"gpu": 1}), PlacementGPU},
		{plan(1, map[string]int64{"gpu": 1}), PlacementHybrid}, {plan(0, map[string]int64{"gpu": 0}), PlacementUnknown},
	} {
		if got := placementForPlan(tc.plan); got != tc.want {
			t.Fatalf("placement = %s, want %s", got, tc.want)
		}
	}
}

func TestWorkerGPUSelectionFollowsRequestedOrder(t *testing.T) {
	plan := ContextPlanView{Memory: engineplanner.ResourceBreakdown{
		Weights: engineplanner.MemoryAllocation{RAMBytes: 4 << 30, GPUBytes: map[string]int64{"gpu-a": 5 << 30, "gpu-b": 2 << 30}},
		Total:   engineplanner.MemoryAllocation{RAMBytes: 8 << 30, GPUBytes: map[string]int64{"gpu-a": 6 << 30, "gpu-b": 3 << 30}},
	}}
	config := defaultEngineConfig()
	config.RuntimeOptions["gpu_ids"] = []string{"gpu-b", "gpu-a"}
	snapshot := hardware.Snapshot{GPUs: []hardware.GPU{
		{ID: "gpu-a", Index: 3, Backend: "cuda", VRAMTotalBytes: 16 << 30},
		{ID: "gpu-b", Index: 7, Backend: "cuda", VRAMTotalBytes: 8 << 30},
	}}
	selected, err := resolveWorkerGPUs(config, plan, snapshot, false)
	if err != nil {
		t.Fatal(err)
	}
	// gpu_ids is a set, not a sequence: it is deduplicated and ordered by ID, so
	// the devices the worker sees are the same whichever order the config listed
	// them in.
	if len(selected) != 2 || selected[0].ID != "gpu-a" || selected[1].ID != "gpu-b" {
		t.Fatalf("selected GPUs = %#v", selected)
	}
	environment := map[string]string{}
	applyWorkerDeviceSelection(environment, selected)
	if environment["CUDA_VISIBLE_DEVICES"] != "3,7" {
		t.Fatalf("CUDA visibility = %q", environment["CUDA_VISIBLE_DEVICES"])
	}
}

func TestCPUWorkerSelectionKeepsRuntimeGPUFree(t *testing.T) {
	plan := ContextPlanView{Memory: engineplanner.ResourceBreakdown{Total: engineplanner.MemoryAllocation{RAMBytes: 8 << 30}}}
	selected, err := resolveWorkerGPUs(defaultEngineConfig(), plan, hardware.Snapshot{}, true)
	if err != nil {
		t.Fatal(err)
	}
	if len(selected) != 0 {
		t.Fatalf("CPU worker selected GPUs: %#v", selected)
	}
	environment := map[string]string{}
	applyWorkerDeviceSelection(environment, selected)
	if environment["CUDA_VISIBLE_DEVICES"] != "" || environment["ROCR_VISIBLE_DEVICES"] != "" {
		t.Fatalf("CPU environment did not hide GPUs: %#v", environment)
	}
}

func TestEnsureReadyReusesActiveStartOperation(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["model"] = &EngineInstance{ID: "model", State: engineruntime.StateQueued, RequestedConfig: defaultEngineConfig()}
	module.mu.Lock()
	operation, _ := module.newOperationLocked("ensure_ready", "model", "queued")
	module.enqueueStartOperationLocked(operation, "normal")
	module.mu.Unlock()
	_, first, err := module.ensureReady("model")
	if err != nil {
		t.Fatal(err)
	}
	_, second, err := module.ensureReady("model")
	if err != nil {
		t.Fatal(err)
	}
	if first.ID != operation.ID || second.ID != operation.ID || len(module.operations) != 1 {
		t.Fatalf("ensure-ready was not idempotent: first=%#v second=%#v", first, second)
	}
}

func TestEnsureReadySchedulingDoesNotRestartWorkerThatBecameReady(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["model"] = &EngineInstance{
		ID: "model", State: engineruntime.StateReady,
		BaseURL: "http://127.0.0.1:1234", WorkerSecret: "worker-secret",
		RequestedConfig: defaultEngineConfig(),
	}

	operation, err := module.scheduleStartForModel("model", "", defaultEngineConfig(), "ensure_ready")
	if err != nil {
		t.Fatal(err)
	}
	if operation != nil || len(module.operations) != 0 {
		t.Fatalf("ensure-ready restarted an already-ready worker: operation=%#v all=%#v", operation, module.operations)
	}
}

func TestStartAdmissionPrioritizesAndReportsPositions(t *testing.T) {
	queue := newStartAdmissionQueue()
	queue.enqueue("active", "low")
	queue.enqueue("low", "low")
	positions := queue.enqueue("high", "high")
	if positions["active"] != 0 || positions["high"] != 1 || positions["low"] != 2 {
		t.Fatalf("positions = %#v", positions)
	}
	positions = queue.done("active")
	if positions["high"] != 0 || positions["low"] != 1 {
		t.Fatalf("promoted positions = %#v", positions)
	}
}

func TestPlanningConflictSelectsMinimalNormalLRUEviction(t *testing.T) {
	now := time.Now().UTC()
	candidates := []normalLRUCandidate{{ID: "old", LastUsed: now.Add(-time.Hour)}, {ID: "new", LastUsed: now.Add(-time.Minute)}}
	attempts := 0
	evictions, err := planWithNormalLRUExclusions(candidates, func(excluded map[string]bool) error {
		attempts++
		if !excluded["old"] {
			return &engineplanner.ConflictError{InstanceID: "target", Resource: "ram", Reason: "test conflict"}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if attempts != 2 || len(evictions) != 1 || evictions[0] != "old" {
		t.Fatalf("attempts=%d evictions=%#v", attempts, evictions)
	}
}

func TestConflictEvictsThenReplansInsideNormalLRUAdmission(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	used := time.Now().UTC().Add(-time.Hour)
	module.instances["old"] = &EngineInstance{ID: "old", State: engineruntime.StateReady, LastUsedAt: &used}
	steps := []string{}
	attempts := 0
	evicted, err := module.evictNormalLRUUntilPlanned(context.Background(), "target", func() error {
		attempts++
		steps = append(steps, "plan")
		if attempts == 1 {
			return &engineplanner.ConflictError{InstanceID: "target", Resource: "gpu", Reason: "occupied"}
		}
		return nil
	}, func(candidate *EngineInstance) error {
		steps = append(steps, "evict:"+candidate.ID)
		return module.stopClaimedNormalLRU(candidate.ID)
	})
	if err != nil {
		t.Fatal(err)
	}
	if strings.Join(steps, ",") != "plan,evict:old,plan" || len(evicted) != 1 || evicted[0] != "old" {
		t.Fatalf("steps=%#v evicted=%#v", steps, evicted)
	}
	instance, _ := module.getInstance("old")
	if instance.State != engineruntime.StateStopped {
		t.Fatalf("evicted instance state = %s", instance.State)
	}
}

func TestPeakAdmissionEvictsIdleInstanceAndRetries(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	used := time.Now().UTC().Add(-time.Hour)
	module.instances["idle"] = &EngineInstance{ID: "idle", State: engineruntime.StateReady, LastUsedAt: &used}
	attempts := 0
	limit, err := module.evictNormalLRUUntilPeakAdmitted(context.Background(), "target", func() (int64, error) {
		attempts++
		if attempts == 1 {
			return 0, fmt.Errorf("%w: %w", localinference.ErrGuardRejected, &ResourceConflictError{Resource: "ram", RequiredBytes: 10, AvailableBytes: 5, Reason: "peak"})
		}
		return 42, nil
	}, func(candidate *EngineInstance) error {
		return module.stopClaimedNormalLRU(candidate.ID)
	})
	if err != nil {
		t.Fatal(err)
	}
	if attempts != 2 || limit != 42 {
		t.Fatalf("peak attempts=%d limit=%d", attempts, limit)
	}
	instance, _ := module.getInstance("idle")
	if instance.State != engineruntime.StateStopped {
		t.Fatalf("peak LRU candidate state = %s", instance.State)
	}
}

func TestNormalLRUOrderExemptionsAndAtomicClaim(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	old := now.Add(-time.Hour)
	newer := now.Add(-time.Minute)
	module.instances["old"] = &EngineInstance{ID: "old", State: engineruntime.StateReady, LastUsedAt: &old}
	module.instances["new"] = &EngineInstance{ID: "new", State: engineruntime.StateReady, LastUsedAt: &newer}
	module.instances["active"] = &EngineInstance{ID: "active", State: engineruntime.StateReady, LastUsedAt: &old, ActiveRequests: 1}
	module.instances["auto"] = &EngineInstance{ID: "auto", State: engineruntime.StateReady, LastUsedAt: &old, Autostart: true}
	module.instances["pinned"] = &EngineInstance{ID: "pinned", State: engineruntime.StateReady, LastUsedAt: &old, Pinned: true}
	module.instances["primary"] = &EngineInstance{ID: "primary", State: engineruntime.StateReady, LastUsedAt: &old}
	candidates := module.normalLRUCandidates("primary")
	if len(candidates) != 2 || candidates[0].ID != "old" || candidates[1].ID != "new" {
		t.Fatalf("normal LRU candidates = %#v", candidates)
	}
	claimed := module.claimNormalLRUCandidate("primary")
	if claimed == nil || claimed.ID != "old" || claimed.State != engineruntime.StateDraining {
		t.Fatalf("claimed = %#v", claimed)
	}
	if err := module.stopClaimedNormalLRU("old"); err != nil {
		t.Fatal(err)
	}
	stopped, _ := module.getInstance("old")
	if stopped.State != engineruntime.StateStopped || stopped.Phase != "lru_evicted" {
		t.Fatalf("stopped LRU instance = %#v", stopped)
	}
}

func TestConcurrentNormalLRUClaimCannotEvictSameInstanceTwice(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	used := time.Now().UTC().Add(-time.Hour)
	module.instances["only"] = &EngineInstance{ID: "only", State: engineruntime.StateReady, LastUsedAt: &used}
	var wait sync.WaitGroup
	wait.Add(2)
	results := make(chan *EngineInstance, 2)
	for index := 0; index < 2; index++ {
		go func() {
			defer wait.Done()
			results <- module.claimNormalLRUCandidate("target")
		}()
	}
	wait.Wait()
	close(results)
	claimed := 0
	for result := range results {
		if result != nil {
			claimed++
		}
	}
	if claimed != 1 {
		t.Fatalf("concurrent claims = %d, want exactly one", claimed)
	}
}

func TestOperationLRUProtectsEveryRestartAndAlreadyStartedInstance(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	oldest := now.Add(-2 * time.Hour)
	next := now.Add(-time.Hour)
	module.instances["already-started"] = &EngineInstance{ID: "already-started", State: engineruntime.StateReady, LastUsedAt: &oldest}
	module.instances["later-restart"] = &EngineInstance{ID: "later-restart", State: engineruntime.StateReady, LastUsedAt: &oldest}
	module.instances["evictable"] = &EngineInstance{ID: "evictable", State: engineruntime.StateReady, LastUsedAt: &next}
	module.operations["multi"] = &EngineOperation{
		ID:                   "multi",
		State:                "running",
		ProtectedInstanceIDs: []string{"already-started", "later-restart", "target"},
	}

	claimed := module.claimNormalLRUCandidateForOperation("multi", "target")
	if claimed == nil || claimed.ID != "evictable" {
		t.Fatalf("operation-aware claim = %#v, want evictable", claimed)
	}
	for _, id := range []string{"already-started", "later-restart"} {
		instance, _ := module.getInstance(id)
		if instance.State != engineruntime.StateReady {
			t.Fatalf("protected restart %s changed to %s", id, instance.State)
		}
	}
	operation, _ := module.operation("multi")
	if len(operation.ReservedEvictionInstanceIDs) != 1 || operation.ReservedEvictionInstanceIDs[0] != "evictable" {
		t.Fatalf("LRU reservation = %#v", operation.ReservedEvictionInstanceIDs)
	}
}

func TestOperationLRUSkipsOtherQueuedPhysicalStart(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	oldest := now.Add(-2 * time.Hour)
	recent := now.Add(-time.Hour)
	module.instances["queued-primary"] = &EngineInstance{ID: "queued-primary", State: engineruntime.StateReady, LastUsedAt: &oldest}
	module.instances["evictable"] = &EngineInstance{ID: "evictable", State: engineruntime.StateReady, LastUsedAt: &recent}
	module.operations["queued-op"] = &EngineOperation{ID: "queued-op", State: "queued", InstanceID: "queued-primary"}
	module.startExecutions["queued-primary"] = "queued-op"
	module.operations["active-op"] = &EngineOperation{ID: "active-op", State: "running", InstanceID: "target"}
	module.startExecutions["target"] = "active-op"

	claimed := module.claimNormalLRUCandidateForOperation("active-op", "target")
	if claimed == nil || claimed.ID != "evictable" {
		t.Fatalf("cross-operation LRU claim = %#v, want evictable", claimed)
	}
	if state := module.instances["queued-primary"].State; state != engineruntime.StateReady {
		t.Fatalf("queued operation primary was evicted: %s", state)
	}
}

func TestLRUReservationBlocksReactivationUntilOwnerOperationTerminates(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["victim"] = &EngineInstance{ID: "victim", ModelID: "missing-is-not-reached", State: engineruntime.StateStopped}
	module.operations["owner"] = &EngineOperation{
		ID:                          "owner",
		State:                       "running",
		ReservedEvictionInstanceIDs: []string{"victim"},
	}

	if _, err := module.scheduleStartForModel("victim", "", EngineConfig{}, "ensure_ready"); !errors.Is(err, errInstanceLRUReserved) {
		t.Fatalf("reserved start error = %v", err)
	}
	instance, _ := module.getInstance("victim")
	if instance.State != engineruntime.StateStopped {
		t.Fatalf("reserved victim was reactivated: %s", instance.State)
	}
	module.operations["owner"].State = "failed"
	if reservation := module.activeLRUEvictionReservationLocked("victim"); reservation != "" {
		t.Fatalf("terminal operation retained reservation %q", reservation)
	}
}

func TestNormalLRURequiresConfirmedSupervisorTerminalState(t *testing.T) {
	if terminalSupervisorState(engineruntime.StateDraining) || terminalSupervisorState(engineruntime.StateReady) {
		t.Fatal("resource-holding supervisor state was treated as terminal")
	}
	if !terminalSupervisorState(engineruntime.StateStopped) || !terminalSupervisorState(engineruntime.StateFailed) {
		t.Fatal("terminal supervisor state was not recognized")
	}
}

func TestSpawnRevalidationRejectsReactivatedLRUEviction(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.instances["evicted"] = &EngineInstance{ID: "evicted", State: engineruntime.StateStopped}
	module.operations["start"] = &EngineOperation{ID: "start", EvictedInstanceIDs: []string{"evicted"}}
	if err := module.validateOperationLRUEvictionsReleased("start"); err != nil {
		t.Fatalf("stopped eviction rejected: %v", err)
	}
	module.instances["evicted"].State = engineruntime.StateQueued
	if err := module.validateOperationLRUEvictionsReleased("start"); err == nil {
		t.Fatal("reactivated LRU instance was not rejected immediately before spawn")
	}
}

func TestInferenceGateBoundsWaitingQueue(t *testing.T) {
	gate := &inferenceGate{}
	releaseFirst, err := gate.acquire(context.Background(), 1, 1, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	secondResult := make(chan error, 1)
	secondRelease := make(chan func(), 1)
	go func() {
		release, acquireErr := gate.acquire(context.Background(), 1, 1, time.Second)
		secondRelease <- release
		secondResult <- acquireErr
	}()
	deadline := time.Now().Add(time.Second)
	for {
		gate.mu.Lock()
		waiting := len(gate.waiting)
		gate.mu.Unlock()
		if waiting == 1 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("second request did not enter queue")
		}
		time.Sleep(time.Millisecond)
	}
	if _, err := gate.acquire(context.Background(), 1, 1, time.Second); !errors.Is(err, localinference.ErrInferenceBusy) {
		t.Fatalf("full queue error = %v", err)
	}
	releaseFirst()
	if err := <-secondResult; err != nil {
		t.Fatal(err)
	}
	(<-secondRelease)()
}

func TestIdleSweepSkipsReservedAndStopsExpiredInstance(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	expired := now.Add(-time.Second)
	module.instances["idle"] = &EngineInstance{ID: "idle", State: engineruntime.StateReady, IdleExpiresAt: &expired, CreatedAt: now.Add(-time.Hour)}
	module.instances["auto"] = &EngineInstance{ID: "auto", State: engineruntime.StateReady, IdleExpiresAt: &expired, Autostart: true}
	module.instances["pinned"] = &EngineInstance{ID: "pinned", State: engineruntime.StateReady, IdleExpiresAt: &expired, Pinned: true}
	ids := module.runIdleSweep(now)
	if len(ids) != 1 || ids[0] != "idle" {
		t.Fatalf("idle sweep = %#v", ids)
	}
	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		instance, _ := module.getInstance("idle")
		if instance.State == engineruntime.StateStopped {
			if instance.Phase != "stopped" {
				t.Fatalf("terminal stop retained phase %q", instance.Phase)
			}
			return
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("idle instance was not stopped")
}

func TestIdleSweepRevalidatesUsageBetweenScanAndDrain(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	expired := now.Add(-time.Second)
	module.instances["recently-used"] = &EngineInstance{
		ID: "recently-used", State: engineruntime.StateReady,
		BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret",
		IdleExpiresAt: &expired, CreatedAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour),
	}
	candidates := module.idleSweepCandidates(now)
	if len(candidates) != 1 || candidates[0] != "recently-used" {
		t.Fatalf("initial idle candidates = %#v", candidates)
	}

	module.mu.Lock()
	instance := module.instances["recently-used"]
	instance.ActiveRequests = 1
	instance.LastUsedAt = &now
	instance.IdleExpiresAt = nil
	module.mu.Unlock()
	if module.claimIdleStop("recently-used", now) {
		t.Fatal("stale TTL candidate was claimed after a request became active")
	}
	module.mu.RLock()
	state := module.instances["recently-used"].State
	baseURL := module.instances["recently-used"].BaseURL
	module.mu.RUnlock()
	if state != engineruntime.StateReady || baseURL == "" {
		t.Fatalf("recently used instance was drained: state=%s baseURL=%q", state, baseURL)
	}
}

func TestGuardStateAndPeakPolicies(t *testing.T) {
	total := int64(16 << 30)
	floor := emergencyFloor(total, guardRAMFloor)
	if got := guardStateForSnapshot(hardware.Snapshot{RAMTotalBytes: total, RAMAvailableBytes: floor}); got != GuardEmergency {
		t.Fatalf("guard state = %s", got)
	}
	if got := guardStateForSnapshot(hardware.Snapshot{RAMTotalBytes: total, RAMAvailableBytes: floor * 2}); got != GuardWarning {
		t.Fatalf("warning state = %s", got)
	}
	if got := guardStateForSnapshot(hardware.Snapshot{}); got != GuardWarning {
		t.Fatalf("unknown RAM telemetry state = %s, want warning", got)
	}
	if got := guardStateForSnapshot(hardware.Snapshot{RAMTotalBytes: total, RAMAvailableBytes: 0}); got != GuardEmergency {
		t.Fatalf("zero available RAM state = %s, want emergency", got)
	}
	if got := guardStateForSnapshot(hardware.Snapshot{RAMTotalBytes: total, RAMAvailableBytes: total, GPUs: []hardware.GPU{{ID: "gpu", VRAMTotalBytes: 8 << 30, VRAMFreeBytes: 0}}}); got != GuardEmergency {
		t.Fatalf("zero free VRAM state = %s, want emergency", got)
	}
	if got := guardStateForSnapshot(hardware.Snapshot{RAMTotalBytes: total, RAMAvailableBytes: total, GPUs: []hardware.GPU{{ID: "cim-only", VRAMTelemetryUnavailable: true}}}); got != GuardNormal {
		t.Fatalf("inventory-only GPU blocked unrelated CPU admission with state %s", got)
	}
	plan := ContextPlanView{Memory: engineplanner.ResourceBreakdown{Total: engineplanner.MemoryAllocation{RAMBytes: 2 << 30, GPUBytes: map[string]int64{"gpu": 4 << 30}}}}
	record := modelcatalog.ModelRecord{SizeBytes: 1 << 30}
	ram, gpu := loadPeakBytes(record, plan)

	if ram != (2<<30)+(1<<30)+(2<<30) || gpu["gpu"] != (4<<30)+(512<<20) {
		t.Fatalf("llama peaks ram=%d gpu=%#v", ram, gpu)
	}
	configuredRAM := int64(8 << 30)
	if reserve := loadPeakReserveBytes(&configuredRAM, 32<<30, 15, 4<<30, guardRAMFloor); reserve != configuredRAM {
		t.Fatalf("configured RAM reserve = %d, want %d", reserve, configuredRAM)
	}
	configuredGPU := int64(3 << 30)
	if reserve := loadPeakReserveBytes(&configuredGPU, 16<<30, 10, 512<<20, guardGPUFloor); reserve != configuredGPU {
		t.Fatalf("configured GPU reserve = %d, want %d", reserve, configuredGPU)
	}
}

func TestPeakAwareAllocationTurnsMarginalGPUPlanIntoHybridSplit(t *testing.T) {
	availableRAM := int64(64 * engineplanner.GiB)
	availableGPU := int64(16 * engineplanner.GiB)
	hardwarePlan := engineplanner.Hardware{
		RAMTotalBytes: 64 * engineplanner.GiB, RAMAvailableBytes: &availableRAM,
		GPUs: []engineplanner.GPU{{
			ID: "gpu", TotalBytes: 16 * engineplanner.GiB, AvailableBytes: &availableGPU,
		}},
	}
	ramReserve := int64(4 * engineplanner.GiB)
	gpuReserve := int64(16 * engineplanner.GiB / 10)
	policy := engineplanner.ReservePolicy{
		RAMBytes: &ramReserve, GPUBytesByID: map[string]int64{"gpu": gpuReserve},
	}
	record := modelcatalog.ModelRecord{
		ID: "marginal", Format: modelcatalog.FormatGGUF, SizeBytes: 13 * engineplanner.GiB,
	}
	model := engineplanner.Model{
		ID: record.ID, WeightBytes: record.SizeBytes, ContextLimit: 4096, Layers: 32,
		KVHeads: 8, AttentionHeads: 32, HeadDimension: 128,
	}
	allowRAM := false
	request := engineplanner.Request{
		InstanceID: "target", Model: model, MinimumContext: 4096,
		KVCacheDType: engineplanner.KVCacheQ4, AllowRAMOffload: &allowRAM,
		SelectedGPUIDs: []string{"gpu"},
	}

	if _, err := engineplanner.Allocate(hardwarePlan, []engineplanner.Request{request}, policy); err != nil {
		t.Fatalf("steady-state plan should fit before load headroom is added: %v", err)
	}
	if _, err := allocateWithLoadPeak(hardwarePlan, []engineplanner.Request{request}, policy, "target", record); err == nil {
		t.Fatal("GPU-only recommendation ignored the transient load peak")
	} else {
		var conflict *engineplanner.ConflictError
		if !errors.As(err, &conflict) {
			t.Fatalf("peak-aware GPU-only error = %T %v, want planner conflict", err, err)
		}
	}

	allowRAM = true
	request.AllowRAMOffload = &allowRAM
	plans, err := allocateWithLoadPeak(hardwarePlan, []engineplanner.Request{request}, policy, "target", record)
	if err != nil {
		t.Fatalf("peak-aware hybrid plan failed: %v", err)
	}
	plan, ok := plannerContextPlan(plans, "target")
	if !ok {
		t.Fatal("hybrid target plan missing")
	}
	if plan.Breakdown.Weights.GPUBytes["gpu"] <= 0 || plan.Breakdown.Weights.RAMBytes <= 0 {
		t.Fatalf("expected a real GPU/RAM weight split, got %#v", plan.Breakdown.Weights)
	}
	view := planView(plan, nil)
	_, peakGPU := loadPeakBytes(record, view)
	usableGPU := availableGPU - gpuReserve
	if peakGPU["gpu"] > usableGPU {
		t.Fatalf("hybrid GPU peak = %d, usable = %d", peakGPU["gpu"], usableGPU)
	}
}

func TestExplicitCPURequestProducesPeakSafeRAMOnlyPlan(t *testing.T) {
	config := defaultEngineConfig()
	config.RuntimeOptions["offload"] = "cpu"
	config.RuntimeOptions["gpu_layers"] = 0
	config.RuntimeOptions["allow_ram_offload"] = false
	record := modelcatalog.ModelRecord{
		ID: "cpu-model", Format: modelcatalog.FormatGGUF, SizeBytes: 8 * engineplanner.GiB,
		Metadata: modelcatalog.Metadata{
			ContextLength: 4096, Layers: 32, KVHeads: 8, AttentionHeads: 32, HeadDimension: 128,
		},
	}
	request, _, err := plannerRequest("target", record, config, nil)
	if err != nil {
		t.Fatal(err)
	}
	if !request.ForceCPU || request.AllowRAMOffload == nil || !*request.AllowRAMOffload {
		t.Fatalf("CPU request is not RAM-plannable: %#v", request)
	}
	availableRAM := int64(32 * engineplanner.GiB)
	ramReserve := int64(4 * engineplanner.GiB)
	plans, err := allocateWithLoadPeak(
		engineplanner.Hardware{
			RAMTotalBytes: 32 * engineplanner.GiB, RAMAvailableBytes: &availableRAM,
		},
		[]engineplanner.Request{request},
		engineplanner.ReservePolicy{RAMBytes: &ramReserve},
		"target",
		record,
	)
	if err != nil {
		t.Fatalf("RAM-only peak-aware plan failed: %v", err)
	}
	plan, ok := plannerContextPlan(plans, "target")
	if !ok || plan.Breakdown.Total.RAMBytes <= record.SizeBytes || len(plan.Breakdown.Total.GPUBytes) != 0 {
		t.Fatalf("RAM-only placement = %#v", plan.Breakdown.Total)
	}
}

func TestPeakHeadroomKeepsSmallLlamaWeightsFullyOnGPU(t *testing.T) {
	availableRAM := int64(32 * engineplanner.GiB)
	availableGPU := int64(16 * engineplanner.GiB)
	ramReserve := int64(4 * engineplanner.GiB)
	gpuReserve := int64(16 * engineplanner.GiB / 10)
	allowRAM := true
	record := modelcatalog.ModelRecord{
		ID: "small", Format: modelcatalog.FormatGGUF, SizeBytes: 4 * engineplanner.GiB,
	}
	plans, err := allocateWithLoadPeak(
		engineplanner.Hardware{
			RAMTotalBytes: 32 * engineplanner.GiB, RAMAvailableBytes: &availableRAM,
			GPUs: []engineplanner.GPU{{
				ID: "gpu", TotalBytes: 16 * engineplanner.GiB, AvailableBytes: &availableGPU,
			}},
		},
		[]engineplanner.Request{{
			InstanceID: "target",
			Model: engineplanner.Model{
				ID: record.ID, WeightBytes: record.SizeBytes, ContextLimit: 4096,
				Layers: 32, KVHeads: 8, AttentionHeads: 32, HeadDimension: 128,
			},
			MinimumContext: 4096, KVCacheDType: engineplanner.KVCacheQ4,
			AllowRAMOffload: &allowRAM, SelectedGPUIDs: []string{"gpu"},
		}},
		engineplanner.ReservePolicy{
			RAMBytes: &ramReserve, GPUBytesByID: map[string]int64{"gpu": gpuReserve},
		},
		"target",
		record,
	)
	if err != nil {
		t.Fatal(err)
	}
	plan, ok := plannerContextPlan(plans, "target")
	if !ok || plan.Breakdown.Weights.GPUBytes["gpu"] != record.SizeBytes || plan.Breakdown.Weights.RAMBytes != 0 {
		t.Fatalf("small model was unnecessarily split: %#v", plan.Breakdown.Weights)
	}
}

func TestYoungestWarmupSelectsRunningNotNewerQueuedOperation(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	module.operations["running-old"] = &EngineOperation{ID: "running-old", Type: "start", State: "running", CreatedAt: now.Add(-2 * time.Minute)}
	module.operations["running-new"] = &EngineOperation{ID: "running-new", Type: "ensure_ready", State: "running", CreatedAt: now.Add(-time.Minute)}
	module.operations["queued-newest"] = &EngineOperation{ID: "queued-newest", Type: "restart", State: "queued", CreatedAt: now}
	if got := module.youngestWarmupOperation(); got != "running-new" {
		t.Fatalf("warmup cancellation target = %q, want running-new", got)
	}
}

func TestPressureEvictionUsesOldestUnreservedThenLowPriorityEmergency(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	old := now.Add(-time.Hour)
	recent := now.Add(-time.Minute)
	module.instances["old"] = &EngineInstance{ID: "old", State: engineruntime.StateReady, LastUsedAt: &old, Priority: "normal"}
	module.instances["recent"] = &EngineInstance{ID: "recent", State: engineruntime.StateReady, LastUsedAt: &recent, Priority: "normal"}
	module.instances["reserved"] = &EngineInstance{ID: "reserved", State: engineruntime.StateReady, LastUsedAt: &old, Pinned: true, Priority: "low", ActiveRequests: 1}
	if id, active := module.pressureEvictionCandidate(false); id != "old" || active {
		t.Fatalf("critical candidate = %q active=%v", id, active)
	}
	delete(module.instances, "old")
	delete(module.instances, "recent")
	if id, active := module.pressureEvictionCandidate(true); id != "reserved" || !active {
		t.Fatalf("emergency candidate = %q active=%v", id, active)
	}
}

func TestCriticalPressureRevalidatesActiveRequestBeforeDrain(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	old := time.Now().UTC().Add(-time.Hour)
	module.instances["candidate"] = &EngineInstance{
		ID: "candidate", State: engineruntime.StateReady, LastUsedAt: &old,
		BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret",
	}
	id, active := module.pressureEvictionCandidate(false)
	if id != "candidate" || active {
		t.Fatalf("pressure candidate = %q active=%v", id, active)
	}
	module.mu.Lock()
	module.instances[id].ActiveRequests = 1
	module.mu.Unlock()
	claimed, activeNow := module.claimPressureStop(id, false)
	if claimed || !activeNow {
		t.Fatalf("stale pressure candidate claimed=%v activeNow=%v", claimed, activeNow)
	}
	module.mu.RLock()
	instance := cloneInstance(module.instances[id])
	module.mu.RUnlock()
	if instance.State != engineruntime.StateReady || instance.BaseURL == "" {
		t.Fatalf("critical pressure interrupted new active request: %#v", instance)
	}
}

func TestCriticalPressureRevalidatesOperationProtectionBeforeDrain(t *testing.T) {
	for _, test := range []struct {
		name     string
		state    string
		physical bool
		protect  func(*EngineOperation)
	}{
		{name: "protected", state: "running", protect: func(operation *EngineOperation) { operation.ProtectedInstanceIDs = []string{"candidate"} }},
		{name: "reserved", state: "running", protect: func(operation *EngineOperation) { operation.ReservedEvictionInstanceIDs = []string{"candidate"} }},
		{name: "cancelled_physical_primary", state: "cancelled", physical: true, protect: func(*EngineOperation) {}},
	} {
		t.Run(test.name, func(t *testing.T) {
			module := New(filepath.Join(t.TempDir(), "settings.json"))
			old := time.Now().UTC().Add(-time.Hour)
			module.instances["candidate"] = &EngineInstance{
				ID: "candidate", State: engineruntime.StateReady, LastUsedAt: &old,
				BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret",
			}
			id, _ := module.pressureEvictionCandidate(false)
			if id != "candidate" {
				t.Fatalf("initial candidate = %q", id)
			}
			operation := &EngineOperation{ID: "transaction", State: test.state}
			test.protect(operation)
			module.mu.Lock()
			module.operations[operation.ID] = operation
			if test.physical {
				module.startExecutions["candidate"] = operation.ID
			}
			module.mu.Unlock()

			claimed, _ := module.claimPressureStop(id, false)
			if claimed {
				t.Fatal("critical pressure claimed a newly protected transaction participant")
			}
			module.mu.RLock()
			state := module.instances[id].State
			module.mu.RUnlock()
			if state != engineruntime.StateReady {
				t.Fatalf("protected instance state = %s", state)
			}
		})
	}
}

func TestIdleSweepSkipsCancelledPhysicalRestartCleanup(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	expired := now.Add(-time.Second)
	module.instances["candidate"] = &EngineInstance{
		ID: "candidate", State: engineruntime.StateReady, IdleExpiresAt: &expired,
		BaseURL: "http://127.0.0.1:1", WorkerSecret: "secret",
	}
	module.operations["cleanup"] = &EngineOperation{ID: "cleanup", State: "cancelled"}
	module.startExecutions["candidate"] = "cleanup"
	if candidates := module.idleSweepCandidates(now); len(candidates) != 0 {
		t.Fatalf("idle sweep selected physical cleanup owner: %#v", candidates)
	}
	if module.claimIdleStop("candidate", now) {
		t.Fatal("idle claim crossed cancelled physical restart cleanup")
	}
}

func TestKVCacheFollowsTheModelsOwnQuantization(t *testing.T) {
	// A cache far more precise than the weights spends memory on precision the
	// model no longer carries; one far below them throws away quality it still
	// has. The default matches the two.
	for quantization, want := range map[string]engineplanner.KVCacheDType{
		"F16":     engineplanner.KVCacheQ4, // capped by the compact policy
		"Q8_0":    engineplanner.KVCacheQ4, // capped by the compact policy
		"Q4_K_M":  engineplanner.KVCacheQ4,
		"IQ4_XS":  engineplanner.KVCacheQ4,
		"Q3_K_M":  engineplanner.KVCacheQ3K,
		"IQ3_S":   engineplanner.KVCacheQ3K,
		"Q2_K":    engineplanner.KVCacheQ2K,
		"IQ2_XXS": engineplanner.KVCacheQ2K,
		"IQ1_S":   engineplanner.KVCacheQ2K,
		"TQ1_0":   engineplanner.KVCacheQ2K,
		"":        engineplanner.KVCacheQ4,
	} {
		if got := plannerKVType(defaultEngineConfig(), quantization); got != want {
			t.Fatalf("%s model planned a %s cache, want %s", quantization, got, want)
		}
	}
}

func TestKVCachePolicyAndExplicitChoiceOverrideTheDerivedType(t *testing.T) {
	// "native" keeps full precision whatever the weights are.
	native := defaultEngineConfig()
	native.KVCachePolicy = "native"
	if got := plannerKVType(native, "Q2_K"); got != engineplanner.KVCacheFP16 {
		t.Fatalf("native policy on a two-bit model = %s, want fp16", got)
	}
	// The compact policy is a ceiling, not a target: it may not push a model
	// below what its own quantisation suggests, but it does hold f16 down.
	compact := defaultEngineConfig()
	if got := plannerKVType(compact, "F16"); got != engineplanner.KVCacheQ4 {
		t.Fatalf("compact policy on an f16 model = %s, want q4", got)
	}
	// An explicit choice always wins.
	explicit := defaultEngineConfig()
	explicit.RuntimeOptions["kv_cache_dtype"] = "q8_0"
	if got := plannerKVType(explicit, "Q2_K"); got != engineplanner.KVCacheQ8 {
		t.Fatalf("explicit q8_0 on a two-bit model = %s", got)
	}
	// An unrecognised explicit value must size conservatively rather than be
	// assumed small.
	unknown := defaultEngineConfig()
	unknown.RuntimeOptions["kv_cache_dtype"] = "some_future_type"
	if got := plannerKVType(unknown, "Q4_K_M"); got != engineplanner.KVCacheFP16 {
		t.Fatalf("unknown cache type sized as %s, want the conservative fp16", got)
	}
}

func TestSubByteCachesShrinkThePlannedContext(t *testing.T) {
	model := engineplanner.Model{
		ID: "sizing", WeightBytes: 1, ContextLimit: 1 << 20,
		Layers: 32, KVHeads: 8, HeadDimension: 128,
	}
	const budget = int64(4 << 30)
	previous := 0
	// Smaller cache types must buy strictly more context, or the factor table
	// is not actually being consulted.
	for _, dtype := range []engineplanner.KVCacheDType{
		engineplanner.KVCacheFP16, engineplanner.KVCacheQ8,
		engineplanner.KVCacheQ4, engineplanner.KVCacheQ3K, engineplanner.KVCacheQ2K,
	} {
		tokens, err := engineplanner.MaxTokensForContextBudget(model, 1, dtype, budget)
		if err != nil {
			t.Fatal(err)
		}
		if tokens <= previous {
			t.Fatalf("%s allowed %d tokens, not more than the larger type's %d", dtype, tokens, previous)
		}
		previous = tokens
	}
}
