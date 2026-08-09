// This is a generated file - do not edit.
//
// Generated from culpeostudio/login/v1/login.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// SessionDuration is how long an issued token stays valid. The HTTP API took
/// this as a string and quietly fell back to 24h for anything it did not
/// recognise; UNSPECIFIED keeps that fallback but makes it explicit.
class SessionDuration extends $pb.ProtobufEnum {
  static const SessionDuration SESSION_DURATION_UNSPECIFIED = SessionDuration._(
      0, _omitEnumNames ? '' : 'SESSION_DURATION_UNSPECIFIED');
  static const SessionDuration SESSION_DURATION_8H =
      SessionDuration._(1, _omitEnumNames ? '' : 'SESSION_DURATION_8H');
  static const SessionDuration SESSION_DURATION_24H =
      SessionDuration._(2, _omitEnumNames ? '' : 'SESSION_DURATION_24H');
  static const SessionDuration SESSION_DURATION_48H =
      SessionDuration._(3, _omitEnumNames ? '' : 'SESSION_DURATION_48H');
  static const SessionDuration SESSION_DURATION_PERMANENT =
      SessionDuration._(4, _omitEnumNames ? '' : 'SESSION_DURATION_PERMANENT');

  static const $core.List<SessionDuration> values = <SessionDuration>[
    SESSION_DURATION_UNSPECIFIED,
    SESSION_DURATION_8H,
    SESSION_DURATION_24H,
    SESSION_DURATION_48H,
    SESSION_DURATION_PERMANENT,
  ];

  static final $core.List<SessionDuration?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SessionDuration? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionDuration._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
