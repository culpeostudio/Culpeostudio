// Tests in this package validate logic adapted from whichllm v0.5.15.
// Copyright (c) 2026 Andyyyy64; original portions are MIT-licensed.
// Culpeo Studio modifications are AGPL-3.0-only. See NOTICE.

package recommender

import "testing"

func TestCheckIncludesRuntimeMemoryBeyondArtifactSize(t *testing.T) {
	model := Model{ID: "acme/model-7b", ParameterCount: 7_000_000_000, QualityScore: 80}
	variant := Variant{Quantization: "Q4_K_M", FileSizeBytes: 4 * GiB}
	result := Check(model, &variant, Hardware{
		RAMBytes: 32 * GiB,
		GPUs:     []GPU{{Name: "GPU", Vendor: "nvidia", VRAMBytes: 5 * GiB, MemoryBandwidthGBPS: 448}},
	}, 4096)
	if result.VRAMRequiredBytes <= variant.FileSizeBytes {
		t.Fatalf("runtime memory was not included: %d", result.VRAMRequiredBytes)
	}
	if !result.CanRun || result.Fit != FitPartialOffload {
		t.Fatalf("got canRun=%v fit=%s, want partial offload", result.CanRun, result.Fit)
	}
}

func TestCheckReportsUnsupportedWhenHardwareIsInsufficient(t *testing.T) {

	model := Model{ID: "acme/model-70b", ParameterCount: 70_000_000_000, QualityScore: 80}
	variant := Variant{Quantization: "Q4_K_M", FileSizeBytes: 40 * GiB}
	result := Check(model, &variant, Hardware{
		RAMBytes: 8 * GiB,
		GPUs:     []GPU{{Name: "GPU", Vendor: "nvidia", VRAMBytes: 6 * GiB, MemoryBandwidthGBPS: 448}},
	}, 4096)
	if result.CanRun {
		t.Fatalf("expected CanRun=false for insufficient hardware")
	}
	if result.Fit != FitUnsupported {
		t.Fatalf("got fit=%s, want unsupported", result.Fit)
	}
	if result.Score != 0 {
		t.Fatalf("expected zero score for a model that cannot run, got %f", result.Score)
	}
}

func TestCheckReportsUnsupportedWhenDiskSpaceIsInsufficient(t *testing.T) {
	model := Model{ID: "acme/model-7b", ParameterCount: 7_000_000_000, QualityScore: 80}
	variant := Variant{Quantization: "Q4_K_M", FileSizeBytes: 4 * GiB}
	result := Check(model, &variant, Hardware{
		RAMBytes:      32 * GiB,
		DiskFreeBytes: 1 * GiB,
		GPUs:          []GPU{{Name: "GPU", Vendor: "nvidia", VRAMBytes: 24 * GiB, MemoryBandwidthGBPS: 448}},
	}, 4096)
	if result.CanRun {
		t.Fatalf("expected CanRun=false when disk space is insufficient")
	}
	if result.Fit != FitUnsupported {
		t.Fatalf("got fit=%s, want unsupported even though it fits in VRAM", result.Fit)
	}
}

func TestCheckUsesTotalMoEWeightsForFit(t *testing.T) {
	model := Model{ID: "acme/moe", ParameterCount: 30_000_000_000, ActiveParameterCount: 3_000_000_000, IsMoE: true, QualityScore: 90}
	variant := Variant{Quantization: "Q4_K_M", FileSizeBytes: 18 * GiB}
	result := Check(model, &variant, Hardware{
		RAMBytes: 64 * GiB,
		GPUs:     []GPU{{Name: "GPU", Vendor: "nvidia", VRAMBytes: 24 * GiB, MemoryBandwidthGBPS: 1000}},
	}, 4096)
	if !result.CanRun || result.Fit != FitFullGPU {
		t.Fatalf("got canRun=%v fit=%s", result.CanRun, result.Fit)
	}
	if result.EstimatedTokPerSec < 10 {
		t.Fatalf("unexpectedly low MoE speed estimate: %f", result.EstimatedTokPerSec)
	}
}
