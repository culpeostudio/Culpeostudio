package marketplace

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

const (
	culpeoStudioHardwarePythonEnv = "CULPEOSTUDIO_HARDWARE_PYTHON"
	culpeoStudioHardwareProbeEnv  = "CULPEOSTUDIO_HARDWARE_PROBE_PATH"
	legacyWhichLLMPythonEnv       = "WHICHLLM_PYTHON"
	legacyWhichLLMProbeEnv        = "WHICHLLM_PROBE_PATH"
)

type culpeoStudioProbeGPU struct {
	Name                string   `json:"name"`
	Vendor              string   `json:"vendor"`
	VRAMBytes           int64    `json:"vram_bytes"`
	UsableVRAMBytes     *int64   `json:"usable_vram_bytes"`
	MemoryBandwidthGBPS *float64 `json:"memory_bandwidth_gbps"`
	SharedMemory        bool     `json:"shared_memory"`
	ComputeCapability   []int    `json:"compute_capability"`
}

type culpeoStudioProbeResult struct {
	OS            string                 `json:"os"`
	CPUName       string                 `json:"cpu_name"`
	CPUCores      int                    `json:"cpu_cores"`
	HasAVX2       bool                   `json:"has_avx2"`
	HasAVX512     bool                   `json:"has_avx512"`
	RAMBytes      int64                  `json:"ram_bytes"`
	DiskFreeBytes int64                  `json:"disk_free_bytes"`
	GPUs          []culpeoStudioProbeGPU `json:"gpus"`
	Error         string                 `json:"error"`
}

func detectHardwareProfileWithCulpeoStudio() (HardwareProfile, error) {
	python, err := culpeoStudioPythonExecutable()
	if err != nil {
		return HardwareProfile{}, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()
	command := exec.CommandContext(ctx, python, culpeoStudioProbePath())
	output, err := command.Output()
	if ctx.Err() != nil {
		return HardwareProfile{}, fmt.Errorf("Culpeo Studio hardware detection timed out")
	}
	if err != nil {
		return HardwareProfile{}, fmt.Errorf("Culpeo Studio hardware detection: %w", err)
	}

	var result culpeoStudioProbeResult
	if err := json.Unmarshal(output, &result); err != nil {
		return HardwareProfile{}, fmt.Errorf("invalid Culpeo Studio hardware JSON: %w", err)
	}
	if strings.TrimSpace(result.Error) != "" {
		return HardwareProfile{}, fmt.Errorf("Culpeo Studio hardware detection failed: %s", result.Error)
	}
	if result.RAMBytes <= 0 {
		return HardwareProfile{}, fmt.Errorf("Culpeo Studio hardware detection did not report RAM")
	}

	profile := HardwareProfile{
		OS:              firstNonEmpty(strings.TrimSpace(result.OS), runtime.GOOS),
		Arch:            runtime.GOARCH,
		RAMGB:           bytesToGiB(result.RAMBytes),
		DiskFreeBytes:   result.DiskFreeBytes,
		DiskFree:        formatBytesAsGB(result.DiskFreeBytes),
		CPUName:         strings.TrimSpace(result.CPUName),
		CPUCores:        result.CPUCores,
		HasAVX2:         result.HasAVX2,
		HasAVX512:       result.HasAVX512,
		Detected:        true,
		DetectionSource: "culpeostudio_hardware",
		GPUs:            make([]DetectedGPU, 0, len(result.GPUs)),
	}
	for _, gpu := range result.GPUs {
		available := gpu.VRAMBytes
		if gpu.UsableVRAMBytes != nil && *gpu.UsableVRAMBytes > 0 {
			available = *gpu.UsableVRAMBytes
		}
		entry := DetectedGPU{
			Name:                normalizeCulpeoStudioGPUName(gpu.Vendor, gpu.Name),
			Vendor:              strings.TrimSpace(gpu.Vendor),
			VRAMGB:              bytesToGiB(available),
			SharedMemory:        gpu.SharedMemory,
			MemoryBandwidthGBPS: derefFloat(gpu.MemoryBandwidthGBPS),
		}
		if len(gpu.ComputeCapability) == 2 {
			entry.ComputeCapability = fmt.Sprintf("%d.%d", gpu.ComputeCapability[0], gpu.ComputeCapability[1])
		}
		profile.GPUs = append(profile.GPUs, entry)

		if profile.GPUName == "" && entry.Name != "" {
			profile.GPUName = entry.Name
			profile.GPUVendor = entry.Vendor
			profile.GPUMemoryBandwidthGBPS = entry.MemoryBandwidthGBPS
		}
		if available > 0 && (profile.VRAMGB == 0 || entry.VRAMGB > profile.VRAMGB) {
			profile.VRAMGB = entry.VRAMGB
			profile.GPUName = entry.Name
			profile.GPUVendor = entry.Vendor
			profile.GPUMemoryBandwidthGBPS = entry.MemoryBandwidthGBPS
		}
	}
	profile.HasGPU = len(profile.GPUs) > 0
	return profile, nil
}

func normalizeCulpeoStudioGPUName(vendor, name string) string {
	trimmed := strings.TrimSpace(name)
	parts := strings.Fields(strings.ToLower(trimmed))
	if len(parts) == 2 && parts[0] == "device" {
		if id, err := strconv.ParseUint(parts[1], 16, 16); err == nil {
			mapped := linuxGPUName("0x"+strings.ToLower(strings.TrimSpace(vendorToPCI(vendor))), fmt.Sprintf("0x%04x", id))
			if mapped != "" && !strings.Contains(strings.ToLower(mapped), " gpu ") {
				return mapped
			}
		}
	}
	return trimmed
}

func vendorToPCI(vendor string) string {
	switch strings.ToLower(strings.TrimSpace(vendor)) {
	case "amd":
		return "1002"
	case "nvidia":
		return "10de"
	case "intel":
		return "8086"
	default:
		return ""
	}
}

func culpeoStudioPythonExecutable() (string, error) {
	if configured := firstNonEmpty(
		os.Getenv(culpeoStudioHardwarePythonEnv),
		os.Getenv(legacyWhichLLMPythonEnv),
	); configured != "" {
		return configured, nil
	}
	local := filepath.Join(".venv", "bin", "python")
	if runtime.GOOS == "windows" {
		local = filepath.Join(".venv", "Scripts", "python.exe")
	}
	if _, err := os.Stat(local); err == nil {
		return local, nil
	}
	if path, err := exec.LookPath("python3"); err == nil {
		return path, nil
	}
	return "", fmt.Errorf("Culpeo Studio hardware Python interpreter not found")
}

func culpeoStudioProbePath() string {
	if configured := firstNonEmpty(
		os.Getenv(culpeoStudioHardwareProbeEnv),
		os.Getenv(legacyWhichLLMProbeEnv),
	); configured != "" {
		return configured
	}
	preferred := filepath.Join("tools", "culpeostudio_hardware_probe.py")
	if _, err := os.Stat(preferred); err == nil {
		return preferred
	}
	legacy := filepath.Join("tools", "whichllm_hardware_probe.py")
	if _, err := os.Stat(legacy); err == nil {
		return legacy
	}
	return preferred
}

func derefFloat(value *float64) float64 {
	if value == nil {
		return 0
	}
	return *value
}

func formatBytesAsGB(bytes int64) string {
	if bytes <= 0 {
		return ""
	}
	return fmt.Sprintf("%.1f GB", float64(bytes)/float64(1024*1024*1024))
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value = strings.TrimSpace(value); value != "" {
			return value
		}
	}
	return ""
}
