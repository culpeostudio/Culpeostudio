// This is a generated file - do not edit.
//
// Generated from culpeostudio/skills/v1/skills.proto.

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

import 'skills.pb.dart' as $0;

export 'skills.pb.dart';

/// SkillsService manages the locally installed skill definitions: listing them,
/// importing new ones from disk, toggling them and removing them again.
@$pb.GrpcServiceName('culpeostudio.skills.v1.SkillsService')
class SkillsServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SkillsServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListSkillsResponse> listSkills(
    $0.ListSkillsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSkills, request, options: options);
  }

  $grpc.ResponseFuture<$0.ImportSkillResponse> importSkill(
    $0.ImportSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$importSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateSkillResponse> updateSkill(
    $0.UpdateSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSkillResponse> deleteSkill(
    $0.DeleteSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.RescanSkillsResponse> rescanSkills(
    $0.RescanSkillsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rescanSkills, request, options: options);
  }

  // method descriptors

  static final _$listSkills =
      $grpc.ClientMethod<$0.ListSkillsRequest, $0.ListSkillsResponse>(
          '/culpeostudio.skills.v1.SkillsService/ListSkills',
          ($0.ListSkillsRequest value) => value.writeToBuffer(),
          $0.ListSkillsResponse.fromBuffer);
  static final _$importSkill =
      $grpc.ClientMethod<$0.ImportSkillRequest, $0.ImportSkillResponse>(
          '/culpeostudio.skills.v1.SkillsService/ImportSkill',
          ($0.ImportSkillRequest value) => value.writeToBuffer(),
          $0.ImportSkillResponse.fromBuffer);
  static final _$updateSkill =
      $grpc.ClientMethod<$0.UpdateSkillRequest, $0.UpdateSkillResponse>(
          '/culpeostudio.skills.v1.SkillsService/UpdateSkill',
          ($0.UpdateSkillRequest value) => value.writeToBuffer(),
          $0.UpdateSkillResponse.fromBuffer);
  static final _$deleteSkill =
      $grpc.ClientMethod<$0.DeleteSkillRequest, $0.DeleteSkillResponse>(
          '/culpeostudio.skills.v1.SkillsService/DeleteSkill',
          ($0.DeleteSkillRequest value) => value.writeToBuffer(),
          $0.DeleteSkillResponse.fromBuffer);
  static final _$rescanSkills =
      $grpc.ClientMethod<$0.RescanSkillsRequest, $0.RescanSkillsResponse>(
          '/culpeostudio.skills.v1.SkillsService/RescanSkills',
          ($0.RescanSkillsRequest value) => value.writeToBuffer(),
          $0.RescanSkillsResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.skills.v1.SkillsService')
abstract class SkillsServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.skills.v1.SkillsService';

  SkillsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListSkillsRequest, $0.ListSkillsResponse>(
        'ListSkills',
        listSkills_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListSkillsRequest.fromBuffer(value),
        ($0.ListSkillsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ImportSkillRequest, $0.ImportSkillResponse>(
            'ImportSkill',
            importSkill_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ImportSkillRequest.fromBuffer(value),
            ($0.ImportSkillResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateSkillRequest, $0.UpdateSkillResponse>(
            'UpdateSkill',
            updateSkill_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateSkillRequest.fromBuffer(value),
            ($0.UpdateSkillResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteSkillRequest, $0.DeleteSkillResponse>(
            'DeleteSkill',
            deleteSkill_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteSkillRequest.fromBuffer(value),
            ($0.DeleteSkillResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RescanSkillsRequest, $0.RescanSkillsResponse>(
            'RescanSkills',
            rescanSkills_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RescanSkillsRequest.fromBuffer(value),
            ($0.RescanSkillsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListSkillsResponse> listSkills_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListSkillsRequest> $request) async {
    return listSkills($call, await $request);
  }

  $async.Future<$0.ListSkillsResponse> listSkills(
      $grpc.ServiceCall call, $0.ListSkillsRequest request);

  $async.Future<$0.ImportSkillResponse> importSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ImportSkillRequest> $request) async {
    return importSkill($call, await $request);
  }

  $async.Future<$0.ImportSkillResponse> importSkill(
      $grpc.ServiceCall call, $0.ImportSkillRequest request);

  $async.Future<$0.UpdateSkillResponse> updateSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateSkillRequest> $request) async {
    return updateSkill($call, await $request);
  }

  $async.Future<$0.UpdateSkillResponse> updateSkill(
      $grpc.ServiceCall call, $0.UpdateSkillRequest request);

  $async.Future<$0.DeleteSkillResponse> deleteSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteSkillRequest> $request) async {
    return deleteSkill($call, await $request);
  }

  $async.Future<$0.DeleteSkillResponse> deleteSkill(
      $grpc.ServiceCall call, $0.DeleteSkillRequest request);

  $async.Future<$0.RescanSkillsResponse> rescanSkills_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RescanSkillsRequest> $request) async {
    return rescanSkills($call, await $request);
  }

  $async.Future<$0.RescanSkillsResponse> rescanSkills(
      $grpc.ServiceCall call, $0.RescanSkillsRequest request);
}
