// Portions adapted from whichllm v0.5.15.
// Copyright (c) 2026 Andyyyy64; original portions are MIT-licensed.
// PhiloEngine modifications are AGPL-3.0-only. See NOTICE.

package recommender

import (
	"regexp"
	"strings"
)

const (
	frameworkOverheadBytes      int64   = 300 * 1024 * 1024
	kvBytesPerBParamPerKContext float64 = 3.5 * 1024 * 1024
)

var nonGGUFQuantPatterns = []struct {
	pattern *regexp.Regexp
	quant   string
}{
	{regexp.MustCompile(`(^|[-_/])awq($|[-_/])`), "AWQ"},
	{regexp.MustCompile(`(^|[-_/])gptq($|[-_/])`), "GPTQ"},
	{regexp.MustCompile(`(^|[-_/])mxfp4($|[-_/])`), "MXFP4"},
	{regexp.MustCompile(`(^|[-_/])nvfp4($|[-_/])`), "NVFP4"},
	{regexp.MustCompile(`(bnb[-_/]?4bit|nf4|int4|4bit)`), "BNB_4BIT"},
	{regexp.MustCompile(`(int8|8bit)`), "INT8"},
	{regexp.MustCompile(`(^|[-_/])fp8($|[-_/])`), "FP8"},
	{regexp.MustCompile(`(^|[-_/])bf16($|[-_/])`), "BF16"},
	{regexp.MustCompile(`(^|[-_/])(fp16|f16)($|[-_/])`), "FP16"},
}

var bytesPerWeight = map[string]float64{
	"F32": 4, "F16": 2, "FP16": 2, "BF16": 2, "Q8_0": 1.0625, "Q6_K": .8125,
	"Q5_K_M": .6875, "Q5_K_S": .6875, "Q5_0": .625, "Q4_K_M": .5625,
	"Q4_K_S": .5625, "Q4_0": .5, "Q3_K_M": .4375, "Q3_K_S": .4375,
	"Q3_K_L": .4375, "Q2_K": .3125, "IQ4_XS": .5, "IQ4_NL": .5,
	"IQ3_S": .4, "IQ3_M": .42, "IQ3_XS": .41, "IQ3_XXS": .375,
	"IQ2_S": .275, "IQ2_M": .3, "IQ2_XXS": .25, "IQ1_M": .22,
	"IQ1_S": .21, "Q2_0": .28, "Q1_0": .28, "TQ2_0": .28,
	"TQ1_0": .21, "MXFP4": .53125, "NVFP4": .5625, "AWQ": .5,
	"GPTQ": .5, "BNB_4BIT": .5, "INT8": 1, "FP8": 1,
}

var quantPenalty = map[string]float64{
	"F32": 0, "F16": 0, "FP16": 0, "BF16": 0, "Q8_0": .01, "Q6_K": .02,
	"Q5_K_M": .03, "Q5_K_S": .035, "Q5_0": .035, "Q4_K_M": .05,
	"Q4_K_S": .055, "Q4_0": .06, "NVFP4": .05, "MXFP4": .06,
	"Q3_K_M": .08, "Q3_K_S": .12, "Q3_K_L": .075, "Q2_K": .25,
	"IQ4_XS": .05, "IQ4_NL": .055, "IQ3_XS": .16, "IQ3_S": .17,
	"IQ3_M": .16, "IQ3_XXS": .18, "IQ2_M": .3, "IQ2_S": .32,
	"IQ2_XXS": .4, "IQ1_M": .5, "IQ1_S": .55, "Q2_0": .45,
	"Q1_0": .55, "TQ2_0": .45, "TQ1_0": .55,
}

func normalizeQuantization(quant string) string { return strings.ToUpper(strings.TrimSpace(quant)) }

func effectiveQuantization(model Model, variant *Variant) string {
	if variant != nil && strings.TrimSpace(variant.Quantization) != "" {
		return normalizeQuantization(variant.Quantization)
	}
	if strings.TrimSpace(model.Quantization) != "" {
		return normalizeQuantization(model.Quantization)
	}
	for _, candidate := range nonGGUFQuantPatterns {
		if candidate.pattern.MatchString(strings.ToLower(model.ID)) {
			return candidate.quant
		}
	}
	return "FP16"
}

func estimateWeightBytes(model Model, variant *Variant) int64 {
	if variant != nil && variant.FileSizeBytes > 0 {
		return variant.FileSizeBytes
	}
	bpw := bytesPerWeight[effectiveQuantization(model, variant)]
	if bpw == 0 {
		bpw = 2
	}
	return int64(float64(model.ParameterCount) * bpw)
}

func qualityPenalty(model Model, variant *Variant) float64 {
	if penalty, ok := quantPenalty[effectiveQuantization(model, variant)]; ok {
		return penalty
	}
	return .05
}

func effectiveKVContext(model Model, context int) float64 {
	if model.SlidingWindow <= 0 {
		return float64(context)
	}
	ratio := model.SlidingWindowGlobalRatio
	if ratio < 0 {
		return float64(context)
	}
	if ratio > 1 {
		ratio = 1
	}
	windowed := context
	if windowed > model.SlidingWindow {
		windowed = model.SlidingWindow
	}
	return ratio*float64(context) + (1-ratio)*float64(windowed)
}

func estimateKVCache(model Model, context int) int64 {
	if context <= 0 {
		return 0
	}
	params := float64(model.ParameterCount) / 1e9
	if model.IsMoE && model.ActiveParameterCount > 0 {
		params = float64(model.ActiveParameterCount) / 1e9 * 4
	}
	return int64(params * effectiveKVContext(model, context) / 1024 * kvBytesPerBParamPerKContext)
}

func estimateVRAM(model Model, variant *Variant, context int) int64 {
	effectiveParameters := model.ParameterCount
	if model.IsMoE && model.ActiveParameterCount > 0 {
		effectiveParameters = model.ActiveParameterCount
	}
	activation := int64(400_000_000) + int64(float64(effectiveParameters)*.08) + int64(float64(context)/4096*150_000_000)
	return estimateWeightBytes(model, variant) + estimateKVCache(model, context) + activation + frameworkOverheadBytes
}
