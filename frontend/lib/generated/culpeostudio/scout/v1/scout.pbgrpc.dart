// This is a generated file - do not edit.
//
// Generated from culpeostudio/scout/v1/scout.proto.

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

import 'scout.pb.dart' as $0;

export 'scout.pb.dart';

/// ScoutService backs the chat: sessions and their history, the bots that answer
/// in them, and the reply itself - either as one message or streamed.
@$pb.GrpcServiceName('culpeostudio.scout.v1.ScoutService')
class ScoutServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ScoutServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.CreateSessionResponse> createSession(
    $0.CreateSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListSessionsResponse> listSessions(
    $0.ListSessionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSessions, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetHistoryResponse> getHistory(
    $0.GetHistoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getHistory, request, options: options);
  }

  $grpc.ResponseFuture<$0.RenameSessionResponse> renameSession(
    $0.RenameSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$renameSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSessionResponse> deleteSession(
    $0.DeleteSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetSessionProjectResponse> setSessionProject(
    $0.SetSessionProjectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setSessionProject, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetSessionModelResponse> setSessionModel(
    $0.SetSessionModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setSessionModel, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetSessionTreeResponse> getSessionTree(
    $0.GetSessionTreeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSessionTree, request, options: options);
  }

  $grpc.ResponseFuture<$0.SendMessageResponse> sendMessage(
    $0.SendMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendMessage, request, options: options);
  }

  /// The streamed counterpart of SendMessage. This replaces the Server-Sent
  /// Events the HTTP API wrote by hand: the events are typed, a client that
  /// goes away cancels the context instead of the handler discovering a dead
  /// writer, and the call carries the same credentials as every other method.
  $grpc.ResponseStream<$0.StreamMessageResponse> streamMessage(
    $0.StreamMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamMessage, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ListBotsResponse> listBots(
    $0.ListBotsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listBots, request, options: options);
  }

  $grpc.ResponseFuture<$0.SaveBotResponse> saveBot(
    $0.SaveBotRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveBot, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteBotResponse> deleteBot(
    $0.DeleteBotRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteBot, request, options: options);
  }

  // method descriptors

  static final _$createSession =
      $grpc.ClientMethod<$0.CreateSessionRequest, $0.CreateSessionResponse>(
          '/culpeostudio.scout.v1.ScoutService/CreateSession',
          ($0.CreateSessionRequest value) => value.writeToBuffer(),
          $0.CreateSessionResponse.fromBuffer);
  static final _$listSessions =
      $grpc.ClientMethod<$0.ListSessionsRequest, $0.ListSessionsResponse>(
          '/culpeostudio.scout.v1.ScoutService/ListSessions',
          ($0.ListSessionsRequest value) => value.writeToBuffer(),
          $0.ListSessionsResponse.fromBuffer);
  static final _$getHistory =
      $grpc.ClientMethod<$0.GetHistoryRequest, $0.GetHistoryResponse>(
          '/culpeostudio.scout.v1.ScoutService/GetHistory',
          ($0.GetHistoryRequest value) => value.writeToBuffer(),
          $0.GetHistoryResponse.fromBuffer);
  static final _$renameSession =
      $grpc.ClientMethod<$0.RenameSessionRequest, $0.RenameSessionResponse>(
          '/culpeostudio.scout.v1.ScoutService/RenameSession',
          ($0.RenameSessionRequest value) => value.writeToBuffer(),
          $0.RenameSessionResponse.fromBuffer);
  static final _$deleteSession =
      $grpc.ClientMethod<$0.DeleteSessionRequest, $0.DeleteSessionResponse>(
          '/culpeostudio.scout.v1.ScoutService/DeleteSession',
          ($0.DeleteSessionRequest value) => value.writeToBuffer(),
          $0.DeleteSessionResponse.fromBuffer);
  static final _$setSessionProject = $grpc.ClientMethod<
          $0.SetSessionProjectRequest, $0.SetSessionProjectResponse>(
      '/culpeostudio.scout.v1.ScoutService/SetSessionProject',
      ($0.SetSessionProjectRequest value) => value.writeToBuffer(),
      $0.SetSessionProjectResponse.fromBuffer);
  static final _$setSessionModel =
      $grpc.ClientMethod<$0.SetSessionModelRequest, $0.SetSessionModelResponse>(
          '/culpeostudio.scout.v1.ScoutService/SetSessionModel',
          ($0.SetSessionModelRequest value) => value.writeToBuffer(),
          $0.SetSessionModelResponse.fromBuffer);
  static final _$getSessionTree =
      $grpc.ClientMethod<$0.GetSessionTreeRequest, $0.GetSessionTreeResponse>(
          '/culpeostudio.scout.v1.ScoutService/GetSessionTree',
          ($0.GetSessionTreeRequest value) => value.writeToBuffer(),
          $0.GetSessionTreeResponse.fromBuffer);
  static final _$sendMessage =
      $grpc.ClientMethod<$0.SendMessageRequest, $0.SendMessageResponse>(
          '/culpeostudio.scout.v1.ScoutService/SendMessage',
          ($0.SendMessageRequest value) => value.writeToBuffer(),
          $0.SendMessageResponse.fromBuffer);
  static final _$streamMessage =
      $grpc.ClientMethod<$0.StreamMessageRequest, $0.StreamMessageResponse>(
          '/culpeostudio.scout.v1.ScoutService/StreamMessage',
          ($0.StreamMessageRequest value) => value.writeToBuffer(),
          $0.StreamMessageResponse.fromBuffer);
  static final _$listBots =
      $grpc.ClientMethod<$0.ListBotsRequest, $0.ListBotsResponse>(
          '/culpeostudio.scout.v1.ScoutService/ListBots',
          ($0.ListBotsRequest value) => value.writeToBuffer(),
          $0.ListBotsResponse.fromBuffer);
  static final _$saveBot =
      $grpc.ClientMethod<$0.SaveBotRequest, $0.SaveBotResponse>(
          '/culpeostudio.scout.v1.ScoutService/SaveBot',
          ($0.SaveBotRequest value) => value.writeToBuffer(),
          $0.SaveBotResponse.fromBuffer);
  static final _$deleteBot =
      $grpc.ClientMethod<$0.DeleteBotRequest, $0.DeleteBotResponse>(
          '/culpeostudio.scout.v1.ScoutService/DeleteBot',
          ($0.DeleteBotRequest value) => value.writeToBuffer(),
          $0.DeleteBotResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.scout.v1.ScoutService')
abstract class ScoutServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.scout.v1.ScoutService';

  ScoutServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.CreateSessionRequest, $0.CreateSessionResponse>(
            'CreateSession',
            createSession_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateSessionRequest.fromBuffer(value),
            ($0.CreateSessionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListSessionsRequest, $0.ListSessionsResponse>(
            'ListSessions',
            listSessions_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListSessionsRequest.fromBuffer(value),
            ($0.ListSessionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetHistoryRequest, $0.GetHistoryResponse>(
        'GetHistory',
        getHistory_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetHistoryRequest.fromBuffer(value),
        ($0.GetHistoryResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RenameSessionRequest, $0.RenameSessionResponse>(
            'RenameSession',
            renameSession_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RenameSessionRequest.fromBuffer(value),
            ($0.RenameSessionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteSessionRequest, $0.DeleteSessionResponse>(
            'DeleteSession',
            deleteSession_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteSessionRequest.fromBuffer(value),
            ($0.DeleteSessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetSessionProjectRequest,
            $0.SetSessionProjectResponse>(
        'SetSessionProject',
        setSessionProject_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetSessionProjectRequest.fromBuffer(value),
        ($0.SetSessionProjectResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetSessionModelRequest,
            $0.SetSessionModelResponse>(
        'SetSessionModel',
        setSessionModel_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetSessionModelRequest.fromBuffer(value),
        ($0.SetSessionModelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetSessionTreeRequest,
            $0.GetSessionTreeResponse>(
        'GetSessionTree',
        getSessionTree_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetSessionTreeRequest.fromBuffer(value),
        ($0.GetSessionTreeResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SendMessageRequest, $0.SendMessageResponse>(
            'SendMessage',
            sendMessage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SendMessageRequest.fromBuffer(value),
            ($0.SendMessageResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StreamMessageRequest, $0.StreamMessageResponse>(
            'StreamMessage',
            streamMessage_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.StreamMessageRequest.fromBuffer(value),
            ($0.StreamMessageResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListBotsRequest, $0.ListBotsResponse>(
        'ListBots',
        listBots_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListBotsRequest.fromBuffer(value),
        ($0.ListBotsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SaveBotRequest, $0.SaveBotResponse>(
        'SaveBot',
        saveBot_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SaveBotRequest.fromBuffer(value),
        ($0.SaveBotResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteBotRequest, $0.DeleteBotResponse>(
        'DeleteBot',
        deleteBot_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteBotRequest.fromBuffer(value),
        ($0.DeleteBotResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CreateSessionResponse> createSession_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateSessionRequest> $request) async {
    return createSession($call, await $request);
  }

  $async.Future<$0.CreateSessionResponse> createSession(
      $grpc.ServiceCall call, $0.CreateSessionRequest request);

  $async.Future<$0.ListSessionsResponse> listSessions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListSessionsRequest> $request) async {
    return listSessions($call, await $request);
  }

  $async.Future<$0.ListSessionsResponse> listSessions(
      $grpc.ServiceCall call, $0.ListSessionsRequest request);

  $async.Future<$0.GetHistoryResponse> getHistory_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetHistoryRequest> $request) async {
    return getHistory($call, await $request);
  }

  $async.Future<$0.GetHistoryResponse> getHistory(
      $grpc.ServiceCall call, $0.GetHistoryRequest request);

  $async.Future<$0.RenameSessionResponse> renameSession_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RenameSessionRequest> $request) async {
    return renameSession($call, await $request);
  }

  $async.Future<$0.RenameSessionResponse> renameSession(
      $grpc.ServiceCall call, $0.RenameSessionRequest request);

  $async.Future<$0.DeleteSessionResponse> deleteSession_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteSessionRequest> $request) async {
    return deleteSession($call, await $request);
  }

  $async.Future<$0.DeleteSessionResponse> deleteSession(
      $grpc.ServiceCall call, $0.DeleteSessionRequest request);

  $async.Future<$0.SetSessionProjectResponse> setSessionProject_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetSessionProjectRequest> $request) async {
    return setSessionProject($call, await $request);
  }

  $async.Future<$0.SetSessionProjectResponse> setSessionProject(
      $grpc.ServiceCall call, $0.SetSessionProjectRequest request);

  $async.Future<$0.SetSessionModelResponse> setSessionModel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetSessionModelRequest> $request) async {
    return setSessionModel($call, await $request);
  }

  $async.Future<$0.SetSessionModelResponse> setSessionModel(
      $grpc.ServiceCall call, $0.SetSessionModelRequest request);

  $async.Future<$0.GetSessionTreeResponse> getSessionTree_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSessionTreeRequest> $request) async {
    return getSessionTree($call, await $request);
  }

  $async.Future<$0.GetSessionTreeResponse> getSessionTree(
      $grpc.ServiceCall call, $0.GetSessionTreeRequest request);

  $async.Future<$0.SendMessageResponse> sendMessage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SendMessageRequest> $request) async {
    return sendMessage($call, await $request);
  }

  $async.Future<$0.SendMessageResponse> sendMessage(
      $grpc.ServiceCall call, $0.SendMessageRequest request);

  $async.Stream<$0.StreamMessageResponse> streamMessage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StreamMessageRequest> $request) async* {
    yield* streamMessage($call, await $request);
  }

  $async.Stream<$0.StreamMessageResponse> streamMessage(
      $grpc.ServiceCall call, $0.StreamMessageRequest request);

  $async.Future<$0.ListBotsResponse> listBots_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListBotsRequest> $request) async {
    return listBots($call, await $request);
  }

  $async.Future<$0.ListBotsResponse> listBots(
      $grpc.ServiceCall call, $0.ListBotsRequest request);

  $async.Future<$0.SaveBotResponse> saveBot_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SaveBotRequest> $request) async {
    return saveBot($call, await $request);
  }

  $async.Future<$0.SaveBotResponse> saveBot(
      $grpc.ServiceCall call, $0.SaveBotRequest request);

  $async.Future<$0.DeleteBotResponse> deleteBot_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteBotRequest> $request) async {
    return deleteBot($call, await $request);
  }

  $async.Future<$0.DeleteBotResponse> deleteBot(
      $grpc.ServiceCall call, $0.DeleteBotRequest request);
}
