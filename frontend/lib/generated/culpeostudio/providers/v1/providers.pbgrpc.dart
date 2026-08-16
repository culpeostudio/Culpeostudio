// This is a generated file - do not edit.
//
// Generated from culpeostudio/providers/v1/providers.proto.

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

import 'providers.pb.dart' as $0;

export 'providers.pb.dart';

/// ProviderService owns externally hosted AI connections.  It deliberately
/// keeps API keys on the backend: clients can see only whether a key exists.
/// A connection is user-scoped, so one signed-in account can never list or use
/// another account's credentials or models.
@$pb.GrpcServiceName('culpeostudio.providers.v1.ProviderService')
class ProviderServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProviderServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListPresetsResponse> listPresets(
    $0.ListPresetsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listPresets, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListConnectionsResponse> listConnections(
    $0.ListConnectionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listConnections, request, options: options);
  }

  $grpc.ResponseFuture<$0.SaveConnectionResponse> saveConnection(
    $0.SaveConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveConnection, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteConnectionResponse> deleteConnection(
    $0.DeleteConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteConnection, request, options: options);
  }

  $grpc.ResponseFuture<$0.TestConnectionResponse> testConnection(
    $0.TestConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$testConnection, request, options: options);
  }

  $grpc.ResponseFuture<$0.SyncConnectionModelsResponse> syncConnectionModels(
    $0.SyncConnectionModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$syncConnectionModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListConnectionModelsResponse> listConnectionModels(
    $0.ListConnectionModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listConnectionModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.ActivateModelResponse> activateModel(
    $0.ActivateModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$activateModel, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListActiveModelsResponse> listActiveModels(
    $0.ListActiveModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listActiveModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteActiveModelResponse> deleteActiveModel(
    $0.DeleteActiveModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteActiveModel, request, options: options);
  }

  // method descriptors

  static final _$listPresets =
      $grpc.ClientMethod<$0.ListPresetsRequest, $0.ListPresetsResponse>(
          '/culpeostudio.providers.v1.ProviderService/ListPresets',
          ($0.ListPresetsRequest value) => value.writeToBuffer(),
          $0.ListPresetsResponse.fromBuffer);
  static final _$listConnections =
      $grpc.ClientMethod<$0.ListConnectionsRequest, $0.ListConnectionsResponse>(
          '/culpeostudio.providers.v1.ProviderService/ListConnections',
          ($0.ListConnectionsRequest value) => value.writeToBuffer(),
          $0.ListConnectionsResponse.fromBuffer);
  static final _$saveConnection =
      $grpc.ClientMethod<$0.SaveConnectionRequest, $0.SaveConnectionResponse>(
          '/culpeostudio.providers.v1.ProviderService/SaveConnection',
          ($0.SaveConnectionRequest value) => value.writeToBuffer(),
          $0.SaveConnectionResponse.fromBuffer);
  static final _$deleteConnection = $grpc.ClientMethod<
          $0.DeleteConnectionRequest, $0.DeleteConnectionResponse>(
      '/culpeostudio.providers.v1.ProviderService/DeleteConnection',
      ($0.DeleteConnectionRequest value) => value.writeToBuffer(),
      $0.DeleteConnectionResponse.fromBuffer);
  static final _$testConnection =
      $grpc.ClientMethod<$0.TestConnectionRequest, $0.TestConnectionResponse>(
          '/culpeostudio.providers.v1.ProviderService/TestConnection',
          ($0.TestConnectionRequest value) => value.writeToBuffer(),
          $0.TestConnectionResponse.fromBuffer);
  static final _$syncConnectionModels = $grpc.ClientMethod<
          $0.SyncConnectionModelsRequest, $0.SyncConnectionModelsResponse>(
      '/culpeostudio.providers.v1.ProviderService/SyncConnectionModels',
      ($0.SyncConnectionModelsRequest value) => value.writeToBuffer(),
      $0.SyncConnectionModelsResponse.fromBuffer);
  static final _$listConnectionModels = $grpc.ClientMethod<
          $0.ListConnectionModelsRequest, $0.ListConnectionModelsResponse>(
      '/culpeostudio.providers.v1.ProviderService/ListConnectionModels',
      ($0.ListConnectionModelsRequest value) => value.writeToBuffer(),
      $0.ListConnectionModelsResponse.fromBuffer);
  static final _$activateModel =
      $grpc.ClientMethod<$0.ActivateModelRequest, $0.ActivateModelResponse>(
          '/culpeostudio.providers.v1.ProviderService/ActivateModel',
          ($0.ActivateModelRequest value) => value.writeToBuffer(),
          $0.ActivateModelResponse.fromBuffer);
  static final _$listActiveModels = $grpc.ClientMethod<
          $0.ListActiveModelsRequest, $0.ListActiveModelsResponse>(
      '/culpeostudio.providers.v1.ProviderService/ListActiveModels',
      ($0.ListActiveModelsRequest value) => value.writeToBuffer(),
      $0.ListActiveModelsResponse.fromBuffer);
  static final _$deleteActiveModel = $grpc.ClientMethod<
          $0.DeleteActiveModelRequest, $0.DeleteActiveModelResponse>(
      '/culpeostudio.providers.v1.ProviderService/DeleteActiveModel',
      ($0.DeleteActiveModelRequest value) => value.writeToBuffer(),
      $0.DeleteActiveModelResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.providers.v1.ProviderService')
abstract class ProviderServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.providers.v1.ProviderService';

  ProviderServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListPresetsRequest, $0.ListPresetsResponse>(
            'ListPresets',
            listPresets_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListPresetsRequest.fromBuffer(value),
            ($0.ListPresetsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListConnectionsRequest,
            $0.ListConnectionsResponse>(
        'ListConnections',
        listConnections_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListConnectionsRequest.fromBuffer(value),
        ($0.ListConnectionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SaveConnectionRequest,
            $0.SaveConnectionResponse>(
        'SaveConnection',
        saveConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SaveConnectionRequest.fromBuffer(value),
        ($0.SaveConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteConnectionRequest,
            $0.DeleteConnectionResponse>(
        'DeleteConnection',
        deleteConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteConnectionRequest.fromBuffer(value),
        ($0.DeleteConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TestConnectionRequest,
            $0.TestConnectionResponse>(
        'TestConnection',
        testConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.TestConnectionRequest.fromBuffer(value),
        ($0.TestConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SyncConnectionModelsRequest,
            $0.SyncConnectionModelsResponse>(
        'SyncConnectionModels',
        syncConnectionModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SyncConnectionModelsRequest.fromBuffer(value),
        ($0.SyncConnectionModelsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListConnectionModelsRequest,
            $0.ListConnectionModelsResponse>(
        'ListConnectionModels',
        listConnectionModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListConnectionModelsRequest.fromBuffer(value),
        ($0.ListConnectionModelsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ActivateModelRequest, $0.ActivateModelResponse>(
            'ActivateModel',
            activateModel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ActivateModelRequest.fromBuffer(value),
            ($0.ActivateModelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListActiveModelsRequest,
            $0.ListActiveModelsResponse>(
        'ListActiveModels',
        listActiveModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListActiveModelsRequest.fromBuffer(value),
        ($0.ListActiveModelsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteActiveModelRequest,
            $0.DeleteActiveModelResponse>(
        'DeleteActiveModel',
        deleteActiveModel_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteActiveModelRequest.fromBuffer(value),
        ($0.DeleteActiveModelResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListPresetsResponse> listPresets_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListPresetsRequest> $request) async {
    return listPresets($call, await $request);
  }

  $async.Future<$0.ListPresetsResponse> listPresets(
      $grpc.ServiceCall call, $0.ListPresetsRequest request);

  $async.Future<$0.ListConnectionsResponse> listConnections_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListConnectionsRequest> $request) async {
    return listConnections($call, await $request);
  }

  $async.Future<$0.ListConnectionsResponse> listConnections(
      $grpc.ServiceCall call, $0.ListConnectionsRequest request);

  $async.Future<$0.SaveConnectionResponse> saveConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SaveConnectionRequest> $request) async {
    return saveConnection($call, await $request);
  }

  $async.Future<$0.SaveConnectionResponse> saveConnection(
      $grpc.ServiceCall call, $0.SaveConnectionRequest request);

  $async.Future<$0.DeleteConnectionResponse> deleteConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteConnectionRequest> $request) async {
    return deleteConnection($call, await $request);
  }

  $async.Future<$0.DeleteConnectionResponse> deleteConnection(
      $grpc.ServiceCall call, $0.DeleteConnectionRequest request);

  $async.Future<$0.TestConnectionResponse> testConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.TestConnectionRequest> $request) async {
    return testConnection($call, await $request);
  }

  $async.Future<$0.TestConnectionResponse> testConnection(
      $grpc.ServiceCall call, $0.TestConnectionRequest request);

  $async.Future<$0.SyncConnectionModelsResponse> syncConnectionModels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SyncConnectionModelsRequest> $request) async {
    return syncConnectionModels($call, await $request);
  }

  $async.Future<$0.SyncConnectionModelsResponse> syncConnectionModels(
      $grpc.ServiceCall call, $0.SyncConnectionModelsRequest request);

  $async.Future<$0.ListConnectionModelsResponse> listConnectionModels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListConnectionModelsRequest> $request) async {
    return listConnectionModels($call, await $request);
  }

  $async.Future<$0.ListConnectionModelsResponse> listConnectionModels(
      $grpc.ServiceCall call, $0.ListConnectionModelsRequest request);

  $async.Future<$0.ActivateModelResponse> activateModel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ActivateModelRequest> $request) async {
    return activateModel($call, await $request);
  }

  $async.Future<$0.ActivateModelResponse> activateModel(
      $grpc.ServiceCall call, $0.ActivateModelRequest request);

  $async.Future<$0.ListActiveModelsResponse> listActiveModels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListActiveModelsRequest> $request) async {
    return listActiveModels($call, await $request);
  }

  $async.Future<$0.ListActiveModelsResponse> listActiveModels(
      $grpc.ServiceCall call, $0.ListActiveModelsRequest request);

  $async.Future<$0.DeleteActiveModelResponse> deleteActiveModel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteActiveModelRequest> $request) async {
    return deleteActiveModel($call, await $request);
  }

  $async.Future<$0.DeleteActiveModelResponse> deleteActiveModel(
      $grpc.ServiceCall call, $0.DeleteActiveModelRequest request);
}
