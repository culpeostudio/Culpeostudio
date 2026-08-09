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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'benchmark.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'benchmark.pbenum.dart';

/// Detail is one free-form fact the source published about an entry, such as the
/// number of votes behind a rating.
class Detail extends $pb.GeneratedMessage {
  factory Detail({
    $core.String? key,
    $core.String? value,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (value != null) result.value = value;
    return result;
  }

  Detail._();

  factory Detail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Detail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Detail',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Detail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Detail copyWith(void Function(Detail) updates) =>
      super.copyWith((message) => updates(message as Detail)) as Detail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Detail create() => Detail._();
  @$core.override
  Detail createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Detail getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Detail>(create);
  static Detail? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

/// Entry is one measured result: a model on a board, with its primary score and
/// whatever per-category scores the source carried.
class Entry extends $pb.GeneratedMessage {
  factory Entry({
    $core.String? board,
    $core.String? key,
    $core.String? name,
    $core.String? modelId,
    $core.String? org,
    $core.String? license,
    $core.String? url,
    $core.String? type,
    $core.bool? openWeights,
    $core.String? evalDate,
    $core.double? primary,
    $core.Iterable<$core.MapEntry<$core.String, $core.double>>? scores,
    $core.int? rank,
    $core.Iterable<Detail>? details,
  }) {
    final result = create();
    if (board != null) result.board = board;
    if (key != null) result.key = key;
    if (name != null) result.name = name;
    if (modelId != null) result.modelId = modelId;
    if (org != null) result.org = org;
    if (license != null) result.license = license;
    if (url != null) result.url = url;
    if (type != null) result.type = type;
    if (openWeights != null) result.openWeights = openWeights;
    if (evalDate != null) result.evalDate = evalDate;
    if (primary != null) result.primary = primary;
    if (scores != null) result.scores.addEntries(scores);
    if (rank != null) result.rank = rank;
    if (details != null) result.details.addAll(details);
    return result;
  }

  Entry._();

  factory Entry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Entry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Entry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'modelId')
    ..aOS(5, _omitFieldNames ? '' : 'org')
    ..aOS(6, _omitFieldNames ? '' : 'license')
    ..aOS(7, _omitFieldNames ? '' : 'url')
    ..aOS(8, _omitFieldNames ? '' : 'type')
    ..aOB(9, _omitFieldNames ? '' : 'openWeights')
    ..aOS(10, _omitFieldNames ? '' : 'evalDate')
    ..aD(11, _omitFieldNames ? '' : 'primary')
    ..m<$core.String, $core.double>(12, _omitFieldNames ? '' : 'scores',
        entryClassName: 'Entry.ScoresEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OD,
        packageName: const $pb.PackageName('culpeostudio.benchmark.v1'))
    ..aI(13, _omitFieldNames ? '' : 'rank')
    ..pPM<Detail>(14, _omitFieldNames ? '' : 'details',
        subBuilder: Detail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Entry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Entry copyWith(void Function(Entry) updates) =>
      super.copyWith((message) => updates(message as Entry)) as Entry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Entry create() => Entry._();
  @$core.override
  Entry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Entry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Entry>(create);
  static Entry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get modelId => $_getSZ(3);
  @$pb.TagNumber(4)
  set modelId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelId() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get org => $_getSZ(4);
  @$pb.TagNumber(5)
  set org($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOrg() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrg() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get license => $_getSZ(5);
  @$pb.TagNumber(6)
  set license($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLicense() => $_has(5);
  @$pb.TagNumber(6)
  void clearLicense() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get url => $_getSZ(6);
  @$pb.TagNumber(7)
  set url($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUrl() => $_has(6);
  @$pb.TagNumber(7)
  void clearUrl() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get type => $_getSZ(7);
  @$pb.TagNumber(8)
  set type($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasType() => $_has(7);
  @$pb.TagNumber(8)
  void clearType() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get openWeights => $_getBF(8);
  @$pb.TagNumber(9)
  set openWeights($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOpenWeights() => $_has(8);
  @$pb.TagNumber(9)
  void clearOpenWeights() => $_clearField(9);

  /// As published by the source, in whatever precision it used - not
  /// necessarily a full date, so it stays text.
  @$pb.TagNumber(10)
  $core.String get evalDate => $_getSZ(9);
  @$pb.TagNumber(10)
  set evalDate($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasEvalDate() => $_has(9);
  @$pb.TagNumber(10)
  void clearEvalDate() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get primary => $_getN(10);
  @$pb.TagNumber(11)
  set primary($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPrimary() => $_has(10);
  @$pb.TagNumber(11)
  void clearPrimary() => $_clearField(11);

  /// Keyed by metric key. A metric the model was never measured on is absent
  /// rather than zero.
  @$pb.TagNumber(12)
  $pb.PbMap<$core.String, $core.double> get scores => $_getMap(11);

  @$pb.TagNumber(13)
  $core.int get rank => $_getIZ(12);
  @$pb.TagNumber(13)
  set rank($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasRank() => $_has(12);
  @$pb.TagNumber(13)
  void clearRank() => $_clearField(13);

  @$pb.TagNumber(14)
  $pb.PbList<Detail> get details => $_getList(13);
}

/// MetricInfo describes one scoring category of a board. The keys are data, not
/// schema: a board declares its own set, and the client only ever looks them up.
class MetricInfo extends $pb.GeneratedMessage {
  factory MetricInfo({
    $core.String? key,
    $core.String? label,
    $core.String? family,
    $core.String? shots,
    $core.String? dataset,
    $core.String? url,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (label != null) result.label = label;
    if (family != null) result.family = family;
    if (shots != null) result.shots = shots;
    if (dataset != null) result.dataset = dataset;
    if (url != null) result.url = url;
    return result;
  }

  MetricInfo._();

  factory MetricInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MetricInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MetricInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'family')
    ..aOS(4, _omitFieldNames ? '' : 'shots')
    ..aOS(5, _omitFieldNames ? '' : 'dataset')
    ..aOS(6, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricInfo copyWith(void Function(MetricInfo) updates) =>
      super.copyWith((message) => updates(message as MetricInfo)) as MetricInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MetricInfo create() => MetricInfo._();
  @$core.override
  MetricInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MetricInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MetricInfo>(create);
  static MetricInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get family => $_getSZ(2);
  @$pb.TagNumber(3)
  set family($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFamily() => $_has(2);
  @$pb.TagNumber(3)
  void clearFamily() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get shots => $_getSZ(3);
  @$pb.TagNumber(4)
  set shots($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShots() => $_has(3);
  @$pb.TagNumber(4)
  void clearShots() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get dataset => $_getSZ(4);
  @$pb.TagNumber(5)
  set dataset($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDataset() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataset() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get url => $_getSZ(5);
  @$pb.TagNumber(6)
  set url($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearUrl() => $_clearField(6);
}

class MetricStats extends $pb.GeneratedMessage {
  factory MetricStats({
    $core.String? key,
    $core.double? min,
    $core.double? max,
    $core.double? mean,
    $core.double? median,
    $core.String? topModel,
    $core.double? topScore,
    $core.int? evaluated,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (min != null) result.min = min;
    if (max != null) result.max = max;
    if (mean != null) result.mean = mean;
    if (median != null) result.median = median;
    if (topModel != null) result.topModel = topModel;
    if (topScore != null) result.topScore = topScore;
    if (evaluated != null) result.evaluated = evaluated;
    return result;
  }

  MetricStats._();

  factory MetricStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MetricStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MetricStats',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aD(2, _omitFieldNames ? '' : 'min')
    ..aD(3, _omitFieldNames ? '' : 'max')
    ..aD(4, _omitFieldNames ? '' : 'mean')
    ..aD(5, _omitFieldNames ? '' : 'median')
    ..aOS(6, _omitFieldNames ? '' : 'topModel')
    ..aD(7, _omitFieldNames ? '' : 'topScore')
    ..aI(8, _omitFieldNames ? '' : 'evaluated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetricStats copyWith(void Function(MetricStats) updates) =>
      super.copyWith((message) => updates(message as MetricStats))
          as MetricStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MetricStats create() => MetricStats._();
  @$core.override
  MetricStats createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MetricStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MetricStats>(create);
  static MetricStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get min => $_getN(1);
  @$pb.TagNumber(2)
  set min($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMin() => $_has(1);
  @$pb.TagNumber(2)
  void clearMin() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get max => $_getN(2);
  @$pb.TagNumber(3)
  set max($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMax() => $_has(2);
  @$pb.TagNumber(3)
  void clearMax() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get mean => $_getN(3);
  @$pb.TagNumber(4)
  set mean($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMean() => $_has(3);
  @$pb.TagNumber(4)
  void clearMean() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get median => $_getN(4);
  @$pb.TagNumber(5)
  set median($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMedian() => $_has(4);
  @$pb.TagNumber(5)
  void clearMedian() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get topModel => $_getSZ(5);
  @$pb.TagNumber(6)
  set topModel($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTopModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearTopModel() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get topScore => $_getN(6);
  @$pb.TagNumber(7)
  set topScore($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTopScore() => $_has(6);
  @$pb.TagNumber(7)
  void clearTopScore() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get evaluated => $_getIZ(7);
  @$pb.TagNumber(8)
  set evaluated($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEvaluated() => $_has(7);
  @$pb.TagNumber(8)
  void clearEvaluated() => $_clearField(8);
}

class SourceInfo extends $pb.GeneratedMessage {
  factory SourceInfo({
    $core.String? provider,
    $core.String? dataset,
    $core.String? url,
    $core.bool? live,
    $core.bool? archived,
    $core.String? archivedAt,
    $core.String? publishedAt,
    $core.String? fetchedAt,
    $core.bool? fromCache,
    $core.int? entries,
    $core.int? models,
    BoardState? state,
    $core.String? error,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    if (dataset != null) result.dataset = dataset;
    if (url != null) result.url = url;
    if (live != null) result.live = live;
    if (archived != null) result.archived = archived;
    if (archivedAt != null) result.archivedAt = archivedAt;
    if (publishedAt != null) result.publishedAt = publishedAt;
    if (fetchedAt != null) result.fetchedAt = fetchedAt;
    if (fromCache != null) result.fromCache = fromCache;
    if (entries != null) result.entries = entries;
    if (models != null) result.models = models;
    if (state != null) result.state = state;
    if (error != null) result.error = error;
    return result;
  }

  SourceInfo._();

  factory SourceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SourceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SourceInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..aOS(2, _omitFieldNames ? '' : 'dataset')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..aOB(4, _omitFieldNames ? '' : 'live')
    ..aOB(5, _omitFieldNames ? '' : 'archived')
    ..aOS(6, _omitFieldNames ? '' : 'archivedAt')
    ..aOS(7, _omitFieldNames ? '' : 'publishedAt')
    ..aOS(8, _omitFieldNames ? '' : 'fetchedAt')
    ..aOB(9, _omitFieldNames ? '' : 'fromCache')
    ..aI(10, _omitFieldNames ? '' : 'entries')
    ..aI(11, _omitFieldNames ? '' : 'models')
    ..aE<BoardState>(12, _omitFieldNames ? '' : 'state',
        enumValues: BoardState.values)
    ..aOS(13, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SourceInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SourceInfo copyWith(void Function(SourceInfo) updates) =>
      super.copyWith((message) => updates(message as SourceInfo)) as SourceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SourceInfo create() => SourceInfo._();
  @$core.override
  SourceInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SourceInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SourceInfo>(create);
  static SourceInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get provider => $_getSZ(0);
  @$pb.TagNumber(1)
  set provider($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get dataset => $_getSZ(1);
  @$pb.TagNumber(2)
  set dataset($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDataset() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get live => $_getBF(3);
  @$pb.TagNumber(4)
  set live($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLive() => $_has(3);
  @$pb.TagNumber(4)
  void clearLive() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get archived => $_getBF(4);
  @$pb.TagNumber(5)
  set archived($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasArchived() => $_has(4);
  @$pb.TagNumber(5)
  void clearArchived() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get archivedAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set archivedAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasArchivedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearArchivedAt() => $_clearField(6);

  /// Published by the source; fetched_at is ours. Both stay text because the
  /// client only displays them and the source's precision varies.
  @$pb.TagNumber(7)
  $core.String get publishedAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set publishedAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPublishedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearPublishedAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get fetchedAt => $_getSZ(7);
  @$pb.TagNumber(8)
  set fetchedAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFetchedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearFetchedAt() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get fromCache => $_getBF(8);
  @$pb.TagNumber(9)
  set fromCache($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFromCache() => $_has(8);
  @$pb.TagNumber(9)
  void clearFromCache() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get entries => $_getIZ(9);
  @$pb.TagNumber(10)
  set entries($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasEntries() => $_has(9);
  @$pb.TagNumber(10)
  void clearEntries() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get models => $_getIZ(10);
  @$pb.TagNumber(11)
  set models($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasModels() => $_has(10);
  @$pb.TagNumber(11)
  void clearModels() => $_clearField(11);

  @$pb.TagNumber(12)
  BoardState get state => $_getN(11);
  @$pb.TagNumber(12)
  set state(BoardState value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasState() => $_has(11);
  @$pb.TagNumber(12)
  void clearState() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get error => $_getSZ(12);
  @$pb.TagNumber(13)
  set error($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasError() => $_has(12);
  @$pb.TagNumber(13)
  void clearError() => $_clearField(13);
}

class BoardInfo extends $pb.GeneratedMessage {
  factory BoardInfo({
    $core.String? key,
    $core.String? label,
    $core.String? kind,
    $core.String? scoreKind,
    $core.String? primaryLabel,
    $core.double? scoreMax,
    $core.Iterable<MetricInfo>? metrics,
    SourceInfo? source,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (label != null) result.label = label;
    if (kind != null) result.kind = kind;
    if (scoreKind != null) result.scoreKind = scoreKind;
    if (primaryLabel != null) result.primaryLabel = primaryLabel;
    if (scoreMax != null) result.scoreMax = scoreMax;
    if (metrics != null) result.metrics.addAll(metrics);
    if (source != null) result.source = source;
    return result;
  }

  BoardInfo._();

  factory BoardInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BoardInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BoardInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aOS(4, _omitFieldNames ? '' : 'scoreKind')
    ..aOS(5, _omitFieldNames ? '' : 'primaryLabel')
    ..aD(6, _omitFieldNames ? '' : 'scoreMax')
    ..pPM<MetricInfo>(7, _omitFieldNames ? '' : 'metrics',
        subBuilder: MetricInfo.create)
    ..aOM<SourceInfo>(8, _omitFieldNames ? '' : 'source',
        subBuilder: SourceInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoardInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoardInfo copyWith(void Function(BoardInfo) updates) =>
      super.copyWith((message) => updates(message as BoardInfo)) as BoardInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BoardInfo create() => BoardInfo._();
  @$core.override
  BoardInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BoardInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BoardInfo>(create);
  static BoardInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get scoreKind => $_getSZ(3);
  @$pb.TagNumber(4)
  set scoreKind($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasScoreKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearScoreKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get primaryLabel => $_getSZ(4);
  @$pb.TagNumber(5)
  set primaryLabel($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPrimaryLabel() => $_has(4);
  @$pb.TagNumber(5)
  void clearPrimaryLabel() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get scoreMax => $_getN(5);
  @$pb.TagNumber(6)
  set scoreMax($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasScoreMax() => $_has(5);
  @$pb.TagNumber(6)
  void clearScoreMax() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<MetricInfo> get metrics => $_getList(6);

  @$pb.TagNumber(8)
  SourceInfo get source => $_getN(7);
  @$pb.TagNumber(8)
  set source(SourceInfo value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSource() => $_has(7);
  @$pb.TagNumber(8)
  void clearSource() => $_clearField(8);
  @$pb.TagNumber(8)
  SourceInfo ensureSource() => $_ensure(7);
}

/// HubStats is what the Hugging Face hub knows about a model, looked up
/// alongside the board result.
class HubStats extends $pb.GeneratedMessage {
  factory HubStats({
    $core.String? modelId,
    $core.int? likes,
    $fixnum.Int64? downloads30d,
    $fixnum.Int64? downloadsAllTime,
    $core.double? trendingScore,
    $core.String? lastModified,
    $core.String? pipelineTag,
    $core.bool? gated,
    $fixnum.Int64? paramsTotal,
    $core.Iterable<$core.String>? tags,
    $core.Iterable<$core.String>? inferenceProviders,
    $core.bool? missing,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    if (likes != null) result.likes = likes;
    if (downloads30d != null) result.downloads30d = downloads30d;
    if (downloadsAllTime != null) result.downloadsAllTime = downloadsAllTime;
    if (trendingScore != null) result.trendingScore = trendingScore;
    if (lastModified != null) result.lastModified = lastModified;
    if (pipelineTag != null) result.pipelineTag = pipelineTag;
    if (gated != null) result.gated = gated;
    if (paramsTotal != null) result.paramsTotal = paramsTotal;
    if (tags != null) result.tags.addAll(tags);
    if (inferenceProviders != null)
      result.inferenceProviders.addAll(inferenceProviders);
    if (missing != null) result.missing = missing;
    return result;
  }

  HubStats._();

  factory HubStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HubStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HubStats',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aI(2, _omitFieldNames ? '' : 'likes')
    ..aInt64(3, _omitFieldNames ? '' : 'downloads30d',
        protoName: 'downloads_30d')
    ..aInt64(4, _omitFieldNames ? '' : 'downloadsAllTime')
    ..aD(5, _omitFieldNames ? '' : 'trendingScore')
    ..aOS(6, _omitFieldNames ? '' : 'lastModified')
    ..aOS(7, _omitFieldNames ? '' : 'pipelineTag')
    ..aOB(8, _omitFieldNames ? '' : 'gated')
    ..aInt64(9, _omitFieldNames ? '' : 'paramsTotal')
    ..pPS(10, _omitFieldNames ? '' : 'tags')
    ..pPS(11, _omitFieldNames ? '' : 'inferenceProviders')
    ..aOB(12, _omitFieldNames ? '' : 'missing')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HubStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HubStats copyWith(void Function(HubStats) updates) =>
      super.copyWith((message) => updates(message as HubStats)) as HubStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HubStats create() => HubStats._();
  @$core.override
  HubStats createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HubStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HubStats>(create);
  static HubStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get likes => $_getIZ(1);
  @$pb.TagNumber(2)
  set likes($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLikes() => $_has(1);
  @$pb.TagNumber(2)
  void clearLikes() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get downloads30d => $_getI64(2);
  @$pb.TagNumber(3)
  set downloads30d($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDownloads30d() => $_has(2);
  @$pb.TagNumber(3)
  void clearDownloads30d() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get downloadsAllTime => $_getI64(3);
  @$pb.TagNumber(4)
  set downloadsAllTime($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDownloadsAllTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearDownloadsAllTime() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get trendingScore => $_getN(4);
  @$pb.TagNumber(5)
  set trendingScore($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTrendingScore() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrendingScore() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get lastModified => $_getSZ(5);
  @$pb.TagNumber(6)
  set lastModified($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastModified() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastModified() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get pipelineTag => $_getSZ(6);
  @$pb.TagNumber(7)
  set pipelineTag($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPipelineTag() => $_has(6);
  @$pb.TagNumber(7)
  void clearPipelineTag() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get gated => $_getBF(7);
  @$pb.TagNumber(8)
  set gated($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGated() => $_has(7);
  @$pb.TagNumber(8)
  void clearGated() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get paramsTotal => $_getI64(8);
  @$pb.TagNumber(9)
  set paramsTotal($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasParamsTotal() => $_has(8);
  @$pb.TagNumber(9)
  void clearParamsTotal() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get tags => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get inferenceProviders => $_getList(10);

  /// True when the hub has no such model, which is how a detail lookup stays a
  /// valid answer instead of an error.
  @$pb.TagNumber(12)
  $core.bool get missing => $_getBF(11);
  @$pb.TagNumber(12)
  set missing($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMissing() => $_has(11);
  @$pb.TagNumber(12)
  void clearMissing() => $_clearField(12);
}

/// CardResult is a self-reported score from a model card, which is not the same
/// evidence as a board measurement and is shown apart from it.
class CardResult extends $pb.GeneratedMessage {
  factory CardResult({
    $core.String? task,
    $core.String? dataset,
    $core.String? metric,
    $core.double? value,
    $core.bool? verified,
  }) {
    final result = create();
    if (task != null) result.task = task;
    if (dataset != null) result.dataset = dataset;
    if (metric != null) result.metric = metric;
    if (value != null) result.value = value;
    if (verified != null) result.verified = verified;
    return result;
  }

  CardResult._();

  factory CardResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CardResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CardResult',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'task')
    ..aOS(2, _omitFieldNames ? '' : 'dataset')
    ..aOS(3, _omitFieldNames ? '' : 'metric')
    ..aD(4, _omitFieldNames ? '' : 'value')
    ..aOB(5, _omitFieldNames ? '' : 'verified')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardResult copyWith(void Function(CardResult) updates) =>
      super.copyWith((message) => updates(message as CardResult)) as CardResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CardResult create() => CardResult._();
  @$core.override
  CardResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CardResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CardResult>(create);
  static CardResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get task => $_getSZ(0);
  @$pb.TagNumber(1)
  set task($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTask() => $_has(0);
  @$pb.TagNumber(1)
  void clearTask() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get dataset => $_getSZ(1);
  @$pb.TagNumber(2)
  set dataset($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDataset() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get metric => $_getSZ(2);
  @$pb.TagNumber(3)
  set metric($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMetric() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetric() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get value => $_getN(3);
  @$pb.TagNumber(4)
  set value($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get verified => $_getBF(4);
  @$pb.TagNumber(5)
  set verified($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasVerified() => $_has(4);
  @$pb.TagNumber(5)
  void clearVerified() => $_clearField(5);
}

/// Delta compares one score against the board's median for that metric.
class Delta extends $pb.GeneratedMessage {
  factory Delta({
    $core.double? value,
    $core.double? median,
    $core.double? diff,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (median != null) result.median = median;
    if (diff != null) result.diff = diff;
    return result;
  }

  Delta._();

  factory Delta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Delta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Delta',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'value')
    ..aD(2, _omitFieldNames ? '' : 'median')
    ..aD(3, _omitFieldNames ? '' : 'diff')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Delta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Delta copyWith(void Function(Delta) updates) =>
      super.copyWith((message) => updates(message as Delta)) as Delta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Delta create() => Delta._();
  @$core.override
  Delta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Delta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Delta>(create);
  static Delta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get value => $_getN(0);
  @$pb.TagNumber(1)
  set value($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get median => $_getN(1);
  @$pb.TagNumber(2)
  set median($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMedian() => $_has(1);
  @$pb.TagNumber(2)
  void clearMedian() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get diff => $_getN(2);
  @$pb.TagNumber(3)
  set diff($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDiff() => $_has(2);
  @$pb.TagNumber(3)
  void clearDiff() => $_clearField(3);
}

class ModelDetail extends $pb.GeneratedMessage {
  factory ModelDetail({
    $core.String? board,
    $core.String? modelId,
    $core.String? name,
    $core.Iterable<Entry>? entries,
    Entry? best,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? metricRanks,
    $core.double? percentile,
    $core.Iterable<Entry>? peers,
    HubStats? hub,
    $core.Iterable<CardResult>? cardResults,
    $core.Iterable<$core.MapEntry<$core.String, Delta>>? deltas,
    $core.Iterable<MetricInfo>? metrics,
    SourceInfo? source,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? totals,
    $core.String? scoreKind,
  }) {
    final result = create();
    if (board != null) result.board = board;
    if (modelId != null) result.modelId = modelId;
    if (name != null) result.name = name;
    if (entries != null) result.entries.addAll(entries);
    if (best != null) result.best = best;
    if (metricRanks != null) result.metricRanks.addEntries(metricRanks);
    if (percentile != null) result.percentile = percentile;
    if (peers != null) result.peers.addAll(peers);
    if (hub != null) result.hub = hub;
    if (cardResults != null) result.cardResults.addAll(cardResults);
    if (deltas != null) result.deltas.addEntries(deltas);
    if (metrics != null) result.metrics.addAll(metrics);
    if (source != null) result.source = source;
    if (totals != null) result.totals.addEntries(totals);
    if (scoreKind != null) result.scoreKind = scoreKind;
    return result;
  }

  ModelDetail._();

  factory ModelDetail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelDetail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelDetail',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..aOS(2, _omitFieldNames ? '' : 'modelId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..pPM<Entry>(4, _omitFieldNames ? '' : 'entries', subBuilder: Entry.create)
    ..aOM<Entry>(5, _omitFieldNames ? '' : 'best', subBuilder: Entry.create)
    ..m<$core.String, $core.int>(6, _omitFieldNames ? '' : 'metricRanks',
        entryClassName: 'ModelDetail.MetricRanksEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('culpeostudio.benchmark.v1'))
    ..aD(7, _omitFieldNames ? '' : 'percentile')
    ..pPM<Entry>(8, _omitFieldNames ? '' : 'peers', subBuilder: Entry.create)
    ..aOM<HubStats>(9, _omitFieldNames ? '' : 'hub',
        subBuilder: HubStats.create)
    ..pPM<CardResult>(10, _omitFieldNames ? '' : 'cardResults',
        subBuilder: CardResult.create)
    ..m<$core.String, Delta>(11, _omitFieldNames ? '' : 'deltas',
        entryClassName: 'ModelDetail.DeltasEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: Delta.create,
        valueDefaultOrMaker: Delta.getDefault,
        packageName: const $pb.PackageName('culpeostudio.benchmark.v1'))
    ..pPM<MetricInfo>(12, _omitFieldNames ? '' : 'metrics',
        subBuilder: MetricInfo.create)
    ..aOM<SourceInfo>(13, _omitFieldNames ? '' : 'source',
        subBuilder: SourceInfo.create)
    ..m<$core.String, $core.int>(14, _omitFieldNames ? '' : 'totals',
        entryClassName: 'ModelDetail.TotalsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('culpeostudio.benchmark.v1'))
    ..aOS(15, _omitFieldNames ? '' : 'scoreKind')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelDetail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelDetail copyWith(void Function(ModelDetail) updates) =>
      super.copyWith((message) => updates(message as ModelDetail))
          as ModelDetail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelDetail create() => ModelDetail._();
  @$core.override
  ModelDetail createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelDetail getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelDetail>(create);
  static ModelDetail? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<Entry> get entries => $_getList(3);

  /// The highest-scoring of the model's entries. Absent when the board knows
  /// nothing about it and only the hub answered.
  @$pb.TagNumber(5)
  Entry get best => $_getN(4);
  @$pb.TagNumber(5)
  set best(Entry value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasBest() => $_has(4);
  @$pb.TagNumber(5)
  void clearBest() => $_clearField(5);
  @$pb.TagNumber(5)
  Entry ensureBest() => $_ensure(4);

  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.int> get metricRanks => $_getMap(5);

  @$pb.TagNumber(7)
  $core.double get percentile => $_getN(6);
  @$pb.TagNumber(7)
  set percentile($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPercentile() => $_has(6);
  @$pb.TagNumber(7)
  void clearPercentile() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<Entry> get peers => $_getList(7);

  @$pb.TagNumber(9)
  HubStats get hub => $_getN(8);
  @$pb.TagNumber(9)
  set hub(HubStats value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasHub() => $_has(8);
  @$pb.TagNumber(9)
  void clearHub() => $_clearField(9);
  @$pb.TagNumber(9)
  HubStats ensureHub() => $_ensure(8);

  @$pb.TagNumber(10)
  $pb.PbList<CardResult> get cardResults => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbMap<$core.String, Delta> get deltas => $_getMap(10);

  @$pb.TagNumber(12)
  $pb.PbList<MetricInfo> get metrics => $_getList(11);

  @$pb.TagNumber(13)
  SourceInfo get source => $_getN(12);
  @$pb.TagNumber(13)
  set source(SourceInfo value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasSource() => $_has(12);
  @$pb.TagNumber(13)
  void clearSource() => $_clearField(13);
  @$pb.TagNumber(13)
  SourceInfo ensureSource() => $_ensure(12);

  @$pb.TagNumber(14)
  $pb.PbMap<$core.String, $core.int> get totals => $_getMap(13);

  @$pb.TagNumber(15)
  $core.String get scoreKind => $_getSZ(14);
  @$pb.TagNumber(15)
  set scoreKind($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasScoreKind() => $_has(14);
  @$pb.TagNumber(15)
  void clearScoreKind() => $_clearField(15);
}

class FacetValue extends $pb.GeneratedMessage {
  factory FacetValue({
    $core.String? value,
    $core.String? label,
    $core.int? count,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (label != null) result.label = label;
    if (count != null) result.count = count;
    return result;
  }

  FacetValue._();

  factory FacetValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FacetValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FacetValue',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aI(3, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FacetValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FacetValue copyWith(void Function(FacetValue) updates) =>
      super.copyWith((message) => updates(message as FacetValue)) as FacetValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FacetValue create() => FacetValue._();
  @$core.override
  FacetValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FacetValue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FacetValue>(create);
  static FacetValue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get count => $_getIZ(2);
  @$pb.TagNumber(3)
  set count($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearCount() => $_clearField(3);
}

class Facets extends $pb.GeneratedMessage {
  factory Facets({
    $core.Iterable<FacetValue>? types,
    $core.Iterable<FacetValue>? orgs,
    $core.Iterable<FacetValue>? licenses,
  }) {
    final result = create();
    if (types != null) result.types.addAll(types);
    if (orgs != null) result.orgs.addAll(orgs);
    if (licenses != null) result.licenses.addAll(licenses);
    return result;
  }

  Facets._();

  factory Facets.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Facets.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Facets',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..pPM<FacetValue>(1, _omitFieldNames ? '' : 'types',
        subBuilder: FacetValue.create)
    ..pPM<FacetValue>(2, _omitFieldNames ? '' : 'orgs',
        subBuilder: FacetValue.create)
    ..pPM<FacetValue>(3, _omitFieldNames ? '' : 'licenses',
        subBuilder: FacetValue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Facets clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Facets copyWith(void Function(Facets) updates) =>
      super.copyWith((message) => updates(message as Facets)) as Facets;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Facets create() => Facets._();
  @$core.override
  Facets createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Facets getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Facets>(create);
  static Facets? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FacetValue> get types => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<FacetValue> get orgs => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<FacetValue> get licenses => $_getList(2);
}

/// EntryList wraps a repeated field so it can be a map value, which proto does
/// not allow directly.
class EntryList extends $pb.GeneratedMessage {
  factory EntryList({
    $core.Iterable<Entry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  EntryList._();

  factory EntryList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EntryList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntryList',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..pPM<Entry>(1, _omitFieldNames ? '' : 'entries', subBuilder: Entry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntryList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntryList copyWith(void Function(EntryList) updates) =>
      super.copyWith((message) => updates(message as EntryList)) as EntryList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EntryList create() => EntryList._();
  @$core.override
  EntryList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EntryList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EntryList>(create);
  static EntryList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Entry> get entries => $_getList(0);
}

class ListBoardsRequest extends $pb.GeneratedMessage {
  factory ListBoardsRequest() => create();

  ListBoardsRequest._();

  factory ListBoardsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBoardsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBoardsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBoardsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBoardsRequest copyWith(void Function(ListBoardsRequest) updates) =>
      super.copyWith((message) => updates(message as ListBoardsRequest))
          as ListBoardsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBoardsRequest create() => ListBoardsRequest._();
  @$core.override
  ListBoardsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBoardsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBoardsRequest>(create);
  static ListBoardsRequest? _defaultInstance;
}

class ListBoardsResponse extends $pb.GeneratedMessage {
  factory ListBoardsResponse({
    $core.Iterable<BoardInfo>? boards,
    $core.String? defaultBoard,
  }) {
    final result = create();
    if (boards != null) result.boards.addAll(boards);
    if (defaultBoard != null) result.defaultBoard = defaultBoard;
    return result;
  }

  ListBoardsResponse._();

  factory ListBoardsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBoardsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBoardsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..pPM<BoardInfo>(1, _omitFieldNames ? '' : 'boards',
        subBuilder: BoardInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'defaultBoard')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBoardsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBoardsResponse copyWith(void Function(ListBoardsResponse) updates) =>
      super.copyWith((message) => updates(message as ListBoardsResponse))
          as ListBoardsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBoardsResponse create() => ListBoardsResponse._();
  @$core.override
  ListBoardsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBoardsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBoardsResponse>(create);
  static ListBoardsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<BoardInfo> get boards => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get defaultBoard => $_getSZ(1);
  @$pb.TagNumber(2)
  set defaultBoard($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultBoard() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultBoard() => $_clearField(2);
}

/// An unknown or empty board falls back to the default one, the way the query
/// parameter did. Boards are a registry the backend owns, so the key stays a
/// string rather than an enum that would have to change with the data.
class GetStatusRequest extends $pb.GeneratedMessage {
  factory GetStatusRequest({
    $core.String? board,
  }) {
    final result = create();
    if (board != null) result.board = board;
    return result;
  }

  GetStatusRequest._();

  factory GetStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatusRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest copyWith(void Function(GetStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatusRequest))
          as GetStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusRequest create() => GetStatusRequest._();
  @$core.override
  GetStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStatusRequest>(create);
  static GetStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);
}

class GetStatusResponse extends $pb.GeneratedMessage {
  factory GetStatusResponse({
    BoardState? state,
    $core.int? loaded,
    $core.int? expected,
    $core.String? error,
    $core.bool? refreshing,
    $core.Iterable<BoardInfo>? boards,
    SourceInfo? source,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (loaded != null) result.loaded = loaded;
    if (expected != null) result.expected = expected;
    if (error != null) result.error = error;
    if (refreshing != null) result.refreshing = refreshing;
    if (boards != null) result.boards.addAll(boards);
    if (source != null) result.source = source;
    return result;
  }

  GetStatusResponse._();

  factory GetStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatusResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aE<BoardState>(1, _omitFieldNames ? '' : 'state',
        enumValues: BoardState.values)
    ..aI(2, _omitFieldNames ? '' : 'loaded')
    ..aI(3, _omitFieldNames ? '' : 'expected')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..aOB(5, _omitFieldNames ? '' : 'refreshing')
    ..pPM<BoardInfo>(6, _omitFieldNames ? '' : 'boards',
        subBuilder: BoardInfo.create)
    ..aOM<SourceInfo>(7, _omitFieldNames ? '' : 'source',
        subBuilder: SourceInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse copyWith(void Function(GetStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetStatusResponse))
          as GetStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusResponse create() => GetStatusResponse._();
  @$core.override
  GetStatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStatusResponse>(create);
  static GetStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BoardState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(BoardState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Rows read so far, against how many the snapshot announced.
  @$pb.TagNumber(2)
  $core.int get loaded => $_getIZ(1);
  @$pb.TagNumber(2)
  set loaded($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLoaded() => $_has(1);
  @$pb.TagNumber(2)
  void clearLoaded() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get expected => $_getIZ(2);
  @$pb.TagNumber(3)
  set expected($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpected() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpected() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get refreshing => $_getBF(4);
  @$pb.TagNumber(5)
  set refreshing($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRefreshing() => $_has(4);
  @$pb.TagNumber(5)
  void clearRefreshing() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<BoardInfo> get boards => $_getList(5);

  @$pb.TagNumber(7)
  SourceInfo get source => $_getN(6);
  @$pb.TagNumber(7)
  set source(SourceInfo value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSource() => $_has(6);
  @$pb.TagNumber(7)
  void clearSource() => $_clearField(7);
  @$pb.TagNumber(7)
  SourceInfo ensureSource() => $_ensure(6);
}

class GetOverviewRequest extends $pb.GeneratedMessage {
  factory GetOverviewRequest({
    $core.String? board,
  }) {
    final result = create();
    if (board != null) result.board = board;
    return result;
  }

  GetOverviewRequest._();

  factory GetOverviewRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetOverviewRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetOverviewRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOverviewRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOverviewRequest copyWith(void Function(GetOverviewRequest) updates) =>
      super.copyWith((message) => updates(message as GetOverviewRequest))
          as GetOverviewRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetOverviewRequest create() => GetOverviewRequest._();
  @$core.override
  GetOverviewRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetOverviewRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetOverviewRequest>(create);
  static GetOverviewRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);
}

class GetOverviewResponse extends $pb.GeneratedMessage {
  factory GetOverviewResponse({
    BoardInfo? board,
    $core.Iterable<BoardInfo>? boards,
    $core.int? totalEntries,
    $core.int? totalModels,
    $core.Iterable<MetricStats>? metricStats,
    $core.Iterable<Entry>? topOverall,
    $core.Iterable<$core.MapEntry<$core.String, EntryList>>? topByMetric,
    $core.Iterable<Entry>? topOpenWeights,
    $core.Iterable<$core.MapEntry<$core.String, EntryList>>? topOpenByMetric,
    $core.Iterable<FacetValue>? typeShare,
    $core.Iterable<FacetValue>? orgShare,
  }) {
    final result = create();
    if (board != null) result.board = board;
    if (boards != null) result.boards.addAll(boards);
    if (totalEntries != null) result.totalEntries = totalEntries;
    if (totalModels != null) result.totalModels = totalModels;
    if (metricStats != null) result.metricStats.addAll(metricStats);
    if (topOverall != null) result.topOverall.addAll(topOverall);
    if (topByMetric != null) result.topByMetric.addEntries(topByMetric);
    if (topOpenWeights != null) result.topOpenWeights.addAll(topOpenWeights);
    if (topOpenByMetric != null)
      result.topOpenByMetric.addEntries(topOpenByMetric);
    if (typeShare != null) result.typeShare.addAll(typeShare);
    if (orgShare != null) result.orgShare.addAll(orgShare);
    return result;
  }

  GetOverviewResponse._();

  factory GetOverviewResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetOverviewResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetOverviewResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOM<BoardInfo>(1, _omitFieldNames ? '' : 'board',
        subBuilder: BoardInfo.create)
    ..pPM<BoardInfo>(2, _omitFieldNames ? '' : 'boards',
        subBuilder: BoardInfo.create)
    ..aI(3, _omitFieldNames ? '' : 'totalEntries')
    ..aI(4, _omitFieldNames ? '' : 'totalModels')
    ..pPM<MetricStats>(5, _omitFieldNames ? '' : 'metricStats',
        subBuilder: MetricStats.create)
    ..pPM<Entry>(6, _omitFieldNames ? '' : 'topOverall',
        subBuilder: Entry.create)
    ..m<$core.String, EntryList>(7, _omitFieldNames ? '' : 'topByMetric',
        entryClassName: 'GetOverviewResponse.TopByMetricEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: EntryList.create,
        valueDefaultOrMaker: EntryList.getDefault,
        packageName: const $pb.PackageName('culpeostudio.benchmark.v1'))
    ..pPM<Entry>(8, _omitFieldNames ? '' : 'topOpenWeights',
        subBuilder: Entry.create)
    ..m<$core.String, EntryList>(9, _omitFieldNames ? '' : 'topOpenByMetric',
        entryClassName: 'GetOverviewResponse.TopOpenByMetricEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: EntryList.create,
        valueDefaultOrMaker: EntryList.getDefault,
        packageName: const $pb.PackageName('culpeostudio.benchmark.v1'))
    ..pPM<FacetValue>(10, _omitFieldNames ? '' : 'typeShare',
        subBuilder: FacetValue.create)
    ..pPM<FacetValue>(11, _omitFieldNames ? '' : 'orgShare',
        subBuilder: FacetValue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOverviewResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOverviewResponse copyWith(void Function(GetOverviewResponse) updates) =>
      super.copyWith((message) => updates(message as GetOverviewResponse))
          as GetOverviewResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetOverviewResponse create() => GetOverviewResponse._();
  @$core.override
  GetOverviewResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetOverviewResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetOverviewResponse>(create);
  static GetOverviewResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BoardInfo get board => $_getN(0);
  @$pb.TagNumber(1)
  set board(BoardInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);
  @$pb.TagNumber(1)
  BoardInfo ensureBoard() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<BoardInfo> get boards => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get totalEntries => $_getIZ(2);
  @$pb.TagNumber(3)
  set totalEntries($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalEntries() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalEntries() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get totalModels => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalModels($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalModels() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalModels() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<MetricStats> get metricStats => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<Entry> get topOverall => $_getList(5);

  /// Keyed by metric key. A metric nothing was measured on is left out.
  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, EntryList> get topByMetric => $_getMap(6);

  @$pb.TagNumber(8)
  $pb.PbList<Entry> get topOpenWeights => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbMap<$core.String, EntryList> get topOpenByMetric => $_getMap(8);

  @$pb.TagNumber(10)
  $pb.PbList<FacetValue> get typeShare => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<FacetValue> get orgShare => $_getList(10);
}

class GetLeaderboardRequest extends $pb.GeneratedMessage {
  factory GetLeaderboardRequest({
    $core.String? board,
    $core.String? query,
    $core.Iterable<$core.String>? types,
    $core.Iterable<$core.String>? orgs,
    $core.Iterable<$core.String>? licenses,
    $core.bool? openWeightsOnly,
    $core.bool? bestPerModel,
    $core.String? sort,
    SortOrder? order,
    $core.int? offset,
    $core.int? limit,
  }) {
    final result = create();
    if (board != null) result.board = board;
    if (query != null) result.query = query;
    if (types != null) result.types.addAll(types);
    if (orgs != null) result.orgs.addAll(orgs);
    if (licenses != null) result.licenses.addAll(licenses);
    if (openWeightsOnly != null) result.openWeightsOnly = openWeightsOnly;
    if (bestPerModel != null) result.bestPerModel = bestPerModel;
    if (sort != null) result.sort = sort;
    if (order != null) result.order = order;
    if (offset != null) result.offset = offset;
    if (limit != null) result.limit = limit;
    return result;
  }

  GetLeaderboardRequest._();

  factory GetLeaderboardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLeaderboardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLeaderboardRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..aOS(2, _omitFieldNames ? '' : 'query')
    ..pPS(3, _omitFieldNames ? '' : 'types')
    ..pPS(4, _omitFieldNames ? '' : 'orgs')
    ..pPS(5, _omitFieldNames ? '' : 'licenses')
    ..aOB(6, _omitFieldNames ? '' : 'openWeightsOnly')
    ..aOB(7, _omitFieldNames ? '' : 'bestPerModel')
    ..aOS(8, _omitFieldNames ? '' : 'sort')
    ..aE<SortOrder>(9, _omitFieldNames ? '' : 'order',
        enumValues: SortOrder.values)
    ..aI(10, _omitFieldNames ? '' : 'offset')
    ..aI(11, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLeaderboardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLeaderboardRequest copyWith(
          void Function(GetLeaderboardRequest) updates) =>
      super.copyWith((message) => updates(message as GetLeaderboardRequest))
          as GetLeaderboardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLeaderboardRequest create() => GetLeaderboardRequest._();
  @$core.override
  GetLeaderboardRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetLeaderboardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLeaderboardRequest>(create);
  static GetLeaderboardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);

  /// The HTTP API took these as one comma-separated parameter, which no value
  /// containing a comma survived.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get types => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get orgs => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get licenses => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get openWeightsOnly => $_getBF(5);
  @$pb.TagNumber(6)
  set openWeightsOnly($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOpenWeightsOnly() => $_has(5);
  @$pb.TagNumber(6)
  void clearOpenWeightsOnly() => $_clearField(6);

  /// Optional because it defaults to true: a plain bool could not tell "not
  /// asked for" from "explicitly off", and would silently show every duplicate
  /// entry of a model.
  @$pb.TagNumber(7)
  $core.bool get bestPerModel => $_getBF(6);
  @$pb.TagNumber(7)
  set bestPerModel($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBestPerModel() => $_has(6);
  @$pb.TagNumber(7)
  void clearBestPerModel() => $_clearField(7);

  /// A metric key, or "primary"/"average"/"name". Anything the board does not
  /// measure falls back to the primary score.
  @$pb.TagNumber(8)
  $core.String get sort => $_getSZ(7);
  @$pb.TagNumber(8)
  set sort($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSort() => $_has(7);
  @$pb.TagNumber(8)
  void clearSort() => $_clearField(8);

  @$pb.TagNumber(9)
  SortOrder get order => $_getN(8);
  @$pb.TagNumber(9)
  set order(SortOrder value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasOrder() => $_has(8);
  @$pb.TagNumber(9)
  void clearOrder() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get offset => $_getIZ(9);
  @$pb.TagNumber(10)
  set offset($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOffset() => $_has(9);
  @$pb.TagNumber(10)
  void clearOffset() => $_clearField(10);

  /// Zero means the default of 50; anything above 200 is clamped to 200.
  @$pb.TagNumber(11)
  $core.int get limit => $_getIZ(10);
  @$pb.TagNumber(11)
  set limit($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLimit() => $_has(10);
  @$pb.TagNumber(11)
  void clearLimit() => $_clearField(11);
}

class GetLeaderboardResponse extends $pb.GeneratedMessage {
  factory GetLeaderboardResponse({
    BoardInfo? board,
    $core.Iterable<Entry>? items,
    $core.int? total,
    $core.int? offset,
    $core.int? limit,
    $core.String? sort,
    SortOrder? order,
    Facets? facets,
    BoardState? warning,
  }) {
    final result = create();
    if (board != null) result.board = board;
    if (items != null) result.items.addAll(items);
    if (total != null) result.total = total;
    if (offset != null) result.offset = offset;
    if (limit != null) result.limit = limit;
    if (sort != null) result.sort = sort;
    if (order != null) result.order = order;
    if (facets != null) result.facets = facets;
    if (warning != null) result.warning = warning;
    return result;
  }

  GetLeaderboardResponse._();

  factory GetLeaderboardResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLeaderboardResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLeaderboardResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOM<BoardInfo>(1, _omitFieldNames ? '' : 'board',
        subBuilder: BoardInfo.create)
    ..pPM<Entry>(2, _omitFieldNames ? '' : 'items', subBuilder: Entry.create)
    ..aI(3, _omitFieldNames ? '' : 'total')
    ..aI(4, _omitFieldNames ? '' : 'offset')
    ..aI(5, _omitFieldNames ? '' : 'limit')
    ..aOS(6, _omitFieldNames ? '' : 'sort')
    ..aE<SortOrder>(7, _omitFieldNames ? '' : 'order',
        enumValues: SortOrder.values)
    ..aOM<Facets>(8, _omitFieldNames ? '' : 'facets', subBuilder: Facets.create)
    ..aE<BoardState>(9, _omitFieldNames ? '' : 'warning',
        enumValues: BoardState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLeaderboardResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLeaderboardResponse copyWith(
          void Function(GetLeaderboardResponse) updates) =>
      super.copyWith((message) => updates(message as GetLeaderboardResponse))
          as GetLeaderboardResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLeaderboardResponse create() => GetLeaderboardResponse._();
  @$core.override
  GetLeaderboardResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetLeaderboardResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLeaderboardResponse>(create);
  static GetLeaderboardResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BoardInfo get board => $_getN(0);
  @$pb.TagNumber(1)
  set board(BoardInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);
  @$pb.TagNumber(1)
  BoardInfo ensureBoard() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<Entry> get items => $_getList(1);

  /// Matching the filters, before pagination.
  @$pb.TagNumber(3)
  $core.int get total => $_getIZ(2);
  @$pb.TagNumber(3)
  set total($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get limit => $_getIZ(4);
  @$pb.TagNumber(5)
  set limit($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimit() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get sort => $_getSZ(5);
  @$pb.TagNumber(6)
  set sort($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSort() => $_has(5);
  @$pb.TagNumber(6)
  void clearSort() => $_clearField(6);

  @$pb.TagNumber(7)
  SortOrder get order => $_getN(6);
  @$pb.TagNumber(7)
  set order(SortOrder value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOrder() => $_has(6);
  @$pb.TagNumber(7)
  void clearOrder() => $_clearField(7);

  @$pb.TagNumber(8)
  Facets get facets => $_getN(7);
  @$pb.TagNumber(8)
  set facets(Facets value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasFacets() => $_has(7);
  @$pb.TagNumber(8)
  void clearFacets() => $_clearField(8);
  @$pb.TagNumber(8)
  Facets ensureFacets() => $_ensure(7);

  /// Set when the list was served from a board that is not ready, so the client
  /// can say why it looks thin.
  @$pb.TagNumber(9)
  BoardState get warning => $_getN(8);
  @$pb.TagNumber(9)
  set warning(BoardState value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasWarning() => $_has(8);
  @$pb.TagNumber(9)
  void clearWarning() => $_clearField(9);
}

class GetModelRequest extends $pb.GeneratedMessage {
  factory GetModelRequest({
    $core.String? board,
    $core.String? id,
    $core.bool? withHub,
  }) {
    final result = create();
    if (board != null) result.board = board;
    if (id != null) result.id = id;
    if (withHub != null) result.withHub = withHub;
    return result;
  }

  GetModelRequest._();

  factory GetModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOB(3, _omitFieldNames ? '' : 'withHub')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelRequest copyWith(void Function(GetModelRequest) updates) =>
      super.copyWith((message) => updates(message as GetModelRequest))
          as GetModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetModelRequest create() => GetModelRequest._();
  @$core.override
  GetModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModelRequest>(create);
  static GetModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  /// Optional because it defaults to true: the hub lookup is what lets a model
  /// the board never rated still resolve.
  @$pb.TagNumber(3)
  $core.bool get withHub => $_getBF(2);
  @$pb.TagNumber(3)
  set withHub($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWithHub() => $_has(2);
  @$pb.TagNumber(3)
  void clearWithHub() => $_clearField(3);
}

class GetModelResponse extends $pb.GeneratedMessage {
  factory GetModelResponse({
    ModelDetail? detail,
  }) {
    final result = create();
    if (detail != null) result.detail = detail;
    return result;
  }

  GetModelResponse._();

  factory GetModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOM<ModelDetail>(1, _omitFieldNames ? '' : 'detail',
        subBuilder: ModelDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelResponse copyWith(void Function(GetModelResponse) updates) =>
      super.copyWith((message) => updates(message as GetModelResponse))
          as GetModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetModelResponse create() => GetModelResponse._();
  @$core.override
  GetModelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModelResponse>(create);
  static GetModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ModelDetail get detail => $_getN(0);
  @$pb.TagNumber(1)
  set detail(ModelDetail value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDetail() => $_has(0);
  @$pb.TagNumber(1)
  void clearDetail() => $_clearField(1);
  @$pb.TagNumber(1)
  ModelDetail ensureDetail() => $_ensure(0);
}

class CompareModelsRequest extends $pb.GeneratedMessage {
  factory CompareModelsRequest({
    $core.String? board,
    $core.Iterable<$core.String>? ids,
    $core.bool? withHub,
  }) {
    final result = create();
    if (board != null) result.board = board;
    if (ids != null) result.ids.addAll(ids);
    if (withHub != null) result.withHub = withHub;
    return result;
  }

  CompareModelsRequest._();

  factory CompareModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompareModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompareModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..pPS(2, _omitFieldNames ? '' : 'ids')
    ..aOB(3, _omitFieldNames ? '' : 'withHub')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompareModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompareModelsRequest copyWith(void Function(CompareModelsRequest) updates) =>
      super.copyWith((message) => updates(message as CompareModelsRequest))
          as CompareModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompareModelsRequest create() => CompareModelsRequest._();
  @$core.override
  CompareModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompareModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompareModelsRequest>(create);
  static CompareModelsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);

  /// Capped at twelve; anything beyond that is dropped.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get ids => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get withHub => $_getBF(2);
  @$pb.TagNumber(3)
  set withHub($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWithHub() => $_has(2);
  @$pb.TagNumber(3)
  void clearWithHub() => $_clearField(3);
}

class CompareModelsResponse extends $pb.GeneratedMessage {
  factory CompareModelsResponse({
    $core.Iterable<ModelDetail>? models,
    BoardInfo? board,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    if (board != null) result.board = board;
    return result;
  }

  CompareModelsResponse._();

  factory CompareModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompareModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompareModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..pPM<ModelDetail>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelDetail.create)
    ..aOM<BoardInfo>(2, _omitFieldNames ? '' : 'board',
        subBuilder: BoardInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompareModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompareModelsResponse copyWith(
          void Function(CompareModelsResponse) updates) =>
      super.copyWith((message) => updates(message as CompareModelsResponse))
          as CompareModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompareModelsResponse create() => CompareModelsResponse._();
  @$core.override
  CompareModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompareModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompareModelsResponse>(create);
  static CompareModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModelDetail> get models => $_getList(0);

  @$pb.TagNumber(2)
  BoardInfo get board => $_getN(1);
  @$pb.TagNumber(2)
  set board(BoardInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBoard() => $_has(1);
  @$pb.TagNumber(2)
  void clearBoard() => $_clearField(2);
  @$pb.TagNumber(2)
  BoardInfo ensureBoard() => $_ensure(1);
}

/// An empty board refreshes every registered board.
class RefreshBoardsRequest extends $pb.GeneratedMessage {
  factory RefreshBoardsRequest({
    $core.String? board,
  }) {
    final result = create();
    if (board != null) result.board = board;
    return result;
  }

  RefreshBoardsRequest._();

  factory RefreshBoardsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshBoardsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshBoardsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'board')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshBoardsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshBoardsRequest copyWith(void Function(RefreshBoardsRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshBoardsRequest))
          as RefreshBoardsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshBoardsRequest create() => RefreshBoardsRequest._();
  @$core.override
  RefreshBoardsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshBoardsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshBoardsRequest>(create);
  static RefreshBoardsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get board => $_getSZ(0);
  @$pb.TagNumber(1)
  set board($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBoard() => $_has(0);
  @$pb.TagNumber(1)
  void clearBoard() => $_clearField(1);
}

/// The refresh runs in the background, so the response only names what was
/// started. The HTTP API said so with a 202 and a "started" flag that was never
/// anything but true.
class RefreshBoardsResponse extends $pb.GeneratedMessage {
  factory RefreshBoardsResponse({
    $core.Iterable<$core.String>? boards,
  }) {
    final result = create();
    if (boards != null) result.boards.addAll(boards);
    return result;
  }

  RefreshBoardsResponse._();

  factory RefreshBoardsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshBoardsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshBoardsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.benchmark.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'boards')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshBoardsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshBoardsResponse copyWith(
          void Function(RefreshBoardsResponse) updates) =>
      super.copyWith((message) => updates(message as RefreshBoardsResponse))
          as RefreshBoardsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshBoardsResponse create() => RefreshBoardsResponse._();
  @$core.override
  RefreshBoardsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshBoardsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshBoardsResponse>(create);
  static RefreshBoardsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get boards => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
