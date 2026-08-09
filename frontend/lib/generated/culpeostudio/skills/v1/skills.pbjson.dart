// This is a generated file - do not edit.
//
// Generated from culpeostudio/skills/v1/skills.proto.

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

@$core.Deprecated('Use listSkillsRequestDescriptor instead')
const ListSkillsRequest$json = {
  '1': 'ListSkillsRequest',
};

/// Descriptor for `ListSkillsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSkillsRequestDescriptor =
    $convert.base64Decode('ChFMaXN0U2tpbGxzUmVxdWVzdA==');

@$core.Deprecated('Use listSkillsResponseDescriptor instead')
const ListSkillsResponse$json = {
  '1': 'ListSkillsResponse',
  '2': [
    {
      '1': 'skills',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.skills.v1.SkillRecord',
      '10': 'skills'
    },
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `ListSkillsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSkillsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0U2tpbGxzUmVzcG9uc2USOwoGc2tpbGxzGAEgAygLMiMuY3VscGVvc3R1ZGlvLnNraW'
    'xscy52MS5Ta2lsbFJlY29yZFIGc2tpbGxzEhQKBWNvdW50GAIgASgFUgVjb3VudA==');

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

@$core.Deprecated('Use importSkillResponseDescriptor instead')
const ImportSkillResponse$json = {
  '1': 'ImportSkillResponse',
  '2': [
    {
      '1': 'skill',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.skills.v1.SkillRecord',
      '10': 'skill'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ImportSkillResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importSkillResponseDescriptor = $convert.base64Decode(
    'ChNJbXBvcnRTa2lsbFJlc3BvbnNlEjkKBXNraWxsGAEgASgLMiMuY3VscGVvc3R1ZGlvLnNraW'
    'xscy52MS5Ta2lsbFJlY29yZFIFc2tpbGwSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

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

@$core.Deprecated('Use updateSkillResponseDescriptor instead')
const UpdateSkillResponse$json = {
  '1': 'UpdateSkillResponse',
  '2': [
    {
      '1': 'skill',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.skills.v1.SkillRecord',
      '10': 'skill'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `UpdateSkillResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSkillResponseDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVTa2lsbFJlc3BvbnNlEjkKBXNraWxsGAEgASgLMiMuY3VscGVvc3R1ZGlvLnNraW'
    'xscy52MS5Ta2lsbFJlY29yZFIFc2tpbGwSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

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

@$core.Deprecated('Use rescanSkillsRequestDescriptor instead')
const RescanSkillsRequest$json = {
  '1': 'RescanSkillsRequest',
};

/// Descriptor for `RescanSkillsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rescanSkillsRequestDescriptor =
    $convert.base64Decode('ChNSZXNjYW5Ta2lsbHNSZXF1ZXN0');

@$core.Deprecated('Use rescanSkillsResponseDescriptor instead')
const RescanSkillsResponse$json = {
  '1': 'RescanSkillsResponse',
  '2': [
    {
      '1': 'skills',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.skills.v1.SkillRecord',
      '10': 'skills'
    },
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `RescanSkillsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rescanSkillsResponseDescriptor = $convert.base64Decode(
    'ChRSZXNjYW5Ta2lsbHNSZXNwb25zZRI7CgZza2lsbHMYASADKAsyIy5jdWxwZW9zdHVkaW8uc2'
    'tpbGxzLnYxLlNraWxsUmVjb3JkUgZza2lsbHMSFAoFY291bnQYAiABKAVSBWNvdW50');

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
      '6': '.culpeostudio.skills.v1.SkillFileSummary',
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
    'EhQKBXZhbGlkGAsgASgIUgV2YWxpZBIWCgZlcnJvcnMYDCADKAlSBmVycm9ycxJLCgxmaWxlX3'
    'N1bW1hcnkYDSABKAsyKC5jdWxwZW9zdHVkaW8uc2tpbGxzLnYxLlNraWxsRmlsZVN1bW1hcnlS'
    'C2ZpbGVTdW1tYXJ5');

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
