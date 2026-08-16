// This is a generated file - do not edit.
//
// Generated from culpeostudio/providers/v1/providers.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ConnectionProtocol tells the backend which discovery and streaming-chat
/// adapter to use.  New vendors can reuse OPENAI_COMPATIBLE instead of forcing
/// a client schema change for every provider.
class ConnectionProtocol extends $pb.ProtobufEnum {
  static const ConnectionProtocol CONNECTION_PROTOCOL_UNSPECIFIED =
      ConnectionProtocol._(
          0, _omitEnumNames ? '' : 'CONNECTION_PROTOCOL_UNSPECIFIED');
  static const ConnectionProtocol CONNECTION_PROTOCOL_OPENAI_COMPATIBLE =
      ConnectionProtocol._(
          1, _omitEnumNames ? '' : 'CONNECTION_PROTOCOL_OPENAI_COMPATIBLE');
  static const ConnectionProtocol CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES =
      ConnectionProtocol._(
          2, _omitEnumNames ? '' : 'CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES');
  static const ConnectionProtocol CONNECTION_PROTOCOL_GOOGLE_GENAI =
      ConnectionProtocol._(
          3, _omitEnumNames ? '' : 'CONNECTION_PROTOCOL_GOOGLE_GENAI');
  static const ConnectionProtocol CONNECTION_PROTOCOL_OLLAMA_NATIVE =
      ConnectionProtocol._(
          4, _omitEnumNames ? '' : 'CONNECTION_PROTOCOL_OLLAMA_NATIVE');

  static const $core.List<ConnectionProtocol> values = <ConnectionProtocol>[
    CONNECTION_PROTOCOL_UNSPECIFIED,
    CONNECTION_PROTOCOL_OPENAI_COMPATIBLE,
    CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES,
    CONNECTION_PROTOCOL_GOOGLE_GENAI,
    CONNECTION_PROTOCOL_OLLAMA_NATIVE,
  ];

  static final $core.List<ConnectionProtocol?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ConnectionProtocol? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ConnectionProtocol._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
