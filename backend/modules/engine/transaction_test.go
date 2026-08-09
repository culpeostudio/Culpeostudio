package engine

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func TestQueuedReadyRestartFailureRestoresRoutableBackup(t *testing.T) {
	for _, tc := range []struct {
		name    string
		timeout bool
	}{
		{name: "cancel"},
		{name: "timeout", timeout: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			module := New(filepath.Join(t.TempDir(), "settings.json"))
			module.startQueue.setPaused(true)
			module.startQueueTimeout = 20 * time.Millisecond
			now := time.Now().UTC()
			backup := &EngineInstance{
				ID: "ready", State: engineruntime.StateReady, ModelID: "old-model",
				BaseURL: "http://127.0.0.1:1234", WorkerSecret: "secret",
				RequestedConfig: defaultEngineConfig(), EffectiveConfig: defaultEngineConfig(),
				CreatedAt: now, UpdatedAt: now,
			}
			current := cloneInstance(backup)
			current.ModelID = "new-model"
			current.RequestedConfig.ContextMode = "fixed"
			module.instances[current.ID] = current
			releaseInference, acquireErr := module.acquireInference(context.Background(), current.ID)
			if acquireErr != nil {
				t.Fatal(acquireErr)
			}
			module.mu.Lock()
			operation, operationCtx := module.newOperationLocked("restart", current.ID, "queued")
			module.enqueueStartOperationLocked(operation, "normal")
			module.mu.Unlock()
			if !tc.timeout {
				_, _ = module.cancelOperation(operation.ID)
			}
			module.executePlanTransaction(operationCtx, operation.ID, current.ID, nil, current.RequestedConfig, map[string]*EngineInstance{current.ID: backup})

			restored, _ := module.getInstance(current.ID)
			if restored.State != engineruntime.StateReady || restored.ModelID != backup.ModelID || restored.BaseURL != backup.BaseURL || restored.WorkerSecret != backup.WorkerSecret {
				t.Fatalf("ready backup lost after queue %s: %#v", tc.name, restored)
			}
			if !resourceHoldingState(restored.State) {
				t.Fatal("restored ready worker left resource accounting")
			}
			if restored.ActiveRequests != 1 || restored.IdleExpiresAt != nil {
				t.Fatalf("queue rollback rewound live inference fields: %#v", restored)
			}
			releaseInference()
			finalOperation, _ := module.operation(operation.ID)
			if tc.timeout && (finalOperation.State != "failed" || finalOperation.Phase != "queue_timeout") {
				t.Fatalf("timeout operation = %#v", finalOperation)
			}
			if !tc.timeout && finalOperation.State != "cancelled" {
				t.Fatalf("cancel operation = %#v", finalOperation)
			}
		})
	}
}

func TestQueuedStartRollbackRestoresEveryMutatedTargetPlan(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	oldPlan := &ContextPlanView{EffectiveContextTokens: 2048}
	newPlan := &ContextPlanView{EffectiveContextTokens: 8192}
	module.instances["primary"] = &EngineInstance{
		ID: "primary", State: engineruntime.StateStopped, ModelID: "old-primary",
		RequestedConfig: defaultEngineConfig(), Plan: oldPlan, PlanRevision: 1,
	}
	module.instances["affected"] = &EngineInstance{
		ID: "affected", State: engineruntime.StateStopped, ModelID: "old-affected",
		RequestedConfig: defaultEngineConfig(), Plan: oldPlan, PlanRevision: 1,
	}
	backups := map[string]*EngineInstance{
		"primary":  cloneInstance(module.instances["primary"]),
		"affected": cloneInstance(module.instances["affected"]),
	}
	module.instances["primary"].ModelID = "new-primary"
	module.instances["primary"].Plan = newPlan
	module.instances["primary"].PlanRevision = 2
	module.instances["affected"].Plan = newPlan
	module.instances["affected"].PlanRevision = 2

	if primaryReady := module.restoreQueuedStartBackup("primary", backups); primaryReady {
		t.Fatal("stopped primary was reported as a restored ready worker")
	}
	for _, id := range []string{"primary", "affected"} {
		restored, _ := module.getInstance(id)
		if restored.Plan == nil || restored.Plan.EffectiveContextTokens != 2048 || restored.PlanRevision != 1 {
			t.Fatalf("queued rollback left target plan mutated for %s: %#v", id, restored)
		}
	}
	if restored, _ := module.getInstance("primary"); restored.ModelID != "old-primary" {
		t.Fatalf("queued rollback left primary model mutated: %#v", restored)
	}
}

func TestLifecycleAcquisitionHonorsContext(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	<-module.lifecycleGate
	defer func() { module.lifecycleGate <- struct{}{} }()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer cancel()
	started := time.Now()
	if _, err := module.acquireLifecycle(ctx, false); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("lifecycle acquisition error = %v", err)
	}
	if time.Since(started) > 250*time.Millisecond {
		t.Fatal("context-aware lifecycle acquisition blocked beyond its deadline")
	}
}

func TestCancelledStartKeepsPhysicalCleanupReservation(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	now := time.Now().UTC()
	module.instances["model"] = &EngineInstance{
		ID: "model", ModelID: "old-model", State: engineruntime.StateReady,
		RequestedConfig: defaultEngineConfig(), CreatedAt: now, UpdatedAt: now,
	}
	module.operations["old-op"] = &EngineOperation{
		ID: "old-op", Type: "restart", State: "cancelled", InstanceID: "model",
		CreatedAt: now, UpdatedAt: now,
	}
	module.startExecutions["model"] = "old-op"

	operation, err := module.scheduleStartForModel("model", "different-model", defaultEngineConfig(), "restart")
	if err != nil {
		t.Fatal(err)
	}
	if operation == nil || operation.ID != "old-op" {
		t.Fatalf("retry did not deduplicate to cleanup owner: %#v", operation)
	}
	if got := module.instances["model"].ModelID; got != "old-model" {
		t.Fatalf("retry mutated model during old cleanup: %q", got)
	}
	module.finishStartExecution("model", "old-op")
	if module.startExecutions["model"] != "" {
		t.Fatal("physical cleanup reservation was not released")
	}
}

func TestCancellationBeforeDrainKeepsReadyWorkerRoutable(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	backup := &EngineInstance{
		ID: "ready", State: engineruntime.StateReady, ModelID: "model-old",
		BaseURL: "http://127.0.0.1:1234", WorkerSecret: "worker-secret",
		RequestedConfig: defaultEngineConfig(), EffectiveConfig: defaultEngineConfig(),
	}
	module.instances[backup.ID] = cloneInstance(backup)
	module.instances[backup.ID].ModelID = "model-new"

	module.restoreBeforeDrainCancellation(backup.ID, map[string]*EngineInstance{backup.ID: backup})
	restored, ok := module.getInstance(backup.ID)
	if !ok || restored.State != engineruntime.StateReady || restored.ModelID != "model-old" || restored.BaseURL != backup.BaseURL || restored.WorkerSecret != backup.WorkerSecret {
		t.Fatalf("ready worker was not restored before drain: %#v", restored)
	}
}

func TestRollbackNeverResurrectsEmergencyStoppedRouting(t *testing.T) {
	backup := &EngineInstance{
		ID: "ready", State: engineruntime.StateReady, ModelID: "old-model",
		BaseURL: "http://127.0.0.1:1234", WorkerSecret: "secret", workerGeneration: 4,
		RequestedConfig: defaultEngineConfig(),
	}
	current := cloneInstance(backup)
	current.ModelID = "new-model"
	current.State = engineruntime.StateDraining
	current.Phase = "guard_emergency_stopping"
	current.BaseURL = ""
	current.WorkerSecret = ""
	merged := mergeLiveWorkerRollback(current, backup)
	if merged.State != engineruntime.StateDraining || merged.BaseURL != "" || merged.WorkerSecret != "" {
		t.Fatalf("rollback resurrected emergency routing: %#v", merged)
	}
	if merged.ModelID != "old-model" {
		t.Fatalf("requested model was not rolled back: %#v", merged)
	}
}

func TestRollbackNeverRewritesNewWorkerGenerationMetadata(t *testing.T) {
	backup := &EngineInstance{
		ID: "ready", State: engineruntime.StateReady, ModelID: "old-model",
		BaseURL: "http://127.0.0.1:1234", WorkerSecret: "old-secret", workerGeneration: 4,
		RequestedConfig: defaultEngineConfig(), Priority: "normal", PlanRevision: 3,
	}
	current := cloneInstance(backup)
	current.workerGeneration = 5
	current.ModelID = "new-worker-model"
	current.BaseURL = "http://127.0.0.1:5678"
	current.WorkerSecret = "new-secret"
	current.Priority = "high"
	current.PlanRevision = 8
	current.RequestedConfig.MaxSequences = 7

	merged := mergeLiveWorkerRollback(current, backup)
	if merged.ModelID != current.ModelID || merged.RequestedConfig.MaxSequences != 7 ||
		merged.Priority != current.Priority || merged.PlanRevision != current.PlanRevision {
		t.Fatalf("stale rollback rewrote newer generation metadata: %#v", merged)
	}
	if merged.workerGeneration != current.workerGeneration || merged.BaseURL != current.BaseURL || merged.WorkerSecret != current.WorkerSecret {
		t.Fatalf("stale rollback rewrote newer worker identity: %#v", merged)
	}
}

func TestOperationAndInstanceProgressStayMonotoneAndExposeUsefulErrors(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.operations["op"] = &EngineOperation{ID: "op", InstanceID: "inst", State: "running", Phase: "loading_model", Progress: 0.70}
	module.instances["inst"] = &EngineInstance{ID: "inst", State: engineruntime.StateStarting, Phase: "loading_model", Progress: 0.70}

	module.setOperationDetail("op", "running", 0.40, "fallback", "Fallback", "Kompatibler Fallback wird geprueft.", nil)
	module.setInstanceStateDetail("inst", engineruntime.StateStarting, 0.40, "fallback", "Kompatibler Fallback wird geprueft.", "")
	operation, _ := module.operation("op")
	instance, _ := module.getInstance("inst")
	if operation.Progress != 0.70 || instance.Progress != 0.70 {
		t.Fatalf("progress regressed: operation=%v instance=%v", operation.Progress, instance.Progress)
	}
	module.operations["cancelled"] = &EngineOperation{ID: "cancelled", State: "cancelled", Phase: "cancelled", Progress: 0.70}
	module.setOperationDetail("cancelled", "running", 0.86, "verifying_worker", "Test", "Test", nil)
	cancelled, _ := module.operation("cancelled")
	if cancelled.State != "cancelled" || cancelled.Phase != "cancelled" || cancelled.Progress != 0.70 {
		t.Fatalf("terminal operation was resurrected: %#v", cancelled)
	}
	if operation.Phase != "fallback" || operation.DetailMessage == "" || instance.Phase != "fallback" || instance.DetailMessage == "" {
		t.Fatalf("missing phase details: operation=%#v instance=%#v", operation, instance)
	}

	module.setOperation("op", "failed", 1, "Start fehlgeschlagen", os.ErrNotExist)
	module.setInstanceState("inst", engineruntime.StateFailed, 1, os.ErrNotExist.Error())
	operation, _ = module.operation("op")
	instance, _ = module.getInstance("inst")
	if operation.ErrorCode != "required_file_missing" || operation.ErrorSummary == "" || instance.ErrorCode != "required_file_missing" || instance.ErrorSummary == "" {
		t.Fatalf("missing useful error contract: operation=%#v instance=%#v", operation, instance)
	}
}

func TestEngineLogSanitizerRedactsSecretsAndBearerCredentials(t *testing.T) {
	t.Setenv("HF_TOKEN", "provider-secret")
	got := sanitizeEngineLogText("line\nHF_TOKEN=provider-secret Authorization: Bearer internal-secret")
	if strings.Contains(got, "provider-secret") || strings.Contains(got, "internal-secret") || strings.Contains(got, "\n") {
		t.Fatalf("unsanitized engine log text: %q", got)
	}
}

func TestRuntimePreparationFailureDoesNotRestartReadyWorker(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	backup := &EngineInstance{
		ID: "ready", State: engineruntime.StateReady, ModelID: "model",
		BaseURL: "http://127.0.0.1:1234", WorkerSecret: "worker-secret",
		RequestedConfig: defaultEngineConfig(), EffectiveConfig: defaultEngineConfig(),
	}
	module.instances[backup.ID] = cloneInstance(backup)
	module.instances[backup.ID].RequestedConfig.ContextMode = "fixed"
	releaseInference, err := module.acquireInference(context.Background(), backup.ID)
	if err != nil {
		t.Fatal(err)
	}
	module.operations["op"] = &EngineOperation{ID: "op", State: "running"}

	module.failBeforeDrain("op", backup.ID, map[string]*EngineInstance{backup.ID: backup}, errors.New("runtime setup failed"))
	restored, _ := module.getInstance(backup.ID)
	operation, _ := module.operation("op")
	if restored.State != engineruntime.StateReady || restored.BaseURL != backup.BaseURL || restored.WorkerSecret != backup.WorkerSecret {
		t.Fatalf("ready worker was interrupted before drain: %#v", restored)
	}
	if operation.State != "failed" {
		t.Fatalf("operation = %#v", operation)
	}
	if restored.ActiveRequests != 1 || restored.IdleExpiresAt != nil {
		t.Fatalf("pre-drain rollback rewound live inference fields: %#v", restored)
	}
	releaseInference()
}

func TestCancellationBeforeFirstStartLeavesInstanceStopped(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	backup := &EngineInstance{ID: "new", State: engineruntime.StateQueued, ModelID: "model", RequestedConfig: defaultEngineConfig(), EffectiveConfig: defaultEngineConfig()}
	module.instances[backup.ID] = cloneInstance(backup)

	module.restoreBeforeDrainCancellation(backup.ID, map[string]*EngineInstance{backup.ID: backup})
	restored, ok := module.getInstance(backup.ID)
	if !ok || restored.State != engineruntime.StateStopped {
		t.Fatalf("cancelled first start = %#v", restored)
	}
}
