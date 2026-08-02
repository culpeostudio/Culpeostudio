package marktplatz

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	enginehardware "github.com/fillyengine/backend/internal/hardware"
)

type HardwareProfile struct {
	OS                     string        `json:"os"`
	Arch                   string        `json:"arch"`
	RAMGB                  int           `json:"ram_gb"`
	VRAMGB                 int           `json:"vram_gb"`
	HasGPU                 bool          `json:"has_gpu"`
	GPUName                string        `json:"gpu_name,omitempty"`
	GPUVendor              string        `json:"gpu_vendor,omitempty"`
	GPUMemoryBandwidthGBPS float64       `json:"gpu_memory_bandwidth_gbps,omitempty"`
	GPUs                   []DetectedGPU `json:"gpus,omitempty"`
	CPUName                string        `json:"cpu_name,omitempty"`
	CPUCores               int           `json:"cpu_cores,omitempty"`
	HasAVX2                bool          `json:"has_avx2,omitempty"`
	HasAVX512              bool          `json:"has_avx512,omitempty"`

	DiskFree string `json:"disk_free,omitempty"`

	DiskFreeBytes   int64  `json:"disk_free_bytes,omitempty"`
	Detected        bool   `json:"detected"`
	DetectionSource string `json:"detection_source,omitempty"`

	RAMTotalBytes     int64                `json:"ram_total_bytes,omitempty"`
	RAMAvailableBytes int64                `json:"ram_available_bytes,omitempty"`
	CapturedAt        time.Time            `json:"captured_at,omitempty"`
	EngineGPUs        []enginehardware.GPU `json:"engine_gpus,omitempty"`
}

type DetectedGPU struct {
	ID                  string  `json:"id,omitempty"`
	Index               int     `json:"index,omitempty"`
	Name                string  `json:"name"`
	Vendor              string  `json:"vendor"`
	Backend             string  `json:"backend,omitempty"`
	VRAMGB              int     `json:"vram_gb"`
	VRAMTotalBytes      int64   `json:"vram_total_bytes,omitempty"`
	VRAMUsedBytes       int64   `json:"vram_used_bytes,omitempty"`
	VRAMFreeBytes       int64   `json:"vram_free_bytes,omitempty"`
	SharedMemory        bool    `json:"shared_memory,omitempty"`
	MemoryBandwidthGBPS float64 `json:"memory_bandwidth_gbps,omitempty"`
	ComputeCapability   string  `json:"compute_capability,omitempty"`
}

var hardwareProfileCache struct {
	mu        sync.Mutex
	profile   HardwareProfile
	expiresAt time.Time
}

const hardwareProfileTTL = 45 * time.Second

func detectHardwareProfile() HardwareProfile {
	hardwareProfileCache.mu.Lock()
	defer hardwareProfileCache.mu.Unlock()

	now := time.Now()
	if !hardwareProfileCache.expiresAt.IsZero() && now.Before(hardwareProfileCache.expiresAt) {
		return hardwareProfileCache.profile
	}

	profile := detectHardwareProfileFresh()
	hardwareProfileCache.profile = profile
	hardwareProfileCache.expiresAt = now.Add(hardwareProfileTTL)
	return profile
}

func CurrentHardwareProfile() HardwareProfile { return detectHardwareProfile() }

func detectHardwareProfileFresh() HardwareProfile {

	profile, philoEngineErr := detectHardwareProfileWithPhiloEngine()
	if philoEngineErr != nil {
		profile = HardwareProfile{}
	}
	snapshot := enginehardware.Detect(context.Background(), ".")
	if snapshot.RAMTotalBytes > 0 {
		profile.OS = snapshot.OS
		profile.Arch = snapshot.Arch
		profile.CPUName = firstNonEmpty(profile.CPUName, snapshot.CPUName)
		if profile.CPUCores == 0 {
			profile.CPUCores = snapshot.CPUCores
		}
		profile.RAMGB = bytesToGiB(snapshot.RAMTotalBytes)
		profile.RAMTotalBytes = snapshot.RAMTotalBytes
		profile.RAMAvailableBytes = snapshot.RAMAvailableBytes
		profile.DiskFreeBytes = snapshot.DiskFreeBytes
		profile.DiskFree = formatBytesAsGB(snapshot.DiskFreeBytes)
		profile.CapturedAt = snapshot.CapturedAt
		profile.EngineGPUs = snapshot.GPUs
		profile.Detected = true
		if philoEngineErr == nil {
			profile.DetectionSource = "philoengine_hardware+native_live"
		} else {
			profile.DetectionSource = "native_live"
		}
		if len(snapshot.GPUs) > 0 {
			profile.GPUs = make([]DetectedGPU, 0, len(snapshot.GPUs))
			profile.VRAMGB = 0
			for _, gpu := range snapshot.GPUs {
				entry := DetectedGPU{
					ID: gpu.ID, Index: gpu.Index, Name: gpu.Name, Vendor: gpu.Vendor,
					Backend: gpu.Backend, VRAMGB: bytesToGiB(gpu.VRAMTotalBytes),
					VRAMTotalBytes: gpu.VRAMTotalBytes, VRAMUsedBytes: gpu.VRAMUsedBytes,
					VRAMFreeBytes: gpu.VRAMFreeBytes, SharedMemory: gpu.SharedMemory,
					MemoryBandwidthGBPS: gpu.MemoryBandwidth, ComputeCapability: gpu.ComputeCapability,
				}
				profile.GPUs = append(profile.GPUs, entry)
				if profile.GPUName == "" || entry.VRAMGB >= profile.VRAMGB {
					profile.VRAMGB = entry.VRAMGB
					profile.GPUName = entry.Name
					profile.GPUVendor = entry.Vendor
				}
			}
			profile.HasGPU = true
		}
		return profile
	}

	ramBytes := detectTotalRAMBytes()
	gpuName, vramMB := detectGPUInfo()
	diskFree := detectDiskFree()
	diskFreeBytes := detectDiskFreeBytes()

	profile = HardwareProfile{
		OS:              runtime.GOOS,
		Arch:            runtime.GOARCH,
		Detected:        true,
		DetectionSource: "go_fallback",
		DiskFree:        diskFree,
		DiskFreeBytes:   diskFreeBytes,
	}

	if ramBytes > 0 {
		profile.RAMGB = bytesToGiB(ramBytes)
	} else {
		profile.Detected = false
	}

	if vramMB > 0 {
		profile.VRAMGB = int((vramMB + 1023) / 1024)
	}

	profile.GPUName = strings.TrimSpace(gpuName)
	profile.GPUVendor = inferGPUVendor(profile.GPUName)
	profile.HasGPU = profile.GPUName != "" || profile.VRAMGB > 0
	if profile.HasGPU {
		profile.GPUs = []DetectedGPU{{
			Name:   profile.GPUName,
			Vendor: profile.GPUVendor,
			VRAMGB: profile.VRAMGB,
		}}
	}
	return profile
}

func detectTotalRAMBytes() int64 {
	switch runtime.GOOS {
	case "windows":
		if out, err := runCommand(2*time.Second, "wmic", "computersystem", "get", "TotalPhysicalMemory", "/value"); err == nil {
			if value := parseKeyValueInt64(out, "TotalPhysicalMemory"); value > 0 {
				return value
			}
		}
		if out, err := runCommand(2*time.Second, "powershell", "-NoProfile", "-Command", "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory"); err == nil {
			if value := parseFirstInt64(out); value > 0 {
				return value
			}
		}
	case "linux":
		data, err := os.ReadFile("/proc/meminfo")
		if err == nil {
			scanner := bufio.NewScanner(bytes.NewReader(data))
			for scanner.Scan() {
				line := strings.TrimSpace(scanner.Text())
				if strings.HasPrefix(line, "MemTotal:") {
					parts := strings.Fields(line)
					if len(parts) >= 2 {
						if kb, parseErr := strconv.ParseInt(strings.TrimSpace(parts[1]), 10, 64); parseErr == nil && kb > 0 {
							return kb * 1024
						}
					}
				}
			}
		}
	case "darwin":
		if out, err := runCommand(2*time.Second, "sysctl", "-n", "hw.memsize"); err == nil {
			if value := parseFirstInt64(out); value > 0 {
				return value
			}
		}
	}
	return 0
}

func detectGPUInfo() (string, int64) {
	name, vramMB := detectNvidiaGPU()
	if strings.TrimSpace(name) != "" || vramMB > 0 {
		return name, vramMB
	}

	switch runtime.GOOS {
	case "windows":
		return detectWindowsGPU()
	case "linux":
		return detectLinuxGPU()
	case "darwin":
		return detectMacGPU()
	default:
		return "", 0
	}
}

func detectNvidiaGPU() (string, int64) {
	out, err := runCommand(
		2*time.Second,
		"nvidia-smi",
		"--query-gpu=name,memory.total",
		"--format=csv,noheader,nounits",
	)
	if err != nil || strings.TrimSpace(out) == "" {
		return "", 0
	}

	var selectedName string
	var selectedVRAM int64
	lines := strings.Split(strings.TrimSpace(out), "\n")
	for _, line := range lines {
		parts := strings.Split(line, ",")
		if len(parts) < 2 {
			continue
		}
		name := strings.TrimSpace(parts[0])
		mem := parseFirstInt64(parts[1])
		if mem > selectedVRAM {
			selectedVRAM = mem
			selectedName = name
		}
	}
	return selectedName, selectedVRAM
}

func detectWindowsGPU() (string, int64) {
	name, vramMB := detectWindowsGPURegistry()
	if strings.TrimSpace(name) != "" || vramMB > 0 {
		return name, vramMB
	}

	name, vramMB = detectWindowsGPUDxdiag()
	if strings.TrimSpace(name) != "" || vramMB > 0 {
		return name, vramMB
	}

	out, err := runCommand(
		3*time.Second,
		"powershell",
		"-NoProfile",
		"-Command",
		`Get-CimInstance Win32_VideoController | ForEach-Object { "{0}|{1}" -f $_.AdapterRAM, $_.Name }`,
	)
	if err != nil || strings.TrimSpace(out) == "" {
		return detectWindowsGPUWMIC()
	}

	lines := strings.Split(strings.TrimSpace(out), "\n")
	for _, line := range lines {
		parts := strings.SplitN(strings.TrimSpace(line), "|", 2)
		if len(parts) != 2 {
			continue
		}
		ramBytes := parseFirstInt64(parts[0])
		name := strings.TrimSpace(parts[1])
		if ramBytes > 0 || name != "" {
			return name, ramBytes / (1024 * 1024)
		}
	}
	return detectWindowsGPUWMIC()
}

func detectWindowsGPURegistry() (string, int64) {
	out, err := runCommand(
		3*time.Second,
		"powershell",
		"-NoProfile",
		"-Command",
		`Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Video\*\0000' -ErrorAction SilentlyContinue | ForEach-Object { "{0}|{1}|{2}" -f $_.DriverDesc, $_.'HardwareInformation.qwMemorySize', $_.'HardwareInformation.MemorySize' }`,
	)
	if err != nil || strings.TrimSpace(out) == "" {
		return "", 0
	}

	var bestName string
	var bestVRAMBytes int64
	lines := strings.Split(strings.TrimSpace(out), "\n")
	for _, line := range lines {
		parts := strings.SplitN(strings.TrimSpace(line), "|", 3)
		if len(parts) != 3 {
			continue
		}
		name := strings.TrimSpace(parts[0])
		vramBytes := parseFirstInt64(parts[1])
		if vramBytes <= 0 {
			vramBytes = parseFirstInt64(parts[2])
		}
		if vramBytes > bestVRAMBytes {
			bestVRAMBytes = vramBytes
			bestName = name
		}
	}

	if bestVRAMBytes <= 0 {
		return strings.TrimSpace(bestName), 0
	}
	return strings.TrimSpace(bestName), bestVRAMBytes / (1024 * 1024)
}

func detectWindowsGPUWMIC() (string, int64) {
	out, err := runCommand(2*time.Second, "wmic", "path", "win32_VideoController", "get", "Name,AdapterRAM", "/format:csv")
	if err != nil || strings.TrimSpace(out) == "" {
		return "", 0
	}

	var bestName string
	var bestRAMBytes int64
	lines := strings.Split(strings.TrimSpace(out), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(strings.ToLower(trimmed), "node,") {
			continue
		}
		parts := strings.Split(trimmed, ",")
		if len(parts) < 3 {
			continue
		}
		ram := parseFirstInt64(parts[1])
		name := strings.TrimSpace(parts[2])
		if ram > bestRAMBytes {
			bestRAMBytes = ram
			bestName = name
		}
	}
	if bestRAMBytes <= 0 {
		return strings.TrimSpace(bestName), 0
	}
	return strings.TrimSpace(bestName), bestRAMBytes / (1024 * 1024)
}

func detectWindowsGPUDxdiag() (string, int64) {
	tmpDir, err := os.MkdirTemp("", "marktplatz-dxdiag-*")
	if err != nil {
		return "", 0
	}
	defer os.RemoveAll(tmpDir)

	reportPath := filepath.Join(tmpDir, "dxdiag.txt")
	_, err = runCommand(12*time.Second, "dxdiag", "/whql:off", "/t", reportPath)
	if err != nil {
		return "", 0
	}

	raw, err := waitForFileContent(reportPath, 2*time.Second)
	if err != nil {
		return "", 0
	}
	return parseDxdiagDisplayDevice(raw)
}

func detectLinuxGPU() (string, int64) {
	if name, vramMB := detectLinuxGPUFromSysfs("/sys/class/drm"); name != "" || vramMB > 0 {
		return name, vramMB
	}

	out, err := runCommand(2*time.Second, "lspci")
	if err != nil || strings.TrimSpace(out) == "" {
		return "", 0
	}
	lines := strings.Split(strings.TrimSpace(out), "\n")
	for _, line := range lines {
		lower := strings.ToLower(line)
		if strings.Contains(lower, "vga") || strings.Contains(lower, "3d controller") {
			return strings.TrimSpace(line), 0
		}
	}
	return "", 0
}

func detectLinuxGPUFromSysfs(drmPath string) (string, int64) {
	cards, err := filepath.Glob(filepath.Join(drmPath, "card[0-9]*"))
	if err != nil {
		return "", 0
	}

	var bestName string
	var bestVRAMMB int64
	for _, card := range cards {
		base := filepath.Base(card)
		if !isDRMCardName(base) {
			continue
		}
		devicePath := filepath.Join(card, "device")
		vendor := strings.ToLower(strings.TrimSpace(readTextFile(filepath.Join(devicePath, "vendor"))))
		if vendor != "0x1002" && vendor != "0x10de" && vendor != "0x8086" {
			continue
		}
		deviceID := strings.ToLower(strings.TrimSpace(readTextFile(filepath.Join(devicePath, "device"))))
		vramBytes := readIntFile(filepath.Join(devicePath, "mem_info_vram_total"))
		name := linuxGPUName(vendor, deviceID)
		if name == "" {
			name = "Linux GPU " + strings.TrimPrefix(deviceID, "0x")
		}
		vramMB := vramBytes / (1024 * 1024)
		if bestName == "" || vramMB > bestVRAMMB {
			bestName, bestVRAMMB = name, vramMB
		}
	}
	return bestName, bestVRAMMB
}

func isDRMCardName(name string) bool {
	if !strings.HasPrefix(name, "card") || len(name) == len("card") {
		return false
	}
	_, err := strconv.Atoi(name[len("card"):])
	return err == nil
}

func readTextFile(path string) string {
	contents, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	return string(contents)
}

func readIntFile(path string) int64 {
	value, err := strconv.ParseInt(strings.TrimSpace(readTextFile(path)), 0, 64)
	if err != nil || value < 0 {
		return 0
	}
	return value
}

func linuxGPUName(vendor, deviceID string) string {

	switch vendor {
	case "0x1002":
		switch deviceID {
		case "0x7550":
			return "AMD Radeon RX 9070 XT"
		}
		return "AMD GPU " + strings.TrimPrefix(deviceID, "0x")
	case "0x10de":
		return "NVIDIA GPU " + strings.TrimPrefix(deviceID, "0x")
	case "0x8086":
		return "Intel GPU " + strings.TrimPrefix(deviceID, "0x")
	default:
		return ""
	}
}

func detectMacGPU() (string, int64) {
	out, err := runCommand(2*time.Second, "system_profiler", "SPDisplaysDataType")
	if err != nil || strings.TrimSpace(out) == "" {
		return "", 0
	}
	lines := strings.Split(strings.TrimSpace(out), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(strings.ToLower(trimmed), "chipset model:") {
			name := strings.TrimSpace(strings.TrimPrefix(trimmed, "Chipset Model:"))
			return name, 0
		}
	}
	return "", 0
}

func waitForFileContent(path string, timeout time.Duration) (string, error) {
	deadline := time.Now().Add(timeout)
	for {
		raw, err := os.ReadFile(path)
		if err == nil && len(raw) > 0 {
			return string(raw), nil
		}
		if time.Now().After(deadline) {
			return "", err
		}
		time.Sleep(150 * time.Millisecond)
	}
}

func parseDxdiagDisplayDevice(raw string) (string, int64) {
	lines := strings.Split(strings.ReplaceAll(raw, "\r\n", "\n"), "\n")
	var currentName string
	var currentDedicatedMB int64
	var currentDisplayMB int64
	var bestName string
	var bestVRAMMB int64

	flush := func() {
		candidate := currentDedicatedMB
		if candidate <= 0 {
			candidate = currentDisplayMB
		}
		if candidate > bestVRAMMB {
			bestVRAMMB = candidate
			bestName = strings.TrimSpace(currentName)
		}
	}

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		lower := strings.ToLower(trimmed)
		switch {
		case strings.HasPrefix(lower, "card name:"):
			if currentName != "" {
				flush()
			}
			currentName = strings.TrimSpace(trimmed[len("Card name:"):])
			currentDedicatedMB = 0
			currentDisplayMB = 0
		case strings.HasPrefix(lower, "dedicated memory:"):
			currentDedicatedMB = parseFirstInt64(trimmed)
		case strings.HasPrefix(lower, "display memory:"):
			currentDisplayMB = parseFirstInt64(trimmed)
		}
	}
	if currentName != "" {
		flush()
	}

	return bestName, bestVRAMMB
}

func runCommand(timeout time.Duration, name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, name, args...)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	if err := cmd.Run(); err != nil {
		return strings.TrimSpace(out.String()), err
	}
	return strings.TrimSpace(out.String()), nil
}

func parseKeyValueInt64(raw string, key string) int64 {
	lines := strings.Split(raw, "\n")
	for _, line := range lines {
		parts := strings.SplitN(strings.TrimSpace(line), "=", 2)
		if len(parts) != 2 {
			continue
		}
		if strings.EqualFold(strings.TrimSpace(parts[0]), strings.TrimSpace(key)) {
			value, err := strconv.ParseInt(strings.TrimSpace(parts[1]), 10, 64)
			if err == nil {
				return value
			}
		}
	}
	return 0
}

func parseFirstInt64(raw string) int64 {
	clean := strings.TrimSpace(raw)
	if clean == "" {
		return 0
	}
	fields := strings.Fields(clean)
	for _, field := range fields {
		onlyDigits := strings.Map(func(r rune) rune {
			if r >= '0' && r <= '9' {
				return r
			}
			return -1
		}, field)
		if onlyDigits == "" {
			continue
		}
		value, err := strconv.ParseInt(onlyDigits, 10, 64)
		if err == nil {
			return value
		}
	}
	return 0
}

func bytesToGiB(bytes int64) int {
	if bytes <= 0 {
		return 0
	}
	const gib = int64(1024 * 1024 * 1024)
	return int((bytes + gib - 1) / gib)
}

func detectDiskFree() string {
	cwd, err := os.Getwd()
	if err != nil {
		cwd = "."
	}

	switch runtime.GOOS {
	case "windows":
		drive := "C:"
		if len(cwd) >= 2 && cwd[1] == ':' {
			drive = string(cwd[0:2])
		}
		cmdText := fmt.Sprintf("[Math]::Round((Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID=''%s''').FreeSpace / 1GB, 1)", drive)
		if out, err := runCommand(2*time.Second, "powershell", "-NoProfile", "-Command", cmdText); err == nil {
			val := strings.TrimSpace(out)
			if val != "" {

				val = strings.ReplaceAll(val, ",", ".")
				return val + " GB"
			}
		}
	case "linux", "darwin":
		if out, err := runCommand(2*time.Second, "df", "-h", cwd); err == nil {
			lines := strings.Split(strings.TrimSpace(out), "\n")
			if len(lines) >= 2 {
				fields := strings.Fields(lines[1])
				if len(fields) >= 4 {
					return fields[3]
				}
			}
		}
	}
	return "N/A"
}

func detectDiskFreeBytes() int64 {
	cwd, err := os.Getwd()
	if err != nil {
		cwd = "."
	}

	switch runtime.GOOS {
	case "windows":
		drive := "C:"
		if len(cwd) >= 2 && cwd[1] == ':' {
			drive = string(cwd[0:2])
		}

		cmdText := fmt.Sprintf("(Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID=''%s''').FreeSpace", drive)
		out, err := runCommand(2*time.Second, "powershell", "-NoProfile", "-Command", cmdText)
		if err != nil {
			return 0
		}

		val := strings.ReplaceAll(strings.TrimSpace(out), ",", ".")

		if val == "" {
			return 0
		}
		if n, err := strconv.ParseInt(val, 10, 64); err == nil && n > 0 {
			return n
		}
		if f, err := strconv.ParseFloat(val, 64); err == nil && f > 0 {
			return int64(f)
		}
		return 0
	case "linux", "darwin":

		out, err := runCommand(2*time.Second, "df", "-k", cwd)
		if err != nil {
			return 0
		}
		lines := strings.Split(strings.TrimSpace(out), "\n")
		if len(lines) < 2 {
			return 0
		}
		fields := strings.Fields(lines[1])

		if len(fields) < 4 {
			return 0
		}
		if n, err := strconv.ParseInt(fields[3], 10, 64); err == nil && n > 0 {
			return n * 1024
		}
		return 0
	default:
		return 0
	}
}
