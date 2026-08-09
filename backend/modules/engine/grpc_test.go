package engine

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
)

func ptrInt32(value int32) *int32 { return &value }

// newGRPCEngineModule builds a module with a small real catalog, the way the
// HTTP contract test does, and wraps it in the gRPC service under test.
func newGRPCEngineModule(t *testing.T) (*EngineModule, *grpcService) {
	t.Helper()
	t.Setenv("ENGINE_GATEWAY_ADDR", "disabled")
	t.Setenv("ENGINE_RUNTIME_PREWARM", "disabled")
	root := t.TempDir()
	modelDir := filepath.Join(root, "models")
	writeEngineModel(t, filepath.Join(modelDir, "org", "model"))
	settingsPath := filepath.Join(root, "settings.json")
	settings, _ := json.Marshal(map[string]interface{}{"model_dir": modelDir})
	if err := os.WriteFile(settingsPath, settings, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = module.Shutdown() })
	if module.installer != nil {
		module.installer.Close()
		module.installer = nil
	}
	return module, &grpcService{module: module}
}

func requireEngineCode(t *testing.T, err error, want codes.Code) {
	t.Helper()
	if err == nil {
		t.Fatalf("erwartet %s, bekam keinen Fehler", want)
	}
	if got := status.Code(err); got != want {
		t.Fatalf("Statuscode = %s, want %s (%v)", got, want, err)
	}
}

func TestGRPCModelCatalogContract(t *testing.T) {
	_, service := newGRPCEngineModule(t)

	models, err := service.ListModels(context.Background(), &enginev1.ListModelsRequest{})
	if err != nil {
		t.Fatalf("ListModels: %v", err)
	}
	if len(models.GetModels()) != 1 {
		t.Fatalf("models = %#v", models)
	}
	record := models.GetModels()[0]
	if record.GetStatus() != enginev1.ModelStatus_MODEL_STATUS_READY || record.GetFormat() != enginev1.ModelFormat_MODEL_FORMAT_GGUF {
		t.Fatalf("model record = %+v", record)
	}

	capabilities, err := service.GetCapabilities(context.Background(), &enginev1.GetCapabilitiesRequest{})
	if err != nil {
		t.Fatalf("GetCapabilities: %v", err)
	}
	defaults := capabilities.GetDefaults()
	if defaults.GetMinimumContextTokens() != 4096 || defaults.GetKvCachePolicy() != enginev1.KvCachePolicy_KV_CACHE_POLICY_PREFER_4BIT || defaults.GetMaxSequences() != 1 {
		t.Fatalf("defaults = %+v", defaults)
	}

	recommendation, err := service.GetRecommendation(context.Background(), &enginev1.GetRecommendationRequest{
		ModelId: record.GetId(),
		Config: &enginev1.EngineConfig{
			ContextMode:    enginev1.ContextMode_CONTEXT_MODE_FIXED,
			ContextTokens:  func() *int32 { value := int32(8192); return &value }(),
			RuntimeOptions: structFromMap(map[string]interface{}{"allow_ram_offload": true}),
		},
	})
	if err != nil {
		t.Fatalf("GetRecommendation: %v", err)
	}
	plan := recommendation.GetPlan()
	if plan.GetModelContextLimitTokens() != 16384 || plan.GetEffectiveContextTokens() != 8192 {
		t.Fatalf("plan = %+v", plan)
	}
}

func TestGRPCInstanceLifecycle(t *testing.T) {
	_, service := newGRPCEngineModule(t)

	catalog, err := service.ListModels(context.Background(), &enginev1.ListModelsRequest{})
	if err != nil {
		t.Fatal(err)
	}
	modelID := catalog.GetModels()[0].GetId()

	created, err := service.CreateInstance(context.Background(), &enginev1.CreateInstanceRequest{
		ModelId: modelID,
		Config: &enginev1.EngineConfig{
			ContextTokens: ptrInt32(4096),
			MaxSequences:  1,
			// gpu_layers is an explicit zero, not an omission: a runtime option
			// that means "no GPU layers" must survive rather than be dropped as
			// an empty value.
			RuntimeOptions: structFromMap(map[string]interface{}{
				"allow_ram_offload": true,
				"gpu_layers":        0,
			}),
		},
	})
	if err != nil {
		t.Fatalf("CreateInstance: %v", err)
	}
	instance := created.GetInstance()
	if instance.GetId() == "" || created.GetOperationId() == "" || instance.GetState() != enginev1.InstanceState_INSTANCE_STATE_QUEUED {
		t.Fatalf("created = %+v", created)
	}

	options := instance.GetRequestedConfig().GetRuntimeOptions().GetFields()
	layers, present := options["gpu_layers"]
	if !present || layers.GetNumberValue() != 0 {
		t.Fatalf("explicit numeric zero was not preserved: %+v", options)
	}

	// Visibility is an instant change with no operation.
	updated, err := service.UpdateInstance(context.Background(), &enginev1.UpdateInstanceRequest{
		InstanceId: instance.GetId(),
		Change: &enginev1.UpdateInstanceRequest_Visibility{
			Visibility: &enginev1.SetVisibility{ShowInChatPicker: true},
		},
	})
	if err != nil {
		t.Fatalf("UpdateInstance visibility: %v", err)
	}
	if !updated.GetInstance().GetShowInChatPicker() || updated.GetOperationId() != "" {
		t.Fatalf("updated = %+v", updated)
	}

	// A start schedules work.
	started, err := service.UpdateInstance(context.Background(), &enginev1.UpdateInstanceRequest{
		InstanceId: instance.GetId(),
		Change: &enginev1.UpdateInstanceRequest_Start{
			Start: &enginev1.StartInstance{Restart: true},
		},
	})
	if err != nil {
		t.Fatalf("UpdateInstance start: %v", err)
	}
	if started.GetOperationId() == "" || started.GetState() == enginev1.OperationState_OPERATION_STATE_UNSPECIFIED {
		t.Fatalf("start = %+v", started)
	}

	// A stop puts the instance into a stopping operation.
	stopped, err := service.UpdateInstance(context.Background(), &enginev1.UpdateInstanceRequest{
		InstanceId: instance.GetId(),
		Change:     &enginev1.UpdateInstanceRequest_Stop{Stop: &enginev1.StopInstance{}},
	})
	if err != nil {
		t.Fatalf("UpdateInstance stop: %v", err)
	}
	if stopped.GetOperationId() == "" {
		t.Fatalf("stop = %+v", stopped)
	}

	fetched, err := service.GetInstance(context.Background(), &enginev1.GetInstanceRequest{InstanceId: instance.GetId()})
	if err != nil {
		t.Fatalf("GetInstance: %v", err)
	}
	if fetched.GetInstance().GetId() != instance.GetId() {
		t.Fatalf("fetched = %+v", fetched)
	}

	deleted, err := service.DeleteInstance(context.Background(), &enginev1.DeleteInstanceRequest{InstanceId: instance.GetId()})
	if err != nil {
		t.Fatalf("DeleteInstance: %v", err)
	}
	if deleted.GetOperationId() == "" {
		t.Fatalf("deleted = %+v", deleted)
	}

	_, err = service.GetInstance(context.Background(), &enginev1.GetInstanceRequest{InstanceId: instance.GetId()})
	if err != nil {
		t.Fatalf("GetInstance nach DeleteInstance: %v", err) // the deletion is scheduled, not done
	}
	_, err = service.GetInstance(context.Background(), &enginev1.GetInstanceRequest{InstanceId: "does-not-exist"})
	requireEngineCode(t, err, codes.NotFound)

	// The stop and delete operations finish in the background. Wait for both,
	// so no goroutine writes state after the test's temp directory is gone.
	awaitGrpcOperation(t, service, started.GetOperationId())
	awaitGrpcOperation(t, service, stopped.GetOperationId())
	awaitGrpcOperation(t, service, deleted.GetOperationId())
}

// awaitGrpcOperation polls GetOperation until the operation left the running
// state, so async state persists are done when the test ends.
func awaitGrpcOperation(t *testing.T, service *grpcService, operationID string) {
	t.Helper()
	if operationID == "" {
		return
	}
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		operation, err := service.GetOperation(context.Background(), &enginev1.GetOperationRequest{OperationId: operationID})
		if err != nil {
			t.Fatalf("GetOperation(%s): %v", operationID, err)
		}
		switch operation.GetOperation().GetState() {
		case enginev1.OperationState_OPERATION_STATE_RUNNING, enginev1.OperationState_OPERATION_STATE_QUEUED:
			time.Sleep(10 * time.Millisecond)
		default:
			return
		}
	}
	t.Fatalf("Operation %s wurde nicht fertig", operationID)
}

func TestGRPCErrorCodesSurviveTheTransport(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	module.mu.Lock()
	module.instances["inst-1"] = &EngineInstance{
		ID: "inst-1", State: "ready", ModelID: "m",
		RequestedConfig: defaultEngineConfig(), EffectiveConfig: defaultEngineConfig(),
	}
	module.mu.Unlock()

	err := engineErrorStatus(&ResourceConflictError{
		Resource: "gpu:test", RequiredBytes: 1 << 30, AvailableBytes: 0,
		Reason: "Reserve unterschritten",
	})
	detail := engineErrorDetail(t, err)
	if detail.GetCode() != "resource_conflict" {
		t.Fatalf("detail = %+v", detail)
	}

	gpuErr := engineErrorStatus(&gpuRuntimeUnavailableError{Reason: "kein Build", Remediation: "use_cpu_runtime"})
	gpuDetail := engineErrorDetail(t, gpuErr)
	if gpuDetail.GetCode() != "gpu_runtime_unavailable" || gpuDetail.GetRemediation() != "use_cpu_runtime" {
		t.Fatalf("gpu detail = %+v", gpuDetail)
	}

	_, err = service.GetInstance(context.Background(), &enginev1.GetInstanceRequest{InstanceId: "nope"})
	requireEngineCode(t, err, codes.NotFound)

	// A config naming one of the removed runtimes has to be refused outright
	// rather than quietly resolved to llama.cpp.
	_, err = service.InstallRuntime(context.Background(), &enginev1.InstallRuntimeRequest{
		Runtime: enginev1.RuntimeKind(3),
	})
	requireEngineCode(t, err, codes.InvalidArgument)
}

func engineErrorDetail(t *testing.T, err error) *enginev1.EngineError {
	t.Helper()
	if err == nil {
		t.Fatal("kein Fehler")
	}
	stat, ok := status.FromError(err)
	if !ok {
		t.Fatal("kein gRPC-Status")
	}
	for _, any := range stat.Proto().GetDetails() {
		detail := &enginev1.EngineError{}
		if any.MessageName() == detail.ProtoReflect().Descriptor().FullName() {
			if err := any.UnmarshalTo(detail); err != nil {
				t.Fatalf("EngineError entpacken: %v", err)
			}
			return detail
		}
	}
	t.Fatalf("kein EngineError-Detail in %v", stat.Proto().GetDetails())
	return nil
}

func TestGRPCKeysAndOperations(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	module.mu.Lock()
	module.instances["inst-1"] = &EngineInstance{ID: "inst-1"}
	module.mu.Unlock()

	created, err := service.CreateKey(context.Background(), &enginev1.CreateKeyRequest{Name: "test", InstanceIds: []string{"inst-1"}})
	if err != nil {
		t.Fatalf("CreateKey: %v", err)
	}
	plaintext := created.GetPlaintext()
	if created.GetKey().GetId() == "" || plaintext == "" {
		t.Fatalf("created = %+v", created)
	}

	keys, err := service.ListKeys(context.Background(), &enginev1.ListKeysRequest{})
	if err != nil {
		t.Fatalf("ListKeys: %v", err)
	}
	if len(keys.GetKeys()) != 1 || keys.GetKeys()[0].GetName() != "test" {
		t.Fatalf("keys = %+v", keys)
	}

	rotated, err := service.RotateKey(context.Background(), &enginev1.RotateKeyRequest{KeyId: created.GetKey().GetId()})
	if err != nil {
		t.Fatalf("RotateKey: %v", err)
	}
	if rotated.GetPlaintext() == plaintext || rotated.GetPlaintext() == "" {
		t.Fatalf("rotate = %+v", rotated)
	}
	if rotated.GetKey().GetId() == created.GetKey().GetId() {
		t.Fatalf("rotate muss einen neuen Schluessel erzeugen: %+v", rotated)
	}
	// Rotating revokes the old key, so revoking it again fails.
	if _, err := service.RevokeKey(context.Background(), &enginev1.RevokeKeyRequest{KeyId: created.GetKey().GetId()}); err == nil {
		t.Fatal("alter Schluessel muss nach Rotation widerrufen sein")
	}

	revoked, err := service.RevokeKey(context.Background(), &enginev1.RevokeKeyRequest{KeyId: rotated.GetKey().GetId()})
	if err != nil {
		t.Fatalf("RevokeKey: %v", err)
	}
	if !revoked.GetRevoked() {
		t.Fatalf("revoked = %+v", revoked)
	}

	if _, err := service.RevokeKey(context.Background(), &enginev1.RevokeKeyRequest{KeyId: rotated.GetKey().GetId()}); err == nil {
		t.Fatal("zweites Revoke muss fehlschlagen")
	}

	_, err = service.CreateKey(context.Background(), &enginev1.CreateKeyRequest{Name: "bad", InstanceIds: []string{"inst-never"}})
	requireEngineCode(t, err, codes.InvalidArgument)
}

func TestSimulateParallelLoadRefusesMoreModelsThanTheCap(t *testing.T) {
	_, service := newGRPCEngineModule(t)
	models := make([]*enginev1.SimulateModelEntry, 0, maxSimulatedModels+1)
	for range maxSimulatedModels + 1 {
		models = append(models, &enginev1.SimulateModelEntry{ModelId: "model"})
	}
	// Each entry costs a planner allocation, so an unbounded list lets one
	// request drive unbounded work.
	_, err := service.SimulateParallelLoad(context.Background(), &enginev1.SimulateParallelLoadRequest{
		Models: models,
	})
	requireEngineCode(t, err, codes.InvalidArgument)
}

func TestGRPCSimulateParallelLoad(t *testing.T) {
	_, service := newGRPCEngineModule(t)
	catalog, err := service.ListModels(context.Background(), &enginev1.ListModelsRequest{})
	if err != nil {
		t.Fatal(err)
	}
	simulated, err := service.SimulateParallelLoad(context.Background(), &enginev1.SimulateParallelLoadRequest{
		Models: []*enginev1.SimulateModelEntry{{
			ModelId: catalog.GetModels()[0].GetId(),
			Config: &enginev1.EngineConfig{
				ContextTokens:  ptrInt32(4096),
				MaxSequences:   1,
				RuntimeOptions: structFromMap(map[string]interface{}{"allow_ram_offload": true}),
			},
		}},
	})
	if err != nil {
		t.Fatalf("SimulateParallelLoad: %v", err)
	}
	if len(simulated.GetModels()) != 1 || simulated.GetHost() == nil || simulated.GetTotals() == nil {
		t.Fatalf("simulated = %+v", simulated)
	}
}

func TestGRPCEventConversion(t *testing.T) {
	module, _ := newGRPCEngineModule(t)
	now := time.Now().UTC()

	snapshot := engineEventToProto(module, engineEvent{
		Type:      "instance_changed",
		Data:      &EngineInstance{ID: "inst-1", UpdatedAt: now},
		Timestamp: now,
	})
	if _, ok := snapshot.GetEvent().(*enginev1.StreamEventsResponse_InstanceChanged); !ok {
		t.Fatalf("instance_changed = %+v", snapshot)
	}

	deleted := engineEventToProto(module, engineEvent{Type: "instance_deleted", Data: map[string]string{"id": "inst-7"}})
	deletedEvent, ok := deleted.GetEvent().(*enginev1.StreamEventsResponse_InstanceDeleted)
	if !ok || deletedEvent.InstanceDeleted.GetInstanceId() != "inst-7" {
		t.Fatalf("instance_deleted = %+v", deleted)
	}

	rescanned := engineEventToProto(module, engineEvent{Type: "models_rescanned", Data: map[string]interface{}{"count": float64(3)}})
	rescannedEvent, ok := rescanned.GetEvent().(*enginev1.StreamEventsResponse_ModelsRescanned)
	if !ok || rescannedEvent.ModelsRescanned.GetCount() != 3 {
		t.Fatalf("models_rescanned = %+v", rescanned)
	}

	guard := engineEventToProto(module, engineEvent{Type: "guard_state", Data: map[string]interface{}{"state": GuardCritical}})
	guardEvent, ok := guard.GetEvent().(*enginev1.StreamEventsResponse_GuardState)
	if !ok || guardEvent.GuardState.GetState() != enginev1.GuardState_GUARD_STATE_CRITICAL {
		t.Fatalf("guard_state = %+v", guard)
	}

	generic := engineEventToProto(module, engineEvent{Type: "future_kind", Data: map[string]string{"a": "b"}})
	genericEvent, ok := generic.GetEvent().(*enginev1.StreamEventsResponse_Generic)
	if !ok || genericEvent.Generic.GetType() != "future_kind" {
		t.Fatalf("generic = %+v", generic)
	}

	unknown := engineEventToProto(module, engineEvent{Type: "instance_changed", Data: "not-an-instance"})
	if _, ok := unknown.GetEvent().(*enginev1.StreamEventsResponse_InstanceChanged); ok {
		t.Fatalf("kaputtes Event muss wegfallen: %+v", unknown)
	}
}
