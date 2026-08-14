// This is a generated file - do not edit.
//
// Generated from culpeostudio/node/v1/node.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use nodeStateDescriptor instead')
const NodeState$json = {
  '1': 'NodeState',
  '2': [
    {'1': 'NODE_STATE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_STATE_ONLINE', '2': 1},
    {'1': 'NODE_STATE_OFFLINE', '2': 2},
    {'1': 'NODE_STATE_UNAUTHORIZED', '2': 3},
    {'1': 'NODE_STATE_DISABLED', '2': 4},
  ],
};

/// Descriptor for `NodeState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeStateDescriptor = $convert.base64Decode(
    'CglOb2RlU3RhdGUSGgoWTk9ERV9TVEFURV9VTlNQRUNJRklFRBAAEhUKEU5PREVfU1RBVEVfT0'
    '5MSU5FEAESFgoSTk9ERV9TVEFURV9PRkZMSU5FEAISGwoXTk9ERV9TVEFURV9VTkFVVEhPUkla'
    'RUQQAxIXChNOT0RFX1NUQVRFX0RJU0FCTEVEEAQ=');

@$core.Deprecated('Use tunnelStateDescriptor instead')
const TunnelState$json = {
  '1': 'TunnelState',
  '2': [
    {'1': 'TUNNEL_STATE_UNSPECIFIED', '2': 0},
    {'1': 'TUNNEL_STATE_DOWN', '2': 1},
    {'1': 'TUNNEL_STATE_UP', '2': 2},
    {'1': 'TUNNEL_STATE_UNAVAILABLE', '2': 3},
  ],
};

/// Descriptor for `TunnelState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List tunnelStateDescriptor = $convert.base64Decode(
    'CgtUdW5uZWxTdGF0ZRIcChhUVU5ORUxfU1RBVEVfVU5TUEVDSUZJRUQQABIVChFUVU5ORUxfU1'
    'RBVEVfRE9XThABEhMKD1RVTk5FTF9TVEFURV9VUBACEhwKGFRVTk5FTF9TVEFURV9VTkFWQUlM'
    'QUJMRRAD');

@$core.Deprecated('Use nodeTunnelDescriptor instead')
const NodeTunnel$json = {
  '1': 'NodeTunnel',
  '2': [
    {'1': 'interface_name', '3': 1, '4': 1, '5': 9, '10': 'interfaceName'},
    {'1': 'config_path', '3': 2, '4': 1, '5': 9, '10': 'configPath'},
    {'1': 'local_address', '3': 3, '4': 1, '5': 9, '10': 'localAddress'},
    {'1': 'endpoint', '3': 4, '4': 1, '5': 9, '10': 'endpoint'},
    {'1': 'peer_public_key', '3': 5, '4': 1, '5': 9, '10': 'peerPublicKey'},
    {
      '1': 'state',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.node.v1.TunnelState',
      '10': 'state'
    },
    {'1': 'bring_up_command', '3': 7, '4': 1, '5': 9, '10': 'bringUpCommand'},
    {
      '1': 'bring_down_command',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'bringDownCommand'
    },
    {'1': 'status_message', '3': 9, '4': 1, '5': 9, '10': 'statusMessage'},
    {
      '1': 'last_handshake_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastHandshakeAt'
    },
  ],
};

/// Descriptor for `NodeTunnel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeTunnelDescriptor = $convert.base64Decode(
    'CgpOb2RlVHVubmVsEiUKDmludGVyZmFjZV9uYW1lGAEgASgJUg1pbnRlcmZhY2VOYW1lEh8KC2'
    'NvbmZpZ19wYXRoGAIgASgJUgpjb25maWdQYXRoEiMKDWxvY2FsX2FkZHJlc3MYAyABKAlSDGxv'
    'Y2FsQWRkcmVzcxIaCghlbmRwb2ludBgEIAEoCVIIZW5kcG9pbnQSJgoPcGVlcl9wdWJsaWNfa2'
    'V5GAUgASgJUg1wZWVyUHVibGljS2V5EjcKBXN0YXRlGAYgASgOMiEuY3VscGVvc3R1ZGlvLm5v'
    'ZGUudjEuVHVubmVsU3RhdGVSBXN0YXRlEigKEGJyaW5nX3VwX2NvbW1hbmQYByABKAlSDmJyaW'
    '5nVXBDb21tYW5kEiwKEmJyaW5nX2Rvd25fY29tbWFuZBgIIAEoCVIQYnJpbmdEb3duQ29tbWFu'
    'ZBIlCg5zdGF0dXNfbWVzc2FnZRgJIAEoCVINc3RhdHVzTWVzc2FnZRJGChFsYXN0X2hhbmRzaG'
    'FrZV9hdBgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSD2xhc3RIYW5kc2hha2VB'
    'dA==');

@$core.Deprecated('Use nodeDescriptor instead')
const Node$json = {
  '1': 'Node',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'address', '3': 3, '4': 1, '5': 9, '10': 'address'},
    {'1': 'grpc_port', '3': 4, '4': 1, '5': 5, '10': 'grpcPort'},
    {'1': 'gateway_port', '3': 5, '4': 1, '5': 5, '10': 'gatewayPort'},
    {'1': 'enabled', '3': 6, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'state',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.node.v1.NodeState',
      '10': 'state'
    },
    {'1': 'status_message', '3': 8, '4': 1, '5': 9, '10': 'statusMessage'},
    {
      '1': 'hardware',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.HardwareProfile',
      '10': 'hardware'
    },
    {'1': 'version', '3': 10, '4': 1, '5': 9, '10': 'version'},
    {'1': 'model_dir', '3': 11, '4': 1, '5': 9, '10': 'modelDir'},
    {'1': 'model_count', '3': 12, '4': 1, '5': 5, '10': 'modelCount'},
    {'1': 'instance_count', '3': 13, '4': 1, '5': 5, '10': 'instanceCount'},
    {'1': 'disk_free_bytes', '3': 14, '4': 1, '5': 3, '10': 'diskFreeBytes'},
    {
      '1': 'tunnel',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.node.v1.NodeTunnel',
      '10': 'tunnel'
    },
    {
      '1': 'added_at',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'addedAt'
    },
    {
      '1': 'last_seen_at',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastSeenAt'
    },
  ],
};

/// Descriptor for `Node`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeDescriptor = $convert.base64Decode(
    'CgROb2RlEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhgKB2FkZHJlc3MYAy'
    'ABKAlSB2FkZHJlc3MSGwoJZ3JwY19wb3J0GAQgASgFUghncnBjUG9ydBIhCgxnYXRld2F5X3Bv'
    'cnQYBSABKAVSC2dhdGV3YXlQb3J0EhgKB2VuYWJsZWQYBiABKAhSB2VuYWJsZWQSNQoFc3RhdG'
    'UYByABKA4yHy5jdWxwZW9zdHVkaW8ubm9kZS52MS5Ob2RlU3RhdGVSBXN0YXRlEiUKDnN0YXR1'
    'c19tZXNzYWdlGAggASgJUg1zdGF0dXNNZXNzYWdlEkUKCGhhcmR3YXJlGAkgASgLMikuY3VscG'
    'Vvc3R1ZGlvLmhhcmR3YXJlLnYxLkhhcmR3YXJlUHJvZmlsZVIIaGFyZHdhcmUSGAoHdmVyc2lv'
    'bhgKIAEoCVIHdmVyc2lvbhIbCgltb2RlbF9kaXIYCyABKAlSCG1vZGVsRGlyEh8KC21vZGVsX2'
    'NvdW50GAwgASgFUgptb2RlbENvdW50EiUKDmluc3RhbmNlX2NvdW50GA0gASgFUg1pbnN0YW5j'
    'ZUNvdW50EiYKD2Rpc2tfZnJlZV9ieXRlcxgOIAEoA1INZGlza0ZyZWVCeXRlcxI4CgZ0dW5uZW'
    'wYDyABKAsyIC5jdWxwZW9zdHVkaW8ubm9kZS52MS5Ob2RlVHVubmVsUgZ0dW5uZWwSNQoIYWRk'
    'ZWRfYXQYECABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdhZGRlZEF0EjwKDGxhc3'
    'Rfc2Vlbl9hdBgRIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmxhc3RTZWVuQXQ=');

@$core.Deprecated('Use listNodesRequestDescriptor instead')
const ListNodesRequest$json = {
  '1': 'ListNodesRequest',
};

/// Descriptor for `ListNodesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNodesRequestDescriptor =
    $convert.base64Decode('ChBMaXN0Tm9kZXNSZXF1ZXN0');

@$core.Deprecated('Use listNodesResponseDescriptor instead')
const ListNodesResponse$json = {
  '1': 'ListNodesResponse',
  '2': [
    {
      '1': 'nodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.node.v1.Node',
      '10': 'nodes'
    },
  ],
};

/// Descriptor for `ListNodesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNodesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0Tm9kZXNSZXNwb25zZRIwCgVub2RlcxgBIAMoCzIaLmN1bHBlb3N0dWRpby5ub2RlLn'
    'YxLk5vZGVSBW5vZGVz');

@$core.Deprecated('Use manualNodeDetailsDescriptor instead')
const ManualNodeDetails$json = {
  '1': 'ManualNodeDetails',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'address', '3': 2, '4': 1, '5': 9, '10': 'address'},
    {'1': 'grpc_port', '3': 3, '4': 1, '5': 5, '10': 'grpcPort'},
    {'1': 'gateway_port', '3': 4, '4': 1, '5': 5, '10': 'gatewayPort'},
    {'1': 'token', '3': 5, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `ManualNodeDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List manualNodeDetailsDescriptor = $convert.base64Decode(
    'ChFNYW51YWxOb2RlRGV0YWlscxISCgRuYW1lGAEgASgJUgRuYW1lEhgKB2FkZHJlc3MYAiABKA'
    'lSB2FkZHJlc3MSGwoJZ3JwY19wb3J0GAMgASgFUghncnBjUG9ydBIhCgxnYXRld2F5X3BvcnQY'
    'BCABKAVSC2dhdGV3YXlQb3J0EhQKBXRva2VuGAUgASgJUgV0b2tlbg==');

@$core.Deprecated('Use addNodeRequestDescriptor instead')
const AddNodeRequest$json = {
  '1': 'AddNodeRequest',
  '2': [
    {'1': 'join_code', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'joinCode'},
    {
      '1': 'manual',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.node.v1.ManualNodeDetails',
      '9': 0,
      '10': 'manual'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
  ],
  '8': [
    {'1': 'source'},
  ],
};

/// Descriptor for `AddNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addNodeRequestDescriptor = $convert.base64Decode(
    'Cg5BZGROb2RlUmVxdWVzdBIdCglqb2luX2NvZGUYASABKAlIAFIIam9pbkNvZGUSQQoGbWFudW'
    'FsGAIgASgLMicuY3VscGVvc3R1ZGlvLm5vZGUudjEuTWFudWFsTm9kZURldGFpbHNIAFIGbWFu'
    'dWFsEhIKBG5hbWUYAyABKAlSBG5hbWVCCAoGc291cmNl');

@$core.Deprecated('Use addNodeResponseDescriptor instead')
const AddNodeResponse$json = {
  '1': 'AddNodeResponse',
  '2': [
    {
      '1': 'node',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.node.v1.Node',
      '10': 'node'
    },
    {'1': 'next_steps', '3': 2, '4': 3, '5': 9, '10': 'nextSteps'},
  ],
};

/// Descriptor for `AddNodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addNodeResponseDescriptor = $convert.base64Decode(
    'Cg9BZGROb2RlUmVzcG9uc2USLgoEbm9kZRgBIAEoCzIaLmN1bHBlb3N0dWRpby5ub2RlLnYxLk'
    '5vZGVSBG5vZGUSHQoKbmV4dF9zdGVwcxgCIAMoCVIJbmV4dFN0ZXBz');

@$core.Deprecated('Use updateNodeRequestDescriptor instead')
const UpdateNodeRequest$json = {
  '1': 'UpdateNodeRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'enabled',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'enabled',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_enabled'},
  ],
};

/// Descriptor for `UpdateNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateNodeRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVOb2RlUmVxdWVzdBIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSFwoEbmFtZRgCIA'
    'EoCUgAUgRuYW1liAEBEh0KB2VuYWJsZWQYAyABKAhIAVIHZW5hYmxlZIgBAUIHCgVfbmFtZUIK'
    'CghfZW5hYmxlZA==');

@$core.Deprecated('Use updateNodeResponseDescriptor instead')
const UpdateNodeResponse$json = {
  '1': 'UpdateNodeResponse',
  '2': [
    {
      '1': 'node',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.node.v1.Node',
      '10': 'node'
    },
  ],
};

/// Descriptor for `UpdateNodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateNodeResponseDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVOb2RlUmVzcG9uc2USLgoEbm9kZRgBIAEoCzIaLmN1bHBlb3N0dWRpby5ub2RlLn'
    'YxLk5vZGVSBG5vZGU=');

@$core.Deprecated('Use removeNodeRequestDescriptor instead')
const RemoveNodeRequest$json = {
  '1': 'RemoveNodeRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {
      '1': 'delete_tunnel_config',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'deleteTunnelConfig'
    },
  ],
};

/// Descriptor for `RemoveNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeNodeRequestDescriptor = $convert.base64Decode(
    'ChFSZW1vdmVOb2RlUmVxdWVzdBIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSMAoUZGVsZXRlX3'
    'R1bm5lbF9jb25maWcYAiABKAhSEmRlbGV0ZVR1bm5lbENvbmZpZw==');

@$core.Deprecated('Use removeNodeResponseDescriptor instead')
const RemoveNodeResponse$json = {
  '1': 'RemoveNodeResponse',
};

/// Descriptor for `RemoveNodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeNodeResponseDescriptor =
    $convert.base64Decode('ChJSZW1vdmVOb2RlUmVzcG9uc2U=');

@$core.Deprecated('Use refreshNodeRequestDescriptor instead')
const RefreshNodeRequest$json = {
  '1': 'RefreshNodeRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
  ],
};

/// Descriptor for `RefreshNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshNodeRequestDescriptor =
    $convert.base64Decode(
        'ChJSZWZyZXNoTm9kZVJlcXVlc3QSFwoHbm9kZV9pZBgBIAEoCVIGbm9kZUlk');

@$core.Deprecated('Use refreshNodeResponseDescriptor instead')
const RefreshNodeResponse$json = {
  '1': 'RefreshNodeResponse',
  '2': [
    {
      '1': 'nodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.node.v1.Node',
      '10': 'nodes'
    },
  ],
};

/// Descriptor for `RefreshNodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshNodeResponseDescriptor = $convert.base64Decode(
    'ChNSZWZyZXNoTm9kZVJlc3BvbnNlEjAKBW5vZGVzGAEgAygLMhouY3VscGVvc3R1ZGlvLm5vZG'
    'UudjEuTm9kZVIFbm9kZXM=');

@$core.Deprecated('Use getNodeTunnelRequestDescriptor instead')
const GetNodeTunnelRequest$json = {
  '1': 'GetNodeTunnelRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
  ],
};

/// Descriptor for `GetNodeTunnelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getNodeTunnelRequestDescriptor =
    $convert.base64Decode(
        'ChRHZXROb2RlVHVubmVsUmVxdWVzdBIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQ=');

@$core.Deprecated('Use getNodeTunnelResponseDescriptor instead')
const GetNodeTunnelResponse$json = {
  '1': 'GetNodeTunnelResponse',
  '2': [
    {
      '1': 'tunnel',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.node.v1.NodeTunnel',
      '10': 'tunnel'
    },
    {'1': 'config_text', '3': 2, '4': 1, '5': 9, '10': 'configText'},
  ],
};

/// Descriptor for `GetNodeTunnelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getNodeTunnelResponseDescriptor = $convert.base64Decode(
    'ChVHZXROb2RlVHVubmVsUmVzcG9uc2USOAoGdHVubmVsGAEgASgLMiAuY3VscGVvc3R1ZGlvLm'
    '5vZGUudjEuTm9kZVR1bm5lbFIGdHVubmVsEh8KC2NvbmZpZ190ZXh0GAIgASgJUgpjb25maWdU'
    'ZXh0');

@$core.Deprecated('Use setNodeTunnelRequestDescriptor instead')
const SetNodeTunnelRequest$json = {
  '1': 'SetNodeTunnelRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'up', '3': 2, '4': 1, '5': 8, '10': 'up'},
  ],
};

/// Descriptor for `SetNodeTunnelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setNodeTunnelRequestDescriptor = $convert.base64Decode(
    'ChRTZXROb2RlVHVubmVsUmVxdWVzdBIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSDgoCdXAYAi'
    'ABKAhSAnVw');

@$core.Deprecated('Use setNodeTunnelResponseDescriptor instead')
const SetNodeTunnelResponse$json = {
  '1': 'SetNodeTunnelResponse',
  '2': [
    {
      '1': 'tunnel',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.node.v1.NodeTunnel',
      '10': 'tunnel'
    },
    {'1': 'output', '3': 2, '4': 1, '5': 9, '10': 'output'},
  ],
};

/// Descriptor for `SetNodeTunnelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setNodeTunnelResponseDescriptor = $convert.base64Decode(
    'ChVTZXROb2RlVHVubmVsUmVzcG9uc2USOAoGdHVubmVsGAEgASgLMiAuY3VscGVvc3R1ZGlvLm'
    '5vZGUudjEuTm9kZVR1bm5lbFIGdHVubmVsEhYKBm91dHB1dBgCIAEoCVIGb3V0cHV0');

@$core.Deprecated('Use getNodeStatusRequestDescriptor instead')
const GetNodeStatusRequest$json = {
  '1': 'GetNodeStatusRequest',
};

/// Descriptor for `GetNodeStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getNodeStatusRequestDescriptor =
    $convert.base64Decode('ChRHZXROb2RlU3RhdHVzUmVxdWVzdA==');

@$core.Deprecated('Use getNodeStatusResponseDescriptor instead')
const GetNodeStatusResponse$json = {
  '1': 'GetNodeStatusResponse',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    {
      '1': 'hardware',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.HardwareProfile',
      '10': 'hardware'
    },
    {'1': 'model_dir', '3': 5, '4': 1, '5': 9, '10': 'modelDir'},
    {'1': 'model_count', '3': 6, '4': 1, '5': 5, '10': 'modelCount'},
    {'1': 'instance_count', '3': 7, '4': 1, '5': 5, '10': 'instanceCount'},
    {'1': 'disk_free_bytes', '3': 8, '4': 1, '5': 3, '10': 'diskFreeBytes'},
    {'1': 'gateway_base_url', '3': 9, '4': 1, '5': 9, '10': 'gatewayBaseUrl'},
    {
      '1': 'gateway_key_issued',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'gatewayKeyIssued'
    },
  ],
};

/// Descriptor for `GetNodeStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getNodeStatusResponseDescriptor = $convert.base64Decode(
    'ChVHZXROb2RlU3RhdHVzUmVzcG9uc2USFwoHbm9kZV9pZBgBIAEoCVIGbm9kZUlkEhIKBG5hbW'
    'UYAiABKAlSBG5hbWUSGAoHdmVyc2lvbhgDIAEoCVIHdmVyc2lvbhJFCghoYXJkd2FyZRgEIAEo'
    'CzIpLmN1bHBlb3N0dWRpby5oYXJkd2FyZS52MS5IYXJkd2FyZVByb2ZpbGVSCGhhcmR3YXJlEh'
    'sKCW1vZGVsX2RpchgFIAEoCVIIbW9kZWxEaXISHwoLbW9kZWxfY291bnQYBiABKAVSCm1vZGVs'
    'Q291bnQSJQoOaW5zdGFuY2VfY291bnQYByABKAVSDWluc3RhbmNlQ291bnQSJgoPZGlza19mcm'
    'VlX2J5dGVzGAggASgDUg1kaXNrRnJlZUJ5dGVzEigKEGdhdGV3YXlfYmFzZV91cmwYCSABKAlS'
    'DmdhdGV3YXlCYXNlVXJsEiwKEmdhdGV3YXlfa2V5X2lzc3VlZBgKIAEoCFIQZ2F0ZXdheUtleU'
    'lzc3VlZA==');

@$core.Deprecated('Use issueGatewayKeyRequestDescriptor instead')
const IssueGatewayKeyRequest$json = {
  '1': 'IssueGatewayKeyRequest',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `IssueGatewayKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueGatewayKeyRequestDescriptor =
    $convert.base64Decode(
        'ChZJc3N1ZUdhdGV3YXlLZXlSZXF1ZXN0EhQKBWxhYmVsGAEgASgJUgVsYWJlbA==');

@$core.Deprecated('Use issueGatewayKeyResponseDescriptor instead')
const IssueGatewayKeyResponse$json = {
  '1': 'IssueGatewayKeyResponse',
  '2': [
    {'1': 'key_id', '3': 1, '4': 1, '5': 9, '10': 'keyId'},
    {'1': 'secret', '3': 2, '4': 1, '5': 9, '10': 'secret'},
    {'1': 'gateway_base_url', '3': 3, '4': 1, '5': 9, '10': 'gatewayBaseUrl'},
  ],
};

/// Descriptor for `IssueGatewayKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueGatewayKeyResponseDescriptor = $convert.base64Decode(
    'ChdJc3N1ZUdhdGV3YXlLZXlSZXNwb25zZRIVCgZrZXlfaWQYASABKAlSBWtleUlkEhYKBnNlY3'
    'JldBgCIAEoCVIGc2VjcmV0EigKEGdhdGV3YXlfYmFzZV91cmwYAyABKAlSDmdhdGV3YXlCYXNl'
    'VXJs');
