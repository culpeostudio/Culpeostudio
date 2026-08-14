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

import 'package:protobuf/protobuf.dart' as $pb;

/// NodeState is what the last probe found.
class NodeState extends $pb.ProtobufEnum {
  static const NodeState NODE_STATE_UNSPECIFIED =
      NodeState._(0, _omitEnumNames ? '' : 'NODE_STATE_UNSPECIFIED');
  static const NodeState NODE_STATE_ONLINE =
      NodeState._(1, _omitEnumNames ? '' : 'NODE_STATE_ONLINE');

  /// Reachable address, no answer. Usually the tunnel is down or the node's
  /// backend is not running.
  static const NodeState NODE_STATE_OFFLINE =
      NodeState._(2, _omitEnumNames ? '' : 'NODE_STATE_OFFLINE');

  /// The node answered and rejected the pairing token.
  static const NodeState NODE_STATE_UNAUTHORIZED =
      NodeState._(3, _omitEnumNames ? '' : 'NODE_STATE_UNAUTHORIZED');

  /// Switched off in the Studio. Its models and instances stay out of every
  /// list until it is switched back on.
  static const NodeState NODE_STATE_DISABLED =
      NodeState._(4, _omitEnumNames ? '' : 'NODE_STATE_DISABLED');

  static const $core.List<NodeState> values = <NodeState>[
    NODE_STATE_UNSPECIFIED,
    NODE_STATE_ONLINE,
    NODE_STATE_OFFLINE,
    NODE_STATE_UNAUTHORIZED,
    NODE_STATE_DISABLED,
  ];

  static final $core.List<NodeState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static NodeState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeState._(super.value, super.name);
}

/// TunnelState is what the WireGuard interface for a node is doing.
class TunnelState extends $pb.ProtobufEnum {
  static const TunnelState TUNNEL_STATE_UNSPECIFIED =
      TunnelState._(0, _omitEnumNames ? '' : 'TUNNEL_STATE_UNSPECIFIED');
  static const TunnelState TUNNEL_STATE_DOWN =
      TunnelState._(1, _omitEnumNames ? '' : 'TUNNEL_STATE_DOWN');
  static const TunnelState TUNNEL_STATE_UP =
      TunnelState._(2, _omitEnumNames ? '' : 'TUNNEL_STATE_UP');

  /// WireGuard is not installed, so the Studio can write the config but cannot
  /// say anything about the interface.
  static const TunnelState TUNNEL_STATE_UNAVAILABLE =
      TunnelState._(3, _omitEnumNames ? '' : 'TUNNEL_STATE_UNAVAILABLE');

  static const $core.List<TunnelState> values = <TunnelState>[
    TUNNEL_STATE_UNSPECIFIED,
    TUNNEL_STATE_DOWN,
    TUNNEL_STATE_UP,
    TUNNEL_STATE_UNAVAILABLE,
  ];

  static final $core.List<TunnelState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TunnelState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TunnelState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
