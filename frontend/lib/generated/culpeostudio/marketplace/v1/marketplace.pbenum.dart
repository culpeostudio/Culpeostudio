// This is a generated file - do not edit.
//
// Generated from culpeostudio/marketplace/v1/marketplace.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Provider names a model host. The HTTP API took it as a free-form string and
/// normalised aliases such as "hf" or "open-router" on every request; the enum
/// settles the value set at the schema instead. PROVIDER_ALL only makes sense
/// when searching - asking for the detail of a model without saying where it
/// lives was already an error.
class Provider extends $pb.ProtobufEnum {
  static const Provider PROVIDER_UNSPECIFIED =
      Provider._(0, _omitEnumNames ? '' : 'PROVIDER_UNSPECIFIED');
  static const Provider PROVIDER_ALL =
      Provider._(1, _omitEnumNames ? '' : 'PROVIDER_ALL');
  static const Provider PROVIDER_HUGGINGFACE =
      Provider._(2, _omitEnumNames ? '' : 'PROVIDER_HUGGINGFACE');
  static const Provider PROVIDER_OPENROUTER =
      Provider._(3, _omitEnumNames ? '' : 'PROVIDER_OPENROUTER');
  static const Provider PROVIDER_FEATHERLESS =
      Provider._(4, _omitEnumNames ? '' : 'PROVIDER_FEATHERLESS');

  static const $core.List<Provider> values = <Provider>[
    PROVIDER_UNSPECIFIED,
    PROVIDER_ALL,
    PROVIDER_HUGGINGFACE,
    PROVIDER_OPENROUTER,
    PROVIDER_FEATHERLESS,
  ];

  static final $core.List<Provider?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Provider? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Provider._(super.value, super.name);
}

/// Category filters the search by what a model is for. The HTTP API silently
/// widened an unknown category to "all"; an unknown value cannot be sent here.
class Category extends $pb.ProtobufEnum {
  /// No category filter, which is what "all" meant.
  static const Category CATEGORY_UNSPECIFIED =
      Category._(0, _omitEnumNames ? '' : 'CATEGORY_UNSPECIFIED');
  static const Category CATEGORY_CHAT =
      Category._(1, _omitEnumNames ? '' : 'CATEGORY_CHAT');
  static const Category CATEGORY_CODE =
      Category._(2, _omitEnumNames ? '' : 'CATEGORY_CODE');
  static const Category CATEGORY_REASONING =
      Category._(3, _omitEnumNames ? '' : 'CATEGORY_REASONING');
  static const Category CATEGORY_VISION =
      Category._(4, _omitEnumNames ? '' : 'CATEGORY_VISION');
  static const Category CATEGORY_EMBEDDING =
      Category._(5, _omitEnumNames ? '' : 'CATEGORY_EMBEDDING');

  static const $core.List<Category> values = <Category>[
    CATEGORY_UNSPECIFIED,
    CATEGORY_CHAT,
    CATEGORY_CODE,
    CATEGORY_REASONING,
    CATEGORY_VISION,
    CATEGORY_EMBEDDING,
  ];

  static final $core.List<Category?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static Category? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Category._(super.value, super.name);
}

/// SortMode orders the search results. The HTTP API accepted a pile of German
/// and English aliases for each mode ("neu", "newest", "neu_zuerst"); the enum
/// replaces all of them.
class SortMode extends $pb.ProtobufEnum {
  /// Falls back to SORT_MODE_POPULARITY, the default the screen opens with.
  static const SortMode SORT_MODE_UNSPECIFIED =
      SortMode._(0, _omitEnumNames ? '' : 'SORT_MODE_UNSPECIFIED');
  static const SortMode SORT_MODE_POPULARITY =
      SortMode._(1, _omitEnumNames ? '' : 'SORT_MODE_POPULARITY');
  static const SortMode SORT_MODE_INTELLIGENCE =
      SortMode._(2, _omitEnumNames ? '' : 'SORT_MODE_INTELLIGENCE');
  static const SortMode SORT_MODE_CONTEXT =
      SortMode._(3, _omitEnumNames ? '' : 'SORT_MODE_CONTEXT');
  static const SortMode SORT_MODE_NEWEST =
      SortMode._(4, _omitEnumNames ? '' : 'SORT_MODE_NEWEST');

  /// The price modes drop every model whose price is unknown, so they are only
  /// offered for the hosted providers.
  static const SortMode SORT_MODE_PRICE_LOW_HIGH =
      SortMode._(5, _omitEnumNames ? '' : 'SORT_MODE_PRICE_LOW_HIGH');
  static const SortMode SORT_MODE_PRICE_HIGH_LOW =
      SortMode._(6, _omitEnumNames ? '' : 'SORT_MODE_PRICE_HIGH_LOW');

  static const $core.List<SortMode> values = <SortMode>[
    SORT_MODE_UNSPECIFIED,
    SORT_MODE_POPULARITY,
    SORT_MODE_INTELLIGENCE,
    SORT_MODE_CONTEXT,
    SORT_MODE_NEWEST,
    SORT_MODE_PRICE_LOW_HIGH,
    SORT_MODE_PRICE_HIGH_LOW,
  ];

  static final $core.List<SortMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static SortMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SortMode._(super.value, super.name);
}

class DownloadStatus extends $pb.ProtobufEnum {
  static const DownloadStatus DOWNLOAD_STATUS_UNSPECIFIED =
      DownloadStatus._(0, _omitEnumNames ? '' : 'DOWNLOAD_STATUS_UNSPECIFIED');
  static const DownloadStatus DOWNLOAD_STATUS_QUEUED =
      DownloadStatus._(1, _omitEnumNames ? '' : 'DOWNLOAD_STATUS_QUEUED');
  static const DownloadStatus DOWNLOAD_STATUS_RUNNING =
      DownloadStatus._(2, _omitEnumNames ? '' : 'DOWNLOAD_STATUS_RUNNING');
  static const DownloadStatus DOWNLOAD_STATUS_DONE =
      DownloadStatus._(3, _omitEnumNames ? '' : 'DOWNLOAD_STATUS_DONE');
  static const DownloadStatus DOWNLOAD_STATUS_FAILED =
      DownloadStatus._(4, _omitEnumNames ? '' : 'DOWNLOAD_STATUS_FAILED');

  static const $core.List<DownloadStatus> values = <DownloadStatus>[
    DOWNLOAD_STATUS_UNSPECIFIED,
    DOWNLOAD_STATUS_QUEUED,
    DOWNLOAD_STATUS_RUNNING,
    DOWNLOAD_STATUS_DONE,
    DOWNLOAD_STATUS_FAILED,
  ];

  static final $core.List<DownloadStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static DownloadStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DownloadStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
