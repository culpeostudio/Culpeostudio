// This is a generated file - do not edit.
//
// Generated from culpeostudio/node/v1/node.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import '../../hardware/v1/hardware.pb.dart' as $2;
import 'node.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'node.pbenum.dart';

/// NodeTunnel is the WireGuard side of one node.
class NodeTunnel extends $pb.GeneratedMessage {
  factory NodeTunnel({
    $core.String? interfaceName,
    $core.String? configPath,
    $core.String? localAddress,
    $core.String? endpoint,
    $core.String? peerPublicKey,
    TunnelState? state,
    $core.String? bringUpCommand,
    $core.String? bringDownCommand,
    $core.String? statusMessage,
    $1.Timestamp? lastHandshakeAt,
  }) {
    final result = create();
    if (interfaceName != null) result.interfaceName = interfaceName;
    if (configPath != null) result.configPath = configPath;
    if (localAddress != null) result.localAddress = localAddress;
    if (endpoint != null) result.endpoint = endpoint;
    if (peerPublicKey != null) result.peerPublicKey = peerPublicKey;
    if (state != null) result.state = state;
    if (bringUpCommand != null) result.bringUpCommand = bringUpCommand;
    if (bringDownCommand != null) result.bringDownCommand = bringDownCommand;
    if (statusMessage != null) result.statusMessage = statusMessage;
    if (lastHandshakeAt != null) result.lastHandshakeAt = lastHandshakeAt;
    return result;
  }

  NodeTunnel._();

  factory NodeTunnel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeTunnel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeTunnel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'interfaceName')
    ..aOS(2, _omitFieldNames ? '' : 'configPath')
    ..aOS(3, _omitFieldNames ? '' : 'localAddress')
    ..aOS(4, _omitFieldNames ? '' : 'endpoint')
    ..aOS(5, _omitFieldNames ? '' : 'peerPublicKey')
    ..aE<TunnelState>(6, _omitFieldNames ? '' : 'state',
        enumValues: TunnelState.values)
    ..aOS(7, _omitFieldNames ? '' : 'bringUpCommand')
    ..aOS(8, _omitFieldNames ? '' : 'bringDownCommand')
    ..aOS(9, _omitFieldNames ? '' : 'statusMessage')
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'lastHandshakeAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTunnel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTunnel copyWith(void Function(NodeTunnel) updates) =>
      super.copyWith((message) => updates(message as NodeTunnel)) as NodeTunnel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeTunnel create() => NodeTunnel._();
  @$core.override
  NodeTunnel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeTunnel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeTunnel>(create);
  static NodeTunnel? _defaultInstance;

  /// The interface the config names, e.g. culpeo-workstation.
  @$pb.TagNumber(1)
  $core.String get interfaceName => $_getSZ(0);
  @$pb.TagNumber(1)
  set interfaceName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInterfaceName() => $_has(0);
  @$pb.TagNumber(1)
  void clearInterfaceName() => $_clearField(1);

  /// Where the config was written. It holds a private key and is created 0600.
  @$pb.TagNumber(2)
  $core.String get configPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set configPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConfigPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfigPath() => $_clearField(2);

  /// The address this Studio has inside the tunnel.
  @$pb.TagNumber(3)
  $core.String get localAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set localAddress($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocalAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalAddress() => $_clearField(3);

  /// The node's WireGuard endpoint, as host:port.
  @$pb.TagNumber(4)
  $core.String get endpoint => $_getSZ(3);
  @$pb.TagNumber(4)
  set endpoint($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEndpoint() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndpoint() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get peerPublicKey => $_getSZ(4);
  @$pb.TagNumber(5)
  set peerPublicKey($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPeerPublicKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearPeerPublicKey() => $_clearField(5);

  @$pb.TagNumber(6)
  TunnelState get state => $_getN(5);
  @$pb.TagNumber(6)
  set state(TunnelState value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasState() => $_has(5);
  @$pb.TagNumber(6)
  void clearState() => $_clearField(6);

  /// The command that brings the interface up or down. It needs root, so it is
  /// reported rather than silently run - SetNodeTunnel runs it behind a
  /// privilege prompt when one is available.
  @$pb.TagNumber(7)
  $core.String get bringUpCommand => $_getSZ(6);
  @$pb.TagNumber(7)
  set bringUpCommand($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBringUpCommand() => $_has(6);
  @$pb.TagNumber(7)
  void clearBringUpCommand() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get bringDownCommand => $_getSZ(7);
  @$pb.TagNumber(8)
  set bringDownCommand($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBringDownCommand() => $_has(7);
  @$pb.TagNumber(8)
  void clearBringDownCommand() => $_clearField(8);

  /// Set when the state could not be read, e.g. because wg is missing.
  @$pb.TagNumber(9)
  $core.String get statusMessage => $_getSZ(8);
  @$pb.TagNumber(9)
  set statusMessage($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStatusMessage() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatusMessage() => $_clearField(9);

  @$pb.TagNumber(10)
  $1.Timestamp get lastHandshakeAt => $_getN(9);
  @$pb.TagNumber(10)
  set lastHandshakeAt($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasLastHandshakeAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearLastHandshakeAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensureLastHandshakeAt() => $_ensure(9);
}

/// Node is one machine this Studio can run models on.
class Node extends $pb.GeneratedMessage {
  factory Node({
    $core.String? id,
    $core.String? name,
    $core.String? address,
    $core.int? grpcPort,
    $core.int? gatewayPort,
    $core.bool? enabled,
    NodeState? state,
    $core.String? statusMessage,
    $2.HardwareProfile? hardware,
    $core.String? version,
    $core.String? modelDir,
    $core.int? modelCount,
    $core.int? instanceCount,
    $fixnum.Int64? diskFreeBytes,
    NodeTunnel? tunnel,
    $1.Timestamp? addedAt,
    $1.Timestamp? lastSeenAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (address != null) result.address = address;
    if (grpcPort != null) result.grpcPort = grpcPort;
    if (gatewayPort != null) result.gatewayPort = gatewayPort;
    if (enabled != null) result.enabled = enabled;
    if (state != null) result.state = state;
    if (statusMessage != null) result.statusMessage = statusMessage;
    if (hardware != null) result.hardware = hardware;
    if (version != null) result.version = version;
    if (modelDir != null) result.modelDir = modelDir;
    if (modelCount != null) result.modelCount = modelCount;
    if (instanceCount != null) result.instanceCount = instanceCount;
    if (diskFreeBytes != null) result.diskFreeBytes = diskFreeBytes;
    if (tunnel != null) result.tunnel = tunnel;
    if (addedAt != null) result.addedAt = addedAt;
    if (lastSeenAt != null) result.lastSeenAt = lastSeenAt;
    return result;
  }

  Node._();

  factory Node.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Node.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Node',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'address')
    ..aI(4, _omitFieldNames ? '' : 'grpcPort')
    ..aI(5, _omitFieldNames ? '' : 'gatewayPort')
    ..aOB(6, _omitFieldNames ? '' : 'enabled')
    ..aE<NodeState>(7, _omitFieldNames ? '' : 'state',
        enumValues: NodeState.values)
    ..aOS(8, _omitFieldNames ? '' : 'statusMessage')
    ..aOM<$2.HardwareProfile>(9, _omitFieldNames ? '' : 'hardware',
        subBuilder: $2.HardwareProfile.create)
    ..aOS(10, _omitFieldNames ? '' : 'version')
    ..aOS(11, _omitFieldNames ? '' : 'modelDir')
    ..aI(12, _omitFieldNames ? '' : 'modelCount')
    ..aI(13, _omitFieldNames ? '' : 'instanceCount')
    ..aInt64(14, _omitFieldNames ? '' : 'diskFreeBytes')
    ..aOM<NodeTunnel>(15, _omitFieldNames ? '' : 'tunnel',
        subBuilder: NodeTunnel.create)
    ..aOM<$1.Timestamp>(16, _omitFieldNames ? '' : 'addedAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(17, _omitFieldNames ? '' : 'lastSeenAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Node clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Node copyWith(void Function(Node) updates) =>
      super.copyWith((message) => updates(message as Node)) as Node;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Node create() => Node._();
  @$core.override
  Node createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Node getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Node>(create);
  static Node? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// The node's address inside the tunnel. Everything the Studio sends goes
  /// here, never to a public address.
  @$pb.TagNumber(3)
  $core.String get address => $_getSZ(2);
  @$pb.TagNumber(3)
  set address($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddress() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get grpcPort => $_getIZ(3);
  @$pb.TagNumber(4)
  set grpcPort($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGrpcPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearGrpcPort() => $_clearField(4);

  /// The port the node's OpenAI gateway listens on. Inference is streamed from
  /// there rather than through gRPC, because the gateway already speaks the
  /// streaming shape the chat needs.
  @$pb.TagNumber(5)
  $core.int get gatewayPort => $_getIZ(4);
  @$pb.TagNumber(5)
  set gatewayPort($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGatewayPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearGatewayPort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enabled => $_getBF(5);
  @$pb.TagNumber(6)
  set enabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnabled() => $_clearField(6);

  @$pb.TagNumber(7)
  NodeState get state => $_getN(6);
  @$pb.TagNumber(7)
  set state(NodeState value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasState() => $_has(6);
  @$pb.TagNumber(7)
  void clearState() => $_clearField(7);

  /// Why the state is what it is, in the node's own words when it answered.
  @$pb.TagNumber(8)
  $core.String get statusMessage => $_getSZ(7);
  @$pb.TagNumber(8)
  set statusMessage($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasStatusMessage() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatusMessage() => $_clearField(8);

  /// What the node reported about itself on the last successful probe.
  @$pb.TagNumber(9)
  $2.HardwareProfile get hardware => $_getN(8);
  @$pb.TagNumber(9)
  set hardware($2.HardwareProfile value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasHardware() => $_has(8);
  @$pb.TagNumber(9)
  void clearHardware() => $_clearField(9);
  @$pb.TagNumber(9)
  $2.HardwareProfile ensureHardware() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.String get version => $_getSZ(9);
  @$pb.TagNumber(10)
  set version($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasVersion() => $_has(9);
  @$pb.TagNumber(10)
  void clearVersion() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get modelDir => $_getSZ(10);
  @$pb.TagNumber(11)
  set modelDir($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasModelDir() => $_has(10);
  @$pb.TagNumber(11)
  void clearModelDir() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get modelCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set modelCount($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasModelCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearModelCount() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get instanceCount => $_getIZ(12);
  @$pb.TagNumber(13)
  set instanceCount($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasInstanceCount() => $_has(12);
  @$pb.TagNumber(13)
  void clearInstanceCount() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get diskFreeBytes => $_getI64(13);
  @$pb.TagNumber(14)
  set diskFreeBytes($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDiskFreeBytes() => $_has(13);
  @$pb.TagNumber(14)
  void clearDiskFreeBytes() => $_clearField(14);

  @$pb.TagNumber(15)
  NodeTunnel get tunnel => $_getN(14);
  @$pb.TagNumber(15)
  set tunnel(NodeTunnel value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasTunnel() => $_has(14);
  @$pb.TagNumber(15)
  void clearTunnel() => $_clearField(15);
  @$pb.TagNumber(15)
  NodeTunnel ensureTunnel() => $_ensure(14);

  @$pb.TagNumber(16)
  $1.Timestamp get addedAt => $_getN(15);
  @$pb.TagNumber(16)
  set addedAt($1.Timestamp value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasAddedAt() => $_has(15);
  @$pb.TagNumber(16)
  void clearAddedAt() => $_clearField(16);
  @$pb.TagNumber(16)
  $1.Timestamp ensureAddedAt() => $_ensure(15);

  @$pb.TagNumber(17)
  $1.Timestamp get lastSeenAt => $_getN(16);
  @$pb.TagNumber(17)
  set lastSeenAt($1.Timestamp value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasLastSeenAt() => $_has(16);
  @$pb.TagNumber(17)
  void clearLastSeenAt() => $_clearField(17);
  @$pb.TagNumber(17)
  $1.Timestamp ensureLastSeenAt() => $_ensure(16);
}

class ListNodesRequest extends $pb.GeneratedMessage {
  factory ListNodesRequest() => create();

  ListNodesRequest._();

  factory ListNodesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNodesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNodesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesRequest copyWith(void Function(ListNodesRequest) updates) =>
      super.copyWith((message) => updates(message as ListNodesRequest))
          as ListNodesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNodesRequest create() => ListNodesRequest._();
  @$core.override
  ListNodesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNodesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNodesRequest>(create);
  static ListNodesRequest? _defaultInstance;
}

class ListNodesResponse extends $pb.GeneratedMessage {
  factory ListNodesResponse({
    $core.Iterable<Node>? nodes,
  }) {
    final result = create();
    if (nodes != null) result.nodes.addAll(nodes);
    return result;
  }

  ListNodesResponse._();

  factory ListNodesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNodesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNodesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..pPM<Node>(1, _omitFieldNames ? '' : 'nodes', subBuilder: Node.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesResponse copyWith(void Function(ListNodesResponse) updates) =>
      super.copyWith((message) => updates(message as ListNodesResponse))
          as ListNodesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNodesResponse create() => ListNodesResponse._();
  @$core.override
  ListNodesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNodesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNodesResponse>(create);
  static ListNodesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Node> get nodes => $_getList(0);
}

/// ManualNodeDetails registers a node whose tunnel was set up by hand. The
/// Studio then only stores where the node is and how to authenticate; it writes
/// no config and manages no interface.
class ManualNodeDetails extends $pb.GeneratedMessage {
  factory ManualNodeDetails({
    $core.String? name,
    $core.String? address,
    $core.int? grpcPort,
    $core.int? gatewayPort,
    $core.String? token,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (address != null) result.address = address;
    if (grpcPort != null) result.grpcPort = grpcPort;
    if (gatewayPort != null) result.gatewayPort = gatewayPort;
    if (token != null) result.token = token;
    return result;
  }

  ManualNodeDetails._();

  factory ManualNodeDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ManualNodeDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ManualNodeDetails',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'address')
    ..aI(3, _omitFieldNames ? '' : 'grpcPort')
    ..aI(4, _omitFieldNames ? '' : 'gatewayPort')
    ..aOS(5, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManualNodeDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManualNodeDetails copyWith(void Function(ManualNodeDetails) updates) =>
      super.copyWith((message) => updates(message as ManualNodeDetails))
          as ManualNodeDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ManualNodeDetails create() => ManualNodeDetails._();
  @$core.override
  ManualNodeDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ManualNodeDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ManualNodeDetails>(create);
  static ManualNodeDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get address => $_getSZ(1);
  @$pb.TagNumber(2)
  set address($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddress() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get grpcPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set grpcPort($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGrpcPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearGrpcPort() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get gatewayPort => $_getIZ(3);
  @$pb.TagNumber(4)
  set gatewayPort($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGatewayPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearGatewayPort() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get token => $_getSZ(4);
  @$pb.TagNumber(5)
  set token($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasToken() => $_has(4);
  @$pb.TagNumber(5)
  void clearToken() => $_clearField(5);
}

enum AddNodeRequest_Source { joinCode, manual, notSet }

class AddNodeRequest extends $pb.GeneratedMessage {
  factory AddNodeRequest({
    $core.String? joinCode,
    ManualNodeDetails? manual,
    $core.String? name,
  }) {
    final result = create();
    if (joinCode != null) result.joinCode = joinCode;
    if (manual != null) result.manual = manual;
    if (name != null) result.name = name;
    return result;
  }

  AddNodeRequest._();

  factory AddNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, AddNodeRequest_Source>
      _AddNodeRequest_SourceByTag = {
    1: AddNodeRequest_Source.joinCode,
    2: AddNodeRequest_Source.manual,
    0: AddNodeRequest_Source.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddNodeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'joinCode')
    ..aOM<ManualNodeDetails>(2, _omitFieldNames ? '' : 'manual',
        subBuilder: ManualNodeDetails.create)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddNodeRequest copyWith(void Function(AddNodeRequest) updates) =>
      super.copyWith((message) => updates(message as AddNodeRequest))
          as AddNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddNodeRequest create() => AddNodeRequest._();
  @$core.override
  AddNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddNodeRequest>(create);
  static AddNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  AddNodeRequest_Source whichSource() =>
      _AddNodeRequest_SourceByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearSource() => $_clearField($_whichOneof(0));

  /// The base64 join code the node printed at first start. It carries the
  /// pairing token and the complete client tunnel config, including its
  /// private key: the node generates both key pairs, because the Studio has
  /// no way to reach the node before the tunnel it is trying to describe
  /// exists. Treat the code like a WireGuard config file.
  @$pb.TagNumber(1)
  $core.String get joinCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set joinCode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJoinCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearJoinCode() => $_clearField(1);

  @$pb.TagNumber(2)
  ManualNodeDetails get manual => $_getN(1);
  @$pb.TagNumber(2)
  set manual(ManualNodeDetails value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasManual() => $_has(1);
  @$pb.TagNumber(2)
  void clearManual() => $_clearField(2);
  @$pb.TagNumber(2)
  ManualNodeDetails ensureManual() => $_ensure(1);

  /// Overrides the name the join code carried.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);
}

class AddNodeResponse extends $pb.GeneratedMessage {
  factory AddNodeResponse({
    Node? node,
    $core.Iterable<$core.String>? nextSteps,
  }) {
    final result = create();
    if (node != null) result.node = node;
    if (nextSteps != null) result.nextSteps.addAll(nextSteps);
    return result;
  }

  AddNodeResponse._();

  factory AddNodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddNodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddNodeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOM<Node>(1, _omitFieldNames ? '' : 'node', subBuilder: Node.create)
    ..pPS(2, _omitFieldNames ? '' : 'nextSteps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddNodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddNodeResponse copyWith(void Function(AddNodeResponse) updates) =>
      super.copyWith((message) => updates(message as AddNodeResponse))
          as AddNodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddNodeResponse create() => AddNodeResponse._();
  @$core.override
  AddNodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddNodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddNodeResponse>(create);
  static AddNodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Node get node => $_getN(0);
  @$pb.TagNumber(1)
  set node(Node value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearNode() => $_clearField(1);
  @$pb.TagNumber(1)
  Node ensureNode() => $_ensure(0);

  /// What still has to happen before the node is usable, e.g. bringing the
  /// tunnel up.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get nextSteps => $_getList(1);
}

class UpdateNodeRequest extends $pb.GeneratedMessage {
  factory UpdateNodeRequest({
    $core.String? nodeId,
    $core.String? name,
    $core.bool? enabled,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (name != null) result.name = name;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  UpdateNodeRequest._();

  factory UpdateNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateNodeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNodeRequest copyWith(void Function(UpdateNodeRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateNodeRequest))
          as UpdateNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateNodeRequest create() => UpdateNodeRequest._();
  @$core.override
  UpdateNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateNodeRequest>(create);
  static UpdateNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);
}

class UpdateNodeResponse extends $pb.GeneratedMessage {
  factory UpdateNodeResponse({
    Node? node,
  }) {
    final result = create();
    if (node != null) result.node = node;
    return result;
  }

  UpdateNodeResponse._();

  factory UpdateNodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateNodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateNodeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOM<Node>(1, _omitFieldNames ? '' : 'node', subBuilder: Node.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNodeResponse copyWith(void Function(UpdateNodeResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateNodeResponse))
          as UpdateNodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateNodeResponse create() => UpdateNodeResponse._();
  @$core.override
  UpdateNodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateNodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateNodeResponse>(create);
  static UpdateNodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Node get node => $_getN(0);
  @$pb.TagNumber(1)
  set node(Node value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearNode() => $_clearField(1);
  @$pb.TagNumber(1)
  Node ensureNode() => $_ensure(0);
}

class RemoveNodeRequest extends $pb.GeneratedMessage {
  factory RemoveNodeRequest({
    $core.String? nodeId,
    $core.bool? deleteTunnelConfig,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (deleteTunnelConfig != null)
      result.deleteTunnelConfig = deleteTunnelConfig;
    return result;
  }

  RemoveNodeRequest._();

  factory RemoveNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveNodeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOB(2, _omitFieldNames ? '' : 'deleteTunnelConfig')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveNodeRequest copyWith(void Function(RemoveNodeRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveNodeRequest))
          as RemoveNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveNodeRequest create() => RemoveNodeRequest._();
  @$core.override
  RemoveNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveNodeRequest>(create);
  static RemoveNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  /// Also deletes the tunnel config this Studio wrote. The interface is brought
  /// down first when it is up.
  @$pb.TagNumber(2)
  $core.bool get deleteTunnelConfig => $_getBF(1);
  @$pb.TagNumber(2)
  set deleteTunnelConfig($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeleteTunnelConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeleteTunnelConfig() => $_clearField(2);
}

class RemoveNodeResponse extends $pb.GeneratedMessage {
  factory RemoveNodeResponse() => create();

  RemoveNodeResponse._();

  factory RemoveNodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveNodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveNodeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveNodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveNodeResponse copyWith(void Function(RemoveNodeResponse) updates) =>
      super.copyWith((message) => updates(message as RemoveNodeResponse))
          as RemoveNodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveNodeResponse create() => RemoveNodeResponse._();
  @$core.override
  RemoveNodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveNodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveNodeResponse>(create);
  static RemoveNodeResponse? _defaultInstance;
}

class RefreshNodeRequest extends $pb.GeneratedMessage {
  factory RefreshNodeRequest({
    $core.String? nodeId,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    return result;
  }

  RefreshNodeRequest._();

  factory RefreshNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshNodeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshNodeRequest copyWith(void Function(RefreshNodeRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshNodeRequest))
          as RefreshNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshNodeRequest create() => RefreshNodeRequest._();
  @$core.override
  RefreshNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshNodeRequest>(create);
  static RefreshNodeRequest? _defaultInstance;

  /// Empty probes every enabled node.
  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);
}

class RefreshNodeResponse extends $pb.GeneratedMessage {
  factory RefreshNodeResponse({
    $core.Iterable<Node>? nodes,
  }) {
    final result = create();
    if (nodes != null) result.nodes.addAll(nodes);
    return result;
  }

  RefreshNodeResponse._();

  factory RefreshNodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshNodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshNodeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..pPM<Node>(1, _omitFieldNames ? '' : 'nodes', subBuilder: Node.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshNodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshNodeResponse copyWith(void Function(RefreshNodeResponse) updates) =>
      super.copyWith((message) => updates(message as RefreshNodeResponse))
          as RefreshNodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshNodeResponse create() => RefreshNodeResponse._();
  @$core.override
  RefreshNodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshNodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshNodeResponse>(create);
  static RefreshNodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Node> get nodes => $_getList(0);
}

class GetNodeTunnelRequest extends $pb.GeneratedMessage {
  factory GetNodeTunnelRequest({
    $core.String? nodeId,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    return result;
  }

  GetNodeTunnelRequest._();

  factory GetNodeTunnelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetNodeTunnelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetNodeTunnelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeTunnelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeTunnelRequest copyWith(void Function(GetNodeTunnelRequest) updates) =>
      super.copyWith((message) => updates(message as GetNodeTunnelRequest))
          as GetNodeTunnelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetNodeTunnelRequest create() => GetNodeTunnelRequest._();
  @$core.override
  GetNodeTunnelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetNodeTunnelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetNodeTunnelRequest>(create);
  static GetNodeTunnelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);
}

class GetNodeTunnelResponse extends $pb.GeneratedMessage {
  factory GetNodeTunnelResponse({
    NodeTunnel? tunnel,
    $core.String? configText,
  }) {
    final result = create();
    if (tunnel != null) result.tunnel = tunnel;
    if (configText != null) result.configText = configText;
    return result;
  }

  GetNodeTunnelResponse._();

  factory GetNodeTunnelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetNodeTunnelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetNodeTunnelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOM<NodeTunnel>(1, _omitFieldNames ? '' : 'tunnel',
        subBuilder: NodeTunnel.create)
    ..aOS(2, _omitFieldNames ? '' : 'configText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeTunnelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeTunnelResponse copyWith(
          void Function(GetNodeTunnelResponse) updates) =>
      super.copyWith((message) => updates(message as GetNodeTunnelResponse))
          as GetNodeTunnelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetNodeTunnelResponse create() => GetNodeTunnelResponse._();
  @$core.override
  GetNodeTunnelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetNodeTunnelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetNodeTunnelResponse>(create);
  static GetNodeTunnelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  NodeTunnel get tunnel => $_getN(0);
  @$pb.TagNumber(1)
  set tunnel(NodeTunnel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTunnel() => $_has(0);
  @$pb.TagNumber(1)
  void clearTunnel() => $_clearField(1);
  @$pb.TagNumber(1)
  NodeTunnel ensureTunnel() => $_ensure(0);

  /// The config as it was written, so the user can copy it somewhere the
  /// Studio cannot reach - another machine, or a WireGuard app on a phone.
  @$pb.TagNumber(2)
  $core.String get configText => $_getSZ(1);
  @$pb.TagNumber(2)
  set configText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConfigText() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfigText() => $_clearField(2);
}

class SetNodeTunnelRequest extends $pb.GeneratedMessage {
  factory SetNodeTunnelRequest({
    $core.String? nodeId,
    $core.bool? up,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (up != null) result.up = up;
    return result;
  }

  SetNodeTunnelRequest._();

  factory SetNodeTunnelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetNodeTunnelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetNodeTunnelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOB(2, _omitFieldNames ? '' : 'up')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetNodeTunnelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetNodeTunnelRequest copyWith(void Function(SetNodeTunnelRequest) updates) =>
      super.copyWith((message) => updates(message as SetNodeTunnelRequest))
          as SetNodeTunnelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetNodeTunnelRequest create() => SetNodeTunnelRequest._();
  @$core.override
  SetNodeTunnelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetNodeTunnelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetNodeTunnelRequest>(create);
  static SetNodeTunnelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  /// True brings the interface up, false brings it down.
  @$pb.TagNumber(2)
  $core.bool get up => $_getBF(1);
  @$pb.TagNumber(2)
  set up($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUp() => $_has(1);
  @$pb.TagNumber(2)
  void clearUp() => $_clearField(2);
}

class SetNodeTunnelResponse extends $pb.GeneratedMessage {
  factory SetNodeTunnelResponse({
    NodeTunnel? tunnel,
    $core.String? output,
  }) {
    final result = create();
    if (tunnel != null) result.tunnel = tunnel;
    if (output != null) result.output = output;
    return result;
  }

  SetNodeTunnelResponse._();

  factory SetNodeTunnelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetNodeTunnelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetNodeTunnelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOM<NodeTunnel>(1, _omitFieldNames ? '' : 'tunnel',
        subBuilder: NodeTunnel.create)
    ..aOS(2, _omitFieldNames ? '' : 'output')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetNodeTunnelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetNodeTunnelResponse copyWith(
          void Function(SetNodeTunnelResponse) updates) =>
      super.copyWith((message) => updates(message as SetNodeTunnelResponse))
          as SetNodeTunnelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetNodeTunnelResponse create() => SetNodeTunnelResponse._();
  @$core.override
  SetNodeTunnelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetNodeTunnelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetNodeTunnelResponse>(create);
  static SetNodeTunnelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  NodeTunnel get tunnel => $_getN(0);
  @$pb.TagNumber(1)
  set tunnel(NodeTunnel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTunnel() => $_has(0);
  @$pb.TagNumber(1)
  void clearTunnel() => $_clearField(1);
  @$pb.TagNumber(1)
  NodeTunnel ensureTunnel() => $_ensure(0);

  /// What the privilege helper printed, successful or not. It is shown as is:
  /// wg-quick's own errors say more than anything this could put in their place.
  @$pb.TagNumber(2)
  $core.String get output => $_getSZ(1);
  @$pb.TagNumber(2)
  set output($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutput() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutput() => $_clearField(2);
}

class GetNodeStatusRequest extends $pb.GeneratedMessage {
  factory GetNodeStatusRequest() => create();

  GetNodeStatusRequest._();

  factory GetNodeStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetNodeStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetNodeStatusRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeStatusRequest copyWith(void Function(GetNodeStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetNodeStatusRequest))
          as GetNodeStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetNodeStatusRequest create() => GetNodeStatusRequest._();
  @$core.override
  GetNodeStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetNodeStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetNodeStatusRequest>(create);
  static GetNodeStatusRequest? _defaultInstance;
}

class GetNodeStatusResponse extends $pb.GeneratedMessage {
  factory GetNodeStatusResponse({
    $core.String? nodeId,
    $core.String? name,
    $core.String? version,
    $2.HardwareProfile? hardware,
    $core.String? modelDir,
    $core.int? modelCount,
    $core.int? instanceCount,
    $fixnum.Int64? diskFreeBytes,
    $core.String? gatewayBaseUrl,
    $core.bool? gatewayKeyIssued,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (hardware != null) result.hardware = hardware;
    if (modelDir != null) result.modelDir = modelDir;
    if (modelCount != null) result.modelCount = modelCount;
    if (instanceCount != null) result.instanceCount = instanceCount;
    if (diskFreeBytes != null) result.diskFreeBytes = diskFreeBytes;
    if (gatewayBaseUrl != null) result.gatewayBaseUrl = gatewayBaseUrl;
    if (gatewayKeyIssued != null) result.gatewayKeyIssued = gatewayKeyIssued;
    return result;
  }

  GetNodeStatusResponse._();

  factory GetNodeStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetNodeStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetNodeStatusResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..aOM<$2.HardwareProfile>(4, _omitFieldNames ? '' : 'hardware',
        subBuilder: $2.HardwareProfile.create)
    ..aOS(5, _omitFieldNames ? '' : 'modelDir')
    ..aI(6, _omitFieldNames ? '' : 'modelCount')
    ..aI(7, _omitFieldNames ? '' : 'instanceCount')
    ..aInt64(8, _omitFieldNames ? '' : 'diskFreeBytes')
    ..aOS(9, _omitFieldNames ? '' : 'gatewayBaseUrl')
    ..aOB(10, _omitFieldNames ? '' : 'gatewayKeyIssued')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetNodeStatusResponse copyWith(
          void Function(GetNodeStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetNodeStatusResponse))
          as GetNodeStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetNodeStatusResponse create() => GetNodeStatusResponse._();
  @$core.override
  GetNodeStatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetNodeStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetNodeStatusResponse>(create);
  static GetNodeStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.HardwareProfile get hardware => $_getN(3);
  @$pb.TagNumber(4)
  set hardware($2.HardwareProfile value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasHardware() => $_has(3);
  @$pb.TagNumber(4)
  void clearHardware() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.HardwareProfile ensureHardware() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get modelDir => $_getSZ(4);
  @$pb.TagNumber(5)
  set modelDir($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModelDir() => $_has(4);
  @$pb.TagNumber(5)
  void clearModelDir() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get modelCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set modelCount($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModelCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearModelCount() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get instanceCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set instanceCount($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasInstanceCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearInstanceCount() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get diskFreeBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set diskFreeBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDiskFreeBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearDiskFreeBytes() => $_clearField(8);

  /// Where the node's OpenAI gateway listens, as the Studio should address it.
  /// Empty when the node could not bind it, which makes the node usable for
  /// downloads but not for inference.
  @$pb.TagNumber(9)
  $core.String get gatewayBaseUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set gatewayBaseUrl($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasGatewayBaseUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearGatewayBaseUrl() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get gatewayKeyIssued => $_getBF(9);
  @$pb.TagNumber(10)
  set gatewayKeyIssued($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasGatewayKeyIssued() => $_has(9);
  @$pb.TagNumber(10)
  void clearGatewayKeyIssued() => $_clearField(10);
}

class IssueGatewayKeyRequest extends $pb.GeneratedMessage {
  factory IssueGatewayKeyRequest({
    $core.String? label,
  }) {
    final result = create();
    if (label != null) result.label = label;
    return result;
  }

  IssueGatewayKeyRequest._();

  factory IssueGatewayKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IssueGatewayKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IssueGatewayKeyRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueGatewayKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueGatewayKeyRequest copyWith(
          void Function(IssueGatewayKeyRequest) updates) =>
      super.copyWith((message) => updates(message as IssueGatewayKeyRequest))
          as IssueGatewayKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IssueGatewayKeyRequest create() => IssueGatewayKeyRequest._();
  @$core.override
  IssueGatewayKeyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IssueGatewayKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IssueGatewayKeyRequest>(create);
  static IssueGatewayKeyRequest? _defaultInstance;

  /// Names the key on the node, so a node paired with two Studios shows which
  /// is which.
  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);
}

class IssueGatewayKeyResponse extends $pb.GeneratedMessage {
  factory IssueGatewayKeyResponse({
    $core.String? keyId,
    $core.String? secret,
    $core.String? gatewayBaseUrl,
  }) {
    final result = create();
    if (keyId != null) result.keyId = keyId;
    if (secret != null) result.secret = secret;
    if (gatewayBaseUrl != null) result.gatewayBaseUrl = gatewayBaseUrl;
    return result;
  }

  IssueGatewayKeyResponse._();

  factory IssueGatewayKeyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IssueGatewayKeyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IssueGatewayKeyResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.node.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'keyId')
    ..aOS(2, _omitFieldNames ? '' : 'secret')
    ..aOS(3, _omitFieldNames ? '' : 'gatewayBaseUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueGatewayKeyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueGatewayKeyResponse copyWith(
          void Function(IssueGatewayKeyResponse) updates) =>
      super.copyWith((message) => updates(message as IssueGatewayKeyResponse))
          as IssueGatewayKeyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IssueGatewayKeyResponse create() => IssueGatewayKeyResponse._();
  @$core.override
  IssueGatewayKeyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IssueGatewayKeyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IssueGatewayKeyResponse>(create);
  static IssueGatewayKeyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get keyId => $_getSZ(0);
  @$pb.TagNumber(1)
  set keyId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyId() => $_clearField(1);

  /// Returned once, as by every other key this engine hands out.
  @$pb.TagNumber(2)
  $core.String get secret => $_getSZ(1);
  @$pb.TagNumber(2)
  set secret($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSecret() => $_has(1);
  @$pb.TagNumber(2)
  void clearSecret() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get gatewayBaseUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set gatewayBaseUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGatewayBaseUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearGatewayBaseUrl() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
