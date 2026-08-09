// This is a generated file - do not edit.
//
// Generated from culpeostudio/search/v1/search.proto.

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

@$core.Deprecated('Use categoryDescriptor instead')
const Category$json = {
  '1': 'Category',
  '2': [
    {'1': 'CATEGORY_UNSPECIFIED', '2': 0},
    {'1': 'CATEGORY_TEXT', '2': 1},
    {'1': 'CATEGORY_NEWS', '2': 2},
    {'1': 'CATEGORY_IMAGES', '2': 3},
    {'1': 'CATEGORY_VIDEOS', '2': 4},
    {'1': 'CATEGORY_BOOKS', '2': 5},
  ],
};

/// Descriptor for `Category`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List categoryDescriptor = $convert.base64Decode(
    'CghDYXRlZ29yeRIYChRDQVRFR09SWV9VTlNQRUNJRklFRBAAEhEKDUNBVEVHT1JZX1RFWFQQAR'
    'IRCg1DQVRFR09SWV9ORVdTEAISEwoPQ0FURUdPUllfSU1BR0VTEAMSEwoPQ0FURUdPUllfVklE'
    'RU9TEAQSEgoOQ0FURUdPUllfQk9PS1MQBQ==');

@$core.Deprecated('Use extractFormatDescriptor instead')
const ExtractFormat$json = {
  '1': 'ExtractFormat',
  '2': [
    {'1': 'EXTRACT_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'EXTRACT_FORMAT_TEXT', '2': 1},
    {'1': 'EXTRACT_FORMAT_CONTENT', '2': 2},
    {'1': 'EXTRACT_FORMAT_TEXT_PLAIN', '2': 3},
    {'1': 'EXTRACT_FORMAT_TEXT_RICH', '2': 4},
    {'1': 'EXTRACT_FORMAT_TEXT_MARKDOWN', '2': 5},
  ],
};

/// Descriptor for `ExtractFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List extractFormatDescriptor = $convert.base64Decode(
    'Cg1FeHRyYWN0Rm9ybWF0Eh4KGkVYVFJBQ1RfRk9STUFUX1VOU1BFQ0lGSUVEEAASFwoTRVhUUk'
    'FDVF9GT1JNQVRfVEVYVBABEhoKFkVYVFJBQ1RfRk9STUFUX0NPTlRFTlQQAhIdChlFWFRSQUNU'
    'X0ZPUk1BVF9URVhUX1BMQUlOEAMSHAoYRVhUUkFDVF9GT1JNQVRfVEVYVF9SSUNIEAQSIAocRV'
    'hUUkFDVF9GT1JNQVRfVEVYVF9NQVJLRE9XThAF');

@$core.Deprecated('Use searchRequestDescriptor instead')
const SearchRequest$json = {
  '1': 'SearchRequest',
  '2': [
    {
      '1': 'category',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.search.v1.Category',
      '10': 'category'
    },
    {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    {'1': 'region', '3': 3, '4': 1, '5': 9, '10': 'region'},
    {'1': 'safesearch', '3': 4, '4': 1, '5': 9, '10': 'safesearch'},
    {'1': 'timelimit', '3': 5, '4': 1, '5': 9, '10': 'timelimit'},
    {'1': 'page', '3': 6, '4': 1, '5': 5, '10': 'page'},
    {'1': 'max_results', '3': 7, '4': 1, '5': 5, '10': 'maxResults'},
    {'1': 'backend', '3': 8, '4': 1, '5': 9, '10': 'backend'},
  ],
};

/// Descriptor for `SearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchRequestDescriptor = $convert.base64Decode(
    'Cg1TZWFyY2hSZXF1ZXN0EjwKCGNhdGVnb3J5GAEgASgOMiAuY3VscGVvc3R1ZGlvLnNlYXJjaC'
    '52MS5DYXRlZ29yeVIIY2F0ZWdvcnkSFAoFcXVlcnkYAiABKAlSBXF1ZXJ5EhYKBnJlZ2lvbhgD'
    'IAEoCVIGcmVnaW9uEh4KCnNhZmVzZWFyY2gYBCABKAlSCnNhZmVzZWFyY2gSHAoJdGltZWxpbW'
    'l0GAUgASgJUgl0aW1lbGltaXQSEgoEcGFnZRgGIAEoBVIEcGFnZRIfCgttYXhfcmVzdWx0cxgH'
    'IAEoBVIKbWF4UmVzdWx0cxIYCgdiYWNrZW5kGAggASgJUgdiYWNrZW5k');

@$core.Deprecated('Use searchResultDescriptor instead')
const SearchResult$json = {
  '1': 'SearchResult',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'href', '3': 2, '4': 1, '5': 9, '10': 'href'},
    {'1': 'body', '3': 3, '4': 1, '5': 9, '10': 'body'},
    {'1': 'image', '3': 4, '4': 1, '5': 9, '10': 'image'},
    {'1': 'thumbnail', '3': 5, '4': 1, '5': 9, '10': 'thumbnail'},
    {'1': 'url', '3': 6, '4': 1, '5': 9, '10': 'url'},
    {'1': 'height', '3': 7, '4': 1, '5': 9, '10': 'height'},
    {'1': 'width', '3': 8, '4': 1, '5': 9, '10': 'width'},
    {'1': 'source', '3': 9, '4': 1, '5': 9, '10': 'source'},
    {'1': 'date', '3': 10, '4': 1, '5': 9, '10': 'date'},
    {'1': 'content', '3': 11, '4': 1, '5': 9, '10': 'content'},
    {'1': 'description', '3': 12, '4': 1, '5': 9, '10': 'description'},
    {'1': 'duration', '3': 13, '4': 1, '5': 9, '10': 'duration'},
    {'1': 'embed_html', '3': 14, '4': 1, '5': 9, '10': 'embedHtml'},
    {'1': 'embed_url', '3': 15, '4': 1, '5': 9, '10': 'embedUrl'},
    {'1': 'image_token', '3': 16, '4': 1, '5': 9, '10': 'imageToken'},
    {'1': 'provider', '3': 17, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'published', '3': 18, '4': 1, '5': 9, '10': 'published'},
    {'1': 'publisher', '3': 19, '4': 1, '5': 9, '10': 'publisher'},
    {'1': 'uploader', '3': 20, '4': 1, '5': 9, '10': 'uploader'},
    {'1': 'author', '3': 21, '4': 1, '5': 9, '10': 'author'},
    {'1': 'info', '3': 22, '4': 1, '5': 9, '10': 'info'},
  ],
};

/// Descriptor for `SearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResultDescriptor = $convert.base64Decode(
    'CgxTZWFyY2hSZXN1bHQSFAoFdGl0bGUYASABKAlSBXRpdGxlEhIKBGhyZWYYAiABKAlSBGhyZW'
    'YSEgoEYm9keRgDIAEoCVIEYm9keRIUCgVpbWFnZRgEIAEoCVIFaW1hZ2USHAoJdGh1bWJuYWls'
    'GAUgASgJUgl0aHVtYm5haWwSEAoDdXJsGAYgASgJUgN1cmwSFgoGaGVpZ2h0GAcgASgJUgZoZW'
    'lnaHQSFAoFd2lkdGgYCCABKAlSBXdpZHRoEhYKBnNvdXJjZRgJIAEoCVIGc291cmNlEhIKBGRh'
    'dGUYCiABKAlSBGRhdGUSGAoHY29udGVudBgLIAEoCVIHY29udGVudBIgCgtkZXNjcmlwdGlvbh'
    'gMIAEoCVILZGVzY3JpcHRpb24SGgoIZHVyYXRpb24YDSABKAlSCGR1cmF0aW9uEh0KCmVtYmVk'
    'X2h0bWwYDiABKAlSCWVtYmVkSHRtbBIbCgllbWJlZF91cmwYDyABKAlSCGVtYmVkVXJsEh8KC2'
    'ltYWdlX3Rva2VuGBAgASgJUgppbWFnZVRva2VuEhoKCHByb3ZpZGVyGBEgASgJUghwcm92aWRl'
    'chIcCglwdWJsaXNoZWQYEiABKAlSCXB1Ymxpc2hlZBIcCglwdWJsaXNoZXIYEyABKAlSCXB1Ym'
    'xpc2hlchIaCgh1cGxvYWRlchgUIAEoCVIIdXBsb2FkZXISFgoGYXV0aG9yGBUgASgJUgZhdXRo'
    'b3ISEgoEaW5mbxgWIAEoCVIEaW5mbw==');

@$core.Deprecated('Use searchResponseDescriptor instead')
const SearchResponse$json = {
  '1': 'SearchResponse',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {
      '1': 'results',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.search.v1.SearchResult',
      '10': 'results'
    },
    {'1': 'count', '3': 3, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `SearchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResponseDescriptor = $convert.base64Decode(
    'Cg5TZWFyY2hSZXNwb25zZRIUCgVxdWVyeRgBIAEoCVIFcXVlcnkSPgoHcmVzdWx0cxgCIAMoCz'
    'IkLmN1bHBlb3N0dWRpby5zZWFyY2gudjEuU2VhcmNoUmVzdWx0UgdyZXN1bHRzEhQKBWNvdW50'
    'GAMgASgFUgVjb3VudA==');

@$core.Deprecated('Use extractRequestDescriptor instead')
const ExtractRequest$json = {
  '1': 'ExtractRequest',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {
      '1': 'format',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.search.v1.ExtractFormat',
      '10': 'format'
    },
  ],
};

/// Descriptor for `ExtractRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extractRequestDescriptor = $convert.base64Decode(
    'Cg5FeHRyYWN0UmVxdWVzdBIQCgN1cmwYASABKAlSA3VybBI9CgZmb3JtYXQYAiABKA4yJS5jdW'
    'xwZW9zdHVkaW8uc2VhcmNoLnYxLkV4dHJhY3RGb3JtYXRSBmZvcm1hdA==');

@$core.Deprecated('Use extractResponseDescriptor instead')
const ExtractResponse$json = {
  '1': 'ExtractResponse',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {
      '1': 'format',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.search.v1.ExtractFormat',
      '10': 'format'
    },
    {'1': 'content', '3': 3, '4': 1, '5': 9, '10': 'content'},
    {'1': 'raw_content', '3': 4, '4': 1, '5': 12, '10': 'rawContent'},
  ],
};

/// Descriptor for `ExtractResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extractResponseDescriptor = $convert.base64Decode(
    'Cg9FeHRyYWN0UmVzcG9uc2USEAoDdXJsGAEgASgJUgN1cmwSPQoGZm9ybWF0GAIgASgOMiUuY3'
    'VscGVvc3R1ZGlvLnNlYXJjaC52MS5FeHRyYWN0Rm9ybWF0UgZmb3JtYXQSGAoHY29udGVudBgD'
    'IAEoCVIHY29udGVudBIfCgtyYXdfY29udGVudBgEIAEoDFIKcmF3Q29udGVudA==');

@$core.Deprecated('Use listEnginesRequestDescriptor instead')
const ListEnginesRequest$json = {
  '1': 'ListEnginesRequest',
};

/// Descriptor for `ListEnginesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEnginesRequestDescriptor =
    $convert.base64Decode('ChJMaXN0RW5naW5lc1JlcXVlc3Q=');

@$core.Deprecated('Use listEnginesResponseDescriptor instead')
const ListEnginesResponse$json = {
  '1': 'ListEnginesResponse',
  '2': [
    {
      '1': 'engines',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.search.v1.ListEnginesResponse.EnginesEntry',
      '10': 'engines'
    },
  ],
  '3': [ListEnginesResponse_EnginesEntry$json],
};

@$core.Deprecated('Use listEnginesResponseDescriptor instead')
const ListEnginesResponse_EnginesEntry$json = {
  '1': 'EnginesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.search.v1.EngineNames',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `ListEnginesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEnginesResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0RW5naW5lc1Jlc3BvbnNlElIKB2VuZ2luZXMYASADKAsyOC5jdWxwZW9zdHVkaW8uc2'
    'VhcmNoLnYxLkxpc3RFbmdpbmVzUmVzcG9uc2UuRW5naW5lc0VudHJ5UgdlbmdpbmVzGl8KDEVu'
    'Z2luZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI5CgV2YWx1ZRgCIAEoCzIjLmN1bHBlb3N0dW'
    'Rpby5zZWFyY2gudjEuRW5naW5lTmFtZXNSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use engineNamesDescriptor instead')
const EngineNames$json = {
  '1': 'EngineNames',
  '2': [
    {'1': 'names', '3': 1, '4': 3, '5': 9, '10': 'names'},
  ],
};

/// Descriptor for `EngineNames`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineNamesDescriptor =
    $convert.base64Decode('CgtFbmdpbmVOYW1lcxIUCgVuYW1lcxgBIAMoCVIFbmFtZXM=');
