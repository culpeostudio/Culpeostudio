// This is a generated file - do not edit.
//
// Generated from culpeostudio/login/v1/login.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'login.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'login.pbenum.dart';

class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? username,
    $core.String? password,
    SessionDuration? sessionDuration,
  }) {
    final result = create();
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    if (sessionDuration != null) result.sessionDuration = sessionDuration;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aE<SessionDuration>(3, _omitFieldNames ? '' : 'sessionDuration',
        enumValues: SessionDuration.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginRequest create() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginRequest>(create);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);

  @$pb.TagNumber(3)
  SessionDuration get sessionDuration => $_getN(2);
  @$pb.TagNumber(3)
  set sessionDuration(SessionDuration value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionDuration() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionDuration() => $_clearField(3);
}

class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    $core.String? token,
    $core.String? username,
    SessionDuration? sessionDuration,
  }) {
    final result = create();
    if (token != null) result.token = token;
    if (username != null) result.username = username;
    if (sessionDuration != null) result.sessionDuration = sessionDuration;
    return result;
  }

  LoginResponse._();

  factory LoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aE<SessionDuration>(3, _omitFieldNames ? '' : 'sessionDuration',
        enumValues: SessionDuration.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginResponse create() => LoginResponse._();
  @$core.override
  LoginResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginResponse>(create);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  /// The duration actually granted, which is the resolved value rather than
  /// whatever the request asked for.
  @$pb.TagNumber(3)
  SessionDuration get sessionDuration => $_getN(2);
  @$pb.TagNumber(3)
  set sessionDuration(SessionDuration value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionDuration() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionDuration() => $_clearField(3);
}

class GetAuthStatusRequest extends $pb.GeneratedMessage {
  factory GetAuthStatusRequest() => create();

  GetAuthStatusRequest._();

  factory GetAuthStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAuthStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAuthStatusRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusRequest copyWith(void Function(GetAuthStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetAuthStatusRequest))
          as GetAuthStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAuthStatusRequest create() => GetAuthStatusRequest._();
  @$core.override
  GetAuthStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAuthStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAuthStatusRequest>(create);
  static GetAuthStatusRequest? _defaultInstance;
}

class GetAuthStatusResponse extends $pb.GeneratedMessage {
  factory GetAuthStatusResponse({
    $core.bool? totpConfigured,
    $core.String? authenticatorApp,
    $core.bool? guestModeActive,
  }) {
    final result = create();
    if (totpConfigured != null) result.totpConfigured = totpConfigured;
    if (authenticatorApp != null) result.authenticatorApp = authenticatorApp;
    if (guestModeActive != null) result.guestModeActive = guestModeActive;
    return result;
  }

  GetAuthStatusResponse._();

  factory GetAuthStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAuthStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAuthStatusResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'totpConfigured')
    ..aOS(2, _omitFieldNames ? '' : 'authenticatorApp')
    ..aOB(3, _omitFieldNames ? '' : 'guestModeActive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusResponse copyWith(
          void Function(GetAuthStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetAuthStatusResponse))
          as GetAuthStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAuthStatusResponse create() => GetAuthStatusResponse._();
  @$core.override
  GetAuthStatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAuthStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAuthStatusResponse>(create);
  static GetAuthStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get totpConfigured => $_getBF(0);
  @$pb.TagNumber(1)
  set totpConfigured($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotpConfigured() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotpConfigured() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get authenticatorApp => $_getSZ(1);
  @$pb.TagNumber(2)
  set authenticatorApp($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthenticatorApp() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthenticatorApp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get guestModeActive => $_getBF(2);
  @$pb.TagNumber(3)
  set guestModeActive($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGuestModeActive() => $_has(2);
  @$pb.TagNumber(3)
  void clearGuestModeActive() => $_clearField(3);
}

class StartAuthenticatorSetupRequest extends $pb.GeneratedMessage {
  factory StartAuthenticatorSetupRequest() => create();

  StartAuthenticatorSetupRequest._();

  factory StartAuthenticatorSetupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartAuthenticatorSetupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartAuthenticatorSetupRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartAuthenticatorSetupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartAuthenticatorSetupRequest copyWith(
          void Function(StartAuthenticatorSetupRequest) updates) =>
      super.copyWith(
              (message) => updates(message as StartAuthenticatorSetupRequest))
          as StartAuthenticatorSetupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartAuthenticatorSetupRequest create() =>
      StartAuthenticatorSetupRequest._();
  @$core.override
  StartAuthenticatorSetupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartAuthenticatorSetupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartAuthenticatorSetupRequest>(create);
  static StartAuthenticatorSetupRequest? _defaultInstance;
}

class StartAuthenticatorSetupResponse extends $pb.GeneratedMessage {
  factory StartAuthenticatorSetupResponse({
    $core.String? secret,
    $core.String? otpauthUrl,
  }) {
    final result = create();
    if (secret != null) result.secret = secret;
    if (otpauthUrl != null) result.otpauthUrl = otpauthUrl;
    return result;
  }

  StartAuthenticatorSetupResponse._();

  factory StartAuthenticatorSetupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartAuthenticatorSetupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartAuthenticatorSetupResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'secret')
    ..aOS(2, _omitFieldNames ? '' : 'otpauthUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartAuthenticatorSetupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartAuthenticatorSetupResponse copyWith(
          void Function(StartAuthenticatorSetupResponse) updates) =>
      super.copyWith(
              (message) => updates(message as StartAuthenticatorSetupResponse))
          as StartAuthenticatorSetupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartAuthenticatorSetupResponse create() =>
      StartAuthenticatorSetupResponse._();
  @$core.override
  StartAuthenticatorSetupResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartAuthenticatorSetupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartAuthenticatorSetupResponse>(
          create);
  static StartAuthenticatorSetupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get secret => $_getSZ(0);
  @$pb.TagNumber(1)
  set secret($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get otpauthUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set otpauthUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOtpauthUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearOtpauthUrl() => $_clearField(2);
}

class ConfirmAuthenticatorSetupRequest extends $pb.GeneratedMessage {
  factory ConfirmAuthenticatorSetupRequest({
    $core.String? code,
    $core.String? app,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (app != null) result.app = app;
    return result;
  }

  ConfirmAuthenticatorSetupRequest._();

  factory ConfirmAuthenticatorSetupRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConfirmAuthenticatorSetupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConfirmAuthenticatorSetupRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'app')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfirmAuthenticatorSetupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfirmAuthenticatorSetupRequest copyWith(
          void Function(ConfirmAuthenticatorSetupRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ConfirmAuthenticatorSetupRequest))
          as ConfirmAuthenticatorSetupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConfirmAuthenticatorSetupRequest create() =>
      ConfirmAuthenticatorSetupRequest._();
  @$core.override
  ConfirmAuthenticatorSetupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConfirmAuthenticatorSetupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConfirmAuthenticatorSetupRequest>(
          create);
  static ConfirmAuthenticatorSetupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get app => $_getSZ(1);
  @$pb.TagNumber(2)
  set app($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasApp() => $_has(1);
  @$pb.TagNumber(2)
  void clearApp() => $_clearField(2);
}

class ConfirmAuthenticatorSetupResponse extends $pb.GeneratedMessage {
  factory ConfirmAuthenticatorSetupResponse({
    $core.bool? totpConfigured,
  }) {
    final result = create();
    if (totpConfigured != null) result.totpConfigured = totpConfigured;
    return result;
  }

  ConfirmAuthenticatorSetupResponse._();

  factory ConfirmAuthenticatorSetupResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConfirmAuthenticatorSetupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConfirmAuthenticatorSetupResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'totpConfigured')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfirmAuthenticatorSetupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfirmAuthenticatorSetupResponse copyWith(
          void Function(ConfirmAuthenticatorSetupResponse) updates) =>
      super.copyWith((message) =>
              updates(message as ConfirmAuthenticatorSetupResponse))
          as ConfirmAuthenticatorSetupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConfirmAuthenticatorSetupResponse create() =>
      ConfirmAuthenticatorSetupResponse._();
  @$core.override
  ConfirmAuthenticatorSetupResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConfirmAuthenticatorSetupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConfirmAuthenticatorSetupResponse>(
          create);
  static ConfirmAuthenticatorSetupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get totpConfigured => $_getBF(0);
  @$pb.TagNumber(1)
  set totpConfigured($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotpConfigured() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotpConfigured() => $_clearField(1);
}

class CreateAccountRequest extends $pb.GeneratedMessage {
  factory CreateAccountRequest({
    $core.String? username,
    $core.String? password,
    $core.String? totpCode,
  }) {
    final result = create();
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    if (totpCode != null) result.totpCode = totpCode;
    return result;
  }

  CreateAccountRequest._();

  factory CreateAccountRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateAccountRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateAccountRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOS(3, _omitFieldNames ? '' : 'totpCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAccountRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAccountRequest copyWith(void Function(CreateAccountRequest) updates) =>
      super.copyWith((message) => updates(message as CreateAccountRequest))
          as CreateAccountRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateAccountRequest create() => CreateAccountRequest._();
  @$core.override
  CreateAccountRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateAccountRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateAccountRequest>(create);
  static CreateAccountRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get totpCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set totpCode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotpCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotpCode() => $_clearField(3);
}

class CreateAccountResponse extends $pb.GeneratedMessage {
  factory CreateAccountResponse({
    $core.String? username,
  }) {
    final result = create();
    if (username != null) result.username = username;
    return result;
  }

  CreateAccountResponse._();

  factory CreateAccountResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateAccountResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateAccountResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAccountResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateAccountResponse copyWith(
          void Function(CreateAccountResponse) updates) =>
      super.copyWith((message) => updates(message as CreateAccountResponse))
          as CreateAccountResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateAccountResponse create() => CreateAccountResponse._();
  @$core.override
  CreateAccountResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateAccountResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateAccountResponse>(create);
  static CreateAccountResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);
}

class ResetPasswordRequest extends $pb.GeneratedMessage {
  factory ResetPasswordRequest({
    $core.String? username,
    $core.String? newPassword,
    $core.String? totpCode,
  }) {
    final result = create();
    if (username != null) result.username = username;
    if (newPassword != null) result.newPassword = newPassword;
    if (totpCode != null) result.totpCode = totpCode;
    return result;
  }

  ResetPasswordRequest._();

  factory ResetPasswordRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResetPasswordRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetPasswordRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'newPassword')
    ..aOS(3, _omitFieldNames ? '' : 'totpCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordRequest copyWith(void Function(ResetPasswordRequest) updates) =>
      super.copyWith((message) => updates(message as ResetPasswordRequest))
          as ResetPasswordRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResetPasswordRequest create() => ResetPasswordRequest._();
  @$core.override
  ResetPasswordRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResetPasswordRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetPasswordRequest>(create);
  static ResetPasswordRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newPassword => $_getSZ(1);
  @$pb.TagNumber(2)
  set newPassword($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewPassword() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get totpCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set totpCode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotpCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotpCode() => $_clearField(3);
}

class ResetPasswordResponse extends $pb.GeneratedMessage {
  factory ResetPasswordResponse({
    $core.String? username,
    $core.bool? passwordReset,
  }) {
    final result = create();
    if (username != null) result.username = username;
    if (passwordReset != null) result.passwordReset = passwordReset;
    return result;
  }

  ResetPasswordResponse._();

  factory ResetPasswordResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResetPasswordResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetPasswordResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOB(2, _omitFieldNames ? '' : 'passwordReset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordResponse copyWith(
          void Function(ResetPasswordResponse) updates) =>
      super.copyWith((message) => updates(message as ResetPasswordResponse))
          as ResetPasswordResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResetPasswordResponse create() => ResetPasswordResponse._();
  @$core.override
  ResetPasswordResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResetPasswordResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetPasswordResponse>(create);
  static ResetPasswordResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get passwordReset => $_getBF(1);
  @$pb.TagNumber(2)
  set passwordReset($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPasswordReset() => $_has(1);
  @$pb.TagNumber(2)
  void clearPasswordReset() => $_clearField(2);
}

class UserPreferences extends $pb.GeneratedMessage {
  factory UserPreferences({
    $core.bool? configured,
    $core.String? language,
  }) {
    final result = create();
    if (configured != null) result.configured = configured;
    if (language != null) result.language = language;
    return result;
  }

  UserPreferences._();

  factory UserPreferences.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserPreferences.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserPreferences',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'configured')
    ..aOS(2, _omitFieldNames ? '' : 'language')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPreferences clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPreferences copyWith(void Function(UserPreferences) updates) =>
      super.copyWith((message) => updates(message as UserPreferences))
          as UserPreferences;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserPreferences create() => UserPreferences._();
  @$core.override
  UserPreferences createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserPreferences getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserPreferences>(create);
  static UserPreferences? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get configured => $_getBF(0);
  @$pb.TagNumber(1)
  set configured($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfigured() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigured() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get language => $_getSZ(1);
  @$pb.TagNumber(2)
  set language($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLanguage() => $_has(1);
  @$pb.TagNumber(2)
  void clearLanguage() => $_clearField(2);
}

class GetUserPreferencesRequest extends $pb.GeneratedMessage {
  factory GetUserPreferencesRequest() => create();

  GetUserPreferencesRequest._();

  factory GetUserPreferencesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetUserPreferencesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUserPreferencesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserPreferencesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserPreferencesRequest copyWith(
          void Function(GetUserPreferencesRequest) updates) =>
      super.copyWith((message) => updates(message as GetUserPreferencesRequest))
          as GetUserPreferencesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetUserPreferencesRequest create() => GetUserPreferencesRequest._();
  @$core.override
  GetUserPreferencesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetUserPreferencesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUserPreferencesRequest>(create);
  static GetUserPreferencesRequest? _defaultInstance;
}

class GetUserPreferencesResponse extends $pb.GeneratedMessage {
  factory GetUserPreferencesResponse({
    UserPreferences? preferences,
  }) {
    final result = create();
    if (preferences != null) result.preferences = preferences;
    return result;
  }

  GetUserPreferencesResponse._();

  factory GetUserPreferencesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetUserPreferencesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUserPreferencesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOM<UserPreferences>(1, _omitFieldNames ? '' : 'preferences',
        subBuilder: UserPreferences.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserPreferencesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserPreferencesResponse copyWith(
          void Function(GetUserPreferencesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetUserPreferencesResponse))
          as GetUserPreferencesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetUserPreferencesResponse create() => GetUserPreferencesResponse._();
  @$core.override
  GetUserPreferencesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetUserPreferencesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUserPreferencesResponse>(create);
  static GetUserPreferencesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UserPreferences get preferences => $_getN(0);
  @$pb.TagNumber(1)
  set preferences(UserPreferences value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreferences() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreferences() => $_clearField(1);
  @$pb.TagNumber(1)
  UserPreferences ensurePreferences() => $_ensure(0);
}

class UpdateUserPreferencesRequest extends $pb.GeneratedMessage {
  factory UpdateUserPreferencesRequest({
    $core.String? language,
  }) {
    final result = create();
    if (language != null) result.language = language;
    return result;
  }

  UpdateUserPreferencesRequest._();

  factory UpdateUserPreferencesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateUserPreferencesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateUserPreferencesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'language')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateUserPreferencesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateUserPreferencesRequest copyWith(
          void Function(UpdateUserPreferencesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateUserPreferencesRequest))
          as UpdateUserPreferencesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateUserPreferencesRequest create() =>
      UpdateUserPreferencesRequest._();
  @$core.override
  UpdateUserPreferencesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateUserPreferencesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateUserPreferencesRequest>(create);
  static UpdateUserPreferencesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get language => $_getSZ(0);
  @$pb.TagNumber(1)
  set language($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLanguage() => $_has(0);
  @$pb.TagNumber(1)
  void clearLanguage() => $_clearField(1);
}

class UpdateUserPreferencesResponse extends $pb.GeneratedMessage {
  factory UpdateUserPreferencesResponse({
    UserPreferences? preferences,
  }) {
    final result = create();
    if (preferences != null) result.preferences = preferences;
    return result;
  }

  UpdateUserPreferencesResponse._();

  factory UpdateUserPreferencesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateUserPreferencesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateUserPreferencesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..aOM<UserPreferences>(1, _omitFieldNames ? '' : 'preferences',
        subBuilder: UserPreferences.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateUserPreferencesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateUserPreferencesResponse copyWith(
          void Function(UpdateUserPreferencesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateUserPreferencesResponse))
          as UpdateUserPreferencesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateUserPreferencesResponse create() =>
      UpdateUserPreferencesResponse._();
  @$core.override
  UpdateUserPreferencesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateUserPreferencesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateUserPreferencesResponse>(create);
  static UpdateUserPreferencesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UserPreferences get preferences => $_getN(0);
  @$pb.TagNumber(1)
  set preferences(UserPreferences value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreferences() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreferences() => $_clearField(1);
  @$pb.TagNumber(1)
  UserPreferences ensurePreferences() => $_ensure(0);
}

class EnableGuestModeRequest extends $pb.GeneratedMessage {
  factory EnableGuestModeRequest() => create();

  EnableGuestModeRequest._();

  factory EnableGuestModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnableGuestModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnableGuestModeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableGuestModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableGuestModeRequest copyWith(
          void Function(EnableGuestModeRequest) updates) =>
      super.copyWith((message) => updates(message as EnableGuestModeRequest))
          as EnableGuestModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnableGuestModeRequest create() => EnableGuestModeRequest._();
  @$core.override
  EnableGuestModeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnableGuestModeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnableGuestModeRequest>(create);
  static EnableGuestModeRequest? _defaultInstance;
}

class EnableGuestModeResponse extends $pb.GeneratedMessage {
  factory EnableGuestModeResponse() => create();

  EnableGuestModeResponse._();

  factory EnableGuestModeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnableGuestModeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnableGuestModeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableGuestModeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableGuestModeResponse copyWith(
          void Function(EnableGuestModeResponse) updates) =>
      super.copyWith((message) => updates(message as EnableGuestModeResponse))
          as EnableGuestModeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnableGuestModeResponse create() => EnableGuestModeResponse._();
  @$core.override
  EnableGuestModeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnableGuestModeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnableGuestModeResponse>(create);
  static EnableGuestModeResponse? _defaultInstance;
}

class DisableGuestModeRequest extends $pb.GeneratedMessage {
  factory DisableGuestModeRequest() => create();

  DisableGuestModeRequest._();

  factory DisableGuestModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DisableGuestModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableGuestModeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableGuestModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableGuestModeRequest copyWith(
          void Function(DisableGuestModeRequest) updates) =>
      super.copyWith((message) => updates(message as DisableGuestModeRequest))
          as DisableGuestModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisableGuestModeRequest create() => DisableGuestModeRequest._();
  @$core.override
  DisableGuestModeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DisableGuestModeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableGuestModeRequest>(create);
  static DisableGuestModeRequest? _defaultInstance;
}

class DisableGuestModeResponse extends $pb.GeneratedMessage {
  factory DisableGuestModeResponse() => create();

  DisableGuestModeResponse._();

  factory DisableGuestModeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DisableGuestModeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableGuestModeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.login.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableGuestModeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableGuestModeResponse copyWith(
          void Function(DisableGuestModeResponse) updates) =>
      super.copyWith((message) => updates(message as DisableGuestModeResponse))
          as DisableGuestModeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisableGuestModeResponse create() => DisableGuestModeResponse._();
  @$core.override
  DisableGuestModeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DisableGuestModeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableGuestModeResponse>(create);
  static DisableGuestModeResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
