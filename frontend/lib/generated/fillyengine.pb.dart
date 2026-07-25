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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'fillyengine.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'fillyengine.pbenum.dart';

class StartEngineRequest extends $pb.GeneratedMessage {
  factory StartEngineRequest({
    $core.String? modelPath,
    $core.int? gpuLayers,
    $core.int? threads,
    $core.int? contextSize,
  }) {
    final result = create();
    if (modelPath != null) result.modelPath = modelPath;
    if (gpuLayers != null) result.gpuLayers = gpuLayers;
    if (threads != null) result.threads = threads;
    if (contextSize != null) result.contextSize = contextSize;
    return result;
  }

  StartEngineRequest._();

  factory StartEngineRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartEngineRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartEngineRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelPath')
    ..aI(2, _omitFieldNames ? '' : 'gpuLayers')
    ..aI(3, _omitFieldNames ? '' : 'threads')
    ..aI(4, _omitFieldNames ? '' : 'contextSize')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartEngineRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartEngineRequest copyWith(void Function(StartEngineRequest) updates) =>
      super.copyWith((message) => updates(message as StartEngineRequest))
          as StartEngineRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartEngineRequest create() => StartEngineRequest._();
  @$core.override
  StartEngineRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartEngineRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartEngineRequest>(create);
  static StartEngineRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get gpuLayers => $_getIZ(1);
  @$pb.TagNumber(2)
  set gpuLayers($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGpuLayers() => $_has(1);
  @$pb.TagNumber(2)
  void clearGpuLayers() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get threads => $_getIZ(2);
  @$pb.TagNumber(3)
  set threads($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThreads() => $_has(2);
  @$pb.TagNumber(3)
  void clearThreads() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get contextSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set contextSize($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContextSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearContextSize() => $_clearField(4);
}

class LoadModelRequest extends $pb.GeneratedMessage {
  factory LoadModelRequest({
    $core.String? modelPath,
  }) {
    final result = create();
    if (modelPath != null) result.modelPath = modelPath;
    return result;
  }

  LoadModelRequest._();

  factory LoadModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoadModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoadModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadModelRequest copyWith(void Function(LoadModelRequest) updates) =>
      super.copyWith((message) => updates(message as LoadModelRequest))
          as LoadModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoadModelRequest create() => LoadModelRequest._();
  @$core.override
  LoadModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoadModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoadModelRequest>(create);
  static LoadModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelPath() => $_clearField(1);
}

class EngineStatus extends $pb.GeneratedMessage {
  factory EngineStatus({
    $core.bool? running,
    $core.String? model,
    $fixnum.Int64? vramUsedMb,
    $fixnum.Int64? ramUsedMb,
  }) {
    final result = create();
    if (running != null) result.running = running;
    if (model != null) result.model = model;
    if (vramUsedMb != null) result.vramUsedMb = vramUsedMb;
    if (ramUsedMb != null) result.ramUsedMb = ramUsedMb;
    return result;
  }

  EngineStatus._();

  factory EngineStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'running')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..aInt64(3, _omitFieldNames ? '' : 'vramUsedMb')
    ..aInt64(4, _omitFieldNames ? '' : 'ramUsedMb')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineStatus copyWith(void Function(EngineStatus) updates) =>
      super.copyWith((message) => updates(message as EngineStatus))
          as EngineStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineStatus create() => EngineStatus._();
  @$core.override
  EngineStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineStatus>(create);
  static EngineStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get running => $_getBF(0);
  @$pb.TagNumber(1)
  set running($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunning() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunning() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get model => $_getSZ(1);
  @$pb.TagNumber(2)
  set model($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModel() => $_has(1);
  @$pb.TagNumber(2)
  void clearModel() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get vramUsedMb => $_getI64(2);
  @$pb.TagNumber(3)
  set vramUsedMb($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVramUsedMb() => $_has(2);
  @$pb.TagNumber(3)
  void clearVramUsedMb() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get ramUsedMb => $_getI64(3);
  @$pb.TagNumber(4)
  set ramUsedMb($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRamUsedMb() => $_has(3);
  @$pb.TagNumber(4)
  void clearRamUsedMb() => $_clearField(4);
}

class ModelList extends $pb.GeneratedMessage {
  factory ModelList({
    $core.Iterable<ModelInfo>? models,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    return result;
  }

  ModelList._();

  factory ModelList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..pPM<ModelInfo>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelList copyWith(void Function(ModelList) updates) =>
      super.copyWith((message) => updates(message as ModelList)) as ModelList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelList create() => ModelList._();
  @$core.override
  ModelList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelList>(create);
  static ModelList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModelInfo> get models => $_getList(0);
}

class ModelInfo extends $pb.GeneratedMessage {
  factory ModelInfo({
    $core.String? name,
    $core.String? path,
    $core.String? format,
    $fixnum.Int64? sizeBytes,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (path != null) result.path = path;
    if (format != null) result.format = format;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    return result;
  }

  ModelInfo._();

  factory ModelInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'format')
    ..aInt64(4, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelInfo copyWith(void Function(ModelInfo) updates) =>
      super.copyWith((message) => updates(message as ModelInfo)) as ModelInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelInfo create() => ModelInfo._();
  @$core.override
  ModelInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelInfo>(create);
  static ModelInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get format => $_getSZ(2);
  @$pb.TagNumber(3)
  set format($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFormat() => $_has(2);
  @$pb.TagNumber(3)
  void clearFormat() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sizeBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSizeBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearSizeBytes() => $_clearField(4);
}

class CreateSessionRequest extends $pb.GeneratedMessage {
  factory CreateSessionRequest({
    $core.String? modelId,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    return result;
  }

  CreateSessionRequest._();

  factory CreateSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest copyWith(void Function(CreateSessionRequest) updates) =>
      super.copyWith((message) => updates(message as CreateSessionRequest))
          as CreateSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateSessionRequest create() => CreateSessionRequest._();
  @$core.override
  CreateSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionRequest>(create);
  static CreateSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);
}

class SessionInfo extends $pb.GeneratedMessage {
  factory SessionInfo({
    $core.String? sessionId,
    $core.String? modelId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (modelId != null) result.modelId = modelId;
    return result;
  }

  SessionInfo._();

  factory SessionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'modelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionInfo copyWith(void Function(SessionInfo) updates) =>
      super.copyWith((message) => updates(message as SessionInfo))
          as SessionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionInfo create() => SessionInfo._();
  @$core.override
  SessionInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SessionInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionInfo>(create);
  static SessionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelId() => $_clearField(2);
}

class SessionRequest extends $pb.GeneratedMessage {
  factory SessionRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  SessionRequest._();

  factory SessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionRequest copyWith(void Function(SessionRequest) updates) =>
      super.copyWith((message) => updates(message as SessionRequest))
          as SessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionRequest create() => SessionRequest._();
  @$core.override
  SessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionRequest>(create);
  static SessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class ChatMessageRequest extends $pb.GeneratedMessage {
  factory ChatMessageRequest({
    $core.String? sessionId,
    $core.String? message,
    $core.double? temperature,
    $core.int? maxTokens,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (message != null) result.message = message;
    if (temperature != null) result.temperature = temperature;
    if (maxTokens != null) result.maxTokens = maxTokens;
    return result;
  }

  ChatMessageRequest._();

  factory ChatMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChatMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aD(3, _omitFieldNames ? '' : 'temperature', fieldType: $pb.PbFieldType.OF)
    ..aI(4, _omitFieldNames ? '' : 'maxTokens')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessageRequest copyWith(void Function(ChatMessageRequest) updates) =>
      super.copyWith((message) => updates(message as ChatMessageRequest))
          as ChatMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatMessageRequest create() => ChatMessageRequest._();
  @$core.override
  ChatMessageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChatMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatMessageRequest>(create);
  static ChatMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get temperature => $_getN(2);
  @$pb.TagNumber(3)
  set temperature($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTemperature() => $_has(2);
  @$pb.TagNumber(3)
  void clearTemperature() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxTokens => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxTokens($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaxTokens() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxTokens() => $_clearField(4);
}

class ChatMessageResponse extends $pb.GeneratedMessage {
  factory ChatMessageResponse({
    $core.String? reply,
    $core.String? sessionId,
    $core.int? tokensUsed,
  }) {
    final result = create();
    if (reply != null) result.reply = reply;
    if (sessionId != null) result.sessionId = sessionId;
    if (tokensUsed != null) result.tokensUsed = tokensUsed;
    return result;
  }

  ChatMessageResponse._();

  factory ChatMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChatMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'reply')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aI(3, _omitFieldNames ? '' : 'tokensUsed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessageResponse copyWith(void Function(ChatMessageResponse) updates) =>
      super.copyWith((message) => updates(message as ChatMessageResponse))
          as ChatMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatMessageResponse create() => ChatMessageResponse._();
  @$core.override
  ChatMessageResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChatMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatMessageResponse>(create);
  static ChatMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reply => $_getSZ(0);
  @$pb.TagNumber(1)
  set reply($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReply() => $_has(0);
  @$pb.TagNumber(1)
  void clearReply() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get tokensUsed => $_getIZ(2);
  @$pb.TagNumber(3)
  set tokensUsed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTokensUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearTokensUsed() => $_clearField(3);
}

class ChatToken extends $pb.GeneratedMessage {
  factory ChatToken({
    $core.String? token,
    $core.bool? done,
  }) {
    final result = create();
    if (token != null) result.token = token;
    if (done != null) result.done = done;
    return result;
  }

  ChatToken._();

  factory ChatToken.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChatToken.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatToken',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOB(2, _omitFieldNames ? '' : 'done')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatToken clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatToken copyWith(void Function(ChatToken) updates) =>
      super.copyWith((message) => updates(message as ChatToken)) as ChatToken;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatToken create() => ChatToken._();
  @$core.override
  ChatToken createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChatToken getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatToken>(create);
  static ChatToken? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get done => $_getBF(1);
  @$pb.TagNumber(2)
  set done($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDone() => $_has(1);
  @$pb.TagNumber(2)
  void clearDone() => $_clearField(2);
}

class ChatHistory extends $pb.GeneratedMessage {
  factory ChatHistory({
    $core.Iterable<ChatEntry>? messages,
  }) {
    final result = create();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  ChatHistory._();

  factory ChatHistory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChatHistory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatHistory',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..pPM<ChatEntry>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: ChatEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatHistory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatHistory copyWith(void Function(ChatHistory) updates) =>
      super.copyWith((message) => updates(message as ChatHistory))
          as ChatHistory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatHistory create() => ChatHistory._();
  @$core.override
  ChatHistory createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChatHistory getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatHistory>(create);
  static ChatHistory? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ChatEntry> get messages => $_getList(0);
}

class ChatEntry extends $pb.GeneratedMessage {
  factory ChatEntry({
    $core.String? role,
    $core.String? content,
    $fixnum.Int64? timestamp,
  }) {
    final result = create();
    if (role != null) result.role = role;
    if (content != null) result.content = content;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  ChatEntry._();

  factory ChatEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChatEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'role')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..aInt64(3, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatEntry copyWith(void Function(ChatEntry) updates) =>
      super.copyWith((message) => updates(message as ChatEntry)) as ChatEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatEntry create() => ChatEntry._();
  @$core.override
  ChatEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChatEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatEntry>(create);
  static ChatEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get role => $_getSZ(0);
  @$pb.TagNumber(1)
  set role($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);
}

class TrainingRequest extends $pb.GeneratedMessage {
  factory TrainingRequest({
    $core.String? modelId,
    $core.String? datasetPath,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? hyperparams,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    if (datasetPath != null) result.datasetPath = datasetPath;
    if (hyperparams != null) result.hyperparams.addEntries(hyperparams);
    return result;
  }

  TrainingRequest._();

  factory TrainingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrainingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrainingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOS(2, _omitFieldNames ? '' : 'datasetPath')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'hyperparams',
        entryClassName: 'TrainingRequest.HyperparamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fillyengine'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrainingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrainingRequest copyWith(void Function(TrainingRequest) updates) =>
      super.copyWith((message) => updates(message as TrainingRequest))
          as TrainingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrainingRequest create() => TrainingRequest._();
  @$core.override
  TrainingRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrainingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrainingRequest>(create);
  static TrainingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get datasetPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set datasetPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatasetPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatasetPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get hyperparams => $_getMap(2);
}

class JobRequest extends $pb.GeneratedMessage {
  factory JobRequest({
    $core.String? jobId,
  }) {
    final result = create();
    if (jobId != null) result.jobId = jobId;
    return result;
  }

  JobRequest._();

  factory JobRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JobRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JobRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jobId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobRequest copyWith(void Function(JobRequest) updates) =>
      super.copyWith((message) => updates(message as JobRequest)) as JobRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JobRequest create() => JobRequest._();
  @$core.override
  JobRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JobRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JobRequest>(create);
  static JobRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jobId => $_getSZ(0);
  @$pb.TagNumber(1)
  set jobId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJobId() => $_has(0);
  @$pb.TagNumber(1)
  void clearJobId() => $_clearField(1);
}

class JobInfo extends $pb.GeneratedMessage {
  factory JobInfo({
    $core.String? jobId,
    $core.String? status,
  }) {
    final result = create();
    if (jobId != null) result.jobId = jobId;
    if (status != null) result.status = status;
    return result;
  }

  JobInfo._();

  factory JobInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JobInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JobInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jobId')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobInfo copyWith(void Function(JobInfo) updates) =>
      super.copyWith((message) => updates(message as JobInfo)) as JobInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JobInfo create() => JobInfo._();
  @$core.override
  JobInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JobInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JobInfo>(create);
  static JobInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jobId => $_getSZ(0);
  @$pb.TagNumber(1)
  set jobId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJobId() => $_has(0);
  @$pb.TagNumber(1)
  void clearJobId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class JobStatus extends $pb.GeneratedMessage {
  factory JobStatus({
    $core.String? jobId,
    $core.String? status,
    $core.int? progress,
    $core.String? error,
  }) {
    final result = create();
    if (jobId != null) result.jobId = jobId;
    if (status != null) result.status = status;
    if (progress != null) result.progress = progress;
    if (error != null) result.error = error;
    return result;
  }

  JobStatus._();

  factory JobStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JobStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JobStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jobId')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aI(3, _omitFieldNames ? '' : 'progress')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobStatus copyWith(void Function(JobStatus) updates) =>
      super.copyWith((message) => updates(message as JobStatus)) as JobStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JobStatus create() => JobStatus._();
  @$core.override
  JobStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JobStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JobStatus>(create);
  static JobStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jobId => $_getSZ(0);
  @$pb.TagNumber(1)
  set jobId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJobId() => $_has(0);
  @$pb.TagNumber(1)
  void clearJobId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get progress => $_getIZ(2);
  @$pb.TagNumber(3)
  set progress($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProgress() => $_has(2);
  @$pb.TagNumber(3)
  void clearProgress() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
}

class JobList extends $pb.GeneratedMessage {
  factory JobList({
    $core.Iterable<JobStatus>? jobs,
  }) {
    final result = create();
    if (jobs != null) result.jobs.addAll(jobs);
    return result;
  }

  JobList._();

  factory JobList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JobList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JobList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..pPM<JobStatus>(1, _omitFieldNames ? '' : 'jobs',
        subBuilder: JobStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JobList copyWith(void Function(JobList) updates) =>
      super.copyWith((message) => updates(message as JobList)) as JobList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JobList create() => JobList._();
  @$core.override
  JobList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JobList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JobList>(create);
  static JobList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<JobStatus> get jobs => $_getList(0);
}

class TrainingMetrics extends $pb.GeneratedMessage {
  factory TrainingMetrics({
    $core.int? epoch,
    $core.int? step,
    $core.double? loss,
    $core.double? learningRate,
    $core.int? progressPercent,
  }) {
    final result = create();
    if (epoch != null) result.epoch = epoch;
    if (step != null) result.step = step;
    if (loss != null) result.loss = loss;
    if (learningRate != null) result.learningRate = learningRate;
    if (progressPercent != null) result.progressPercent = progressPercent;
    return result;
  }

  TrainingMetrics._();

  factory TrainingMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrainingMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrainingMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'epoch')
    ..aI(2, _omitFieldNames ? '' : 'step')
    ..aD(3, _omitFieldNames ? '' : 'loss', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'learningRate',
        fieldType: $pb.PbFieldType.OF)
    ..aI(5, _omitFieldNames ? '' : 'progressPercent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrainingMetrics clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrainingMetrics copyWith(void Function(TrainingMetrics) updates) =>
      super.copyWith((message) => updates(message as TrainingMetrics))
          as TrainingMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrainingMetrics create() => TrainingMetrics._();
  @$core.override
  TrainingMetrics createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrainingMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrainingMetrics>(create);
  static TrainingMetrics? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get epoch => $_getIZ(0);
  @$pb.TagNumber(1)
  set epoch($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpoch() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpoch() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get step => $_getIZ(1);
  @$pb.TagNumber(2)
  set step($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStep() => $_has(1);
  @$pb.TagNumber(2)
  void clearStep() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get loss => $_getN(2);
  @$pb.TagNumber(3)
  set loss($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLoss() => $_has(2);
  @$pb.TagNumber(3)
  void clearLoss() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get learningRate => $_getN(3);
  @$pb.TagNumber(4)
  set learningRate($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLearningRate() => $_has(3);
  @$pb.TagNumber(4)
  void clearLearningRate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get progressPercent => $_getIZ(4);
  @$pb.TagNumber(5)
  set progressPercent($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProgressPercent() => $_has(4);
  @$pb.TagNumber(5)
  void clearProgressPercent() => $_clearField(5);
}

class QuantRequest extends $pb.GeneratedMessage {
  factory QuantRequest({
    $core.String? modelPath,
    $core.String? quantType,
    $core.String? outputPath,
  }) {
    final result = create();
    if (modelPath != null) result.modelPath = modelPath;
    if (quantType != null) result.quantType = quantType;
    if (outputPath != null) result.outputPath = outputPath;
    return result;
  }

  QuantRequest._();

  factory QuantRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QuantRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuantRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelPath')
    ..aOS(2, _omitFieldNames ? '' : 'quantType')
    ..aOS(3, _omitFieldNames ? '' : 'outputPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantRequest copyWith(void Function(QuantRequest) updates) =>
      super.copyWith((message) => updates(message as QuantRequest))
          as QuantRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuantRequest create() => QuantRequest._();
  @$core.override
  QuantRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QuantRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuantRequest>(create);
  static QuantRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get quantType => $_getSZ(1);
  @$pb.TagNumber(2)
  set quantType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuantType() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuantType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get outputPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set outputPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOutputPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputPath() => $_clearField(3);
}

class QuantTypes extends $pb.GeneratedMessage {
  factory QuantTypes({
    $core.Iterable<$core.String>? types,
  }) {
    final result = create();
    if (types != null) result.types.addAll(types);
    return result;
  }

  QuantTypes._();

  factory QuantTypes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QuantTypes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuantTypes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'types')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantTypes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantTypes copyWith(void Function(QuantTypes) updates) =>
      super.copyWith((message) => updates(message as QuantTypes)) as QuantTypes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuantTypes create() => QuantTypes._();
  @$core.override
  QuantTypes createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QuantTypes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuantTypes>(create);
  static QuantTypes? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get types => $_getList(0);
}

class QuantProgress extends $pb.GeneratedMessage {
  factory QuantProgress({
    $core.String? jobId,
    $core.int? progressPercent,
    $core.String? currentStep,
  }) {
    final result = create();
    if (jobId != null) result.jobId = jobId;
    if (progressPercent != null) result.progressPercent = progressPercent;
    if (currentStep != null) result.currentStep = currentStep;
    return result;
  }

  QuantProgress._();

  factory QuantProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QuantProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuantProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jobId')
    ..aI(2, _omitFieldNames ? '' : 'progressPercent')
    ..aOS(3, _omitFieldNames ? '' : 'currentStep')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuantProgress copyWith(void Function(QuantProgress) updates) =>
      super.copyWith((message) => updates(message as QuantProgress))
          as QuantProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuantProgress create() => QuantProgress._();
  @$core.override
  QuantProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QuantProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuantProgress>(create);
  static QuantProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jobId => $_getSZ(0);
  @$pb.TagNumber(1)
  set jobId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJobId() => $_has(0);
  @$pb.TagNumber(1)
  void clearJobId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get progressPercent => $_getIZ(1);
  @$pb.TagNumber(2)
  set progressPercent($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProgressPercent() => $_has(1);
  @$pb.TagNumber(2)
  void clearProgressPercent() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get currentStep => $_getSZ(2);
  @$pb.TagNumber(3)
  set currentStep($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrentStep() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentStep() => $_clearField(3);
}

class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    $core.String? query,
    $core.String? format,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (query != null) result.query = query;
    if (format != null) result.format = format;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  SearchRequest._();

  factory SearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..aI(4, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest copyWith(void Function(SearchRequest) updates) =>
      super.copyWith((message) => updates(message as SearchRequest))
          as SearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRequest create() => SearchRequest._();
  @$core.override
  SearchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRequest>(create);
  static SearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);
}

class SearchResponse extends $pb.GeneratedMessage {
  factory SearchResponse({
    $core.Iterable<ModelDetail>? models,
    $core.int? total,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    if (total != null) result.total = total;
    return result;
  }

  SearchResponse._();

  factory SearchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..pPM<ModelDetail>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelDetail.create)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse copyWith(void Function(SearchResponse) updates) =>
      super.copyWith((message) => updates(message as SearchResponse))
          as SearchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResponse create() => SearchResponse._();
  @$core.override
  SearchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchResponse>(create);
  static SearchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModelDetail> get models => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

class ModelDetailRequest extends $pb.GeneratedMessage {
  factory ModelDetailRequest({
    $core.String? modelId,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    return result;
  }

  ModelDetailRequest._();

  factory ModelDetailRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelDetailRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelDetailRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelDetailRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelDetailRequest copyWith(void Function(ModelDetailRequest) updates) =>
      super.copyWith((message) => updates(message as ModelDetailRequest))
          as ModelDetailRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelDetailRequest create() => ModelDetailRequest._();
  @$core.override
  ModelDetailRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelDetailRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelDetailRequest>(create);
  static ModelDetailRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);
}

class ModelDetail extends $pb.GeneratedMessage {
  factory ModelDetail({
    $core.String? id,
    $core.String? name,
    $core.String? description,
    $core.String? author,
    $core.Iterable<$core.String>? formats,
    $fixnum.Int64? sizeBytes,
    $fixnum.Int64? downloads,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (author != null) result.author = author;
    if (formats != null) result.formats.addAll(formats);
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (downloads != null) result.downloads = downloads;
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
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOS(4, _omitFieldNames ? '' : 'author')
    ..pPS(5, _omitFieldNames ? '' : 'formats')
    ..aInt64(6, _omitFieldNames ? '' : 'sizeBytes')
    ..aInt64(7, _omitFieldNames ? '' : 'downloads')
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
  $core.String get author => $_getSZ(3);
  @$pb.TagNumber(4)
  set author($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get formats => $_getList(4);

  @$pb.TagNumber(6)
  $fixnum.Int64 get sizeBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSizeBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearSizeBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get downloads => $_getI64(6);
  @$pb.TagNumber(7)
  set downloads($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDownloads() => $_has(6);
  @$pb.TagNumber(7)
  void clearDownloads() => $_clearField(7);
}

class DownloadRequest extends $pb.GeneratedMessage {
  factory DownloadRequest({
    $core.String? modelId,
    $core.String? format,
  }) {
    final result = create();
    if (modelId != null) result.modelId = modelId;
    if (format != null) result.format = format;
    return result;
  }

  DownloadRequest._();

  factory DownloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest copyWith(void Function(DownloadRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadRequest))
          as DownloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadRequest create() => DownloadRequest._();
  @$core.override
  DownloadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadRequest>(create);
  static DownloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);
}

class DownloadProgress extends $pb.GeneratedMessage {
  factory DownloadProgress({
    $core.String? jobId,
    $fixnum.Int64? bytesDownloaded,
    $fixnum.Int64? bytesTotal,
    $core.int? progressPercent,
    $core.String? status,
  }) {
    final result = create();
    if (jobId != null) result.jobId = jobId;
    if (bytesDownloaded != null) result.bytesDownloaded = bytesDownloaded;
    if (bytesTotal != null) result.bytesTotal = bytesTotal;
    if (progressPercent != null) result.progressPercent = progressPercent;
    if (status != null) result.status = status;
    return result;
  }

  DownloadProgress._();

  factory DownloadProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jobId')
    ..aInt64(2, _omitFieldNames ? '' : 'bytesDownloaded')
    ..aInt64(3, _omitFieldNames ? '' : 'bytesTotal')
    ..aI(4, _omitFieldNames ? '' : 'progressPercent')
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadProgress copyWith(void Function(DownloadProgress) updates) =>
      super.copyWith((message) => updates(message as DownloadProgress))
          as DownloadProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadProgress create() => DownloadProgress._();
  @$core.override
  DownloadProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadProgress>(create);
  static DownloadProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jobId => $_getSZ(0);
  @$pb.TagNumber(1)
  set jobId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJobId() => $_has(0);
  @$pb.TagNumber(1)
  void clearJobId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytesDownloaded => $_getI64(1);
  @$pb.TagNumber(2)
  set bytesDownloaded($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytesDownloaded() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytesDownloaded() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get bytesTotal => $_getI64(2);
  @$pb.TagNumber(3)
  set bytesTotal($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBytesTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearBytesTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get progressPercent => $_getIZ(3);
  @$pb.TagNumber(4)
  set progressPercent($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProgressPercent() => $_has(3);
  @$pb.TagNumber(4)
  void clearProgressPercent() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(4);
  @$pb.TagNumber(5)
  set status($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);
}

class ImportSkillRequest extends $pb.GeneratedMessage {
  factory ImportSkillRequest({
    $core.String? sourcePath,
    $core.bool? enabled,
  }) {
    final result = create();
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  ImportSkillRequest._();

  factory ImportSkillRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportSkillRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportSkillRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourcePath')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportSkillRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportSkillRequest copyWith(void Function(ImportSkillRequest) updates) =>
      super.copyWith((message) => updates(message as ImportSkillRequest))
          as ImportSkillRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportSkillRequest create() => ImportSkillRequest._();
  @$core.override
  ImportSkillRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportSkillRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportSkillRequest>(create);
  static ImportSkillRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourcePath => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourcePath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourcePath() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourcePath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class UpdateSkillRequest extends $pb.GeneratedMessage {
  factory UpdateSkillRequest({
    $core.String? name,
    $core.bool? enabled,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  UpdateSkillRequest._();

  factory UpdateSkillRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSkillRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSkillRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSkillRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSkillRequest copyWith(void Function(UpdateSkillRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateSkillRequest))
          as UpdateSkillRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSkillRequest create() => UpdateSkillRequest._();
  @$core.override
  UpdateSkillRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateSkillRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSkillRequest>(create);
  static UpdateSkillRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class DeleteSkillRequest extends $pb.GeneratedMessage {
  factory DeleteSkillRequest({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  DeleteSkillRequest._();

  factory DeleteSkillRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSkillRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSkillRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSkillRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSkillRequest copyWith(void Function(DeleteSkillRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSkillRequest))
          as DeleteSkillRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSkillRequest create() => DeleteSkillRequest._();
  @$core.override
  DeleteSkillRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteSkillRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSkillRequest>(create);
  static DeleteSkillRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class SkillListResponse extends $pb.GeneratedMessage {
  factory SkillListResponse({
    $core.Iterable<SkillRecord>? skills,
    $core.int? count,
  }) {
    final result = create();
    if (skills != null) result.skills.addAll(skills);
    if (count != null) result.count = count;
    return result;
  }

  SkillListResponse._();

  factory SkillListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkillListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkillListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..pPM<SkillRecord>(1, _omitFieldNames ? '' : 'skills',
        subBuilder: SkillRecord.create)
    ..aI(2, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillListResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillListResponse copyWith(void Function(SkillListResponse) updates) =>
      super.copyWith((message) => updates(message as SkillListResponse))
          as SkillListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkillListResponse create() => SkillListResponse._();
  @$core.override
  SkillListResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkillListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkillListResponse>(create);
  static SkillListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SkillRecord> get skills => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

class SkillResponse extends $pb.GeneratedMessage {
  factory SkillResponse({
    SkillRecord? skill,
    $core.String? message,
  }) {
    final result = create();
    if (skill != null) result.skill = skill;
    if (message != null) result.message = message;
    return result;
  }

  SkillResponse._();

  factory SkillResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkillResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkillResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOM<SkillRecord>(1, _omitFieldNames ? '' : 'skill',
        subBuilder: SkillRecord.create)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillResponse copyWith(void Function(SkillResponse) updates) =>
      super.copyWith((message) => updates(message as SkillResponse))
          as SkillResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkillResponse create() => SkillResponse._();
  @$core.override
  SkillResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkillResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkillResponse>(create);
  static SkillResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SkillRecord get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(SkillRecord value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => $_clearField(1);
  @$pb.TagNumber(1)
  SkillRecord ensureSkill() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class DeleteSkillResponse extends $pb.GeneratedMessage {
  factory DeleteSkillResponse({
    $core.String? name,
    $core.String? status,
    $core.String? message,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (status != null) result.status = status;
    if (message != null) result.message = message;
    return result;
  }

  DeleteSkillResponse._();

  factory DeleteSkillResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSkillResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSkillResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSkillResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSkillResponse copyWith(void Function(DeleteSkillResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteSkillResponse))
          as DeleteSkillResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSkillResponse create() => DeleteSkillResponse._();
  @$core.override
  DeleteSkillResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteSkillResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSkillResponse>(create);
  static DeleteSkillResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class SkillRecord extends $pb.GeneratedMessage {
  factory SkillRecord({
    $core.String? name,
    $core.String? description,
    $core.bool? enabled,
    $core.String? path,
    $fixnum.Int64? importedAtUnix,
    $fixnum.Int64? updatedAtUnix,
    $core.String? license,
    $core.String? compatibility,
    $core.String? metadataJson,
    $core.String? allowedTools,
    $core.bool? valid,
    $core.Iterable<$core.String>? errors,
    SkillFileSummary? fileSummary,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (enabled != null) result.enabled = enabled;
    if (path != null) result.path = path;
    if (importedAtUnix != null) result.importedAtUnix = importedAtUnix;
    if (updatedAtUnix != null) result.updatedAtUnix = updatedAtUnix;
    if (license != null) result.license = license;
    if (compatibility != null) result.compatibility = compatibility;
    if (metadataJson != null) result.metadataJson = metadataJson;
    if (allowedTools != null) result.allowedTools = allowedTools;
    if (valid != null) result.valid = valid;
    if (errors != null) result.errors.addAll(errors);
    if (fileSummary != null) result.fileSummary = fileSummary;
    return result;
  }

  SkillRecord._();

  factory SkillRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkillRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkillRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..aOS(4, _omitFieldNames ? '' : 'path')
    ..aInt64(5, _omitFieldNames ? '' : 'importedAtUnix')
    ..aInt64(6, _omitFieldNames ? '' : 'updatedAtUnix')
    ..aOS(7, _omitFieldNames ? '' : 'license')
    ..aOS(8, _omitFieldNames ? '' : 'compatibility')
    ..aOS(9, _omitFieldNames ? '' : 'metadataJson')
    ..aOS(10, _omitFieldNames ? '' : 'allowedTools')
    ..aOB(11, _omitFieldNames ? '' : 'valid')
    ..pPS(12, _omitFieldNames ? '' : 'errors')
    ..aOM<SkillFileSummary>(13, _omitFieldNames ? '' : 'fileSummary',
        subBuilder: SkillFileSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillRecord copyWith(void Function(SkillRecord) updates) =>
      super.copyWith((message) => updates(message as SkillRecord))
          as SkillRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkillRecord create() => SkillRecord._();
  @$core.override
  SkillRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkillRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkillRecord>(create);
  static SkillRecord? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get importedAtUnix => $_getI64(4);
  @$pb.TagNumber(5)
  set importedAtUnix($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasImportedAtUnix() => $_has(4);
  @$pb.TagNumber(5)
  void clearImportedAtUnix() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get updatedAtUnix => $_getI64(5);
  @$pb.TagNumber(6)
  set updatedAtUnix($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdatedAtUnix() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdatedAtUnix() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get license => $_getSZ(6);
  @$pb.TagNumber(7)
  set license($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLicense() => $_has(6);
  @$pb.TagNumber(7)
  void clearLicense() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get compatibility => $_getSZ(7);
  @$pb.TagNumber(8)
  set compatibility($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCompatibility() => $_has(7);
  @$pb.TagNumber(8)
  void clearCompatibility() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get metadataJson => $_getSZ(8);
  @$pb.TagNumber(9)
  set metadataJson($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMetadataJson() => $_has(8);
  @$pb.TagNumber(9)
  void clearMetadataJson() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get allowedTools => $_getSZ(9);
  @$pb.TagNumber(10)
  set allowedTools($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAllowedTools() => $_has(9);
  @$pb.TagNumber(10)
  void clearAllowedTools() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get valid => $_getBF(10);
  @$pb.TagNumber(11)
  set valid($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasValid() => $_has(10);
  @$pb.TagNumber(11)
  void clearValid() => $_clearField(11);

  @$pb.TagNumber(12)
  $pb.PbList<$core.String> get errors => $_getList(11);

  @$pb.TagNumber(13)
  SkillFileSummary get fileSummary => $_getN(12);
  @$pb.TagNumber(13)
  set fileSummary(SkillFileSummary value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasFileSummary() => $_has(12);
  @$pb.TagNumber(13)
  void clearFileSummary() => $_clearField(13);
  @$pb.TagNumber(13)
  SkillFileSummary ensureFileSummary() => $_ensure(12);
}

class SkillFileSummary extends $pb.GeneratedMessage {
  factory SkillFileSummary({
    $core.int? fileCount,
    $core.int? directoryCount,
    $core.bool? hasScripts,
    $core.bool? hasReferences,
    $core.bool? hasAssets,
  }) {
    final result = create();
    if (fileCount != null) result.fileCount = fileCount;
    if (directoryCount != null) result.directoryCount = directoryCount;
    if (hasScripts != null) result.hasScripts = hasScripts;
    if (hasReferences != null) result.hasReferences = hasReferences;
    if (hasAssets != null) result.hasAssets = hasAssets;
    return result;
  }

  SkillFileSummary._();

  factory SkillFileSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkillFileSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkillFileSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'fileCount')
    ..aI(2, _omitFieldNames ? '' : 'directoryCount')
    ..aOB(3, _omitFieldNames ? '' : 'hasScripts')
    ..aOB(4, _omitFieldNames ? '' : 'hasReferences')
    ..aOB(5, _omitFieldNames ? '' : 'hasAssets')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillFileSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillFileSummary copyWith(void Function(SkillFileSummary) updates) =>
      super.copyWith((message) => updates(message as SkillFileSummary))
          as SkillFileSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkillFileSummary create() => SkillFileSummary._();
  @$core.override
  SkillFileSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkillFileSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkillFileSummary>(create);
  static SkillFileSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fileCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set fileCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get directoryCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set directoryCount($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDirectoryCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirectoryCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get hasScripts => $_getBF(2);
  @$pb.TagNumber(3)
  set hasScripts($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasScripts() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasScripts() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get hasReferences => $_getBF(3);
  @$pb.TagNumber(4)
  set hasReferences($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHasReferences() => $_has(3);
  @$pb.TagNumber(4)
  void clearHasReferences() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get hasAssets => $_getBF(4);
  @$pb.TagNumber(5)
  set hasAssets($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHasAssets() => $_has(4);
  @$pb.TagNumber(5)
  void clearHasAssets() => $_clearField(5);
}

class Empty extends $pb.GeneratedMessage {
  factory Empty() => create();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Empty create() => Empty._();
  @$core.override
  Empty createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Empty>(create);
  static Empty? _defaultInstance;
}

class AgenticRequest extends $pb.GeneratedMessage {
  factory AgenticRequest({
    $core.String? sessionId,
    $core.String? userMessage,
    $core.String? thinkingLevel,
    $core.String? mode,
    $core.Iterable<$core.String>? allowedRoots,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? context,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (userMessage != null) result.userMessage = userMessage;
    if (thinkingLevel != null) result.thinkingLevel = thinkingLevel;
    if (mode != null) result.mode = mode;
    if (allowedRoots != null) result.allowedRoots.addAll(allowedRoots);
    if (context != null) result.context.addEntries(context);
    return result;
  }

  AgenticRequest._();

  factory AgenticRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AgenticRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgenticRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'userMessage')
    ..aOS(3, _omitFieldNames ? '' : 'thinkingLevel')
    ..aOS(4, _omitFieldNames ? '' : 'mode')
    ..pPS(5, _omitFieldNames ? '' : 'allowedRoots')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'context',
        entryClassName: 'AgenticRequest.ContextEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fillyengine'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgenticRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgenticRequest copyWith(void Function(AgenticRequest) updates) =>
      super.copyWith((message) => updates(message as AgenticRequest))
          as AgenticRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgenticRequest create() => AgenticRequest._();
  @$core.override
  AgenticRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AgenticRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgenticRequest>(create);
  static AgenticRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set userMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get thinkingLevel => $_getSZ(2);
  @$pb.TagNumber(3)
  set thinkingLevel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThinkingLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearThinkingLevel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mode => $_getSZ(3);
  @$pb.TagNumber(4)
  set mode($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearMode() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get allowedRoots => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.String> get context => $_getMap(5);
}

class AgenticResponse extends $pb.GeneratedMessage {
  factory AgenticResponse({
    AgenticResponse_Type? type,
    $core.String? text,
    ToolCall? toolCall,
    PlanningState? planning,
    CompressionEvent? compression,
    $core.String? error,
    $core.bool? done,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (text != null) result.text = text;
    if (toolCall != null) result.toolCall = toolCall;
    if (planning != null) result.planning = planning;
    if (compression != null) result.compression = compression;
    if (error != null) result.error = error;
    if (done != null) result.done = done;
    return result;
  }

  AgenticResponse._();

  factory AgenticResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AgenticResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgenticResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aE<AgenticResponse_Type>(1, _omitFieldNames ? '' : 'type',
        enumValues: AgenticResponse_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOM<ToolCall>(3, _omitFieldNames ? '' : 'toolCall',
        subBuilder: ToolCall.create)
    ..aOM<PlanningState>(4, _omitFieldNames ? '' : 'planning',
        subBuilder: PlanningState.create)
    ..aOM<CompressionEvent>(5, _omitFieldNames ? '' : 'compression',
        subBuilder: CompressionEvent.create)
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..aOB(7, _omitFieldNames ? '' : 'done')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgenticResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgenticResponse copyWith(void Function(AgenticResponse) updates) =>
      super.copyWith((message) => updates(message as AgenticResponse))
          as AgenticResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgenticResponse create() => AgenticResponse._();
  @$core.override
  AgenticResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AgenticResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgenticResponse>(create);
  static AgenticResponse? _defaultInstance;

  @$pb.TagNumber(1)
  AgenticResponse_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(AgenticResponse_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  ToolCall get toolCall => $_getN(2);
  @$pb.TagNumber(3)
  set toolCall(ToolCall value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasToolCall() => $_has(2);
  @$pb.TagNumber(3)
  void clearToolCall() => $_clearField(3);
  @$pb.TagNumber(3)
  ToolCall ensureToolCall() => $_ensure(2);

  @$pb.TagNumber(4)
  PlanningState get planning => $_getN(3);
  @$pb.TagNumber(4)
  set planning(PlanningState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPlanning() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlanning() => $_clearField(4);
  @$pb.TagNumber(4)
  PlanningState ensurePlanning() => $_ensure(3);

  @$pb.TagNumber(5)
  CompressionEvent get compression => $_getN(4);
  @$pb.TagNumber(5)
  set compression(CompressionEvent value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCompression() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompression() => $_clearField(5);
  @$pb.TagNumber(5)
  CompressionEvent ensureCompression() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get done => $_getBF(6);
  @$pb.TagNumber(7)
  set done($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDone() => $_has(6);
  @$pb.TagNumber(7)
  void clearDone() => $_clearField(7);
}

class ToolCall extends $pb.GeneratedMessage {
  factory ToolCall({
    $core.String? id,
    $core.String? name,
    $core.String? arguments,
    $core.String? resultPreview,
    $core.bool? success,
    $core.String? error,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (arguments != null) result.arguments = arguments;
    if (resultPreview != null) result.resultPreview = resultPreview;
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  ToolCall._();

  factory ToolCall.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ToolCall.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolCall',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'arguments')
    ..aOS(4, _omitFieldNames ? '' : 'resultPreview')
    ..aOB(5, _omitFieldNames ? '' : 'success')
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolCall clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolCall copyWith(void Function(ToolCall) updates) =>
      super.copyWith((message) => updates(message as ToolCall)) as ToolCall;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ToolCall create() => ToolCall._();
  @$core.override
  ToolCall createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ToolCall getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ToolCall>(create);
  static ToolCall? _defaultInstance;

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
  $core.String get arguments => $_getSZ(2);
  @$pb.TagNumber(3)
  set arguments($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasArguments() => $_has(2);
  @$pb.TagNumber(3)
  void clearArguments() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get resultPreview => $_getSZ(3);
  @$pb.TagNumber(4)
  set resultPreview($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasResultPreview() => $_has(3);
  @$pb.TagNumber(4)
  void clearResultPreview() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get success => $_getBF(4);
  @$pb.TagNumber(5)
  set success($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSuccess() => $_has(4);
  @$pb.TagNumber(5)
  void clearSuccess() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);
}

class PlanningState extends $pb.GeneratedMessage {
  factory PlanningState({
    $core.String? status,
    $core.Iterable<PlanningQuestion>? questions,
    $core.String? planSummary,
    $core.Iterable<$core.String>? steps,
    $core.Iterable<$core.String>? risks,
    $core.Iterable<$core.String>? tests,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (questions != null) result.questions.addAll(questions);
    if (planSummary != null) result.planSummary = planSummary;
    if (steps != null) result.steps.addAll(steps);
    if (risks != null) result.risks.addAll(risks);
    if (tests != null) result.tests.addAll(tests);
    return result;
  }

  PlanningState._();

  factory PlanningState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlanningState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlanningState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..pPM<PlanningQuestion>(2, _omitFieldNames ? '' : 'questions',
        subBuilder: PlanningQuestion.create)
    ..aOS(3, _omitFieldNames ? '' : 'planSummary')
    ..pPS(4, _omitFieldNames ? '' : 'steps')
    ..pPS(5, _omitFieldNames ? '' : 'risks')
    ..pPS(6, _omitFieldNames ? '' : 'tests')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanningState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanningState copyWith(void Function(PlanningState) updates) =>
      super.copyWith((message) => updates(message as PlanningState))
          as PlanningState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlanningState create() => PlanningState._();
  @$core.override
  PlanningState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlanningState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlanningState>(create);
  static PlanningState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<PlanningQuestion> get questions => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get planSummary => $_getSZ(2);
  @$pb.TagNumber(3)
  set planSummary($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlanSummary() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlanSummary() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get steps => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get risks => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get tests => $_getList(5);
}

class PlanningQuestion extends $pb.GeneratedMessage {
  factory PlanningQuestion({
    $core.String? id,
    $core.String? prompt,
    $core.Iterable<PlanningOption>? options,
    $core.bool? allowCustom,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (prompt != null) result.prompt = prompt;
    if (options != null) result.options.addAll(options);
    if (allowCustom != null) result.allowCustom = allowCustom;
    return result;
  }

  PlanningQuestion._();

  factory PlanningQuestion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlanningQuestion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlanningQuestion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'prompt')
    ..pPM<PlanningOption>(3, _omitFieldNames ? '' : 'options',
        subBuilder: PlanningOption.create)
    ..aOB(4, _omitFieldNames ? '' : 'allowCustom')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanningQuestion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanningQuestion copyWith(void Function(PlanningQuestion) updates) =>
      super.copyWith((message) => updates(message as PlanningQuestion))
          as PlanningQuestion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlanningQuestion create() => PlanningQuestion._();
  @$core.override
  PlanningQuestion createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlanningQuestion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlanningQuestion>(create);
  static PlanningQuestion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get prompt => $_getSZ(1);
  @$pb.TagNumber(2)
  set prompt($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrompt() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrompt() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<PlanningOption> get options => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get allowCustom => $_getBF(3);
  @$pb.TagNumber(4)
  set allowCustom($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAllowCustom() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowCustom() => $_clearField(4);
}

class PlanningOption extends $pb.GeneratedMessage {
  factory PlanningOption({
    $core.String? id,
    $core.String? label,
    $core.String? description,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (description != null) result.description = description;
    return result;
  }

  PlanningOption._();

  factory PlanningOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlanningOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlanningOption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanningOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanningOption copyWith(void Function(PlanningOption) updates) =>
      super.copyWith((message) => updates(message as PlanningOption))
          as PlanningOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlanningOption create() => PlanningOption._();
  @$core.override
  PlanningOption createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlanningOption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlanningOption>(create);
  static PlanningOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);
}

class ToolList extends $pb.GeneratedMessage {
  factory ToolList({
    $core.Iterable<ToolDef>? tools,
  }) {
    final result = create();
    if (tools != null) result.tools.addAll(tools);
    return result;
  }

  ToolList._();

  factory ToolList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ToolList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..pPM<ToolDef>(1, _omitFieldNames ? '' : 'tools',
        subBuilder: ToolDef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolList copyWith(void Function(ToolList) updates) =>
      super.copyWith((message) => updates(message as ToolList)) as ToolList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ToolList create() => ToolList._();
  @$core.override
  ToolList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ToolList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ToolList>(create);
  static ToolList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ToolDef> get tools => $_getList(0);
}

class ToolDef extends $pb.GeneratedMessage {
  factory ToolDef({
    $core.String? name,
    $core.String? description,
    $core.String? parametersJsonSchema,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (parametersJsonSchema != null)
      result.parametersJsonSchema = parametersJsonSchema;
    return result;
  }

  ToolDef._();

  factory ToolDef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ToolDef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolDef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'parametersJsonSchema')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolDef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolDef copyWith(void Function(ToolDef) updates) =>
      super.copyWith((message) => updates(message as ToolDef)) as ToolDef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ToolDef create() => ToolDef._();
  @$core.override
  ToolDef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ToolDef getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ToolDef>(create);
  static ToolDef? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.String get parametersJsonSchema => $_getSZ(2);
  @$pb.TagNumber(3)
  set parametersJsonSchema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasParametersJsonSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearParametersJsonSchema() => $_clearField(3);
}

class CompressionEvent extends $pb.GeneratedMessage {
  factory CompressionEvent({
    $core.bool? triggered,
    $core.double? usageBefore,
    $core.double? usageAfter,
    $core.int? compressedMessages,
    $core.String? memoryId,
  }) {
    final result = create();
    if (triggered != null) result.triggered = triggered;
    if (usageBefore != null) result.usageBefore = usageBefore;
    if (usageAfter != null) result.usageAfter = usageAfter;
    if (compressedMessages != null)
      result.compressedMessages = compressedMessages;
    if (memoryId != null) result.memoryId = memoryId;
    return result;
  }

  CompressionEvent._();

  factory CompressionEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompressionEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompressionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fillyengine'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'triggered')
    ..aD(2, _omitFieldNames ? '' : 'usageBefore', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'usageAfter', fieldType: $pb.PbFieldType.OF)
    ..aI(4, _omitFieldNames ? '' : 'compressedMessages')
    ..aOS(5, _omitFieldNames ? '' : 'memoryId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompressionEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompressionEvent copyWith(void Function(CompressionEvent) updates) =>
      super.copyWith((message) => updates(message as CompressionEvent))
          as CompressionEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompressionEvent create() => CompressionEvent._();
  @$core.override
  CompressionEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompressionEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompressionEvent>(create);
  static CompressionEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get triggered => $_getBF(0);
  @$pb.TagNumber(1)
  set triggered($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTriggered() => $_has(0);
  @$pb.TagNumber(1)
  void clearTriggered() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get usageBefore => $_getN(1);
  @$pb.TagNumber(2)
  set usageBefore($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsageBefore() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsageBefore() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get usageAfter => $_getN(2);
  @$pb.TagNumber(3)
  set usageAfter($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsageAfter() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsageAfter() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get compressedMessages => $_getIZ(3);
  @$pb.TagNumber(4)
  set compressedMessages($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCompressedMessages() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompressedMessages() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get memoryId => $_getSZ(4);
  @$pb.TagNumber(5)
  set memoryId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMemoryId() => $_has(4);
  @$pb.TagNumber(5)
  void clearMemoryId() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
