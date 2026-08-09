// This is a generated file - do not edit.
//
// Generated from culpeostudio/news/v1/news.proto.

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

import 'news.pb.dart' as $0;

export 'news.pb.dart';

/// NewsService serves the fetched news feed and each user's reading list.
@$pb.GrpcServiceName('culpeostudio.news.v1.NewsService')
class NewsServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NewsServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListNewsResponse> listNews(
    $0.ListNewsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listNews, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetNewsResponse> getNews(
    $0.GetNewsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getNews, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListSavedArticlesResponse> listSavedArticles(
    $0.ListSavedArticlesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSavedArticles, request, options: options);
  }

  $grpc.ResponseFuture<$0.SaveArticleResponse> saveArticle(
    $0.SaveArticleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveArticle, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSavedArticleResponse> deleteSavedArticle(
    $0.DeleteSavedArticleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSavedArticle, request, options: options);
  }

  // method descriptors

  static final _$listNews =
      $grpc.ClientMethod<$0.ListNewsRequest, $0.ListNewsResponse>(
          '/culpeostudio.news.v1.NewsService/ListNews',
          ($0.ListNewsRequest value) => value.writeToBuffer(),
          $0.ListNewsResponse.fromBuffer);
  static final _$getNews =
      $grpc.ClientMethod<$0.GetNewsRequest, $0.GetNewsResponse>(
          '/culpeostudio.news.v1.NewsService/GetNews',
          ($0.GetNewsRequest value) => value.writeToBuffer(),
          $0.GetNewsResponse.fromBuffer);
  static final _$listSavedArticles = $grpc.ClientMethod<
          $0.ListSavedArticlesRequest, $0.ListSavedArticlesResponse>(
      '/culpeostudio.news.v1.NewsService/ListSavedArticles',
      ($0.ListSavedArticlesRequest value) => value.writeToBuffer(),
      $0.ListSavedArticlesResponse.fromBuffer);
  static final _$saveArticle =
      $grpc.ClientMethod<$0.SaveArticleRequest, $0.SaveArticleResponse>(
          '/culpeostudio.news.v1.NewsService/SaveArticle',
          ($0.SaveArticleRequest value) => value.writeToBuffer(),
          $0.SaveArticleResponse.fromBuffer);
  static final _$deleteSavedArticle = $grpc.ClientMethod<
          $0.DeleteSavedArticleRequest, $0.DeleteSavedArticleResponse>(
      '/culpeostudio.news.v1.NewsService/DeleteSavedArticle',
      ($0.DeleteSavedArticleRequest value) => value.writeToBuffer(),
      $0.DeleteSavedArticleResponse.fromBuffer);
}

@$pb.GrpcServiceName('culpeostudio.news.v1.NewsService')
abstract class NewsServiceBase extends $grpc.Service {
  $core.String get $name => 'culpeostudio.news.v1.NewsService';

  NewsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListNewsRequest, $0.ListNewsResponse>(
        'ListNews',
        listNews_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListNewsRequest.fromBuffer(value),
        ($0.ListNewsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetNewsRequest, $0.GetNewsResponse>(
        'GetNews',
        getNews_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetNewsRequest.fromBuffer(value),
        ($0.GetNewsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListSavedArticlesRequest,
            $0.ListSavedArticlesResponse>(
        'ListSavedArticles',
        listSavedArticles_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListSavedArticlesRequest.fromBuffer(value),
        ($0.ListSavedArticlesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SaveArticleRequest, $0.SaveArticleResponse>(
            'SaveArticle',
            saveArticle_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveArticleRequest.fromBuffer(value),
            ($0.SaveArticleResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteSavedArticleRequest,
            $0.DeleteSavedArticleResponse>(
        'DeleteSavedArticle',
        deleteSavedArticle_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteSavedArticleRequest.fromBuffer(value),
        ($0.DeleteSavedArticleResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListNewsResponse> listNews_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListNewsRequest> $request) async {
    return listNews($call, await $request);
  }

  $async.Future<$0.ListNewsResponse> listNews(
      $grpc.ServiceCall call, $0.ListNewsRequest request);

  $async.Future<$0.GetNewsResponse> getNews_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetNewsRequest> $request) async {
    return getNews($call, await $request);
  }

  $async.Future<$0.GetNewsResponse> getNews(
      $grpc.ServiceCall call, $0.GetNewsRequest request);

  $async.Future<$0.ListSavedArticlesResponse> listSavedArticles_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListSavedArticlesRequest> $request) async {
    return listSavedArticles($call, await $request);
  }

  $async.Future<$0.ListSavedArticlesResponse> listSavedArticles(
      $grpc.ServiceCall call, $0.ListSavedArticlesRequest request);

  $async.Future<$0.SaveArticleResponse> saveArticle_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SaveArticleRequest> $request) async {
    return saveArticle($call, await $request);
  }

  $async.Future<$0.SaveArticleResponse> saveArticle(
      $grpc.ServiceCall call, $0.SaveArticleRequest request);

  $async.Future<$0.DeleteSavedArticleResponse> deleteSavedArticle_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteSavedArticleRequest> $request) async {
    return deleteSavedArticle($call, await $request);
  }

  $async.Future<$0.DeleteSavedArticleResponse> deleteSavedArticle(
      $grpc.ServiceCall call, $0.DeleteSavedArticleRequest request);
}
