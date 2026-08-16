// This is a generated file - do not edit.
//
// Generated from culpeostudio/providers/v1/providers.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'providers.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'providers.pbenum.dart';

class ProviderPreset extends $pb.GeneratedMessage {
  factory ProviderPreset({
    $core.String? id,
    $core.String? name,
    $core.String? description,
    ConnectionProtocol? protocol,
    $core.String? defaultBaseUrl,
    $core.String? documentationUrl,
    $core.bool? apiKeyRequired,
    $core.bool? available,
    $core.String? unavailableReason,
    $core.bool? localOnly,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (protocol != null) result.protocol = protocol;
    if (defaultBaseUrl != null) result.defaultBaseUrl = defaultBaseUrl;
    if (documentationUrl != null) result.documentationUrl = documentationUrl;
    if (apiKeyRequired != null) result.apiKeyRequired = apiKeyRequired;
    if (available != null) result.available = available;
    if (unavailableReason != null) result.unavailableReason = unavailableReason;
    if (localOnly != null) result.localOnly = localOnly;
    return result;
  }

  ProviderPreset._();

  factory ProviderPreset.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProviderPreset.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProviderPreset',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aE<ConnectionProtocol>(4, _omitFieldNames ? '' : 'protocol',
        enumValues: ConnectionProtocol.values)
    ..aOS(5, _omitFieldNames ? '' : 'defaultBaseUrl')
    ..aOS(6, _omitFieldNames ? '' : 'documentationUrl')
    ..aOB(7, _omitFieldNames ? '' : 'apiKeyRequired')
    ..aOB(8, _omitFieldNames ? '' : 'available')
    ..aOS(9, _omitFieldNames ? '' : 'unavailableReason')
    ..aOB(10, _omitFieldNames ? '' : 'localOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProviderPreset clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProviderPreset copyWith(void Function(ProviderPreset) updates) =>
      super.copyWith((message) => updates(message as ProviderPreset))
          as ProviderPreset;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProviderPreset create() => ProviderPreset._();
  @$core.override
  ProviderPreset createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProviderPreset getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProviderPreset>(create);
  static ProviderPreset? _defaultInstance;

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
  ConnectionProtocol get protocol => $_getN(3);
  @$pb.TagNumber(4)
  set protocol(ConnectionProtocol value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasProtocol() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtocol() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get defaultBaseUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set defaultBaseUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDefaultBaseUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearDefaultBaseUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get documentationUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set documentationUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDocumentationUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearDocumentationUrl() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get apiKeyRequired => $_getBF(6);
  @$pb.TagNumber(7)
  set apiKeyRequired($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasApiKeyRequired() => $_has(6);
  @$pb.TagNumber(7)
  void clearApiKeyRequired() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get available => $_getBF(7);
  @$pb.TagNumber(8)
  set available($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAvailable() => $_has(7);
  @$pb.TagNumber(8)
  void clearAvailable() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get unavailableReason => $_getSZ(8);
  @$pb.TagNumber(9)
  set unavailableReason($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUnavailableReason() => $_has(8);
  @$pb.TagNumber(9)
  void clearUnavailableReason() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get localOnly => $_getBF(9);
  @$pb.TagNumber(10)
  set localOnly($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLocalOnly() => $_has(9);
  @$pb.TagNumber(10)
  void clearLocalOnly() => $_clearField(10);
}

/// ProviderConnection is always safe to return to the Flutter client.  The
/// API key is intentionally absent; api_key_set merely drives the UI state.
class ProviderConnection extends $pb.GeneratedMessage {
  factory ProviderConnection({
    $core.String? id,
    $core.String? presetId,
    $core.String? name,
    ConnectionProtocol? protocol,
    $core.String? baseUrl,
    $core.bool? apiKeySet,
    $core.bool? enabled,
    $core.int? modelCount,
    $1.Timestamp? lastSyncedAt,
    $core.String? lastSyncError,
    $core.bool? chatSupported,
    $core.bool? stale,
    $core.String? providerLabel,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (presetId != null) result.presetId = presetId;
    if (name != null) result.name = name;
    if (protocol != null) result.protocol = protocol;
    if (baseUrl != null) result.baseUrl = baseUrl;
    if (apiKeySet != null) result.apiKeySet = apiKeySet;
    if (enabled != null) result.enabled = enabled;
    if (modelCount != null) result.modelCount = modelCount;
    if (lastSyncedAt != null) result.lastSyncedAt = lastSyncedAt;
    if (lastSyncError != null) result.lastSyncError = lastSyncError;
    if (chatSupported != null) result.chatSupported = chatSupported;
    if (stale != null) result.stale = stale;
    if (providerLabel != null) result.providerLabel = providerLabel;
    return result;
  }

  ProviderConnection._();

  factory ProviderConnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProviderConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProviderConnection',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'presetId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<ConnectionProtocol>(4, _omitFieldNames ? '' : 'protocol',
        enumValues: ConnectionProtocol.values)
    ..aOS(5, _omitFieldNames ? '' : 'baseUrl')
    ..aOB(6, _omitFieldNames ? '' : 'apiKeySet')
    ..aOB(7, _omitFieldNames ? '' : 'enabled')
    ..aI(8, _omitFieldNames ? '' : 'modelCount')
    ..aOM<$1.Timestamp>(9, _omitFieldNames ? '' : 'lastSyncedAt',
        subBuilder: $1.Timestamp.create)
    ..aOS(10, _omitFieldNames ? '' : 'lastSyncError')
    ..aOB(11, _omitFieldNames ? '' : 'chatSupported')
    ..aOB(12, _omitFieldNames ? '' : 'stale')
    ..aOS(13, _omitFieldNames ? '' : 'providerLabel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProviderConnection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProviderConnection copyWith(void Function(ProviderConnection) updates) =>
      super.copyWith((message) => updates(message as ProviderConnection))
          as ProviderConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProviderConnection create() => ProviderConnection._();
  @$core.override
  ProviderConnection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProviderConnection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProviderConnection>(create);
  static ProviderConnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get presetId => $_getSZ(1);
  @$pb.TagNumber(2)
  set presetId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPresetId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPresetId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  ConnectionProtocol get protocol => $_getN(3);
  @$pb.TagNumber(4)
  set protocol(ConnectionProtocol value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasProtocol() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtocol() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get baseUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set baseUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBaseUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearBaseUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get apiKeySet => $_getBF(5);
  @$pb.TagNumber(6)
  set apiKeySet($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasApiKeySet() => $_has(5);
  @$pb.TagNumber(6)
  void clearApiKeySet() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get enabled => $_getBF(6);
  @$pb.TagNumber(7)
  set enabled($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEnabled() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnabled() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get modelCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set modelCount($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasModelCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearModelCount() => $_clearField(8);

  @$pb.TagNumber(9)
  $1.Timestamp get lastSyncedAt => $_getN(8);
  @$pb.TagNumber(9)
  set lastSyncedAt($1.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasLastSyncedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastSyncedAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureLastSyncedAt() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.String get lastSyncError => $_getSZ(9);
  @$pb.TagNumber(10)
  set lastSyncError($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLastSyncError() => $_has(9);
  @$pb.TagNumber(10)
  void clearLastSyncError() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get chatSupported => $_getBF(10);
  @$pb.TagNumber(11)
  set chatSupported($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasChatSupported() => $_has(10);
  @$pb.TagNumber(11)
  void clearChatSupported() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get stale => $_getBF(11);
  @$pb.TagNumber(12)
  set stale($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasStale() => $_has(11);
  @$pb.TagNumber(12)
  void clearStale() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get providerLabel => $_getSZ(12);
  @$pb.TagNumber(13)
  set providerLabel($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasProviderLabel() => $_has(12);
  @$pb.TagNumber(13)
  void clearProviderLabel() => $_clearField(13);
}

class ProviderModel extends $pb.GeneratedMessage {
  factory ProviderModel({
    $core.String? id,
    $core.String? displayName,
    $core.String? description,
    $core.int? contextWindow,
    $core.int? maxOutputTokens,
    $core.Iterable<$core.String>? inputModalities,
    $core.Iterable<$core.String>? outputModalities,
    $core.Iterable<$core.String>? capabilities,
    $core.bool? chatSupported,
    $core.bool? deprecated,
    $1.Timestamp? discoveredAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (displayName != null) result.displayName = displayName;
    if (description != null) result.description = description;
    if (contextWindow != null) result.contextWindow = contextWindow;
    if (maxOutputTokens != null) result.maxOutputTokens = maxOutputTokens;
    if (inputModalities != null) result.inputModalities.addAll(inputModalities);
    if (outputModalities != null)
      result.outputModalities.addAll(outputModalities);
    if (capabilities != null) result.capabilities.addAll(capabilities);
    if (chatSupported != null) result.chatSupported = chatSupported;
    if (deprecated != null) result.deprecated = deprecated;
    if (discoveredAt != null) result.discoveredAt = discoveredAt;
    return result;
  }

  ProviderModel._();

  factory ProviderModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProviderModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProviderModel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aI(4, _omitFieldNames ? '' : 'contextWindow')
    ..aI(5, _omitFieldNames ? '' : 'maxOutputTokens')
    ..pPS(6, _omitFieldNames ? '' : 'inputModalities')
    ..pPS(7, _omitFieldNames ? '' : 'outputModalities')
    ..pPS(8, _omitFieldNames ? '' : 'capabilities')
    ..aOB(9, _omitFieldNames ? '' : 'chatSupported')
    ..aOB(10, _omitFieldNames ? '' : 'deprecated')
    ..aOM<$1.Timestamp>(11, _omitFieldNames ? '' : 'discoveredAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProviderModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProviderModel copyWith(void Function(ProviderModel) updates) =>
      super.copyWith((message) => updates(message as ProviderModel))
          as ProviderModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProviderModel create() => ProviderModel._();
  @$core.override
  ProviderModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProviderModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProviderModel>(create);
  static ProviderModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get contextWindow => $_getIZ(3);
  @$pb.TagNumber(4)
  set contextWindow($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContextWindow() => $_has(3);
  @$pb.TagNumber(4)
  void clearContextWindow() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get maxOutputTokens => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxOutputTokens($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxOutputTokens() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxOutputTokens() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get inputModalities => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get outputModalities => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get capabilities => $_getList(7);

  @$pb.TagNumber(9)
  $core.bool get chatSupported => $_getBF(8);
  @$pb.TagNumber(9)
  set chatSupported($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasChatSupported() => $_has(8);
  @$pb.TagNumber(9)
  void clearChatSupported() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get deprecated => $_getBF(9);
  @$pb.TagNumber(10)
  set deprecated($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDeprecated() => $_has(9);
  @$pb.TagNumber(10)
  void clearDeprecated() => $_clearField(10);

  @$pb.TagNumber(11)
  $1.Timestamp get discoveredAt => $_getN(10);
  @$pb.TagNumber(11)
  set discoveredAt($1.Timestamp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasDiscoveredAt() => $_has(10);
  @$pb.TagNumber(11)
  void clearDiscoveredAt() => $_clearField(11);
  @$pb.TagNumber(11)
  $1.Timestamp ensureDiscoveredAt() => $_ensure(10);
}

/// ActiveProviderModel is a model deliberately enabled for the chat picker.
/// Model discovery never activates a billable model by itself.
class ActiveProviderModel extends $pb.GeneratedMessage {
  factory ActiveProviderModel({
    $core.String? modelRef,
    $core.String? connectionId,
    $core.String? providerLabel,
    $core.String? providerId,
    $core.String? modelId,
    $core.String? displayName,
    ConnectionProtocol? protocol,
    $1.Timestamp? activatedAt,
    $1.Timestamp? lastUsedAt,
  }) {
    final result = create();
    if (modelRef != null) result.modelRef = modelRef;
    if (connectionId != null) result.connectionId = connectionId;
    if (providerLabel != null) result.providerLabel = providerLabel;
    if (providerId != null) result.providerId = providerId;
    if (modelId != null) result.modelId = modelId;
    if (displayName != null) result.displayName = displayName;
    if (protocol != null) result.protocol = protocol;
    if (activatedAt != null) result.activatedAt = activatedAt;
    if (lastUsedAt != null) result.lastUsedAt = lastUsedAt;
    return result;
  }

  ActiveProviderModel._();

  factory ActiveProviderModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActiveProviderModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveProviderModel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelRef')
    ..aOS(2, _omitFieldNames ? '' : 'connectionId')
    ..aOS(3, _omitFieldNames ? '' : 'providerLabel')
    ..aOS(4, _omitFieldNames ? '' : 'providerId')
    ..aOS(5, _omitFieldNames ? '' : 'modelId')
    ..aOS(6, _omitFieldNames ? '' : 'displayName')
    ..aE<ConnectionProtocol>(7, _omitFieldNames ? '' : 'protocol',
        enumValues: ConnectionProtocol.values)
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'activatedAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(9, _omitFieldNames ? '' : 'lastUsedAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveProviderModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveProviderModel copyWith(void Function(ActiveProviderModel) updates) =>
      super.copyWith((message) => updates(message as ActiveProviderModel))
          as ActiveProviderModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActiveProviderModel create() => ActiveProviderModel._();
  @$core.override
  ActiveProviderModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActiveProviderModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActiveProviderModel>(create);
  static ActiveProviderModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelRef => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelRef($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelRef() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelRef() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get connectionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set connectionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get providerLabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set providerLabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProviderLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearProviderLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get providerId => $_getSZ(3);
  @$pb.TagNumber(4)
  set providerId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProviderId() => $_has(3);
  @$pb.TagNumber(4)
  void clearProviderId() => $_clearField(4);

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
  ConnectionProtocol get protocol => $_getN(6);
  @$pb.TagNumber(7)
  set protocol(ConnectionProtocol value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasProtocol() => $_has(6);
  @$pb.TagNumber(7)
  void clearProtocol() => $_clearField(7);

  @$pb.TagNumber(8)
  $1.Timestamp get activatedAt => $_getN(7);
  @$pb.TagNumber(8)
  set activatedAt($1.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasActivatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearActivatedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureActivatedAt() => $_ensure(7);

  @$pb.TagNumber(9)
  $1.Timestamp get lastUsedAt => $_getN(8);
  @$pb.TagNumber(9)
  set lastUsedAt($1.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasLastUsedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastUsedAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureLastUsedAt() => $_ensure(8);
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
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
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
    $core.Iterable<ProviderPreset>? presets,
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
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..pPM<ProviderPreset>(1, _omitFieldNames ? '' : 'presets',
        subBuilder: ProviderPreset.create)
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
  $pb.PbList<ProviderPreset> get presets => $_getList(0);
}

class ListConnectionsRequest extends $pb.GeneratedMessage {
  factory ListConnectionsRequest() => create();

  ListConnectionsRequest._();

  factory ListConnectionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListConnectionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConnectionsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsRequest copyWith(
          void Function(ListConnectionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListConnectionsRequest))
          as ListConnectionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionsRequest create() => ListConnectionsRequest._();
  @$core.override
  ListConnectionsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionsRequest>(create);
  static ListConnectionsRequest? _defaultInstance;
}

class ListConnectionsResponse extends $pb.GeneratedMessage {
  factory ListConnectionsResponse({
    $core.Iterable<ProviderConnection>? connections,
  }) {
    final result = create();
    if (connections != null) result.connections.addAll(connections);
    return result;
  }

  ListConnectionsResponse._();

  factory ListConnectionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListConnectionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConnectionsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..pPM<ProviderConnection>(1, _omitFieldNames ? '' : 'connections',
        subBuilder: ProviderConnection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsResponse copyWith(
          void Function(ListConnectionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListConnectionsResponse))
          as ListConnectionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionsResponse create() => ListConnectionsResponse._();
  @$core.override
  ListConnectionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionsResponse>(create);
  static ListConnectionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ProviderConnection> get connections => $_getList(0);
}

/// An empty id creates a connection; a supplied id updates one of the caller's
/// own connections.  api_key is write-only and is never echoed in a response.
class SaveConnectionRequest extends $pb.GeneratedMessage {
  factory SaveConnectionRequest({
    $core.String? id,
    $core.String? presetId,
    $core.String? name,
    ConnectionProtocol? protocol,
    $core.String? baseUrl,
    $core.String? apiKey,
    $core.bool? clearApiKey_7,
    $core.bool? enabled,
    $core.bool? syncModels,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (presetId != null) result.presetId = presetId;
    if (name != null) result.name = name;
    if (protocol != null) result.protocol = protocol;
    if (baseUrl != null) result.baseUrl = baseUrl;
    if (apiKey != null) result.apiKey = apiKey;
    if (clearApiKey_7 != null) result.clearApiKey_7 = clearApiKey_7;
    if (enabled != null) result.enabled = enabled;
    if (syncModels != null) result.syncModels = syncModels;
    return result;
  }

  SaveConnectionRequest._();

  factory SaveConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveConnectionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'presetId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<ConnectionProtocol>(4, _omitFieldNames ? '' : 'protocol',
        enumValues: ConnectionProtocol.values)
    ..aOS(5, _omitFieldNames ? '' : 'baseUrl')
    ..aOS(6, _omitFieldNames ? '' : 'apiKey')
    ..aOB(7, _omitFieldNames ? '' : 'clearApiKey')
    ..aOB(8, _omitFieldNames ? '' : 'enabled')
    ..aOB(9, _omitFieldNames ? '' : 'syncModels')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveConnectionRequest copyWith(
          void Function(SaveConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as SaveConnectionRequest))
          as SaveConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveConnectionRequest create() => SaveConnectionRequest._();
  @$core.override
  SaveConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveConnectionRequest>(create);
  static SaveConnectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get presetId => $_getSZ(1);
  @$pb.TagNumber(2)
  set presetId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPresetId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPresetId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  ConnectionProtocol get protocol => $_getN(3);
  @$pb.TagNumber(4)
  set protocol(ConnectionProtocol value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasProtocol() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtocol() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get baseUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set baseUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBaseUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearBaseUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get apiKey => $_getSZ(5);
  @$pb.TagNumber(6)
  set apiKey($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasApiKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearApiKey() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get clearApiKey_7 => $_getBF(6);
  @$pb.TagNumber(7)
  set clearApiKey_7($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasClearApiKey_7() => $_has(6);
  @$pb.TagNumber(7)
  void clearClearApiKey_7() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get enabled => $_getBF(7);
  @$pb.TagNumber(8)
  set enabled($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearEnabled() => $_clearField(8);

  /// Saving a valid connection normally fetches the current provider catalogue
  /// straight away.  It remains explicit for callers that only want to edit a
  /// display name while offline.
  @$pb.TagNumber(9)
  $core.bool get syncModels => $_getBF(8);
  @$pb.TagNumber(9)
  set syncModels($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSyncModels() => $_has(8);
  @$pb.TagNumber(9)
  void clearSyncModels() => $_clearField(9);
}

class SaveConnectionResponse extends $pb.GeneratedMessage {
  factory SaveConnectionResponse({
    ProviderConnection? connection,
    $core.Iterable<ProviderModel>? models,
    $core.String? syncError,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    if (models != null) result.models.addAll(models);
    if (syncError != null) result.syncError = syncError;
    return result;
  }

  SaveConnectionResponse._();

  factory SaveConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveConnectionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOM<ProviderConnection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: ProviderConnection.create)
    ..pPM<ProviderModel>(2, _omitFieldNames ? '' : 'models',
        subBuilder: ProviderModel.create)
    ..aOS(3, _omitFieldNames ? '' : 'syncError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveConnectionResponse copyWith(
          void Function(SaveConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as SaveConnectionResponse))
          as SaveConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveConnectionResponse create() => SaveConnectionResponse._();
  @$core.override
  SaveConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveConnectionResponse>(create);
  static SaveConnectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ProviderConnection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(ProviderConnection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  ProviderConnection ensureConnection() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<ProviderModel> get models => $_getList(1);

  /// A save is durable even if the provider is temporarily unreachable.  The
  /// UI receives this value and lets the user retry synchronization.
  @$pb.TagNumber(3)
  $core.String get syncError => $_getSZ(2);
  @$pb.TagNumber(3)
  set syncError($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSyncError() => $_has(2);
  @$pb.TagNumber(3)
  void clearSyncError() => $_clearField(3);
}

class DeleteConnectionRequest extends $pb.GeneratedMessage {
  factory DeleteConnectionRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteConnectionRequest._();

  factory DeleteConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteConnectionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionRequest copyWith(
          void Function(DeleteConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteConnectionRequest))
          as DeleteConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteConnectionRequest create() => DeleteConnectionRequest._();
  @$core.override
  DeleteConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteConnectionRequest>(create);
  static DeleteConnectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeleteConnectionResponse extends $pb.GeneratedMessage {
  factory DeleteConnectionResponse() => create();

  DeleteConnectionResponse._();

  factory DeleteConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteConnectionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionResponse copyWith(
          void Function(DeleteConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteConnectionResponse))
          as DeleteConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteConnectionResponse create() => DeleteConnectionResponse._();
  @$core.override
  DeleteConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteConnectionResponse>(create);
  static DeleteConnectionResponse? _defaultInstance;
}

class TestConnectionRequest extends $pb.GeneratedMessage {
  factory TestConnectionRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  TestConnectionRequest._();

  factory TestConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestConnectionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionRequest copyWith(
          void Function(TestConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as TestConnectionRequest))
          as TestConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestConnectionRequest create() => TestConnectionRequest._();
  @$core.override
  TestConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestConnectionRequest>(create);
  static TestConnectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class TestConnectionResponse extends $pb.GeneratedMessage {
  factory TestConnectionResponse({
    $core.bool? reachable,
    $core.String? message,
    $core.int? discoveredModelCount,
  }) {
    final result = create();
    if (reachable != null) result.reachable = reachable;
    if (message != null) result.message = message;
    if (discoveredModelCount != null)
      result.discoveredModelCount = discoveredModelCount;
    return result;
  }

  TestConnectionResponse._();

  factory TestConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestConnectionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'reachable')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aI(3, _omitFieldNames ? '' : 'discoveredModelCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionResponse copyWith(
          void Function(TestConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as TestConnectionResponse))
          as TestConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestConnectionResponse create() => TestConnectionResponse._();
  @$core.override
  TestConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestConnectionResponse>(create);
  static TestConnectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get reachable => $_getBF(0);
  @$pb.TagNumber(1)
  set reachable($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReachable() => $_has(0);
  @$pb.TagNumber(1)
  void clearReachable() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get discoveredModelCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set discoveredModelCount($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDiscoveredModelCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearDiscoveredModelCount() => $_clearField(3);
}

class SyncConnectionModelsRequest extends $pb.GeneratedMessage {
  factory SyncConnectionModelsRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  SyncConnectionModelsRequest._();

  factory SyncConnectionModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncConnectionModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncConnectionModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncConnectionModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncConnectionModelsRequest copyWith(
          void Function(SyncConnectionModelsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SyncConnectionModelsRequest))
          as SyncConnectionModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncConnectionModelsRequest create() =>
      SyncConnectionModelsRequest._();
  @$core.override
  SyncConnectionModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncConnectionModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncConnectionModelsRequest>(create);
  static SyncConnectionModelsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class SyncConnectionModelsResponse extends $pb.GeneratedMessage {
  factory SyncConnectionModelsResponse({
    ProviderConnection? connection,
    $core.Iterable<ProviderModel>? models,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    if (models != null) result.models.addAll(models);
    return result;
  }

  SyncConnectionModelsResponse._();

  factory SyncConnectionModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SyncConnectionModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncConnectionModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOM<ProviderConnection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: ProviderConnection.create)
    ..pPM<ProviderModel>(2, _omitFieldNames ? '' : 'models',
        subBuilder: ProviderModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncConnectionModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncConnectionModelsResponse copyWith(
          void Function(SyncConnectionModelsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SyncConnectionModelsResponse))
          as SyncConnectionModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncConnectionModelsResponse create() =>
      SyncConnectionModelsResponse._();
  @$core.override
  SyncConnectionModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SyncConnectionModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncConnectionModelsResponse>(create);
  static SyncConnectionModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ProviderConnection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(ProviderConnection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  ProviderConnection ensureConnection() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<ProviderModel> get models => $_getList(1);
}

class ListConnectionModelsRequest extends $pb.GeneratedMessage {
  factory ListConnectionModelsRequest({
    $core.String? connectionId,
  }) {
    final result = create();
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  ListConnectionModelsRequest._();

  factory ListConnectionModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListConnectionModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConnectionModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionModelsRequest copyWith(
          void Function(ListConnectionModelsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListConnectionModelsRequest))
          as ListConnectionModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionModelsRequest create() =>
      ListConnectionModelsRequest._();
  @$core.override
  ListConnectionModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListConnectionModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionModelsRequest>(create);
  static ListConnectionModelsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);
}

class ListConnectionModelsResponse extends $pb.GeneratedMessage {
  factory ListConnectionModelsResponse({
    ProviderConnection? connection,
    $core.Iterable<ProviderModel>? models,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    if (models != null) result.models.addAll(models);
    return result;
  }

  ListConnectionModelsResponse._();

  factory ListConnectionModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListConnectionModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConnectionModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOM<ProviderConnection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: ProviderConnection.create)
    ..pPM<ProviderModel>(2, _omitFieldNames ? '' : 'models',
        subBuilder: ProviderModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionModelsResponse copyWith(
          void Function(ListConnectionModelsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListConnectionModelsResponse))
          as ListConnectionModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionModelsResponse create() =>
      ListConnectionModelsResponse._();
  @$core.override
  ListConnectionModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListConnectionModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionModelsResponse>(create);
  static ListConnectionModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ProviderConnection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(ProviderConnection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  ProviderConnection ensureConnection() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<ProviderModel> get models => $_getList(1);
}

class ActivateModelRequest extends $pb.GeneratedMessage {
  factory ActivateModelRequest({
    $core.String? connectionId,
    $core.String? modelId,
    $core.String? displayName,
  }) {
    final result = create();
    if (connectionId != null) result.connectionId = connectionId;
    if (modelId != null) result.modelId = modelId;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  ActivateModelRequest._();

  factory ActivateModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActivateModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActivateModelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..aOS(2, _omitFieldNames ? '' : 'modelId')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateModelRequest copyWith(void Function(ActivateModelRequest) updates) =>
      super.copyWith((message) => updates(message as ActivateModelRequest))
          as ActivateModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActivateModelRequest create() => ActivateModelRequest._();
  @$core.override
  ActivateModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActivateModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActivateModelRequest>(create);
  static ActivateModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);

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

class ActivateModelResponse extends $pb.GeneratedMessage {
  factory ActivateModelResponse({
    ActiveProviderModel? model,
  }) {
    final result = create();
    if (model != null) result.model = model;
    return result;
  }

  ActivateModelResponse._();

  factory ActivateModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActivateModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActivateModelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOM<ActiveProviderModel>(1, _omitFieldNames ? '' : 'model',
        subBuilder: ActiveProviderModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateModelResponse copyWith(
          void Function(ActivateModelResponse) updates) =>
      super.copyWith((message) => updates(message as ActivateModelResponse))
          as ActivateModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActivateModelResponse create() => ActivateModelResponse._();
  @$core.override
  ActivateModelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActivateModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActivateModelResponse>(create);
  static ActivateModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ActiveProviderModel get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(ActiveProviderModel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);
  @$pb.TagNumber(1)
  ActiveProviderModel ensureModel() => $_ensure(0);
}

class ListActiveModelsRequest extends $pb.GeneratedMessage {
  factory ListActiveModelsRequest() => create();

  ListActiveModelsRequest._();

  factory ListActiveModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListActiveModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListActiveModelsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveModelsRequest copyWith(
          void Function(ListActiveModelsRequest) updates) =>
      super.copyWith((message) => updates(message as ListActiveModelsRequest))
          as ListActiveModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListActiveModelsRequest create() => ListActiveModelsRequest._();
  @$core.override
  ListActiveModelsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListActiveModelsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListActiveModelsRequest>(create);
  static ListActiveModelsRequest? _defaultInstance;
}

class ListActiveModelsResponse extends $pb.GeneratedMessage {
  factory ListActiveModelsResponse({
    $core.Iterable<ActiveProviderModel>? models,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    return result;
  }

  ListActiveModelsResponse._();

  factory ListActiveModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListActiveModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListActiveModelsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..pPM<ActiveProviderModel>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ActiveProviderModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListActiveModelsResponse copyWith(
          void Function(ListActiveModelsResponse) updates) =>
      super.copyWith((message) => updates(message as ListActiveModelsResponse))
          as ListActiveModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListActiveModelsResponse create() => ListActiveModelsResponse._();
  @$core.override
  ListActiveModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListActiveModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListActiveModelsResponse>(create);
  static ListActiveModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ActiveProviderModel> get models => $_getList(0);
}

class DeleteActiveModelRequest extends $pb.GeneratedMessage {
  factory DeleteActiveModelRequest({
    $core.String? modelRef,
  }) {
    final result = create();
    if (modelRef != null) result.modelRef = modelRef;
    return result;
  }

  DeleteActiveModelRequest._();

  factory DeleteActiveModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteActiveModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteActiveModelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelRef')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveModelRequest copyWith(
          void Function(DeleteActiveModelRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteActiveModelRequest))
          as DeleteActiveModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteActiveModelRequest create() => DeleteActiveModelRequest._();
  @$core.override
  DeleteActiveModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteActiveModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteActiveModelRequest>(create);
  static DeleteActiveModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelRef => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelRef($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelRef() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelRef() => $_clearField(1);
}

class DeleteActiveModelResponse extends $pb.GeneratedMessage {
  factory DeleteActiveModelResponse() => create();

  DeleteActiveModelResponse._();

  factory DeleteActiveModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteActiveModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteActiveModelResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.providers.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteActiveModelResponse copyWith(
          void Function(DeleteActiveModelResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteActiveModelResponse))
          as DeleteActiveModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteActiveModelResponse create() => DeleteActiveModelResponse._();
  @$core.override
  DeleteActiveModelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteActiveModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteActiveModelResponse>(create);
  static DeleteActiveModelResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
