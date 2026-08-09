// This is a generated file - do not edit.
//
// Generated from culpeostudio/spark/v1/spark.proto.

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

@$core.Deprecated('Use projectDescriptor instead')
const Project$json = {
  '1': 'Project',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'color', '3': 4, '4': 1, '5': 9, '10': 'color'},
    {'1': 'path', '3': 5, '4': 1, '5': 9, '10': 'path'},
    {'1': 'icon', '3': 6, '4': 1, '5': 9, '10': 'icon'},
    {
      '1': 'created_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
};

/// Descriptor for `Project`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List projectDescriptor = $convert.base64Decode(
    'CgdQcm9qZWN0Eg4KAmlkGAEgASgJUgJpZBIXCgd1c2VyX2lkGAIgASgJUgZ1c2VySWQSEgoEbm'
    'FtZRgDIAEoCVIEbmFtZRIUCgVjb2xvchgEIAEoCVIFY29sb3ISEgoEcGF0aBgFIAEoCVIEcGF0'
    'aBISCgRpY29uGAYgASgJUgRpY29uEjkKCmNyZWF0ZWRfYXQYByABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSOQoKdXBkYXRlZF9hdBgIIAEoCzIaLmdvb2dsZS5w'
    'cm90b2J1Zi5UaW1lc3RhbXBSCXVwZGF0ZWRBdA==');

@$core.Deprecated('Use listProjectsRequestDescriptor instead')
const ListProjectsRequest$json = {
  '1': 'ListProjectsRequest',
};

/// Descriptor for `ListProjectsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listProjectsRequestDescriptor =
    $convert.base64Decode('ChNMaXN0UHJvamVjdHNSZXF1ZXN0');

@$core.Deprecated('Use listProjectsResponseDescriptor instead')
const ListProjectsResponse$json = {
  '1': 'ListProjectsResponse',
  '2': [
    {
      '1': 'projects',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.spark.v1.Project',
      '10': 'projects'
    },
  ],
};

/// Descriptor for `ListProjectsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listProjectsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0UHJvamVjdHNSZXNwb25zZRI6Cghwcm9qZWN0cxgBIAMoCzIeLmN1bHBlb3N0dWRpby'
    '5zcGFyay52MS5Qcm9qZWN0Ughwcm9qZWN0cw==');

@$core.Deprecated('Use createProjectRequestDescriptor instead')
const CreateProjectRequest$json = {
  '1': 'CreateProjectRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'color', '3': 2, '4': 1, '5': 9, '10': 'color'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {'1': 'icon', '3': 4, '4': 1, '5': 9, '10': 'icon'},
  ],
};

/// Descriptor for `CreateProjectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createProjectRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVQcm9qZWN0UmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lEhQKBWNvbG9yGAIgAS'
    'gJUgVjb2xvchISCgRwYXRoGAMgASgJUgRwYXRoEhIKBGljb24YBCABKAlSBGljb24=');

@$core.Deprecated('Use createProjectResponseDescriptor instead')
const CreateProjectResponse$json = {
  '1': 'CreateProjectResponse',
  '2': [
    {
      '1': 'project',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.spark.v1.Project',
      '10': 'project'
    },
  ],
};

/// Descriptor for `CreateProjectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createProjectResponseDescriptor = $convert.base64Decode(
    'ChVDcmVhdGVQcm9qZWN0UmVzcG9uc2USOAoHcHJvamVjdBgBIAEoCzIeLmN1bHBlb3N0dWRpby'
    '5zcGFyay52MS5Qcm9qZWN0Ugdwcm9qZWN0');

@$core.Deprecated('Use renameProjectRequestDescriptor instead')
const RenameProjectRequest$json = {
  '1': 'RenameProjectRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'color', '3': 3, '4': 1, '5': 9, '10': 'color'},
    {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
    {'1': 'icon', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'icon', '17': true},
  ],
  '8': [
    {'1': '_icon'},
  ],
};

/// Descriptor for `RenameProjectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameProjectRequestDescriptor = $convert.base64Decode(
    'ChRSZW5hbWVQcm9qZWN0UmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbm'
    'FtZRIUCgVjb2xvchgDIAEoCVIFY29sb3ISEgoEcGF0aBgEIAEoCVIEcGF0aBIXCgRpY29uGAUg'
    'ASgJSABSBGljb26IAQFCBwoFX2ljb24=');

@$core.Deprecated('Use renameProjectResponseDescriptor instead')
const RenameProjectResponse$json = {
  '1': 'RenameProjectResponse',
  '2': [
    {
      '1': 'project',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.spark.v1.Project',
      '10': 'project'
    },
  ],
};

/// Descriptor for `RenameProjectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameProjectResponseDescriptor = $convert.base64Decode(
    'ChVSZW5hbWVQcm9qZWN0UmVzcG9uc2USOAoHcHJvamVjdBgBIAEoCzIeLmN1bHBlb3N0dWRpby'
    '5zcGFyay52MS5Qcm9qZWN0Ugdwcm9qZWN0');

@$core.Deprecated('Use deleteProjectRequestDescriptor instead')
const DeleteProjectRequest$json = {
  '1': 'DeleteProjectRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteProjectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteProjectRequestDescriptor = $convert
    .base64Decode('ChREZWxldGVQcm9qZWN0UmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use deleteProjectResponseDescriptor instead')
const DeleteProjectResponse$json = {
  '1': 'DeleteProjectResponse',
};

/// Descriptor for `DeleteProjectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteProjectResponseDescriptor =
    $convert.base64Decode('ChVEZWxldGVQcm9qZWN0UmVzcG9uc2U=');

@$core.Deprecated('Use respondToPermissionRequestDescriptor instead')
const RespondToPermissionRequest$json = {
  '1': 'RespondToPermissionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'decision', '3': 3, '4': 1, '5': 9, '10': 'decision'},
  ],
};

/// Descriptor for `RespondToPermissionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respondToPermissionRequestDescriptor =
    $convert.base64Decode(
        'ChpSZXNwb25kVG9QZXJtaXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW'
        '9uSWQSHQoKcmVxdWVzdF9pZBgCIAEoCVIJcmVxdWVzdElkEhoKCGRlY2lzaW9uGAMgASgJUghk'
        'ZWNpc2lvbg==');

@$core.Deprecated('Use respondToPermissionResponseDescriptor instead')
const RespondToPermissionResponse$json = {
  '1': 'RespondToPermissionResponse',
};

/// Descriptor for `RespondToPermissionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respondToPermissionResponseDescriptor =
    $convert.base64Decode('ChtSZXNwb25kVG9QZXJtaXNzaW9uUmVzcG9uc2U=');
