// This is a generated file - do not edit.
//
// Generated from culpeostudio/engine/v1/engine.proto.

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

@$core.Deprecated('Use runtimeKindDescriptor instead')
const RuntimeKind$json = {
  '1': 'RuntimeKind',
  '2': [
    {'1': 'RUNTIME_KIND_UNSPECIFIED', '2': 0},
    {'1': 'RUNTIME_KIND_AUTO', '2': 1},
    {'1': 'RUNTIME_KIND_LLAMA_CPP', '2': 2},
  ],
  '4': [
    {'1': 3, '2': 3},
    {'1': 4, '2': 4},
  ],
  '5': ['RUNTIME_KIND_VLLM', 'RUNTIME_KIND_TRANSFORMERS'],
};

/// Descriptor for `RuntimeKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List runtimeKindDescriptor = $convert.base64Decode(
    'CgtSdW50aW1lS2luZBIcChhSVU5USU1FX0tJTkRfVU5TUEVDSUZJRUQQABIVChFSVU5USU1FX0'
    'tJTkRfQVVUTxABEhoKFlJVTlRJTUVfS0lORF9MTEFNQV9DUFAQAiIECAMQAyIECAQQBCoRUlVO'
    'VElNRV9LSU5EX1ZMTE0qGVJVTlRJTUVfS0lORF9UUkFOU0ZPUk1FUlM=');

@$core.Deprecated('Use contextModeDescriptor instead')
const ContextMode$json = {
  '1': 'ContextMode',
  '2': [
    {'1': 'CONTEXT_MODE_UNSPECIFIED', '2': 0},
    {'1': 'CONTEXT_MODE_AUTO_MAX', '2': 1},
    {'1': 'CONTEXT_MODE_FIXED', '2': 2},
  ],
};

/// Descriptor for `ContextMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List contextModeDescriptor = $convert.base64Decode(
    'CgtDb250ZXh0TW9kZRIcChhDT05URVhUX01PREVfVU5TUEVDSUZJRUQQABIZChVDT05URVhUX0'
    '1PREVfQVVUT19NQVgQARIWChJDT05URVhUX01PREVfRklYRUQQAg==');

@$core.Deprecated('Use priorityDescriptor instead')
const Priority$json = {
  '1': 'Priority',
  '2': [
    {'1': 'PRIORITY_UNSPECIFIED', '2': 0},
    {'1': 'PRIORITY_LOW', '2': 1},
    {'1': 'PRIORITY_NORMAL', '2': 2},
    {'1': 'PRIORITY_HIGH', '2': 3},
    {'1': 'PRIORITY_PINNED', '2': 4},
  ],
};

/// Descriptor for `Priority`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List priorityDescriptor = $convert.base64Decode(
    'CghQcmlvcml0eRIYChRQUklPUklUWV9VTlNQRUNJRklFRBAAEhAKDFBSSU9SSVRZX0xPVxABEh'
    'MKD1BSSU9SSVRZX05PUk1BTBACEhEKDVBSSU9SSVRZX0hJR0gQAxITCg9QUklPUklUWV9QSU5O'
    'RUQQBA==');

@$core.Deprecated('Use kvCachePolicyDescriptor instead')
const KvCachePolicy$json = {
  '1': 'KvCachePolicy',
  '2': [
    {'1': 'KV_CACHE_POLICY_UNSPECIFIED', '2': 0},
    {'1': 'KV_CACHE_POLICY_NATIVE', '2': 1},
    {'1': 'KV_CACHE_POLICY_PREFER_4BIT', '2': 2},
  ],
};

/// Descriptor for `KvCachePolicy`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List kvCachePolicyDescriptor = $convert.base64Decode(
    'Cg1LdkNhY2hlUG9saWN5Eh8KG0tWX0NBQ0hFX1BPTElDWV9VTlNQRUNJRklFRBAAEhoKFktWX0'
    'NBQ0hFX1BPTElDWV9OQVRJVkUQARIfChtLVl9DQUNIRV9QT0xJQ1lfUFJFRkVSXzRCSVQQAg==');

@$core.Deprecated('Use kvCacheDtypeDescriptor instead')
const KvCacheDtype$json = {
  '1': 'KvCacheDtype',
  '2': [
    {'1': 'KV_CACHE_DTYPE_UNSPECIFIED', '2': 0},
    {'1': 'KV_CACHE_DTYPE_Q4', '2': 1},
    {'1': 'KV_CACHE_DTYPE_FP16', '2': 3},
    {'1': 'KV_CACHE_DTYPE_BF16', '2': 4},
    {'1': 'KV_CACHE_DTYPE_FP32', '2': 5},
    {'1': 'KV_CACHE_DTYPE_Q4_1', '2': 6},
    {'1': 'KV_CACHE_DTYPE_IQ4_NL', '2': 7},
    {'1': 'KV_CACHE_DTYPE_Q5_0', '2': 8},
    {'1': 'KV_CACHE_DTYPE_Q5_1', '2': 9},
    {'1': 'KV_CACHE_DTYPE_Q8_0', '2': 10},
    {'1': 'KV_CACHE_DTYPE_Q2_K', '2': 11},
  ],
  '4': [
    {'1': 2, '2': 2},
  ],
  '5': ['KV_CACHE_DTYPE_FP8'],
};

/// Descriptor for `KvCacheDtype`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List kvCacheDtypeDescriptor = $convert.base64Decode(
    'CgxLdkNhY2hlRHR5cGUSHgoaS1ZfQ0FDSEVfRFRZUEVfVU5TUEVDSUZJRUQQABIVChFLVl9DQU'
    'NIRV9EVFlQRV9RNBABEhcKE0tWX0NBQ0hFX0RUWVBFX0ZQMTYQAxIXChNLVl9DQUNIRV9EVFlQ'
    'RV9CRjE2EAQSFwoTS1ZfQ0FDSEVfRFRZUEVfRlAzMhAFEhcKE0tWX0NBQ0hFX0RUWVBFX1E0Xz'
    'EQBhIZChVLVl9DQUNIRV9EVFlQRV9JUTRfTkwQBxIXChNLVl9DQUNIRV9EVFlQRV9RNV8wEAgS'
    'FwoTS1ZfQ0FDSEVfRFRZUEVfUTVfMRAJEhcKE0tWX0NBQ0hFX0RUWVBFX1E4XzAQChIXChNLVl'
    '9DQUNIRV9EVFlQRV9RMl9LEAsiBAgCEAIqEktWX0NBQ0hFX0RUWVBFX0ZQOA==');

@$core.Deprecated('Use instanceStateDescriptor instead')
const InstanceState$json = {
  '1': 'InstanceState',
  '2': [
    {'1': 'INSTANCE_STATE_UNSPECIFIED', '2': 0},
    {'1': 'INSTANCE_STATE_INSTALLING', '2': 1},
    {'1': 'INSTANCE_STATE_QUEUED', '2': 2},
    {'1': 'INSTANCE_STATE_STARTING', '2': 3},
    {'1': 'INSTANCE_STATE_READY', '2': 4},
    {'1': 'INSTANCE_STATE_DRAINING', '2': 5},
    {'1': 'INSTANCE_STATE_RESTARTING', '2': 6},
    {'1': 'INSTANCE_STATE_STOPPED', '2': 7},
    {'1': 'INSTANCE_STATE_FAILED', '2': 8},
    {'1': 'INSTANCE_STATE_FAILED_ROLLBACK', '2': 9},
  ],
};

/// Descriptor for `InstanceState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List instanceStateDescriptor = $convert.base64Decode(
    'Cg1JbnN0YW5jZVN0YXRlEh4KGklOU1RBTkNFX1NUQVRFX1VOU1BFQ0lGSUVEEAASHQoZSU5TVE'
    'FOQ0VfU1RBVEVfSU5TVEFMTElORxABEhkKFUlOU1RBTkNFX1NUQVRFX1FVRVVFRBACEhsKF0lO'
    'U1RBTkNFX1NUQVRFX1NUQVJUSU5HEAMSGAoUSU5TVEFOQ0VfU1RBVEVfUkVBRFkQBBIbChdJTl'
    'NUQU5DRV9TVEFURV9EUkFJTklORxAFEh0KGUlOU1RBTkNFX1NUQVRFX1JFU1RBUlRJTkcQBhIa'
    'ChZJTlNUQU5DRV9TVEFURV9TVE9QUEVEEAcSGQoVSU5TVEFOQ0VfU1RBVEVfRkFJTEVEEAgSIg'
    'oeSU5TVEFOQ0VfU1RBVEVfRkFJTEVEX1JPTExCQUNLEAk=');

@$core.Deprecated('Use operationStateDescriptor instead')
const OperationState$json = {
  '1': 'OperationState',
  '2': [
    {'1': 'OPERATION_STATE_UNSPECIFIED', '2': 0},
    {'1': 'OPERATION_STATE_QUEUED', '2': 1},
    {'1': 'OPERATION_STATE_RUNNING', '2': 2},
    {'1': 'OPERATION_STATE_COMPLETED', '2': 3},
    {'1': 'OPERATION_STATE_FAILED', '2': 4},
    {'1': 'OPERATION_STATE_CANCELLED', '2': 5},
  ],
};

/// Descriptor for `OperationState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List operationStateDescriptor = $convert.base64Decode(
    'Cg5PcGVyYXRpb25TdGF0ZRIfChtPUEVSQVRJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIaChZPUE'
    'VSQVRJT05fU1RBVEVfUVVFVUVEEAESGwoXT1BFUkFUSU9OX1NUQVRFX1JVTk5JTkcQAhIdChlP'
    'UEVSQVRJT05fU1RBVEVfQ09NUExFVEVEEAMSGgoWT1BFUkFUSU9OX1NUQVRFX0ZBSUxFRBAEEh'
    '0KGU9QRVJBVElPTl9TVEFURV9DQU5DRUxMRUQQBQ==');

@$core.Deprecated('Use placementDescriptor instead')
const Placement$json = {
  '1': 'Placement',
  '2': [
    {'1': 'PLACEMENT_UNSPECIFIED', '2': 0},
    {'1': 'PLACEMENT_GPU', '2': 1},
    {'1': 'PLACEMENT_RAM', '2': 2},
    {'1': 'PLACEMENT_HYBRID', '2': 3},
  ],
};

/// Descriptor for `Placement`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List placementDescriptor = $convert.base64Decode(
    'CglQbGFjZW1lbnQSGQoVUExBQ0VNRU5UX1VOU1BFQ0lGSUVEEAASEQoNUExBQ0VNRU5UX0dQVR'
    'ABEhEKDVBMQUNFTUVOVF9SQU0QAhIUChBQTEFDRU1FTlRfSFlCUklEEAM=');

@$core.Deprecated('Use guardStateDescriptor instead')
const GuardState$json = {
  '1': 'GuardState',
  '2': [
    {'1': 'GUARD_STATE_UNSPECIFIED', '2': 0},
    {'1': 'GUARD_STATE_NORMAL', '2': 1},
    {'1': 'GUARD_STATE_WARNING', '2': 2},
    {'1': 'GUARD_STATE_CRITICAL', '2': 3},
    {'1': 'GUARD_STATE_EMERGENCY', '2': 4},
  ],
};

/// Descriptor for `GuardState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List guardStateDescriptor = $convert.base64Decode(
    'CgpHdWFyZFN0YXRlEhsKF0dVQVJEX1NUQVRFX1VOU1BFQ0lGSUVEEAASFgoSR1VBUkRfU1RBVE'
    'VfTk9STUFMEAESFwoTR1VBUkRfU1RBVEVfV0FSTklORxACEhgKFEdVQVJEX1NUQVRFX0NSSVRJ'
    'Q0FMEAMSGQoVR1VBUkRfU1RBVEVfRU1FUkdFTkNZEAQ=');

@$core.Deprecated('Use modelFormatDescriptor instead')
const ModelFormat$json = {
  '1': 'ModelFormat',
  '2': [
    {'1': 'MODEL_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'MODEL_FORMAT_GGUF', '2': 1},
  ],
  '4': [
    {'1': 2, '2': 2},
  ],
  '5': ['MODEL_FORMAT_SAFETENSORS'],
};

/// Descriptor for `ModelFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelFormatDescriptor = $convert.base64Decode(
    'CgtNb2RlbEZvcm1hdBIcChhNT0RFTF9GT1JNQVRfVU5TUEVDSUZJRUQQABIVChFNT0RFTF9GT1'
    'JNQVRfR0dVRhABIgQIAhACKhhNT0RFTF9GT1JNQVRfU0FGRVRFTlNPUlM=');

@$core.Deprecated('Use modelStatusDescriptor instead')
const ModelStatus$json = {
  '1': 'ModelStatus',
  '2': [
    {'1': 'MODEL_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'MODEL_STATUS_READY', '2': 1},
    {'1': 'MODEL_STATUS_INVALID', '2': 2},
    {'1': 'MODEL_STATUS_INCOMPLETE', '2': 3},
  ],
};

/// Descriptor for `ModelStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelStatusDescriptor = $convert.base64Decode(
    'CgtNb2RlbFN0YXR1cxIcChhNT0RFTF9TVEFUVVNfVU5TUEVDSUZJRUQQABIWChJNT0RFTF9TVE'
    'FUVVNfUkVBRFkQARIYChRNT0RFTF9TVEFUVVNfSU5WQUxJRBACEhsKF01PREVMX1NUQVRVU19J'
    'TkNPTVBMRVRFEAM=');

@$core.Deprecated('Use issueSeverityDescriptor instead')
const IssueSeverity$json = {
  '1': 'IssueSeverity',
  '2': [
    {'1': 'ISSUE_SEVERITY_UNSPECIFIED', '2': 0},
    {'1': 'ISSUE_SEVERITY_WARNING', '2': 1},
    {'1': 'ISSUE_SEVERITY_ERROR', '2': 2},
  ],
};

/// Descriptor for `IssueSeverity`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List issueSeverityDescriptor = $convert.base64Decode(
    'Cg1Jc3N1ZVNldmVyaXR5Eh4KGklTU1VFX1NFVkVSSVRZX1VOU1BFQ0lGSUVEEAASGgoWSVNTVU'
    'VfU0VWRVJJVFlfV0FSTklORxABEhgKFElTU1VFX1NFVkVSSVRZX0VSUk9SEAI=');

@$core.Deprecated('Use changeModeDescriptor instead')
const ChangeMode$json = {
  '1': 'ChangeMode',
  '2': [
    {'1': 'CHANGE_MODE_UNSPECIFIED', '2': 0},
    {'1': 'CHANGE_MODE_LIVE', '2': 1},
    {'1': 'CHANGE_MODE_RESTART_REQUIRED', '2': 2},
  ],
};

/// Descriptor for `ChangeMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List changeModeDescriptor = $convert.base64Decode(
    'CgpDaGFuZ2VNb2RlEhsKF0NIQU5HRV9NT0RFX1VOU1BFQ0lGSUVEEAASFAoQQ0hBTkdFX01PRE'
    'VfTElWRRABEiAKHENIQU5HRV9NT0RFX1JFU1RBUlRfUkVRVUlSRUQQAg==');

@$core.Deprecated('Use confidenceDescriptor instead')
const Confidence$json = {
  '1': 'Confidence',
  '2': [
    {'1': 'CONFIDENCE_UNSPECIFIED', '2': 0},
    {'1': 'CONFIDENCE_MEASURED', '2': 1},
    {'1': 'CONFIDENCE_ESTIMATED', '2': 2},
  ],
};

/// Descriptor for `Confidence`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List confidenceDescriptor = $convert.base64Decode(
    'CgpDb25maWRlbmNlEhoKFkNPTkZJREVOQ0VfVU5TUEVDSUZJRUQQABIXChNDT05GSURFTkNFX0'
    '1FQVNVUkVEEAESGAoUQ09ORklERU5DRV9FU1RJTUFURUQQAg==');

@$core.Deprecated('Use engineConfigDescriptor instead')
const EngineConfig$json = {
  '1': 'EngineConfig',
  '2': [
    {
      '1': 'runtime',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.RuntimeKind',
      '10': 'runtime'
    },
    {
      '1': 'context_mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.ContextMode',
      '10': 'contextMode'
    },
    {
      '1': 'context_tokens',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'contextTokens',
      '17': true
    },
    {'1': 'max_sequences', '3': 4, '4': 1, '5': 5, '10': 'maxSequences'},
    {
      '1': 'priority',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.Priority',
      '10': 'priority'
    },
    {
      '1': 'kv_cache_policy',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.KvCachePolicy',
      '10': 'kvCachePolicy'
    },
    {
      '1': 'allow_fallback',
      '3': 7,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'allowFallback',
      '17': true
    },
    {'1': 'autostart', '3': 8, '4': 1, '5': 8, '10': 'autostart'},
    {
      '1': 'runtime_options',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'runtimeOptions'
    },
    {
      '1': 'generation_defaults',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'generationDefaults'
    },
    {
      '1': 'gateway_autostart',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'gatewayAutostart'
    },
    {'1': 'restart_on_crash', '3': 13, '4': 1, '5': 8, '10': 'restartOnCrash'},
    {
      '1': 'idle_timeout_seconds',
      '3': 14,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'idleTimeoutSeconds',
      '17': true
    },
  ],
  '8': [
    {'1': '_context_tokens'},
    {'1': '_allow_fallback'},
    {'1': '_idle_timeout_seconds'},
  ],
  '9': [
    {'1': 11, '2': 12},
  ],
  '10': ['trust_remote_code'],
};

/// Descriptor for `EngineConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineConfigDescriptor = $convert.base64Decode(
    'CgxFbmdpbmVDb25maWcSPQoHcnVudGltZRgBIAEoDjIjLmN1bHBlb3N0dWRpby5lbmdpbmUudj'
    'EuUnVudGltZUtpbmRSB3J1bnRpbWUSRgoMY29udGV4dF9tb2RlGAIgASgOMiMuY3VscGVvc3R1'
    'ZGlvLmVuZ2luZS52MS5Db250ZXh0TW9kZVILY29udGV4dE1vZGUSKgoOY29udGV4dF90b2tlbn'
    'MYAyABKAVIAFINY29udGV4dFRva2Vuc4gBARIjCg1tYXhfc2VxdWVuY2VzGAQgASgFUgxtYXhT'
    'ZXF1ZW5jZXMSPAoIcHJpb3JpdHkYBSABKA4yIC5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLlByaW'
    '9yaXR5Ughwcmlvcml0eRJNCg9rdl9jYWNoZV9wb2xpY3kYBiABKA4yJS5jdWxwZW9zdHVkaW8u'
    'ZW5naW5lLnYxLkt2Q2FjaGVQb2xpY3lSDWt2Q2FjaGVQb2xpY3kSKgoOYWxsb3dfZmFsbGJhY2'
    'sYByABKAhIAVINYWxsb3dGYWxsYmFja4gBARIcCglhdXRvc3RhcnQYCCABKAhSCWF1dG9zdGFy'
    'dBJACg9ydW50aW1lX29wdGlvbnMYCSABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0Ug5ydW'
    '50aW1lT3B0aW9ucxJIChNnZW5lcmF0aW9uX2RlZmF1bHRzGAogASgLMhcuZ29vZ2xlLnByb3Rv'
    'YnVmLlN0cnVjdFISZ2VuZXJhdGlvbkRlZmF1bHRzEisKEWdhdGV3YXlfYXV0b3N0YXJ0GAwgAS'
    'gIUhBnYXRld2F5QXV0b3N0YXJ0EigKEHJlc3RhcnRfb25fY3Jhc2gYDSABKAhSDnJlc3RhcnRP'
    'bkNyYXNoEjUKFGlkbGVfdGltZW91dF9zZWNvbmRzGA4gASgFSAJSEmlkbGVUaW1lb3V0U2Vjb2'
    '5kc4gBAUIRCg9fY29udGV4dF90b2tlbnNCEQoPX2FsbG93X2ZhbGxiYWNrQhcKFV9pZGxlX3Rp'
    'bWVvdXRfc2Vjb25kc0oECAsQDFIRdHJ1c3RfcmVtb3RlX2NvZGU=');

@$core.Deprecated('Use modelMetadataDescriptor instead')
const ModelMetadata$json = {
  '1': 'ModelMetadata',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'architecture', '3': 2, '4': 1, '5': 9, '10': 'architecture'},
    {'1': 'layers', '3': 3, '4': 1, '5': 5, '10': 'layers'},
    {'1': 'attention_heads', '3': 4, '4': 1, '5': 5, '10': 'attentionHeads'},
    {'1': 'kv_heads', '3': 5, '4': 1, '5': 5, '10': 'kvHeads'},
    {'1': 'head_dimension', '3': 6, '4': 1, '5': 5, '10': 'headDimension'},
    {
      '1': 'embedding_dimension',
      '3': 7,
      '4': 1,
      '5': 5,
      '10': 'embeddingDimension'
    },
    {'1': 'context_length', '3': 8, '4': 1, '5': 5, '10': 'contextLength'},
    {'1': 'sliding_window', '3': 9, '4': 1, '5': 5, '10': 'slidingWindow'},
    {'1': 'parameter_count', '3': 10, '4': 1, '5': 3, '10': 'parameterCount'},
    {'1': 'quantization', '3': 11, '4': 1, '5': 9, '10': 'quantization'},
    {
      '1': 'stored_tensor_data_type',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'storedTensorDataType'
    },
    {
      '1': 'expert_weight_bytes',
      '3': 13,
      '4': 1,
      '5': 3,
      '10': 'expertWeightBytes'
    },
    {'1': 'expert_layers', '3': 14, '4': 1, '5': 5, '10': 'expertLayers'},
  ],
};

/// Descriptor for `ModelMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelMetadataDescriptor = $convert.base64Decode(
    'Cg1Nb2RlbE1ldGFkYXRhEhIKBG5hbWUYASABKAlSBG5hbWUSIgoMYXJjaGl0ZWN0dXJlGAIgAS'
    'gJUgxhcmNoaXRlY3R1cmUSFgoGbGF5ZXJzGAMgASgFUgZsYXllcnMSJwoPYXR0ZW50aW9uX2hl'
    'YWRzGAQgASgFUg5hdHRlbnRpb25IZWFkcxIZCghrdl9oZWFkcxgFIAEoBVIHa3ZIZWFkcxIlCg'
    '5oZWFkX2RpbWVuc2lvbhgGIAEoBVINaGVhZERpbWVuc2lvbhIvChNlbWJlZGRpbmdfZGltZW5z'
    'aW9uGAcgASgFUhJlbWJlZGRpbmdEaW1lbnNpb24SJQoOY29udGV4dF9sZW5ndGgYCCABKAVSDW'
    'NvbnRleHRMZW5ndGgSJQoOc2xpZGluZ193aW5kb3cYCSABKAVSDXNsaWRpbmdXaW5kb3cSJwoP'
    'cGFyYW1ldGVyX2NvdW50GAogASgDUg5wYXJhbWV0ZXJDb3VudBIiCgxxdWFudGl6YXRpb24YCy'
    'ABKAlSDHF1YW50aXphdGlvbhI1ChdzdG9yZWRfdGVuc29yX2RhdGFfdHlwZRgMIAEoCVIUc3Rv'
    'cmVkVGVuc29yRGF0YVR5cGUSLgoTZXhwZXJ0X3dlaWdodF9ieXRlcxgNIAEoA1IRZXhwZXJ0V2'
    'VpZ2h0Qnl0ZXMSIwoNZXhwZXJ0X2xheWVycxgOIAEoBVIMZXhwZXJ0TGF5ZXJz');

@$core.Deprecated('Use validationIssueDescriptor instead')
const ValidationIssue$json = {
  '1': 'ValidationIssue',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {
      '1': 'severity',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.IssueSeverity',
      '10': 'severity'
    },
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'remediation', '3': 4, '4': 1, '5': 9, '10': 'remediation'},
  ],
};

/// Descriptor for `ValidationIssue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validationIssueDescriptor = $convert.base64Decode(
    'Cg9WYWxpZGF0aW9uSXNzdWUSEgoEY29kZRgBIAEoCVIEY29kZRJBCghzZXZlcml0eRgCIAEoDj'
    'IlLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuSXNzdWVTZXZlcml0eVIIc2V2ZXJpdHkSGAoHbWVz'
    'c2FnZRgDIAEoCVIHbWVzc2FnZRIgCgtyZW1lZGlhdGlvbhgEIAEoCVILcmVtZWRpYXRpb24=');

@$core.Deprecated('Use modelRecordDescriptor instead')
const ModelRecord$json = {
  '1': 'ModelRecord',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'fingerprint', '3': 2, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'relative_path', '3': 4, '4': 1, '5': 9, '10': 'relativePath'},
    {
      '1': 'format',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.ModelFormat',
      '10': 'format'
    },
    {'1': 'complete', '3': 6, '4': 1, '5': 8, '10': 'complete'},
    {'1': 'startable', '3': 7, '4': 1, '5': 8, '10': 'startable'},
    {'1': 'size_bytes', '3': 8, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'files', '3': 9, '4': 3, '5': 9, '10': 'files'},
    {
      '1': 'metadata',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ModelMetadata',
      '10': 'metadata'
    },
    {
      '1': 'runtime_candidates',
      '3': 11,
      '4': 3,
      '5': 14,
      '6': '.culpeostudio.engine.v1.RuntimeKind',
      '10': 'runtimeCandidates'
    },
    {
      '1': 'issues',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ValidationIssue',
      '10': 'issues'
    },
    {
      '1': 'status',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.ModelStatus',
      '10': 'status'
    },
    {'1': 'node_id', '3': 14, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'node_name', '3': 15, '4': 1, '5': 9, '10': 'nodeName'},
  ],
};

/// Descriptor for `ModelRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelRecordDescriptor = $convert.base64Decode(
    'CgtNb2RlbFJlY29yZBIOCgJpZBgBIAEoCVICaWQSIAoLZmluZ2VycHJpbnQYAiABKAlSC2Zpbm'
    'dlcnByaW50EhIKBG5hbWUYAyABKAlSBG5hbWUSIwoNcmVsYXRpdmVfcGF0aBgEIAEoCVIMcmVs'
    'YXRpdmVQYXRoEjsKBmZvcm1hdBgFIAEoDjIjLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuTW9kZW'
    'xGb3JtYXRSBmZvcm1hdBIaCghjb21wbGV0ZRgGIAEoCFIIY29tcGxldGUSHAoJc3RhcnRhYmxl'
    'GAcgASgIUglzdGFydGFibGUSHQoKc2l6ZV9ieXRlcxgIIAEoA1IJc2l6ZUJ5dGVzEhQKBWZpbG'
    'VzGAkgAygJUgVmaWxlcxJBCghtZXRhZGF0YRgKIAEoCzIlLmN1bHBlb3N0dWRpby5lbmdpbmUu'
    'djEuTW9kZWxNZXRhZGF0YVIIbWV0YWRhdGESUgoScnVudGltZV9jYW5kaWRhdGVzGAsgAygOMi'
    'MuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5SdW50aW1lS2luZFIRcnVudGltZUNhbmRpZGF0ZXMS'
    'PwoGaXNzdWVzGAwgAygLMicuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5WYWxpZGF0aW9uSXNzdW'
    'VSBmlzc3VlcxI7CgZzdGF0dXMYDSABKA4yIy5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLk1vZGVs'
    'U3RhdHVzUgZzdGF0dXMSFwoHbm9kZV9pZBgOIAEoCVIGbm9kZUlkEhsKCW5vZGVfbmFtZRgPIA'
    'EoCVIIbm9kZU5hbWU=');

@$core.Deprecated('Use hardwareSnapshotDescriptor instead')
const HardwareSnapshot$json = {
  '1': 'HardwareSnapshot',
  '2': [
    {'1': 'os', '3': 1, '4': 1, '5': 9, '10': 'os'},
    {'1': 'arch', '3': 2, '4': 1, '5': 9, '10': 'arch'},
    {'1': 'cpu_name', '3': 3, '4': 1, '5': 9, '10': 'cpuName'},
    {'1': 'cpu_cores', '3': 4, '4': 1, '5': 5, '10': 'cpuCores'},
    {'1': 'ram_total_bytes', '3': 5, '4': 1, '5': 3, '10': 'ramTotalBytes'},
    {
      '1': 'ram_available_bytes',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'ramAvailableBytes'
    },
    {'1': 'disk_free_bytes', '3': 7, '4': 1, '5': 3, '10': 'diskFreeBytes'},
    {
      '1': 'gpus',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.EngineGpu',
      '10': 'gpus'
    },
    {
      '1': 'gpu_telemetry_incomplete',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'gpuTelemetryIncomplete'
    },
    {
      '1': 'captured_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'capturedAt'
    },
    {'1': 'source', '3': 11, '4': 1, '5': 9, '10': 'source'},
  ],
};

/// Descriptor for `HardwareSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hardwareSnapshotDescriptor = $convert.base64Decode(
    'ChBIYXJkd2FyZVNuYXBzaG90Eg4KAm9zGAEgASgJUgJvcxISCgRhcmNoGAIgASgJUgRhcmNoEh'
    'kKCGNwdV9uYW1lGAMgASgJUgdjcHVOYW1lEhsKCWNwdV9jb3JlcxgEIAEoBVIIY3B1Q29yZXMS'
    'JgoPcmFtX3RvdGFsX2J5dGVzGAUgASgDUg1yYW1Ub3RhbEJ5dGVzEi4KE3JhbV9hdmFpbGFibG'
    'VfYnl0ZXMYBiABKANSEXJhbUF2YWlsYWJsZUJ5dGVzEiYKD2Rpc2tfZnJlZV9ieXRlcxgHIAEo'
    'A1INZGlza0ZyZWVCeXRlcxI3CgRncHVzGAggAygLMiMuY3VscGVvc3R1ZGlvLmhhcmR3YXJlLn'
    'YxLkVuZ2luZUdwdVIEZ3B1cxI4ChhncHVfdGVsZW1ldHJ5X2luY29tcGxldGUYCSABKAhSFmdw'
    'dVRlbGVtZXRyeUluY29tcGxldGUSOwoLY2FwdHVyZWRfYXQYCiABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wUgpjYXB0dXJlZEF0EhYKBnNvdXJjZRgLIAEoCVIGc291cmNl');

@$core.Deprecated('Use runtimeCapabilityDescriptor instead')
const RuntimeCapability$json = {
  '1': 'RuntimeCapability',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.RuntimeKind',
      '10': 'kind'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'installed', '3': 3, '4': 1, '5': 8, '10': 'installed'},
    {'1': 'healthy', '3': 4, '4': 1, '5': 8, '10': 'healthy'},
    {'1': 'environment', '3': 5, '4': 1, '5': 9, '10': 'environment'},
    {'1': 'gpu_backends', '3': 6, '4': 3, '5': 9, '10': 'gpuBackends'},
    {'1': 'kv_cache_modes', '3': 7, '4': 3, '5': 9, '10': 'kvCacheModes'},
    {
      '1': 'config_fields',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.RuntimeCapability.ConfigFieldsEntry',
      '10': 'configFields'
    },
    {'1': 'probe_error', '3': 9, '4': 1, '5': 9, '10': 'probeError'},
    {
      '1': 'last_probed_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastProbedAt'
    },
    {'1': 'status', '3': 11, '4': 1, '5': 9, '10': 'status'},
    {'1': 'status_message', '3': 12, '4': 1, '5': 9, '10': 'statusMessage'},
    {'1': 'progress', '3': 13, '4': 1, '5': 1, '10': 'progress'},
    {'1': 'error_code', '3': 14, '4': 1, '5': 9, '10': 'errorCode'},
    {'1': 'variant', '3': 15, '4': 1, '5': 9, '10': 'variant'},
    {'1': 'server_path', '3': 16, '4': 1, '5': 9, '10': 'serverPath'},
    {'1': 'build_version', '3': 17, '4': 1, '5': 9, '10': 'buildVersion'},
  ],
  '3': [RuntimeCapability_ConfigFieldsEntry$json],
};

@$core.Deprecated('Use runtimeCapabilityDescriptor instead')
const RuntimeCapability_ConfigFieldsEntry$json = {
  '1': 'ConfigFieldsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.ChangeMode',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `RuntimeCapability`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runtimeCapabilityDescriptor = $convert.base64Decode(
    'ChFSdW50aW1lQ2FwYWJpbGl0eRI3CgRraW5kGAEgASgOMiMuY3VscGVvc3R1ZGlvLmVuZ2luZS'
    '52MS5SdW50aW1lS2luZFIEa2luZBIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhwKCWluc3Rh'
    'bGxlZBgDIAEoCFIJaW5zdGFsbGVkEhgKB2hlYWx0aHkYBCABKAhSB2hlYWx0aHkSIAoLZW52aX'
    'Jvbm1lbnQYBSABKAlSC2Vudmlyb25tZW50EiEKDGdwdV9iYWNrZW5kcxgGIAMoCVILZ3B1QmFj'
    'a2VuZHMSJAoOa3ZfY2FjaGVfbW9kZXMYByADKAlSDGt2Q2FjaGVNb2RlcxJgCg1jb25maWdfZm'
    'llbGRzGAggAygLMjsuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5SdW50aW1lQ2FwYWJpbGl0eS5D'
    'b25maWdGaWVsZHNFbnRyeVIMY29uZmlnRmllbGRzEh8KC3Byb2JlX2Vycm9yGAkgASgJUgpwcm'
    '9iZUVycm9yEkAKDmxhc3RfcHJvYmVkX2F0GAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcFIMbGFzdFByb2JlZEF0EhYKBnN0YXR1cxgLIAEoCVIGc3RhdHVzEiUKDnN0YXR1c19tZX'
    'NzYWdlGAwgASgJUg1zdGF0dXNNZXNzYWdlEhoKCHByb2dyZXNzGA0gASgBUghwcm9ncmVzcxId'
    'CgplcnJvcl9jb2RlGA4gASgJUgllcnJvckNvZGUSGAoHdmFyaWFudBgPIAEoCVIHdmFyaWFudB'
    'IfCgtzZXJ2ZXJfcGF0aBgQIAEoCVIKc2VydmVyUGF0aBIjCg1idWlsZF92ZXJzaW9uGBEgASgJ'
    'UgxidWlsZFZlcnNpb24aYwoRQ29uZmlnRmllbGRzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSOA'
    'oFdmFsdWUYAiABKA4yIi5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLkNoYW5nZU1vZGVSBXZhbHVl'
    'OgI4AQ==');

@$core.Deprecated('Use engineDefaultsDescriptor instead')
const EngineDefaults$json = {
  '1': 'EngineDefaults',
  '2': [
    {
      '1': 'minimum_context_tokens',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'minimumContextTokens'
    },
    {
      '1': 'context_step_tokens',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'contextStepTokens'
    },
    {'1': 'ram_reserve', '3': 3, '4': 1, '5': 9, '10': 'ramReserve'},
    {'1': 'gpu_reserve', '3': 4, '4': 1, '5': 9, '10': 'gpuReserve'},
    {
      '1': 'emergency_ram_floor',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'emergencyRamFloor'
    },
    {
      '1': 'emergency_gpu_floor',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'emergencyGpuFloor'
    },
    {
      '1': 'kv_cache_policy',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.KvCachePolicy',
      '10': 'kvCachePolicy'
    },
    {'1': 'max_sequences', '3': 8, '4': 1, '5': 5, '10': 'maxSequences'},
    {'1': 'autostart', '3': 9, '4': 1, '5': 8, '10': 'autostart'},
    {'1': 'gateway_url', '3': 10, '4': 1, '5': 9, '10': 'gatewayUrl'},
    {
      '1': 'weight_quantization',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'weightQuantization'
    },
    {
      '1': 'ram_reserve_bytes',
      '3': 12,
      '4': 1,
      '5': 3,
      '10': 'ramReserveBytes'
    },
    {
      '1': 'gpu_reserve_bytes',
      '3': 13,
      '4': 1,
      '5': 3,
      '10': 'gpuReserveBytes'
    },
    {
      '1': 'gpu_reserve_bytes_by_id',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineDefaults.GpuReserveBytesByIdEntry',
      '10': 'gpuReserveBytesById'
    },
    {
      '1': 'ram_reserve_is_automatic',
      '3': 15,
      '4': 1,
      '5': 8,
      '10': 'ramReserveIsAutomatic'
    },
    {
      '1': 'gpu_reserve_is_automatic',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'gpuReserveIsAutomatic'
    },
  ],
  '3': [EngineDefaults_GpuReserveBytesByIdEntry$json],
};

@$core.Deprecated('Use engineDefaultsDescriptor instead')
const EngineDefaults_GpuReserveBytesByIdEntry$json = {
  '1': 'GpuReserveBytesByIdEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 3, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `EngineDefaults`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineDefaultsDescriptor = $convert.base64Decode(
    'Cg5FbmdpbmVEZWZhdWx0cxI0ChZtaW5pbXVtX2NvbnRleHRfdG9rZW5zGAEgASgFUhRtaW5pbX'
    'VtQ29udGV4dFRva2VucxIuChNjb250ZXh0X3N0ZXBfdG9rZW5zGAIgASgFUhFjb250ZXh0U3Rl'
    'cFRva2VucxIfCgtyYW1fcmVzZXJ2ZRgDIAEoCVIKcmFtUmVzZXJ2ZRIfCgtncHVfcmVzZXJ2ZR'
    'gEIAEoCVIKZ3B1UmVzZXJ2ZRIuChNlbWVyZ2VuY3lfcmFtX2Zsb29yGAUgASgJUhFlbWVyZ2Vu'
    'Y3lSYW1GbG9vchIuChNlbWVyZ2VuY3lfZ3B1X2Zsb29yGAYgASgJUhFlbWVyZ2VuY3lHcHVGbG'
    '9vchJNCg9rdl9jYWNoZV9wb2xpY3kYByABKA4yJS5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLkt2'
    'Q2FjaGVQb2xpY3lSDWt2Q2FjaGVQb2xpY3kSIwoNbWF4X3NlcXVlbmNlcxgIIAEoBVIMbWF4U2'
    'VxdWVuY2VzEhwKCWF1dG9zdGFydBgJIAEoCFIJYXV0b3N0YXJ0Eh8KC2dhdGV3YXlfdXJsGAog'
    'ASgJUgpnYXRld2F5VXJsEi8KE3dlaWdodF9xdWFudGl6YXRpb24YCyABKAlSEndlaWdodFF1YW'
    '50aXphdGlvbhIqChFyYW1fcmVzZXJ2ZV9ieXRlcxgMIAEoA1IPcmFtUmVzZXJ2ZUJ5dGVzEioK'
    'EWdwdV9yZXNlcnZlX2J5dGVzGA0gASgDUg9ncHVSZXNlcnZlQnl0ZXMSdQoXZ3B1X3Jlc2Vydm'
    'VfYnl0ZXNfYnlfaWQYDiADKAsyPy5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLkVuZ2luZURlZmF1'
    'bHRzLkdwdVJlc2VydmVCeXRlc0J5SWRFbnRyeVITZ3B1UmVzZXJ2ZUJ5dGVzQnlJZBI3ChhyYW'
    '1fcmVzZXJ2ZV9pc19hdXRvbWF0aWMYDyABKAhSFXJhbVJlc2VydmVJc0F1dG9tYXRpYxI3Chhn'
    'cHVfcmVzZXJ2ZV9pc19hdXRvbWF0aWMYECABKAhSFWdwdVJlc2VydmVJc0F1dG9tYXRpYxpGCh'
    'hHcHVSZXNlcnZlQnl0ZXNCeUlkRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB'
    'KANSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use memoryAllocationDescriptor instead')
const MemoryAllocation$json = {
  '1': 'MemoryAllocation',
  '2': [
    {'1': 'ram_bytes', '3': 1, '4': 1, '5': 3, '10': 'ramBytes'},
    {
      '1': 'gpu_bytes',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation.GpuBytesEntry',
      '10': 'gpuBytes'
    },
  ],
  '3': [MemoryAllocation_GpuBytesEntry$json],
};

@$core.Deprecated('Use memoryAllocationDescriptor instead')
const MemoryAllocation_GpuBytesEntry$json = {
  '1': 'GpuBytesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 3, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `MemoryAllocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memoryAllocationDescriptor = $convert.base64Decode(
    'ChBNZW1vcnlBbGxvY2F0aW9uEhsKCXJhbV9ieXRlcxgBIAEoA1IIcmFtQnl0ZXMSUwoJZ3B1X2'
    'J5dGVzGAIgAygLMjYuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5NZW1vcnlBbGxvY2F0aW9uLkdw'
    'dUJ5dGVzRW50cnlSCGdwdUJ5dGVzGjsKDUdwdUJ5dGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZX'
    'kSFAoFdmFsdWUYAiABKANSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use resourceBreakdownDescriptor instead')
const ResourceBreakdown$json = {
  '1': 'ResourceBreakdown',
  '2': [
    {
      '1': 'weights',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation',
      '10': 'weights'
    },
    {
      '1': 'kv_cache',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation',
      '10': 'kvCache'
    },
    {
      '1': 'runtime',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation',
      '10': 'runtime'
    },
    {
      '1': 'reserve',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation',
      '10': 'reserve'
    },
    {
      '1': 'total',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation',
      '10': 'total'
    },
  ],
};

/// Descriptor for `ResourceBreakdown`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resourceBreakdownDescriptor = $convert.base64Decode(
    'ChFSZXNvdXJjZUJyZWFrZG93bhJCCgd3ZWlnaHRzGAEgASgLMiguY3VscGVvc3R1ZGlvLmVuZ2'
    'luZS52MS5NZW1vcnlBbGxvY2F0aW9uUgd3ZWlnaHRzEkMKCGt2X2NhY2hlGAIgASgLMiguY3Vs'
    'cGVvc3R1ZGlvLmVuZ2luZS52MS5NZW1vcnlBbGxvY2F0aW9uUgdrdkNhY2hlEkIKB3J1bnRpbW'
    'UYAyABKAsyKC5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLk1lbW9yeUFsbG9jYXRpb25SB3J1bnRp'
    'bWUSQgoHcmVzZXJ2ZRgEIAEoCzIoLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuTWVtb3J5QWxsb2'
    'NhdGlvblIHcmVzZXJ2ZRI+CgV0b3RhbBgFIAEoCzIoLmN1bHBlb3N0dWRpby5lbmdpbmUudjEu'
    'TWVtb3J5QWxsb2NhdGlvblIFdG90YWw=');

@$core.Deprecated('Use preflightCheckDescriptor instead')
const PreflightCheck$json = {
  '1': 'PreflightCheck',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'state', '3': 2, '4': 1, '5': 9, '10': 'state'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'detail', '3': 4, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `PreflightCheck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preflightCheckDescriptor = $convert.base64Decode(
    'Cg5QcmVmbGlnaHRDaGVjaxIOCgJpZBgBIAEoCVICaWQSFAoFc3RhdGUYAiABKAlSBXN0YXRlEh'
    'QKBWxhYmVsGAMgASgJUgVsYWJlbBIWCgZkZXRhaWwYBCABKAlSBmRldGFpbA==');

@$core.Deprecated('Use preflightReportDescriptor instead')
const PreflightReport$json = {
  '1': 'PreflightReport',
  '2': [
    {
      '1': 'hardware_snapshot_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'hardwareSnapshotId'
    },
    {
      '1': 'model_fingerprint',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'modelFingerprint'
    },
    {
      '1': 'metadata_confidence',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'metadataConfidence'
    },
    {
      '1': 'checks',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.PreflightCheck',
      '10': 'checks'
    },
  ],
};

/// Descriptor for `PreflightReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preflightReportDescriptor = $convert.base64Decode(
    'Cg9QcmVmbGlnaHRSZXBvcnQSMAoUaGFyZHdhcmVfc25hcHNob3RfaWQYASABKAlSEmhhcmR3YX'
    'JlU25hcHNob3RJZBIrChFtb2RlbF9maW5nZXJwcmludBgCIAEoCVIQbW9kZWxGaW5nZXJwcmlu'
    'dBIvChNtZXRhZGF0YV9jb25maWRlbmNlGAMgASgJUhJtZXRhZGF0YUNvbmZpZGVuY2USPgoGY2'
    'hlY2tzGAQgAygLMiYuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5QcmVmbGlnaHRDaGVja1IGY2hl'
    'Y2tz');

@$core.Deprecated('Use contextPlanDescriptor instead')
const ContextPlan$json = {
  '1': 'ContextPlan',
  '2': [
    {
      '1': 'model_context_limit_tokens',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'modelContextLimitTokens'
    },
    {
      '1': 'gpu_only_max_context_tokens',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'gpuOnlyMaxContextTokens'
    },
    {
      '1': 'hybrid_max_context_tokens',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'hybridMaxContextTokens'
    },
    {
      '1': 'effective_context_tokens',
      '3': 4,
      '4': 1,
      '5': 5,
      '10': 'effectiveContextTokens'
    },
    {
      '1': 'ram_required_after_tokens',
      '3': 5,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'ramRequiredAfterTokens',
      '17': true
    },
    {
      '1': 'kv_bytes_per_token_at_start',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'kvBytesPerTokenAtStart'
    },
    {'1': 'max_sequences', '3': 7, '4': 1, '5': 5, '10': 'maxSequences'},
    {
      '1': 'kv_cache_dtype',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.KvCacheDtype',
      '10': 'kvCacheDtype'
    },
    {
      '1': 'priority',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.Priority',
      '10': 'priority'
    },
    {'1': 'pinned', '3': 10, '4': 1, '5': 8, '10': 'pinned'},
    {'1': 'restart_required', '3': 11, '4': 1, '5': 8, '10': 'restartRequired'},
    {'1': 'uses_ram', '3': 12, '4': 1, '5': 8, '10': 'usesRam'},
    {
      '1': 'memory',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ResourceBreakdown',
      '10': 'memory'
    },
    {
      '1': 'confidence',
      '3': 14,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.Confidence',
      '10': 'confidence'
    },
    {'1': 'warnings', '3': 15, '4': 3, '5': 9, '10': 'warnings'},
    {
      '1': 'affected_restart_instances',
      '3': 16,
      '4': 3,
      '5': 9,
      '10': 'affectedRestartInstances'
    },
    {
      '1': 'preflight',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.PreflightReport',
      '10': 'preflight'
    },
  ],
  '8': [
    {'1': '_ram_required_after_tokens'},
  ],
};

/// Descriptor for `ContextPlan`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextPlanDescriptor = $convert.base64Decode(
    'CgtDb250ZXh0UGxhbhI7Chptb2RlbF9jb250ZXh0X2xpbWl0X3Rva2VucxgBIAEoBVIXbW9kZW'
    'xDb250ZXh0TGltaXRUb2tlbnMSPAobZ3B1X29ubHlfbWF4X2NvbnRleHRfdG9rZW5zGAIgASgF'
    'UhdncHVPbmx5TWF4Q29udGV4dFRva2VucxI5ChloeWJyaWRfbWF4X2NvbnRleHRfdG9rZW5zGA'
    'MgASgFUhZoeWJyaWRNYXhDb250ZXh0VG9rZW5zEjgKGGVmZmVjdGl2ZV9jb250ZXh0X3Rva2Vu'
    'cxgEIAEoBVIWZWZmZWN0aXZlQ29udGV4dFRva2VucxI+ChlyYW1fcmVxdWlyZWRfYWZ0ZXJfdG'
    '9rZW5zGAUgASgFSABSFnJhbVJlcXVpcmVkQWZ0ZXJUb2tlbnOIAQESOwoba3ZfYnl0ZXNfcGVy'
    'X3Rva2VuX2F0X3N0YXJ0GAYgASgDUhZrdkJ5dGVzUGVyVG9rZW5BdFN0YXJ0EiMKDW1heF9zZX'
    'F1ZW5jZXMYByABKAVSDG1heFNlcXVlbmNlcxJKCg5rdl9jYWNoZV9kdHlwZRgIIAEoDjIkLmN1'
    'bHBlb3N0dWRpby5lbmdpbmUudjEuS3ZDYWNoZUR0eXBlUgxrdkNhY2hlRHR5cGUSPAoIcHJpb3'
    'JpdHkYCSABKA4yIC5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLlByaW9yaXR5Ughwcmlvcml0eRIW'
    'CgZwaW5uZWQYCiABKAhSBnBpbm5lZBIpChByZXN0YXJ0X3JlcXVpcmVkGAsgASgIUg9yZXN0YX'
    'J0UmVxdWlyZWQSGQoIdXNlc19yYW0YDCABKAhSB3VzZXNSYW0SQQoGbWVtb3J5GA0gASgLMiku'
    'Y3VscGVvc3R1ZGlvLmVuZ2luZS52MS5SZXNvdXJjZUJyZWFrZG93blIGbWVtb3J5EkIKCmNvbm'
    'ZpZGVuY2UYDiABKA4yIi5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLkNvbmZpZGVuY2VSCmNvbmZp'
    'ZGVuY2USGgoId2FybmluZ3MYDyADKAlSCHdhcm5pbmdzEjwKGmFmZmVjdGVkX3Jlc3RhcnRfaW'
    '5zdGFuY2VzGBAgAygJUhhhZmZlY3RlZFJlc3RhcnRJbnN0YW5jZXMSRQoJcHJlZmxpZ2h0GBEg'
    'ASgLMicuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5QcmVmbGlnaHRSZXBvcnRSCXByZWZsaWdodE'
    'IcChpfcmFtX3JlcXVpcmVkX2FmdGVyX3Rva2Vucw==');

@$core.Deprecated('Use fallbackDescriptor instead')
const Fallback$json = {
  '1': 'Fallback',
  '2': [
    {'1': 'setting', '3': 1, '4': 1, '5': 9, '10': 'setting'},
    {'1': 'from', '3': 2, '4': 1, '5': 9, '10': 'from'},
    {'1': 'to', '3': 3, '4': 1, '5': 9, '10': 'to'},
    {'1': 'reason', '3': 4, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `Fallback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fallbackDescriptor = $convert.base64Decode(
    'CghGYWxsYmFjaxIYCgdzZXR0aW5nGAEgASgJUgdzZXR0aW5nEhIKBGZyb20YAiABKAlSBGZyb2'
    '0SDgoCdG8YAyABKAlSAnRvEhYKBnJlYXNvbhgEIAEoCVIGcmVhc29u');

@$core.Deprecated('Use suggestedFixDescriptor instead')
const SuggestedFix$json = {
  '1': 'SuggestedFix',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `SuggestedFix`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestedFixDescriptor = $convert.base64Decode(
    'CgxTdWdnZXN0ZWRGaXgSFgoGYWN0aW9uGAEgASgJUgZhY3Rpb24SFAoFbGFiZWwYAiABKAlSBW'
    'xhYmVs');

@$core.Deprecated('Use engineInstanceDescriptor instead')
const EngineInstance$json = {
  '1': 'EngineInstance',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.InstanceState',
      '10': 'state'
    },
    {'1': 'model_id', '3': 3, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'served_model_name', '3': 4, '4': 1, '5': 9, '10': 'servedModelName'},
    {
      '1': 'requested_config',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'requestedConfig'
    },
    {
      '1': 'effective_config',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'effectiveConfig'
    },
    {
      '1': 'plan',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ContextPlan',
      '10': 'plan'
    },
    {
      '1': 'runtime',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.RuntimeKind',
      '10': 'runtime'
    },
    {
      '1': 'priority',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.Priority',
      '10': 'priority'
    },
    {'1': 'pinned', '3': 10, '4': 1, '5': 8, '10': 'pinned'},
    {'1': 'autostart', '3': 11, '4': 1, '5': 8, '10': 'autostart'},
    {
      '1': 'show_in_chat_picker',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'showInChatPicker'
    },
    {
      '1': 'placement',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.Placement',
      '10': 'placement'
    },
    {'1': 'active_requests', '3': 14, '4': 1, '5': 5, '10': 'activeRequests'},
    {
      '1': 'last_used_at',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUsedAt'
    },
    {
      '1': 'idle_expires_at',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'idleExpiresAt'
    },
    {
      '1': 'guard_state',
      '3': 17,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.GuardState',
      '10': 'guardState'
    },
    {
      '1': 'restart_required_fields',
      '3': 18,
      '4': 3,
      '5': 9,
      '10': 'restartRequiredFields'
    },
    {
      '1': 'fallbacks',
      '3': 19,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.Fallback',
      '10': 'fallbacks'
    },
    {'1': 'error', '3': 20, '4': 1, '5': 9, '10': 'error'},
    {'1': 'error_summary', '3': 21, '4': 1, '5': 9, '10': 'errorSummary'},
    {'1': 'error_code', '3': 22, '4': 1, '5': 9, '10': 'errorCode'},
    {
      '1': 'suggested_fix',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SuggestedFix',
      '10': 'suggestedFix'
    },
    {'1': 'phase', '3': 24, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'detail_message', '3': 25, '4': 1, '5': 9, '10': 'detailMessage'},
    {'1': 'progress', '3': 26, '4': 1, '5': 1, '10': 'progress'},
    {'1': 'endpoint_name', '3': 27, '4': 1, '5': 9, '10': 'endpointName'},
    {'1': 'plan_revision', '3': 28, '4': 1, '5': 3, '10': 'planRevision'},
    {
      '1': 'created_at',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {
      '1': 'gateway_autostart',
      '3': 31,
      '4': 1,
      '5': 8,
      '10': 'gatewayAutostart'
    },
    {'1': 'restart_on_crash', '3': 32, '4': 1, '5': 8, '10': 'restartOnCrash'},
    {
      '1': 'idle_timeout_seconds',
      '3': 33,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'idleTimeoutSeconds',
      '17': true
    },
    {'1': 'node_id', '3': 34, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'node_name', '3': 35, '4': 1, '5': 9, '10': 'nodeName'},
  ],
  '8': [
    {'1': '_idle_timeout_seconds'},
  ],
};

/// Descriptor for `EngineInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineInstanceDescriptor = $convert.base64Decode(
    'Cg5FbmdpbmVJbnN0YW5jZRIOCgJpZBgBIAEoCVICaWQSOwoFc3RhdGUYAiABKA4yJS5jdWxwZW'
    '9zdHVkaW8uZW5naW5lLnYxLkluc3RhbmNlU3RhdGVSBXN0YXRlEhkKCG1vZGVsX2lkGAMgASgJ'
    'Ugdtb2RlbElkEioKEXNlcnZlZF9tb2RlbF9uYW1lGAQgASgJUg9zZXJ2ZWRNb2RlbE5hbWUSTw'
    'oQcmVxdWVzdGVkX2NvbmZpZxgFIAEoCzIkLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuRW5naW5l'
    'Q29uZmlnUg9yZXF1ZXN0ZWRDb25maWcSTwoQZWZmZWN0aXZlX2NvbmZpZxgGIAEoCzIkLmN1bH'
    'Blb3N0dWRpby5lbmdpbmUudjEuRW5naW5lQ29uZmlnUg9lZmZlY3RpdmVDb25maWcSNwoEcGxh'
    'bhgHIAEoCzIjLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuQ29udGV4dFBsYW5SBHBsYW4SPQoHcn'
    'VudGltZRgIIAEoDjIjLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuUnVudGltZUtpbmRSB3J1bnRp'
    'bWUSPAoIcHJpb3JpdHkYCSABKA4yIC5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLlByaW9yaXR5Ug'
    'hwcmlvcml0eRIWCgZwaW5uZWQYCiABKAhSBnBpbm5lZBIcCglhdXRvc3RhcnQYCyABKAhSCWF1'
    'dG9zdGFydBItChNzaG93X2luX2NoYXRfcGlja2VyGAwgASgIUhBzaG93SW5DaGF0UGlja2VyEj'
    '8KCXBsYWNlbWVudBgNIAEoDjIhLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuUGxhY2VtZW50Uglw'
    'bGFjZW1lbnQSJwoPYWN0aXZlX3JlcXVlc3RzGA4gASgFUg5hY3RpdmVSZXF1ZXN0cxI8CgxsYX'
    'N0X3VzZWRfYXQYDyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpsYXN0VXNlZEF0'
    'EkIKD2lkbGVfZXhwaXJlc19hdBgQIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDW'
    'lkbGVFeHBpcmVzQXQSQwoLZ3VhcmRfc3RhdGUYESABKA4yIi5jdWxwZW9zdHVkaW8uZW5naW5l'
    'LnYxLkd1YXJkU3RhdGVSCmd1YXJkU3RhdGUSNgoXcmVzdGFydF9yZXF1aXJlZF9maWVsZHMYEi'
    'ADKAlSFXJlc3RhcnRSZXF1aXJlZEZpZWxkcxI+CglmYWxsYmFja3MYEyADKAsyIC5jdWxwZW9z'
    'dHVkaW8uZW5naW5lLnYxLkZhbGxiYWNrUglmYWxsYmFja3MSFAoFZXJyb3IYFCABKAlSBWVycm'
    '9yEiMKDWVycm9yX3N1bW1hcnkYFSABKAlSDGVycm9yU3VtbWFyeRIdCgplcnJvcl9jb2RlGBYg'
    'ASgJUgllcnJvckNvZGUSSQoNc3VnZ2VzdGVkX2ZpeBgXIAEoCzIkLmN1bHBlb3N0dWRpby5lbm'
    'dpbmUudjEuU3VnZ2VzdGVkRml4UgxzdWdnZXN0ZWRGaXgSFAoFcGhhc2UYGCABKAlSBXBoYXNl'
    'EiUKDmRldGFpbF9tZXNzYWdlGBkgASgJUg1kZXRhaWxNZXNzYWdlEhoKCHByb2dyZXNzGBogAS'
    'gBUghwcm9ncmVzcxIjCg1lbmRwb2ludF9uYW1lGBsgASgJUgxlbmRwb2ludE5hbWUSIwoNcGxh'
    'bl9yZXZpc2lvbhgcIAEoA1IMcGxhblJldmlzaW9uEjkKCmNyZWF0ZWRfYXQYHSABKAsyGi5nb2'
    '9nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSOQoKdXBkYXRlZF9hdBgeIAEoCzIa'
    'Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXVwZGF0ZWRBdBIrChFnYXRld2F5X2F1dG9zdG'
    'FydBgfIAEoCFIQZ2F0ZXdheUF1dG9zdGFydBIoChByZXN0YXJ0X29uX2NyYXNoGCAgASgIUg5y'
    'ZXN0YXJ0T25DcmFzaBI1ChRpZGxlX3RpbWVvdXRfc2Vjb25kcxghIAEoBUgAUhJpZGxlVGltZW'
    '91dFNlY29uZHOIAQESFwoHbm9kZV9pZBgiIAEoCVIGbm9kZUlkEhsKCW5vZGVfbmFtZRgjIAEo'
    'CVIIbm9kZU5hbWVCFwoVX2lkbGVfdGltZW91dF9zZWNvbmRz');

@$core.Deprecated('Use resourceConflictDescriptor instead')
const ResourceConflict$json = {
  '1': 'ResourceConflict',
  '2': [
    {'1': 'resource', '3': 1, '4': 1, '5': 9, '10': 'resource'},
    {'1': 'required_bytes', '3': 2, '4': 1, '5': 3, '10': 'requiredBytes'},
    {'1': 'available_bytes', '3': 3, '4': 1, '5': 3, '10': 'availableBytes'},
    {'1': 'reserve_bytes', '3': 4, '4': 1, '5': 3, '10': 'reserveBytes'},
    {'1': 'total_bytes', '3': 5, '4': 1, '5': 3, '10': 'totalBytes'},
    {'1': 'reason', '3': 6, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'instance_id', '3': 7, '4': 1, '5': 9, '10': 'instanceId'},
  ],
};

/// Descriptor for `ResourceConflict`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resourceConflictDescriptor = $convert.base64Decode(
    'ChBSZXNvdXJjZUNvbmZsaWN0EhoKCHJlc291cmNlGAEgASgJUghyZXNvdXJjZRIlCg5yZXF1aX'
    'JlZF9ieXRlcxgCIAEoA1INcmVxdWlyZWRCeXRlcxInCg9hdmFpbGFibGVfYnl0ZXMYAyABKANS'
    'DmF2YWlsYWJsZUJ5dGVzEiMKDXJlc2VydmVfYnl0ZXMYBCABKANSDHJlc2VydmVCeXRlcxIfCg'
    't0b3RhbF9ieXRlcxgFIAEoA1IKdG90YWxCeXRlcxIWCgZyZWFzb24YBiABKAlSBnJlYXNvbhIf'
    'CgtpbnN0YW5jZV9pZBgHIAEoCVIKaW5zdGFuY2VJZA==');

@$core.Deprecated('Use engineOperationDescriptor instead')
const EngineOperation$json = {
  '1': 'EngineOperation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.OperationState',
      '10': 'state'
    },
    {'1': 'instance_id', '3': 4, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'queue_position', '3': 5, '4': 1, '5': 5, '10': 'queuePosition'},
    {'1': 'progress', '3': 6, '4': 1, '5': 1, '10': 'progress'},
    {'1': 'message', '3': 7, '4': 1, '5': 9, '10': 'message'},
    {'1': 'detail_message', '3': 8, '4': 1, '5': 9, '10': 'detailMessage'},
    {'1': 'phase', '3': 9, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'error', '3': 10, '4': 1, '5': 9, '10': 'error'},
    {'1': 'error_summary', '3': 11, '4': 1, '5': 9, '10': 'errorSummary'},
    {'1': 'error_code', '3': 12, '4': 1, '5': 9, '10': 'errorCode'},
    {
      '1': 'suggested_fix',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SuggestedFix',
      '10': 'suggestedFix'
    },
    {
      '1': 'resource_conflict',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ResourceConflict',
      '10': 'resourceConflict'
    },
    {
      '1': 'created_at',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {
      '1': 'finished_at',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'finishedAt'
    },
    {
      '1': 'evicted_instance_ids',
      '3': 18,
      '4': 3,
      '5': 9,
      '10': 'evictedInstanceIds'
    },
  ],
};

/// Descriptor for `EngineOperation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineOperationDescriptor = $convert.base64Decode(
    'Cg9FbmdpbmVPcGVyYXRpb24SDgoCaWQYASABKAlSAmlkEhIKBHR5cGUYAiABKAlSBHR5cGUSPA'
    'oFc3RhdGUYAyABKA4yJi5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLk9wZXJhdGlvblN0YXRlUgVz'
    'dGF0ZRIfCgtpbnN0YW5jZV9pZBgEIAEoCVIKaW5zdGFuY2VJZBIlCg5xdWV1ZV9wb3NpdGlvbh'
    'gFIAEoBVINcXVldWVQb3NpdGlvbhIaCghwcm9ncmVzcxgGIAEoAVIIcHJvZ3Jlc3MSGAoHbWVz'
    'c2FnZRgHIAEoCVIHbWVzc2FnZRIlCg5kZXRhaWxfbWVzc2FnZRgIIAEoCVINZGV0YWlsTWVzc2'
    'FnZRIUCgVwaGFzZRgJIAEoCVIFcGhhc2USFAoFZXJyb3IYCiABKAlSBWVycm9yEiMKDWVycm9y'
    'X3N1bW1hcnkYCyABKAlSDGVycm9yU3VtbWFyeRIdCgplcnJvcl9jb2RlGAwgASgJUgllcnJvck'
    'NvZGUSSQoNc3VnZ2VzdGVkX2ZpeBgNIAEoCzIkLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuU3Vn'
    'Z2VzdGVkRml4UgxzdWdnZXN0ZWRGaXgSVQoRcmVzb3VyY2VfY29uZmxpY3QYDiABKAsyKC5jdW'
    'xwZW9zdHVkaW8uZW5naW5lLnYxLlJlc291cmNlQ29uZmxpY3RSEHJlc291cmNlQ29uZmxpY3QS'
    'OQoKY3JlYXRlZF9hdBgPIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZW'
    'RBdBI5Cgp1cGRhdGVkX2F0GBAgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJdXBk'
    'YXRlZEF0EjsKC2ZpbmlzaGVkX2F0GBEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcF'
    'IKZmluaXNoZWRBdBIwChRldmljdGVkX2luc3RhbmNlX2lkcxgSIAMoCVISZXZpY3RlZEluc3Rh'
    'bmNlSWRz');

@$core.Deprecated('Use engineErrorDescriptor instead')
const EngineError$json = {
  '1': 'EngineError',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'conflict',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ResourceConflict',
      '10': 'conflict'
    },
    {'1': 'reason', '3': 4, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'remediation', '3': 5, '4': 1, '5': 9, '10': 'remediation'},
    {
      '1': 'model_fingerprint',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'modelFingerprint'
    },
  ],
  '9': [
    {'1': 7, '2': 8},
    {'1': 8, '2': 9},
  ],
  '10': ['python_files_hash', 'python_file_count'],
};

/// Descriptor for `EngineError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineErrorDescriptor = $convert.base64Decode(
    'CgtFbmdpbmVFcnJvchISCgRjb2RlGAEgASgJUgRjb2RlEhgKB21lc3NhZ2UYAiABKAlSB21lc3'
    'NhZ2USRAoIY29uZmxpY3QYAyABKAsyKC5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLlJlc291cmNl'
    'Q29uZmxpY3RSCGNvbmZsaWN0EhYKBnJlYXNvbhgEIAEoCVIGcmVhc29uEiAKC3JlbWVkaWF0aW'
    '9uGAUgASgJUgtyZW1lZGlhdGlvbhIrChFtb2RlbF9maW5nZXJwcmludBgGIAEoCVIQbW9kZWxG'
    'aW5nZXJwcmludEoECAcQCEoECAgQCVIRcHl0aG9uX2ZpbGVzX2hhc2hSEXB5dGhvbl9maWxlX2'
    'NvdW50');

@$core.Deprecated('Use listModelsRequestDescriptor instead')
const ListModelsRequest$json = {
  '1': 'ListModelsRequest',
};

/// Descriptor for `ListModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModelsRequestDescriptor =
    $convert.base64Decode('ChFMaXN0TW9kZWxzUmVxdWVzdA==');

@$core.Deprecated('Use listModelsResponseDescriptor instead')
const ListModelsResponse$json = {
  '1': 'ListModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ModelRecord',
      '10': 'models'
    },
    {'1': 'model_dir', '3': 2, '4': 1, '5': 9, '10': 'modelDir'},
  ],
};

/// Descriptor for `ListModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModelsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0TW9kZWxzUmVzcG9uc2USOwoGbW9kZWxzGAEgAygLMiMuY3VscGVvc3R1ZGlvLmVuZ2'
    'luZS52MS5Nb2RlbFJlY29yZFIGbW9kZWxzEhsKCW1vZGVsX2RpchgCIAEoCVIIbW9kZWxEaXI=');

@$core.Deprecated('Use rescanModelsRequestDescriptor instead')
const RescanModelsRequest$json = {
  '1': 'RescanModelsRequest',
};

/// Descriptor for `RescanModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rescanModelsRequestDescriptor =
    $convert.base64Decode('ChNSZXNjYW5Nb2RlbHNSZXF1ZXN0');

@$core.Deprecated('Use rescanModelsResponseDescriptor instead')
const RescanModelsResponse$json = {
  '1': 'RescanModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ModelRecord',
      '10': 'models'
    },
    {'1': 'model_dir', '3': 2, '4': 1, '5': 9, '10': 'modelDir'},
  ],
};

/// Descriptor for `RescanModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rescanModelsResponseDescriptor = $convert.base64Decode(
    'ChRSZXNjYW5Nb2RlbHNSZXNwb25zZRI7CgZtb2RlbHMYASADKAsyIy5jdWxwZW9zdHVkaW8uZW'
    '5naW5lLnYxLk1vZGVsUmVjb3JkUgZtb2RlbHMSGwoJbW9kZWxfZGlyGAIgASgJUghtb2RlbERp'
    'cg==');

@$core.Deprecated('Use deleteModelRequestDescriptor instead')
const DeleteModelRequest$json = {
  '1': 'DeleteModelRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
  ],
};

/// Descriptor for `DeleteModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteModelRequestDescriptor =
    $convert.base64Decode(
        'ChJEZWxldGVNb2RlbFJlcXVlc3QSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQ=');

@$core.Deprecated('Use deleteModelResponseDescriptor instead')
const DeleteModelResponse$json = {
  '1': 'DeleteModelResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ModelRecord',
      '10': 'models'
    },
    {'1': 'model_dir', '3': 2, '4': 1, '5': 9, '10': 'modelDir'},
  ],
};

/// Descriptor for `DeleteModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteModelResponseDescriptor = $convert.base64Decode(
    'ChNEZWxldGVNb2RlbFJlc3BvbnNlEjsKBm1vZGVscxgBIAMoCzIjLmN1bHBlb3N0dWRpby5lbm'
    'dpbmUudjEuTW9kZWxSZWNvcmRSBm1vZGVscxIbCgltb2RlbF9kaXIYAiABKAlSCG1vZGVsRGly');

@$core.Deprecated('Use getCapabilitiesRequestDescriptor instead')
const GetCapabilitiesRequest$json = {
  '1': 'GetCapabilitiesRequest',
};

/// Descriptor for `GetCapabilitiesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCapabilitiesRequestDescriptor =
    $convert.base64Decode('ChZHZXRDYXBhYmlsaXRpZXNSZXF1ZXN0');

@$core.Deprecated('Use getCapabilitiesResponseDescriptor instead')
const GetCapabilitiesResponse$json = {
  '1': 'GetCapabilitiesResponse',
  '2': [
    {
      '1': 'hardware',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.HardwareSnapshot',
      '10': 'hardware'
    },
    {
      '1': 'runtimes',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.RuntimeCapability',
      '10': 'runtimes'
    },
    {
      '1': 'defaults',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineDefaults',
      '10': 'defaults'
    },
  ],
};

/// Descriptor for `GetCapabilitiesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCapabilitiesResponseDescriptor = $convert.base64Decode(
    'ChdHZXRDYXBhYmlsaXRpZXNSZXNwb25zZRJECghoYXJkd2FyZRgBIAEoCzIoLmN1bHBlb3N0dW'
    'Rpby5lbmdpbmUudjEuSGFyZHdhcmVTbmFwc2hvdFIIaGFyZHdhcmUSRQoIcnVudGltZXMYAiAD'
    'KAsyKS5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLlJ1bnRpbWVDYXBhYmlsaXR5UghydW50aW1lcx'
    'JCCghkZWZhdWx0cxgDIAEoCzImLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuRW5naW5lRGVmYXVs'
    'dHNSCGRlZmF1bHRz');

@$core.Deprecated('Use getRecommendationRequestDescriptor instead')
const GetRecommendationRequest$json = {
  '1': 'GetRecommendationRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {
      '1': 'config',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'config'
    },
  ],
};

/// Descriptor for `GetRecommendationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRecommendationRequestDescriptor = $convert.base64Decode(
    'ChhHZXRSZWNvbW1lbmRhdGlvblJlcXVlc3QSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQSPA'
    'oGY29uZmlnGAIgASgLMiQuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5FbmdpbmVDb25maWdSBmNv'
    'bmZpZw==');

@$core.Deprecated('Use getRecommendationResponseDescriptor instead')
const GetRecommendationResponse$json = {
  '1': 'GetRecommendationResponse',
  '2': [
    {
      '1': 'plan',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ContextPlan',
      '10': 'plan'
    },
  ],
};

/// Descriptor for `GetRecommendationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRecommendationResponseDescriptor =
    $convert.base64Decode(
        'ChlHZXRSZWNvbW1lbmRhdGlvblJlc3BvbnNlEjcKBHBsYW4YASABKAsyIy5jdWxwZW9zdHVkaW'
        '8uZW5naW5lLnYxLkNvbnRleHRQbGFuUgRwbGFu');

@$core.Deprecated('Use simulateModelEntryDescriptor instead')
const SimulateModelEntry$json = {
  '1': 'SimulateModelEntry',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {
      '1': 'config',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'config'
    },
  ],
};

/// Descriptor for `SimulateModelEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulateModelEntryDescriptor = $convert.base64Decode(
    'ChJTaW11bGF0ZU1vZGVsRW50cnkSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQSPAoGY29uZm'
    'lnGAIgASgLMiQuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5FbmdpbmVDb25maWdSBmNvbmZpZw==');

@$core.Deprecated('Use simulateParallelLoadRequestDescriptor instead')
const SimulateParallelLoadRequest$json = {
  '1': 'SimulateParallelLoadRequest',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SimulateModelEntry',
      '10': 'models'
    },
    {
      '1': 'include_running',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'includeRunning',
      '17': true
    },
  ],
  '8': [
    {'1': '_include_running'},
  ],
};

/// Descriptor for `SimulateParallelLoadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulateParallelLoadRequestDescriptor = $convert.base64Decode(
    'ChtTaW11bGF0ZVBhcmFsbGVsTG9hZFJlcXVlc3QSQgoGbW9kZWxzGAEgAygLMiouY3VscGVvc3'
    'R1ZGlvLmVuZ2luZS52MS5TaW11bGF0ZU1vZGVsRW50cnlSBm1vZGVscxIsCg9pbmNsdWRlX3J1'
    'bm5pbmcYAiABKAhIAFIOaW5jbHVkZVJ1bm5pbmeIAQFCEgoQX2luY2x1ZGVfcnVubmluZw==');

@$core.Deprecated('Use simulatedModelDescriptor instead')
const SimulatedModel$json = {
  '1': 'SimulatedModel',
  '2': [
    {'1': 'model', '3': 1, '4': 1, '5': 9, '10': 'model'},
    {'1': 'fits', '3': 2, '4': 1, '5': 8, '10': 'fits'},
    {
      '1': 'effective_context_tokens',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'effectiveContextTokens'
    },
    {
      '1': 'placement',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.Placement',
      '10': 'placement'
    },
    {
      '1': 'memory',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation',
      '10': 'memory'
    },
    {'1': 'warnings', '3': 6, '4': 3, '5': 9, '10': 'warnings'},
    {'1': 'reason', '3': 7, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `SimulatedModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulatedModelDescriptor = $convert.base64Decode(
    'Cg5TaW11bGF0ZWRNb2RlbBIUCgVtb2RlbBgBIAEoCVIFbW9kZWwSEgoEZml0cxgCIAEoCFIEZm'
    'l0cxI4ChhlZmZlY3RpdmVfY29udGV4dF90b2tlbnMYAyABKAVSFmVmZmVjdGl2ZUNvbnRleHRU'
    'b2tlbnMSPwoJcGxhY2VtZW50GAQgASgOMiEuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5QbGFjZW'
    '1lbnRSCXBsYWNlbWVudBJACgZtZW1vcnkYBSABKAsyKC5jdWxwZW9zdHVkaW8uZW5naW5lLnYx'
    'Lk1lbW9yeUFsbG9jYXRpb25SBm1lbW9yeRIaCgh3YXJuaW5ncxgGIAMoCVIId2FybmluZ3MSFg'
    'oGcmVhc29uGAcgASgJUgZyZWFzb24=');

@$core.Deprecated('Use simulatedGpuBudgetDescriptor instead')
const SimulatedGpuBudget$json = {
  '1': 'SimulatedGpuBudget',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'vram_total_bytes', '3': 3, '4': 1, '5': 3, '10': 'vramTotalBytes'},
    {'1': 'vram_free_bytes', '3': 4, '4': 1, '5': 3, '10': 'vramFreeBytes'},
    {'1': 'planned_bytes', '3': 5, '4': 1, '5': 3, '10': 'plannedBytes'},
  ],
};

/// Descriptor for `SimulatedGpuBudget`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulatedGpuBudgetDescriptor = $convert.base64Decode(
    'ChJTaW11bGF0ZWRHcHVCdWRnZXQSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USKAoQdnJhbV90b3RhbF9ieXRlcxgDIAEoA1IOdnJhbVRvdGFsQnl0ZXMSJgoPdnJhbV9mcmVl'
    'X2J5dGVzGAQgASgDUg12cmFtRnJlZUJ5dGVzEiMKDXBsYW5uZWRfYnl0ZXMYBSABKANSDHBsYW'
    '5uZWRCeXRlcw==');

@$core.Deprecated('Use simulatedHostDescriptor instead')
const SimulatedHost$json = {
  '1': 'SimulatedHost',
  '2': [
    {'1': 'ram_total_bytes', '3': 1, '4': 1, '5': 3, '10': 'ramTotalBytes'},
    {
      '1': 'ram_available_bytes',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'ramAvailableBytes'
    },
    {'1': 'ram_reserve_bytes', '3': 3, '4': 1, '5': 3, '10': 'ramReserveBytes'},
    {
      '1': 'gpus',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SimulatedGpuBudget',
      '10': 'gpus'
    },
  ],
};

/// Descriptor for `SimulatedHost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulatedHostDescriptor = $convert.base64Decode(
    'Cg1TaW11bGF0ZWRIb3N0EiYKD3JhbV90b3RhbF9ieXRlcxgBIAEoA1INcmFtVG90YWxCeXRlcx'
    'IuChNyYW1fYXZhaWxhYmxlX2J5dGVzGAIgASgDUhFyYW1BdmFpbGFibGVCeXRlcxIqChFyYW1f'
    'cmVzZXJ2ZV9ieXRlcxgDIAEoA1IPcmFtUmVzZXJ2ZUJ5dGVzEj4KBGdwdXMYBCADKAsyKi5jdW'
    'xwZW9zdHVkaW8uZW5naW5lLnYxLlNpbXVsYXRlZEdwdUJ1ZGdldFIEZ3B1cw==');

@$core.Deprecated('Use simulateParallelLoadResponseDescriptor instead')
const SimulateParallelLoadResponse$json = {
  '1': 'SimulateParallelLoadResponse',
  '2': [
    {'1': 'feasible', '3': 1, '4': 1, '5': 8, '10': 'feasible'},
    {
      '1': 'models',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SimulatedModel',
      '10': 'models'
    },
    {
      '1': 'totals',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.MemoryAllocation',
      '10': 'totals'
    },
    {
      '1': 'host',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SimulatedHost',
      '10': 'host'
    },
    {
      '1': 'affected_running_instances',
      '3': 5,
      '4': 3,
      '5': 9,
      '10': 'affectedRunningInstances'
    },
    {'1': 'recommendations', '3': 6, '4': 3, '5': 9, '10': 'recommendations'},
    {'1': 'reason', '3': 7, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `SimulateParallelLoadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simulateParallelLoadResponseDescriptor = $convert.base64Decode(
    'ChxTaW11bGF0ZVBhcmFsbGVsTG9hZFJlc3BvbnNlEhoKCGZlYXNpYmxlGAEgASgIUghmZWFzaW'
    'JsZRI+CgZtb2RlbHMYAiADKAsyJi5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLlNpbXVsYXRlZE1v'
    'ZGVsUgZtb2RlbHMSQAoGdG90YWxzGAMgASgLMiguY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5NZW'
    '1vcnlBbGxvY2F0aW9uUgZ0b3RhbHMSOQoEaG9zdBgEIAEoCzIlLmN1bHBlb3N0dWRpby5lbmdp'
    'bmUudjEuU2ltdWxhdGVkSG9zdFIEaG9zdBI8ChphZmZlY3RlZF9ydW5uaW5nX2luc3RhbmNlcx'
    'gFIAMoCVIYYWZmZWN0ZWRSdW5uaW5nSW5zdGFuY2VzEigKD3JlY29tbWVuZGF0aW9ucxgGIAMo'
    'CVIPcmVjb21tZW5kYXRpb25zEhYKBnJlYXNvbhgHIAEoCVIGcmVhc29u');

@$core.Deprecated('Use listInstancesRequestDescriptor instead')
const ListInstancesRequest$json = {
  '1': 'ListInstancesRequest',
};

/// Descriptor for `ListInstancesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listInstancesRequestDescriptor =
    $convert.base64Decode('ChRMaXN0SW5zdGFuY2VzUmVxdWVzdA==');

@$core.Deprecated('Use listInstancesResponseDescriptor instead')
const ListInstancesResponse$json = {
  '1': 'ListInstancesResponse',
  '2': [
    {
      '1': 'instances',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '10': 'instances'
    },
  ],
};

/// Descriptor for `ListInstancesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listInstancesResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0SW5zdGFuY2VzUmVzcG9uc2USRAoJaW5zdGFuY2VzGAEgAygLMiYuY3VscGVvc3R1ZG'
    'lvLmVuZ2luZS52MS5FbmdpbmVJbnN0YW5jZVIJaW5zdGFuY2Vz');

@$core.Deprecated('Use createInstanceRequestDescriptor instead')
const CreateInstanceRequest$json = {
  '1': 'CreateInstanceRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'served_model_name', '3': 2, '4': 1, '5': 9, '10': 'servedModelName'},
    {
      '1': 'config',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'config'
    },
    {'1': 'node_id', '3': 4, '4': 1, '5': 9, '10': 'nodeId'},
  ],
};

/// Descriptor for `CreateInstanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createInstanceRequestDescriptor = $convert.base64Decode(
    'ChVDcmVhdGVJbnN0YW5jZVJlcXVlc3QSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQSKgoRc2'
    'VydmVkX21vZGVsX25hbWUYAiABKAlSD3NlcnZlZE1vZGVsTmFtZRI8CgZjb25maWcYAyABKAsy'
    'JC5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLkVuZ2luZUNvbmZpZ1IGY29uZmlnEhcKB25vZGVfaW'
    'QYBCABKAlSBm5vZGVJZA==');

@$core.Deprecated('Use createInstanceResponseDescriptor instead')
const CreateInstanceResponse$json = {
  '1': 'CreateInstanceResponse',
  '2': [
    {
      '1': 'instance',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '10': 'instance'
    },
    {'1': 'operation_id', '3': 2, '4': 1, '5': 9, '10': 'operationId'},
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.OperationState',
      '10': 'state'
    },
    {'1': 'queue_position', '3': 4, '4': 1, '5': 5, '10': 'queuePosition'},
  ],
};

/// Descriptor for `CreateInstanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createInstanceResponseDescriptor = $convert.base64Decode(
    'ChZDcmVhdGVJbnN0YW5jZVJlc3BvbnNlEkIKCGluc3RhbmNlGAEgASgLMiYuY3VscGVvc3R1ZG'
    'lvLmVuZ2luZS52MS5FbmdpbmVJbnN0YW5jZVIIaW5zdGFuY2USIQoMb3BlcmF0aW9uX2lkGAIg'
    'ASgJUgtvcGVyYXRpb25JZBI8CgVzdGF0ZRgDIAEoDjImLmN1bHBlb3N0dWRpby5lbmdpbmUudj'
    'EuT3BlcmF0aW9uU3RhdGVSBXN0YXRlEiUKDnF1ZXVlX3Bvc2l0aW9uGAQgASgFUg1xdWV1ZVBv'
    'c2l0aW9u');

@$core.Deprecated('Use getInstanceRequestDescriptor instead')
const GetInstanceRequest$json = {
  '1': 'GetInstanceRequest',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
  ],
};

/// Descriptor for `GetInstanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstanceRequestDescriptor = $convert.base64Decode(
    'ChJHZXRJbnN0YW5jZVJlcXVlc3QSHwoLaW5zdGFuY2VfaWQYASABKAlSCmluc3RhbmNlSWQ=');

@$core.Deprecated('Use getInstanceResponseDescriptor instead')
const GetInstanceResponse$json = {
  '1': 'GetInstanceResponse',
  '2': [
    {
      '1': 'instance',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '10': 'instance'
    },
  ],
};

/// Descriptor for `GetInstanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstanceResponseDescriptor = $convert.base64Decode(
    'ChNHZXRJbnN0YW5jZVJlc3BvbnNlEkIKCGluc3RhbmNlGAEgASgLMiYuY3VscGVvc3R1ZGlvLm'
    'VuZ2luZS52MS5FbmdpbmVJbnN0YW5jZVIIaW5zdGFuY2U=');

@$core.Deprecated('Use getInstanceMetricsRequestDescriptor instead')
const GetInstanceMetricsRequest$json = {
  '1': 'GetInstanceMetricsRequest',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
  ],
};

/// Descriptor for `GetInstanceMetricsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstanceMetricsRequestDescriptor =
    $convert.base64Decode(
        'ChlHZXRJbnN0YW5jZU1ldHJpY3NSZXF1ZXN0Eh8KC2luc3RhbmNlX2lkGAEgASgJUgppbnN0YW'
        '5jZUlk');

@$core.Deprecated('Use getInstanceMetricsResponseDescriptor instead')
const GetInstanceMetricsResponse$json = {
  '1': 'GetInstanceMetricsResponse',
  '2': [
    {
      '1': 'metrics',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'metrics'
    },
  ],
};

/// Descriptor for `GetInstanceMetricsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstanceMetricsResponseDescriptor =
    $convert.base64Decode(
        'ChpHZXRJbnN0YW5jZU1ldHJpY3NSZXNwb25zZRIxCgdtZXRyaWNzGAEgASgLMhcuZ29vZ2xlLn'
        'Byb3RvYnVmLlN0cnVjdFIHbWV0cmljcw==');

@$core.Deprecated('Use setVisibilityDescriptor instead')
const SetVisibility$json = {
  '1': 'SetVisibility',
  '2': [
    {
      '1': 'show_in_chat_picker',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'showInChatPicker'
    },
  ],
};

/// Descriptor for `SetVisibility`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setVisibilityDescriptor = $convert.base64Decode(
    'Cg1TZXRWaXNpYmlsaXR5Ei0KE3Nob3dfaW5fY2hhdF9waWNrZXIYASABKAhSEHNob3dJbkNoYX'
    'RQaWNrZXI=');

@$core.Deprecated('Use setGenerationDefaultsDescriptor instead')
const SetGenerationDefaults$json = {
  '1': 'SetGenerationDefaults',
  '2': [
    {
      '1': 'generation_defaults',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'generationDefaults'
    },
  ],
};

/// Descriptor for `SetGenerationDefaults`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setGenerationDefaultsDescriptor = $convert.base64Decode(
    'ChVTZXRHZW5lcmF0aW9uRGVmYXVsdHMSSAoTZ2VuZXJhdGlvbl9kZWZhdWx0cxgBIAEoCzIXLm'
    'dvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSEmdlbmVyYXRpb25EZWZhdWx0cw==');

@$core.Deprecated('Use startInstanceDescriptor instead')
const StartInstance$json = {
  '1': 'StartInstance',
  '2': [
    {
      '1': 'requested_config',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'requestedConfig'
    },
    {'1': 'restart', '3': 2, '4': 1, '5': 8, '10': 'restart'},
  ],
};

/// Descriptor for `StartInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startInstanceDescriptor = $convert.base64Decode(
    'Cg1TdGFydEluc3RhbmNlEk8KEHJlcXVlc3RlZF9jb25maWcYASABKAsyJC5jdWxwZW9zdHVkaW'
    '8uZW5naW5lLnYxLkVuZ2luZUNvbmZpZ1IPcmVxdWVzdGVkQ29uZmlnEhgKB3Jlc3RhcnQYAiAB'
    'KAhSB3Jlc3RhcnQ=');

@$core.Deprecated('Use stopInstanceDescriptor instead')
const StopInstance$json = {
  '1': 'StopInstance',
};

/// Descriptor for `StopInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopInstanceDescriptor =
    $convert.base64Decode('CgxTdG9wSW5zdGFuY2U=');

@$core.Deprecated('Use applyFixDescriptor instead')
const ApplyFix$json = {
  '1': 'ApplyFix',
  '2': [
    {'1': 'fix', '3': 1, '4': 1, '5': 9, '10': 'fix'},
  ],
};

/// Descriptor for `ApplyFix`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyFixDescriptor =
    $convert.base64Decode('CghBcHBseUZpeBIQCgNmaXgYASABKAlSA2ZpeA==');

@$core.Deprecated('Use setRequestedConfigDescriptor instead')
const SetRequestedConfig$json = {
  '1': 'SetRequestedConfig',
  '2': [
    {
      '1': 'requested_config',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'requestedConfig'
    },
  ],
};

/// Descriptor for `SetRequestedConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRequestedConfigDescriptor = $convert.base64Decode(
    'ChJTZXRSZXF1ZXN0ZWRDb25maWcSTwoQcmVxdWVzdGVkX2NvbmZpZxgBIAEoCzIkLmN1bHBlb3'
    'N0dWRpby5lbmdpbmUudjEuRW5naW5lQ29uZmlnUg9yZXF1ZXN0ZWRDb25maWc=');

@$core.Deprecated('Use updateInstanceRequestDescriptor instead')
const UpdateInstanceRequest$json = {
  '1': 'UpdateInstanceRequest',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
    {
      '1': 'visibility',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SetVisibility',
      '9': 0,
      '10': 'visibility'
    },
    {
      '1': 'generation_defaults',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SetGenerationDefaults',
      '9': 0,
      '10': 'generationDefaults'
    },
    {
      '1': 'start',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.StartInstance',
      '9': 0,
      '10': 'start'
    },
    {
      '1': 'stop',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.StopInstance',
      '9': 0,
      '10': 'stop'
    },
    {
      '1': 'apply_fix',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ApplyFix',
      '9': 0,
      '10': 'applyFix'
    },
    {
      '1': 'requested_config',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.SetRequestedConfig',
      '9': 0,
      '10': 'requestedConfig'
    },
  ],
  '8': [
    {'1': 'change'},
  ],
};

/// Descriptor for `UpdateInstanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateInstanceRequestDescriptor = $convert.base64Decode(
    'ChVVcGRhdGVJbnN0YW5jZVJlcXVlc3QSHwoLaW5zdGFuY2VfaWQYASABKAlSCmluc3RhbmNlSW'
    'QSRwoKdmlzaWJpbGl0eRgCIAEoCzIlLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuU2V0VmlzaWJp'
    'bGl0eUgAUgp2aXNpYmlsaXR5EmAKE2dlbmVyYXRpb25fZGVmYXVsdHMYAyABKAsyLS5jdWxwZW'
    '9zdHVkaW8uZW5naW5lLnYxLlNldEdlbmVyYXRpb25EZWZhdWx0c0gAUhJnZW5lcmF0aW9uRGVm'
    'YXVsdHMSPQoFc3RhcnQYBCABKAsyJS5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLlN0YXJ0SW5zdG'
    'FuY2VIAFIFc3RhcnQSOgoEc3RvcBgFIAEoCzIkLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuU3Rv'
    'cEluc3RhbmNlSABSBHN0b3ASPwoJYXBwbHlfZml4GAYgASgLMiAuY3VscGVvc3R1ZGlvLmVuZ2'
    'luZS52MS5BcHBseUZpeEgAUghhcHBseUZpeBJXChByZXF1ZXN0ZWRfY29uZmlnGAcgASgLMiou'
    'Y3VscGVvc3R1ZGlvLmVuZ2luZS52MS5TZXRSZXF1ZXN0ZWRDb25maWdIAFIPcmVxdWVzdGVkQ2'
    '9uZmlnQggKBmNoYW5nZQ==');

@$core.Deprecated('Use updateInstanceResponseDescriptor instead')
const UpdateInstanceResponse$json = {
  '1': 'UpdateInstanceResponse',
  '2': [
    {
      '1': 'instance',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '10': 'instance'
    },
    {'1': 'operation_id', '3': 2, '4': 1, '5': 9, '10': 'operationId'},
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.OperationState',
      '10': 'state'
    },
    {'1': 'queue_position', '3': 4, '4': 1, '5': 5, '10': 'queuePosition'},
    {'1': 'applied_fix', '3': 5, '4': 1, '5': 9, '10': 'appliedFix'},
  ],
};

/// Descriptor for `UpdateInstanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateInstanceResponseDescriptor = $convert.base64Decode(
    'ChZVcGRhdGVJbnN0YW5jZVJlc3BvbnNlEkIKCGluc3RhbmNlGAEgASgLMiYuY3VscGVvc3R1ZG'
    'lvLmVuZ2luZS52MS5FbmdpbmVJbnN0YW5jZVIIaW5zdGFuY2USIQoMb3BlcmF0aW9uX2lkGAIg'
    'ASgJUgtvcGVyYXRpb25JZBI8CgVzdGF0ZRgDIAEoDjImLmN1bHBlb3N0dWRpby5lbmdpbmUudj'
    'EuT3BlcmF0aW9uU3RhdGVSBXN0YXRlEiUKDnF1ZXVlX3Bvc2l0aW9uGAQgASgFUg1xdWV1ZVBv'
    'c2l0aW9uEh8KC2FwcGxpZWRfZml4GAUgASgJUgphcHBsaWVkRml4');

@$core.Deprecated('Use ensureInstanceReadyRequestDescriptor instead')
const EnsureInstanceReadyRequest$json = {
  '1': 'EnsureInstanceReadyRequest',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
  ],
};

/// Descriptor for `EnsureInstanceReadyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ensureInstanceReadyRequestDescriptor =
    $convert.base64Decode(
        'ChpFbnN1cmVJbnN0YW5jZVJlYWR5UmVxdWVzdBIfCgtpbnN0YW5jZV9pZBgBIAEoCVIKaW5zdG'
        'FuY2VJZA==');

@$core.Deprecated('Use ensureInstanceReadyResponseDescriptor instead')
const EnsureInstanceReadyResponse$json = {
  '1': 'EnsureInstanceReadyResponse',
  '2': [
    {
      '1': 'instance',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '10': 'instance'
    },
    {'1': 'operation_id', '3': 2, '4': 1, '5': 9, '10': 'operationId'},
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.OperationState',
      '10': 'state'
    },
    {'1': 'queue_position', '3': 4, '4': 1, '5': 5, '10': 'queuePosition'},
    {'1': 'already_ready', '3': 5, '4': 1, '5': 8, '10': 'alreadyReady'},
  ],
};

/// Descriptor for `EnsureInstanceReadyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ensureInstanceReadyResponseDescriptor = $convert.base64Decode(
    'ChtFbnN1cmVJbnN0YW5jZVJlYWR5UmVzcG9uc2USQgoIaW5zdGFuY2UYASABKAsyJi5jdWxwZW'
    '9zdHVkaW8uZW5naW5lLnYxLkVuZ2luZUluc3RhbmNlUghpbnN0YW5jZRIhCgxvcGVyYXRpb25f'
    'aWQYAiABKAlSC29wZXJhdGlvbklkEjwKBXN0YXRlGAMgASgOMiYuY3VscGVvc3R1ZGlvLmVuZ2'
    'luZS52MS5PcGVyYXRpb25TdGF0ZVIFc3RhdGUSJQoOcXVldWVfcG9zaXRpb24YBCABKAVSDXF1'
    'ZXVlUG9zaXRpb24SIwoNYWxyZWFkeV9yZWFkeRgFIAEoCFIMYWxyZWFkeVJlYWR5');

@$core.Deprecated('Use deleteInstanceRequestDescriptor instead')
const DeleteInstanceRequest$json = {
  '1': 'DeleteInstanceRequest',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
  ],
};

/// Descriptor for `DeleteInstanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteInstanceRequestDescriptor = $convert.base64Decode(
    'ChVEZWxldGVJbnN0YW5jZVJlcXVlc3QSHwoLaW5zdGFuY2VfaWQYASABKAlSCmluc3RhbmNlSW'
    'Q=');

@$core.Deprecated('Use deleteInstanceResponseDescriptor instead')
const DeleteInstanceResponse$json = {
  '1': 'DeleteInstanceResponse',
  '2': [
    {
      '1': 'instance',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '10': 'instance'
    },
    {'1': 'operation_id', '3': 2, '4': 1, '5': 9, '10': 'operationId'},
  ],
};

/// Descriptor for `DeleteInstanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteInstanceResponseDescriptor = $convert.base64Decode(
    'ChZEZWxldGVJbnN0YW5jZVJlc3BvbnNlEkIKCGluc3RhbmNlGAEgASgLMiYuY3VscGVvc3R1ZG'
    'lvLmVuZ2luZS52MS5FbmdpbmVJbnN0YW5jZVIIaW5zdGFuY2USIQoMb3BlcmF0aW9uX2lkGAIg'
    'ASgJUgtvcGVyYXRpb25JZA==');

@$core.Deprecated('Use getOperationRequestDescriptor instead')
const GetOperationRequest$json = {
  '1': 'GetOperationRequest',
  '2': [
    {'1': 'operation_id', '3': 1, '4': 1, '5': 9, '10': 'operationId'},
  ],
};

/// Descriptor for `GetOperationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getOperationRequestDescriptor = $convert.base64Decode(
    'ChNHZXRPcGVyYXRpb25SZXF1ZXN0EiEKDG9wZXJhdGlvbl9pZBgBIAEoCVILb3BlcmF0aW9uSW'
    'Q=');

@$core.Deprecated('Use getOperationResponseDescriptor instead')
const GetOperationResponse$json = {
  '1': 'GetOperationResponse',
  '2': [
    {
      '1': 'operation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineOperation',
      '10': 'operation'
    },
  ],
};

/// Descriptor for `GetOperationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getOperationResponseDescriptor = $convert.base64Decode(
    'ChRHZXRPcGVyYXRpb25SZXNwb25zZRJFCglvcGVyYXRpb24YASABKAsyJy5jdWxwZW9zdHVkaW'
    '8uZW5naW5lLnYxLkVuZ2luZU9wZXJhdGlvblIJb3BlcmF0aW9u');

@$core.Deprecated('Use cancelOperationRequestDescriptor instead')
const CancelOperationRequest$json = {
  '1': 'CancelOperationRequest',
  '2': [
    {'1': 'operation_id', '3': 1, '4': 1, '5': 9, '10': 'operationId'},
  ],
};

/// Descriptor for `CancelOperationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelOperationRequestDescriptor =
    $convert.base64Decode(
        'ChZDYW5jZWxPcGVyYXRpb25SZXF1ZXN0EiEKDG9wZXJhdGlvbl9pZBgBIAEoCVILb3BlcmF0aW'
        '9uSWQ=');

@$core.Deprecated('Use cancelOperationResponseDescriptor instead')
const CancelOperationResponse$json = {
  '1': 'CancelOperationResponse',
  '2': [
    {
      '1': 'operation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineOperation',
      '10': 'operation'
    },
  ],
};

/// Descriptor for `CancelOperationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelOperationResponseDescriptor =
    $convert.base64Decode(
        'ChdDYW5jZWxPcGVyYXRpb25SZXNwb25zZRJFCglvcGVyYXRpb24YASABKAsyJy5jdWxwZW9zdH'
        'VkaW8uZW5naW5lLnYxLkVuZ2luZU9wZXJhdGlvblIJb3BlcmF0aW9u');

@$core.Deprecated('Use streamEventsRequestDescriptor instead')
const StreamEventsRequest$json = {
  '1': 'StreamEventsRequest',
};

/// Descriptor for `StreamEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamEventsRequestDescriptor =
    $convert.base64Decode('ChNTdHJlYW1FdmVudHNSZXF1ZXN0');

@$core.Deprecated('Use streamEventsResponseDescriptor instead')
const StreamEventsResponse$json = {
  '1': 'StreamEventsResponse',
  '2': [
    {
      '1': 'timestamp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
    {
      '1': 'snapshot',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.InstanceSnapshot',
      '9': 0,
      '10': 'snapshot'
    },
    {
      '1': 'instance_created',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '9': 0,
      '10': 'instanceCreated'
    },
    {
      '1': 'instance_changed',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '9': 0,
      '10': 'instanceChanged'
    },
    {
      '1': 'instance_deleted',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.InstanceDeleted',
      '9': 0,
      '10': 'instanceDeleted'
    },
    {
      '1': 'operation',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineOperation',
      '9': 0,
      '10': 'operation'
    },
    {
      '1': 'models_rescanned',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ModelsRescanned',
      '9': 0,
      '10': 'modelsRescanned'
    },
    {
      '1': 'model_deleted',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.ModelDeleted',
      '9': 0,
      '10': 'modelDeleted'
    },
    {
      '1': 'guard_state',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.GuardStateChanged',
      '9': 0,
      '10': 'guardState'
    },
    {
      '1': 'generic',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.GenericEvent',
      '9': 0,
      '10': 'generic'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `StreamEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamEventsResponseDescriptor = $convert.base64Decode(
    'ChRTdHJlYW1FdmVudHNSZXNwb25zZRI4Cgl0aW1lc3RhbXAYASABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wUgl0aW1lc3RhbXASRgoIc25hcHNob3QYAiABKAsyKC5jdWxwZW9zdHVk'
    'aW8uZW5naW5lLnYxLkluc3RhbmNlU25hcHNob3RIAFIIc25hcHNob3QSUwoQaW5zdGFuY2VfY3'
    'JlYXRlZBgDIAEoCzImLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuRW5naW5lSW5zdGFuY2VIAFIP'
    'aW5zdGFuY2VDcmVhdGVkElMKEGluc3RhbmNlX2NoYW5nZWQYBCABKAsyJi5jdWxwZW9zdHVkaW'
    '8uZW5naW5lLnYxLkVuZ2luZUluc3RhbmNlSABSD2luc3RhbmNlQ2hhbmdlZBJUChBpbnN0YW5j'
    'ZV9kZWxldGVkGAUgASgLMicuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5JbnN0YW5jZURlbGV0ZW'
    'RIAFIPaW5zdGFuY2VEZWxldGVkEkcKCW9wZXJhdGlvbhgGIAEoCzInLmN1bHBlb3N0dWRpby5l'
    'bmdpbmUudjEuRW5naW5lT3BlcmF0aW9uSABSCW9wZXJhdGlvbhJUChBtb2RlbHNfcmVzY2Fubm'
    'VkGAcgASgLMicuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5Nb2RlbHNSZXNjYW5uZWRIAFIPbW9k'
    'ZWxzUmVzY2FubmVkEksKDW1vZGVsX2RlbGV0ZWQYCCABKAsyJC5jdWxwZW9zdHVkaW8uZW5naW'
    '5lLnYxLk1vZGVsRGVsZXRlZEgAUgxtb2RlbERlbGV0ZWQSTAoLZ3VhcmRfc3RhdGUYCSABKAsy'
    'KS5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLkd1YXJkU3RhdGVDaGFuZ2VkSABSCmd1YXJkU3RhdG'
    'USQAoHZ2VuZXJpYxgKIAEoCzIkLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuR2VuZXJpY0V2ZW50'
    'SABSB2dlbmVyaWNCBwoFZXZlbnQ=');

@$core.Deprecated('Use instanceSnapshotDescriptor instead')
const InstanceSnapshot$json = {
  '1': 'InstanceSnapshot',
  '2': [
    {
      '1': 'instances',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineInstance',
      '10': 'instances'
    },
  ],
};

/// Descriptor for `InstanceSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instanceSnapshotDescriptor = $convert.base64Decode(
    'ChBJbnN0YW5jZVNuYXBzaG90EkQKCWluc3RhbmNlcxgBIAMoCzImLmN1bHBlb3N0dWRpby5lbm'
    'dpbmUudjEuRW5naW5lSW5zdGFuY2VSCWluc3RhbmNlcw==');

@$core.Deprecated('Use instanceDeletedDescriptor instead')
const InstanceDeleted$json = {
  '1': 'InstanceDeleted',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
  ],
};

/// Descriptor for `InstanceDeleted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instanceDeletedDescriptor = $convert.base64Decode(
    'Cg9JbnN0YW5jZURlbGV0ZWQSHwoLaW5zdGFuY2VfaWQYASABKAlSCmluc3RhbmNlSWQ=');

@$core.Deprecated('Use modelsRescannedDescriptor instead')
const ModelsRescanned$json = {
  '1': 'ModelsRescanned',
  '2': [
    {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `ModelsRescanned`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelsRescannedDescriptor = $convert.base64Decode(
    'Cg9Nb2RlbHNSZXNjYW5uZWQSFAoFY291bnQYASABKAVSBWNvdW50EhYKBnJlYXNvbhgCIAEoCV'
    'IGcmVhc29u');

@$core.Deprecated('Use modelDeletedDescriptor instead')
const ModelDeleted$json = {
  '1': 'ModelDeleted',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ModelDeleted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelDeletedDescriptor = $convert.base64Decode(
    'CgxNb2RlbERlbGV0ZWQSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQSEgoEbmFtZRgCIAEoCV'
    'IEbmFtZQ==');

@$core.Deprecated('Use guardStateChangedDescriptor instead')
const GuardStateChanged$json = {
  '1': 'GuardStateChanged',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.GuardState',
      '10': 'state'
    },
  ],
};

/// Descriptor for `GuardStateChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List guardStateChangedDescriptor = $convert.base64Decode(
    'ChFHdWFyZFN0YXRlQ2hhbmdlZBI4CgVzdGF0ZRgBIAEoDjIiLmN1bHBlb3N0dWRpby5lbmdpbm'
    'UudjEuR3VhcmRTdGF0ZVIFc3RhdGU=');

@$core.Deprecated('Use genericEventDescriptor instead')
const GenericEvent$json = {
  '1': 'GenericEvent',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'data',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'data'
    },
  ],
};

/// Descriptor for `GenericEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List genericEventDescriptor = $convert.base64Decode(
    'CgxHZW5lcmljRXZlbnQSEgoEdHlwZRgBIAEoCVIEdHlwZRIrCgRkYXRhGAIgASgLMhcuZ29vZ2'
    'xlLnByb3RvYnVmLlN0cnVjdFIEZGF0YQ==');

@$core.Deprecated('Use listRuntimesRequestDescriptor instead')
const ListRuntimesRequest$json = {
  '1': 'ListRuntimesRequest',
};

/// Descriptor for `ListRuntimesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRuntimesRequestDescriptor =
    $convert.base64Decode('ChNMaXN0UnVudGltZXNSZXF1ZXN0');

@$core.Deprecated('Use listRuntimesResponseDescriptor instead')
const ListRuntimesResponse$json = {
  '1': 'ListRuntimesResponse',
  '2': [
    {
      '1': 'runtimes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.RuntimeCapability',
      '10': 'runtimes'
    },
    {
      '1': 'install_operations',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.RuntimeInstallJob',
      '10': 'installOperations'
    },
  ],
};

/// Descriptor for `ListRuntimesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRuntimesResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0UnVudGltZXNSZXNwb25zZRJFCghydW50aW1lcxgBIAMoCzIpLmN1bHBlb3N0dWRpby'
    '5lbmdpbmUudjEuUnVudGltZUNhcGFiaWxpdHlSCHJ1bnRpbWVzElgKEmluc3RhbGxfb3BlcmF0'
    'aW9ucxgCIAMoCzIpLmN1bHBlb3N0dWRpby5lbmdpbmUudjEuUnVudGltZUluc3RhbGxKb2JSEW'
    'luc3RhbGxPcGVyYXRpb25z');

@$core.Deprecated('Use runtimeInstallJobDescriptor instead')
const RuntimeInstallJob$json = {
  '1': 'RuntimeInstallJob',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'build_digest', '3': 2, '4': 1, '5': 9, '10': 'buildDigest'},
    {
      '1': 'runtime',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.RuntimeKind',
      '10': 'runtime'
    },
    {'1': 'version', '3': 4, '4': 1, '5': 9, '10': 'version'},
    {'1': 'install_path', '3': 5, '4': 1, '5': 9, '10': 'installPath'},
    {'1': 'status', '3': 6, '4': 1, '5': 9, '10': 'status'},
    {'1': 'phase', '3': 7, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'progress', '3': 8, '4': 1, '5': 1, '10': 'progress'},
    {'1': 'message', '3': 9, '4': 1, '5': 9, '10': 'message'},
    {'1': 'detail_message', '3': 10, '4': 1, '5': 9, '10': 'detailMessage'},
    {'1': 'log', '3': 11, '4': 1, '5': 9, '10': 'log'},
    {'1': 'error', '3': 12, '4': 1, '5': 9, '10': 'error'},
    {'1': 'error_summary', '3': 13, '4': 1, '5': 9, '10': 'errorSummary'},
    {'1': 'error_code', '3': 14, '4': 1, '5': 9, '10': 'errorCode'},
    {
      '1': 'created_at',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {
      '1': 'finished_at',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'finishedAt'
    },
    {'1': 'variant', '3': 18, '4': 1, '5': 9, '10': 'variant'},
    {'1': 'server_path', '3': 19, '4': 1, '5': 9, '10': 'serverPath'},
  ],
};

/// Descriptor for `RuntimeInstallJob`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runtimeInstallJobDescriptor = $convert.base64Decode(
    'ChFSdW50aW1lSW5zdGFsbEpvYhIOCgJpZBgBIAEoCVICaWQSIQoMYnVpbGRfZGlnZXN0GAIgAS'
    'gJUgtidWlsZERpZ2VzdBI9CgdydW50aW1lGAMgASgOMiMuY3VscGVvc3R1ZGlvLmVuZ2luZS52'
    'MS5SdW50aW1lS2luZFIHcnVudGltZRIYCgd2ZXJzaW9uGAQgASgJUgd2ZXJzaW9uEiEKDGluc3'
    'RhbGxfcGF0aBgFIAEoCVILaW5zdGFsbFBhdGgSFgoGc3RhdHVzGAYgASgJUgZzdGF0dXMSFAoF'
    'cGhhc2UYByABKAlSBXBoYXNlEhoKCHByb2dyZXNzGAggASgBUghwcm9ncmVzcxIYCgdtZXNzYW'
    'dlGAkgASgJUgdtZXNzYWdlEiUKDmRldGFpbF9tZXNzYWdlGAogASgJUg1kZXRhaWxNZXNzYWdl'
    'EhAKA2xvZxgLIAEoCVIDbG9nEhQKBWVycm9yGAwgASgJUgVlcnJvchIjCg1lcnJvcl9zdW1tYX'
    'J5GA0gASgJUgxlcnJvclN1bW1hcnkSHQoKZXJyb3JfY29kZRgOIAEoCVIJZXJyb3JDb2RlEjkK'
    'CmNyZWF0ZWRfYXQYDyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQX'
    'QSOQoKdXBkYXRlZF9hdBgQIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXVwZGF0'
    'ZWRBdBI7CgtmaW5pc2hlZF9hdBgRIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCm'
    'ZpbmlzaGVkQXQSGAoHdmFyaWFudBgSIAEoCVIHdmFyaWFudBIfCgtzZXJ2ZXJfcGF0aBgTIAEo'
    'CVIKc2VydmVyUGF0aA==');

@$core.Deprecated('Use installRuntimeRequestDescriptor instead')
const InstallRuntimeRequest$json = {
  '1': 'InstallRuntimeRequest',
  '2': [
    {
      '1': 'runtime',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.RuntimeKind',
      '10': 'runtime'
    },
  ],
};

/// Descriptor for `InstallRuntimeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installRuntimeRequestDescriptor = $convert.base64Decode(
    'ChVJbnN0YWxsUnVudGltZVJlcXVlc3QSPQoHcnVudGltZRgBIAEoDjIjLmN1bHBlb3N0dWRpby'
    '5lbmdpbmUudjEuUnVudGltZUtpbmRSB3J1bnRpbWU=');

@$core.Deprecated('Use installRuntimeResponseDescriptor instead')
const InstallRuntimeResponse$json = {
  '1': 'InstallRuntimeResponse',
  '2': [
    {'1': 'operation_id', '3': 1, '4': 1, '5': 9, '10': 'operationId'},
    {
      '1': 'runtime_install',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.RuntimeInstallJob',
      '10': 'runtimeInstall'
    },
  ],
};

/// Descriptor for `InstallRuntimeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installRuntimeResponseDescriptor = $convert.base64Decode(
    'ChZJbnN0YWxsUnVudGltZVJlc3BvbnNlEiEKDG9wZXJhdGlvbl9pZBgBIAEoCVILb3BlcmF0aW'
    '9uSWQSUgoPcnVudGltZV9pbnN0YWxsGAIgASgLMikuY3VscGVvc3R1ZGlvLmVuZ2luZS52MS5S'
    'dW50aW1lSW5zdGFsbEpvYlIOcnVudGltZUluc3RhbGw=');

@$core.Deprecated('Use gatewayKeyDescriptor instead')
const GatewayKey$json = {
  '1': 'GatewayKey',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'instance_ids', '3': 3, '4': 3, '5': 9, '10': 'instanceIds'},
    {
      '1': 'created_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'last_used_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUsedAt'
    },
    {
      '1': 'revoked_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'revokedAt'
    },
  ],
};

/// Descriptor for `GatewayKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gatewayKeyDescriptor = $convert.base64Decode(
    'CgpHYXRld2F5S2V5Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEiEKDGluc3'
    'RhbmNlX2lkcxgDIAMoCVILaW5zdGFuY2VJZHMSOQoKY3JlYXRlZF9hdBgEIAEoCzIaLmdvb2ds'
    'ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI8CgxsYXN0X3VzZWRfYXQYBSABKAsyGi'
    '5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpsYXN0VXNlZEF0EjkKCnJldm9rZWRfYXQYBiAB'
    'KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglyZXZva2VkQXQ=');

@$core.Deprecated('Use listKeysRequestDescriptor instead')
const ListKeysRequest$json = {
  '1': 'ListKeysRequest',
};

/// Descriptor for `ListKeysRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKeysRequestDescriptor =
    $convert.base64Decode('Cg9MaXN0S2V5c1JlcXVlc3Q=');

@$core.Deprecated('Use listKeysResponseDescriptor instead')
const ListKeysResponse$json = {
  '1': 'ListKeysResponse',
  '2': [
    {
      '1': 'keys',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.GatewayKey',
      '10': 'keys'
    },
  ],
};

/// Descriptor for `ListKeysResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKeysResponseDescriptor = $convert.base64Decode(
    'ChBMaXN0S2V5c1Jlc3BvbnNlEjYKBGtleXMYASADKAsyIi5jdWxwZW9zdHVkaW8uZW5naW5lLn'
    'YxLkdhdGV3YXlLZXlSBGtleXM=');

@$core.Deprecated('Use createKeyRequestDescriptor instead')
const CreateKeyRequest$json = {
  '1': 'CreateKeyRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'instance_ids', '3': 2, '4': 3, '5': 9, '10': 'instanceIds'},
  ],
};

/// Descriptor for `CreateKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createKeyRequestDescriptor = $convert.base64Decode(
    'ChBDcmVhdGVLZXlSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSIQoMaW5zdGFuY2VfaWRzGA'
    'IgAygJUgtpbnN0YW5jZUlkcw==');

@$core.Deprecated('Use createKeyResponseDescriptor instead')
const CreateKeyResponse$json = {
  '1': 'CreateKeyResponse',
  '2': [
    {
      '1': 'key',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.GatewayKey',
      '10': 'key'
    },
    {'1': 'plaintext', '3': 2, '4': 1, '5': 9, '10': 'plaintext'},
  ],
};

/// Descriptor for `CreateKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createKeyResponseDescriptor = $convert.base64Decode(
    'ChFDcmVhdGVLZXlSZXNwb25zZRI0CgNrZXkYASABKAsyIi5jdWxwZW9zdHVkaW8uZW5naW5lLn'
    'YxLkdhdGV3YXlLZXlSA2tleRIcCglwbGFpbnRleHQYAiABKAlSCXBsYWludGV4dA==');

@$core.Deprecated('Use rotateKeyRequestDescriptor instead')
const RotateKeyRequest$json = {
  '1': 'RotateKeyRequest',
  '2': [
    {'1': 'key_id', '3': 1, '4': 1, '5': 9, '10': 'keyId'},
  ],
};

/// Descriptor for `RotateKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rotateKeyRequestDescriptor = $convert
    .base64Decode('ChBSb3RhdGVLZXlSZXF1ZXN0EhUKBmtleV9pZBgBIAEoCVIFa2V5SWQ=');

@$core.Deprecated('Use rotateKeyResponseDescriptor instead')
const RotateKeyResponse$json = {
  '1': 'RotateKeyResponse',
  '2': [
    {
      '1': 'key',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.GatewayKey',
      '10': 'key'
    },
    {'1': 'plaintext', '3': 2, '4': 1, '5': 9, '10': 'plaintext'},
  ],
};

/// Descriptor for `RotateKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rotateKeyResponseDescriptor = $convert.base64Decode(
    'ChFSb3RhdGVLZXlSZXNwb25zZRI0CgNrZXkYASABKAsyIi5jdWxwZW9zdHVkaW8uZW5naW5lLn'
    'YxLkdhdGV3YXlLZXlSA2tleRIcCglwbGFpbnRleHQYAiABKAlSCXBsYWludGV4dA==');

@$core.Deprecated('Use revokeKeyRequestDescriptor instead')
const RevokeKeyRequest$json = {
  '1': 'RevokeKeyRequest',
  '2': [
    {'1': 'key_id', '3': 1, '4': 1, '5': 9, '10': 'keyId'},
  ],
};

/// Descriptor for `RevokeKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeKeyRequestDescriptor = $convert
    .base64Decode('ChBSZXZva2VLZXlSZXF1ZXN0EhUKBmtleV9pZBgBIAEoCVIFa2V5SWQ=');

@$core.Deprecated('Use revokeKeyResponseDescriptor instead')
const RevokeKeyResponse$json = {
  '1': 'RevokeKeyResponse',
  '2': [
    {'1': 'revoked', '3': 1, '4': 1, '5': 8, '10': 'revoked'},
  ],
};

/// Descriptor for `RevokeKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeKeyResponseDescriptor = $convert.base64Decode(
    'ChFSZXZva2VLZXlSZXNwb25zZRIYCgdyZXZva2VkGAEgASgIUgdyZXZva2Vk');

@$core.Deprecated('Use getInstanceLogsRequestDescriptor instead')
const GetInstanceLogsRequest$json = {
  '1': 'GetInstanceLogsRequest',
  '2': [
    {'1': 'instance_id', '3': 1, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'tail_lines', '3': 2, '4': 1, '5': 5, '10': 'tailLines'},
  ],
};

/// Descriptor for `GetInstanceLogsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstanceLogsRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRJbnN0YW5jZUxvZ3NSZXF1ZXN0Eh8KC2luc3RhbmNlX2lkGAEgASgJUgppbnN0YW5jZU'
        'lkEh0KCnRhaWxfbGluZXMYAiABKAVSCXRhaWxMaW5lcw==');

@$core.Deprecated('Use getInstanceLogsResponseDescriptor instead')
const GetInstanceLogsResponse$json = {
  '1': 'GetInstanceLogsResponse',
  '2': [
    {'1': 'stdout', '3': 1, '4': 1, '5': 9, '10': 'stdout'},
    {'1': 'stderr', '3': 2, '4': 1, '5': 9, '10': 'stderr'},
    {'1': 'available', '3': 3, '4': 1, '5': 8, '10': 'available'},
  ],
};

/// Descriptor for `GetInstanceLogsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstanceLogsResponseDescriptor =
    $convert.base64Decode(
        'ChdHZXRJbnN0YW5jZUxvZ3NSZXNwb25zZRIWCgZzdGRvdXQYASABKAlSBnN0ZG91dBIWCgZzdG'
        'RlcnIYAiABKAlSBnN0ZGVychIcCglhdmFpbGFibGUYAyABKAhSCWF2YWlsYWJsZQ==');

@$core.Deprecated('Use quantizationTypeDescriptor instead')
const QuantizationType$json = {
  '1': 'QuantizationType',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'size_gib_at_reference',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'sizeGibAtReference'
    },
    {'1': 'perplexity_delta', '3': 4, '4': 1, '5': 1, '10': 'perplexityDelta'},
    {'1': 'reference_model', '3': 5, '4': 1, '5': 9, '10': 'referenceModel'},
    {'1': 'bits_per_weight', '3': 6, '4': 1, '5': 1, '10': 'bitsPerWeight'},
    {'1': 'alias', '3': 7, '4': 1, '5': 9, '10': 'alias'},
  ],
};

/// Descriptor for `QuantizationType`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quantizationTypeDescriptor = $convert.base64Decode(
    'ChBRdWFudGl6YXRpb25UeXBlEhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAi'
    'ABKAlSC2Rlc2NyaXB0aW9uEjEKFXNpemVfZ2liX2F0X3JlZmVyZW5jZRgDIAEoAVISc2l6ZUdp'
    'YkF0UmVmZXJlbmNlEikKEHBlcnBsZXhpdHlfZGVsdGEYBCABKAFSD3BlcnBsZXhpdHlEZWx0YR'
    'InCg9yZWZlcmVuY2VfbW9kZWwYBSABKAlSDnJlZmVyZW5jZU1vZGVsEiYKD2JpdHNfcGVyX3dl'
    'aWdodBgGIAEoAVINYml0c1BlcldlaWdodBIUCgVhbGlhcxgHIAEoCVIFYWxpYXM=');

@$core.Deprecated('Use listQuantizationTypesRequestDescriptor instead')
const ListQuantizationTypesRequest$json = {
  '1': 'ListQuantizationTypesRequest',
};

/// Descriptor for `ListQuantizationTypesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listQuantizationTypesRequestDescriptor =
    $convert.base64Decode('ChxMaXN0UXVhbnRpemF0aW9uVHlwZXNSZXF1ZXN0');

@$core.Deprecated('Use listQuantizationTypesResponseDescriptor instead')
const ListQuantizationTypesResponse$json = {
  '1': 'ListQuantizationTypesResponse',
  '2': [
    {
      '1': 'types',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.QuantizationType',
      '10': 'types'
    },
    {'1': 'available', '3': 2, '4': 1, '5': 8, '10': 'available'},
    {
      '1': 'unavailable_reason',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'unavailableReason'
    },
  ],
};

/// Descriptor for `ListQuantizationTypesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listQuantizationTypesResponseDescriptor = $convert.base64Decode(
    'Ch1MaXN0UXVhbnRpemF0aW9uVHlwZXNSZXNwb25zZRI+CgV0eXBlcxgBIAMoCzIoLmN1bHBlb3'
    'N0dWRpby5lbmdpbmUudjEuUXVhbnRpemF0aW9uVHlwZVIFdHlwZXMSHAoJYXZhaWxhYmxlGAIg'
    'ASgIUglhdmFpbGFibGUSLQoSdW5hdmFpbGFibGVfcmVhc29uGAMgASgJUhF1bmF2YWlsYWJsZV'
    'JlYXNvbg==');

@$core.Deprecated('Use quantizationRequestDescriptor instead')
const QuantizationRequest$json = {
  '1': 'QuantizationRequest',
  '2': [
    {'1': 'source_model_id', '3': 1, '4': 1, '5': 9, '10': 'sourceModelId'},
    {'1': 'target_type', '3': 2, '4': 1, '5': 9, '10': 'targetType'},
    {'1': 'target_name', '3': 3, '4': 1, '5': 9, '10': 'targetName'},
    {'1': 'allow_requantize', '3': 4, '4': 1, '5': 8, '10': 'allowRequantize'},
    {
      '1': 'leave_output_tensor',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'leaveOutputTensor'
    },
    {'1': 'threads', '3': 6, '4': 1, '5': 5, '10': 'threads'},
  ],
};

/// Descriptor for `QuantizationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quantizationRequestDescriptor = $convert.base64Decode(
    'ChNRdWFudGl6YXRpb25SZXF1ZXN0EiYKD3NvdXJjZV9tb2RlbF9pZBgBIAEoCVINc291cmNlTW'
    '9kZWxJZBIfCgt0YXJnZXRfdHlwZRgCIAEoCVIKdGFyZ2V0VHlwZRIfCgt0YXJnZXRfbmFtZRgD'
    'IAEoCVIKdGFyZ2V0TmFtZRIpChBhbGxvd19yZXF1YW50aXplGAQgASgIUg9hbGxvd1JlcXVhbn'
    'RpemUSLgoTbGVhdmVfb3V0cHV0X3RlbnNvchgFIAEoCFIRbGVhdmVPdXRwdXRUZW5zb3ISGAoH'
    'dGhyZWFkcxgGIAEoBVIHdGhyZWFkcw==');

@$core.Deprecated('Use quantizationPreflightDescriptor instead')
const QuantizationPreflight$json = {
  '1': 'QuantizationPreflight',
  '2': [
    {'1': 'source_model_id', '3': 1, '4': 1, '5': 9, '10': 'sourceModelId'},
    {'1': 'source_name', '3': 2, '4': 1, '5': 9, '10': 'sourceName'},
    {
      '1': 'source_quantization',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'sourceQuantization'
    },
    {'1': 'source_bytes', '3': 4, '4': 1, '5': 3, '10': 'sourceBytes'},
    {'1': 'target_type', '3': 5, '4': 1, '5': 9, '10': 'targetType'},
    {'1': 'target_name', '3': 6, '4': 1, '5': 9, '10': 'targetName'},
    {
      '1': 'target_relative_path',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'targetRelativePath'
    },
    {'1': 'estimated_bytes', '3': 8, '4': 1, '5': 3, '10': 'estimatedBytes'},
    {'1': 'free_disk_bytes', '3': 9, '4': 1, '5': 3, '10': 'freeDiskBytes'},
    {
      '1': 'required_disk_bytes',
      '3': 10,
      '4': 1,
      '5': 3,
      '10': 'requiredDiskBytes'
    },
    {
      '1': 'source_bits_per_weight',
      '3': 11,
      '4': 1,
      '5': 1,
      '10': 'sourceBitsPerWeight'
    },
    {
      '1': 'target_bits_per_weight',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'targetBitsPerWeight'
    },
    {
      '1': 'is_requantization',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'isRequantization'
    },
    {'1': 'feasible', '3': 14, '4': 1, '5': 8, '10': 'feasible'},
    {'1': 'blockers', '3': 15, '4': 3, '5': 9, '10': 'blockers'},
    {'1': 'warnings', '3': 16, '4': 3, '5': 9, '10': 'warnings'},
  ],
};

/// Descriptor for `QuantizationPreflight`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quantizationPreflightDescriptor = $convert.base64Decode(
    'ChVRdWFudGl6YXRpb25QcmVmbGlnaHQSJgoPc291cmNlX21vZGVsX2lkGAEgASgJUg1zb3VyY2'
    'VNb2RlbElkEh8KC3NvdXJjZV9uYW1lGAIgASgJUgpzb3VyY2VOYW1lEi8KE3NvdXJjZV9xdWFu'
    'dGl6YXRpb24YAyABKAlSEnNvdXJjZVF1YW50aXphdGlvbhIhCgxzb3VyY2VfYnl0ZXMYBCABKA'
    'NSC3NvdXJjZUJ5dGVzEh8KC3RhcmdldF90eXBlGAUgASgJUgp0YXJnZXRUeXBlEh8KC3Rhcmdl'
    'dF9uYW1lGAYgASgJUgp0YXJnZXROYW1lEjAKFHRhcmdldF9yZWxhdGl2ZV9wYXRoGAcgASgJUh'
    'J0YXJnZXRSZWxhdGl2ZVBhdGgSJwoPZXN0aW1hdGVkX2J5dGVzGAggASgDUg5lc3RpbWF0ZWRC'
    'eXRlcxImCg9mcmVlX2Rpc2tfYnl0ZXMYCSABKANSDWZyZWVEaXNrQnl0ZXMSLgoTcmVxdWlyZW'
    'RfZGlza19ieXRlcxgKIAEoA1IRcmVxdWlyZWREaXNrQnl0ZXMSMwoWc291cmNlX2JpdHNfcGVy'
    'X3dlaWdodBgLIAEoAVITc291cmNlQml0c1BlcldlaWdodBIzChZ0YXJnZXRfYml0c19wZXJfd2'
    'VpZ2h0GAwgASgBUhN0YXJnZXRCaXRzUGVyV2VpZ2h0EisKEWlzX3JlcXVhbnRpemF0aW9uGA0g'
    'ASgIUhBpc1JlcXVhbnRpemF0aW9uEhoKCGZlYXNpYmxlGA4gASgIUghmZWFzaWJsZRIaCghibG'
    '9ja2VycxgPIAMoCVIIYmxvY2tlcnMSGgoId2FybmluZ3MYECADKAlSCHdhcm5pbmdz');

@$core.Deprecated('Use preflightQuantizationRequestDescriptor instead')
const PreflightQuantizationRequest$json = {
  '1': 'PreflightQuantizationRequest',
  '2': [
    {
      '1': 'request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.QuantizationRequest',
      '10': 'request'
    },
  ],
};

/// Descriptor for `PreflightQuantizationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preflightQuantizationRequestDescriptor =
    $convert.base64Decode(
        'ChxQcmVmbGlnaHRRdWFudGl6YXRpb25SZXF1ZXN0EkUKB3JlcXVlc3QYASABKAsyKy5jdWxwZW'
        '9zdHVkaW8uZW5naW5lLnYxLlF1YW50aXphdGlvblJlcXVlc3RSB3JlcXVlc3Q=');

@$core.Deprecated('Use preflightQuantizationResponseDescriptor instead')
const PreflightQuantizationResponse$json = {
  '1': 'PreflightQuantizationResponse',
  '2': [
    {
      '1': 'preflight',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.QuantizationPreflight',
      '10': 'preflight'
    },
  ],
};

/// Descriptor for `PreflightQuantizationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preflightQuantizationResponseDescriptor =
    $convert.base64Decode(
        'Ch1QcmVmbGlnaHRRdWFudGl6YXRpb25SZXNwb25zZRJLCglwcmVmbGlnaHQYASABKAsyLS5jdW'
        'xwZW9zdHVkaW8uZW5naW5lLnYxLlF1YW50aXphdGlvblByZWZsaWdodFIJcHJlZmxpZ2h0');

@$core.Deprecated('Use startQuantizationRequestDescriptor instead')
const StartQuantizationRequest$json = {
  '1': 'StartQuantizationRequest',
  '2': [
    {
      '1': 'request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.QuantizationRequest',
      '10': 'request'
    },
  ],
};

/// Descriptor for `StartQuantizationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startQuantizationRequestDescriptor =
    $convert.base64Decode(
        'ChhTdGFydFF1YW50aXphdGlvblJlcXVlc3QSRQoHcmVxdWVzdBgBIAEoCzIrLmN1bHBlb3N0dW'
        'Rpby5lbmdpbmUudjEuUXVhbnRpemF0aW9uUmVxdWVzdFIHcmVxdWVzdA==');

@$core.Deprecated('Use startQuantizationResponseDescriptor instead')
const StartQuantizationResponse$json = {
  '1': 'StartQuantizationResponse',
  '2': [
    {'1': 'operation_id', '3': 1, '4': 1, '5': 9, '10': 'operationId'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.engine.v1.OperationState',
      '10': 'state'
    },
    {
      '1': 'preflight',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.QuantizationPreflight',
      '10': 'preflight'
    },
  ],
};

/// Descriptor for `StartQuantizationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startQuantizationResponseDescriptor = $convert.base64Decode(
    'ChlTdGFydFF1YW50aXphdGlvblJlc3BvbnNlEiEKDG9wZXJhdGlvbl9pZBgBIAEoCVILb3Blcm'
    'F0aW9uSWQSPAoFc3RhdGUYAiABKA4yJi5jdWxwZW9zdHVkaW8uZW5naW5lLnYxLk9wZXJhdGlv'
    'blN0YXRlUgVzdGF0ZRJLCglwcmVmbGlnaHQYAyABKAsyLS5jdWxwZW9zdHVkaW8uZW5naW5lLn'
    'YxLlF1YW50aXphdGlvblByZWZsaWdodFIJcHJlZmxpZ2h0');

@$core.Deprecated('Use enginePresetDescriptor instead')
const EnginePreset$json = {
  '1': 'EnginePreset',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'config',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EngineConfig',
      '10': 'config'
    },
    {'1': 'model_id', '3': 5, '4': 1, '5': 9, '10': 'modelId'},
    {
      '1': 'created_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {'1': 'built_in', '3': 8, '4': 1, '5': 8, '10': 'builtIn'},
  ],
};

/// Descriptor for `EnginePreset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enginePresetDescriptor = $convert.base64Decode(
    'CgxFbmdpbmVQcmVzZXQSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSIAoLZG'
    'VzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEjwKBmNvbmZpZxgEIAEoCzIkLmN1bHBlb3N0'
    'dWRpby5lbmdpbmUudjEuRW5naW5lQ29uZmlnUgZjb25maWcSGQoIbW9kZWxfaWQYBSABKAlSB2'
    '1vZGVsSWQSOQoKY3JlYXRlZF9hdBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS'
    'CWNyZWF0ZWRBdBI5Cgp1cGRhdGVkX2F0GAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
    'FtcFIJdXBkYXRlZEF0EhkKCGJ1aWx0X2luGAggASgIUgdidWlsdElu');

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
      '6': '.culpeostudio.engine.v1.EnginePreset',
      '10': 'presets'
    },
  ],
};

/// Descriptor for `ListPresetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPresetsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0UHJlc2V0c1Jlc3BvbnNlEj4KB3ByZXNldHMYASADKAsyJC5jdWxwZW9zdHVkaW8uZW'
    '5naW5lLnYxLkVuZ2luZVByZXNldFIHcHJlc2V0cw==');

@$core.Deprecated('Use savePresetRequestDescriptor instead')
const SavePresetRequest$json = {
  '1': 'SavePresetRequest',
  '2': [
    {
      '1': 'preset',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EnginePreset',
      '10': 'preset'
    },
  ],
};

/// Descriptor for `SavePresetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savePresetRequestDescriptor = $convert.base64Decode(
    'ChFTYXZlUHJlc2V0UmVxdWVzdBI8CgZwcmVzZXQYASABKAsyJC5jdWxwZW9zdHVkaW8uZW5naW'
    '5lLnYxLkVuZ2luZVByZXNldFIGcHJlc2V0');

@$core.Deprecated('Use savePresetResponseDescriptor instead')
const SavePresetResponse$json = {
  '1': 'SavePresetResponse',
  '2': [
    {
      '1': 'preset',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EnginePreset',
      '10': 'preset'
    },
  ],
};

/// Descriptor for `SavePresetResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savePresetResponseDescriptor = $convert.base64Decode(
    'ChJTYXZlUHJlc2V0UmVzcG9uc2USPAoGcHJlc2V0GAEgASgLMiQuY3VscGVvc3R1ZGlvLmVuZ2'
    'luZS52MS5FbmdpbmVQcmVzZXRSBnByZXNldA==');

@$core.Deprecated('Use deletePresetRequestDescriptor instead')
const DeletePresetRequest$json = {
  '1': 'DeletePresetRequest',
  '2': [
    {'1': 'preset_id', '3': 1, '4': 1, '5': 9, '10': 'presetId'},
  ],
};

/// Descriptor for `DeletePresetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePresetRequestDescriptor =
    $convert.base64Decode(
        'ChNEZWxldGVQcmVzZXRSZXF1ZXN0EhsKCXByZXNldF9pZBgBIAEoCVIIcHJlc2V0SWQ=');

@$core.Deprecated('Use deletePresetResponseDescriptor instead')
const DeletePresetResponse$json = {
  '1': 'DeletePresetResponse',
  '2': [
    {'1': 'deleted', '3': 1, '4': 1, '5': 8, '10': 'deleted'},
  ],
};

/// Descriptor for `DeletePresetResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePresetResponseDescriptor =
    $convert.base64Decode(
        'ChREZWxldGVQcmVzZXRSZXNwb25zZRIYCgdkZWxldGVkGAEgASgIUgdkZWxldGVk');

@$core.Deprecated('Use exportPresetsRequestDescriptor instead')
const ExportPresetsRequest$json = {
  '1': 'ExportPresetsRequest',
  '2': [
    {'1': 'preset_ids', '3': 1, '4': 3, '5': 9, '10': 'presetIds'},
  ],
};

/// Descriptor for `ExportPresetsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportPresetsRequestDescriptor = $convert.base64Decode(
    'ChRFeHBvcnRQcmVzZXRzUmVxdWVzdBIdCgpwcmVzZXRfaWRzGAEgAygJUglwcmVzZXRJZHM=');

@$core.Deprecated('Use exportPresetsResponseDescriptor instead')
const ExportPresetsResponse$json = {
  '1': 'ExportPresetsResponse',
  '2': [
    {'1': 'document', '3': 1, '4': 1, '5': 9, '10': 'document'},
    {
      '1': 'suggested_filename',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'suggestedFilename'
    },
  ],
};

/// Descriptor for `ExportPresetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportPresetsResponseDescriptor = $convert.base64Decode(
    'ChVFeHBvcnRQcmVzZXRzUmVzcG9uc2USGgoIZG9jdW1lbnQYASABKAlSCGRvY3VtZW50Ei0KEn'
    'N1Z2dlc3RlZF9maWxlbmFtZRgCIAEoCVIRc3VnZ2VzdGVkRmlsZW5hbWU=');

@$core.Deprecated('Use importPresetsRequestDescriptor instead')
const ImportPresetsRequest$json = {
  '1': 'ImportPresetsRequest',
  '2': [
    {'1': 'document', '3': 1, '4': 1, '5': 9, '10': 'document'},
  ],
};

/// Descriptor for `ImportPresetsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importPresetsRequestDescriptor =
    $convert.base64Decode(
        'ChRJbXBvcnRQcmVzZXRzUmVxdWVzdBIaCghkb2N1bWVudBgBIAEoCVIIZG9jdW1lbnQ=');

@$core.Deprecated('Use importPresetsResponseDescriptor instead')
const ImportPresetsResponse$json = {
  '1': 'ImportPresetsResponse',
  '2': [
    {
      '1': 'presets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.engine.v1.EnginePreset',
      '10': 'presets'
    },
  ],
};

/// Descriptor for `ImportPresetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importPresetsResponseDescriptor = $convert.base64Decode(
    'ChVJbXBvcnRQcmVzZXRzUmVzcG9uc2USPgoHcHJlc2V0cxgBIAMoCzIkLmN1bHBlb3N0dWRpby'
    '5lbmdpbmUudjEuRW5naW5lUHJlc2V0UgdwcmVzZXRz');
