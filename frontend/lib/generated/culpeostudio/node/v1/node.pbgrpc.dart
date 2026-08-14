// This is a generated file - do not edit.
//
// Generated from culpeostudio/node/v1/node.proto.

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

import 'node.pb.dart' as $0;

export 'node.pb.dart';

/// NodeService is the studio side of a node: the list of machines this Studio
/// may reach, the WireGuard tunnel to each of them, and their reachability.
///
/// It is not how work is sent to a node. A node runs the same backend, so the
/// Studio speaks its EngineService and MarketplaceService directly over the
/// tunnel and authenticates with the node's pairing token. That is the whole
/// point of the node mode: a model is downloaded and started by the machine
/// that will run it, and only the tokens cross the wire.
@$pb.GrpcServiceName('culpeostudio.node.v1.NodeService')
class NodeServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NodeServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListNodesResponse> listNodes(
    $0.ListNodesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listNodes, request, options: options);
  }

  /// Registers a node from the join code its node mode printed. The tunnel
  /// config comes with the code and is written to disk here; bringing the
  /// interface up needs root and is a separate, deliberate step.
  $grpc.ResponseFuture<$0.AddNodeResponse> addNode(
    $0.AddNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addNode, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateNodeResponse> updateNode(
    $0.UpdateNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateNode, request, options: options);
  }

  $grpc.ResponseFuture<$0.RemoveNodeResponse> removeNode(
    $0.RemoveNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeNode, request, options: options);
  }

  /// Probes one node and stores what it reported. The client calls this to show
  /// a live state; every other call uses the cached one.
  $grpc.ResponseFuture<$0.RefreshNodeResponse> refreshNode(
    $0.RefreshNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshNode, request, options: options);
  }

  /// The tunnel to one node: the config that was written, whether the interface
  /// is up, and the command that would change that.
  $grpc.ResponseFuture<$0.GetNodeTunnelResponse> getNodeTunnel(
    $0.GetNodeTunnelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getNodeTunnel, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetNodeTunnelResponse> setNodeTunnel(
    $0.SetNodeTunnelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setNodeTunnel, request, options: options);
  }

  // method descriptors

  static final _$listNodes =
      $grpc.ClientMethod<$0.ListNodesRequest, $0.ListNodesResponse>(
          '/culpeostudio.node.v1.NodeService/ListNodes',
          ($0.ListNodesRequest value) => value.writeToBuffer(),
          $0.ListNodesResponse.fromBuffer);
  static final _$addNode =
      $grpc.ClientMethod<$0.AddNodeRequest, $0.AddNodeResponse>(
          '/culpeostudio.node.v1.NodeService/AddNode',
          ($0.AddNodeRequest value) => value.writeToBuffer(),
          $0.AddNodeResponse.fromBuffer);
  static final _$updateNode =
      $grpc.ClientMethod<$0.UpdateNodeRequest, $0.UpdateNodeResponse>(
          '/culpeostudio.node.v1.NodeService/UpdateNode',
          ($0.UpdateNodeRequest value) => value.writeToBuffer(),
          $0.UpdateNodeResponse.fromBuffer);
  static final _$removeNode =
      $grpc.ClientMethod<$0.RemoveNodeRequest, $0.RemoveNodeResponse>(
          '/culpeostudio.node.v1.NodeService/RemoveNode',
          ($0.RemoveNodeRequest value) => value.writeToBuffer(),
          $0.RemoveNodeResponse.fromBuffer);
  static final _$refreshNode =
      $grpc.ClientMethod<$0.RefreshNodeRequest, $0.RefreshNodeResponse>(
          '/culpeostudio.node.v1.NodeService/RefreshNode',
          ($0.RefreshNodeRequest value) => value.writeToBuffer(),
          $0.RefreshNodeResponse.fromBuffer);
  static final _$getNodeTunnel =
      $grpc.ClientMethod<$0.GetNodeTunnelRequest, $0.GetNodeTunnelResponse>(
          '/culpeostudio.node.v1.NodeService/GetNodeTunnel',
          ($0.GetNodeTunnelRequest value) => value.writeToBuffer(),
          $0.GetNodeTunnelResponse.fromBuffer);
  static final _$setNodeTunnel =
      $grpc.ClientMethod<$0.SetNodeTunnelRequest, $0.SetNodeTunnelResponse>(
          '/culpeostudio.node.v1.NodeService/SetNodeTunnel',
          ($0.SetNodeTunnelRequest value) => value.writeToBuffer(),
          $0.SetNodeTunnelResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.node.v1.NodeService')
abstract class NodeServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.node.v1.NodeService';

  NodeServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListNodesRequest, $0.ListNodesResponse>(
        'ListNodes',
        listNodes_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListNodesRequest.fromBuffer(value),
        ($0.ListNodesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddNodeRequest, $0.AddNodeResponse>(
        'AddNode',
        addNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AddNodeRequest.fromBuffer(value),
        ($0.AddNodeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateNodeRequest, $0.UpdateNodeResponse>(
        'UpdateNode',
        updateNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpdateNodeRequest.fromBuffer(value),
        ($0.UpdateNodeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveNodeRequest, $0.RemoveNodeResponse>(
        'RemoveNode',
        removeNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RemoveNodeRequest.fromBuffer(value),
        ($0.RemoveNodeResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RefreshNodeRequest, $0.RefreshNodeResponse>(
            'RefreshNode',
            refreshNode_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RefreshNodeRequest.fromBuffer(value),
            ($0.RefreshNodeResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetNodeTunnelRequest, $0.GetNodeTunnelResponse>(
            'GetNodeTunnel',
            getNodeTunnel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetNodeTunnelRequest.fromBuffer(value),
            ($0.GetNodeTunnelResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SetNodeTunnelRequest, $0.SetNodeTunnelResponse>(
            'SetNodeTunnel',
            setNodeTunnel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SetNodeTunnelRequest.fromBuffer(value),
            ($0.SetNodeTunnelResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListNodesResponse> listNodes_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListNodesRequest> $request) async {
    return listNodes($call, await $request);
  }

  $async.Future<$0.ListNodesResponse> listNodes(
      $grpc.ServiceCall call, $0.ListNodesRequest request);

  $async.Future<$0.AddNodeResponse> addNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddNodeRequest> $request) async {
    return addNode($call, await $request);
  }

  $async.Future<$0.AddNodeResponse> addNode(
      $grpc.ServiceCall call, $0.AddNodeRequest request);

  $async.Future<$0.UpdateNodeResponse> updateNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateNodeRequest> $request) async {
    return updateNode($call, await $request);
  }

  $async.Future<$0.UpdateNodeResponse> updateNode(
      $grpc.ServiceCall call, $0.UpdateNodeRequest request);

  $async.Future<$0.RemoveNodeResponse> removeNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RemoveNodeRequest> $request) async {
    return removeNode($call, await $request);
  }

  $async.Future<$0.RemoveNodeResponse> removeNode(
      $grpc.ServiceCall call, $0.RemoveNodeRequest request);

  $async.Future<$0.RefreshNodeResponse> refreshNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RefreshNodeRequest> $request) async {
    return refreshNode($call, await $request);
  }

  $async.Future<$0.RefreshNodeResponse> refreshNode(
      $grpc.ServiceCall call, $0.RefreshNodeRequest request);

  $async.Future<$0.GetNodeTunnelResponse> getNodeTunnel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetNodeTunnelRequest> $request) async {
    return getNodeTunnel($call, await $request);
  }

  $async.Future<$0.GetNodeTunnelResponse> getNodeTunnel(
      $grpc.ServiceCall call, $0.GetNodeTunnelRequest request);

  $async.Future<$0.SetNodeTunnelResponse> setNodeTunnel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetNodeTunnelRequest> $request) async {
    return setNodeTunnel($call, await $request);
  }

  $async.Future<$0.SetNodeTunnelResponse> setNodeTunnel(
      $grpc.ServiceCall call, $0.SetNodeTunnelRequest request);
}

/// NodeAgentService is what a node adds to its own backend. Everything else a
/// node does is reached through the services it already had.
@$pb.GrpcServiceName('culpeostudio.node.v1.NodeAgentService')
class NodeAgentServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NodeAgentServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GetNodeStatusResponse> getNodeStatus(
    $0.GetNodeStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getNodeStatus, request, options: options);
  }

  /// Hands out the engine gateway key the Studio streams inference with. Called
  /// once at pairing; calling it again rotates the key, which is how a Studio
  /// that lost it recovers.
  $grpc.ResponseFuture<$0.IssueGatewayKeyResponse> issueGatewayKey(
    $0.IssueGatewayKeyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$issueGatewayKey, request, options: options);
  }

  // method descriptors

  static final _$getNodeStatus =
      $grpc.ClientMethod<$0.GetNodeStatusRequest, $0.GetNodeStatusResponse>(
          '/culpeostudio.node.v1.NodeAgentService/GetNodeStatus',
          ($0.GetNodeStatusRequest value) => value.writeToBuffer(),
          $0.GetNodeStatusResponse.fromBuffer);
  static final _$issueGatewayKey =
      $grpc.ClientMethod<$0.IssueGatewayKeyRequest, $0.IssueGatewayKeyResponse>(
          '/culpeostudio.node.v1.NodeAgentService/IssueGatewayKey',
          ($0.IssueGatewayKeyRequest value) => value.writeToBuffer(),
          $0.IssueGatewayKeyResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.node.v1.NodeAgentService')
abstract class NodeAgentServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.node.v1.NodeAgentService';

  NodeAgentServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.GetNodeStatusRequest, $0.GetNodeStatusResponse>(
            'GetNodeStatus',
            getNodeStatus_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetNodeStatusRequest.fromBuffer(value),
            ($0.GetNodeStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IssueGatewayKeyRequest,
            $0.IssueGatewayKeyResponse>(
        'IssueGatewayKey',
        issueGatewayKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.IssueGatewayKeyRequest.fromBuffer(value),
        ($0.IssueGatewayKeyResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetNodeStatusResponse> getNodeStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetNodeStatusRequest> $request) async {
    return getNodeStatus($call, await $request);
  }

  $async.Future<$0.GetNodeStatusResponse> getNodeStatus(
      $grpc.ServiceCall call, $0.GetNodeStatusRequest request);

  $async.Future<$0.IssueGatewayKeyResponse> issueGatewayKey_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.IssueGatewayKeyRequest> $request) async {
    return issueGatewayKey($call, await $request);
  }

  $async.Future<$0.IssueGatewayKeyResponse> issueGatewayKey(
      $grpc.ServiceCall call, $0.IssueGatewayKeyRequest request);
}
