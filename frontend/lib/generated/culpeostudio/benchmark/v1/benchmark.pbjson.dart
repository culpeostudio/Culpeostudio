// This is a generated file - do not edit.
//
// Generated from culpeostudio/benchmark/v1/benchmark.proto.

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

@$core.Deprecated('Use boardStateDescriptor instead')
const BoardState$json = {
  '1': 'BoardState',
  '2': [
    {'1': 'BOARD_STATE_UNSPECIFIED', '2': 0},
    {'1': 'BOARD_STATE_EMPTY', '2': 1},
    {'1': 'BOARD_STATE_LOADING', '2': 2},
    {'1': 'BOARD_STATE_READY', '2': 3},
    {'1': 'BOARD_STATE_ERROR', '2': 4},
  ],
};

/// Descriptor for `BoardState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List boardStateDescriptor = $convert.base64Decode(
    'CgpCb2FyZFN0YXRlEhsKF0JPQVJEX1NUQVRFX1VOU1BFQ0lGSUVEEAASFQoRQk9BUkRfU1RBVE'
    'VfRU1QVFkQARIXChNCT0FSRF9TVEFURV9MT0FESU5HEAISFQoRQk9BUkRfU1RBVEVfUkVBRFkQ'
    'AxIVChFCT0FSRF9TVEFURV9FUlJPUhAE');

@$core.Deprecated('Use sortOrderDescriptor instead')
const SortOrder$json = {
  '1': 'SortOrder',
  '2': [
    {'1': 'SORT_ORDER_UNSPECIFIED', '2': 0},
    {'1': 'SORT_ORDER_ASC', '2': 1},
    {'1': 'SORT_ORDER_DESC', '2': 2},
  ],
};

/// Descriptor for `SortOrder`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sortOrderDescriptor = $convert.base64Decode(
    'CglTb3J0T3JkZXISGgoWU09SVF9PUkRFUl9VTlNQRUNJRklFRBAAEhIKDlNPUlRfT1JERVJfQV'
    'NDEAESEwoPU09SVF9PUkRFUl9ERVNDEAI=');

@$core.Deprecated('Use detailDescriptor instead')
const Detail$json = {
  '1': 'Detail',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `Detail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detailDescriptor = $convert.base64Decode(
    'CgZEZXRhaWwSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVl');

@$core.Deprecated('Use entryDescriptor instead')
const Entry$json = {
  '1': 'Entry',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'model_id', '3': 4, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'org', '3': 5, '4': 1, '5': 9, '10': 'org'},
    {'1': 'license', '3': 6, '4': 1, '5': 9, '10': 'license'},
    {'1': 'url', '3': 7, '4': 1, '5': 9, '10': 'url'},
    {'1': 'type', '3': 8, '4': 1, '5': 9, '10': 'type'},
    {'1': 'open_weights', '3': 9, '4': 1, '5': 8, '10': 'openWeights'},
    {'1': 'eval_date', '3': 10, '4': 1, '5': 9, '10': 'evalDate'},
    {'1': 'primary', '3': 11, '4': 1, '5': 1, '10': 'primary'},
    {
      '1': 'scores',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry.ScoresEntry',
      '10': 'scores'
    },
    {'1': 'rank', '3': 13, '4': 1, '5': 5, '10': 'rank'},
    {
      '1': 'details',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Detail',
      '10': 'details'
    },
  ],
  '3': [Entry_ScoresEntry$json],
};

@$core.Deprecated('Use entryDescriptor instead')
const Entry_ScoresEntry$json = {
  '1': 'ScoresEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 1, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Entry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entryDescriptor = $convert.base64Decode(
    'CgVFbnRyeRIUCgVib2FyZBgBIAEoCVIFYm9hcmQSEAoDa2V5GAIgASgJUgNrZXkSEgoEbmFtZR'
    'gDIAEoCVIEbmFtZRIZCghtb2RlbF9pZBgEIAEoCVIHbW9kZWxJZBIQCgNvcmcYBSABKAlSA29y'
    'ZxIYCgdsaWNlbnNlGAYgASgJUgdsaWNlbnNlEhAKA3VybBgHIAEoCVIDdXJsEhIKBHR5cGUYCC'
    'ABKAlSBHR5cGUSIQoMb3Blbl93ZWlnaHRzGAkgASgIUgtvcGVuV2VpZ2h0cxIbCglldmFsX2Rh'
    'dGUYCiABKAlSCGV2YWxEYXRlEhgKB3ByaW1hcnkYCyABKAFSB3ByaW1hcnkSRAoGc2NvcmVzGA'
    'wgAygLMiwuY3VscGVvc3R1ZGlvLmJlbmNobWFyay52MS5FbnRyeS5TY29yZXNFbnRyeVIGc2Nv'
    'cmVzEhIKBHJhbmsYDSABKAVSBHJhbmsSOwoHZGV0YWlscxgOIAMoCzIhLmN1bHBlb3N0dWRpby'
    '5iZW5jaG1hcmsudjEuRGV0YWlsUgdkZXRhaWxzGjkKC1Njb3Jlc0VudHJ5EhAKA2tleRgBIAEo'
    'CVIDa2V5EhQKBXZhbHVlGAIgASgBUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use metricInfoDescriptor instead')
const MetricInfo$json = {
  '1': 'MetricInfo',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'family', '3': 3, '4': 1, '5': 9, '10': 'family'},
    {'1': 'shots', '3': 4, '4': 1, '5': 9, '10': 'shots'},
    {'1': 'dataset', '3': 5, '4': 1, '5': 9, '10': 'dataset'},
    {'1': 'url', '3': 6, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `MetricInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List metricInfoDescriptor = $convert.base64Decode(
    'CgpNZXRyaWNJbmZvEhAKA2tleRgBIAEoCVIDa2V5EhQKBWxhYmVsGAIgASgJUgVsYWJlbBIWCg'
    'ZmYW1pbHkYAyABKAlSBmZhbWlseRIUCgVzaG90cxgEIAEoCVIFc2hvdHMSGAoHZGF0YXNldBgF'
    'IAEoCVIHZGF0YXNldBIQCgN1cmwYBiABKAlSA3VybA==');

@$core.Deprecated('Use metricStatsDescriptor instead')
const MetricStats$json = {
  '1': 'MetricStats',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'min', '3': 2, '4': 1, '5': 1, '10': 'min'},
    {'1': 'max', '3': 3, '4': 1, '5': 1, '10': 'max'},
    {'1': 'mean', '3': 4, '4': 1, '5': 1, '10': 'mean'},
    {'1': 'median', '3': 5, '4': 1, '5': 1, '10': 'median'},
    {'1': 'top_model', '3': 6, '4': 1, '5': 9, '10': 'topModel'},
    {'1': 'top_score', '3': 7, '4': 1, '5': 1, '10': 'topScore'},
    {'1': 'evaluated', '3': 8, '4': 1, '5': 5, '10': 'evaluated'},
  ],
};

/// Descriptor for `MetricStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List metricStatsDescriptor = $convert.base64Decode(
    'CgtNZXRyaWNTdGF0cxIQCgNrZXkYASABKAlSA2tleRIQCgNtaW4YAiABKAFSA21pbhIQCgNtYX'
    'gYAyABKAFSA21heBISCgRtZWFuGAQgASgBUgRtZWFuEhYKBm1lZGlhbhgFIAEoAVIGbWVkaWFu'
    'EhsKCXRvcF9tb2RlbBgGIAEoCVIIdG9wTW9kZWwSGwoJdG9wX3Njb3JlGAcgASgBUgh0b3BTY2'
    '9yZRIcCglldmFsdWF0ZWQYCCABKAVSCWV2YWx1YXRlZA==');

@$core.Deprecated('Use sourceInfoDescriptor instead')
const SourceInfo$json = {
  '1': 'SourceInfo',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'dataset', '3': 2, '4': 1, '5': 9, '10': 'dataset'},
    {'1': 'url', '3': 3, '4': 1, '5': 9, '10': 'url'},
    {'1': 'live', '3': 4, '4': 1, '5': 8, '10': 'live'},
    {'1': 'archived', '3': 5, '4': 1, '5': 8, '10': 'archived'},
    {'1': 'archived_at', '3': 6, '4': 1, '5': 9, '10': 'archivedAt'},
    {'1': 'published_at', '3': 7, '4': 1, '5': 9, '10': 'publishedAt'},
    {'1': 'fetched_at', '3': 8, '4': 1, '5': 9, '10': 'fetchedAt'},
    {'1': 'from_cache', '3': 9, '4': 1, '5': 8, '10': 'fromCache'},
    {'1': 'entries', '3': 10, '4': 1, '5': 5, '10': 'entries'},
    {'1': 'models', '3': 11, '4': 1, '5': 5, '10': 'models'},
    {
      '1': 'state',
      '3': 12,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.benchmark.v1.BoardState',
      '10': 'state'
    },
    {'1': 'error', '3': 13, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SourceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sourceInfoDescriptor = $convert.base64Decode(
    'CgpTb3VyY2VJbmZvEhoKCHByb3ZpZGVyGAEgASgJUghwcm92aWRlchIYCgdkYXRhc2V0GAIgAS'
    'gJUgdkYXRhc2V0EhAKA3VybBgDIAEoCVIDdXJsEhIKBGxpdmUYBCABKAhSBGxpdmUSGgoIYXJj'
    'aGl2ZWQYBSABKAhSCGFyY2hpdmVkEh8KC2FyY2hpdmVkX2F0GAYgASgJUgphcmNoaXZlZEF0Ei'
    'EKDHB1Ymxpc2hlZF9hdBgHIAEoCVILcHVibGlzaGVkQXQSHQoKZmV0Y2hlZF9hdBgIIAEoCVIJ'
    'ZmV0Y2hlZEF0Eh0KCmZyb21fY2FjaGUYCSABKAhSCWZyb21DYWNoZRIYCgdlbnRyaWVzGAogAS'
    'gFUgdlbnRyaWVzEhYKBm1vZGVscxgLIAEoBVIGbW9kZWxzEjsKBXN0YXRlGAwgASgOMiUuY3Vs'
    'cGVvc3R1ZGlvLmJlbmNobWFyay52MS5Cb2FyZFN0YXRlUgVzdGF0ZRIUCgVlcnJvchgNIAEoCV'
    'IFZXJyb3I=');

@$core.Deprecated('Use boardInfoDescriptor instead')
const BoardInfo$json = {
  '1': 'BoardInfo',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'score_kind', '3': 4, '4': 1, '5': 9, '10': 'scoreKind'},
    {'1': 'primary_label', '3': 5, '4': 1, '5': 9, '10': 'primaryLabel'},
    {'1': 'score_max', '3': 6, '4': 1, '5': 1, '10': 'scoreMax'},
    {
      '1': 'metrics',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.MetricInfo',
      '10': 'metrics'
    },
    {
      '1': 'source',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.SourceInfo',
      '10': 'source'
    },
  ],
};

/// Descriptor for `BoardInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boardInfoDescriptor = $convert.base64Decode(
    'CglCb2FyZEluZm8SEAoDa2V5GAEgASgJUgNrZXkSFAoFbGFiZWwYAiABKAlSBWxhYmVsEhIKBG'
    'tpbmQYAyABKAlSBGtpbmQSHQoKc2NvcmVfa2luZBgEIAEoCVIJc2NvcmVLaW5kEiMKDXByaW1h'
    'cnlfbGFiZWwYBSABKAlSDHByaW1hcnlMYWJlbBIbCglzY29yZV9tYXgYBiABKAFSCHNjb3JlTW'
    'F4Ej8KB21ldHJpY3MYByADKAsyJS5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLk1ldHJpY0lu'
    'Zm9SB21ldHJpY3MSPQoGc291cmNlGAggASgLMiUuY3VscGVvc3R1ZGlvLmJlbmNobWFyay52MS'
    '5Tb3VyY2VJbmZvUgZzb3VyY2U=');

@$core.Deprecated('Use hubStatsDescriptor instead')
const HubStats$json = {
  '1': 'HubStats',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'likes', '3': 2, '4': 1, '5': 5, '10': 'likes'},
    {'1': 'downloads_30d', '3': 3, '4': 1, '5': 3, '10': 'downloads30d'},
    {
      '1': 'downloads_all_time',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'downloadsAllTime'
    },
    {'1': 'trending_score', '3': 5, '4': 1, '5': 1, '10': 'trendingScore'},
    {'1': 'last_modified', '3': 6, '4': 1, '5': 9, '10': 'lastModified'},
    {'1': 'pipeline_tag', '3': 7, '4': 1, '5': 9, '10': 'pipelineTag'},
    {'1': 'gated', '3': 8, '4': 1, '5': 8, '10': 'gated'},
    {'1': 'params_total', '3': 9, '4': 1, '5': 3, '10': 'paramsTotal'},
    {'1': 'tags', '3': 10, '4': 3, '5': 9, '10': 'tags'},
    {
      '1': 'inference_providers',
      '3': 11,
      '4': 3,
      '5': 9,
      '10': 'inferenceProviders'
    },
    {'1': 'missing', '3': 12, '4': 1, '5': 8, '10': 'missing'},
  ],
};

/// Descriptor for `HubStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hubStatsDescriptor = $convert.base64Decode(
    'CghIdWJTdGF0cxIZCghtb2RlbF9pZBgBIAEoCVIHbW9kZWxJZBIUCgVsaWtlcxgCIAEoBVIFbG'
    'lrZXMSIwoNZG93bmxvYWRzXzMwZBgDIAEoA1IMZG93bmxvYWRzMzBkEiwKEmRvd25sb2Fkc19h'
    'bGxfdGltZRgEIAEoA1IQZG93bmxvYWRzQWxsVGltZRIlCg50cmVuZGluZ19zY29yZRgFIAEoAV'
    'INdHJlbmRpbmdTY29yZRIjCg1sYXN0X21vZGlmaWVkGAYgASgJUgxsYXN0TW9kaWZpZWQSIQoM'
    'cGlwZWxpbmVfdGFnGAcgASgJUgtwaXBlbGluZVRhZxIUCgVnYXRlZBgIIAEoCFIFZ2F0ZWQSIQ'
    'oMcGFyYW1zX3RvdGFsGAkgASgDUgtwYXJhbXNUb3RhbBISCgR0YWdzGAogAygJUgR0YWdzEi8K'
    'E2luZmVyZW5jZV9wcm92aWRlcnMYCyADKAlSEmluZmVyZW5jZVByb3ZpZGVycxIYCgdtaXNzaW'
    '5nGAwgASgIUgdtaXNzaW5n');

@$core.Deprecated('Use cardResultDescriptor instead')
const CardResult$json = {
  '1': 'CardResult',
  '2': [
    {'1': 'task', '3': 1, '4': 1, '5': 9, '10': 'task'},
    {'1': 'dataset', '3': 2, '4': 1, '5': 9, '10': 'dataset'},
    {'1': 'metric', '3': 3, '4': 1, '5': 9, '10': 'metric'},
    {'1': 'value', '3': 4, '4': 1, '5': 1, '10': 'value'},
    {'1': 'verified', '3': 5, '4': 1, '5': 8, '10': 'verified'},
  ],
};

/// Descriptor for `CardResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cardResultDescriptor = $convert.base64Decode(
    'CgpDYXJkUmVzdWx0EhIKBHRhc2sYASABKAlSBHRhc2sSGAoHZGF0YXNldBgCIAEoCVIHZGF0YX'
    'NldBIWCgZtZXRyaWMYAyABKAlSBm1ldHJpYxIUCgV2YWx1ZRgEIAEoAVIFdmFsdWUSGgoIdmVy'
    'aWZpZWQYBSABKAhSCHZlcmlmaWVk');

@$core.Deprecated('Use deltaDescriptor instead')
const Delta$json = {
  '1': 'Delta',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 1, '10': 'value'},
    {'1': 'median', '3': 2, '4': 1, '5': 1, '10': 'median'},
    {'1': 'diff', '3': 3, '4': 1, '5': 1, '10': 'diff'},
  ],
};

/// Descriptor for `Delta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deltaDescriptor = $convert.base64Decode(
    'CgVEZWx0YRIUCgV2YWx1ZRgBIAEoAVIFdmFsdWUSFgoGbWVkaWFuGAIgASgBUgZtZWRpYW4SEg'
    'oEZGlmZhgDIAEoAVIEZGlmZg==');

@$core.Deprecated('Use modelDetailDescriptor instead')
const ModelDetail$json = {
  '1': 'ModelDetail',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
    {'1': 'model_id', '3': 2, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'entries',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry',
      '10': 'entries'
    },
    {
      '1': 'best',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry',
      '10': 'best'
    },
    {
      '1': 'metric_ranks',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.ModelDetail.MetricRanksEntry',
      '10': 'metricRanks'
    },
    {'1': 'percentile', '3': 7, '4': 1, '5': 1, '10': 'percentile'},
    {
      '1': 'peers',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry',
      '10': 'peers'
    },
    {
      '1': 'hub',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.HubStats',
      '10': 'hub'
    },
    {
      '1': 'card_results',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.CardResult',
      '10': 'cardResults'
    },
    {
      '1': 'deltas',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.ModelDetail.DeltasEntry',
      '10': 'deltas'
    },
    {
      '1': 'metrics',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.MetricInfo',
      '10': 'metrics'
    },
    {
      '1': 'source',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.SourceInfo',
      '10': 'source'
    },
    {
      '1': 'totals',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.ModelDetail.TotalsEntry',
      '10': 'totals'
    },
    {'1': 'score_kind', '3': 15, '4': 1, '5': 9, '10': 'scoreKind'},
  ],
  '3': [
    ModelDetail_MetricRanksEntry$json,
    ModelDetail_DeltasEntry$json,
    ModelDetail_TotalsEntry$json
  ],
};

@$core.Deprecated('Use modelDetailDescriptor instead')
const ModelDetail_MetricRanksEntry$json = {
  '1': 'MetricRanksEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use modelDetailDescriptor instead')
const ModelDetail_DeltasEntry$json = {
  '1': 'DeltasEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Delta',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use modelDetailDescriptor instead')
const ModelDetail_TotalsEntry$json = {
  '1': 'TotalsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ModelDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelDetailDescriptor = $convert.base64Decode(
    'CgtNb2RlbERldGFpbBIUCgVib2FyZBgBIAEoCVIFYm9hcmQSGQoIbW9kZWxfaWQYAiABKAlSB2'
    '1vZGVsSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRI6CgdlbnRyaWVzGAQgAygLMiAuY3VscGVvc3R1'
    'ZGlvLmJlbmNobWFyay52MS5FbnRyeVIHZW50cmllcxI0CgRiZXN0GAUgASgLMiAuY3VscGVvc3'
    'R1ZGlvLmJlbmNobWFyay52MS5FbnRyeVIEYmVzdBJaCgxtZXRyaWNfcmFua3MYBiADKAsyNy5j'
    'dWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLk1vZGVsRGV0YWlsLk1ldHJpY1JhbmtzRW50cnlSC2'
    '1ldHJpY1JhbmtzEh4KCnBlcmNlbnRpbGUYByABKAFSCnBlcmNlbnRpbGUSNgoFcGVlcnMYCCAD'
    'KAsyIC5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLkVudHJ5UgVwZWVycxI1CgNodWIYCSABKA'
    'syIy5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLkh1YlN0YXRzUgNodWISSAoMY2FyZF9yZXN1'
    'bHRzGAogAygLMiUuY3VscGVvc3R1ZGlvLmJlbmNobWFyay52MS5DYXJkUmVzdWx0UgtjYXJkUm'
    'VzdWx0cxJKCgZkZWx0YXMYCyADKAsyMi5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLk1vZGVs'
    'RGV0YWlsLkRlbHRhc0VudHJ5UgZkZWx0YXMSPwoHbWV0cmljcxgMIAMoCzIlLmN1bHBlb3N0dW'
    'Rpby5iZW5jaG1hcmsudjEuTWV0cmljSW5mb1IHbWV0cmljcxI9CgZzb3VyY2UYDSABKAsyJS5j'
    'dWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLlNvdXJjZUluZm9SBnNvdXJjZRJKCgZ0b3RhbHMYDi'
    'ADKAsyMi5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLk1vZGVsRGV0YWlsLlRvdGFsc0VudHJ5'
    'UgZ0b3RhbHMSHQoKc2NvcmVfa2luZBgPIAEoCVIJc2NvcmVLaW5kGj4KEE1ldHJpY1JhbmtzRW'
    '50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAVSBXZhbHVlOgI4ARpbCgtEZWx0'
    'YXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI2CgV2YWx1ZRgCIAEoCzIgLmN1bHBlb3N0dWRpby'
    '5iZW5jaG1hcmsudjEuRGVsdGFSBXZhbHVlOgI4ARo5CgtUb3RhbHNFbnRyeRIQCgNrZXkYASAB'
    'KAlSA2tleRIUCgV2YWx1ZRgCIAEoBVIFdmFsdWU6AjgB');

@$core.Deprecated('Use facetValueDescriptor instead')
const FacetValue$json = {
  '1': 'FacetValue',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'count', '3': 3, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `FacetValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List facetValueDescriptor = $convert.base64Decode(
    'CgpGYWNldFZhbHVlEhQKBXZhbHVlGAEgASgJUgV2YWx1ZRIUCgVsYWJlbBgCIAEoCVIFbGFiZW'
    'wSFAoFY291bnQYAyABKAVSBWNvdW50');

@$core.Deprecated('Use facetsDescriptor instead')
const Facets$json = {
  '1': 'Facets',
  '2': [
    {
      '1': 'types',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.FacetValue',
      '10': 'types'
    },
    {
      '1': 'orgs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.FacetValue',
      '10': 'orgs'
    },
    {
      '1': 'licenses',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.FacetValue',
      '10': 'licenses'
    },
  ],
};

/// Descriptor for `Facets`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List facetsDescriptor = $convert.base64Decode(
    'CgZGYWNldHMSOwoFdHlwZXMYASADKAsyJS5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLkZhY2'
    'V0VmFsdWVSBXR5cGVzEjkKBG9yZ3MYAiADKAsyJS5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYx'
    'LkZhY2V0VmFsdWVSBG9yZ3MSQQoIbGljZW5zZXMYAyADKAsyJS5jdWxwZW9zdHVkaW8uYmVuY2'
    'htYXJrLnYxLkZhY2V0VmFsdWVSCGxpY2Vuc2Vz');

@$core.Deprecated('Use entryListDescriptor instead')
const EntryList$json = {
  '1': 'EntryList',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `EntryList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entryListDescriptor = $convert.base64Decode(
    'CglFbnRyeUxpc3QSOgoHZW50cmllcxgBIAMoCzIgLmN1bHBlb3N0dWRpby5iZW5jaG1hcmsudj'
    'EuRW50cnlSB2VudHJpZXM=');

@$core.Deprecated('Use listBoardsRequestDescriptor instead')
const ListBoardsRequest$json = {
  '1': 'ListBoardsRequest',
};

/// Descriptor for `ListBoardsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBoardsRequestDescriptor =
    $convert.base64Decode('ChFMaXN0Qm9hcmRzUmVxdWVzdA==');

@$core.Deprecated('Use listBoardsResponseDescriptor instead')
const ListBoardsResponse$json = {
  '1': 'ListBoardsResponse',
  '2': [
    {
      '1': 'boards',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.BoardInfo',
      '10': 'boards'
    },
    {'1': 'default_board', '3': 2, '4': 1, '5': 9, '10': 'defaultBoard'},
  ],
};

/// Descriptor for `ListBoardsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBoardsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0Qm9hcmRzUmVzcG9uc2USPAoGYm9hcmRzGAEgAygLMiQuY3VscGVvc3R1ZGlvLmJlbm'
    'NobWFyay52MS5Cb2FyZEluZm9SBmJvYXJkcxIjCg1kZWZhdWx0X2JvYXJkGAIgASgJUgxkZWZh'
    'dWx0Qm9hcmQ=');

@$core.Deprecated('Use getStatusRequestDescriptor instead')
const GetStatusRequest$json = {
  '1': 'GetStatusRequest',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
  ],
};

/// Descriptor for `GetStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusRequestDescriptor = $convert
    .base64Decode('ChBHZXRTdGF0dXNSZXF1ZXN0EhQKBWJvYXJkGAEgASgJUgVib2FyZA==');

@$core.Deprecated('Use getStatusResponseDescriptor instead')
const GetStatusResponse$json = {
  '1': 'GetStatusResponse',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.benchmark.v1.BoardState',
      '10': 'state'
    },
    {'1': 'loaded', '3': 2, '4': 1, '5': 5, '10': 'loaded'},
    {'1': 'expected', '3': 3, '4': 1, '5': 5, '10': 'expected'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
    {'1': 'refreshing', '3': 5, '4': 1, '5': 8, '10': 'refreshing'},
    {
      '1': 'boards',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.BoardInfo',
      '10': 'boards'
    },
    {
      '1': 'source',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.SourceInfo',
      '10': 'source'
    },
  ],
};

/// Descriptor for `GetStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusResponseDescriptor = $convert.base64Decode(
    'ChFHZXRTdGF0dXNSZXNwb25zZRI7CgVzdGF0ZRgBIAEoDjIlLmN1bHBlb3N0dWRpby5iZW5jaG'
    '1hcmsudjEuQm9hcmRTdGF0ZVIFc3RhdGUSFgoGbG9hZGVkGAIgASgFUgZsb2FkZWQSGgoIZXhw'
    'ZWN0ZWQYAyABKAVSCGV4cGVjdGVkEhQKBWVycm9yGAQgASgJUgVlcnJvchIeCgpyZWZyZXNoaW'
    '5nGAUgASgIUgpyZWZyZXNoaW5nEjwKBmJvYXJkcxgGIAMoCzIkLmN1bHBlb3N0dWRpby5iZW5j'
    'aG1hcmsudjEuQm9hcmRJbmZvUgZib2FyZHMSPQoGc291cmNlGAcgASgLMiUuY3VscGVvc3R1ZG'
    'lvLmJlbmNobWFyay52MS5Tb3VyY2VJbmZvUgZzb3VyY2U=');

@$core.Deprecated('Use getOverviewRequestDescriptor instead')
const GetOverviewRequest$json = {
  '1': 'GetOverviewRequest',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
  ],
};

/// Descriptor for `GetOverviewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getOverviewRequestDescriptor = $convert
    .base64Decode('ChJHZXRPdmVydmlld1JlcXVlc3QSFAoFYm9hcmQYASABKAlSBWJvYXJk');

@$core.Deprecated('Use getOverviewResponseDescriptor instead')
const GetOverviewResponse$json = {
  '1': 'GetOverviewResponse',
  '2': [
    {
      '1': 'board',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.BoardInfo',
      '10': 'board'
    },
    {
      '1': 'boards',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.BoardInfo',
      '10': 'boards'
    },
    {'1': 'total_entries', '3': 3, '4': 1, '5': 5, '10': 'totalEntries'},
    {'1': 'total_models', '3': 4, '4': 1, '5': 5, '10': 'totalModels'},
    {
      '1': 'metric_stats',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.MetricStats',
      '10': 'metricStats'
    },
    {
      '1': 'top_overall',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry',
      '10': 'topOverall'
    },
    {
      '1': 'top_by_metric',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.GetOverviewResponse.TopByMetricEntry',
      '10': 'topByMetric'
    },
    {
      '1': 'top_open_weights',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry',
      '10': 'topOpenWeights'
    },
    {
      '1': 'top_open_by_metric',
      '3': 9,
      '4': 3,
      '5': 11,
      '6':
          '.culpeostudio.benchmark.v1.GetOverviewResponse.TopOpenByMetricEntry',
      '10': 'topOpenByMetric'
    },
    {
      '1': 'type_share',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.FacetValue',
      '10': 'typeShare'
    },
    {
      '1': 'org_share',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.FacetValue',
      '10': 'orgShare'
    },
  ],
  '3': [
    GetOverviewResponse_TopByMetricEntry$json,
    GetOverviewResponse_TopOpenByMetricEntry$json
  ],
};

@$core.Deprecated('Use getOverviewResponseDescriptor instead')
const GetOverviewResponse_TopByMetricEntry$json = {
  '1': 'TopByMetricEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.EntryList',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use getOverviewResponseDescriptor instead')
const GetOverviewResponse_TopOpenByMetricEntry$json = {
  '1': 'TopOpenByMetricEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.EntryList',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `GetOverviewResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getOverviewResponseDescriptor = $convert.base64Decode(
    'ChNHZXRPdmVydmlld1Jlc3BvbnNlEjoKBWJvYXJkGAEgASgLMiQuY3VscGVvc3R1ZGlvLmJlbm'
    'NobWFyay52MS5Cb2FyZEluZm9SBWJvYXJkEjwKBmJvYXJkcxgCIAMoCzIkLmN1bHBlb3N0dWRp'
    'by5iZW5jaG1hcmsudjEuQm9hcmRJbmZvUgZib2FyZHMSIwoNdG90YWxfZW50cmllcxgDIAEoBV'
    'IMdG90YWxFbnRyaWVzEiEKDHRvdGFsX21vZGVscxgEIAEoBVILdG90YWxNb2RlbHMSSQoMbWV0'
    'cmljX3N0YXRzGAUgAygLMiYuY3VscGVvc3R1ZGlvLmJlbmNobWFyay52MS5NZXRyaWNTdGF0c1'
    'ILbWV0cmljU3RhdHMSQQoLdG9wX292ZXJhbGwYBiADKAsyIC5jdWxwZW9zdHVkaW8uYmVuY2ht'
    'YXJrLnYxLkVudHJ5Ugp0b3BPdmVyYWxsEmMKDXRvcF9ieV9tZXRyaWMYByADKAsyPy5jdWxwZW'
    '9zdHVkaW8uYmVuY2htYXJrLnYxLkdldE92ZXJ2aWV3UmVzcG9uc2UuVG9wQnlNZXRyaWNFbnRy'
    'eVILdG9wQnlNZXRyaWMSSgoQdG9wX29wZW5fd2VpZ2h0cxgIIAMoCzIgLmN1bHBlb3N0dWRpby'
    '5iZW5jaG1hcmsudjEuRW50cnlSDnRvcE9wZW5XZWlnaHRzEnAKEnRvcF9vcGVuX2J5X21ldHJp'
    'YxgJIAMoCzJDLmN1bHBlb3N0dWRpby5iZW5jaG1hcmsudjEuR2V0T3ZlcnZpZXdSZXNwb25zZS'
    '5Ub3BPcGVuQnlNZXRyaWNFbnRyeVIPdG9wT3BlbkJ5TWV0cmljEkQKCnR5cGVfc2hhcmUYCiAD'
    'KAsyJS5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLkZhY2V0VmFsdWVSCXR5cGVTaGFyZRJCCg'
    'lvcmdfc2hhcmUYCyADKAsyJS5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLkZhY2V0VmFsdWVS'
    'CG9yZ1NoYXJlGmQKEFRvcEJ5TWV0cmljRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSOgoFdmFsdW'
    'UYAiABKAsyJC5jdWxwZW9zdHVkaW8uYmVuY2htYXJrLnYxLkVudHJ5TGlzdFIFdmFsdWU6AjgB'
    'GmgKFFRvcE9wZW5CeU1ldHJpY0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjoKBXZhbHVlGAIgAS'
    'gLMiQuY3VscGVvc3R1ZGlvLmJlbmNobWFyay52MS5FbnRyeUxpc3RSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use getLeaderboardRequestDescriptor instead')
const GetLeaderboardRequest$json = {
  '1': 'GetLeaderboardRequest',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
    {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    {'1': 'types', '3': 3, '4': 3, '5': 9, '10': 'types'},
    {'1': 'orgs', '3': 4, '4': 3, '5': 9, '10': 'orgs'},
    {'1': 'licenses', '3': 5, '4': 3, '5': 9, '10': 'licenses'},
    {'1': 'open_weights_only', '3': 6, '4': 1, '5': 8, '10': 'openWeightsOnly'},
    {
      '1': 'best_per_model',
      '3': 7,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'bestPerModel',
      '17': true
    },
    {'1': 'sort', '3': 8, '4': 1, '5': 9, '10': 'sort'},
    {
      '1': 'order',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.benchmark.v1.SortOrder',
      '10': 'order'
    },
    {'1': 'offset', '3': 10, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'limit', '3': 11, '4': 1, '5': 5, '10': 'limit'},
  ],
  '8': [
    {'1': '_best_per_model'},
  ],
};

/// Descriptor for `GetLeaderboardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLeaderboardRequestDescriptor = $convert.base64Decode(
    'ChVHZXRMZWFkZXJib2FyZFJlcXVlc3QSFAoFYm9hcmQYASABKAlSBWJvYXJkEhQKBXF1ZXJ5GA'
    'IgASgJUgVxdWVyeRIUCgV0eXBlcxgDIAMoCVIFdHlwZXMSEgoEb3JncxgEIAMoCVIEb3JncxIa'
    'CghsaWNlbnNlcxgFIAMoCVIIbGljZW5zZXMSKgoRb3Blbl93ZWlnaHRzX29ubHkYBiABKAhSD2'
    '9wZW5XZWlnaHRzT25seRIpCg5iZXN0X3Blcl9tb2RlbBgHIAEoCEgAUgxiZXN0UGVyTW9kZWyI'
    'AQESEgoEc29ydBgIIAEoCVIEc29ydBI6CgVvcmRlchgJIAEoDjIkLmN1bHBlb3N0dWRpby5iZW'
    '5jaG1hcmsudjEuU29ydE9yZGVyUgVvcmRlchIWCgZvZmZzZXQYCiABKAVSBm9mZnNldBIUCgVs'
    'aW1pdBgLIAEoBVIFbGltaXRCEQoPX2Jlc3RfcGVyX21vZGVs');

@$core.Deprecated('Use getLeaderboardResponseDescriptor instead')
const GetLeaderboardResponse$json = {
  '1': 'GetLeaderboardResponse',
  '2': [
    {
      '1': 'board',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.BoardInfo',
      '10': 'board'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Entry',
      '10': 'items'
    },
    {'1': 'total', '3': 3, '4': 1, '5': 5, '10': 'total'},
    {'1': 'offset', '3': 4, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'limit', '3': 5, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'sort', '3': 6, '4': 1, '5': 9, '10': 'sort'},
    {
      '1': 'order',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.benchmark.v1.SortOrder',
      '10': 'order'
    },
    {
      '1': 'facets',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.Facets',
      '10': 'facets'
    },
    {
      '1': 'warning',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.benchmark.v1.BoardState',
      '10': 'warning'
    },
  ],
};

/// Descriptor for `GetLeaderboardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLeaderboardResponseDescriptor = $convert.base64Decode(
    'ChZHZXRMZWFkZXJib2FyZFJlc3BvbnNlEjoKBWJvYXJkGAEgASgLMiQuY3VscGVvc3R1ZGlvLm'
    'JlbmNobWFyay52MS5Cb2FyZEluZm9SBWJvYXJkEjYKBWl0ZW1zGAIgAygLMiAuY3VscGVvc3R1'
    'ZGlvLmJlbmNobWFyay52MS5FbnRyeVIFaXRlbXMSFAoFdG90YWwYAyABKAVSBXRvdGFsEhYKBm'
    '9mZnNldBgEIAEoBVIGb2Zmc2V0EhQKBWxpbWl0GAUgASgFUgVsaW1pdBISCgRzb3J0GAYgASgJ'
    'UgRzb3J0EjoKBW9yZGVyGAcgASgOMiQuY3VscGVvc3R1ZGlvLmJlbmNobWFyay52MS5Tb3J0T3'
    'JkZXJSBW9yZGVyEjkKBmZhY2V0cxgIIAEoCzIhLmN1bHBlb3N0dWRpby5iZW5jaG1hcmsudjEu'
    'RmFjZXRzUgZmYWNldHMSPwoHd2FybmluZxgJIAEoDjIlLmN1bHBlb3N0dWRpby5iZW5jaG1hcm'
    'sudjEuQm9hcmRTdGF0ZVIHd2FybmluZw==');

@$core.Deprecated('Use getModelRequestDescriptor instead')
const GetModelRequest$json = {
  '1': 'GetModelRequest',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'with_hub',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'withHub',
      '17': true
    },
  ],
  '8': [
    {'1': '_with_hub'},
  ],
};

/// Descriptor for `GetModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModelRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRNb2RlbFJlcXVlc3QSFAoFYm9hcmQYASABKAlSBWJvYXJkEg4KAmlkGAIgASgJUgJpZB'
    'IeCgh3aXRoX2h1YhgDIAEoCEgAUgd3aXRoSHViiAEBQgsKCV93aXRoX2h1Yg==');

@$core.Deprecated('Use getModelResponseDescriptor instead')
const GetModelResponse$json = {
  '1': 'GetModelResponse',
  '2': [
    {
      '1': 'detail',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.ModelDetail',
      '10': 'detail'
    },
  ],
};

/// Descriptor for `GetModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModelResponseDescriptor = $convert.base64Decode(
    'ChBHZXRNb2RlbFJlc3BvbnNlEj4KBmRldGFpbBgBIAEoCzImLmN1bHBlb3N0dWRpby5iZW5jaG'
    '1hcmsudjEuTW9kZWxEZXRhaWxSBmRldGFpbA==');

@$core.Deprecated('Use compareModelsRequestDescriptor instead')
const CompareModelsRequest$json = {
  '1': 'CompareModelsRequest',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
    {'1': 'ids', '3': 2, '4': 3, '5': 9, '10': 'ids'},
    {
      '1': 'with_hub',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'withHub',
      '17': true
    },
  ],
  '8': [
    {'1': '_with_hub'},
  ],
};

/// Descriptor for `CompareModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compareModelsRequestDescriptor = $convert.base64Decode(
    'ChRDb21wYXJlTW9kZWxzUmVxdWVzdBIUCgVib2FyZBgBIAEoCVIFYm9hcmQSEAoDaWRzGAIgAy'
    'gJUgNpZHMSHgoId2l0aF9odWIYAyABKAhIAFIHd2l0aEh1YogBAUILCglfd2l0aF9odWI=');

@$core.Deprecated('Use compareModelsResponseDescriptor instead')
const CompareModelsResponse$json = {
  '1': 'CompareModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.ModelDetail',
      '10': 'models'
    },
    {
      '1': 'board',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.benchmark.v1.BoardInfo',
      '10': 'board'
    },
  ],
};

/// Descriptor for `CompareModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compareModelsResponseDescriptor = $convert.base64Decode(
    'ChVDb21wYXJlTW9kZWxzUmVzcG9uc2USPgoGbW9kZWxzGAEgAygLMiYuY3VscGVvc3R1ZGlvLm'
    'JlbmNobWFyay52MS5Nb2RlbERldGFpbFIGbW9kZWxzEjoKBWJvYXJkGAIgASgLMiQuY3VscGVv'
    'c3R1ZGlvLmJlbmNobWFyay52MS5Cb2FyZEluZm9SBWJvYXJk');

@$core.Deprecated('Use refreshBoardsRequestDescriptor instead')
const RefreshBoardsRequest$json = {
  '1': 'RefreshBoardsRequest',
  '2': [
    {'1': 'board', '3': 1, '4': 1, '5': 9, '10': 'board'},
  ],
};

/// Descriptor for `RefreshBoardsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshBoardsRequestDescriptor =
    $convert.base64Decode(
        'ChRSZWZyZXNoQm9hcmRzUmVxdWVzdBIUCgVib2FyZBgBIAEoCVIFYm9hcmQ=');

@$core.Deprecated('Use refreshBoardsResponseDescriptor instead')
const RefreshBoardsResponse$json = {
  '1': 'RefreshBoardsResponse',
  '2': [
    {'1': 'boards', '3': 1, '4': 3, '5': 9, '10': 'boards'},
  ],
};

/// Descriptor for `RefreshBoardsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshBoardsResponseDescriptor =
    $convert.base64Decode(
        'ChVSZWZyZXNoQm9hcmRzUmVzcG9uc2USFgoGYm9hcmRzGAEgAygJUgZib2FyZHM=');
