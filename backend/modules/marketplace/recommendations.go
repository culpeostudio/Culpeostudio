package marketplace

import (
	"math"
	"path/filepath"
	"strings"

	"github.com/culpeohq/backend/internal/recommender"
	"github.com/culpeohq/backend/modules/marketplace/types"
)

func marketplaceRecommendation(model types.ModelSummary, profile HardwareProfile, requestedQuantization string) recommender.Result {

	if !hasKnownVRAMMetadata(model) {
		return recommender.Result{}
	}

	if model.EstimatedVRAMGB > 0 && len(model.DownloadOptions) == 0 && model.SizeBytes == 0 {
		return estimatedVRAMOnlyResult(model, profile)
	}
	base := recommender.Model{
		ID:             model.ModelID,
		ParameterCount: int64(math.Round(model.ParameterCountB * 1e9)),
		QualityScore:   float64(model.IntelligenceScore),
		ContextLength:  model.ContextLength,
	}
	hardware := recommender.Hardware{
		RAMBytes:      int64(profile.RAMGB) * recommender.GiB,
		DiskFreeBytes: profile.DiskFreeBytes,
	}
	if profile.VRAMGB > 0 {
		hardware.GPUs = []recommender.GPU{{
			Name:                profile.GPUName,
			Vendor:              firstNonEmpty(profile.GPUVendor, inferGPUVendor(profile.GPUName)),
			VRAMBytes:           int64(profile.VRAMGB) * recommender.GiB,
			MemoryBandwidthGBPS: profile.GPUMemoryBandwidthGBPS,
		}}
	}

	options := model.DownloadOptions
	if len(options) == 0 && model.SizeBytes > 0 {
		options = []types.DownloadOption{{SizeBytes: model.SizeBytes, Label: model.ModelID, Format: model.Format}}
	}
	var best recommender.Result
	hasBest := false
	for _, option := range options {

		if !isRecommendableWeightOption(option) {
			continue
		}

		if strings.Contains(strings.ToLower(option.Label+option.AssetID), "mmproj") {
			continue
		}
		sizeBytes := option.SizeBytes
		quantizations := extractQuantizationsFromText(strings.Join([]string{option.Label, option.AssetID, option.URL}, " "))
		quantization := ""
		if len(quantizations) > 0 {
			quantization = quantizations[0]
		}

		if sizeBytes <= 0 && (quantization == "" || model.ParameterCountB <= 0) {
			continue
		}
		optCopy := option
		optCopy.SizeBytes = sizeBytes

		if !optionMatchesRequestedQuantization(optCopy, requestedQuantization) {
			continue
		}
		candidate := recommender.Check(base, &recommender.Variant{
			Quantization:  quantization,
			FileSizeBytes: sizeBytes,
		}, hardware, 4096)

		if !hasBest || candidate.VRAMRequiredBytes < best.VRAMRequiredBytes {
			best, hasBest = candidate, true
		}
	}
	if hasBest {
		return best
	}
	return recommender.Result{}
}

var recommendableWeightFormats = map[string]struct{}{
	"gguf": {}, "safetensors": {}, "mlx": {}, "nemo": {},
	"bin": {}, "pt": {}, "pth": {}, "ckpt": {}, "onnx": {},
}

func isRecommendableWeightOption(option types.DownloadOption) bool {
	format := types.NormalizeFormat(option.Format)
	if format == "" {
		ext := filepath.Ext(firstNonEmpty(option.AssetID, option.Label))
		format = types.NormalizeFormat(strings.TrimPrefix(ext, "."))
	}
	_, ok := recommendableWeightFormats[format]
	return ok
}

func hasKnownVRAMMetadata(model types.ModelSummary) bool {
	if hasRealSizeMetadata(model) {
		return true
	}
	if model.ParameterCountB <= 0 {
		return false
	}
	for _, option := range model.DownloadOptions {
		if !isRecommendableWeightOption(option) {
			continue
		}
		joined := strings.Join([]string{option.Label, option.AssetID, option.URL}, " ")
		if len(extractQuantizationsFromText(joined)) > 0 {
			return true
		}
	}
	return false
}

func hasRealSizeMetadata(model types.ModelSummary) bool {
	if model.EstimatedVRAMGB > 0 || model.SizeBytes > 0 {
		return true
	}
	for _, option := range model.DownloadOptions {
		if option.SizeBytes > 0 {
			return true
		}
	}
	return false
}

func estimatedVRAMOnlyResult(model types.ModelSummary, profile HardwareProfile) recommender.Result {
	requiredBytes := int64(model.EstimatedVRAMGB * float64(recommender.GiB))
	result := recommender.Result{Fit: recommender.FitUnsupported, VRAMRequiredBytes: requiredBytes}
	if requiredBytes <= 0 {
		return result
	}
	vramBytes := int64(profile.VRAMGB) * recommender.GiB
	ramBytes := int64(profile.RAMGB) * recommender.GiB
	switch {
	case profile.VRAMGB > 0 && vramBytes >= requiredBytes:
		result.CanRun, result.Fit = true, recommender.FitFullGPU
	case profile.VRAMGB > 0 && vramBytes+ramBytes >= requiredBytes:
		result.CanRun, result.Fit = true, recommender.FitPartialOffload
		result.OffloadRatio = float64(requiredBytes-vramBytes) / float64(requiredBytes)
	case ramBytes >= requiredBytes:
		result.CanRun, result.Fit = true, recommender.FitCPUOnly
	}
	return result
}

func optionMatchesRequestedQuantization(option types.DownloadOption, requested string) bool {
	req := normalizeQuantization(requested)
	if req == "" {
		return true
	}
	if req == "safetensors" {
		return types.NormalizeFormat(option.Format) == "safetensors"
	}
	joined := strings.Join([]string{option.Label, option.AssetID, option.URL}, " ")
	return matchesQuantization(extractQuantizationsFromText(joined), requested)
}

func modelHasFullGPUFit(model types.ModelSummary, profile HardwareProfile, requestedQuantization string) bool {
	if !model.LocalModel || profile.VRAMGB <= 0 {
		return false
	}

	return marketplaceRecommendation(model, profile, requestedQuantization).Fit == recommender.FitFullGPU
}

func runtimeRAMOffloadGB(recommendation recommender.Result, estimatedVRAMGB float64) float64 {
	switch recommendation.Fit {
	case recommender.FitPartialOffload:
		return math.Round(estimatedVRAMGB*recommendation.OffloadRatio*10) / 10
	case recommender.FitCPUOnly:
		return estimatedVRAMGB
	default:
		return 0
	}
}

func inferGPUVendor(name string) string {
	lower := strings.ToLower(name)
	switch {
	case strings.Contains(lower, "nvidia"), strings.Contains(lower, "geforce"), strings.Contains(lower, "rtx"), strings.Contains(lower, "gtx"):
		return "nvidia"
	case strings.Contains(lower, "amd"), strings.Contains(lower, "radeon"):
		return "amd"
	case strings.Contains(lower, "intel"), strings.Contains(lower, "arc"):
		return "intel"
	case strings.Contains(lower, "apple"):
		return "apple"
	default:
		return "unknown"
	}
}
