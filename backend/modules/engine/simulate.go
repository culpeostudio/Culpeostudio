package engine

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"github.com/culpeohq/backend/internal/engineplanner"
)

// maxSimulatedModels caps a simulation. Planning is cheap but not free, and
// eight is already more models than a machine that has to hold them all.
const maxSimulatedModels = 8

type simulateModelEntry struct {
	ModelID string
	Config  *EngineConfig
}

// simulatedModel is how one entry of the request fared. Reason is set instead
// of the numbers when the planner reserved no budget for it at all.
type simulatedModel struct {
	Model                  string
	Fits                   bool
	EffectiveContextTokens int
	Placement              Placement
	Memory                 engineplanner.MemoryAllocation
	Warnings               []string
	Reason                 string
}

type simulatedGPUBudget struct {
	ID             string
	Name           string
	VRAMTotalBytes int64
	VRAMFreeBytes  int64
	PlannedBytes   int64
}

type simulatedHost struct {
	RAMTotalBytes     int64
	RAMAvailableBytes int64
	RAMReserveBytes   int64
	GPUs              []simulatedGPUBudget
}

// simulationResult answers whether a set of models fits together, and where
// the budget goes if it does. Reason carries the explanation when the planner
// could allocate nothing at all, in which case Models is empty.
type simulationResult struct {
	Feasible                 bool
	Reason                   string
	Models                   []simulatedModel
	Totals                   engineplanner.MemoryAllocation
	Host                     simulatedHost
	AffectedRunningInstances []string
	Recommendations          []string
}

func (m *EngineModule) simulateParallelLoad(ctx context.Context, entries []simulateModelEntry, includeRunning bool) (simulationResult, error) {
	hardwareSnapshot, plannerHardware := m.liveHardware(ctx)
	requests := []engineplanner.Request{}
	warningsByID := map[string][]string{}
	nameByID := map[string]string{}

	if includeRunning {
		m.mu.RLock()
		for _, existing := range m.instances {
			if !resourceHoldingState(existing.State) {
				continue
			}
			existingRecord, found := m.modelsByID[existing.ModelID]
			if !found || !existingRecord.Startable {
				continue
			}
			planningConfig := cloneEngineConfig(existing.RequestedConfig)
			if forced, _ := boolOption(existing.EffectiveConfig.RuntimeOptions, "force_cpu_runtime"); forced {
				planningConfig.RuntimeOptions["force_cpu_runtime"] = true
				planningConfig.RuntimeOptions["offload"] = "cpu"
			}
			request, warnings, requestErr := plannerRequest(existing.ID, existingRecord, planningConfig, existing.Plan)
			if requestErr != nil {
				m.mu.RUnlock()
				return simulationResult{}, requestErr
			}
			if forceCPUForConfig(existingRecord, planningConfig, hardwareSnapshot) {
				request.ForceCPU = true
			}
			if selectionErr := limitPlannerGPUs(&request, existingRecord, planningConfig, hardwareSnapshot); selectionErr != nil {
				m.mu.RUnlock()
				return simulationResult{}, selectionErr
			}
			requests = append(requests, request)
			warningsByID[existing.ID] = warnings
			nameByID[existing.ID] = existing.ServedModelName
		}
		m.mu.RUnlock()
	}

	simulatedIDs := make([]string, 0, len(entries))
	for index, entry := range entries {
		record, ok := m.getModel(strings.TrimSpace(entry.ModelID))
		if !ok {
			return simulationResult{}, fmt.Errorf("Modell %q wurde nicht gefunden", entry.ModelID)
		}
		if !record.Startable {
			return simulationResult{}, notStartableError(record)
		}
		config := defaultEngineConfig()
		if entry.Config != nil {
			config = normalizeConfig(*entry.Config)
		}
		simulationID := fmt.Sprintf("simulate-%d", index+1)
		request, warnings, err := plannerRequest(simulationID, record, config, nil)
		if err != nil {
			return simulationResult{}, err
		}
		if forceCPUForConfig(record, config, hardwareSnapshot) {
			request.ForceCPU = true
			zero := int64(0)
			request.WeightGPUBytes = &zero
		}
		if err := limitPlannerGPUs(&request, record, config, hardwareSnapshot); err != nil {
			return simulationResult{}, err
		}
		requests = append(requests, request)
		warningsByID[simulationID] = warnings
		nameByID[simulationID] = record.Name
		simulatedIDs = append(simulatedIDs, simulationID)
	}

	settings := m.settings.Get()
	ramReserve := effectiveReserveBytes(settings.EngineRAMReserveBytes, hardwareSnapshot.RAMTotalBytes, 15, 4<<30)
	ramReserve = maxInt64(ramReserve, emergencyFloor(hardwareSnapshot.RAMTotalBytes, guardRAMFloor))
	gpuReserves := map[string]int64{}
	for _, gpu := range hardwareSnapshot.GPUs {
		if gpu.SharedMemory {
			continue
		}
		reserve := effectiveReserveBytes(settings.EngineGPUReserveBytes, gpu.VRAMTotalBytes, 10, 512<<20)
		gpuReserves[gpu.ID] = maxInt64(reserve, emergencyFloor(gpu.VRAMTotalBytes, guardGPUFloor))
	}
	reservePolicy := engineplanner.ReservePolicy{RAMBytes: &ramReserve, GPUBytesByID: gpuReserves}

	plans, err := engineplanner.Allocate(plannerHardware, requests, reservePolicy)
	if err != nil {
		// Not an error for the caller: the answer to "do these fit" is no, and
		// the planner's message is the reason.
		return simulationResult{
			Feasible: false,
			Reason:   "Die Modelle passen zusammen nicht in das verfuegbare Speicherbudget: " + err.Error(),
		}, nil
	}
	planByID := map[string]engineplanner.ContextPlan{}
	for _, plan := range plans {
		planByID[plan.InstanceID] = plan
	}

	feasible := true
	recommendations := []string{}
	totalRAM := int64(0)
	totalGPU := map[string]int64{}
	modelResults := make([]simulatedModel, 0, len(simulatedIDs))
	for _, id := range simulatedIDs {
		plan, exists := planByID[id]
		if !exists {
			feasible = false
			modelResults = append(modelResults, simulatedModel{
				Model:  nameByID[id],
				Fits:   false,
				Reason: "Der Planer konnte kein Budget reservieren.",
			})
			continue
		}
		fits := plan.EffectiveContext > 0
		if !fits {
			feasible = false
		}
		view := planView(plan, warningsByID[id])
		totalRAM += view.Memory.Total.RAMBytes
		for gpuID, bytes := range view.Memory.Total.GPUBytes {
			totalGPU[gpuID] += bytes
		}
		entry := simulatedModel{
			Model:                  nameByID[id],
			Fits:                   fits,
			EffectiveContextTokens: view.EffectiveContextTokens,
			Placement:              placementForPlan(&view),
			Memory:                 view.Memory.Total,
			Warnings:               view.Warnings,
		}
		if view.UsesRAM {
			recommendations = append(recommendations, fmt.Sprintf(
				"%s nutzt RAM-Offload; ein kleinerer Kontext haelt das Modell vollstaendig im Grafikspeicher.", nameByID[id]))
		}
		if fits && view.EffectiveContextTokens < view.ModelContextLimitTokens/4 {
			recommendations = append(recommendations, fmt.Sprintf(
				"%s erhaelt nur %d von %d Token Kontext; weniger parallele Modelle geben ihm mehr Budget.",
				nameByID[id], view.EffectiveContextTokens, view.ModelContextLimitTokens))
		}
		modelResults = append(modelResults, entry)
	}

	affected := []string{}
	if includeRunning {
		m.mu.RLock()
		for id, plan := range planByID {
			existing := m.instances[id]
			if existing == nil || existing.Plan == nil {
				continue
			}
			if existing.Plan.EffectiveContextTokens != plan.EffectiveContext {
				name := existing.ServedModelName
				if name == "" {
					name = id
				}
				affected = append(affected, name)
			}
		}
		m.mu.RUnlock()
		sort.Strings(affected)
	}
	if len(affected) > 0 {
		recommendations = append(recommendations, "Laufende Modelle wuerden mit kleinerem Kontext neu geplant: "+strings.Join(affected, ", "))
	}

	gpuBudget := make([]simulatedGPUBudget, 0, len(hardwareSnapshot.GPUs))
	for _, gpu := range hardwareSnapshot.GPUs {
		gpuBudget = append(gpuBudget, simulatedGPUBudget{
			ID:             gpu.ID,
			Name:           gpu.Name,
			VRAMTotalBytes: gpu.VRAMTotalBytes,
			VRAMFreeBytes:  gpu.VRAMFreeBytes,
			PlannedBytes:   totalGPU[gpu.ID],
		})
	}

	return simulationResult{
		Feasible: feasible,
		Models:   modelResults,
		Totals:   engineplanner.MemoryAllocation{RAMBytes: totalRAM, GPUBytes: totalGPU},
		Host: simulatedHost{
			RAMTotalBytes:     hardwareSnapshot.RAMTotalBytes,
			RAMAvailableBytes: hardwareSnapshot.RAMAvailableBytes,
			RAMReserveBytes:   ramReserve,
			GPUs:              gpuBudget,
		},
		AffectedRunningInstances: affected,
		Recommendations:          recommendations,
	}, nil
}
