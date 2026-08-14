// This is a generated file - do not edit.
//
// Generated from culpeostudio/engine/v1/engine.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart' as $1;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $3;

import '../../hardware/v1/hardware.pb.dart' as $2;
import 'engine.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'engine.pbenum.dart';

/// EngineConfig is what the caller asks for. Every field the HTTP API accepted
/// as a JSON patch is spelled out here, except runtime_options and
/// generation_defaults: those are passed through to the runtime and to the
/// sampler untouched, so they stay free-form.
class EngineConfig extends $pb.GeneratedMessage {
  factory EngineConfig({
    RuntimeKind? runtime,
    ContextMode? contextMode,
    $core.int? contextTokens,
    $core.int? maxSequences,
    Priority? priority,
    KvCachePolicy? kvCachePolicy,
    $core.bool? allowFallback,
    $core.bool? autostart,
    $1.Struct? runtimeOptions,
    $1.Struct? generationDefaults,
    $core.bool? gatewayAutostart,
    $core.bool? restartOnCrash,
    $core.int? idleTimeoutSeconds,
  }) {
    final result = create();
    if (runtime != null) result.runtime = runtime;
    if (contextMode != null) result.contextMode = contextMode;
    if (contextTokens != null) result.contextTokens = contextTokens;
    if (maxSequences != null) result.maxSequences = maxSequences;
    if (priority != null) result.priority = priority;
    if (kvCachePolicy != null) result.kvCachePolicy = kvCachePolicy;
    if (allowFallback != null) result.allowFallback = allowFallback;
    if (autostart != null) result.autostart = autostart;
    if (runtimeOptions != null) result.runtimeOptions = runtimeOptions;
    if (generationDefaults != null)
      result.generationDefaults = generationDefaults;
    if (gatewayAutostart != null) result.gatewayAutostart = gatewayAutostart;
    if (restartOnCrash != null) result.restartOnCrash = restartOnCrash;
    if (idleTimeoutSeconds != null)
      result.idleTimeoutSeconds = idleTimeoutSeconds;
    return result;
  }

  EngineConfig._();

  factory EngineConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineConfig',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aE<RuntimeKind>(1, _omitFieldNames ? '' : 'runtime',
        enumValues: RuntimeKind.values)
    ..aE<ContextMode>(2, _omitFieldNames ? '' : 'contextMode',
        enumValues: ContextMode.values)
    ..aI(3, _omitFieldNames ? '' : 'contextTokens')
    ..aI(4, _omitFieldNames ? '' : 'maxSequences')
    ..aE<Priority>(5, _omitFieldNames ? '' : 'priority',
        enumValues: Priority.values)
    ..aE<KvCachePolicy>(6, _omitFieldNames ? '' : 'kvCachePolicy',
        enumValues: KvCachePolicy.values)
    ..aOB(7, _omitFieldNames ? '' : 'allowFallback')
    ..aOB(8, _omitFieldNames ? '' : 'autostart')
    ..aOM<$1.Struct>(9, _omitFieldNames ? '' : 'runtimeOptions',
        subBuilder: $1.Struct.create)
    ..aOM<$1.Struct>(10, _omitFieldNames ? '' : 'generationDefaults',
        subBuilder: $1.Struct.create)
    ..aOB(12, _omitFieldNames ? '' : 'gatewayAutostart')
    ..aOB(13, _omitFieldNames ? '' : 'restartOnCrash')
    ..aI(14, _omitFieldNames ? '' : 'idleTimeoutSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineConfig copyWith(void Function(EngineConfig) updates) =>
      super.copyWith((message) => updates(message as EngineConfig))
          as EngineConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineConfig create() => EngineConfig._();
  @$core.override
  EngineConfig createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineConfig>(create);
  static EngineConfig? _defaultInstance;

  @$pb.TagNumber(1)
  RuntimeKind get runtime => $_getN(0);
  @$pb.TagNumber(1)
  set runtime(RuntimeKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRuntime() => $_has(0);
  @$pb.TagNumber(1)
  void clearRuntime() => $_clearField(1);

  @$pb.TagNumber(2)
  ContextMode get contextMode => $_getN(1);
  @$pb.TagNumber(2)
  set contextMode(ContextMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasContextMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearContextMode() => $_clearField(2);

  /// Only read when context_mode is fixed. Unset asks for the planner's choice.
  @$pb.TagNumber(3)
  $core.int get contextTokens => $_getIZ(2);
  @$pb.TagNumber(3)
  set contextTokens($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextTokens() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextTokens() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxSequences => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxSequences($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaxSequences() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxSequences() => $_clearField(4);

  @$pb.TagNumber(5)
  Priority get priority => $_getN(4);
  @$pb.TagNumber(5)
  set priority(Priority value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPriority() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriority() => $_clearField(5);

  @$pb.TagNumber(6)
  KvCachePolicy get kvCachePolicy => $_getN(5);
  @$pb.TagNumber(6)
  set kvCachePolicy(KvCachePolicy value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasKvCachePolicy() => $_has(5);
  @$pb.TagNumber(6)
  void clearKvCachePolicy() => $_clearField(6);

  /// Unset means the engine may fall back to a weaker placement rather than
  /// refusing to start. It defaults to true.
  @$pb.TagNumber(7)
  $core.bool get allowFallback => $_getBF(6);
  @$pb.TagNumber(7)
  set allowFallback($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAllowFallback() => $_has(6);
  @$pb.TagNumber(7)
  void clearAllowFallback() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get autostart => $_getBF(7);
  @$pb.TagNumber(8)
  set autostart($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAutostart() => $_has(7);
  @$pb.TagNumber(8)
  void clearAutostart() => $_clearField(8);

  @$pb.TagNumber(9)
  $1.Struct get runtimeOptions => $_getN(8);
  @$pb.TagNumber(9)
  set runtimeOptions($1.Struct value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasRuntimeOptions() => $_has(8);
  @$pb.TagNumber(9)
  void clearRuntimeOptions() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.Struct ensureRuntimeOptions() => $_ensure(8);

  @$pb.TagNumber(10)
  $1.Struct get generationDefaults => $_getN(9);
  @$pb.TagNumber(10)
  set generationDefaults($1.Struct value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasGenerationDefaults() => $_has(9);
  @$pb.TagNumber(10)
  void clearGenerationDefaults() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Struct ensureGenerationDefaults() => $_ensure(9);

  /// Let the local OpenAI gateway load this instance when a request arrives for
  /// it, instead of answering "not ready". Off by default: a request that
  /// silently loads tens of gigabytes is not something to do unasked.
  @$pb.TagNumber(12)
  $core.bool get gatewayAutostart => $_getBF(10);
  @$pb.TagNumber(12)
  set gatewayAutostart($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(12)
  $core.bool hasGatewayAutostart() => $_has(10);
  @$pb.TagNumber(12)
  void clearGatewayAutostart() => $_clearField(12);

  /// Bring the instance back after its worker process died on its own. Also off
  /// by default, so a model that cannot load stops instead of looping.
  @$pb.TagNumber(13)
  $core.bool get restartOnCrash => $_getBF(11);
  @$pb.TagNumber(13)
  set restartOnCrash($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(13)
  $core.bool hasRestartOnCrash() => $_has(11);
  @$pb.TagNumber(13)
  void clearRestartOnCrash() => $_clearField(13);

  /// How long the instance may sit unused before it is unloaded. Unset follows
  /// the engine default; a negative value keeps it loaded until it is stopped
  /// by hand.
  @$pb.TagNumber(14)
  $core.int get idleTimeoutSeconds => $_getIZ(12);
  @$pb.TagNumber(14)
  set idleTimeoutSeconds($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(14)
  $core.bool hasIdleTimeoutSeconds() => $_has(12);
  @$pb.TagNumber(14)
  void clearIdleTimeoutSeconds() => $_clearField(14);
}

/// ModelMetadata is what the catalog read out of the model files.
class ModelMetadata extends $pb.GeneratedMessage {
  factory ModelMetadata({
    $core.String? name,
    $core.String? architecture,
    $core.int? layers,
    $core.int? attentionHeads,
    $core.int? kvHeads,
    $core.int? headDimension,
    $core.int? embeddingDimension,
    $core.int? contextLength,
    $core.int? slidingWindow,
    $fixnum.Int64? parameterCount,
    $core.String? quantization,
    $core.String? storedTensorDataType,
    $fixnum.Int64? expertWeightBytes,
    $core.int? expertLayers,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (architecture != null) result.architecture = architecture;
    if (layers != null) result.layers = layers;
    if (attentionHeads != null) result.attentionHeads = attentionHeads;
    if (kvHeads != null) result.kvHeads = kvHeads;
    if (headDimension != null) result.headDimension = headDimension;
    if (embeddingDimension != null)
      result.embeddingDimension = embeddingDimension;
    if (contextLength != null) result.contextLength = contextLength;
    if (slidingWindow != null) result.slidingWindow = slidingWindow;
    if (parameterCount != null) result.parameterCount = parameterCount;
    if (quantization != null) result.quantization = quantization;
    if (storedTensorDataType != null)
      result.storedTensorDataType = storedTensorDataType;
    if (expertWeightBytes != null) result.expertWeightBytes = expertWeightBytes;
    if (expertLayers != null) result.expertLayers = expertLayers;
    return result;
  }

  ModelMetadata._();

  factory ModelMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelMetadata',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'architecture')
    ..aI(3, _omitFieldNames ? '' : 'layers')
    ..aI(4, _omitFieldNames ? '' : 'attentionHeads')
    ..aI(5, _omitFieldNames ? '' : 'kvHeads')
    ..aI(6, _omitFieldNames ? '' : 'headDimension')
    ..aI(7, _omitFieldNames ? '' : 'embeddingDimension')
    ..aI(8, _omitFieldNames ? '' : 'contextLength')
    ..aI(9, _omitFieldNames ? '' : 'slidingWindow')
    ..aInt64(10, _omitFieldNames ? '' : 'parameterCount')
    ..aOS(11, _omitFieldNames ? '' : 'quantization')
    ..aOS(12, _omitFieldNames ? '' : 'storedTensorDataType')
    ..aInt64(13, _omitFieldNames ? '' : 'expertWeightBytes')
    ..aI(14, _omitFieldNames ? '' : 'expertLayers')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelMetadata copyWith(void Function(ModelMetadata) updates) =>
      super.copyWith((message) => updates(message as ModelMetadata))
          as ModelMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelMetadata create() => ModelMetadata._();
  @$core.override
  ModelMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelMetadata>(create);
  static ModelMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get architecture => $_getSZ(1);
  @$pb.TagNumber(2)
  set architecture($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArchitecture() => $_has(1);
  @$pb.TagNumber(2)
  void clearArchitecture() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get layers => $_getIZ(2);
  @$pb.TagNumber(3)
  set layers($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLayers() => $_has(2);
  @$pb.TagNumber(3)
  void clearLayers() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get attentionHeads => $_getIZ(3);
  @$pb.TagNumber(4)
  set attentionHeads($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAttentionHeads() => $_has(3);
  @$pb.TagNumber(4)
  void clearAttentionHeads() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get kvHeads => $_getIZ(4);
  @$pb.TagNumber(5)
  set kvHeads($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKvHeads() => $_has(4);
  @$pb.TagNumber(5)
  void clearKvHeads() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get headDimension => $_getIZ(5);
  @$pb.TagNumber(6)
  set headDimension($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeadDimension() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeadDimension() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get embeddingDimension => $_getIZ(6);
  @$pb.TagNumber(7)
  set embeddingDimension($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEmbeddingDimension() => $_has(6);
  @$pb.TagNumber(7)
  void clearEmbeddingDimension() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get contextLength => $_getIZ(7);
  @$pb.TagNumber(8)
  set contextLength($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasContextLength() => $_has(7);
  @$pb.TagNumber(8)
  void clearContextLength() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get slidingWindow => $_getIZ(8);
  @$pb.TagNumber(9)
  set slidingWindow($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSlidingWindow() => $_has(8);
  @$pb.TagNumber(9)
  void clearSlidingWindow() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get parameterCount => $_getI64(9);
  @$pb.TagNumber(10)
  set parameterCount($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasParameterCount() => $_has(9);
  @$pb.TagNumber(10)
  void clearParameterCount() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get quantization => $_getSZ(10);
  @$pb.TagNumber(11)
  set quantization($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasQuantization() => $_has(10);
  @$pb.TagNumber(11)
  void clearQuantization() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get storedTensorDataType => $_getSZ(11);
  @$pb.TagNumber(12)
  set storedTensorDataType($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasStoredTensorDataType() => $_has(11);
  @$pb.TagNumber(12)
  void clearStoredTensorDataType() => $_clearField(12);

  /// How many bytes of this model are Mixture-of-Experts weight, and how many
  /// blocks carry any. Both zero for a dense model, which is what makes them a
  /// reliable test for whether an expert offload applies at all.
  @$pb.TagNumber(13)
  $fixnum.Int64 get expertWeightBytes => $_getI64(12);
  @$pb.TagNumber(13)
  set expertWeightBytes($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasExpertWeightBytes() => $_has(12);
  @$pb.TagNumber(13)
  void clearExpertWeightBytes() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get expertLayers => $_getIZ(13);
  @$pb.TagNumber(14)
  set expertLayers($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasExpertLayers() => $_has(13);
  @$pb.TagNumber(14)
  void clearExpertLayers() => $_clearField(14);
}

/// ValidationIssue is one reason a catalog entry is not startable, or one
/// caveat about starting it.
class ValidationIssue extends $pb.GeneratedMessage {
  factory ValidationIssue({
    $core.String? code,
    IssueSeverity? severity,
    $core.String? message,
    $core.String? remediation,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (severity != null) result.severity = severity;
    if (message != null) result.message = message;
    if (remediation != null) result.remediation = remediation;
    return result;
  }

  ValidationIssue._();

  factory ValidationIssue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidationIssue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidationIssue',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aE<IssueSeverity>(2, _omitFieldNames ? '' : 'severity',
        enumValues: IssueSeverity.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOS(4, _omitFieldNames ? '' : 'remediation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidationIssue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidationIssue copyWith(void Function(ValidationIssue) updates) =>
      super.copyWith((message) => updates(message as ValidationIssue))
          as ValidationIssue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidationIssue create() => ValidationIssue._();
  @$core.override
  ValidationIssue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ValidationIssue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidationIssue>(create);
  static ValidationIssue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  IssueSeverity get severity => $_getN(1);
  @$pb.TagNumber(2)
  set severity(IssueSeverity value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSeverity() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeverity() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get remediation => $_getSZ(3);
  @$pb.TagNumber(4)
  set remediation($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRemediation() => $_has(3);
  @$pb.TagNumber(4)
  void clearRemediation() => $_clearField(4);
}

/// ModelRecord is one entry in the on-disk catalog.
class ModelRecord extends $pb.GeneratedMessage {
  factory ModelRecord({
    $core.String? id,
    $core.String? fingerprint,
    $core.String? name,
    $core.String? relativePath,
    ModelFormat? format,
    $core.bool? complete,
    $core.bool? startable,
    $fixnum.Int64? sizeBytes,
    $core.Iterable<$core.String>? files,
    ModelMetadata? metadata,
    $core.Iterable<RuntimeKind>? runtimeCandidates,
    $core.Iterable<ValidationIssue>? issues,
    ModelStatus? status,
    $core.String? nodeId,
    $core.String? nodeName,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (name != null) result.name = name;
    if (relativePath != null) result.relativePath = relativePath;
    if (format != null) result.format = format;
    if (complete != null) result.complete = complete;
    if (startable != null) result.startable = startable;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (files != null) result.files.addAll(files);
    if (metadata != null) result.metadata = metadata;
    if (runtimeCandidates != null)
      result.runtimeCandidates.addAll(runtimeCandidates);
    if (issues != null) result.issues.addAll(issues);
    if (status != null) result.status = status;
    if (nodeId != null) result.nodeId = nodeId;
    if (nodeName != null) result.nodeName = nodeName;
    return result;
  }

  ModelRecord._();

  factory ModelRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelRecord',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'relativePath')
    ..aE<ModelFormat>(5, _omitFieldNames ? '' : 'format',
        enumValues: ModelFormat.values)
    ..aOB(6, _omitFieldNames ? '' : 'complete')
    ..aOB(7, _omitFieldNames ? '' : 'startable')
    ..aInt64(8, _omitFieldNames ? '' : 'sizeBytes')
    ..pPS(9, _omitFieldNames ? '' : 'files')
    ..aOM<ModelMetadata>(10, _omitFieldNames ? '' : 'metadata',
        subBuilder: ModelMetadata.create)
    ..pc<RuntimeKind>(
        11, _omitFieldNames ? '' : 'runtimeCandidates', $pb.PbFieldType.KE,
        valueOf: RuntimeKind.valueOf,
        enumValues: RuntimeKind.values,
        defaultEnumValue: RuntimeKind.RUNTIME_KIND_UNSPECIFIED)
    ..pPM<ValidationIssue>(12, _omitFieldNames ? '' : 'issues',
        subBuilder: ValidationIssue.create)
    ..aE<ModelStatus>(13, _omitFieldNames ? '' : 'status',
        enumValues: ModelStatus.values)
    ..aOS(14, _omitFieldNames ? '' : 'nodeId')
    ..aOS(15, _omitFieldNames ? '' : 'nodeName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelRecord copyWith(void Function(ModelRecord) updates) =>
      super.copyWith((message) => updates(message as ModelRecord))
          as ModelRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelRecord create() => ModelRecord._();
  @$core.override
  ModelRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelRecord>(create);
  static ModelRecord? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fingerprint => $_getSZ(1);
  @$pb.TagNumber(2)
  set fingerprint($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFingerprint() => $_has(1);
  @$pb.TagNumber(2)
  void clearFingerprint() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get relativePath => $_getSZ(3);
  @$pb.TagNumber(4)
  set relativePath($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRelativePath() => $_has(3);
  @$pb.TagNumber(4)
  void clearRelativePath() => $_clearField(4);

  @$pb.TagNumber(5)
  ModelFormat get format => $_getN(4);
  @$pb.TagNumber(5)
  set format(ModelFormat value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFormat() => $_has(4);
  @$pb.TagNumber(5)
  void clearFormat() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get complete => $_getBF(5);
  @$pb.TagNumber(6)
  set complete($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasComplete() => $_has(5);
  @$pb.TagNumber(6)
  void clearComplete() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get startable => $_getBF(6);
  @$pb.TagNumber(7)
  set startable($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStartable() => $_has(6);
  @$pb.TagNumber(7)
  void clearStartable() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get sizeBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSizeBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearSizeBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get files => $_getList(8);

  @$pb.TagNumber(10)
  ModelMetadata get metadata => $_getN(9);
  @$pb.TagNumber(10)
  set metadata(ModelMetadata value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMetadata() => $_has(9);
  @$pb.TagNumber(10)
  void clearMetadata() => $_clearField(10);
  @$pb.TagNumber(10)
  ModelMetadata ensureMetadata() => $_ensure(9);

  @$pb.TagNumber(11)
  $pb.PbList<RuntimeKind> get runtimeCandidates => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<ValidationIssue> get issues => $_getList(11);

  @$pb.TagNumber(13)
  ModelStatus get status => $_getN(12);
  @$pb.TagNumber(13)
  set status(ModelStatus value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasStatus() => $_has(12);
  @$pb.TagNumber(13)
  void clearStatus() => $_clearField(13);

  /// Empty for a model on this machine. A model that lives on a node carries
  /// the node it was found on, and its id is qualified with that node so the
  /// calls acting on it route themselves.
  @$pb.TagNumber(14)
  $core.String get nodeId => $_getSZ(13);
  @$pb.TagNumber(14)
  set nodeId($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasNodeId() => $_has(13);
  @$pb.TagNumber(14)
  void clearNodeId() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get nodeName => $_getSZ(14);
  @$pb.TagNumber(15)
  set nodeName($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasNodeName() => $_has(14);
  @$pb.TagNumber(15)
  void clearNodeName() => $_clearField(15);
}

/// HardwareSnapshot is the live reading the engine plans against. It reuses the
/// GPU message the marketplace and the settings screen already receive, so the
/// client has one GPU shape to parse rather than two.
class HardwareSnapshot extends $pb.GeneratedMessage {
  factory HardwareSnapshot({
    $core.String? os,
    $core.String? arch,
    $core.String? cpuName,
    $core.int? cpuCores,
    $fixnum.Int64? ramTotalBytes,
    $fixnum.Int64? ramAvailableBytes,
    $fixnum.Int64? diskFreeBytes,
    $core.Iterable<$2.EngineGpu>? gpus,
    $core.bool? gpuTelemetryIncomplete,
    $3.Timestamp? capturedAt,
    $core.String? source,
  }) {
    final result = create();
    if (os != null) result.os = os;
    if (arch != null) result.arch = arch;
    if (cpuName != null) result.cpuName = cpuName;
    if (cpuCores != null) result.cpuCores = cpuCores;
    if (ramTotalBytes != null) result.ramTotalBytes = ramTotalBytes;
    if (ramAvailableBytes != null) result.ramAvailableBytes = ramAvailableBytes;
    if (diskFreeBytes != null) result.diskFreeBytes = diskFreeBytes;
    if (gpus != null) result.gpus.addAll(gpus);
    if (gpuTelemetryIncomplete != null)
      result.gpuTelemetryIncomplete = gpuTelemetryIncomplete;
    if (capturedAt != null) result.capturedAt = capturedAt;
    if (source != null) result.source = source;
    return result;
  }

  HardwareSnapshot._();

  factory HardwareSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HardwareSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HardwareSnapshot',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'os')
    ..aOS(2, _omitFieldNames ? '' : 'arch')
    ..aOS(3, _omitFieldNames ? '' : 'cpuName')
    ..aI(4, _omitFieldNames ? '' : 'cpuCores')
    ..aInt64(5, _omitFieldNames ? '' : 'ramTotalBytes')
    ..aInt64(6, _omitFieldNames ? '' : 'ramAvailableBytes')
    ..aInt64(7, _omitFieldNames ? '' : 'diskFreeBytes')
    ..pPM<$2.EngineGpu>(8, _omitFieldNames ? '' : 'gpus',
        subBuilder: $2.EngineGpu.create)
    ..aOB(9, _omitFieldNames ? '' : 'gpuTelemetryIncomplete')
    ..aOM<$3.Timestamp>(10, _omitFieldNames ? '' : 'capturedAt',
        subBuilder: $3.Timestamp.create)
    ..aOS(11, _omitFieldNames ? '' : 'source')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HardwareSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HardwareSnapshot copyWith(void Function(HardwareSnapshot) updates) =>
      super.copyWith((message) => updates(message as HardwareSnapshot))
          as HardwareSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HardwareSnapshot create() => HardwareSnapshot._();
  @$core.override
  HardwareSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HardwareSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HardwareSnapshot>(create);
  static HardwareSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get os => $_getSZ(0);
  @$pb.TagNumber(1)
  set os($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOs() => $_has(0);
  @$pb.TagNumber(1)
  void clearOs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get arch => $_getSZ(1);
  @$pb.TagNumber(2)
  set arch($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArch() => $_has(1);
  @$pb.TagNumber(2)
  void clearArch() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get cpuName => $_getSZ(2);
  @$pb.TagNumber(3)
  set cpuName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCpuName() => $_has(2);
  @$pb.TagNumber(3)
  void clearCpuName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get cpuCores => $_getIZ(3);
  @$pb.TagNumber(4)
  set cpuCores($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCpuCores() => $_has(3);
  @$pb.TagNumber(4)
  void clearCpuCores() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get ramTotalBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set ramTotalBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRamTotalBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearRamTotalBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get ramAvailableBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set ramAvailableBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRamAvailableBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearRamAvailableBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get diskFreeBytes => $_getI64(6);
  @$pb.TagNumber(7)
  set diskFreeBytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDiskFreeBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearDiskFreeBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<$2.EngineGpu> get gpus => $_getList(7);

  @$pb.TagNumber(9)
  $core.bool get gpuTelemetryIncomplete => $_getBF(8);
  @$pb.TagNumber(9)
  set gpuTelemetryIncomplete($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasGpuTelemetryIncomplete() => $_has(8);
  @$pb.TagNumber(9)
  void clearGpuTelemetryIncomplete() => $_clearField(9);

  @$pb.TagNumber(10)
  $3.Timestamp get capturedAt => $_getN(9);
  @$pb.TagNumber(10)
  set capturedAt($3.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCapturedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearCapturedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $3.Timestamp ensureCapturedAt() => $_ensure(9);

  @$pb.TagNumber(11)
  $core.String get source => $_getSZ(10);
  @$pb.TagNumber(11)
  set source($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSource() => $_has(10);
  @$pb.TagNumber(11)
  void clearSource() => $_clearField(11);
}

/// RuntimeCapability is what one runtime can do on this machine right now.
class RuntimeCapability extends $pb.GeneratedMessage {
  factory RuntimeCapability({
    RuntimeKind? kind,
    $core.String? version,
    $core.bool? installed,
    $core.bool? healthy,
    $core.String? environment,
    $core.Iterable<$core.String>? gpuBackends,
    $core.Iterable<$core.String>? kvCacheModes,
    $core.Iterable<$core.MapEntry<$core.String, ChangeMode>>? configFields,
    $core.String? probeError,
    $3.Timestamp? lastProbedAt,
    $core.String? status,
    $core.String? statusMessage,
    $core.double? progress,
    $core.String? errorCode,
    $core.String? variant,
    $core.String? serverPath,
    $core.String? buildVersion,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (version != null) result.version = version;
    if (installed != null) result.installed = installed;
    if (healthy != null) result.healthy = healthy;
    if (environment != null) result.environment = environment;
    if (gpuBackends != null) result.gpuBackends.addAll(gpuBackends);
    if (kvCacheModes != null) result.kvCacheModes.addAll(kvCacheModes);
    if (configFields != null) result.configFields.addEntries(configFields);
    if (probeError != null) result.probeError = probeError;
    if (lastProbedAt != null) result.lastProbedAt = lastProbedAt;
    if (status != null) result.status = status;
    if (statusMessage != null) result.statusMessage = statusMessage;
    if (progress != null) result.progress = progress;
    if (errorCode != null) result.errorCode = errorCode;
    if (variant != null) result.variant = variant;
    if (serverPath != null) result.serverPath = serverPath;
    if (buildVersion != null) result.buildVersion = buildVersion;
    return result;
  }

  RuntimeCapability._();

  factory RuntimeCapability.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RuntimeCapability.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RuntimeCapability',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aE<RuntimeKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: RuntimeKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOB(3, _omitFieldNames ? '' : 'installed')
    ..aOB(4, _omitFieldNames ? '' : 'healthy')
    ..aOS(5, _omitFieldNames ? '' : 'environment')
    ..pPS(6, _omitFieldNames ? '' : 'gpuBackends')
    ..pPS(7, _omitFieldNames ? '' : 'kvCacheModes')
    ..m<$core.String, ChangeMode>(8, _omitFieldNames ? '' : 'configFields',
        entryClassName: 'RuntimeCapability.ConfigFieldsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OE,
        valueOf: ChangeMode.valueOf,
        enumValues: ChangeMode.values,
        valueDefaultOrMaker: ChangeMode.CHANGE_MODE_UNSPECIFIED,
        defaultEnumValue: ChangeMode.CHANGE_MODE_UNSPECIFIED,
        packageName: const $pb.PackageName('culpeostudio.engine.v1'))
    ..aOS(9, _omitFieldNames ? '' : 'probeError')
    ..aOM<$3.Timestamp>(10, _omitFieldNames ? '' : 'lastProbedAt',
        subBuilder: $3.Timestamp.create)
    ..aOS(11, _omitFieldNames ? '' : 'status')
    ..aOS(12, _omitFieldNames ? '' : 'statusMessage')
    ..aD(13, _omitFieldNames ? '' : 'progress')
    ..aOS(14, _omitFieldNames ? '' : 'errorCode')
    ..aOS(15, _omitFieldNames ? '' : 'variant')
    ..aOS(16, _omitFieldNames ? '' : 'serverPath')
    ..aOS(17, _omitFieldNames ? '' : 'buildVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeCapability clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeCapability copyWith(void Function(RuntimeCapability) updates) =>
      super.copyWith((message) => updates(message as RuntimeCapability))
          as RuntimeCapability;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RuntimeCapability create() => RuntimeCapability._();
  @$core.override
  RuntimeCapability createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RuntimeCapability getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RuntimeCapability>(create);
  static RuntimeCapability? _defaultInstance;

  @$pb.TagNumber(1)
  RuntimeKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(RuntimeKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  /// The pinned llama.cpp release tag this build comes from.
  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get installed => $_getBF(2);
  @$pb.TagNumber(3)
  set installed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInstalled() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstalled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get healthy => $_getBF(3);
  @$pb.TagNumber(4)
  set healthy($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHealthy() => $_has(3);
  @$pb.TagNumber(4)
  void clearHealthy() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get environment => $_getSZ(4);
  @$pb.TagNumber(5)
  set environment($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnvironment() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnvironment() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get gpuBackends => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get kvCacheModes => $_getList(6);

  /// Which config fields this runtime honours, and whether a change to one of
  /// them can be applied live.
  @$pb.TagNumber(8)
  $pb.PbMap<$core.String, ChangeMode> get configFields => $_getMap(7);

  @$pb.TagNumber(9)
  $core.String get probeError => $_getSZ(8);
  @$pb.TagNumber(9)
  set probeError($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProbeError() => $_has(8);
  @$pb.TagNumber(9)
  void clearProbeError() => $_clearField(9);

  @$pb.TagNumber(10)
  $3.Timestamp get lastProbedAt => $_getN(9);
  @$pb.TagNumber(10)
  set lastProbedAt($3.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasLastProbedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearLastProbedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $3.Timestamp ensureLastProbedAt() => $_ensure(9);

  /// Free-form because it also carries installer progress states, which grow
  /// with the installer rather than with the schema.
  @$pb.TagNumber(11)
  $core.String get status => $_getSZ(10);
  @$pb.TagNumber(11)
  set status($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasStatus() => $_has(10);
  @$pb.TagNumber(11)
  void clearStatus() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get statusMessage => $_getSZ(11);
  @$pb.TagNumber(12)
  set statusMessage($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasStatusMessage() => $_has(11);
  @$pb.TagNumber(12)
  void clearStatusMessage() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get progress => $_getN(12);
  @$pb.TagNumber(13)
  set progress($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasProgress() => $_has(12);
  @$pb.TagNumber(13)
  void clearProgress() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get errorCode => $_getSZ(13);
  @$pb.TagNumber(14)
  set errorCode($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasErrorCode() => $_has(13);
  @$pb.TagNumber(14)
  void clearErrorCode() => $_clearField(14);

  /// Which prebuilt binary this machine resolves to: cuda, vulkan, sycl, metal
  /// or cpu.
  @$pb.TagNumber(15)
  $core.String get variant => $_getSZ(14);
  @$pb.TagNumber(15)
  set variant($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasVariant() => $_has(14);
  @$pb.TagNumber(15)
  void clearVariant() => $_clearField(15);

  /// Absolute path of the installed llama-server, once it is installed.
  @$pb.TagNumber(16)
  $core.String get serverPath => $_getSZ(15);
  @$pb.TagNumber(16)
  set serverPath($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasServerPath() => $_has(15);
  @$pb.TagNumber(16)
  void clearServerPath() => $_clearField(16);

  /// What the installed binary reported for --version.
  @$pb.TagNumber(17)
  $core.String get buildVersion => $_getSZ(16);
  @$pb.TagNumber(17)
  set buildVersion($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasBuildVersion() => $_has(16);
  @$pb.TagNumber(17)
  void clearBuildVersion() => $_clearField(17);
}

/// EngineDefaults are the values the engine applies when a config leaves a
/// field out, plus the reserves it currently holds back. The HTTP API returned
/// this as a free-form object the client picked keys out of.
class EngineDefaults extends $pb.GeneratedMessage {
  factory EngineDefaults({
    $core.int? minimumContextTokens,
    $core.int? contextStepTokens,
    $core.String? ramReserve,
    $core.String? gpuReserve,
    $core.String? emergencyRamFloor,
    $core.String? emergencyGpuFloor,
    KvCachePolicy? kvCachePolicy,
    $core.int? maxSequences,
    $core.bool? autostart,
    $core.String? gatewayUrl,
    $core.String? weightQuantization,
    $fixnum.Int64? ramReserveBytes,
    $fixnum.Int64? gpuReserveBytes,
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>?
        gpuReserveBytesById,
    $core.bool? ramReserveIsAutomatic,
    $core.bool? gpuReserveIsAutomatic,
  }) {
    final result = create();
    if (minimumContextTokens != null)
      result.minimumContextTokens = minimumContextTokens;
    if (contextStepTokens != null) result.contextStepTokens = contextStepTokens;
    if (ramReserve != null) result.ramReserve = ramReserve;
    if (gpuReserve != null) result.gpuReserve = gpuReserve;
    if (emergencyRamFloor != null) result.emergencyRamFloor = emergencyRamFloor;
    if (emergencyGpuFloor != null) result.emergencyGpuFloor = emergencyGpuFloor;
    if (kvCachePolicy != null) result.kvCachePolicy = kvCachePolicy;
    if (maxSequences != null) result.maxSequences = maxSequences;
    if (autostart != null) result.autostart = autostart;
    if (gatewayUrl != null) result.gatewayUrl = gatewayUrl;
    if (weightQuantization != null)
      result.weightQuantization = weightQuantization;
    if (ramReserveBytes != null) result.ramReserveBytes = ramReserveBytes;
    if (gpuReserveBytes != null) result.gpuReserveBytes = gpuReserveBytes;
    if (gpuReserveBytesById != null)
      result.gpuReserveBytesById.addEntries(gpuReserveBytesById);
    if (ramReserveIsAutomatic != null)
      result.ramReserveIsAutomatic = ramReserveIsAutomatic;
    if (gpuReserveIsAutomatic != null)
      result.gpuReserveIsAutomatic = gpuReserveIsAutomatic;
    return result;
  }

  EngineDefaults._();

  factory EngineDefaults.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineDefaults.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineDefaults',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'minimumContextTokens')
    ..aI(2, _omitFieldNames ? '' : 'contextStepTokens')
    ..aOS(3, _omitFieldNames ? '' : 'ramReserve')
    ..aOS(4, _omitFieldNames ? '' : 'gpuReserve')
    ..aOS(5, _omitFieldNames ? '' : 'emergencyRamFloor')
    ..aOS(6, _omitFieldNames ? '' : 'emergencyGpuFloor')
    ..aE<KvCachePolicy>(7, _omitFieldNames ? '' : 'kvCachePolicy',
        enumValues: KvCachePolicy.values)
    ..aI(8, _omitFieldNames ? '' : 'maxSequences')
    ..aOB(9, _omitFieldNames ? '' : 'autostart')
    ..aOS(10, _omitFieldNames ? '' : 'gatewayUrl')
    ..aOS(11, _omitFieldNames ? '' : 'weightQuantization')
    ..aInt64(12, _omitFieldNames ? '' : 'ramReserveBytes')
    ..aInt64(13, _omitFieldNames ? '' : 'gpuReserveBytes')
    ..m<$core.String, $fixnum.Int64>(
        14, _omitFieldNames ? '' : 'gpuReserveBytesById',
        entryClassName: 'EngineDefaults.GpuReserveBytesByIdEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O6,
        packageName: const $pb.PackageName('culpeostudio.engine.v1'))
    ..aOB(15, _omitFieldNames ? '' : 'ramReserveIsAutomatic')
    ..aOB(16, _omitFieldNames ? '' : 'gpuReserveIsAutomatic')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineDefaults clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineDefaults copyWith(void Function(EngineDefaults) updates) =>
      super.copyWith((message) => updates(message as EngineDefaults))
          as EngineDefaults;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineDefaults create() => EngineDefaults._();
  @$core.override
  EngineDefaults createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineDefaults getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineDefaults>(create);
  static EngineDefaults? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get minimumContextTokens => $_getIZ(0);
  @$pb.TagNumber(1)
  set minimumContextTokens($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMinimumContextTokens() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinimumContextTokens() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get contextStepTokens => $_getIZ(1);
  @$pb.TagNumber(2)
  set contextStepTokens($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContextStepTokens() => $_has(1);
  @$pb.TagNumber(2)
  void clearContextStepTokens() => $_clearField(2);

  /// Human-readable formulas, shown next to the numbers below.
  @$pb.TagNumber(3)
  $core.String get ramReserve => $_getSZ(2);
  @$pb.TagNumber(3)
  set ramReserve($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRamReserve() => $_has(2);
  @$pb.TagNumber(3)
  void clearRamReserve() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get gpuReserve => $_getSZ(3);
  @$pb.TagNumber(4)
  set gpuReserve($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGpuReserve() => $_has(3);
  @$pb.TagNumber(4)
  void clearGpuReserve() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get emergencyRamFloor => $_getSZ(4);
  @$pb.TagNumber(5)
  set emergencyRamFloor($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEmergencyRamFloor() => $_has(4);
  @$pb.TagNumber(5)
  void clearEmergencyRamFloor() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get emergencyGpuFloor => $_getSZ(5);
  @$pb.TagNumber(6)
  set emergencyGpuFloor($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEmergencyGpuFloor() => $_has(5);
  @$pb.TagNumber(6)
  void clearEmergencyGpuFloor() => $_clearField(6);

  @$pb.TagNumber(7)
  KvCachePolicy get kvCachePolicy => $_getN(6);
  @$pb.TagNumber(7)
  set kvCachePolicy(KvCachePolicy value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasKvCachePolicy() => $_has(6);
  @$pb.TagNumber(7)
  void clearKvCachePolicy() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get maxSequences => $_getIZ(7);
  @$pb.TagNumber(8)
  set maxSequences($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaxSequences() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxSequences() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get autostart => $_getBF(8);
  @$pb.TagNumber(9)
  set autostart($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAutostart() => $_has(8);
  @$pb.TagNumber(9)
  void clearAutostart() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get gatewayUrl => $_getSZ(9);
  @$pb.TagNumber(10)
  set gatewayUrl($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasGatewayUrl() => $_has(9);
  @$pb.TagNumber(10)
  void clearGatewayUrl() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get weightQuantization => $_getSZ(10);
  @$pb.TagNumber(11)
  set weightQuantization($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasWeightQuantization() => $_has(10);
  @$pb.TagNumber(11)
  void clearWeightQuantization() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get ramReserveBytes => $_getI64(11);
  @$pb.TagNumber(12)
  set ramReserveBytes($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasRamReserveBytes() => $_has(11);
  @$pb.TagNumber(12)
  void clearRamReserveBytes() => $_clearField(12);

  /// The largest of the per-GPU reserves, kept for a single-GPU summary.
  @$pb.TagNumber(13)
  $fixnum.Int64 get gpuReserveBytes => $_getI64(12);
  @$pb.TagNumber(13)
  set gpuReserveBytes($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasGpuReserveBytes() => $_has(12);
  @$pb.TagNumber(13)
  void clearGpuReserveBytes() => $_clearField(13);

  @$pb.TagNumber(14)
  $pb.PbMap<$core.String, $fixnum.Int64> get gpuReserveBytesById =>
      $_getMap(13);

  /// False when the user has overridden the reserve in the settings.
  @$pb.TagNumber(15)
  $core.bool get ramReserveIsAutomatic => $_getBF(14);
  @$pb.TagNumber(15)
  set ramReserveIsAutomatic($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasRamReserveIsAutomatic() => $_has(14);
  @$pb.TagNumber(15)
  void clearRamReserveIsAutomatic() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get gpuReserveIsAutomatic => $_getBF(15);
  @$pb.TagNumber(16)
  set gpuReserveIsAutomatic($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasGpuReserveIsAutomatic() => $_has(15);
  @$pb.TagNumber(16)
  void clearGpuReserveIsAutomatic() => $_clearField(16);
}

/// MemoryAllocation is one line of the memory budget: what it costs in RAM and
/// what it costs on each GPU.
class MemoryAllocation extends $pb.GeneratedMessage {
  factory MemoryAllocation({
    $fixnum.Int64? ramBytes,
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>? gpuBytes,
  }) {
    final result = create();
    if (ramBytes != null) result.ramBytes = ramBytes;
    if (gpuBytes != null) result.gpuBytes.addEntries(gpuBytes);
    return result;
  }

  MemoryAllocation._();

  factory MemoryAllocation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemoryAllocation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemoryAllocation',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'ramBytes')
    ..m<$core.String, $fixnum.Int64>(2, _omitFieldNames ? '' : 'gpuBytes',
        entryClassName: 'MemoryAllocation.GpuBytesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O6,
        packageName: const $pb.PackageName('culpeostudio.engine.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemoryAllocation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemoryAllocation copyWith(void Function(MemoryAllocation) updates) =>
      super.copyWith((message) => updates(message as MemoryAllocation))
          as MemoryAllocation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemoryAllocation create() => MemoryAllocation._();
  @$core.override
  MemoryAllocation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemoryAllocation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemoryAllocation>(create);
  static MemoryAllocation? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ramBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set ramBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRamBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearRamBytes() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $fixnum.Int64> get gpuBytes => $_getMap(1);
}

/// ResourceBreakdown is the whole budget, split by what claims it.
class ResourceBreakdown extends $pb.GeneratedMessage {
  factory ResourceBreakdown({
    MemoryAllocation? weights,
    MemoryAllocation? kvCache,
    MemoryAllocation? runtime,
    MemoryAllocation? reserve,
    MemoryAllocation? total,
  }) {
    final result = create();
    if (weights != null) result.weights = weights;
    if (kvCache != null) result.kvCache = kvCache;
    if (runtime != null) result.runtime = runtime;
    if (reserve != null) result.reserve = reserve;
    if (total != null) result.total = total;
    return result;
  }

  ResourceBreakdown._();

  factory ResourceBreakdown.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResourceBreakdown.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResourceBreakdown',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<MemoryAllocation>(1, _omitFieldNames ? '' : 'weights',
        subBuilder: MemoryAllocation.create)
    ..aOM<MemoryAllocation>(2, _omitFieldNames ? '' : 'kvCache',
        subBuilder: MemoryAllocation.create)
    ..aOM<MemoryAllocation>(3, _omitFieldNames ? '' : 'runtime',
        subBuilder: MemoryAllocation.create)
    ..aOM<MemoryAllocation>(4, _omitFieldNames ? '' : 'reserve',
        subBuilder: MemoryAllocation.create)
    ..aOM<MemoryAllocation>(5, _omitFieldNames ? '' : 'total',
        subBuilder: MemoryAllocation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResourceBreakdown clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResourceBreakdown copyWith(void Function(ResourceBreakdown) updates) =>
      super.copyWith((message) => updates(message as ResourceBreakdown))
          as ResourceBreakdown;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResourceBreakdown create() => ResourceBreakdown._();
  @$core.override
  ResourceBreakdown createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResourceBreakdown getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResourceBreakdown>(create);
  static ResourceBreakdown? _defaultInstance;

  @$pb.TagNumber(1)
  MemoryAllocation get weights => $_getN(0);
  @$pb.TagNumber(1)
  set weights(MemoryAllocation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasWeights() => $_has(0);
  @$pb.TagNumber(1)
  void clearWeights() => $_clearField(1);
  @$pb.TagNumber(1)
  MemoryAllocation ensureWeights() => $_ensure(0);

  @$pb.TagNumber(2)
  MemoryAllocation get kvCache => $_getN(1);
  @$pb.TagNumber(2)
  set kvCache(MemoryAllocation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKvCache() => $_has(1);
  @$pb.TagNumber(2)
  void clearKvCache() => $_clearField(2);
  @$pb.TagNumber(2)
  MemoryAllocation ensureKvCache() => $_ensure(1);

  @$pb.TagNumber(3)
  MemoryAllocation get runtime => $_getN(2);
  @$pb.TagNumber(3)
  set runtime(MemoryAllocation value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRuntime() => $_has(2);
  @$pb.TagNumber(3)
  void clearRuntime() => $_clearField(3);
  @$pb.TagNumber(3)
  MemoryAllocation ensureRuntime() => $_ensure(2);

  @$pb.TagNumber(4)
  MemoryAllocation get reserve => $_getN(3);
  @$pb.TagNumber(4)
  set reserve(MemoryAllocation value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasReserve() => $_has(3);
  @$pb.TagNumber(4)
  void clearReserve() => $_clearField(4);
  @$pb.TagNumber(4)
  MemoryAllocation ensureReserve() => $_ensure(3);

  @$pb.TagNumber(5)
  MemoryAllocation get total => $_getN(4);
  @$pb.TagNumber(5)
  set total(MemoryAllocation value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTotal() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotal() => $_clearField(5);
  @$pb.TagNumber(5)
  MemoryAllocation ensureTotal() => $_ensure(4);
}

/// PreflightCheck is one gate passed before a start is attempted. Its state is
/// free-form: the checks are a diagnostic list that grows, and the client shows
/// it rather than branching on it.
class PreflightCheck extends $pb.GeneratedMessage {
  factory PreflightCheck({
    $core.String? id,
    $core.String? state,
    $core.String? label,
    $core.String? detail,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (state != null) result.state = state;
    if (label != null) result.label = label;
    if (detail != null) result.detail = detail;
    return result;
  }

  PreflightCheck._();

  factory PreflightCheck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreflightCheck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreflightCheck',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'state')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightCheck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightCheck copyWith(void Function(PreflightCheck) updates) =>
      super.copyWith((message) => updates(message as PreflightCheck))
          as PreflightCheck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreflightCheck create() => PreflightCheck._();
  @$core.override
  PreflightCheck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreflightCheck getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreflightCheck>(create);
  static PreflightCheck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get state => $_getSZ(1);
  @$pb.TagNumber(2)
  set state($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get detail => $_getSZ(3);
  @$pb.TagNumber(4)
  set detail($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDetail() => $_has(3);
  @$pb.TagNumber(4)
  void clearDetail() => $_clearField(4);
}

/// PreflightReport ties the checks to the hardware and model they ran against.
class PreflightReport extends $pb.GeneratedMessage {
  factory PreflightReport({
    $core.String? hardwareSnapshotId,
    $core.String? modelFingerprint,
    $core.String? metadataConfidence,
    $core.Iterable<PreflightCheck>? checks,
  }) {
    final result = create();
    if (hardwareSnapshotId != null)
      result.hardwareSnapshotId = hardwareSnapshotId;
    if (modelFingerprint != null) result.modelFingerprint = modelFingerprint;
    if (metadataConfidence != null)
      result.metadataConfidence = metadataConfidence;
    if (checks != null) result.checks.addAll(checks);
    return result;
  }

  PreflightReport._();

  factory PreflightReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreflightReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreflightReport',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hardwareSnapshotId')
    ..aOS(2, _omitFieldNames ? '' : 'modelFingerprint')
    ..aOS(3, _omitFieldNames ? '' : 'metadataConfidence')
    ..pPM<PreflightCheck>(4, _omitFieldNames ? '' : 'checks',
        subBuilder: PreflightCheck.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightReport copyWith(void Function(PreflightReport) updates) =>
      super.copyWith((message) => updates(message as PreflightReport))
          as PreflightReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreflightReport create() => PreflightReport._();
  @$core.override
  PreflightReport createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreflightReport getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreflightReport>(create);
  static PreflightReport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hardwareSnapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set hardwareSnapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHardwareSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearHardwareSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelFingerprint => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelFingerprint($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelFingerprint() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelFingerprint() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get metadataConfidence => $_getSZ(2);
  @$pb.TagNumber(3)
  set metadataConfidence($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMetadataConfidence() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetadataConfidence() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<PreflightCheck> get checks => $_getList(3);
}

/// ContextPlan is what the planner decided: how much context fits, where it
/// fits, and what it costs.
class ContextPlan extends $pb.GeneratedMessage {
  factory ContextPlan({
    $core.int? modelContextLimitTokens,
    $core.int? gpuOnlyMaxContextTokens,
    $core.int? hybridMaxContextTokens,
    $core.int? effectiveContextTokens,
    $core.int? ramRequiredAfterTokens,
    $fixnum.Int64? kvBytesPerTokenAtStart,
    $core.int? maxSequences,
    KvCacheDtype? kvCacheDtype,
    Priority? priority,
    $core.bool? pinned,
    $core.bool? restartRequired,
    $core.bool? usesRam,
    ResourceBreakdown? memory,
    Confidence? confidence,
    $core.Iterable<$core.String>? warnings,
    $core.Iterable<$core.String>? affectedRestartInstances,
    PreflightReport? preflight,
  }) {
    final result = create();
    if (modelContextLimitTokens != null)
      result.modelContextLimitTokens = modelContextLimitTokens;
    if (gpuOnlyMaxContextTokens != null)
      result.gpuOnlyMaxContextTokens = gpuOnlyMaxContextTokens;
    if (hybridMaxContextTokens != null)
      result.hybridMaxContextTokens = hybridMaxContextTokens;
    if (effectiveContextTokens != null)
      result.effectiveContextTokens = effectiveContextTokens;
    if (ramRequiredAfterTokens != null)
      result.ramRequiredAfterTokens = ramRequiredAfterTokens;
    if (kvBytesPerTokenAtStart != null)
      result.kvBytesPerTokenAtStart = kvBytesPerTokenAtStart;
    if (maxSequences != null) result.maxSequences = maxSequences;
    if (kvCacheDtype != null) result.kvCacheDtype = kvCacheDtype;
    if (priority != null) result.priority = priority;
    if (pinned != null) result.pinned = pinned;
    if (restartRequired != null) result.restartRequired = restartRequired;
    if (usesRam != null) result.usesRam = usesRam;
    if (memory != null) result.memory = memory;
    if (confidence != null) result.confidence = confidence;
    if (warnings != null) result.warnings.addAll(warnings);
    if (affectedRestartInstances != null)
      result.affectedRestartInstances.addAll(affectedRestartInstances);
    if (preflight != null) result.preflight = preflight;
    return result;
  }

  ContextPlan._();

  factory ContextPlan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextPlan.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextPlan',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'modelContextLimitTokens')
    ..aI(2, _omitFieldNames ? '' : 'gpuOnlyMaxContextTokens')
    ..aI(3, _omitFieldNames ? '' : 'hybridMaxContextTokens')
    ..aI(4, _omitFieldNames ? '' : 'effectiveContextTokens')
    ..aI(5, _omitFieldNames ? '' : 'ramRequiredAfterTokens')
    ..aInt64(6, _omitFieldNames ? '' : 'kvBytesPerTokenAtStart')
    ..aI(7, _omitFieldNames ? '' : 'maxSequences')
    ..aE<KvCacheDtype>(8, _omitFieldNames ? '' : 'kvCacheDtype',
        enumValues: KvCacheDtype.values)
    ..aE<Priority>(9, _omitFieldNames ? '' : 'priority',
        enumValues: Priority.values)
    ..aOB(10, _omitFieldNames ? '' : 'pinned')
    ..aOB(11, _omitFieldNames ? '' : 'restartRequired')
    ..aOB(12, _omitFieldNames ? '' : 'usesRam')
    ..aOM<ResourceBreakdown>(13, _omitFieldNames ? '' : 'memory',
        subBuilder: ResourceBreakdown.create)
    ..aE<Confidence>(14, _omitFieldNames ? '' : 'confidence',
        enumValues: Confidence.values)
    ..pPS(15, _omitFieldNames ? '' : 'warnings')
    ..pPS(16, _omitFieldNames ? '' : 'affectedRestartInstances')
    ..aOM<PreflightReport>(17, _omitFieldNames ? '' : 'preflight',
        subBuilder: PreflightReport.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlan copyWith(void Function(ContextPlan) updates) =>
      super.copyWith((message) => updates(message as ContextPlan))
          as ContextPlan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextPlan create() => ContextPlan._();
  @$core.override
  ContextPlan createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextPlan getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextPlan>(create);
  static ContextPlan? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get modelContextLimitTokens => $_getIZ(0);
  @$pb.TagNumber(1)
  set modelContextLimitTokens($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelContextLimitTokens() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelContextLimitTokens() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get gpuOnlyMaxContextTokens => $_getIZ(1);
  @$pb.TagNumber(2)
  set gpuOnlyMaxContextTokens($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGpuOnlyMaxContextTokens() => $_has(1);
  @$pb.TagNumber(2)
  void clearGpuOnlyMaxContextTokens() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get hybridMaxContextTokens => $_getIZ(2);
  @$pb.TagNumber(3)
  set hybridMaxContextTokens($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHybridMaxContextTokens() => $_has(2);
  @$pb.TagNumber(3)
  void clearHybridMaxContextTokens() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get effectiveContextTokens => $_getIZ(3);
  @$pb.TagNumber(4)
  set effectiveContextTokens($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEffectiveContextTokens() => $_has(3);
  @$pb.TagNumber(4)
  void clearEffectiveContextTokens() => $_clearField(4);

  /// The context length above which the cache spills into RAM. Unset when it
  /// never does.
  @$pb.TagNumber(5)
  $core.int get ramRequiredAfterTokens => $_getIZ(4);
  @$pb.TagNumber(5)
  set ramRequiredAfterTokens($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRamRequiredAfterTokens() => $_has(4);
  @$pb.TagNumber(5)
  void clearRamRequiredAfterTokens() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get kvBytesPerTokenAtStart => $_getI64(5);
  @$pb.TagNumber(6)
  set kvBytesPerTokenAtStart($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasKvBytesPerTokenAtStart() => $_has(5);
  @$pb.TagNumber(6)
  void clearKvBytesPerTokenAtStart() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get maxSequences => $_getIZ(6);
  @$pb.TagNumber(7)
  set maxSequences($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxSequences() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxSequences() => $_clearField(7);

  @$pb.TagNumber(8)
  KvCacheDtype get kvCacheDtype => $_getN(7);
  @$pb.TagNumber(8)
  set kvCacheDtype(KvCacheDtype value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasKvCacheDtype() => $_has(7);
  @$pb.TagNumber(8)
  void clearKvCacheDtype() => $_clearField(8);

  @$pb.TagNumber(9)
  Priority get priority => $_getN(8);
  @$pb.TagNumber(9)
  set priority(Priority value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPriority() => $_has(8);
  @$pb.TagNumber(9)
  void clearPriority() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get pinned => $_getBF(9);
  @$pb.TagNumber(10)
  set pinned($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPinned() => $_has(9);
  @$pb.TagNumber(10)
  void clearPinned() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get restartRequired => $_getBF(10);
  @$pb.TagNumber(11)
  set restartRequired($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasRestartRequired() => $_has(10);
  @$pb.TagNumber(11)
  void clearRestartRequired() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get usesRam => $_getBF(11);
  @$pb.TagNumber(12)
  set usesRam($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUsesRam() => $_has(11);
  @$pb.TagNumber(12)
  void clearUsesRam() => $_clearField(12);

  @$pb.TagNumber(13)
  ResourceBreakdown get memory => $_getN(12);
  @$pb.TagNumber(13)
  set memory(ResourceBreakdown value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasMemory() => $_has(12);
  @$pb.TagNumber(13)
  void clearMemory() => $_clearField(13);
  @$pb.TagNumber(13)
  ResourceBreakdown ensureMemory() => $_ensure(12);

  @$pb.TagNumber(14)
  Confidence get confidence => $_getN(13);
  @$pb.TagNumber(14)
  set confidence(Confidence value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasConfidence() => $_has(13);
  @$pb.TagNumber(14)
  void clearConfidence() => $_clearField(14);

  @$pb.TagNumber(15)
  $pb.PbList<$core.String> get warnings => $_getList(14);

  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get affectedRestartInstances => $_getList(15);

  @$pb.TagNumber(17)
  PreflightReport get preflight => $_getN(16);
  @$pb.TagNumber(17)
  set preflight(PreflightReport value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasPreflight() => $_has(16);
  @$pb.TagNumber(17)
  void clearPreflight() => $_clearField(17);
  @$pb.TagNumber(17)
  PreflightReport ensurePreflight() => $_ensure(16);
}

/// Fallback records one setting the engine had to give up on, and why.
class Fallback extends $pb.GeneratedMessage {
  factory Fallback({
    $core.String? setting,
    $core.String? from,
    $core.String? to,
    $core.String? reason,
  }) {
    final result = create();
    if (setting != null) result.setting = setting;
    if (from != null) result.from = from;
    if (to != null) result.to = to;
    if (reason != null) result.reason = reason;
    return result;
  }

  Fallback._();

  factory Fallback.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Fallback.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Fallback',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'setting')
    ..aOS(2, _omitFieldNames ? '' : 'from')
    ..aOS(3, _omitFieldNames ? '' : 'to')
    ..aOS(4, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Fallback clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Fallback copyWith(void Function(Fallback) updates) =>
      super.copyWith((message) => updates(message as Fallback)) as Fallback;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Fallback create() => Fallback._();
  @$core.override
  Fallback createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Fallback getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Fallback>(create);
  static Fallback? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get setting => $_getSZ(0);
  @$pb.TagNumber(1)
  set setting($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSetting() => $_has(0);
  @$pb.TagNumber(1)
  void clearSetting() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get from => $_getSZ(1);
  @$pb.TagNumber(2)
  set from($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFrom() => $_has(1);
  @$pb.TagNumber(2)
  void clearFrom() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get to => $_getSZ(2);
  @$pb.TagNumber(3)
  set to($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTo() => $_has(2);
  @$pb.TagNumber(3)
  void clearTo() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reason => $_getSZ(3);
  @$pb.TagNumber(4)
  set reason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);
}

/// SuggestedFix is the one-click remedy offered for a failure. The action is
/// what UpdateInstance takes as apply_fix.
class SuggestedFix extends $pb.GeneratedMessage {
  factory SuggestedFix({
    $core.String? action,
    $core.String? label,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (label != null) result.label = label;
    return result;
  }

  SuggestedFix._();

  factory SuggestedFix.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuggestedFix.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuggestedFix',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestedFix clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestedFix copyWith(void Function(SuggestedFix) updates) =>
      super.copyWith((message) => updates(message as SuggestedFix))
          as SuggestedFix;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuggestedFix create() => SuggestedFix._();
  @$core.override
  SuggestedFix createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuggestedFix getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuggestedFix>(create);
  static SuggestedFix? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);
}

/// EngineInstance is one served model.
class EngineInstance extends $pb.GeneratedMessage {
  factory EngineInstance({
    $core.String? id,
    InstanceState? state,
    $core.String? modelId,
    $core.String? servedModelName,
    EngineConfig? requestedConfig,
    EngineConfig? effectiveConfig,
    ContextPlan? plan,
    RuntimeKind? runtime,
    Priority? priority,
    $core.bool? pinned,
    $core.bool? autostart,
    $core.bool? showInChatPicker,
    Placement? placement,
    $core.int? activeRequests,
    $3.Timestamp? lastUsedAt,
    $3.Timestamp? idleExpiresAt,
    GuardState? guardState,
    $core.Iterable<$core.String>? restartRequiredFields,
    $core.Iterable<Fallback>? fallbacks,
    $core.String? error,
    $core.String? errorSummary,
    $core.String? errorCode,
    SuggestedFix? suggestedFix,
    $core.String? phase,
    $core.String? detailMessage,
    $core.double? progress,
    $core.String? endpointName,
    $fixnum.Int64? planRevision,
    $3.Timestamp? createdAt,
    $3.Timestamp? updatedAt,
    $core.bool? gatewayAutostart,
    $core.bool? restartOnCrash,
    $core.int? idleTimeoutSeconds,
    $core.String? nodeId,
    $core.String? nodeName,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (state != null) result.state = state;
    if (modelId != null) result.modelId = modelId;
    if (servedModelName != null) result.servedModelName = servedModelName;
    if (requestedConfig != null) result.requestedConfig = requestedConfig;
    if (effectiveConfig != null) result.effectiveConfig = effectiveConfig;
    if (plan != null) result.plan = plan;
    if (runtime != null) result.runtime = runtime;
    if (priority != null) result.priority = priority;
    if (pinned != null) result.pinned = pinned;
    if (autostart != null) result.autostart = autostart;
    if (showInChatPicker != null) result.showInChatPicker = showInChatPicker;
    if (placement != null) result.placement = placement;
    if (activeRequests != null) result.activeRequests = activeRequests;
    if (lastUsedAt != null) result.lastUsedAt = lastUsedAt;
    if (idleExpiresAt != null) result.idleExpiresAt = idleExpiresAt;
    if (guardState != null) result.guardState = guardState;
    if (restartRequiredFields != null)
      result.restartRequiredFields.addAll(restartRequiredFields);
    if (fallbacks != null) result.fallbacks.addAll(fallbacks);
    if (error != null) result.error = error;
    if (errorSummary != null) result.errorSummary = errorSummary;
    if (errorCode != null) result.errorCode = errorCode;
    if (suggestedFix != null) result.suggestedFix = suggestedFix;
    if (phase != null) result.phase = phase;
    if (detailMessage != null) result.detailMessage = detailMessage;
    if (progress != null) result.progress = progress;
    if (endpointName != null) result.endpointName = endpointName;
    if (planRevision != null) result.planRevision = planRevision;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (gatewayAutostart != null) result.gatewayAutostart = gatewayAutostart;
    if (restartOnCrash != null) result.restartOnCrash = restartOnCrash;
    if (idleTimeoutSeconds != null)
      result.idleTimeoutSeconds = idleTimeoutSeconds;
    if (nodeId != null) result.nodeId = nodeId;
    if (nodeName != null) result.nodeName = nodeName;
    return result;
  }

  EngineInstance._();

  factory EngineInstance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineInstance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineInstance',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<InstanceState>(2, _omitFieldNames ? '' : 'state',
        enumValues: InstanceState.values)
    ..aOS(3, _omitFieldNames ? '' : 'modelId')
    ..aOS(4, _omitFieldNames ? '' : 'servedModelName')
    ..aOM<EngineConfig>(5, _omitFieldNames ? '' : 'requestedConfig',
        subBuilder: EngineConfig.create)
    ..aOM<EngineConfig>(6, _omitFieldNames ? '' : 'effectiveConfig',
        subBuilder: EngineConfig.create)
    ..aOM<ContextPlan>(7, _omitFieldNames ? '' : 'plan',
        subBuilder: ContextPlan.create)
    ..aE<RuntimeKind>(8, _omitFieldNames ? '' : 'runtime',
        enumValues: RuntimeKind.values)
    ..aE<Priority>(9, _omitFieldNames ? '' : 'priority',
        enumValues: Priority.values)
    ..aOB(10, _omitFieldNames ? '' : 'pinned')
    ..aOB(11, _omitFieldNames ? '' : 'autostart')
    ..aOB(12, _omitFieldNames ? '' : 'showInChatPicker')
    ..aE<Placement>(13, _omitFieldNames ? '' : 'placement',
        enumValues: Placement.values)
    ..aI(14, _omitFieldNames ? '' : 'activeRequests')
    ..aOM<$3.Timestamp>(15, _omitFieldNames ? '' : 'lastUsedAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(16, _omitFieldNames ? '' : 'idleExpiresAt',
        subBuilder: $3.Timestamp.create)
    ..aE<GuardState>(17, _omitFieldNames ? '' : 'guardState',
        enumValues: GuardState.values)
    ..pPS(18, _omitFieldNames ? '' : 'restartRequiredFields')
    ..pPM<Fallback>(19, _omitFieldNames ? '' : 'fallbacks',
        subBuilder: Fallback.create)
    ..aOS(20, _omitFieldNames ? '' : 'error')
    ..aOS(21, _omitFieldNames ? '' : 'errorSummary')
    ..aOS(22, _omitFieldNames ? '' : 'errorCode')
    ..aOM<SuggestedFix>(23, _omitFieldNames ? '' : 'suggestedFix',
        subBuilder: SuggestedFix.create)
    ..aOS(24, _omitFieldNames ? '' : 'phase')
    ..aOS(25, _omitFieldNames ? '' : 'detailMessage')
    ..aD(26, _omitFieldNames ? '' : 'progress')
    ..aOS(27, _omitFieldNames ? '' : 'endpointName')
    ..aInt64(28, _omitFieldNames ? '' : 'planRevision')
    ..aOM<$3.Timestamp>(29, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(30, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $3.Timestamp.create)
    ..aOB(31, _omitFieldNames ? '' : 'gatewayAutostart')
    ..aOB(32, _omitFieldNames ? '' : 'restartOnCrash')
    ..aI(33, _omitFieldNames ? '' : 'idleTimeoutSeconds')
    ..aOS(34, _omitFieldNames ? '' : 'nodeId')
    ..aOS(35, _omitFieldNames ? '' : 'nodeName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineInstance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineInstance copyWith(void Function(EngineInstance) updates) =>
      super.copyWith((message) => updates(message as EngineInstance))
          as EngineInstance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineInstance create() => EngineInstance._();
  @$core.override
  EngineInstance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineInstance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineInstance>(create);
  static EngineInstance? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  InstanceState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(InstanceState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get modelId => $_getSZ(2);
  @$pb.TagNumber(3)
  set modelId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModelId() => $_has(2);
  @$pb.TagNumber(3)
  void clearModelId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get servedModelName => $_getSZ(3);
  @$pb.TagNumber(4)
  set servedModelName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasServedModelName() => $_has(3);
  @$pb.TagNumber(4)
  void clearServedModelName() => $_clearField(4);

  @$pb.TagNumber(5)
  EngineConfig get requestedConfig => $_getN(4);
  @$pb.TagNumber(5)
  set requestedConfig(EngineConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRequestedConfig() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequestedConfig() => $_clearField(5);
  @$pb.TagNumber(5)
  EngineConfig ensureRequestedConfig() => $_ensure(4);

  @$pb.TagNumber(6)
  EngineConfig get effectiveConfig => $_getN(5);
  @$pb.TagNumber(6)
  set effectiveConfig(EngineConfig value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasEffectiveConfig() => $_has(5);
  @$pb.TagNumber(6)
  void clearEffectiveConfig() => $_clearField(6);
  @$pb.TagNumber(6)
  EngineConfig ensureEffectiveConfig() => $_ensure(5);

  @$pb.TagNumber(7)
  ContextPlan get plan => $_getN(6);
  @$pb.TagNumber(7)
  set plan(ContextPlan value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPlan() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlan() => $_clearField(7);
  @$pb.TagNumber(7)
  ContextPlan ensurePlan() => $_ensure(6);

  @$pb.TagNumber(8)
  RuntimeKind get runtime => $_getN(7);
  @$pb.TagNumber(8)
  set runtime(RuntimeKind value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasRuntime() => $_has(7);
  @$pb.TagNumber(8)
  void clearRuntime() => $_clearField(8);

  @$pb.TagNumber(9)
  Priority get priority => $_getN(8);
  @$pb.TagNumber(9)
  set priority(Priority value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPriority() => $_has(8);
  @$pb.TagNumber(9)
  void clearPriority() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get pinned => $_getBF(9);
  @$pb.TagNumber(10)
  set pinned($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPinned() => $_has(9);
  @$pb.TagNumber(10)
  void clearPinned() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get autostart => $_getBF(10);
  @$pb.TagNumber(11)
  set autostart($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasAutostart() => $_has(10);
  @$pb.TagNumber(11)
  void clearAutostart() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get showInChatPicker => $_getBF(11);
  @$pb.TagNumber(12)
  set showInChatPicker($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasShowInChatPicker() => $_has(11);
  @$pb.TagNumber(12)
  void clearShowInChatPicker() => $_clearField(12);

  @$pb.TagNumber(13)
  Placement get placement => $_getN(12);
  @$pb.TagNumber(13)
  set placement(Placement value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasPlacement() => $_has(12);
  @$pb.TagNumber(13)
  void clearPlacement() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get activeRequests => $_getIZ(13);
  @$pb.TagNumber(14)
  set activeRequests($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasActiveRequests() => $_has(13);
  @$pb.TagNumber(14)
  void clearActiveRequests() => $_clearField(14);

  @$pb.TagNumber(15)
  $3.Timestamp get lastUsedAt => $_getN(14);
  @$pb.TagNumber(15)
  set lastUsedAt($3.Timestamp value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasLastUsedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearLastUsedAt() => $_clearField(15);
  @$pb.TagNumber(15)
  $3.Timestamp ensureLastUsedAt() => $_ensure(14);

  @$pb.TagNumber(16)
  $3.Timestamp get idleExpiresAt => $_getN(15);
  @$pb.TagNumber(16)
  set idleExpiresAt($3.Timestamp value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasIdleExpiresAt() => $_has(15);
  @$pb.TagNumber(16)
  void clearIdleExpiresAt() => $_clearField(16);
  @$pb.TagNumber(16)
  $3.Timestamp ensureIdleExpiresAt() => $_ensure(15);

  @$pb.TagNumber(17)
  GuardState get guardState => $_getN(16);
  @$pb.TagNumber(17)
  set guardState(GuardState value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasGuardState() => $_has(16);
  @$pb.TagNumber(17)
  void clearGuardState() => $_clearField(17);

  @$pb.TagNumber(18)
  $pb.PbList<$core.String> get restartRequiredFields => $_getList(17);

  @$pb.TagNumber(19)
  $pb.PbList<Fallback> get fallbacks => $_getList(18);

  @$pb.TagNumber(20)
  $core.String get error => $_getSZ(19);
  @$pb.TagNumber(20)
  set error($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasError() => $_has(19);
  @$pb.TagNumber(20)
  void clearError() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get errorSummary => $_getSZ(20);
  @$pb.TagNumber(21)
  set errorSummary($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasErrorSummary() => $_has(20);
  @$pb.TagNumber(21)
  void clearErrorSummary() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get errorCode => $_getSZ(21);
  @$pb.TagNumber(22)
  set errorCode($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasErrorCode() => $_has(21);
  @$pb.TagNumber(22)
  void clearErrorCode() => $_clearField(22);

  @$pb.TagNumber(23)
  SuggestedFix get suggestedFix => $_getN(22);
  @$pb.TagNumber(23)
  set suggestedFix(SuggestedFix value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasSuggestedFix() => $_has(22);
  @$pb.TagNumber(23)
  void clearSuggestedFix() => $_clearField(23);
  @$pb.TagNumber(23)
  SuggestedFix ensureSuggestedFix() => $_ensure(22);

  @$pb.TagNumber(24)
  $core.String get phase => $_getSZ(23);
  @$pb.TagNumber(24)
  set phase($core.String value) => $_setString(23, value);
  @$pb.TagNumber(24)
  $core.bool hasPhase() => $_has(23);
  @$pb.TagNumber(24)
  void clearPhase() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.String get detailMessage => $_getSZ(24);
  @$pb.TagNumber(25)
  set detailMessage($core.String value) => $_setString(24, value);
  @$pb.TagNumber(25)
  $core.bool hasDetailMessage() => $_has(24);
  @$pb.TagNumber(25)
  void clearDetailMessage() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.double get progress => $_getN(25);
  @$pb.TagNumber(26)
  set progress($core.double value) => $_setDouble(25, value);
  @$pb.TagNumber(26)
  $core.bool hasProgress() => $_has(25);
  @$pb.TagNumber(26)
  void clearProgress() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.String get endpointName => $_getSZ(26);
  @$pb.TagNumber(27)
  set endpointName($core.String value) => $_setString(26, value);
  @$pb.TagNumber(27)
  $core.bool hasEndpointName() => $_has(26);
  @$pb.TagNumber(27)
  void clearEndpointName() => $_clearField(27);

  @$pb.TagNumber(28)
  $fixnum.Int64 get planRevision => $_getI64(27);
  @$pb.TagNumber(28)
  set planRevision($fixnum.Int64 value) => $_setInt64(27, value);
  @$pb.TagNumber(28)
  $core.bool hasPlanRevision() => $_has(27);
  @$pb.TagNumber(28)
  void clearPlanRevision() => $_clearField(28);

  @$pb.TagNumber(29)
  $3.Timestamp get createdAt => $_getN(28);
  @$pb.TagNumber(29)
  set createdAt($3.Timestamp value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasCreatedAt() => $_has(28);
  @$pb.TagNumber(29)
  void clearCreatedAt() => $_clearField(29);
  @$pb.TagNumber(29)
  $3.Timestamp ensureCreatedAt() => $_ensure(28);

  @$pb.TagNumber(30)
  $3.Timestamp get updatedAt => $_getN(29);
  @$pb.TagNumber(30)
  set updatedAt($3.Timestamp value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasUpdatedAt() => $_has(29);
  @$pb.TagNumber(30)
  void clearUpdatedAt() => $_clearField(30);
  @$pb.TagNumber(30)
  $3.Timestamp ensureUpdatedAt() => $_ensure(29);

  /// Mirrors of the config switches, so a list view does not have to reach into
  /// requested_config to render the toggles beside the instance.
  @$pb.TagNumber(31)
  $core.bool get gatewayAutostart => $_getBF(30);
  @$pb.TagNumber(31)
  set gatewayAutostart($core.bool value) => $_setBool(30, value);
  @$pb.TagNumber(31)
  $core.bool hasGatewayAutostart() => $_has(30);
  @$pb.TagNumber(31)
  void clearGatewayAutostart() => $_clearField(31);

  @$pb.TagNumber(32)
  $core.bool get restartOnCrash => $_getBF(31);
  @$pb.TagNumber(32)
  set restartOnCrash($core.bool value) => $_setBool(31, value);
  @$pb.TagNumber(32)
  $core.bool hasRestartOnCrash() => $_has(31);
  @$pb.TagNumber(32)
  void clearRestartOnCrash() => $_clearField(32);

  @$pb.TagNumber(33)
  $core.int get idleTimeoutSeconds => $_getIZ(32);
  @$pb.TagNumber(33)
  set idleTimeoutSeconds($core.int value) => $_setSignedInt32(32, value);
  @$pb.TagNumber(33)
  $core.bool hasIdleTimeoutSeconds() => $_has(32);
  @$pb.TagNumber(33)
  void clearIdleTimeoutSeconds() => $_clearField(33);

  /// Empty for an instance on this machine. An instance running on a node is
  /// listed beside the local ones and behaves the same way; only the process is
  /// elsewhere and its output is streamed back through the tunnel.
  @$pb.TagNumber(34)
  $core.String get nodeId => $_getSZ(33);
  @$pb.TagNumber(34)
  set nodeId($core.String value) => $_setString(33, value);
  @$pb.TagNumber(34)
  $core.bool hasNodeId() => $_has(33);
  @$pb.TagNumber(34)
  void clearNodeId() => $_clearField(34);

  @$pb.TagNumber(35)
  $core.String get nodeName => $_getSZ(34);
  @$pb.TagNumber(35)
  set nodeName($core.String value) => $_setString(34, value);
  @$pb.TagNumber(35)
  $core.bool hasNodeName() => $_has(34);
  @$pb.TagNumber(35)
  void clearNodeName() => $_clearField(35);
}

/// ResourceConflict says which resource was short and by how much. It is
/// carried on a failed operation and, as an error detail, on the call that
/// could not be scheduled.
class ResourceConflict extends $pb.GeneratedMessage {
  factory ResourceConflict({
    $core.String? resource,
    $fixnum.Int64? requiredBytes,
    $fixnum.Int64? availableBytes,
    $fixnum.Int64? reserveBytes,
    $fixnum.Int64? totalBytes,
    $core.String? reason,
    $core.String? instanceId,
  }) {
    final result = create();
    if (resource != null) result.resource = resource;
    if (requiredBytes != null) result.requiredBytes = requiredBytes;
    if (availableBytes != null) result.availableBytes = availableBytes;
    if (reserveBytes != null) result.reserveBytes = reserveBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (reason != null) result.reason = reason;
    if (instanceId != null) result.instanceId = instanceId;
    return result;
  }

  ResourceConflict._();

  factory ResourceConflict.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResourceConflict.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResourceConflict',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'resource')
    ..aInt64(2, _omitFieldNames ? '' : 'requiredBytes')
    ..aInt64(3, _omitFieldNames ? '' : 'availableBytes')
    ..aInt64(4, _omitFieldNames ? '' : 'reserveBytes')
    ..aInt64(5, _omitFieldNames ? '' : 'totalBytes')
    ..aOS(6, _omitFieldNames ? '' : 'reason')
    ..aOS(7, _omitFieldNames ? '' : 'instanceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResourceConflict clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResourceConflict copyWith(void Function(ResourceConflict) updates) =>
      super.copyWith((message) => updates(message as ResourceConflict))
          as ResourceConflict;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResourceConflict create() => ResourceConflict._();
  @$core.override
  ResourceConflict createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResourceConflict getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResourceConflict>(create);
  static ResourceConflict? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get resource => $_getSZ(0);
  @$pb.TagNumber(1)
  set resource($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResource() => $_has(0);
  @$pb.TagNumber(1)
  void clearResource() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get requiredBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set requiredBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequiredBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequiredBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get availableBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set availableBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvailableBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvailableBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get reserveBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set reserveBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReserveBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearReserveBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get totalBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set totalBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get reason => $_getSZ(5);
  @$pb.TagNumber(6)
  set reason($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReason() => $_has(5);
  @$pb.TagNumber(6)
  void clearReason() => $_clearField(6);

  /// Set when the conflict is attributed to a specific instance.
  @$pb.TagNumber(7)
  $core.String get instanceId => $_getSZ(6);
  @$pb.TagNumber(7)
  set instanceId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasInstanceId() => $_has(6);
  @$pb.TagNumber(7)
  void clearInstanceId() => $_clearField(7);
}

/// EngineOperation is a scheduled unit of work. Its type is free-form on
/// purpose: it labels the work for the UI, and new kinds of work should not
/// need a schema change to be reportable.
class EngineOperation extends $pb.GeneratedMessage {
  factory EngineOperation({
    $core.String? id,
    $core.String? type,
    OperationState? state,
    $core.String? instanceId,
    $core.int? queuePosition,
    $core.double? progress,
    $core.String? message,
    $core.String? detailMessage,
    $core.String? phase,
    $core.String? error,
    $core.String? errorSummary,
    $core.String? errorCode,
    SuggestedFix? suggestedFix,
    ResourceConflict? resourceConflict,
    $3.Timestamp? createdAt,
    $3.Timestamp? updatedAt,
    $3.Timestamp? finishedAt,
    $core.Iterable<$core.String>? evictedInstanceIds,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (state != null) result.state = state;
    if (instanceId != null) result.instanceId = instanceId;
    if (queuePosition != null) result.queuePosition = queuePosition;
    if (progress != null) result.progress = progress;
    if (message != null) result.message = message;
    if (detailMessage != null) result.detailMessage = detailMessage;
    if (phase != null) result.phase = phase;
    if (error != null) result.error = error;
    if (errorSummary != null) result.errorSummary = errorSummary;
    if (errorCode != null) result.errorCode = errorCode;
    if (suggestedFix != null) result.suggestedFix = suggestedFix;
    if (resourceConflict != null) result.resourceConflict = resourceConflict;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (finishedAt != null) result.finishedAt = finishedAt;
    if (evictedInstanceIds != null)
      result.evictedInstanceIds.addAll(evictedInstanceIds);
    return result;
  }

  EngineOperation._();

  factory EngineOperation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineOperation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineOperation',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aE<OperationState>(3, _omitFieldNames ? '' : 'state',
        enumValues: OperationState.values)
    ..aOS(4, _omitFieldNames ? '' : 'instanceId')
    ..aI(5, _omitFieldNames ? '' : 'queuePosition')
    ..aD(6, _omitFieldNames ? '' : 'progress')
    ..aOS(7, _omitFieldNames ? '' : 'message')
    ..aOS(8, _omitFieldNames ? '' : 'detailMessage')
    ..aOS(9, _omitFieldNames ? '' : 'phase')
    ..aOS(10, _omitFieldNames ? '' : 'error')
    ..aOS(11, _omitFieldNames ? '' : 'errorSummary')
    ..aOS(12, _omitFieldNames ? '' : 'errorCode')
    ..aOM<SuggestedFix>(13, _omitFieldNames ? '' : 'suggestedFix',
        subBuilder: SuggestedFix.create)
    ..aOM<ResourceConflict>(14, _omitFieldNames ? '' : 'resourceConflict',
        subBuilder: ResourceConflict.create)
    ..aOM<$3.Timestamp>(15, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(16, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(17, _omitFieldNames ? '' : 'finishedAt',
        subBuilder: $3.Timestamp.create)
    ..pPS(18, _omitFieldNames ? '' : 'evictedInstanceIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineOperation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineOperation copyWith(void Function(EngineOperation) updates) =>
      super.copyWith((message) => updates(message as EngineOperation))
          as EngineOperation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineOperation create() => EngineOperation._();
  @$core.override
  EngineOperation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineOperation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineOperation>(create);
  static EngineOperation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  OperationState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(OperationState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get instanceId => $_getSZ(3);
  @$pb.TagNumber(4)
  set instanceId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInstanceId() => $_has(3);
  @$pb.TagNumber(4)
  void clearInstanceId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get queuePosition => $_getIZ(4);
  @$pb.TagNumber(5)
  set queuePosition($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasQueuePosition() => $_has(4);
  @$pb.TagNumber(5)
  void clearQueuePosition() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get progress => $_getN(5);
  @$pb.TagNumber(6)
  set progress($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProgress() => $_has(5);
  @$pb.TagNumber(6)
  void clearProgress() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get message => $_getSZ(6);
  @$pb.TagNumber(7)
  set message($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessage() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get detailMessage => $_getSZ(7);
  @$pb.TagNumber(8)
  set detailMessage($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDetailMessage() => $_has(7);
  @$pb.TagNumber(8)
  void clearDetailMessage() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get phase => $_getSZ(8);
  @$pb.TagNumber(9)
  set phase($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPhase() => $_has(8);
  @$pb.TagNumber(9)
  void clearPhase() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get error => $_getSZ(9);
  @$pb.TagNumber(10)
  set error($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasError() => $_has(9);
  @$pb.TagNumber(10)
  void clearError() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get errorSummary => $_getSZ(10);
  @$pb.TagNumber(11)
  set errorSummary($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasErrorSummary() => $_has(10);
  @$pb.TagNumber(11)
  void clearErrorSummary() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get errorCode => $_getSZ(11);
  @$pb.TagNumber(12)
  set errorCode($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasErrorCode() => $_has(11);
  @$pb.TagNumber(12)
  void clearErrorCode() => $_clearField(12);

  @$pb.TagNumber(13)
  SuggestedFix get suggestedFix => $_getN(12);
  @$pb.TagNumber(13)
  set suggestedFix(SuggestedFix value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasSuggestedFix() => $_has(12);
  @$pb.TagNumber(13)
  void clearSuggestedFix() => $_clearField(13);
  @$pb.TagNumber(13)
  SuggestedFix ensureSuggestedFix() => $_ensure(12);

  @$pb.TagNumber(14)
  ResourceConflict get resourceConflict => $_getN(13);
  @$pb.TagNumber(14)
  set resourceConflict(ResourceConflict value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasResourceConflict() => $_has(13);
  @$pb.TagNumber(14)
  void clearResourceConflict() => $_clearField(14);
  @$pb.TagNumber(14)
  ResourceConflict ensureResourceConflict() => $_ensure(13);

  @$pb.TagNumber(15)
  $3.Timestamp get createdAt => $_getN(14);
  @$pb.TagNumber(15)
  set createdAt($3.Timestamp value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasCreatedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearCreatedAt() => $_clearField(15);
  @$pb.TagNumber(15)
  $3.Timestamp ensureCreatedAt() => $_ensure(14);

  @$pb.TagNumber(16)
  $3.Timestamp get updatedAt => $_getN(15);
  @$pb.TagNumber(16)
  set updatedAt($3.Timestamp value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasUpdatedAt() => $_has(15);
  @$pb.TagNumber(16)
  void clearUpdatedAt() => $_clearField(16);
  @$pb.TagNumber(16)
  $3.Timestamp ensureUpdatedAt() => $_ensure(15);

  @$pb.TagNumber(17)
  $3.Timestamp get finishedAt => $_getN(16);
  @$pb.TagNumber(17)
  set finishedAt($3.Timestamp value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasFinishedAt() => $_has(16);
  @$pb.TagNumber(17)
  void clearFinishedAt() => $_clearField(17);
  @$pb.TagNumber(17)
  $3.Timestamp ensureFinishedAt() => $_ensure(16);

  @$pb.TagNumber(18)
  $pb.PbList<$core.String> get evictedInstanceIds => $_getList(17);
}

/// EngineError is attached as a status detail when a call fails for a reason
/// the client acts on. The HTTP API put the same fields in the error body, and
/// the client read them back off the JSON.
class EngineError extends $pb.GeneratedMessage {
  factory EngineError({
    $core.String? code,
    $core.String? message,
    ResourceConflict? conflict,
    $core.String? reason,
    $core.String? remediation,
    $core.String? modelFingerprint,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (conflict != null) result.conflict = conflict;
    if (reason != null) result.reason = reason;
    if (remediation != null) result.remediation = remediation;
    if (modelFingerprint != null) result.modelFingerprint = modelFingerprint;
    return result;
  }

  EngineError._();

  factory EngineError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineError',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<ResourceConflict>(3, _omitFieldNames ? '' : 'conflict',
        subBuilder: ResourceConflict.create)
    ..aOS(4, _omitFieldNames ? '' : 'reason')
    ..aOS(5, _omitFieldNames ? '' : 'remediation')
    ..aOS(6, _omitFieldNames ? '' : 'modelFingerprint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineError copyWith(void Function(EngineError) updates) =>
      super.copyWith((message) => updates(message as EngineError))
          as EngineError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineError create() => EngineError._();
  @$core.override
  EngineError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineError>(create);
  static EngineError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  /// Set when code is resource_conflict.
  @$pb.TagNumber(3)
  ResourceConflict get conflict => $_getN(2);
  @$pb.TagNumber(3)
  set conflict(ResourceConflict value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConflict() => $_has(2);
  @$pb.TagNumber(3)
  void clearConflict() => $_clearField(3);
  @$pb.TagNumber(3)
  ResourceConflict ensureConflict() => $_ensure(2);

  /// Set when code is gpu_runtime_unavailable.
  @$pb.TagNumber(4)
  $core.String get reason => $_getSZ(3);
  @$pb.TagNumber(4)
  set reason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get remediation => $_getSZ(4);
  @$pb.TagNumber(5)
  set remediation($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRemediation() => $_has(4);
  @$pb.TagNumber(5)
  void clearRemediation() => $_clearField(5);

  /// Retired with the SafeTensors runtimes:
  /// would have to cover.
  @$pb.TagNumber(6)
  $core.String get modelFingerprint => $_getSZ(5);
  @$pb.TagNumber(6)
  set modelFingerprint($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModelFingerprint() => $_has(5);
  @$pb.TagNumber(6)
  void clearModelFingerprint() => $_clearField(6);
}

class ListModelsRequest extends $pb.GeneratedMessage {
  factory ListModelsRequest() => create();

  ListModelsRequest._();

  factory ListModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsRequest copyWith(void Function(ListModelsRequest) updates) =>
      super.copyWith((message) => updates(message as ListModelsRequest))
          as ListModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListModelsRequest create() => ListModelsRequest._();
  @$core.override
  ListModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListModelsRequest>(create);
  static ListModelsRequest? _defaultInstance;
}

class ListModelsResponse extends $pb.GeneratedMessage {
  factory ListModelsResponse({
    $core.Iterable<ModelRecord>? models,
    $core.String? modelDir,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    if (modelDir != null) result.modelDir = modelDir;
    return result;
  }

  ListModelsResponse._();

  factory ListModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<ModelRecord>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelRecord.create)
    ..aOS(2, _omitFieldNames ? '' : 'modelDir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse copyWith(void Function(ListModelsResponse) updates) =>
      super.copyWith((message) => updates(message as ListModelsResponse))
          as ListModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListModelsResponse create() => ListModelsResponse._();
  @$core.override
  ListModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListModelsResponse>(create);
  static ListModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModelRecord> get models => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get modelDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelDir($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelDir() => $_clearField(2);
}

class RescanModelsRequest extends $pb.GeneratedMessage {
  factory RescanModelsRequest() => create();

  RescanModelsRequest._();

  factory RescanModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RescanModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RescanModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanModelsRequest copyWith(void Function(RescanModelsRequest) updates) =>
      super.copyWith((message) => updates(message as RescanModelsRequest))
          as RescanModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RescanModelsRequest create() => RescanModelsRequest._();
  @$core.override
  RescanModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RescanModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RescanModelsRequest>(create);
  static RescanModelsRequest? _defaultInstance;
}

class RescanModelsResponse extends $pb.GeneratedMessage {
  factory RescanModelsResponse({
    $core.Iterable<ModelRecord>? models,
    $core.String? modelDir,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    if (modelDir != null) result.modelDir = modelDir;
    return result;
  }

  RescanModelsResponse._();

  factory RescanModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RescanModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RescanModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<ModelRecord>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelRecord.create)
    ..aOS(2, _omitFieldNames ? '' : 'modelDir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanModelsResponse copyWith(void Function(RescanModelsResponse) updates) =>
      super.copyWith((message) => updates(message as RescanModelsResponse))
          as RescanModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RescanModelsResponse create() => RescanModelsResponse._();
  @$core.override
  RescanModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RescanModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RescanModelsResponse>(create);
  static RescanModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModelRecord> get models => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get modelDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelDir($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelDir() => $_clearField(2);
}

class DeleteModelRequest extends $pb.GeneratedMessage {
  factory DeleteModelRequest({
    $core.String? modelId,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    return result;
  }

  DeleteModelRequest._();

  factory DeleteModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteModelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteModelRequest copyWith(void Function(DeleteModelRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteModelRequest))
          as DeleteModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteModelRequest create() => DeleteModelRequest._();
  @$core.override
  DeleteModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteModelRequest>(create);
  static DeleteModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);
}

/// The catalog after the deletion, so a client does not have to list again.
class DeleteModelResponse extends $pb.GeneratedMessage {
  factory DeleteModelResponse({
    $core.Iterable<ModelRecord>? models,
    $core.String? modelDir,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    if (modelDir != null) result.modelDir = modelDir;
    return result;
  }

  DeleteModelResponse._();

  factory DeleteModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteModelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<ModelRecord>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelRecord.create)
    ..aOS(2, _omitFieldNames ? '' : 'modelDir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteModelResponse copyWith(void Function(DeleteModelResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteModelResponse))
          as DeleteModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteModelResponse create() => DeleteModelResponse._();
  @$core.override
  DeleteModelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteModelResponse>(create);
  static DeleteModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModelRecord> get models => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get modelDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelDir($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelDir() => $_clearField(2);
}

class GetCapabilitiesRequest extends $pb.GeneratedMessage {
  factory GetCapabilitiesRequest() => create();

  GetCapabilitiesRequest._();

  factory GetCapabilitiesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetCapabilitiesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCapabilitiesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCapabilitiesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCapabilitiesRequest copyWith(
          void Function(GetCapabilitiesRequest) updates) =>
      super.copyWith((message) => updates(message as GetCapabilitiesRequest))
          as GetCapabilitiesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetCapabilitiesRequest create() => GetCapabilitiesRequest._();
  @$core.override
  GetCapabilitiesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetCapabilitiesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCapabilitiesRequest>(create);
  static GetCapabilitiesRequest? _defaultInstance;
}

class GetCapabilitiesResponse extends $pb.GeneratedMessage {
  factory GetCapabilitiesResponse({
    HardwareSnapshot? hardware,
    $core.Iterable<RuntimeCapability>? runtimes,
    EngineDefaults? defaults,
  }) {
    final result = create();
    if (hardware != null) result.hardware = hardware;
    if (runtimes != null) result.runtimes.addAll(runtimes);
    if (defaults != null) result.defaults = defaults;
    return result;
  }

  GetCapabilitiesResponse._();

  factory GetCapabilitiesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetCapabilitiesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCapabilitiesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<HardwareSnapshot>(1, _omitFieldNames ? '' : 'hardware',
        subBuilder: HardwareSnapshot.create)
    ..pPM<RuntimeCapability>(2, _omitFieldNames ? '' : 'runtimes',
        subBuilder: RuntimeCapability.create)
    ..aOM<EngineDefaults>(3, _omitFieldNames ? '' : 'defaults',
        subBuilder: EngineDefaults.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCapabilitiesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCapabilitiesResponse copyWith(
          void Function(GetCapabilitiesResponse) updates) =>
      super.copyWith((message) => updates(message as GetCapabilitiesResponse))
          as GetCapabilitiesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetCapabilitiesResponse create() => GetCapabilitiesResponse._();
  @$core.override
  GetCapabilitiesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetCapabilitiesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCapabilitiesResponse>(create);
  static GetCapabilitiesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  HardwareSnapshot get hardware => $_getN(0);
  @$pb.TagNumber(1)
  set hardware(HardwareSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHardware() => $_has(0);
  @$pb.TagNumber(1)
  void clearHardware() => $_clearField(1);
  @$pb.TagNumber(1)
  HardwareSnapshot ensureHardware() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<RuntimeCapability> get runtimes => $_getList(1);

  @$pb.TagNumber(3)
  EngineDefaults get defaults => $_getN(2);
  @$pb.TagNumber(3)
  set defaults(EngineDefaults value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDefaults() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaults() => $_clearField(3);
  @$pb.TagNumber(3)
  EngineDefaults ensureDefaults() => $_ensure(2);
}

class GetRecommendationRequest extends $pb.GeneratedMessage {
  factory GetRecommendationRequest({
    $core.String? modelId,
    EngineConfig? config,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    if (config != null) result.config = config;
    return result;
  }

  GetRecommendationRequest._();

  factory GetRecommendationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRecommendationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRecommendationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOM<EngineConfig>(2, _omitFieldNames ? '' : 'config',
        subBuilder: EngineConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRecommendationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRecommendationRequest copyWith(
          void Function(GetRecommendationRequest) updates) =>
      super.copyWith((message) => updates(message as GetRecommendationRequest))
          as GetRecommendationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRecommendationRequest create() => GetRecommendationRequest._();
  @$core.override
  GetRecommendationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetRecommendationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRecommendationRequest>(create);
  static GetRecommendationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  /// Merged over the engine defaults, the same way the HTTP body was.
  @$pb.TagNumber(2)
  EngineConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config(EngineConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  EngineConfig ensureConfig() => $_ensure(1);
}

class GetRecommendationResponse extends $pb.GeneratedMessage {
  factory GetRecommendationResponse({
    ContextPlan? plan,
  }) {
    final result = create();
    if (plan != null) result.plan = plan;
    return result;
  }

  GetRecommendationResponse._();

  factory GetRecommendationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRecommendationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRecommendationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<ContextPlan>(1, _omitFieldNames ? '' : 'plan',
        subBuilder: ContextPlan.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRecommendationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRecommendationResponse copyWith(
          void Function(GetRecommendationResponse) updates) =>
      super.copyWith((message) => updates(message as GetRecommendationResponse))
          as GetRecommendationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRecommendationResponse create() => GetRecommendationResponse._();
  @$core.override
  GetRecommendationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetRecommendationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRecommendationResponse>(create);
  static GetRecommendationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ContextPlan get plan => $_getN(0);
  @$pb.TagNumber(1)
  set plan(ContextPlan value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPlan() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlan() => $_clearField(1);
  @$pb.TagNumber(1)
  ContextPlan ensurePlan() => $_ensure(0);
}

/// SimulateModelEntry is one model to plan for, without starting it.
class SimulateModelEntry extends $pb.GeneratedMessage {
  factory SimulateModelEntry({
    $core.String? modelId,
    EngineConfig? config,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    if (config != null) result.config = config;
    return result;
  }

  SimulateModelEntry._();

  factory SimulateModelEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SimulateModelEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimulateModelEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOM<EngineConfig>(2, _omitFieldNames ? '' : 'config',
        subBuilder: EngineConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulateModelEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulateModelEntry copyWith(void Function(SimulateModelEntry) updates) =>
      super.copyWith((message) => updates(message as SimulateModelEntry))
          as SimulateModelEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SimulateModelEntry create() => SimulateModelEntry._();
  @$core.override
  SimulateModelEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SimulateModelEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulateModelEntry>(create);
  static SimulateModelEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  EngineConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config(EngineConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  EngineConfig ensureConfig() => $_ensure(1);
}

class SimulateParallelLoadRequest extends $pb.GeneratedMessage {
  factory SimulateParallelLoadRequest({
    $core.Iterable<SimulateModelEntry>? models,
    $core.bool? includeRunning,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    if (includeRunning != null) result.includeRunning = includeRunning;
    return result;
  }

  SimulateParallelLoadRequest._();

  factory SimulateParallelLoadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SimulateParallelLoadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimulateParallelLoadRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<SimulateModelEntry>(1, _omitFieldNames ? '' : 'models',
        subBuilder: SimulateModelEntry.create)
    ..aOB(2, _omitFieldNames ? '' : 'includeRunning')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulateParallelLoadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulateParallelLoadRequest copyWith(
          void Function(SimulateParallelLoadRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SimulateParallelLoadRequest))
          as SimulateParallelLoadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SimulateParallelLoadRequest create() =>
      SimulateParallelLoadRequest._();
  @$core.override
  SimulateParallelLoadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SimulateParallelLoadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulateParallelLoadRequest>(create);
  static SimulateParallelLoadRequest? _defaultInstance;

  /// Between 1 and 8 entries.
  @$pb.TagNumber(1)
  $pb.PbList<SimulateModelEntry> get models => $_getList(0);

  /// Whether the instances already holding memory are counted against the
  /// budget. Unset means true, which is what an omitted field meant.
  @$pb.TagNumber(2)
  $core.bool get includeRunning => $_getBF(1);
  @$pb.TagNumber(2)
  set includeRunning($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncludeRunning() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeRunning() => $_clearField(2);
}

/// SimulatedModel is how one entry of the request fared.
class SimulatedModel extends $pb.GeneratedMessage {
  factory SimulatedModel({
    $core.String? model,
    $core.bool? fits,
    $core.int? effectiveContextTokens,
    Placement? placement,
    MemoryAllocation? memory,
    $core.Iterable<$core.String>? warnings,
    $core.String? reason,
  }) {
    final result = create();
    if (model != null) result.model = model;
    if (fits != null) result.fits = fits;
    if (effectiveContextTokens != null)
      result.effectiveContextTokens = effectiveContextTokens;
    if (placement != null) result.placement = placement;
    if (memory != null) result.memory = memory;
    if (warnings != null) result.warnings.addAll(warnings);
    if (reason != null) result.reason = reason;
    return result;
  }

  SimulatedModel._();

  factory SimulatedModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SimulatedModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimulatedModel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'model')
    ..aOB(2, _omitFieldNames ? '' : 'fits')
    ..aI(3, _omitFieldNames ? '' : 'effectiveContextTokens')
    ..aE<Placement>(4, _omitFieldNames ? '' : 'placement',
        enumValues: Placement.values)
    ..aOM<MemoryAllocation>(5, _omitFieldNames ? '' : 'memory',
        subBuilder: MemoryAllocation.create)
    ..pPS(6, _omitFieldNames ? '' : 'warnings')
    ..aOS(7, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulatedModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulatedModel copyWith(void Function(SimulatedModel) updates) =>
      super.copyWith((message) => updates(message as SimulatedModel))
          as SimulatedModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SimulatedModel create() => SimulatedModel._();
  @$core.override
  SimulatedModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SimulatedModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulatedModel>(create);
  static SimulatedModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get model => $_getSZ(0);
  @$pb.TagNumber(1)
  set model($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get fits => $_getBF(1);
  @$pb.TagNumber(2)
  set fits($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFits() => $_has(1);
  @$pb.TagNumber(2)
  void clearFits() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get effectiveContextTokens => $_getIZ(2);
  @$pb.TagNumber(3)
  set effectiveContextTokens($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEffectiveContextTokens() => $_has(2);
  @$pb.TagNumber(3)
  void clearEffectiveContextTokens() => $_clearField(3);

  @$pb.TagNumber(4)
  Placement get placement => $_getN(3);
  @$pb.TagNumber(4)
  set placement(Placement value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPlacement() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlacement() => $_clearField(4);

  @$pb.TagNumber(5)
  MemoryAllocation get memory => $_getN(4);
  @$pb.TagNumber(5)
  set memory(MemoryAllocation value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMemory() => $_has(4);
  @$pb.TagNumber(5)
  void clearMemory() => $_clearField(5);
  @$pb.TagNumber(5)
  MemoryAllocation ensureMemory() => $_ensure(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get warnings => $_getList(5);

  /// Set instead of the numbers above when the planner reserved no budget.
  @$pb.TagNumber(7)
  $core.String get reason => $_getSZ(6);
  @$pb.TagNumber(7)
  set reason($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearReason() => $_clearField(7);
}

/// SimulatedGpuBudget is one GPU measured against what the simulation planned.
class SimulatedGpuBudget extends $pb.GeneratedMessage {
  factory SimulatedGpuBudget({
    $core.String? id,
    $core.String? name,
    $fixnum.Int64? vramTotalBytes,
    $fixnum.Int64? vramFreeBytes,
    $fixnum.Int64? plannedBytes,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (vramTotalBytes != null) result.vramTotalBytes = vramTotalBytes;
    if (vramFreeBytes != null) result.vramFreeBytes = vramFreeBytes;
    if (plannedBytes != null) result.plannedBytes = plannedBytes;
    return result;
  }

  SimulatedGpuBudget._();

  factory SimulatedGpuBudget.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SimulatedGpuBudget.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimulatedGpuBudget',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aInt64(3, _omitFieldNames ? '' : 'vramTotalBytes')
    ..aInt64(4, _omitFieldNames ? '' : 'vramFreeBytes')
    ..aInt64(5, _omitFieldNames ? '' : 'plannedBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulatedGpuBudget clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulatedGpuBudget copyWith(void Function(SimulatedGpuBudget) updates) =>
      super.copyWith((message) => updates(message as SimulatedGpuBudget))
          as SimulatedGpuBudget;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SimulatedGpuBudget create() => SimulatedGpuBudget._();
  @$core.override
  SimulatedGpuBudget createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SimulatedGpuBudget getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulatedGpuBudget>(create);
  static SimulatedGpuBudget? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get vramTotalBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set vramTotalBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVramTotalBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearVramTotalBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get vramFreeBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set vramFreeBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVramFreeBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearVramFreeBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get plannedBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set plannedBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPlannedBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlannedBytes() => $_clearField(5);
}

class SimulatedHost extends $pb.GeneratedMessage {
  factory SimulatedHost({
    $fixnum.Int64? ramTotalBytes,
    $fixnum.Int64? ramAvailableBytes,
    $fixnum.Int64? ramReserveBytes,
    $core.Iterable<SimulatedGpuBudget>? gpus,
  }) {
    final result = create();
    if (ramTotalBytes != null) result.ramTotalBytes = ramTotalBytes;
    if (ramAvailableBytes != null) result.ramAvailableBytes = ramAvailableBytes;
    if (ramReserveBytes != null) result.ramReserveBytes = ramReserveBytes;
    if (gpus != null) result.gpus.addAll(gpus);
    return result;
  }

  SimulatedHost._();

  factory SimulatedHost.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SimulatedHost.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimulatedHost',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'ramTotalBytes')
    ..aInt64(2, _omitFieldNames ? '' : 'ramAvailableBytes')
    ..aInt64(3, _omitFieldNames ? '' : 'ramReserveBytes')
    ..pPM<SimulatedGpuBudget>(4, _omitFieldNames ? '' : 'gpus',
        subBuilder: SimulatedGpuBudget.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulatedHost clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulatedHost copyWith(void Function(SimulatedHost) updates) =>
      super.copyWith((message) => updates(message as SimulatedHost))
          as SimulatedHost;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SimulatedHost create() => SimulatedHost._();
  @$core.override
  SimulatedHost createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SimulatedHost getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulatedHost>(create);
  static SimulatedHost? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ramTotalBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set ramTotalBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRamTotalBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearRamTotalBytes() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ramAvailableBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set ramAvailableBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRamAvailableBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearRamAvailableBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ramReserveBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set ramReserveBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRamReserveBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearRamReserveBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<SimulatedGpuBudget> get gpus => $_getList(3);
}

class SimulateParallelLoadResponse extends $pb.GeneratedMessage {
  factory SimulateParallelLoadResponse({
    $core.bool? feasible,
    $core.Iterable<SimulatedModel>? models,
    MemoryAllocation? totals,
    SimulatedHost? host,
    $core.Iterable<$core.String>? affectedRunningInstances,
    $core.Iterable<$core.String>? recommendations,
    $core.String? reason,
  }) {
    final result = create();
    if (feasible != null) result.feasible = feasible;
    if (models != null) result.models.addAll(models);
    if (totals != null) result.totals = totals;
    if (host != null) result.host = host;
    if (affectedRunningInstances != null)
      result.affectedRunningInstances.addAll(affectedRunningInstances);
    if (recommendations != null) result.recommendations.addAll(recommendations);
    if (reason != null) result.reason = reason;
    return result;
  }

  SimulateParallelLoadResponse._();

  factory SimulateParallelLoadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SimulateParallelLoadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimulateParallelLoadResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'feasible')
    ..pPM<SimulatedModel>(2, _omitFieldNames ? '' : 'models',
        subBuilder: SimulatedModel.create)
    ..aOM<MemoryAllocation>(3, _omitFieldNames ? '' : 'totals',
        subBuilder: MemoryAllocation.create)
    ..aOM<SimulatedHost>(4, _omitFieldNames ? '' : 'host',
        subBuilder: SimulatedHost.create)
    ..pPS(5, _omitFieldNames ? '' : 'affectedRunningInstances')
    ..pPS(6, _omitFieldNames ? '' : 'recommendations')
    ..aOS(7, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulateParallelLoadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimulateParallelLoadResponse copyWith(
          void Function(SimulateParallelLoadResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SimulateParallelLoadResponse))
          as SimulateParallelLoadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SimulateParallelLoadResponse create() =>
      SimulateParallelLoadResponse._();
  @$core.override
  SimulateParallelLoadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SimulateParallelLoadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulateParallelLoadResponse>(create);
  static SimulateParallelLoadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get feasible => $_getBF(0);
  @$pb.TagNumber(1)
  set feasible($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFeasible() => $_has(0);
  @$pb.TagNumber(1)
  void clearFeasible() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SimulatedModel> get models => $_getList(1);

  @$pb.TagNumber(3)
  MemoryAllocation get totals => $_getN(2);
  @$pb.TagNumber(3)
  set totals(MemoryAllocation value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTotals() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotals() => $_clearField(3);
  @$pb.TagNumber(3)
  MemoryAllocation ensureTotals() => $_ensure(2);

  @$pb.TagNumber(4)
  SimulatedHost get host => $_getN(3);
  @$pb.TagNumber(4)
  set host(SimulatedHost value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasHost() => $_has(3);
  @$pb.TagNumber(4)
  void clearHost() => $_clearField(4);
  @$pb.TagNumber(4)
  SimulatedHost ensureHost() => $_ensure(3);

  /// Running instances that would be replanned with a smaller context.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get affectedRunningInstances => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get recommendations => $_getList(5);

  /// Set when nothing could be planned at all, in which case models is empty.
  @$pb.TagNumber(7)
  $core.String get reason => $_getSZ(6);
  @$pb.TagNumber(7)
  set reason($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearReason() => $_clearField(7);
}

class ListInstancesRequest extends $pb.GeneratedMessage {
  factory ListInstancesRequest() => create();

  ListInstancesRequest._();

  factory ListInstancesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListInstancesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListInstancesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInstancesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInstancesRequest copyWith(void Function(ListInstancesRequest) updates) =>
      super.copyWith((message) => updates(message as ListInstancesRequest))
          as ListInstancesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListInstancesRequest create() => ListInstancesRequest._();
  @$core.override
  ListInstancesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListInstancesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListInstancesRequest>(create);
  static ListInstancesRequest? _defaultInstance;
}

class ListInstancesResponse extends $pb.GeneratedMessage {
  factory ListInstancesResponse({
    $core.Iterable<EngineInstance>? instances,
  }) {
    final result = create();
    if (instances != null) result.instances.addAll(instances);
    return result;
  }

  ListInstancesResponse._();

  factory ListInstancesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListInstancesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListInstancesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<EngineInstance>(1, _omitFieldNames ? '' : 'instances',
        subBuilder: EngineInstance.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInstancesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInstancesResponse copyWith(
          void Function(ListInstancesResponse) updates) =>
      super.copyWith((message) => updates(message as ListInstancesResponse))
          as ListInstancesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListInstancesResponse create() => ListInstancesResponse._();
  @$core.override
  ListInstancesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListInstancesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListInstancesResponse>(create);
  static ListInstancesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<EngineInstance> get instances => $_getList(0);
}

class CreateInstanceRequest extends $pb.GeneratedMessage {
  factory CreateInstanceRequest({
    $core.String? modelId,
    $core.String? servedModelName,
    EngineConfig? config,
    $core.String? nodeId,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    if (servedModelName != null) result.servedModelName = servedModelName;
    if (config != null) result.config = config;
    if (nodeId != null) result.nodeId = nodeId;
    return result;
  }

  CreateInstanceRequest._();

  factory CreateInstanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateInstanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateInstanceRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOS(2, _omitFieldNames ? '' : 'servedModelName')
    ..aOM<EngineConfig>(3, _omitFieldNames ? '' : 'config',
        subBuilder: EngineConfig.create)
    ..aOS(4, _omitFieldNames ? '' : 'nodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInstanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInstanceRequest copyWith(
          void Function(CreateInstanceRequest) updates) =>
      super.copyWith((message) => updates(message as CreateInstanceRequest))
          as CreateInstanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateInstanceRequest create() => CreateInstanceRequest._();
  @$core.override
  CreateInstanceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateInstanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateInstanceRequest>(create);
  static CreateInstanceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  /// Defaults to the model's name.
  @$pb.TagNumber(2)
  $core.String get servedModelName => $_getSZ(1);
  @$pb.TagNumber(2)
  set servedModelName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServedModelName() => $_has(1);
  @$pb.TagNumber(2)
  void clearServedModelName() => $_clearField(2);

  @$pb.TagNumber(3)
  EngineConfig get config => $_getN(2);
  @$pb.TagNumber(3)
  set config(EngineConfig value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConfig() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfig() => $_clearField(3);
  @$pb.TagNumber(3)
  EngineConfig ensureConfig() => $_ensure(2);

  /// Which machine runs it. Empty means this one. It may be left out when
  /// model_id is already qualified with a node, which is how the catalog lists
  /// a node's models.
  @$pb.TagNumber(4)
  $core.String get nodeId => $_getSZ(3);
  @$pb.TagNumber(4)
  set nodeId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNodeId() => $_has(3);
  @$pb.TagNumber(4)
  void clearNodeId() => $_clearField(4);
}

/// The response to every call that schedules work on an instance: the instance
/// as it stands now, and the operation that will change it.
class CreateInstanceResponse extends $pb.GeneratedMessage {
  factory CreateInstanceResponse({
    EngineInstance? instance,
    $core.String? operationId,
    OperationState? state,
    $core.int? queuePosition,
  }) {
    final result = create();
    if (instance != null) result.instance = instance;
    if (operationId != null) result.operationId = operationId;
    if (state != null) result.state = state;
    if (queuePosition != null) result.queuePosition = queuePosition;
    return result;
  }

  CreateInstanceResponse._();

  factory CreateInstanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateInstanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateInstanceResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineInstance>(1, _omitFieldNames ? '' : 'instance',
        subBuilder: EngineInstance.create)
    ..aOS(2, _omitFieldNames ? '' : 'operationId')
    ..aE<OperationState>(3, _omitFieldNames ? '' : 'state',
        enumValues: OperationState.values)
    ..aI(4, _omitFieldNames ? '' : 'queuePosition')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInstanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateInstanceResponse copyWith(
          void Function(CreateInstanceResponse) updates) =>
      super.copyWith((message) => updates(message as CreateInstanceResponse))
          as CreateInstanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateInstanceResponse create() => CreateInstanceResponse._();
  @$core.override
  CreateInstanceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateInstanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateInstanceResponse>(create);
  static CreateInstanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EngineInstance get instance => $_getN(0);
  @$pb.TagNumber(1)
  set instance(EngineInstance value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstance() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineInstance ensureInstance() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get operationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set operationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOperationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperationId() => $_clearField(2);

  @$pb.TagNumber(3)
  OperationState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(OperationState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get queuePosition => $_getIZ(3);
  @$pb.TagNumber(4)
  set queuePosition($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQueuePosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearQueuePosition() => $_clearField(4);
}

class GetInstanceRequest extends $pb.GeneratedMessage {
  factory GetInstanceRequest({
    $core.String? instanceId,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    return result;
  }

  GetInstanceRequest._();

  factory GetInstanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstanceRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceRequest copyWith(void Function(GetInstanceRequest) updates) =>
      super.copyWith((message) => updates(message as GetInstanceRequest))
          as GetInstanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstanceRequest create() => GetInstanceRequest._();
  @$core.override
  GetInstanceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstanceRequest>(create);
  static GetInstanceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);
}

class GetInstanceResponse extends $pb.GeneratedMessage {
  factory GetInstanceResponse({
    EngineInstance? instance,
  }) {
    final result = create();
    if (instance != null) result.instance = instance;
    return result;
  }

  GetInstanceResponse._();

  factory GetInstanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstanceResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineInstance>(1, _omitFieldNames ? '' : 'instance',
        subBuilder: EngineInstance.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceResponse copyWith(void Function(GetInstanceResponse) updates) =>
      super.copyWith((message) => updates(message as GetInstanceResponse))
          as GetInstanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstanceResponse create() => GetInstanceResponse._();
  @$core.override
  GetInstanceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstanceResponse>(create);
  static GetInstanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EngineInstance get instance => $_getN(0);
  @$pb.TagNumber(1)
  set instance(EngineInstance value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstance() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineInstance ensureInstance() => $_ensure(0);
}

class GetInstanceMetricsRequest extends $pb.GeneratedMessage {
  factory GetInstanceMetricsRequest({
    $core.String? instanceId,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    return result;
  }

  GetInstanceMetricsRequest._();

  factory GetInstanceMetricsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstanceMetricsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstanceMetricsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceMetricsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceMetricsRequest copyWith(
          void Function(GetInstanceMetricsRequest) updates) =>
      super.copyWith((message) => updates(message as GetInstanceMetricsRequest))
          as GetInstanceMetricsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstanceMetricsRequest create() => GetInstanceMetricsRequest._();
  @$core.override
  GetInstanceMetricsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstanceMetricsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstanceMetricsRequest>(create);
  static GetInstanceMetricsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);
}

class GetInstanceMetricsResponse extends $pb.GeneratedMessage {
  factory GetInstanceMetricsResponse({
    $1.Struct? metrics,
  }) {
    final result = create();
    if (metrics != null) result.metrics = metrics;
    return result;
  }

  GetInstanceMetricsResponse._();

  factory GetInstanceMetricsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstanceMetricsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstanceMetricsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<$1.Struct>(1, _omitFieldNames ? '' : 'metrics',
        subBuilder: $1.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceMetricsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceMetricsResponse copyWith(
          void Function(GetInstanceMetricsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetInstanceMetricsResponse))
          as GetInstanceMetricsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstanceMetricsResponse create() => GetInstanceMetricsResponse._();
  @$core.override
  GetInstanceMetricsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstanceMetricsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstanceMetricsResponse>(create);
  static GetInstanceMetricsResponse? _defaultInstance;

  /// Free-form: this is a telemetry blob for display, and pinning its shape
  /// would mean a schema change for every counter added.
  @$pb.TagNumber(1)
  $1.Struct get metrics => $_getN(0);
  @$pb.TagNumber(1)
  set metrics($1.Struct value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMetrics() => $_has(0);
  @$pb.TagNumber(1)
  void clearMetrics() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Struct ensureMetrics() => $_ensure(0);
}

/// SetVisibility shows or hides a stopped instance in the chat model picker.
class SetVisibility extends $pb.GeneratedMessage {
  factory SetVisibility({
    $core.bool? showInChatPicker,
  }) {
    final result = create();
    if (showInChatPicker != null) result.showInChatPicker = showInChatPicker;
    return result;
  }

  SetVisibility._();

  factory SetVisibility.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetVisibility.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetVisibility',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'showInChatPicker')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetVisibility clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetVisibility copyWith(void Function(SetVisibility) updates) =>
      super.copyWith((message) => updates(message as SetVisibility))
          as SetVisibility;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetVisibility create() => SetVisibility._();
  @$core.override
  SetVisibility createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetVisibility getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetVisibility>(create);
  static SetVisibility? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get showInChatPicker => $_getBF(0);
  @$pb.TagNumber(1)
  set showInChatPicker($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShowInChatPicker() => $_has(0);
  @$pb.TagNumber(1)
  void clearShowInChatPicker() => $_clearField(1);
}

/// SetGenerationDefaults replaces the sampler defaults. It applies live.
class SetGenerationDefaults extends $pb.GeneratedMessage {
  factory SetGenerationDefaults({
    $1.Struct? generationDefaults,
  }) {
    final result = create();
    if (generationDefaults != null)
      result.generationDefaults = generationDefaults;
    return result;
  }

  SetGenerationDefaults._();

  factory SetGenerationDefaults.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetGenerationDefaults.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetGenerationDefaults',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<$1.Struct>(1, _omitFieldNames ? '' : 'generationDefaults',
        subBuilder: $1.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetGenerationDefaults clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetGenerationDefaults copyWith(
          void Function(SetGenerationDefaults) updates) =>
      super.copyWith((message) => updates(message as SetGenerationDefaults))
          as SetGenerationDefaults;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetGenerationDefaults create() => SetGenerationDefaults._();
  @$core.override
  SetGenerationDefaults createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetGenerationDefaults getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetGenerationDefaults>(create);
  static SetGenerationDefaults? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Struct get generationDefaults => $_getN(0);
  @$pb.TagNumber(1)
  set generationDefaults($1.Struct value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGenerationDefaults() => $_has(0);
  @$pb.TagNumber(1)
  void clearGenerationDefaults() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Struct ensureGenerationDefaults() => $_ensure(0);
}

/// StartInstance starts a stopped instance or restarts a running one.
class StartInstance extends $pb.GeneratedMessage {
  factory StartInstance({
    EngineConfig? requestedConfig,
    $core.bool? restart,
  }) {
    final result = create();
    if (requestedConfig != null) result.requestedConfig = requestedConfig;
    if (restart != null) result.restart = restart;
    return result;
  }

  StartInstance._();

  factory StartInstance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartInstance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartInstance',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineConfig>(1, _omitFieldNames ? '' : 'requestedConfig',
        subBuilder: EngineConfig.create)
    ..aOB(2, _omitFieldNames ? '' : 'restart')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartInstance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartInstance copyWith(void Function(StartInstance) updates) =>
      super.copyWith((message) => updates(message as StartInstance))
          as StartInstance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartInstance create() => StartInstance._();
  @$core.override
  StartInstance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartInstance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartInstance>(create);
  static StartInstance? _defaultInstance;

  /// Unset keeps the config the instance already asked for. A config that is
  /// set replaces it, with every field it leaves out taking the engine default
  /// rather than the instance's previous value - the two free-form maps are the
  /// exception and are merged over what the instance already had, because they
  /// are passed through to the runtime key by key.
  @$pb.TagNumber(1)
  EngineConfig get requestedConfig => $_getN(0);
  @$pb.TagNumber(1)
  set requestedConfig(EngineConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedConfig() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineConfig ensureRequestedConfig() => $_ensure(0);

  /// Whether a running instance is stopped first. A start on a running instance
  /// was accepted as a restart by the HTTP API and is here too.
  @$pb.TagNumber(2)
  $core.bool get restart => $_getBF(1);
  @$pb.TagNumber(2)
  set restart($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRestart() => $_has(1);
  @$pb.TagNumber(2)
  void clearRestart() => $_clearField(2);
}

class StopInstance extends $pb.GeneratedMessage {
  factory StopInstance() => create();

  StopInstance._();

  factory StopInstance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StopInstance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopInstance',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopInstance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopInstance copyWith(void Function(StopInstance) updates) =>
      super.copyWith((message) => updates(message as StopInstance))
          as StopInstance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopInstance create() => StopInstance._();
  @$core.override
  StopInstance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StopInstance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopInstance>(create);
  static StopInstance? _defaultInstance;
}

/// ApplyFix restarts with the config change a SuggestedFix names.
class ApplyFix extends $pb.GeneratedMessage {
  factory ApplyFix({
    $core.String? fix,
  }) {
    final result = create();
    if (fix != null) result.fix = fix;
    return result;
  }

  ApplyFix._();

  factory ApplyFix.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyFix.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyFix',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyFix clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyFix copyWith(void Function(ApplyFix) updates) =>
      super.copyWith((message) => updates(message as ApplyFix)) as ApplyFix;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyFix create() => ApplyFix._();
  @$core.override
  ApplyFix createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyFix getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplyFix>(create);
  static ApplyFix? _defaultInstance;

  /// One of reduce_context, retry_on_cpu or retry_with_ram.
  @$pb.TagNumber(1)
  $core.String get fix => $_getSZ(0);
  @$pb.TagNumber(1)
  set fix($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFix() => $_has(0);
  @$pb.TagNumber(1)
  void clearFix() => $_clearField(1);
}

/// SetRequestedConfig stores a config without acting on it. The fields that
/// need a restart take effect the next time the instance starts.
class SetRequestedConfig extends $pb.GeneratedMessage {
  factory SetRequestedConfig({
    EngineConfig? requestedConfig,
  }) {
    final result = create();
    if (requestedConfig != null) result.requestedConfig = requestedConfig;
    return result;
  }

  SetRequestedConfig._();

  factory SetRequestedConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetRequestedConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRequestedConfig',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineConfig>(1, _omitFieldNames ? '' : 'requestedConfig',
        subBuilder: EngineConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRequestedConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRequestedConfig copyWith(void Function(SetRequestedConfig) updates) =>
      super.copyWith((message) => updates(message as SetRequestedConfig))
          as SetRequestedConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetRequestedConfig create() => SetRequestedConfig._();
  @$core.override
  SetRequestedConfig createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetRequestedConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRequestedConfig>(create);
  static SetRequestedConfig? _defaultInstance;

  @$pb.TagNumber(1)
  EngineConfig get requestedConfig => $_getN(0);
  @$pb.TagNumber(1)
  set requestedConfig(EngineConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedConfig() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineConfig ensureRequestedConfig() => $_ensure(0);
}

enum UpdateInstanceRequest_Change {
  visibility,
  generationDefaults,
  start,
  stop,
  applyFix,
  requestedConfig,
  notSet
}

/// UpdateInstanceRequest carries exactly one change. The HTTP API took a JSON
/// object and worked out which change was meant from which keys were present,
/// which is why it had to reject a visibility change bundled with anything
/// else; the oneof makes that impossible to express instead of an error to
/// return.
class UpdateInstanceRequest extends $pb.GeneratedMessage {
  factory UpdateInstanceRequest({
    $core.String? instanceId,
    SetVisibility? visibility,
    SetGenerationDefaults? generationDefaults,
    StartInstance? start,
    StopInstance? stop,
    ApplyFix? applyFix,
    SetRequestedConfig? requestedConfig,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    if (visibility != null) result.visibility = visibility;
    if (generationDefaults != null)
      result.generationDefaults = generationDefaults;
    if (start != null) result.start = start;
    if (stop != null) result.stop = stop;
    if (applyFix != null) result.applyFix = applyFix;
    if (requestedConfig != null) result.requestedConfig = requestedConfig;
    return result;
  }

  UpdateInstanceRequest._();

  factory UpdateInstanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateInstanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UpdateInstanceRequest_Change>
      _UpdateInstanceRequest_ChangeByTag = {
    2: UpdateInstanceRequest_Change.visibility,
    3: UpdateInstanceRequest_Change.generationDefaults,
    4: UpdateInstanceRequest_Change.start,
    5: UpdateInstanceRequest_Change.stop,
    6: UpdateInstanceRequest_Change.applyFix,
    7: UpdateInstanceRequest_Change.requestedConfig,
    0: UpdateInstanceRequest_Change.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateInstanceRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5, 6, 7])
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..aOM<SetVisibility>(2, _omitFieldNames ? '' : 'visibility',
        subBuilder: SetVisibility.create)
    ..aOM<SetGenerationDefaults>(3, _omitFieldNames ? '' : 'generationDefaults',
        subBuilder: SetGenerationDefaults.create)
    ..aOM<StartInstance>(4, _omitFieldNames ? '' : 'start',
        subBuilder: StartInstance.create)
    ..aOM<StopInstance>(5, _omitFieldNames ? '' : 'stop',
        subBuilder: StopInstance.create)
    ..aOM<ApplyFix>(6, _omitFieldNames ? '' : 'applyFix',
        subBuilder: ApplyFix.create)
    ..aOM<SetRequestedConfig>(7, _omitFieldNames ? '' : 'requestedConfig',
        subBuilder: SetRequestedConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateInstanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateInstanceRequest copyWith(
          void Function(UpdateInstanceRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateInstanceRequest))
          as UpdateInstanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateInstanceRequest create() => UpdateInstanceRequest._();
  @$core.override
  UpdateInstanceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateInstanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateInstanceRequest>(create);
  static UpdateInstanceRequest? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  UpdateInstanceRequest_Change whichChange() =>
      _UpdateInstanceRequest_ChangeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  void clearChange() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  SetVisibility get visibility => $_getN(1);
  @$pb.TagNumber(2)
  set visibility(SetVisibility value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasVisibility() => $_has(1);
  @$pb.TagNumber(2)
  void clearVisibility() => $_clearField(2);
  @$pb.TagNumber(2)
  SetVisibility ensureVisibility() => $_ensure(1);

  @$pb.TagNumber(3)
  SetGenerationDefaults get generationDefaults => $_getN(2);
  @$pb.TagNumber(3)
  set generationDefaults(SetGenerationDefaults value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGenerationDefaults() => $_has(2);
  @$pb.TagNumber(3)
  void clearGenerationDefaults() => $_clearField(3);
  @$pb.TagNumber(3)
  SetGenerationDefaults ensureGenerationDefaults() => $_ensure(2);

  @$pb.TagNumber(4)
  StartInstance get start => $_getN(3);
  @$pb.TagNumber(4)
  set start(StartInstance value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStart() => $_has(3);
  @$pb.TagNumber(4)
  void clearStart() => $_clearField(4);
  @$pb.TagNumber(4)
  StartInstance ensureStart() => $_ensure(3);

  @$pb.TagNumber(5)
  StopInstance get stop => $_getN(4);
  @$pb.TagNumber(5)
  set stop(StopInstance value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasStop() => $_has(4);
  @$pb.TagNumber(5)
  void clearStop() => $_clearField(5);
  @$pb.TagNumber(5)
  StopInstance ensureStop() => $_ensure(4);

  @$pb.TagNumber(6)
  ApplyFix get applyFix => $_getN(5);
  @$pb.TagNumber(6)
  set applyFix(ApplyFix value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasApplyFix() => $_has(5);
  @$pb.TagNumber(6)
  void clearApplyFix() => $_clearField(6);
  @$pb.TagNumber(6)
  ApplyFix ensureApplyFix() => $_ensure(5);

  @$pb.TagNumber(7)
  SetRequestedConfig get requestedConfig => $_getN(6);
  @$pb.TagNumber(7)
  set requestedConfig(SetRequestedConfig value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasRequestedConfig() => $_has(6);
  @$pb.TagNumber(7)
  void clearRequestedConfig() => $_clearField(7);
  @$pb.TagNumber(7)
  SetRequestedConfig ensureRequestedConfig() => $_ensure(6);
}

class UpdateInstanceResponse extends $pb.GeneratedMessage {
  factory UpdateInstanceResponse({
    EngineInstance? instance,
    $core.String? operationId,
    OperationState? state,
    $core.int? queuePosition,
    $core.String? appliedFix,
  }) {
    final result = create();
    if (instance != null) result.instance = instance;
    if (operationId != null) result.operationId = operationId;
    if (state != null) result.state = state;
    if (queuePosition != null) result.queuePosition = queuePosition;
    if (appliedFix != null) result.appliedFix = appliedFix;
    return result;
  }

  UpdateInstanceResponse._();

  factory UpdateInstanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateInstanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateInstanceResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineInstance>(1, _omitFieldNames ? '' : 'instance',
        subBuilder: EngineInstance.create)
    ..aOS(2, _omitFieldNames ? '' : 'operationId')
    ..aE<OperationState>(3, _omitFieldNames ? '' : 'state',
        enumValues: OperationState.values)
    ..aI(4, _omitFieldNames ? '' : 'queuePosition')
    ..aOS(5, _omitFieldNames ? '' : 'appliedFix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateInstanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateInstanceResponse copyWith(
          void Function(UpdateInstanceResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateInstanceResponse))
          as UpdateInstanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateInstanceResponse create() => UpdateInstanceResponse._();
  @$core.override
  UpdateInstanceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateInstanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateInstanceResponse>(create);
  static UpdateInstanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EngineInstance get instance => $_getN(0);
  @$pb.TagNumber(1)
  set instance(EngineInstance value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstance() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineInstance ensureInstance() => $_ensure(0);

  /// Empty for the changes that take effect at once.
  @$pb.TagNumber(2)
  $core.String get operationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set operationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOperationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperationId() => $_clearField(2);

  @$pb.TagNumber(3)
  OperationState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(OperationState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get queuePosition => $_getIZ(3);
  @$pb.TagNumber(4)
  set queuePosition($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQueuePosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearQueuePosition() => $_clearField(4);

  /// Echoes ApplyFix.fix so a client can tell which fix was applied.
  @$pb.TagNumber(5)
  $core.String get appliedFix => $_getSZ(4);
  @$pb.TagNumber(5)
  set appliedFix($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAppliedFix() => $_has(4);
  @$pb.TagNumber(5)
  void clearAppliedFix() => $_clearField(5);
}

class EnsureInstanceReadyRequest extends $pb.GeneratedMessage {
  factory EnsureInstanceReadyRequest({
    $core.String? instanceId,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    return result;
  }

  EnsureInstanceReadyRequest._();

  factory EnsureInstanceReadyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnsureInstanceReadyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnsureInstanceReadyRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnsureInstanceReadyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnsureInstanceReadyRequest copyWith(
          void Function(EnsureInstanceReadyRequest) updates) =>
      super.copyWith(
              (message) => updates(message as EnsureInstanceReadyRequest))
          as EnsureInstanceReadyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnsureInstanceReadyRequest create() => EnsureInstanceReadyRequest._();
  @$core.override
  EnsureInstanceReadyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnsureInstanceReadyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnsureInstanceReadyRequest>(create);
  static EnsureInstanceReadyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);
}

class EnsureInstanceReadyResponse extends $pb.GeneratedMessage {
  factory EnsureInstanceReadyResponse({
    EngineInstance? instance,
    $core.String? operationId,
    OperationState? state,
    $core.int? queuePosition,
    $core.bool? alreadyReady,
  }) {
    final result = create();
    if (instance != null) result.instance = instance;
    if (operationId != null) result.operationId = operationId;
    if (state != null) result.state = state;
    if (queuePosition != null) result.queuePosition = queuePosition;
    if (alreadyReady != null) result.alreadyReady = alreadyReady;
    return result;
  }

  EnsureInstanceReadyResponse._();

  factory EnsureInstanceReadyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnsureInstanceReadyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnsureInstanceReadyResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineInstance>(1, _omitFieldNames ? '' : 'instance',
        subBuilder: EngineInstance.create)
    ..aOS(2, _omitFieldNames ? '' : 'operationId')
    ..aE<OperationState>(3, _omitFieldNames ? '' : 'state',
        enumValues: OperationState.values)
    ..aI(4, _omitFieldNames ? '' : 'queuePosition')
    ..aOB(5, _omitFieldNames ? '' : 'alreadyReady')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnsureInstanceReadyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnsureInstanceReadyResponse copyWith(
          void Function(EnsureInstanceReadyResponse) updates) =>
      super.copyWith(
              (message) => updates(message as EnsureInstanceReadyResponse))
          as EnsureInstanceReadyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnsureInstanceReadyResponse create() =>
      EnsureInstanceReadyResponse._();
  @$core.override
  EnsureInstanceReadyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnsureInstanceReadyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnsureInstanceReadyResponse>(create);
  static EnsureInstanceReadyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EngineInstance get instance => $_getN(0);
  @$pb.TagNumber(1)
  set instance(EngineInstance value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstance() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineInstance ensureInstance() => $_ensure(0);

  /// Both empty when the instance was already ready.
  @$pb.TagNumber(2)
  $core.String get operationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set operationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOperationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperationId() => $_clearField(2);

  @$pb.TagNumber(3)
  OperationState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(OperationState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get queuePosition => $_getIZ(3);
  @$pb.TagNumber(4)
  set queuePosition($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQueuePosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearQueuePosition() => $_clearField(4);

  /// True when no operation had to be scheduled.
  @$pb.TagNumber(5)
  $core.bool get alreadyReady => $_getBF(4);
  @$pb.TagNumber(5)
  set alreadyReady($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAlreadyReady() => $_has(4);
  @$pb.TagNumber(5)
  void clearAlreadyReady() => $_clearField(5);
}

class DeleteInstanceRequest extends $pb.GeneratedMessage {
  factory DeleteInstanceRequest({
    $core.String? instanceId,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    return result;
  }

  DeleteInstanceRequest._();

  factory DeleteInstanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteInstanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteInstanceRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteInstanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteInstanceRequest copyWith(
          void Function(DeleteInstanceRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteInstanceRequest))
          as DeleteInstanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteInstanceRequest create() => DeleteInstanceRequest._();
  @$core.override
  DeleteInstanceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteInstanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteInstanceRequest>(create);
  static DeleteInstanceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);
}

class DeleteInstanceResponse extends $pb.GeneratedMessage {
  factory DeleteInstanceResponse({
    EngineInstance? instance,
    $core.String? operationId,
  }) {
    final result = create();
    if (instance != null) result.instance = instance;
    if (operationId != null) result.operationId = operationId;
    return result;
  }

  DeleteInstanceResponse._();

  factory DeleteInstanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteInstanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteInstanceResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineInstance>(1, _omitFieldNames ? '' : 'instance',
        subBuilder: EngineInstance.create)
    ..aOS(2, _omitFieldNames ? '' : 'operationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteInstanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteInstanceResponse copyWith(
          void Function(DeleteInstanceResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteInstanceResponse))
          as DeleteInstanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteInstanceResponse create() => DeleteInstanceResponse._();
  @$core.override
  DeleteInstanceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteInstanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteInstanceResponse>(create);
  static DeleteInstanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EngineInstance get instance => $_getN(0);
  @$pb.TagNumber(1)
  set instance(EngineInstance value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstance() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineInstance ensureInstance() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get operationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set operationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOperationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperationId() => $_clearField(2);
}

class GetOperationRequest extends $pb.GeneratedMessage {
  factory GetOperationRequest({
    $core.String? operationId,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    return result;
  }

  GetOperationRequest._();

  factory GetOperationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetOperationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetOperationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOperationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOperationRequest copyWith(void Function(GetOperationRequest) updates) =>
      super.copyWith((message) => updates(message as GetOperationRequest))
          as GetOperationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetOperationRequest create() => GetOperationRequest._();
  @$core.override
  GetOperationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetOperationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetOperationRequest>(create);
  static GetOperationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);
}

class GetOperationResponse extends $pb.GeneratedMessage {
  factory GetOperationResponse({
    EngineOperation? operation,
  }) {
    final result = create();
    if (operation != null) result.operation = operation;
    return result;
  }

  GetOperationResponse._();

  factory GetOperationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetOperationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetOperationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineOperation>(1, _omitFieldNames ? '' : 'operation',
        subBuilder: EngineOperation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOperationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetOperationResponse copyWith(void Function(GetOperationResponse) updates) =>
      super.copyWith((message) => updates(message as GetOperationResponse))
          as GetOperationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetOperationResponse create() => GetOperationResponse._();
  @$core.override
  GetOperationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetOperationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetOperationResponse>(create);
  static GetOperationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EngineOperation get operation => $_getN(0);
  @$pb.TagNumber(1)
  set operation(EngineOperation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperation() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperation() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineOperation ensureOperation() => $_ensure(0);
}

class CancelOperationRequest extends $pb.GeneratedMessage {
  factory CancelOperationRequest({
    $core.String? operationId,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    return result;
  }

  CancelOperationRequest._();

  factory CancelOperationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelOperationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelOperationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOperationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOperationRequest copyWith(
          void Function(CancelOperationRequest) updates) =>
      super.copyWith((message) => updates(message as CancelOperationRequest))
          as CancelOperationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelOperationRequest create() => CancelOperationRequest._();
  @$core.override
  CancelOperationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelOperationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelOperationRequest>(create);
  static CancelOperationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);
}

class CancelOperationResponse extends $pb.GeneratedMessage {
  factory CancelOperationResponse({
    EngineOperation? operation,
  }) {
    final result = create();
    if (operation != null) result.operation = operation;
    return result;
  }

  CancelOperationResponse._();

  factory CancelOperationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelOperationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelOperationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EngineOperation>(1, _omitFieldNames ? '' : 'operation',
        subBuilder: EngineOperation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOperationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelOperationResponse copyWith(
          void Function(CancelOperationResponse) updates) =>
      super.copyWith((message) => updates(message as CancelOperationResponse))
          as CancelOperationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelOperationResponse create() => CancelOperationResponse._();
  @$core.override
  CancelOperationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelOperationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelOperationResponse>(create);
  static CancelOperationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EngineOperation get operation => $_getN(0);
  @$pb.TagNumber(1)
  set operation(EngineOperation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperation() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperation() => $_clearField(1);
  @$pb.TagNumber(1)
  EngineOperation ensureOperation() => $_ensure(0);
}

/// StreamEventsRequest opens the engine feed. It carries nothing: the HTTP
/// version needed a single-use ticket because an EventSource cannot send an
/// Authorization header, and a gRPC stream authenticates itself like every
/// other call.
class StreamEventsRequest extends $pb.GeneratedMessage {
  factory StreamEventsRequest() => create();

  StreamEventsRequest._();

  factory StreamEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamEventsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEventsRequest copyWith(void Function(StreamEventsRequest) updates) =>
      super.copyWith((message) => updates(message as StreamEventsRequest))
          as StreamEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamEventsRequest create() => StreamEventsRequest._();
  @$core.override
  StreamEventsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamEventsRequest>(create);
  static StreamEventsRequest? _defaultInstance;
}

enum StreamEventsResponse_Event {
  snapshot,
  instanceCreated,
  instanceChanged,
  instanceDeleted,
  operation,
  modelsRescanned,
  modelDeleted,
  guardState,
  generic,
  notSet
}

/// StreamEventsResponse is one entry of the feed. The first one on every stream
/// is a snapshot of the instances, so a client that has just connected does not
/// have to list them separately.
class StreamEventsResponse extends $pb.GeneratedMessage {
  factory StreamEventsResponse({
    $3.Timestamp? timestamp,
    InstanceSnapshot? snapshot,
    EngineInstance? instanceCreated,
    EngineInstance? instanceChanged,
    InstanceDeleted? instanceDeleted,
    EngineOperation? operation,
    ModelsRescanned? modelsRescanned,
    ModelDeleted? modelDeleted,
    GuardStateChanged? guardState,
    GenericEvent? generic,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (snapshot != null) result.snapshot = snapshot;
    if (instanceCreated != null) result.instanceCreated = instanceCreated;
    if (instanceChanged != null) result.instanceChanged = instanceChanged;
    if (instanceDeleted != null) result.instanceDeleted = instanceDeleted;
    if (operation != null) result.operation = operation;
    if (modelsRescanned != null) result.modelsRescanned = modelsRescanned;
    if (modelDeleted != null) result.modelDeleted = modelDeleted;
    if (guardState != null) result.guardState = guardState;
    if (generic != null) result.generic = generic;
    return result;
  }

  StreamEventsResponse._();

  factory StreamEventsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamEventsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, StreamEventsResponse_Event>
      _StreamEventsResponse_EventByTag = {
    2: StreamEventsResponse_Event.snapshot,
    3: StreamEventsResponse_Event.instanceCreated,
    4: StreamEventsResponse_Event.instanceChanged,
    5: StreamEventsResponse_Event.instanceDeleted,
    6: StreamEventsResponse_Event.operation,
    7: StreamEventsResponse_Event.modelsRescanned,
    8: StreamEventsResponse_Event.modelDeleted,
    9: StreamEventsResponse_Event.guardState,
    10: StreamEventsResponse_Event.generic,
    0: StreamEventsResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamEventsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5, 6, 7, 8, 9, 10])
    ..aOM<$3.Timestamp>(1, _omitFieldNames ? '' : 'timestamp',
        subBuilder: $3.Timestamp.create)
    ..aOM<InstanceSnapshot>(2, _omitFieldNames ? '' : 'snapshot',
        subBuilder: InstanceSnapshot.create)
    ..aOM<EngineInstance>(3, _omitFieldNames ? '' : 'instanceCreated',
        subBuilder: EngineInstance.create)
    ..aOM<EngineInstance>(4, _omitFieldNames ? '' : 'instanceChanged',
        subBuilder: EngineInstance.create)
    ..aOM<InstanceDeleted>(5, _omitFieldNames ? '' : 'instanceDeleted',
        subBuilder: InstanceDeleted.create)
    ..aOM<EngineOperation>(6, _omitFieldNames ? '' : 'operation',
        subBuilder: EngineOperation.create)
    ..aOM<ModelsRescanned>(7, _omitFieldNames ? '' : 'modelsRescanned',
        subBuilder: ModelsRescanned.create)
    ..aOM<ModelDeleted>(8, _omitFieldNames ? '' : 'modelDeleted',
        subBuilder: ModelDeleted.create)
    ..aOM<GuardStateChanged>(9, _omitFieldNames ? '' : 'guardState',
        subBuilder: GuardStateChanged.create)
    ..aOM<GenericEvent>(10, _omitFieldNames ? '' : 'generic',
        subBuilder: GenericEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEventsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEventsResponse copyWith(void Function(StreamEventsResponse) updates) =>
      super.copyWith((message) => updates(message as StreamEventsResponse))
          as StreamEventsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamEventsResponse create() => StreamEventsResponse._();
  @$core.override
  StreamEventsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamEventsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamEventsResponse>(create);
  static StreamEventsResponse? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  StreamEventsResponse_Event whichEvent() =>
      _StreamEventsResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $3.Timestamp get timestamp => $_getN(0);
  @$pb.TagNumber(1)
  set timestamp($3.Timestamp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);
  @$pb.TagNumber(1)
  $3.Timestamp ensureTimestamp() => $_ensure(0);

  @$pb.TagNumber(2)
  InstanceSnapshot get snapshot => $_getN(1);
  @$pb.TagNumber(2)
  set snapshot(InstanceSnapshot value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSnapshot() => $_has(1);
  @$pb.TagNumber(2)
  void clearSnapshot() => $_clearField(2);
  @$pb.TagNumber(2)
  InstanceSnapshot ensureSnapshot() => $_ensure(1);

  @$pb.TagNumber(3)
  EngineInstance get instanceCreated => $_getN(2);
  @$pb.TagNumber(3)
  set instanceCreated(EngineInstance value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInstanceCreated() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstanceCreated() => $_clearField(3);
  @$pb.TagNumber(3)
  EngineInstance ensureInstanceCreated() => $_ensure(2);

  @$pb.TagNumber(4)
  EngineInstance get instanceChanged => $_getN(3);
  @$pb.TagNumber(4)
  set instanceChanged(EngineInstance value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInstanceChanged() => $_has(3);
  @$pb.TagNumber(4)
  void clearInstanceChanged() => $_clearField(4);
  @$pb.TagNumber(4)
  EngineInstance ensureInstanceChanged() => $_ensure(3);

  @$pb.TagNumber(5)
  InstanceDeleted get instanceDeleted => $_getN(4);
  @$pb.TagNumber(5)
  set instanceDeleted(InstanceDeleted value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasInstanceDeleted() => $_has(4);
  @$pb.TagNumber(5)
  void clearInstanceDeleted() => $_clearField(5);
  @$pb.TagNumber(5)
  InstanceDeleted ensureInstanceDeleted() => $_ensure(4);

  @$pb.TagNumber(6)
  EngineOperation get operation => $_getN(5);
  @$pb.TagNumber(6)
  set operation(EngineOperation value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOperation() => $_has(5);
  @$pb.TagNumber(6)
  void clearOperation() => $_clearField(6);
  @$pb.TagNumber(6)
  EngineOperation ensureOperation() => $_ensure(5);

  @$pb.TagNumber(7)
  ModelsRescanned get modelsRescanned => $_getN(6);
  @$pb.TagNumber(7)
  set modelsRescanned(ModelsRescanned value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasModelsRescanned() => $_has(6);
  @$pb.TagNumber(7)
  void clearModelsRescanned() => $_clearField(7);
  @$pb.TagNumber(7)
  ModelsRescanned ensureModelsRescanned() => $_ensure(6);

  @$pb.TagNumber(8)
  ModelDeleted get modelDeleted => $_getN(7);
  @$pb.TagNumber(8)
  set modelDeleted(ModelDeleted value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasModelDeleted() => $_has(7);
  @$pb.TagNumber(8)
  void clearModelDeleted() => $_clearField(8);
  @$pb.TagNumber(8)
  ModelDeleted ensureModelDeleted() => $_ensure(7);

  @$pb.TagNumber(9)
  GuardStateChanged get guardState => $_getN(8);
  @$pb.TagNumber(9)
  set guardState(GuardStateChanged value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasGuardState() => $_has(8);
  @$pb.TagNumber(9)
  void clearGuardState() => $_clearField(9);
  @$pb.TagNumber(9)
  GuardStateChanged ensureGuardState() => $_ensure(8);

  /// The escape hatch for an event the engine publishes that has no case
  /// above yet, so it reaches the client as something ignorable rather than
  /// disappearing from the feed.
  @$pb.TagNumber(10)
  GenericEvent get generic => $_getN(9);
  @$pb.TagNumber(10)
  set generic(GenericEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasGeneric() => $_has(9);
  @$pb.TagNumber(10)
  void clearGeneric() => $_clearField(10);
  @$pb.TagNumber(10)
  GenericEvent ensureGeneric() => $_ensure(9);
}

class InstanceSnapshot extends $pb.GeneratedMessage {
  factory InstanceSnapshot({
    $core.Iterable<EngineInstance>? instances,
  }) {
    final result = create();
    if (instances != null) result.instances.addAll(instances);
    return result;
  }

  InstanceSnapshot._();

  factory InstanceSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstanceSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstanceSnapshot',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<EngineInstance>(1, _omitFieldNames ? '' : 'instances',
        subBuilder: EngineInstance.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstanceSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstanceSnapshot copyWith(void Function(InstanceSnapshot) updates) =>
      super.copyWith((message) => updates(message as InstanceSnapshot))
          as InstanceSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstanceSnapshot create() => InstanceSnapshot._();
  @$core.override
  InstanceSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstanceSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstanceSnapshot>(create);
  static InstanceSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<EngineInstance> get instances => $_getList(0);
}

class InstanceDeleted extends $pb.GeneratedMessage {
  factory InstanceDeleted({
    $core.String? instanceId,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    return result;
  }

  InstanceDeleted._();

  factory InstanceDeleted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstanceDeleted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstanceDeleted',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstanceDeleted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstanceDeleted copyWith(void Function(InstanceDeleted) updates) =>
      super.copyWith((message) => updates(message as InstanceDeleted))
          as InstanceDeleted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstanceDeleted create() => InstanceDeleted._();
  @$core.override
  InstanceDeleted createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstanceDeleted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstanceDeleted>(create);
  static InstanceDeleted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);
}

class ModelsRescanned extends $pb.GeneratedMessage {
  factory ModelsRescanned({
    $core.int? count,
    $core.String? reason,
  }) {
    final result = create();
    if (count != null) result.count = count;
    if (reason != null) result.reason = reason;
    return result;
  }

  ModelsRescanned._();

  factory ModelsRescanned.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelsRescanned.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelsRescanned',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'count')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelsRescanned clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelsRescanned copyWith(void Function(ModelsRescanned) updates) =>
      super.copyWith((message) => updates(message as ModelsRescanned))
          as ModelsRescanned;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelsRescanned create() => ModelsRescanned._();
  @$core.override
  ModelsRescanned createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelsRescanned getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelsRescanned>(create);
  static ModelsRescanned? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get count => $_getIZ(0);
  @$pb.TagNumber(1)
  set count($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => $_clearField(1);

  /// Set when the rescan was not asked for, e.g. after a download finished.
  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

class ModelDeleted extends $pb.GeneratedMessage {
  factory ModelDeleted({
    $core.String? modelId,
    $core.String? name,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    if (name != null) result.name = name;
    return result;
  }

  ModelDeleted._();

  factory ModelDeleted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelDeleted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelDeleted',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelDeleted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelDeleted copyWith(void Function(ModelDeleted) updates) =>
      super.copyWith((message) => updates(message as ModelDeleted))
          as ModelDeleted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelDeleted create() => ModelDeleted._();
  @$core.override
  ModelDeleted createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelDeleted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelDeleted>(create);
  static ModelDeleted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class GuardStateChanged extends $pb.GeneratedMessage {
  factory GuardStateChanged({
    GuardState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  GuardStateChanged._();

  factory GuardStateChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GuardStateChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GuardStateChanged',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aE<GuardState>(1, _omitFieldNames ? '' : 'state',
        enumValues: GuardState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GuardStateChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GuardStateChanged copyWith(void Function(GuardStateChanged) updates) =>
      super.copyWith((message) => updates(message as GuardStateChanged))
          as GuardStateChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GuardStateChanged create() => GuardStateChanged._();
  @$core.override
  GuardStateChanged createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GuardStateChanged getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GuardStateChanged>(create);
  static GuardStateChanged? _defaultInstance;

  @$pb.TagNumber(1)
  GuardState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(GuardState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
}

class GenericEvent extends $pb.GeneratedMessage {
  factory GenericEvent({
    $core.String? type,
    $1.Struct? data,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (data != null) result.data = data;
    return result;
  }

  GenericEvent._();

  factory GenericEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GenericEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenericEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOM<$1.Struct>(2, _omitFieldNames ? '' : 'data',
        subBuilder: $1.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenericEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenericEvent copyWith(void Function(GenericEvent) updates) =>
      super.copyWith((message) => updates(message as GenericEvent))
          as GenericEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenericEvent create() => GenericEvent._();
  @$core.override
  GenericEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GenericEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GenericEvent>(create);
  static GenericEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Struct get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($1.Struct value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Struct ensureData() => $_ensure(1);
}

class ListRuntimesRequest extends $pb.GeneratedMessage {
  factory ListRuntimesRequest() => create();

  ListRuntimesRequest._();

  factory ListRuntimesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListRuntimesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRuntimesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRuntimesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRuntimesRequest copyWith(void Function(ListRuntimesRequest) updates) =>
      super.copyWith((message) => updates(message as ListRuntimesRequest))
          as ListRuntimesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListRuntimesRequest create() => ListRuntimesRequest._();
  @$core.override
  ListRuntimesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListRuntimesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListRuntimesRequest>(create);
  static ListRuntimesRequest? _defaultInstance;
}

class ListRuntimesResponse extends $pb.GeneratedMessage {
  factory ListRuntimesResponse({
    $core.Iterable<RuntimeCapability>? runtimes,
    $core.Iterable<RuntimeInstallJob>? installOperations,
  }) {
    final result = create();
    if (runtimes != null) result.runtimes.addAll(runtimes);
    if (installOperations != null)
      result.installOperations.addAll(installOperations);
    return result;
  }

  ListRuntimesResponse._();

  factory ListRuntimesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListRuntimesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRuntimesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<RuntimeCapability>(1, _omitFieldNames ? '' : 'runtimes',
        subBuilder: RuntimeCapability.create)
    ..pPM<RuntimeInstallJob>(2, _omitFieldNames ? '' : 'installOperations',
        subBuilder: RuntimeInstallJob.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRuntimesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRuntimesResponse copyWith(void Function(ListRuntimesResponse) updates) =>
      super.copyWith((message) => updates(message as ListRuntimesResponse))
          as ListRuntimesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListRuntimesResponse create() => ListRuntimesResponse._();
  @$core.override
  ListRuntimesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListRuntimesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListRuntimesResponse>(create);
  static ListRuntimesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<RuntimeCapability> get runtimes => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<RuntimeInstallJob> get installOperations => $_getList(1);
}

/// RuntimeInstallJob is the installer's own view of an install, which outlives
/// the operation that started it.
class RuntimeInstallJob extends $pb.GeneratedMessage {
  factory RuntimeInstallJob({
    $core.String? id,
    $core.String? buildDigest,
    RuntimeKind? runtime,
    $core.String? version,
    $core.String? installPath,
    $core.String? status,
    $core.String? phase,
    $core.double? progress,
    $core.String? message,
    $core.String? detailMessage,
    $core.String? log,
    $core.String? error,
    $core.String? errorSummary,
    $core.String? errorCode,
    $3.Timestamp? createdAt,
    $3.Timestamp? updatedAt,
    $3.Timestamp? finishedAt,
    $core.String? variant,
    $core.String? serverPath,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (buildDigest != null) result.buildDigest = buildDigest;
    if (runtime != null) result.runtime = runtime;
    if (version != null) result.version = version;
    if (installPath != null) result.installPath = installPath;
    if (status != null) result.status = status;
    if (phase != null) result.phase = phase;
    if (progress != null) result.progress = progress;
    if (message != null) result.message = message;
    if (detailMessage != null) result.detailMessage = detailMessage;
    if (log != null) result.log = log;
    if (error != null) result.error = error;
    if (errorSummary != null) result.errorSummary = errorSummary;
    if (errorCode != null) result.errorCode = errorCode;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (finishedAt != null) result.finishedAt = finishedAt;
    if (variant != null) result.variant = variant;
    if (serverPath != null) result.serverPath = serverPath;
    return result;
  }

  RuntimeInstallJob._();

  factory RuntimeInstallJob.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RuntimeInstallJob.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RuntimeInstallJob',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'buildDigest')
    ..aE<RuntimeKind>(3, _omitFieldNames ? '' : 'runtime',
        enumValues: RuntimeKind.values)
    ..aOS(4, _omitFieldNames ? '' : 'version')
    ..aOS(5, _omitFieldNames ? '' : 'installPath')
    ..aOS(6, _omitFieldNames ? '' : 'status')
    ..aOS(7, _omitFieldNames ? '' : 'phase')
    ..aD(8, _omitFieldNames ? '' : 'progress')
    ..aOS(9, _omitFieldNames ? '' : 'message')
    ..aOS(10, _omitFieldNames ? '' : 'detailMessage')
    ..aOS(11, _omitFieldNames ? '' : 'log')
    ..aOS(12, _omitFieldNames ? '' : 'error')
    ..aOS(13, _omitFieldNames ? '' : 'errorSummary')
    ..aOS(14, _omitFieldNames ? '' : 'errorCode')
    ..aOM<$3.Timestamp>(15, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(16, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(17, _omitFieldNames ? '' : 'finishedAt',
        subBuilder: $3.Timestamp.create)
    ..aOS(18, _omitFieldNames ? '' : 'variant')
    ..aOS(19, _omitFieldNames ? '' : 'serverPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeInstallJob clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeInstallJob copyWith(void Function(RuntimeInstallJob) updates) =>
      super.copyWith((message) => updates(message as RuntimeInstallJob))
          as RuntimeInstallJob;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RuntimeInstallJob create() => RuntimeInstallJob._();
  @$core.override
  RuntimeInstallJob createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RuntimeInstallJob getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RuntimeInstallJob>(create);
  static RuntimeInstallJob? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Identifies the exact set of archives this job installs.
  @$pb.TagNumber(2)
  $core.String get buildDigest => $_getSZ(1);
  @$pb.TagNumber(2)
  set buildDigest($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBuildDigest() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuildDigest() => $_clearField(2);

  @$pb.TagNumber(3)
  RuntimeKind get runtime => $_getN(2);
  @$pb.TagNumber(3)
  set runtime(RuntimeKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRuntime() => $_has(2);
  @$pb.TagNumber(3)
  void clearRuntime() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get version => $_getSZ(3);
  @$pb.TagNumber(4)
  set version($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get installPath => $_getSZ(4);
  @$pb.TagNumber(5)
  set installPath($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInstallPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearInstallPath() => $_clearField(5);

  /// Free-form for the same reason RuntimeCapability.status is.
  @$pb.TagNumber(6)
  $core.String get status => $_getSZ(5);
  @$pb.TagNumber(6)
  set status($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearStatus() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get phase => $_getSZ(6);
  @$pb.TagNumber(7)
  set phase($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPhase() => $_has(6);
  @$pb.TagNumber(7)
  void clearPhase() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get progress => $_getN(7);
  @$pb.TagNumber(8)
  set progress($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProgress() => $_has(7);
  @$pb.TagNumber(8)
  void clearProgress() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get message => $_getSZ(8);
  @$pb.TagNumber(9)
  set message($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMessage() => $_has(8);
  @$pb.TagNumber(9)
  void clearMessage() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get detailMessage => $_getSZ(9);
  @$pb.TagNumber(10)
  set detailMessage($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDetailMessage() => $_has(9);
  @$pb.TagNumber(10)
  void clearDetailMessage() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get log => $_getSZ(10);
  @$pb.TagNumber(11)
  set log($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLog() => $_has(10);
  @$pb.TagNumber(11)
  void clearLog() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get error => $_getSZ(11);
  @$pb.TagNumber(12)
  set error($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasError() => $_has(11);
  @$pb.TagNumber(12)
  void clearError() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get errorSummary => $_getSZ(12);
  @$pb.TagNumber(13)
  set errorSummary($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasErrorSummary() => $_has(12);
  @$pb.TagNumber(13)
  void clearErrorSummary() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get errorCode => $_getSZ(13);
  @$pb.TagNumber(14)
  set errorCode($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasErrorCode() => $_has(13);
  @$pb.TagNumber(14)
  void clearErrorCode() => $_clearField(14);

  @$pb.TagNumber(15)
  $3.Timestamp get createdAt => $_getN(14);
  @$pb.TagNumber(15)
  set createdAt($3.Timestamp value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasCreatedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearCreatedAt() => $_clearField(15);
  @$pb.TagNumber(15)
  $3.Timestamp ensureCreatedAt() => $_ensure(14);

  @$pb.TagNumber(16)
  $3.Timestamp get updatedAt => $_getN(15);
  @$pb.TagNumber(16)
  set updatedAt($3.Timestamp value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasUpdatedAt() => $_has(15);
  @$pb.TagNumber(16)
  void clearUpdatedAt() => $_clearField(16);
  @$pb.TagNumber(16)
  $3.Timestamp ensureUpdatedAt() => $_ensure(15);

  @$pb.TagNumber(17)
  $3.Timestamp get finishedAt => $_getN(16);
  @$pb.TagNumber(17)
  set finishedAt($3.Timestamp value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasFinishedAt() => $_has(16);
  @$pb.TagNumber(17)
  void clearFinishedAt() => $_clearField(17);
  @$pb.TagNumber(17)
  $3.Timestamp ensureFinishedAt() => $_ensure(16);

  @$pb.TagNumber(18)
  $core.String get variant => $_getSZ(17);
  @$pb.TagNumber(18)
  set variant($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasVariant() => $_has(17);
  @$pb.TagNumber(18)
  void clearVariant() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get serverPath => $_getSZ(18);
  @$pb.TagNumber(19)
  set serverPath($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasServerPath() => $_has(18);
  @$pb.TagNumber(19)
  void clearServerPath() => $_clearField(19);
}

class InstallRuntimeRequest extends $pb.GeneratedMessage {
  factory InstallRuntimeRequest({
    RuntimeKind? runtime,
  }) {
    final result = create();
    if (runtime != null) result.runtime = runtime;
    return result;
  }

  InstallRuntimeRequest._();

  factory InstallRuntimeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallRuntimeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallRuntimeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aE<RuntimeKind>(1, _omitFieldNames ? '' : 'runtime',
        enumValues: RuntimeKind.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallRuntimeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallRuntimeRequest copyWith(
          void Function(InstallRuntimeRequest) updates) =>
      super.copyWith((message) => updates(message as InstallRuntimeRequest))
          as InstallRuntimeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallRuntimeRequest create() => InstallRuntimeRequest._();
  @$core.override
  InstallRuntimeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallRuntimeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallRuntimeRequest>(create);
  static InstallRuntimeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  RuntimeKind get runtime => $_getN(0);
  @$pb.TagNumber(1)
  set runtime(RuntimeKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRuntime() => $_has(0);
  @$pb.TagNumber(1)
  void clearRuntime() => $_clearField(1);
}

class InstallRuntimeResponse extends $pb.GeneratedMessage {
  factory InstallRuntimeResponse({
    $core.String? operationId,
    RuntimeInstallJob? runtimeInstall,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    if (runtimeInstall != null) result.runtimeInstall = runtimeInstall;
    return result;
  }

  InstallRuntimeResponse._();

  factory InstallRuntimeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallRuntimeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallRuntimeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..aOM<RuntimeInstallJob>(2, _omitFieldNames ? '' : 'runtimeInstall',
        subBuilder: RuntimeInstallJob.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallRuntimeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallRuntimeResponse copyWith(
          void Function(InstallRuntimeResponse) updates) =>
      super.copyWith((message) => updates(message as InstallRuntimeResponse))
          as InstallRuntimeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallRuntimeResponse create() => InstallRuntimeResponse._();
  @$core.override
  InstallRuntimeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallRuntimeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallRuntimeResponse>(create);
  static InstallRuntimeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);

  @$pb.TagNumber(2)
  RuntimeInstallJob get runtimeInstall => $_getN(1);
  @$pb.TagNumber(2)
  set runtimeInstall(RuntimeInstallJob value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRuntimeInstall() => $_has(1);
  @$pb.TagNumber(2)
  void clearRuntimeInstall() => $_clearField(2);
  @$pb.TagNumber(2)
  RuntimeInstallJob ensureRuntimeInstall() => $_ensure(1);
}

/// GatewayKey is a key the local gateway accepts, without its secret. The
/// secret is returned once, by the call that created or rotated it.
class GatewayKey extends $pb.GeneratedMessage {
  factory GatewayKey({
    $core.String? id,
    $core.String? name,
    $core.Iterable<$core.String>? instanceIds,
    $3.Timestamp? createdAt,
    $3.Timestamp? lastUsedAt,
    $3.Timestamp? revokedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (instanceIds != null) result.instanceIds.addAll(instanceIds);
    if (createdAt != null) result.createdAt = createdAt;
    if (lastUsedAt != null) result.lastUsedAt = lastUsedAt;
    if (revokedAt != null) result.revokedAt = revokedAt;
    return result;
  }

  GatewayKey._();

  factory GatewayKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GatewayKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GatewayKey',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPS(3, _omitFieldNames ? '' : 'instanceIds')
    ..aOM<$3.Timestamp>(4, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(5, _omitFieldNames ? '' : 'lastUsedAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(6, _omitFieldNames ? '' : 'revokedAt',
        subBuilder: $3.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GatewayKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GatewayKey copyWith(void Function(GatewayKey) updates) =>
      super.copyWith((message) => updates(message as GatewayKey)) as GatewayKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GatewayKey create() => GatewayKey._();
  @$core.override
  GatewayKey createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GatewayKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GatewayKey>(create);
  static GatewayKey? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Empty means the key reaches every instance.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get instanceIds => $_getList(2);

  @$pb.TagNumber(4)
  $3.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($3.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.Timestamp ensureCreatedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $3.Timestamp get lastUsedAt => $_getN(4);
  @$pb.TagNumber(5)
  set lastUsedAt($3.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLastUsedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastUsedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $3.Timestamp ensureLastUsedAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $3.Timestamp get revokedAt => $_getN(5);
  @$pb.TagNumber(6)
  set revokedAt($3.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRevokedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearRevokedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $3.Timestamp ensureRevokedAt() => $_ensure(5);
}

class ListKeysRequest extends $pb.GeneratedMessage {
  factory ListKeysRequest() => create();

  ListKeysRequest._();

  factory ListKeysRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListKeysRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKeysRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeysRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeysRequest copyWith(void Function(ListKeysRequest) updates) =>
      super.copyWith((message) => updates(message as ListKeysRequest))
          as ListKeysRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListKeysRequest create() => ListKeysRequest._();
  @$core.override
  ListKeysRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListKeysRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKeysRequest>(create);
  static ListKeysRequest? _defaultInstance;
}

class ListKeysResponse extends $pb.GeneratedMessage {
  factory ListKeysResponse({
    $core.Iterable<GatewayKey>? keys,
  }) {
    final result = create();
    if (keys != null) result.keys.addAll(keys);
    return result;
  }

  ListKeysResponse._();

  factory ListKeysResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListKeysResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKeysResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<GatewayKey>(1, _omitFieldNames ? '' : 'keys',
        subBuilder: GatewayKey.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeysResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKeysResponse copyWith(void Function(ListKeysResponse) updates) =>
      super.copyWith((message) => updates(message as ListKeysResponse))
          as ListKeysResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListKeysResponse create() => ListKeysResponse._();
  @$core.override
  ListKeysResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListKeysResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKeysResponse>(create);
  static ListKeysResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GatewayKey> get keys => $_getList(0);
}

class CreateKeyRequest extends $pb.GeneratedMessage {
  factory CreateKeyRequest({
    $core.String? name,
    $core.Iterable<$core.String>? instanceIds,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (instanceIds != null) result.instanceIds.addAll(instanceIds);
    return result;
  }

  CreateKeyRequest._();

  factory CreateKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateKeyRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'instanceIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateKeyRequest copyWith(void Function(CreateKeyRequest) updates) =>
      super.copyWith((message) => updates(message as CreateKeyRequest))
          as CreateKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateKeyRequest create() => CreateKeyRequest._();
  @$core.override
  CreateKeyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateKeyRequest>(create);
  static CreateKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Every id must name an existing instance. Empty scopes the key to all.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get instanceIds => $_getList(1);
}

class CreateKeyResponse extends $pb.GeneratedMessage {
  factory CreateKeyResponse({
    GatewayKey? key,
    $core.String? plaintext,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (plaintext != null) result.plaintext = plaintext;
    return result;
  }

  CreateKeyResponse._();

  factory CreateKeyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateKeyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateKeyResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<GatewayKey>(1, _omitFieldNames ? '' : 'key',
        subBuilder: GatewayKey.create)
    ..aOS(2, _omitFieldNames ? '' : 'plaintext')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateKeyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateKeyResponse copyWith(void Function(CreateKeyResponse) updates) =>
      super.copyWith((message) => updates(message as CreateKeyResponse))
          as CreateKeyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateKeyResponse create() => CreateKeyResponse._();
  @$core.override
  CreateKeyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateKeyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateKeyResponse>(create);
  static CreateKeyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  GatewayKey get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(GatewayKey value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);
  @$pb.TagNumber(1)
  GatewayKey ensureKey() => $_ensure(0);

  /// The only time the secret is readable.
  @$pb.TagNumber(2)
  $core.String get plaintext => $_getSZ(1);
  @$pb.TagNumber(2)
  set plaintext($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlaintext() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlaintext() => $_clearField(2);
}

class RotateKeyRequest extends $pb.GeneratedMessage {
  factory RotateKeyRequest({
    $core.String? keyId,
  }) {
    final result = create();
    if (keyId != null) result.keyId = keyId;
    return result;
  }

  RotateKeyRequest._();

  factory RotateKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RotateKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RotateKeyRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'keyId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RotateKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RotateKeyRequest copyWith(void Function(RotateKeyRequest) updates) =>
      super.copyWith((message) => updates(message as RotateKeyRequest))
          as RotateKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RotateKeyRequest create() => RotateKeyRequest._();
  @$core.override
  RotateKeyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RotateKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RotateKeyRequest>(create);
  static RotateKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get keyId => $_getSZ(0);
  @$pb.TagNumber(1)
  set keyId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyId() => $_clearField(1);
}

class RotateKeyResponse extends $pb.GeneratedMessage {
  factory RotateKeyResponse({
    GatewayKey? key,
    $core.String? plaintext,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (plaintext != null) result.plaintext = plaintext;
    return result;
  }

  RotateKeyResponse._();

  factory RotateKeyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RotateKeyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RotateKeyResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<GatewayKey>(1, _omitFieldNames ? '' : 'key',
        subBuilder: GatewayKey.create)
    ..aOS(2, _omitFieldNames ? '' : 'plaintext')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RotateKeyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RotateKeyResponse copyWith(void Function(RotateKeyResponse) updates) =>
      super.copyWith((message) => updates(message as RotateKeyResponse))
          as RotateKeyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RotateKeyResponse create() => RotateKeyResponse._();
  @$core.override
  RotateKeyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RotateKeyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RotateKeyResponse>(create);
  static RotateKeyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  GatewayKey get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(GatewayKey value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);
  @$pb.TagNumber(1)
  GatewayKey ensureKey() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get plaintext => $_getSZ(1);
  @$pb.TagNumber(2)
  set plaintext($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlaintext() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlaintext() => $_clearField(2);
}

class RevokeKeyRequest extends $pb.GeneratedMessage {
  factory RevokeKeyRequest({
    $core.String? keyId,
  }) {
    final result = create();
    if (keyId != null) result.keyId = keyId;
    return result;
  }

  RevokeKeyRequest._();

  factory RevokeKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeKeyRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'keyId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeKeyRequest copyWith(void Function(RevokeKeyRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeKeyRequest))
          as RevokeKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeKeyRequest create() => RevokeKeyRequest._();
  @$core.override
  RevokeKeyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeKeyRequest>(create);
  static RevokeKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get keyId => $_getSZ(0);
  @$pb.TagNumber(1)
  set keyId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyId() => $_clearField(1);
}

class RevokeKeyResponse extends $pb.GeneratedMessage {
  factory RevokeKeyResponse({
    $core.bool? revoked,
  }) {
    final result = create();
    if (revoked != null) result.revoked = revoked;
    return result;
  }

  RevokeKeyResponse._();

  factory RevokeKeyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeKeyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeKeyResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'revoked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeKeyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeKeyResponse copyWith(void Function(RevokeKeyResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeKeyResponse))
          as RevokeKeyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeKeyResponse create() => RevokeKeyResponse._();
  @$core.override
  RevokeKeyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeKeyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeKeyResponse>(create);
  static RevokeKeyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get revoked => $_getBF(0);
  @$pb.TagNumber(1)
  set revoked($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevoked() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevoked() => $_clearField(1);
}

class GetInstanceLogsRequest extends $pb.GeneratedMessage {
  factory GetInstanceLogsRequest({
    $core.String? instanceId,
    $core.int? tailLines,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    if (tailLines != null) result.tailLines = tailLines;
    return result;
  }

  GetInstanceLogsRequest._();

  factory GetInstanceLogsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstanceLogsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstanceLogsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..aI(2, _omitFieldNames ? '' : 'tailLines')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceLogsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceLogsRequest copyWith(
          void Function(GetInstanceLogsRequest) updates) =>
      super.copyWith((message) => updates(message as GetInstanceLogsRequest))
          as GetInstanceLogsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstanceLogsRequest create() => GetInstanceLogsRequest._();
  @$core.override
  GetInstanceLogsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstanceLogsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstanceLogsRequest>(create);
  static GetInstanceLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);

  /// Number of trailing lines to return per stream. Zero returns everything the
  /// supervisor still holds, which is a bounded ring buffer either way.
  @$pb.TagNumber(2)
  $core.int get tailLines => $_getIZ(1);
  @$pb.TagNumber(2)
  set tailLines($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTailLines() => $_has(1);
  @$pb.TagNumber(2)
  void clearTailLines() => $_clearField(2);
}

class GetInstanceLogsResponse extends $pb.GeneratedMessage {
  factory GetInstanceLogsResponse({
    $core.String? stdout,
    $core.String? stderr,
    $core.bool? available,
  }) {
    final result = create();
    if (stdout != null) result.stdout = stdout;
    if (stderr != null) result.stderr = stderr;
    if (available != null) result.available = available;
    return result;
  }

  GetInstanceLogsResponse._();

  factory GetInstanceLogsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstanceLogsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstanceLogsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'stdout')
    ..aOS(2, _omitFieldNames ? '' : 'stderr')
    ..aOB(3, _omitFieldNames ? '' : 'available')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceLogsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstanceLogsResponse copyWith(
          void Function(GetInstanceLogsResponse) updates) =>
      super.copyWith((message) => updates(message as GetInstanceLogsResponse))
          as GetInstanceLogsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstanceLogsResponse create() => GetInstanceLogsResponse._();
  @$core.override
  GetInstanceLogsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstanceLogsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstanceLogsResponse>(create);
  static GetInstanceLogsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get stdout => $_getSZ(0);
  @$pb.TagNumber(1)
  set stdout($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStdout() => $_has(0);
  @$pb.TagNumber(1)
  void clearStdout() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get stderr => $_getSZ(1);
  @$pb.TagNumber(2)
  set stderr($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStderr() => $_has(1);
  @$pb.TagNumber(2)
  void clearStderr() => $_clearField(2);

  /// False when the process is gone: the buffers live with the process, so a
  /// stopped instance has no output to show.
  @$pb.TagNumber(3)
  $core.bool get available => $_getBF(2);
  @$pb.TagNumber(3)
  set available($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvailable() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvailable() => $_clearField(3);
}

/// QuantizationType is one target format the installed llama.cpp build can
/// write. The figures come from that build's own help output rather than from a
/// table maintained in Culpeo Studio, so they always describe the binary that
/// would actually do the work.
class QuantizationType extends $pb.GeneratedMessage {
  factory QuantizationType({
    $core.String? name,
    $core.String? description,
    $core.double? sizeGibAtReference,
    $core.double? perplexityDelta,
    $core.String? referenceModel,
    $core.double? bitsPerWeight,
    $core.String? alias,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (sizeGibAtReference != null)
      result.sizeGibAtReference = sizeGibAtReference;
    if (perplexityDelta != null) result.perplexityDelta = perplexityDelta;
    if (referenceModel != null) result.referenceModel = referenceModel;
    if (bitsPerWeight != null) result.bitsPerWeight = bitsPerWeight;
    if (alias != null) result.alias = alias;
    return result;
  }

  QuantizationType._();

  factory QuantizationType.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QuantizationType.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuantizationType',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aD(3, _omitFieldNames ? '' : 'sizeGibAtReference')
    ..aD(4, _omitFieldNames ? '' : 'perplexityDelta')
    ..aOS(5, _omitFieldNames ? '' : 'referenceModel')
    ..aD(6, _omitFieldNames ? '' : 'bitsPerWeight')
    ..aOS(7, _omitFieldNames ? '' : 'alias')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantizationType clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantizationType copyWith(void Function(QuantizationType) updates) =>
      super.copyWith((message) => updates(message as QuantizationType))
          as QuantizationType;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuantizationType create() => QuantizationType._();
  @$core.override
  QuantizationType createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QuantizationType getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuantizationType>(create);
  static QuantizationType? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  /// Size and perplexity delta for the reference model the build names, which
  /// is the only quality comparison the tool itself provides.
  @$pb.TagNumber(3)
  $core.double get sizeGibAtReference => $_getN(2);
  @$pb.TagNumber(3)
  set sizeGibAtReference($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeGibAtReference() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeGibAtReference() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get perplexityDelta => $_getN(3);
  @$pb.TagNumber(4)
  set perplexityDelta($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPerplexityDelta() => $_has(3);
  @$pb.TagNumber(4)
  void clearPerplexityDelta() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get referenceModel => $_getSZ(4);
  @$pb.TagNumber(5)
  set referenceModel($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReferenceModel() => $_has(4);
  @$pb.TagNumber(5)
  void clearReferenceModel() => $_clearField(5);

  /// Reported instead of the pair above for the types described this way.
  @$pb.TagNumber(6)
  $core.double get bitsPerWeight => $_getN(5);
  @$pb.TagNumber(6)
  set bitsPerWeight($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBitsPerWeight() => $_has(5);
  @$pb.TagNumber(6)
  void clearBitsPerWeight() => $_clearField(6);

  /// Set when this name resolves to another entry, such as Q4_K to Q4_K_M.
  @$pb.TagNumber(7)
  $core.String get alias => $_getSZ(6);
  @$pb.TagNumber(7)
  set alias($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlias() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlias() => $_clearField(7);
}

class ListQuantizationTypesRequest extends $pb.GeneratedMessage {
  factory ListQuantizationTypesRequest() => create();

  ListQuantizationTypesRequest._();

  factory ListQuantizationTypesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListQuantizationTypesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListQuantizationTypesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListQuantizationTypesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListQuantizationTypesRequest copyWith(
          void Function(ListQuantizationTypesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListQuantizationTypesRequest))
          as ListQuantizationTypesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListQuantizationTypesRequest create() =>
      ListQuantizationTypesRequest._();
  @$core.override
  ListQuantizationTypesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListQuantizationTypesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListQuantizationTypesRequest>(create);
  static ListQuantizationTypesRequest? _defaultInstance;
}

class ListQuantizationTypesResponse extends $pb.GeneratedMessage {
  factory ListQuantizationTypesResponse({
    $core.Iterable<QuantizationType>? types,
    $core.bool? available,
    $core.String? unavailableReason,
  }) {
    final result = create();
    if (types != null) result.types.addAll(types);
    if (available != null) result.available = available;
    if (unavailableReason != null) result.unavailableReason = unavailableReason;
    return result;
  }

  ListQuantizationTypesResponse._();

  factory ListQuantizationTypesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListQuantizationTypesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListQuantizationTypesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<QuantizationType>(1, _omitFieldNames ? '' : 'types',
        subBuilder: QuantizationType.create)
    ..aOB(2, _omitFieldNames ? '' : 'available')
    ..aOS(3, _omitFieldNames ? '' : 'unavailableReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListQuantizationTypesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListQuantizationTypesResponse copyWith(
          void Function(ListQuantizationTypesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListQuantizationTypesResponse))
          as ListQuantizationTypesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListQuantizationTypesResponse create() =>
      ListQuantizationTypesResponse._();
  @$core.override
  ListQuantizationTypesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListQuantizationTypesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListQuantizationTypesResponse>(create);
  static ListQuantizationTypesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<QuantizationType> get types => $_getList(0);

  /// False when no local runtime is installed yet, in which case the tool that
  /// would answer this is not on disk.
  @$pb.TagNumber(2)
  $core.bool get available => $_getBF(1);
  @$pb.TagNumber(2)
  set available($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvailable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get unavailableReason => $_getSZ(2);
  @$pb.TagNumber(3)
  set unavailableReason($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnavailableReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnavailableReason() => $_clearField(3);
}

/// QuantizationRequest names one conversion.
class QuantizationRequest extends $pb.GeneratedMessage {
  factory QuantizationRequest({
    $core.String? sourceModelId,
    $core.String? targetType,
    $core.String? targetName,
    $core.bool? allowRequantize,
    $core.bool? leaveOutputTensor,
    $core.int? threads,
  }) {
    final result = create();
    if (sourceModelId != null) result.sourceModelId = sourceModelId;
    if (targetType != null) result.targetType = targetType;
    if (targetName != null) result.targetName = targetName;
    if (allowRequantize != null) result.allowRequantize = allowRequantize;
    if (leaveOutputTensor != null) result.leaveOutputTensor = leaveOutputTensor;
    if (threads != null) result.threads = threads;
    return result;
  }

  QuantizationRequest._();

  factory QuantizationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QuantizationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuantizationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceModelId')
    ..aOS(2, _omitFieldNames ? '' : 'targetType')
    ..aOS(3, _omitFieldNames ? '' : 'targetName')
    ..aOB(4, _omitFieldNames ? '' : 'allowRequantize')
    ..aOB(5, _omitFieldNames ? '' : 'leaveOutputTensor')
    ..aI(6, _omitFieldNames ? '' : 'threads')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantizationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantizationRequest copyWith(void Function(QuantizationRequest) updates) =>
      super.copyWith((message) => updates(message as QuantizationRequest))
          as QuantizationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuantizationRequest create() => QuantizationRequest._();
  @$core.override
  QuantizationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QuantizationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuantizationRequest>(create);
  static QuantizationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceModelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceModelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceModelId() => $_clearField(1);

  /// A name from ListQuantizationTypes, such as Q4_K_M.
  @$pb.TagNumber(2)
  $core.String get targetType => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetType() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetType() => $_clearField(2);

  /// Bare filename for the result, placed beside its source. Empty derives one
  /// from the source name and the target type.
  @$pb.TagNumber(3)
  $core.String get targetName => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetName() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetName() => $_clearField(3);

  /// Required when the source is already quantised. Re-quantising stacks loss on
  /// loss, so it is never implied.
  @$pb.TagNumber(4)
  $core.bool get allowRequantize => $_getBF(3);
  @$pb.TagNumber(4)
  set allowRequantize($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAllowRequantize() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowRequantize() => $_clearField(4);

  /// Keep output.weight at its source precision: a little larger, noticeably
  /// better at the low end of the range.
  @$pb.TagNumber(5)
  $core.bool get leaveOutputTensor => $_getBF(4);
  @$pb.TagNumber(5)
  set leaveOutputTensor($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLeaveOutputTensor() => $_has(4);
  @$pb.TagNumber(5)
  void clearLeaveOutputTensor() => $_clearField(5);

  /// Zero lets the tool pick.
  @$pb.TagNumber(6)
  $core.int get threads => $_getIZ(5);
  @$pb.TagNumber(6)
  set threads($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasThreads() => $_has(5);
  @$pb.TagNumber(6)
  void clearThreads() => $_clearField(6);
}

/// QuantizationPreflight is what the conversion would do, computed before
/// anything is written. The size is not estimated from bits per weight: it is
/// what the tool's own dry run reported.
class QuantizationPreflight extends $pb.GeneratedMessage {
  factory QuantizationPreflight({
    $core.String? sourceModelId,
    $core.String? sourceName,
    $core.String? sourceQuantization,
    $fixnum.Int64? sourceBytes,
    $core.String? targetType,
    $core.String? targetName,
    $core.String? targetRelativePath,
    $fixnum.Int64? estimatedBytes,
    $fixnum.Int64? freeDiskBytes,
    $fixnum.Int64? requiredDiskBytes,
    $core.double? sourceBitsPerWeight,
    $core.double? targetBitsPerWeight,
    $core.bool? isRequantization,
    $core.bool? feasible,
    $core.Iterable<$core.String>? blockers,
    $core.Iterable<$core.String>? warnings,
  }) {
    final result = create();
    if (sourceModelId != null) result.sourceModelId = sourceModelId;
    if (sourceName != null) result.sourceName = sourceName;
    if (sourceQuantization != null)
      result.sourceQuantization = sourceQuantization;
    if (sourceBytes != null) result.sourceBytes = sourceBytes;
    if (targetType != null) result.targetType = targetType;
    if (targetName != null) result.targetName = targetName;
    if (targetRelativePath != null)
      result.targetRelativePath = targetRelativePath;
    if (estimatedBytes != null) result.estimatedBytes = estimatedBytes;
    if (freeDiskBytes != null) result.freeDiskBytes = freeDiskBytes;
    if (requiredDiskBytes != null) result.requiredDiskBytes = requiredDiskBytes;
    if (sourceBitsPerWeight != null)
      result.sourceBitsPerWeight = sourceBitsPerWeight;
    if (targetBitsPerWeight != null)
      result.targetBitsPerWeight = targetBitsPerWeight;
    if (isRequantization != null) result.isRequantization = isRequantization;
    if (feasible != null) result.feasible = feasible;
    if (blockers != null) result.blockers.addAll(blockers);
    if (warnings != null) result.warnings.addAll(warnings);
    return result;
  }

  QuantizationPreflight._();

  factory QuantizationPreflight.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QuantizationPreflight.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuantizationPreflight',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceModelId')
    ..aOS(2, _omitFieldNames ? '' : 'sourceName')
    ..aOS(3, _omitFieldNames ? '' : 'sourceQuantization')
    ..aInt64(4, _omitFieldNames ? '' : 'sourceBytes')
    ..aOS(5, _omitFieldNames ? '' : 'targetType')
    ..aOS(6, _omitFieldNames ? '' : 'targetName')
    ..aOS(7, _omitFieldNames ? '' : 'targetRelativePath')
    ..aInt64(8, _omitFieldNames ? '' : 'estimatedBytes')
    ..aInt64(9, _omitFieldNames ? '' : 'freeDiskBytes')
    ..aInt64(10, _omitFieldNames ? '' : 'requiredDiskBytes')
    ..aD(11, _omitFieldNames ? '' : 'sourceBitsPerWeight')
    ..aD(12, _omitFieldNames ? '' : 'targetBitsPerWeight')
    ..aOB(13, _omitFieldNames ? '' : 'isRequantization')
    ..aOB(14, _omitFieldNames ? '' : 'feasible')
    ..pPS(15, _omitFieldNames ? '' : 'blockers')
    ..pPS(16, _omitFieldNames ? '' : 'warnings')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantizationPreflight clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantizationPreflight copyWith(
          void Function(QuantizationPreflight) updates) =>
      super.copyWith((message) => updates(message as QuantizationPreflight))
          as QuantizationPreflight;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuantizationPreflight create() => QuantizationPreflight._();
  @$core.override
  QuantizationPreflight createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QuantizationPreflight getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuantizationPreflight>(create);
  static QuantizationPreflight? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceModelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceModelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sourceName => $_getSZ(1);
  @$pb.TagNumber(2)
  set sourceName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSourceName() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sourceQuantization => $_getSZ(2);
  @$pb.TagNumber(3)
  set sourceQuantization($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSourceQuantization() => $_has(2);
  @$pb.TagNumber(3)
  void clearSourceQuantization() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sourceBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set sourceBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSourceBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourceBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get targetType => $_getSZ(4);
  @$pb.TagNumber(5)
  set targetType($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTargetType() => $_has(4);
  @$pb.TagNumber(5)
  void clearTargetType() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get targetName => $_getSZ(5);
  @$pb.TagNumber(6)
  set targetName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTargetName() => $_has(5);
  @$pb.TagNumber(6)
  void clearTargetName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get targetRelativePath => $_getSZ(6);
  @$pb.TagNumber(7)
  set targetRelativePath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTargetRelativePath() => $_has(6);
  @$pb.TagNumber(7)
  void clearTargetRelativePath() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get estimatedBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set estimatedBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEstimatedBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearEstimatedBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get freeDiskBytes => $_getI64(8);
  @$pb.TagNumber(9)
  set freeDiskBytes($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFreeDiskBytes() => $_has(8);
  @$pb.TagNumber(9)
  void clearFreeDiskBytes() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get requiredDiskBytes => $_getI64(9);
  @$pb.TagNumber(10)
  set requiredDiskBytes($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRequiredDiskBytes() => $_has(9);
  @$pb.TagNumber(10)
  void clearRequiredDiskBytes() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get sourceBitsPerWeight => $_getN(10);
  @$pb.TagNumber(11)
  set sourceBitsPerWeight($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSourceBitsPerWeight() => $_has(10);
  @$pb.TagNumber(11)
  void clearSourceBitsPerWeight() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get targetBitsPerWeight => $_getN(11);
  @$pb.TagNumber(12)
  set targetBitsPerWeight($core.double value) => $_setDouble(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTargetBitsPerWeight() => $_has(11);
  @$pb.TagNumber(12)
  void clearTargetBitsPerWeight() => $_clearField(12);

  /// The source already carries a quantisation, so the result loses quality
  /// twice. Most local GGUFs are in this state, which makes it the single most
  /// important thing to show.
  @$pb.TagNumber(13)
  $core.bool get isRequantization => $_getBF(12);
  @$pb.TagNumber(13)
  set isRequantization($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasIsRequantization() => $_has(12);
  @$pb.TagNumber(13)
  void clearIsRequantization() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get feasible => $_getBF(13);
  @$pb.TagNumber(14)
  set feasible($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasFeasible() => $_has(13);
  @$pb.TagNumber(14)
  void clearFeasible() => $_clearField(14);

  /// Reasons the conversion cannot start. Empty when feasible.
  @$pb.TagNumber(15)
  $pb.PbList<$core.String> get blockers => $_getList(14);

  /// Reasons to think twice, which do not prevent it.
  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get warnings => $_getList(15);
}

class PreflightQuantizationRequest extends $pb.GeneratedMessage {
  factory PreflightQuantizationRequest({
    QuantizationRequest? request,
  }) {
    final result = create();
    if (request != null) result.request = request;
    return result;
  }

  PreflightQuantizationRequest._();

  factory PreflightQuantizationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreflightQuantizationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreflightQuantizationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<QuantizationRequest>(1, _omitFieldNames ? '' : 'request',
        subBuilder: QuantizationRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightQuantizationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightQuantizationRequest copyWith(
          void Function(PreflightQuantizationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as PreflightQuantizationRequest))
          as PreflightQuantizationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreflightQuantizationRequest create() =>
      PreflightQuantizationRequest._();
  @$core.override
  PreflightQuantizationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreflightQuantizationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreflightQuantizationRequest>(create);
  static PreflightQuantizationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  QuantizationRequest get request => $_getN(0);
  @$pb.TagNumber(1)
  set request(QuantizationRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  QuantizationRequest ensureRequest() => $_ensure(0);
}

class PreflightQuantizationResponse extends $pb.GeneratedMessage {
  factory PreflightQuantizationResponse({
    QuantizationPreflight? preflight,
  }) {
    final result = create();
    if (preflight != null) result.preflight = preflight;
    return result;
  }

  PreflightQuantizationResponse._();

  factory PreflightQuantizationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreflightQuantizationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreflightQuantizationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<QuantizationPreflight>(1, _omitFieldNames ? '' : 'preflight',
        subBuilder: QuantizationPreflight.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightQuantizationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreflightQuantizationResponse copyWith(
          void Function(PreflightQuantizationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as PreflightQuantizationResponse))
          as PreflightQuantizationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreflightQuantizationResponse create() =>
      PreflightQuantizationResponse._();
  @$core.override
  PreflightQuantizationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreflightQuantizationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreflightQuantizationResponse>(create);
  static PreflightQuantizationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  QuantizationPreflight get preflight => $_getN(0);
  @$pb.TagNumber(1)
  set preflight(QuantizationPreflight value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreflight() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreflight() => $_clearField(1);
  @$pb.TagNumber(1)
  QuantizationPreflight ensurePreflight() => $_ensure(0);
}

class StartQuantizationRequest extends $pb.GeneratedMessage {
  factory StartQuantizationRequest({
    QuantizationRequest? request,
  }) {
    final result = create();
    if (request != null) result.request = request;
    return result;
  }

  StartQuantizationRequest._();

  factory StartQuantizationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartQuantizationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartQuantizationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<QuantizationRequest>(1, _omitFieldNames ? '' : 'request',
        subBuilder: QuantizationRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartQuantizationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartQuantizationRequest copyWith(
          void Function(StartQuantizationRequest) updates) =>
      super.copyWith((message) => updates(message as StartQuantizationRequest))
          as StartQuantizationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartQuantizationRequest create() => StartQuantizationRequest._();
  @$core.override
  StartQuantizationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartQuantizationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartQuantizationRequest>(create);
  static StartQuantizationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  QuantizationRequest get request => $_getN(0);
  @$pb.TagNumber(1)
  set request(QuantizationRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  QuantizationRequest ensureRequest() => $_ensure(0);
}

class StartQuantizationResponse extends $pb.GeneratedMessage {
  factory StartQuantizationResponse({
    $core.String? operationId,
    OperationState? state,
    QuantizationPreflight? preflight,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    if (state != null) result.state = state;
    if (preflight != null) result.preflight = preflight;
    return result;
  }

  StartQuantizationResponse._();

  factory StartQuantizationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartQuantizationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartQuantizationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..aE<OperationState>(2, _omitFieldNames ? '' : 'state',
        enumValues: OperationState.values)
    ..aOM<QuantizationPreflight>(3, _omitFieldNames ? '' : 'preflight',
        subBuilder: QuantizationPreflight.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartQuantizationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartQuantizationResponse copyWith(
          void Function(StartQuantizationResponse) updates) =>
      super.copyWith((message) => updates(message as StartQuantizationResponse))
          as StartQuantizationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartQuantizationResponse create() => StartQuantizationResponse._();
  @$core.override
  StartQuantizationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartQuantizationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartQuantizationResponse>(create);
  static StartQuantizationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);

  @$pb.TagNumber(2)
  OperationState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(OperationState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  QuantizationPreflight get preflight => $_getN(2);
  @$pb.TagNumber(3)
  set preflight(QuantizationPreflight value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPreflight() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreflight() => $_clearField(3);
  @$pb.TagNumber(3)
  QuantizationPreflight ensurePreflight() => $_ensure(2);
}

class EnginePreset extends $pb.GeneratedMessage {
  factory EnginePreset({
    $core.String? id,
    $core.String? name,
    $core.String? description,
    EngineConfig? config,
    $core.String? modelId,
    $3.Timestamp? createdAt,
    $3.Timestamp? updatedAt,
    $core.bool? builtIn,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (config != null) result.config = config;
    if (modelId != null) result.modelId = modelId;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (builtIn != null) result.builtIn = builtIn;
    return result;
  }

  EnginePreset._();

  factory EnginePreset.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnginePreset.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnginePreset',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOM<EngineConfig>(4, _omitFieldNames ? '' : 'config',
        subBuilder: EngineConfig.create)
    ..aOS(5, _omitFieldNames ? '' : 'modelId')
    ..aOM<$3.Timestamp>(6, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(7, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $3.Timestamp.create)
    ..aOB(8, _omitFieldNames ? '' : 'builtIn')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnginePreset clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnginePreset copyWith(void Function(EnginePreset) updates) =>
      super.copyWith((message) => updates(message as EnginePreset))
          as EnginePreset;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnginePreset create() => EnginePreset._();
  @$core.override
  EnginePreset createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnginePreset getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnginePreset>(create);
  static EnginePreset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  EngineConfig get config => $_getN(3);
  @$pb.TagNumber(4)
  set config(EngineConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasConfig() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfig() => $_clearField(4);
  @$pb.TagNumber(4)
  EngineConfig ensureConfig() => $_ensure(3);

  /// The model this was saved from, as a hint only. A preset is not bound to it.
  @$pb.TagNumber(5)
  $core.String get modelId => $_getSZ(4);
  @$pb.TagNumber(5)
  set modelId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModelId() => $_has(4);
  @$pb.TagNumber(5)
  void clearModelId() => $_clearField(5);

  @$pb.TagNumber(6)
  $3.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($3.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $3.Timestamp ensureCreatedAt() => $_ensure(5);

  @$pb.TagNumber(7)
  $3.Timestamp get updatedAt => $_getN(6);
  @$pb.TagNumber(7)
  set updatedAt($3.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $3.Timestamp ensureUpdatedAt() => $_ensure(6);

  /// Shipped with the engine: applicable and copyable, but not editable, so
  /// there is always something to fall back to.
  @$pb.TagNumber(8)
  $core.bool get builtIn => $_getBF(7);
  @$pb.TagNumber(8)
  set builtIn($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBuiltIn() => $_has(7);
  @$pb.TagNumber(8)
  void clearBuiltIn() => $_clearField(8);
}

class ListPresetsRequest extends $pb.GeneratedMessage {
  factory ListPresetsRequest() => create();

  ListPresetsRequest._();

  factory ListPresetsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListPresetsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPresetsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPresetsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPresetsRequest copyWith(void Function(ListPresetsRequest) updates) =>
      super.copyWith((message) => updates(message as ListPresetsRequest))
          as ListPresetsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPresetsRequest create() => ListPresetsRequest._();
  @$core.override
  ListPresetsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListPresetsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPresetsRequest>(create);
  static ListPresetsRequest? _defaultInstance;
}

class ListPresetsResponse extends $pb.GeneratedMessage {
  factory ListPresetsResponse({
    $core.Iterable<EnginePreset>? presets,
  }) {
    final result = create();
    if (presets != null) result.presets.addAll(presets);
    return result;
  }

  ListPresetsResponse._();

  factory ListPresetsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListPresetsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPresetsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<EnginePreset>(1, _omitFieldNames ? '' : 'presets',
        subBuilder: EnginePreset.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPresetsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPresetsResponse copyWith(void Function(ListPresetsResponse) updates) =>
      super.copyWith((message) => updates(message as ListPresetsResponse))
          as ListPresetsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPresetsResponse create() => ListPresetsResponse._();
  @$core.override
  ListPresetsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListPresetsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPresetsResponse>(create);
  static ListPresetsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<EnginePreset> get presets => $_getList(0);
}

class SavePresetRequest extends $pb.GeneratedMessage {
  factory SavePresetRequest({
    EnginePreset? preset,
  }) {
    final result = create();
    if (preset != null) result.preset = preset;
    return result;
  }

  SavePresetRequest._();

  factory SavePresetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavePresetRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavePresetRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EnginePreset>(1, _omitFieldNames ? '' : 'preset',
        subBuilder: EnginePreset.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavePresetRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavePresetRequest copyWith(void Function(SavePresetRequest) updates) =>
      super.copyWith((message) => updates(message as SavePresetRequest))
          as SavePresetRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavePresetRequest create() => SavePresetRequest._();
  @$core.override
  SavePresetRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavePresetRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavePresetRequest>(create);
  static SavePresetRequest? _defaultInstance;

  /// Empty creates a new preset; an existing id replaces that one.
  @$pb.TagNumber(1)
  EnginePreset get preset => $_getN(0);
  @$pb.TagNumber(1)
  set preset(EnginePreset value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreset() => $_clearField(1);
  @$pb.TagNumber(1)
  EnginePreset ensurePreset() => $_ensure(0);
}

class SavePresetResponse extends $pb.GeneratedMessage {
  factory SavePresetResponse({
    EnginePreset? preset,
  }) {
    final result = create();
    if (preset != null) result.preset = preset;
    return result;
  }

  SavePresetResponse._();

  factory SavePresetResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavePresetResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavePresetResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOM<EnginePreset>(1, _omitFieldNames ? '' : 'preset',
        subBuilder: EnginePreset.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavePresetResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavePresetResponse copyWith(void Function(SavePresetResponse) updates) =>
      super.copyWith((message) => updates(message as SavePresetResponse))
          as SavePresetResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavePresetResponse create() => SavePresetResponse._();
  @$core.override
  SavePresetResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavePresetResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavePresetResponse>(create);
  static SavePresetResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EnginePreset get preset => $_getN(0);
  @$pb.TagNumber(1)
  set preset(EnginePreset value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreset() => $_clearField(1);
  @$pb.TagNumber(1)
  EnginePreset ensurePreset() => $_ensure(0);
}

class DeletePresetRequest extends $pb.GeneratedMessage {
  factory DeletePresetRequest({
    $core.String? presetId,
  }) {
    final result = create();
    if (presetId != null) result.presetId = presetId;
    return result;
  }

  DeletePresetRequest._();

  factory DeletePresetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePresetRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePresetRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'presetId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePresetRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePresetRequest copyWith(void Function(DeletePresetRequest) updates) =>
      super.copyWith((message) => updates(message as DeletePresetRequest))
          as DeletePresetRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePresetRequest create() => DeletePresetRequest._();
  @$core.override
  DeletePresetRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeletePresetRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePresetRequest>(create);
  static DeletePresetRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get presetId => $_getSZ(0);
  @$pb.TagNumber(1)
  set presetId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPresetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPresetId() => $_clearField(1);
}

class DeletePresetResponse extends $pb.GeneratedMessage {
  factory DeletePresetResponse({
    $core.bool? deleted,
  }) {
    final result = create();
    if (deleted != null) result.deleted = deleted;
    return result;
  }

  DeletePresetResponse._();

  factory DeletePresetResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePresetResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePresetResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'deleted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePresetResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePresetResponse copyWith(void Function(DeletePresetResponse) updates) =>
      super.copyWith((message) => updates(message as DeletePresetResponse))
          as DeletePresetResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePresetResponse create() => DeletePresetResponse._();
  @$core.override
  DeletePresetResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeletePresetResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePresetResponse>(create);
  static DeletePresetResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get deleted => $_getBF(0);
  @$pb.TagNumber(1)
  set deleted($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeleted() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeleted() => $_clearField(1);
}

class ExportPresetsRequest extends $pb.GeneratedMessage {
  factory ExportPresetsRequest({
    $core.Iterable<$core.String>? presetIds,
  }) {
    final result = create();
    if (presetIds != null) result.presetIds.addAll(presetIds);
    return result;
  }

  ExportPresetsRequest._();

  factory ExportPresetsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportPresetsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportPresetsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'presetIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportPresetsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportPresetsRequest copyWith(void Function(ExportPresetsRequest) updates) =>
      super.copyWith((message) => updates(message as ExportPresetsRequest))
          as ExportPresetsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportPresetsRequest create() => ExportPresetsRequest._();
  @$core.override
  ExportPresetsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportPresetsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportPresetsRequest>(create);
  static ExportPresetsRequest? _defaultInstance;

  /// Empty exports every preset the user saved themselves.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get presetIds => $_getList(0);
}

class ExportPresetsResponse extends $pb.GeneratedMessage {
  factory ExportPresetsResponse({
    $core.String? document,
    $core.String? suggestedFilename,
  }) {
    final result = create();
    if (document != null) result.document = document;
    if (suggestedFilename != null) result.suggestedFilename = suggestedFilename;
    return result;
  }

  ExportPresetsResponse._();

  factory ExportPresetsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportPresetsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportPresetsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'document')
    ..aOS(2, _omitFieldNames ? '' : 'suggestedFilename')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportPresetsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportPresetsResponse copyWith(
          void Function(ExportPresetsResponse) updates) =>
      super.copyWith((message) => updates(message as ExportPresetsResponse))
          as ExportPresetsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportPresetsResponse create() => ExportPresetsResponse._();
  @$core.override
  ExportPresetsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportPresetsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportPresetsResponse>(create);
  static ExportPresetsResponse? _defaultInstance;

  /// The transfer format, as JSON. The client writes it wherever it likes.
  @$pb.TagNumber(1)
  $core.String get document => $_getSZ(0);
  @$pb.TagNumber(1)
  set document($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDocument() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocument() => $_clearField(1);

  /// A filename the client can offer by default.
  @$pb.TagNumber(2)
  $core.String get suggestedFilename => $_getSZ(1);
  @$pb.TagNumber(2)
  set suggestedFilename($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSuggestedFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearSuggestedFilename() => $_clearField(2);
}

class ImportPresetsRequest extends $pb.GeneratedMessage {
  factory ImportPresetsRequest({
    $core.String? document,
  }) {
    final result = create();
    if (document != null) result.document = document;
    return result;
  }

  ImportPresetsRequest._();

  factory ImportPresetsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportPresetsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportPresetsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'document')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportPresetsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportPresetsRequest copyWith(void Function(ImportPresetsRequest) updates) =>
      super.copyWith((message) => updates(message as ImportPresetsRequest))
          as ImportPresetsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportPresetsRequest create() => ImportPresetsRequest._();
  @$core.override
  ImportPresetsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportPresetsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportPresetsRequest>(create);
  static ImportPresetsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get document => $_getSZ(0);
  @$pb.TagNumber(1)
  set document($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDocument() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocument() => $_clearField(1);
}

class ImportPresetsResponse extends $pb.GeneratedMessage {
  factory ImportPresetsResponse({
    $core.Iterable<EnginePreset>? presets,
  }) {
    final result = create();
    if (presets != null) result.presets.addAll(presets);
    return result;
  }

  ImportPresetsResponse._();

  factory ImportPresetsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportPresetsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportPresetsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.engine.v1'),
      createEmptyInstance: create)
    ..pPM<EnginePreset>(1, _omitFieldNames ? '' : 'presets',
        subBuilder: EnginePreset.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportPresetsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportPresetsResponse copyWith(
          void Function(ImportPresetsResponse) updates) =>
      super.copyWith((message) => updates(message as ImportPresetsResponse))
          as ImportPresetsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportPresetsResponse create() => ImportPresetsResponse._();
  @$core.override
  ImportPresetsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportPresetsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportPresetsResponse>(create);
  static ImportPresetsResponse? _defaultInstance;

  /// Every entry is imported under a fresh id, so importing the same file twice
  /// makes copies rather than silently overwriting.
  @$pb.TagNumber(1)
  $pb.PbList<EnginePreset> get presets => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
