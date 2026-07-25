package engine

import (
	"context"
	"os"
	"testing"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

// TestDiagnosePlannerWithRealModels is a manual diagnosis helper: it runs the
// real catalog scan + planner against the machine's actual hardware and model
// directory and dumps every intermediate number. Enable with
// ENGINE_DIAGNOSE_DIR=/path/to/models.
func TestDiagnosePlannerWithRealModels(t *testing.T) {
	dir := os.Getenv("ENGINE_DIAGNOSE_DIR")
	if dir == "" {
		t.Skip("set ENGINE_DIAGNOSE_DIR to run the planner diagnosis")
	}
	ctx := context.Background()
	records, err := modelcatalog.Scan(ctx, dir)
	if err != nil {
		t.Fatal(err)
	}
	snapshot := hardware.Detect(ctx, dir)
	t.Logf("HARDWARE ram_total=%d ram_available=%d gpus=%d", snapshot.RAMTotalBytes, snapshot.RAMAvailableBytes, len(snapshot.GPUs))
	for _, gpu := range snapshot.GPUs {
		t.Logf("  GPU id=%s name=%q backend=%s vram_total=%d vram_free=%d shared=%v",
			gpu.ID, gpu.Name, gpu.Backend, gpu.VRAMTotalBytes, gpu.VRAMFreeBytes, gpu.SharedMemory)
	}

	availableRAM := snapshot.RAMAvailableBytes
	plannerHardware := engineplanner.Hardware{
		RAMTotalBytes: snapshot.RAMTotalBytes, RAMAvailableBytes: &availableRAM,
		RAMConfidence: engineplanner.ConfidenceMeasured,
	}
	for _, gpu := range snapshot.GPUs {
		available := gpu.VRAMFreeBytes
		plannerHardware.GPUs = append(plannerHardware.GPUs, engineplanner.GPU{
			ID: gpu.ID, Name: gpu.Name, Backend: gpu.Backend, TotalBytes: gpu.VRAMTotalBytes,
			AvailableBytes: &available, UnifiedMemory: gpu.SharedMemory, Confidence: engineplanner.ConfidenceMeasured,
		})
	}

	for _, record := range records {
		t.Logf("MODEL id=%s name=%q format=%s size=%d startable=%v issues=%v",
			record.ID, record.Name, record.Format, record.SizeBytes, record.Startable, record.Issues)
		t.Logf("  METADATA arch=%q layers=%d heads=%d kv_heads=%d head_dim=%d embed=%d context=%d params=%d quant=%q",
			record.Metadata.Architecture, record.Metadata.Layers, record.Metadata.AttentionHeads,
			record.Metadata.KVHeads, record.Metadata.HeadDimension, record.Metadata.EmbeddingDimension,
			record.Metadata.ContextLength, record.Metadata.ParameterCount, record.Metadata.Quantization)
		if !record.Startable {
			continue
		}
		request, warnings, err := plannerRequest("diagnose", record, defaultEngineConfig(), nil)
		if err != nil {
			t.Logf("  plannerRequest ERROR: %v", err)
			continue
		}
		t.Logf("  REQUEST weights=%d context_limit=%d layers=%d kv_heads=%d head_dim=%d warnings=%v",
			request.Model.WeightBytes, request.Model.ContextLimit, request.Model.Layers,
			request.Model.KVHeads, request.Model.HeadDimension, warnings)
		ramReserve := effectiveReserveBytes(nil, snapshot.RAMTotalBytes, 15, 4<<30)
		ramReserve = maxInt64(ramReserve, emergencyFloor(snapshot.RAMTotalBytes, guardRAMFloor))
		gpuReserves := map[string]int64{}
		for _, gpu := range snapshot.GPUs {
			if gpu.SharedMemory {
				continue
			}
			reserve := effectiveReserveBytes(nil, gpu.VRAMTotalBytes, 10, 512<<20)
			gpuReserves[gpu.ID] = maxInt64(reserve, emergencyFloor(gpu.VRAMTotalBytes, guardGPUFloor))
		}
		t.Logf("  RESERVES ram=%d gpu=%v", ramReserve, gpuReserves)
		plans, err := engineplanner.Allocate(plannerHardware, []engineplanner.Request{request}, engineplanner.ReservePolicy{
			RAMBytes: &ramReserve, GPUBytesByID: gpuReserves,
		})
		if err != nil {
			t.Logf("  ALLOCATE ERROR: %v", err)
			continue
		}
		for _, plan := range plans {
			t.Logf("  PLAN effective=%d gpu_only_max=%d ram_backed_max=%d model_limit=%d kv_per_token=%d uses_ram=%v",
				plan.EffectiveContext, plan.GPUOnlyMaxContext, plan.RAMBackedMaxContext,
				plan.ModelLimit, plan.KVBytesPerTokenAtStart, plan.UsesRAM)
			t.Logf("  PLAN memory total_ram=%d total_gpu=%v weights_ram=%d weights_gpu=%v",
				plan.Breakdown.Total.RAMBytes, plan.Breakdown.Total.GPUBytes,
				plan.Breakdown.Weights.RAMBytes, plan.Breakdown.Weights.GPUBytes)
		}
	}
}
