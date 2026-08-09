// This is a generated file - do not edit.
//
// Generated from culpeostudio/engine/v1/engine.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'engine.pb.dart' as $0;

export 'engine.pb.dart';

/// EngineService runs models on this machine: the on-disk catalog, the instances
/// started from it, the runtimes those need, and the keys the local gateway
/// accepts.
///
/// The gateway itself stays on HTTP. It speaks the OpenAI API so that an
/// unmodified SDK can point at it, and an SDK that already speaks HTTP gains
/// nothing from a second dialect - it would only lose the ability to connect.
/// Everything the Studio client calls lives here.
@$pb.GrpcServiceName('culpeostudio.engine.v1.EngineService')
class EngineServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EngineServiceClient(super.channel, {super.options, super.interceptors});

  /// The model catalog on disk.
  $grpc.ResponseFuture<$0.ListModelsResponse> listModels(
    $0.ListModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.RescanModelsResponse> rescanModels(
    $0.RescanModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rescanModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteModelResponse> deleteModel(
    $0.DeleteModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteModel, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetCapabilitiesResponse> getCapabilities(
    $0.GetCapabilitiesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCapabilities, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetRecommendationResponse> getRecommendation(
    $0.GetRecommendationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getRecommendation, request, options: options);
  }

  $grpc.ResponseFuture<$0.SimulateParallelLoadResponse> simulateParallelLoad(
    $0.SimulateParallelLoadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$simulateParallelLoad, request, options: options);
  }

  /// The instances started from it.
  $grpc.ResponseFuture<$0.ListInstancesResponse> listInstances(
    $0.ListInstancesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listInstances, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreateInstanceResponse> createInstance(
    $0.CreateInstanceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createInstance, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetInstanceResponse> getInstance(
    $0.GetInstanceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getInstance, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetInstanceMetricsResponse> getInstanceMetrics(
    $0.GetInstanceMetricsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getInstanceMetrics, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateInstanceResponse> updateInstance(
    $0.UpdateInstanceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateInstance, request, options: options);
  }

  $grpc.ResponseFuture<$0.EnsureInstanceReadyResponse> ensureInstanceReady(
    $0.EnsureInstanceReadyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$ensureInstanceReady, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteInstanceResponse> deleteInstance(
    $0.DeleteInstanceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteInstance, request, options: options);
  }

  /// What the worker process itself printed. The summary on a failed instance
  /// is a diagnosis; this is the evidence behind it.
  $grpc.ResponseFuture<$0.GetInstanceLogsResponse> getInstanceLogs(
    $0.GetInstanceLogsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getInstanceLogs, request, options: options);
  }

  /// The long-running work they schedule, and the feed that reports on it.
  $grpc.ResponseFuture<$0.GetOperationResponse> getOperation(
    $0.GetOperationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getOperation, request, options: options);
  }

  $grpc.ResponseFuture<$0.CancelOperationResponse> cancelOperation(
    $0.CancelOperationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelOperation, request, options: options);
  }

  $grpc.ResponseStream<$0.StreamEventsResponse> streamEvents(
    $0.StreamEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamEvents, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Re-quantising a local GGUF into a smaller one. The tool for this ships
  /// inside the llama.cpp archive the runtime installer already unpacks, so
  /// nothing further is downloaded to make it work.
  $grpc.ResponseFuture<$0.ListQuantizationTypesResponse> listQuantizationTypes(
    $0.ListQuantizationTypesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listQuantizationTypes, request, options: options);
  }

  $grpc.ResponseFuture<$0.PreflightQuantizationResponse> preflightQuantization(
    $0.PreflightQuantizationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$preflightQuantization, request, options: options);
  }

  $grpc.ResponseFuture<$0.StartQuantizationResponse> startQuantization(
    $0.StartQuantizationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startQuantization, request, options: options);
  }

  /// Saved configurations. A preset is an EngineConfig under a name, so it
  /// applies to any model rather than being bound to the one it came from.
  $grpc.ResponseFuture<$0.ListPresetsResponse> listPresets(
    $0.ListPresetsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listPresets, request, options: options);
  }

  $grpc.ResponseFuture<$0.SavePresetResponse> savePreset(
    $0.SavePresetRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$savePreset, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeletePresetResponse> deletePreset(
    $0.DeletePresetRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deletePreset, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExportPresetsResponse> exportPresets(
    $0.ExportPresetsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exportPresets, request, options: options);
  }

  $grpc.ResponseFuture<$0.ImportPresetsResponse> importPresets(
    $0.ImportPresetsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$importPresets, request, options: options);
  }

  /// The runtimes and the system packages they build against.
  $grpc.ResponseFuture<$0.ListRuntimesResponse> listRuntimes(
    $0.ListRuntimesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listRuntimes, request, options: options);
  }

  $grpc.ResponseFuture<$0.InstallRuntimeResponse> installRuntime(
    $0.InstallRuntimeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$installRuntime, request, options: options);
  }

  /// The keys the local gateway accepts.
  $grpc.ResponseFuture<$0.ListKeysResponse> listKeys(
    $0.ListKeysRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listKeys, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreateKeyResponse> createKey(
    $0.CreateKeyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createKey, request, options: options);
  }

  $grpc.ResponseFuture<$0.RotateKeyResponse> rotateKey(
    $0.RotateKeyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rotateKey, request, options: options);
  }

  $grpc.ResponseFuture<$0.RevokeKeyResponse> revokeKey(
    $0.RevokeKeyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$revokeKey, request, options: options);
  }

  // method descriptors

  static final _$listModels =
      $grpc.ClientMethod<$0.ListModelsRequest, $0.ListModelsResponse>(
          '/culpeostudio.engine.v1.EngineService/ListModels',
          ($0.ListModelsRequest value) => value.writeToBuffer(),
          $0.ListModelsResponse.fromBuffer);
  static final _$rescanModels =
      $grpc.ClientMethod<$0.RescanModelsRequest, $0.RescanModelsResponse>(
          '/culpeostudio.engine.v1.EngineService/RescanModels',
          ($0.RescanModelsRequest value) => value.writeToBuffer(),
          $0.RescanModelsResponse.fromBuffer);
  static final _$deleteModel =
      $grpc.ClientMethod<$0.DeleteModelRequest, $0.DeleteModelResponse>(
          '/culpeostudio.engine.v1.EngineService/DeleteModel',
          ($0.DeleteModelRequest value) => value.writeToBuffer(),
          $0.DeleteModelResponse.fromBuffer);
  static final _$getCapabilities =
      $grpc.ClientMethod<$0.GetCapabilitiesRequest, $0.GetCapabilitiesResponse>(
          '/culpeostudio.engine.v1.EngineService/GetCapabilities',
          ($0.GetCapabilitiesRequest value) => value.writeToBuffer(),
          $0.GetCapabilitiesResponse.fromBuffer);
  static final _$getRecommendation = $grpc.ClientMethod<
          $0.GetRecommendationRequest, $0.GetRecommendationResponse>(
      '/culpeostudio.engine.v1.EngineService/GetRecommendation',
      ($0.GetRecommendationRequest value) => value.writeToBuffer(),
      $0.GetRecommendationResponse.fromBuffer);
  static final _$simulateParallelLoad = $grpc.ClientMethod<
          $0.SimulateParallelLoadRequest, $0.SimulateParallelLoadResponse>(
      '/culpeostudio.engine.v1.EngineService/SimulateParallelLoad',
      ($0.SimulateParallelLoadRequest value) => value.writeToBuffer(),
      $0.SimulateParallelLoadResponse.fromBuffer);
  static final _$listInstances =
      $grpc.ClientMethod<$0.ListInstancesRequest, $0.ListInstancesResponse>(
          '/culpeostudio.engine.v1.EngineService/ListInstances',
          ($0.ListInstancesRequest value) => value.writeToBuffer(),
          $0.ListInstancesResponse.fromBuffer);
  static final _$createInstance =
      $grpc.ClientMethod<$0.CreateInstanceRequest, $0.CreateInstanceResponse>(
          '/culpeostudio.engine.v1.EngineService/CreateInstance',
          ($0.CreateInstanceRequest value) => value.writeToBuffer(),
          $0.CreateInstanceResponse.fromBuffer);
  static final _$getInstance =
      $grpc.ClientMethod<$0.GetInstanceRequest, $0.GetInstanceResponse>(
          '/culpeostudio.engine.v1.EngineService/GetInstance',
          ($0.GetInstanceRequest value) => value.writeToBuffer(),
          $0.GetInstanceResponse.fromBuffer);
  static final _$getInstanceMetrics = $grpc.ClientMethod<
          $0.GetInstanceMetricsRequest, $0.GetInstanceMetricsResponse>(
      '/culpeostudio.engine.v1.EngineService/GetInstanceMetrics',
      ($0.GetInstanceMetricsRequest value) => value.writeToBuffer(),
      $0.GetInstanceMetricsResponse.fromBuffer);
  static final _$updateInstance =
      $grpc.ClientMethod<$0.UpdateInstanceRequest, $0.UpdateInstanceResponse>(
          '/culpeostudio.engine.v1.EngineService/UpdateInstance',
          ($0.UpdateInstanceRequest value) => value.writeToBuffer(),
          $0.UpdateInstanceResponse.fromBuffer);
  static final _$ensureInstanceReady = $grpc.ClientMethod<
          $0.EnsureInstanceReadyRequest, $0.EnsureInstanceReadyResponse>(
      '/culpeostudio.engine.v1.EngineService/EnsureInstanceReady',
      ($0.EnsureInstanceReadyRequest value) => value.writeToBuffer(),
      $0.EnsureInstanceReadyResponse.fromBuffer);
  static final _$deleteInstance =
      $grpc.ClientMethod<$0.DeleteInstanceRequest, $0.DeleteInstanceResponse>(
          '/culpeostudio.engine.v1.EngineService/DeleteInstance',
          ($0.DeleteInstanceRequest value) => value.writeToBuffer(),
          $0.DeleteInstanceResponse.fromBuffer);
  static final _$getInstanceLogs =
      $grpc.ClientMethod<$0.GetInstanceLogsRequest, $0.GetInstanceLogsResponse>(
          '/culpeostudio.engine.v1.EngineService/GetInstanceLogs',
          ($0.GetInstanceLogsRequest value) => value.writeToBuffer(),
          $0.GetInstanceLogsResponse.fromBuffer);
  static final _$getOperation =
      $grpc.ClientMethod<$0.GetOperationRequest, $0.GetOperationResponse>(
          '/culpeostudio.engine.v1.EngineService/GetOperation',
          ($0.GetOperationRequest value) => value.writeToBuffer(),
          $0.GetOperationResponse.fromBuffer);
  static final _$cancelOperation =
      $grpc.ClientMethod<$0.CancelOperationRequest, $0.CancelOperationResponse>(
          '/culpeostudio.engine.v1.EngineService/CancelOperation',
          ($0.CancelOperationRequest value) => value.writeToBuffer(),
          $0.CancelOperationResponse.fromBuffer);
  static final _$streamEvents =
      $grpc.ClientMethod<$0.StreamEventsRequest, $0.StreamEventsResponse>(
          '/culpeostudio.engine.v1.EngineService/StreamEvents',
          ($0.StreamEventsRequest value) => value.writeToBuffer(),
          $0.StreamEventsResponse.fromBuffer);
  static final _$listQuantizationTypes = $grpc.ClientMethod<
          $0.ListQuantizationTypesRequest, $0.ListQuantizationTypesResponse>(
      '/culpeostudio.engine.v1.EngineService/ListQuantizationTypes',
      ($0.ListQuantizationTypesRequest value) => value.writeToBuffer(),
      $0.ListQuantizationTypesResponse.fromBuffer);
  static final _$preflightQuantization = $grpc.ClientMethod<
          $0.PreflightQuantizationRequest, $0.PreflightQuantizationResponse>(
      '/culpeostudio.engine.v1.EngineService/PreflightQuantization',
      ($0.PreflightQuantizationRequest value) => value.writeToBuffer(),
      $0.PreflightQuantizationResponse.fromBuffer);
  static final _$startQuantization = $grpc.ClientMethod<
          $0.StartQuantizationRequest, $0.StartQuantizationResponse>(
      '/culpeostudio.engine.v1.EngineService/StartQuantization',
      ($0.StartQuantizationRequest value) => value.writeToBuffer(),
      $0.StartQuantizationResponse.fromBuffer);
  static final _$listPresets =
      $grpc.ClientMethod<$0.ListPresetsRequest, $0.ListPresetsResponse>(
          '/culpeostudio.engine.v1.EngineService/ListPresets',
          ($0.ListPresetsRequest value) => value.writeToBuffer(),
          $0.ListPresetsResponse.fromBuffer);
  static final _$savePreset =
      $grpc.ClientMethod<$0.SavePresetRequest, $0.SavePresetResponse>(
          '/culpeostudio.engine.v1.EngineService/SavePreset',
          ($0.SavePresetRequest value) => value.writeToBuffer(),
          $0.SavePresetResponse.fromBuffer);
  static final _$deletePreset =
      $grpc.ClientMethod<$0.DeletePresetRequest, $0.DeletePresetResponse>(
          '/culpeostudio.engine.v1.EngineService/DeletePreset',
          ($0.DeletePresetRequest value) => value.writeToBuffer(),
          $0.DeletePresetResponse.fromBuffer);
  static final _$exportPresets =
      $grpc.ClientMethod<$0.ExportPresetsRequest, $0.ExportPresetsResponse>(
          '/culpeostudio.engine.v1.EngineService/ExportPresets',
          ($0.ExportPresetsRequest value) => value.writeToBuffer(),
          $0.ExportPresetsResponse.fromBuffer);
  static final _$importPresets =
      $grpc.ClientMethod<$0.ImportPresetsRequest, $0.ImportPresetsResponse>(
          '/culpeostudio.engine.v1.EngineService/ImportPresets',
          ($0.ImportPresetsRequest value) => value.writeToBuffer(),
          $0.ImportPresetsResponse.fromBuffer);
  static final _$listRuntimes =
      $grpc.ClientMethod<$0.ListRuntimesRequest, $0.ListRuntimesResponse>(
          '/culpeostudio.engine.v1.EngineService/ListRuntimes',
          ($0.ListRuntimesRequest value) => value.writeToBuffer(),
          $0.ListRuntimesResponse.fromBuffer);
  static final _$installRuntime =
      $grpc.ClientMethod<$0.InstallRuntimeRequest, $0.InstallRuntimeResponse>(
          '/culpeostudio.engine.v1.EngineService/InstallRuntime',
          ($0.InstallRuntimeRequest value) => value.writeToBuffer(),
          $0.InstallRuntimeResponse.fromBuffer);
  static final _$listKeys =
      $grpc.ClientMethod<$0.ListKeysRequest, $0.ListKeysResponse>(
          '/culpeostudio.engine.v1.EngineService/ListKeys',
          ($0.ListKeysRequest value) => value.writeToBuffer(),
          $0.ListKeysResponse.fromBuffer);
  static final _$createKey =
      $grpc.ClientMethod<$0.CreateKeyRequest, $0.CreateKeyResponse>(
          '/culpeostudio.engine.v1.EngineService/CreateKey',
          ($0.CreateKeyRequest value) => value.writeToBuffer(),
          $0.CreateKeyResponse.fromBuffer);
  static final _$rotateKey =
      $grpc.ClientMethod<$0.RotateKeyRequest, $0.RotateKeyResponse>(
          '/culpeostudio.engine.v1.EngineService/RotateKey',
          ($0.RotateKeyRequest value) => value.writeToBuffer(),
          $0.RotateKeyResponse.fromBuffer);
  static final _$revokeKey =
      $grpc.ClientMethod<$0.RevokeKeyRequest, $0.RevokeKeyResponse>(
          '/culpeostudio.engine.v1.EngineService/RevokeKey',
          ($0.RevokeKeyRequest value) => value.writeToBuffer(),
          $0.RevokeKeyResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.engine.v1.EngineService')
abstract class EngineServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.engine.v1.EngineService';

  EngineServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListModelsRequest, $0.ListModelsResponse>(
        'ListModels',
        listModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListModelsRequest.fromBuffer(value),
        ($0.ListModelsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RescanModelsRequest, $0.RescanModelsResponse>(
            'RescanModels',
            rescanModels_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RescanModelsRequest.fromBuffer(value),
            ($0.RescanModelsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteModelRequest, $0.DeleteModelResponse>(
            'DeleteModel',
            deleteModel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteModelRequest.fromBuffer(value),
            ($0.DeleteModelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetCapabilitiesRequest,
            $0.GetCapabilitiesResponse>(
        'GetCapabilities',
        getCapabilities_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetCapabilitiesRequest.fromBuffer(value),
        ($0.GetCapabilitiesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetRecommendationRequest,
            $0.GetRecommendationResponse>(
        'GetRecommendation',
        getRecommendation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetRecommendationRequest.fromBuffer(value),
        ($0.GetRecommendationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SimulateParallelLoadRequest,
            $0.SimulateParallelLoadResponse>(
        'SimulateParallelLoad',
        simulateParallelLoad_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SimulateParallelLoadRequest.fromBuffer(value),
        ($0.SimulateParallelLoadResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListInstancesRequest, $0.ListInstancesResponse>(
            'ListInstances',
            listInstances_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListInstancesRequest.fromBuffer(value),
            ($0.ListInstancesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateInstanceRequest,
            $0.CreateInstanceResponse>(
        'CreateInstance',
        createInstance_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateInstanceRequest.fromBuffer(value),
        ($0.CreateInstanceResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetInstanceRequest, $0.GetInstanceResponse>(
            'GetInstance',
            getInstance_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetInstanceRequest.fromBuffer(value),
            ($0.GetInstanceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetInstanceMetricsRequest,
            $0.GetInstanceMetricsResponse>(
        'GetInstanceMetrics',
        getInstanceMetrics_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetInstanceMetricsRequest.fromBuffer(value),
        ($0.GetInstanceMetricsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateInstanceRequest,
            $0.UpdateInstanceResponse>(
        'UpdateInstance',
        updateInstance_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateInstanceRequest.fromBuffer(value),
        ($0.UpdateInstanceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EnsureInstanceReadyRequest,
            $0.EnsureInstanceReadyResponse>(
        'EnsureInstanceReady',
        ensureInstanceReady_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.EnsureInstanceReadyRequest.fromBuffer(value),
        ($0.EnsureInstanceReadyResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteInstanceRequest,
            $0.DeleteInstanceResponse>(
        'DeleteInstance',
        deleteInstance_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteInstanceRequest.fromBuffer(value),
        ($0.DeleteInstanceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetInstanceLogsRequest,
            $0.GetInstanceLogsResponse>(
        'GetInstanceLogs',
        getInstanceLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetInstanceLogsRequest.fromBuffer(value),
        ($0.GetInstanceLogsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetOperationRequest, $0.GetOperationResponse>(
            'GetOperation',
            getOperation_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetOperationRequest.fromBuffer(value),
            ($0.GetOperationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CancelOperationRequest,
            $0.CancelOperationResponse>(
        'CancelOperation',
        cancelOperation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CancelOperationRequest.fromBuffer(value),
        ($0.CancelOperationResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StreamEventsRequest, $0.StreamEventsResponse>(
            'StreamEvents',
            streamEvents_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.StreamEventsRequest.fromBuffer(value),
            ($0.StreamEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListQuantizationTypesRequest,
            $0.ListQuantizationTypesResponse>(
        'ListQuantizationTypes',
        listQuantizationTypes_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListQuantizationTypesRequest.fromBuffer(value),
        ($0.ListQuantizationTypesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PreflightQuantizationRequest,
            $0.PreflightQuantizationResponse>(
        'PreflightQuantization',
        preflightQuantization_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PreflightQuantizationRequest.fromBuffer(value),
        ($0.PreflightQuantizationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartQuantizationRequest,
            $0.StartQuantizationResponse>(
        'StartQuantization',
        startQuantization_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StartQuantizationRequest.fromBuffer(value),
        ($0.StartQuantizationResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListPresetsRequest, $0.ListPresetsResponse>(
            'ListPresets',
            listPresets_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListPresetsRequest.fromBuffer(value),
            ($0.ListPresetsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SavePresetRequest, $0.SavePresetResponse>(
        'SavePreset',
        savePreset_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SavePresetRequest.fromBuffer(value),
        ($0.SavePresetResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeletePresetRequest, $0.DeletePresetResponse>(
            'DeletePreset',
            deletePreset_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeletePresetRequest.fromBuffer(value),
            ($0.DeletePresetResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ExportPresetsRequest, $0.ExportPresetsResponse>(
            'ExportPresets',
            exportPresets_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ExportPresetsRequest.fromBuffer(value),
            ($0.ExportPresetsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ImportPresetsRequest, $0.ImportPresetsResponse>(
            'ImportPresets',
            importPresets_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ImportPresetsRequest.fromBuffer(value),
            ($0.ImportPresetsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListRuntimesRequest, $0.ListRuntimesResponse>(
            'ListRuntimes',
            listRuntimes_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListRuntimesRequest.fromBuffer(value),
            ($0.ListRuntimesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InstallRuntimeRequest,
            $0.InstallRuntimeResponse>(
        'InstallRuntime',
        installRuntime_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InstallRuntimeRequest.fromBuffer(value),
        ($0.InstallRuntimeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListKeysRequest, $0.ListKeysResponse>(
        'ListKeys',
        listKeys_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListKeysRequest.fromBuffer(value),
        ($0.ListKeysResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateKeyRequest, $0.CreateKeyResponse>(
        'CreateKey',
        createKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateKeyRequest.fromBuffer(value),
        ($0.CreateKeyResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RotateKeyRequest, $0.RotateKeyResponse>(
        'RotateKey',
        rotateKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RotateKeyRequest.fromBuffer(value),
        ($0.RotateKeyResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RevokeKeyRequest, $0.RevokeKeyResponse>(
        'RevokeKey',
        revokeKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RevokeKeyRequest.fromBuffer(value),
        ($0.RevokeKeyResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListModelsResponse> listModels_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListModelsRequest> $request) async {
    return listModels($call, await $request);
  }

  $async.Future<$0.ListModelsResponse> listModels(
      $grpc.ServiceCall call, $0.ListModelsRequest request);

  $async.Future<$0.RescanModelsResponse> rescanModels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RescanModelsRequest> $request) async {
    return rescanModels($call, await $request);
  }

  $async.Future<$0.RescanModelsResponse> rescanModels(
      $grpc.ServiceCall call, $0.RescanModelsRequest request);

  $async.Future<$0.DeleteModelResponse> deleteModel_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteModelRequest> $request) async {
    return deleteModel($call, await $request);
  }

  $async.Future<$0.DeleteModelResponse> deleteModel(
      $grpc.ServiceCall call, $0.DeleteModelRequest request);

  $async.Future<$0.GetCapabilitiesResponse> getCapabilities_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetCapabilitiesRequest> $request) async {
    return getCapabilities($call, await $request);
  }

  $async.Future<$0.GetCapabilitiesResponse> getCapabilities(
      $grpc.ServiceCall call, $0.GetCapabilitiesRequest request);

  $async.Future<$0.GetRecommendationResponse> getRecommendation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetRecommendationRequest> $request) async {
    return getRecommendation($call, await $request);
  }

  $async.Future<$0.GetRecommendationResponse> getRecommendation(
      $grpc.ServiceCall call, $0.GetRecommendationRequest request);

  $async.Future<$0.SimulateParallelLoadResponse> simulateParallelLoad_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SimulateParallelLoadRequest> $request) async {
    return simulateParallelLoad($call, await $request);
  }

  $async.Future<$0.SimulateParallelLoadResponse> simulateParallelLoad(
      $grpc.ServiceCall call, $0.SimulateParallelLoadRequest request);

  $async.Future<$0.ListInstancesResponse> listInstances_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListInstancesRequest> $request) async {
    return listInstances($call, await $request);
  }

  $async.Future<$0.ListInstancesResponse> listInstances(
      $grpc.ServiceCall call, $0.ListInstancesRequest request);

  $async.Future<$0.CreateInstanceResponse> createInstance_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateInstanceRequest> $request) async {
    return createInstance($call, await $request);
  }

  $async.Future<$0.CreateInstanceResponse> createInstance(
      $grpc.ServiceCall call, $0.CreateInstanceRequest request);

  $async.Future<$0.GetInstanceResponse> getInstance_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetInstanceRequest> $request) async {
    return getInstance($call, await $request);
  }

  $async.Future<$0.GetInstanceResponse> getInstance(
      $grpc.ServiceCall call, $0.GetInstanceRequest request);

  $async.Future<$0.GetInstanceMetricsResponse> getInstanceMetrics_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetInstanceMetricsRequest> $request) async {
    return getInstanceMetrics($call, await $request);
  }

  $async.Future<$0.GetInstanceMetricsResponse> getInstanceMetrics(
      $grpc.ServiceCall call, $0.GetInstanceMetricsRequest request);

  $async.Future<$0.UpdateInstanceResponse> updateInstance_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateInstanceRequest> $request) async {
    return updateInstance($call, await $request);
  }

  $async.Future<$0.UpdateInstanceResponse> updateInstance(
      $grpc.ServiceCall call, $0.UpdateInstanceRequest request);

  $async.Future<$0.EnsureInstanceReadyResponse> ensureInstanceReady_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.EnsureInstanceReadyRequest> $request) async {
    return ensureInstanceReady($call, await $request);
  }

  $async.Future<$0.EnsureInstanceReadyResponse> ensureInstanceReady(
      $grpc.ServiceCall call, $0.EnsureInstanceReadyRequest request);

  $async.Future<$0.DeleteInstanceResponse> deleteInstance_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteInstanceRequest> $request) async {
    return deleteInstance($call, await $request);
  }

  $async.Future<$0.DeleteInstanceResponse> deleteInstance(
      $grpc.ServiceCall call, $0.DeleteInstanceRequest request);

  $async.Future<$0.GetInstanceLogsResponse> getInstanceLogs_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetInstanceLogsRequest> $request) async {
    return getInstanceLogs($call, await $request);
  }

  $async.Future<$0.GetInstanceLogsResponse> getInstanceLogs(
      $grpc.ServiceCall call, $0.GetInstanceLogsRequest request);

  $async.Future<$0.GetOperationResponse> getOperation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetOperationRequest> $request) async {
    return getOperation($call, await $request);
  }

  $async.Future<$0.GetOperationResponse> getOperation(
      $grpc.ServiceCall call, $0.GetOperationRequest request);

  $async.Future<$0.CancelOperationResponse> cancelOperation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CancelOperationRequest> $request) async {
    return cancelOperation($call, await $request);
  }

  $async.Future<$0.CancelOperationResponse> cancelOperation(
      $grpc.ServiceCall call, $0.CancelOperationRequest request);

  $async.Stream<$0.StreamEventsResponse> streamEvents_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StreamEventsRequest> $request) async* {
    yield* streamEvents($call, await $request);
  }

  $async.Stream<$0.StreamEventsResponse> streamEvents(
      $grpc.ServiceCall call, $0.StreamEventsRequest request);

  $async.Future<$0.ListQuantizationTypesResponse> listQuantizationTypes_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListQuantizationTypesRequest> $request) async {
    return listQuantizationTypes($call, await $request);
  }

  $async.Future<$0.ListQuantizationTypesResponse> listQuantizationTypes(
      $grpc.ServiceCall call, $0.ListQuantizationTypesRequest request);

  $async.Future<$0.PreflightQuantizationResponse> preflightQuantization_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PreflightQuantizationRequest> $request) async {
    return preflightQuantization($call, await $request);
  }

  $async.Future<$0.PreflightQuantizationResponse> preflightQuantization(
      $grpc.ServiceCall call, $0.PreflightQuantizationRequest request);

  $async.Future<$0.StartQuantizationResponse> startQuantization_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartQuantizationRequest> $request) async {
    return startQuantization($call, await $request);
  }

  $async.Future<$0.StartQuantizationResponse> startQuantization(
      $grpc.ServiceCall call, $0.StartQuantizationRequest request);

  $async.Future<$0.ListPresetsResponse> listPresets_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListPresetsRequest> $request) async {
    return listPresets($call, await $request);
  }

  $async.Future<$0.ListPresetsResponse> listPresets(
      $grpc.ServiceCall call, $0.ListPresetsRequest request);

  $async.Future<$0.SavePresetResponse> savePreset_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SavePresetRequest> $request) async {
    return savePreset($call, await $request);
  }

  $async.Future<$0.SavePresetResponse> savePreset(
      $grpc.ServiceCall call, $0.SavePresetRequest request);

  $async.Future<$0.DeletePresetResponse> deletePreset_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeletePresetRequest> $request) async {
    return deletePreset($call, await $request);
  }

  $async.Future<$0.DeletePresetResponse> deletePreset(
      $grpc.ServiceCall call, $0.DeletePresetRequest request);

  $async.Future<$0.ExportPresetsResponse> exportPresets_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExportPresetsRequest> $request) async {
    return exportPresets($call, await $request);
  }

  $async.Future<$0.ExportPresetsResponse> exportPresets(
      $grpc.ServiceCall call, $0.ExportPresetsRequest request);

  $async.Future<$0.ImportPresetsResponse> importPresets_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ImportPresetsRequest> $request) async {
    return importPresets($call, await $request);
  }

  $async.Future<$0.ImportPresetsResponse> importPresets(
      $grpc.ServiceCall call, $0.ImportPresetsRequest request);

  $async.Future<$0.ListRuntimesResponse> listRuntimes_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListRuntimesRequest> $request) async {
    return listRuntimes($call, await $request);
  }

  $async.Future<$0.ListRuntimesResponse> listRuntimes(
      $grpc.ServiceCall call, $0.ListRuntimesRequest request);

  $async.Future<$0.InstallRuntimeResponse> installRuntime_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InstallRuntimeRequest> $request) async {
    return installRuntime($call, await $request);
  }

  $async.Future<$0.InstallRuntimeResponse> installRuntime(
      $grpc.ServiceCall call, $0.InstallRuntimeRequest request);

  $async.Future<$0.ListKeysResponse> listKeys_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListKeysRequest> $request) async {
    return listKeys($call, await $request);
  }

  $async.Future<$0.ListKeysResponse> listKeys(
      $grpc.ServiceCall call, $0.ListKeysRequest request);

  $async.Future<$0.CreateKeyResponse> createKey_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateKeyRequest> $request) async {
    return createKey($call, await $request);
  }

  $async.Future<$0.CreateKeyResponse> createKey(
      $grpc.ServiceCall call, $0.CreateKeyRequest request);

  $async.Future<$0.RotateKeyResponse> rotateKey_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RotateKeyRequest> $request) async {
    return rotateKey($call, await $request);
  }

  $async.Future<$0.RotateKeyResponse> rotateKey(
      $grpc.ServiceCall call, $0.RotateKeyRequest request);

  $async.Future<$0.RevokeKeyResponse> revokeKey_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RevokeKeyRequest> $request) async {
    return revokeKey($call, await $request);
  }

  $async.Future<$0.RevokeKeyResponse> revokeKey(
      $grpc.ServiceCall call, $0.RevokeKeyRequest request);
}
