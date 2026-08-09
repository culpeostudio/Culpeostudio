// This is a generated file - do not edit.
//
// Generated from culpeostudio/settings/v1/settings.proto.

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

import 'settings.pb.dart' as $0;

export 'settings.pb.dart';

/// SettingsService backs the settings screen: the stored studio settings, the
/// detected system information and the provider connection tests.
@$pb.GrpcServiceName('culpeostudio.settings.v1.SettingsService')
class SettingsServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SettingsServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GetSettingsResponse> getSettings(
    $0.GetSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateSettingsResponse> updateSettings(
    $0.UpdateSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetSystemInfoResponse> getSystemInfo(
    $0.GetSystemInfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSystemInfo, request, options: options);
  }

  $grpc.ResponseFuture<$0.TestProviderResponse> testProvider(
    $0.TestProviderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$testProvider, request, options: options);
  }

  // method descriptors

  static final _$getSettings =
      $grpc.ClientMethod<$0.GetSettingsRequest, $0.GetSettingsResponse>(
          '/culpeostudio.settings.v1.SettingsService/GetSettings',
          ($0.GetSettingsRequest value) => value.writeToBuffer(),
          $0.GetSettingsResponse.fromBuffer);
  static final _$updateSettings =
      $grpc.ClientMethod<$0.UpdateSettingsRequest, $0.UpdateSettingsResponse>(
          '/culpeostudio.settings.v1.SettingsService/UpdateSettings',
          ($0.UpdateSettingsRequest value) => value.writeToBuffer(),
          $0.UpdateSettingsResponse.fromBuffer);
  static final _$getSystemInfo =
      $grpc.ClientMethod<$0.GetSystemInfoRequest, $0.GetSystemInfoResponse>(
          '/culpeostudio.settings.v1.SettingsService/GetSystemInfo',
          ($0.GetSystemInfoRequest value) => value.writeToBuffer(),
          $0.GetSystemInfoResponse.fromBuffer);
  static final _$testProvider =
      $grpc.ClientMethod<$0.TestProviderRequest, $0.TestProviderResponse>(
          '/culpeostudio.settings.v1.SettingsService/TestProvider',
          ($0.TestProviderRequest value) => value.writeToBuffer(),
          $0.TestProviderResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.settings.v1.SettingsService')
abstract class SettingsServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.settings.v1.SettingsService';

  SettingsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.GetSettingsRequest, $0.GetSettingsResponse>(
            'GetSettings',
            getSettings_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetSettingsRequest.fromBuffer(value),
            ($0.GetSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateSettingsRequest,
            $0.UpdateSettingsResponse>(
        'UpdateSettings',
        updateSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateSettingsRequest.fromBuffer(value),
        ($0.UpdateSettingsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetSystemInfoRequest, $0.GetSystemInfoResponse>(
            'GetSystemInfo',
            getSystemInfo_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetSystemInfoRequest.fromBuffer(value),
            ($0.GetSystemInfoResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.TestProviderRequest, $0.TestProviderResponse>(
            'TestProvider',
            testProvider_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.TestProviderRequest.fromBuffer(value),
            ($0.TestProviderResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetSettingsResponse> getSettings_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetSettingsRequest> $request) async {
    return getSettings($call, await $request);
  }

  $async.Future<$0.GetSettingsResponse> getSettings(
      $grpc.ServiceCall call, $0.GetSettingsRequest request);

  $async.Future<$0.UpdateSettingsResponse> updateSettings_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateSettingsRequest> $request) async {
    return updateSettings($call, await $request);
  }

  $async.Future<$0.UpdateSettingsResponse> updateSettings(
      $grpc.ServiceCall call, $0.UpdateSettingsRequest request);

  $async.Future<$0.GetSystemInfoResponse> getSystemInfo_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSystemInfoRequest> $request) async {
    return getSystemInfo($call, await $request);
  }

  $async.Future<$0.GetSystemInfoResponse> getSystemInfo(
      $grpc.ServiceCall call, $0.GetSystemInfoRequest request);

  $async.Future<$0.TestProviderResponse> testProvider_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.TestProviderRequest> $request) async {
    return testProvider($call, await $request);
  }

  $async.Future<$0.TestProviderResponse> testProvider(
      $grpc.ServiceCall call, $0.TestProviderRequest request);
}
