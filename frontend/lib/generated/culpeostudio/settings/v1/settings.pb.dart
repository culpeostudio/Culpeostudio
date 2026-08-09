// This is a generated file - do not edit.
//
// Generated from culpeostudio/settings/v1/settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../hardware/v1/hardware.pb.dart' as $1;
import 'settings.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'settings.pbenum.dart';

/// Settings is what the client may see. The provider tokens themselves never
/// leave the backend - only whether one is stored.
class Settings extends $pb.GeneratedMessage {
  factory Settings({
    $core.String? modelDir,
    $core.bool? modelDirValid,
    $core.String? modelDirError,
    $core.bool? huggingfaceTokenSet,
    $core.bool? openrouterTokenSet,
    $core.bool? featherlessTokenSet,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? shortcuts,
    $fixnum.Int64? engineRamReserveBytes,
    $fixnum.Int64? engineGpuReserveBytes,
  }) {
    final result = create();
    if (modelDir != null) result.modelDir = modelDir;
    if (modelDirValid != null) result.modelDirValid = modelDirValid;
    if (modelDirError != null) result.modelDirError = modelDirError;
    if (huggingfaceTokenSet != null)
      result.huggingfaceTokenSet = huggingfaceTokenSet;
    if (openrouterTokenSet != null)
      result.openrouterTokenSet = openrouterTokenSet;
    if (featherlessTokenSet != null)
      result.featherlessTokenSet = featherlessTokenSet;
    if (shortcuts != null) result.shortcuts.addEntries(shortcuts);
    if (engineRamReserveBytes != null)
      result.engineRamReserveBytes = engineRamReserveBytes;
    if (engineGpuReserveBytes != null)
      result.engineGpuReserveBytes = engineGpuReserveBytes;
    return result;
  }

  Settings._();

  factory Settings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Settings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Settings',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelDir')
    ..aOB(2, _omitFieldNames ? '' : 'modelDirValid')
    ..aOS(3, _omitFieldNames ? '' : 'modelDirError')
    ..aOB(4, _omitFieldNames ? '' : 'huggingfaceTokenSet')
    ..aOB(5, _omitFieldNames ? '' : 'openrouterTokenSet')
    ..aOB(6, _omitFieldNames ? '' : 'featherlessTokenSet')
    ..m<$core.String, $core.String>(7, _omitFieldNames ? '' : 'shortcuts',
        entryClassName: 'Settings.ShortcutsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('culpeostudio.settings.v1'))
    ..aInt64(8, _omitFieldNames ? '' : 'engineRamReserveBytes')
    ..aInt64(9, _omitFieldNames ? '' : 'engineGpuReserveBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Settings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Settings copyWith(void Function(Settings) updates) =>
      super.copyWith((message) => updates(message as Settings)) as Settings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Settings create() => Settings._();
  @$core.override
  Settings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Settings getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Settings>(create);
  static Settings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelDir => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelDir($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelDir() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelDir() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get modelDirValid => $_getBF(1);
  @$pb.TagNumber(2)
  set modelDirValid($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelDirValid() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelDirValid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get modelDirError => $_getSZ(2);
  @$pb.TagNumber(3)
  set modelDirError($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModelDirError() => $_has(2);
  @$pb.TagNumber(3)
  void clearModelDirError() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get huggingfaceTokenSet => $_getBF(3);
  @$pb.TagNumber(4)
  set huggingfaceTokenSet($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHuggingfaceTokenSet() => $_has(3);
  @$pb.TagNumber(4)
  void clearHuggingfaceTokenSet() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get openrouterTokenSet => $_getBF(4);
  @$pb.TagNumber(5)
  set openrouterTokenSet($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOpenrouterTokenSet() => $_has(4);
  @$pb.TagNumber(5)
  void clearOpenrouterTokenSet() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get featherlessTokenSet => $_getBF(5);
  @$pb.TagNumber(6)
  set featherlessTokenSet($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFeatherlessTokenSet() => $_has(5);
  @$pb.TagNumber(6)
  void clearFeatherlessTokenSet() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, $core.String> get shortcuts => $_getMap(6);

  /// Optional so an unconfigured reserve stays distinguishable from a reserve
  /// deliberately set to zero.
  @$pb.TagNumber(8)
  $fixnum.Int64 get engineRamReserveBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set engineRamReserveBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEngineRamReserveBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearEngineRamReserveBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get engineGpuReserveBytes => $_getI64(8);
  @$pb.TagNumber(9)
  set engineGpuReserveBytes($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEngineGpuReserveBytes() => $_has(8);
  @$pb.TagNumber(9)
  void clearEngineGpuReserveBytes() => $_clearField(9);
}

class GetSettingsRequest extends $pb.GeneratedMessage {
  factory GetSettingsRequest() => create();

  GetSettingsRequest._();

  factory GetSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSettingsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSettingsRequest copyWith(void Function(GetSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as GetSettingsRequest))
          as GetSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSettingsRequest create() => GetSettingsRequest._();
  @$core.override
  GetSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSettingsRequest>(create);
  static GetSettingsRequest? _defaultInstance;
}

class GetSettingsResponse extends $pb.GeneratedMessage {
  factory GetSettingsResponse({
    Settings? settings,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    return result;
  }

  GetSettingsResponse._();

  factory GetSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSettingsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..aOM<Settings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: Settings.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSettingsResponse copyWith(void Function(GetSettingsResponse) updates) =>
      super.copyWith((message) => updates(message as GetSettingsResponse))
          as GetSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSettingsResponse create() => GetSettingsResponse._();
  @$core.override
  GetSettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSettingsResponse>(create);
  static GetSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Settings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(Settings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  Settings ensureSettings() => $_ensure(0);
}

/// Every changeable field is optional: an absent field is left untouched, which
/// is what the nil pointers in the JSON body used to express.
class UpdateSettingsRequest extends $pb.GeneratedMessage {
  factory UpdateSettingsRequest({
    $core.String? modelDir,
    $core.String? huggingfaceToken,
    $core.String? openrouterToken,
    $core.String? featherlessToken,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? shortcuts,
    $fixnum.Int64? engineRamReserveBytes,
    $fixnum.Int64? engineGpuReserveBytes,
    $core.bool? resetEngineReserves,
  }) {
    final result = create();
    if (modelDir != null) result.modelDir = modelDir;
    if (huggingfaceToken != null) result.huggingfaceToken = huggingfaceToken;
    if (openrouterToken != null) result.openrouterToken = openrouterToken;
    if (featherlessToken != null) result.featherlessToken = featherlessToken;
    if (shortcuts != null) result.shortcuts.addEntries(shortcuts);
    if (engineRamReserveBytes != null)
      result.engineRamReserveBytes = engineRamReserveBytes;
    if (engineGpuReserveBytes != null)
      result.engineGpuReserveBytes = engineGpuReserveBytes;
    if (resetEngineReserves != null)
      result.resetEngineReserves = resetEngineReserves;
    return result;
  }

  UpdateSettingsRequest._();

  factory UpdateSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSettingsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelDir')
    ..aOS(2, _omitFieldNames ? '' : 'huggingfaceToken')
    ..aOS(3, _omitFieldNames ? '' : 'openrouterToken')
    ..aOS(4, _omitFieldNames ? '' : 'featherlessToken')
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'shortcuts',
        entryClassName: 'UpdateSettingsRequest.ShortcutsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('culpeostudio.settings.v1'))
    ..aInt64(6, _omitFieldNames ? '' : 'engineRamReserveBytes')
    ..aInt64(7, _omitFieldNames ? '' : 'engineGpuReserveBytes')
    ..aOB(8, _omitFieldNames ? '' : 'resetEngineReserves')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSettingsRequest copyWith(
          void Function(UpdateSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateSettingsRequest))
          as UpdateSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSettingsRequest create() => UpdateSettingsRequest._();
  @$core.override
  UpdateSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSettingsRequest>(create);
  static UpdateSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelDir => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelDir($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelDir() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelDir() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get huggingfaceToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set huggingfaceToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHuggingfaceToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearHuggingfaceToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get openrouterToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set openrouterToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOpenrouterToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearOpenrouterToken() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get featherlessToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set featherlessToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFeatherlessToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearFeatherlessToken() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get shortcuts => $_getMap(4);

  @$pb.TagNumber(6)
  $fixnum.Int64 get engineRamReserveBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set engineRamReserveBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEngineRamReserveBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearEngineRamReserveBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get engineGpuReserveBytes => $_getI64(6);
  @$pb.TagNumber(7)
  set engineGpuReserveBytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEngineGpuReserveBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearEngineGpuReserveBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get resetEngineReserves => $_getBF(7);
  @$pb.TagNumber(8)
  set resetEngineReserves($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasResetEngineReserves() => $_has(7);
  @$pb.TagNumber(8)
  void clearResetEngineReserves() => $_clearField(8);
}

class UpdateSettingsResponse extends $pb.GeneratedMessage {
  factory UpdateSettingsResponse({
    Settings? settings,
    $core.String? message,
    $core.Iterable<$core.String>? warnings,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    if (message != null) result.message = message;
    if (warnings != null) result.warnings.addAll(warnings);
    return result;
  }

  UpdateSettingsResponse._();

  factory UpdateSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSettingsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..aOM<Settings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: Settings.create)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPS(3, _omitFieldNames ? '' : 'warnings')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSettingsResponse copyWith(
          void Function(UpdateSettingsResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateSettingsResponse))
          as UpdateSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSettingsResponse create() => UpdateSettingsResponse._();
  @$core.override
  UpdateSettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSettingsResponse>(create);
  static UpdateSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Settings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(Settings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  Settings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  /// Reserve sizes that were accepted but leave little room for models.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get warnings => $_getList(2);
}

class GetSystemInfoRequest extends $pb.GeneratedMessage {
  factory GetSystemInfoRequest() => create();

  GetSystemInfoRequest._();

  factory GetSystemInfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSystemInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSystemInfoRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSystemInfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSystemInfoRequest copyWith(void Function(GetSystemInfoRequest) updates) =>
      super.copyWith((message) => updates(message as GetSystemInfoRequest))
          as GetSystemInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSystemInfoRequest create() => GetSystemInfoRequest._();
  @$core.override
  GetSystemInfoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSystemInfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSystemInfoRequest>(create);
  static GetSystemInfoRequest? _defaultInstance;
}

class GetSystemInfoResponse extends $pb.GeneratedMessage {
  factory GetSystemInfoResponse({
    $1.HardwareProfile? profile,
  }) {
    final result = create();
    if (profile != null) result.profile = profile;
    return result;
  }

  GetSystemInfoResponse._();

  factory GetSystemInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSystemInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSystemInfoResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..aOM<$1.HardwareProfile>(1, _omitFieldNames ? '' : 'profile',
        subBuilder: $1.HardwareProfile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSystemInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSystemInfoResponse copyWith(
          void Function(GetSystemInfoResponse) updates) =>
      super.copyWith((message) => updates(message as GetSystemInfoResponse))
          as GetSystemInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSystemInfoResponse create() => GetSystemInfoResponse._();
  @$core.override
  GetSystemInfoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSystemInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSystemInfoResponse>(create);
  static GetSystemInfoResponse? _defaultInstance;

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

class TestProviderRequest extends $pb.GeneratedMessage {
  factory TestProviderRequest({
    Provider? provider,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    return result;
  }

  TestProviderRequest._();

  factory TestProviderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestProviderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestProviderRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..aE<Provider>(1, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestProviderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestProviderRequest copyWith(void Function(TestProviderRequest) updates) =>
      super.copyWith((message) => updates(message as TestProviderRequest))
          as TestProviderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestProviderRequest create() => TestProviderRequest._();
  @$core.override
  TestProviderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestProviderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestProviderRequest>(create);
  static TestProviderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Provider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(Provider value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);
}

class TestProviderResponse extends $pb.GeneratedMessage {
  factory TestProviderResponse({
    Provider? provider,
    $core.bool? reachable,
    $core.String? message,
  }) {
    final result = create();
    if (provider != null) result.provider = provider;
    if (reachable != null) result.reachable = reachable;
    if (message != null) result.message = message;
    return result;
  }

  TestProviderResponse._();

  factory TestProviderResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestProviderResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestProviderResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.settings.v1'),
      createEmptyInstance: create)
    ..aE<Provider>(1, _omitFieldNames ? '' : 'provider',
        enumValues: Provider.values)
    ..aOB(2, _omitFieldNames ? '' : 'reachable')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestProviderResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestProviderResponse copyWith(void Function(TestProviderResponse) updates) =>
      super.copyWith((message) => updates(message as TestProviderResponse))
          as TestProviderResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestProviderResponse create() => TestProviderResponse._();
  @$core.override
  TestProviderResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestProviderResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestProviderResponse>(create);
  static TestProviderResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Provider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(Provider value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get reachable => $_getBF(1);
  @$pb.TagNumber(2)
  set reachable($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReachable() => $_has(1);
  @$pb.TagNumber(2)
  void clearReachable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
