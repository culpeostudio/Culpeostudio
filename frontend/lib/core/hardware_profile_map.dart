import '../generated/culpeostudio/hardware/v1/hardware.pb.dart' as hwpb;

/// Flattens the detected machine profile for the widgets, which read it as a
/// plain map. Shared because the backend serves the same message twice: the
/// settings screen shows it as system information and the marketplace matches
/// models against it.
///
/// Absent keys are kept absent, mirroring the `omitempty` of the JSON this
/// replaced: the UI falls back to placeholders like "no GPU" when a field is
/// missing, and proto3 would hand it an empty string instead.
Map<String, dynamic> hardwareProfileToMap(hwpb.HardwareProfile profile) {
  return {
    'os': profile.os,
    'arch': profile.arch,
    'ram_gb': profile.ramGb,
    'vram_gb': profile.vramGb,
    'has_gpu': profile.hasGpu,
    if (profile.gpuName.isNotEmpty) 'gpu_name': profile.gpuName,
    if (profile.gpuVendor.isNotEmpty) 'gpu_vendor': profile.gpuVendor,
    if (profile.cpuName.isNotEmpty) 'cpu_name': profile.cpuName,
    if (profile.cpuCores != 0) 'cpu_cores': profile.cpuCores,
    if (profile.diskFree.isNotEmpty) 'disk_free': profile.diskFree,
    if (profile.diskFreeBytes != 0)
      'disk_free_bytes': profile.diskFreeBytes.toInt(),
    'detected': profile.detected,
    if (profile.detectionSource.isNotEmpty)
      'detection_source': profile.detectionSource,
    if (profile.ramTotalBytes != 0)
      'ram_total_bytes': profile.ramTotalBytes.toInt(),
    if (profile.ramAvailableBytes != 0)
      'ram_available_bytes': profile.ramAvailableBytes.toInt(),
  };
}
