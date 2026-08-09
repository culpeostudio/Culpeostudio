// This is a generated file - do not edit.
//
// Generated from culpeostudio/marketplace/v1/marketplace.proto.

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

import 'marketplace.pb.dart' as $0;

export 'marketplace.pb.dart';

/// MarketplaceService backs the model marketplace: searching the model hosts,
/// the detail view, the download jobs and the hosted models activated for chat.
@$pb.GrpcServiceName('culpeostudio.marketplace.v1.MarketplaceService')
class MarketplaceServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MarketplaceServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SearchModelsResponse> searchModels(
    $0.SearchModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetModelDetailResponse> getModelDetail(
    $0.GetModelDetailRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getModelDetail, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetHardwareProfileResponse> getHardwareProfile(
    $0.GetHardwareProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getHardwareProfile, request, options: options);
  }

  $grpc.ResponseFuture<$0.StartDownloadResponse> startDownload(
    $0.StartDownloadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startDownload, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListDownloadJobsResponse> listDownloadJobs(
    $0.ListDownloadJobsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDownloadJobs, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetDownloadJobResponse> getDownloadJob(
    $0.GetDownloadJobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getDownloadJob, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteDownloadJobResponse> deleteDownloadJob(
    $0.DeleteDownloadJobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteDownloadJob, request, options: options);
  }

  $grpc.ResponseFuture<$0.StartApiModelResponse> startApiModel(
    $0.StartApiModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startApiModel, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListActiveApiModelsResponse> listActiveApiModels(
    $0.ListActiveApiModelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listActiveApiModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteActiveApiModelResponse> deleteActiveApiModel(
    $0.DeleteActiveApiModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteActiveApiModel, request, options: options);
  }

  // method descriptors

  static final _$searchModels =
      $grpc.ClientMethod<$0.SearchModelsRequest, $0.SearchModelsResponse>(
          '/culpeostudio.marketplace.v1.MarketplaceService/SearchModels',
          ($0.SearchModelsRequest value) => value.writeToBuffer(),
          $0.SearchModelsResponse.fromBuffer);
  static final _$getModelDetail =
      $grpc.ClientMethod<$0.GetModelDetailRequest, $0.GetModelDetailResponse>(
          '/culpeostudio.marketplace.v1.MarketplaceService/GetModelDetail',
          ($0.GetModelDetailRequest value) => value.writeToBuffer(),
          $0.GetModelDetailResponse.fromBuffer);
  static final _$getHardwareProfile = $grpc.ClientMethod<
          $0.GetHardwareProfileRequest, $0.GetHardwareProfileResponse>(
      '/culpeostudio.marketplace.v1.MarketplaceService/GetHardwareProfile',
      ($0.GetHardwareProfileRequest value) => value.writeToBuffer(),
      $0.GetHardwareProfileResponse.fromBuffer);
  static final _$startDownload =
      $grpc.ClientMethod<$0.StartDownloadRequest, $0.StartDownloadResponse>(
          '/culpeostudio.marketplace.v1.MarketplaceService/StartDownload',
          ($0.StartDownloadRequest value) => value.writeToBuffer(),
          $0.StartDownloadResponse.fromBuffer);
  static final _$listDownloadJobs = $grpc.ClientMethod<
          $0.ListDownloadJobsRequest, $0.ListDownloadJobsResponse>(
      '/culpeostudio.marketplace.v1.MarketplaceService/ListDownloadJobs',
      ($0.ListDownloadJobsRequest value) => value.writeToBuffer(),
      $0.ListDownloadJobsResponse.fromBuffer);
  static final _$getDownloadJob =
      $grpc.ClientMethod<$0.GetDownloadJobRequest, $0.GetDownloadJobResponse>(
          '/culpeostudio.marketplace.v1.MarketplaceService/GetDownloadJob',
          ($0.GetDownloadJobRequest value) => value.writeToBuffer(),
          $0.GetDownloadJobResponse.fromBuffer);
  static final _$deleteDownloadJob = $grpc.ClientMethod<
          $0.DeleteDownloadJobRequest, $0.DeleteDownloadJobResponse>(
      '/culpeostudio.marketplace.v1.MarketplaceService/DeleteDownloadJob',
      ($0.DeleteDownloadJobRequest value) => value.writeToBuffer(),
      $0.DeleteDownloadJobResponse.fromBuffer);
  static final _$startApiModel =
      $grpc.ClientMethod<$0.StartApiModelRequest, $0.StartApiModelResponse>(
          '/culpeostudio.marketplace.v1.MarketplaceService/StartApiModel',
          ($0.StartApiModelRequest value) => value.writeToBuffer(),
          $0.StartApiModelResponse.fromBuffer);
  static final _$listActiveApiModels = $grpc.ClientMethod<
          $0.ListActiveApiModelsRequest, $0.ListActiveApiModelsResponse>(
      '/culpeostudio.marketplace.v1.MarketplaceService/ListActiveApiModels',
      ($0.ListActiveApiModelsRequest value) => value.writeToBuffer(),
      $0.ListActiveApiModelsResponse.fromBuffer);
  static final _$deleteActiveApiModel = $grpc.ClientMethod<
          $0.DeleteActiveApiModelRequest, $0.DeleteActiveApiModelResponse>(
      '/culpeostudio.marketplace.v1.MarketplaceService/DeleteActiveApiModel',
      ($0.DeleteActiveApiModelRequest value) => value.writeToBuffer(),
      $0.DeleteActiveApiModelResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.marketplace.v1.MarketplaceService')
abstract class MarketplaceServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.marketplace.v1.MarketplaceService';

  MarketplaceServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.SearchModelsRequest, $0.SearchModelsResponse>(
            'SearchModels',
            searchModels_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SearchModelsRequest.fromBuffer(value),
            ($0.SearchModelsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetModelDetailRequest,
            $0.GetModelDetailResponse>(
        'GetModelDetail',
        getModelDetail_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetModelDetailRequest.fromBuffer(value),
        ($0.GetModelDetailResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetHardwareProfileRequest,
            $0.GetHardwareProfileResponse>(
        'GetHardwareProfile',
        getHardwareProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetHardwareProfileRequest.fromBuffer(value),
        ($0.GetHardwareProfileResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StartDownloadRequest, $0.StartDownloadResponse>(
            'StartDownload',
            startDownload_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.StartDownloadRequest.fromBuffer(value),
            ($0.StartDownloadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListDownloadJobsRequest,
            $0.ListDownloadJobsResponse>(
        'ListDownloadJobs',
        listDownloadJobs_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListDownloadJobsRequest.fromBuffer(value),
        ($0.ListDownloadJobsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetDownloadJobRequest,
            $0.GetDownloadJobResponse>(
        'GetDownloadJob',
        getDownloadJob_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetDownloadJobRequest.fromBuffer(value),
        ($0.GetDownloadJobResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteDownloadJobRequest,
            $0.DeleteDownloadJobResponse>(
        'DeleteDownloadJob',
        deleteDownloadJob_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteDownloadJobRequest.fromBuffer(value),
        ($0.DeleteDownloadJobResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StartApiModelRequest, $0.StartApiModelResponse>(
            'StartApiModel',
            startApiModel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.StartApiModelRequest.fromBuffer(value),
            ($0.StartApiModelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListActiveApiModelsRequest,
            $0.ListActiveApiModelsResponse>(
        'ListActiveApiModels',
        listActiveApiModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListActiveApiModelsRequest.fromBuffer(value),
        ($0.ListActiveApiModelsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteActiveApiModelRequest,
            $0.DeleteActiveApiModelResponse>(
        'DeleteActiveApiModel',
        deleteActiveApiModel_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteActiveApiModelRequest.fromBuffer(value),
        ($0.DeleteActiveApiModelResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SearchModelsResponse> searchModels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SearchModelsRequest> $request) async {
    return searchModels($call, await $request);
  }

  $async.Future<$0.SearchModelsResponse> searchModels(
      $grpc.ServiceCall call, $0.SearchModelsRequest request);

  $async.Future<$0.GetModelDetailResponse> getModelDetail_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetModelDetailRequest> $request) async {
    return getModelDetail($call, await $request);
  }

  $async.Future<$0.GetModelDetailResponse> getModelDetail(
      $grpc.ServiceCall call, $0.GetModelDetailRequest request);

  $async.Future<$0.GetHardwareProfileResponse> getHardwareProfile_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetHardwareProfileRequest> $request) async {
    return getHardwareProfile($call, await $request);
  }

  $async.Future<$0.GetHardwareProfileResponse> getHardwareProfile(
      $grpc.ServiceCall call, $0.GetHardwareProfileRequest request);

  $async.Future<$0.StartDownloadResponse> startDownload_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartDownloadRequest> $request) async {
    return startDownload($call, await $request);
  }

  $async.Future<$0.StartDownloadResponse> startDownload(
      $grpc.ServiceCall call, $0.StartDownloadRequest request);

  $async.Future<$0.ListDownloadJobsResponse> listDownloadJobs_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDownloadJobsRequest> $request) async {
    return listDownloadJobs($call, await $request);
  }

  $async.Future<$0.ListDownloadJobsResponse> listDownloadJobs(
      $grpc.ServiceCall call, $0.ListDownloadJobsRequest request);

  $async.Future<$0.GetDownloadJobResponse> getDownloadJob_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetDownloadJobRequest> $request) async {
    return getDownloadJob($call, await $request);
  }

  $async.Future<$0.GetDownloadJobResponse> getDownloadJob(
      $grpc.ServiceCall call, $0.GetDownloadJobRequest request);

  $async.Future<$0.DeleteDownloadJobResponse> deleteDownloadJob_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteDownloadJobRequest> $request) async {
    return deleteDownloadJob($call, await $request);
  }

  $async.Future<$0.DeleteDownloadJobResponse> deleteDownloadJob(
      $grpc.ServiceCall call, $0.DeleteDownloadJobRequest request);

  $async.Future<$0.StartApiModelResponse> startApiModel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartApiModelRequest> $request) async {
    return startApiModel($call, await $request);
  }

  $async.Future<$0.StartApiModelResponse> startApiModel(
      $grpc.ServiceCall call, $0.StartApiModelRequest request);

  $async.Future<$0.ListActiveApiModelsResponse> listActiveApiModels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListActiveApiModelsRequest> $request) async {
    return listActiveApiModels($call, await $request);
  }

  $async.Future<$0.ListActiveApiModelsResponse> listActiveApiModels(
      $grpc.ServiceCall call, $0.ListActiveApiModelsRequest request);

  $async.Future<$0.DeleteActiveApiModelResponse> deleteActiveApiModel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteActiveApiModelRequest> $request) async {
    return deleteActiveApiModel($call, await $request);
  }

  $async.Future<$0.DeleteActiveApiModelResponse> deleteActiveApiModel(
      $grpc.ServiceCall call, $0.DeleteActiveApiModelRequest request);
}
