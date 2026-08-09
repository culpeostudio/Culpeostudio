// This is a generated file - do not edit.
//
// Generated from culpeostudio/settings/v1/settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Provider names the model hosts a token can be tested against. The HTTP API
/// took this as a free-form path segment and rejected unknown values at
/// runtime; as an enum the schema rules them out up front.
class Provider extends $pb.ProtobufEnum {
  static const Provider PROVIDER_UNSPECIFIED =
      Provider._(0, _omitEnumNames ? '' : 'PROVIDER_UNSPECIFIED');
  static const Provider PROVIDER_HUGGINGFACE =
      Provider._(1, _omitEnumNames ? '' : 'PROVIDER_HUGGINGFACE');
  static const Provider PROVIDER_OPENROUTER =
      Provider._(2, _omitEnumNames ? '' : 'PROVIDER_OPENROUTER');
  static const Provider PROVIDER_FEATHERLESS =
      Provider._(3, _omitEnumNames ? '' : 'PROVIDER_FEATHERLESS');

  static const $core.List<Provider> values = <Provider>[
    PROVIDER_UNSPECIFIED,
    PROVIDER_HUGGINGFACE,
    PROVIDER_OPENROUTER,
    PROVIDER_FEATHERLESS,
  ];

  static final $core.List<Provider?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Provider? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Provider._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
