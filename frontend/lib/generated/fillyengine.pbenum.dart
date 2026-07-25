// This is a generated file - do not edit.
//
// Generated from fillyengine.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AgenticResponse_Type extends $pb.ProtobufEnum {
  static const AgenticResponse_Type TEXT_DELTA =
      AgenticResponse_Type._(0, _omitEnumNames ? '' : 'TEXT_DELTA');
  static const AgenticResponse_Type TOOL_START =
      AgenticResponse_Type._(1, _omitEnumNames ? '' : 'TOOL_START');
  static const AgenticResponse_Type TOOL_RESULT =
      AgenticResponse_Type._(2, _omitEnumNames ? '' : 'TOOL_RESULT');
  static const AgenticResponse_Type PLANNING_QUESTIONS =
      AgenticResponse_Type._(3, _omitEnumNames ? '' : 'PLANNING_QUESTIONS');
  static const AgenticResponse_Type PLAN_READY =
      AgenticResponse_Type._(4, _omitEnumNames ? '' : 'PLAN_READY');
  static const AgenticResponse_Type APPROVAL_NEEDED =
      AgenticResponse_Type._(5, _omitEnumNames ? '' : 'APPROVAL_NEEDED');
  static const AgenticResponse_Type COMPRESSION_EVENT =
      AgenticResponse_Type._(6, _omitEnumNames ? '' : 'COMPRESSION_EVENT');
  static const AgenticResponse_Type ERROR =
      AgenticResponse_Type._(7, _omitEnumNames ? '' : 'ERROR');
  static const AgenticResponse_Type DONE =
      AgenticResponse_Type._(8, _omitEnumNames ? '' : 'DONE');

  static const $core.List<AgenticResponse_Type> values = <AgenticResponse_Type>[
    TEXT_DELTA,
    TOOL_START,
    TOOL_RESULT,
    PLANNING_QUESTIONS,
    PLAN_READY,
    APPROVAL_NEEDED,
    COMPRESSION_EVENT,
    ERROR,
    DONE,
  ];

  static final $core.List<AgenticResponse_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static AgenticResponse_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AgenticResponse_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
