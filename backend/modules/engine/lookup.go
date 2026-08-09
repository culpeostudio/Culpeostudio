package engine

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	"github.com/culpeohq/backend/internal/engineplanner"
	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/internal/modelcatalog"
)

func placementForPlan(plan *ContextPlanView) Placement {
	if plan == nil {
		return PlacementUnknown
	}
	hasRAM := plan.Memory.Total.RAMBytes > 0
	hasGPU := false
	for _, value := range plan.Memory.Total.GPUBytes {
		if value > 0 {
			hasGPU = true
			break
		}
	}
	switch {
	case hasRAM && hasGPU:
		return PlacementHybrid
	case hasGPU:
		return PlacementGPU
	case hasRAM:
		return PlacementRAM
	default:
		return PlacementUnknown
	}
}

func (m *EngineModule) getInstance(id string) (*EngineInstance, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	instance := m.instances[id]
	return cloneInstance(instance), instance != nil
}

func (m *EngineModule) getModel(id string) (modelcatalog.ModelRecord, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	record, ok := m.modelsByID[id]
	return record, ok
}

func (m *EngineModule) freshModelRecord(ctx context.Context, record modelcatalog.ModelRecord) (modelcatalog.ModelRecord, error) {
	m.mu.RLock()
	root := m.modelDir
	m.mu.RUnlock()
	if root == "" || modelcatalog.VerifyFingerprint(root, record) {
		return record, nil
	}
	log.Printf("[engine] model %s changed on disk since last scan, rescanning catalog", record.ID)
	if _, err := m.rescan(ctx); err != nil {
		return record, fmt.Errorf("Modelldateien von %q haben sich geaendert, aber der erneute Scan ist fehlgeschlagen: %w", record.Name, err)
	}
	fresh, ok := m.getModel(record.ID)
	if !ok {
		return record, fmt.Errorf("Modell %q wurde auf der Festplatte veraendert oder entfernt und ist nach dem erneuten Scan nicht mehr verfuegbar.", record.Name)
	}
	return fresh, nil
}

func (m *EngineModule) modelPath(record modelcatalog.ModelRecord) (string, error) {
	m.mu.RLock()
	root := m.modelDir
	m.mu.RUnlock()
	candidate := filepath.Join(root, filepath.FromSlash(record.RelativePath))
	abs, err := filepath.Abs(candidate)
	if err != nil {
		return "", err
	}
	relative, err := filepath.Rel(root, abs)
	if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("Modellpfad verlaesst model_dir")
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return "", err
	}
	resolvedRelative, err := filepath.Rel(root, resolved)
	if err != nil || resolvedRelative == ".." || strings.HasPrefix(resolvedRelative, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("aufgeloester Modellpfad verlaesst model_dir")
	}
	return resolved, nil
}

func (m *EngineModule) liveHardware(ctx context.Context) (hardware.Snapshot, engineplanner.Hardware) {
	m.mu.RLock()
	modelDir := m.modelDir
	m.mu.RUnlock()
	snapshot := hardware.Detect(ctx, modelDir)
	availableRAM := snapshot.RAMAvailableBytes
	plannerHardware := engineplanner.Hardware{
		RAMTotalBytes: snapshot.RAMTotalBytes, RAMAvailableBytes: &availableRAM,
		RAMConfidence: engineplanner.ConfidenceMeasured, EngineRAMUsedBytes: m.engineProcessRAM(),
	}
	engineGPUUsed := m.enginePlannedGPUUsage()
	for _, gpu := range snapshot.GPUs {
		available := gpu.VRAMFreeBytes
		plannerHardware.GPUs = append(plannerHardware.GPUs, engineplanner.GPU{
			ID: gpu.ID, Name: gpu.Name, Backend: gpu.Backend, TotalBytes: gpu.VRAMTotalBytes,
			AvailableBytes: &available, EngineUsedBytes: engineGPUUsed[gpu.ID], UnifiedMemory: gpu.SharedMemory, Confidence: engineplanner.ConfidenceMeasured,
		})
	}
	return snapshot, plannerHardware
}

func (m *EngineModule) enginePlannedGPUUsage() map[string]int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()
	result := map[string]int64{}
	for _, instance := range m.instances {
		if instance.State != engineruntime.StateReady || instance.Plan == nil {
			continue
		}
		for id, bytes := range instance.Plan.Memory.Total.GPUBytes {
			result[id] += bytes
		}
	}
	return result
}

func (m *EngineModule) engineProcessRAM() int64 {
	if m.supervisor == nil || runtime.GOOS != "linux" {
		return 0
	}
	var total int64
	for _, process := range m.supervisor.Instances() {
		if process.PID <= 0 {
			continue
		}
		data, err := os.ReadFile(filepath.Join("/proc", strconv.Itoa(process.PID), "status"))
		if err != nil {
			continue
		}
		for _, line := range strings.Split(string(data), "\n") {
			if strings.HasPrefix(line, "VmRSS:") {
				fields := strings.Fields(line)
				if len(fields) >= 2 {
					value, _ := strconv.ParseInt(fields[1], 10, 64)
					total += value * 1024
				}
				break
			}
		}
	}
	return total
}
