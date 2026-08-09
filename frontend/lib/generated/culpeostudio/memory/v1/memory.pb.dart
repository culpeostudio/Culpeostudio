// This is a generated file - do not edit.
//
// Generated from culpeostudio/memory/v1/memory.proto.

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

import 'memory.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'memory.pbenum.dart';

class Prompt extends $pb.GeneratedMessage {
  factory Prompt({
    $core.String? id,
    $core.String? sessionId,
    PromptRole? role,
    $core.String? text,
    $1.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (sessionId != null) result.sessionId = sessionId;
    if (role != null) result.role = role;
    if (text != null) result.text = text;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Prompt._();

  factory Prompt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Prompt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Prompt',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aE<PromptRole>(3, _omitFieldNames ? '' : 'role',
        enumValues: PromptRole.values)
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Prompt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Prompt copyWith(void Function(Prompt) updates) =>
      super.copyWith((message) => updates(message as Prompt)) as Prompt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Prompt create() => Prompt._();
  @$core.override
  Prompt createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Prompt getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Prompt>(create);
  static Prompt? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  PromptRole get role => $_getN(2);
  @$pb.TagNumber(3)
  set role(PromptRole value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRole() => $_has(2);
  @$pb.TagNumber(3)
  void clearRole() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => $_clearField(4);

  @$pb.TagNumber(5)
  $1.Timestamp get createdAt => $_getN(4);
  @$pb.TagNumber(5)
  set createdAt($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensureCreatedAt() => $_ensure(4);
}

/// ChangeRequestState is a proposal and the decision on it. Present only on an
/// observation that carries one.
class ChangeRequestState extends $pb.GeneratedMessage {
  factory ChangeRequestState({
    ChangeRequestStatus? status,
    $core.String? proposal,
    $core.String? reasonShort,
    $core.String? decidedAt,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (proposal != null) result.proposal = proposal;
    if (reasonShort != null) result.reasonShort = reasonShort;
    if (decidedAt != null) result.decidedAt = decidedAt;
    return result;
  }

  ChangeRequestState._();

  factory ChangeRequestState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeRequestState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeRequestState',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aE<ChangeRequestStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: ChangeRequestStatus.values)
    ..aOS(2, _omitFieldNames ? '' : 'proposal')
    ..aOS(3, _omitFieldNames ? '' : 'reasonShort')
    ..aOS(4, _omitFieldNames ? '' : 'decidedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeRequestState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeRequestState copyWith(void Function(ChangeRequestState) updates) =>
      super.copyWith((message) => updates(message as ChangeRequestState))
          as ChangeRequestState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeRequestState create() => ChangeRequestState._();
  @$core.override
  ChangeRequestState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangeRequestState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeRequestState>(create);
  static ChangeRequestState? _defaultInstance;

  @$pb.TagNumber(1)
  ChangeRequestStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ChangeRequestStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get proposal => $_getSZ(1);
  @$pb.TagNumber(2)
  set proposal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProposal() => $_has(1);
  @$pb.TagNumber(2)
  void clearProposal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reasonShort => $_getSZ(2);
  @$pb.TagNumber(3)
  set reasonShort($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReasonShort() => $_has(2);
  @$pb.TagNumber(3)
  void clearReasonShort() => $_clearField(3);

  /// Written by whoever decided, in whatever precision they used, so it stays
  /// text rather than a timestamp.
  @$pb.TagNumber(4)
  $core.String get decidedAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set decidedAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDecidedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearDecidedAt() => $_clearField(4);
}

/// Observation is one thing that happened, as the module recorded it.
class Observation extends $pb.GeneratedMessage {
  factory Observation({
    $core.String? id,
    $core.String? sessionId,
    $core.String? project,
    $core.String? source,
    MemoryLayer? layer,
    MemoryCategory? category,
    $core.String? type,
    $core.String? title,
    $core.String? narrative,
    ChangeRequestState? changeRequest,
    $core.String? speaker,
    $core.int? dialogueId,
    $core.Iterable<$core.String>? keywords,
    $core.Iterable<$core.String>? persons,
    $core.Iterable<$core.String>? entities,
    $core.String? topic,
    $core.String? location,
    $core.String? validFrom,
    $core.double? importance,
    $core.double? confidence,
    $core.String? supersededBy,
    $core.String? toolName,
    $core.String? sourcePath,
    $core.Iterable<$core.String>? tags,
    $core.String? contentHash,
    $core.bool? archived,
    $core.String? memoryId,
    $core.String? deletedAt,
    $1.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (sessionId != null) result.sessionId = sessionId;
    if (project != null) result.project = project;
    if (source != null) result.source = source;
    if (layer != null) result.layer = layer;
    if (category != null) result.category = category;
    if (type != null) result.type = type;
    if (title != null) result.title = title;
    if (narrative != null) result.narrative = narrative;
    if (changeRequest != null) result.changeRequest = changeRequest;
    if (speaker != null) result.speaker = speaker;
    if (dialogueId != null) result.dialogueId = dialogueId;
    if (keywords != null) result.keywords.addAll(keywords);
    if (persons != null) result.persons.addAll(persons);
    if (entities != null) result.entities.addAll(entities);
    if (topic != null) result.topic = topic;
    if (location != null) result.location = location;
    if (validFrom != null) result.validFrom = validFrom;
    if (importance != null) result.importance = importance;
    if (confidence != null) result.confidence = confidence;
    if (supersededBy != null) result.supersededBy = supersededBy;
    if (toolName != null) result.toolName = toolName;
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (tags != null) result.tags.addAll(tags);
    if (contentHash != null) result.contentHash = contentHash;
    if (archived != null) result.archived = archived;
    if (memoryId != null) result.memoryId = memoryId;
    if (deletedAt != null) result.deletedAt = deletedAt;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Observation._();

  factory Observation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Observation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Observation',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOS(3, _omitFieldNames ? '' : 'project')
    ..aOS(4, _omitFieldNames ? '' : 'source')
    ..aE<MemoryLayer>(5, _omitFieldNames ? '' : 'layer',
        enumValues: MemoryLayer.values)
    ..aE<MemoryCategory>(6, _omitFieldNames ? '' : 'category',
        enumValues: MemoryCategory.values)
    ..aOS(7, _omitFieldNames ? '' : 'type')
    ..aOS(8, _omitFieldNames ? '' : 'title')
    ..aOS(9, _omitFieldNames ? '' : 'narrative')
    ..aOM<ChangeRequestState>(10, _omitFieldNames ? '' : 'changeRequest',
        subBuilder: ChangeRequestState.create)
    ..aOS(11, _omitFieldNames ? '' : 'speaker')
    ..aI(12, _omitFieldNames ? '' : 'dialogueId')
    ..pPS(13, _omitFieldNames ? '' : 'keywords')
    ..pPS(14, _omitFieldNames ? '' : 'persons')
    ..pPS(15, _omitFieldNames ? '' : 'entities')
    ..aOS(16, _omitFieldNames ? '' : 'topic')
    ..aOS(17, _omitFieldNames ? '' : 'location')
    ..aOS(18, _omitFieldNames ? '' : 'validFrom')
    ..aD(19, _omitFieldNames ? '' : 'importance')
    ..aD(20, _omitFieldNames ? '' : 'confidence')
    ..aOS(21, _omitFieldNames ? '' : 'supersededBy')
    ..aOS(22, _omitFieldNames ? '' : 'toolName')
    ..aOS(23, _omitFieldNames ? '' : 'sourcePath')
    ..pPS(24, _omitFieldNames ? '' : 'tags')
    ..aOS(25, _omitFieldNames ? '' : 'contentHash')
    ..aOB(26, _omitFieldNames ? '' : 'archived')
    ..aOS(27, _omitFieldNames ? '' : 'memoryId')
    ..aOS(28, _omitFieldNames ? '' : 'deletedAt')
    ..aOM<$1.Timestamp>(29, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Observation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Observation copyWith(void Function(Observation) updates) =>
      super.copyWith((message) => updates(message as Observation))
          as Observation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Observation create() => Observation._();
  @$core.override
  Observation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Observation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Observation>(create);
  static Observation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get project => $_getSZ(2);
  @$pb.TagNumber(3)
  set project($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProject() => $_has(2);
  @$pb.TagNumber(3)
  void clearProject() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get source => $_getSZ(3);
  @$pb.TagNumber(4)
  set source($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);

  @$pb.TagNumber(5)
  MemoryLayer get layer => $_getN(4);
  @$pb.TagNumber(5)
  set layer(MemoryLayer value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLayer() => $_has(4);
  @$pb.TagNumber(5)
  void clearLayer() => $_clearField(5);

  @$pb.TagNumber(6)
  MemoryCategory get category => $_getN(5);
  @$pb.TagNumber(6)
  set category(MemoryCategory value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCategory() => $_has(5);
  @$pb.TagNumber(6)
  void clearCategory() => $_clearField(6);

  /// One of a fixed set the store normalises to: note, decision, task,
  /// tool_start, tool_result, insight, assistant_reply, event, summary,
  /// change_request, chat_memory. It stays a string because it is data the
  /// capture layer produces, not a schema both sides have to agree on.
  @$pb.TagNumber(7)
  $core.String get type => $_getSZ(6);
  @$pb.TagNumber(7)
  set type($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasType() => $_has(6);
  @$pb.TagNumber(7)
  void clearType() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get title => $_getSZ(7);
  @$pb.TagNumber(8)
  set title($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTitle() => $_has(7);
  @$pb.TagNumber(8)
  void clearTitle() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get narrative => $_getSZ(8);
  @$pb.TagNumber(9)
  set narrative($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasNarrative() => $_has(8);
  @$pb.TagNumber(9)
  void clearNarrative() => $_clearField(9);

  @$pb.TagNumber(10)
  ChangeRequestState get changeRequest => $_getN(9);
  @$pb.TagNumber(10)
  set changeRequest(ChangeRequestState value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasChangeRequest() => $_has(9);
  @$pb.TagNumber(10)
  void clearChangeRequest() => $_clearField(10);
  @$pb.TagNumber(10)
  ChangeRequestState ensureChangeRequest() => $_ensure(9);

  @$pb.TagNumber(11)
  $core.String get speaker => $_getSZ(10);
  @$pb.TagNumber(11)
  set speaker($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSpeaker() => $_has(10);
  @$pb.TagNumber(11)
  void clearSpeaker() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get dialogueId => $_getIZ(11);
  @$pb.TagNumber(12)
  set dialogueId($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDialogueId() => $_has(11);
  @$pb.TagNumber(12)
  void clearDialogueId() => $_clearField(12);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get keywords => $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<$core.String> get persons => $_getList(13);

  @$pb.TagNumber(15)
  $pb.PbList<$core.String> get entities => $_getList(14);

  @$pb.TagNumber(16)
  $core.String get topic => $_getSZ(15);
  @$pb.TagNumber(16)
  set topic($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasTopic() => $_has(15);
  @$pb.TagNumber(16)
  void clearTopic() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get location => $_getSZ(16);
  @$pb.TagNumber(17)
  set location($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasLocation() => $_has(16);
  @$pb.TagNumber(17)
  void clearLocation() => $_clearField(17);

  /// When the fact started holding, as the caller wrote it - not necessarily a
  /// full date.
  @$pb.TagNumber(18)
  $core.String get validFrom => $_getSZ(17);
  @$pb.TagNumber(18)
  set validFrom($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasValidFrom() => $_has(17);
  @$pb.TagNumber(18)
  void clearValidFrom() => $_clearField(18);

  /// Both are weights in (0,1]. Zero is read as "not rated" and becomes 0.5.
  @$pb.TagNumber(19)
  $core.double get importance => $_getN(18);
  @$pb.TagNumber(19)
  set importance($core.double value) => $_setDouble(18, value);
  @$pb.TagNumber(19)
  $core.bool hasImportance() => $_has(18);
  @$pb.TagNumber(19)
  void clearImportance() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.double get confidence => $_getN(19);
  @$pb.TagNumber(20)
  set confidence($core.double value) => $_setDouble(19, value);
  @$pb.TagNumber(20)
  $core.bool hasConfidence() => $_has(19);
  @$pb.TagNumber(20)
  void clearConfidence() => $_clearField(20);

  /// Id of the observation that replaced this one.
  @$pb.TagNumber(21)
  $core.String get supersededBy => $_getSZ(20);
  @$pb.TagNumber(21)
  set supersededBy($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasSupersededBy() => $_has(20);
  @$pb.TagNumber(21)
  void clearSupersededBy() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get toolName => $_getSZ(21);
  @$pb.TagNumber(22)
  set toolName($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasToolName() => $_has(21);
  @$pb.TagNumber(22)
  void clearToolName() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get sourcePath => $_getSZ(22);
  @$pb.TagNumber(23)
  set sourcePath($core.String value) => $_setString(22, value);
  @$pb.TagNumber(23)
  $core.bool hasSourcePath() => $_has(22);
  @$pb.TagNumber(23)
  void clearSourcePath() => $_clearField(23);

  @$pb.TagNumber(24)
  $pb.PbList<$core.String> get tags => $_getList(23);

  @$pb.TagNumber(25)
  $core.String get contentHash => $_getSZ(24);
  @$pb.TagNumber(25)
  set contentHash($core.String value) => $_setString(24, value);
  @$pb.TagNumber(25)
  $core.bool hasContentHash() => $_has(24);
  @$pb.TagNumber(25)
  void clearContentHash() => $_clearField(25);

  /// Set once the observation was folded into a compressed memory.
  @$pb.TagNumber(26)
  $core.bool get archived => $_getBF(25);
  @$pb.TagNumber(26)
  set archived($core.bool value) => $_setBool(25, value);
  @$pb.TagNumber(26)
  $core.bool hasArchived() => $_has(25);
  @$pb.TagNumber(26)
  void clearArchived() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.String get memoryId => $_getSZ(26);
  @$pb.TagNumber(27)
  set memoryId($core.String value) => $_setString(26, value);
  @$pb.TagNumber(27)
  $core.bool hasMemoryId() => $_has(26);
  @$pb.TagNumber(27)
  void clearMemoryId() => $_clearField(27);

  /// Set on a soft-deleted observation that is kept until the retention window
  /// passes.
  @$pb.TagNumber(28)
  $core.String get deletedAt => $_getSZ(27);
  @$pb.TagNumber(28)
  set deletedAt($core.String value) => $_setString(27, value);
  @$pb.TagNumber(28)
  $core.bool hasDeletedAt() => $_has(27);
  @$pb.TagNumber(28)
  void clearDeletedAt() => $_clearField(28);

  @$pb.TagNumber(29)
  $1.Timestamp get createdAt => $_getN(28);
  @$pb.TagNumber(29)
  set createdAt($1.Timestamp value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasCreatedAt() => $_has(28);
  @$pb.TagNumber(29)
  void clearCreatedAt() => $_clearField(29);
  @$pb.TagNumber(29)
  $1.Timestamp ensureCreatedAt() => $_ensure(28);
}

/// CompressedMemory is what is left of a run of observations once they were
/// summarised, and what recall reads instead of them.
class CompressedMemory extends $pb.GeneratedMessage {
  factory CompressedMemory({
    $core.String? id,
    $core.String? sessionId,
    MemoryLayer? layer,
    MemoryCategory? category,
    $core.String? summary,
    $core.Iterable<$core.String>? learned,
    $core.Iterable<$core.String>? openTasks,
    $core.Iterable<$core.String>? observationIds,
    $core.bool? correctedByUser,
    $1.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (sessionId != null) result.sessionId = sessionId;
    if (layer != null) result.layer = layer;
    if (category != null) result.category = category;
    if (summary != null) result.summary = summary;
    if (learned != null) result.learned.addAll(learned);
    if (openTasks != null) result.openTasks.addAll(openTasks);
    if (observationIds != null) result.observationIds.addAll(observationIds);
    if (correctedByUser != null) result.correctedByUser = correctedByUser;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  CompressedMemory._();

  factory CompressedMemory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompressedMemory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompressedMemory',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aE<MemoryLayer>(3, _omitFieldNames ? '' : 'layer',
        enumValues: MemoryLayer.values)
    ..aE<MemoryCategory>(4, _omitFieldNames ? '' : 'category',
        enumValues: MemoryCategory.values)
    ..aOS(5, _omitFieldNames ? '' : 'summary')
    ..pPS(6, _omitFieldNames ? '' : 'learned')
    ..pPS(7, _omitFieldNames ? '' : 'openTasks')
    ..pPS(8, _omitFieldNames ? '' : 'observationIds')
    ..aOB(9, _omitFieldNames ? '' : 'correctedByUser')
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompressedMemory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompressedMemory copyWith(void Function(CompressedMemory) updates) =>
      super.copyWith((message) => updates(message as CompressedMemory))
          as CompressedMemory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompressedMemory create() => CompressedMemory._();
  @$core.override
  CompressedMemory createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompressedMemory getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompressedMemory>(create);
  static CompressedMemory? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  MemoryLayer get layer => $_getN(2);
  @$pb.TagNumber(3)
  set layer(MemoryLayer value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLayer() => $_has(2);
  @$pb.TagNumber(3)
  void clearLayer() => $_clearField(3);

  @$pb.TagNumber(4)
  MemoryCategory get category => $_getN(3);
  @$pb.TagNumber(4)
  set category(MemoryCategory value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCategory() => $_has(3);
  @$pb.TagNumber(4)
  void clearCategory() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get summary => $_getSZ(4);
  @$pb.TagNumber(5)
  set summary($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSummary() => $_has(4);
  @$pb.TagNumber(5)
  void clearSummary() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get learned => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get openTasks => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get observationIds => $_getList(7);

  /// A memory the user edited by hand. Compression leaves it alone from then
  /// on rather than overwriting the correction.
  @$pb.TagNumber(9)
  $core.bool get correctedByUser => $_getBF(8);
  @$pb.TagNumber(9)
  set correctedByUser($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCorrectedByUser() => $_has(8);
  @$pb.TagNumber(9)
  void clearCorrectedByUser() => $_clearField(9);

  @$pb.TagNumber(10)
  $1.Timestamp get createdAt => $_getN(9);
  @$pb.TagNumber(10)
  set createdAt($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreatedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensureCreatedAt() => $_ensure(9);
}

class SessionSummary extends $pb.GeneratedMessage {
  factory SessionSummary({
    $core.String? id,
    $core.String? sessionId,
    $core.Iterable<$core.String>? learned,
    $core.Iterable<$core.String>? completed,
    $core.Iterable<$core.String>? nextSteps,
    $1.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (sessionId != null) result.sessionId = sessionId;
    if (learned != null) result.learned.addAll(learned);
    if (completed != null) result.completed.addAll(completed);
    if (nextSteps != null) result.nextSteps.addAll(nextSteps);
    if (createdAt != null) result.createdAt = createdAt;
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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..pPS(3, _omitFieldNames ? '' : 'learned')
    ..pPS(4, _omitFieldNames ? '' : 'completed')
    ..pPS(5, _omitFieldNames ? '' : 'nextSteps')
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
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
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get learned => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get completed => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get nextSteps => $_getList(4);

  @$pb.TagNumber(6)
  $1.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($1.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureCreatedAt() => $_ensure(5);
}

class Session extends $pb.GeneratedMessage {
  factory Session({
    $core.String? id,
    $core.String? project,
    $core.String? source,
    SessionStatus? status,
    $core.Iterable<$core.String>? goals,
    $core.Iterable<Prompt>? prompts,
    $core.Iterable<Observation>? activeObservations,
    $core.Iterable<Observation>? archivedObservations,
    $core.Iterable<CompressedMemory>? memories,
    $core.Iterable<SessionSummary>? summaries,
    $core.double? contextUsageEstimate,
    $core.int? promptCount,
    $core.int? observationCount,
    $core.int? compressedMemoryCount,
    $core.int? summaryCount,
    $1.Timestamp? createdAt,
    $1.Timestamp? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (project != null) result.project = project;
    if (source != null) result.source = source;
    if (status != null) result.status = status;
    if (goals != null) result.goals.addAll(goals);
    if (prompts != null) result.prompts.addAll(prompts);
    if (activeObservations != null)
      result.activeObservations.addAll(activeObservations);
    if (archivedObservations != null)
      result.archivedObservations.addAll(archivedObservations);
    if (memories != null) result.memories.addAll(memories);
    if (summaries != null) result.summaries.addAll(summaries);
    if (contextUsageEstimate != null)
      result.contextUsageEstimate = contextUsageEstimate;
    if (promptCount != null) result.promptCount = promptCount;
    if (observationCount != null) result.observationCount = observationCount;
    if (compressedMemoryCount != null)
      result.compressedMemoryCount = compressedMemoryCount;
    if (summaryCount != null) result.summaryCount = summaryCount;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  Session._();

  factory Session.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Session.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Session',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aE<SessionStatus>(4, _omitFieldNames ? '' : 'status',
        enumValues: SessionStatus.values)
    ..pPS(5, _omitFieldNames ? '' : 'goals')
    ..pPM<Prompt>(6, _omitFieldNames ? '' : 'prompts',
        subBuilder: Prompt.create)
    ..pPM<Observation>(7, _omitFieldNames ? '' : 'activeObservations',
        subBuilder: Observation.create)
    ..pPM<Observation>(8, _omitFieldNames ? '' : 'archivedObservations',
        subBuilder: Observation.create)
    ..pPM<CompressedMemory>(9, _omitFieldNames ? '' : 'memories',
        subBuilder: CompressedMemory.create)
    ..pPM<SessionSummary>(10, _omitFieldNames ? '' : 'summaries',
        subBuilder: SessionSummary.create)
    ..aD(11, _omitFieldNames ? '' : 'contextUsageEstimate')
    ..aI(12, _omitFieldNames ? '' : 'promptCount')
    ..aI(13, _omitFieldNames ? '' : 'observationCount')
    ..aI(14, _omitFieldNames ? '' : 'compressedMemoryCount')
    ..aI(15, _omitFieldNames ? '' : 'summaryCount')
    ..aOM<$1.Timestamp>(16, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(17, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session copyWith(void Function(Session) updates) =>
      super.copyWith((message) => updates(message as Session)) as Session;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Session create() => Session._();
  @$core.override
  Session createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Session getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Session>(create);
  static Session? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  SessionStatus get status => $_getN(3);
  @$pb.TagNumber(4)
  set status(SessionStatus value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get goals => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<Prompt> get prompts => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<Observation> get activeObservations => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<Observation> get archivedObservations => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<CompressedMemory> get memories => $_getList(8);

  @$pb.TagNumber(10)
  $pb.PbList<SessionSummary> get summaries => $_getList(9);

  /// Share of the context budget the session would spend, between 0 and 1.
  @$pb.TagNumber(11)
  $core.double get contextUsageEstimate => $_getN(10);
  @$pb.TagNumber(11)
  set contextUsageEstimate($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasContextUsageEstimate() => $_has(10);
  @$pb.TagNumber(11)
  void clearContextUsageEstimate() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get promptCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set promptCount($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPromptCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearPromptCount() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get observationCount => $_getIZ(12);
  @$pb.TagNumber(13)
  set observationCount($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasObservationCount() => $_has(12);
  @$pb.TagNumber(13)
  void clearObservationCount() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get compressedMemoryCount => $_getIZ(13);
  @$pb.TagNumber(14)
  set compressedMemoryCount($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCompressedMemoryCount() => $_has(13);
  @$pb.TagNumber(14)
  void clearCompressedMemoryCount() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get summaryCount => $_getIZ(14);
  @$pb.TagNumber(15)
  set summaryCount($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasSummaryCount() => $_has(14);
  @$pb.TagNumber(15)
  void clearSummaryCount() => $_clearField(15);

  @$pb.TagNumber(16)
  $1.Timestamp get createdAt => $_getN(15);
  @$pb.TagNumber(16)
  set createdAt($1.Timestamp value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasCreatedAt() => $_has(15);
  @$pb.TagNumber(16)
  void clearCreatedAt() => $_clearField(16);
  @$pb.TagNumber(16)
  $1.Timestamp ensureCreatedAt() => $_ensure(15);

  @$pb.TagNumber(17)
  $1.Timestamp get updatedAt => $_getN(16);
  @$pb.TagNumber(17)
  set updatedAt($1.Timestamp value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasUpdatedAt() => $_has(16);
  @$pb.TagNumber(17)
  void clearUpdatedAt() => $_clearField(17);
  @$pb.TagNumber(17)
  $1.Timestamp ensureUpdatedAt() => $_ensure(16);
}

/// SearchResult is a hit in the index, which is deliberately not the observation
/// itself: a caller filters on these and then fetches what it wants in full
/// through GetObservations.
class SearchResult extends $pb.GeneratedMessage {
  factory SearchResult({
    $core.String? docId,
    $core.String? sessionId,
    $core.String? refId,
    $core.String? kind,
    $core.String? project,
    $core.String? source,
    MemoryLayer? layer,
    MemoryCategory? category,
    $core.String? type,
    $core.String? title,
    $core.String? snippet,
    $core.double? score,
    $core.double? textScore,
    $core.double? vectorScore,
    $1.Timestamp? createdAt,
  }) {
    final result = create();
    if (docId != null) result.docId = docId;
    if (sessionId != null) result.sessionId = sessionId;
    if (refId != null) result.refId = refId;
    if (kind != null) result.kind = kind;
    if (project != null) result.project = project;
    if (source != null) result.source = source;
    if (layer != null) result.layer = layer;
    if (category != null) result.category = category;
    if (type != null) result.type = type;
    if (title != null) result.title = title;
    if (snippet != null) result.snippet = snippet;
    if (score != null) result.score = score;
    if (textScore != null) result.textScore = textScore;
    if (vectorScore != null) result.vectorScore = vectorScore;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  SearchResult._();

  factory SearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResult',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'docId')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOS(3, _omitFieldNames ? '' : 'refId')
    ..aOS(4, _omitFieldNames ? '' : 'kind')
    ..aOS(5, _omitFieldNames ? '' : 'project')
    ..aOS(6, _omitFieldNames ? '' : 'source')
    ..aE<MemoryLayer>(7, _omitFieldNames ? '' : 'layer',
        enumValues: MemoryLayer.values)
    ..aE<MemoryCategory>(8, _omitFieldNames ? '' : 'category',
        enumValues: MemoryCategory.values)
    ..aOS(9, _omitFieldNames ? '' : 'type')
    ..aOS(10, _omitFieldNames ? '' : 'title')
    ..aOS(11, _omitFieldNames ? '' : 'snippet')
    ..aD(12, _omitFieldNames ? '' : 'score')
    ..aD(13, _omitFieldNames ? '' : 'textScore')
    ..aD(14, _omitFieldNames ? '' : 'vectorScore')
    ..aOM<$1.Timestamp>(15, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult copyWith(void Function(SearchResult) updates) =>
      super.copyWith((message) => updates(message as SearchResult))
          as SearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResult create() => SearchResult._();
  @$core.override
  SearchResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchResult>(create);
  static SearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  /// Id of the observation or memory the document was built from.
  @$pb.TagNumber(3)
  $core.String get refId => $_getSZ(2);
  @$pb.TagNumber(3)
  set refId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRefId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRefId() => $_clearField(3);

  /// Which of the two it is: "observation" or "memory".
  @$pb.TagNumber(4)
  $core.String get kind => $_getSZ(3);
  @$pb.TagNumber(4)
  set kind($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get project => $_getSZ(4);
  @$pb.TagNumber(5)
  set project($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProject() => $_has(4);
  @$pb.TagNumber(5)
  void clearProject() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get source => $_getSZ(5);
  @$pb.TagNumber(6)
  set source($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSource() => $_has(5);
  @$pb.TagNumber(6)
  void clearSource() => $_clearField(6);

  @$pb.TagNumber(7)
  MemoryLayer get layer => $_getN(6);
  @$pb.TagNumber(7)
  set layer(MemoryLayer value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasLayer() => $_has(6);
  @$pb.TagNumber(7)
  void clearLayer() => $_clearField(7);

  @$pb.TagNumber(8)
  MemoryCategory get category => $_getN(7);
  @$pb.TagNumber(8)
  set category(MemoryCategory value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasCategory() => $_has(7);
  @$pb.TagNumber(8)
  void clearCategory() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get type => $_getSZ(8);
  @$pb.TagNumber(9)
  set type($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasType() => $_has(8);
  @$pb.TagNumber(9)
  void clearType() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get title => $_getSZ(9);
  @$pb.TagNumber(10)
  set title($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTitle() => $_has(9);
  @$pb.TagNumber(10)
  void clearTitle() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get snippet => $_getSZ(10);
  @$pb.TagNumber(11)
  set snippet($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSnippet() => $_has(10);
  @$pb.TagNumber(11)
  void clearSnippet() => $_clearField(11);

  /// score is the merged ranking; the two below are what it was merged from, so
  /// a caller can see whether a hit is lexical or semantic.
  @$pb.TagNumber(12)
  $core.double get score => $_getN(11);
  @$pb.TagNumber(12)
  set score($core.double value) => $_setDouble(11, value);
  @$pb.TagNumber(12)
  $core.bool hasScore() => $_has(11);
  @$pb.TagNumber(12)
  void clearScore() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get textScore => $_getN(12);
  @$pb.TagNumber(13)
  set textScore($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTextScore() => $_has(12);
  @$pb.TagNumber(13)
  void clearTextScore() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get vectorScore => $_getN(13);
  @$pb.TagNumber(14)
  set vectorScore($core.double value) => $_setDouble(13, value);
  @$pb.TagNumber(14)
  $core.bool hasVectorScore() => $_has(13);
  @$pb.TagNumber(14)
  void clearVectorScore() => $_clearField(14);

  @$pb.TagNumber(15)
  $1.Timestamp get createdAt => $_getN(14);
  @$pb.TagNumber(15)
  set createdAt($1.Timestamp value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasCreatedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearCreatedAt() => $_clearField(15);
  @$pb.TagNumber(15)
  $1.Timestamp ensureCreatedAt() => $_ensure(14);
}

/// ToolDefinition describes a retrieval tool to a model, so a prompt can tell it
/// how to ask for more instead of being handed everything up front.
class ToolDefinition extends $pb.GeneratedMessage {
  factory ToolDefinition({
    $core.String? name,
    $core.String? description,
    $core.String? jsonShape,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (jsonShape != null) result.jsonShape = jsonShape;
    return result;
  }

  ToolDefinition._();

  factory ToolDefinition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ToolDefinition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolDefinition',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'jsonShape')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolDefinition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolDefinition copyWith(void Function(ToolDefinition) updates) =>
      super.copyWith((message) => updates(message as ToolDefinition))
          as ToolDefinition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ToolDefinition create() => ToolDefinition._();
  @$core.override
  ToolDefinition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ToolDefinition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ToolDefinition>(create);
  static ToolDefinition? _defaultInstance;

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
  $core.String get jsonShape => $_getSZ(2);
  @$pb.TagNumber(3)
  set jsonShape($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasJsonShape() => $_has(2);
  @$pb.TagNumber(3)
  void clearJsonShape() => $_clearField(3);
}

/// ContextEnvelope is what gets injected into a prompt: the recall block itself,
/// what it was built from, and what it cost of the budget.
class ContextEnvelope extends $pb.GeneratedMessage {
  factory ContextEnvelope({
    $core.String? sessionId,
    $core.String? query,
    $core.int? budgetTokens,
    $core.int? usedTokens,
    $core.String? injectionPrompt,
    $core.Iterable<CompressedMemory>? memories,
    $core.Iterable<Observation>? observations,
    SessionSummary? summary,
    $core.Iterable<ToolDefinition>? toolHints,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (query != null) result.query = query;
    if (budgetTokens != null) result.budgetTokens = budgetTokens;
    if (usedTokens != null) result.usedTokens = usedTokens;
    if (injectionPrompt != null) result.injectionPrompt = injectionPrompt;
    if (memories != null) result.memories.addAll(memories);
    if (observations != null) result.observations.addAll(observations);
    if (summary != null) result.summary = summary;
    if (toolHints != null) result.toolHints.addAll(toolHints);
    return result;
  }

  ContextEnvelope._();

  factory ContextEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextEnvelope',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'query')
    ..aI(3, _omitFieldNames ? '' : 'budgetTokens')
    ..aI(4, _omitFieldNames ? '' : 'usedTokens')
    ..aOS(5, _omitFieldNames ? '' : 'injectionPrompt')
    ..pPM<CompressedMemory>(6, _omitFieldNames ? '' : 'memories',
        subBuilder: CompressedMemory.create)
    ..pPM<Observation>(7, _omitFieldNames ? '' : 'observations',
        subBuilder: Observation.create)
    ..aOM<SessionSummary>(8, _omitFieldNames ? '' : 'summary',
        subBuilder: SessionSummary.create)
    ..pPM<ToolDefinition>(9, _omitFieldNames ? '' : 'toolHints',
        subBuilder: ToolDefinition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextEnvelope copyWith(void Function(ContextEnvelope) updates) =>
      super.copyWith((message) => updates(message as ContextEnvelope))
          as ContextEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextEnvelope create() => ContextEnvelope._();
  @$core.override
  ContextEnvelope createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextEnvelope>(create);
  static ContextEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get budgetTokens => $_getIZ(2);
  @$pb.TagNumber(3)
  set budgetTokens($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBudgetTokens() => $_has(2);
  @$pb.TagNumber(3)
  void clearBudgetTokens() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get usedTokens => $_getIZ(3);
  @$pb.TagNumber(4)
  set usedTokens($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUsedTokens() => $_has(3);
  @$pb.TagNumber(4)
  void clearUsedTokens() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get injectionPrompt => $_getSZ(4);
  @$pb.TagNumber(5)
  set injectionPrompt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInjectionPrompt() => $_has(4);
  @$pb.TagNumber(5)
  void clearInjectionPrompt() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<CompressedMemory> get memories => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<Observation> get observations => $_getList(6);

  @$pb.TagNumber(8)
  SessionSummary get summary => $_getN(7);
  @$pb.TagNumber(8)
  set summary(SessionSummary value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSummary() => $_has(7);
  @$pb.TagNumber(8)
  void clearSummary() => $_clearField(8);
  @$pb.TagNumber(8)
  SessionSummary ensureSummary() => $_ensure(7);

  @$pb.TagNumber(9)
  $pb.PbList<ToolDefinition> get toolHints => $_getList(8);
}

/// An empty session_id opens a new session under a generated id.
class CreateSessionRequest extends $pb.GeneratedMessage {
  factory CreateSessionRequest({
    $core.String? sessionId,
    $core.String? project,
    $core.String? source,
    $core.Iterable<$core.String>? goals,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (project != null) result.project = project;
    if (source != null) result.source = source;
    if (goals != null) result.goals.addAll(goals);
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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..pPS(4, _omitFieldNames ? '' : 'goals')
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
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get goals => $_getList(3);
}

class CreateSessionResponse extends $pb.GeneratedMessage {
  factory CreateSessionResponse({
    Session? session,
  }) {
    final result = create();
    if (session != null) result.session = session;
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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.create)
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
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
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

/// Sessions carry their counts but not their contents. Reading one in full is
/// GetSession.
class ListSessionsResponse extends $pb.GeneratedMessage {
  factory ListSessionsResponse({
    $core.Iterable<Session>? sessions,
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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..pPM<Session>(1, _omitFieldNames ? '' : 'sessions',
        subBuilder: Session.create)
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
  $pb.PbList<Session> get sessions => $_getList(0);
}

class GetSessionRequest extends $pb.GeneratedMessage {
  factory GetSessionRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  GetSessionRequest._();

  factory GetSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSessionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionRequest copyWith(void Function(GetSessionRequest) updates) =>
      super.copyWith((message) => updates(message as GetSessionRequest))
          as GetSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSessionRequest create() => GetSessionRequest._();
  @$core.override
  GetSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSessionRequest>(create);
  static GetSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class GetSessionResponse extends $pb.GeneratedMessage {
  factory GetSessionResponse({
    Session? session,
  }) {
    final result = create();
    if (session != null) result.session = session;
    return result;
  }

  GetSessionResponse._();

  factory GetSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSessionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionResponse copyWith(void Function(GetSessionResponse) updates) =>
      super.copyWith((message) => updates(message as GetSessionResponse))
          as GetSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSessionResponse create() => GetSessionResponse._();
  @$core.override
  GetSessionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSessionResponse>(create);
  static GetSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
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

class AddPromptRequest extends $pb.GeneratedMessage {
  factory AddPromptRequest({
    $core.String? sessionId,
    PromptRole? role,
    $core.String? text,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (role != null) result.role = role;
    if (text != null) result.text = text;
    return result;
  }

  AddPromptRequest._();

  factory AddPromptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddPromptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddPromptRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aE<PromptRole>(2, _omitFieldNames ? '' : 'role',
        enumValues: PromptRole.values)
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPromptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPromptRequest copyWith(void Function(AddPromptRequest) updates) =>
      super.copyWith((message) => updates(message as AddPromptRequest))
          as AddPromptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddPromptRequest create() => AddPromptRequest._();
  @$core.override
  AddPromptRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddPromptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddPromptRequest>(create);
  static AddPromptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  PromptRole get role => $_getN(1);
  @$pb.TagNumber(2)
  set role(PromptRole value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);
}

/// The context is returned with the prompt because that is the point of adding
/// one: the caller gets back what to inject alongside it.
class AddPromptResponse extends $pb.GeneratedMessage {
  factory AddPromptResponse({
    Prompt? prompt,
    ContextEnvelope? context,
  }) {
    final result = create();
    if (prompt != null) result.prompt = prompt;
    if (context != null) result.context = context;
    return result;
  }

  AddPromptResponse._();

  factory AddPromptResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddPromptResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddPromptResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<Prompt>(1, _omitFieldNames ? '' : 'prompt', subBuilder: Prompt.create)
    ..aOM<ContextEnvelope>(2, _omitFieldNames ? '' : 'context',
        subBuilder: ContextEnvelope.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPromptResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPromptResponse copyWith(void Function(AddPromptResponse) updates) =>
      super.copyWith((message) => updates(message as AddPromptResponse))
          as AddPromptResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddPromptResponse create() => AddPromptResponse._();
  @$core.override
  AddPromptResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddPromptResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddPromptResponse>(create);
  static AddPromptResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Prompt get prompt => $_getN(0);
  @$pb.TagNumber(1)
  set prompt(Prompt value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrompt() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrompt() => $_clearField(1);
  @$pb.TagNumber(1)
  Prompt ensurePrompt() => $_ensure(0);

  @$pb.TagNumber(2)
  ContextEnvelope get context => $_getN(1);
  @$pb.TagNumber(2)
  set context(ContextEnvelope value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasContext() => $_has(1);
  @$pb.TagNumber(2)
  void clearContext() => $_clearField(2);
  @$pb.TagNumber(2)
  ContextEnvelope ensureContext() => $_ensure(1);
}

/// Either title or narrative must be set. An observation whose category is
/// CHANGE_REQUEST gets a proposal built from its text if none is given.
class AddObservationRequest extends $pb.GeneratedMessage {
  factory AddObservationRequest({
    $core.String? sessionId,
    $core.String? project,
    $core.String? source,
    MemoryLayer? layer,
    MemoryCategory? category,
    $core.String? type,
    $core.String? title,
    $core.String? narrative,
    ChangeRequestState? changeRequest,
    $core.String? speaker,
    $core.int? dialogueId,
    $core.Iterable<$core.String>? keywords,
    $core.Iterable<$core.String>? persons,
    $core.Iterable<$core.String>? entities,
    $core.String? topic,
    $core.String? location,
    $core.String? validFrom,
    $core.double? importance,
    $core.double? confidence,
    $core.String? supersededBy,
    $core.String? toolName,
    $core.String? sourcePath,
    $core.Iterable<$core.String>? tags,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (project != null) result.project = project;
    if (source != null) result.source = source;
    if (layer != null) result.layer = layer;
    if (category != null) result.category = category;
    if (type != null) result.type = type;
    if (title != null) result.title = title;
    if (narrative != null) result.narrative = narrative;
    if (changeRequest != null) result.changeRequest = changeRequest;
    if (speaker != null) result.speaker = speaker;
    if (dialogueId != null) result.dialogueId = dialogueId;
    if (keywords != null) result.keywords.addAll(keywords);
    if (persons != null) result.persons.addAll(persons);
    if (entities != null) result.entities.addAll(entities);
    if (topic != null) result.topic = topic;
    if (location != null) result.location = location;
    if (validFrom != null) result.validFrom = validFrom;
    if (importance != null) result.importance = importance;
    if (confidence != null) result.confidence = confidence;
    if (supersededBy != null) result.supersededBy = supersededBy;
    if (toolName != null) result.toolName = toolName;
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  AddObservationRequest._();

  factory AddObservationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddObservationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddObservationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aE<MemoryLayer>(4, _omitFieldNames ? '' : 'layer',
        enumValues: MemoryLayer.values)
    ..aE<MemoryCategory>(5, _omitFieldNames ? '' : 'category',
        enumValues: MemoryCategory.values)
    ..aOS(6, _omitFieldNames ? '' : 'type')
    ..aOS(7, _omitFieldNames ? '' : 'title')
    ..aOS(8, _omitFieldNames ? '' : 'narrative')
    ..aOM<ChangeRequestState>(9, _omitFieldNames ? '' : 'changeRequest',
        subBuilder: ChangeRequestState.create)
    ..aOS(10, _omitFieldNames ? '' : 'speaker')
    ..aI(11, _omitFieldNames ? '' : 'dialogueId')
    ..pPS(12, _omitFieldNames ? '' : 'keywords')
    ..pPS(13, _omitFieldNames ? '' : 'persons')
    ..pPS(14, _omitFieldNames ? '' : 'entities')
    ..aOS(15, _omitFieldNames ? '' : 'topic')
    ..aOS(16, _omitFieldNames ? '' : 'location')
    ..aOS(17, _omitFieldNames ? '' : 'validFrom')
    ..aD(18, _omitFieldNames ? '' : 'importance')
    ..aD(19, _omitFieldNames ? '' : 'confidence')
    ..aOS(20, _omitFieldNames ? '' : 'supersededBy')
    ..aOS(21, _omitFieldNames ? '' : 'toolName')
    ..aOS(22, _omitFieldNames ? '' : 'sourcePath')
    ..pPS(23, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddObservationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddObservationRequest copyWith(
          void Function(AddObservationRequest) updates) =>
      super.copyWith((message) => updates(message as AddObservationRequest))
          as AddObservationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddObservationRequest create() => AddObservationRequest._();
  @$core.override
  AddObservationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddObservationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddObservationRequest>(create);
  static AddObservationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  MemoryLayer get layer => $_getN(3);
  @$pb.TagNumber(4)
  set layer(MemoryLayer value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLayer() => $_has(3);
  @$pb.TagNumber(4)
  void clearLayer() => $_clearField(4);

  @$pb.TagNumber(5)
  MemoryCategory get category => $_getN(4);
  @$pb.TagNumber(5)
  set category(MemoryCategory value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCategory() => $_has(4);
  @$pb.TagNumber(5)
  void clearCategory() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get type => $_getSZ(5);
  @$pb.TagNumber(6)
  set type($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get title => $_getSZ(6);
  @$pb.TagNumber(7)
  set title($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTitle() => $_has(6);
  @$pb.TagNumber(7)
  void clearTitle() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get narrative => $_getSZ(7);
  @$pb.TagNumber(8)
  set narrative($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNarrative() => $_has(7);
  @$pb.TagNumber(8)
  void clearNarrative() => $_clearField(8);

  @$pb.TagNumber(9)
  ChangeRequestState get changeRequest => $_getN(8);
  @$pb.TagNumber(9)
  set changeRequest(ChangeRequestState value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasChangeRequest() => $_has(8);
  @$pb.TagNumber(9)
  void clearChangeRequest() => $_clearField(9);
  @$pb.TagNumber(9)
  ChangeRequestState ensureChangeRequest() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.String get speaker => $_getSZ(9);
  @$pb.TagNumber(10)
  set speaker($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSpeaker() => $_has(9);
  @$pb.TagNumber(10)
  void clearSpeaker() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get dialogueId => $_getIZ(10);
  @$pb.TagNumber(11)
  set dialogueId($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDialogueId() => $_has(10);
  @$pb.TagNumber(11)
  void clearDialogueId() => $_clearField(11);

  @$pb.TagNumber(12)
  $pb.PbList<$core.String> get keywords => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get persons => $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<$core.String> get entities => $_getList(13);

  @$pb.TagNumber(15)
  $core.String get topic => $_getSZ(14);
  @$pb.TagNumber(15)
  set topic($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasTopic() => $_has(14);
  @$pb.TagNumber(15)
  void clearTopic() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get location => $_getSZ(15);
  @$pb.TagNumber(16)
  set location($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasLocation() => $_has(15);
  @$pb.TagNumber(16)
  void clearLocation() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get validFrom => $_getSZ(16);
  @$pb.TagNumber(17)
  set validFrom($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasValidFrom() => $_has(16);
  @$pb.TagNumber(17)
  void clearValidFrom() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.double get importance => $_getN(17);
  @$pb.TagNumber(18)
  set importance($core.double value) => $_setDouble(17, value);
  @$pb.TagNumber(18)
  $core.bool hasImportance() => $_has(17);
  @$pb.TagNumber(18)
  void clearImportance() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.double get confidence => $_getN(18);
  @$pb.TagNumber(19)
  set confidence($core.double value) => $_setDouble(18, value);
  @$pb.TagNumber(19)
  $core.bool hasConfidence() => $_has(18);
  @$pb.TagNumber(19)
  void clearConfidence() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get supersededBy => $_getSZ(19);
  @$pb.TagNumber(20)
  set supersededBy($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasSupersededBy() => $_has(19);
  @$pb.TagNumber(20)
  void clearSupersededBy() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get toolName => $_getSZ(20);
  @$pb.TagNumber(21)
  set toolName($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasToolName() => $_has(20);
  @$pb.TagNumber(21)
  void clearToolName() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get sourcePath => $_getSZ(21);
  @$pb.TagNumber(22)
  set sourcePath($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasSourcePath() => $_has(21);
  @$pb.TagNumber(22)
  void clearSourcePath() => $_clearField(22);

  @$pb.TagNumber(23)
  $pb.PbList<$core.String> get tags => $_getList(22);
}

/// An observation that repeats one recorded moments ago is not stored twice; the
/// existing one is returned instead.
class AddObservationResponse extends $pb.GeneratedMessage {
  factory AddObservationResponse({
    Observation? observation,
  }) {
    final result = create();
    if (observation != null) result.observation = observation;
    return result;
  }

  AddObservationResponse._();

  factory AddObservationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddObservationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddObservationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<Observation>(1, _omitFieldNames ? '' : 'observation',
        subBuilder: Observation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddObservationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddObservationResponse copyWith(
          void Function(AddObservationResponse) updates) =>
      super.copyWith((message) => updates(message as AddObservationResponse))
          as AddObservationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddObservationResponse create() => AddObservationResponse._();
  @$core.override
  AddObservationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddObservationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddObservationResponse>(create);
  static AddObservationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Observation get observation => $_getN(0);
  @$pb.TagNumber(1)
  set observation(Observation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasObservation() => $_has(0);
  @$pb.TagNumber(1)
  void clearObservation() => $_clearField(1);
  @$pb.TagNumber(1)
  Observation ensureObservation() => $_ensure(0);
}

class CompleteSessionRequest extends $pb.GeneratedMessage {
  factory CompleteSessionRequest({
    $core.String? sessionId,
    $core.Iterable<$core.String>? learned,
    $core.Iterable<$core.String>? completed,
    $core.Iterable<$core.String>? nextSteps,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (learned != null) result.learned.addAll(learned);
    if (completed != null) result.completed.addAll(completed);
    if (nextSteps != null) result.nextSteps.addAll(nextSteps);
    return result;
  }

  CompleteSessionRequest._();

  factory CompleteSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompleteSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteSessionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..pPS(2, _omitFieldNames ? '' : 'learned')
    ..pPS(3, _omitFieldNames ? '' : 'completed')
    ..pPS(4, _omitFieldNames ? '' : 'nextSteps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteSessionRequest copyWith(
          void Function(CompleteSessionRequest) updates) =>
      super.copyWith((message) => updates(message as CompleteSessionRequest))
          as CompleteSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompleteSessionRequest create() => CompleteSessionRequest._();
  @$core.override
  CompleteSessionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompleteSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompleteSessionRequest>(create);
  static CompleteSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get learned => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get completed => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get nextSteps => $_getList(3);
}

class CompleteSessionResponse extends $pb.GeneratedMessage {
  factory CompleteSessionResponse({
    SessionSummary? summary,
  }) {
    final result = create();
    if (summary != null) result.summary = summary;
    return result;
  }

  CompleteSessionResponse._();

  factory CompleteSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompleteSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteSessionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<SessionSummary>(1, _omitFieldNames ? '' : 'summary',
        subBuilder: SessionSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteSessionResponse copyWith(
          void Function(CompleteSessionResponse) updates) =>
      super.copyWith((message) => updates(message as CompleteSessionResponse))
          as CompleteSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompleteSessionResponse create() => CompleteSessionResponse._();
  @$core.override
  CompleteSessionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompleteSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompleteSessionResponse>(create);
  static CompleteSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionSummary get summary => $_getN(0);
  @$pb.TagNumber(1)
  set summary(SessionSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSummary() => $_has(0);
  @$pb.TagNumber(1)
  void clearSummary() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionSummary ensureSummary() => $_ensure(0);
}

/// An empty query lists what the filters match, ordered by recency, instead of
/// searching.
class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    $core.String? query,
    $core.String? project,
    $core.String? source,
    MemoryLayer? layer,
    MemoryCategory? category,
    $core.String? type,
    $core.int? limit,
  }) {
    final result = create();
    if (query != null) result.query = query;
    if (project != null) result.project = project;
    if (source != null) result.source = source;
    if (layer != null) result.layer = layer;
    if (category != null) result.category = category;
    if (type != null) result.type = type;
    if (limit != null) result.limit = limit;
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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aE<MemoryLayer>(4, _omitFieldNames ? '' : 'layer',
        enumValues: MemoryLayer.values)
    ..aE<MemoryCategory>(5, _omitFieldNames ? '' : 'category',
        enumValues: MemoryCategory.values)
    ..aOS(6, _omitFieldNames ? '' : 'type')
    ..aI(7, _omitFieldNames ? '' : 'limit')
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
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  MemoryLayer get layer => $_getN(3);
  @$pb.TagNumber(4)
  set layer(MemoryLayer value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLayer() => $_has(3);
  @$pb.TagNumber(4)
  void clearLayer() => $_clearField(4);

  @$pb.TagNumber(5)
  MemoryCategory get category => $_getN(4);
  @$pb.TagNumber(5)
  set category(MemoryCategory value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCategory() => $_has(4);
  @$pb.TagNumber(5)
  void clearCategory() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get type => $_getSZ(5);
  @$pb.TagNumber(6)
  set type($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => $_clearField(6);

  /// Zero means the default of 10.
  @$pb.TagNumber(7)
  $core.int get limit => $_getIZ(6);
  @$pb.TagNumber(7)
  set limit($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLimit() => $_has(6);
  @$pb.TagNumber(7)
  void clearLimit() => $_clearField(7);
}

class SearchResponse extends $pb.GeneratedMessage {
  factory SearchResponse({
    $core.Iterable<SearchResult>? results,
  }) {
    final result = create();
    if (results != null) result.results.addAll(results);
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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..pPM<SearchResult>(1, _omitFieldNames ? '' : 'results',
        subBuilder: SearchResult.create)
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
  $pb.PbList<SearchResult> get results => $_getList(0);
}

/// Names a point in the session by observation id or by a query that finds one,
/// and reads the neighbours around it.
class GetTimelineRequest extends $pb.GeneratedMessage {
  factory GetTimelineRequest({
    $core.String? sessionId,
    $core.String? observationId,
    $core.String? query,
    $core.int? before,
    $core.int? after,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (observationId != null) result.observationId = observationId;
    if (query != null) result.query = query;
    if (before != null) result.before = before;
    if (after != null) result.after = after;
    return result;
  }

  GetTimelineRequest._();

  factory GetTimelineRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTimelineRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTimelineRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'observationId')
    ..aOS(3, _omitFieldNames ? '' : 'query')
    ..aI(4, _omitFieldNames ? '' : 'before')
    ..aI(5, _omitFieldNames ? '' : 'after')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTimelineRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTimelineRequest copyWith(void Function(GetTimelineRequest) updates) =>
      super.copyWith((message) => updates(message as GetTimelineRequest))
          as GetTimelineRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTimelineRequest create() => GetTimelineRequest._();
  @$core.override
  GetTimelineRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetTimelineRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTimelineRequest>(create);
  static GetTimelineRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get observationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set observationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasObservationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearObservationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get query => $_getSZ(2);
  @$pb.TagNumber(3)
  set query($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQuery() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuery() => $_clearField(3);

  /// How many observations to include on either side. Zero means the default of
  /// two.
  @$pb.TagNumber(4)
  $core.int get before => $_getIZ(3);
  @$pb.TagNumber(4)
  set before($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBefore() => $_has(3);
  @$pb.TagNumber(4)
  void clearBefore() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get after => $_getIZ(4);
  @$pb.TagNumber(5)
  set after($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAfter() => $_has(4);
  @$pb.TagNumber(5)
  void clearAfter() => $_clearField(5);
}

class GetTimelineResponse extends $pb.GeneratedMessage {
  factory GetTimelineResponse({
    $core.Iterable<Observation>? observations,
  }) {
    final result = create();
    if (observations != null) result.observations.addAll(observations);
    return result;
  }

  GetTimelineResponse._();

  factory GetTimelineResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTimelineResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTimelineResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..pPM<Observation>(1, _omitFieldNames ? '' : 'observations',
        subBuilder: Observation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTimelineResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTimelineResponse copyWith(void Function(GetTimelineResponse) updates) =>
      super.copyWith((message) => updates(message as GetTimelineResponse))
          as GetTimelineResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTimelineResponse create() => GetTimelineResponse._();
  @$core.override
  GetTimelineResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetTimelineResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTimelineResponse>(create);
  static GetTimelineResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Observation> get observations => $_getList(0);
}

class GetObservationsRequest extends $pb.GeneratedMessage {
  factory GetObservationsRequest({
    $core.Iterable<$core.String>? ids,
  }) {
    final result = create();
    if (ids != null) result.ids.addAll(ids);
    return result;
  }

  GetObservationsRequest._();

  factory GetObservationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetObservationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetObservationsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'ids')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObservationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObservationsRequest copyWith(
          void Function(GetObservationsRequest) updates) =>
      super.copyWith((message) => updates(message as GetObservationsRequest))
          as GetObservationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetObservationsRequest create() => GetObservationsRequest._();
  @$core.override
  GetObservationsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetObservationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetObservationsRequest>(create);
  static GetObservationsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get ids => $_getList(0);
}

class GetObservationsResponse extends $pb.GeneratedMessage {
  factory GetObservationsResponse({
    $core.Iterable<Observation>? observations,
  }) {
    final result = create();
    if (observations != null) result.observations.addAll(observations);
    return result;
  }

  GetObservationsResponse._();

  factory GetObservationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetObservationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetObservationsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..pPM<Observation>(1, _omitFieldNames ? '' : 'observations',
        subBuilder: Observation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObservationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObservationsResponse copyWith(
          void Function(GetObservationsResponse) updates) =>
      super.copyWith((message) => updates(message as GetObservationsResponse))
          as GetObservationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetObservationsResponse create() => GetObservationsResponse._();
  @$core.override
  GetObservationsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetObservationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetObservationsResponse>(create);
  static GetObservationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Observation> get observations => $_getList(0);
}

class GetContextRequest extends $pb.GeneratedMessage {
  factory GetContextRequest({
    $core.String? sessionId,
    $core.String? query,
    $core.int? limit,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (query != null) result.query = query;
    if (limit != null) result.limit = limit;
    return result;
  }

  GetContextRequest._();

  factory GetContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetContextRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'query')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetContextRequest copyWith(void Function(GetContextRequest) updates) =>
      super.copyWith((message) => updates(message as GetContextRequest))
          as GetContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetContextRequest create() => GetContextRequest._();
  @$core.override
  GetContextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetContextRequest>(create);
  static GetContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Optional. A query focuses recall on what is relevant to it; without one
  /// the most recent memory is used.
  @$pb.TagNumber(2)
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);

  /// Zero means the default of 8.
  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class GetContextResponse extends $pb.GeneratedMessage {
  factory GetContextResponse({
    ContextEnvelope? context,
  }) {
    final result = create();
    if (context != null) result.context = context;
    return result;
  }

  GetContextResponse._();

  factory GetContextResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetContextResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetContextResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<ContextEnvelope>(1, _omitFieldNames ? '' : 'context',
        subBuilder: ContextEnvelope.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetContextResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetContextResponse copyWith(void Function(GetContextResponse) updates) =>
      super.copyWith((message) => updates(message as GetContextResponse))
          as GetContextResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetContextResponse create() => GetContextResponse._();
  @$core.override
  GetContextResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetContextResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetContextResponse>(create);
  static GetContextResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ContextEnvelope get context => $_getN(0);
  @$pb.TagNumber(1)
  set context(ContextEnvelope value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearContext() => $_clearField(1);
  @$pb.TagNumber(1)
  ContextEnvelope ensureContext() => $_ensure(0);
}

class UpdateChangeRequestStatusRequest extends $pb.GeneratedMessage {
  factory UpdateChangeRequestStatusRequest({
    $core.String? observationId,
    ChangeRequestStatus? status,
    $core.String? reasonShort,
  }) {
    final result = create();
    if (observationId != null) result.observationId = observationId;
    if (status != null) result.status = status;
    if (reasonShort != null) result.reasonShort = reasonShort;
    return result;
  }

  UpdateChangeRequestStatusRequest._();

  factory UpdateChangeRequestStatusRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateChangeRequestStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateChangeRequestStatusRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'observationId')
    ..aE<ChangeRequestStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: ChangeRequestStatus.values)
    ..aOS(3, _omitFieldNames ? '' : 'reasonShort')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateChangeRequestStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateChangeRequestStatusRequest copyWith(
          void Function(UpdateChangeRequestStatusRequest) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateChangeRequestStatusRequest))
          as UpdateChangeRequestStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateChangeRequestStatusRequest create() =>
      UpdateChangeRequestStatusRequest._();
  @$core.override
  UpdateChangeRequestStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateChangeRequestStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateChangeRequestStatusRequest>(
          create);
  static UpdateChangeRequestStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get observationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set observationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObservationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObservationId() => $_clearField(1);

  @$pb.TagNumber(2)
  ChangeRequestStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(ChangeRequestStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reasonShort => $_getSZ(2);
  @$pb.TagNumber(3)
  set reasonShort($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReasonShort() => $_has(2);
  @$pb.TagNumber(3)
  void clearReasonShort() => $_clearField(3);
}

class UpdateChangeRequestStatusResponse extends $pb.GeneratedMessage {
  factory UpdateChangeRequestStatusResponse({
    Observation? observation,
  }) {
    final result = create();
    if (observation != null) result.observation = observation;
    return result;
  }

  UpdateChangeRequestStatusResponse._();

  factory UpdateChangeRequestStatusResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateChangeRequestStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateChangeRequestStatusResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<Observation>(1, _omitFieldNames ? '' : 'observation',
        subBuilder: Observation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateChangeRequestStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateChangeRequestStatusResponse copyWith(
          void Function(UpdateChangeRequestStatusResponse) updates) =>
      super.copyWith((message) =>
              updates(message as UpdateChangeRequestStatusResponse))
          as UpdateChangeRequestStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateChangeRequestStatusResponse create() =>
      UpdateChangeRequestStatusResponse._();
  @$core.override
  UpdateChangeRequestStatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateChangeRequestStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateChangeRequestStatusResponse>(
          create);
  static UpdateChangeRequestStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Observation get observation => $_getN(0);
  @$pb.TagNumber(1)
  set observation(Observation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasObservation() => $_has(0);
  @$pb.TagNumber(1)
  void clearObservation() => $_clearField(1);
  @$pb.TagNumber(1)
  Observation ensureObservation() => $_ensure(0);
}

class DeleteObservationRequest extends $pb.GeneratedMessage {
  factory DeleteObservationRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteObservationRequest._();

  factory DeleteObservationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteObservationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteObservationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteObservationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteObservationRequest copyWith(
          void Function(DeleteObservationRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteObservationRequest))
          as DeleteObservationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteObservationRequest create() => DeleteObservationRequest._();
  @$core.override
  DeleteObservationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteObservationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteObservationRequest>(create);
  static DeleteObservationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// An observation already folded into a compressed memory is tombstoned rather
/// than removed, so the memory does not lose what it was built from.
class DeleteObservationResponse extends $pb.GeneratedMessage {
  factory DeleteObservationResponse({
    Observation? observation,
    $core.bool? tombstoned,
  }) {
    final result = create();
    if (observation != null) result.observation = observation;
    if (tombstoned != null) result.tombstoned = tombstoned;
    return result;
  }

  DeleteObservationResponse._();

  factory DeleteObservationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteObservationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteObservationResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<Observation>(1, _omitFieldNames ? '' : 'observation',
        subBuilder: Observation.create)
    ..aOB(2, _omitFieldNames ? '' : 'tombstoned')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteObservationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteObservationResponse copyWith(
          void Function(DeleteObservationResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteObservationResponse))
          as DeleteObservationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteObservationResponse create() => DeleteObservationResponse._();
  @$core.override
  DeleteObservationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteObservationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteObservationResponse>(create);
  static DeleteObservationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Observation get observation => $_getN(0);
  @$pb.TagNumber(1)
  set observation(Observation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasObservation() => $_has(0);
  @$pb.TagNumber(1)
  void clearObservation() => $_clearField(1);
  @$pb.TagNumber(1)
  Observation ensureObservation() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get tombstoned => $_getBF(1);
  @$pb.TagNumber(2)
  set tombstoned($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTombstoned() => $_has(1);
  @$pb.TagNumber(2)
  void clearTombstoned() => $_clearField(2);
}

/// StringList wraps a repeated field so that leaving it out can mean "do not
/// touch this list", which a bare repeated field cannot express.
class StringList extends $pb.GeneratedMessage {
  factory StringList({
    $core.Iterable<$core.String>? values,
  }) {
    final result = create();
    if (values != null) result.values.addAll(values);
    return result;
  }

  StringList._();

  factory StringList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StringList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StringList',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'values')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StringList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StringList copyWith(void Function(StringList) updates) =>
      super.copyWith((message) => updates(message as StringList)) as StringList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StringList create() => StringList._();
  @$core.override
  StringList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StringList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StringList>(create);
  static StringList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get values => $_getList(0);
}

/// Every field is optional and only what is set is written. Editing a memory
/// marks it as corrected by the user, and compression stops overwriting it.
class UpdateMemoryRequest extends $pb.GeneratedMessage {
  factory UpdateMemoryRequest({
    $core.String? id,
    $core.String? summary,
    StringList? learned,
    StringList? openTasks,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (summary != null) result.summary = summary;
    if (learned != null) result.learned = learned;
    if (openTasks != null) result.openTasks = openTasks;
    return result;
  }

  UpdateMemoryRequest._();

  factory UpdateMemoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateMemoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateMemoryRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'summary')
    ..aOM<StringList>(3, _omitFieldNames ? '' : 'learned',
        subBuilder: StringList.create)
    ..aOM<StringList>(4, _omitFieldNames ? '' : 'openTasks',
        subBuilder: StringList.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemoryRequest copyWith(void Function(UpdateMemoryRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateMemoryRequest))
          as UpdateMemoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateMemoryRequest create() => UpdateMemoryRequest._();
  @$core.override
  UpdateMemoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateMemoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateMemoryRequest>(create);
  static UpdateMemoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get summary => $_getSZ(1);
  @$pb.TagNumber(2)
  set summary($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSummary() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummary() => $_clearField(2);

  @$pb.TagNumber(3)
  StringList get learned => $_getN(2);
  @$pb.TagNumber(3)
  set learned(StringList value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLearned() => $_has(2);
  @$pb.TagNumber(3)
  void clearLearned() => $_clearField(3);
  @$pb.TagNumber(3)
  StringList ensureLearned() => $_ensure(2);

  @$pb.TagNumber(4)
  StringList get openTasks => $_getN(3);
  @$pb.TagNumber(4)
  set openTasks(StringList value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOpenTasks() => $_has(3);
  @$pb.TagNumber(4)
  void clearOpenTasks() => $_clearField(4);
  @$pb.TagNumber(4)
  StringList ensureOpenTasks() => $_ensure(3);
}

class UpdateMemoryResponse extends $pb.GeneratedMessage {
  factory UpdateMemoryResponse({
    CompressedMemory? memory,
  }) {
    final result = create();
    if (memory != null) result.memory = memory;
    return result;
  }

  UpdateMemoryResponse._();

  factory UpdateMemoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateMemoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateMemoryResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<CompressedMemory>(1, _omitFieldNames ? '' : 'memory',
        subBuilder: CompressedMemory.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemoryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemoryResponse copyWith(void Function(UpdateMemoryResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateMemoryResponse))
          as UpdateMemoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateMemoryResponse create() => UpdateMemoryResponse._();
  @$core.override
  UpdateMemoryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateMemoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateMemoryResponse>(create);
  static UpdateMemoryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CompressedMemory get memory => $_getN(0);
  @$pb.TagNumber(1)
  set memory(CompressedMemory value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMemory() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemory() => $_clearField(1);
  @$pb.TagNumber(1)
  CompressedMemory ensureMemory() => $_ensure(0);
}

/// One turn of a conversation. Turns are buffered into a window and only
/// condensed into an observation once it is full, so most calls record the turn
/// and return the context unchanged.
class CaptureChatMessageRequest extends $pb.GeneratedMessage {
  factory CaptureChatMessageRequest({
    $core.String? sessionId,
    $core.String? project,
    $core.String? prompt,
    $core.String? reply,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (project != null) result.project = project;
    if (prompt != null) result.prompt = prompt;
    if (reply != null) result.reply = reply;
    return result;
  }

  CaptureChatMessageRequest._();

  factory CaptureChatMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CaptureChatMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureChatMessageRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'prompt')
    ..aOS(4, _omitFieldNames ? '' : 'reply')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureChatMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureChatMessageRequest copyWith(
          void Function(CaptureChatMessageRequest) updates) =>
      super.copyWith((message) => updates(message as CaptureChatMessageRequest))
          as CaptureChatMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CaptureChatMessageRequest create() => CaptureChatMessageRequest._();
  @$core.override
  CaptureChatMessageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CaptureChatMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CaptureChatMessageRequest>(create);
  static CaptureChatMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get prompt => $_getSZ(2);
  @$pb.TagNumber(3)
  set prompt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrompt() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrompt() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reply => $_getSZ(3);
  @$pb.TagNumber(4)
  set reply($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReply() => $_has(3);
  @$pb.TagNumber(4)
  void clearReply() => $_clearField(4);
}

class CaptureChatMessageResponse extends $pb.GeneratedMessage {
  factory CaptureChatMessageResponse({
    ContextEnvelope? context,
  }) {
    final result = create();
    if (context != null) result.context = context;
    return result;
  }

  CaptureChatMessageResponse._();

  factory CaptureChatMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CaptureChatMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureChatMessageResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<ContextEnvelope>(1, _omitFieldNames ? '' : 'context',
        subBuilder: ContextEnvelope.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureChatMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureChatMessageResponse copyWith(
          void Function(CaptureChatMessageResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CaptureChatMessageResponse))
          as CaptureChatMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CaptureChatMessageResponse create() => CaptureChatMessageResponse._();
  @$core.override
  CaptureChatMessageResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CaptureChatMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CaptureChatMessageResponse>(create);
  static CaptureChatMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ContextEnvelope get context => $_getN(0);
  @$pb.TagNumber(1)
  set context(ContextEnvelope value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearContext() => $_clearField(1);
  @$pb.TagNumber(1)
  ContextEnvelope ensureContext() => $_ensure(0);
}

/// An event from elsewhere in the backend. The payload stays dynamic because it
/// is whatever the emitting module put on the bus.
class CaptureEventRequest extends $pb.GeneratedMessage {
  factory CaptureEventRequest({
    $core.String? sessionId,
    $core.String? project,
    $core.String? source,
    $core.String? type,
    $2.Struct? data,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (project != null) result.project = project;
    if (source != null) result.source = source;
    if (type != null) result.type = type;
    if (data != null) result.data = data;
    return result;
  }

  CaptureEventRequest._();

  factory CaptureEventRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CaptureEventRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureEventRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aOS(4, _omitFieldNames ? '' : 'type')
    ..aOM<$2.Struct>(5, _omitFieldNames ? '' : 'data',
        subBuilder: $2.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureEventRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureEventRequest copyWith(void Function(CaptureEventRequest) updates) =>
      super.copyWith((message) => updates(message as CaptureEventRequest))
          as CaptureEventRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CaptureEventRequest create() => CaptureEventRequest._();
  @$core.override
  CaptureEventRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CaptureEventRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CaptureEventRequest>(create);
  static CaptureEventRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get type => $_getSZ(3);
  @$pb.TagNumber(4)
  set type($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Struct get data => $_getN(4);
  @$pb.TagNumber(5)
  set data($2.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasData() => $_has(4);
  @$pb.TagNumber(5)
  void clearData() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Struct ensureData() => $_ensure(4);
}

class CaptureEventResponse extends $pb.GeneratedMessage {
  factory CaptureEventResponse({
    Observation? observation,
  }) {
    final result = create();
    if (observation != null) result.observation = observation;
    return result;
  }

  CaptureEventResponse._();

  factory CaptureEventResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CaptureEventResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureEventResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..aOM<Observation>(1, _omitFieldNames ? '' : 'observation',
        subBuilder: Observation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureEventResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureEventResponse copyWith(void Function(CaptureEventResponse) updates) =>
      super.copyWith((message) => updates(message as CaptureEventResponse))
          as CaptureEventResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CaptureEventResponse create() => CaptureEventResponse._();
  @$core.override
  CaptureEventResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CaptureEventResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CaptureEventResponse>(create);
  static CaptureEventResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Observation get observation => $_getN(0);
  @$pb.TagNumber(1)
  set observation(Observation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasObservation() => $_has(0);
  @$pb.TagNumber(1)
  void clearObservation() => $_clearField(1);
  @$pb.TagNumber(1)
  Observation ensureObservation() => $_ensure(0);
}

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
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
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

enum StreamEventsResponse_Payload {
  session,
  prompt,
  observation,
  memory,
  summary,
  data,
  notSet
}

/// One change to the store. Named after the RPC rather than after what it is,
/// because the schema lint ties a response message to its method.
///
/// The payload is typed where the publisher has a type for it; everything else -
/// the counts behind a compression, an indexing failure - is carried as the JSON
/// object the feed already delivered.
class StreamEventsResponse extends $pb.GeneratedMessage {
  factory StreamEventsResponse({
    $core.String? type,
    $1.Timestamp? timestamp,
    Session? session,
    Prompt? prompt,
    Observation? observation,
    CompressedMemory? memory,
    SessionSummary? summary,
    $2.Struct? data,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (timestamp != null) result.timestamp = timestamp;
    if (session != null) result.session = session;
    if (prompt != null) result.prompt = prompt;
    if (observation != null) result.observation = observation;
    if (memory != null) result.memory = memory;
    if (summary != null) result.summary = summary;
    if (data != null) result.data = data;
    return result;
  }

  StreamEventsResponse._();

  factory StreamEventsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamEventsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, StreamEventsResponse_Payload>
      _StreamEventsResponse_PayloadByTag = {
    3: StreamEventsResponse_Payload.session,
    4: StreamEventsResponse_Payload.prompt,
    5: StreamEventsResponse_Payload.observation,
    6: StreamEventsResponse_Payload.memory,
    7: StreamEventsResponse_Payload.summary,
    8: StreamEventsResponse_Payload.data,
    0: StreamEventsResponse_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamEventsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.memory.v1'),
      createEmptyInstance: create)
    ..oo(0, [3, 4, 5, 6, 7, 8])
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'timestamp',
        subBuilder: $1.Timestamp.create)
    ..aOM<Session>(3, _omitFieldNames ? '' : 'session',
        subBuilder: Session.create)
    ..aOM<Prompt>(4, _omitFieldNames ? '' : 'prompt', subBuilder: Prompt.create)
    ..aOM<Observation>(5, _omitFieldNames ? '' : 'observation',
        subBuilder: Observation.create)
    ..aOM<CompressedMemory>(6, _omitFieldNames ? '' : 'memory',
        subBuilder: CompressedMemory.create)
    ..aOM<SessionSummary>(7, _omitFieldNames ? '' : 'summary',
        subBuilder: SessionSummary.create)
    ..aOM<$2.Struct>(8, _omitFieldNames ? '' : 'data',
        subBuilder: $2.Struct.create)
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

  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  StreamEventsResponse_Payload whichPayload() =>
      _StreamEventsResponse_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get timestamp => $_getN(1);
  @$pb.TagNumber(2)
  set timestamp($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureTimestamp() => $_ensure(1);

  @$pb.TagNumber(3)
  Session get session => $_getN(2);
  @$pb.TagNumber(3)
  set session(Session value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSession() => $_has(2);
  @$pb.TagNumber(3)
  void clearSession() => $_clearField(3);
  @$pb.TagNumber(3)
  Session ensureSession() => $_ensure(2);

  @$pb.TagNumber(4)
  Prompt get prompt => $_getN(3);
  @$pb.TagNumber(4)
  set prompt(Prompt value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPrompt() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrompt() => $_clearField(4);
  @$pb.TagNumber(4)
  Prompt ensurePrompt() => $_ensure(3);

  @$pb.TagNumber(5)
  Observation get observation => $_getN(4);
  @$pb.TagNumber(5)
  set observation(Observation value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasObservation() => $_has(4);
  @$pb.TagNumber(5)
  void clearObservation() => $_clearField(5);
  @$pb.TagNumber(5)
  Observation ensureObservation() => $_ensure(4);

  @$pb.TagNumber(6)
  CompressedMemory get memory => $_getN(5);
  @$pb.TagNumber(6)
  set memory(CompressedMemory value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMemory() => $_has(5);
  @$pb.TagNumber(6)
  void clearMemory() => $_clearField(6);
  @$pb.TagNumber(6)
  CompressedMemory ensureMemory() => $_ensure(5);

  @$pb.TagNumber(7)
  SessionSummary get summary => $_getN(6);
  @$pb.TagNumber(7)
  set summary(SessionSummary value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSummary() => $_has(6);
  @$pb.TagNumber(7)
  void clearSummary() => $_clearField(7);
  @$pb.TagNumber(7)
  SessionSummary ensureSummary() => $_ensure(6);

  @$pb.TagNumber(8)
  $2.Struct get data => $_getN(7);
  @$pb.TagNumber(8)
  set data($2.Struct value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasData() => $_has(7);
  @$pb.TagNumber(8)
  void clearData() => $_clearField(8);
  @$pb.TagNumber(8)
  $2.Struct ensureData() => $_ensure(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
