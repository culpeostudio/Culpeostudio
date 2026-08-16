// This is a generated file - do not edit.
//
// Generated from culpeostudio/scout/v1/scout.proto.

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

@$core.Deprecated('Use chatMessageDescriptor instead')
const ChatMessage$json = {
  '1': 'ChatMessage',
  '2': [
    {'1': 'role', '3': 1, '4': 1, '5': 9, '10': 'role'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'bot_id', '3': 3, '4': 1, '5': 9, '10': 'botId'},
    {'1': 'bot_name', '3': 4, '4': 1, '5': 9, '10': 'botName'},
  ],
};

/// Descriptor for `ChatMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageDescriptor = $convert.base64Decode(
    'CgtDaGF0TWVzc2FnZRISCgRyb2xlGAEgASgJUgRyb2xlEhgKB2NvbnRlbnQYAiABKAlSB2Nvbn'
    'RlbnQSFQoGYm90X2lkGAMgASgJUgVib3RJZBIZCghib3RfbmFtZRgEIAEoCVIHYm90TmFtZQ==');

@$core.Deprecated('Use modelBindingDescriptor instead')
const ModelBinding$json = {
  '1': 'ModelBinding',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'model_ref', '3': 2, '4': 1, '5': 9, '10': 'modelRef'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model_id', '3': 4, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'instance_id', '3': 5, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'display_name', '3': 6, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'connection_id', '3': 7, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `ModelBinding`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelBindingDescriptor = $convert.base64Decode(
    'CgxNb2RlbEJpbmRpbmcSEgoEa2luZBgBIAEoCVIEa2luZBIbCgltb2RlbF9yZWYYAiABKAlSCG'
    '1vZGVsUmVmEhoKCHByb3ZpZGVyGAMgASgJUghwcm92aWRlchIZCghtb2RlbF9pZBgEIAEoCVIH'
    'bW9kZWxJZBIfCgtpbnN0YW5jZV9pZBgFIAEoCVIKaW5zdGFuY2VJZBIhCgxkaXNwbGF5X25hbW'
    'UYBiABKAlSC2Rpc3BsYXlOYW1lEiMKDWNvbm5lY3Rpb25faWQYByABKAlSDGNvbm5lY3Rpb25J'
    'ZA==');

@$core.Deprecated('Use botDescriptor instead')
const Bot$json = {
  '1': 'Bot',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'system_prompt', '3': 3, '4': 1, '5': 9, '10': 'systemPrompt'},
    {'1': 'keywords', '3': 4, '4': 3, '5': 9, '10': 'keywords'},
    {'1': 'response_style', '3': 5, '4': 1, '5': 9, '10': 'responseStyle'},
    {'1': 'agentic_enabled', '3': 6, '4': 1, '5': 8, '10': 'agenticEnabled'},
    {'1': 'allowed_roots', '3': 7, '4': 3, '5': 9, '10': 'allowedRoots'},
    {'1': 'is_default', '3': 8, '4': 1, '5': 8, '10': 'isDefault'},
    {
      '1': 'model_binding',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ModelBinding',
      '10': 'modelBinding'
    },
  ],
};

/// Descriptor for `Bot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List botDescriptor = $convert.base64Decode(
    'CgNCb3QSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSIwoNc3lzdGVtX3Byb2'
    '1wdBgDIAEoCVIMc3lzdGVtUHJvbXB0EhoKCGtleXdvcmRzGAQgAygJUghrZXl3b3JkcxIlCg5y'
    'ZXNwb25zZV9zdHlsZRgFIAEoCVINcmVzcG9uc2VTdHlsZRInCg9hZ2VudGljX2VuYWJsZWQYBi'
    'ABKAhSDmFnZW50aWNFbmFibGVkEiMKDWFsbG93ZWRfcm9vdHMYByADKAlSDGFsbG93ZWRSb290'
    'cxIdCgppc19kZWZhdWx0GAggASgIUglpc0RlZmF1bHQSSAoNbW9kZWxfYmluZGluZxgJIAEoCz'
    'IjLmN1bHBlb3N0dWRpby5zY291dC52MS5Nb2RlbEJpbmRpbmdSDG1vZGVsQmluZGluZw==');

@$core.Deprecated('Use sessionSummaryDescriptor instead')
const SessionSummary$json = {
  '1': 'SessionSummary',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'preview', '3': 3, '4': 1, '5': 9, '10': 'preview'},
    {'1': 'provider', '3': 4, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model_id', '3': 5, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'display_name', '3': 6, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'locked_bot_id', '3': 7, '4': 1, '5': 9, '10': 'lockedBotId'},
    {'1': 'project_id', '3': 8, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'message_count', '3': 9, '4': 1, '5': 5, '10': 'messageCount'},
    {
      '1': 'updated_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {'1': 'connection_id', '3': 11, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `SessionSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionSummaryDescriptor = $convert.base64Decode(
    'Cg5TZXNzaW9uU3VtbWFyeRIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFdGl0bG'
    'UYAiABKAlSBXRpdGxlEhgKB3ByZXZpZXcYAyABKAlSB3ByZXZpZXcSGgoIcHJvdmlkZXIYBCAB'
    'KAlSCHByb3ZpZGVyEhkKCG1vZGVsX2lkGAUgASgJUgdtb2RlbElkEiEKDGRpc3BsYXlfbmFtZR'
    'gGIAEoCVILZGlzcGxheU5hbWUSIgoNbG9ja2VkX2JvdF9pZBgHIAEoCVILbG9ja2VkQm90SWQS'
    'HQoKcHJvamVjdF9pZBgIIAEoCVIJcHJvamVjdElkEiMKDW1lc3NhZ2VfY291bnQYCSABKAVSDG'
    '1lc3NhZ2VDb3VudBI5Cgp1cGRhdGVkX2F0GAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcFIJdXBkYXRlZEF0EiMKDWNvbm5lY3Rpb25faWQYCyABKAlSDGNvbm5lY3Rpb25JZA==');

@$core.Deprecated('Use fileNodeDescriptor instead')
const FileNode$json = {
  '1': 'FileNode',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'is_dir', '3': 3, '4': 1, '5': 8, '10': 'isDir'},
    {
      '1': 'children',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.scout.v1.FileNode',
      '10': 'children'
    },
  ],
};

/// Descriptor for `FileNode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileNodeDescriptor = $convert.base64Decode(
    'CghGaWxlTm9kZRISCgRuYW1lGAEgASgJUgRuYW1lEhIKBHBhdGgYAiABKAlSBHBhdGgSFQoGaX'
    'NfZGlyGAMgASgIUgVpc0RpchI7CghjaGlsZHJlbhgEIAMoCzIfLmN1bHBlb3N0dWRpby5zY291'
    'dC52MS5GaWxlTm9kZVIIY2hpbGRyZW4=');

@$core.Deprecated('Use chatOptionsDescriptor instead')
const ChatOptions$json = {
  '1': 'ChatOptions',
  '2': [
    {'1': 'thinking_level', '3': 1, '4': 1, '5': 9, '10': 'thinkingLevel'},
    {'1': 'response_style', '3': 2, '4': 1, '5': 9, '10': 'responseStyle'},
    {
      '1': 'edit_message_index',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'editMessageIndex',
      '17': true
    },
    {'1': 'mode', '3': 4, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'allowed_roots', '3': 5, '4': 3, '5': 9, '10': 'allowedRoots'},
    {'1': 'approve_plan', '3': 6, '4': 1, '5': 8, '10': 'approvePlan'},
    {'1': 'planning', '3': 7, '4': 1, '5': 8, '10': 'planning'},
    {'1': 'reasoning_effort', '3': 8, '4': 1, '5': 9, '10': 'reasoningEffort'},
    {'1': 'output_level', '3': 9, '4': 1, '5': 9, '10': 'outputLevel'},
  ],
  '8': [
    {'1': '_edit_message_index'},
  ],
};

/// Descriptor for `ChatOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatOptionsDescriptor = $convert.base64Decode(
    'CgtDaGF0T3B0aW9ucxIlCg50aGlua2luZ19sZXZlbBgBIAEoCVINdGhpbmtpbmdMZXZlbBIlCg'
    '5yZXNwb25zZV9zdHlsZRgCIAEoCVINcmVzcG9uc2VTdHlsZRIxChJlZGl0X21lc3NhZ2VfaW5k'
    'ZXgYAyABKAVIAFIQZWRpdE1lc3NhZ2VJbmRleIgBARISCgRtb2RlGAQgASgJUgRtb2RlEiMKDW'
    'FsbG93ZWRfcm9vdHMYBSADKAlSDGFsbG93ZWRSb290cxIhCgxhcHByb3ZlX3BsYW4YBiABKAhS'
    'C2FwcHJvdmVQbGFuEhoKCHBsYW5uaW5nGAcgASgIUghwbGFubmluZxIpChByZWFzb25pbmdfZW'
    'Zmb3J0GAggASgJUg9yZWFzb25pbmdFZmZvcnQSIQoMb3V0cHV0X2xldmVsGAkgASgJUgtvdXRw'
    'dXRMZXZlbEIVChNfZWRpdF9tZXNzYWdlX2luZGV4');

@$core.Deprecated('Use createSessionRequestDescriptor instead')
const CreateSessionRequest$json = {
  '1': 'CreateSessionRequest',
  '2': [
    {'1': 'model_ref', '3': 1, '4': 1, '5': 9, '10': 'modelRef'},
    {'1': 'provider', '3': 2, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model_id', '3': 3, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'instance_id', '3': 4, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'bot_id', '3': 5, '4': 1, '5': 9, '10': 'botId'},
    {'1': 'thinking_level', '3': 6, '4': 1, '5': 9, '10': 'thinkingLevel'},
    {'1': 'response_style', '3': 7, '4': 1, '5': 9, '10': 'responseStyle'},
    {'1': 'project_id', '3': 8, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'connection_id', '3': 9, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `CreateSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTZXNzaW9uUmVxdWVzdBIbCgltb2RlbF9yZWYYASABKAlSCG1vZGVsUmVmEhoKCH'
    'Byb3ZpZGVyGAIgASgJUghwcm92aWRlchIZCghtb2RlbF9pZBgDIAEoCVIHbW9kZWxJZBIfCgtp'
    'bnN0YW5jZV9pZBgEIAEoCVIKaW5zdGFuY2VJZBIVCgZib3RfaWQYBSABKAlSBWJvdElkEiUKDn'
    'RoaW5raW5nX2xldmVsGAYgASgJUg10aGlua2luZ0xldmVsEiUKDnJlc3BvbnNlX3N0eWxlGAcg'
    'ASgJUg1yZXNwb25zZVN0eWxlEh0KCnByb2plY3RfaWQYCCABKAlSCXByb2plY3RJZBIjCg1jb2'
    '5uZWN0aW9uX2lkGAkgASgJUgxjb25uZWN0aW9uSWQ=');

@$core.Deprecated('Use createSessionResponseDescriptor instead')
const CreateSessionResponse$json = {
  '1': 'CreateSessionResponse',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'model_ref', '3': 2, '4': 1, '5': 9, '10': 'modelRef'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model_id', '3': 4, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'display_name', '3': 5, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'thinking', '3': 6, '4': 1, '5': 9, '10': 'thinking'},
    {'1': 'style', '3': 7, '4': 1, '5': 9, '10': 'style'},
    {'1': 'bot_id', '3': 8, '4': 1, '5': 9, '10': 'botId'},
    {'1': 'bot_name', '3': 9, '4': 1, '5': 9, '10': 'botName'},
    {'1': 'locked_bot_id', '3': 10, '4': 1, '5': 9, '10': 'lockedBotId'},
    {'1': 'instance_id', '3': 11, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'context_limit', '3': 12, '4': 1, '5': 5, '10': 'contextLimit'},
    {'1': 'connection_id', '3': 13, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `CreateSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionResponseDescriptor = $convert.base64Decode(
    'ChVDcmVhdGVTZXNzaW9uUmVzcG9uc2USHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh'
    'sKCW1vZGVsX3JlZhgCIAEoCVIIbW9kZWxSZWYSGgoIcHJvdmlkZXIYAyABKAlSCHByb3ZpZGVy'
    'EhkKCG1vZGVsX2lkGAQgASgJUgdtb2RlbElkEiEKDGRpc3BsYXlfbmFtZRgFIAEoCVILZGlzcG'
    'xheU5hbWUSGgoIdGhpbmtpbmcYBiABKAlSCHRoaW5raW5nEhQKBXN0eWxlGAcgASgJUgVzdHls'
    'ZRIVCgZib3RfaWQYCCABKAlSBWJvdElkEhkKCGJvdF9uYW1lGAkgASgJUgdib3ROYW1lEiIKDW'
    'xvY2tlZF9ib3RfaWQYCiABKAlSC2xvY2tlZEJvdElkEh8KC2luc3RhbmNlX2lkGAsgASgJUgpp'
    'bnN0YW5jZUlkEiMKDWNvbnRleHRfbGltaXQYDCABKAVSDGNvbnRleHRMaW1pdBIjCg1jb25uZW'
    'N0aW9uX2lkGA0gASgJUgxjb25uZWN0aW9uSWQ=');

@$core.Deprecated('Use listSessionsRequestDescriptor instead')
const ListSessionsRequest$json = {
  '1': 'ListSessionsRequest',
};

/// Descriptor for `ListSessionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsRequestDescriptor =
    $convert.base64Decode('ChNMaXN0U2Vzc2lvbnNSZXF1ZXN0');

@$core.Deprecated('Use listSessionsResponseDescriptor instead')
const ListSessionsResponse$json = {
  '1': 'ListSessionsResponse',
  '2': [
    {
      '1': 'sessions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.scout.v1.SessionSummary',
      '10': 'sessions'
    },
  ],
};

/// Descriptor for `ListSessionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0U2Vzc2lvbnNSZXNwb25zZRJBCghzZXNzaW9ucxgBIAMoCzIlLmN1bHBlb3N0dWRpby'
    '5zY291dC52MS5TZXNzaW9uU3VtbWFyeVIIc2Vzc2lvbnM=');

@$core.Deprecated('Use getHistoryRequestDescriptor instead')
const GetHistoryRequest$json = {
  '1': 'GetHistoryRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetHistoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHistoryRequestDescriptor = $convert.base64Decode(
    'ChFHZXRIaXN0b3J5UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use getHistoryResponseDescriptor instead')
const GetHistoryResponse$json = {
  '1': 'GetHistoryResponse',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'provider', '3': 2, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model_id', '3': 3, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'model_ref', '3': 4, '4': 1, '5': 9, '10': 'modelRef'},
    {'1': 'display_name', '3': 5, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'context_limit', '3': 6, '4': 1, '5': 5, '10': 'contextLimit'},
    {'1': 'locked_bot_id', '3': 7, '4': 1, '5': 9, '10': 'lockedBotId'},
    {'1': 'active_bot_id', '3': 8, '4': 1, '5': 9, '10': 'activeBotId'},
    {
      '1': 'messages',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ChatMessage',
      '10': 'messages'
    },
    {'1': 'connection_id', '3': 10, '4': 1, '5': 9, '10': 'connectionId'},
    {
      '1': 'context_usage',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ContextUsage',
      '10': 'contextUsage'
    },
  ],
};

/// Descriptor for `GetHistoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHistoryResponseDescriptor = $convert.base64Decode(
    'ChJHZXRIaXN0b3J5UmVzcG9uc2USHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCH'
    'Byb3ZpZGVyGAIgASgJUghwcm92aWRlchIZCghtb2RlbF9pZBgDIAEoCVIHbW9kZWxJZBIbCglt'
    'b2RlbF9yZWYYBCABKAlSCG1vZGVsUmVmEiEKDGRpc3BsYXlfbmFtZRgFIAEoCVILZGlzcGxheU'
    '5hbWUSIwoNY29udGV4dF9saW1pdBgGIAEoBVIMY29udGV4dExpbWl0EiIKDWxvY2tlZF9ib3Rf'
    'aWQYByABKAlSC2xvY2tlZEJvdElkEiIKDWFjdGl2ZV9ib3RfaWQYCCABKAlSC2FjdGl2ZUJvdE'
    'lkEj4KCG1lc3NhZ2VzGAkgAygLMiIuY3VscGVvc3R1ZGlvLnNjb3V0LnYxLkNoYXRNZXNzYWdl'
    'UghtZXNzYWdlcxIjCg1jb25uZWN0aW9uX2lkGAogASgJUgxjb25uZWN0aW9uSWQSSAoNY29udG'
    'V4dF91c2FnZRgLIAEoCzIjLmN1bHBlb3N0dWRpby5zY291dC52MS5Db250ZXh0VXNhZ2VSDGNv'
    'bnRleHRVc2FnZQ==');

@$core.Deprecated('Use renameSessionRequestDescriptor instead')
const RenameSessionRequest$json = {
  '1': 'RenameSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `RenameSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameSessionRequestDescriptor = $convert.base64Decode(
    'ChRSZW5hbWVTZXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFA'
    'oFdGl0bGUYAiABKAlSBXRpdGxl');

@$core.Deprecated('Use renameSessionResponseDescriptor instead')
const RenameSessionResponse$json = {
  '1': 'RenameSessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.SessionSummary',
      '10': 'session'
    },
  ],
};

/// Descriptor for `RenameSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameSessionResponseDescriptor = $convert.base64Decode(
    'ChVSZW5hbWVTZXNzaW9uUmVzcG9uc2USPwoHc2Vzc2lvbhgBIAEoCzIlLmN1bHBlb3N0dWRpby'
    '5zY291dC52MS5TZXNzaW9uU3VtbWFyeVIHc2Vzc2lvbg==');

@$core.Deprecated('Use deleteSessionRequestDescriptor instead')
const DeleteSessionRequest$json = {
  '1': 'DeleteSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `DeleteSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSessionRequestDescriptor = $convert.base64Decode(
    'ChREZWxldGVTZXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use deleteSessionResponseDescriptor instead')
const DeleteSessionResponse$json = {
  '1': 'DeleteSessionResponse',
};

/// Descriptor for `DeleteSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSessionResponseDescriptor =
    $convert.base64Decode('ChVEZWxldGVTZXNzaW9uUmVzcG9uc2U=');

@$core.Deprecated('Use setSessionProjectRequestDescriptor instead')
const SetSessionProjectRequest$json = {
  '1': 'SetSessionProjectRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project_id', '3': 2, '4': 1, '5': 9, '10': 'projectId'},
  ],
};

/// Descriptor for `SetSessionProjectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSessionProjectRequestDescriptor =
    $convert.base64Decode(
        'ChhTZXRTZXNzaW9uUHJvamVjdFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbk'
        'lkEh0KCnByb2plY3RfaWQYAiABKAlSCXByb2plY3RJZA==');

@$core.Deprecated('Use setSessionProjectResponseDescriptor instead')
const SetSessionProjectResponse$json = {
  '1': 'SetSessionProjectResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.SessionSummary',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SetSessionProjectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSessionProjectResponseDescriptor =
    $convert.base64Decode(
        'ChlTZXRTZXNzaW9uUHJvamVjdFJlc3BvbnNlEj8KB3Nlc3Npb24YASABKAsyJS5jdWxwZW9zdH'
        'VkaW8uc2NvdXQudjEuU2Vzc2lvblN1bW1hcnlSB3Nlc3Npb24=');

@$core.Deprecated('Use setSessionModelRequestDescriptor instead')
const SetSessionModelRequest$json = {
  '1': 'SetSessionModelRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'provider', '3': 2, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model_id', '3': 3, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'model_ref', '3': 4, '4': 1, '5': 9, '10': 'modelRef'},
    {'1': 'display_name', '3': 5, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'context_limit', '3': 6, '4': 1, '5': 5, '10': 'contextLimit'},
    {'1': 'connection_id', '3': 7, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `SetSessionModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSessionModelRequestDescriptor = $convert.base64Decode(
    'ChZTZXRTZXNzaW9uTW9kZWxSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IaCghwcm92aWRlchgCIAEoCVIIcHJvdmlkZXISGQoIbW9kZWxfaWQYAyABKAlSB21vZGVsSWQS'
    'GwoJbW9kZWxfcmVmGAQgASgJUghtb2RlbFJlZhIhCgxkaXNwbGF5X25hbWUYBSABKAlSC2Rpc3'
    'BsYXlOYW1lEiMKDWNvbnRleHRfbGltaXQYBiABKAVSDGNvbnRleHRMaW1pdBIjCg1jb25uZWN0'
    'aW9uX2lkGAcgASgJUgxjb25uZWN0aW9uSWQ=');

@$core.Deprecated('Use setSessionModelResponseDescriptor instead')
const SetSessionModelResponse$json = {
  '1': 'SetSessionModelResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.SessionSummary',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SetSessionModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSessionModelResponseDescriptor =
    $convert.base64Decode(
        'ChdTZXRTZXNzaW9uTW9kZWxSZXNwb25zZRI/CgdzZXNzaW9uGAEgASgLMiUuY3VscGVvc3R1ZG'
        'lvLnNjb3V0LnYxLlNlc3Npb25TdW1tYXJ5UgdzZXNzaW9u');

@$core.Deprecated('Use getSessionTreeRequestDescriptor instead')
const GetSessionTreeRequest$json = {
  '1': 'GetSessionTreeRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetSessionTreeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionTreeRequestDescriptor = $convert.base64Decode(
    'ChVHZXRTZXNzaW9uVHJlZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use getSessionTreeResponseDescriptor instead')
const GetSessionTreeResponse$json = {
  '1': 'GetSessionTreeResponse',
  '2': [
    {'1': 'root', '3': 1, '4': 1, '5': 9, '10': 'root'},
    {
      '1': 'tree',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.FileNode',
      '10': 'tree'
    },
    {'1': 'truncated', '3': 3, '4': 1, '5': 8, '10': 'truncated'},
  ],
};

/// Descriptor for `GetSessionTreeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionTreeResponseDescriptor = $convert.base64Decode(
    'ChZHZXRTZXNzaW9uVHJlZVJlc3BvbnNlEhIKBHJvb3QYASABKAlSBHJvb3QSMwoEdHJlZRgCIA'
    'EoCzIfLmN1bHBlb3N0dWRpby5zY291dC52MS5GaWxlTm9kZVIEdHJlZRIcCgl0cnVuY2F0ZWQY'
    'AyABKAhSCXRydW5jYXRlZA==');

@$core.Deprecated('Use sendMessageRequestDescriptor instead')
const SendMessageRequest$json = {
  '1': 'SendMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'options',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ChatOptions',
      '10': 'options'
    },
  ],
};

/// Descriptor for `SendMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendMessageRequestDescriptor = $convert.base64Decode(
    'ChJTZW5kTWVzc2FnZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhgKB2'
    '1lc3NhZ2UYAiABKAlSB21lc3NhZ2USPAoHb3B0aW9ucxgDIAEoCzIiLmN1bHBlb3N0dWRpby5z'
    'Y291dC52MS5DaGF0T3B0aW9uc1IHb3B0aW9ucw==');

@$core.Deprecated('Use sendMessageResponseDescriptor instead')
const SendMessageResponse$json = {
  '1': 'SendMessageResponse',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'reply', '3': 2, '4': 1, '5': 9, '10': 'reply'},
    {'1': 'bot_id', '3': 3, '4': 1, '5': 9, '10': 'botId'},
    {'1': 'bot_name', '3': 4, '4': 1, '5': 9, '10': 'botName'},
    {'1': 'thinking_level', '3': 5, '4': 1, '5': 9, '10': 'thinkingLevel'},
    {'1': 'response_style', '3': 6, '4': 1, '5': 9, '10': 'responseStyle'},
    {
      '1': 'created_bot',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.Bot',
      '10': 'createdBot'
    },
  ],
};

/// Descriptor for `SendMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendMessageResponseDescriptor = $convert.base64Decode(
    'ChNTZW5kTWVzc2FnZVJlc3BvbnNlEh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCg'
    'VyZXBseRgCIAEoCVIFcmVwbHkSFQoGYm90X2lkGAMgASgJUgVib3RJZBIZCghib3RfbmFtZRgE'
    'IAEoCVIHYm90TmFtZRIlCg50aGlua2luZ19sZXZlbBgFIAEoCVINdGhpbmtpbmdMZXZlbBIlCg'
    '5yZXNwb25zZV9zdHlsZRgGIAEoCVINcmVzcG9uc2VTdHlsZRI7CgtjcmVhdGVkX2JvdBgHIAEo'
    'CzIaLmN1bHBlb3N0dWRpby5zY291dC52MS5Cb3RSCmNyZWF0ZWRCb3Q=');

@$core.Deprecated('Use streamMessageRequestDescriptor instead')
const StreamMessageRequest$json = {
  '1': 'StreamMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'options',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ChatOptions',
      '10': 'options'
    },
  ],
};

/// Descriptor for `StreamMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamMessageRequestDescriptor = $convert.base64Decode(
    'ChRTdHJlYW1NZXNzYWdlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGA'
    'oHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZRI8CgdvcHRpb25zGAMgASgLMiIuY3VscGVvc3R1ZGlv'
    'LnNjb3V0LnYxLkNoYXRPcHRpb25zUgdvcHRpb25z');

@$core.Deprecated('Use textDeltaDescriptor instead')
const TextDelta$json = {
  '1': 'TextDelta',
  '2': [
    {'1': 'chunk', '3': 1, '4': 1, '5': 9, '10': 'chunk'},
  ],
};

/// Descriptor for `TextDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textDeltaDescriptor =
    $convert.base64Decode('CglUZXh0RGVsdGESFAoFY2h1bmsYASABKAlSBWNodW5r');

@$core.Deprecated('Use reasoningDeltaDescriptor instead')
const ReasoningDelta$json = {
  '1': 'ReasoningDelta',
  '2': [
    {'1': 'chunk', '3': 1, '4': 1, '5': 9, '10': 'chunk'},
  ],
};

/// Descriptor for `ReasoningDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasoningDeltaDescriptor = $convert
    .base64Decode('Cg5SZWFzb25pbmdEZWx0YRIUCgVjaHVuaxgBIAEoCVIFY2h1bms=');

@$core.Deprecated('Use botSelectedDescriptor instead')
const BotSelected$json = {
  '1': 'BotSelected',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `BotSelected`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List botSelectedDescriptor = $convert.base64Decode(
    'CgtCb3RTZWxlY3RlZBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use botCreatedDescriptor instead')
const BotCreated$json = {
  '1': 'BotCreated',
  '2': [
    {
      '1': 'bot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.Bot',
      '10': 'bot'
    },
  ],
};

/// Descriptor for `BotCreated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List botCreatedDescriptor = $convert.base64Decode(
    'CgpCb3RDcmVhdGVkEiwKA2JvdBgBIAEoCzIaLmN1bHBlb3N0dWRpby5zY291dC52MS5Cb3RSA2'
    'JvdA==');

@$core.Deprecated('Use statusUpdateDescriptor instead')
const StatusUpdate$json = {
  '1': 'StatusUpdate',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
  ],
};

/// Descriptor for `StatusUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusUpdateDescriptor = $convert
    .base64Decode('CgxTdGF0dXNVcGRhdGUSFgoGYWN0aW9uGAEgASgJUgZhY3Rpb24=');

@$core.Deprecated('Use modelWarmupDescriptor instead')
const ModelWarmup$json = {
  '1': 'ModelWarmup',
  '2': [
    {'1': 'operation_id', '3': 1, '4': 1, '5': 9, '10': 'operationId'},
    {'1': 'instance_id', '3': 2, '4': 1, '5': 9, '10': 'instanceId'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
    {'1': 'phase', '3': 4, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'progress', '3': 5, '4': 1, '5': 1, '10': 'progress'},
    {'1': 'queue_position', '3': 6, '4': 1, '5': 5, '10': 'queuePosition'},
    {'1': 'placement', '3': 7, '4': 1, '5': 9, '10': 'placement'},
    {'1': 'message', '3': 8, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ModelWarmup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelWarmupDescriptor = $convert.base64Decode(
    'CgtNb2RlbFdhcm11cBIhCgxvcGVyYXRpb25faWQYASABKAlSC29wZXJhdGlvbklkEh8KC2luc3'
    'RhbmNlX2lkGAIgASgJUgppbnN0YW5jZUlkEhYKBnN0YXR1cxgDIAEoCVIGc3RhdHVzEhQKBXBo'
    'YXNlGAQgASgJUgVwaGFzZRIaCghwcm9ncmVzcxgFIAEoAVIIcHJvZ3Jlc3MSJQoOcXVldWVfcG'
    '9zaXRpb24YBiABKAVSDXF1ZXVlUG9zaXRpb24SHAoJcGxhY2VtZW50GAcgASgJUglwbGFjZW1l'
    'bnQSGAoHbWVzc2FnZRgIIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use streamDoneDescriptor instead')
const StreamDone$json = {
  '1': 'StreamDone',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'thinking_level', '3': 2, '4': 1, '5': 9, '10': 'thinkingLevel'},
    {'1': 'response_style', '3': 3, '4': 1, '5': 9, '10': 'responseStyle'},
  ],
};

/// Descriptor for `StreamDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamDoneDescriptor = $convert.base64Decode(
    'CgpTdHJlYW1Eb25lEh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIlCg50aGlua2luZ1'
    '9sZXZlbBgCIAEoCVINdGhpbmtpbmdMZXZlbBIlCg5yZXNwb25zZV9zdHlsZRgDIAEoCVINcmVz'
    'cG9uc2VTdHlsZQ==');

@$core.Deprecated('Use contextUsageDescriptor instead')
const ContextUsage$json = {
  '1': 'ContextUsage',
  '2': [
    {'1': 'limit_tokens', '3': 1, '4': 1, '5': 5, '10': 'limitTokens'},
    {'1': 'used_tokens', '3': 2, '4': 1, '5': 5, '10': 'usedTokens'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {'1': 'compactions', '3': 4, '4': 1, '5': 5, '10': 'compactions'},
    {'1': 'compacted', '3': 5, '4': 1, '5': 8, '10': 'compacted'},
    {
      '1': 'model_limit_tokens',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'modelLimitTokens'
    },
  ],
};

/// Descriptor for `ContextUsage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextUsageDescriptor = $convert.base64Decode(
    'CgxDb250ZXh0VXNhZ2USIQoMbGltaXRfdG9rZW5zGAEgASgFUgtsaW1pdFRva2VucxIfCgt1c2'
    'VkX3Rva2VucxgCIAEoBVIKdXNlZFRva2VucxIWCgZzb3VyY2UYAyABKAlSBnNvdXJjZRIgCgtj'
    'b21wYWN0aW9ucxgEIAEoBVILY29tcGFjdGlvbnMSHAoJY29tcGFjdGVkGAUgASgIUgljb21wYW'
    'N0ZWQSLAoSbW9kZWxfbGltaXRfdG9rZW5zGAYgASgFUhBtb2RlbExpbWl0VG9rZW5z');

@$core.Deprecated('Use streamErrorDescriptor instead')
const StreamError$json = {
  '1': 'StreamError',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
    {'1': 'retry_after', '3': 3, '4': 1, '5': 5, '10': 'retryAfter'},
  ],
};

/// Descriptor for `StreamError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamErrorDescriptor = $convert.base64Decode(
    'CgtTdHJlYW1FcnJvchIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdlEhIKBGNvZGUYAiABKAlSBG'
    'NvZGUSHwoLcmV0cnlfYWZ0ZXIYAyABKAVSCnJldHJ5QWZ0ZXI=');

@$core.Deprecated('Use agentEventDescriptor instead')
const AgentEvent$json = {
  '1': 'AgentEvent',
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

/// Descriptor for `AgentEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentEventDescriptor = $convert.base64Decode(
    'CgpBZ2VudEV2ZW50EhIKBHR5cGUYASABKAlSBHR5cGUSKwoEZGF0YRgCIAEoCzIXLmdvb2dsZS'
    '5wcm90b2J1Zi5TdHJ1Y3RSBGRhdGE=');

@$core.Deprecated('Use streamMessageResponseDescriptor instead')
const StreamMessageResponse$json = {
  '1': 'StreamMessageResponse',
  '2': [
    {
      '1': 'text_delta',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.TextDelta',
      '9': 0,
      '10': 'textDelta'
    },
    {
      '1': 'reasoning_delta',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ReasoningDelta',
      '9': 0,
      '10': 'reasoningDelta'
    },
    {
      '1': 'bot_selected',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.BotSelected',
      '9': 0,
      '10': 'botSelected'
    },
    {
      '1': 'bot_created',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.BotCreated',
      '9': 0,
      '10': 'botCreated'
    },
    {
      '1': 'status',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.StatusUpdate',
      '9': 0,
      '10': 'status'
    },
    {
      '1': 'model_warmup',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ModelWarmup',
      '9': 0,
      '10': 'modelWarmup'
    },
    {
      '1': 'done',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.StreamDone',
      '9': 0,
      '10': 'done'
    },
    {
      '1': 'error',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.StreamError',
      '9': 0,
      '10': 'error'
    },
    {
      '1': 'agent',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.AgentEvent',
      '9': 0,
      '10': 'agent'
    },
    {
      '1': 'context_usage',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ContextUsage',
      '9': 0,
      '10': 'contextUsage'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `StreamMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamMessageResponseDescriptor = $convert.base64Decode(
    'ChVTdHJlYW1NZXNzYWdlUmVzcG9uc2USQQoKdGV4dF9kZWx0YRgBIAEoCzIgLmN1bHBlb3N0dW'
    'Rpby5zY291dC52MS5UZXh0RGVsdGFIAFIJdGV4dERlbHRhElAKD3JlYXNvbmluZ19kZWx0YRgC'
    'IAEoCzIlLmN1bHBlb3N0dWRpby5zY291dC52MS5SZWFzb25pbmdEZWx0YUgAUg5yZWFzb25pbm'
    'dEZWx0YRJHCgxib3Rfc2VsZWN0ZWQYAyABKAsyIi5jdWxwZW9zdHVkaW8uc2NvdXQudjEuQm90'
    'U2VsZWN0ZWRIAFILYm90U2VsZWN0ZWQSRAoLYm90X2NyZWF0ZWQYBCABKAsyIS5jdWxwZW9zdH'
    'VkaW8uc2NvdXQudjEuQm90Q3JlYXRlZEgAUgpib3RDcmVhdGVkEj0KBnN0YXR1cxgFIAEoCzIj'
    'LmN1bHBlb3N0dWRpby5zY291dC52MS5TdGF0dXNVcGRhdGVIAFIGc3RhdHVzEkcKDG1vZGVsX3'
    'dhcm11cBgGIAEoCzIiLmN1bHBlb3N0dWRpby5zY291dC52MS5Nb2RlbFdhcm11cEgAUgttb2Rl'
    'bFdhcm11cBI3CgRkb25lGAcgASgLMiEuY3VscGVvc3R1ZGlvLnNjb3V0LnYxLlN0cmVhbURvbm'
    'VIAFIEZG9uZRI6CgVlcnJvchgIIAEoCzIiLmN1bHBlb3N0dWRpby5zY291dC52MS5TdHJlYW1F'
    'cnJvckgAUgVlcnJvchI5CgVhZ2VudBgJIAEoCzIhLmN1bHBlb3N0dWRpby5zY291dC52MS5BZ2'
    'VudEV2ZW50SABSBWFnZW50EkoKDWNvbnRleHRfdXNhZ2UYCiABKAsyIy5jdWxwZW9zdHVkaW8u'
    'c2NvdXQudjEuQ29udGV4dFVzYWdlSABSDGNvbnRleHRVc2FnZUIHCgVldmVudA==');

@$core.Deprecated('Use listBotsRequestDescriptor instead')
const ListBotsRequest$json = {
  '1': 'ListBotsRequest',
};

/// Descriptor for `ListBotsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBotsRequestDescriptor =
    $convert.base64Decode('Cg9MaXN0Qm90c1JlcXVlc3Q=');

@$core.Deprecated('Use listBotsResponseDescriptor instead')
const ListBotsResponse$json = {
  '1': 'ListBotsResponse',
  '2': [
    {
      '1': 'bots',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.scout.v1.Bot',
      '10': 'bots'
    },
  ],
};

/// Descriptor for `ListBotsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBotsResponseDescriptor = $convert.base64Decode(
    'ChBMaXN0Qm90c1Jlc3BvbnNlEi4KBGJvdHMYASADKAsyGi5jdWxwZW9zdHVkaW8uc2NvdXQudj'
    'EuQm90UgRib3Rz');

@$core.Deprecated('Use saveBotRequestDescriptor instead')
const SaveBotRequest$json = {
  '1': 'SaveBotRequest',
  '2': [
    {
      '1': 'bot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.Bot',
      '10': 'bot'
    },
  ],
};

/// Descriptor for `SaveBotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveBotRequestDescriptor = $convert.base64Decode(
    'Cg5TYXZlQm90UmVxdWVzdBIsCgNib3QYASABKAsyGi5jdWxwZW9zdHVkaW8uc2NvdXQudjEuQm'
    '90UgNib3Q=');

@$core.Deprecated('Use saveBotResponseDescriptor instead')
const SaveBotResponse$json = {
  '1': 'SaveBotResponse',
  '2': [
    {
      '1': 'bot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.scout.v1.Bot',
      '10': 'bot'
    },
  ],
};

/// Descriptor for `SaveBotResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveBotResponseDescriptor = $convert.base64Decode(
    'Cg9TYXZlQm90UmVzcG9uc2USLAoDYm90GAEgASgLMhouY3VscGVvc3R1ZGlvLnNjb3V0LnYxLk'
    'JvdFIDYm90');

@$core.Deprecated('Use deleteBotRequestDescriptor instead')
const DeleteBotRequest$json = {
  '1': 'DeleteBotRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteBotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteBotRequestDescriptor =
    $convert.base64Decode('ChBEZWxldGVCb3RSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use deleteBotResponseDescriptor instead')
const DeleteBotResponse$json = {
  '1': 'DeleteBotResponse',
};

/// Descriptor for `DeleteBotResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteBotResponseDescriptor =
    $convert.base64Decode('ChFEZWxldGVCb3RSZXNwb25zZQ==');

@$core.Deprecated('Use reasoningProfileDescriptor instead')
const ReasoningProfile$json = {
  '1': 'ReasoningProfile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'mandatory', '3': 3, '4': 1, '5': 8, '10': 'mandatory'},
    {'1': 'default_enabled', '3': 4, '4': 1, '5': 8, '10': 'defaultEnabled'},
    {
      '1': 'supported_efforts',
      '3': 5,
      '4': 3,
      '5': 9,
      '10': 'supportedEfforts'
    },
    {'1': 'default_effort', '3': 6, '4': 1, '5': 9, '10': 'defaultEffort'},
    {'1': 'context_length', '3': 7, '4': 1, '5': 5, '10': 'contextLength'},
  ],
};

/// Descriptor for `ReasoningProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasoningProfileDescriptor = $convert.base64Decode(
    'ChBSZWFzb25pbmdQcm9maWxlEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEh'
    'wKCW1hbmRhdG9yeRgDIAEoCFIJbWFuZGF0b3J5EicKD2RlZmF1bHRfZW5hYmxlZBgEIAEoCFIO'
    'ZGVmYXVsdEVuYWJsZWQSKwoRc3VwcG9ydGVkX2VmZm9ydHMYBSADKAlSEHN1cHBvcnRlZEVmZm'
    '9ydHMSJQoOZGVmYXVsdF9lZmZvcnQYBiABKAlSDWRlZmF1bHRFZmZvcnQSJQoOY29udGV4dF9s'
    'ZW5ndGgYByABKAVSDWNvbnRleHRMZW5ndGg=');

@$core.Deprecated('Use listReasoningProfilesRequestDescriptor instead')
const ListReasoningProfilesRequest$json = {
  '1': 'ListReasoningProfilesRequest',
};

/// Descriptor for `ListReasoningProfilesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listReasoningProfilesRequestDescriptor =
    $convert.base64Decode('ChxMaXN0UmVhc29uaW5nUHJvZmlsZXNSZXF1ZXN0');

@$core.Deprecated('Use listReasoningProfilesResponseDescriptor instead')
const ListReasoningProfilesResponse$json = {
  '1': 'ListReasoningProfilesResponse',
  '2': [
    {
      '1': 'profiles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.scout.v1.ReasoningProfile',
      '10': 'profiles'
    },
  ],
};

/// Descriptor for `ListReasoningProfilesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listReasoningProfilesResponseDescriptor =
    $convert.base64Decode(
        'Ch1MaXN0UmVhc29uaW5nUHJvZmlsZXNSZXNwb25zZRJDCghwcm9maWxlcxgBIAMoCzInLmN1bH'
        'Blb3N0dWRpby5zY291dC52MS5SZWFzb25pbmdQcm9maWxlUghwcm9maWxlcw==');
