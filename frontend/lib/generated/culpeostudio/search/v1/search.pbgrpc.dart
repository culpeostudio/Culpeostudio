// This is a generated file - do not edit.
//
// Generated from culpeostudio/search/v1/search.proto.

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

import 'search.pb.dart' as $0;

export 'search.pb.dart';

/// SearchService is CulpeoSearch: concurrent metasearch across public engines
/// and extraction of a single page.
@$pb.GrpcServiceName('culpeostudio.search.v1.SearchService')
class SearchServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SearchServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SearchResponse> search(
    $0.SearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$search, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExtractResponse> extract(
    $0.ExtractRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$extract, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListEnginesResponse> listEngines(
    $0.ListEnginesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listEngines, request, options: options);
  }

  // method descriptors

  static final _$search =
      $grpc.ClientMethod<$0.SearchRequest, $0.SearchResponse>(
          '/culpeostudio.search.v1.SearchService/Search',
          ($0.SearchRequest value) => value.writeToBuffer(),
          $0.SearchResponse.fromBuffer);
  static final _$extract =
      $grpc.ClientMethod<$0.ExtractRequest, $0.ExtractResponse>(
          '/culpeostudio.search.v1.SearchService/Extract',
          ($0.ExtractRequest value) => value.writeToBuffer(),
          $0.ExtractResponse.fromBuffer);
  static final _$listEngines =
      $grpc.ClientMethod<$0.ListEnginesRequest, $0.ListEnginesResponse>(
          '/culpeostudio.search.v1.SearchService/ListEngines',
          ($0.ListEnginesRequest value) => value.writeToBuffer(),
          $0.ListEnginesResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.search.v1.SearchService')
abstract class SearchServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.search.v1.SearchService';

  SearchServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SearchRequest, $0.SearchResponse>(
        'Search',
        search_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SearchRequest.fromBuffer(value),
        ($0.SearchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExtractRequest, $0.ExtractResponse>(
        'Extract',
        extract_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExtractRequest.fromBuffer(value),
        ($0.ExtractResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListEnginesRequest, $0.ListEnginesResponse>(
            'ListEngines',
            listEngines_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListEnginesRequest.fromBuffer(value),
            ($0.ListEnginesResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SearchResponse> search_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SearchRequest> $request) async {
    return search($call, await $request);
  }

  $async.Future<$0.SearchResponse> search(
      $grpc.ServiceCall call, $0.SearchRequest request);

  $async.Future<$0.ExtractResponse> extract_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ExtractRequest> $request) async {
    return extract($call, await $request);
  }

  $async.Future<$0.ExtractResponse> extract(
      $grpc.ServiceCall call, $0.ExtractRequest request);

  $async.Future<$0.ListEnginesResponse> listEngines_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListEnginesRequest> $request) async {
    return listEngines($call, await $request);
  }

  $async.Future<$0.ListEnginesResponse> listEngines(
      $grpc.ServiceCall call, $0.ListEnginesRequest request);
}
