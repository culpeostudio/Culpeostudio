// Portions adapted from whichllm v0.5.15.
// Copyright (c) 2026 Andyyyy64; original portions are MIT-licensed.
// Culpeo Studio modifications are AGPL-3.0-only. See NOTICE.

// Package recommender estimates what a model will need at runtime and ranks
// candidates against the detected hardware.
package recommender

import (
	"math"
	"strings"
)

var quantEfficiency = map[string]float64{
	"F32": .30, "F16": .40, "FP16": .40, "BF16": .40, "Q8_0": .45, "Q6_K": .50,
	"Q5_K_M": .52, "Q5_K_S": .52, "Q5_0": .50, "Q4_K_M": .55, "Q4_K_S": .55,
	"Q4_0": .53, "NVFP4": .56, "MXFP4": .55, "Q3_K_M": .50, "Q3_K_S": .48,
	"Q3_K_L": .50, "Q2_K": .45, "IQ4_XS": .52, "IQ4_NL": .50, "IQ3_S": .45,
	"IQ3_M": .45, "IQ3_XS": .45, "IQ3_XXS": .42, "IQ2_S": .40, "IQ2_M": .40,
	"IQ2_XXS": .38, "IQ1_M": .35, "IQ1_S": .35,
}

func usableRAM(h Hardware) int64 {
	if h.RAMBudgetBytes > 0 && (h.RAMBytes == 0 || h.RAMBudgetBytes < h.RAMBytes) {
		return h.RAMBudgetBytes
	}
	return h.RAMBytes
}

func availableVRAM(gpu GPU, ram int64) int64 {
	available := gpu.VRAMBytes
	if gpu.UsableVRAMBytes > 0 {
		available = gpu.UsableVRAMBytes
	}
	if gpu.SharedMemory && available < 2*GiB {
		return ram
	}
	return available
}

func effectiveVRAM(gpus []GPU, available []int64) int64 {
	if len(available) == 0 {
		return 0
	}
	if len(available) == 1 {
		return available[0]
	}
	for _, gpu := range gpus {
		if gpu.SharedMemory || strings.EqualFold(gpu.Vendor, "apple") {
			return maxInt64s(available)
		}
	}
	raw := int64(0)
	for _, value := range available {
		raw += value
	}
	return int64(float64(maxInt64(0, raw-int64(len(gpus))*(3*GiB/10))) * .90)
}

func maxInt64(left, right int64) int64 {
	if left > right {
		return left
	}
	return right
}
func maxInt64s(values []int64) int64 {
	var max int64
	for _, value := range values {
		if value > max {
			max = value
		}
	}
	return max
}

func bestGPU(gpus []GPU, available []int64) *GPU {
	if len(gpus) == 0 {
		return nil
	}
	best := 0
	for i := 1; i < len(gpus); i++ {
		if available[i] > available[best] {
			best = i
		}
	}
	return &gpus[best]
}

func Check(model Model, variant *Variant, hardware Hardware, context int) Result {
	if context <= 0 {
		context = 4096
	}
	result := Result{Fit: FitUnsupported, VRAMRequiredBytes: estimateVRAM(model, variant, context)}
	ram := usableRAM(hardware)
	available := make([]int64, 0, len(hardware.GPUs))
	for _, gpu := range hardware.GPUs {
		available = append(available, availableVRAM(gpu, ram))
	}
	for _, value := range available {
		result.VRAMAvailableBytes += value
	}
	fitVRAM := effectiveVRAM(hardware.GPUs, available)
	best := bestGPU(hardware.GPUs, available)
	offloadRAM := ram
	if best != nil && (best.SharedMemory || strings.EqualFold(best.Vendor, "apple")) {
		offloadRAM = 0
	}
	switch {
	case fitVRAM >= result.VRAMRequiredBytes:
		result.CanRun, result.Fit = true, FitFullGPU
	case fitVRAM > 0 && fitVRAM+offloadRAM >= result.VRAMRequiredBytes:
		result.CanRun, result.Fit = true, FitPartialOffload
		result.OffloadRatio = float64(result.VRAMRequiredBytes-fitVRAM) / float64(result.VRAMRequiredBytes)
		result.Warnings = append(result.Warnings, "Ein Teil des Modells wird in den Arbeitsspeicher ausgelagert.")
	case ram >= result.VRAMRequiredBytes:
		result.CanRun, result.Fit = true, FitCPUOnly
		result.Warnings = append(result.Warnings, "Das Modell läuft nur auf der CPU und kann langsam sein.")
	default:
		result.Fit = FitUnsupported
		result.Warnings = append(result.Warnings, "GPU- und Arbeitsspeicher reichen nicht aus.")
	}
	if model.ContextLength > 0 && model.ContextLength < context {
		result.Warnings = append(result.Warnings, "Der angeforderte Kontext ist größer als der Modellkontext.")
	}
	if hardware.DiskFreeBytes > 0 && estimateWeightBytes(model, variant) > hardware.DiskFreeBytes {

		result.CanRun = false
		result.Fit = FitUnsupported
		result.Warnings = append(result.Warnings, "Nicht genügend Speicherplatz für das Modell.")
	}
	result.EstimatedTokPerSec = estimateTokPerSec(model, variant, best, result.Fit)
	result.Score = score(model, variant, result)
	return result
}

func estimateTokPerSec(model Model, variant *Variant, gpu *GPU, fit FitType) float64 {
	parameters := float64(model.ParameterCount) / 1e9
	if model.IsMoE && model.ActiveParameterCount > 0 {
		parameters = float64(model.ActiveParameterCount) / 1e9
	}
	if gpu == nil || fit == FitCPUOnly {
		if parameters <= 0 {
			return 0
		}
		efficiency := quantEfficiency[effectiveQuantization(model, variant)]
		if efficiency == 0 {
			efficiency = .45
		}
		return math.Max(.3, 18/math.Max(parameters, .5)*(efficiency/.45))
	}
	if gpu.MemoryBandwidthGBPS <= 0 {
		return 0
	}
	readBytes := float64(estimateWeightBytes(model, variant))
	if model.IsMoE && model.ActiveParameterCount > 0 && model.ParameterCount > 0 {
		readBytes *= math.Max(float64(model.ActiveParameterCount)/float64(model.ParameterCount), math.Min(.25, math.Max(.05, .05*gpu.MemoryBandwidthGBPS/256)))
	}
	if readBytes <= 0 {
		return 0
	}
	efficiency := quantEfficiency[effectiveQuantization(model, variant)]
	if efficiency == 0 {
		efficiency = .45
	}
	switch strings.ToLower(gpu.Vendor) {
	case "amd":
		efficiency *= .78
	case "apple":
		efficiency *= .82
	case "intel":
		efficiency *= .65
	case "nvidia":
	default:
		efficiency *= .7
	}
	if fit == FitPartialOffload {
		if gpu.SharedMemory || strings.EqualFold(gpu.Vendor, "apple") {
			efficiency *= .85
		} else {
			efficiency *= .45
		}
	}
	return gpu.MemoryBandwidthGBPS * 1e9 / readBytes * efficiency
}

func score(model Model, variant *Variant, result Result) float64 {
	if !result.CanRun {
		return 0
	}
	score := math.Max(0, math.Min(100, model.QualityScore)) * (1 - qualityPenalty(model, variant))
	switch result.Fit {
	case FitPartialOffload:
		score *= .62
	case FitCPUOnly:
		score *= .45
	}
	if result.EstimatedTokPerSec >= 30 {
		score += 3
	} else if result.EstimatedTokPerSec >= 10 {
		score++
	}
	return math.Min(100, score)
}
