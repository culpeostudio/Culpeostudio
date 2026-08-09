package marketplace

import (
	"google.golang.org/protobuf/types/known/timestamppb"

	hardwarev1 "github.com/culpeohq/backend/gen/go/culpeostudio/hardware/v1"
)

// HardwareProfileToProto converts a detected profile for the wire. It lives
// here because HardwareProfile does, and both the settings service (as system
// information) and the marketplace itself hand it to the client.
func HardwareProfileToProto(profile HardwareProfile) *hardwarev1.HardwareProfile {
	message := &hardwarev1.HardwareProfile{
		Os:                     profile.OS,
		Arch:                   profile.Arch,
		RamGb:                  int32(profile.RAMGB),
		VramGb:                 int32(profile.VRAMGB),
		HasGpu:                 profile.HasGPU,
		GpuName:                profile.GPUName,
		GpuVendor:              profile.GPUVendor,
		GpuMemoryBandwidthGbps: profile.GPUMemoryBandwidthGBPS,
		CpuName:                profile.CPUName,
		CpuCores:               int32(profile.CPUCores),
		HasAvx2:                profile.HasAVX2,
		HasAvx512:              profile.HasAVX512,
		DiskFree:               profile.DiskFree,
		DiskFreeBytes:          profile.DiskFreeBytes,
		Detected:               profile.Detected,
		DetectionSource:        profile.DetectionSource,
		RamTotalBytes:          profile.RAMTotalBytes,
		RamAvailableBytes:      profile.RAMAvailableBytes,
	}

	// A profile that was never captured carries the zero time; leaving the
	// field unset says "unknown" rather than reporting the epoch.
	if !profile.CapturedAt.IsZero() {
		message.CapturedAt = timestamppb.New(profile.CapturedAt)
	}

	message.Gpus = make([]*hardwarev1.DetectedGpu, 0, len(profile.GPUs))
	for _, gpu := range profile.GPUs {
		message.Gpus = append(message.Gpus, &hardwarev1.DetectedGpu{
			Id:                  gpu.ID,
			Index:               int32(gpu.Index),
			Name:                gpu.Name,
			Vendor:              gpu.Vendor,
			Backend:             gpu.Backend,
			VramGb:              int32(gpu.VRAMGB),
			VramTotalBytes:      gpu.VRAMTotalBytes,
			VramUsedBytes:       gpu.VRAMUsedBytes,
			VramFreeBytes:       gpu.VRAMFreeBytes,
			SharedMemory:        gpu.SharedMemory,
			MemoryBandwidthGbps: gpu.MemoryBandwidthGBPS,
			ComputeCapability:   gpu.ComputeCapability,
		})
	}

	message.EngineGpus = make([]*hardwarev1.EngineGpu, 0, len(profile.EngineGPUs))
	for _, gpu := range profile.EngineGPUs {
		message.EngineGpus = append(message.EngineGpus, &hardwarev1.EngineGpu{
			Id:                       gpu.ID,
			Index:                    int32(gpu.Index),
			Name:                     gpu.Name,
			Vendor:                   gpu.Vendor,
			Backend:                  gpu.Backend,
			VramTotalBytes:           gpu.VRAMTotalBytes,
			VramUsedBytes:            gpu.VRAMUsedBytes,
			VramFreeBytes:            gpu.VRAMFreeBytes,
			VramTelemetryUnavailable: gpu.VRAMTelemetryUnavailable,
			SharedMemory:             gpu.SharedMemory,
			ComputeCapability:        gpu.ComputeCapability,
			DriverVersion:            gpu.DriverVersion,
			MemoryBandwidthGbps:      gpu.MemoryBandwidth,
		})
	}

	return message
}
