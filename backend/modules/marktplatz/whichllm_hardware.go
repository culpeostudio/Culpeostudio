package marktplatz

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

type whichLLMProbeGPU struct {
	Name                string   `json:"name"`
	Vendor              string   `json:"vendor"`
	VRAMBytes           int64    `json:"vram_bytes"`
	UsableVRAMBytes     *int64   `json:"usable_vram_bytes"`
	MemoryBandwidthGBPS *float64 `json:"memory_bandwidth_gbps"`
	SharedMemory        bool     `json:"shared_memory"`
	ComputeCapability   []int    `json:"compute_capability"`
}

type whichLLMProbeResult struct {
	OS            string             `json:"os"`
	CPUName       string             `json:"cpu_name"`
	CPUCores      int                `json:"cpu_cores"`
	HasAVX2       bool               `json:"has_avx2"`
	HasAVX512     bool               `json:"has_avx512"`
	RAMBytes      int64              `json:"ram_bytes"`
	DiskFreeBytes int64              `json:"disk_free_bytes"`
	GPUs          []whichLLMProbeGPU `json:"gpus"`
	Error         string             `json:"error"`
}

// detectHardwareProfileWithWhichLLM runs the original Python detector in a
// short-lived local process.  It has no network access and its result is
// cached by detectHardwareProfile, so it cannot affect request throughput.
func detectHardwareProfileWithWhichLLM() (HardwareProfile, error) {
	python, err := whichLLMPythonExecutable()
	if err != nil {
		return HardwareProfile{}, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()
	command := exec.CommandContext(ctx, python, whichLLMProbePath())
	output, err := command.Output()
	if ctx.Err() != nil {
		return HardwareProfile{}, fmt.Errorf("whichllm hardware probe timed out")
	}
	if err != nil {
		return HardwareProfile{}, fmt.Errorf("whichllm hardware probe: %w", err)
	}

	var result whichLLMProbeResult
	if err := json.Unmarshal(output, &result); err != nil {
		return HardwareProfile{}, fmt.Errorf("invalid whichllm hardware JSON: %w", err)
	}
	if strings.TrimSpace(result.Error) != "" {
		return HardwareProfile{}, fmt.Errorf("whichllm hardware probe failed: %s", result.Error)
	}
	if result.RAMBytes <= 0 {
		return HardwareProfile{}, fmt.Errorf("whichllm did not report RAM")
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
		DetectionSource: "whichllm",
		GPUs:            make([]DetectedGPU, 0, len(result.GPUs)),
	}
	for _, gpu := range result.GPUs {
		available := gpu.VRAMBytes
		if gpu.UsableVRAMBytes != nil && *gpu.UsableVRAMBytes > 0 {
			available = *gpu.UsableVRAMBytes
		}
		entry := DetectedGPU{
			Name:                normalizeWhichLLMGPUName(gpu.Vendor, gpu.Name),
			Vendor:              strings.TrimSpace(gpu.Vendor),
			VRAMGB:              bytesToGiB(available),
			SharedMemory:        gpu.SharedMemory,
			MemoryBandwidthGBPS: derefFloat(gpu.MemoryBandwidthGBPS),
		}
		if len(gpu.ComputeCapability) == 2 {
			entry.ComputeCapability = fmt.Sprintf("%d.%d", gpu.ComputeCapability[0], gpu.ComputeCapability[1])
		}
		profile.GPUs = append(profile.GPUs, entry)
		// Integrated GPUs may correctly report no dedicated VRAM. They are
		// still useful to show to the user and to classify the machine.
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

// whichllm correctly reports the vendor, VRAM and driver capabilities from
// sysfs. Some very new Linux PCI IDs are still printed by lspci as
// "Device 7550" though. Enrich only that unambiguous device-ID form; never
// replace a real driver-provided model name with a guess.
func normalizeWhichLLMGPUName(vendor, name string) string {
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

func whichLLMPythonExecutable() (string, error) {
	if configured := strings.TrimSpace(os.Getenv("WHICHLLM_PYTHON")); configured != "" {
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
	return "", fmt.Errorf("whichllm Python interpreter not found")
}

func whichLLMProbePath() string {
	if configured := strings.TrimSpace(os.Getenv("WHICHLLM_PROBE_PATH")); configured != "" {
		return configured
	}
	return filepath.Join("tools", "whichllm_hardware_probe.py")
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
