// This is a generated file - do not edit.
//
// Generated from culpeostudio/scout/v1/scout.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart' as $2;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// ChatMessage is one turn of a conversation.
class ChatMessage extends $pb.GeneratedMessage {
  factory ChatMessage({
    $core.String? role,
    $core.String? content,
    $core.String? botId,
    $core.String? botName,
  }) {
    final result = create();
    if (role != null) result.role = role;
    if (content != null) result.content = content;
    if (botId != null) result.botId = botId;
    if (botName != null) result.botName = botName;
    return result;
  }

  ChatMessage._();

  factory ChatMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChatMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatMessage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'role')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..aOS(3, _omitFieldNames ? '' : 'botId')
    ..aOS(4, _omitFieldNames ? '' : 'botName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMessage copyWith(void Function(ChatMessage) updates) =>
      super.copyWith((message) => updates(message as ChatMessage))
          as ChatMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatMessage create() => ChatMessage._();
  @$core.override
  ChatMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChatMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatMessage>(create);
  static ChatMessage? _defaultInstance;

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
  $core.String get botId => $_getSZ(2);
  @$pb.TagNumber(3)
  set botId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBotId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBotId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get botName => $_getSZ(3);
  @$pb.TagNumber(4)
  set botName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBotName() => $_has(3);
  @$pb.TagNumber(4)
  void clearBotName() => $_clearField(4);
}

/// ModelBinding pins a bot to one model, either a hosted one or a local
/// instance the engine runs.
class ModelBinding extends $pb.GeneratedMessage {
  factory ModelBinding({
    $core.String? kind,
    $core.String? modelRef,
    $core.String? provider,
    $core.String? modelId,
    $core.String? instanceId,
    $core.String? displayName,
    $core.String? connectionId,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (modelRef != null) result.modelRef = modelRef;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (instanceId != null) result.instanceId = instanceId;
    if (displayName != null) result.displayName = displayName;
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  ModelBinding._();

  factory ModelBinding.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelBinding.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelBinding',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'modelRef')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'modelId')
    ..aOS(5, _omitFieldNames ? '' : 'instanceId')
    ..aOS(6, _omitFieldNames ? '' : 'displayName')
    ..aOS(7, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelBinding clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelBinding copyWith(void Function(ModelBinding) updates) =>
      super.copyWith((message) => updates(message as ModelBinding))
          as ModelBinding;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelBinding create() => ModelBinding._();
  @$core.override
  ModelBinding createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelBinding getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelBinding>(create);
  static ModelBinding? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelRef => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelRef($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelRef() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get modelId => $_getSZ(3);
  @$pb.TagNumber(4)
  set modelId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelId() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get instanceId => $_getSZ(4);
  @$pb.TagNumber(5)
  set instanceId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInstanceId() => $_has(4);
  @$pb.TagNumber(5)
  void clearInstanceId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get displayName => $_getSZ(5);
  @$pb.TagNumber(6)
  set displayName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDisplayName() => $_has(5);
  @$pb.TagNumber(6)
  void clearDisplayName() => $_clearField(6);

  /// User-owned provider connection used for a dynamically discovered API
  /// model. Empty keeps the legacy Marketplace provider binding.
  @$pb.TagNumber(7)
  $core.String get connectionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set connectionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConnectionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearConnectionId() => $_clearField(7);
}

/// Bot is one configured assistant: its prompt, when it is picked, and what it
/// is allowed to reach.
class Bot extends $pb.GeneratedMessage {
  factory Bot({
    $core.String? id,
    $core.String? name,
    $core.String? systemPrompt,
    $core.Iterable<$core.String>? keywords,
    $core.String? responseStyle,
    $core.bool? agenticEnabled,
    $core.Iterable<$core.String>? allowedRoots,
    $core.bool? isDefault,
    ModelBinding? modelBinding,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (systemPrompt != null) result.systemPrompt = systemPrompt;
    if (keywords != null) result.keywords.addAll(keywords);
    if (responseStyle != null) result.responseStyle = responseStyle;
    if (agenticEnabled != null) result.agenticEnabled = agenticEnabled;
    if (allowedRoots != null) result.allowedRoots.addAll(allowedRoots);
    if (isDefault != null) result.isDefault = isDefault;
    if (modelBinding != null) result.modelBinding = modelBinding;
    return result;
  }

  Bot._();

  factory Bot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Bot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Bot',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'systemPrompt')
    ..pPS(4, _omitFieldNames ? '' : 'keywords')
    ..aOS(5, _omitFieldNames ? '' : 'responseStyle')
    ..aOB(6, _omitFieldNames ? '' : 'agenticEnabled')
    ..pPS(7, _omitFieldNames ? '' : 'allowedRoots')
    ..aOB(8, _omitFieldNames ? '' : 'isDefault')
    ..aOM<ModelBinding>(9, _omitFieldNames ? '' : 'modelBinding',
        subBuilder: ModelBinding.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Bot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Bot copyWith(void Function(Bot) updates) =>
      super.copyWith((message) => updates(message as Bot)) as Bot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Bot create() => Bot._();
  @$core.override
  Bot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Bot getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Bot>(create);
  static Bot? _defaultInstance;

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
  $core.String get systemPrompt => $_getSZ(2);
  @$pb.TagNumber(3)
  set systemPrompt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSystemPrompt() => $_has(2);
  @$pb.TagNumber(3)
  void clearSystemPrompt() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get keywords => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get responseStyle => $_getSZ(4);
  @$pb.TagNumber(5)
  set responseStyle($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasResponseStyle() => $_has(4);
  @$pb.TagNumber(5)
  void clearResponseStyle() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get agenticEnabled => $_getBF(5);
  @$pb.TagNumber(6)
  set agenticEnabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAgenticEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearAgenticEnabled() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get allowedRoots => $_getList(6);

  @$pb.TagNumber(8)
  $core.bool get isDefault => $_getBF(7);
  @$pb.TagNumber(8)
  set isDefault($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsDefault() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsDefault() => $_clearField(8);

  /// Absent when the bot answers with whatever model the session selected.
  @$pb.TagNumber(9)
  ModelBinding get modelBinding => $_getN(8);
  @$pb.TagNumber(9)
  set modelBinding(ModelBinding value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasModelBinding() => $_has(8);
  @$pb.TagNumber(9)
  void clearModelBinding() => $_clearField(9);
  @$pb.TagNumber(9)
  ModelBinding ensureModelBinding() => $_ensure(8);
}

class SessionSummary extends $pb.GeneratedMessage {
  factory SessionSummary({
    $core.String? sessionId,
    $core.String? title,
    $core.String? preview,
    $core.String? provider,
    $core.String? modelId,
    $core.String? displayName,
    $core.String? lockedBotId,
    $core.String? projectId,
    $core.int? messageCount,
    $1.Timestamp? updatedAt,
    $core.String? connectionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (title != null) result.title = title;
    if (preview != null) result.preview = preview;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (displayName != null) result.displayName = displayName;
    if (lockedBotId != null) result.lockedBotId = lockedBotId;
    if (projectId != null) result.projectId = projectId;
    if (messageCount != null) result.messageCount = messageCount;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  SessionSummary._();

  factory SessionSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionSummary',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'preview')
    ..aOS(4, _omitFieldNames ? '' : 'provider')
    ..aOS(5, _omitFieldNames ? '' : 'modelId')
    ..aOS(6, _omitFieldNames ? '' : 'displayName')
    ..aOS(7, _omitFieldNames ? '' : 'lockedBotId')
    ..aOS(8, _omitFieldNames ? '' : 'projectId')
    ..aI(9, _omitFieldNames ? '' : 'messageCount')
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.create)
    ..aOS(11, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionSummary copyWith(void Function(SessionSummary) updates) =>
      super.copyWith((message) => updates(message as SessionSummary))
          as SessionSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionSummary create() => SessionSummary._();
  @$core.override
  SessionSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SessionSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionSummary>(create);
  static SessionSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get preview => $_getSZ(2);
  @$pb.TagNumber(3)
  set preview($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPreview() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreview() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get provider => $_getSZ(3);
  @$pb.TagNumber(4)
  set provider($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProvider() => $_has(3);
  @$pb.TagNumber(4)
  void clearProvider() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get modelId => $_getSZ(4);
  @$pb.TagNumber(5)
  set modelId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModelId() => $_has(4);
  @$pb.TagNumber(5)
  void clearModelId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get displayName => $_getSZ(5);
  @$pb.TagNumber(6)
  set displayName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDisplayName() => $_has(5);
  @$pb.TagNumber(6)
  void clearDisplayName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get lockedBotId => $_getSZ(6);
  @$pb.TagNumber(7)
  set lockedBotId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLockedBotId() => $_has(6);
  @$pb.TagNumber(7)
  void clearLockedBotId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get projectId => $_getSZ(7);
  @$pb.TagNumber(8)
  set projectId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProjectId() => $_has(7);
  @$pb.TagNumber(8)
  void clearProjectId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get messageCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set messageCount($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMessageCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearMessageCount() => $_clearField(9);

  @$pb.TagNumber(10)
  $1.Timestamp get updatedAt => $_getN(9);
  @$pb.TagNumber(10)
  set updatedAt($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensureUpdatedAt() => $_ensure(9);

  @$pb.TagNumber(11)
  $core.String get connectionId => $_getSZ(10);
  @$pb.TagNumber(11)
  set connectionId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasConnectionId() => $_has(10);
  @$pb.TagNumber(11)
  void clearConnectionId() => $_clearField(11);
}

/// FileNode is one entry of the project folder listing. The HTTP API handed this
/// out as an untyped tree; the shape was always this.
class FileNode extends $pb.GeneratedMessage {
  factory FileNode({
    $core.String? name,
    $core.String? path,
    $core.bool? isDir,
    $core.Iterable<FileNode>? children,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (path != null) result.path = path;
    if (isDir != null) result.isDir = isDir;
    if (children != null) result.children.addAll(children);
    return result;
  }

  FileNode._();

  factory FileNode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileNode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileNode',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOB(3, _omitFieldNames ? '' : 'isDir')
    ..pPM<FileNode>(4, _omitFieldNames ? '' : 'children',
        subBuilder: FileNode.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileNode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileNode copyWith(void Function(FileNode) updates) =>
      super.copyWith((message) => updates(message as FileNode)) as FileNode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileNode create() => FileNode._();
  @$core.override
  FileNode createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileNode getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileNode>(create);
  static FileNode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Relative to the project root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isDir => $_getBF(2);
  @$pb.TagNumber(3)
  set isDir($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsDir() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsDir() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<FileNode> get children => $_getList(3);
}

/// ChatOptions are the knobs a turn is answered with. They travel with each
/// message rather than being stored, because the UI lets them change per turn.
class ChatOptions extends $pb.GeneratedMessage {
  factory ChatOptions({
    $core.String? thinkingLevel,
    $core.String? responseStyle,
    $core.int? editMessageIndex,
    $core.String? mode,
    $core.Iterable<$core.String>? allowedRoots,
    $core.bool? approvePlan,
    $core.bool? planning,
    $core.String? reasoningEffort,
    $core.String? outputLevel,
  }) {
    final result = create();
    if (thinkingLevel != null) result.thinkingLevel = thinkingLevel;
    if (responseStyle != null) result.responseStyle = responseStyle;
    if (editMessageIndex != null) result.editMessageIndex = editMessageIndex;
    if (mode != null) result.mode = mode;
    if (allowedRoots != null) result.allowedRoots.addAll(allowedRoots);
    if (approvePlan != null) result.approvePlan = approvePlan;
    if (planning != null) result.planning = planning;
    if (reasoningEffort != null) result.reasoningEffort = reasoningEffort;
    if (outputLevel != null) result.outputLevel = outputLevel;
    return result;
  }

  ChatOptions._();

  factory ChatOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChatOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatOptions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'thinkingLevel')
    ..aOS(2, _omitFieldNames ? '' : 'responseStyle')
    ..aI(3, _omitFieldNames ? '' : 'editMessageIndex')
    ..aOS(4, _omitFieldNames ? '' : 'mode')
    ..pPS(5, _omitFieldNames ? '' : 'allowedRoots')
    ..aOB(6, _omitFieldNames ? '' : 'approvePlan')
    ..aOB(7, _omitFieldNames ? '' : 'planning')
    ..aOS(8, _omitFieldNames ? '' : 'reasoningEffort')
    ..aOS(9, _omitFieldNames ? '' : 'outputLevel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatOptions copyWith(void Function(ChatOptions) updates) =>
      super.copyWith((message) => updates(message as ChatOptions))
          as ChatOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatOptions create() => ChatOptions._();
  @$core.override
  ChatOptions createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChatOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatOptions>(create);
  static ChatOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get thinkingLevel => $_getSZ(0);
  @$pb.TagNumber(1)
  set thinkingLevel($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasThinkingLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearThinkingLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get responseStyle => $_getSZ(1);
  @$pb.TagNumber(2)
  set responseStyle($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResponseStyle() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseStyle() => $_clearField(2);

  /// Rewrites the conversation from this message on. Absent means append.
  @$pb.TagNumber(3)
  $core.int get editMessageIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set editMessageIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEditMessageIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearEditMessageIndex() => $_clearField(3);

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
  $core.bool get approvePlan => $_getBF(5);
  @$pb.TagNumber(6)
  set approvePlan($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasApprovePlan() => $_has(5);
  @$pb.TagNumber(6)
  void clearApprovePlan() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get planning => $_getBF(6);
  @$pb.TagNumber(7)
  set planning($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPlanning() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlanning() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get reasoningEffort => $_getSZ(7);
  @$pb.TagNumber(8)
  set reasoningEffort($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReasoningEffort() => $_has(7);
  @$pb.TagNumber(8)
  void clearReasoningEffort() => $_clearField(8);

  /// How long the answer may get: "short", "normal" or "max". Empty means
  /// normal. "max" resolves to whatever the model itself will write, capped by
  /// what is left of its context window.
  @$pb.TagNumber(9)
  $core.String get outputLevel => $_getSZ(8);
  @$pb.TagNumber(9)
  set outputLevel($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOutputLevel() => $_has(8);
  @$pb.TagNumber(9)
  void clearOutputLevel() => $_clearField(9);
}

class CreateSessionRequest extends $pb.GeneratedMessage {
  factory CreateSessionRequest({
    $core.String? modelRef,
    $core.String? provider,
    $core.String? modelId,
    $core.String? instanceId,
    $core.String? botId,
    $core.String? thinkingLevel,
    $core.String? responseStyle,
    $core.String? projectId,
    $core.String? connectionId,
  }) {
    final result = create();
    if (modelRef != null) result.modelRef = modelRef;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (instanceId != null) result.instanceId = instanceId;
    if (botId != null) result.botId = botId;
    if (thinkingLevel != null) result.thinkingLevel = thinkingLevel;
    if (responseStyle != null) result.responseStyle = responseStyle;
    if (projectId != null) result.projectId = projectId;
    if (connectionId != null) result.connectionId = connectionId;
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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelRef')
    ..aOS(2, _omitFieldNames ? '' : 'provider')
    ..aOS(3, _omitFieldNames ? '' : 'modelId')
    ..aOS(4, _omitFieldNames ? '' : 'instanceId')
    ..aOS(5, _omitFieldNames ? '' : 'botId')
    ..aOS(6, _omitFieldNames ? '' : 'thinkingLevel')
    ..aOS(7, _omitFieldNames ? '' : 'responseStyle')
    ..aOS(8, _omitFieldNames ? '' : 'projectId')
    ..aOS(9, _omitFieldNames ? '' : 'connectionId')
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
  $core.String get modelRef => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelRef($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelRef() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelRef() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get provider => $_getSZ(1);
  @$pb.TagNumber(2)
  set provider($core.String value) => $_setString(1, value);
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
  $core.String get instanceId => $_getSZ(3);
  @$pb.TagNumber(4)
  set instanceId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInstanceId() => $_has(3);
  @$pb.TagNumber(4)
  void clearInstanceId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get botId => $_getSZ(4);
  @$pb.TagNumber(5)
  set botId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBotId() => $_has(4);
  @$pb.TagNumber(5)
  void clearBotId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get thinkingLevel => $_getSZ(5);
  @$pb.TagNumber(6)
  set thinkingLevel($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasThinkingLevel() => $_has(5);
  @$pb.TagNumber(6)
  void clearThinkingLevel() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get responseStyle => $_getSZ(6);
  @$pb.TagNumber(7)
  set responseStyle($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasResponseStyle() => $_has(6);
  @$pb.TagNumber(7)
  void clearResponseStyle() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get projectId => $_getSZ(7);
  @$pb.TagNumber(8)
  set projectId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProjectId() => $_has(7);
  @$pb.TagNumber(8)
  void clearProjectId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get connectionId => $_getSZ(8);
  @$pb.TagNumber(9)
  set connectionId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasConnectionId() => $_has(8);
  @$pb.TagNumber(9)
  void clearConnectionId() => $_clearField(9);
}

class CreateSessionResponse extends $pb.GeneratedMessage {
  factory CreateSessionResponse({
    $core.String? sessionId,
    $core.String? modelRef,
    $core.String? provider,
    $core.String? modelId,
    $core.String? displayName,
    $core.String? thinking,
    $core.String? style,
    $core.String? botId,
    $core.String? botName,
    $core.String? lockedBotId,
    $core.String? instanceId,
    $core.int? contextLimit,
    $core.String? connectionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (modelRef != null) result.modelRef = modelRef;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (displayName != null) result.displayName = displayName;
    if (thinking != null) result.thinking = thinking;
    if (style != null) result.style = style;
    if (botId != null) result.botId = botId;
    if (botName != null) result.botName = botName;
    if (lockedBotId != null) result.lockedBotId = lockedBotId;
    if (instanceId != null) result.instanceId = instanceId;
    if (contextLimit != null) result.contextLimit = contextLimit;
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  CreateSessionResponse._();

  factory CreateSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'modelRef')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'modelId')
    ..aOS(5, _omitFieldNames ? '' : 'displayName')
    ..aOS(6, _omitFieldNames ? '' : 'thinking')
    ..aOS(7, _omitFieldNames ? '' : 'style')
    ..aOS(8, _omitFieldNames ? '' : 'botId')
    ..aOS(9, _omitFieldNames ? '' : 'botName')
    ..aOS(10, _omitFieldNames ? '' : 'lockedBotId')
    ..aOS(11, _omitFieldNames ? '' : 'instanceId')
    ..aI(12, _omitFieldNames ? '' : 'contextLimit')
    ..aOS(13, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionResponse copyWith(
          void Function(CreateSessionResponse) updates) =>
      super.copyWith((message) => updates(message as CreateSessionResponse))
          as CreateSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateSessionResponse create() => CreateSessionResponse._();
  @$core.override
  CreateSessionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionResponse>(create);
  static CreateSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modelRef => $_getSZ(1);
  @$pb.TagNumber(2)
  set modelRef($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelRef() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get modelId => $_getSZ(3);
  @$pb.TagNumber(4)
  set modelId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelId() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get displayName => $_getSZ(4);
  @$pb.TagNumber(5)
  set displayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplayName() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplayName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get thinking => $_getSZ(5);
  @$pb.TagNumber(6)
  set thinking($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasThinking() => $_has(5);
  @$pb.TagNumber(6)
  void clearThinking() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get style => $_getSZ(6);
  @$pb.TagNumber(7)
  set style($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStyle() => $_has(6);
  @$pb.TagNumber(7)
  void clearStyle() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get botId => $_getSZ(7);
  @$pb.TagNumber(8)
  set botId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBotId() => $_has(7);
  @$pb.TagNumber(8)
  void clearBotId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get botName => $_getSZ(8);
  @$pb.TagNumber(9)
  set botName($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBotName() => $_has(8);
  @$pb.TagNumber(9)
  void clearBotName() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get lockedBotId => $_getSZ(9);
  @$pb.TagNumber(10)
  set lockedBotId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLockedBotId() => $_has(9);
  @$pb.TagNumber(10)
  void clearLockedBotId() => $_clearField(10);

  /// Only set for a local model: which engine instance answers, and how much
  /// context it was started with.
  @$pb.TagNumber(11)
  $core.String get instanceId => $_getSZ(10);
  @$pb.TagNumber(11)
  set instanceId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasInstanceId() => $_has(10);
  @$pb.TagNumber(11)
  void clearInstanceId() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get contextLimit => $_getIZ(11);
  @$pb.TagNumber(12)
  set contextLimit($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasContextLimit() => $_has(11);
  @$pb.TagNumber(12)
  void clearContextLimit() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get connectionId => $_getSZ(12);
  @$pb.TagNumber(13)
  set connectionId($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasConnectionId() => $_has(12);
  @$pb.TagNumber(13)
  void clearConnectionId() => $_clearField(13);
}

class ListSessionsRequest extends $pb.GeneratedMessage {
  factory ListSessionsRequest() => create();

  ListSessionsRequest._();

  factory ListSessionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSessionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSessionsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest copyWith(void Function(ListSessionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSessionsRequest))
          as ListSessionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSessionsRequest create() => ListSessionsRequest._();
  @$core.override
  ListSessionsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSessionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSessionsRequest>(create);
  static ListSessionsRequest? _defaultInstance;
}

class ListSessionsResponse extends $pb.GeneratedMessage {
  factory ListSessionsResponse({
    $core.Iterable<SessionSummary>? sessions,
  }) {
    final result = create();
    if (sessions != null) result.sessions.addAll(sessions);
    return result;
  }

  ListSessionsResponse._();

  factory ListSessionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSessionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSessionsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..pPM<SessionSummary>(1, _omitFieldNames ? '' : 'sessions',
        subBuilder: SessionSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse copyWith(void Function(ListSessionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSessionsResponse))
          as ListSessionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSessionsResponse create() => ListSessionsResponse._();
  @$core.override
  ListSessionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSessionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSessionsResponse>(create);
  static ListSessionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SessionSummary> get sessions => $_getList(0);
}

class GetHistoryRequest extends $pb.GeneratedMessage {
  factory GetHistoryRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  GetHistoryRequest._();

  factory GetHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHistoryRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryRequest copyWith(void Function(GetHistoryRequest) updates) =>
      super.copyWith((message) => updates(message as GetHistoryRequest))
          as GetHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHistoryRequest create() => GetHistoryRequest._();
  @$core.override
  GetHistoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetHistoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHistoryRequest>(create);
  static GetHistoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class GetHistoryResponse extends $pb.GeneratedMessage {
  factory GetHistoryResponse({
    $core.String? sessionId,
    $core.String? provider,
    $core.String? modelId,
    $core.String? modelRef,
    $core.String? displayName,
    $core.int? contextLimit,
    $core.String? lockedBotId,
    $core.String? activeBotId,
    $core.Iterable<ChatMessage>? messages,
    $core.String? connectionId,
    ContextUsage? contextUsage,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (modelRef != null) result.modelRef = modelRef;
    if (displayName != null) result.displayName = displayName;
    if (contextLimit != null) result.contextLimit = contextLimit;
    if (lockedBotId != null) result.lockedBotId = lockedBotId;
    if (activeBotId != null) result.activeBotId = activeBotId;
    if (messages != null) result.messages.addAll(messages);
    if (connectionId != null) result.connectionId = connectionId;
    if (contextUsage != null) result.contextUsage = contextUsage;
    return result;
  }

  GetHistoryResponse._();

  factory GetHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHistoryResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'provider')
    ..aOS(3, _omitFieldNames ? '' : 'modelId')
    ..aOS(4, _omitFieldNames ? '' : 'modelRef')
    ..aOS(5, _omitFieldNames ? '' : 'displayName')
    ..aI(6, _omitFieldNames ? '' : 'contextLimit')
    ..aOS(7, _omitFieldNames ? '' : 'lockedBotId')
    ..aOS(8, _omitFieldNames ? '' : 'activeBotId')
    ..pPM<ChatMessage>(9, _omitFieldNames ? '' : 'messages',
        subBuilder: ChatMessage.create)
    ..aOS(10, _omitFieldNames ? '' : 'connectionId')
    ..aOM<ContextUsage>(11, _omitFieldNames ? '' : 'contextUsage',
        subBuilder: ContextUsage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryResponse copyWith(void Function(GetHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as GetHistoryResponse))
          as GetHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHistoryResponse create() => GetHistoryResponse._();
  @$core.override
  GetHistoryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHistoryResponse>(create);
  static GetHistoryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get provider => $_getSZ(1);
  @$pb.TagNumber(2)
  set provider($core.String value) => $_setString(1, value);
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
  $core.String get modelRef => $_getSZ(3);
  @$pb.TagNumber(4)
  set modelRef($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelRef() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelRef() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get displayName => $_getSZ(4);
  @$pb.TagNumber(5)
  set displayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplayName() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplayName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get contextLimit => $_getIZ(5);
  @$pb.TagNumber(6)
  set contextLimit($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasContextLimit() => $_has(5);
  @$pb.TagNumber(6)
  void clearContextLimit() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get lockedBotId => $_getSZ(6);
  @$pb.TagNumber(7)
  set lockedBotId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLockedBotId() => $_has(6);
  @$pb.TagNumber(7)
  void clearLockedBotId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get activeBotId => $_getSZ(7);
  @$pb.TagNumber(8)
  set activeBotId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasActiveBotId() => $_has(7);
  @$pb.TagNumber(8)
  void clearActiveBotId() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<ChatMessage> get messages => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get connectionId => $_getSZ(9);
  @$pb.TagNumber(10)
  set connectionId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasConnectionId() => $_has(9);
  @$pb.TagNumber(10)
  void clearConnectionId() => $_clearField(10);

  /// How full the model's context window is right now, so a reopened chat shows
  /// its meter without having to send a message first.
  @$pb.TagNumber(11)
  ContextUsage get contextUsage => $_getN(10);
  @$pb.TagNumber(11)
  set contextUsage(ContextUsage value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasContextUsage() => $_has(10);
  @$pb.TagNumber(11)
  void clearContextUsage() => $_clearField(11);
  @$pb.TagNumber(11)
  ContextUsage ensureContextUsage() => $_ensure(10);
}

class RenameSessionRequest extends $pb.GeneratedMessage {
  factory RenameSessionRequest({
    $core.String? sessionId,
    $core.String? title,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (title != null) result.title = title;
    return result;
  }

  RenameSessionRequest._();

  factory RenameSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameSessionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameSessionRequest copyWith(void Function(RenameSessionRequest) updates) =>
      super.copyWith((message) => updates(message as RenameSessionRequest))
          as RenameSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameSessionRequest create() => RenameSessionRequest._();
  @$core.override
  RenameSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameSessionRequest>(create);
  static RenameSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Trimmed to 120 characters.
  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);
}

class RenameSessionResponse extends $pb.GeneratedMessage {
  factory RenameSessionResponse({
    SessionSummary? session,
  }) {
    final result = create();
    if (session != null) result.session = session;
    return result;
  }

  RenameSessionResponse._();

  factory RenameSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameSessionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOM<SessionSummary>(1, _omitFieldNames ? '' : 'session',
        subBuilder: SessionSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameSessionResponse copyWith(
          void Function(RenameSessionResponse) updates) =>
      super.copyWith((message) => updates(message as RenameSessionResponse))
          as RenameSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameSessionResponse create() => RenameSessionResponse._();
  @$core.override
  RenameSessionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameSessionResponse>(create);
  static RenameSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionSummary get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(SessionSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionSummary ensureSession() => $_ensure(0);
}

class DeleteSessionRequest extends $pb.GeneratedMessage {
  factory DeleteSessionRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  DeleteSessionRequest._();

  factory DeleteSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSessionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSessionRequest copyWith(void Function(DeleteSessionRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSessionRequest))
          as DeleteSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSessionRequest create() => DeleteSessionRequest._();
  @$core.override
  DeleteSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSessionRequest>(create);
  static DeleteSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class DeleteSessionResponse extends $pb.GeneratedMessage {
  factory DeleteSessionResponse() => create();

  DeleteSessionResponse._();

  factory DeleteSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSessionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSessionResponse copyWith(
          void Function(DeleteSessionResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteSessionResponse))
          as DeleteSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSessionResponse create() => DeleteSessionResponse._();
  @$core.override
  DeleteSessionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSessionResponse>(create);
  static DeleteSessionResponse? _defaultInstance;
}

/// An empty project_id detaches the session from its project.
class SetSessionProjectRequest extends $pb.GeneratedMessage {
  factory SetSessionProjectRequest({
    $core.String? sessionId,
    $core.String? projectId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (projectId != null) result.projectId = projectId;
    return result;
  }

  SetSessionProjectRequest._();

  factory SetSessionProjectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetSessionProjectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSessionProjectRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'projectId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionProjectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionProjectRequest copyWith(
          void Function(SetSessionProjectRequest) updates) =>
      super.copyWith((message) => updates(message as SetSessionProjectRequest))
          as SetSessionProjectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetSessionProjectRequest create() => SetSessionProjectRequest._();
  @$core.override
  SetSessionProjectRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetSessionProjectRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSessionProjectRequest>(create);
  static SetSessionProjectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get projectId => $_getSZ(1);
  @$pb.TagNumber(2)
  set projectId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProjectId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProjectId() => $_clearField(2);
}

class SetSessionProjectResponse extends $pb.GeneratedMessage {
  factory SetSessionProjectResponse({
    SessionSummary? session,
  }) {
    final result = create();
    if (session != null) result.session = session;
    return result;
  }

  SetSessionProjectResponse._();

  factory SetSessionProjectResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetSessionProjectResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSessionProjectResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOM<SessionSummary>(1, _omitFieldNames ? '' : 'session',
        subBuilder: SessionSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionProjectResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionProjectResponse copyWith(
          void Function(SetSessionProjectResponse) updates) =>
      super.copyWith((message) => updates(message as SetSessionProjectResponse))
          as SetSessionProjectResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetSessionProjectResponse create() => SetSessionProjectResponse._();
  @$core.override
  SetSessionProjectResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetSessionProjectResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSessionProjectResponse>(create);
  static SetSessionProjectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionSummary get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(SessionSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionSummary ensureSession() => $_ensure(0);
}

class SetSessionModelRequest extends $pb.GeneratedMessage {
  factory SetSessionModelRequest({
    $core.String? sessionId,
    $core.String? provider,
    $core.String? modelId,
    $core.String? modelRef,
    $core.String? displayName,
    $core.int? contextLimit,
    $core.String? connectionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (provider != null) result.provider = provider;
    if (modelId != null) result.modelId = modelId;
    if (modelRef != null) result.modelRef = modelRef;
    if (displayName != null) result.displayName = displayName;
    if (contextLimit != null) result.contextLimit = contextLimit;
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  SetSessionModelRequest._();

  factory SetSessionModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetSessionModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSessionModelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'provider')
    ..aOS(3, _omitFieldNames ? '' : 'modelId')
    ..aOS(4, _omitFieldNames ? '' : 'modelRef')
    ..aOS(5, _omitFieldNames ? '' : 'displayName')
    ..aI(6, _omitFieldNames ? '' : 'contextLimit')
    ..aOS(7, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionModelRequest copyWith(
          void Function(SetSessionModelRequest) updates) =>
      super.copyWith((message) => updates(message as SetSessionModelRequest))
          as SetSessionModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetSessionModelRequest create() => SetSessionModelRequest._();
  @$core.override
  SetSessionModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetSessionModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSessionModelRequest>(create);
  static SetSessionModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get provider => $_getSZ(1);
  @$pb.TagNumber(2)
  set provider($core.String value) => $_setString(1, value);
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
  $core.String get modelRef => $_getSZ(3);
  @$pb.TagNumber(4)
  set modelRef($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelRef() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelRef() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get displayName => $_getSZ(4);
  @$pb.TagNumber(5)
  set displayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplayName() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplayName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get contextLimit => $_getIZ(5);
  @$pb.TagNumber(6)
  set contextLimit($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasContextLimit() => $_has(5);
  @$pb.TagNumber(6)
  void clearContextLimit() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get connectionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set connectionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConnectionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearConnectionId() => $_clearField(7);
}

class SetSessionModelResponse extends $pb.GeneratedMessage {
  factory SetSessionModelResponse({
    SessionSummary? session,
  }) {
    final result = create();
    if (session != null) result.session = session;
    return result;
  }

  SetSessionModelResponse._();

  factory SetSessionModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetSessionModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSessionModelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOM<SessionSummary>(1, _omitFieldNames ? '' : 'session',
        subBuilder: SessionSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSessionModelResponse copyWith(
          void Function(SetSessionModelResponse) updates) =>
      super.copyWith((message) => updates(message as SetSessionModelResponse))
          as SetSessionModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetSessionModelResponse create() => SetSessionModelResponse._();
  @$core.override
  SetSessionModelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetSessionModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSessionModelResponse>(create);
  static SetSessionModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionSummary get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(SessionSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionSummary ensureSession() => $_ensure(0);
}

class GetSessionTreeRequest extends $pb.GeneratedMessage {
  factory GetSessionTreeRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  GetSessionTreeRequest._();

  factory GetSessionTreeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSessionTreeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSessionTreeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTreeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTreeRequest copyWith(
          void Function(GetSessionTreeRequest) updates) =>
      super.copyWith((message) => updates(message as GetSessionTreeRequest))
          as GetSessionTreeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSessionTreeRequest create() => GetSessionTreeRequest._();
  @$core.override
  GetSessionTreeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSessionTreeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSessionTreeRequest>(create);
  static GetSessionTreeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class GetSessionTreeResponse extends $pb.GeneratedMessage {
  factory GetSessionTreeResponse({
    $core.String? root,
    FileNode? tree,
    $core.bool? truncated,
  }) {
    final result = create();
    if (root != null) result.root = root;
    if (tree != null) result.tree = tree;
    if (truncated != null) result.truncated = truncated;
    return result;
  }

  GetSessionTreeResponse._();

  factory GetSessionTreeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSessionTreeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSessionTreeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'root')
    ..aOM<FileNode>(2, _omitFieldNames ? '' : 'tree',
        subBuilder: FileNode.create)
    ..aOB(3, _omitFieldNames ? '' : 'truncated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTreeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTreeResponse copyWith(
          void Function(GetSessionTreeResponse) updates) =>
      super.copyWith((message) => updates(message as GetSessionTreeResponse))
          as GetSessionTreeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSessionTreeResponse create() => GetSessionTreeResponse._();
  @$core.override
  GetSessionTreeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSessionTreeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSessionTreeResponse>(create);
  static GetSessionTreeResponse? _defaultInstance;

  /// Absolute path of the project folder.
  @$pb.TagNumber(1)
  $core.String get root => $_getSZ(0);
  @$pb.TagNumber(1)
  set root($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoot() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoot() => $_clearField(1);

  @$pb.TagNumber(2)
  FileNode get tree => $_getN(1);
  @$pb.TagNumber(2)
  set tree(FileNode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTree() => $_has(1);
  @$pb.TagNumber(2)
  void clearTree() => $_clearField(2);
  @$pb.TagNumber(2)
  FileNode ensureTree() => $_ensure(1);

  /// True when the walk hit its depth or entry limit, so the tree is partial.
  @$pb.TagNumber(3)
  $core.bool get truncated => $_getBF(2);
  @$pb.TagNumber(3)
  set truncated($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTruncated() => $_has(2);
  @$pb.TagNumber(3)
  void clearTruncated() => $_clearField(3);
}

class SendMessageRequest extends $pb.GeneratedMessage {
  factory SendMessageRequest({
    $core.String? sessionId,
    $core.String? message,
    ChatOptions? options,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (message != null) result.message = message;
    if (options != null) result.options = options;
    return result;
  }

  SendMessageRequest._();

  factory SendMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessageRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<ChatOptions>(3, _omitFieldNames ? '' : 'options',
        subBuilder: ChatOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest copyWith(void Function(SendMessageRequest) updates) =>
      super.copyWith((message) => updates(message as SendMessageRequest))
          as SendMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendMessageRequest create() => SendMessageRequest._();
  @$core.override
  SendMessageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SendMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendMessageRequest>(create);
  static SendMessageRequest? _defaultInstance;

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
  ChatOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(ChatOptions value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => $_clearField(3);
  @$pb.TagNumber(3)
  ChatOptions ensureOptions() => $_ensure(2);
}

class SendMessageResponse extends $pb.GeneratedMessage {
  factory SendMessageResponse({
    $core.String? sessionId,
    $core.String? reply,
    $core.String? botId,
    $core.String? botName,
    $core.String? thinkingLevel,
    $core.String? responseStyle,
    Bot? createdBot,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (reply != null) result.reply = reply;
    if (botId != null) result.botId = botId;
    if (botName != null) result.botName = botName;
    if (thinkingLevel != null) result.thinkingLevel = thinkingLevel;
    if (responseStyle != null) result.responseStyle = responseStyle;
    if (createdBot != null) result.createdBot = createdBot;
    return result;
  }

  SendMessageResponse._();

  factory SendMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessageResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'reply')
    ..aOS(3, _omitFieldNames ? '' : 'botId')
    ..aOS(4, _omitFieldNames ? '' : 'botName')
    ..aOS(5, _omitFieldNames ? '' : 'thinkingLevel')
    ..aOS(6, _omitFieldNames ? '' : 'responseStyle')
    ..aOM<Bot>(7, _omitFieldNames ? '' : 'createdBot', subBuilder: Bot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageResponse copyWith(void Function(SendMessageResponse) updates) =>
      super.copyWith((message) => updates(message as SendMessageResponse))
          as SendMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendMessageResponse create() => SendMessageResponse._();
  @$core.override
  SendMessageResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SendMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendMessageResponse>(create);
  static SendMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get reply => $_getSZ(1);
  @$pb.TagNumber(2)
  set reply($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReply() => $_has(1);
  @$pb.TagNumber(2)
  void clearReply() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get botId => $_getSZ(2);
  @$pb.TagNumber(3)
  set botId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBotId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBotId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get botName => $_getSZ(3);
  @$pb.TagNumber(4)
  set botName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBotName() => $_has(3);
  @$pb.TagNumber(4)
  void clearBotName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get thinkingLevel => $_getSZ(4);
  @$pb.TagNumber(5)
  set thinkingLevel($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasThinkingLevel() => $_has(4);
  @$pb.TagNumber(5)
  void clearThinkingLevel() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get responseStyle => $_getSZ(5);
  @$pb.TagNumber(6)
  set responseStyle($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasResponseStyle() => $_has(5);
  @$pb.TagNumber(6)
  void clearResponseStyle() => $_clearField(6);

  /// Set when the turn was handled by the bot builder and produced a new bot.
  @$pb.TagNumber(7)
  Bot get createdBot => $_getN(6);
  @$pb.TagNumber(7)
  set createdBot(Bot value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedBot() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedBot() => $_clearField(7);
  @$pb.TagNumber(7)
  Bot ensureCreatedBot() => $_ensure(6);
}

class StreamMessageRequest extends $pb.GeneratedMessage {
  factory StreamMessageRequest({
    $core.String? sessionId,
    $core.String? message,
    ChatOptions? options,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (message != null) result.message = message;
    if (options != null) result.options = options;
    return result;
  }

  StreamMessageRequest._();

  factory StreamMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamMessageRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<ChatOptions>(3, _omitFieldNames ? '' : 'options',
        subBuilder: ChatOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamMessageRequest copyWith(void Function(StreamMessageRequest) updates) =>
      super.copyWith((message) => updates(message as StreamMessageRequest))
          as StreamMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamMessageRequest create() => StreamMessageRequest._();
  @$core.override
  StreamMessageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamMessageRequest>(create);
  static StreamMessageRequest? _defaultInstance;

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
  ChatOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(ChatOptions value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => $_clearField(3);
  @$pb.TagNumber(3)
  ChatOptions ensureOptions() => $_ensure(2);
}

/// One character of the reply. Emitted per grapheme, which is why it is a
/// message of its own rather than a generic payload - this is the hot path.
class TextDelta extends $pb.GeneratedMessage {
  factory TextDelta({
    $core.String? chunk,
  }) {
    final result = create();
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  TextDelta._();

  factory TextDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextDelta',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'chunk')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDelta copyWith(void Function(TextDelta) updates) =>
      super.copyWith((message) => updates(message as TextDelta)) as TextDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextDelta create() => TextDelta._();
  @$core.override
  TextDelta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TextDelta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextDelta>(create);
  static TextDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get chunk => $_getSZ(0);
  @$pb.TagNumber(1)
  set chunk($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChunk() => $_has(0);
  @$pb.TagNumber(1)
  void clearChunk() => $_clearField(1);
}

/// One character of the model's reasoning, kept apart from the reply so the UI
/// can fold it away.
class ReasoningDelta extends $pb.GeneratedMessage {
  factory ReasoningDelta({
    $core.String? chunk,
  }) {
    final result = create();
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  ReasoningDelta._();

  factory ReasoningDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReasoningDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReasoningDelta',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'chunk')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningDelta copyWith(void Function(ReasoningDelta) updates) =>
      super.copyWith((message) => updates(message as ReasoningDelta))
          as ReasoningDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReasoningDelta create() => ReasoningDelta._();
  @$core.override
  ReasoningDelta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReasoningDelta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReasoningDelta>(create);
  static ReasoningDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get chunk => $_getSZ(0);
  @$pb.TagNumber(1)
  set chunk($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChunk() => $_has(0);
  @$pb.TagNumber(1)
  void clearChunk() => $_clearField(1);
}

class BotSelected extends $pb.GeneratedMessage {
  factory BotSelected({
    $core.String? id,
    $core.String? name,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    return result;
  }

  BotSelected._();

  factory BotSelected.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BotSelected.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BotSelected',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotSelected clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotSelected copyWith(void Function(BotSelected) updates) =>
      super.copyWith((message) => updates(message as BotSelected))
          as BotSelected;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BotSelected create() => BotSelected._();
  @$core.override
  BotSelected createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BotSelected getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BotSelected>(create);
  static BotSelected? _defaultInstance;

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
}

class BotCreated extends $pb.GeneratedMessage {
  factory BotCreated({
    Bot? bot,
  }) {
    final result = create();
    if (bot != null) result.bot = bot;
    return result;
  }

  BotCreated._();

  factory BotCreated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BotCreated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BotCreated',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOM<Bot>(1, _omitFieldNames ? '' : 'bot', subBuilder: Bot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotCreated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotCreated copyWith(void Function(BotCreated) updates) =>
      super.copyWith((message) => updates(message as BotCreated)) as BotCreated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BotCreated create() => BotCreated._();
  @$core.override
  BotCreated createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BotCreated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BotCreated>(create);
  static BotCreated? _defaultInstance;

  @$pb.TagNumber(1)
  Bot get bot => $_getN(0);
  @$pb.TagNumber(1)
  set bot(Bot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBot() => $_has(0);
  @$pb.TagNumber(1)
  void clearBot() => $_clearField(1);
  @$pb.TagNumber(1)
  Bot ensureBot() => $_ensure(0);
}

class StatusUpdate extends $pb.GeneratedMessage {
  factory StatusUpdate({
    $core.String? action,
  }) {
    final result = create();
    if (action != null) result.action = action;
    return result;
  }

  StatusUpdate._();

  factory StatusUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusUpdate',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusUpdate copyWith(void Function(StatusUpdate) updates) =>
      super.copyWith((message) => updates(message as StatusUpdate))
          as StatusUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusUpdate create() => StatusUpdate._();
  @$core.override
  StatusUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatusUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusUpdate>(create);
  static StatusUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);
}

/// ModelWarmup reports a local model being made ready, which can take long
/// enough that the UI shows its own progress for it.
class ModelWarmup extends $pb.GeneratedMessage {
  factory ModelWarmup({
    $core.String? operationId,
    $core.String? instanceId,
    $core.String? status,
    $core.String? phase,
    $core.double? progress,
    $core.int? queuePosition,
    $core.String? placement,
    $core.String? message,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    if (instanceId != null) result.instanceId = instanceId;
    if (status != null) result.status = status;
    if (phase != null) result.phase = phase;
    if (progress != null) result.progress = progress;
    if (queuePosition != null) result.queuePosition = queuePosition;
    if (placement != null) result.placement = placement;
    if (message != null) result.message = message;
    return result;
  }

  ModelWarmup._();

  factory ModelWarmup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelWarmup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelWarmup',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..aOS(2, _omitFieldNames ? '' : 'instanceId')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..aOS(4, _omitFieldNames ? '' : 'phase')
    ..aD(5, _omitFieldNames ? '' : 'progress')
    ..aI(6, _omitFieldNames ? '' : 'queuePosition')
    ..aOS(7, _omitFieldNames ? '' : 'placement')
    ..aOS(8, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelWarmup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelWarmup copyWith(void Function(ModelWarmup) updates) =>
      super.copyWith((message) => updates(message as ModelWarmup))
          as ModelWarmup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelWarmup create() => ModelWarmup._();
  @$core.override
  ModelWarmup createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelWarmup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelWarmup>(create);
  static ModelWarmup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get instanceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set instanceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInstanceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstanceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get phase => $_getSZ(3);
  @$pb.TagNumber(4)
  set phase($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPhase() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get progress => $_getN(4);
  @$pb.TagNumber(5)
  set progress($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProgress() => $_has(4);
  @$pb.TagNumber(5)
  void clearProgress() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get queuePosition => $_getIZ(5);
  @$pb.TagNumber(6)
  set queuePosition($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasQueuePosition() => $_has(5);
  @$pb.TagNumber(6)
  void clearQueuePosition() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get placement => $_getSZ(6);
  @$pb.TagNumber(7)
  set placement($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPlacement() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlacement() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get message => $_getSZ(7);
  @$pb.TagNumber(8)
  set message($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMessage() => $_has(7);
  @$pb.TagNumber(8)
  void clearMessage() => $_clearField(8);
}

class StreamDone extends $pb.GeneratedMessage {
  factory StreamDone({
    $core.String? sessionId,
    $core.String? thinkingLevel,
    $core.String? responseStyle,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (thinkingLevel != null) result.thinkingLevel = thinkingLevel;
    if (responseStyle != null) result.responseStyle = responseStyle;
    return result;
  }

  StreamDone._();

  factory StreamDone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamDone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamDone',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'thinkingLevel')
    ..aOS(3, _omitFieldNames ? '' : 'responseStyle')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamDone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamDone copyWith(void Function(StreamDone) updates) =>
      super.copyWith((message) => updates(message as StreamDone)) as StreamDone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamDone create() => StreamDone._();
  @$core.override
  StreamDone createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamDone getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamDone>(create);
  static StreamDone? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get thinkingLevel => $_getSZ(1);
  @$pb.TagNumber(2)
  set thinkingLevel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasThinkingLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearThinkingLevel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get responseStyle => $_getSZ(2);
  @$pb.TagNumber(3)
  set responseStyle($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResponseStyle() => $_has(2);
  @$pb.TagNumber(3)
  void clearResponseStyle() => $_clearField(3);
}

/// ContextUsage is how much of the model's context window the conversation
/// occupies. Both numbers are estimates: limit_tokens may be a catalogue
/// average when nothing reported a real one, and used_tokens is counted by a
/// characters-per-token rule rather than the model's own tokenizer.
class ContextUsage extends $pb.GeneratedMessage {
  factory ContextUsage({
    $core.int? limitTokens,
    $core.int? usedTokens,
    $core.String? source,
    $core.int? compactions,
    $core.bool? compacted,
    $core.int? modelLimitTokens,
  }) {
    final result = create();
    if (limitTokens != null) result.limitTokens = limitTokens;
    if (usedTokens != null) result.usedTokens = usedTokens;
    if (source != null) result.source = source;
    if (compactions != null) result.compactions = compactions;
    if (compacted != null) result.compacted = compacted;
    if (modelLimitTokens != null) result.modelLimitTokens = modelLimitTokens;
    return result;
  }

  ContextUsage._();

  factory ContextUsage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextUsage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextUsage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'limitTokens')
    ..aI(2, _omitFieldNames ? '' : 'usedTokens')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aI(4, _omitFieldNames ? '' : 'compactions')
    ..aOB(5, _omitFieldNames ? '' : 'compacted')
    ..aI(6, _omitFieldNames ? '' : 'modelLimitTokens')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextUsage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextUsage copyWith(void Function(ContextUsage) updates) =>
      super.copyWith((message) => updates(message as ContextUsage))
          as ContextUsage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextUsage create() => ContextUsage._();
  @$core.override
  ContextUsage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextUsage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextUsage>(create);
  static ContextUsage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get limitTokens => $_getIZ(0);
  @$pb.TagNumber(1)
  set limitTokens($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLimitTokens() => $_has(0);
  @$pb.TagNumber(1)
  void clearLimitTokens() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get usedTokens => $_getIZ(1);
  @$pb.TagNumber(2)
  set usedTokens($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsedTokens() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsedTokens() => $_clearField(2);

  /// Where limit_tokens came from: "local" (the engine started the instance
  /// with it), "provider" (a configured connection reported it), "catalog"
  /// (the OpenRouter model list, the same source as the thinking levels), or
  /// "average" (the mean over every model the catalogue knows).
  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  /// How often this session's older turns have been folded into a summary.
  @$pb.TagNumber(4)
  $core.int get compactions => $_getIZ(3);
  @$pb.TagNumber(4)
  set compactions($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCompactions() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompactions() => $_clearField(4);

  /// True on the reading that follows a folding, so the UI can explain a meter
  /// that just dropped.
  @$pb.TagNumber(5)
  $core.bool get compacted => $_getBF(4);
  @$pb.TagNumber(5)
  set compacted($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCompacted() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompacted() => $_clearField(5);

  /// What the model itself would allow, where limit_tokens is only what this
  /// instance was actually started with - the engine's memory plan routinely
  /// starts a local model well below its maximum. Zero when the two are the
  /// same, so the UI only explains the gap when there is one.
  @$pb.TagNumber(6)
  $core.int get modelLimitTokens => $_getIZ(5);
  @$pb.TagNumber(6)
  set modelLimitTokens($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModelLimitTokens() => $_has(5);
  @$pb.TagNumber(6)
  void clearModelLimitTokens() => $_clearField(6);
}

/// StreamError ends the stream with a reason. It stays an event rather than a
/// gRPC status because the reply may already be half-written, and the client
/// needs the code to tell a warm-up problem from a real failure.
class StreamError extends $pb.GeneratedMessage {
  factory StreamError({
    $core.String? message,
    $core.String? code,
    $core.int? retryAfter,
  }) {
    final result = create();
    if (message != null) result.message = message;
    if (code != null) result.code = code;
    if (retryAfter != null) result.retryAfter = retryAfter;
    return result;
  }

  StreamError._();

  factory StreamError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamError',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aI(3, _omitFieldNames ? '' : 'retryAfter')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamError copyWith(void Function(StreamError) updates) =>
      super.copyWith((message) => updates(message as StreamError))
          as StreamError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamError create() => StreamError._();
  @$core.override
  StreamError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamError>(create);
  static StreamError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  /// Seconds to wait before retrying, for the codes that are worth retrying.
  @$pb.TagNumber(3)
  $core.int get retryAfter => $_getIZ(2);
  @$pb.TagNumber(3)
  set retryAfter($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRetryAfter() => $_has(2);
  @$pb.TagNumber(3)
  void clearRetryAfter() => $_clearField(3);
}

/// AgentEvent carries what the agent loop reports while it works: tool calls,
/// plans, permission prompts, file changes. The payload stays dynamic on
/// purpose - it is produced by the tool layer in the spark module, where each
/// tool decides what its result looks like, and the client stores it as an
/// opaque record next to the message. Typing it here would pin this schema to
/// spark's internal tool protocol.
class AgentEvent extends $pb.GeneratedMessage {
  factory AgentEvent({
    $core.String? type,
    $2.Struct? data,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (data != null) result.data = data;
    return result;
  }

  AgentEvent._();

  factory AgentEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AgentEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgentEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOM<$2.Struct>(2, _omitFieldNames ? '' : 'data',
        subBuilder: $2.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentEvent copyWith(void Function(AgentEvent) updates) =>
      super.copyWith((message) => updates(message as AgentEvent)) as AgentEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgentEvent create() => AgentEvent._();
  @$core.override
  AgentEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AgentEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgentEvent>(create);
  static AgentEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $2.Struct get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($2.Struct value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.Struct ensureData() => $_ensure(1);
}

enum StreamMessageResponse_Event {
  textDelta,
  reasoningDelta,
  botSelected,
  botCreated,
  status,
  modelWarmup,
  done,
  error,
  agent,
  contextUsage,
  notSet
}

/// One event of a streamed reply. Named after the RPC rather than after what it
/// is, because the schema lint ties a response message to its method.
class StreamMessageResponse extends $pb.GeneratedMessage {
  factory StreamMessageResponse({
    TextDelta? textDelta,
    ReasoningDelta? reasoningDelta,
    BotSelected? botSelected,
    BotCreated? botCreated,
    StatusUpdate? status,
    ModelWarmup? modelWarmup,
    StreamDone? done,
    StreamError? error,
    AgentEvent? agent,
    ContextUsage? contextUsage,
  }) {
    final result = create();
    if (textDelta != null) result.textDelta = textDelta;
    if (reasoningDelta != null) result.reasoningDelta = reasoningDelta;
    if (botSelected != null) result.botSelected = botSelected;
    if (botCreated != null) result.botCreated = botCreated;
    if (status != null) result.status = status;
    if (modelWarmup != null) result.modelWarmup = modelWarmup;
    if (done != null) result.done = done;
    if (error != null) result.error = error;
    if (agent != null) result.agent = agent;
    if (contextUsage != null) result.contextUsage = contextUsage;
    return result;
  }

  StreamMessageResponse._();

  factory StreamMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, StreamMessageResponse_Event>
      _StreamMessageResponse_EventByTag = {
    1: StreamMessageResponse_Event.textDelta,
    2: StreamMessageResponse_Event.reasoningDelta,
    3: StreamMessageResponse_Event.botSelected,
    4: StreamMessageResponse_Event.botCreated,
    5: StreamMessageResponse_Event.status,
    6: StreamMessageResponse_Event.modelWarmup,
    7: StreamMessageResponse_Event.done,
    8: StreamMessageResponse_Event.error,
    9: StreamMessageResponse_Event.agent,
    10: StreamMessageResponse_Event.contextUsage,
    0: StreamMessageResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamMessageResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    ..aOM<TextDelta>(1, _omitFieldNames ? '' : 'textDelta',
        subBuilder: TextDelta.create)
    ..aOM<ReasoningDelta>(2, _omitFieldNames ? '' : 'reasoningDelta',
        subBuilder: ReasoningDelta.create)
    ..aOM<BotSelected>(3, _omitFieldNames ? '' : 'botSelected',
        subBuilder: BotSelected.create)
    ..aOM<BotCreated>(4, _omitFieldNames ? '' : 'botCreated',
        subBuilder: BotCreated.create)
    ..aOM<StatusUpdate>(5, _omitFieldNames ? '' : 'status',
        subBuilder: StatusUpdate.create)
    ..aOM<ModelWarmup>(6, _omitFieldNames ? '' : 'modelWarmup',
        subBuilder: ModelWarmup.create)
    ..aOM<StreamDone>(7, _omitFieldNames ? '' : 'done',
        subBuilder: StreamDone.create)
    ..aOM<StreamError>(8, _omitFieldNames ? '' : 'error',
        subBuilder: StreamError.create)
    ..aOM<AgentEvent>(9, _omitFieldNames ? '' : 'agent',
        subBuilder: AgentEvent.create)
    ..aOM<ContextUsage>(10, _omitFieldNames ? '' : 'contextUsage',
        subBuilder: ContextUsage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamMessageResponse copyWith(
          void Function(StreamMessageResponse) updates) =>
      super.copyWith((message) => updates(message as StreamMessageResponse))
          as StreamMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamMessageResponse create() => StreamMessageResponse._();
  @$core.override
  StreamMessageResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamMessageResponse>(create);
  static StreamMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  StreamMessageResponse_Event whichEvent() =>
      _StreamMessageResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
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
  TextDelta get textDelta => $_getN(0);
  @$pb.TagNumber(1)
  set textDelta(TextDelta value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTextDelta() => $_has(0);
  @$pb.TagNumber(1)
  void clearTextDelta() => $_clearField(1);
  @$pb.TagNumber(1)
  TextDelta ensureTextDelta() => $_ensure(0);

  @$pb.TagNumber(2)
  ReasoningDelta get reasoningDelta => $_getN(1);
  @$pb.TagNumber(2)
  set reasoningDelta(ReasoningDelta value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReasoningDelta() => $_has(1);
  @$pb.TagNumber(2)
  void clearReasoningDelta() => $_clearField(2);
  @$pb.TagNumber(2)
  ReasoningDelta ensureReasoningDelta() => $_ensure(1);

  @$pb.TagNumber(3)
  BotSelected get botSelected => $_getN(2);
  @$pb.TagNumber(3)
  set botSelected(BotSelected value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBotSelected() => $_has(2);
  @$pb.TagNumber(3)
  void clearBotSelected() => $_clearField(3);
  @$pb.TagNumber(3)
  BotSelected ensureBotSelected() => $_ensure(2);

  @$pb.TagNumber(4)
  BotCreated get botCreated => $_getN(3);
  @$pb.TagNumber(4)
  set botCreated(BotCreated value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasBotCreated() => $_has(3);
  @$pb.TagNumber(4)
  void clearBotCreated() => $_clearField(4);
  @$pb.TagNumber(4)
  BotCreated ensureBotCreated() => $_ensure(3);

  @$pb.TagNumber(5)
  StatusUpdate get status => $_getN(4);
  @$pb.TagNumber(5)
  set status(StatusUpdate value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);
  @$pb.TagNumber(5)
  StatusUpdate ensureStatus() => $_ensure(4);

  @$pb.TagNumber(6)
  ModelWarmup get modelWarmup => $_getN(5);
  @$pb.TagNumber(6)
  set modelWarmup(ModelWarmup value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasModelWarmup() => $_has(5);
  @$pb.TagNumber(6)
  void clearModelWarmup() => $_clearField(6);
  @$pb.TagNumber(6)
  ModelWarmup ensureModelWarmup() => $_ensure(5);

  @$pb.TagNumber(7)
  StreamDone get done => $_getN(6);
  @$pb.TagNumber(7)
  set done(StreamDone value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDone() => $_has(6);
  @$pb.TagNumber(7)
  void clearDone() => $_clearField(7);
  @$pb.TagNumber(7)
  StreamDone ensureDone() => $_ensure(6);

  @$pb.TagNumber(8)
  StreamError get error => $_getN(7);
  @$pb.TagNumber(8)
  set error(StreamError value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasError() => $_has(7);
  @$pb.TagNumber(8)
  void clearError() => $_clearField(8);
  @$pb.TagNumber(8)
  StreamError ensureError() => $_ensure(7);

  @$pb.TagNumber(9)
  AgentEvent get agent => $_getN(8);
  @$pb.TagNumber(9)
  set agent(AgentEvent value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasAgent() => $_has(8);
  @$pb.TagNumber(9)
  void clearAgent() => $_clearField(9);
  @$pb.TagNumber(9)
  AgentEvent ensureAgent() => $_ensure(8);

  @$pb.TagNumber(10)
  ContextUsage get contextUsage => $_getN(9);
  @$pb.TagNumber(10)
  set contextUsage(ContextUsage value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasContextUsage() => $_has(9);
  @$pb.TagNumber(10)
  void clearContextUsage() => $_clearField(10);
  @$pb.TagNumber(10)
  ContextUsage ensureContextUsage() => $_ensure(9);
}

class ListBotsRequest extends $pb.GeneratedMessage {
  factory ListBotsRequest() => create();

  ListBotsRequest._();

  factory ListBotsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBotsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBotsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBotsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBotsRequest copyWith(void Function(ListBotsRequest) updates) =>
      super.copyWith((message) => updates(message as ListBotsRequest))
          as ListBotsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBotsRequest create() => ListBotsRequest._();
  @$core.override
  ListBotsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBotsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBotsRequest>(create);
  static ListBotsRequest? _defaultInstance;
}

class ListBotsResponse extends $pb.GeneratedMessage {
  factory ListBotsResponse({
    $core.Iterable<Bot>? bots,
  }) {
    final result = create();
    if (bots != null) result.bots.addAll(bots);
    return result;
  }

  ListBotsResponse._();

  factory ListBotsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBotsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBotsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..pPM<Bot>(1, _omitFieldNames ? '' : 'bots', subBuilder: Bot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBotsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBotsResponse copyWith(void Function(ListBotsResponse) updates) =>
      super.copyWith((message) => updates(message as ListBotsResponse))
          as ListBotsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBotsResponse create() => ListBotsResponse._();
  @$core.override
  ListBotsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBotsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBotsResponse>(create);
  static ListBotsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Bot> get bots => $_getList(0);
}

/// An empty id creates a bot; the backend assigns one.
class SaveBotRequest extends $pb.GeneratedMessage {
  factory SaveBotRequest({
    Bot? bot,
  }) {
    final result = create();
    if (bot != null) result.bot = bot;
    return result;
  }

  SaveBotRequest._();

  factory SaveBotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveBotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveBotRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOM<Bot>(1, _omitFieldNames ? '' : 'bot', subBuilder: Bot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveBotRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveBotRequest copyWith(void Function(SaveBotRequest) updates) =>
      super.copyWith((message) => updates(message as SaveBotRequest))
          as SaveBotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveBotRequest create() => SaveBotRequest._();
  @$core.override
  SaveBotRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveBotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveBotRequest>(create);
  static SaveBotRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Bot get bot => $_getN(0);
  @$pb.TagNumber(1)
  set bot(Bot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBot() => $_has(0);
  @$pb.TagNumber(1)
  void clearBot() => $_clearField(1);
  @$pb.TagNumber(1)
  Bot ensureBot() => $_ensure(0);
}

class SaveBotResponse extends $pb.GeneratedMessage {
  factory SaveBotResponse({
    Bot? bot,
  }) {
    final result = create();
    if (bot != null) result.bot = bot;
    return result;
  }

  SaveBotResponse._();

  factory SaveBotResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveBotResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveBotResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOM<Bot>(1, _omitFieldNames ? '' : 'bot', subBuilder: Bot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveBotResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveBotResponse copyWith(void Function(SaveBotResponse) updates) =>
      super.copyWith((message) => updates(message as SaveBotResponse))
          as SaveBotResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveBotResponse create() => SaveBotResponse._();
  @$core.override
  SaveBotResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveBotResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveBotResponse>(create);
  static SaveBotResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Bot get bot => $_getN(0);
  @$pb.TagNumber(1)
  set bot(Bot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBot() => $_has(0);
  @$pb.TagNumber(1)
  void clearBot() => $_clearField(1);
  @$pb.TagNumber(1)
  Bot ensureBot() => $_ensure(0);
}

class DeleteBotRequest extends $pb.GeneratedMessage {
  factory DeleteBotRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteBotRequest._();

  factory DeleteBotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteBotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteBotRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteBotRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteBotRequest copyWith(void Function(DeleteBotRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteBotRequest))
          as DeleteBotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteBotRequest create() => DeleteBotRequest._();
  @$core.override
  DeleteBotRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteBotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteBotRequest>(create);
  static DeleteBotRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeleteBotResponse extends $pb.GeneratedMessage {
  factory DeleteBotResponse() => create();

  DeleteBotResponse._();

  factory DeleteBotResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteBotResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteBotResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteBotResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteBotResponse copyWith(void Function(DeleteBotResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteBotResponse))
          as DeleteBotResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteBotResponse create() => DeleteBotResponse._();
  @$core.override
  DeleteBotResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteBotResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteBotResponse>(create);
  static DeleteBotResponse? _defaultInstance;
}

class ReasoningProfile extends $pb.GeneratedMessage {
  factory ReasoningProfile({
    $core.String? id,
    $core.String? name,
    $core.bool? mandatory,
    $core.bool? defaultEnabled,
    $core.Iterable<$core.String>? supportedEfforts,
    $core.String? defaultEffort,
    $core.int? contextLength,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (mandatory != null) result.mandatory = mandatory;
    if (defaultEnabled != null) result.defaultEnabled = defaultEnabled;
    if (supportedEfforts != null)
      result.supportedEfforts.addAll(supportedEfforts);
    if (defaultEffort != null) result.defaultEffort = defaultEffort;
    if (contextLength != null) result.contextLength = contextLength;
    return result;
  }

  ReasoningProfile._();

  factory ReasoningProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReasoningProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReasoningProfile',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOB(3, _omitFieldNames ? '' : 'mandatory')
    ..aOB(4, _omitFieldNames ? '' : 'defaultEnabled')
    ..pPS(5, _omitFieldNames ? '' : 'supportedEfforts')
    ..aOS(6, _omitFieldNames ? '' : 'defaultEffort')
    ..aI(7, _omitFieldNames ? '' : 'contextLength')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningProfile copyWith(void Function(ReasoningProfile) updates) =>
      super.copyWith((message) => updates(message as ReasoningProfile))
          as ReasoningProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReasoningProfile create() => ReasoningProfile._();
  @$core.override
  ReasoningProfile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReasoningProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReasoningProfile>(create);
  static ReasoningProfile? _defaultInstance;

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
  $core.bool get mandatory => $_getBF(2);
  @$pb.TagNumber(3)
  set mandatory($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMandatory() => $_has(2);
  @$pb.TagNumber(3)
  void clearMandatory() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get defaultEnabled => $_getBF(3);
  @$pb.TagNumber(4)
  set defaultEnabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDefaultEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefaultEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get supportedEfforts => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get defaultEffort => $_getSZ(5);
  @$pb.TagNumber(6)
  set defaultEffort($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDefaultEffort() => $_has(5);
  @$pb.TagNumber(6)
  void clearDefaultEffort() => $_clearField(6);

  /// The model's context window in tokens, read from the same catalogue entry
  /// as the thinking levels above. Zero when the catalogue does not report one.
  @$pb.TagNumber(7)
  $core.int get contextLength => $_getIZ(6);
  @$pb.TagNumber(7)
  set contextLength($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasContextLength() => $_has(6);
  @$pb.TagNumber(7)
  void clearContextLength() => $_clearField(7);
}

class ListReasoningProfilesRequest extends $pb.GeneratedMessage {
  factory ListReasoningProfilesRequest() => create();

  ListReasoningProfilesRequest._();

  factory ListReasoningProfilesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReasoningProfilesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReasoningProfilesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReasoningProfilesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReasoningProfilesRequest copyWith(
          void Function(ListReasoningProfilesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListReasoningProfilesRequest))
          as ListReasoningProfilesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReasoningProfilesRequest create() =>
      ListReasoningProfilesRequest._();
  @$core.override
  ListReasoningProfilesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListReasoningProfilesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReasoningProfilesRequest>(create);
  static ListReasoningProfilesRequest? _defaultInstance;
}

class ListReasoningProfilesResponse extends $pb.GeneratedMessage {
  factory ListReasoningProfilesResponse({
    $core.Iterable<ReasoningProfile>? profiles,
  }) {
    final result = create();
    if (profiles != null) result.profiles.addAll(profiles);
    return result;
  }

  ListReasoningProfilesResponse._();

  factory ListReasoningProfilesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReasoningProfilesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReasoningProfilesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.scout.v1'),
      createEmptyInstance: create)
    ..pPM<ReasoningProfile>(1, _omitFieldNames ? '' : 'profiles',
        subBuilder: ReasoningProfile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReasoningProfilesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReasoningProfilesResponse copyWith(
          void Function(ListReasoningProfilesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListReasoningProfilesResponse))
          as ListReasoningProfilesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReasoningProfilesResponse create() =>
      ListReasoningProfilesResponse._();
  @$core.override
  ListReasoningProfilesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListReasoningProfilesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReasoningProfilesResponse>(create);
  static ListReasoningProfilesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReasoningProfile> get profiles => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
