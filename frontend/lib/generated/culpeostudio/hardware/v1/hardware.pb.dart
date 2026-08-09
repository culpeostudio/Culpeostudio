// This is a generated file - do not edit.
//
// Generated from culpeostudio/hardware/v1/hardware.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// HardwareProfile is the detected machine profile. It is shared: the settings
/// screen shows it as system information and the marketplace matches models
/// against it.
class HardwareProfile extends $pb.GeneratedMessage {
  factory HardwareProfile({
    $core.String? os,
    $core.String? arch,
    $core.int? ramGb,
    $core.int? vramGb,
    $core.bool? hasGpu,
    $core.String? gpuName,
    $core.String? gpuVendor,
    $core.double? gpuMemoryBandwidthGbps,
    $core.Iterable<DetectedGpu>? gpus,
    $core.String? cpuName,
    $core.int? cpuCores,
    $core.bool? hasAvx2,
    $core.bool? hasAvx512,
    $core.String? diskFree,
    $fixnum.Int64? diskFreeBytes,
    $core.bool? detected,
    $core.String? detectionSource,
    $fixnum.Int64? ramTotalBytes,
    $fixnum.Int64? ramAvailableBytes,
    $0.Timestamp? capturedAt,
    $core.Iterable<EngineGpu>? engineGpus,
  }) {
    final result = create();
    if (os != null) result.os = os;
    if (arch != null) result.arch = arch;
    if (ramGb != null) result.ramGb = ramGb;
    if (vramGb != null) result.vramGb = vramGb;
    if (hasGpu != null) result.hasGpu = hasGpu;
    if (gpuName != null) result.gpuName = gpuName;
    if (gpuVendor != null) result.gpuVendor = gpuVendor;
    if (gpuMemoryBandwidthGbps != null)
      result.gpuMemoryBandwidthGbps = gpuMemoryBandwidthGbps;
    if (gpus != null) result.gpus.addAll(gpus);
    if (cpuName != null) result.cpuName = cpuName;
    if (cpuCores != null) result.cpuCores = cpuCores;
    if (hasAvx2 != null) result.hasAvx2 = hasAvx2;
    if (hasAvx512 != null) result.hasAvx512 = hasAvx512;
    if (diskFree != null) result.diskFree = diskFree;
    if (diskFreeBytes != null) result.diskFreeBytes = diskFreeBytes;
    if (detected != null) result.detected = detected;
    if (detectionSource != null) result.detectionSource = detectionSource;
    if (ramTotalBytes != null) result.ramTotalBytes = ramTotalBytes;
    if (ramAvailableBytes != null) result.ramAvailableBytes = ramAvailableBytes;
    if (capturedAt != null) result.capturedAt = capturedAt;
    if (engineGpus != null) result.engineGpus.addAll(engineGpus);
    return result;
  }

  HardwareProfile._();

  factory HardwareProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HardwareProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HardwareProfile',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.hardware.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'os')
    ..aOS(2, _omitFieldNames ? '' : 'arch')
    ..aI(3, _omitFieldNames ? '' : 'ramGb')
    ..aI(4, _omitFieldNames ? '' : 'vramGb')
    ..aOB(5, _omitFieldNames ? '' : 'hasGpu')
    ..aOS(6, _omitFieldNames ? '' : 'gpuName')
    ..aOS(7, _omitFieldNames ? '' : 'gpuVendor')
    ..aD(8, _omitFieldNames ? '' : 'gpuMemoryBandwidthGbps')
    ..pPM<DetectedGpu>(9, _omitFieldNames ? '' : 'gpus',
        subBuilder: DetectedGpu.create)
    ..aOS(10, _omitFieldNames ? '' : 'cpuName')
    ..aI(11, _omitFieldNames ? '' : 'cpuCores')
    ..aOB(12, _omitFieldNames ? '' : 'hasAvx2')
    ..aOB(13, _omitFieldNames ? '' : 'hasAvx512')
    ..aOS(14, _omitFieldNames ? '' : 'diskFree')
    ..aInt64(15, _omitFieldNames ? '' : 'diskFreeBytes')
    ..aOB(16, _omitFieldNames ? '' : 'detected')
    ..aOS(17, _omitFieldNames ? '' : 'detectionSource')
    ..aInt64(18, _omitFieldNames ? '' : 'ramTotalBytes')
    ..aInt64(19, _omitFieldNames ? '' : 'ramAvailableBytes')
    ..aOM<$0.Timestamp>(20, _omitFieldNames ? '' : 'capturedAt',
        subBuilder: $0.Timestamp.create)
    ..pPM<EngineGpu>(21, _omitFieldNames ? '' : 'engineGpus',
        subBuilder: EngineGpu.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HardwareProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HardwareProfile copyWith(void Function(HardwareProfile) updates) =>
      super.copyWith((message) => updates(message as HardwareProfile))
          as HardwareProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HardwareProfile create() => HardwareProfile._();
  @$core.override
  HardwareProfile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HardwareProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HardwareProfile>(create);
  static HardwareProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get os => $_getSZ(0);
  @$pb.TagNumber(1)
  set os($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOs() => $_has(0);
  @$pb.TagNumber(1)
  void clearOs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get arch => $_getSZ(1);
  @$pb.TagNumber(2)
  set arch($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArch() => $_has(1);
  @$pb.TagNumber(2)
  void clearArch() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get ramGb => $_getIZ(2);
  @$pb.TagNumber(3)
  set ramGb($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRamGb() => $_has(2);
  @$pb.TagNumber(3)
  void clearRamGb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get vramGb => $_getIZ(3);
  @$pb.TagNumber(4)
  set vramGb($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVramGb() => $_has(3);
  @$pb.TagNumber(4)
  void clearVramGb() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get hasGpu => $_getBF(4);
  @$pb.TagNumber(5)
  set hasGpu($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHasGpu() => $_has(4);
  @$pb.TagNumber(5)
  void clearHasGpu() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get gpuName => $_getSZ(5);
  @$pb.TagNumber(6)
  set gpuName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGpuName() => $_has(5);
  @$pb.TagNumber(6)
  void clearGpuName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get gpuVendor => $_getSZ(6);
  @$pb.TagNumber(7)
  set gpuVendor($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasGpuVendor() => $_has(6);
  @$pb.TagNumber(7)
  void clearGpuVendor() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get gpuMemoryBandwidthGbps => $_getN(7);
  @$pb.TagNumber(8)
  set gpuMemoryBandwidthGbps($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGpuMemoryBandwidthGbps() => $_has(7);
  @$pb.TagNumber(8)
  void clearGpuMemoryBandwidthGbps() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<DetectedGpu> get gpus => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get cpuName => $_getSZ(9);
  @$pb.TagNumber(10)
  set cpuName($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCpuName() => $_has(9);
  @$pb.TagNumber(10)
  void clearCpuName() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get cpuCores => $_getIZ(10);
  @$pb.TagNumber(11)
  set cpuCores($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCpuCores() => $_has(10);
  @$pb.TagNumber(11)
  void clearCpuCores() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get hasAvx2 => $_getBF(11);
  @$pb.TagNumber(12)
  set hasAvx2($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasHasAvx2() => $_has(11);
  @$pb.TagNumber(12)
  void clearHasAvx2() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get hasAvx512 => $_getBF(12);
  @$pb.TagNumber(13)
  set hasAvx512($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasHasAvx512() => $_has(12);
  @$pb.TagNumber(13)
  void clearHasAvx512() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get diskFree => $_getSZ(13);
  @$pb.TagNumber(14)
  set diskFree($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDiskFree() => $_has(13);
  @$pb.TagNumber(14)
  void clearDiskFree() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get diskFreeBytes => $_getI64(14);
  @$pb.TagNumber(15)
  set diskFreeBytes($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasDiskFreeBytes() => $_has(14);
  @$pb.TagNumber(15)
  void clearDiskFreeBytes() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get detected => $_getBF(15);
  @$pb.TagNumber(16)
  set detected($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasDetected() => $_has(15);
  @$pb.TagNumber(16)
  void clearDetected() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get detectionSource => $_getSZ(16);
  @$pb.TagNumber(17)
  set detectionSource($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDetectionSource() => $_has(16);
  @$pb.TagNumber(17)
  void clearDetectionSource() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get ramTotalBytes => $_getI64(17);
  @$pb.TagNumber(18)
  set ramTotalBytes($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasRamTotalBytes() => $_has(17);
  @$pb.TagNumber(18)
  void clearRamTotalBytes() => $_clearField(18);

  @$pb.TagNumber(19)
  $fixnum.Int64 get ramAvailableBytes => $_getI64(18);
  @$pb.TagNumber(19)
  set ramAvailableBytes($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(19)
  $core.bool hasRamAvailableBytes() => $_has(18);
  @$pb.TagNumber(19)
  void clearRamAvailableBytes() => $_clearField(19);

  @$pb.TagNumber(20)
  $0.Timestamp get capturedAt => $_getN(19);
  @$pb.TagNumber(20)
  set capturedAt($0.Timestamp value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasCapturedAt() => $_has(19);
  @$pb.TagNumber(20)
  void clearCapturedAt() => $_clearField(20);
  @$pb.TagNumber(20)
  $0.Timestamp ensureCapturedAt() => $_ensure(19);

  @$pb.TagNumber(21)
  $pb.PbList<EngineGpu> get engineGpus => $_getList(20);
}

/// DetectedGpu is the summarised view the marketplace matches against.
class DetectedGpu extends $pb.GeneratedMessage {
  factory DetectedGpu({
    $core.String? id,
    $core.int? index,
    $core.String? name,
    $core.String? vendor,
    $core.String? backend,
    $core.int? vramGb,
    $fixnum.Int64? vramTotalBytes,
    $fixnum.Int64? vramUsedBytes,
    $fixnum.Int64? vramFreeBytes,
    $core.bool? sharedMemory,
    $core.double? memoryBandwidthGbps,
    $core.String? computeCapability,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (index != null) result.index = index;
    if (name != null) result.name = name;
    if (vendor != null) result.vendor = vendor;
    if (backend != null) result.backend = backend;
    if (vramGb != null) result.vramGb = vramGb;
    if (vramTotalBytes != null) result.vramTotalBytes = vramTotalBytes;
    if (vramUsedBytes != null) result.vramUsedBytes = vramUsedBytes;
    if (vramFreeBytes != null) result.vramFreeBytes = vramFreeBytes;
    if (sharedMemory != null) result.sharedMemory = sharedMemory;
    if (memoryBandwidthGbps != null)
      result.memoryBandwidthGbps = memoryBandwidthGbps;
    if (computeCapability != null) result.computeCapability = computeCapability;
    return result;
  }

  DetectedGpu._();

  factory DetectedGpu.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetectedGpu.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetectedGpu',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.hardware.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'index')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'vendor')
    ..aOS(5, _omitFieldNames ? '' : 'backend')
    ..aI(6, _omitFieldNames ? '' : 'vramGb')
    ..aInt64(7, _omitFieldNames ? '' : 'vramTotalBytes')
    ..aInt64(8, _omitFieldNames ? '' : 'vramUsedBytes')
    ..aInt64(9, _omitFieldNames ? '' : 'vramFreeBytes')
    ..aOB(10, _omitFieldNames ? '' : 'sharedMemory')
    ..aD(11, _omitFieldNames ? '' : 'memoryBandwidthGbps')
    ..aOS(12, _omitFieldNames ? '' : 'computeCapability')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectedGpu clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectedGpu copyWith(void Function(DetectedGpu) updates) =>
      super.copyWith((message) => updates(message as DetectedGpu))
          as DetectedGpu;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetectedGpu create() => DetectedGpu._();
  @$core.override
  DetectedGpu createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetectedGpu getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetectedGpu>(create);
  static DetectedGpu? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get vendor => $_getSZ(3);
  @$pb.TagNumber(4)
  set vendor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVendor() => $_has(3);
  @$pb.TagNumber(4)
  void clearVendor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get backend => $_getSZ(4);
  @$pb.TagNumber(5)
  set backend($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBackend() => $_has(4);
  @$pb.TagNumber(5)
  void clearBackend() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get vramGb => $_getIZ(5);
  @$pb.TagNumber(6)
  set vramGb($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVramGb() => $_has(5);
  @$pb.TagNumber(6)
  void clearVramGb() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get vramTotalBytes => $_getI64(6);
  @$pb.TagNumber(7)
  set vramTotalBytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasVramTotalBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearVramTotalBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get vramUsedBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set vramUsedBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVramUsedBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearVramUsedBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get vramFreeBytes => $_getI64(8);
  @$pb.TagNumber(9)
  set vramFreeBytes($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasVramFreeBytes() => $_has(8);
  @$pb.TagNumber(9)
  void clearVramFreeBytes() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get sharedMemory => $_getBF(9);
  @$pb.TagNumber(10)
  set sharedMemory($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSharedMemory() => $_has(9);
  @$pb.TagNumber(10)
  void clearSharedMemory() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get memoryBandwidthGbps => $_getN(10);
  @$pb.TagNumber(11)
  set memoryBandwidthGbps($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMemoryBandwidthGbps() => $_has(10);
  @$pb.TagNumber(11)
  void clearMemoryBandwidthGbps() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get computeCapability => $_getSZ(11);
  @$pb.TagNumber(12)
  set computeCapability($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasComputeCapability() => $_has(11);
  @$pb.TagNumber(12)
  void clearComputeCapability() => $_clearField(12);
}

/// EngineGpu is the fuller reading taken from the live hardware snapshot,
/// including telemetry the summarised view drops.
class EngineGpu extends $pb.GeneratedMessage {
  factory EngineGpu({
    $core.String? id,
    $core.int? index,
    $core.String? name,
    $core.String? vendor,
    $core.String? backend,
    $fixnum.Int64? vramTotalBytes,
    $fixnum.Int64? vramUsedBytes,
    $fixnum.Int64? vramFreeBytes,
    $core.bool? vramTelemetryUnavailable,
    $core.bool? sharedMemory,
    $core.String? computeCapability,
    $core.String? driverVersion,
    $core.double? memoryBandwidthGbps,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (index != null) result.index = index;
    if (name != null) result.name = name;
    if (vendor != null) result.vendor = vendor;
    if (backend != null) result.backend = backend;
    if (vramTotalBytes != null) result.vramTotalBytes = vramTotalBytes;
    if (vramUsedBytes != null) result.vramUsedBytes = vramUsedBytes;
    if (vramFreeBytes != null) result.vramFreeBytes = vramFreeBytes;
    if (vramTelemetryUnavailable != null)
      result.vramTelemetryUnavailable = vramTelemetryUnavailable;
    if (sharedMemory != null) result.sharedMemory = sharedMemory;
    if (computeCapability != null) result.computeCapability = computeCapability;
    if (driverVersion != null) result.driverVersion = driverVersion;
    if (memoryBandwidthGbps != null)
      result.memoryBandwidthGbps = memoryBandwidthGbps;
    return result;
  }

  EngineGpu._();

  factory EngineGpu.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineGpu.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineGpu',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'culpeostudio.hardware.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'index')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'vendor')
    ..aOS(5, _omitFieldNames ? '' : 'backend')
    ..aInt64(6, _omitFieldNames ? '' : 'vramTotalBytes')
    ..aInt64(7, _omitFieldNames ? '' : 'vramUsedBytes')
    ..aInt64(8, _omitFieldNames ? '' : 'vramFreeBytes')
    ..aOB(9, _omitFieldNames ? '' : 'vramTelemetryUnavailable')
    ..aOB(10, _omitFieldNames ? '' : 'sharedMemory')
    ..aOS(11, _omitFieldNames ? '' : 'computeCapability')
    ..aOS(12, _omitFieldNames ? '' : 'driverVersion')
    ..aD(13, _omitFieldNames ? '' : 'memoryBandwidthGbps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineGpu clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineGpu copyWith(void Function(EngineGpu) updates) =>
      super.copyWith((message) => updates(message as EngineGpu)) as EngineGpu;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineGpu create() => EngineGpu._();
  @$core.override
  EngineGpu createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineGpu getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EngineGpu>(create);
  static EngineGpu? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get vendor => $_getSZ(3);
  @$pb.TagNumber(4)
  set vendor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVendor() => $_has(3);
  @$pb.TagNumber(4)
  void clearVendor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get backend => $_getSZ(4);
  @$pb.TagNumber(5)
  set backend($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBackend() => $_has(4);
  @$pb.TagNumber(5)
  void clearBackend() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get vramTotalBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set vramTotalBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVramTotalBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearVramTotalBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get vramUsedBytes => $_getI64(6);
  @$pb.TagNumber(7)
  set vramUsedBytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasVramUsedBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearVramUsedBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get vramFreeBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set vramFreeBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVramFreeBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearVramFreeBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get vramTelemetryUnavailable => $_getBF(8);
  @$pb.TagNumber(9)
  set vramTelemetryUnavailable($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasVramTelemetryUnavailable() => $_has(8);
  @$pb.TagNumber(9)
  void clearVramTelemetryUnavailable() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get sharedMemory => $_getBF(9);
  @$pb.TagNumber(10)
  set sharedMemory($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSharedMemory() => $_has(9);
  @$pb.TagNumber(10)
  void clearSharedMemory() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get computeCapability => $_getSZ(10);
  @$pb.TagNumber(11)
  set computeCapability($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasComputeCapability() => $_has(10);
  @$pb.TagNumber(11)
  void clearComputeCapability() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get driverVersion => $_getSZ(11);
  @$pb.TagNumber(12)
  set driverVersion($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDriverVersion() => $_has(11);
  @$pb.TagNumber(12)
  void clearDriverVersion() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get memoryBandwidthGbps => $_getN(12);
  @$pb.TagNumber(13)
  set memoryBandwidthGbps($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasMemoryBandwidthGbps() => $_has(12);
  @$pb.TagNumber(13)
  void clearMemoryBandwidthGbps() => $_clearField(13);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
