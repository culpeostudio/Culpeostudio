package engine

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/gofiber/fiber/v2"
)

type simulateModelEntry struct {
	ModelID string        `json:"model_id"`
	Config  *EngineConfig `json:"config,omitempty"`
}

func (m *EngineModule) handleSimulateParallelLoad(c *fiber.Ctx) error {
	var body struct {
		Models         []simulateModelEntry `json:"models"`
		IncludeRunning *bool                `json:"include_running,omitempty"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Ungueltige Anfrage: models-Liste erwartet"})
	}
	if len(body.Models) == 0 || len(body.Models) > 8 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Bitte 1 bis 8 Modelle fuer die Simulation angeben"})
	}
	includeRunning := body.IncludeRunning == nil || *body.IncludeRunning
	result, err := m.simulateParallelLoad(c.UserContext(), body.Models, includeRunning)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(result)
}

func (m *EngineModule) simulateParallelLoad(ctx context.Context, entries []simulateModelEntry, includeRunning bool) (fiber.Map, error) {
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
				return nil, requestErr
			}
			if forceCPUForConfig(existingRecord, planningConfig, hardwareSnapshot) {
				request.ForceCPU = true
			}
			if selectionErr := limitPlannerGPUs(&request, existingRecord, planningConfig, hardwareSnapshot); selectionErr != nil {
				m.mu.RUnlock()
				return nil, selectionErr
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
			return nil, fmt.Errorf("Modell %q wurde nicht gefunden", entry.ModelID)
		}
		if !record.Startable {
			return nil, notStartableError(record)
		}
		config := defaultEngineConfig()
		if entry.Config != nil {
			config = normalizeConfig(*entry.Config)
		}
		simulationID := fmt.Sprintf("simulate-%d", index+1)
		request, warnings, err := plannerRequest(simulationID, record, config, nil)
		if err != nil {
			return nil, err
		}
		if forceCPUForConfig(record, config, hardwareSnapshot) {
			request.ForceCPU = true
			zero := int64(0)
			request.WeightGPUBytes = &zero
		}
		if err := limitPlannerGPUs(&request, record, config, hardwareSnapshot); err != nil {
			return nil, err
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
		return fiber.Map{
			"feasible": false,
			"reason":   "Die Modelle passen zusammen nicht in das verfuegbare Speicherbudget: " + err.Error(),
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
	modelResults := make([]fiber.Map, 0, len(simulatedIDs))
	for _, id := range simulatedIDs {
		plan, exists := planByID[id]
		if !exists {
			feasible = false
			modelResults = append(modelResults, fiber.Map{
				"model": nameByID[id], "fits": false,
				"reason": "Der Planer konnte kein Budget reservieren.",
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
		entry := fiber.Map{
			"model":                    nameByID[id],
			"fits":                     fits,
			"effective_context_tokens": view.EffectiveContextTokens,
			"placement":                string(placementForPlan(&view)),
			"memory":                   view.Memory.Total,
		}
		if len(view.Warnings) > 0 {
			entry["warnings"] = view.Warnings
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

	gpuBudget := make([]fiber.Map, 0, len(hardwareSnapshot.GPUs))
	for _, gpu := range hardwareSnapshot.GPUs {
		gpuBudget = append(gpuBudget, fiber.Map{
			"id": gpu.ID, "name": gpu.Name,
			"vram_total_bytes": gpu.VRAMTotalBytes,
			"vram_free_bytes":  gpu.VRAMFreeBytes,
			"planned_bytes":    totalGPU[gpu.ID],
		})
	}

	return fiber.Map{
		"feasible": feasible,
		"models":   modelResults,
		"totals": fiber.Map{
			"ram_bytes": totalRAM,
			"gpu_bytes": totalGPU,
		},
		"host": fiber.Map{
			"ram_total_bytes":     hardwareSnapshot.RAMTotalBytes,
			"ram_available_bytes": hardwareSnapshot.RAMAvailableBytes,
			"ram_reserve_bytes":   ramReserve,
			"gpus":                gpuBudget,
		},
		"affected_running_instances": affected,
		"recommendations":            recommendations,
	}, nil
}
