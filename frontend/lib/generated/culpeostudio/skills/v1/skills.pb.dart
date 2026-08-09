// This is a generated file - do not edit.
//
// Generated from culpeostudio/skills/v1/skills.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListSkillsRequest extends $pb.GeneratedMessage {
  factory ListSkillsRequest() => create();

  ListSkillsRequest._();

  factory ListSkillsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSkillsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSkillsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsRequest copyWith(void Function(ListSkillsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSkillsRequest))
          as ListSkillsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSkillsRequest create() => ListSkillsRequest._();
  @$core.override
  ListSkillsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSkillsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSkillsRequest>(create);
  static ListSkillsRequest? _defaultInstance;
}

class ListSkillsResponse extends $pb.GeneratedMessage {
  factory ListSkillsResponse({
    $core.Iterable<SkillRecord>? skills,
    $core.int? count,
  }) {
    final result = create();
    if (skills != null) result.skills.addAll(skills);
    if (count != null) result.count = count;
    return result;
  }

  ListSkillsResponse._();

  factory ListSkillsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSkillsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSkillsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
      createEmptyInstance: create)
    ..pPM<SkillRecord>(1, _omitFieldNames ? '' : 'skills',
        subBuilder: SkillRecord.create)
    ..aI(2, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsResponse copyWith(void Function(ListSkillsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSkillsResponse))
          as ListSkillsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSkillsResponse create() => ListSkillsResponse._();
  @$core.override
  ListSkillsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSkillsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSkillsResponse>(create);
  static ListSkillsResponse? _defaultInstance;

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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
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

class ImportSkillResponse extends $pb.GeneratedMessage {
  factory ImportSkillResponse({
    SkillRecord? skill,
    $core.String? message,
  }) {
    final result = create();
    if (skill != null) result.skill = skill;
    if (message != null) result.message = message;
    return result;
  }

  ImportSkillResponse._();

  factory ImportSkillResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportSkillResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportSkillResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
      createEmptyInstance: create)
    ..aOM<SkillRecord>(1, _omitFieldNames ? '' : 'skill',
        subBuilder: SkillRecord.create)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportSkillResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportSkillResponse copyWith(void Function(ImportSkillResponse) updates) =>
      super.copyWith((message) => updates(message as ImportSkillResponse))
          as ImportSkillResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportSkillResponse create() => ImportSkillResponse._();
  @$core.override
  ImportSkillResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportSkillResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportSkillResponse>(create);
  static ImportSkillResponse? _defaultInstance;

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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
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

class UpdateSkillResponse extends $pb.GeneratedMessage {
  factory UpdateSkillResponse({
    SkillRecord? skill,
    $core.String? message,
  }) {
    final result = create();
    if (skill != null) result.skill = skill;
    if (message != null) result.message = message;
    return result;
  }

  UpdateSkillResponse._();

  factory UpdateSkillResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSkillResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSkillResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
      createEmptyInstance: create)
    ..aOM<SkillRecord>(1, _omitFieldNames ? '' : 'skill',
        subBuilder: SkillRecord.create)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSkillResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSkillResponse copyWith(void Function(UpdateSkillResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateSkillResponse))
          as UpdateSkillResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSkillResponse create() => UpdateSkillResponse._();
  @$core.override
  UpdateSkillResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateSkillResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSkillResponse>(create);
  static UpdateSkillResponse? _defaultInstance;

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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
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

class RescanSkillsRequest extends $pb.GeneratedMessage {
  factory RescanSkillsRequest() => create();

  RescanSkillsRequest._();

  factory RescanSkillsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RescanSkillsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RescanSkillsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanSkillsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanSkillsRequest copyWith(void Function(RescanSkillsRequest) updates) =>
      super.copyWith((message) => updates(message as RescanSkillsRequest))
          as RescanSkillsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RescanSkillsRequest create() => RescanSkillsRequest._();
  @$core.override
  RescanSkillsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RescanSkillsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RescanSkillsRequest>(create);
  static RescanSkillsRequest? _defaultInstance;
}

class RescanSkillsResponse extends $pb.GeneratedMessage {
  factory RescanSkillsResponse({
    $core.Iterable<SkillRecord>? skills,
    $core.int? count,
  }) {
    final result = create();
    if (skills != null) result.skills.addAll(skills);
    if (count != null) result.count = count;
    return result;
  }

  RescanSkillsResponse._();

  factory RescanSkillsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RescanSkillsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RescanSkillsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
      createEmptyInstance: create)
    ..pPM<SkillRecord>(1, _omitFieldNames ? '' : 'skills',
        subBuilder: SkillRecord.create)
    ..aI(2, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanSkillsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RescanSkillsResponse copyWith(void Function(RescanSkillsResponse) updates) =>
      super.copyWith((message) => updates(message as RescanSkillsResponse))
          as RescanSkillsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RescanSkillsResponse create() => RescanSkillsResponse._();
  @$core.override
  RescanSkillsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RescanSkillsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RescanSkillsResponse>(create);
  static RescanSkillsResponse? _defaultInstance;

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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.skills.v1'),
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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
