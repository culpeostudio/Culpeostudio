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

import 'fillyengine.pb.dart' as $0;

export 'fillyengine.pb.dart';

@$pb.GrpcServiceName('fillyengine.EngineService')
class EngineServiceClient extends $grpc.Client {
  static const $core.String defaultHost = '';

  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EngineServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.EngineStatus> startEngine(
    $0.StartEngineRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startEngine, request, options: options);
  }

  $grpc.ResponseFuture<$0.EngineStatus> stopEngine(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopEngine, request, options: options);
  }

  $grpc.ResponseFuture<$0.EngineStatus> loadModel(
    $0.LoadModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$loadModel, request, options: options);
  }

  $grpc.ResponseFuture<$0.EngineStatus> getStatus(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModelList> listLocalModels(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listLocalModels, request, options: options);
  }

  static final _$startEngine =
      $grpc.ClientMethod<$0.StartEngineRequest, $0.EngineStatus>(
          '/fillyengine.EngineService/StartEngine',
          ($0.StartEngineRequest value) => value.writeToBuffer(),
          $0.EngineStatus.fromBuffer);
  static final _$stopEngine = $grpc.ClientMethod<$0.Empty, $0.EngineStatus>(
      '/fillyengine.EngineService/StopEngine',
      ($0.Empty value) => value.writeToBuffer(),
      $0.EngineStatus.fromBuffer);
  static final _$loadModel =
      $grpc.ClientMethod<$0.LoadModelRequest, $0.EngineStatus>(
          '/fillyengine.EngineService/LoadModel',
          ($0.LoadModelRequest value) => value.writeToBuffer(),
          $0.EngineStatus.fromBuffer);
  static final _$getStatus = $grpc.ClientMethod<$0.Empty, $0.EngineStatus>(
      '/fillyengine.EngineService/GetStatus',
      ($0.Empty value) => value.writeToBuffer(),
      $0.EngineStatus.fromBuffer);
  static final _$listLocalModels = $grpc.ClientMethod<$0.Empty, $0.ModelList>(
      '/fillyengine.EngineService/ListLocalModels',
      ($0.Empty value) => value.writeToBuffer(),
      $0.ModelList.fromBuffer);
}

@$pb.GrpcServiceName('fillyengine.EngineService')
abstract class EngineServiceBase extends $grpc.Service {
  $core.String get $name => 'fillyengine.EngineService';

  EngineServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StartEngineRequest, $0.EngineStatus>(
        'StartEngine',
        startEngine_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StartEngineRequest.fromBuffer(value),
        ($0.EngineStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.EngineStatus>(
        'StopEngine',
        stopEngine_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.EngineStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoadModelRequest, $0.EngineStatus>(
        'LoadModel',
        loadModel_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoadModelRequest.fromBuffer(value),
        ($0.EngineStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.EngineStatus>(
        'GetStatus',
        getStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.EngineStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.ModelList>(
        'ListLocalModels',
        listLocalModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.ModelList value) => value.writeToBuffer()));
  }

  $async.Future<$0.EngineStatus> startEngine_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StartEngineRequest> $request) async {
    return startEngine($call, await $request);
  }

  $async.Future<$0.EngineStatus> startEngine(
      $grpc.ServiceCall call, $0.StartEngineRequest request);

  $async.Future<$0.EngineStatus> stopEngine_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return stopEngine($call, await $request);
  }

  $async.Future<$0.EngineStatus> stopEngine(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.EngineStatus> loadModel_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LoadModelRequest> $request) async {
    return loadModel($call, await $request);
  }

  $async.Future<$0.EngineStatus> loadModel(
      $grpc.ServiceCall call, $0.LoadModelRequest request);

  $async.Future<$0.EngineStatus> getStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getStatus($call, await $request);
  }

  $async.Future<$0.EngineStatus> getStatus(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.ModelList> listLocalModels_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listLocalModels($call, await $request);
  }

  $async.Future<$0.ModelList> listLocalModels(
      $grpc.ServiceCall call, $0.Empty request);
}

@$pb.GrpcServiceName('fillyengine.ChatService')
class ChatServiceClient extends $grpc.Client {
  static const $core.String defaultHost = '';

  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ChatServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SessionInfo> createSession(
    $0.CreateSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.ChatMessageResponse> sendMessage(
    $0.ChatMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendMessage, request, options: options);
  }

  $grpc.ResponseStream<$0.ChatToken> streamMessage(
    $0.ChatMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamMessage, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ChatHistory> getHistory(
    $0.SessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getHistory, request, options: options);
  }

  static final _$createSession =
      $grpc.ClientMethod<$0.CreateSessionRequest, $0.SessionInfo>(
          '/fillyengine.ChatService/CreateSession',
          ($0.CreateSessionRequest value) => value.writeToBuffer(),
          $0.SessionInfo.fromBuffer);
  static final _$sendMessage =
      $grpc.ClientMethod<$0.ChatMessageRequest, $0.ChatMessageResponse>(
          '/fillyengine.ChatService/SendMessage',
          ($0.ChatMessageRequest value) => value.writeToBuffer(),
          $0.ChatMessageResponse.fromBuffer);
  static final _$streamMessage =
      $grpc.ClientMethod<$0.ChatMessageRequest, $0.ChatToken>(
          '/fillyengine.ChatService/StreamMessage',
          ($0.ChatMessageRequest value) => value.writeToBuffer(),
          $0.ChatToken.fromBuffer);
  static final _$getHistory =
      $grpc.ClientMethod<$0.SessionRequest, $0.ChatHistory>(
          '/fillyengine.ChatService/GetHistory',
          ($0.SessionRequest value) => value.writeToBuffer(),
          $0.ChatHistory.fromBuffer);
}

@$pb.GrpcServiceName('fillyengine.ChatService')
abstract class ChatServiceBase extends $grpc.Service {
  $core.String get $name => 'fillyengine.ChatService';

  ChatServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CreateSessionRequest, $0.SessionInfo>(
        'CreateSession',
        createSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateSessionRequest.fromBuffer(value),
        ($0.SessionInfo value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ChatMessageRequest, $0.ChatMessageResponse>(
            'SendMessage',
            sendMessage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ChatMessageRequest.fromBuffer(value),
            ($0.ChatMessageResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChatMessageRequest, $0.ChatToken>(
        'StreamMessage',
        streamMessage_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.ChatMessageRequest.fromBuffer(value),
        ($0.ChatToken value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRequest, $0.ChatHistory>(
        'GetHistory',
        getHistory_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRequest.fromBuffer(value),
        ($0.ChatHistory value) => value.writeToBuffer()));
  }

  $async.Future<$0.SessionInfo> createSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateSessionRequest> $request) async {
    return createSession($call, await $request);
  }

  $async.Future<$0.SessionInfo> createSession(
      $grpc.ServiceCall call, $0.CreateSessionRequest request);

  $async.Future<$0.ChatMessageResponse> sendMessage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ChatMessageRequest> $request) async {
    return sendMessage($call, await $request);
  }

  $async.Future<$0.ChatMessageResponse> sendMessage(
      $grpc.ServiceCall call, $0.ChatMessageRequest request);

  $async.Stream<$0.ChatToken> streamMessage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ChatMessageRequest> $request) async* {
    yield* streamMessage($call, await $request);
  }

  $async.Stream<$0.ChatToken> streamMessage(
      $grpc.ServiceCall call, $0.ChatMessageRequest request);

  $async.Future<$0.ChatHistory> getHistory_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SessionRequest> $request) async {
    return getHistory($call, await $request);
  }

  $async.Future<$0.ChatHistory> getHistory(
      $grpc.ServiceCall call, $0.SessionRequest request);
}

@$pb.GrpcServiceName('fillyengine.TrainingService')
class TrainingServiceClient extends $grpc.Client {
  static const $core.String defaultHost = '';

  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TrainingServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.JobInfo> startTraining(
    $0.TrainingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startTraining, request, options: options);
  }

  $grpc.ResponseFuture<$0.JobStatus> getJobStatus(
    $0.JobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getJobStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.JobList> listJobs(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listJobs, request, options: options);
  }

  $grpc.ResponseFuture<$0.JobStatus> cancelJob(
    $0.JobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelJob, request, options: options);
  }

  $grpc.ResponseStream<$0.TrainingMetrics> streamProgress(
    $0.JobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamProgress, $async.Stream.fromIterable([request]),
        options: options);
  }

  static final _$startTraining =
      $grpc.ClientMethod<$0.TrainingRequest, $0.JobInfo>(
          '/fillyengine.TrainingService/StartTraining',
          ($0.TrainingRequest value) => value.writeToBuffer(),
          $0.JobInfo.fromBuffer);
  static final _$getJobStatus = $grpc.ClientMethod<$0.JobRequest, $0.JobStatus>(
      '/fillyengine.TrainingService/GetJobStatus',
      ($0.JobRequest value) => value.writeToBuffer(),
      $0.JobStatus.fromBuffer);
  static final _$listJobs = $grpc.ClientMethod<$0.Empty, $0.JobList>(
      '/fillyengine.TrainingService/ListJobs',
      ($0.Empty value) => value.writeToBuffer(),
      $0.JobList.fromBuffer);
  static final _$cancelJob = $grpc.ClientMethod<$0.JobRequest, $0.JobStatus>(
      '/fillyengine.TrainingService/CancelJob',
      ($0.JobRequest value) => value.writeToBuffer(),
      $0.JobStatus.fromBuffer);
  static final _$streamProgress =
      $grpc.ClientMethod<$0.JobRequest, $0.TrainingMetrics>(
          '/fillyengine.TrainingService/StreamProgress',
          ($0.JobRequest value) => value.writeToBuffer(),
          $0.TrainingMetrics.fromBuffer);
}

@$pb.GrpcServiceName('fillyengine.TrainingService')
abstract class TrainingServiceBase extends $grpc.Service {
  $core.String get $name => 'fillyengine.TrainingService';

  TrainingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.TrainingRequest, $0.JobInfo>(
        'StartTraining',
        startTraining_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.TrainingRequest.fromBuffer(value),
        ($0.JobInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JobRequest, $0.JobStatus>(
        'GetJobStatus',
        getJobStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.JobRequest.fromBuffer(value),
        ($0.JobStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.JobList>(
        'ListJobs',
        listJobs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.JobList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JobRequest, $0.JobStatus>(
        'CancelJob',
        cancelJob_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.JobRequest.fromBuffer(value),
        ($0.JobStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JobRequest, $0.TrainingMetrics>(
        'StreamProgress',
        streamProgress_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.JobRequest.fromBuffer(value),
        ($0.TrainingMetrics value) => value.writeToBuffer()));
  }

  $async.Future<$0.JobInfo> startTraining_Pre($grpc.ServiceCall $call,
      $async.Future<$0.TrainingRequest> $request) async {
    return startTraining($call, await $request);
  }

  $async.Future<$0.JobInfo> startTraining(
      $grpc.ServiceCall call, $0.TrainingRequest request);

  $async.Future<$0.JobStatus> getJobStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.JobRequest> $request) async {
    return getJobStatus($call, await $request);
  }

  $async.Future<$0.JobStatus> getJobStatus(
      $grpc.ServiceCall call, $0.JobRequest request);

  $async.Future<$0.JobList> listJobs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listJobs($call, await $request);
  }

  $async.Future<$0.JobList> listJobs($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.JobStatus> cancelJob_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.JobRequest> $request) async {
    return cancelJob($call, await $request);
  }

  $async.Future<$0.JobStatus> cancelJob(
      $grpc.ServiceCall call, $0.JobRequest request);

  $async.Stream<$0.TrainingMetrics> streamProgress_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.JobRequest> $request) async* {
    yield* streamProgress($call, await $request);
  }

  $async.Stream<$0.TrainingMetrics> streamProgress(
      $grpc.ServiceCall call, $0.JobRequest request);
}

@$pb.GrpcServiceName('fillyengine.QuantizationService')
class QuantizationServiceClient extends $grpc.Client {
  static const $core.String defaultHost = '';

  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  QuantizationServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.JobInfo> startQuantization(
    $0.QuantRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startQuantization, request, options: options);
  }

  $grpc.ResponseFuture<$0.JobStatus> getJobStatus(
    $0.JobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getJobStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.JobList> listJobs(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listJobs, request, options: options);
  }

  $grpc.ResponseFuture<$0.QuantTypes> getAvailableTypes(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAvailableTypes, request, options: options);
  }

  $grpc.ResponseStream<$0.QuantProgress> streamProgress(
    $0.JobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamProgress, $async.Stream.fromIterable([request]),
        options: options);
  }

  static final _$startQuantization =
      $grpc.ClientMethod<$0.QuantRequest, $0.JobInfo>(
          '/fillyengine.QuantizationService/StartQuantization',
          ($0.QuantRequest value) => value.writeToBuffer(),
          $0.JobInfo.fromBuffer);
  static final _$getJobStatus = $grpc.ClientMethod<$0.JobRequest, $0.JobStatus>(
      '/fillyengine.QuantizationService/GetJobStatus',
      ($0.JobRequest value) => value.writeToBuffer(),
      $0.JobStatus.fromBuffer);
  static final _$listJobs = $grpc.ClientMethod<$0.Empty, $0.JobList>(
      '/fillyengine.QuantizationService/ListJobs',
      ($0.Empty value) => value.writeToBuffer(),
      $0.JobList.fromBuffer);
  static final _$getAvailableTypes =
      $grpc.ClientMethod<$0.Empty, $0.QuantTypes>(
          '/fillyengine.QuantizationService/GetAvailableTypes',
          ($0.Empty value) => value.writeToBuffer(),
          $0.QuantTypes.fromBuffer);
  static final _$streamProgress =
      $grpc.ClientMethod<$0.JobRequest, $0.QuantProgress>(
          '/fillyengine.QuantizationService/StreamProgress',
          ($0.JobRequest value) => value.writeToBuffer(),
          $0.QuantProgress.fromBuffer);
}

@$pb.GrpcServiceName('fillyengine.QuantizationService')
abstract class QuantizationServiceBase extends $grpc.Service {
  $core.String get $name => 'fillyengine.QuantizationService';

  QuantizationServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.QuantRequest, $0.JobInfo>(
        'StartQuantization',
        startQuantization_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QuantRequest.fromBuffer(value),
        ($0.JobInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JobRequest, $0.JobStatus>(
        'GetJobStatus',
        getJobStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.JobRequest.fromBuffer(value),
        ($0.JobStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.JobList>(
        'ListJobs',
        listJobs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.JobList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.QuantTypes>(
        'GetAvailableTypes',
        getAvailableTypes_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.QuantTypes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JobRequest, $0.QuantProgress>(
        'StreamProgress',
        streamProgress_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.JobRequest.fromBuffer(value),
        ($0.QuantProgress value) => value.writeToBuffer()));
  }

  $async.Future<$0.JobInfo> startQuantization_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.QuantRequest> $request) async {
    return startQuantization($call, await $request);
  }

  $async.Future<$0.JobInfo> startQuantization(
      $grpc.ServiceCall call, $0.QuantRequest request);

  $async.Future<$0.JobStatus> getJobStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.JobRequest> $request) async {
    return getJobStatus($call, await $request);
  }

  $async.Future<$0.JobStatus> getJobStatus(
      $grpc.ServiceCall call, $0.JobRequest request);

  $async.Future<$0.JobList> listJobs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listJobs($call, await $request);
  }

  $async.Future<$0.JobList> listJobs($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.QuantTypes> getAvailableTypes_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getAvailableTypes($call, await $request);
  }

  $async.Future<$0.QuantTypes> getAvailableTypes(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$0.QuantProgress> streamProgress_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.JobRequest> $request) async* {
    yield* streamProgress($call, await $request);
  }

  $async.Stream<$0.QuantProgress> streamProgress(
      $grpc.ServiceCall call, $0.JobRequest request);
}

@$pb.GrpcServiceName('fillyengine.MarktplatzService')
class MarktplatzServiceClient extends $grpc.Client {
  static const $core.String defaultHost = '';

  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MarktplatzServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SearchResponse> search(
    $0.SearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$search, request, options: options);
  }

  $grpc.ResponseFuture<$0.ModelDetail> getModelDetail(
    $0.ModelDetailRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getModelDetail, request, options: options);
  }

  $grpc.ResponseFuture<$0.JobInfo> download(
    $0.DownloadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$download, request, options: options);
  }

  $grpc.ResponseStream<$0.DownloadProgress> streamDownloadProgress(
    $0.JobRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamDownloadProgress, $async.Stream.fromIterable([request]),
        options: options);
  }

  static final _$search =
      $grpc.ClientMethod<$0.SearchRequest, $0.SearchResponse>(
          '/fillyengine.MarktplatzService/Search',
          ($0.SearchRequest value) => value.writeToBuffer(),
          $0.SearchResponse.fromBuffer);
  static final _$getModelDetail =
      $grpc.ClientMethod<$0.ModelDetailRequest, $0.ModelDetail>(
          '/fillyengine.MarktplatzService/GetModelDetail',
          ($0.ModelDetailRequest value) => value.writeToBuffer(),
          $0.ModelDetail.fromBuffer);
  static final _$download = $grpc.ClientMethod<$0.DownloadRequest, $0.JobInfo>(
      '/fillyengine.MarktplatzService/Download',
      ($0.DownloadRequest value) => value.writeToBuffer(),
      $0.JobInfo.fromBuffer);
  static final _$streamDownloadProgress =
      $grpc.ClientMethod<$0.JobRequest, $0.DownloadProgress>(
          '/fillyengine.MarktplatzService/StreamDownloadProgress',
          ($0.JobRequest value) => value.writeToBuffer(),
          $0.DownloadProgress.fromBuffer);
}

@$pb.GrpcServiceName('fillyengine.MarktplatzService')
abstract class MarktplatzServiceBase extends $grpc.Service {
  $core.String get $name => 'fillyengine.MarktplatzService';

  MarktplatzServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SearchRequest, $0.SearchResponse>(
        'Search',
        search_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SearchRequest.fromBuffer(value),
        ($0.SearchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ModelDetailRequest, $0.ModelDetail>(
        'GetModelDetail',
        getModelDetail_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ModelDetailRequest.fromBuffer(value),
        ($0.ModelDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DownloadRequest, $0.JobInfo>(
        'Download',
        download_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DownloadRequest.fromBuffer(value),
        ($0.JobInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JobRequest, $0.DownloadProgress>(
        'StreamDownloadProgress',
        streamDownloadProgress_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.JobRequest.fromBuffer(value),
        ($0.DownloadProgress value) => value.writeToBuffer()));
  }

  $async.Future<$0.SearchResponse> search_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SearchRequest> $request) async {
    return search($call, await $request);
  }

  $async.Future<$0.SearchResponse> search(
      $grpc.ServiceCall call, $0.SearchRequest request);

  $async.Future<$0.ModelDetail> getModelDetail_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ModelDetailRequest> $request) async {
    return getModelDetail($call, await $request);
  }

  $async.Future<$0.ModelDetail> getModelDetail(
      $grpc.ServiceCall call, $0.ModelDetailRequest request);

  $async.Future<$0.JobInfo> download_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DownloadRequest> $request) async {
    return download($call, await $request);
  }

  $async.Future<$0.JobInfo> download(
      $grpc.ServiceCall call, $0.DownloadRequest request);

  $async.Stream<$0.DownloadProgress> streamDownloadProgress_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.JobRequest> $request) async* {
    yield* streamDownloadProgress($call, await $request);
  }

  $async.Stream<$0.DownloadProgress> streamDownloadProgress(
      $grpc.ServiceCall call, $0.JobRequest request);
}

@$pb.GrpcServiceName('fillyengine.SkillsService')
class SkillsServiceClient extends $grpc.Client {
  static const $core.String defaultHost = '';

  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SkillsServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SkillListResponse> listSkills(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSkills, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkillResponse> importSkill(
    $0.ImportSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$importSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkillResponse> updateSkill(
    $0.UpdateSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSkillResponse> deleteSkill(
    $0.DeleteSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.SkillListResponse> rescanSkills(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rescanSkills, request, options: options);
  }

  static final _$listSkills =
      $grpc.ClientMethod<$0.Empty, $0.SkillListResponse>(
          '/fillyengine.SkillsService/ListSkills',
          ($0.Empty value) => value.writeToBuffer(),
          $0.SkillListResponse.fromBuffer);
  static final _$importSkill =
      $grpc.ClientMethod<$0.ImportSkillRequest, $0.SkillResponse>(
          '/fillyengine.SkillsService/ImportSkill',
          ($0.ImportSkillRequest value) => value.writeToBuffer(),
          $0.SkillResponse.fromBuffer);
  static final _$updateSkill =
      $grpc.ClientMethod<$0.UpdateSkillRequest, $0.SkillResponse>(
          '/fillyengine.SkillsService/UpdateSkill',
          ($0.UpdateSkillRequest value) => value.writeToBuffer(),
          $0.SkillResponse.fromBuffer);
  static final _$deleteSkill =
      $grpc.ClientMethod<$0.DeleteSkillRequest, $0.DeleteSkillResponse>(
          '/fillyengine.SkillsService/DeleteSkill',
          ($0.DeleteSkillRequest value) => value.writeToBuffer(),
          $0.DeleteSkillResponse.fromBuffer);
  static final _$rescanSkills =
      $grpc.ClientMethod<$0.Empty, $0.SkillListResponse>(
          '/fillyengine.SkillsService/RescanSkills',
          ($0.Empty value) => value.writeToBuffer(),
          $0.SkillListResponse.fromBuffer);
}

@$pb.GrpcServiceName('fillyengine.SkillsService')
abstract class SkillsServiceBase extends $grpc.Service {
  $core.String get $name => 'fillyengine.SkillsService';

  SkillsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SkillListResponse>(
        'ListSkills',
        listSkills_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SkillListResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ImportSkillRequest, $0.SkillResponse>(
        'ImportSkill',
        importSkill_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ImportSkillRequest.fromBuffer(value),
        ($0.SkillResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateSkillRequest, $0.SkillResponse>(
        'UpdateSkill',
        updateSkill_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateSkillRequest.fromBuffer(value),
        ($0.SkillResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteSkillRequest, $0.DeleteSkillResponse>(
            'DeleteSkill',
            deleteSkill_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteSkillRequest.fromBuffer(value),
            ($0.DeleteSkillResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SkillListResponse>(
        'RescanSkills',
        rescanSkills_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SkillListResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SkillListResponse> listSkills_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listSkills($call, await $request);
  }

  $async.Future<$0.SkillListResponse> listSkills(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SkillResponse> importSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ImportSkillRequest> $request) async {
    return importSkill($call, await $request);
  }

  $async.Future<$0.SkillResponse> importSkill(
      $grpc.ServiceCall call, $0.ImportSkillRequest request);

  $async.Future<$0.SkillResponse> updateSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateSkillRequest> $request) async {
    return updateSkill($call, await $request);
  }

  $async.Future<$0.SkillResponse> updateSkill(
      $grpc.ServiceCall call, $0.UpdateSkillRequest request);

  $async.Future<$0.DeleteSkillResponse> deleteSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteSkillRequest> $request) async {
    return deleteSkill($call, await $request);
  }

  $async.Future<$0.DeleteSkillResponse> deleteSkill(
      $grpc.ServiceCall call, $0.DeleteSkillRequest request);

  $async.Future<$0.SkillListResponse> rescanSkills_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return rescanSkills($call, await $request);
  }

  $async.Future<$0.SkillListResponse> rescanSkills(
      $grpc.ServiceCall call, $0.Empty request);
}

@$pb.GrpcServiceName('fillyengine.PhiloxAgenticService')
class PhiloxAgenticServiceClient extends $grpc.Client {
  static const $core.String defaultHost = '';

  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  PhiloxAgenticServiceClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseStream<$0.AgenticResponse> executeAgentic(
    $0.AgenticRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$executeAgentic, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.AgenticResponse> planAgentic(
    $0.AgenticRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$planAgentic, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ToolList> listTools(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listTools, request, options: options);
  }

  static final _$executeAgentic =
      $grpc.ClientMethod<$0.AgenticRequest, $0.AgenticResponse>(
          '/fillyengine.PhiloxAgenticService/ExecuteAgentic',
          ($0.AgenticRequest value) => value.writeToBuffer(),
          $0.AgenticResponse.fromBuffer);
  static final _$planAgentic =
      $grpc.ClientMethod<$0.AgenticRequest, $0.AgenticResponse>(
          '/fillyengine.PhiloxAgenticService/PlanAgentic',
          ($0.AgenticRequest value) => value.writeToBuffer(),
          $0.AgenticResponse.fromBuffer);
  static final _$listTools = $grpc.ClientMethod<$0.Empty, $0.ToolList>(
      '/fillyengine.PhiloxAgenticService/ListTools',
      ($0.Empty value) => value.writeToBuffer(),
      $0.ToolList.fromBuffer);
}

@$pb.GrpcServiceName('fillyengine.PhiloxAgenticService')
abstract class PhiloxAgenticServiceBase extends $grpc.Service {
  $core.String get $name => 'fillyengine.PhiloxAgenticService';

  PhiloxAgenticServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.AgenticRequest, $0.AgenticResponse>(
        'ExecuteAgentic',
        executeAgentic_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.AgenticRequest.fromBuffer(value),
        ($0.AgenticResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AgenticRequest, $0.AgenticResponse>(
        'PlanAgentic',
        planAgentic_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.AgenticRequest.fromBuffer(value),
        ($0.AgenticResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.ToolList>(
        'ListTools',
        listTools_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.ToolList value) => value.writeToBuffer()));
  }

  $async.Stream<$0.AgenticResponse> executeAgentic_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AgenticRequest> $request) async* {
    yield* executeAgentic($call, await $request);
  }

  $async.Stream<$0.AgenticResponse> executeAgentic(
      $grpc.ServiceCall call, $0.AgenticRequest request);

  $async.Stream<$0.AgenticResponse> planAgentic_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AgenticRequest> $request) async* {
    yield* planAgentic($call, await $request);
  }

  $async.Stream<$0.AgenticResponse> planAgentic(
      $grpc.ServiceCall call, $0.AgenticRequest request);

  $async.Future<$0.ToolList> listTools_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listTools($call, await $request);
  }

  $async.Future<$0.ToolList> listTools(
      $grpc.ServiceCall call, $0.Empty request);
}
