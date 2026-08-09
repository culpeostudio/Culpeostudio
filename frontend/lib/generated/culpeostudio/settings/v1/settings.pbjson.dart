// This is a generated file - do not edit.
//
// Generated from culpeostudio/settings/v1/settings.proto.

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

@$core.Deprecated('Use providerDescriptor instead')
const Provider$json = {
  '1': 'Provider',
  '2': [
    {'1': 'PROVIDER_UNSPECIFIED', '2': 0},
    {'1': 'PROVIDER_HUGGINGFACE', '2': 1},
    {'1': 'PROVIDER_OPENROUTER', '2': 2},
    {'1': 'PROVIDER_FEATHERLESS', '2': 3},
  ],
};

/// Descriptor for `Provider`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List providerDescriptor = $convert.base64Decode(
    'CghQcm92aWRlchIYChRQUk9WSURFUl9VTlNQRUNJRklFRBAAEhgKFFBST1ZJREVSX0hVR0dJTk'
    'dGQUNFEAESFwoTUFJPVklERVJfT1BFTlJPVVRFUhACEhgKFFBST1ZJREVSX0ZFQVRIRVJMRVNT'
    'EAM=');

@$core.Deprecated('Use settingsDescriptor instead')
const Settings$json = {
  '1': 'Settings',
  '2': [
    {'1': 'model_dir', '3': 1, '4': 1, '5': 9, '10': 'modelDir'},
    {'1': 'model_dir_valid', '3': 2, '4': 1, '5': 8, '10': 'modelDirValid'},
    {'1': 'model_dir_error', '3': 3, '4': 1, '5': 9, '10': 'modelDirError'},
    {
      '1': 'huggingface_token_set',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'huggingfaceTokenSet'
    },
    {
      '1': 'openrouter_token_set',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'openrouterTokenSet'
    },
    {
      '1': 'featherless_token_set',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'featherlessTokenSet'
    },
    {
      '1': 'shortcuts',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.settings.v1.Settings.ShortcutsEntry',
      '10': 'shortcuts'
    },
    {
      '1': 'engine_ram_reserve_bytes',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'engineRamReserveBytes',
      '17': true
    },
    {
      '1': 'engine_gpu_reserve_bytes',
      '3': 9,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'engineGpuReserveBytes',
      '17': true
    },
  ],
  '3': [Settings_ShortcutsEntry$json],
  '8': [
    {'1': '_engine_ram_reserve_bytes'},
    {'1': '_engine_gpu_reserve_bytes'},
  ],
};

@$core.Deprecated('Use settingsDescriptor instead')
const Settings_ShortcutsEntry$json = {
  '1': 'ShortcutsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Settings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsDescriptor = $convert.base64Decode(
    'CghTZXR0aW5ncxIbCgltb2RlbF9kaXIYASABKAlSCG1vZGVsRGlyEiYKD21vZGVsX2Rpcl92YW'
    'xpZBgCIAEoCFINbW9kZWxEaXJWYWxpZBImCg9tb2RlbF9kaXJfZXJyb3IYAyABKAlSDW1vZGVs'
    'RGlyRXJyb3ISMgoVaHVnZ2luZ2ZhY2VfdG9rZW5fc2V0GAQgASgIUhNodWdnaW5nZmFjZVRva2'
    'VuU2V0EjAKFG9wZW5yb3V0ZXJfdG9rZW5fc2V0GAUgASgIUhJvcGVucm91dGVyVG9rZW5TZXQS'
    'MgoVZmVhdGhlcmxlc3NfdG9rZW5fc2V0GAYgASgIUhNmZWF0aGVybGVzc1Rva2VuU2V0Ek8KCX'
    'Nob3J0Y3V0cxgHIAMoCzIxLmN1bHBlb3N0dWRpby5zZXR0aW5ncy52MS5TZXR0aW5ncy5TaG9y'
    'dGN1dHNFbnRyeVIJc2hvcnRjdXRzEjwKGGVuZ2luZV9yYW1fcmVzZXJ2ZV9ieXRlcxgIIAEoA0'
    'gAUhVlbmdpbmVSYW1SZXNlcnZlQnl0ZXOIAQESPAoYZW5naW5lX2dwdV9yZXNlcnZlX2J5dGVz'
    'GAkgASgDSAFSFWVuZ2luZUdwdVJlc2VydmVCeXRlc4gBARo8Cg5TaG9ydGN1dHNFbnRyeRIQCg'
    'NrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQhsKGV9lbmdpbmVfcmFt'
    'X3Jlc2VydmVfYnl0ZXNCGwoZX2VuZ2luZV9ncHVfcmVzZXJ2ZV9ieXRlcw==');

@$core.Deprecated('Use getSettingsRequestDescriptor instead')
const GetSettingsRequest$json = {
  '1': 'GetSettingsRequest',
};

/// Descriptor for `GetSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSettingsRequestDescriptor =
    $convert.base64Decode('ChJHZXRTZXR0aW5nc1JlcXVlc3Q=');

@$core.Deprecated('Use getSettingsResponseDescriptor instead')
const GetSettingsResponse$json = {
  '1': 'GetSettingsResponse',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.settings.v1.Settings',
      '10': 'settings'
    },
  ],
};

/// Descriptor for `GetSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSettingsResponseDescriptor = $convert.base64Decode(
    'ChNHZXRTZXR0aW5nc1Jlc3BvbnNlEj4KCHNldHRpbmdzGAEgASgLMiIuY3VscGVvc3R1ZGlvLn'
    'NldHRpbmdzLnYxLlNldHRpbmdzUghzZXR0aW5ncw==');

@$core.Deprecated('Use updateSettingsRequestDescriptor instead')
const UpdateSettingsRequest$json = {
  '1': 'UpdateSettingsRequest',
  '2': [
    {
      '1': 'model_dir',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'modelDir',
      '17': true
    },
    {
      '1': 'huggingface_token',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'huggingfaceToken',
      '17': true
    },
    {
      '1': 'openrouter_token',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'openrouterToken',
      '17': true
    },
    {
      '1': 'featherless_token',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'featherlessToken',
      '17': true
    },
    {
      '1': 'shortcuts',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.settings.v1.UpdateSettingsRequest.ShortcutsEntry',
      '10': 'shortcuts'
    },
    {
      '1': 'engine_ram_reserve_bytes',
      '3': 6,
      '4': 1,
      '5': 3,
      '9': 4,
      '10': 'engineRamReserveBytes',
      '17': true
    },
    {
      '1': 'engine_gpu_reserve_bytes',
      '3': 7,
      '4': 1,
      '5': 3,
      '9': 5,
      '10': 'engineGpuReserveBytes',
      '17': true
    },
    {
      '1': 'reset_engine_reserves',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'resetEngineReserves'
    },
  ],
  '3': [UpdateSettingsRequest_ShortcutsEntry$json],
  '8': [
    {'1': '_model_dir'},
    {'1': '_huggingface_token'},
    {'1': '_openrouter_token'},
    {'1': '_featherless_token'},
    {'1': '_engine_ram_reserve_bytes'},
    {'1': '_engine_gpu_reserve_bytes'},
  ],
};

@$core.Deprecated('Use updateSettingsRequestDescriptor instead')
const UpdateSettingsRequest_ShortcutsEntry$json = {
  '1': 'ShortcutsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `UpdateSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSettingsRequestDescriptor = $convert.base64Decode(
    'ChVVcGRhdGVTZXR0aW5nc1JlcXVlc3QSIAoJbW9kZWxfZGlyGAEgASgJSABSCG1vZGVsRGlyiA'
    'EBEjAKEWh1Z2dpbmdmYWNlX3Rva2VuGAIgASgJSAFSEGh1Z2dpbmdmYWNlVG9rZW6IAQESLgoQ'
    'b3BlbnJvdXRlcl90b2tlbhgDIAEoCUgCUg9vcGVucm91dGVyVG9rZW6IAQESMAoRZmVhdGhlcm'
    'xlc3NfdG9rZW4YBCABKAlIA1IQZmVhdGhlcmxlc3NUb2tlbogBARJcCglzaG9ydGN1dHMYBSAD'
    'KAsyPi5jdWxwZW9zdHVkaW8uc2V0dGluZ3MudjEuVXBkYXRlU2V0dGluZ3NSZXF1ZXN0LlNob3'
    'J0Y3V0c0VudHJ5UglzaG9ydGN1dHMSPAoYZW5naW5lX3JhbV9yZXNlcnZlX2J5dGVzGAYgASgD'
    'SARSFWVuZ2luZVJhbVJlc2VydmVCeXRlc4gBARI8ChhlbmdpbmVfZ3B1X3Jlc2VydmVfYnl0ZX'
    'MYByABKANIBVIVZW5naW5lR3B1UmVzZXJ2ZUJ5dGVziAEBEjIKFXJlc2V0X2VuZ2luZV9yZXNl'
    'cnZlcxgIIAEoCFITcmVzZXRFbmdpbmVSZXNlcnZlcxo8Cg5TaG9ydGN1dHNFbnRyeRIQCgNrZX'
    'kYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQgwKCl9tb2RlbF9kaXJCFAoS'
    'X2h1Z2dpbmdmYWNlX3Rva2VuQhMKEV9vcGVucm91dGVyX3Rva2VuQhQKEl9mZWF0aGVybGVzc1'
    '90b2tlbkIbChlfZW5naW5lX3JhbV9yZXNlcnZlX2J5dGVzQhsKGV9lbmdpbmVfZ3B1X3Jlc2Vy'
    'dmVfYnl0ZXM=');

@$core.Deprecated('Use updateSettingsResponseDescriptor instead')
const UpdateSettingsResponse$json = {
  '1': 'UpdateSettingsResponse',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.settings.v1.Settings',
      '10': 'settings'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'warnings', '3': 3, '4': 3, '5': 9, '10': 'warnings'},
  ],
};

/// Descriptor for `UpdateSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSettingsResponseDescriptor = $convert.base64Decode(
    'ChZVcGRhdGVTZXR0aW5nc1Jlc3BvbnNlEj4KCHNldHRpbmdzGAEgASgLMiIuY3VscGVvc3R1ZG'
    'lvLnNldHRpbmdzLnYxLlNldHRpbmdzUghzZXR0aW5ncxIYCgdtZXNzYWdlGAIgASgJUgdtZXNz'
    'YWdlEhoKCHdhcm5pbmdzGAMgAygJUgh3YXJuaW5ncw==');

@$core.Deprecated('Use getSystemInfoRequestDescriptor instead')
const GetSystemInfoRequest$json = {
  '1': 'GetSystemInfoRequest',
};

/// Descriptor for `GetSystemInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSystemInfoRequestDescriptor =
    $convert.base64Decode('ChRHZXRTeXN0ZW1JbmZvUmVxdWVzdA==');

@$core.Deprecated('Use getSystemInfoResponseDescriptor instead')
const GetSystemInfoResponse$json = {
  '1': 'GetSystemInfoResponse',
  '2': [
    {
      '1': 'profile',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.HardwareProfile',
      '10': 'profile'
    },
  ],
};

/// Descriptor for `GetSystemInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSystemInfoResponseDescriptor = $convert.base64Decode(
    'ChVHZXRTeXN0ZW1JbmZvUmVzcG9uc2USQwoHcHJvZmlsZRgBIAEoCzIpLmN1bHBlb3N0dWRpby'
    '5oYXJkd2FyZS52MS5IYXJkd2FyZVByb2ZpbGVSB3Byb2ZpbGU=');

@$core.Deprecated('Use testProviderRequestDescriptor instead')
const TestProviderRequest$json = {
  '1': 'TestProviderRequest',
  '2': [
    {
      '1': 'provider',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.settings.v1.Provider',
      '10': 'provider'
    },
  ],
};

/// Descriptor for `TestProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testProviderRequestDescriptor = $convert.base64Decode(
    'ChNUZXN0UHJvdmlkZXJSZXF1ZXN0Ej4KCHByb3ZpZGVyGAEgASgOMiIuY3VscGVvc3R1ZGlvLn'
    'NldHRpbmdzLnYxLlByb3ZpZGVyUghwcm92aWRlcg==');

@$core.Deprecated('Use testProviderResponseDescriptor instead')
const TestProviderResponse$json = {
  '1': 'TestProviderResponse',
  '2': [
    {
      '1': 'provider',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.settings.v1.Provider',
      '10': 'provider'
    },
    {'1': 'reachable', '3': 2, '4': 1, '5': 8, '10': 'reachable'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `TestProviderResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testProviderResponseDescriptor = $convert.base64Decode(
    'ChRUZXN0UHJvdmlkZXJSZXNwb25zZRI+Cghwcm92aWRlchgBIAEoDjIiLmN1bHBlb3N0dWRpby'
    '5zZXR0aW5ncy52MS5Qcm92aWRlclIIcHJvdmlkZXISHAoJcmVhY2hhYmxlGAIgASgIUglyZWFj'
    'aGFibGUSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZQ==');
