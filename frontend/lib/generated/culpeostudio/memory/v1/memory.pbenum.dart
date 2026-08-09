// This is a generated file - do not edit.
//
// Generated from culpeostudio/memory/v1/memory.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SessionStatus extends $pb.ProtobufEnum {
  static const SessionStatus SESSION_STATUS_UNSPECIFIED =
      SessionStatus._(0, _omitEnumNames ? '' : 'SESSION_STATUS_UNSPECIFIED');
  static const SessionStatus SESSION_STATUS_ACTIVE =
      SessionStatus._(1, _omitEnumNames ? '' : 'SESSION_STATUS_ACTIVE');
  static const SessionStatus SESSION_STATUS_COMPLETED =
      SessionStatus._(2, _omitEnumNames ? '' : 'SESSION_STATUS_COMPLETED');

  static const $core.List<SessionStatus> values = <SessionStatus>[
    SESSION_STATUS_UNSPECIFIED,
    SESSION_STATUS_ACTIVE,
    SESSION_STATUS_COMPLETED,
  ];

  static final $core.List<SessionStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SessionStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionStatus._(super.value, super.name);
}

/// PromptRole is who spoke. Unspecified is read as USER, which is what the
/// store did with any role it did not recognise.
class PromptRole extends $pb.ProtobufEnum {
  static const PromptRole PROMPT_ROLE_UNSPECIFIED =
      PromptRole._(0, _omitEnumNames ? '' : 'PROMPT_ROLE_UNSPECIFIED');
  static const PromptRole PROMPT_ROLE_USER =
      PromptRole._(1, _omitEnumNames ? '' : 'PROMPT_ROLE_USER');
  static const PromptRole PROMPT_ROLE_ASSISTANT =
      PromptRole._(2, _omitEnumNames ? '' : 'PROMPT_ROLE_ASSISTANT');
  static const PromptRole PROMPT_ROLE_SYSTEM =
      PromptRole._(3, _omitEnumNames ? '' : 'PROMPT_ROLE_SYSTEM');

  static const $core.List<PromptRole> values = <PromptRole>[
    PROMPT_ROLE_UNSPECIFIED,
    PROMPT_ROLE_USER,
    PROMPT_ROLE_ASSISTANT,
    PROMPT_ROLE_SYSTEM,
  ];

  static final $core.List<PromptRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PromptRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PromptRole._(super.value, super.name);
}

/// MemoryLayer separates what is true of the user from what is true of a
/// project. On a write, unspecified means PROJECT_DATA: memory a caller does not
/// place belongs to the project, not to the person. On a filter it means "any
/// layer", and search then infers one from the query.
class MemoryLayer extends $pb.ProtobufEnum {
  static const MemoryLayer MEMORY_LAYER_UNSPECIFIED =
      MemoryLayer._(0, _omitEnumNames ? '' : 'MEMORY_LAYER_UNSPECIFIED');
  static const MemoryLayer MEMORY_LAYER_USER_DATA =
      MemoryLayer._(1, _omitEnumNames ? '' : 'MEMORY_LAYER_USER_DATA');
  static const MemoryLayer MEMORY_LAYER_PROJECT_DATA =
      MemoryLayer._(2, _omitEnumNames ? '' : 'MEMORY_LAYER_PROJECT_DATA');

  static const $core.List<MemoryLayer> values = <MemoryLayer>[
    MEMORY_LAYER_UNSPECIFIED,
    MEMORY_LAYER_USER_DATA,
    MEMORY_LAYER_PROJECT_DATA,
  ];

  static final $core.List<MemoryLayer?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MemoryLayer? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MemoryLayer._(super.value, super.name);
}

/// MemoryCategory is what kind of thing was remembered. On a write, unspecified
/// means STATUS; on a filter it means "any category".
class MemoryCategory extends $pb.ProtobufEnum {
  static const MemoryCategory MEMORY_CATEGORY_UNSPECIFIED =
      MemoryCategory._(0, _omitEnumNames ? '' : 'MEMORY_CATEGORY_UNSPECIFIED');
  static const MemoryCategory MEMORY_CATEGORY_STATUS =
      MemoryCategory._(1, _omitEnumNames ? '' : 'MEMORY_CATEGORY_STATUS');
  static const MemoryCategory MEMORY_CATEGORY_BRAINSTORMING = MemoryCategory._(
      2, _omitEnumNames ? '' : 'MEMORY_CATEGORY_BRAINSTORMING');
  static const MemoryCategory MEMORY_CATEGORY_CHANGE_REQUEST = MemoryCategory._(
      3, _omitEnumNames ? '' : 'MEMORY_CATEGORY_CHANGE_REQUEST');

  static const $core.List<MemoryCategory> values = <MemoryCategory>[
    MEMORY_CATEGORY_UNSPECIFIED,
    MEMORY_CATEGORY_STATUS,
    MEMORY_CATEGORY_BRAINSTORMING,
    MEMORY_CATEGORY_CHANGE_REQUEST,
  ];

  static final $core.List<MemoryCategory?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static MemoryCategory? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MemoryCategory._(super.value, super.name);
}

/// ChangeRequestStatus is where a proposal stands. Unspecified is read as OPEN,
/// which is the state a proposal is recorded in.
class ChangeRequestStatus extends $pb.ProtobufEnum {
  static const ChangeRequestStatus CHANGE_REQUEST_STATUS_UNSPECIFIED =
      ChangeRequestStatus._(
          0, _omitEnumNames ? '' : 'CHANGE_REQUEST_STATUS_UNSPECIFIED');
  static const ChangeRequestStatus CHANGE_REQUEST_STATUS_OPEN =
      ChangeRequestStatus._(
          1, _omitEnumNames ? '' : 'CHANGE_REQUEST_STATUS_OPEN');
  static const ChangeRequestStatus CHANGE_REQUEST_STATUS_ACCEPTED =
      ChangeRequestStatus._(
          2, _omitEnumNames ? '' : 'CHANGE_REQUEST_STATUS_ACCEPTED');
  static const ChangeRequestStatus CHANGE_REQUEST_STATUS_REJECTED =
      ChangeRequestStatus._(
          3, _omitEnumNames ? '' : 'CHANGE_REQUEST_STATUS_REJECTED');

  static const $core.List<ChangeRequestStatus> values = <ChangeRequestStatus>[
    CHANGE_REQUEST_STATUS_UNSPECIFIED,
    CHANGE_REQUEST_STATUS_OPEN,
    CHANGE_REQUEST_STATUS_ACCEPTED,
    CHANGE_REQUEST_STATUS_REJECTED,
  ];

  static final $core.List<ChangeRequestStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ChangeRequestStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ChangeRequestStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
