// This is a generated file - do not edit.
//
// Generated from culpeostudio/benchmark/v1/benchmark.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// BoardState is how far a board got with loading its snapshot.
class BoardState extends $pb.ProtobufEnum {
  static const BoardState BOARD_STATE_UNSPECIFIED =
      BoardState._(0, _omitEnumNames ? '' : 'BOARD_STATE_UNSPECIFIED');

  /// Nothing loaded yet, which is what a board reports before its first fetch.
  static const BoardState BOARD_STATE_EMPTY =
      BoardState._(1, _omitEnumNames ? '' : 'BOARD_STATE_EMPTY');
  static const BoardState BOARD_STATE_LOADING =
      BoardState._(2, _omitEnumNames ? '' : 'BOARD_STATE_LOADING');
  static const BoardState BOARD_STATE_READY =
      BoardState._(3, _omitEnumNames ? '' : 'BOARD_STATE_READY');
  static const BoardState BOARD_STATE_ERROR =
      BoardState._(4, _omitEnumNames ? '' : 'BOARD_STATE_ERROR');

  static const $core.List<BoardState> values = <BoardState>[
    BOARD_STATE_UNSPECIFIED,
    BOARD_STATE_EMPTY,
    BOARD_STATE_LOADING,
    BOARD_STATE_READY,
    BOARD_STATE_ERROR,
  ];

  static final $core.List<BoardState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static BoardState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BoardState._(super.value, super.name);
}

class SortOrder extends $pb.ProtobufEnum {
  /// Falls back to descending, which is what every leaderboard opens with.
  static const SortOrder SORT_ORDER_UNSPECIFIED =
      SortOrder._(0, _omitEnumNames ? '' : 'SORT_ORDER_UNSPECIFIED');
  static const SortOrder SORT_ORDER_ASC =
      SortOrder._(1, _omitEnumNames ? '' : 'SORT_ORDER_ASC');
  static const SortOrder SORT_ORDER_DESC =
      SortOrder._(2, _omitEnumNames ? '' : 'SORT_ORDER_DESC');

  static const $core.List<SortOrder> values = <SortOrder>[
    SORT_ORDER_UNSPECIFIED,
    SORT_ORDER_ASC,
    SORT_ORDER_DESC,
  ];

  static final $core.List<SortOrder?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SortOrder? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SortOrder._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
