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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $2;

import '../../hardware/v1/hardware.pb.dart' as $1;
import 'marketplace.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'marketplace.pbenum.dart';

/// DownloadOption is one downloadable variant of a model: a single file, or a
/// set of shards that only make sense together.
class DownloadOption extends $pb.GeneratedMessage {
  factory DownloadOption({
    $core.String? label,
    $core.String? assetId,
    $core.Iterable<$core.String>? assetIds,
    $core.String? format,
    $fixnum.Int64? sizeBytes,
    $core.String? url,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (assetId != null) result.assetId = assetId;
    if (assetIds != null) result.assetIds.addAll(assetIds);
    if (format != null) result.format = format;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (url != null) result.url = url;
    return result;
  }

  DownloadOption._();

  factory DownloadOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadOption',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'assetId')
    ..pPS(3, _omitFieldNames ? '' : 'assetIds')
    ..aOS(4, _omitFieldNames ? '' : 'format')
    ..aInt64(5, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(6, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadOption copyWith(void Function(DownloadOption) updates) =>
      super.copyWith((message) => updates(message as DownloadOption))
          as DownloadOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadOption create() => DownloadOption._();
  @$core.override
  DownloadOption createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadOption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadOption>(create);
  static DownloadOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get assetId => $_getSZ(1);
  @$pb.TagNumber(2)
  set assetId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAssetId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAssetId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get assetIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get format => $_getSZ(3);
  @$pb.TagNumber(4)
  set format($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormat() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sizeBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSizeBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSizeBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get url => $_getSZ(5);
  @$pb.TagNumber(6)
  set url($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearUrl() => $_clearField(6);
}

/// ModelSummary is one search hit, enriched by the backend with what it derived
/// about the model and how it would run on the detected hardware.
class ModelSummary extends $pb.GeneratedMessage {
  factory ModelSummary({
    $core.String? id,
    Provider? provider,
    $core.String? modelId,
    $core.String? displayName,
    $core.String? name,
    $core.String? description,
    $core.String? format,
    $core.Iterable<$core.String>? formats,
    $core.Iterable<$core.String>? quantizations,
    $core.String? author,
    $fixnum.Int64? downloads,
    $fixnum.Int64? sizeBytes,
    $core.String? parameterBadge,
    $core.double? parameterCountB,
    $core.String? providerBadge,
    $core.String? category,
    $core.Iterable<$core.String>? capabilityTags,
    $core.String? pricePer1m,
    $core.double? pricePer1mInput,
    $core.double? pricePer1mOutput,
    $core.int? contextLength,
    $core.int? intelligenceScore,
    $core.double? estimatedVramGb,
    $core.bool? vramEstimated,
    $core.bool? fitsDetectedGpu,
    $core.String? runtimeFit,
    $core.Iterable<$core.String>? runtimeWarnings,
    $core.double? runtimeRamOffloadGb,
    $core.double? recommendationScore,
    $core.bool? localModel,
    $fixnum.Int64? newScore,
    $core.Iterable<DownloadOption>? downloadOptions,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (displayName != null) result.displayName = displayName;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (format != null) result.format = format;
    if (formats != null) result.formats.addAll(formats);
    if (quantizations != null) result.quantizations.addAll(quantizations);
    if (author != null) result.author = author;
    if (downloads != null) result.downloads = downloads;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (parameterBadge != null) result.parameterBadge = parameterBadge;
    if (parameterCountB != null) result.parameterCountB = parameterCountB;
    if (providerBadge != null) result.providerBadge = providerBadge;
    if (category != null) result.category = category;
    if (capabilityTags != null) result.capabilityTags.addAll(capabilityTags);
    if (pricePer1m != null) result.pricePer1m = pricePer1m;
    if (pricePer1mInput != null) result.pricePer1mInput = pricePer1mInput;
    if (pricePer1mOutput != null) result.pricePer1mOutput = pricePer1mOutput;
    if (contextLength != null) result.contextLength = contextLength;
    if (intelligenceScore != null) result.intelligenceScore = intelligenceScore;
    if (estimatedVramGb != null) result.estimatedVramGb = estimatedVramGb;
    if (vramEstimated != null) result.vramEstimated = vramEstimated;
    if (fitsDetectedGpu != null) result.fitsDetectedGpu = fitsDetectedGpu;
    if (runtimeFit != null) result.runtimeFit = runtimeFit;
    if (runtimeWarnings != null) result.runtimeWarnings.addAll(runtimeWarnings);
    if (runtimeRamOffloadGb != null)
      result.runtimeRamOffloadGb = runtimeRamOffloadGb;
    if (recommendationScore != null)
      result.recommendationScore = recommendationScore;
    if (localModel != null) result.localModel = localModel;
    if (newScore != null) result.newScore = newScore;
    if (downloadOptions != null) result.downloadOptions.addAll(downloadOptions);
    return result;
  }

  ModelSummary._();

  factory ModelSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelSummary',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<Provider>(2, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOS(3, _omitFieldNames ? '' : 'modelId')
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aOS(6, _omitFieldNames ? '' : 'description')
    ..aOS(7, _omitFieldNames ? '' : 'format')
    ..pPS(8, _omitFieldNames ? '' : 'formats')
    ..pPS(9, _omitFieldNames ? '' : 'quantizations')
    ..aOS(10, _omitFieldNames ? '' : 'author')
    ..aInt64(11, _omitFieldNames ? '' : 'downloads')
    ..aInt64(12, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(13, _omitFieldNames ? '' : 'parameterBadge')
    ..aD(14, _omitFieldNames ? '' : 'parameterCountB')
    ..aOS(15, _omitFieldNames ? '' : 'providerBadge')
    ..aOS(16, _omitFieldNames ? '' : 'category')
    ..pPS(17, _omitFieldNames ? '' : 'capabilityTags')
    ..aOS(18, _omitFieldNames ? '' : 'pricePer1m', protoName: 'price_per_1m')
    ..aD(19, _omitFieldNames ? '' : 'pricePer1mInput',
        protoName: 'price_per_1m_input')
    ..aD(20, _omitFieldNames ? '' : 'pricePer1mOutput',
        protoName: 'price_per_1m_output')
    ..aI(21, _omitFieldNames ? '' : 'contextLength')
    ..aI(22, _omitFieldNames ? '' : 'intelligenceScore')
    ..aD(23, _omitFieldNames ? '' : 'estimatedVramGb')
    ..aOB(24, _omitFieldNames ? '' : 'vramEstimated')
    ..aOB(25, _omitFieldNames ? '' : 'fitsDetectedGpu')
    ..aOS(26, _omitFieldNames ? '' : 'runtimeFit')
    ..pPS(27, _omitFieldNames ? '' : 'runtimeWarnings')
    ..aD(28, _omitFieldNames ? '' : 'runtimeRamOffloadGb')
    ..aD(29, _omitFieldNames ? '' : 'recommendationScore')
    ..aOB(30, _omitFieldNames ? '' : 'localModel')
    ..aInt64(31, _omitFieldNames ? '' : 'newScore')
    ..pPM<DownloadOption>(32, _omitFieldNames ? '' : 'downloadOptions',
        subBuilder: DownloadOption.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelSummary copyWith(void Function(ModelSummary) updates) =>
      super.copyWith((message) => updates(message as ModelSummary))
          as ModelSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelSummary create() => ModelSummary._();
  @$core.override
  ModelSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelSummary>(create);
  static ModelSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  Provider get provider => $_getN(1);
  @$pb.TagNumber(2)
  set provider(Provider value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProvider() => $_has(1);
  @$pb.TagNumber(2)
  void clearProvider() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get modelId => $_getSZ(2);
  @$pb.TagNumber(3)
  set modelId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModelId() => $_has(2);
  @$pb.TagNumber(3)
  void clearModelId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get description => $_getSZ(5);
  @$pb.TagNumber(6)
  set description($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDescription() => $_has(5);
  @$pb.TagNumber(6)
  void clearDescription() => $_clearField(6);

  /// Formats stay strings: they are inferred from the file names a repository
  /// happens to carry, so the value set is open.
  @$pb.TagNumber(7)
  $core.String get format => $_getSZ(6);
  @$pb.TagNumber(7)
  set format($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFormat() => $_has(6);
  @$pb.TagNumber(7)
  void clearFormat() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get formats => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get quantizations => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get author => $_getSZ(9);
  @$pb.TagNumber(10)
  set author($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAuthor() => $_has(9);
  @$pb.TagNumber(10)
  void clearAuthor() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get downloads => $_getI64(10);
  @$pb.TagNumber(11)
  set downloads($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDownloads() => $_has(10);
  @$pb.TagNumber(11)
  void clearDownloads() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get sizeBytes => $_getI64(11);
  @$pb.TagNumber(12)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasSizeBytes() => $_has(11);
  @$pb.TagNumber(12)
  void clearSizeBytes() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get parameterBadge => $_getSZ(12);
  @$pb.TagNumber(13)
  set parameterBadge($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasParameterBadge() => $_has(12);
  @$pb.TagNumber(13)
  void clearParameterBadge() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get parameterCountB => $_getN(13);
  @$pb.TagNumber(14)
  set parameterCountB($core.double value) => $_setDouble(13, value);
  @$pb.TagNumber(14)
  $core.bool hasParameterCountB() => $_has(13);
  @$pb.TagNumber(14)
  void clearParameterCountB() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get providerBadge => $_getSZ(14);
  @$pb.TagNumber(15)
  set providerBadge($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasProviderBadge() => $_has(14);
  @$pb.TagNumber(15)
  void clearProviderBadge() => $_clearField(15);

  /// Always one of the Category values, but carried as the derived string so a
  /// category the enrichment learns later still reaches the client.
  @$pb.TagNumber(16)
  $core.String get category => $_getSZ(15);
  @$pb.TagNumber(16)
  set category($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCategory() => $_has(15);
  @$pb.TagNumber(16)
  void clearCategory() => $_clearField(16);

  @$pb.TagNumber(17)
  $pb.PbList<$core.String> get capabilityTags => $_getList(16);

  @$pb.TagNumber(18)
  $core.String get pricePer1m => $_getSZ(17);
  @$pb.TagNumber(18)
  set pricePer1m($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasPricePer1m() => $_has(17);
  @$pb.TagNumber(18)
  void clearPricePer1m() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.double get pricePer1mInput => $_getN(18);
  @$pb.TagNumber(19)
  set pricePer1mInput($core.double value) => $_setDouble(18, value);
  @$pb.TagNumber(19)
  $core.bool hasPricePer1mInput() => $_has(18);
  @$pb.TagNumber(19)
  void clearPricePer1mInput() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.double get pricePer1mOutput => $_getN(19);
  @$pb.TagNumber(20)
  set pricePer1mOutput($core.double value) => $_setDouble(19, value);
  @$pb.TagNumber(20)
  $core.bool hasPricePer1mOutput() => $_has(19);
  @$pb.TagNumber(20)
  void clearPricePer1mOutput() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.int get contextLength => $_getIZ(20);
  @$pb.TagNumber(21)
  set contextLength($core.int value) => $_setSignedInt32(20, value);
  @$pb.TagNumber(21)
  $core.bool hasContextLength() => $_has(20);
  @$pb.TagNumber(21)
  void clearContextLength() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.int get intelligenceScore => $_getIZ(21);
  @$pb.TagNumber(22)
  set intelligenceScore($core.int value) => $_setSignedInt32(21, value);
  @$pb.TagNumber(22)
  $core.bool hasIntelligenceScore() => $_has(21);
  @$pb.TagNumber(22)
  void clearIntelligenceScore() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.double get estimatedVramGb => $_getN(22);
  @$pb.TagNumber(23)
  set estimatedVramGb($core.double value) => $_setDouble(22, value);
  @$pb.TagNumber(23)
  $core.bool hasEstimatedVramGb() => $_has(22);
  @$pb.TagNumber(23)
  void clearEstimatedVramGb() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.bool get vramEstimated => $_getBF(23);
  @$pb.TagNumber(24)
  set vramEstimated($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(24)
  $core.bool hasVramEstimated() => $_has(23);
  @$pb.TagNumber(24)
  void clearVramEstimated() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.bool get fitsDetectedGpu => $_getBF(24);
  @$pb.TagNumber(25)
  set fitsDetectedGpu($core.bool value) => $_setBool(24, value);
  @$pb.TagNumber(25)
  $core.bool hasFitsDetectedGpu() => $_has(24);
  @$pb.TagNumber(25)
  void clearFitsDetectedGpu() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.String get runtimeFit => $_getSZ(25);
  @$pb.TagNumber(26)
  set runtimeFit($core.String value) => $_setString(25, value);
  @$pb.TagNumber(26)
  $core.bool hasRuntimeFit() => $_has(25);
  @$pb.TagNumber(26)
  void clearRuntimeFit() => $_clearField(26);

  @$pb.TagNumber(27)
  $pb.PbList<$core.String> get runtimeWarnings => $_getList(26);

  @$pb.TagNumber(28)
  $core.double get runtimeRamOffloadGb => $_getN(27);
  @$pb.TagNumber(28)
  set runtimeRamOffloadGb($core.double value) => $_setDouble(27, value);
  @$pb.TagNumber(28)
  $core.bool hasRuntimeRamOffloadGb() => $_has(27);
  @$pb.TagNumber(28)
  void clearRuntimeRamOffloadGb() => $_clearField(28);

  @$pb.TagNumber(29)
  $core.double get recommendationScore => $_getN(28);
  @$pb.TagNumber(29)
  set recommendationScore($core.double value) => $_setDouble(28, value);
  @$pb.TagNumber(29)
  $core.bool hasRecommendationScore() => $_has(28);
  @$pb.TagNumber(29)
  void clearRecommendationScore() => $_clearField(29);

  @$pb.TagNumber(30)
  $core.bool get localModel => $_getBF(29);
  @$pb.TagNumber(30)
  set localModel($core.bool value) => $_setBool(29, value);
  @$pb.TagNumber(30)
  $core.bool hasLocalModel() => $_has(29);
  @$pb.TagNumber(30)
  void clearLocalModel() => $_clearField(30);

  @$pb.TagNumber(31)
  $fixnum.Int64 get newScore => $_getI64(30);
  @$pb.TagNumber(31)
  set newScore($fixnum.Int64 value) => $_setInt64(30, value);
  @$pb.TagNumber(31)
  $core.bool hasNewScore() => $_has(30);
  @$pb.TagNumber(31)
  void clearNewScore() => $_clearField(31);

  @$pb.TagNumber(32)
  $pb.PbList<DownloadOption> get downloadOptions => $_getList(31);
}

/// ModelDetail is the summary plus what only the detail lookup fetches. The Go
/// type embeds ModelSummary and the JSON flattened it; here it stays a nested
/// field and the client flattens it back for the dialog.
class ModelDetail extends $pb.GeneratedMessage {
  factory ModelDetail({
    ModelSummary? summary,
    $core.Iterable<$core.String>? tags,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? metadata,
  }) {
    final result = create();
    if (summary != null) result.summary = summary;
    if (tags != null) result.tags.addAll(tags);
    if (metadata != null) result.metadata.addEntries(metadata);
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
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOM<ModelSummary>(1, _omitFieldNames ? '' : 'summary',
        subBuilder: ModelSummary.create)
    ..pPS(2, _omitFieldNames ? '' : 'tags')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'metadata',
        entryClassName: 'ModelDetail.MetadataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('culpeostudio.marketplace.v1'))
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
  ModelSummary get summary => $_getN(0);
  @$pb.TagNumber(1)
  set summary(ModelSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSummary() => $_has(0);
  @$pb.TagNumber(1)
  void clearSummary() => $_clearField(1);
  @$pb.TagNumber(1)
  ModelSummary ensureSummary() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get tags => $_getList(1);

  /// Free-form provider notes. The JSON carried arbitrary values here, but
  /// every provider only ever sets a "source" entry naming itself, so strings
  /// are enough.
  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get metadata => $_getMap(2);
}

class SearchModelsRequest extends $pb.GeneratedMessage {
  factory SearchModelsRequest({
    Provider? provider,
    $core.String? query,
    $core.String? format,
    $core.String? quantization,
    Category? category,
    SortMode? sort,
    $core.bool? gpuFit,
    $core.bool? localOnly,
    $core.int? page,
    $core.int? pageSize,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    if (query != null) result.query = query;
    if (format != null) result.format = format;
    if (quantization != null) result.quantization = quantization;
    if (category != null) result.category = category;
    if (sort != null) result.sort = sort;
    if (gpuFit != null) result.gpuFit = gpuFit;
    if (localOnly != null) result.localOnly = localOnly;
    if (page != null) result.page = page;
    if (pageSize != null) result.pageSize = pageSize;
    return result;
  }

  SearchModelsRequest._();

  factory SearchModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aE<Provider>(1, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOS(2, _omitFieldNames ? '' : 'query')
    ..aOS(3, _omitFieldNames ? '' : 'format')
    ..aOS(4, _omitFieldNames ? '' : 'quantization')
    ..aE<Category>(5, _omitFieldNames ? '' : 'category',
        enumValues: Category.values)
    ..aE<SortMode>(6, _omitFieldNames ? '' : 'sort',
        enumValues: SortMode.values)
    ..aOB(7, _omitFieldNames ? '' : 'gpuFit')
    ..aOB(8, _omitFieldNames ? '' : 'localOnly')
    ..aI(9, _omitFieldNames ? '' : 'page')
    ..aI(10, _omitFieldNames ? '' : 'pageSize')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchModelsRequest copyWith(void Function(SearchModelsRequest) updates) =>
      super.copyWith((message) => updates(message as SearchModelsRequest))
          as SearchModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchModelsRequest create() => SearchModelsRequest._();
  @$core.override
  SearchModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchModelsRequest>(create);
  static SearchModelsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Provider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(Provider value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get format => $_getSZ(2);
  @$pb.TagNumber(3)
  set format($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFormat() => $_has(2);
  @$pb.TagNumber(3)
  void clearFormat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get quantization => $_getSZ(3);
  @$pb.TagNumber(4)
  set quantization($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQuantization() => $_has(3);
  @$pb.TagNumber(4)
  void clearQuantization() => $_clearField(4);

  @$pb.TagNumber(5)
  Category get category => $_getN(4);
  @$pb.TagNumber(5)
  set category(Category value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCategory() => $_has(4);
  @$pb.TagNumber(5)
  void clearCategory() => $_clearField(5);

  @$pb.TagNumber(6)
  SortMode get sort => $_getN(5);
  @$pb.TagNumber(6)
  set sort(SortMode value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSort() => $_has(5);
  @$pb.TagNumber(6)
  void clearSort() => $_clearField(6);

  /// Both are HuggingFace-only, as is quantization: the hosted providers serve
  /// models over an API, so there is nothing to fit into local VRAM.
  @$pb.TagNumber(7)
  $core.bool get gpuFit => $_getBF(6);
  @$pb.TagNumber(7)
  set gpuFit($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasGpuFit() => $_has(6);
  @$pb.TagNumber(7)
  void clearGpuFit() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get localOnly => $_getBF(7);
  @$pb.TagNumber(8)
  set localOnly($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLocalOnly() => $_has(7);
  @$pb.TagNumber(8)
  void clearLocalOnly() => $_clearField(8);

  /// One-based. Zero means the first page, which is what an omitted page did.
  @$pb.TagNumber(9)
  $core.int get page => $_getIZ(8);
  @$pb.TagNumber(9)
  set page($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPage() => $_has(8);
  @$pb.TagNumber(9)
  void clearPage() => $_clearField(9);

  /// Zero means the default of 20; anything above 1000 is clamped to 1000.
  @$pb.TagNumber(10)
  $core.int get pageSize => $_getIZ(9);
  @$pb.TagNumber(10)
  set pageSize($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPageSize() => $_has(9);
  @$pb.TagNumber(10)
  void clearPageSize() => $_clearField(10);
}

class SearchModelsResponse extends $pb.GeneratedMessage {
  factory SearchModelsResponse({
    $core.Iterable<ModelSummary>? models,
    $core.int? total,
    $core.int? returned,
    $core.bool? partial,
    $core.Iterable<$core.String>? errors,
    $core.int? page,
    $core.int? pageSize,
    $core.bool? hasMore,
    $1.HardwareProfile? hardware,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    if (total != null) result.total = total;
    if (returned != null) result.returned = returned;
    if (partial != null) result.partial = partial;
    if (errors != null) result.errors.addAll(errors);
    if (page != null) result.page = page;
    if (pageSize != null) result.pageSize = pageSize;
    if (hasMore != null) result.hasMore = hasMore;
    if (hardware != null) result.hardware = hardware;
    return result;
  }

  SearchModelsResponse._();

  factory SearchModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..pPM<ModelSummary>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelSummary.create)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..aI(3, _omitFieldNames ? '' : 'returned')
    ..aOB(4, _omitFieldNames ? '' : 'partial')
    ..pPS(5, _omitFieldNames ? '' : 'errors')
    ..aI(6, _omitFieldNames ? '' : 'page')
    ..aI(7, _omitFieldNames ? '' : 'pageSize')
    ..aOB(8, _omitFieldNames ? '' : 'hasMore')
    ..aOM<$1.HardwareProfile>(9, _omitFieldNames ? '' : 'hardware',
        subBuilder: $1.HardwareProfile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchModelsResponse copyWith(void Function(SearchModelsResponse) updates) =>
      super.copyWith((message) => updates(message as SearchModelsResponse))
          as SearchModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchModelsResponse create() => SearchModelsResponse._();
  @$core.override
  SearchModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchModelsResponse>(create);
  static SearchModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModelSummary> get models => $_getList(0);

  /// Across all pages, before pagination.
  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get returned => $_getIZ(2);
  @$pb.TagNumber(3)
  set returned($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReturned() => $_has(2);
  @$pb.TagNumber(3)
  void clearReturned() => $_clearField(3);

  /// True when at least one provider failed; the hits of the others are still
  /// in models, and errors says who was left out.
  @$pb.TagNumber(4)
  $core.bool get partial => $_getBF(3);
  @$pb.TagNumber(4)
  set partial($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPartial() => $_has(3);
  @$pb.TagNumber(4)
  void clearPartial() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get errors => $_getList(4);

  @$pb.TagNumber(6)
  $core.int get page => $_getIZ(5);
  @$pb.TagNumber(6)
  set page($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPage() => $_has(5);
  @$pb.TagNumber(6)
  void clearPage() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get pageSize => $_getIZ(6);
  @$pb.TagNumber(7)
  set pageSize($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPageSize() => $_has(6);
  @$pb.TagNumber(7)
  void clearPageSize() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get hasMore => $_getBF(7);
  @$pb.TagNumber(8)
  set hasMore($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHasMore() => $_has(7);
  @$pb.TagNumber(8)
  void clearHasMore() => $_clearField(8);

  /// The profile the fit flags on every model were computed against.
  @$pb.TagNumber(9)
  $1.HardwareProfile get hardware => $_getN(8);
  @$pb.TagNumber(9)
  set hardware($1.HardwareProfile value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasHardware() => $_has(8);
  @$pb.TagNumber(9)
  void clearHardware() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.HardwareProfile ensureHardware() => $_ensure(8);
}

class GetModelDetailRequest extends $pb.GeneratedMessage {
  factory GetModelDetailRequest({
    Provider? provider,
    $core.String? id,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    if (id != null) result.id = id;
    return result;
  }

  GetModelDetailRequest._();

  factory GetModelDetailRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetModelDetailRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModelDetailRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aE<Provider>(1, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelDetailRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelDetailRequest copyWith(
          void Function(GetModelDetailRequest) updates) =>
      super.copyWith((message) => updates(message as GetModelDetailRequest))
          as GetModelDetailRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetModelDetailRequest create() => GetModelDetailRequest._();
  @$core.override
  GetModelDetailRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetModelDetailRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModelDetailRequest>(create);
  static GetModelDetailRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Provider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(Provider value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);
}

class GetModelDetailResponse extends $pb.GeneratedMessage {
  factory GetModelDetailResponse({
    ModelDetail? detail,
  }) {
    final result = create();
    if (detail != null) result.detail = detail;
    return result;
  }

  GetModelDetailResponse._();

  factory GetModelDetailResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetModelDetailResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModelDetailResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOM<ModelDetail>(1, _omitFieldNames ? '' : 'detail',
        subBuilder: ModelDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelDetailResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelDetailResponse copyWith(
          void Function(GetModelDetailResponse) updates) =>
      super.copyWith((message) => updates(message as GetModelDetailResponse))
          as GetModelDetailResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetModelDetailResponse create() => GetModelDetailResponse._();
  @$core.override
  GetModelDetailResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetModelDetailResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModelDetailResponse>(create);
  static GetModelDetailResponse? _defaultInstance;

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

class GetHardwareProfileRequest extends $pb.GeneratedMessage {
  factory GetHardwareProfileRequest() => create();

  GetHardwareProfileRequest._();

  factory GetHardwareProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHardwareProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHardwareProfileRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHardwareProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHardwareProfileRequest copyWith(
          void Function(GetHardwareProfileRequest) updates) =>
      super.copyWith((message) => updates(message as GetHardwareProfileRequest))
          as GetHardwareProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHardwareProfileRequest create() => GetHardwareProfileRequest._();
  @$core.override
  GetHardwareProfileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetHardwareProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHardwareProfileRequest>(create);
  static GetHardwareProfileRequest? _defaultInstance;
}

class GetHardwareProfileResponse extends $pb.GeneratedMessage {
  factory GetHardwareProfileResponse({
    $1.HardwareProfile? profile,
  }) {
    final result = create();
    if (profile != null) result.profile = profile;
    return result;
  }

  GetHardwareProfileResponse._();

  factory GetHardwareProfileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHardwareProfileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHardwareProfileResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOM<$1.HardwareProfile>(1, _omitFieldNames ? '' : 'profile',
        subBuilder: $1.HardwareProfile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHardwareProfileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHardwareProfileResponse copyWith(
          void Function(GetHardwareProfileResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetHardwareProfileResponse))
          as GetHardwareProfileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHardwareProfileResponse create() => GetHardwareProfileResponse._();
  @$core.override
  GetHardwareProfileResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetHardwareProfileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHardwareProfileResponse>(create);
  static GetHardwareProfileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $1.HardwareProfile get profile => $_getN(0);
  @$pb.TagNumber(1)
  set profile($1.HardwareProfile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProfile() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfile() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.HardwareProfile ensureProfile() => $_ensure(0);
}

class StartDownloadRequest extends $pb.GeneratedMessage {
  factory StartDownloadRequest({
    Provider? provider,
    $core.String? modelId,
    $core.String? assetId,
    $core.Iterable<$core.String>? assetIds,
    $core.String? revision,
    $core.String? targetDir,
    $fixnum.Int64? sizeBytes,
    $core.String? nodeId,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (assetId != null) result.assetId = assetId;
    if (assetIds != null) result.assetIds.addAll(assetIds);
    if (revision != null) result.revision = revision;
    if (targetDir != null) result.targetDir = targetDir;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (nodeId != null) result.nodeId = nodeId;
    return result;
  }

  StartDownloadRequest._();

  factory StartDownloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartDownloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartDownloadRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aE<Provider>(1, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOS(2, _omitFieldNames ? '' : 'modelId')
    ..aOS(3, _omitFieldNames ? '' : 'assetId')
    ..pPS(4, _omitFieldNames ? '' : 'assetIds')
    ..aOS(5, _omitFieldNames ? '' : 'revision')
    ..aOS(6, _omitFieldNames ? '' : 'targetDir')
    ..aInt64(7, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(8, _omitFieldNames ? '' : 'nodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDownloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDownloadRequest copyWith(void Function(StartDownloadRequest) updates) =>
      super.copyWith((message) => updates(message as StartDownloadRequest))
          as StartDownloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartDownloadRequest create() => StartDownloadRequest._();
  @$core.override
  StartDownloadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartDownloadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartDownloadRequest>(create);
  static StartDownloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Provider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(Provider value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get assetId => $_getSZ(2);
  @$pb.TagNumber(3)
  set assetId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAssetId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAssetId() => $_clearField(3);

  /// A bundle of shards to fetch together. When empty, asset_id is used alone.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get assetIds => $_getList(3);

  /// Defaults to "main".
  @$pb.TagNumber(5)
  $core.String get revision => $_getSZ(4);
  @$pb.TagNumber(5)
  set revision($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRevision() => $_has(4);
  @$pb.TagNumber(5)
  void clearRevision() => $_clearField(5);

  /// Relative to the configured model directory, or absolute inside it. Empty
  /// means the model directory itself.
  @$pb.TagNumber(6)
  $core.String get targetDir => $_getSZ(5);
  @$pb.TagNumber(6)
  set targetDir($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTargetDir() => $_has(5);
  @$pb.TagNumber(6)
  void clearTargetDir() => $_clearField(6);

  /// What the client expects to download. When set, the backend refuses the job
  /// up front if the disk cannot hold it plus a ten percent margin.
  @$pb.TagNumber(7)
  $fixnum.Int64 get sizeBytes => $_getI64(6);
  @$pb.TagNumber(7)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSizeBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearSizeBytes() => $_clearField(7);

  /// Which machine fetches the model. Empty means this one. A node id sends the
  /// job to that node, which downloads from the model host itself - the weights
  /// never travel through the Studio, because a model of tens of gigabytes
  /// would arrive twice as slowly for no reason.
  @$pb.TagNumber(8)
  $core.String get nodeId => $_getSZ(7);
  @$pb.TagNumber(8)
  set nodeId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNodeId() => $_has(7);
  @$pb.TagNumber(8)
  void clearNodeId() => $_clearField(8);
}

class StartDownloadResponse extends $pb.GeneratedMessage {
  factory StartDownloadResponse({
    $core.String? jobId,
    DownloadStatus? status,
    $core.bool? existing,
    $core.String? targetDir,
  }) {
    final result = create();
    if (jobId != null) result.jobId = jobId;
    if (status != null) result.status = status;
    if (existing != null) result.existing = existing;
    if (targetDir != null) result.targetDir = targetDir;
    return result;
  }

  StartDownloadResponse._();

  factory StartDownloadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartDownloadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartDownloadResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jobId')
    ..aE<DownloadStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: DownloadStatus.values)
    ..aOB(3, _omitFieldNames ? '' : 'existing')
    ..aOS(4, _omitFieldNames ? '' : 'targetDir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDownloadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDownloadResponse copyWith(
          void Function(StartDownloadResponse) updates) =>
      super.copyWith((message) => updates(message as StartDownloadResponse))
          as StartDownloadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartDownloadResponse create() => StartDownloadResponse._();
  @$core.override
  StartDownloadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartDownloadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartDownloadResponse>(create);
  static StartDownloadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jobId => $_getSZ(0);
  @$pb.TagNumber(1)
  set jobId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJobId() => $_has(0);
  @$pb.TagNumber(1)
  void clearJobId() => $_clearField(1);

  @$pb.TagNumber(2)
  DownloadStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(DownloadStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  /// True when the model was already downloading and job_id names that job
  /// rather than a new one.
  @$pb.TagNumber(3)
  $core.bool get existing => $_getBF(2);
  @$pb.TagNumber(3)
  set existing($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExisting() => $_has(2);
  @$pb.TagNumber(3)
  void clearExisting() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get targetDir => $_getSZ(3);
  @$pb.TagNumber(4)
  set targetDir($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTargetDir() => $_has(3);
  @$pb.TagNumber(4)
  void clearTargetDir() => $_clearField(4);
}

class DownloadJob extends $pb.GeneratedMessage {
  factory DownloadJob({
    $core.String? id,
    Provider? provider,
    $core.String? modelId,
    $core.String? assetId,
    $core.Iterable<$core.String>? assetIds,
    $core.String? revision,
    $core.String? commitSha,
    $core.String? targetDir,
    DownloadStatus? status,
    $core.int? progress,
    $core.String? error,
    $core.String? outputPath,
    $2.Timestamp? createdAt,
    $2.Timestamp? updatedAt,
    $2.Timestamp? startedAt,
    $2.Timestamp? finishedAt,
    $fixnum.Int64? downloadedBytes,
    $fixnum.Int64? speedBytesPerSec,
    $fixnum.Int64? totalBytes,
    $core.String? nodeId,
    $core.String? nodeName,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (assetId != null) result.assetId = assetId;
    if (assetIds != null) result.assetIds.addAll(assetIds);
    if (revision != null) result.revision = revision;
    if (commitSha != null) result.commitSha = commitSha;
    if (targetDir != null) result.targetDir = targetDir;
    if (status != null) result.status = status;
    if (progress != null) result.progress = progress;
    if (error != null) result.error = error;
    if (outputPath != null) result.outputPath = outputPath;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (startedAt != null) result.startedAt = startedAt;
    if (finishedAt != null) result.finishedAt = finishedAt;
    if (downloadedBytes != null) result.downloadedBytes = downloadedBytes;
    if (speedBytesPerSec != null) result.speedBytesPerSec = speedBytesPerSec;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (nodeId != null) result.nodeId = nodeId;
    if (nodeName != null) result.nodeName = nodeName;
    return result;
  }

  DownloadJob._();

  factory DownloadJob.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadJob.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadJob',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<Provider>(2, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOS(3, _omitFieldNames ? '' : 'modelId')
    ..aOS(4, _omitFieldNames ? '' : 'assetId')
    ..pPS(5, _omitFieldNames ? '' : 'assetIds')
    ..aOS(6, _omitFieldNames ? '' : 'revision')
    ..aOS(7, _omitFieldNames ? '' : 'commitSha')
    ..aOS(8, _omitFieldNames ? '' : 'targetDir')
    ..aE<DownloadStatus>(9, _omitFieldNames ? '' : 'status',
        enumValues: DownloadStatus.values)
    ..aI(10, _omitFieldNames ? '' : 'progress')
    ..aOS(11, _omitFieldNames ? '' : 'error')
    ..aOS(12, _omitFieldNames ? '' : 'outputPath')
    ..aOM<$2.Timestamp>(13, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(14, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(15, _omitFieldNames ? '' : 'startedAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(16, _omitFieldNames ? '' : 'finishedAt',
        subBuilder: $2.Timestamp.create)
    ..aInt64(17, _omitFieldNames ? '' : 'downloadedBytes')
    ..aInt64(18, _omitFieldNames ? '' : 'speedBytesPerSec')
    ..aInt64(19, _omitFieldNames ? '' : 'totalBytes')
    ..aOS(20, _omitFieldNames ? '' : 'nodeId')
    ..aOS(21, _omitFieldNames ? '' : 'nodeName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadJob clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadJob copyWith(void Function(DownloadJob) updates) =>
      super.copyWith((message) => updates(message as DownloadJob))
          as DownloadJob;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadJob create() => DownloadJob._();
  @$core.override
  DownloadJob createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadJob getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadJob>(create);
  static DownloadJob? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  Provider get provider => $_getN(1);
  @$pb.TagNumber(2)
  set provider(Provider value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProvider() => $_has(1);
  @$pb.TagNumber(2)
  void clearProvider() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get modelId => $_getSZ(2);
  @$pb.TagNumber(3)
  set modelId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModelId() => $_has(2);
  @$pb.TagNumber(3)
  void clearModelId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get assetId => $_getSZ(3);
  @$pb.TagNumber(4)
  set assetId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAssetId() => $_has(3);
  @$pb.TagNumber(4)
  void clearAssetId() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get assetIds => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get revision => $_getSZ(5);
  @$pb.TagNumber(6)
  set revision($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRevision() => $_has(5);
  @$pb.TagNumber(6)
  void clearRevision() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get commitSha => $_getSZ(6);
  @$pb.TagNumber(7)
  set commitSha($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCommitSha() => $_has(6);
  @$pb.TagNumber(7)
  void clearCommitSha() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get targetDir => $_getSZ(7);
  @$pb.TagNumber(8)
  set targetDir($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTargetDir() => $_has(7);
  @$pb.TagNumber(8)
  void clearTargetDir() => $_clearField(8);

  @$pb.TagNumber(9)
  DownloadStatus get status => $_getN(8);
  @$pb.TagNumber(9)
  set status(DownloadStatus value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasStatus() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatus() => $_clearField(9);

  /// Percent, 0 to 100.
  @$pb.TagNumber(10)
  $core.int get progress => $_getIZ(9);
  @$pb.TagNumber(10)
  set progress($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasProgress() => $_has(9);
  @$pb.TagNumber(10)
  void clearProgress() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get error => $_getSZ(10);
  @$pb.TagNumber(11)
  set error($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasError() => $_has(10);
  @$pb.TagNumber(11)
  void clearError() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get outputPath => $_getSZ(11);
  @$pb.TagNumber(12)
  set outputPath($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasOutputPath() => $_has(11);
  @$pb.TagNumber(12)
  void clearOutputPath() => $_clearField(12);

  @$pb.TagNumber(13)
  $2.Timestamp get createdAt => $_getN(12);
  @$pb.TagNumber(13)
  set createdAt($2.Timestamp value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasCreatedAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearCreatedAt() => $_clearField(13);
  @$pb.TagNumber(13)
  $2.Timestamp ensureCreatedAt() => $_ensure(12);

  @$pb.TagNumber(14)
  $2.Timestamp get updatedAt => $_getN(13);
  @$pb.TagNumber(14)
  set updatedAt($2.Timestamp value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasUpdatedAt() => $_has(13);
  @$pb.TagNumber(14)
  void clearUpdatedAt() => $_clearField(14);
  @$pb.TagNumber(14)
  $2.Timestamp ensureUpdatedAt() => $_ensure(13);

  @$pb.TagNumber(15)
  $2.Timestamp get startedAt => $_getN(14);
  @$pb.TagNumber(15)
  set startedAt($2.Timestamp value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasStartedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearStartedAt() => $_clearField(15);
  @$pb.TagNumber(15)
  $2.Timestamp ensureStartedAt() => $_ensure(14);

  @$pb.TagNumber(16)
  $2.Timestamp get finishedAt => $_getN(15);
  @$pb.TagNumber(16)
  set finishedAt($2.Timestamp value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasFinishedAt() => $_has(15);
  @$pb.TagNumber(16)
  void clearFinishedAt() => $_clearField(16);
  @$pb.TagNumber(16)
  $2.Timestamp ensureFinishedAt() => $_ensure(15);

  @$pb.TagNumber(17)
  $fixnum.Int64 get downloadedBytes => $_getI64(16);
  @$pb.TagNumber(17)
  set downloadedBytes($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDownloadedBytes() => $_has(16);
  @$pb.TagNumber(17)
  void clearDownloadedBytes() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get speedBytesPerSec => $_getI64(17);
  @$pb.TagNumber(18)
  set speedBytesPerSec($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasSpeedBytesPerSec() => $_has(17);
  @$pb.TagNumber(18)
  void clearSpeedBytesPerSec() => $_clearField(18);

  @$pb.TagNumber(19)
  $fixnum.Int64 get totalBytes => $_getI64(18);
  @$pb.TagNumber(19)
  set totalBytes($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(19)
  $core.bool hasTotalBytes() => $_has(18);
  @$pb.TagNumber(19)
  void clearTotalBytes() => $_clearField(19);

  /// Empty for a job on this machine. On a node job the id is qualified with
  /// the node it belongs to, so the calls that act on a job route themselves.
  @$pb.TagNumber(20)
  $core.String get nodeId => $_getSZ(19);
  @$pb.TagNumber(20)
  set nodeId($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasNodeId() => $_has(19);
  @$pb.TagNumber(20)
  void clearNodeId() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get nodeName => $_getSZ(20);
  @$pb.TagNumber(21)
  set nodeName($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasNodeName() => $_has(20);
  @$pb.TagNumber(21)
  void clearNodeName() => $_clearField(21);
}

class ListDownloadJobsRequest extends $pb.GeneratedMessage {
  factory ListDownloadJobsRequest() => create();

  ListDownloadJobsRequest._();

  factory ListDownloadJobsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDownloadJobsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDownloadJobsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDownloadJobsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDownloadJobsRequest copyWith(
          void Function(ListDownloadJobsRequest) updates) =>
      super.copyWith((message) => updates(message as ListDownloadJobsRequest))
          as ListDownloadJobsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDownloadJobsRequest create() => ListDownloadJobsRequest._();
  @$core.override
  ListDownloadJobsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDownloadJobsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDownloadJobsRequest>(create);
  static ListDownloadJobsRequest? _defaultInstance;
}

class ListDownloadJobsResponse extends $pb.GeneratedMessage {
  factory ListDownloadJobsResponse({
    $core.Iterable<DownloadJob>? jobs,
  }) {
    final result = create();
    if (jobs != null) result.jobs.addAll(jobs);
    return result;
  }

  ListDownloadJobsResponse._();

  factory ListDownloadJobsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDownloadJobsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDownloadJobsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..pPM<DownloadJob>(1, _omitFieldNames ? '' : 'jobs',
        subBuilder: DownloadJob.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDownloadJobsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDownloadJobsResponse copyWith(
          void Function(ListDownloadJobsResponse) updates) =>
      super.copyWith((message) => updates(message as ListDownloadJobsResponse))
          as ListDownloadJobsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDownloadJobsResponse create() => ListDownloadJobsResponse._();
  @$core.override
  ListDownloadJobsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDownloadJobsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDownloadJobsResponse>(create);
  static ListDownloadJobsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DownloadJob> get jobs => $_getList(0);
}

class GetDownloadJobRequest extends $pb.GeneratedMessage {
  factory GetDownloadJobRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetDownloadJobRequest._();

  factory GetDownloadJobRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetDownloadJobRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDownloadJobRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDownloadJobRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDownloadJobRequest copyWith(
          void Function(GetDownloadJobRequest) updates) =>
      super.copyWith((message) => updates(message as GetDownloadJobRequest))
          as GetDownloadJobRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDownloadJobRequest create() => GetDownloadJobRequest._();
  @$core.override
  GetDownloadJobRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetDownloadJobRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDownloadJobRequest>(create);
  static GetDownloadJobRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class GetDownloadJobResponse extends $pb.GeneratedMessage {
  factory GetDownloadJobResponse({
    DownloadJob? job,
  }) {
    final result = create();
    if (job != null) result.job = job;
    return result;
  }

  GetDownloadJobResponse._();

  factory GetDownloadJobResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetDownloadJobResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDownloadJobResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOM<DownloadJob>(1, _omitFieldNames ? '' : 'job',
        subBuilder: DownloadJob.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDownloadJobResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDownloadJobResponse copyWith(
          void Function(GetDownloadJobResponse) updates) =>
      super.copyWith((message) => updates(message as GetDownloadJobResponse))
          as GetDownloadJobResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDownloadJobResponse create() => GetDownloadJobResponse._();
  @$core.override
  GetDownloadJobResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetDownloadJobResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDownloadJobResponse>(create);
  static GetDownloadJobResponse? _defaultInstance;

  @$pb.TagNumber(1)
  DownloadJob get job => $_getN(0);
  @$pb.TagNumber(1)
  set job(DownloadJob value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasJob() => $_has(0);
  @$pb.TagNumber(1)
  void clearJob() => $_clearField(1);
  @$pb.TagNumber(1)
  DownloadJob ensureJob() => $_ensure(0);
}

class DeleteDownloadJobRequest extends $pb.GeneratedMessage {
  factory DeleteDownloadJobRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteDownloadJobRequest._();

  factory DeleteDownloadJobRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteDownloadJobRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteDownloadJobRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDownloadJobRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDownloadJobRequest copyWith(
          void Function(DeleteDownloadJobRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteDownloadJobRequest))
          as DeleteDownloadJobRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteDownloadJobRequest create() => DeleteDownloadJobRequest._();
  @$core.override
  DeleteDownloadJobRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteDownloadJobRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteDownloadJobRequest>(create);
  static DeleteDownloadJobRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeleteDownloadJobResponse extends $pb.GeneratedMessage {
  factory DeleteDownloadJobResponse() => create();

  DeleteDownloadJobResponse._();

  factory DeleteDownloadJobResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteDownloadJobResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteDownloadJobResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDownloadJobResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDownloadJobResponse copyWith(
          void Function(DeleteDownloadJobResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteDownloadJobResponse))
          as DeleteDownloadJobResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteDownloadJobResponse create() => DeleteDownloadJobResponse._();
  @$core.override
  DeleteDownloadJobResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteDownloadJobResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteDownloadJobResponse>(create);
  static DeleteDownloadJobResponse? _defaultInstance;
}

/// ActiveApiModel is a hosted model the user activated for chat.
class ActiveApiModel extends $pb.GeneratedMessage {
  factory ActiveApiModel({
    Provider? provider,
    $core.String? modelId,
    $core.String? displayName,
    $core.String? modelRef,
    $2.Timestamp? startedAt,
    $2.Timestamp? lastUsedAt,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (displayName != null) result.displayName = displayName;
    if (modelRef != null) result.modelRef = modelRef;
    if (startedAt != null) result.startedAt = startedAt;
    if (lastUsedAt != null) result.lastUsedAt = lastUsedAt;
    return result;
  }

  ActiveApiModel._();

  factory ActiveApiModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActiveApiModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveApiModel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aE<Provider>(1, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOS(2, _omitFieldNames ? '' : 'modelId')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOS(4, _omitFieldNames ? '' : 'modelRef')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'startedAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'lastUsedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveApiModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveApiModel copyWith(void Function(ActiveApiModel) updates) =>
      super.copyWith((message) => updates(message as ActiveApiModel))
          as ActiveApiModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActiveApiModel create() => ActiveApiModel._();
  @$core.override
  ActiveApiModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActiveApiModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActiveApiModel>(create);
  static ActiveApiModel? _defaultInstance;

  @$pb.TagNumber(1)
  Provider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(Provider value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  /// Stable handle the chat binds to, derived from provider and model id.
  @$pb.TagNumber(4)
  $core.String get modelRef => $_getSZ(3);
  @$pb.TagNumber(4)
  set modelRef($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelRef() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelRef() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get startedAt => $_getN(4);
  @$pb.TagNumber(5)
  set startedAt($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasStartedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearStartedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureStartedAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $2.Timestamp get lastUsedAt => $_getN(5);
  @$pb.TagNumber(6)
  set lastUsedAt($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLastUsedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastUsedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureLastUsedAt() => $_ensure(5);
}

/// Only the hosted providers can be started: a HuggingFace repository is
/// downloaded and run by the engine, not called over an API.
class StartApiModelRequest extends $pb.GeneratedMessage {
  factory StartApiModelRequest({
    Provider? provider,
    $core.String? modelId,
    $core.String? displayName,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  StartApiModelRequest._();

  factory StartApiModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartApiModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartApiModelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aE<Provider>(1, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOS(2, _omitFieldNames ? '' : 'modelId')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartApiModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartApiModelRequest copyWith(void Function(StartApiModelRequest) updates) =>
      super.copyWith((message) => updates(message as StartApiModelRequest))
          as StartApiModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartApiModelRequest create() => StartApiModelRequest._();
  @$core.override
  StartApiModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartApiModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartApiModelRequest>(create);
  static StartApiModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Provider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(Provider value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);
}

class StartApiModelResponse extends $pb.GeneratedMessage {
  factory StartApiModelResponse({
    ActiveApiModel? model,
  }) {
    final result = create();
    if (model != null) result.model = model;
    return result;
  }

  StartApiModelResponse._();

  factory StartApiModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartApiModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartApiModelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOM<ActiveApiModel>(1, _omitFieldNames ? '' : 'model',
        subBuilder: ActiveApiModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartApiModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartApiModelResponse copyWith(
          void Function(StartApiModelResponse) updates) =>
      super.copyWith((message) => updates(message as StartApiModelResponse))
          as StartApiModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartApiModelResponse create() => StartApiModelResponse._();
  @$core.override
  StartApiModelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartApiModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartApiModelResponse>(create);
  static StartApiModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ActiveApiModel get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(ActiveApiModel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);
  @$pb.TagNumber(1)
  ActiveApiModel ensureModel() => $_ensure(0);
}

class ListActiveApiModelsRequest extends $pb.GeneratedMessage {
  factory ListActiveApiModelsRequest() => create();

  ListActiveApiModelsRequest._();

  factory ListActiveApiModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListActiveApiModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListActiveApiModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveApiModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveApiModelsRequest copyWith(
          void Function(ListActiveApiModelsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListActiveApiModelsRequest))
          as ListActiveApiModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListActiveApiModelsRequest create() => ListActiveApiModelsRequest._();
  @$core.override
  ListActiveApiModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListActiveApiModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListActiveApiModelsRequest>(create);
  static ListActiveApiModelsRequest? _defaultInstance;
}

class ListActiveApiModelsResponse extends $pb.GeneratedMessage {
  factory ListActiveApiModelsResponse({
    $core.Iterable<ActiveApiModel>? models,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    return result;
  }

  ListActiveApiModelsResponse._();

  factory ListActiveApiModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListActiveApiModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListActiveApiModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..pPM<ActiveApiModel>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ActiveApiModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveApiModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveApiModelsResponse copyWith(
          void Function(ListActiveApiModelsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListActiveApiModelsResponse))
          as ListActiveApiModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListActiveApiModelsResponse create() =>
      ListActiveApiModelsResponse._();
  @$core.override
  ListActiveApiModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListActiveApiModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListActiveApiModelsResponse>(create);
  static ListActiveApiModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ActiveApiModel> get models => $_getList(0);
}

class DeleteActiveApiModelRequest extends $pb.GeneratedMessage {
  factory DeleteActiveApiModelRequest({
    $core.String? modelRef,
  }) {
    final result = create();
    if (modelRef != null) result.modelRef = modelRef;
    return result;
  }

  DeleteActiveApiModelRequest._();

  factory DeleteActiveApiModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteActiveApiModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteActiveApiModelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelRef')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveApiModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveApiModelRequest copyWith(
          void Function(DeleteActiveApiModelRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DeleteActiveApiModelRequest))
          as DeleteActiveApiModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteActiveApiModelRequest create() =>
      DeleteActiveApiModelRequest._();
  @$core.override
  DeleteActiveApiModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteActiveApiModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteActiveApiModelRequest>(create);
  static DeleteActiveApiModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelRef => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelRef($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelRef() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelRef() => $_clearField(1);
}

class DeleteActiveApiModelResponse extends $pb.GeneratedMessage {
  factory DeleteActiveApiModelResponse() => create();

  DeleteActiveApiModelResponse._();

  factory DeleteActiveApiModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteActiveApiModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteActiveApiModelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.marketplace.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveApiModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveApiModelResponse copyWith(
          void Function(DeleteActiveApiModelResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DeleteActiveApiModelResponse))
          as DeleteActiveApiModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteActiveApiModelResponse create() =>
      DeleteActiveApiModelResponse._();
  @$core.override
  DeleteActiveApiModelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteActiveApiModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteActiveApiModelResponse>(create);
  static DeleteActiveApiModelResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
