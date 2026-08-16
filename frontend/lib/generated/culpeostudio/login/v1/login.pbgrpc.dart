// This is a generated file - do not edit.
//
// Generated from culpeostudio/login/v1/login.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'login.pb.dart' as $0;

export 'login.pb.dart';

/// LoginService issues the session tokens and manages the accounts, the
/// authenticator and the per-user preferences.
///
/// Everything except the two preference calls is reachable without a token -
/// they are what a client uses before it has one. See publicGRPCMethods in
/// cmd/server.
@$pb.GrpcServiceName('culpeostudio.login.v1.LoginService')
class LoginServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  LoginServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.LoginResponse> login(
    $0.LoginRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetAuthStatusResponse> getAuthStatus(
    $0.GetAuthStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAuthStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.StartAuthenticatorSetupResponse>
      startAuthenticatorSetup(
    $0.StartAuthenticatorSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startAuthenticatorSetup, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.ConfirmAuthenticatorSetupResponse>
      confirmAuthenticatorSetup(
    $0.ConfirmAuthenticatorSetupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$confirmAuthenticatorSetup, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.CreateAccountResponse> createAccount(
    $0.CreateAccountRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  $grpc.ResponseFuture<$0.ResetPasswordResponse> resetPassword(
    $0.ResetPasswordRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resetPassword, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetUserPreferencesResponse> getUserPreferences(
    $0.GetUserPreferencesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUserPreferences, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateUserPreferencesResponse> updateUserPreferences(
    $0.UpdateUserPreferencesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateUserPreferences, request, options: options);
  }

  $grpc.ResponseFuture<$0.EnableGuestModeResponse> enableGuestMode(
    $0.EnableGuestModeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$enableGuestMode, request, options: options);
  }

  $grpc.ResponseFuture<$0.DisableGuestModeResponse> disableGuestMode(
    $0.DisableGuestModeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$disableGuestMode, request, options: options);
  }

  // method descriptors

  static final _$login = $grpc.ClientMethod<$0.LoginRequest, $0.LoginResponse>(
      '/culpeostudio.login.v1.LoginService/Login',
      ($0.LoginRequest value) => value.writeToBuffer(),
      $0.LoginResponse.fromBuffer);
  static final _$getAuthStatus =
      $grpc.ClientMethod<$0.GetAuthStatusRequest, $0.GetAuthStatusResponse>(
          '/culpeostudio.login.v1.LoginService/GetAuthStatus',
          ($0.GetAuthStatusRequest value) => value.writeToBuffer(),
          $0.GetAuthStatusResponse.fromBuffer);
  static final _$startAuthenticatorSetup = $grpc.ClientMethod<
          $0.StartAuthenticatorSetupRequest,
          $0.StartAuthenticatorSetupResponse>(
      '/culpeostudio.login.v1.LoginService/StartAuthenticatorSetup',
      ($0.StartAuthenticatorSetupRequest value) => value.writeToBuffer(),
      $0.StartAuthenticatorSetupResponse.fromBuffer);
  static final _$confirmAuthenticatorSetup = $grpc.ClientMethod<
          $0.ConfirmAuthenticatorSetupRequest,
          $0.ConfirmAuthenticatorSetupResponse>(
      '/culpeostudio.login.v1.LoginService/ConfirmAuthenticatorSetup',
      ($0.ConfirmAuthenticatorSetupRequest value) => value.writeToBuffer(),
      $0.ConfirmAuthenticatorSetupResponse.fromBuffer);
  static final _$createAccount =
      $grpc.ClientMethod<$0.CreateAccountRequest, $0.CreateAccountResponse>(
          '/culpeostudio.login.v1.LoginService/CreateAccount',
          ($0.CreateAccountRequest value) => value.writeToBuffer(),
          $0.CreateAccountResponse.fromBuffer);
  static final _$resetPassword =
      $grpc.ClientMethod<$0.ResetPasswordRequest, $0.ResetPasswordResponse>(
          '/culpeostudio.login.v1.LoginService/ResetPassword',
          ($0.ResetPasswordRequest value) => value.writeToBuffer(),
          $0.ResetPasswordResponse.fromBuffer);
  static final _$getUserPreferences = $grpc.ClientMethod<
          $0.GetUserPreferencesRequest, $0.GetUserPreferencesResponse>(
      '/culpeostudio.login.v1.LoginService/GetUserPreferences',
      ($0.GetUserPreferencesRequest value) => value.writeToBuffer(),
      $0.GetUserPreferencesResponse.fromBuffer);
  static final _$updateUserPreferences = $grpc.ClientMethod<
          $0.UpdateUserPreferencesRequest, $0.UpdateUserPreferencesResponse>(
      '/culpeostudio.login.v1.LoginService/UpdateUserPreferences',
      ($0.UpdateUserPreferencesRequest value) => value.writeToBuffer(),
      $0.UpdateUserPreferencesResponse.fromBuffer);
  static final _$enableGuestMode =
      $grpc.ClientMethod<$0.EnableGuestModeRequest, $0.EnableGuestModeResponse>(
          '/culpeostudio.login.v1.LoginService/EnableGuestMode',
          ($0.EnableGuestModeRequest value) => value.writeToBuffer(),
          $0.EnableGuestModeResponse.fromBuffer);
  static final _$disableGuestMode = $grpc.ClientMethod<
          $0.DisableGuestModeRequest, $0.DisableGuestModeResponse>(
      '/culpeostudio.login.v1.LoginService/DisableGuestMode',
      ($0.DisableGuestModeRequest value) => value.writeToBuffer(),
      $0.DisableGuestModeResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.login.v1.LoginService')
abstract class LoginServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.login.v1.LoginService';

  LoginServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LoginRequest, $0.LoginResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoginRequest.fromBuffer(value),
        ($0.LoginResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetAuthStatusRequest, $0.GetAuthStatusResponse>(
            'GetAuthStatus',
            getAuthStatus_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetAuthStatusRequest.fromBuffer(value),
            ($0.GetAuthStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartAuthenticatorSetupRequest,
            $0.StartAuthenticatorSetupResponse>(
        'StartAuthenticatorSetup',
        startAuthenticatorSetup_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StartAuthenticatorSetupRequest.fromBuffer(value),
        ($0.StartAuthenticatorSetupResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ConfirmAuthenticatorSetupRequest,
            $0.ConfirmAuthenticatorSetupResponse>(
        'ConfirmAuthenticatorSetup',
        confirmAuthenticatorSetup_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ConfirmAuthenticatorSetupRequest.fromBuffer(value),
        ($0.ConfirmAuthenticatorSetupResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CreateAccountRequest, $0.CreateAccountResponse>(
            'CreateAccount',
            createAccount_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateAccountRequest.fromBuffer(value),
            ($0.CreateAccountResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ResetPasswordRequest, $0.ResetPasswordResponse>(
            'ResetPassword',
            resetPassword_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ResetPasswordRequest.fromBuffer(value),
            ($0.ResetPasswordResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetUserPreferencesRequest,
            $0.GetUserPreferencesResponse>(
        'GetUserPreferences',
        getUserPreferences_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetUserPreferencesRequest.fromBuffer(value),
        ($0.GetUserPreferencesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateUserPreferencesRequest,
            $0.UpdateUserPreferencesResponse>(
        'UpdateUserPreferences',
        updateUserPreferences_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateUserPreferencesRequest.fromBuffer(value),
        ($0.UpdateUserPreferencesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EnableGuestModeRequest,
            $0.EnableGuestModeResponse>(
        'EnableGuestMode',
        enableGuestMode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.EnableGuestModeRequest.fromBuffer(value),
        ($0.EnableGuestModeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DisableGuestModeRequest,
            $0.DisableGuestModeResponse>(
        'DisableGuestMode',
        disableGuestMode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DisableGuestModeRequest.fromBuffer(value),
        ($0.DisableGuestModeResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.LoginResponse> login_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoginRequest> $request) async {
    return login($call, await $request);
  }

  $async.Future<$0.LoginResponse> login(
      $grpc.ServiceCall call, $0.LoginRequest request);

  $async.Future<$0.GetAuthStatusResponse> getAuthStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAuthStatusRequest> $request) async {
    return getAuthStatus($call, await $request);
  }

  $async.Future<$0.GetAuthStatusResponse> getAuthStatus(
      $grpc.ServiceCall call, $0.GetAuthStatusRequest request);

  $async.Future<$0.StartAuthenticatorSetupResponse> startAuthenticatorSetup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartAuthenticatorSetupRequest> $request) async {
    return startAuthenticatorSetup($call, await $request);
  }

  $async.Future<$0.StartAuthenticatorSetupResponse> startAuthenticatorSetup(
      $grpc.ServiceCall call, $0.StartAuthenticatorSetupRequest request);

  $async.Future<$0.ConfirmAuthenticatorSetupResponse>
      confirmAuthenticatorSetup_Pre($grpc.ServiceCall $call,
          $async.Future<$0.ConfirmAuthenticatorSetupRequest> $request) async {
    return confirmAuthenticatorSetup($call, await $request);
  }

  $async.Future<$0.ConfirmAuthenticatorSetupResponse> confirmAuthenticatorSetup(
      $grpc.ServiceCall call, $0.ConfirmAuthenticatorSetupRequest request);

  $async.Future<$0.CreateAccountResponse> createAccount_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateAccountRequest> $request) async {
    return createAccount($call, await $request);
  }

  $async.Future<$0.CreateAccountResponse> createAccount(
      $grpc.ServiceCall call, $0.CreateAccountRequest request);

  $async.Future<$0.ResetPasswordResponse> resetPassword_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ResetPasswordRequest> $request) async {
    return resetPassword($call, await $request);
  }

  $async.Future<$0.ResetPasswordResponse> resetPassword(
      $grpc.ServiceCall call, $0.ResetPasswordRequest request);

  $async.Future<$0.GetUserPreferencesResponse> getUserPreferences_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetUserPreferencesRequest> $request) async {
    return getUserPreferences($call, await $request);
  }

  $async.Future<$0.GetUserPreferencesResponse> getUserPreferences(
      $grpc.ServiceCall call, $0.GetUserPreferencesRequest request);

  $async.Future<$0.UpdateUserPreferencesResponse> updateUserPreferences_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateUserPreferencesRequest> $request) async {
    return updateUserPreferences($call, await $request);
  }

  $async.Future<$0.UpdateUserPreferencesResponse> updateUserPreferences(
      $grpc.ServiceCall call, $0.UpdateUserPreferencesRequest request);

  $async.Future<$0.EnableGuestModeResponse> enableGuestMode_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.EnableGuestModeRequest> $request) async {
    return enableGuestMode($call, await $request);
  }

  $async.Future<$0.EnableGuestModeResponse> enableGuestMode(
      $grpc.ServiceCall call, $0.EnableGuestModeRequest request);

  $async.Future<$0.DisableGuestModeResponse> disableGuestMode_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DisableGuestModeRequest> $request) async {
    return disableGuestMode($call, await $request);
  }

  $async.Future<$0.DisableGuestModeResponse> disableGuestMode(
      $grpc.ServiceCall call, $0.DisableGuestModeRequest request);
}
