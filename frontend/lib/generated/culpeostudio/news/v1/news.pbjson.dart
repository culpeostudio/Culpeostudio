// This is a generated file - do not edit.
//
// Generated from culpeostudio/news/v1/news.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use newsItemDescriptor instead')
const NewsItem$json = {
  '1': 'NewsItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'content', '3': 3, '4': 1, '5': 9, '10': 'content'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {
      '1': 'published_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'publishedAt'
    },
    {'1': 'tags', '3': 6, '4': 3, '5': 9, '10': 'tags'},
    {'1': 'image_url', '3': 7, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'url', '3': 8, '4': 1, '5': 9, '10': 'url'},
    {'1': 'category', '3': 9, '4': 1, '5': 9, '10': 'category'},
  ],
};

/// Descriptor for `NewsItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newsItemDescriptor = $convert.base64Decode(
    'CghOZXdzSXRlbRIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEhgKB2Nvbn'
    'RlbnQYAyABKAlSB2NvbnRlbnQSFgoGYXV0aG9yGAQgASgJUgZhdXRob3ISPQoMcHVibGlzaGVk'
    'X2F0GAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFILcHVibGlzaGVkQXQSEgoEdG'
    'FncxgGIAMoCVIEdGFncxIbCglpbWFnZV91cmwYByABKAlSCGltYWdlVXJsEhAKA3VybBgIIAEo'
    'CVIDdXJsEhoKCGNhdGVnb3J5GAkgASgJUghjYXRlZ29yeQ==');

@$core.Deprecated('Use savedArticleDescriptor instead')
const SavedArticle$json = {
  '1': 'SavedArticle',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.news.v1.NewsItem',
      '10': 'item'
    },
    {
      '1': 'saved_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'savedAt'
    },
  ],
};

/// Descriptor for `SavedArticle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List savedArticleDescriptor = $convert.base64Decode(
    'CgxTYXZlZEFydGljbGUSMgoEaXRlbRgBIAEoCzIeLmN1bHBlb3N0dWRpby5uZXdzLnYxLk5ld3'
    'NJdGVtUgRpdGVtEjUKCHNhdmVkX2F0GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt'
    'cFIHc2F2ZWRBdA==');

@$core.Deprecated('Use listNewsRequestDescriptor instead')
const ListNewsRequest$json = {
  '1': 'ListNewsRequest',
};

/// Descriptor for `ListNewsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNewsRequestDescriptor =
    $convert.base64Decode('Cg9MaXN0TmV3c1JlcXVlc3Q=');

@$core.Deprecated('Use listNewsResponseDescriptor instead')
const ListNewsResponse$json = {
  '1': 'ListNewsResponse',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.news.v1.NewsItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListNewsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNewsResponseDescriptor = $convert.base64Decode(
    'ChBMaXN0TmV3c1Jlc3BvbnNlEjQKBWl0ZW1zGAEgAygLMh4uY3VscGVvc3R1ZGlvLm5ld3Mudj'
    'EuTmV3c0l0ZW1SBWl0ZW1z');

@$core.Deprecated('Use getNewsRequestDescriptor instead')
const GetNewsRequest$json = {
  '1': 'GetNewsRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetNewsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getNewsRequestDescriptor =
    $convert.base64Decode('Cg5HZXROZXdzUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use getNewsResponseDescriptor instead')
const GetNewsResponse$json = {
  '1': 'GetNewsResponse',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.news.v1.NewsItem',
      '10': 'item'
    },
  ],
};

/// Descriptor for `GetNewsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getNewsResponseDescriptor = $convert.base64Decode(
    'Cg9HZXROZXdzUmVzcG9uc2USMgoEaXRlbRgBIAEoCzIeLmN1bHBlb3N0dWRpby5uZXdzLnYxLk'
    '5ld3NJdGVtUgRpdGVt');

@$core.Deprecated('Use listSavedArticlesRequestDescriptor instead')
const ListSavedArticlesRequest$json = {
  '1': 'ListSavedArticlesRequest',
};

/// Descriptor for `ListSavedArticlesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSavedArticlesRequestDescriptor =
    $convert.base64Decode('ChhMaXN0U2F2ZWRBcnRpY2xlc1JlcXVlc3Q=');

@$core.Deprecated('Use listSavedArticlesResponseDescriptor instead')
const ListSavedArticlesResponse$json = {
  '1': 'ListSavedArticlesResponse',
  '2': [
    {
      '1': 'articles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.news.v1.SavedArticle',
      '10': 'articles'
    },
  ],
};

/// Descriptor for `ListSavedArticlesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSavedArticlesResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0U2F2ZWRBcnRpY2xlc1Jlc3BvbnNlEj4KCGFydGljbGVzGAEgAygLMiIuY3VscGVvc3'
        'R1ZGlvLm5ld3MudjEuU2F2ZWRBcnRpY2xlUghhcnRpY2xlcw==');

@$core.Deprecated('Use saveArticleRequestDescriptor instead')
const SaveArticleRequest$json = {
  '1': 'SaveArticleRequest',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.news.v1.NewsItem',
      '10': 'item'
    },
  ],
};

/// Descriptor for `SaveArticleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveArticleRequestDescriptor = $convert.base64Decode(
    'ChJTYXZlQXJ0aWNsZVJlcXVlc3QSMgoEaXRlbRgBIAEoCzIeLmN1bHBlb3N0dWRpby5uZXdzLn'
    'YxLk5ld3NJdGVtUgRpdGVt');

@$core.Deprecated('Use saveArticleResponseDescriptor instead')
const SaveArticleResponse$json = {
  '1': 'SaveArticleResponse',
  '2': [
    {
      '1': 'article',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.news.v1.SavedArticle',
      '10': 'article'
    },
  ],
};

/// Descriptor for `SaveArticleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveArticleResponseDescriptor = $convert.base64Decode(
    'ChNTYXZlQXJ0aWNsZVJlc3BvbnNlEjwKB2FydGljbGUYASABKAsyIi5jdWxwZW9zdHVkaW8ubm'
    'V3cy52MS5TYXZlZEFydGljbGVSB2FydGljbGU=');

@$core.Deprecated('Use deleteSavedArticleRequestDescriptor instead')
const DeleteSavedArticleRequest$json = {
  '1': 'DeleteSavedArticleRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteSavedArticleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSavedArticleRequestDescriptor =
    $convert.base64Decode(
        'ChlEZWxldGVTYXZlZEFydGljbGVSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use deleteSavedArticleResponseDescriptor instead')
const DeleteSavedArticleResponse$json = {
  '1': 'DeleteSavedArticleResponse',
};

/// Descriptor for `DeleteSavedArticleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSavedArticleResponseDescriptor =
    $convert.base64Decode('ChpEZWxldGVTYXZlZEFydGljbGVSZXNwb25zZQ==');
