// This is a generated file - do not edit.
//
// Generated from culpeostudio/memory/v1/memory.proto.

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

@$core.Deprecated('Use sessionStatusDescriptor instead')
const SessionStatus$json = {
  '1': 'SessionStatus',
  '2': [
    {'1': 'SESSION_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'SESSION_STATUS_ACTIVE', '2': 1},
    {'1': 'SESSION_STATUS_COMPLETED', '2': 2},
  ],
};

/// Descriptor for `SessionStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sessionStatusDescriptor = $convert.base64Decode(
    'Cg1TZXNzaW9uU3RhdHVzEh4KGlNFU1NJT05fU1RBVFVTX1VOU1BFQ0lGSUVEEAASGQoVU0VTU0'
    'lPTl9TVEFUVVNfQUNUSVZFEAESHAoYU0VTU0lPTl9TVEFUVVNfQ09NUExFVEVEEAI=');

@$core.Deprecated('Use promptRoleDescriptor instead')
const PromptRole$json = {
  '1': 'PromptRole',
  '2': [
    {'1': 'PROMPT_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'PROMPT_ROLE_USER', '2': 1},
    {'1': 'PROMPT_ROLE_ASSISTANT', '2': 2},
    {'1': 'PROMPT_ROLE_SYSTEM', '2': 3},
  ],
};

/// Descriptor for `PromptRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List promptRoleDescriptor = $convert.base64Decode(
    'CgpQcm9tcHRSb2xlEhsKF1BST01QVF9ST0xFX1VOU1BFQ0lGSUVEEAASFAoQUFJPTVBUX1JPTE'
    'VfVVNFUhABEhkKFVBST01QVF9ST0xFX0FTU0lTVEFOVBACEhYKElBST01QVF9ST0xFX1NZU1RF'
    'TRAD');

@$core.Deprecated('Use memoryLayerDescriptor instead')
const MemoryLayer$json = {
  '1': 'MemoryLayer',
  '2': [
    {'1': 'MEMORY_LAYER_UNSPECIFIED', '2': 0},
    {'1': 'MEMORY_LAYER_USER_DATA', '2': 1},
    {'1': 'MEMORY_LAYER_PROJECT_DATA', '2': 2},
  ],
};

/// Descriptor for `MemoryLayer`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List memoryLayerDescriptor = $convert.base64Decode(
    'CgtNZW1vcnlMYXllchIcChhNRU1PUllfTEFZRVJfVU5TUEVDSUZJRUQQABIaChZNRU1PUllfTE'
    'FZRVJfVVNFUl9EQVRBEAESHQoZTUVNT1JZX0xBWUVSX1BST0pFQ1RfREFUQRAC');

@$core.Deprecated('Use memoryCategoryDescriptor instead')
const MemoryCategory$json = {
  '1': 'MemoryCategory',
  '2': [
    {'1': 'MEMORY_CATEGORY_UNSPECIFIED', '2': 0},
    {'1': 'MEMORY_CATEGORY_STATUS', '2': 1},
    {'1': 'MEMORY_CATEGORY_BRAINSTORMING', '2': 2},
    {'1': 'MEMORY_CATEGORY_CHANGE_REQUEST', '2': 3},
  ],
};

/// Descriptor for `MemoryCategory`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List memoryCategoryDescriptor = $convert.base64Decode(
    'Cg5NZW1vcnlDYXRlZ29yeRIfChtNRU1PUllfQ0FURUdPUllfVU5TUEVDSUZJRUQQABIaChZNRU'
    '1PUllfQ0FURUdPUllfU1RBVFVTEAESIQodTUVNT1JZX0NBVEVHT1JZX0JSQUlOU1RPUk1JTkcQ'
    'AhIiCh5NRU1PUllfQ0FURUdPUllfQ0hBTkdFX1JFUVVFU1QQAw==');

@$core.Deprecated('Use changeRequestStatusDescriptor instead')
const ChangeRequestStatus$json = {
  '1': 'ChangeRequestStatus',
  '2': [
    {'1': 'CHANGE_REQUEST_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'CHANGE_REQUEST_STATUS_OPEN', '2': 1},
    {'1': 'CHANGE_REQUEST_STATUS_ACCEPTED', '2': 2},
    {'1': 'CHANGE_REQUEST_STATUS_REJECTED', '2': 3},
  ],
};

/// Descriptor for `ChangeRequestStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List changeRequestStatusDescriptor = $convert.base64Decode(
    'ChNDaGFuZ2VSZXF1ZXN0U3RhdHVzEiUKIUNIQU5HRV9SRVFVRVNUX1NUQVRVU19VTlNQRUNJRk'
    'lFRBAAEh4KGkNIQU5HRV9SRVFVRVNUX1NUQVRVU19PUEVOEAESIgoeQ0hBTkdFX1JFUVVFU1Rf'
    'U1RBVFVTX0FDQ0VQVEVEEAISIgoeQ0hBTkdFX1JFUVVFU1RfU1RBVFVTX1JFSkVDVEVEEAM=');

@$core.Deprecated('Use promptDescriptor instead')
const Prompt$json = {
  '1': 'Prompt',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'role',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.PromptRole',
      '10': 'role'
    },
    {'1': 'text', '3': 4, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'created_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `Prompt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptDescriptor = $convert.base64Decode(
    'CgZQcm9tcHQSDgoCaWQYASABKAlSAmlkEh0KCnNlc3Npb25faWQYAiABKAlSCXNlc3Npb25JZB'
    'I2CgRyb2xlGAMgASgOMiIuY3VscGVvc3R1ZGlvLm1lbW9yeS52MS5Qcm9tcHRSb2xlUgRyb2xl'
    'EhIKBHRleHQYBCABKAlSBHRleHQSOQoKY3JlYXRlZF9hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2'
    'J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdA==');

@$core.Deprecated('Use changeRequestStateDescriptor instead')
const ChangeRequestState$json = {
  '1': 'ChangeRequestState',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.ChangeRequestStatus',
      '10': 'status'
    },
    {'1': 'proposal', '3': 2, '4': 1, '5': 9, '10': 'proposal'},
    {'1': 'reason_short', '3': 3, '4': 1, '5': 9, '10': 'reasonShort'},
    {'1': 'decided_at', '3': 4, '4': 1, '5': 9, '10': 'decidedAt'},
  ],
};

/// Descriptor for `ChangeRequestState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeRequestStateDescriptor = $convert.base64Decode(
    'ChJDaGFuZ2VSZXF1ZXN0U3RhdGUSQwoGc3RhdHVzGAEgASgOMisuY3VscGVvc3R1ZGlvLm1lbW'
    '9yeS52MS5DaGFuZ2VSZXF1ZXN0U3RhdHVzUgZzdGF0dXMSGgoIcHJvcG9zYWwYAiABKAlSCHBy'
    'b3Bvc2FsEiEKDHJlYXNvbl9zaG9ydBgDIAEoCVILcmVhc29uU2hvcnQSHQoKZGVjaWRlZF9hdB'
    'gEIAEoCVIJZGVjaWRlZEF0');

@$core.Deprecated('Use observationDescriptor instead')
const Observation$json = {
  '1': 'Observation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project', '3': 3, '4': 1, '5': 9, '10': 'project'},
    {'1': 'source', '3': 4, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'layer',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryLayer',
      '10': 'layer'
    },
    {
      '1': 'category',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryCategory',
      '10': 'category'
    },
    {'1': 'type', '3': 7, '4': 1, '5': 9, '10': 'type'},
    {'1': 'title', '3': 8, '4': 1, '5': 9, '10': 'title'},
    {'1': 'narrative', '3': 9, '4': 1, '5': 9, '10': 'narrative'},
    {
      '1': 'change_request',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.ChangeRequestState',
      '10': 'changeRequest'
    },
    {'1': 'speaker', '3': 11, '4': 1, '5': 9, '10': 'speaker'},
    {'1': 'dialogue_id', '3': 12, '4': 1, '5': 5, '10': 'dialogueId'},
    {'1': 'keywords', '3': 13, '4': 3, '5': 9, '10': 'keywords'},
    {'1': 'persons', '3': 14, '4': 3, '5': 9, '10': 'persons'},
    {'1': 'entities', '3': 15, '4': 3, '5': 9, '10': 'entities'},
    {'1': 'topic', '3': 16, '4': 1, '5': 9, '10': 'topic'},
    {'1': 'location', '3': 17, '4': 1, '5': 9, '10': 'location'},
    {'1': 'valid_from', '3': 18, '4': 1, '5': 9, '10': 'validFrom'},
    {'1': 'importance', '3': 19, '4': 1, '5': 1, '10': 'importance'},
    {'1': 'confidence', '3': 20, '4': 1, '5': 1, '10': 'confidence'},
    {'1': 'superseded_by', '3': 21, '4': 1, '5': 9, '10': 'supersededBy'},
    {'1': 'tool_name', '3': 22, '4': 1, '5': 9, '10': 'toolName'},
    {'1': 'source_path', '3': 23, '4': 1, '5': 9, '10': 'sourcePath'},
    {'1': 'tags', '3': 24, '4': 3, '5': 9, '10': 'tags'},
    {'1': 'content_hash', '3': 25, '4': 1, '5': 9, '10': 'contentHash'},
    {'1': 'archived', '3': 26, '4': 1, '5': 8, '10': 'archived'},
    {'1': 'memory_id', '3': 27, '4': 1, '5': 9, '10': 'memoryId'},
    {'1': 'deleted_at', '3': 28, '4': 1, '5': 9, '10': 'deletedAt'},
    {
      '1': 'created_at',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `Observation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List observationDescriptor = $convert.base64Decode(
    'CgtPYnNlcnZhdGlvbhIOCgJpZBgBIAEoCVICaWQSHQoKc2Vzc2lvbl9pZBgCIAEoCVIJc2Vzc2'
    'lvbklkEhgKB3Byb2plY3QYAyABKAlSB3Byb2plY3QSFgoGc291cmNlGAQgASgJUgZzb3VyY2US'
    'OQoFbGF5ZXIYBSABKA4yIy5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk1lbW9yeUxheWVyUgVsYX'
    'llchJCCghjYXRlZ29yeRgGIAEoDjImLmN1bHBlb3N0dWRpby5tZW1vcnkudjEuTWVtb3J5Q2F0'
    'ZWdvcnlSCGNhdGVnb3J5EhIKBHR5cGUYByABKAlSBHR5cGUSFAoFdGl0bGUYCCABKAlSBXRpdG'
    'xlEhwKCW5hcnJhdGl2ZRgJIAEoCVIJbmFycmF0aXZlElEKDmNoYW5nZV9yZXF1ZXN0GAogASgL'
    'MiouY3VscGVvc3R1ZGlvLm1lbW9yeS52MS5DaGFuZ2VSZXF1ZXN0U3RhdGVSDWNoYW5nZVJlcX'
    'Vlc3QSGAoHc3BlYWtlchgLIAEoCVIHc3BlYWtlchIfCgtkaWFsb2d1ZV9pZBgMIAEoBVIKZGlh'
    'bG9ndWVJZBIaCghrZXl3b3JkcxgNIAMoCVIIa2V5d29yZHMSGAoHcGVyc29ucxgOIAMoCVIHcG'
    'Vyc29ucxIaCghlbnRpdGllcxgPIAMoCVIIZW50aXRpZXMSFAoFdG9waWMYECABKAlSBXRvcGlj'
    'EhoKCGxvY2F0aW9uGBEgASgJUghsb2NhdGlvbhIdCgp2YWxpZF9mcm9tGBIgASgJUgl2YWxpZE'
    'Zyb20SHgoKaW1wb3J0YW5jZRgTIAEoAVIKaW1wb3J0YW5jZRIeCgpjb25maWRlbmNlGBQgASgB'
    'Ugpjb25maWRlbmNlEiMKDXN1cGVyc2VkZWRfYnkYFSABKAlSDHN1cGVyc2VkZWRCeRIbCgl0b2'
    '9sX25hbWUYFiABKAlSCHRvb2xOYW1lEh8KC3NvdXJjZV9wYXRoGBcgASgJUgpzb3VyY2VQYXRo'
    'EhIKBHRhZ3MYGCADKAlSBHRhZ3MSIQoMY29udGVudF9oYXNoGBkgASgJUgtjb250ZW50SGFzaB'
    'IaCghhcmNoaXZlZBgaIAEoCFIIYXJjaGl2ZWQSGwoJbWVtb3J5X2lkGBsgASgJUghtZW1vcnlJ'
    'ZBIdCgpkZWxldGVkX2F0GBwgASgJUglkZWxldGVkQXQSOQoKY3JlYXRlZF9hdBgdIAEoCzIaLm'
    'dvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdA==');

@$core.Deprecated('Use compressedMemoryDescriptor instead')
const CompressedMemory$json = {
  '1': 'CompressedMemory',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'layer',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryLayer',
      '10': 'layer'
    },
    {
      '1': 'category',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryCategory',
      '10': 'category'
    },
    {'1': 'summary', '3': 5, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'learned', '3': 6, '4': 3, '5': 9, '10': 'learned'},
    {'1': 'open_tasks', '3': 7, '4': 3, '5': 9, '10': 'openTasks'},
    {'1': 'observation_ids', '3': 8, '4': 3, '5': 9, '10': 'observationIds'},
    {'1': 'corrected_by_user', '3': 9, '4': 1, '5': 8, '10': 'correctedByUser'},
    {
      '1': 'created_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `CompressedMemory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compressedMemoryDescriptor = $convert.base64Decode(
    'ChBDb21wcmVzc2VkTWVtb3J5Eg4KAmlkGAEgASgJUgJpZBIdCgpzZXNzaW9uX2lkGAIgASgJUg'
    'lzZXNzaW9uSWQSOQoFbGF5ZXIYAyABKA4yIy5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk1lbW9y'
    'eUxheWVyUgVsYXllchJCCghjYXRlZ29yeRgEIAEoDjImLmN1bHBlb3N0dWRpby5tZW1vcnkudj'
    'EuTWVtb3J5Q2F0ZWdvcnlSCGNhdGVnb3J5EhgKB3N1bW1hcnkYBSABKAlSB3N1bW1hcnkSGAoH'
    'bGVhcm5lZBgGIAMoCVIHbGVhcm5lZBIdCgpvcGVuX3Rhc2tzGAcgAygJUglvcGVuVGFza3MSJw'
    'oPb2JzZXJ2YXRpb25faWRzGAggAygJUg5vYnNlcnZhdGlvbklkcxIqChFjb3JyZWN0ZWRfYnlf'
    'dXNlchgJIAEoCFIPY29ycmVjdGVkQnlVc2VyEjkKCmNyZWF0ZWRfYXQYCiABKAsyGi5nb29nbG'
    'UucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use sessionSummaryDescriptor instead')
const SessionSummary$json = {
  '1': 'SessionSummary',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'learned', '3': 3, '4': 3, '5': 9, '10': 'learned'},
    {'1': 'completed', '3': 4, '4': 3, '5': 9, '10': 'completed'},
    {'1': 'next_steps', '3': 5, '4': 3, '5': 9, '10': 'nextSteps'},
    {
      '1': 'created_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `SessionSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionSummaryDescriptor = $convert.base64Decode(
    'Cg5TZXNzaW9uU3VtbWFyeRIOCgJpZBgBIAEoCVICaWQSHQoKc2Vzc2lvbl9pZBgCIAEoCVIJc2'
    'Vzc2lvbklkEhgKB2xlYXJuZWQYAyADKAlSB2xlYXJuZWQSHAoJY29tcGxldGVkGAQgAygJUglj'
    'b21wbGV0ZWQSHQoKbmV4dF9zdGVwcxgFIAMoCVIJbmV4dFN0ZXBzEjkKCmNyZWF0ZWRfYXQYBi'
    'ABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use sessionDescriptor instead')
const Session$json = {
  '1': 'Session',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'status',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.SessionStatus',
      '10': 'status'
    },
    {'1': 'goals', '3': 5, '4': 3, '5': 9, '10': 'goals'},
    {
      '1': 'prompts',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Prompt',
      '10': 'prompts'
    },
    {
      '1': 'active_observations',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'activeObservations'
    },
    {
      '1': 'archived_observations',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'archivedObservations'
    },
    {
      '1': 'memories',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.CompressedMemory',
      '10': 'memories'
    },
    {
      '1': 'summaries',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.SessionSummary',
      '10': 'summaries'
    },
    {
      '1': 'context_usage_estimate',
      '3': 11,
      '4': 1,
      '5': 1,
      '10': 'contextUsageEstimate'
    },
    {'1': 'prompt_count', '3': 12, '4': 1, '5': 5, '10': 'promptCount'},
    {
      '1': 'observation_count',
      '3': 13,
      '4': 1,
      '5': 5,
      '10': 'observationCount'
    },
    {
      '1': 'compressed_memory_count',
      '3': 14,
      '4': 1,
      '5': 5,
      '10': 'compressedMemoryCount'
    },
    {'1': 'summary_count', '3': 15, '4': 1, '5': 5, '10': 'summaryCount'},
    {
      '1': 'created_at',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
};

/// Descriptor for `Session`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptor = $convert.base64Decode(
    'CgdTZXNzaW9uEg4KAmlkGAEgASgJUgJpZBIYCgdwcm9qZWN0GAIgASgJUgdwcm9qZWN0EhYKBn'
    'NvdXJjZRgDIAEoCVIGc291cmNlEj0KBnN0YXR1cxgEIAEoDjIlLmN1bHBlb3N0dWRpby5tZW1v'
    'cnkudjEuU2Vzc2lvblN0YXR1c1IGc3RhdHVzEhQKBWdvYWxzGAUgAygJUgVnb2FscxI4Cgdwcm'
    '9tcHRzGAYgAygLMh4uY3VscGVvc3R1ZGlvLm1lbW9yeS52MS5Qcm9tcHRSB3Byb21wdHMSVAoT'
    'YWN0aXZlX29ic2VydmF0aW9ucxgHIAMoCzIjLmN1bHBlb3N0dWRpby5tZW1vcnkudjEuT2JzZX'
    'J2YXRpb25SEmFjdGl2ZU9ic2VydmF0aW9ucxJYChVhcmNoaXZlZF9vYnNlcnZhdGlvbnMYCCAD'
    'KAsyIy5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk9ic2VydmF0aW9uUhRhcmNoaXZlZE9ic2Vydm'
    'F0aW9ucxJECghtZW1vcmllcxgJIAMoCzIoLmN1bHBlb3N0dWRpby5tZW1vcnkudjEuQ29tcHJl'
    'c3NlZE1lbW9yeVIIbWVtb3JpZXMSRAoJc3VtbWFyaWVzGAogAygLMiYuY3VscGVvc3R1ZGlvLm'
    '1lbW9yeS52MS5TZXNzaW9uU3VtbWFyeVIJc3VtbWFyaWVzEjQKFmNvbnRleHRfdXNhZ2VfZXN0'
    'aW1hdGUYCyABKAFSFGNvbnRleHRVc2FnZUVzdGltYXRlEiEKDHByb21wdF9jb3VudBgMIAEoBV'
    'ILcHJvbXB0Q291bnQSKwoRb2JzZXJ2YXRpb25fY291bnQYDSABKAVSEG9ic2VydmF0aW9uQ291'
    'bnQSNgoXY29tcHJlc3NlZF9tZW1vcnlfY291bnQYDiABKAVSFWNvbXByZXNzZWRNZW1vcnlDb3'
    'VudBIjCg1zdW1tYXJ5X2NvdW50GA8gASgFUgxzdW1tYXJ5Q291bnQSOQoKY3JlYXRlZF9hdBgQ'
    'IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI5Cgp1cGRhdGVkX2'
    'F0GBEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJdXBkYXRlZEF0');

@$core.Deprecated('Use searchResultDescriptor instead')
const SearchResult$json = {
  '1': 'SearchResult',
  '2': [
    {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'ref_id', '3': 3, '4': 1, '5': 9, '10': 'refId'},
    {'1': 'kind', '3': 4, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'project', '3': 5, '4': 1, '5': 9, '10': 'project'},
    {'1': 'source', '3': 6, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'layer',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryLayer',
      '10': 'layer'
    },
    {
      '1': 'category',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryCategory',
      '10': 'category'
    },
    {'1': 'type', '3': 9, '4': 1, '5': 9, '10': 'type'},
    {'1': 'title', '3': 10, '4': 1, '5': 9, '10': 'title'},
    {'1': 'snippet', '3': 11, '4': 1, '5': 9, '10': 'snippet'},
    {'1': 'score', '3': 12, '4': 1, '5': 1, '10': 'score'},
    {'1': 'text_score', '3': 13, '4': 1, '5': 1, '10': 'textScore'},
    {'1': 'vector_score', '3': 14, '4': 1, '5': 1, '10': 'vectorScore'},
    {
      '1': 'created_at',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `SearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResultDescriptor = $convert.base64Decode(
    'CgxTZWFyY2hSZXN1bHQSFQoGZG9jX2lkGAEgASgJUgVkb2NJZBIdCgpzZXNzaW9uX2lkGAIgAS'
    'gJUglzZXNzaW9uSWQSFQoGcmVmX2lkGAMgASgJUgVyZWZJZBISCgRraW5kGAQgASgJUgRraW5k'
    'EhgKB3Byb2plY3QYBSABKAlSB3Byb2plY3QSFgoGc291cmNlGAYgASgJUgZzb3VyY2USOQoFbG'
    'F5ZXIYByABKA4yIy5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk1lbW9yeUxheWVyUgVsYXllchJC'
    'CghjYXRlZ29yeRgIIAEoDjImLmN1bHBlb3N0dWRpby5tZW1vcnkudjEuTWVtb3J5Q2F0ZWdvcn'
    'lSCGNhdGVnb3J5EhIKBHR5cGUYCSABKAlSBHR5cGUSFAoFdGl0bGUYCiABKAlSBXRpdGxlEhgK'
    'B3NuaXBwZXQYCyABKAlSB3NuaXBwZXQSFAoFc2NvcmUYDCABKAFSBXNjb3JlEh0KCnRleHRfc2'
    'NvcmUYDSABKAFSCXRleHRTY29yZRIhCgx2ZWN0b3Jfc2NvcmUYDiABKAFSC3ZlY3RvclNjb3Jl'
    'EjkKCmNyZWF0ZWRfYXQYDyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdG'
    'VkQXQ=');

@$core.Deprecated('Use toolDefinitionDescriptor instead')
const ToolDefinition$json = {
  '1': 'ToolDefinition',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'json_shape', '3': 3, '4': 1, '5': 9, '10': 'jsonShape'},
  ],
};

/// Descriptor for `ToolDefinition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toolDefinitionDescriptor = $convert.base64Decode(
    'Cg5Ub29sRGVmaW5pdGlvbhISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgAS'
    'gJUgtkZXNjcmlwdGlvbhIdCgpqc29uX3NoYXBlGAMgASgJUglqc29uU2hhcGU=');

@$core.Deprecated('Use contextEnvelopeDescriptor instead')
const ContextEnvelope$json = {
  '1': 'ContextEnvelope',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    {'1': 'budget_tokens', '3': 3, '4': 1, '5': 5, '10': 'budgetTokens'},
    {'1': 'used_tokens', '3': 4, '4': 1, '5': 5, '10': 'usedTokens'},
    {'1': 'injection_prompt', '3': 5, '4': 1, '5': 9, '10': 'injectionPrompt'},
    {
      '1': 'memories',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.CompressedMemory',
      '10': 'memories'
    },
    {
      '1': 'observations',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'observations'
    },
    {
      '1': 'summary',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.SessionSummary',
      '10': 'summary'
    },
    {
      '1': 'tool_hints',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.ToolDefinition',
      '10': 'toolHints'
    },
  ],
};

/// Descriptor for `ContextEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextEnvelopeDescriptor = $convert.base64Decode(
    'Cg9Db250ZXh0RW52ZWxvcGUSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhQKBXF1ZX'
    'J5GAIgASgJUgVxdWVyeRIjCg1idWRnZXRfdG9rZW5zGAMgASgFUgxidWRnZXRUb2tlbnMSHwoL'
    'dXNlZF90b2tlbnMYBCABKAVSCnVzZWRUb2tlbnMSKQoQaW5qZWN0aW9uX3Byb21wdBgFIAEoCV'
    'IPaW5qZWN0aW9uUHJvbXB0EkQKCG1lbW9yaWVzGAYgAygLMiguY3VscGVvc3R1ZGlvLm1lbW9y'
    'eS52MS5Db21wcmVzc2VkTWVtb3J5UghtZW1vcmllcxJHCgxvYnNlcnZhdGlvbnMYByADKAsyIy'
    '5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk9ic2VydmF0aW9uUgxvYnNlcnZhdGlvbnMSQAoHc3Vt'
    'bWFyeRgIIAEoCzImLmN1bHBlb3N0dWRpby5tZW1vcnkudjEuU2Vzc2lvblN1bW1hcnlSB3N1bW'
    '1hcnkSRQoKdG9vbF9oaW50cxgJIAMoCzImLmN1bHBlb3N0dWRpby5tZW1vcnkudjEuVG9vbERl'
    'ZmluaXRpb25SCXRvb2xIaW50cw==');

@$core.Deprecated('Use createSessionRequestDescriptor instead')
const CreateSessionRequest$json = {
  '1': 'CreateSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {'1': 'goals', '3': 4, '4': 3, '5': 9, '10': 'goals'},
  ],
};

/// Descriptor for `CreateSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTZXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGA'
    'oHcHJvamVjdBgCIAEoCVIHcHJvamVjdBIWCgZzb3VyY2UYAyABKAlSBnNvdXJjZRIUCgVnb2Fs'
    'cxgEIAMoCVIFZ29hbHM=');

@$core.Deprecated('Use createSessionResponseDescriptor instead')
const CreateSessionResponse$json = {
  '1': 'CreateSessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `CreateSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionResponseDescriptor = $convert.base64Decode(
    'ChVDcmVhdGVTZXNzaW9uUmVzcG9uc2USOQoHc2Vzc2lvbhgBIAEoCzIfLmN1bHBlb3N0dWRpby'
    '5tZW1vcnkudjEuU2Vzc2lvblIHc2Vzc2lvbg==');

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
      '6': '.culpeostudio.memory.v1.Session',
      '10': 'sessions'
    },
  ],
};

/// Descriptor for `ListSessionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0U2Vzc2lvbnNSZXNwb25zZRI7CghzZXNzaW9ucxgBIAMoCzIfLmN1bHBlb3N0dWRpby'
    '5tZW1vcnkudjEuU2Vzc2lvblIIc2Vzc2lvbnM=');

@$core.Deprecated('Use getSessionRequestDescriptor instead')
const GetSessionRequest$json = {
  '1': 'GetSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionRequestDescriptor = $convert.base64Decode(
    'ChFHZXRTZXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use getSessionResponseDescriptor instead')
const GetSessionResponse$json = {
  '1': 'GetSessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `GetSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionResponseDescriptor = $convert.base64Decode(
    'ChJHZXRTZXNzaW9uUmVzcG9uc2USOQoHc2Vzc2lvbhgBIAEoCzIfLmN1bHBlb3N0dWRpby5tZW'
    '1vcnkudjEuU2Vzc2lvblIHc2Vzc2lvbg==');

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

@$core.Deprecated('Use addPromptRequestDescriptor instead')
const AddPromptRequest$json = {
  '1': 'AddPromptRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'role',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.PromptRole',
      '10': 'role'
    },
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `AddPromptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addPromptRequestDescriptor = $convert.base64Decode(
    'ChBBZGRQcm9tcHRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBI2CgRyb2'
    'xlGAIgASgOMiIuY3VscGVvc3R1ZGlvLm1lbW9yeS52MS5Qcm9tcHRSb2xlUgRyb2xlEhIKBHRl'
    'eHQYAyABKAlSBHRleHQ=');

@$core.Deprecated('Use addPromptResponseDescriptor instead')
const AddPromptResponse$json = {
  '1': 'AddPromptResponse',
  '2': [
    {
      '1': 'prompt',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Prompt',
      '10': 'prompt'
    },
    {
      '1': 'context',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.ContextEnvelope',
      '10': 'context'
    },
  ],
};

/// Descriptor for `AddPromptResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addPromptResponseDescriptor = $convert.base64Decode(
    'ChFBZGRQcm9tcHRSZXNwb25zZRI2CgZwcm9tcHQYASABKAsyHi5jdWxwZW9zdHVkaW8ubWVtb3'
    'J5LnYxLlByb21wdFIGcHJvbXB0EkEKB2NvbnRleHQYAiABKAsyJy5jdWxwZW9zdHVkaW8ubWVt'
    'b3J5LnYxLkNvbnRleHRFbnZlbG9wZVIHY29udGV4dA==');

@$core.Deprecated('Use addObservationRequestDescriptor instead')
const AddObservationRequest$json = {
  '1': 'AddObservationRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'layer',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryLayer',
      '10': 'layer'
    },
    {
      '1': 'category',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryCategory',
      '10': 'category'
    },
    {'1': 'type', '3': 6, '4': 1, '5': 9, '10': 'type'},
    {'1': 'title', '3': 7, '4': 1, '5': 9, '10': 'title'},
    {'1': 'narrative', '3': 8, '4': 1, '5': 9, '10': 'narrative'},
    {
      '1': 'change_request',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.ChangeRequestState',
      '10': 'changeRequest'
    },
    {'1': 'speaker', '3': 10, '4': 1, '5': 9, '10': 'speaker'},
    {'1': 'dialogue_id', '3': 11, '4': 1, '5': 5, '10': 'dialogueId'},
    {'1': 'keywords', '3': 12, '4': 3, '5': 9, '10': 'keywords'},
    {'1': 'persons', '3': 13, '4': 3, '5': 9, '10': 'persons'},
    {'1': 'entities', '3': 14, '4': 3, '5': 9, '10': 'entities'},
    {'1': 'topic', '3': 15, '4': 1, '5': 9, '10': 'topic'},
    {'1': 'location', '3': 16, '4': 1, '5': 9, '10': 'location'},
    {'1': 'valid_from', '3': 17, '4': 1, '5': 9, '10': 'validFrom'},
    {'1': 'importance', '3': 18, '4': 1, '5': 1, '10': 'importance'},
    {'1': 'confidence', '3': 19, '4': 1, '5': 1, '10': 'confidence'},
    {'1': 'superseded_by', '3': 20, '4': 1, '5': 9, '10': 'supersededBy'},
    {'1': 'tool_name', '3': 21, '4': 1, '5': 9, '10': 'toolName'},
    {'1': 'source_path', '3': 22, '4': 1, '5': 9, '10': 'sourcePath'},
    {'1': 'tags', '3': 23, '4': 3, '5': 9, '10': 'tags'},
  ],
};

/// Descriptor for `AddObservationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addObservationRequestDescriptor = $convert.base64Decode(
    'ChVBZGRPYnNlcnZhdGlvblJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh'
    'gKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSFgoGc291cmNlGAMgASgJUgZzb3VyY2USOQoFbGF5'
    'ZXIYBCABKA4yIy5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk1lbW9yeUxheWVyUgVsYXllchJCCg'
    'hjYXRlZ29yeRgFIAEoDjImLmN1bHBlb3N0dWRpby5tZW1vcnkudjEuTWVtb3J5Q2F0ZWdvcnlS'
    'CGNhdGVnb3J5EhIKBHR5cGUYBiABKAlSBHR5cGUSFAoFdGl0bGUYByABKAlSBXRpdGxlEhwKCW'
    '5hcnJhdGl2ZRgIIAEoCVIJbmFycmF0aXZlElEKDmNoYW5nZV9yZXF1ZXN0GAkgASgLMiouY3Vs'
    'cGVvc3R1ZGlvLm1lbW9yeS52MS5DaGFuZ2VSZXF1ZXN0U3RhdGVSDWNoYW5nZVJlcXVlc3QSGA'
    'oHc3BlYWtlchgKIAEoCVIHc3BlYWtlchIfCgtkaWFsb2d1ZV9pZBgLIAEoBVIKZGlhbG9ndWVJ'
    'ZBIaCghrZXl3b3JkcxgMIAMoCVIIa2V5d29yZHMSGAoHcGVyc29ucxgNIAMoCVIHcGVyc29ucx'
    'IaCghlbnRpdGllcxgOIAMoCVIIZW50aXRpZXMSFAoFdG9waWMYDyABKAlSBXRvcGljEhoKCGxv'
    'Y2F0aW9uGBAgASgJUghsb2NhdGlvbhIdCgp2YWxpZF9mcm9tGBEgASgJUgl2YWxpZEZyb20SHg'
    'oKaW1wb3J0YW5jZRgSIAEoAVIKaW1wb3J0YW5jZRIeCgpjb25maWRlbmNlGBMgASgBUgpjb25m'
    'aWRlbmNlEiMKDXN1cGVyc2VkZWRfYnkYFCABKAlSDHN1cGVyc2VkZWRCeRIbCgl0b29sX25hbW'
    'UYFSABKAlSCHRvb2xOYW1lEh8KC3NvdXJjZV9wYXRoGBYgASgJUgpzb3VyY2VQYXRoEhIKBHRh'
    'Z3MYFyADKAlSBHRhZ3M=');

@$core.Deprecated('Use addObservationResponseDescriptor instead')
const AddObservationResponse$json = {
  '1': 'AddObservationResponse',
  '2': [
    {
      '1': 'observation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'observation'
    },
  ],
};

/// Descriptor for `AddObservationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addObservationResponseDescriptor =
    $convert.base64Decode(
        'ChZBZGRPYnNlcnZhdGlvblJlc3BvbnNlEkUKC29ic2VydmF0aW9uGAEgASgLMiMuY3VscGVvc3'
        'R1ZGlvLm1lbW9yeS52MS5PYnNlcnZhdGlvblILb2JzZXJ2YXRpb24=');

@$core.Deprecated('Use completeSessionRequestDescriptor instead')
const CompleteSessionRequest$json = {
  '1': 'CompleteSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'learned', '3': 2, '4': 3, '5': 9, '10': 'learned'},
    {'1': 'completed', '3': 3, '4': 3, '5': 9, '10': 'completed'},
    {'1': 'next_steps', '3': 4, '4': 3, '5': 9, '10': 'nextSteps'},
  ],
};

/// Descriptor for `CompleteSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completeSessionRequestDescriptor = $convert.base64Decode(
    'ChZDb21wbGV0ZVNlc3Npb25SZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IYCgdsZWFybmVkGAIgAygJUgdsZWFybmVkEhwKCWNvbXBsZXRlZBgDIAMoCVIJY29tcGxldGVk'
    'Eh0KCm5leHRfc3RlcHMYBCADKAlSCW5leHRTdGVwcw==');

@$core.Deprecated('Use completeSessionResponseDescriptor instead')
const CompleteSessionResponse$json = {
  '1': 'CompleteSessionResponse',
  '2': [
    {
      '1': 'summary',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.SessionSummary',
      '10': 'summary'
    },
  ],
};

/// Descriptor for `CompleteSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completeSessionResponseDescriptor =
    $convert.base64Decode(
        'ChdDb21wbGV0ZVNlc3Npb25SZXNwb25zZRJACgdzdW1tYXJ5GAEgASgLMiYuY3VscGVvc3R1ZG'
        'lvLm1lbW9yeS52MS5TZXNzaW9uU3VtbWFyeVIHc3VtbWFyeQ==');

@$core.Deprecated('Use searchRequestDescriptor instead')
const SearchRequest$json = {
  '1': 'SearchRequest',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'layer',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryLayer',
      '10': 'layer'
    },
    {
      '1': 'category',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.MemoryCategory',
      '10': 'category'
    },
    {'1': 'type', '3': 6, '4': 1, '5': 9, '10': 'type'},
    {'1': 'limit', '3': 7, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `SearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchRequestDescriptor = $convert.base64Decode(
    'Cg1TZWFyY2hSZXF1ZXN0EhQKBXF1ZXJ5GAEgASgJUgVxdWVyeRIYCgdwcm9qZWN0GAIgASgJUg'
    'dwcm9qZWN0EhYKBnNvdXJjZRgDIAEoCVIGc291cmNlEjkKBWxheWVyGAQgASgOMiMuY3VscGVv'
    'c3R1ZGlvLm1lbW9yeS52MS5NZW1vcnlMYXllclIFbGF5ZXISQgoIY2F0ZWdvcnkYBSABKA4yJi'
    '5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk1lbW9yeUNhdGVnb3J5UghjYXRlZ29yeRISCgR0eXBl'
    'GAYgASgJUgR0eXBlEhQKBWxpbWl0GAcgASgFUgVsaW1pdA==');

@$core.Deprecated('Use searchResponseDescriptor instead')
const SearchResponse$json = {
  '1': 'SearchResponse',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.SearchResult',
      '10': 'results'
    },
  ],
};

/// Descriptor for `SearchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResponseDescriptor = $convert.base64Decode(
    'Cg5TZWFyY2hSZXNwb25zZRI+CgdyZXN1bHRzGAEgAygLMiQuY3VscGVvc3R1ZGlvLm1lbW9yeS'
    '52MS5TZWFyY2hSZXN1bHRSB3Jlc3VsdHM=');

@$core.Deprecated('Use getTimelineRequestDescriptor instead')
const GetTimelineRequest$json = {
  '1': 'GetTimelineRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'observation_id', '3': 2, '4': 1, '5': 9, '10': 'observationId'},
    {'1': 'query', '3': 3, '4': 1, '5': 9, '10': 'query'},
    {'1': 'before', '3': 4, '4': 1, '5': 5, '10': 'before'},
    {'1': 'after', '3': 5, '4': 1, '5': 5, '10': 'after'},
  ],
};

/// Descriptor for `GetTimelineRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTimelineRequestDescriptor = $convert.base64Decode(
    'ChJHZXRUaW1lbGluZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEiUKDm'
    '9ic2VydmF0aW9uX2lkGAIgASgJUg1vYnNlcnZhdGlvbklkEhQKBXF1ZXJ5GAMgASgJUgVxdWVy'
    'eRIWCgZiZWZvcmUYBCABKAVSBmJlZm9yZRIUCgVhZnRlchgFIAEoBVIFYWZ0ZXI=');

@$core.Deprecated('Use getTimelineResponseDescriptor instead')
const GetTimelineResponse$json = {
  '1': 'GetTimelineResponse',
  '2': [
    {
      '1': 'observations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'observations'
    },
  ],
};

/// Descriptor for `GetTimelineResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTimelineResponseDescriptor = $convert.base64Decode(
    'ChNHZXRUaW1lbGluZVJlc3BvbnNlEkcKDG9ic2VydmF0aW9ucxgBIAMoCzIjLmN1bHBlb3N0dW'
    'Rpby5tZW1vcnkudjEuT2JzZXJ2YXRpb25SDG9ic2VydmF0aW9ucw==');

@$core.Deprecated('Use getObservationsRequestDescriptor instead')
const GetObservationsRequest$json = {
  '1': 'GetObservationsRequest',
  '2': [
    {'1': 'ids', '3': 1, '4': 3, '5': 9, '10': 'ids'},
  ],
};

/// Descriptor for `GetObservationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getObservationsRequestDescriptor = $convert
    .base64Decode('ChZHZXRPYnNlcnZhdGlvbnNSZXF1ZXN0EhAKA2lkcxgBIAMoCVIDaWRz');

@$core.Deprecated('Use getObservationsResponseDescriptor instead')
const GetObservationsResponse$json = {
  '1': 'GetObservationsResponse',
  '2': [
    {
      '1': 'observations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'observations'
    },
  ],
};

/// Descriptor for `GetObservationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getObservationsResponseDescriptor =
    $convert.base64Decode(
        'ChdHZXRPYnNlcnZhdGlvbnNSZXNwb25zZRJHCgxvYnNlcnZhdGlvbnMYASADKAsyIy5jdWxwZW'
        '9zdHVkaW8ubWVtb3J5LnYxLk9ic2VydmF0aW9uUgxvYnNlcnZhdGlvbnM=');

@$core.Deprecated('Use getContextRequestDescriptor instead')
const GetContextRequest$json = {
  '1': 'GetContextRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `GetContextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getContextRequestDescriptor = $convert.base64Decode(
    'ChFHZXRDb250ZXh0UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFAoFcX'
    'VlcnkYAiABKAlSBXF1ZXJ5EhQKBWxpbWl0GAMgASgFUgVsaW1pdA==');

@$core.Deprecated('Use getContextResponseDescriptor instead')
const GetContextResponse$json = {
  '1': 'GetContextResponse',
  '2': [
    {
      '1': 'context',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.ContextEnvelope',
      '10': 'context'
    },
  ],
};

/// Descriptor for `GetContextResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getContextResponseDescriptor = $convert.base64Decode(
    'ChJHZXRDb250ZXh0UmVzcG9uc2USQQoHY29udGV4dBgBIAEoCzInLmN1bHBlb3N0dWRpby5tZW'
    '1vcnkudjEuQ29udGV4dEVudmVsb3BlUgdjb250ZXh0');

@$core.Deprecated('Use updateChangeRequestStatusRequestDescriptor instead')
const UpdateChangeRequestStatusRequest$json = {
  '1': 'UpdateChangeRequestStatusRequest',
  '2': [
    {'1': 'observation_id', '3': 1, '4': 1, '5': 9, '10': 'observationId'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.memory.v1.ChangeRequestStatus',
      '10': 'status'
    },
    {'1': 'reason_short', '3': 3, '4': 1, '5': 9, '10': 'reasonShort'},
  ],
};

/// Descriptor for `UpdateChangeRequestStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateChangeRequestStatusRequestDescriptor =
    $convert.base64Decode(
        'CiBVcGRhdGVDaGFuZ2VSZXF1ZXN0U3RhdHVzUmVxdWVzdBIlCg5vYnNlcnZhdGlvbl9pZBgBIA'
        'EoCVINb2JzZXJ2YXRpb25JZBJDCgZzdGF0dXMYAiABKA4yKy5jdWxwZW9zdHVkaW8ubWVtb3J5'
        'LnYxLkNoYW5nZVJlcXVlc3RTdGF0dXNSBnN0YXR1cxIhCgxyZWFzb25fc2hvcnQYAyABKAlSC3'
        'JlYXNvblNob3J0');

@$core.Deprecated('Use updateChangeRequestStatusResponseDescriptor instead')
const UpdateChangeRequestStatusResponse$json = {
  '1': 'UpdateChangeRequestStatusResponse',
  '2': [
    {
      '1': 'observation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'observation'
    },
  ],
};

/// Descriptor for `UpdateChangeRequestStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateChangeRequestStatusResponseDescriptor =
    $convert.base64Decode(
        'CiFVcGRhdGVDaGFuZ2VSZXF1ZXN0U3RhdHVzUmVzcG9uc2USRQoLb2JzZXJ2YXRpb24YASABKA'
        'syIy5jdWxwZW9zdHVkaW8ubWVtb3J5LnYxLk9ic2VydmF0aW9uUgtvYnNlcnZhdGlvbg==');

@$core.Deprecated('Use deleteObservationRequestDescriptor instead')
const DeleteObservationRequest$json = {
  '1': 'DeleteObservationRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteObservationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteObservationRequestDescriptor = $convert
    .base64Decode('ChhEZWxldGVPYnNlcnZhdGlvblJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use deleteObservationResponseDescriptor instead')
const DeleteObservationResponse$json = {
  '1': 'DeleteObservationResponse',
  '2': [
    {
      '1': 'observation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'observation'
    },
    {'1': 'tombstoned', '3': 2, '4': 1, '5': 8, '10': 'tombstoned'},
  ],
};

/// Descriptor for `DeleteObservationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteObservationResponseDescriptor = $convert.base64Decode(
    'ChlEZWxldGVPYnNlcnZhdGlvblJlc3BvbnNlEkUKC29ic2VydmF0aW9uGAEgASgLMiMuY3VscG'
    'Vvc3R1ZGlvLm1lbW9yeS52MS5PYnNlcnZhdGlvblILb2JzZXJ2YXRpb24SHgoKdG9tYnN0b25l'
    'ZBgCIAEoCFIKdG9tYnN0b25lZA==');

@$core.Deprecated('Use stringListDescriptor instead')
const StringList$json = {
  '1': 'StringList',
  '2': [
    {'1': 'values', '3': 1, '4': 3, '5': 9, '10': 'values'},
  ],
};

/// Descriptor for `StringList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stringListDescriptor =
    $convert.base64Decode('CgpTdHJpbmdMaXN0EhYKBnZhbHVlcxgBIAMoCVIGdmFsdWVz');

@$core.Deprecated('Use updateMemoryRequestDescriptor instead')
const UpdateMemoryRequest$json = {
  '1': 'UpdateMemoryRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'summary',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'summary',
      '17': true
    },
    {
      '1': 'learned',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.StringList',
      '10': 'learned'
    },
    {
      '1': 'open_tasks',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.StringList',
      '10': 'openTasks'
    },
  ],
  '8': [
    {'1': '_summary'},
  ],
};

/// Descriptor for `UpdateMemoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateMemoryRequestDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVNZW1vcnlSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIdCgdzdW1tYXJ5GAIgASgJSA'
    'BSB3N1bW1hcnmIAQESPAoHbGVhcm5lZBgDIAEoCzIiLmN1bHBlb3N0dWRpby5tZW1vcnkudjEu'
    'U3RyaW5nTGlzdFIHbGVhcm5lZBJBCgpvcGVuX3Rhc2tzGAQgASgLMiIuY3VscGVvc3R1ZGlvLm'
    '1lbW9yeS52MS5TdHJpbmdMaXN0UglvcGVuVGFza3NCCgoIX3N1bW1hcnk=');

@$core.Deprecated('Use updateMemoryResponseDescriptor instead')
const UpdateMemoryResponse$json = {
  '1': 'UpdateMemoryResponse',
  '2': [
    {
      '1': 'memory',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.CompressedMemory',
      '10': 'memory'
    },
  ],
};

/// Descriptor for `UpdateMemoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateMemoryResponseDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVNZW1vcnlSZXNwb25zZRJACgZtZW1vcnkYASABKAsyKC5jdWxwZW9zdHVkaW8ubW'
    'Vtb3J5LnYxLkNvbXByZXNzZWRNZW1vcnlSBm1lbW9yeQ==');

@$core.Deprecated('Use captureChatMessageRequestDescriptor instead')
const CaptureChatMessageRequest$json = {
  '1': 'CaptureChatMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'prompt', '3': 3, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'reply', '3': 4, '4': 1, '5': 9, '10': 'reply'},
  ],
};

/// Descriptor for `CaptureChatMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureChatMessageRequestDescriptor = $convert.base64Decode(
    'ChlDYXB0dXJlQ2hhdE1lc3NhZ2VSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb2'
    '5JZBIYCgdwcm9qZWN0GAIgASgJUgdwcm9qZWN0EhYKBnByb21wdBgDIAEoCVIGcHJvbXB0EhQK'
    'BXJlcGx5GAQgASgJUgVyZXBseQ==');

@$core.Deprecated('Use captureChatMessageResponseDescriptor instead')
const CaptureChatMessageResponse$json = {
  '1': 'CaptureChatMessageResponse',
  '2': [
    {
      '1': 'context',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.ContextEnvelope',
      '10': 'context'
    },
  ],
};

/// Descriptor for `CaptureChatMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureChatMessageResponseDescriptor =
    $convert.base64Decode(
        'ChpDYXB0dXJlQ2hhdE1lc3NhZ2VSZXNwb25zZRJBCgdjb250ZXh0GAEgASgLMicuY3VscGVvc3'
        'R1ZGlvLm1lbW9yeS52MS5Db250ZXh0RW52ZWxvcGVSB2NvbnRleHQ=');

@$core.Deprecated('Use captureEventRequestDescriptor instead')
const CaptureEventRequest$json = {
  '1': 'CaptureEventRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {'1': 'type', '3': 4, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'data',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'data'
    },
  ],
};

/// Descriptor for `CaptureEventRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureEventRequestDescriptor = $convert.base64Decode(
    'ChNDYXB0dXJlRXZlbnRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIYCg'
    'dwcm9qZWN0GAIgASgJUgdwcm9qZWN0EhYKBnNvdXJjZRgDIAEoCVIGc291cmNlEhIKBHR5cGUY'
    'BCABKAlSBHR5cGUSKwoEZGF0YRgFIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSBGRhdG'
    'E=');

@$core.Deprecated('Use captureEventResponseDescriptor instead')
const CaptureEventResponse$json = {
  '1': 'CaptureEventResponse',
  '2': [
    {
      '1': 'observation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '10': 'observation'
    },
  ],
};

/// Descriptor for `CaptureEventResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureEventResponseDescriptor = $convert.base64Decode(
    'ChRDYXB0dXJlRXZlbnRSZXNwb25zZRJFCgtvYnNlcnZhdGlvbhgBIAEoCzIjLmN1bHBlb3N0dW'
    'Rpby5tZW1vcnkudjEuT2JzZXJ2YXRpb25SC29ic2VydmF0aW9u');

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
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'timestamp',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
    {
      '1': 'session',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Session',
      '9': 0,
      '10': 'session'
    },
    {
      '1': 'prompt',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Prompt',
      '9': 0,
      '10': 'prompt'
    },
    {
      '1': 'observation',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.Observation',
      '9': 0,
      '10': 'observation'
    },
    {
      '1': 'memory',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.CompressedMemory',
      '9': 0,
      '10': 'memory'
    },
    {
      '1': 'summary',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.memory.v1.SessionSummary',
      '9': 0,
      '10': 'summary'
    },
    {
      '1': 'data',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '9': 0,
      '10': 'data'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `StreamEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamEventsResponseDescriptor = $convert.base64Decode(
    'ChRTdHJlYW1FdmVudHNSZXNwb25zZRISCgR0eXBlGAEgASgJUgR0eXBlEjgKCXRpbWVzdGFtcB'
    'gCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXRpbWVzdGFtcBI7CgdzZXNzaW9u'
    'GAMgASgLMh8uY3VscGVvc3R1ZGlvLm1lbW9yeS52MS5TZXNzaW9uSABSB3Nlc3Npb24SOAoGcH'
    'JvbXB0GAQgASgLMh4uY3VscGVvc3R1ZGlvLm1lbW9yeS52MS5Qcm9tcHRIAFIGcHJvbXB0EkcK'
    'C29ic2VydmF0aW9uGAUgASgLMiMuY3VscGVvc3R1ZGlvLm1lbW9yeS52MS5PYnNlcnZhdGlvbk'
    'gAUgtvYnNlcnZhdGlvbhJCCgZtZW1vcnkYBiABKAsyKC5jdWxwZW9zdHVkaW8ubWVtb3J5LnYx'
    'LkNvbXByZXNzZWRNZW1vcnlIAFIGbWVtb3J5EkIKB3N1bW1hcnkYByABKAsyJi5jdWxwZW9zdH'
    'VkaW8ubWVtb3J5LnYxLlNlc3Npb25TdW1tYXJ5SABSB3N1bW1hcnkSLQoEZGF0YRgIIAEoCzIX'
    'Lmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RIAFIEZGF0YUIJCgdwYXlsb2Fk');
