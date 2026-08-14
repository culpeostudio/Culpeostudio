// This is a generated file - do not edit.
//
// Generated from culpeostudio/marketplace/v1/marketplace.proto.

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

@$core.Deprecated('Use providerDescriptor instead')
const Provider$json = {
  '1': 'Provider',
  '2': [
    {'1': 'PROVIDER_UNSPECIFIED', '2': 0},
    {'1': 'PROVIDER_ALL', '2': 1},
    {'1': 'PROVIDER_HUGGINGFACE', '2': 2},
    {'1': 'PROVIDER_OPENROUTER', '2': 3},
    {'1': 'PROVIDER_FEATHERLESS', '2': 4},
  ],
};

/// Descriptor for `Provider`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List providerDescriptor = $convert.base64Decode(
    'CghQcm92aWRlchIYChRQUk9WSURFUl9VTlNQRUNJRklFRBAAEhAKDFBST1ZJREVSX0FMTBABEh'
    'gKFFBST1ZJREVSX0hVR0dJTkdGQUNFEAISFwoTUFJPVklERVJfT1BFTlJPVVRFUhADEhgKFFBS'
    'T1ZJREVSX0ZFQVRIRVJMRVNTEAQ=');

@$core.Deprecated('Use categoryDescriptor instead')
const Category$json = {
  '1': 'Category',
  '2': [
    {'1': 'CATEGORY_UNSPECIFIED', '2': 0},
    {'1': 'CATEGORY_CHAT', '2': 1},
    {'1': 'CATEGORY_CODE', '2': 2},
    {'1': 'CATEGORY_REASONING', '2': 3},
    {'1': 'CATEGORY_VISION', '2': 4},
    {'1': 'CATEGORY_EMBEDDING', '2': 5},
  ],
};

/// Descriptor for `Category`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List categoryDescriptor = $convert.base64Decode(
    'CghDYXRlZ29yeRIYChRDQVRFR09SWV9VTlNQRUNJRklFRBAAEhEKDUNBVEVHT1JZX0NIQVQQAR'
    'IRCg1DQVRFR09SWV9DT0RFEAISFgoSQ0FURUdPUllfUkVBU09OSU5HEAMSEwoPQ0FURUdPUllf'
    'VklTSU9OEAQSFgoSQ0FURUdPUllfRU1CRURESU5HEAU=');

@$core.Deprecated('Use sortModeDescriptor instead')
const SortMode$json = {
  '1': 'SortMode',
  '2': [
    {'1': 'SORT_MODE_UNSPECIFIED', '2': 0},
    {'1': 'SORT_MODE_POPULARITY', '2': 1},
    {'1': 'SORT_MODE_INTELLIGENCE', '2': 2},
    {'1': 'SORT_MODE_CONTEXT', '2': 3},
    {'1': 'SORT_MODE_NEWEST', '2': 4},
    {'1': 'SORT_MODE_PRICE_LOW_HIGH', '2': 5},
    {'1': 'SORT_MODE_PRICE_HIGH_LOW', '2': 6},
  ],
};

/// Descriptor for `SortMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sortModeDescriptor = $convert.base64Decode(
    'CghTb3J0TW9kZRIZChVTT1JUX01PREVfVU5TUEVDSUZJRUQQABIYChRTT1JUX01PREVfUE9QVU'
    'xBUklUWRABEhoKFlNPUlRfTU9ERV9JTlRFTExJR0VOQ0UQAhIVChFTT1JUX01PREVfQ09OVEVY'
    'VBADEhQKEFNPUlRfTU9ERV9ORVdFU1QQBBIcChhTT1JUX01PREVfUFJJQ0VfTE9XX0hJR0gQBR'
    'IcChhTT1JUX01PREVfUFJJQ0VfSElHSF9MT1cQBg==');

@$core.Deprecated('Use downloadStatusDescriptor instead')
const DownloadStatus$json = {
  '1': 'DownloadStatus',
  '2': [
    {'1': 'DOWNLOAD_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'DOWNLOAD_STATUS_QUEUED', '2': 1},
    {'1': 'DOWNLOAD_STATUS_RUNNING', '2': 2},
    {'1': 'DOWNLOAD_STATUS_DONE', '2': 3},
    {'1': 'DOWNLOAD_STATUS_FAILED', '2': 4},
  ],
};

/// Descriptor for `DownloadStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List downloadStatusDescriptor = $convert.base64Decode(
    'Cg5Eb3dubG9hZFN0YXR1cxIfChtET1dOTE9BRF9TVEFUVVNfVU5TUEVDSUZJRUQQABIaChZET1'
    'dOTE9BRF9TVEFUVVNfUVVFVUVEEAESGwoXRE9XTkxPQURfU1RBVFVTX1JVTk5JTkcQAhIYChRE'
    'T1dOTE9BRF9TVEFUVVNfRE9ORRADEhoKFkRPV05MT0FEX1NUQVRVU19GQUlMRUQQBA==');

@$core.Deprecated('Use downloadOptionDescriptor instead')
const DownloadOption$json = {
  '1': 'DownloadOption',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'asset_id', '3': 2, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'asset_ids', '3': 3, '4': 3, '5': 9, '10': 'assetIds'},
    {'1': 'format', '3': 4, '4': 1, '5': 9, '10': 'format'},
    {'1': 'size_bytes', '3': 5, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'url', '3': 6, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `DownloadOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadOptionDescriptor = $convert.base64Decode(
    'Cg5Eb3dubG9hZE9wdGlvbhIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSGQoIYXNzZXRfaWQYAiABKA'
    'lSB2Fzc2V0SWQSGwoJYXNzZXRfaWRzGAMgAygJUghhc3NldElkcxIWCgZmb3JtYXQYBCABKAlS'
    'BmZvcm1hdBIdCgpzaXplX2J5dGVzGAUgASgDUglzaXplQnl0ZXMSEAoDdXJsGAYgASgJUgN1cm'
    'w=');

@$core.Deprecated('Use modelSummaryDescriptor instead')
const ModelSummary$json = {
  '1': 'ModelSummary',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'provider',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Provider',
      '10': 'provider'
    },
    {'1': 'model_id', '3': 3, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'display_name', '3': 4, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 6, '4': 1, '5': 9, '10': 'description'},
    {'1': 'format', '3': 7, '4': 1, '5': 9, '10': 'format'},
    {'1': 'formats', '3': 8, '4': 3, '5': 9, '10': 'formats'},
    {'1': 'quantizations', '3': 9, '4': 3, '5': 9, '10': 'quantizations'},
    {'1': 'author', '3': 10, '4': 1, '5': 9, '10': 'author'},
    {'1': 'downloads', '3': 11, '4': 1, '5': 3, '10': 'downloads'},
    {'1': 'size_bytes', '3': 12, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'parameter_badge', '3': 13, '4': 1, '5': 9, '10': 'parameterBadge'},
    {
      '1': 'parameter_count_b',
      '3': 14,
      '4': 1,
      '5': 1,
      '10': 'parameterCountB'
    },
    {'1': 'provider_badge', '3': 15, '4': 1, '5': 9, '10': 'providerBadge'},
    {'1': 'category', '3': 16, '4': 1, '5': 9, '10': 'category'},
    {'1': 'capability_tags', '3': 17, '4': 3, '5': 9, '10': 'capabilityTags'},
    {'1': 'price_per_1m', '3': 18, '4': 1, '5': 9, '10': 'pricePer1m'},
    {
      '1': 'price_per_1m_input',
      '3': 19,
      '4': 1,
      '5': 1,
      '10': 'pricePer1mInput'
    },
    {
      '1': 'price_per_1m_output',
      '3': 20,
      '4': 1,
      '5': 1,
      '10': 'pricePer1mOutput'
    },
    {'1': 'context_length', '3': 21, '4': 1, '5': 5, '10': 'contextLength'},
    {
      '1': 'intelligence_score',
      '3': 22,
      '4': 1,
      '5': 5,
      '10': 'intelligenceScore'
    },
    {
      '1': 'estimated_vram_gb',
      '3': 23,
      '4': 1,
      '5': 1,
      '10': 'estimatedVramGb'
    },
    {'1': 'vram_estimated', '3': 24, '4': 1, '5': 8, '10': 'vramEstimated'},
    {
      '1': 'fits_detected_gpu',
      '3': 25,
      '4': 1,
      '5': 8,
      '10': 'fitsDetectedGpu'
    },
    {'1': 'runtime_fit', '3': 26, '4': 1, '5': 9, '10': 'runtimeFit'},
    {'1': 'runtime_warnings', '3': 27, '4': 3, '5': 9, '10': 'runtimeWarnings'},
    {
      '1': 'runtime_ram_offload_gb',
      '3': 28,
      '4': 1,
      '5': 1,
      '10': 'runtimeRamOffloadGb'
    },
    {
      '1': 'recommendation_score',
      '3': 29,
      '4': 1,
      '5': 1,
      '10': 'recommendationScore'
    },
    {'1': 'local_model', '3': 30, '4': 1, '5': 8, '10': 'localModel'},
    {'1': 'new_score', '3': 31, '4': 1, '5': 3, '10': 'newScore'},
    {
      '1': 'download_options',
      '3': 32,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.DownloadOption',
      '10': 'downloadOptions'
    },
  ],
};

/// Descriptor for `ModelSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelSummaryDescriptor = $convert.base64Decode(
    'CgxNb2RlbFN1bW1hcnkSDgoCaWQYASABKAlSAmlkEkEKCHByb3ZpZGVyGAIgASgOMiUuY3VscG'
    'Vvc3R1ZGlvLm1hcmtldHBsYWNlLnYxLlByb3ZpZGVyUghwcm92aWRlchIZCghtb2RlbF9pZBgD'
    'IAEoCVIHbW9kZWxJZBIhCgxkaXNwbGF5X25hbWUYBCABKAlSC2Rpc3BsYXlOYW1lEhIKBG5hbW'
    'UYBSABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YBiABKAlSC2Rlc2NyaXB0aW9uEhYKBmZvcm1h'
    'dBgHIAEoCVIGZm9ybWF0EhgKB2Zvcm1hdHMYCCADKAlSB2Zvcm1hdHMSJAoNcXVhbnRpemF0aW'
    '9ucxgJIAMoCVINcXVhbnRpemF0aW9ucxIWCgZhdXRob3IYCiABKAlSBmF1dGhvchIcCglkb3du'
    'bG9hZHMYCyABKANSCWRvd25sb2FkcxIdCgpzaXplX2J5dGVzGAwgASgDUglzaXplQnl0ZXMSJw'
    'oPcGFyYW1ldGVyX2JhZGdlGA0gASgJUg5wYXJhbWV0ZXJCYWRnZRIqChFwYXJhbWV0ZXJfY291'
    'bnRfYhgOIAEoAVIPcGFyYW1ldGVyQ291bnRCEiUKDnByb3ZpZGVyX2JhZGdlGA8gASgJUg1wcm'
    '92aWRlckJhZGdlEhoKCGNhdGVnb3J5GBAgASgJUghjYXRlZ29yeRInCg9jYXBhYmlsaXR5X3Rh'
    'Z3MYESADKAlSDmNhcGFiaWxpdHlUYWdzEiAKDHByaWNlX3Blcl8xbRgSIAEoCVIKcHJpY2VQZX'
    'IxbRIrChJwcmljZV9wZXJfMW1faW5wdXQYEyABKAFSD3ByaWNlUGVyMW1JbnB1dBItChNwcmlj'
    'ZV9wZXJfMW1fb3V0cHV0GBQgASgBUhBwcmljZVBlcjFtT3V0cHV0EiUKDmNvbnRleHRfbGVuZ3'
    'RoGBUgASgFUg1jb250ZXh0TGVuZ3RoEi0KEmludGVsbGlnZW5jZV9zY29yZRgWIAEoBVIRaW50'
    'ZWxsaWdlbmNlU2NvcmUSKgoRZXN0aW1hdGVkX3ZyYW1fZ2IYFyABKAFSD2VzdGltYXRlZFZyYW'
    '1HYhIlCg52cmFtX2VzdGltYXRlZBgYIAEoCFINdnJhbUVzdGltYXRlZBIqChFmaXRzX2RldGVj'
    'dGVkX2dwdRgZIAEoCFIPZml0c0RldGVjdGVkR3B1Eh8KC3J1bnRpbWVfZml0GBogASgJUgpydW'
    '50aW1lRml0EikKEHJ1bnRpbWVfd2FybmluZ3MYGyADKAlSD3J1bnRpbWVXYXJuaW5ncxIzChZy'
    'dW50aW1lX3JhbV9vZmZsb2FkX2diGBwgASgBUhNydW50aW1lUmFtT2ZmbG9hZEdiEjEKFHJlY2'
    '9tbWVuZGF0aW9uX3Njb3JlGB0gASgBUhNyZWNvbW1lbmRhdGlvblNjb3JlEh8KC2xvY2FsX21v'
    'ZGVsGB4gASgIUgpsb2NhbE1vZGVsEhsKCW5ld19zY29yZRgfIAEoA1IIbmV3U2NvcmUSVgoQZG'
    '93bmxvYWRfb3B0aW9ucxggIAMoCzIrLmN1bHBlb3N0dWRpby5tYXJrZXRwbGFjZS52MS5Eb3du'
    'bG9hZE9wdGlvblIPZG93bmxvYWRPcHRpb25z');

@$core.Deprecated('Use modelDetailDescriptor instead')
const ModelDetail$json = {
  '1': 'ModelDetail',
  '2': [
    {
      '1': 'summary',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.ModelSummary',
      '10': 'summary'
    },
    {'1': 'tags', '3': 2, '4': 3, '5': 9, '10': 'tags'},
    {
      '1': 'metadata',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.ModelDetail.MetadataEntry',
      '10': 'metadata'
    },
  ],
  '3': [ModelDetail_MetadataEntry$json],
};

@$core.Deprecated('Use modelDetailDescriptor instead')
const ModelDetail_MetadataEntry$json = {
  '1': 'MetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ModelDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelDetailDescriptor = $convert.base64Decode(
    'CgtNb2RlbERldGFpbBJDCgdzdW1tYXJ5GAEgASgLMikuY3VscGVvc3R1ZGlvLm1hcmtldHBsYW'
    'NlLnYxLk1vZGVsU3VtbWFyeVIHc3VtbWFyeRISCgR0YWdzGAIgAygJUgR0YWdzElIKCG1ldGFk'
    'YXRhGAMgAygLMjYuY3VscGVvc3R1ZGlvLm1hcmtldHBsYWNlLnYxLk1vZGVsRGV0YWlsLk1ldG'
    'FkYXRhRW50cnlSCG1ldGFkYXRhGjsKDU1ldGFkYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS'
    'FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use searchModelsRequestDescriptor instead')
const SearchModelsRequest$json = {
  '1': 'SearchModelsRequest',
  '2': [
    {
      '1': 'provider',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Provider',
      '10': 'provider'
    },
    {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    {'1': 'format', '3': 3, '4': 1, '5': 9, '10': 'format'},
    {'1': 'quantization', '3': 4, '4': 1, '5': 9, '10': 'quantization'},
    {
      '1': 'category',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Category',
      '10': 'category'
    },
    {
      '1': 'sort',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.SortMode',
      '10': 'sort'
    },
    {'1': 'gpu_fit', '3': 7, '4': 1, '5': 8, '10': 'gpuFit'},
    {'1': 'local_only', '3': 8, '4': 1, '5': 8, '10': 'localOnly'},
    {'1': 'page', '3': 9, '4': 1, '5': 5, '10': 'page'},
    {'1': 'page_size', '3': 10, '4': 1, '5': 5, '10': 'pageSize'},
  ],
};

/// Descriptor for `SearchModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchModelsRequestDescriptor = $convert.base64Decode(
    'ChNTZWFyY2hNb2RlbHNSZXF1ZXN0EkEKCHByb3ZpZGVyGAEgASgOMiUuY3VscGVvc3R1ZGlvLm'
    '1hcmtldHBsYWNlLnYxLlByb3ZpZGVyUghwcm92aWRlchIUCgVxdWVyeRgCIAEoCVIFcXVlcnkS'
    'FgoGZm9ybWF0GAMgASgJUgZmb3JtYXQSIgoMcXVhbnRpemF0aW9uGAQgASgJUgxxdWFudGl6YX'
    'Rpb24SQQoIY2F0ZWdvcnkYBSABKA4yJS5jdWxwZW9zdHVkaW8ubWFya2V0cGxhY2UudjEuQ2F0'
    'ZWdvcnlSCGNhdGVnb3J5EjkKBHNvcnQYBiABKA4yJS5jdWxwZW9zdHVkaW8ubWFya2V0cGxhY2'
    'UudjEuU29ydE1vZGVSBHNvcnQSFwoHZ3B1X2ZpdBgHIAEoCFIGZ3B1Rml0Eh0KCmxvY2FsX29u'
    'bHkYCCABKAhSCWxvY2FsT25seRISCgRwYWdlGAkgASgFUgRwYWdlEhsKCXBhZ2Vfc2l6ZRgKIA'
    'EoBVIIcGFnZVNpemU=');

@$core.Deprecated('Use searchModelsResponseDescriptor instead')
const SearchModelsResponse$json = {
  '1': 'SearchModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.ModelSummary',
      '10': 'models'
    },
    {'1': 'total', '3': 2, '4': 1, '5': 5, '10': 'total'},
    {'1': 'returned', '3': 3, '4': 1, '5': 5, '10': 'returned'},
    {'1': 'partial', '3': 4, '4': 1, '5': 8, '10': 'partial'},
    {'1': 'errors', '3': 5, '4': 3, '5': 9, '10': 'errors'},
    {'1': 'page', '3': 6, '4': 1, '5': 5, '10': 'page'},
    {'1': 'page_size', '3': 7, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'has_more', '3': 8, '4': 1, '5': 8, '10': 'hasMore'},
    {
      '1': 'hardware',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.HardwareProfile',
      '10': 'hardware'
    },
  ],
};

/// Descriptor for `SearchModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchModelsResponseDescriptor = $convert.base64Decode(
    'ChRTZWFyY2hNb2RlbHNSZXNwb25zZRJBCgZtb2RlbHMYASADKAsyKS5jdWxwZW9zdHVkaW8ubW'
    'Fya2V0cGxhY2UudjEuTW9kZWxTdW1tYXJ5UgZtb2RlbHMSFAoFdG90YWwYAiABKAVSBXRvdGFs'
    'EhoKCHJldHVybmVkGAMgASgFUghyZXR1cm5lZBIYCgdwYXJ0aWFsGAQgASgIUgdwYXJ0aWFsEh'
    'YKBmVycm9ycxgFIAMoCVIGZXJyb3JzEhIKBHBhZ2UYBiABKAVSBHBhZ2USGwoJcGFnZV9zaXpl'
    'GAcgASgFUghwYWdlU2l6ZRIZCghoYXNfbW9yZRgIIAEoCFIHaGFzTW9yZRJFCghoYXJkd2FyZR'
    'gJIAEoCzIpLmN1bHBlb3N0dWRpby5oYXJkd2FyZS52MS5IYXJkd2FyZVByb2ZpbGVSCGhhcmR3'
    'YXJl');

@$core.Deprecated('Use getModelDetailRequestDescriptor instead')
const GetModelDetailRequest$json = {
  '1': 'GetModelDetailRequest',
  '2': [
    {
      '1': 'provider',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Provider',
      '10': 'provider'
    },
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetModelDetailRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModelDetailRequestDescriptor = $convert.base64Decode(
    'ChVHZXRNb2RlbERldGFpbFJlcXVlc3QSQQoIcHJvdmlkZXIYASABKA4yJS5jdWxwZW9zdHVkaW'
    '8ubWFya2V0cGxhY2UudjEuUHJvdmlkZXJSCHByb3ZpZGVyEg4KAmlkGAIgASgJUgJpZA==');

@$core.Deprecated('Use getModelDetailResponseDescriptor instead')
const GetModelDetailResponse$json = {
  '1': 'GetModelDetailResponse',
  '2': [
    {
      '1': 'detail',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.ModelDetail',
      '10': 'detail'
    },
  ],
};

/// Descriptor for `GetModelDetailResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModelDetailResponseDescriptor =
    $convert.base64Decode(
        'ChZHZXRNb2RlbERldGFpbFJlc3BvbnNlEkAKBmRldGFpbBgBIAEoCzIoLmN1bHBlb3N0dWRpby'
        '5tYXJrZXRwbGFjZS52MS5Nb2RlbERldGFpbFIGZGV0YWls');

@$core.Deprecated('Use getHardwareProfileRequestDescriptor instead')
const GetHardwareProfileRequest$json = {
  '1': 'GetHardwareProfileRequest',
};

/// Descriptor for `GetHardwareProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHardwareProfileRequestDescriptor =
    $convert.base64Decode('ChlHZXRIYXJkd2FyZVByb2ZpbGVSZXF1ZXN0');

@$core.Deprecated('Use getHardwareProfileResponseDescriptor instead')
const GetHardwareProfileResponse$json = {
  '1': 'GetHardwareProfileResponse',
  '2': [
    {
      '1': 'profile',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.HardwareProfile',
      '10': 'profile'
    },
  ],
};

/// Descriptor for `GetHardwareProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHardwareProfileResponseDescriptor =
    $convert.base64Decode(
        'ChpHZXRIYXJkd2FyZVByb2ZpbGVSZXNwb25zZRJDCgdwcm9maWxlGAEgASgLMikuY3VscGVvc3'
        'R1ZGlvLmhhcmR3YXJlLnYxLkhhcmR3YXJlUHJvZmlsZVIHcHJvZmlsZQ==');

@$core.Deprecated('Use startDownloadRequestDescriptor instead')
const StartDownloadRequest$json = {
  '1': 'StartDownloadRequest',
  '2': [
    {
      '1': 'provider',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Provider',
      '10': 'provider'
    },
    {'1': 'model_id', '3': 2, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'asset_id', '3': 3, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'asset_ids', '3': 4, '4': 3, '5': 9, '10': 'assetIds'},
    {'1': 'revision', '3': 5, '4': 1, '5': 9, '10': 'revision'},
    {'1': 'target_dir', '3': 6, '4': 1, '5': 9, '10': 'targetDir'},
    {'1': 'size_bytes', '3': 7, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'node_id', '3': 8, '4': 1, '5': 9, '10': 'nodeId'},
  ],
};

/// Descriptor for `StartDownloadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startDownloadRequestDescriptor = $convert.base64Decode(
    'ChRTdGFydERvd25sb2FkUmVxdWVzdBJBCghwcm92aWRlchgBIAEoDjIlLmN1bHBlb3N0dWRpby'
    '5tYXJrZXRwbGFjZS52MS5Qcm92aWRlclIIcHJvdmlkZXISGQoIbW9kZWxfaWQYAiABKAlSB21v'
    'ZGVsSWQSGQoIYXNzZXRfaWQYAyABKAlSB2Fzc2V0SWQSGwoJYXNzZXRfaWRzGAQgAygJUghhc3'
    'NldElkcxIaCghyZXZpc2lvbhgFIAEoCVIIcmV2aXNpb24SHQoKdGFyZ2V0X2RpchgGIAEoCVIJ'
    'dGFyZ2V0RGlyEh0KCnNpemVfYnl0ZXMYByABKANSCXNpemVCeXRlcxIXCgdub2RlX2lkGAggAS'
    'gJUgZub2RlSWQ=');

@$core.Deprecated('Use startDownloadResponseDescriptor instead')
const StartDownloadResponse$json = {
  '1': 'StartDownloadResponse',
  '2': [
    {'1': 'job_id', '3': 1, '4': 1, '5': 9, '10': 'jobId'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.DownloadStatus',
      '10': 'status'
    },
    {'1': 'existing', '3': 3, '4': 1, '5': 8, '10': 'existing'},
    {'1': 'target_dir', '3': 4, '4': 1, '5': 9, '10': 'targetDir'},
  ],
};

/// Descriptor for `StartDownloadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startDownloadResponseDescriptor = $convert.base64Decode(
    'ChVTdGFydERvd25sb2FkUmVzcG9uc2USFQoGam9iX2lkGAEgASgJUgVqb2JJZBJDCgZzdGF0dX'
    'MYAiABKA4yKy5jdWxwZW9zdHVkaW8ubWFya2V0cGxhY2UudjEuRG93bmxvYWRTdGF0dXNSBnN0'
    'YXR1cxIaCghleGlzdGluZxgDIAEoCFIIZXhpc3RpbmcSHQoKdGFyZ2V0X2RpchgEIAEoCVIJdG'
    'FyZ2V0RGly');

@$core.Deprecated('Use downloadJobDescriptor instead')
const DownloadJob$json = {
  '1': 'DownloadJob',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'provider',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Provider',
      '10': 'provider'
    },
    {'1': 'model_id', '3': 3, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'asset_id', '3': 4, '4': 1, '5': 9, '10': 'assetId'},
    {'1': 'asset_ids', '3': 5, '4': 3, '5': 9, '10': 'assetIds'},
    {'1': 'revision', '3': 6, '4': 1, '5': 9, '10': 'revision'},
    {'1': 'commit_sha', '3': 7, '4': 1, '5': 9, '10': 'commitSha'},
    {'1': 'target_dir', '3': 8, '4': 1, '5': 9, '10': 'targetDir'},
    {
      '1': 'status',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.DownloadStatus',
      '10': 'status'
    },
    {'1': 'progress', '3': 10, '4': 1, '5': 5, '10': 'progress'},
    {'1': 'error', '3': 11, '4': 1, '5': 9, '10': 'error'},
    {'1': 'output_path', '3': 12, '4': 1, '5': 9, '10': 'outputPath'},
    {
      '1': 'created_at',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {
      '1': 'started_at',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startedAt'
    },
    {
      '1': 'finished_at',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'finishedAt'
    },
    {'1': 'downloaded_bytes', '3': 17, '4': 1, '5': 3, '10': 'downloadedBytes'},
    {
      '1': 'speed_bytes_per_sec',
      '3': 18,
      '4': 1,
      '5': 3,
      '10': 'speedBytesPerSec'
    },
    {'1': 'total_bytes', '3': 19, '4': 1, '5': 3, '10': 'totalBytes'},
    {'1': 'node_id', '3': 20, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'node_name', '3': 21, '4': 1, '5': 9, '10': 'nodeName'},
  ],
};

/// Descriptor for `DownloadJob`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadJobDescriptor = $convert.base64Decode(
    'CgtEb3dubG9hZEpvYhIOCgJpZBgBIAEoCVICaWQSQQoIcHJvdmlkZXIYAiABKA4yJS5jdWxwZW'
    '9zdHVkaW8ubWFya2V0cGxhY2UudjEuUHJvdmlkZXJSCHByb3ZpZGVyEhkKCG1vZGVsX2lkGAMg'
    'ASgJUgdtb2RlbElkEhkKCGFzc2V0X2lkGAQgASgJUgdhc3NldElkEhsKCWFzc2V0X2lkcxgFIA'
    'MoCVIIYXNzZXRJZHMSGgoIcmV2aXNpb24YBiABKAlSCHJldmlzaW9uEh0KCmNvbW1pdF9zaGEY'
    'ByABKAlSCWNvbW1pdFNoYRIdCgp0YXJnZXRfZGlyGAggASgJUgl0YXJnZXREaXISQwoGc3RhdH'
    'VzGAkgASgOMisuY3VscGVvc3R1ZGlvLm1hcmtldHBsYWNlLnYxLkRvd25sb2FkU3RhdHVzUgZz'
    'dGF0dXMSGgoIcHJvZ3Jlc3MYCiABKAVSCHByb2dyZXNzEhQKBWVycm9yGAsgASgJUgVlcnJvch'
    'IfCgtvdXRwdXRfcGF0aBgMIAEoCVIKb3V0cHV0UGF0aBI5CgpjcmVhdGVkX2F0GA0gASgLMhou'
    'Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0EjkKCnVwZGF0ZWRfYXQYDiABKA'
    'syGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgl1cGRhdGVkQXQSOQoKc3RhcnRlZF9hdBgP'
    'IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0ZWRBdBI7CgtmaW5pc2hlZF'
    '9hdBgQIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmZpbmlzaGVkQXQSKQoQZG93'
    'bmxvYWRlZF9ieXRlcxgRIAEoA1IPZG93bmxvYWRlZEJ5dGVzEi0KE3NwZWVkX2J5dGVzX3Blcl'
    '9zZWMYEiABKANSEHNwZWVkQnl0ZXNQZXJTZWMSHwoLdG90YWxfYnl0ZXMYEyABKANSCnRvdGFs'
    'Qnl0ZXMSFwoHbm9kZV9pZBgUIAEoCVIGbm9kZUlkEhsKCW5vZGVfbmFtZRgVIAEoCVIIbm9kZU'
    '5hbWU=');

@$core.Deprecated('Use listDownloadJobsRequestDescriptor instead')
const ListDownloadJobsRequest$json = {
  '1': 'ListDownloadJobsRequest',
};

/// Descriptor for `ListDownloadJobsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDownloadJobsRequestDescriptor =
    $convert.base64Decode('ChdMaXN0RG93bmxvYWRKb2JzUmVxdWVzdA==');

@$core.Deprecated('Use listDownloadJobsResponseDescriptor instead')
const ListDownloadJobsResponse$json = {
  '1': 'ListDownloadJobsResponse',
  '2': [
    {
      '1': 'jobs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.DownloadJob',
      '10': 'jobs'
    },
  ],
};

/// Descriptor for `ListDownloadJobsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDownloadJobsResponseDescriptor =
    $convert.base64Decode(
        'ChhMaXN0RG93bmxvYWRKb2JzUmVzcG9uc2USPAoEam9icxgBIAMoCzIoLmN1bHBlb3N0dWRpby'
        '5tYXJrZXRwbGFjZS52MS5Eb3dubG9hZEpvYlIEam9icw==');

@$core.Deprecated('Use getDownloadJobRequestDescriptor instead')
const GetDownloadJobRequest$json = {
  '1': 'GetDownloadJobRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetDownloadJobRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDownloadJobRequestDescriptor = $convert
    .base64Decode('ChVHZXREb3dubG9hZEpvYlJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use getDownloadJobResponseDescriptor instead')
const GetDownloadJobResponse$json = {
  '1': 'GetDownloadJobResponse',
  '2': [
    {
      '1': 'job',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.DownloadJob',
      '10': 'job'
    },
  ],
};

/// Descriptor for `GetDownloadJobResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDownloadJobResponseDescriptor =
    $convert.base64Decode(
        'ChZHZXREb3dubG9hZEpvYlJlc3BvbnNlEjoKA2pvYhgBIAEoCzIoLmN1bHBlb3N0dWRpby5tYX'
        'JrZXRwbGFjZS52MS5Eb3dubG9hZEpvYlIDam9i');

@$core.Deprecated('Use deleteDownloadJobRequestDescriptor instead')
const DeleteDownloadJobRequest$json = {
  '1': 'DeleteDownloadJobRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteDownloadJobRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteDownloadJobRequestDescriptor = $convert
    .base64Decode('ChhEZWxldGVEb3dubG9hZEpvYlJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use deleteDownloadJobResponseDescriptor instead')
const DeleteDownloadJobResponse$json = {
  '1': 'DeleteDownloadJobResponse',
};

/// Descriptor for `DeleteDownloadJobResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteDownloadJobResponseDescriptor =
    $convert.base64Decode('ChlEZWxldGVEb3dubG9hZEpvYlJlc3BvbnNl');

@$core.Deprecated('Use activeApiModelDescriptor instead')
const ActiveApiModel$json = {
  '1': 'ActiveApiModel',
  '2': [
    {
      '1': 'provider',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Provider',
      '10': 'provider'
    },
    {'1': 'model_id', '3': 2, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'model_ref', '3': 4, '4': 1, '5': 9, '10': 'modelRef'},
    {
      '1': 'started_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startedAt'
    },
    {
      '1': 'last_used_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUsedAt'
    },
  ],
};

/// Descriptor for `ActiveApiModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeApiModelDescriptor = $convert.base64Decode(
    'Cg5BY3RpdmVBcGlNb2RlbBJBCghwcm92aWRlchgBIAEoDjIlLmN1bHBlb3N0dWRpby5tYXJrZX'
    'RwbGFjZS52MS5Qcm92aWRlclIIcHJvdmlkZXISGQoIbW9kZWxfaWQYAiABKAlSB21vZGVsSWQS'
    'IQoMZGlzcGxheV9uYW1lGAMgASgJUgtkaXNwbGF5TmFtZRIbCgltb2RlbF9yZWYYBCABKAlSCG'
    '1vZGVsUmVmEjkKCnN0YXJ0ZWRfYXQYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w'
    'UglzdGFydGVkQXQSPAoMbGFzdF91c2VkX2F0GAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbW'
    'VzdGFtcFIKbGFzdFVzZWRBdA==');

@$core.Deprecated('Use startApiModelRequestDescriptor instead')
const StartApiModelRequest$json = {
  '1': 'StartApiModelRequest',
  '2': [
    {
      '1': 'provider',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.marketplace.v1.Provider',
      '10': 'provider'
    },
    {'1': 'model_id', '3': 2, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `StartApiModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startApiModelRequestDescriptor = $convert.base64Decode(
    'ChRTdGFydEFwaU1vZGVsUmVxdWVzdBJBCghwcm92aWRlchgBIAEoDjIlLmN1bHBlb3N0dWRpby'
    '5tYXJrZXRwbGFjZS52MS5Qcm92aWRlclIIcHJvdmlkZXISGQoIbW9kZWxfaWQYAiABKAlSB21v'
    'ZGVsSWQSIQoMZGlzcGxheV9uYW1lGAMgASgJUgtkaXNwbGF5TmFtZQ==');

@$core.Deprecated('Use startApiModelResponseDescriptor instead')
const StartApiModelResponse$json = {
  '1': 'StartApiModelResponse',
  '2': [
    {
      '1': 'model',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.ActiveApiModel',
      '10': 'model'
    },
  ],
};

/// Descriptor for `StartApiModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startApiModelResponseDescriptor = $convert.base64Decode(
    'ChVTdGFydEFwaU1vZGVsUmVzcG9uc2USQQoFbW9kZWwYASABKAsyKy5jdWxwZW9zdHVkaW8ubW'
    'Fya2V0cGxhY2UudjEuQWN0aXZlQXBpTW9kZWxSBW1vZGVs');

@$core.Deprecated('Use listActiveApiModelsRequestDescriptor instead')
const ListActiveApiModelsRequest$json = {
  '1': 'ListActiveApiModelsRequest',
};

/// Descriptor for `ListActiveApiModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listActiveApiModelsRequestDescriptor =
    $convert.base64Decode('ChpMaXN0QWN0aXZlQXBpTW9kZWxzUmVxdWVzdA==');

@$core.Deprecated('Use listActiveApiModelsResponseDescriptor instead')
const ListActiveApiModelsResponse$json = {
  '1': 'ListActiveApiModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.marketplace.v1.ActiveApiModel',
      '10': 'models'
    },
  ],
};

/// Descriptor for `ListActiveApiModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listActiveApiModelsResponseDescriptor =
    $convert.base64Decode(
        'ChtMaXN0QWN0aXZlQXBpTW9kZWxzUmVzcG9uc2USQwoGbW9kZWxzGAEgAygLMisuY3VscGVvc3'
        'R1ZGlvLm1hcmtldHBsYWNlLnYxLkFjdGl2ZUFwaU1vZGVsUgZtb2RlbHM=');

@$core.Deprecated('Use deleteActiveApiModelRequestDescriptor instead')
const DeleteActiveApiModelRequest$json = {
  '1': 'DeleteActiveApiModelRequest',
  '2': [
    {'1': 'model_ref', '3': 1, '4': 1, '5': 9, '10': 'modelRef'},
  ],
};

/// Descriptor for `DeleteActiveApiModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteActiveApiModelRequestDescriptor =
    $convert.base64Decode(
        'ChtEZWxldGVBY3RpdmVBcGlNb2RlbFJlcXVlc3QSGwoJbW9kZWxfcmVmGAEgASgJUghtb2RlbF'
        'JlZg==');

@$core.Deprecated('Use deleteActiveApiModelResponseDescriptor instead')
const DeleteActiveApiModelResponse$json = {
  '1': 'DeleteActiveApiModelResponse',
};

/// Descriptor for `DeleteActiveApiModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteActiveApiModelResponseDescriptor =
    $convert.base64Decode('ChxEZWxldGVBY3RpdmVBcGlNb2RlbFJlc3BvbnNl');
