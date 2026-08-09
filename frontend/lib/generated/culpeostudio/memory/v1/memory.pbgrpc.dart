// This is a generated file - do not edit.
//
// Generated from culpeostudio/memory/v1/memory.proto.

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

import 'memory.pb.dart' as $0;

export 'memory.pb.dart';

/// MemoryService is the programmatic side of the memory module: sessions and
/// what they accumulate, retrieval over it, and the live event feed.
///
/// The user a call acts for is never a field in these messages. It comes from
/// the credential the call carries, the way the HTTP handlers took it from the
/// authenticated request rather than from the body.
///
/// The browser-facing half of the module stays on HTTP, because the memory
/// viewer is a page served to a browser and a browser speaks neither gRPC nor
/// HTTP/2 trailers: /memory/view, its read-only queries, and the SSE feed at
/// /memory/events with the ticket handshake that gets a token past EventSource.
/// StreamEvents below is the same feed for callers that can send metadata, so
/// they need no ticket.
@$pb.GrpcServiceName('culpeostudio.memory.v1.MemoryService')
class MemoryServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MemoryServiceClient(super.channel, {super.options, super.interceptors});

  /// Sessions and their contents.
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

  $grpc.ResponseFuture<$0.GetSessionResponse> getSession(
    $0.GetSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSessionResponse> deleteSession(
    $0.DeleteSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.AddPromptResponse> addPrompt(
    $0.AddPromptRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addPrompt, request, options: options);
  }

  $grpc.ResponseFuture<$0.AddObservationResponse> addObservation(
    $0.AddObservationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addObservation, request, options: options);
  }

  $grpc.ResponseFuture<$0.CompleteSessionResponse> completeSession(
    $0.CompleteSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$completeSession, request, options: options);
  }

  /// Retrieval.
  $grpc.ResponseFuture<$0.SearchResponse> search(
    $0.SearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$search, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetTimelineResponse> getTimeline(
    $0.GetTimelineRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getTimeline, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetObservationsResponse> getObservations(
    $0.GetObservationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getObservations, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetContextResponse> getContext(
    $0.GetContextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getContext, request, options: options);
  }

  /// Corrections to what was remembered.
  $grpc.ResponseFuture<$0.UpdateChangeRequestStatusResponse>
      updateChangeRequestStatus(
    $0.UpdateChangeRequestStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateChangeRequestStatus, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.DeleteObservationResponse> deleteObservation(
    $0.DeleteObservationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteObservation, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateMemoryResponse> updateMemory(
    $0.UpdateMemoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateMemory, request, options: options);
  }

  /// Capture, which is throttled per caller.
  $grpc.ResponseFuture<$0.CaptureChatMessageResponse> captureChatMessage(
    $0.CaptureChatMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$captureChatMessage, request, options: options);
  }

  $grpc.ResponseFuture<$0.CaptureEventResponse> captureEvent(
    $0.CaptureEventRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$captureEvent, request, options: options);
  }

  /// Live feed of everything the store changes, scoped to the caller.
  $grpc.ResponseStream<$0.StreamEventsResponse> streamEvents(
    $0.StreamEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamEvents, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$createSession =
      $grpc.ClientMethod<$0.CreateSessionRequest, $0.CreateSessionResponse>(
          '/culpeostudio.memory.v1.MemoryService/CreateSession',
          ($0.CreateSessionRequest value) => value.writeToBuffer(),
          $0.CreateSessionResponse.fromBuffer);
  static final _$listSessions =
      $grpc.ClientMethod<$0.ListSessionsRequest, $0.ListSessionsResponse>(
          '/culpeostudio.memory.v1.MemoryService/ListSessions',
          ($0.ListSessionsRequest value) => value.writeToBuffer(),
          $0.ListSessionsResponse.fromBuffer);
  static final _$getSession =
      $grpc.ClientMethod<$0.GetSessionRequest, $0.GetSessionResponse>(
          '/culpeostudio.memory.v1.MemoryService/GetSession',
          ($0.GetSessionRequest value) => value.writeToBuffer(),
          $0.GetSessionResponse.fromBuffer);
  static final _$deleteSession =
      $grpc.ClientMethod<$0.DeleteSessionRequest, $0.DeleteSessionResponse>(
          '/culpeostudio.memory.v1.MemoryService/DeleteSession',
          ($0.DeleteSessionRequest value) => value.writeToBuffer(),
          $0.DeleteSessionResponse.fromBuffer);
  static final _$addPrompt =
      $grpc.ClientMethod<$0.AddPromptRequest, $0.AddPromptResponse>(
          '/culpeostudio.memory.v1.MemoryService/AddPrompt',
          ($0.AddPromptRequest value) => value.writeToBuffer(),
          $0.AddPromptResponse.fromBuffer);
  static final _$addObservation =
      $grpc.ClientMethod<$0.AddObservationRequest, $0.AddObservationResponse>(
          '/culpeostudio.memory.v1.MemoryService/AddObservation',
          ($0.AddObservationRequest value) => value.writeToBuffer(),
          $0.AddObservationResponse.fromBuffer);
  static final _$completeSession =
      $grpc.ClientMethod<$0.CompleteSessionRequest, $0.CompleteSessionResponse>(
          '/culpeostudio.memory.v1.MemoryService/CompleteSession',
          ($0.CompleteSessionRequest value) => value.writeToBuffer(),
          $0.CompleteSessionResponse.fromBuffer);
  static final _$search =
      $grpc.ClientMethod<$0.SearchRequest, $0.SearchResponse>(
          '/culpeostudio.memory.v1.MemoryService/Search',
          ($0.SearchRequest value) => value.writeToBuffer(),
          $0.SearchResponse.fromBuffer);
  static final _$getTimeline =
      $grpc.ClientMethod<$0.GetTimelineRequest, $0.GetTimelineResponse>(
          '/culpeostudio.memory.v1.MemoryService/GetTimeline',
          ($0.GetTimelineRequest value) => value.writeToBuffer(),
          $0.GetTimelineResponse.fromBuffer);
  static final _$getObservations =
      $grpc.ClientMethod<$0.GetObservationsRequest, $0.GetObservationsResponse>(
          '/culpeostudio.memory.v1.MemoryService/GetObservations',
          ($0.GetObservationsRequest value) => value.writeToBuffer(),
          $0.GetObservationsResponse.fromBuffer);
  static final _$getContext =
      $grpc.ClientMethod<$0.GetContextRequest, $0.GetContextResponse>(
          '/culpeostudio.memory.v1.MemoryService/GetContext',
          ($0.GetContextRequest value) => value.writeToBuffer(),
          $0.GetContextResponse.fromBuffer);
  static final _$updateChangeRequestStatus = $grpc.ClientMethod<
          $0.UpdateChangeRequestStatusRequest,
          $0.UpdateChangeRequestStatusResponse>(
      '/culpeostudio.memory.v1.MemoryService/UpdateChangeRequestStatus',
      ($0.UpdateChangeRequestStatusRequest value) => value.writeToBuffer(),
      $0.UpdateChangeRequestStatusResponse.fromBuffer);
  static final _$deleteObservation = $grpc.ClientMethod<
          $0.DeleteObservationRequest, $0.DeleteObservationResponse>(
      '/culpeostudio.memory.v1.MemoryService/DeleteObservation',
      ($0.DeleteObservationRequest value) => value.writeToBuffer(),
      $0.DeleteObservationResponse.fromBuffer);
  static final _$updateMemory =
      $grpc.ClientMethod<$0.UpdateMemoryRequest, $0.UpdateMemoryResponse>(
          '/culpeostudio.memory.v1.MemoryService/UpdateMemory',
          ($0.UpdateMemoryRequest value) => value.writeToBuffer(),
          $0.UpdateMemoryResponse.fromBuffer);
  static final _$captureChatMessage = $grpc.ClientMethod<
          $0.CaptureChatMessageRequest, $0.CaptureChatMessageResponse>(
      '/culpeostudio.memory.v1.MemoryService/CaptureChatMessage',
      ($0.CaptureChatMessageRequest value) => value.writeToBuffer(),
      $0.CaptureChatMessageResponse.fromBuffer);
  static final _$captureEvent =
      $grpc.ClientMethod<$0.CaptureEventRequest, $0.CaptureEventResponse>(
          '/culpeostudio.memory.v1.MemoryService/CaptureEvent',
          ($0.CaptureEventRequest value) => value.writeToBuffer(),
          $0.CaptureEventResponse.fromBuffer);
  static final _$streamEvents =
      $grpc.ClientMethod<$0.StreamEventsRequest, $0.StreamEventsResponse>(
          '/culpeostudio.memory.v1.MemoryService/StreamEvents',
          ($0.StreamEventsRequest value) => value.writeToBuffer(),
          $0.StreamEventsResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.memory.v1.MemoryService')
abstract class MemoryServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.memory.v1.MemoryService';

  MemoryServiceBase() {
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
    $addMethod($grpc.ServiceMethod<$0.GetSessionRequest, $0.GetSessionResponse>(
        'GetSession',
        getSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetSessionRequest.fromBuffer(value),
        ($0.GetSessionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteSessionRequest, $0.DeleteSessionResponse>(
            'DeleteSession',
            deleteSession_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteSessionRequest.fromBuffer(value),
            ($0.DeleteSessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddPromptRequest, $0.AddPromptResponse>(
        'AddPrompt',
        addPrompt_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AddPromptRequest.fromBuffer(value),
        ($0.AddPromptResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddObservationRequest,
            $0.AddObservationResponse>(
        'AddObservation',
        addObservation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AddObservationRequest.fromBuffer(value),
        ($0.AddObservationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CompleteSessionRequest,
            $0.CompleteSessionResponse>(
        'CompleteSession',
        completeSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CompleteSessionRequest.fromBuffer(value),
        ($0.CompleteSessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SearchRequest, $0.SearchResponse>(
        'Search',
        search_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SearchRequest.fromBuffer(value),
        ($0.SearchResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetTimelineRequest, $0.GetTimelineResponse>(
            'GetTimeline',
            getTimeline_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetTimelineRequest.fromBuffer(value),
            ($0.GetTimelineResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetObservationsRequest,
            $0.GetObservationsResponse>(
        'GetObservations',
        getObservations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetObservationsRequest.fromBuffer(value),
        ($0.GetObservationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetContextRequest, $0.GetContextResponse>(
        'GetContext',
        getContext_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetContextRequest.fromBuffer(value),
        ($0.GetContextResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateChangeRequestStatusRequest,
            $0.UpdateChangeRequestStatusResponse>(
        'UpdateChangeRequestStatus',
        updateChangeRequestStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateChangeRequestStatusRequest.fromBuffer(value),
        ($0.UpdateChangeRequestStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteObservationRequest,
            $0.DeleteObservationResponse>(
        'DeleteObservation',
        deleteObservation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteObservationRequest.fromBuffer(value),
        ($0.DeleteObservationResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateMemoryRequest, $0.UpdateMemoryResponse>(
            'UpdateMemory',
            updateMemory_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateMemoryRequest.fromBuffer(value),
            ($0.UpdateMemoryResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CaptureChatMessageRequest,
            $0.CaptureChatMessageResponse>(
        'CaptureChatMessage',
        captureChatMessage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CaptureChatMessageRequest.fromBuffer(value),
        ($0.CaptureChatMessageResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CaptureEventRequest, $0.CaptureEventResponse>(
            'CaptureEvent',
            captureEvent_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CaptureEventRequest.fromBuffer(value),
            ($0.CaptureEventResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StreamEventsRequest, $0.StreamEventsResponse>(
            'StreamEvents',
            streamEvents_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.StreamEventsRequest.fromBuffer(value),
            ($0.StreamEventsResponse value) => value.writeToBuffer()));
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

  $async.Future<$0.GetSessionResponse> getSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetSessionRequest> $request) async {
    return getSession($call, await $request);
  }

  $async.Future<$0.GetSessionResponse> getSession(
      $grpc.ServiceCall call, $0.GetSessionRequest request);

  $async.Future<$0.DeleteSessionResponse> deleteSession_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteSessionRequest> $request) async {
    return deleteSession($call, await $request);
  }

  $async.Future<$0.DeleteSessionResponse> deleteSession(
      $grpc.ServiceCall call, $0.DeleteSessionRequest request);

  $async.Future<$0.AddPromptResponse> addPrompt_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddPromptRequest> $request) async {
    return addPrompt($call, await $request);
  }

  $async.Future<$0.AddPromptResponse> addPrompt(
      $grpc.ServiceCall call, $0.AddPromptRequest request);

  $async.Future<$0.AddObservationResponse> addObservation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AddObservationRequest> $request) async {
    return addObservation($call, await $request);
  }

  $async.Future<$0.AddObservationResponse> addObservation(
      $grpc.ServiceCall call, $0.AddObservationRequest request);

  $async.Future<$0.CompleteSessionResponse> completeSession_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CompleteSessionRequest> $request) async {
    return completeSession($call, await $request);
  }

  $async.Future<$0.CompleteSessionResponse> completeSession(
      $grpc.ServiceCall call, $0.CompleteSessionRequest request);

  $async.Future<$0.SearchResponse> search_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SearchRequest> $request) async {
    return search($call, await $request);
  }

  $async.Future<$0.SearchResponse> search(
      $grpc.ServiceCall call, $0.SearchRequest request);

  $async.Future<$0.GetTimelineResponse> getTimeline_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetTimelineRequest> $request) async {
    return getTimeline($call, await $request);
  }

  $async.Future<$0.GetTimelineResponse> getTimeline(
      $grpc.ServiceCall call, $0.GetTimelineRequest request);

  $async.Future<$0.GetObservationsResponse> getObservations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetObservationsRequest> $request) async {
    return getObservations($call, await $request);
  }

  $async.Future<$0.GetObservationsResponse> getObservations(
      $grpc.ServiceCall call, $0.GetObservationsRequest request);

  $async.Future<$0.GetContextResponse> getContext_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetContextRequest> $request) async {
    return getContext($call, await $request);
  }

  $async.Future<$0.GetContextResponse> getContext(
      $grpc.ServiceCall call, $0.GetContextRequest request);

  $async.Future<$0.UpdateChangeRequestStatusResponse>
      updateChangeRequestStatus_Pre($grpc.ServiceCall $call,
          $async.Future<$0.UpdateChangeRequestStatusRequest> $request) async {
    return updateChangeRequestStatus($call, await $request);
  }

  $async.Future<$0.UpdateChangeRequestStatusResponse> updateChangeRequestStatus(
      $grpc.ServiceCall call, $0.UpdateChangeRequestStatusRequest request);

  $async.Future<$0.DeleteObservationResponse> deleteObservation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteObservationRequest> $request) async {
    return deleteObservation($call, await $request);
  }

  $async.Future<$0.DeleteObservationResponse> deleteObservation(
      $grpc.ServiceCall call, $0.DeleteObservationRequest request);

  $async.Future<$0.UpdateMemoryResponse> updateMemory_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateMemoryRequest> $request) async {
    return updateMemory($call, await $request);
  }

  $async.Future<$0.UpdateMemoryResponse> updateMemory(
      $grpc.ServiceCall call, $0.UpdateMemoryRequest request);

  $async.Future<$0.CaptureChatMessageResponse> captureChatMessage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CaptureChatMessageRequest> $request) async {
    return captureChatMessage($call, await $request);
  }

  $async.Future<$0.CaptureChatMessageResponse> captureChatMessage(
      $grpc.ServiceCall call, $0.CaptureChatMessageRequest request);

  $async.Future<$0.CaptureEventResponse> captureEvent_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CaptureEventRequest> $request) async {
    return captureEvent($call, await $request);
  }

  $async.Future<$0.CaptureEventResponse> captureEvent(
      $grpc.ServiceCall call, $0.CaptureEventRequest request);

  $async.Stream<$0.StreamEventsResponse> streamEvents_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StreamEventsRequest> $request) async* {
    yield* streamEvents($call, await $request);
  }

  $async.Stream<$0.StreamEventsResponse> streamEvents(
      $grpc.ServiceCall call, $0.StreamEventsRequest request);
}
