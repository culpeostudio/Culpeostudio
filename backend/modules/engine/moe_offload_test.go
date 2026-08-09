package engine

import (
	"testing"

	"github.com/culpeohq/backend/internal/modelcatalog"
)

func moeRecord() modelcatalog.ModelRecord {
	// A 30 GB MoE model whose experts are 24 GB of that, spread over 48 layers.
	return modelcatalog.ModelRecord{
		ID: "mdl_moe", Format: modelcatalog.FormatGGUF, Startable: true,
		SizeBytes: 30 << 30,
		Metadata: modelcatalog.Metadata{
			Layers: 48, ExpertLayers: 48, ExpertWeightBytes: 24 << 30,
		},
	}
}

func configWithOptions(options map[string]interface{}) EngineConfig {
	config := defaultEngineConfig()
	for key, value := range options {
		config.RuntimeOptions[key] = value
	}
	return config
}

func TestExpertOffloadMovesExpertBytesNotLayerShares(t *testing.T) {
	record := moeRecord()

	// Half the expert layers on the CPU is half the expert weight - 12 GB - and
	// not half the model. Sizing this by layer share was the bug: 24 of 48
	// layers reads as 15 GB, which understates the GPU budget by 3 GB and
	// overstates what fits.
	moved, warning := expertOffloadBytes(record, configWithOptions(map[string]interface{}{
		"cpu_moe_layers": 24,
	}))
	if warning != "" {
		t.Fatalf("unexpected warning: %s", warning)
	}
	if want := int64(12 << 30); moved != want {
		t.Fatalf("moved %d bytes, want %d", moved, want)
	}

	// Every expert layer moves the whole expert weight, leaving only the dense
	// path on the accelerator.
	for _, request := range []interface{}{-1, 48, 100} {
		moved, _ = expertOffloadBytes(record, configWithOptions(map[string]interface{}{
			"cpu_moe_layers": request,
		}))
		if want := int64(24 << 30); moved != want {
			t.Fatalf("cpu_moe_layers=%v moved %d bytes, want %d", request, moved, want)
		}
	}

	// The boolean form of "all experts on the CPU".
	moved, _ = expertOffloadBytes(record, configWithOptions(map[string]interface{}{
		"cpu_moe": true,
	}))
	if want := int64(24 << 30); moved != want {
		t.Fatalf("cpu_moe moved %d bytes, want %d", moved, want)
	}
}

func TestExpertOffloadIsInertWithoutTheOption(t *testing.T) {
	if moved, warning := expertOffloadBytes(moeRecord(), defaultEngineConfig()); moved != 0 || warning != "" {
		t.Fatalf("an unasked-for offload moved %d bytes (%q)", moved, warning)
	}
	if moved, _ := expertOffloadBytes(moeRecord(), configWithOptions(map[string]interface{}{
		"cpu_moe_layers": 0,
	})); moved != 0 {
		t.Fatalf("zero layers moved %d bytes", moved)
	}
}

func TestExpertOffloadOnADenseModelSaysSoRatherThanMovingNothingQuietly(t *testing.T) {
	dense := moeRecord()
	dense.Metadata.ExpertLayers = 0
	dense.Metadata.ExpertWeightBytes = 0

	moved, warning := expertOffloadBytes(dense, configWithOptions(map[string]interface{}{
		"cpu_moe_layers": 24,
	}))
	if moved != 0 {
		t.Fatalf("a dense model has no experts to move, got %d bytes", moved)
	}
	// llama-server accepts the flag on a dense model and does nothing with it,
	// so silence here would leave the user wondering why the placement is
	// unchanged.
	if warning == "" {
		t.Fatal("an ineffective expert offload must be reported")
	}
}

func TestPlannerRequestSubtractsTheExpertOffloadFromTheGPUBudget(t *testing.T) {
	record := moeRecord()
	config := configWithOptions(map[string]interface{}{"cpu_moe_layers": 24})

	request, warnings, err := plannerRequest("inst", record, config, nil)
	if err != nil {
		t.Fatal(err)
	}
	if request.WeightGPUBytes == nil {
		t.Fatal("the expert offload must set an explicit GPU weight budget")
	}
	// 30 GB total less the 12 GB of experts that moved to RAM.
	if want := int64(18 << 30); *request.WeightGPUBytes != want {
		t.Fatalf("GPU weight budget %d, want %d", *request.WeightGPUBytes, want)
	}
	for _, warning := range warnings {
		if warning == "" {
			t.Fatal("empty warning")
		}
	}
}

func TestPlannerRequestComposesExpertOffloadWithAPartialLayerOffload(t *testing.T) {
	record := moeRecord()
	// Half the layers on the GPU is 15 GB by the layer arithmetic; the expert
	// offload then takes another 12 GB off that.
	config := configWithOptions(map[string]interface{}{
		"gpu_layers": 24, "cpu_moe_layers": 24,
	})

	request, _, err := plannerRequest("inst", record, config, nil)
	if err != nil {
		t.Fatal(err)
	}
	if request.WeightGPUBytes == nil {
		t.Fatal("no GPU weight budget was set")
	}
	if want := int64(3 << 30); *request.WeightGPUBytes != want {
		t.Fatalf("GPU weight budget %d, want %d", *request.WeightGPUBytes, want)
	}
}

func TestPlannerRequestNeverBudgetsNegativeWeight(t *testing.T) {
	record := moeRecord()
	// Experts larger than the layer share would drive the budget below zero.
	config := configWithOptions(map[string]interface{}{
		"gpu_layers": 1, "cpu_moe": true,
	})

	request, _, err := plannerRequest("inst", record, config, nil)
	if err != nil {
		t.Fatal(err)
	}
	if request.WeightGPUBytes == nil || *request.WeightGPUBytes < 0 {
		t.Fatalf("GPU weight budget must not go negative, got %v", request.WeightGPUBytes)
	}
}
