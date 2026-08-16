// The gRPC face of the engine. Each method reads as the sequence of steps the
// call takes; the wire conversions live in proto.go, so a handler here is
// readable as "what did the caller ask, what did the engine do, what comes
// back".
//
// The one HTTP route group that stays behind is the gateway itself (it serves
// the OpenAI API so an unmodified SDK can point at it) and the legacy
// /engine/start, /load, /stop and /status helpers, which predate the catalog
// and exist for tooling that still drives the engine by its old shape.
// Everything the Studio client calls lives here.

package engine

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	"github.com/culpeohq/backend/internal/engineplanner"
	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/internal/modelcatalog"
	"github.com/culpeohq/backend/internal/noderouting"
)

type grpcService struct {
	enginev1.UnimplementedEngineServiceServer
	module *EngineModule
}

func (m *EngineModule) RegisterGRPC(server *grpc.Server) {
	enginev1.RegisterEngineServiceServer(server, &grpcService{module: m})
}

// engineUserID is the request-scoped identity of a gRPC caller. The auth
// interceptor has already accepted the token; everything without one belongs
// to the single local user, exactly as the HTTP helpers did.
func engineUserID(ctx context.Context) string {
	if userID := grpcmw.UserIDFromContext(ctx); userID != "" {
		return normalizedEngineUserID(userID)
	}
	return "local"
}

// engineErrorStatus turns an engine failure into the gRPC error the client
// acts on. The code string is the one the HTTP error body carried - the
// client still dispatches on it - and the structured fields ride along as an
// EngineError detail for the calls where they were part of the JSON.
func engineErrorStatus(err error) error {
	if err == nil {
		err = fmt.Errorf("unbekannter Engine-Fehler")
	}
	switch {
	case errors.Is(err, os.ErrNotExist):
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, localinference.ErrGuardRejected):
		return status.Error(codes.Unavailable, err.Error())
	case errors.Is(err, localinference.ErrQueueTimeout):
		return status.Error(codes.DeadlineExceeded, err.Error())
	}
	var conflict *engineplanner.ConflictError
	if errors.As(err, &conflict) {
		return engineErrorWithDetail(codes.FailedPrecondition, err.Error(), &enginev1.EngineError{
			Code:     "resource_conflict",
			Conflict: plannerConflictToProto(conflict),
		})
	}
	var loadConflict *ResourceConflictError
	if errors.As(err, &loadConflict) {
		return engineErrorWithDetail(codes.FailedPrecondition, err.Error(), &enginev1.EngineError{
			Code:     "resource_conflict",
			Conflict: resourceConflictToProto(loadConflict),
		})
	}
	var gpuRuntimeError *gpuRuntimeUnavailableError
	if errors.As(err, &gpuRuntimeError) {
		return engineErrorWithDetail(codes.FailedPrecondition, err.Error(), &enginev1.EngineError{
			Code:        "gpu_runtime_unavailable",
			Message:     err.Error(),
			Reason:      gpuRuntimeError.Reason,
			Remediation: gpuRuntimeError.Remediation,
		})
	}
	var unsupportedFix *engineUnsupportedFixError
	if errors.As(err, &unsupportedFix) {
		return status.Error(codes.InvalidArgument, err.Error())
	}
	return status.Error(codes.InvalidArgument, err.Error())
}

func engineErrorWithDetail(code codes.Code, message string, detail *enginev1.EngineError) error {
	st, err := status.New(code, message).WithDetails(detail)
	if err != nil {
		return status.Error(code, message)
	}
	return st.Err()
}

// The catalog. ---------------------------------------------------

func (s *grpcService) ListModels(ctx context.Context, _ *enginev1.ListModelsRequest) (*enginev1.ListModelsResponse, error) {
	m := s.module
	m.mu.RLock()
	records := append([]modelcatalog.ModelRecord(nil), m.models...)
	modelDir := m.modelDir
	m.mu.RUnlock()
	models := modelRecordsToProto(records)
	// The catalogs of the nodes are listed beside the local one. A model on a
	// node is a model this Studio can start; where it lies is a property of
	// the entry, not a separate screen.
	models = append(models, m.nodeModels(ctx)...)
	return &enginev1.ListModelsResponse{Models: models, ModelDir: modelDir}, nil
}

func (s *grpcService) RescanModels(ctx context.Context, _ *enginev1.RescanModelsRequest) (*enginev1.RescanModelsResponse, error) {
	m := s.module
	records, err := m.rescan(ctx)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	m.events.publish("models_rescanned", map[string]interface{}{"count": len(records)})
	models := modelRecordsToProto(records)
	models = append(models, m.rescanNodeModels(ctx)...)
	return &enginev1.RescanModelsResponse{Models: models, ModelDir: m.modelDir}, nil
}

func (s *grpcService) DeleteModel(ctx context.Context, req *enginev1.DeleteModelRequest) (*enginev1.DeleteModelResponse, error) {
	m := s.module
	modelID := strings.TrimSpace(req.GetModelId())
	if target, client, localID, remote, err := m.nodeEngineFor(modelID); remote {
		if err != nil {
			return nil, err
		}
		return m.deleteModelOnNode(ctx, target, client, localID)
	}
	records, err := m.deleteModel(ctx, modelID)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.DeleteModelResponse{Models: modelRecordsToProto(records), ModelDir: m.modelDir}, nil
}

func (s *grpcService) GetCapabilities(ctx context.Context, _ *enginev1.GetCapabilitiesRequest) (*enginev1.GetCapabilitiesResponse, error) {
	m := s.module
	snapshot, runtimes := m.runtimeCapabilities(ctx)
	settings := m.settings.Get()
	ramReserve := effectiveReserveBytes(settings.EngineRAMReserveBytes, snapshot.RAMTotalBytes, 15, 4<<30)
	gpuReserve := int64(0)
	gpuReservesByID := make(map[string]int64)
	for _, gpu := range snapshot.GPUs {
		if gpu.SharedMemory {
			continue
		}
		reserve := effectiveReserveBytes(settings.EngineGPUReserveBytes, gpu.VRAMTotalBytes, 10, 512<<20)
		gpuReservesByID[gpu.ID] = reserve
		if reserve > gpuReserve {
			gpuReserve = reserve
		}
	}
	return &enginev1.GetCapabilitiesResponse{
		Hardware: hardwareSnapshotToProto(snapshot),
		Runtimes: runtimeCapabilitiesToProto(runtimes),
		Defaults: &enginev1.EngineDefaults{
			MinimumContextTokens:  4096,
			ContextStepTokens:     256,
			RamReserve:            "max(4 GiB, 15%)",
			GpuReserve:            "max(512 MiB, 10%)",
			KvCachePolicy:         kvCachePolicyToProto("prefer_4bit"),
			MaxSequences:          1,
			Autostart:             false,
			GatewayUrl:            m.gatewayURL,
			WeightQuantization:    "unchanged",
			RamReserveBytes:       ramReserve,
			GpuReserveBytes:       gpuReserve,
			GpuReserveBytesById:   gpuReservesByID,
			RamReserveIsAutomatic: settings.EngineRAMReserveBytes == nil,
			GpuReserveIsAutomatic: settings.EngineGPUReserveBytes == nil,
			EmergencyRamFloor:     "max(1 GiB, 5%)",
			EmergencyGpuFloor:     "max(256 MiB, 3%)",
		},
	}, nil
}

func (s *grpcService) GetRecommendation(ctx context.Context, req *enginev1.GetRecommendationRequest) (*enginev1.GetRecommendationResponse, error) {
	m := s.module
	config := engineConfigFromProto(req.GetConfig())
	// A recommendation is a plan against the hardware the model would run on,
	// so it has to be computed there.
	if target, client, localID, remote, err := m.nodeEngineFor(strings.TrimSpace(req.GetModelId())); remote {
		if err != nil {
			return nil, err
		}
		callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
		defer cancel()
		response, callErr := client.GetRecommendation(callCtx, &enginev1.GetRecommendationRequest{
			ModelId: localID, Config: req.GetConfig(),
		})
		if callErr != nil {
			return nil, nodeError(target, callErr)
		}
		return response, nil
	}
	plan, _, err := m.recommendation(ctx, strings.TrimSpace(req.GetModelId()), "recommendation", config)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	message := contextPlanToProto(&plan)
	if message == nil {
		return nil, status.Error(codes.Internal, "Planer lieferte keinen Plan")
	}
	return &enginev1.GetRecommendationResponse{Plan: message}, nil
}

func (s *grpcService) SimulateParallelLoad(ctx context.Context, req *enginev1.SimulateParallelLoadRequest) (*enginev1.SimulateParallelLoadResponse, error) {
	m := s.module
	// The cap maxSimulatedModels documents was never enforced, which let one
	// request drive an unbounded number of planner allocations.
	if len(req.GetModels()) > maxSimulatedModels {
		return nil, status.Errorf(codes.InvalidArgument,
			"es koennen hoechstens %d Modelle gleichzeitig simuliert werden; angefragt wurden %d",
			maxSimulatedModels, len(req.GetModels()))
	}
	entries := make([]simulateModelEntry, 0, len(req.GetModels()))
	for _, entry := range req.GetModels() {
		simulateEntry := simulateModelEntry{ModelID: strings.TrimSpace(entry.GetModelId())}
		if entry.GetConfig() != nil {
			config := engineConfigFromProto(entry.GetConfig())
			simulateEntry.Config = &config
		}
		entries = append(entries, simulateEntry)
	}
	includeRunning := true
	if req.IncludeRunning != nil {
		includeRunning = req.GetIncludeRunning()
	}
	result, err := m.simulateParallelLoad(ctx, entries, includeRunning)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.SimulateParallelLoadResponse{
		Feasible:                 result.Feasible,
		Models:                   simulatedModelsToProto(result.Models),
		Totals:                   memoryAllocationToProto(result.Totals),
		Host:                     simulatedHostToProto(result.Host),
		AffectedRunningInstances: append([]string{}, result.AffectedRunningInstances...),
		Recommendations:          append([]string{}, result.Recommendations...),
		Reason:                   result.Reason,
	}, nil
}

// The instances. -----------------------------------------------------

func (s *grpcService) ListInstances(ctx context.Context, _ *enginev1.ListInstancesRequest) (*enginev1.ListInstancesResponse, error) {
	m := s.module
	instances := instancesToProto(m.listInstancesForUser(engineUserID(ctx)))
	instances = append(instances, m.nodeInstances(ctx)...)
	return &enginev1.ListInstancesResponse{Instances: instances}, nil
}

func (s *grpcService) CreateInstance(ctx context.Context, req *enginev1.CreateInstanceRequest) (*enginev1.CreateInstanceResponse, error) {
	m := s.module
	modelID := strings.TrimSpace(req.GetModelId())
	if modelID == "" {
		return nil, status.Error(codes.InvalidArgument, "model_id ist erforderlich")
	}
	// The node can be named outright or be implied by a model id that came
	// from a node's catalog. Both mean the same thing, and a model id that
	// already names a node wins: it is the entry the user actually picked.
	if nodeID, localModelID, remote := noderouting.Split(modelID); remote {
		return m.createInstanceOnNode(ctx, nodeID, req, localModelID)
	}
	if nodeID := strings.TrimSpace(req.GetNodeId()); nodeID != "" {
		return m.createInstanceOnNode(ctx, nodeID, req, modelID)
	}
	config := engineConfigFromProto(req.GetConfig())
	instance, operation, err := m.createInstance(ctx, modelID, strings.TrimSpace(req.GetServedModelName()), config)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.CreateInstanceResponse{
		Instance:      instanceForUserToProto(m, instance, engineUserID(ctx)),
		OperationId:   operation.ID,
		State:         operationStateFromProto(operation),
		QueuePosition: int32(operation.QueuePosition),
	}, nil
}

func (s *grpcService) GetInstance(ctx context.Context, req *enginev1.GetInstanceRequest) (*enginev1.GetInstanceResponse, error) {
	m := s.module
	id := strings.TrimSpace(req.GetInstanceId())
	if target, client, localID, remote, err := m.nodeEngineFor(id); remote {
		if err != nil {
			return nil, err
		}
		return m.getInstanceFromNode(ctx, target, client, localID)
	}
	instance, ok := m.getInstance(id)
	if !ok {
		return nil, engineErrorStatus(os.ErrNotExist)
	}
	return &enginev1.GetInstanceResponse{Instance: instanceForUserToProto(m, instance, engineUserID(ctx))}, nil
}

func (s *grpcService) GetInstanceMetrics(ctx context.Context, req *enginev1.GetInstanceMetricsRequest) (*enginev1.GetInstanceMetricsResponse, error) {
	m := s.module
	id := strings.TrimSpace(req.GetInstanceId())
	if target, client, localID, remote, err := m.nodeEngineFor(id); remote {
		if err != nil {
			return nil, err
		}
		callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
		defer cancel()
		response, callErr := client.GetInstanceMetrics(callCtx, &enginev1.GetInstanceMetricsRequest{InstanceId: localID})
		if callErr != nil {
			return nil, nodeError(target, callErr)
		}
		return response, nil
	}
	instance, ok := m.getInstance(id)
	if !ok {
		return nil, engineErrorStatus(os.ErrNotExist)
	}
	return &enginev1.GetInstanceMetricsResponse{Metrics: structFromMap(m.instanceMetrics(ctx, instance))}, nil
}

func (s *grpcService) UpdateInstance(ctx context.Context, req *enginev1.UpdateInstanceRequest) (*enginev1.UpdateInstanceResponse, error) {
	m := s.module
	id := strings.TrimSpace(req.GetInstanceId())
	// Every change an instance takes - start, stop, config, visibility - is
	// made where the instance lives. The oneof travels untouched, so a node
	// applies the same change with the same code.
	if target, client, localID, remote, err := m.nodeEngineFor(id); remote {
		if err != nil {
			return nil, err
		}
		return m.updateInstanceOnNode(ctx, target, client, req, localID)
	}
	instance, ok := m.getInstance(id)
	if !ok {
		return nil, engineErrorStatus(os.ErrNotExist)
	}
	userID := engineUserID(ctx)

	switch change := req.GetChange().(type) {
	case *enginev1.UpdateInstanceRequest_Visibility:
		if err := m.preferences.setVisible(userID, id, change.Visibility.GetShowInChatPicker()); err != nil {
			return nil, engineErrorStatus(err)
		}
		updated, _ := m.getInstance(id)
		m.events.publish("instance_changed", updated)
		return &enginev1.UpdateInstanceResponse{Instance: instanceForUserToProto(m, updated, userID)}, nil

	case *enginev1.UpdateInstanceRequest_GenerationDefaults:
		defaults := mapFromStruct(change.GenerationDefaults.GetGenerationDefaults())
		m.mu.Lock()
		current := m.instances[id]
		if current != nil {
			current.RequestedConfig.GenerationDefaults = cloneJSONMap(defaults)
			current.EffectiveConfig.GenerationDefaults = cloneJSONMap(defaults)
			current.UpdatedAt = time.Now().UTC()
			_ = m.persistLocked()
			instance = cloneInstance(current)
		}
		m.mu.Unlock()
		m.events.publish("instance_changed", instance)
		return &enginev1.UpdateInstanceResponse{Instance: instanceForUserToProto(m, instance, userID)}, nil

	case *enginev1.UpdateInstanceRequest_Start:
		config := instance.RequestedConfig
		if change.Start.GetRequestedConfig() != nil {
			incoming := engineConfigFromProto(change.Start.GetRequestedConfig())
			config = mergeEngineConfigOverBase(instance.RequestedConfig, incoming)
		}
		action := "start"
		if change.Start.GetRestart() {
			action = "restart"
		}
		operation, err := m.scheduleStart(id, config, action)
		if err != nil {
			return nil, engineErrorStatus(err)
		}
		updated, _ := m.getInstance(id)
		return &enginev1.UpdateInstanceResponse{
			Instance:      instanceForUserToProto(m, updated, userID),
			OperationId:   operation.ID,
			State:         operationStateFromProto(operation),
			QueuePosition: int32(operation.QueuePosition),
		}, nil

	case *enginev1.UpdateInstanceRequest_Stop:
		operation, err := m.scheduleStop(id)
		if err != nil {
			return nil, engineErrorStatus(err)
		}
		updated, _ := m.getInstance(id)
		return &enginev1.UpdateInstanceResponse{
			Instance:      instanceForUserToProto(m, updated, userID),
			OperationId:   operation.ID,
			State:         operationStateFromProto(operation),
			QueuePosition: int32(operation.QueuePosition),
		}, nil

	case *enginev1.UpdateInstanceRequest_ApplyFix:
		fix := strings.ToLower(strings.TrimSpace(change.ApplyFix.GetFix()))
		config, err := m.configForFix(instance, fix)
		if err != nil {
			return nil, engineErrorStatus(&engineUnsupportedFixError{cause: err})
		}
		operation, err := m.scheduleStart(id, config, "apply_fix")
		if err != nil {
			return nil, engineErrorStatus(err)
		}
		updated, _ := m.getInstance(id)
		return &enginev1.UpdateInstanceResponse{
			Instance:      instanceForUserToProto(m, updated, userID),
			OperationId:   operation.ID,
			State:         operationStateFromProto(operation),
			QueuePosition: int32(operation.QueuePosition),
			AppliedFix:    fix,
		}, nil

	case *enginev1.UpdateInstanceRequest_RequestedConfig:
		config := engineConfigFromProto(change.RequestedConfig.GetRequestedConfig())
		m.mu.Lock()
		if current := m.instances[id]; current != nil {
			current.RequestedConfig = config
			current.RestartRequiredFields = restartRequiredFields()
			current.UpdatedAt = time.Now().UTC()
			instance = cloneInstance(current)
			_ = m.persistLocked()
		}
		m.mu.Unlock()
		return &enginev1.UpdateInstanceResponse{Instance: instanceForUserToProto(m, instance, userID)}, nil

	case nil:
		return nil, status.Error(codes.InvalidArgument, "genau eine Aenderung ist erforderlich")
	default:
		return nil, status.Error(codes.InvalidArgument, "unbekannte Aenderung")
	}
}

// engineUnsupportedFixError is the invalid-request kind for a fix the engine
// does not know. The HTTP API answered 400 with code "unsupported_fix"; the
// client never acted on that code, so a plain InvalidArgument is enough here.
type engineUnsupportedFixError struct{ cause error }

func (e *engineUnsupportedFixError) Error() string { return e.cause.Error() }

func (s *grpcService) EnsureInstanceReady(ctx context.Context, req *enginev1.EnsureInstanceReadyRequest) (*enginev1.EnsureInstanceReadyResponse, error) {
	m := s.module
	if target, client, localID, remote, err := m.nodeEngineFor(strings.TrimSpace(req.GetInstanceId())); remote {
		if err != nil {
			return nil, err
		}
		return m.ensureReadyOnNode(ctx, target, client, localID)
	}
	instance, operation, err := m.ensureReady(strings.TrimSpace(req.GetInstanceId()))
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	response := &enginev1.EnsureInstanceReadyResponse{
		Instance:     instanceForUserToProto(m, instance, engineUserID(ctx)),
		AlreadyReady: operation == nil,
	}
	if operation != nil {
		response.OperationId = operation.ID
		response.State = operationStateFromProto(operation)
		response.QueuePosition = int32(operation.QueuePosition)
	}
	return response, nil
}

func (s *grpcService) DeleteInstance(ctx context.Context, req *enginev1.DeleteInstanceRequest) (*enginev1.DeleteInstanceResponse, error) {
	m := s.module
	if target, client, localID, remote, err := m.nodeEngineFor(strings.TrimSpace(req.GetInstanceId())); remote {
		if err != nil {
			return nil, err
		}
		return m.deleteInstanceOnNode(ctx, target, client, localID)
	}
	instance, operation, err := m.scheduleDelete(strings.TrimSpace(req.GetInstanceId()))
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.DeleteInstanceResponse{
		Instance:    instanceForUserToProto(m, instance, engineUserID(ctx)),
		OperationId: operation.ID,
	}, nil
}

// GetInstanceLogs hands back what the worker itself printed. The error summary
// on a failed instance is a diagnosis derived from this output; when the
// diagnosis does not fit the case, this is the only way to see what actually
// happened.
//
// The buffers live with the process, so a stopped instance has nothing to
// show. That is reported as an empty, unavailable answer rather than an error,
// because it is the normal state of most instances rather than a failure.
func (s *grpcService) GetInstanceLogs(ctx context.Context, req *enginev1.GetInstanceLogsRequest) (*enginev1.GetInstanceLogsResponse, error) {
	m := s.module
	id := strings.TrimSpace(req.GetInstanceId())
	if target, client, localID, remote, routeErr := m.nodeEngineFor(id); remote {
		if routeErr != nil {
			return nil, routeErr
		}
		callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
		defer cancel()
		response, callErr := client.GetInstanceLogs(callCtx, &enginev1.GetInstanceLogsRequest{
			InstanceId: localID, TailLines: req.GetTailLines(),
		})
		if callErr != nil {
			return nil, nodeError(target, callErr)
		}
		return response, nil
	}
	if _, ok := m.getInstance(id); !ok {
		return nil, engineErrorStatus(os.ErrNotExist)
	}
	logs, err := m.instanceLogs(id, int(req.GetTailLines()))
	if err != nil {
		return &enginev1.GetInstanceLogsResponse{Available: false}, nil
	}
	return &enginev1.GetInstanceLogsResponse{
		Stdout: logs.Stdout, Stderr: logs.Stderr, Available: true,
	}, nil
}

// Quantisation. ------------------------------------------------------

func (s *grpcService) ListQuantizationTypes(ctx context.Context, _ *enginev1.ListQuantizationTypesRequest) (*enginev1.ListQuantizationTypesResponse, error) {
	types, err := s.module.quantizationTypes(ctx)
	if err != nil {
		// Not having a runtime installed yet is the ordinary case here, not an
		// error worth failing the call over: the client renders the reason.
		return &enginev1.ListQuantizationTypesResponse{Available: false, UnavailableReason: err.Error()}, nil
	}
	return &enginev1.ListQuantizationTypesResponse{
		Types: quantizationTypesToProto(types), Available: true,
	}, nil
}

func (s *grpcService) PreflightQuantization(ctx context.Context, req *enginev1.PreflightQuantizationRequest) (*enginev1.PreflightQuantizationResponse, error) {
	// Quantising reads one file and writes another beside it, both on the
	// machine that holds them. There is nothing sensible to forward.
	if noderouting.IsRemote(strings.TrimSpace(req.GetRequest().GetSourceModelId())) {
		return nil, errNodeOnlyLocal("Quantisieren")
	}
	report, err := s.module.preflightQuantization(ctx, quantizeRequestFromProto(req.GetRequest()))
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.PreflightQuantizationResponse{Preflight: quantizePreflightToProto(report)}, nil
}

func (s *grpcService) StartQuantization(ctx context.Context, req *enginev1.StartQuantizationRequest) (*enginev1.StartQuantizationResponse, error) {
	if noderouting.IsRemote(strings.TrimSpace(req.GetRequest().GetSourceModelId())) {
		return nil, errNodeOnlyLocal("Quantisieren")
	}
	operation, report, err := s.module.startQuantization(ctx, quantizeRequestFromProto(req.GetRequest()))
	if err != nil {
		// A refusal carries the preflight that explains it, so the client can
		// show which blocker stopped the conversion rather than only the text.
		if report.SourceModelID != "" {
			return &enginev1.StartQuantizationResponse{
				State: enginev1.OperationState_OPERATION_STATE_FAILED, Preflight: quantizePreflightToProto(report),
			}, engineErrorStatus(err)
		}
		return nil, engineErrorStatus(err)
	}
	return &enginev1.StartQuantizationResponse{
		OperationId: operation.ID,
		State:       operationStateFromProto(operation),
		Preflight:   quantizePreflightToProto(report),
	}, nil
}

// The operations and the feed. ---------------------------------------

func (s *grpcService) GetOperation(ctx context.Context, req *enginev1.GetOperationRequest) (*enginev1.GetOperationResponse, error) {
	m := s.module
	id := strings.TrimSpace(req.GetOperationId())
	if target, client, localID, remote, err := m.nodeEngineFor(id); remote {
		if err != nil {
			return nil, err
		}
		return m.getOperationFromNode(ctx, target, client, localID)
	}
	operation, ok := m.operation(id)
	if !ok {
		return nil, engineErrorStatus(os.ErrNotExist)
	}
	return &enginev1.GetOperationResponse{Operation: operationToProto(operation)}, nil
}

func (s *grpcService) CancelOperation(ctx context.Context, req *enginev1.CancelOperationRequest) (*enginev1.CancelOperationResponse, error) {
	m := s.module
	id := strings.TrimSpace(req.GetOperationId())
	if target, client, localID, remote, err := m.nodeEngineFor(id); remote {
		if err != nil {
			return nil, err
		}
		return m.cancelOperationOnNode(ctx, target, client, localID)
	}
	operation, err := m.cancelOperation(id)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.CancelOperationResponse{Operation: operationToProto(operation)}, nil
}

// StreamEvents feeds the engine events to a caller. The stream opens with a
// snapshot of the instances, exactly as the HTTP event feed did, and every
// message after that carries one event of the hub, filtered for the caller.
// The HTTP version needed a single-use ticket because an EventSource cannot
// send an Authorization header; a gRPC stream authenticates itself like every
// other call, so the ticket machinery is gone.
func (s *grpcService) StreamEvents(req *enginev1.StreamEventsRequest, stream grpc.ServerStreamingServer[enginev1.StreamEventsResponse]) error {
	m := s.module
	userID := engineUserID(stream.Context())
	// The snapshot has to carry the nodes too: the client replaces its list
	// with it, so anything missing here is treated as gone.
	snapshot := instancesToProto(m.listInstancesForUser(userID))
	snapshot = append(snapshot, m.nodeInstances(stream.Context())...)
	first := &enginev1.StreamEventsResponse{
		Timestamp: nowTimestamp(),
		Event:     &enginev1.StreamEventsResponse_Snapshot{Snapshot: &enginev1.InstanceSnapshot{Instances: snapshot}},
	}
	if err := stream.Send(first); err != nil {
		return err
	}
	events, unsubscribe := m.events.subscribe()
	defer unsubscribe()
	for {
		select {
		case <-stream.Context().Done():
			return stream.Context().Err()
		case event, ok := <-events:
			if !ok {
				return nil
			}
			converted := engineEventToProto(m, m.engineEventForUser(event, userID))
			if converted == nil {
				continue
			}
			converted.Timestamp = nowTimestamp()
			if err := stream.Send(converted); err != nil {
				return err
			}
		}
	}
}

// The runtimes the instances are built from. -------------------------

func (s *grpcService) ListRuntimes(ctx context.Context, _ *enginev1.ListRuntimesRequest) (*enginev1.ListRuntimesResponse, error) {
	m := s.module
	_, runtimes := m.runtimeCapabilities(ctx)
	jobs := []engineruntime.InstallJobSnapshot{}
	if m.installer != nil {
		jobs = m.installer.Jobs()
	}
	return &enginev1.ListRuntimesResponse{Runtimes: runtimeCapabilitiesToProto(runtimes), InstallOperations: installJobsToProto(jobs)}, nil
}

func (s *grpcService) InstallRuntime(ctx context.Context, req *enginev1.InstallRuntimeRequest) (*enginev1.InstallRuntimeResponse, error) {
	m := s.module
	if kind := engineruntime.RuntimeKind(runtimeKindFromProto(req.GetRuntime())); kind != "" && kind != engineruntime.RuntimeLlamaCPP {
		return nil, status.Errorf(codes.InvalidArgument, "Runtime %q wird nicht mehr unterstuetzt; die Engine faehrt ausschliesslich llama.cpp", kind)
	}
	if m.installer == nil {
		return nil, engineErrorStatus(errors.New("der Runtime-Installer ist nicht verfuegbar"))
	}
	snapshot, _ := m.liveHardware(ctx)
	build, _, err := m.selectBuild(snapshot, false)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	releaseForeground, err := m.beginForegroundRuntime(ctx)
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	job, err := m.startRuntimeInstall(ctx, build)
	if err != nil {
		releaseForeground()
		return nil, engineErrorStatus(err)
	}
	m.mu.Lock()
	operation, operationCtx := m.newOperationLocked("runtime_install", "", "Runtime wird vorgewärmt")
	_ = m.persistLocked()
	m.mu.Unlock()
	go func() {
		defer releaseForeground()
		_, waitErr := m.waitRuntimeInstall(operationCtx, operation.ID, "", job, "llama-server ("+string(build.Variant)+") wird vorbereitet")
		if waitErr != nil {
			if operationCtx.Err() != nil {
				return
			}
			m.setOperation(operation.ID, "failed", 1, "Runtime-Installation fehlgeschlagen", waitErr)
			return
		}
		m.setOperation(operation.ID, "completed", 1, "Runtime ist installiert und geprueft", nil)
	}()
	return &enginev1.InstallRuntimeResponse{OperationId: operation.ID, RuntimeInstall: installJobToProto(job.Snapshot())}, nil
}

// The keys the local gateway accepts. --------------------------------

func (s *grpcService) ListKeys(ctx context.Context, _ *enginev1.ListKeysRequest) (*enginev1.ListKeysResponse, error) {
	m := s.module
	keys := make([]*enginev1.GatewayKey, 0, len(m.keys.list()))
	for _, key := range m.keys.list() {
		keys = append(keys, gatewayKeyToProto(key))
	}
	return &enginev1.ListKeysResponse{Keys: keys}, nil
}

func (s *grpcService) CreateKey(ctx context.Context, req *enginev1.CreateKeyRequest) (*enginev1.CreateKeyResponse, error) {
	m := s.module
	for _, id := range req.GetInstanceIds() {
		if _, ok := m.getInstance(id); !ok {
			return nil, status.Error(codes.InvalidArgument, "unbekannte Instanz im Schluessel-Scope: "+id)
		}
	}
	public, plaintext, err := m.keys.create(strings.TrimSpace(req.GetName()), append([]string{}, req.GetInstanceIds()...))
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.CreateKeyResponse{Key: gatewayKeyToProto(public), Plaintext: plaintext}, nil
}

func (s *grpcService) RotateKey(ctx context.Context, req *enginev1.RotateKeyRequest) (*enginev1.RotateKeyResponse, error) {
	m := s.module
	public, plaintext, err := m.keys.rotate(strings.TrimSpace(req.GetKeyId()))
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.RotateKeyResponse{Key: gatewayKeyToProto(public), Plaintext: plaintext}, nil
}

func (s *grpcService) RevokeKey(ctx context.Context, req *enginev1.RevokeKeyRequest) (*enginev1.RevokeKeyResponse, error) {
	m := s.module
	if !m.keys.revoke(strings.TrimSpace(req.GetKeyId())) {
		return nil, engineErrorStatus(os.ErrNotExist)
	}
	return &enginev1.RevokeKeyResponse{Revoked: true}, nil
}

// Helpers shared by the service methods. ------------------------------

// instanceForUserToProto applies the preference filter the HTTP layer
// applied, then converts the instance.
func instanceForUserToProto(m *EngineModule, instance *EngineInstance, userID string) *enginev1.EngineInstance {
	return instanceToProto(m.instanceForUser(instance, userID))
}

// operationStateFromProto reports the operation's state the way the HTTP
// response did: a running operation with a queue position reads as queued,
// because that is what the client showed while it waited in the queue.
func operationStateFromProto(operation *EngineOperation) enginev1.OperationState {
	if operation == nil {
		return enginev1.OperationState_OPERATION_STATE_UNSPECIFIED
	}
	state := operation.State
	if state == "running" && operation.QueuePosition > 0 {
		state = "queued"
	}
	return operationStateToProto(state)
}

// Saved configurations. -----------------------------------------------

func enginePresetToProto(preset *EnginePreset) *enginev1.EnginePreset {
	if preset == nil {
		return nil
	}
	return &enginev1.EnginePreset{
		Id:          preset.ID,
		Name:        preset.Name,
		Description: preset.Description,
		Config:      engineConfigToProto(preset.Config),
		ModelId:     preset.ModelID,
		CreatedAt:   timestampOrNil(preset.CreatedAt),
		UpdatedAt:   timestampOrNil(preset.UpdatedAt),
		BuiltIn:     preset.BuiltIn,
	}
}

func enginePresetsToProto(presets []*EnginePreset) []*enginev1.EnginePreset {
	result := make([]*enginev1.EnginePreset, 0, len(presets))
	for _, preset := range presets {
		if message := enginePresetToProto(preset); message != nil {
			result = append(result, message)
		}
	}
	return result
}

func (s *grpcService) ListPresets(ctx context.Context, _ *enginev1.ListPresetsRequest) (*enginev1.ListPresetsResponse, error) {
	return &enginev1.ListPresetsResponse{Presets: enginePresetsToProto(s.module.presets.list())}, nil
}

func (s *grpcService) SavePreset(ctx context.Context, req *enginev1.SavePresetRequest) (*enginev1.SavePresetResponse, error) {
	incoming := req.GetPreset()
	if incoming == nil {
		return nil, status.Error(codes.InvalidArgument, "ein Preset ist erforderlich")
	}
	saved, err := s.module.presets.save(EnginePreset{
		ID:          strings.TrimSpace(incoming.GetId()),
		Name:        incoming.GetName(),
		Description: incoming.GetDescription(),
		Config:      engineConfigFromProto(incoming.GetConfig()),
		ModelID:     strings.TrimSpace(incoming.GetModelId()),
	})
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.SavePresetResponse{Preset: enginePresetToProto(saved)}, nil
}

func (s *grpcService) DeletePreset(ctx context.Context, req *enginev1.DeletePresetRequest) (*enginev1.DeletePresetResponse, error) {
	if err := s.module.presets.delete(strings.TrimSpace(req.GetPresetId())); err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.DeletePresetResponse{Deleted: true}, nil
}

func (s *grpcService) ExportPresets(ctx context.Context, req *enginev1.ExportPresetsRequest) (*enginev1.ExportPresetsResponse, error) {
	document, err := s.module.presets.exportPresets(req.GetPresetIds())
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.ExportPresetsResponse{
		Document:          string(document),
		SuggestedFilename: fmt.Sprintf("culpeo-engine-presets-%s.json", time.Now().UTC().Format("2006-01-02")),
	}, nil
}

func (s *grpcService) ImportPresets(ctx context.Context, req *enginev1.ImportPresetsRequest) (*enginev1.ImportPresetsResponse, error) {
	document := strings.TrimSpace(req.GetDocument())
	if document == "" {
		return nil, status.Error(codes.InvalidArgument, "die Preset-Datei ist leer")
	}
	// The document is user-supplied text, so it is bounded before parsing
	// rather than after.
	if len(document) > maxPresetDocumentBytes {
		return nil, status.Errorf(codes.InvalidArgument,
			"die Preset-Datei ist groesser als %d KB", maxPresetDocumentBytes/1024)
	}
	imported, err := s.module.presets.importPresets([]byte(document))
	if err != nil {
		return nil, engineErrorStatus(err)
	}
	return &enginev1.ImportPresetsResponse{Presets: enginePresetsToProto(imported)}, nil
}

// maxPresetDocumentBytes bounds an imported preset file. A preset is a handful
// of scalars and two small maps, so a megabyte is already far more than any
// honest export.
const maxPresetDocumentBytes = 1 << 20
