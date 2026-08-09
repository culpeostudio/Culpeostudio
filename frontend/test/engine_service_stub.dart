import 'package:grpc/grpc.dart';
import 'package:culpeo_studio/generated/culpeostudio/engine/v1/engine.pbgrpc.dart'
    as enginepb;

/// Every method of the engine service, refusing by default. A test extends this
/// and overrides only the calls it drives, instead of restating all 33
/// of them each time.
class EngineServiceStub extends enginepb.EngineServiceBase {
  Never _unused(String method) => throw GrpcError.unimplemented(
    '$method wird in diesem Test nicht genutzt',
  );

  @override
  Future<enginepb.ListModelsResponse> listModels(
    ServiceCall call,
    enginepb.ListModelsRequest request,
  ) async => _unused('listModels');

  @override
  Future<enginepb.RescanModelsResponse> rescanModels(
    ServiceCall call,
    enginepb.RescanModelsRequest request,
  ) async => _unused('rescanModels');

  @override
  Future<enginepb.DeleteModelResponse> deleteModel(
    ServiceCall call,
    enginepb.DeleteModelRequest request,
  ) async => _unused('deleteModel');

  @override
  Future<enginepb.GetCapabilitiesResponse> getCapabilities(
    ServiceCall call,
    enginepb.GetCapabilitiesRequest request,
  ) async => _unused('getCapabilities');

  @override
  Future<enginepb.GetRecommendationResponse> getRecommendation(
    ServiceCall call,
    enginepb.GetRecommendationRequest request,
  ) async => _unused('getRecommendation');

  @override
  Future<enginepb.SimulateParallelLoadResponse> simulateParallelLoad(
    ServiceCall call,
    enginepb.SimulateParallelLoadRequest request,
  ) async => _unused('simulateParallelLoad');

  @override
  Future<enginepb.ListInstancesResponse> listInstances(
    ServiceCall call,
    enginepb.ListInstancesRequest request,
  ) async => _unused('listInstances');

  @override
  Future<enginepb.CreateInstanceResponse> createInstance(
    ServiceCall call,
    enginepb.CreateInstanceRequest request,
  ) async => _unused('createInstance');

  @override
  Future<enginepb.GetInstanceResponse> getInstance(
    ServiceCall call,
    enginepb.GetInstanceRequest request,
  ) async => _unused('getInstance');

  @override
  Future<enginepb.GetInstanceMetricsResponse> getInstanceMetrics(
    ServiceCall call,
    enginepb.GetInstanceMetricsRequest request,
  ) async => _unused('getInstanceMetrics');

  @override
  Future<enginepb.UpdateInstanceResponse> updateInstance(
    ServiceCall call,
    enginepb.UpdateInstanceRequest request,
  ) async => _unused('updateInstance');

  @override
  Future<enginepb.EnsureInstanceReadyResponse> ensureInstanceReady(
    ServiceCall call,
    enginepb.EnsureInstanceReadyRequest request,
  ) async => _unused('ensureInstanceReady');

  @override
  Future<enginepb.DeleteInstanceResponse> deleteInstance(
    ServiceCall call,
    enginepb.DeleteInstanceRequest request,
  ) async => _unused('deleteInstance');

  @override
  Future<enginepb.GetOperationResponse> getOperation(
    ServiceCall call,
    enginepb.GetOperationRequest request,
  ) async => _unused('getOperation');

  @override
  Future<enginepb.CancelOperationResponse> cancelOperation(
    ServiceCall call,
    enginepb.CancelOperationRequest request,
  ) async => _unused('cancelOperation');

  @override
  Stream<enginepb.StreamEventsResponse> streamEvents(
    ServiceCall call,
    enginepb.StreamEventsRequest request,
  ) => _unused('streamEvents');

  @override
  Future<enginepb.ListRuntimesResponse> listRuntimes(
    ServiceCall call,
    enginepb.ListRuntimesRequest request,
  ) async => _unused('listRuntimes');

  @override
  Future<enginepb.InstallRuntimeResponse> installRuntime(
    ServiceCall call,
    enginepb.InstallRuntimeRequest request,
  ) async => _unused('installRuntime');

  @override
  Future<enginepb.ListKeysResponse> listKeys(
    ServiceCall call,
    enginepb.ListKeysRequest request,
  ) async => _unused('listKeys');

  @override
  Future<enginepb.CreateKeyResponse> createKey(
    ServiceCall call,
    enginepb.CreateKeyRequest request,
  ) async => _unused('createKey');

  @override
  Future<enginepb.RotateKeyResponse> rotateKey(
    ServiceCall call,
    enginepb.RotateKeyRequest request,
  ) async => _unused('rotateKey');

  @override
  Future<enginepb.RevokeKeyResponse> revokeKey(
    ServiceCall call,
    enginepb.RevokeKeyRequest request,
  ) async => _unused('revokeKey');

  @override
  Future<enginepb.GetInstanceLogsResponse> getInstanceLogs(
    ServiceCall call,
    enginepb.GetInstanceLogsRequest request,
  ) async => _unused('getInstanceLogs');

  @override
  Future<enginepb.ListQuantizationTypesResponse> listQuantizationTypes(
    ServiceCall call,
    enginepb.ListQuantizationTypesRequest request,
  ) async => _unused('listQuantizationTypes');

  @override
  Future<enginepb.PreflightQuantizationResponse> preflightQuantization(
    ServiceCall call,
    enginepb.PreflightQuantizationRequest request,
  ) async => _unused('preflightQuantization');

  @override
  Future<enginepb.StartQuantizationResponse> startQuantization(
    ServiceCall call,
    enginepb.StartQuantizationRequest request,
  ) async => _unused('startQuantization');

  @override
  Future<enginepb.ListPresetsResponse> listPresets(
    ServiceCall call,
    enginepb.ListPresetsRequest request,
  ) async => _unused('listPresets');

  @override
  Future<enginepb.SavePresetResponse> savePreset(
    ServiceCall call,
    enginepb.SavePresetRequest request,
  ) async => _unused('savePreset');

  @override
  Future<enginepb.DeletePresetResponse> deletePreset(
    ServiceCall call,
    enginepb.DeletePresetRequest request,
  ) async => _unused('deletePreset');

  @override
  Future<enginepb.ExportPresetsResponse> exportPresets(
    ServiceCall call,
    enginepb.ExportPresetsRequest request,
  ) async => _unused('exportPresets');

  @override
  Future<enginepb.ImportPresetsResponse> importPresets(
    ServiceCall call,
    enginepb.ImportPresetsRequest request,
  ) async => _unused('importPresets');
}
