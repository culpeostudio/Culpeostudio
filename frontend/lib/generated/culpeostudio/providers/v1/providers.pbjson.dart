// This is a generated file - do not edit.
//
// Generated from culpeostudio/providers/v1/providers.proto.

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

@$core.Deprecated('Use connectionProtocolDescriptor instead')
const ConnectionProtocol$json = {
  '1': 'ConnectionProtocol',
  '2': [
    {'1': 'CONNECTION_PROTOCOL_UNSPECIFIED', '2': 0},
    {'1': 'CONNECTION_PROTOCOL_OPENAI_COMPATIBLE', '2': 1},
    {'1': 'CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES', '2': 2},
    {'1': 'CONNECTION_PROTOCOL_GOOGLE_GENAI', '2': 3},
    {'1': 'CONNECTION_PROTOCOL_OLLAMA_NATIVE', '2': 4},
  ],
};

/// Descriptor for `ConnectionProtocol`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List connectionProtocolDescriptor = $convert.base64Decode(
    'ChJDb25uZWN0aW9uUHJvdG9jb2wSIwofQ09OTkVDVElPTl9QUk9UT0NPTF9VTlNQRUNJRklFRB'
    'AAEikKJUNPTk5FQ1RJT05fUFJPVE9DT0xfT1BFTkFJX0NPTVBBVElCTEUQARIqCiZDT05ORUNU'
    'SU9OX1BST1RPQ09MX0FOVEhST1BJQ19NRVNTQUdFUxACEiQKIENPTk5FQ1RJT05fUFJPVE9DT0'
    'xfR09PR0xFX0dFTkFJEAMSJQohQ09OTkVDVElPTl9QUk9UT0NPTF9PTExBTUFfTkFUSVZFEAQ=');

@$core.Deprecated('Use providerPresetDescriptor instead')
const ProviderPreset$json = {
  '1': 'ProviderPreset',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'protocol',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.providers.v1.ConnectionProtocol',
      '10': 'protocol'
    },
    {'1': 'default_base_url', '3': 5, '4': 1, '5': 9, '10': 'defaultBaseUrl'},
    {
      '1': 'documentation_url',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'documentationUrl'
    },
    {'1': 'api_key_required', '3': 7, '4': 1, '5': 8, '10': 'apiKeyRequired'},
    {'1': 'available', '3': 8, '4': 1, '5': 8, '10': 'available'},
    {
      '1': 'unavailable_reason',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'unavailableReason'
    },
    {'1': 'local_only', '3': 10, '4': 1, '5': 8, '10': 'localOnly'},
  ],
};

/// Descriptor for `ProviderPreset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List providerPresetDescriptor = $convert.base64Decode(
    'Cg5Qcm92aWRlclByZXNldBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIgCg'
    'tkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SSQoIcHJvdG9jb2wYBCABKA4yLS5jdWxw'
    'ZW9zdHVkaW8ucHJvdmlkZXJzLnYxLkNvbm5lY3Rpb25Qcm90b2NvbFIIcHJvdG9jb2wSKAoQZG'
    'VmYXVsdF9iYXNlX3VybBgFIAEoCVIOZGVmYXVsdEJhc2VVcmwSKwoRZG9jdW1lbnRhdGlvbl91'
    'cmwYBiABKAlSEGRvY3VtZW50YXRpb25VcmwSKAoQYXBpX2tleV9yZXF1aXJlZBgHIAEoCFIOYX'
    'BpS2V5UmVxdWlyZWQSHAoJYXZhaWxhYmxlGAggASgIUglhdmFpbGFibGUSLQoSdW5hdmFpbGFi'
    'bGVfcmVhc29uGAkgASgJUhF1bmF2YWlsYWJsZVJlYXNvbhIdCgpsb2NhbF9vbmx5GAogASgIUg'
    'lsb2NhbE9ubHk=');

@$core.Deprecated('Use providerConnectionDescriptor instead')
const ProviderConnection$json = {
  '1': 'ProviderConnection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'preset_id', '3': 2, '4': 1, '5': 9, '10': 'presetId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'protocol',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.providers.v1.ConnectionProtocol',
      '10': 'protocol'
    },
    {'1': 'base_url', '3': 5, '4': 1, '5': 9, '10': 'baseUrl'},
    {'1': 'api_key_set', '3': 6, '4': 1, '5': 8, '10': 'apiKeySet'},
    {'1': 'enabled', '3': 7, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'model_count', '3': 8, '4': 1, '5': 5, '10': 'modelCount'},
    {
      '1': 'last_synced_at',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastSyncedAt'
    },
    {'1': 'last_sync_error', '3': 10, '4': 1, '5': 9, '10': 'lastSyncError'},
    {'1': 'chat_supported', '3': 11, '4': 1, '5': 8, '10': 'chatSupported'},
    {'1': 'stale', '3': 12, '4': 1, '5': 8, '10': 'stale'},
    {'1': 'provider_label', '3': 13, '4': 1, '5': 9, '10': 'providerLabel'},
  ],
};

/// Descriptor for `ProviderConnection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List providerConnectionDescriptor = $convert.base64Decode(
    'ChJQcm92aWRlckNvbm5lY3Rpb24SDgoCaWQYASABKAlSAmlkEhsKCXByZXNldF9pZBgCIAEoCV'
    'IIcHJlc2V0SWQSEgoEbmFtZRgDIAEoCVIEbmFtZRJJCghwcm90b2NvbBgEIAEoDjItLmN1bHBl'
    'b3N0dWRpby5wcm92aWRlcnMudjEuQ29ubmVjdGlvblByb3RvY29sUghwcm90b2NvbBIZCghiYX'
    'NlX3VybBgFIAEoCVIHYmFzZVVybBIeCgthcGlfa2V5X3NldBgGIAEoCFIJYXBpS2V5U2V0EhgK'
    'B2VuYWJsZWQYByABKAhSB2VuYWJsZWQSHwoLbW9kZWxfY291bnQYCCABKAVSCm1vZGVsQ291bn'
    'QSQAoObGFzdF9zeW5jZWRfYXQYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxs'
    'YXN0U3luY2VkQXQSJgoPbGFzdF9zeW5jX2Vycm9yGAogASgJUg1sYXN0U3luY0Vycm9yEiUKDm'
    'NoYXRfc3VwcG9ydGVkGAsgASgIUg1jaGF0U3VwcG9ydGVkEhQKBXN0YWxlGAwgASgIUgVzdGFs'
    'ZRIlCg5wcm92aWRlcl9sYWJlbBgNIAEoCVINcHJvdmlkZXJMYWJlbA==');

@$core.Deprecated('Use providerModelDescriptor instead')
const ProviderModel$json = {
  '1': 'ProviderModel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'context_window', '3': 4, '4': 1, '5': 5, '10': 'contextWindow'},
    {'1': 'max_output_tokens', '3': 5, '4': 1, '5': 5, '10': 'maxOutputTokens'},
    {'1': 'input_modalities', '3': 6, '4': 3, '5': 9, '10': 'inputModalities'},
    {
      '1': 'output_modalities',
      '3': 7,
      '4': 3,
      '5': 9,
      '10': 'outputModalities'
    },
    {'1': 'capabilities', '3': 8, '4': 3, '5': 9, '10': 'capabilities'},
    {'1': 'chat_supported', '3': 9, '4': 1, '5': 8, '10': 'chatSupported'},
    {'1': 'deprecated', '3': 10, '4': 1, '5': 8, '10': 'deprecated'},
    {
      '1': 'discovered_at',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'discoveredAt'
    },
  ],
};

/// Descriptor for `ProviderModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List providerModelDescriptor = $convert.base64Decode(
    'Cg1Qcm92aWRlck1vZGVsEg4KAmlkGAEgASgJUgJpZBIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2'
    'Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhIlCg5jb250ZXh0'
    'X3dpbmRvdxgEIAEoBVINY29udGV4dFdpbmRvdxIqChFtYXhfb3V0cHV0X3Rva2VucxgFIAEoBV'
    'IPbWF4T3V0cHV0VG9rZW5zEikKEGlucHV0X21vZGFsaXRpZXMYBiADKAlSD2lucHV0TW9kYWxp'
    'dGllcxIrChFvdXRwdXRfbW9kYWxpdGllcxgHIAMoCVIQb3V0cHV0TW9kYWxpdGllcxIiCgxjYX'
    'BhYmlsaXRpZXMYCCADKAlSDGNhcGFiaWxpdGllcxIlCg5jaGF0X3N1cHBvcnRlZBgJIAEoCFIN'
    'Y2hhdFN1cHBvcnRlZBIeCgpkZXByZWNhdGVkGAogASgIUgpkZXByZWNhdGVkEj8KDWRpc2Nvdm'
    'VyZWRfYXQYCyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxkaXNjb3ZlcmVkQXQ=');

@$core.Deprecated('Use activeProviderModelDescriptor instead')
const ActiveProviderModel$json = {
  '1': 'ActiveProviderModel',
  '2': [
    {'1': 'model_ref', '3': 1, '4': 1, '5': 9, '10': 'modelRef'},
    {'1': 'connection_id', '3': 2, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'provider_label', '3': 3, '4': 1, '5': 9, '10': 'providerLabel'},
    {'1': 'provider_id', '3': 4, '4': 1, '5': 9, '10': 'providerId'},
    {'1': 'model_id', '3': 5, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'display_name', '3': 6, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'protocol',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.providers.v1.ConnectionProtocol',
      '10': 'protocol'
    },
    {
      '1': 'activated_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'activatedAt'
    },
    {
      '1': 'last_used_at',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUsedAt'
    },
  ],
};

/// Descriptor for `ActiveProviderModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeProviderModelDescriptor = $convert.base64Decode(
    'ChNBY3RpdmVQcm92aWRlck1vZGVsEhsKCW1vZGVsX3JlZhgBIAEoCVIIbW9kZWxSZWYSIwoNY2'
    '9ubmVjdGlvbl9pZBgCIAEoCVIMY29ubmVjdGlvbklkEiUKDnByb3ZpZGVyX2xhYmVsGAMgASgJ'
    'Ug1wcm92aWRlckxhYmVsEh8KC3Byb3ZpZGVyX2lkGAQgASgJUgpwcm92aWRlcklkEhkKCG1vZG'
    'VsX2lkGAUgASgJUgdtb2RlbElkEiEKDGRpc3BsYXlfbmFtZRgGIAEoCVILZGlzcGxheU5hbWUS'
    'SQoIcHJvdG9jb2wYByABKA4yLS5jdWxwZW9zdHVkaW8ucHJvdmlkZXJzLnYxLkNvbm5lY3Rpb2'
    '5Qcm90b2NvbFIIcHJvdG9jb2wSPQoMYWN0aXZhdGVkX2F0GAggASgLMhouZ29vZ2xlLnByb3Rv'
    'YnVmLlRpbWVzdGFtcFILYWN0aXZhdGVkQXQSPAoMbGFzdF91c2VkX2F0GAkgASgLMhouZ29vZ2'
    'xlLnByb3RvYnVmLlRpbWVzdGFtcFIKbGFzdFVzZWRBdA==');

@$core.Deprecated('Use listPresetsRequestDescriptor instead')
const ListPresetsRequest$json = {
  '1': 'ListPresetsRequest',
};

/// Descriptor for `ListPresetsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPresetsRequestDescriptor =
    $convert.base64Decode('ChJMaXN0UHJlc2V0c1JlcXVlc3Q=');

@$core.Deprecated('Use listPresetsResponseDescriptor instead')
const ListPresetsResponse$json = {
  '1': 'ListPresetsResponse',
  '2': [
    {
      '1': 'presets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderPreset',
      '10': 'presets'
    },
  ],
};

/// Descriptor for `ListPresetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPresetsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0UHJlc2V0c1Jlc3BvbnNlEkMKB3ByZXNldHMYASADKAsyKS5jdWxwZW9zdHVkaW8ucH'
    'JvdmlkZXJzLnYxLlByb3ZpZGVyUHJlc2V0UgdwcmVzZXRz');

@$core.Deprecated('Use listConnectionsRequestDescriptor instead')
const ListConnectionsRequest$json = {
  '1': 'ListConnectionsRequest',
};

/// Descriptor for `ListConnectionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionsRequestDescriptor =
    $convert.base64Decode('ChZMaXN0Q29ubmVjdGlvbnNSZXF1ZXN0');

@$core.Deprecated('Use listConnectionsResponseDescriptor instead')
const ListConnectionsResponse$json = {
  '1': 'ListConnectionsResponse',
  '2': [
    {
      '1': 'connections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderConnection',
      '10': 'connections'
    },
  ],
};

/// Descriptor for `ListConnectionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionsResponseDescriptor = $convert.base64Decode(
    'ChdMaXN0Q29ubmVjdGlvbnNSZXNwb25zZRJPCgtjb25uZWN0aW9ucxgBIAMoCzItLmN1bHBlb3'
    'N0dWRpby5wcm92aWRlcnMudjEuUHJvdmlkZXJDb25uZWN0aW9uUgtjb25uZWN0aW9ucw==');

@$core.Deprecated('Use saveConnectionRequestDescriptor instead')
const SaveConnectionRequest$json = {
  '1': 'SaveConnectionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'preset_id', '3': 2, '4': 1, '5': 9, '10': 'presetId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'protocol',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.providers.v1.ConnectionProtocol',
      '10': 'protocol'
    },
    {'1': 'base_url', '3': 5, '4': 1, '5': 9, '10': 'baseUrl'},
    {
      '1': 'api_key',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'apiKey',
      '17': true
    },
    {'1': 'clear_api_key', '3': 7, '4': 1, '5': 8, '10': 'clearApiKey'},
    {'1': 'enabled', '3': 8, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'sync_models', '3': 9, '4': 1, '5': 8, '10': 'syncModels'},
  ],
  '8': [
    {'1': '_api_key'},
  ],
};

/// Descriptor for `SaveConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveConnectionRequestDescriptor = $convert.base64Decode(
    'ChVTYXZlQ29ubmVjdGlvblJlcXVlc3QSDgoCaWQYASABKAlSAmlkEhsKCXByZXNldF9pZBgCIA'
    'EoCVIIcHJlc2V0SWQSEgoEbmFtZRgDIAEoCVIEbmFtZRJJCghwcm90b2NvbBgEIAEoDjItLmN1'
    'bHBlb3N0dWRpby5wcm92aWRlcnMudjEuQ29ubmVjdGlvblByb3RvY29sUghwcm90b2NvbBIZCg'
    'hiYXNlX3VybBgFIAEoCVIHYmFzZVVybBIcCgdhcGlfa2V5GAYgASgJSABSBmFwaUtleYgBARIi'
    'Cg1jbGVhcl9hcGlfa2V5GAcgASgIUgtjbGVhckFwaUtleRIYCgdlbmFibGVkGAggASgIUgdlbm'
    'FibGVkEh8KC3N5bmNfbW9kZWxzGAkgASgIUgpzeW5jTW9kZWxzQgoKCF9hcGlfa2V5');

@$core.Deprecated('Use saveConnectionResponseDescriptor instead')
const SaveConnectionResponse$json = {
  '1': 'SaveConnectionResponse',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderConnection',
      '10': 'connection'
    },
    {
      '1': 'models',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderModel',
      '10': 'models'
    },
    {'1': 'sync_error', '3': 3, '4': 1, '5': 9, '10': 'syncError'},
  ],
};

/// Descriptor for `SaveConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveConnectionResponseDescriptor = $convert.base64Decode(
    'ChZTYXZlQ29ubmVjdGlvblJlc3BvbnNlEk0KCmNvbm5lY3Rpb24YASABKAsyLS5jdWxwZW9zdH'
    'VkaW8ucHJvdmlkZXJzLnYxLlByb3ZpZGVyQ29ubmVjdGlvblIKY29ubmVjdGlvbhJACgZtb2Rl'
    'bHMYAiADKAsyKC5jdWxwZW9zdHVkaW8ucHJvdmlkZXJzLnYxLlByb3ZpZGVyTW9kZWxSBm1vZG'
    'VscxIdCgpzeW5jX2Vycm9yGAMgASgJUglzeW5jRXJyb3I=');

@$core.Deprecated('Use deleteConnectionRequestDescriptor instead')
const DeleteConnectionRequest$json = {
  '1': 'DeleteConnectionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteConnectionRequestDescriptor = $convert
    .base64Decode('ChdEZWxldGVDb25uZWN0aW9uUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use deleteConnectionResponseDescriptor instead')
const DeleteConnectionResponse$json = {
  '1': 'DeleteConnectionResponse',
};

/// Descriptor for `DeleteConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteConnectionResponseDescriptor =
    $convert.base64Decode('ChhEZWxldGVDb25uZWN0aW9uUmVzcG9uc2U=');

@$core.Deprecated('Use testConnectionRequestDescriptor instead')
const TestConnectionRequest$json = {
  '1': 'TestConnectionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `TestConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testConnectionRequestDescriptor = $convert
    .base64Decode('ChVUZXN0Q29ubmVjdGlvblJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use testConnectionResponseDescriptor instead')
const TestConnectionResponse$json = {
  '1': 'TestConnectionResponse',
  '2': [
    {'1': 'reachable', '3': 1, '4': 1, '5': 8, '10': 'reachable'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'discovered_model_count',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'discoveredModelCount'
    },
  ],
};

/// Descriptor for `TestConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testConnectionResponseDescriptor = $convert.base64Decode(
    'ChZUZXN0Q29ubmVjdGlvblJlc3BvbnNlEhwKCXJlYWNoYWJsZRgBIAEoCFIJcmVhY2hhYmxlEh'
    'gKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USNAoWZGlzY292ZXJlZF9tb2RlbF9jb3VudBgDIAEo'
    'BVIUZGlzY292ZXJlZE1vZGVsQ291bnQ=');

@$core.Deprecated('Use syncConnectionModelsRequestDescriptor instead')
const SyncConnectionModelsRequest$json = {
  '1': 'SyncConnectionModelsRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `SyncConnectionModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncConnectionModelsRequestDescriptor =
    $convert.base64Decode(
        'ChtTeW5jQ29ubmVjdGlvbk1vZGVsc1JlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use syncConnectionModelsResponseDescriptor instead')
const SyncConnectionModelsResponse$json = {
  '1': 'SyncConnectionModelsResponse',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderConnection',
      '10': 'connection'
    },
    {
      '1': 'models',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderModel',
      '10': 'models'
    },
  ],
};

/// Descriptor for `SyncConnectionModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncConnectionModelsResponseDescriptor = $convert.base64Decode(
    'ChxTeW5jQ29ubmVjdGlvbk1vZGVsc1Jlc3BvbnNlEk0KCmNvbm5lY3Rpb24YASABKAsyLS5jdW'
    'xwZW9zdHVkaW8ucHJvdmlkZXJzLnYxLlByb3ZpZGVyQ29ubmVjdGlvblIKY29ubmVjdGlvbhJA'
    'CgZtb2RlbHMYAiADKAsyKC5jdWxwZW9zdHVkaW8ucHJvdmlkZXJzLnYxLlByb3ZpZGVyTW9kZW'
    'xSBm1vZGVscw==');

@$core.Deprecated('Use listConnectionModelsRequestDescriptor instead')
const ListConnectionModelsRequest$json = {
  '1': 'ListConnectionModelsRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `ListConnectionModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionModelsRequestDescriptor =
    $convert.base64Decode(
        'ChtMaXN0Q29ubmVjdGlvbk1vZGVsc1JlcXVlc3QSIwoNY29ubmVjdGlvbl9pZBgBIAEoCVIMY2'
        '9ubmVjdGlvbklk');

@$core.Deprecated('Use listConnectionModelsResponseDescriptor instead')
const ListConnectionModelsResponse$json = {
  '1': 'ListConnectionModelsResponse',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderConnection',
      '10': 'connection'
    },
    {
      '1': 'models',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ProviderModel',
      '10': 'models'
    },
  ],
};

/// Descriptor for `ListConnectionModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionModelsResponseDescriptor = $convert.base64Decode(
    'ChxMaXN0Q29ubmVjdGlvbk1vZGVsc1Jlc3BvbnNlEk0KCmNvbm5lY3Rpb24YASABKAsyLS5jdW'
    'xwZW9zdHVkaW8ucHJvdmlkZXJzLnYxLlByb3ZpZGVyQ29ubmVjdGlvblIKY29ubmVjdGlvbhJA'
    'CgZtb2RlbHMYAiADKAsyKC5jdWxwZW9zdHVkaW8ucHJvdmlkZXJzLnYxLlByb3ZpZGVyTW9kZW'
    'xSBm1vZGVscw==');

@$core.Deprecated('Use activateModelRequestDescriptor instead')
const ActivateModelRequest$json = {
  '1': 'ActivateModelRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'model_id', '3': 2, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `ActivateModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activateModelRequestDescriptor = $convert.base64Decode(
    'ChRBY3RpdmF0ZU1vZGVsUmVxdWVzdBIjCg1jb25uZWN0aW9uX2lkGAEgASgJUgxjb25uZWN0aW'
    '9uSWQSGQoIbW9kZWxfaWQYAiABKAlSB21vZGVsSWQSIQoMZGlzcGxheV9uYW1lGAMgASgJUgtk'
    'aXNwbGF5TmFtZQ==');

@$core.Deprecated('Use activateModelResponseDescriptor instead')
const ActivateModelResponse$json = {
  '1': 'ActivateModelResponse',
  '2': [
    {
      '1': 'model',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ActiveProviderModel',
      '10': 'model'
    },
  ],
};

/// Descriptor for `ActivateModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activateModelResponseDescriptor = $convert.base64Decode(
    'ChVBY3RpdmF0ZU1vZGVsUmVzcG9uc2USRAoFbW9kZWwYASABKAsyLi5jdWxwZW9zdHVkaW8ucH'
    'JvdmlkZXJzLnYxLkFjdGl2ZVByb3ZpZGVyTW9kZWxSBW1vZGVs');

@$core.Deprecated('Use listActiveModelsRequestDescriptor instead')
const ListActiveModelsRequest$json = {
  '1': 'ListActiveModelsRequest',
};

/// Descriptor for `ListActiveModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listActiveModelsRequestDescriptor =
    $convert.base64Decode('ChdMaXN0QWN0aXZlTW9kZWxzUmVxdWVzdA==');

@$core.Deprecated('Use listActiveModelsResponseDescriptor instead')
const ListActiveModelsResponse$json = {
  '1': 'ListActiveModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.providers.v1.ActiveProviderModel',
      '10': 'models'
    },
  ],
};

/// Descriptor for `ListActiveModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listActiveModelsResponseDescriptor =
    $convert.base64Decode(
        'ChhMaXN0QWN0aXZlTW9kZWxzUmVzcG9uc2USRgoGbW9kZWxzGAEgAygLMi4uY3VscGVvc3R1ZG'
        'lvLnByb3ZpZGVycy52MS5BY3RpdmVQcm92aWRlck1vZGVsUgZtb2RlbHM=');

@$core.Deprecated('Use deleteActiveModelRequestDescriptor instead')
const DeleteActiveModelRequest$json = {
  '1': 'DeleteActiveModelRequest',
  '2': [
    {'1': 'model_ref', '3': 1, '4': 1, '5': 9, '10': 'modelRef'},
  ],
};

/// Descriptor for `DeleteActiveModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteActiveModelRequestDescriptor =
    $convert.base64Decode(
        'ChhEZWxldGVBY3RpdmVNb2RlbFJlcXVlc3QSGwoJbW9kZWxfcmVmGAEgASgJUghtb2RlbFJlZg'
        '==');

@$core.Deprecated('Use deleteActiveModelResponseDescriptor instead')
const DeleteActiveModelResponse$json = {
  '1': 'DeleteActiveModelResponse',
};

/// Descriptor for `DeleteActiveModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteActiveModelResponseDescriptor =
    $convert.base64Decode('ChlEZWxldGVBY3RpdmVNb2RlbFJlc3BvbnNl');
