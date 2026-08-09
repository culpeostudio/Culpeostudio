// This is a generated file - do not edit.
//
// Generated from culpeostudio/benchmark/v1/benchmark.proto.

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

import 'benchmark.pb.dart' as $0;

export 'benchmark.pb.dart';

/// BenchmarkService serves the public model leaderboards: the registered boards,
/// their load state, the ranked list, a single model's standing and side-by-side
/// comparisons.
@$pb.GrpcServiceName('culpeostudio.benchmark.v1.BenchmarkService')
class BenchmarkServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  BenchmarkServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListBoardsResponse> listBoards(
    $0.ListBoardsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listBoards, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetStatusResponse> getStatus(
    $0.GetStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetOverviewResponse> getOverview(
    $0.GetOverviewRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getOverview, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetLeaderboardResponse> getLeaderboard(
    $0.GetLeaderboardRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getLeaderboard, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetModelResponse> getModel(
    $0.GetModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getModel, request, options: options);
  }

  $grpc.ResponseFuture<$0.CompareModelsResponse> compareModels(
    $0.CompareModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$compareModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.RefreshBoardsResponse> refreshBoards(
    $0.RefreshBoardsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshBoards, request, options: options);
  }

  // method descriptors

  static final _$listBoards =
      $grpc.ClientMethod<$0.ListBoardsRequest, $0.ListBoardsResponse>(
          '/culpeostudio.benchmark.v1.BenchmarkService/ListBoards',
          ($0.ListBoardsRequest value) => value.writeToBuffer(),
          $0.ListBoardsResponse.fromBuffer);
  static final _$getStatus =
      $grpc.ClientMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
          '/culpeostudio.benchmark.v1.BenchmarkService/GetStatus',
          ($0.GetStatusRequest value) => value.writeToBuffer(),
          $0.GetStatusResponse.fromBuffer);
  static final _$getOverview =
      $grpc.ClientMethod<$0.GetOverviewRequest, $0.GetOverviewResponse>(
          '/culpeostudio.benchmark.v1.BenchmarkService/GetOverview',
          ($0.GetOverviewRequest value) => value.writeToBuffer(),
          $0.GetOverviewResponse.fromBuffer);
  static final _$getLeaderboard =
      $grpc.ClientMethod<$0.GetLeaderboardRequest, $0.GetLeaderboardResponse>(
          '/culpeostudio.benchmark.v1.BenchmarkService/GetLeaderboard',
          ($0.GetLeaderboardRequest value) => value.writeToBuffer(),
          $0.GetLeaderboardResponse.fromBuffer);
  static final _$getModel =
      $grpc.ClientMethod<$0.GetModelRequest, $0.GetModelResponse>(
          '/culpeostudio.benchmark.v1.BenchmarkService/GetModel',
          ($0.GetModelRequest value) => value.writeToBuffer(),
          $0.GetModelResponse.fromBuffer);
  static final _$compareModels =
      $grpc.ClientMethod<$0.CompareModelsRequest, $0.CompareModelsResponse>(
          '/culpeostudio.benchmark.v1.BenchmarkService/CompareModels',
          ($0.CompareModelsRequest value) => value.writeToBuffer(),
          $0.CompareModelsResponse.fromBuffer);
  static final _$refreshBoards =
      $grpc.ClientMethod<$0.RefreshBoardsRequest, $0.RefreshBoardsResponse>(
          '/culpeostudio.benchmark.v1.BenchmarkService/RefreshBoards',
          ($0.RefreshBoardsRequest value) => value.writeToBuffer(),
          $0.RefreshBoardsResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.benchmark.v1.BenchmarkService')
abstract class BenchmarkServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.benchmark.v1.BenchmarkService';

  BenchmarkServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListBoardsRequest, $0.ListBoardsResponse>(
        'ListBoards',
        listBoards_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListBoardsRequest.fromBuffer(value),
        ($0.ListBoardsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
        'GetStatus',
        getStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatusRequest.fromBuffer(value),
        ($0.GetStatusResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetOverviewRequest, $0.GetOverviewResponse>(
            'GetOverview',
            getOverview_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetOverviewRequest.fromBuffer(value),
            ($0.GetOverviewResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetLeaderboardRequest,
            $0.GetLeaderboardResponse>(
        'GetLeaderboard',
        getLeaderboard_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetLeaderboardRequest.fromBuffer(value),
        ($0.GetLeaderboardResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetModelRequest, $0.GetModelResponse>(
        'GetModel',
        getModel_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetModelRequest.fromBuffer(value),
        ($0.GetModelResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CompareModelsRequest, $0.CompareModelsResponse>(
            'CompareModels',
            compareModels_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CompareModelsRequest.fromBuffer(value),
            ($0.CompareModelsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RefreshBoardsRequest, $0.RefreshBoardsResponse>(
            'RefreshBoards',
            refreshBoards_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RefreshBoardsRequest.fromBuffer(value),
            ($0.RefreshBoardsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListBoardsResponse> listBoards_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListBoardsRequest> $request) async {
    return listBoards($call, await $request);
  }

  $async.Future<$0.ListBoardsResponse> listBoards(
      $grpc.ServiceCall call, $0.ListBoardsRequest request);

  $async.Future<$0.GetStatusResponse> getStatus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetStatusRequest> $request) async {
    return getStatus($call, await $request);
  }

  $async.Future<$0.GetStatusResponse> getStatus(
      $grpc.ServiceCall call, $0.GetStatusRequest request);

  $async.Future<$0.GetOverviewResponse> getOverview_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetOverviewRequest> $request) async {
    return getOverview($call, await $request);
  }

  $async.Future<$0.GetOverviewResponse> getOverview(
      $grpc.ServiceCall call, $0.GetOverviewRequest request);

  $async.Future<$0.GetLeaderboardResponse> getLeaderboard_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetLeaderboardRequest> $request) async {
    return getLeaderboard($call, await $request);
  }

  $async.Future<$0.GetLeaderboardResponse> getLeaderboard(
      $grpc.ServiceCall call, $0.GetLeaderboardRequest request);

  $async.Future<$0.GetModelResponse> getModel_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetModelRequest> $request) async {
    return getModel($call, await $request);
  }

  $async.Future<$0.GetModelResponse> getModel(
      $grpc.ServiceCall call, $0.GetModelRequest request);

  $async.Future<$0.CompareModelsResponse> compareModels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CompareModelsRequest> $request) async {
    return compareModels($call, await $request);
  }

  $async.Future<$0.CompareModelsResponse> compareModels(
      $grpc.ServiceCall call, $0.CompareModelsRequest request);

  $async.Future<$0.RefreshBoardsResponse> refreshBoards_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RefreshBoardsRequest> $request) async {
    return refreshBoards($call, await $request);
  }

  $async.Future<$0.RefreshBoardsResponse> refreshBoards(
      $grpc.ServiceCall call, $0.RefreshBoardsRequest request);
}
