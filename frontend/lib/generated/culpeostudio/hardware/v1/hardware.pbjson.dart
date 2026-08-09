// This is a generated file - do not edit.
//
// Generated from culpeostudio/hardware/v1/hardware.proto.

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

@$core.Deprecated('Use hardwareProfileDescriptor instead')
const HardwareProfile$json = {
  '1': 'HardwareProfile',
  '2': [
    {'1': 'os', '3': 1, '4': 1, '5': 9, '10': 'os'},
    {'1': 'arch', '3': 2, '4': 1, '5': 9, '10': 'arch'},
    {'1': 'ram_gb', '3': 3, '4': 1, '5': 5, '10': 'ramGb'},
    {'1': 'vram_gb', '3': 4, '4': 1, '5': 5, '10': 'vramGb'},
    {'1': 'has_gpu', '3': 5, '4': 1, '5': 8, '10': 'hasGpu'},
    {'1': 'gpu_name', '3': 6, '4': 1, '5': 9, '10': 'gpuName'},
    {'1': 'gpu_vendor', '3': 7, '4': 1, '5': 9, '10': 'gpuVendor'},
    {
      '1': 'gpu_memory_bandwidth_gbps',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'gpuMemoryBandwidthGbps'
    },
    {
      '1': 'gpus',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.DetectedGpu',
      '10': 'gpus'
    },
    {'1': 'cpu_name', '3': 10, '4': 1, '5': 9, '10': 'cpuName'},
    {'1': 'cpu_cores', '3': 11, '4': 1, '5': 5, '10': 'cpuCores'},
    {'1': 'has_avx2', '3': 12, '4': 1, '5': 8, '10': 'hasAvx2'},
    {'1': 'has_avx512', '3': 13, '4': 1, '5': 8, '10': 'hasAvx512'},
    {'1': 'disk_free', '3': 14, '4': 1, '5': 9, '10': 'diskFree'},
    {'1': 'disk_free_bytes', '3': 15, '4': 1, '5': 3, '10': 'diskFreeBytes'},
    {'1': 'detected', '3': 16, '4': 1, '5': 8, '10': 'detected'},
    {'1': 'detection_source', '3': 17, '4': 1, '5': 9, '10': 'detectionSource'},
    {'1': 'ram_total_bytes', '3': 18, '4': 1, '5': 3, '10': 'ramTotalBytes'},
    {
      '1': 'ram_available_bytes',
      '3': 19,
      '4': 1,
      '5': 3,
      '10': 'ramAvailableBytes'
    },
    {
      '1': 'captured_at',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'capturedAt'
    },
    {
      '1': 'engine_gpus',
      '3': 21,
      '4': 3,
      '5': 11,
      '6': '.culpeostudio.hardware.v1.EngineGpu',
      '10': 'engineGpus'
    },
  ],
};

/// Descriptor for `HardwareProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hardwareProfileDescriptor = $convert.base64Decode(
    'Cg9IYXJkd2FyZVByb2ZpbGUSDgoCb3MYASABKAlSAm9zEhIKBGFyY2gYAiABKAlSBGFyY2gSFQ'
    'oGcmFtX2diGAMgASgFUgVyYW1HYhIXCgd2cmFtX2diGAQgASgFUgZ2cmFtR2ISFwoHaGFzX2dw'
    'dRgFIAEoCFIGaGFzR3B1EhkKCGdwdV9uYW1lGAYgASgJUgdncHVOYW1lEh0KCmdwdV92ZW5kb3'
    'IYByABKAlSCWdwdVZlbmRvchI5ChlncHVfbWVtb3J5X2JhbmR3aWR0aF9nYnBzGAggASgBUhZn'
    'cHVNZW1vcnlCYW5kd2lkdGhHYnBzEjkKBGdwdXMYCSADKAsyJS5jdWxwZW9zdHVkaW8uaGFyZH'
    'dhcmUudjEuRGV0ZWN0ZWRHcHVSBGdwdXMSGQoIY3B1X25hbWUYCiABKAlSB2NwdU5hbWUSGwoJ'
    'Y3B1X2NvcmVzGAsgASgFUghjcHVDb3JlcxIZCghoYXNfYXZ4MhgMIAEoCFIHaGFzQXZ4MhIdCg'
    'poYXNfYXZ4NTEyGA0gASgIUgloYXNBdng1MTISGwoJZGlza19mcmVlGA4gASgJUghkaXNrRnJl'
    'ZRImCg9kaXNrX2ZyZWVfYnl0ZXMYDyABKANSDWRpc2tGcmVlQnl0ZXMSGgoIZGV0ZWN0ZWQYEC'
    'ABKAhSCGRldGVjdGVkEikKEGRldGVjdGlvbl9zb3VyY2UYESABKAlSD2RldGVjdGlvblNvdXJj'
    'ZRImCg9yYW1fdG90YWxfYnl0ZXMYEiABKANSDXJhbVRvdGFsQnl0ZXMSLgoTcmFtX2F2YWlsYW'
    'JsZV9ieXRlcxgTIAEoA1IRcmFtQXZhaWxhYmxlQnl0ZXMSOwoLY2FwdHVyZWRfYXQYFCABKAsy'
    'Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjYXB0dXJlZEF0EkQKC2VuZ2luZV9ncHVzGB'
    'UgAygLMiMuY3VscGVvc3R1ZGlvLmhhcmR3YXJlLnYxLkVuZ2luZUdwdVIKZW5naW5lR3B1cw==');

@$core.Deprecated('Use detectedGpuDescriptor instead')
const DetectedGpu$json = {
  '1': 'DetectedGpu',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'index', '3': 2, '4': 1, '5': 5, '10': 'index'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'vendor', '3': 4, '4': 1, '5': 9, '10': 'vendor'},
    {'1': 'backend', '3': 5, '4': 1, '5': 9, '10': 'backend'},
    {'1': 'vram_gb', '3': 6, '4': 1, '5': 5, '10': 'vramGb'},
    {'1': 'vram_total_bytes', '3': 7, '4': 1, '5': 3, '10': 'vramTotalBytes'},
    {'1': 'vram_used_bytes', '3': 8, '4': 1, '5': 3, '10': 'vramUsedBytes'},
    {'1': 'vram_free_bytes', '3': 9, '4': 1, '5': 3, '10': 'vramFreeBytes'},
    {'1': 'shared_memory', '3': 10, '4': 1, '5': 8, '10': 'sharedMemory'},
    {
      '1': 'memory_bandwidth_gbps',
      '3': 11,
      '4': 1,
      '5': 1,
      '10': 'memoryBandwidthGbps'
    },
    {
      '1': 'compute_capability',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'computeCapability'
    },
  ],
};

/// Descriptor for `DetectedGpu`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detectedGpuDescriptor = $convert.base64Decode(
    'CgtEZXRlY3RlZEdwdRIOCgJpZBgBIAEoCVICaWQSFAoFaW5kZXgYAiABKAVSBWluZGV4EhIKBG'
    '5hbWUYAyABKAlSBG5hbWUSFgoGdmVuZG9yGAQgASgJUgZ2ZW5kb3ISGAoHYmFja2VuZBgFIAEo'
    'CVIHYmFja2VuZBIXCgd2cmFtX2diGAYgASgFUgZ2cmFtR2ISKAoQdnJhbV90b3RhbF9ieXRlcx'
    'gHIAEoA1IOdnJhbVRvdGFsQnl0ZXMSJgoPdnJhbV91c2VkX2J5dGVzGAggASgDUg12cmFtVXNl'
    'ZEJ5dGVzEiYKD3ZyYW1fZnJlZV9ieXRlcxgJIAEoA1INdnJhbUZyZWVCeXRlcxIjCg1zaGFyZW'
    'RfbWVtb3J5GAogASgIUgxzaGFyZWRNZW1vcnkSMgoVbWVtb3J5X2JhbmR3aWR0aF9nYnBzGAsg'
    'ASgBUhNtZW1vcnlCYW5kd2lkdGhHYnBzEi0KEmNvbXB1dGVfY2FwYWJpbGl0eRgMIAEoCVIRY2'
    '9tcHV0ZUNhcGFiaWxpdHk=');

@$core.Deprecated('Use engineGpuDescriptor instead')
const EngineGpu$json = {
  '1': 'EngineGpu',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'index', '3': 2, '4': 1, '5': 5, '10': 'index'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'vendor', '3': 4, '4': 1, '5': 9, '10': 'vendor'},
    {'1': 'backend', '3': 5, '4': 1, '5': 9, '10': 'backend'},
    {'1': 'vram_total_bytes', '3': 6, '4': 1, '5': 3, '10': 'vramTotalBytes'},
    {'1': 'vram_used_bytes', '3': 7, '4': 1, '5': 3, '10': 'vramUsedBytes'},
    {'1': 'vram_free_bytes', '3': 8, '4': 1, '5': 3, '10': 'vramFreeBytes'},
    {
      '1': 'vram_telemetry_unavailable',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'vramTelemetryUnavailable'
    },
    {'1': 'shared_memory', '3': 10, '4': 1, '5': 8, '10': 'sharedMemory'},
    {
      '1': 'compute_capability',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'computeCapability'
    },
    {'1': 'driver_version', '3': 12, '4': 1, '5': 9, '10': 'driverVersion'},
    {
      '1': 'memory_bandwidth_gbps',
      '3': 13,
      '4': 1,
      '5': 1,
      '10': 'memoryBandwidthGbps'
    },
  ],
};

/// Descriptor for `EngineGpu`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineGpuDescriptor = $convert.base64Decode(
    'CglFbmdpbmVHcHUSDgoCaWQYASABKAlSAmlkEhQKBWluZGV4GAIgASgFUgVpbmRleBISCgRuYW'
    '1lGAMgASgJUgRuYW1lEhYKBnZlbmRvchgEIAEoCVIGdmVuZG9yEhgKB2JhY2tlbmQYBSABKAlS'
    'B2JhY2tlbmQSKAoQdnJhbV90b3RhbF9ieXRlcxgGIAEoA1IOdnJhbVRvdGFsQnl0ZXMSJgoPdn'
    'JhbV91c2VkX2J5dGVzGAcgASgDUg12cmFtVXNlZEJ5dGVzEiYKD3ZyYW1fZnJlZV9ieXRlcxgI'
    'IAEoA1INdnJhbUZyZWVCeXRlcxI8Chp2cmFtX3RlbGVtZXRyeV91bmF2YWlsYWJsZRgJIAEoCF'
    'IYdnJhbVRlbGVtZXRyeVVuYXZhaWxhYmxlEiMKDXNoYXJlZF9tZW1vcnkYCiABKAhSDHNoYXJl'
    'ZE1lbW9yeRItChJjb21wdXRlX2NhcGFiaWxpdHkYCyABKAlSEWNvbXB1dGVDYXBhYmlsaXR5Ei'
    'UKDmRyaXZlcl92ZXJzaW9uGAwgASgJUg1kcml2ZXJWZXJzaW9uEjIKFW1lbW9yeV9iYW5kd2lk'
    'dGhfZ2JwcxgNIAEoAVITbWVtb3J5QmFuZHdpZHRoR2Jwcw==');
