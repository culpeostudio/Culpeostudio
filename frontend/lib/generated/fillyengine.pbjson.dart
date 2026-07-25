// This is a generated file - do not edit.
//
// Generated from fillyengine.proto.

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

@$core.Deprecated('Use startEngineRequestDescriptor instead')
const StartEngineRequest$json = {
  '1': 'StartEngineRequest',
  '2': [
    {'1': 'model_path', '3': 1, '4': 1, '5': 9, '10': 'modelPath'},
    {'1': 'gpu_layers', '3': 2, '4': 1, '5': 5, '10': 'gpuLayers'},
    {'1': 'threads', '3': 3, '4': 1, '5': 5, '10': 'threads'},
    {'1': 'context_size', '3': 4, '4': 1, '5': 5, '10': 'contextSize'},
  ],
};

/// Descriptor for `StartEngineRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startEngineRequestDescriptor = $convert.base64Decode(
    'ChJTdGFydEVuZ2luZVJlcXVlc3QSHQoKbW9kZWxfcGF0aBgBIAEoCVIJbW9kZWxQYXRoEh0KCm'
    'dwdV9sYXllcnMYAiABKAVSCWdwdUxheWVycxIYCgd0aHJlYWRzGAMgASgFUgd0aHJlYWRzEiEK'
    'DGNvbnRleHRfc2l6ZRgEIAEoBVILY29udGV4dFNpemU=');

@$core.Deprecated('Use loadModelRequestDescriptor instead')
const LoadModelRequest$json = {
  '1': 'LoadModelRequest',
  '2': [
    {'1': 'model_path', '3': 1, '4': 1, '5': 9, '10': 'modelPath'},
  ],
};

/// Descriptor for `LoadModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loadModelRequestDescriptor = $convert.base64Decode(
    'ChBMb2FkTW9kZWxSZXF1ZXN0Eh0KCm1vZGVsX3BhdGgYASABKAlSCW1vZGVsUGF0aA==');

@$core.Deprecated('Use engineStatusDescriptor instead')
const EngineStatus$json = {
  '1': 'EngineStatus',
  '2': [
    {'1': 'running', '3': 1, '4': 1, '5': 8, '10': 'running'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
    {'1': 'vram_used_mb', '3': 3, '4': 1, '5': 3, '10': 'vramUsedMb'},
    {'1': 'ram_used_mb', '3': 4, '4': 1, '5': 3, '10': 'ramUsedMb'},
  ],
};

/// Descriptor for `EngineStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineStatusDescriptor = $convert.base64Decode(
    'CgxFbmdpbmVTdGF0dXMSGAoHcnVubmluZxgBIAEoCFIHcnVubmluZxIUCgVtb2RlbBgCIAEoCV'
    'IFbW9kZWwSIAoMdnJhbV91c2VkX21iGAMgASgDUgp2cmFtVXNlZE1iEh4KC3JhbV91c2VkX21i'
    'GAQgASgDUglyYW1Vc2VkTWI=');

@$core.Deprecated('Use modelListDescriptor instead')
const ModelList$json = {
  '1': 'ModelList',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.ModelInfo',
      '10': 'models'
    },
  ],
};

/// Descriptor for `ModelList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelListDescriptor = $convert.base64Decode(
    'CglNb2RlbExpc3QSLgoGbW9kZWxzGAEgAygLMhYuZmlsbHllbmdpbmUuTW9kZWxJbmZvUgZtb2'
    'RlbHM=');

@$core.Deprecated('Use modelInfoDescriptor instead')
const ModelInfo$json = {
  '1': 'ModelInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'format', '3': 3, '4': 1, '5': 9, '10': 'format'},
    {'1': 'size_bytes', '3': 4, '4': 1, '5': 3, '10': 'sizeBytes'},
  ],
};

/// Descriptor for `ModelInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelInfoDescriptor = $convert.base64Decode(
    'CglNb2RlbEluZm8SEgoEbmFtZRgBIAEoCVIEbmFtZRISCgRwYXRoGAIgASgJUgRwYXRoEhYKBm'
    'Zvcm1hdBgDIAEoCVIGZm9ybWF0Eh0KCnNpemVfYnl0ZXMYBCABKANSCXNpemVCeXRlcw==');

@$core.Deprecated('Use createSessionRequestDescriptor instead')
const CreateSessionRequest$json = {
  '1': 'CreateSessionRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
  ],
};

/// Descriptor for `CreateSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionRequestDescriptor =
    $convert.base64Decode(
        'ChRDcmVhdGVTZXNzaW9uUmVxdWVzdBIZCghtb2RlbF9pZBgBIAEoCVIHbW9kZWxJZA==');

@$core.Deprecated('Use sessionInfoDescriptor instead')
const SessionInfo$json = {
  '1': 'SessionInfo',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'model_id', '3': 2, '4': 1, '5': 9, '10': 'modelId'},
  ],
};

/// Descriptor for `SessionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionInfoDescriptor = $convert.base64Decode(
    'CgtTZXNzaW9uSW5mbxIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGQoIbW9kZWxfaW'
    'QYAiABKAlSB21vZGVsSWQ=');

@$core.Deprecated('Use sessionRequestDescriptor instead')
const SessionRequest$json = {
  '1': 'SessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `SessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionRequestDescriptor = $convert.base64Decode(
    'Cg5TZXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use chatMessageRequestDescriptor instead')
const ChatMessageRequest$json = {
  '1': 'ChatMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'temperature', '3': 3, '4': 1, '5': 2, '10': 'temperature'},
    {'1': 'max_tokens', '3': 4, '4': 1, '5': 5, '10': 'maxTokens'},
  ],
};

/// Descriptor for `ChatMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageRequestDescriptor = $convert.base64Decode(
    'ChJDaGF0TWVzc2FnZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhgKB2'
    '1lc3NhZ2UYAiABKAlSB21lc3NhZ2USIAoLdGVtcGVyYXR1cmUYAyABKAJSC3RlbXBlcmF0dXJl'
    'Eh0KCm1heF90b2tlbnMYBCABKAVSCW1heFRva2Vucw==');

@$core.Deprecated('Use chatMessageResponseDescriptor instead')
const ChatMessageResponse$json = {
  '1': 'ChatMessageResponse',
  '2': [
    {'1': 'reply', '3': 1, '4': 1, '5': 9, '10': 'reply'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'tokens_used', '3': 3, '4': 1, '5': 5, '10': 'tokensUsed'},
  ],
};

/// Descriptor for `ChatMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageResponseDescriptor = $convert.base64Decode(
    'ChNDaGF0TWVzc2FnZVJlc3BvbnNlEhQKBXJlcGx5GAEgASgJUgVyZXBseRIdCgpzZXNzaW9uX2'
    'lkGAIgASgJUglzZXNzaW9uSWQSHwoLdG9rZW5zX3VzZWQYAyABKAVSCnRva2Vuc1VzZWQ=');

@$core.Deprecated('Use chatTokenDescriptor instead')
const ChatToken$json = {
  '1': 'ChatToken',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'done', '3': 2, '4': 1, '5': 8, '10': 'done'},
  ],
};

/// Descriptor for `ChatToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatTokenDescriptor = $convert.base64Decode(
    'CglDaGF0VG9rZW4SFAoFdG9rZW4YASABKAlSBXRva2VuEhIKBGRvbmUYAiABKAhSBGRvbmU=');

@$core.Deprecated('Use chatHistoryDescriptor instead')
const ChatHistory$json = {
  '1': 'ChatHistory',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.ChatEntry',
      '10': 'messages'
    },
  ],
};

/// Descriptor for `ChatHistory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatHistoryDescriptor = $convert.base64Decode(
    'CgtDaGF0SGlzdG9yeRIyCghtZXNzYWdlcxgBIAMoCzIWLmZpbGx5ZW5naW5lLkNoYXRFbnRyeV'
    'IIbWVzc2FnZXM=');

@$core.Deprecated('Use chatEntryDescriptor instead')
const ChatEntry$json = {
  '1': 'ChatEntry',
  '2': [
    {'1': 'role', '3': 1, '4': 1, '5': 9, '10': 'role'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `ChatEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatEntryDescriptor = $convert.base64Decode(
    'CglDaGF0RW50cnkSEgoEcm9sZRgBIAEoCVIEcm9sZRIYCgdjb250ZW50GAIgASgJUgdjb250ZW'
    '50EhwKCXRpbWVzdGFtcBgDIAEoA1IJdGltZXN0YW1w');

@$core.Deprecated('Use trainingRequestDescriptor instead')
const TrainingRequest$json = {
  '1': 'TrainingRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'dataset_path', '3': 2, '4': 1, '5': 9, '10': 'datasetPath'},
    {
      '1': 'hyperparams',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.TrainingRequest.HyperparamsEntry',
      '10': 'hyperparams'
    },
  ],
  '3': [TrainingRequest_HyperparamsEntry$json],
};

@$core.Deprecated('Use trainingRequestDescriptor instead')
const TrainingRequest_HyperparamsEntry$json = {
  '1': 'HyperparamsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `TrainingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trainingRequestDescriptor = $convert.base64Decode(
    'Cg9UcmFpbmluZ1JlcXVlc3QSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQSIQoMZGF0YXNldF'
    '9wYXRoGAIgASgJUgtkYXRhc2V0UGF0aBJPCgtoeXBlcnBhcmFtcxgDIAMoCzItLmZpbGx5ZW5n'
    'aW5lLlRyYWluaW5nUmVxdWVzdC5IeXBlcnBhcmFtc0VudHJ5UgtoeXBlcnBhcmFtcxo+ChBIeX'
    'BlcnBhcmFtc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToC'
    'OAE=');

@$core.Deprecated('Use jobRequestDescriptor instead')
const JobRequest$json = {
  '1': 'JobRequest',
  '2': [
    {'1': 'job_id', '3': 1, '4': 1, '5': 9, '10': 'jobId'},
  ],
};

/// Descriptor for `JobRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jobRequestDescriptor =
    $convert.base64Decode('CgpKb2JSZXF1ZXN0EhUKBmpvYl9pZBgBIAEoCVIFam9iSWQ=');

@$core.Deprecated('Use jobInfoDescriptor instead')
const JobInfo$json = {
  '1': 'JobInfo',
  '2': [
    {'1': 'job_id', '3': 1, '4': 1, '5': 9, '10': 'jobId'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `JobInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jobInfoDescriptor = $convert.base64Decode(
    'CgdKb2JJbmZvEhUKBmpvYl9pZBgBIAEoCVIFam9iSWQSFgoGc3RhdHVzGAIgASgJUgZzdGF0dX'
    'M=');

@$core.Deprecated('Use jobStatusDescriptor instead')
const JobStatus$json = {
  '1': 'JobStatus',
  '2': [
    {'1': 'job_id', '3': 1, '4': 1, '5': 9, '10': 'jobId'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'progress', '3': 3, '4': 1, '5': 5, '10': 'progress'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `JobStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jobStatusDescriptor = $convert.base64Decode(
    'CglKb2JTdGF0dXMSFQoGam9iX2lkGAEgASgJUgVqb2JJZBIWCgZzdGF0dXMYAiABKAlSBnN0YX'
    'R1cxIaCghwcm9ncmVzcxgDIAEoBVIIcHJvZ3Jlc3MSFAoFZXJyb3IYBCABKAlSBWVycm9y');

@$core.Deprecated('Use jobListDescriptor instead')
const JobList$json = {
  '1': 'JobList',
  '2': [
    {
      '1': 'jobs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.JobStatus',
      '10': 'jobs'
    },
  ],
};

/// Descriptor for `JobList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jobListDescriptor = $convert.base64Decode(
    'CgdKb2JMaXN0EioKBGpvYnMYASADKAsyFi5maWxseWVuZ2luZS5Kb2JTdGF0dXNSBGpvYnM=');

@$core.Deprecated('Use trainingMetricsDescriptor instead')
const TrainingMetrics$json = {
  '1': 'TrainingMetrics',
  '2': [
    {'1': 'epoch', '3': 1, '4': 1, '5': 5, '10': 'epoch'},
    {'1': 'step', '3': 2, '4': 1, '5': 5, '10': 'step'},
    {'1': 'loss', '3': 3, '4': 1, '5': 2, '10': 'loss'},
    {'1': 'learning_rate', '3': 4, '4': 1, '5': 2, '10': 'learningRate'},
    {'1': 'progress_percent', '3': 5, '4': 1, '5': 5, '10': 'progressPercent'},
  ],
};

/// Descriptor for `TrainingMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trainingMetricsDescriptor = $convert.base64Decode(
    'Cg9UcmFpbmluZ01ldHJpY3MSFAoFZXBvY2gYASABKAVSBWVwb2NoEhIKBHN0ZXAYAiABKAVSBH'
    'N0ZXASEgoEbG9zcxgDIAEoAlIEbG9zcxIjCg1sZWFybmluZ19yYXRlGAQgASgCUgxsZWFybmlu'
    'Z1JhdGUSKQoQcHJvZ3Jlc3NfcGVyY2VudBgFIAEoBVIPcHJvZ3Jlc3NQZXJjZW50');

@$core.Deprecated('Use quantRequestDescriptor instead')
const QuantRequest$json = {
  '1': 'QuantRequest',
  '2': [
    {'1': 'model_path', '3': 1, '4': 1, '5': 9, '10': 'modelPath'},
    {'1': 'quant_type', '3': 2, '4': 1, '5': 9, '10': 'quantType'},
    {'1': 'output_path', '3': 3, '4': 1, '5': 9, '10': 'outputPath'},
  ],
};

/// Descriptor for `QuantRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quantRequestDescriptor = $convert.base64Decode(
    'CgxRdWFudFJlcXVlc3QSHQoKbW9kZWxfcGF0aBgBIAEoCVIJbW9kZWxQYXRoEh0KCnF1YW50X3'
    'R5cGUYAiABKAlSCXF1YW50VHlwZRIfCgtvdXRwdXRfcGF0aBgDIAEoCVIKb3V0cHV0UGF0aA==');

@$core.Deprecated('Use quantTypesDescriptor instead')
const QuantTypes$json = {
  '1': 'QuantTypes',
  '2': [
    {'1': 'types', '3': 1, '4': 3, '5': 9, '10': 'types'},
  ],
};

/// Descriptor for `QuantTypes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quantTypesDescriptor =
    $convert.base64Decode('CgpRdWFudFR5cGVzEhQKBXR5cGVzGAEgAygJUgV0eXBlcw==');

@$core.Deprecated('Use quantProgressDescriptor instead')
const QuantProgress$json = {
  '1': 'QuantProgress',
  '2': [
    {'1': 'job_id', '3': 1, '4': 1, '5': 9, '10': 'jobId'},
    {'1': 'progress_percent', '3': 2, '4': 1, '5': 5, '10': 'progressPercent'},
    {'1': 'current_step', '3': 3, '4': 1, '5': 9, '10': 'currentStep'},
  ],
};

/// Descriptor for `QuantProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quantProgressDescriptor = $convert.base64Decode(
    'Cg1RdWFudFByb2dyZXNzEhUKBmpvYl9pZBgBIAEoCVIFam9iSWQSKQoQcHJvZ3Jlc3NfcGVyY2'
    'VudBgCIAEoBVIPcHJvZ3Jlc3NQZXJjZW50EiEKDGN1cnJlbnRfc3RlcBgDIAEoCVILY3VycmVu'
    'dFN0ZXA=');

@$core.Deprecated('Use searchRequestDescriptor instead')
const SearchRequest$json = {
  '1': 'SearchRequest',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '10': 'format'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'offset', '3': 4, '4': 1, '5': 5, '10': 'offset'},
  ],
};

/// Descriptor for `SearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchRequestDescriptor = $convert.base64Decode(
    'Cg1TZWFyY2hSZXF1ZXN0EhQKBXF1ZXJ5GAEgASgJUgVxdWVyeRIWCgZmb3JtYXQYAiABKAlSBm'
    'Zvcm1hdBIUCgVsaW1pdBgDIAEoBVIFbGltaXQSFgoGb2Zmc2V0GAQgASgFUgZvZmZzZXQ=');

@$core.Deprecated('Use searchResponseDescriptor instead')
const SearchResponse$json = {
  '1': 'SearchResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.ModelDetail',
      '10': 'models'
    },
    {'1': 'total', '3': 2, '4': 1, '5': 5, '10': 'total'},
  ],
};

/// Descriptor for `SearchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResponseDescriptor = $convert.base64Decode(
    'Cg5TZWFyY2hSZXNwb25zZRIwCgZtb2RlbHMYASADKAsyGC5maWxseWVuZ2luZS5Nb2RlbERldG'
    'FpbFIGbW9kZWxzEhQKBXRvdGFsGAIgASgFUgV0b3RhbA==');

@$core.Deprecated('Use modelDetailRequestDescriptor instead')
const ModelDetailRequest$json = {
  '1': 'ModelDetailRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
  ],
};

/// Descriptor for `ModelDetailRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelDetailRequestDescriptor =
    $convert.base64Decode(
        'ChJNb2RlbERldGFpbFJlcXVlc3QSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQ=');

@$core.Deprecated('Use modelDetailDescriptor instead')
const ModelDetail$json = {
  '1': 'ModelDetail',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {'1': 'formats', '3': 5, '4': 3, '5': 9, '10': 'formats'},
    {'1': 'size_bytes', '3': 6, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'downloads', '3': 7, '4': 1, '5': 3, '10': 'downloads'},
  ],
};

/// Descriptor for `ModelDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelDetailDescriptor = $convert.base64Decode(
    'CgtNb2RlbERldGFpbBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIgCgtkZX'
    'NjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SFgoGYXV0aG9yGAQgASgJUgZhdXRob3ISGAoH'
    'Zm9ybWF0cxgFIAMoCVIHZm9ybWF0cxIdCgpzaXplX2J5dGVzGAYgASgDUglzaXplQnl0ZXMSHA'
    'oJZG93bmxvYWRzGAcgASgDUglkb3dubG9hZHM=');

@$core.Deprecated('Use downloadRequestDescriptor instead')
const DownloadRequest$json = {
  '1': 'DownloadRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '10': 'format'},
  ],
};

/// Descriptor for `DownloadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadRequestDescriptor = $convert.base64Decode(
    'Cg9Eb3dubG9hZFJlcXVlc3QSGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQSFgoGZm9ybWF0GA'
    'IgASgJUgZmb3JtYXQ=');

@$core.Deprecated('Use downloadProgressDescriptor instead')
const DownloadProgress$json = {
  '1': 'DownloadProgress',
  '2': [
    {'1': 'job_id', '3': 1, '4': 1, '5': 9, '10': 'jobId'},
    {'1': 'bytes_downloaded', '3': 2, '4': 1, '5': 3, '10': 'bytesDownloaded'},
    {'1': 'bytes_total', '3': 3, '4': 1, '5': 3, '10': 'bytesTotal'},
    {'1': 'progress_percent', '3': 4, '4': 1, '5': 5, '10': 'progressPercent'},
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `DownloadProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadProgressDescriptor = $convert.base64Decode(
    'ChBEb3dubG9hZFByb2dyZXNzEhUKBmpvYl9pZBgBIAEoCVIFam9iSWQSKQoQYnl0ZXNfZG93bm'
    'xvYWRlZBgCIAEoA1IPYnl0ZXNEb3dubG9hZGVkEh8KC2J5dGVzX3RvdGFsGAMgASgDUgpieXRl'
    'c1RvdGFsEikKEHByb2dyZXNzX3BlcmNlbnQYBCABKAVSD3Byb2dyZXNzUGVyY2VudBIWCgZzdG'
    'F0dXMYBSABKAlSBnN0YXR1cw==');

@$core.Deprecated('Use importSkillRequestDescriptor instead')
const ImportSkillRequest$json = {
  '1': 'ImportSkillRequest',
  '2': [
    {'1': 'source_path', '3': 1, '4': 1, '5': 9, '10': 'sourcePath'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `ImportSkillRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importSkillRequestDescriptor = $convert.base64Decode(
    'ChJJbXBvcnRTa2lsbFJlcXVlc3QSHwoLc291cmNlX3BhdGgYASABKAlSCnNvdXJjZVBhdGgSGA'
    'oHZW5hYmxlZBgCIAEoCFIHZW5hYmxlZA==');

@$core.Deprecated('Use updateSkillRequestDescriptor instead')
const UpdateSkillRequest$json = {
  '1': 'UpdateSkillRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `UpdateSkillRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSkillRequestDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVTa2lsbFJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIYCgdlbmFibGVkGAIgAS'
    'gIUgdlbmFibGVk');

@$core.Deprecated('Use deleteSkillRequestDescriptor instead')
const DeleteSkillRequest$json = {
  '1': 'DeleteSkillRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DeleteSkillRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSkillRequestDescriptor = $convert
    .base64Decode('ChJEZWxldGVTa2lsbFJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use skillListResponseDescriptor instead')
const SkillListResponse$json = {
  '1': 'SkillListResponse',
  '2': [
    {
      '1': 'skills',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.SkillRecord',
      '10': 'skills'
    },
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `SkillListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillListResponseDescriptor = $convert.base64Decode(
    'ChFTa2lsbExpc3RSZXNwb25zZRIwCgZza2lsbHMYASADKAsyGC5maWxseWVuZ2luZS5Ta2lsbF'
    'JlY29yZFIGc2tpbGxzEhQKBWNvdW50GAIgASgFUgVjb3VudA==');

@$core.Deprecated('Use skillResponseDescriptor instead')
const SkillResponse$json = {
  '1': 'SkillResponse',
  '2': [
    {
      '1': 'skill',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fillyengine.SkillRecord',
      '10': 'skill'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SkillResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillResponseDescriptor = $convert.base64Decode(
    'Cg1Ta2lsbFJlc3BvbnNlEi4KBXNraWxsGAEgASgLMhguZmlsbHllbmdpbmUuU2tpbGxSZWNvcm'
    'RSBXNraWxsEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use deleteSkillResponseDescriptor instead')
const DeleteSkillResponse$json = {
  '1': 'DeleteSkillResponse',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `DeleteSkillResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSkillResponseDescriptor = $convert.base64Decode(
    'ChNEZWxldGVTa2lsbFJlc3BvbnNlEhIKBG5hbWUYASABKAlSBG5hbWUSFgoGc3RhdHVzGAIgAS'
    'gJUgZzdGF0dXMSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use skillRecordDescriptor instead')
const SkillRecord$json = {
  '1': 'SkillRecord',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'enabled', '3': 3, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
    {'1': 'imported_at_unix', '3': 5, '4': 1, '5': 3, '10': 'importedAtUnix'},
    {'1': 'updated_at_unix', '3': 6, '4': 1, '5': 3, '10': 'updatedAtUnix'},
    {'1': 'license', '3': 7, '4': 1, '5': 9, '10': 'license'},
    {'1': 'compatibility', '3': 8, '4': 1, '5': 9, '10': 'compatibility'},
    {'1': 'metadata_json', '3': 9, '4': 1, '5': 9, '10': 'metadataJson'},
    {'1': 'allowed_tools', '3': 10, '4': 1, '5': 9, '10': 'allowedTools'},
    {'1': 'valid', '3': 11, '4': 1, '5': 8, '10': 'valid'},
    {'1': 'errors', '3': 12, '4': 3, '5': 9, '10': 'errors'},
    {
      '1': 'file_summary',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.fillyengine.SkillFileSummary',
      '10': 'fileSummary'
    },
  ],
};

/// Descriptor for `SkillRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillRecordDescriptor = $convert.base64Decode(
    'CgtTa2lsbFJlY29yZBISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUg'
    'tkZXNjcmlwdGlvbhIYCgdlbmFibGVkGAMgASgIUgdlbmFibGVkEhIKBHBhdGgYBCABKAlSBHBh'
    'dGgSKAoQaW1wb3J0ZWRfYXRfdW5peBgFIAEoA1IOaW1wb3J0ZWRBdFVuaXgSJgoPdXBkYXRlZF'
    '9hdF91bml4GAYgASgDUg11cGRhdGVkQXRVbml4EhgKB2xpY2Vuc2UYByABKAlSB2xpY2Vuc2US'
    'JAoNY29tcGF0aWJpbGl0eRgIIAEoCVINY29tcGF0aWJpbGl0eRIjCg1tZXRhZGF0YV9qc29uGA'
    'kgASgJUgxtZXRhZGF0YUpzb24SIwoNYWxsb3dlZF90b29scxgKIAEoCVIMYWxsb3dlZFRvb2xz'
    'EhQKBXZhbGlkGAsgASgIUgV2YWxpZBIWCgZlcnJvcnMYDCADKAlSBmVycm9ycxJACgxmaWxlX3'
    'N1bW1hcnkYDSABKAsyHS5maWxseWVuZ2luZS5Ta2lsbEZpbGVTdW1tYXJ5UgtmaWxlU3VtbWFy'
    'eQ==');

@$core.Deprecated('Use skillFileSummaryDescriptor instead')
const SkillFileSummary$json = {
  '1': 'SkillFileSummary',
  '2': [
    {'1': 'file_count', '3': 1, '4': 1, '5': 5, '10': 'fileCount'},
    {'1': 'directory_count', '3': 2, '4': 1, '5': 5, '10': 'directoryCount'},
    {'1': 'has_scripts', '3': 3, '4': 1, '5': 8, '10': 'hasScripts'},
    {'1': 'has_references', '3': 4, '4': 1, '5': 8, '10': 'hasReferences'},
    {'1': 'has_assets', '3': 5, '4': 1, '5': 8, '10': 'hasAssets'},
  ],
};

/// Descriptor for `SkillFileSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillFileSummaryDescriptor = $convert.base64Decode(
    'ChBTa2lsbEZpbGVTdW1tYXJ5Eh0KCmZpbGVfY291bnQYASABKAVSCWZpbGVDb3VudBInCg9kaX'
    'JlY3RvcnlfY291bnQYAiABKAVSDmRpcmVjdG9yeUNvdW50Eh8KC2hhc19zY3JpcHRzGAMgASgI'
    'UgpoYXNTY3JpcHRzEiUKDmhhc19yZWZlcmVuY2VzGAQgASgIUg1oYXNSZWZlcmVuY2VzEh0KCm'
    'hhc19hc3NldHMYBSABKAhSCWhhc0Fzc2V0cw==');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use agenticRequestDescriptor instead')
const AgenticRequest$json = {
  '1': 'AgenticRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'user_message', '3': 2, '4': 1, '5': 9, '10': 'userMessage'},
    {'1': 'thinking_level', '3': 3, '4': 1, '5': 9, '10': 'thinkingLevel'},
    {'1': 'mode', '3': 4, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'allowed_roots', '3': 5, '4': 3, '5': 9, '10': 'allowedRoots'},
    {
      '1': 'context',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.AgenticRequest.ContextEntry',
      '10': 'context'
    },
  ],
  '3': [AgenticRequest_ContextEntry$json],
};

@$core.Deprecated('Use agenticRequestDescriptor instead')
const AgenticRequest_ContextEntry$json = {
  '1': 'ContextEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `AgenticRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agenticRequestDescriptor = $convert.base64Decode(
    'Cg5BZ2VudGljUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSIQoMdXNlcl'
    '9tZXNzYWdlGAIgASgJUgt1c2VyTWVzc2FnZRIlCg50aGlua2luZ19sZXZlbBgDIAEoCVINdGhp'
    'bmtpbmdMZXZlbBISCgRtb2RlGAQgASgJUgRtb2RlEiMKDWFsbG93ZWRfcm9vdHMYBSADKAlSDG'
    'FsbG93ZWRSb290cxJCCgdjb250ZXh0GAYgAygLMiguZmlsbHllbmdpbmUuQWdlbnRpY1JlcXVl'
    'c3QuQ29udGV4dEVudHJ5Ugdjb250ZXh0GjoKDENvbnRleHRFbnRyeRIQCgNrZXkYASABKAlSA2'
    'tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use agenticResponseDescriptor instead')
const AgenticResponse$json = {
  '1': 'AgenticResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.fillyengine.AgenticResponse.Type',
      '10': 'type'
    },
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'tool_call',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fillyengine.ToolCall',
      '10': 'toolCall'
    },
    {
      '1': 'planning',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.fillyengine.PlanningState',
      '10': 'planning'
    },
    {
      '1': 'compression',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.fillyengine.CompressionEvent',
      '10': 'compression'
    },
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
    {'1': 'done', '3': 7, '4': 1, '5': 8, '10': 'done'},
  ],
  '4': [AgenticResponse_Type$json],
};

@$core.Deprecated('Use agenticResponseDescriptor instead')
const AgenticResponse_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TEXT_DELTA', '2': 0},
    {'1': 'TOOL_START', '2': 1},
    {'1': 'TOOL_RESULT', '2': 2},
    {'1': 'PLANNING_QUESTIONS', '2': 3},
    {'1': 'PLAN_READY', '2': 4},
    {'1': 'APPROVAL_NEEDED', '2': 5},
    {'1': 'COMPRESSION_EVENT', '2': 6},
    {'1': 'ERROR', '2': 7},
    {'1': 'DONE', '2': 8},
  ],
};

/// Descriptor for `AgenticResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agenticResponseDescriptor = $convert.base64Decode(
    'Cg9BZ2VudGljUmVzcG9uc2USNQoEdHlwZRgBIAEoDjIhLmZpbGx5ZW5naW5lLkFnZW50aWNSZX'
    'Nwb25zZS5UeXBlUgR0eXBlEhIKBHRleHQYAiABKAlSBHRleHQSMgoJdG9vbF9jYWxsGAMgASgL'
    'MhUuZmlsbHllbmdpbmUuVG9vbENhbGxSCHRvb2xDYWxsEjYKCHBsYW5uaW5nGAQgASgLMhouZm'
    'lsbHllbmdpbmUuUGxhbm5pbmdTdGF0ZVIIcGxhbm5pbmcSPwoLY29tcHJlc3Npb24YBSABKAsy'
    'HS5maWxseWVuZ2luZS5Db21wcmVzc2lvbkV2ZW50Ugtjb21wcmVzc2lvbhIUCgVlcnJvchgGIA'
    'EoCVIFZXJyb3ISEgoEZG9uZRgHIAEoCFIEZG9uZSKgAQoEVHlwZRIOCgpURVhUX0RFTFRBEAAS'
    'DgoKVE9PTF9TVEFSVBABEg8KC1RPT0xfUkVTVUxUEAISFgoSUExBTk5JTkdfUVVFU1RJT05TEA'
    'MSDgoKUExBTl9SRUFEWRAEEhMKD0FQUFJPVkFMX05FRURFRBAFEhUKEUNPTVBSRVNTSU9OX0VW'
    'RU5UEAYSCQoFRVJST1IQBxIICgRET05FEAg=');

@$core.Deprecated('Use toolCallDescriptor instead')
const ToolCall$json = {
  '1': 'ToolCall',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'arguments', '3': 3, '4': 1, '5': 9, '10': 'arguments'},
    {'1': 'result_preview', '3': 4, '4': 1, '5': 9, '10': 'resultPreview'},
    {'1': 'success', '3': 5, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ToolCall`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toolCallDescriptor = $convert.base64Decode(
    'CghUb29sQ2FsbBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIcCglhcmd1bW'
    'VudHMYAyABKAlSCWFyZ3VtZW50cxIlCg5yZXN1bHRfcHJldmlldxgEIAEoCVINcmVzdWx0UHJl'
    'dmlldxIYCgdzdWNjZXNzGAUgASgIUgdzdWNjZXNzEhQKBWVycm9yGAYgASgJUgVlcnJvcg==');

@$core.Deprecated('Use planningStateDescriptor instead')
const PlanningState$json = {
  '1': 'PlanningState',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'questions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.PlanningQuestion',
      '10': 'questions'
    },
    {'1': 'plan_summary', '3': 3, '4': 1, '5': 9, '10': 'planSummary'},
    {'1': 'steps', '3': 4, '4': 3, '5': 9, '10': 'steps'},
    {'1': 'risks', '3': 5, '4': 3, '5': 9, '10': 'risks'},
    {'1': 'tests', '3': 6, '4': 3, '5': 9, '10': 'tests'},
  ],
};

/// Descriptor for `PlanningState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List planningStateDescriptor = $convert.base64Decode(
    'Cg1QbGFubmluZ1N0YXRlEhYKBnN0YXR1cxgBIAEoCVIGc3RhdHVzEjsKCXF1ZXN0aW9ucxgCIA'
    'MoCzIdLmZpbGx5ZW5naW5lLlBsYW5uaW5nUXVlc3Rpb25SCXF1ZXN0aW9ucxIhCgxwbGFuX3N1'
    'bW1hcnkYAyABKAlSC3BsYW5TdW1tYXJ5EhQKBXN0ZXBzGAQgAygJUgVzdGVwcxIUCgVyaXNrcx'
    'gFIAMoCVIFcmlza3MSFAoFdGVzdHMYBiADKAlSBXRlc3Rz');

@$core.Deprecated('Use planningQuestionDescriptor instead')
const PlanningQuestion$json = {
  '1': 'PlanningQuestion',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'prompt', '3': 2, '4': 1, '5': 9, '10': 'prompt'},
    {
      '1': 'options',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.PlanningOption',
      '10': 'options'
    },
    {'1': 'allow_custom', '3': 4, '4': 1, '5': 8, '10': 'allowCustom'},
  ],
};

/// Descriptor for `PlanningQuestion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List planningQuestionDescriptor = $convert.base64Decode(
    'ChBQbGFubmluZ1F1ZXN0aW9uEg4KAmlkGAEgASgJUgJpZBIWCgZwcm9tcHQYAiABKAlSBnByb2'
    '1wdBI1CgdvcHRpb25zGAMgAygLMhsuZmlsbHllbmdpbmUuUGxhbm5pbmdPcHRpb25SB29wdGlv'
    'bnMSIQoMYWxsb3dfY3VzdG9tGAQgASgIUgthbGxvd0N1c3RvbQ==');

@$core.Deprecated('Use planningOptionDescriptor instead')
const PlanningOption$json = {
  '1': 'PlanningOption',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `PlanningOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List planningOptionDescriptor = $convert.base64Decode(
    'Cg5QbGFubmluZ09wdGlvbhIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYmVsEi'
    'AKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbg==');

@$core.Deprecated('Use toolListDescriptor instead')
const ToolList$json = {
  '1': 'ToolList',
  '2': [
    {
      '1': 'tools',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fillyengine.ToolDef',
      '10': 'tools'
    },
  ],
};

/// Descriptor for `ToolList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toolListDescriptor = $convert.base64Decode(
    'CghUb29sTGlzdBIqCgV0b29scxgBIAMoCzIULmZpbGx5ZW5naW5lLlRvb2xEZWZSBXRvb2xz');

@$core.Deprecated('Use toolDefDescriptor instead')
const ToolDef$json = {
  '1': 'ToolDef',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'parameters_json_schema',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'parametersJsonSchema'
    },
  ],
};

/// Descriptor for `ToolDef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toolDefDescriptor = $convert.base64Decode(
    'CgdUb29sRGVmEhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2'
    'NyaXB0aW9uEjQKFnBhcmFtZXRlcnNfanNvbl9zY2hlbWEYAyABKAlSFHBhcmFtZXRlcnNKc29u'
    'U2NoZW1h');

@$core.Deprecated('Use compressionEventDescriptor instead')
const CompressionEvent$json = {
  '1': 'CompressionEvent',
  '2': [
    {'1': 'triggered', '3': 1, '4': 1, '5': 8, '10': 'triggered'},
    {'1': 'usage_before', '3': 2, '4': 1, '5': 2, '10': 'usageBefore'},
    {'1': 'usage_after', '3': 3, '4': 1, '5': 2, '10': 'usageAfter'},
    {
      '1': 'compressed_messages',
      '3': 4,
      '4': 1,
      '5': 5,
      '10': 'compressedMessages'
    },
    {'1': 'memory_id', '3': 5, '4': 1, '5': 9, '10': 'memoryId'},
  ],
};

/// Descriptor for `CompressionEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compressionEventDescriptor = $convert.base64Decode(
    'ChBDb21wcmVzc2lvbkV2ZW50EhwKCXRyaWdnZXJlZBgBIAEoCFIJdHJpZ2dlcmVkEiEKDHVzYW'
    'dlX2JlZm9yZRgCIAEoAlILdXNhZ2VCZWZvcmUSHwoLdXNhZ2VfYWZ0ZXIYAyABKAJSCnVzYWdl'
    'QWZ0ZXISLwoTY29tcHJlc3NlZF9tZXNzYWdlcxgEIAEoBVISY29tcHJlc3NlZE1lc3NhZ2VzEh'
    'sKCW1lbW9yeV9pZBgFIAEoCVIIbWVtb3J5SWQ=');
