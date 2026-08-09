// This is a generated file - do not edit.
//
// Generated from culpeostudio/spark/v1/spark.proto.

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

import 'spark.pb.dart' as $0;

export 'spark.pb.dart';

/// SparkService owns the agent's projects and answers the permission prompts a
/// running agent turn raises.
@$pb.GrpcServiceName('culpeostudio.spark.v1.SparkService')
class SparkServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SparkServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListProjectsResponse> listProjects(
    $0.ListProjectsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listProjects, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreateProjectResponse> createProject(
    $0.CreateProjectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createProject, request, options: options);
  }

  $grpc.ResponseFuture<$0.RenameProjectResponse> renameProject(
    $0.RenameProjectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$renameProject, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteProjectResponse> deleteProject(
    $0.DeleteProjectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteProject, request, options: options);
  }

  $grpc.ResponseFuture<$0.RespondToPermissionResponse> respondToPermission(
    $0.RespondToPermissionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$respondToPermission, request, options: options);
  }

  // method descriptors

  static final _$listProjects =
      $grpc.ClientMethod<$0.ListProjectsRequest, $0.ListProjectsResponse>(
          '/culpeostudio.spark.v1.SparkService/ListProjects',
          ($0.ListProjectsRequest value) => value.writeToBuffer(),
          $0.ListProjectsResponse.fromBuffer);
  static final _$createProject =
      $grpc.ClientMethod<$0.CreateProjectRequest, $0.CreateProjectResponse>(
          '/culpeostudio.spark.v1.SparkService/CreateProject',
          ($0.CreateProjectRequest value) => value.writeToBuffer(),
          $0.CreateProjectResponse.fromBuffer);
  static final _$renameProject =
      $grpc.ClientMethod<$0.RenameProjectRequest, $0.RenameProjectResponse>(
          '/culpeostudio.spark.v1.SparkService/RenameProject',
          ($0.RenameProjectRequest value) => value.writeToBuffer(),
          $0.RenameProjectResponse.fromBuffer);
  static final _$deleteProject =
      $grpc.ClientMethod<$0.DeleteProjectRequest, $0.DeleteProjectResponse>(
          '/culpeostudio.spark.v1.SparkService/DeleteProject',
          ($0.DeleteProjectRequest value) => value.writeToBuffer(),
          $0.DeleteProjectResponse.fromBuffer);
  static final _$respondToPermission = $grpc.ClientMethod<
          $0.RespondToPermissionRequest, $0.RespondToPermissionResponse>(
      '/culpeostudio.spark.v1.SparkService/RespondToPermission',
      ($0.RespondToPermissionRequest value) => value.writeToBuffer(),
      $0.RespondToPermissionResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.spark.v1.SparkService')
abstract class SparkServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.spark.v1.SparkService';

  SparkServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListProjectsRequest, $0.ListProjectsResponse>(
            'ListProjects',
            listProjects_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListProjectsRequest.fromBuffer(value),
            ($0.ListProjectsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CreateProjectRequest, $0.CreateProjectResponse>(
            'CreateProject',
            createProject_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateProjectRequest.fromBuffer(value),
            ($0.CreateProjectResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RenameProjectRequest, $0.RenameProjectResponse>(
            'RenameProject',
            renameProject_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RenameProjectRequest.fromBuffer(value),
            ($0.RenameProjectResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteProjectRequest, $0.DeleteProjectResponse>(
            'DeleteProject',
            deleteProject_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteProjectRequest.fromBuffer(value),
            ($0.DeleteProjectResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RespondToPermissionRequest,
            $0.RespondToPermissionResponse>(
        'RespondToPermission',
        respondToPermission_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RespondToPermissionRequest.fromBuffer(value),
        ($0.RespondToPermissionResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListProjectsResponse> listProjects_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListProjectsRequest> $request) async {
    return listProjects($call, await $request);
  }

  $async.Future<$0.ListProjectsResponse> listProjects(
      $grpc.ServiceCall call, $0.ListProjectsRequest request);

  $async.Future<$0.CreateProjectResponse> createProject_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateProjectRequest> $request) async {
    return createProject($call, await $request);
  }

  $async.Future<$0.CreateProjectResponse> createProject(
      $grpc.ServiceCall call, $0.CreateProjectRequest request);

  $async.Future<$0.RenameProjectResponse> renameProject_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RenameProjectRequest> $request) async {
    return renameProject($call, await $request);
  }

  $async.Future<$0.RenameProjectResponse> renameProject(
      $grpc.ServiceCall call, $0.RenameProjectRequest request);

  $async.Future<$0.DeleteProjectResponse> deleteProject_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteProjectRequest> $request) async {
    return deleteProject($call, await $request);
  }

  $async.Future<$0.DeleteProjectResponse> deleteProject(
      $grpc.ServiceCall call, $0.DeleteProjectRequest request);

  $async.Future<$0.RespondToPermissionResponse> respondToPermission_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RespondToPermissionRequest> $request) async {
    return respondToPermission($call, await $request);
  }

  $async.Future<$0.RespondToPermissionResponse> respondToPermission(
      $grpc.ServiceCall call, $0.RespondToPermissionRequest request);
}
