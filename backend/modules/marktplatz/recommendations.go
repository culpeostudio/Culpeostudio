package marktplatz

import (
	"math"
	"path/filepath"
	"strings"

	"github.com/fillyengine/backend/internal/recommender"
	"github.com/fillyengine/backend/modules/marktplatz/types"
)

// marketplaceRecommendation adapts marketplace metadata to the pure ranking
// core.  Every downloadable artifact is checked because a repository can ship
// Q4 and Q8 files with radically different runtime requirements.
func marketplaceRecommendation(model types.ModelSummary, profile HardwareProfile, requestedQuantization string) recommender.Result {
	// hasKnownVRAMMetadata allows two sources: a real artifact size, or a
	// parameter count parsed from the repo name combined with a real
	// quantization label parsed from a real filename (see
	// estimateWeightBytes' formula fallback below). Both are actual data
	// extracted from the provider response, never an invented default.
	if !hasKnownVRAMMetadata(model) {
		return recommender.Result{}
	}
	// A curated/explicit EstimatedVRAMGB with no download option or whole-
	// repo size to derive a weight size from (e.g. a hand-picked suggestion)
	// already represents the complete requirement. Feeding it into
	// recommender.Check as a Variant's FileSizeBytes would double-count: Check
	// layers KV-cache/activation/framework overhead on top of a raw weight
	// size, but this number already includes that overhead. Compare it
	// directly against the detected hardware instead.
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
		// Repos routinely bundle real, correctly-sized files that are not
		// model weights at all: bundled Python inference/conversion scripts,
		// notebooks, importance-matrix calibration data, LFS config. Any of
		// these can be smaller than every real weight shard, so without this
		// check the "smallest artifact wins" rule below would pick a 5KB
		// script and report it as the whole model's VRAM requirement. Only
		// formats an inference runtime can actually load as weights count.
		if !isRecommendableWeightOption(option) {
			continue
		}
		// mmproj files are multimodal projector weights: real, download-
		// worthy companions to a vision model's main GGUF, but not a
		// runnable checkpoint on their own. They are much smaller than the
		// main weight file, so leaving them in this loop meant the "smallest
		// artifact wins" rule picked the projector and reported its tiny
		// size as the whole model's VRAM requirement.
		if strings.Contains(strings.ToLower(option.Label+option.AssetID), "mmproj") {
			continue
		}
		sizeBytes := option.SizeBytes
		quantizations := extractQuantizationsFromText(strings.Join([]string{option.Label, option.AssetID, option.URL}, " "))
		quantization := ""
		if len(quantizations) > 0 {
			quantization = quantizations[0]
		}
		// HuggingFace's search/list API never reports file sizes (only a
		// single-model "?blobs=true" lookup does, see DetailHuggingFace).
		// When the artifact has a real, filename-derived quantization and the
		// model has a name-derived parameter count, recommender.Check falls
		// back to the same weights * bits-per-weight formula llama.cpp/
		// whichllm use for GGUF size estimates instead of skipping the
		// option outright.
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
		// The displayed estimate is the smallest viable artifact.  GPU-only
		// filtering below checks all artifacts separately, so this does not hide
		// a larger requested quantization.
		if !hasBest || candidate.VRAMRequiredBytes < best.VRAMRequiredBytes {
			best, hasBest = candidate, true
		}
	}
	if hasBest {
		return best
	}
	return recommender.Result{}
}

// recommendableWeightFormats are the file formats an inference runtime can
// actually load as model weights. Extension-blocklisting every non-weight
// file HuggingFace repos might bundle (gitattributes, imatrix, .py scripts,
// notebooks, ...) is a losing game -- this is the closed allowlist those
// checks exist to approximate, applied directly where it matters: deciding
// which artifact's size represents "the model".
var recommendableWeightFormats = map[string]struct{}{
	"gguf": {}, "safetensors": {}, "mlx": {}, "nemo": {},
	"bin": {}, "pt": {}, "pth": {}, "ckpt": {}, "onnx": {},
}

// isRecommendableWeightOption falls back to the AssetID/Label's file
// extension when Format was not explicitly set (curated suggestions and
// synthetic single-option lists sometimes only carry a filename), so the
// check works from real filename evidence either way instead of silently
// admitting everything whenever a caller forgets to populate Format.
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

// hasRealSizeMetadata reports whether a real, provider-supplied byte size is
// available anywhere on the model -- as opposed to the parameter-count-based
// formula estimate hasKnownVRAMMetadata also accepts.
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

// estimatedVRAMOnlyResult classifies fit for a model whose only VRAM data
// point is a pre-computed total (no per-artifact size to run through
// recommender.Check). It mirrors Check's full-GPU / GPU+RAM / CPU-only /
// unsupported decision tree directly against the whole requirement.
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
	// marketplaceRecommendation is the single source of truth for fit
	// classification (it also covers the EstimatedVRAMGB-only case and the
	// formula-based estimate for options without a real file size). It
	// already picks the smallest-VRAM artifact matching requestedQuantization
	// across every download option; smaller VRAM requirement is strictly
	// easier to fit fully, so if that best candidate does not reach
	// FitFullGPU, no larger option will either.
	return marketplaceRecommendation(model, profile, requestedQuantization).Fit == recommender.FitFullGPU
}

// runtimeRAMOffloadGB reports how much of estimatedVRAMGB actually runs from
// system RAM instead of GPU VRAM, so the UI can show a "X GB GPU + Y GB RAM"
// breakdown instead of a flat "fits"/"does not fit" verdict. GPU+RAM (partial
// offload) is a legitimate, runnable configuration -- not a failure state --
// and CPU-only means the entire estimate runs from RAM.
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
