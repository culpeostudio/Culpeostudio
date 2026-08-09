// This is a generated file - do not edit.
//
// Generated from culpeostudio/search/v1/search.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Category was a path segment per category, which needed one route each.
class Category extends $pb.ProtobufEnum {
  static const Category CATEGORY_UNSPECIFIED =
      Category._(0, _omitEnumNames ? '' : 'CATEGORY_UNSPECIFIED');
  static const Category CATEGORY_TEXT =
      Category._(1, _omitEnumNames ? '' : 'CATEGORY_TEXT');
  static const Category CATEGORY_NEWS =
      Category._(2, _omitEnumNames ? '' : 'CATEGORY_NEWS');
  static const Category CATEGORY_IMAGES =
      Category._(3, _omitEnumNames ? '' : 'CATEGORY_IMAGES');
  static const Category CATEGORY_VIDEOS =
      Category._(4, _omitEnumNames ? '' : 'CATEGORY_VIDEOS');
  static const Category CATEGORY_BOOKS =
      Category._(5, _omitEnumNames ? '' : 'CATEGORY_BOOKS');

  static const $core.List<Category> values = <Category>[
    CATEGORY_UNSPECIFIED,
    CATEGORY_TEXT,
    CATEGORY_NEWS,
    CATEGORY_IMAGES,
    CATEGORY_VIDEOS,
    CATEGORY_BOOKS,
  ];

  static final $core.List<Category?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static Category? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Category._(super.value, super.name);
}

class ExtractFormat extends $pb.ProtobufEnum {
  /// Resolves to TEXT_MARKDOWN, which is what the missing parameter defaulted
  /// to on the HTTP API.
  static const ExtractFormat EXTRACT_FORMAT_UNSPECIFIED =
      ExtractFormat._(0, _omitEnumNames ? '' : 'EXTRACT_FORMAT_UNSPECIFIED');
  static const ExtractFormat EXTRACT_FORMAT_TEXT =
      ExtractFormat._(1, _omitEnumNames ? '' : 'EXTRACT_FORMAT_TEXT');
  static const ExtractFormat EXTRACT_FORMAT_CONTENT =
      ExtractFormat._(2, _omitEnumNames ? '' : 'EXTRACT_FORMAT_CONTENT');
  static const ExtractFormat EXTRACT_FORMAT_TEXT_PLAIN =
      ExtractFormat._(3, _omitEnumNames ? '' : 'EXTRACT_FORMAT_TEXT_PLAIN');
  static const ExtractFormat EXTRACT_FORMAT_TEXT_RICH =
      ExtractFormat._(4, _omitEnumNames ? '' : 'EXTRACT_FORMAT_TEXT_RICH');
  static const ExtractFormat EXTRACT_FORMAT_TEXT_MARKDOWN =
      ExtractFormat._(5, _omitEnumNames ? '' : 'EXTRACT_FORMAT_TEXT_MARKDOWN');

  static const $core.List<ExtractFormat> values = <ExtractFormat>[
    EXTRACT_FORMAT_UNSPECIFIED,
    EXTRACT_FORMAT_TEXT,
    EXTRACT_FORMAT_CONTENT,
    EXTRACT_FORMAT_TEXT_PLAIN,
    EXTRACT_FORMAT_TEXT_RICH,
    EXTRACT_FORMAT_TEXT_MARKDOWN,
  ];

  static final $core.List<ExtractFormat?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ExtractFormat? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExtractFormat._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
