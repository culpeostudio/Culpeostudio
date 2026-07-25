// Package hardware provides byte-accurate, live hardware snapshots for the
// engine scheduler.  Marketplace keeps its user-facing compatibility model,
// while this package is deliberately independent from HTTP and module code.
package hardware

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"
)

const commandTimeout = 3 * time.Second

// GPU describes one addressable accelerator. All memory values are bytes.
type GPU struct {
	ID             string `json:"id"`
	Index          int    `json:"index"`
	Name           string `json:"name"`
	Vendor         string `json:"vendor"`
	Backend        string `json:"backend,omitempty"`
	VRAMTotalBytes int64  `json:"vram_total_bytes"`
	VRAMUsedBytes  int64  `json:"vram_used_bytes"`
	VRAMFreeBytes  int64  `json:"vram_free_bytes"`
	// VRAMTelemetryUnavailable distinguishes a known inventory-only device
	// from a pressure probe which measured zero free bytes. Such a device is
	// unschedulable for GPU work but must not cause destructive host eviction.
	VRAMTelemetryUnavailable bool    `json:"vram_telemetry_unavailable,omitempty"`
	SharedMemory             bool    `json:"shared_memory,omitempty"`
	ComputeCapability        string  `json:"compute_capability,omitempty"`
	DriverVersion            string  `json:"driver_version,omitempty"`
	MemoryBandwidth          float64 `json:"memory_bandwidth_gbps,omitempty"`
}

// Snapshot is a point-in-time view. It must be refreshed for every scheduling
// transaction; callers must not treat it as a long-lived inventory cache.
type Snapshot struct {
	OS                     string    `json:"os"`
	Arch                   string    `json:"arch"`
	CPUName                string    `json:"cpu_name,omitempty"`
	CPUCores               int       `json:"cpu_cores"`
	RAMTotalBytes          int64     `json:"ram_total_bytes"`
	RAMAvailableBytes      int64     `json:"ram_available_bytes"`
	DiskFreeBytes          int64     `json:"disk_free_bytes,omitempty"`
	GPUs                   []GPU     `json:"gpus"`
	GPUTelemetryIncomplete bool      `json:"gpu_telemetry_incomplete,omitempty"`
	CapturedAt             time.Time `json:"captured_at"`
	Source                 string    `json:"source"`
}

// Detect obtains a live snapshot. modelDir determines the filesystem whose
// free space is reported, avoiding the old CWD-volume mismatch.
func Detect(ctx context.Context, modelDir string) Snapshot {
	s := Snapshot{
		OS:         runtime.GOOS,
		Arch:       runtime.GOARCH,
		CPUCores:   runtime.NumCPU(),
		CapturedAt: time.Now().UTC(),
		Source:     "native",
		GPUs:       []GPU{},
	}
	s.CPUName = detectCPUName(ctx)
	s.RAMTotalBytes, s.RAMAvailableBytes = detectMemory(ctx)
	s.GPUs = detectGPUs(ctx)
	s.DiskFreeBytes = detectDiskFree(ctx, modelDir)
	return s
}

// DetectPressure is the bounded watchdog probe. Unlike the full inventory it
// deliberately skips CPU identity and disk commands, and obtains RAM/native
// pressure plus live VRAM counters concurrently under the caller's deadline.
// A timed-out field stays zero/unknown so admission remains fail-closed.
func DetectPressure(ctx context.Context) Snapshot {
	return capturePressureSnapshot(ctx, detectMemory, detectGPUs)
}

type pressureMemoryProbe func(context.Context) (int64, int64)
type pressureGPUProbe func(context.Context) []GPU

func capturePressureSnapshot(ctx context.Context, memoryProbe pressureMemoryProbe, gpuProbe pressureGPUProbe) Snapshot {
	snapshot := Snapshot{
		OS:       runtime.GOOS,
		Arch:     runtime.GOARCH,
		CPUCores: runtime.NumCPU(),
		Source:   "native-pressure",
		GPUs:     []GPU{},
	}
	if ctx == nil || ctx.Err() != nil {
		snapshot.CapturedAt = time.Now().UTC()
		return snapshot
	}
	type memoryResult struct {
		total     int64
		available int64
	}
	memoryResults := make(chan memoryResult, 1)
	gpuResults := make(chan []GPU, 1)
	go func() {
		total, available := memoryProbe(ctx)
		memoryResults <- memoryResult{total: total, available: available}
	}()
	go func() { gpuResults <- gpuProbe(ctx) }()

	// Both native probes are required to observe the shared context. Waiting for
	// them after cancellation ensures a timed-out sample cannot leave detached
	// probe goroutines behind while the watchdog schedules its next refresh.
	for completed := 0; completed < 2; completed++ {
		select {
		case memory := <-memoryResults:
			snapshot.RAMTotalBytes = memory.total
			snapshot.RAMAvailableBytes = memory.available
		case gpus := <-gpuResults:
			if gpus != nil {
				snapshot.GPUs = gpus
			}
		}
	}
	snapshot.CapturedAt = time.Now().UTC()
	return snapshot
}

// SchedulableRAM applies the engine's default physical-memory reserve. Swap
// is intentionally excluded from Snapshot and therefore from this result.
func (s Snapshot) SchedulableRAM() int64 {
	// A missing total or availability measurement is not evidence that memory
	// is free. Keep scheduling fail-closed until the native probe succeeds.
	if s.RAMTotalBytes <= 0 || s.RAMAvailableBytes <= 0 {
		return 0
	}
	reserve := s.RAMTotalBytes * 15 / 100
	if reserve < 4<<30 {
		reserve = 4 << 30
	}
	limit := s.RAMTotalBytes - reserve
	if limit < 0 {
		return 0
	}
	if s.RAMAvailableBytes > 0 && s.RAMAvailableBytes < limit {
		return s.RAMAvailableBytes
	}
	return limit
}

// SchedulableVRAM applies the engine's default per-device reserve.
func (g GPU) SchedulableVRAM() int64 {
	if g.SharedMemory || g.VRAMTotalBytes <= 0 || g.VRAMFreeBytes <= 0 {
		return 0
	}
	reserve := g.VRAMTotalBytes / 10
	if reserve < 512<<20 {
		reserve = 512 << 20
	}
	limit := g.VRAMTotalBytes - reserve
	if limit < 0 {
		return 0
	}
	if g.VRAMFreeBytes > 0 && g.VRAMFreeBytes < limit {
		return g.VRAMFreeBytes
	}
	return limit
}

func detectMemory(ctx context.Context) (int64, int64) {
	switch runtime.GOOS {
	case "linux":
		data, err := os.ReadFile("/proc/meminfo")
		if err != nil {
			return 0, 0
		}
		return parseProcMeminfo(data)
	case "darwin":
		total := parseInt64(run(ctx, "sysctl", "-n", "hw.memsize"))
		// memory_pressure is backed by Darwin's native memory-pressure accounting
		// and reflects reclaimable memory better than treating all physical RAM as
		// available. If that utility is unavailable, vm_stat still gives a safe
		// free+inactive+speculative approximation. Unknown availability stays zero
		// so the Engine pressure guard fails closed instead of admitting a start
		// from a fabricated all-free snapshot.
		if percent, ok := parseDarwinMemoryPressure(run(ctx, "memory_pressure", "-Q")); ok {
			return darwinMemoryMeasurement(total, total*int64(percent)/100, true)
		}
		if available, ok := parseDarwinVMStatAvailable(run(ctx, "vm_stat")); ok {
			return darwinMemoryMeasurement(total, available, true)
		}
		// Preserve the distinction between a successfully measured zero (which
		// is Emergency) and missing telemetry (which is Warning/fail-closed).
		return darwinMemoryMeasurement(total, 0, false)
	case "windows":
		// GlobalMemoryStatusEx is a constant-time native syscall. PowerShell/CIM
		// regularly exceeds the watchdog deadline and used to turn every Windows
		// sample into an artificial unknown-pressure warning.
		return detectWindowsMemory(ctx)
	}
	return 0, 0
}

func darwinMemoryMeasurement(total, available int64, measured bool) (int64, int64) {
	if !measured || total <= 0 || available < 0 {
		return 0, 0
	}
	if available > total {
		available = total
	}
	return total, available
}

func parseDarwinMemoryPressure(output string) (int, bool) {
	for _, line := range strings.Split(output, "\n") {
		lower := strings.ToLower(line)
		if !strings.Contains(lower, "memory free percentage") {
			continue
		}
		_, value, found := strings.Cut(line, ":")
		if !found {
			continue
		}
		percent, err := strconv.Atoi(strings.TrimSpace(strings.TrimSuffix(strings.TrimSpace(value), "%")))
		if err == nil && percent >= 0 && percent <= 100 {
			return percent, true
		}
	}
	return 0, false
}

func parseDarwinVMStatAvailable(output string) (int64, bool) {
	pageSize := int64(0)
	availablePages := int64(0)
	foundPages := false
	for _, line := range strings.Split(output, "\n") {
		lower := strings.ToLower(strings.TrimSpace(line))
		if pageSize == 0 && strings.Contains(lower, "page size of") {
			fields := strings.Fields(lower)
			for index, field := range fields {
				if field == "of" && index+1 < len(fields) {
					pageSize, _ = strconv.ParseInt(strings.Trim(fields[index+1], "()."), 10, 64)
					break
				}
			}
			continue
		}
		counted := strings.HasPrefix(lower, "pages free:") ||
			strings.HasPrefix(lower, "pages inactive:") ||
			strings.HasPrefix(lower, "pages speculative:")
		if !counted {
			continue
		}
		_, value, ok := strings.Cut(lower, ":")
		if !ok {
			continue
		}
		pages, err := strconv.ParseInt(strings.Trim(strings.TrimSpace(value), "."), 10, 64)
		if err == nil && pages >= 0 {
			availablePages += pages
			foundPages = true
		}
	}
	if pageSize <= 0 || !foundPages || availablePages > int64(^uint64(0)>>1)/pageSize {
		return 0, false
	}
	return availablePages * pageSize, true
}

func parseProcMeminfo(data []byte) (total int64, available int64) {
	scanner := bufio.NewScanner(bytes.NewReader(data))
	for scanner.Scan() {
		parts := strings.Fields(scanner.Text())
		if len(parts) < 2 {
			continue
		}
		value, err := strconv.ParseInt(parts[1], 10, 64)
		if err != nil {
			continue
		}
		switch strings.TrimSuffix(parts[0], ":") {
		case "MemTotal":
			total = value * 1024
		case "MemAvailable":
			available = value * 1024
		}
	}
	return total, available
}

func detectCPUName(ctx context.Context) string {
	switch runtime.GOOS {
	case "linux":
		data, _ := os.ReadFile("/proc/cpuinfo")
		scanner := bufio.NewScanner(bytes.NewReader(data))
		for scanner.Scan() {
			line := scanner.Text()
			if key, value, ok := strings.Cut(line, ":"); ok && strings.TrimSpace(key) == "model name" {
				return strings.TrimSpace(value)
			}
		}
	case "darwin":
		return strings.TrimSpace(run(ctx, "sysctl", "-n", "machdep.cpu.brand_string"))
	case "windows":
		return strings.TrimSpace(run(ctx, "powershell", "-NoProfile", "-Command", `(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)`))
	}
	return ""
}

func detectGPUs(ctx context.Context) []GPU {
	nvidia := detectNvidia(ctx)
	if ctx.Err() != nil {
		return nvidia
	}
	switch runtime.GOOS {
	case "linux":
		return mergeGPUInventories(nvidia, detectLinuxDRM(ctx, "/sys/class/drm"), len(nvidia) > 0)
	case "windows":
		return mergeGPUInventories(nvidia, detectWindowsGPUs(ctx), len(nvidia) > 0)
	case "darwin":
		name := strings.TrimSpace(run(ctx, "system_profiler", "SPDisplaysDataType"))
		if name != "" {
			return []GPU{{ID: "metal:0", Index: 0, Name: firstDisplayName(name), Vendor: "apple", Backend: "metal", SharedMemory: true}}
		}
	}
	return nvidia
}

// mergeGPUInventories keeps accelerators from mixed-vendor systems visible.
// nvidia-smi provides better live counters and stable UUIDs than DRM/CIM, so
// secondary NVIDIA records are omitted only when that primary probe worked.
func mergeGPUInventories(primary, secondary []GPU, skipSecondaryNVIDIA bool) []GPU {
	result := append([]GPU(nil), primary...)
	seen := make(map[string]struct{}, len(primary)+len(secondary))
	for _, gpu := range primary {
		seen[gpu.ID] = struct{}{}
	}
	for _, gpu := range secondary {
		if skipSecondaryNVIDIA && strings.EqualFold(gpu.Vendor, "nvidia") {
			continue
		}
		if _, duplicate := seen[gpu.ID]; duplicate {
			continue
		}
		seen[gpu.ID] = struct{}{}
		result = append(result, gpu)
	}
	sort.SliceStable(result, func(i, j int) bool {
		if result[i].Backend != result[j].Backend {
			return result[i].Backend < result[j].Backend
		}
		return result[i].ID < result[j].ID
	})
	return result
}

func detectNvidia(ctx context.Context) []GPU {
	out := run(ctx, "nvidia-smi", "--query-gpu=index,uuid,name,memory.total,memory.used,memory.free,compute_cap,driver_version", "--format=csv,noheader,nounits")
	if out == "" {
		return nil
	}
	var result []GPU
	for _, line := range strings.Split(strings.TrimSpace(out), "\n") {
		parts := strings.Split(line, ",")
		if len(parts) < 8 {
			continue
		}
		index, _ := strconv.Atoi(strings.TrimSpace(parts[0]))
		total := parseInt64(parts[3]) << 20
		used := parseInt64(parts[4]) << 20
		free := parseInt64(parts[5]) << 20
		result = append(result, GPU{
			ID:                strings.TrimSpace(parts[1]),
			Index:             index,
			Name:              strings.TrimSpace(parts[2]),
			Vendor:            "nvidia",
			Backend:           "cuda",
			VRAMTotalBytes:    total,
			VRAMUsedBytes:     used,
			VRAMFreeBytes:     free,
			ComputeCapability: strings.TrimSpace(parts[6]),
			DriverVersion:     strings.TrimSpace(parts[7]),
		})
	}
	return result
}

func detectLinuxDRM(ctx context.Context, root string) []GPU {
	entries, _ := filepath.Glob(filepath.Join(root, "card[0-9]*"))
	var result []GPU
	for _, card := range entries {
		deviceDir := filepath.Join(card, "device")
		info, err := os.Stat(deviceDir)
		if err != nil || !info.IsDir() {
			continue
		}
		vendorID := readTrim(filepath.Join(deviceDir, "vendor"))
		deviceID := readTrim(filepath.Join(deviceDir, "device"))
		vendor := vendorFromPCI(vendorID)
		if vendor == "unknown" {
			continue
		}
		total := readInt64(filepath.Join(deviceDir, "mem_info_vram_total"))
		used := readInt64(filepath.Join(deviceDir, "mem_info_vram_used"))
		free := total - used
		if free < 0 {
			free = 0
		}
		name := linuxGPUName(vendorID, deviceID)
		pciID := filepath.Base(resolvedPath(deviceDir))
		if name == "" && pciID != "" && pciID != "device" {
			if line := strings.TrimSpace(run(ctx, "lspci", "-s", pciID)); line != "" {
				if _, desc, ok := strings.Cut(line, ": "); ok {
					name = friendlyPCIDescription(desc)
				}
			}
		}
		index := len(result)
		result = append(result, GPU{
			ID:             firstNonEmpty(pciID, fmt.Sprintf("drm:%d", index)),
			Index:          index,
			Name:           firstNonEmpty(name, vendor+" GPU "+deviceID),
			Vendor:         vendor,
			Backend:        linuxGPUBackend(vendor),
			VRAMTotalBytes: total,
			VRAMUsedBytes:  used,
			VRAMFreeBytes:  free,
			SharedMemory:   total == 0,
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].ID < result[j].ID })
	for i := range result {
		result[i].Index = i
	}
	return result
}

func friendlyPCIDescription(value string) string {
	value = strings.TrimSpace(value)
	if _, description, ok := strings.Cut(value, ": "); ok {
		value = strings.TrimSpace(description)
	}
	return value
}

func detectWindowsGPUs(ctx context.Context) []GPU {
	out := run(ctx, "powershell", "-NoProfile", "-Command", `Get-CimInstance Win32_VideoController | Select-Object Name,PNPDeviceID,AdapterRAM,DriverVersion | ConvertTo-Json -Compress`)
	return parseWindowsGPUInventory(out)
}

func parseWindowsGPUInventory(out string) []GPU {
	if out == "" {
		return nil
	}
	type entry struct {
		Name          string `json:"Name"`
		PNPDeviceID   string `json:"PNPDeviceID"`
		AdapterRAM    int64  `json:"AdapterRAM"`
		DriverVersion string `json:"DriverVersion"`
	}
	var list []entry
	if strings.HasPrefix(strings.TrimSpace(out), "[") {
		_ = json.Unmarshal([]byte(out), &list)
	} else {
		var one entry
		if json.Unmarshal([]byte(out), &one) == nil {
			list = []entry{one}
		}
	}
	result := make([]GPU, 0, len(list))
	for i, item := range list {
		vendor := inferVendor(item.Name)
		// Win32_VideoController.AdapterRAM is inventory metadata, not a live free
		// VRAM counter (and is often truncated). Publishing it as both total and
		// free admitted unsafe overcommit. nvidia-smi records are merged earlier;
		// all CIM-only devices therefore remain capacity-unknown and fail closed
		// for GPU scheduling. The telemetry-unavailable marker makes the pressure
		// guard ignore this non-measurement, so it neither blocks CPU starts nor
		// triggers destructive eviction.
		_ = item.AdapterRAM
		result = append(result, GPU{
			ID: firstNonEmpty(item.PNPDeviceID, fmt.Sprintf("gpu:%d", i)), Index: i,
			Name: item.Name, Vendor: vendor,
			Backend:                  map[string]string{"nvidia": "cuda", "amd": "directml", "intel": "directml"}[vendor],
			DriverVersion:            item.DriverVersion,
			VRAMTelemetryUnavailable: true,
		})
	}
	return result
}

func detectDiskFree(ctx context.Context, target string) int64 {
	target = strings.TrimSpace(target)
	if target == "" {
		target = "."
	}
	if runtime.GOOS == "windows" {
		out := run(ctx, "powershell", "-NoProfile", "-Command", fmt.Sprintf(`$p=[IO.Path]::GetPathRoot(%q); (Get-PSDrive -Name $p.Substring(0,1)).Free`, target))
		return parseInt64(out)
	}
	out := run(ctx, "df", "-Pk", target)
	lines := strings.Split(strings.TrimSpace(out), "\n")
	if len(lines) < 2 {
		return 0
	}
	fields := strings.Fields(lines[len(lines)-1])
	if len(fields) < 4 {
		return 0
	}
	return parseInt64(fields[3]) * 1024
}

func run(parent context.Context, name string, args ...string) string {
	ctx, cancel := context.WithTimeout(parent, commandTimeout)
	defer cancel()
	out, err := exec.CommandContext(ctx, name, args...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func readTrim(path string) string {
	data, _ := os.ReadFile(path)
	return strings.TrimSpace(string(data))
}

func readInt64(path string) int64 { return parseInt64(readTrim(path)) }

func parseInt64(value string) int64 {
	fields := strings.Fields(strings.TrimSpace(value))
	if len(fields) == 0 {
		return 0
	}
	parsed, _ := strconv.ParseInt(fields[0], 10, 64)
	return parsed
}

func resolvedPath(path string) string {
	resolved, err := filepath.EvalSymlinks(path)
	if err != nil {
		return ""
	}
	return resolved
}

func vendorFromPCI(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "0x10de":
		return "nvidia"
	case "0x1002":
		return "amd"
	case "0x8086":
		return "intel"
	default:
		return "unknown"
	}
}

func linuxGPUName(vendorID, deviceID string) string {
	if strings.EqualFold(vendorID, "0x1002") && strings.EqualFold(deviceID, "0x7550") {
		return "AMD Radeon RX 9070 XT"
	}
	return ""
}

func linuxGPUBackend(vendor string) string {
	switch vendor {
	case "nvidia":
		return "cuda"
	case "amd":
		if _, err := os.Stat("/opt/rocm"); err == nil {
			return "rocm"
		}
		return "vulkan"
	case "intel":
		return "xpu"
	default:
		return ""
	}
}

func inferVendor(name string) string {
	lower := strings.ToLower(name)
	switch {
	case strings.Contains(lower, "nvidia"), strings.Contains(lower, "geforce"):
		return "nvidia"
	case strings.Contains(lower, "amd"), strings.Contains(lower, "radeon"):
		return "amd"
	case strings.Contains(lower, "intel"):
		return "intel"
	case strings.Contains(lower, "apple"):
		return "apple"
	default:
		return "unknown"
	}
}

func firstDisplayName(output string) string {
	for _, line := range strings.Split(output, "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "Chipset Model:") {
			return strings.TrimSpace(strings.TrimPrefix(line, "Chipset Model:"))
		}
	}
	return "Apple GPU"
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}
