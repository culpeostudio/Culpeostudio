package marktplatz

import (
	"testing"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

func TestExtractQuantizationsFromText(t *testing.T) {
	input := "Llama-3.1-Q4_K_M-int8-awq.safetensors"
	got := extractQuantizationsFromText(input)
	if len(got) == 0 {
		t.Fatalf("expected quantization tokens, got none")
	}
	if !matchesQuantization(got, "q4") {
		t.Fatalf("expected q4 to match extracted quantizations: %#v", got)
	}
	if !matchesQuantization(got, "int8") {
		t.Fatalf("expected int8 to match extracted quantizations: %#v", got)
	}
	if !matchesQuantization(got, "awq") {
		t.Fatalf("expected awq to match extracted quantizations: %#v", got)
	}
}

func TestFilterModelsByQuantization(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:       "model-a",
			Quantizations: []string{"q4_k_m"},
		},
		{
			ModelID:       "model-b",
			Quantizations: []string{"int8"},
		},
	}

	filteredQ4 := filterModelsByQuantization(models, "q4")
	if len(filteredQ4) != 1 || filteredQ4[0].ModelID != "model-a" {
		t.Fatalf("expected only model-a for q4, got %#v", filteredQ4)
	}

	filteredInt8 := filterModelsByQuantization(models, "int8")
	if len(filteredInt8) != 1 || filteredInt8[0].ModelID != "model-b" {
		t.Fatalf("expected only model-b for int8, got %#v", filteredInt8)
	}

	// Test safetensors format mapping
	modelsWithFormats := []types.ModelSummary{
		{
			ModelID: "model-c",
			Format:  "safetensors",
			Formats: []string{"safetensors"},
		},
		{
			ModelID: "model-d",
			Format:  "gguf",
			Formats: []string{"gguf"},
		},
	}
	filteredSafetensors := filterModelsByQuantization(modelsWithFormats, "safetensors")
	if len(filteredSafetensors) != 1 || filteredSafetensors[0].ModelID != "model-c" {
		t.Fatalf("expected only model-c for safetensors, got %#v", filteredSafetensors)
	}
}

func TestFilterModelsByCategoryAlsoUsesCapabilityTags(t *testing.T) {
	models := []types.ModelSummary{
		{ModelID: "vision-by-tag", Category: "chat", CapabilityTags: []string{"vision", "api"}},
		{ModelID: "chat-only", Category: "chat", CapabilityTags: []string{"chat", "api"}},
	}

	filtered := filterModelsByCategory(models, "vision")
	if len(filtered) != 1 || filtered[0].ModelID != "vision-by-tag" {
		t.Fatalf("expected tag-matched vision model, got %#v", filtered)
	}
}

func TestDeriveContextLengthDoesNotInventFallback(t *testing.T) {
	model := types.ModelSummary{
		ModelID:  "example/unknown-context-model",
		Provider: types.ProviderOpenRouter,
	}
	if got := deriveContextLength(model); got != 0 {
		t.Fatalf("expected unknown context to remain empty, got %d", got)
	}
}

func TestPriceSortExcludesHuggingFaceAndLocalModels(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:          "local-a",
			Provider:         types.ProviderHuggingFace,
			LocalModel:       true,
			PricePer1MInput:  0,
			PricePer1MOutput: 0,
			PricePer1M:       "lokal",
		},
		{
			ModelID:          "local-cloud-provider",
			Provider:         types.ProviderOpenRouter,
			LocalModel:       true,
			PricePer1MInput:  0.1,
			PricePer1MOutput: 0.1,
		},
		{
			ModelID:          "cloud-free",
			Provider:         types.ProviderOpenRouter,
			LocalModel:       false,
			PricePer1MInput:  0,
			PricePer1MOutput: 0,
			PricePer1M:       "gratis",
			PriceKnown:       true,
		},
		{
			ModelID:          "cloud-a",
			Provider:         types.ProviderFeatherless,
			LocalModel:       false,
			PricePer1MInput:  0.2,
			PricePer1MOutput: 0.4,
			PriceKnown:       true,
		},
		{
			ModelID:          "cloud-b",
			Provider:         types.ProviderFeatherless,
			LocalModel:       false,
			PricePer1MInput:  0.1,
			PricePer1MOutput: 0.1,
			PriceKnown:       true,
		},
		{
			ModelID:    "cloud-unknown",
			Provider:   types.ProviderFeatherless,
			LocalModel: false,
		},
	}

	sorted := sortModels(models, "price_low_high")
	if len(sorted) != 3 {
		t.Fatalf("expected only price API providers, got %#v", sorted)
	}
	if sorted[0].ModelID != "cloud-free" || sorted[1].ModelID != "cloud-b" || sorted[2].ModelID != "cloud-a" {
		t.Fatalf("expected cloud models sorted by input plus output price, got %#v", sorted)
	}
}

func TestPriceSortSupportsHighToLow(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:          "cloud-a",
			Provider:         types.ProviderOpenRouter,
			PricePer1MInput:  0.2,
			PricePer1MOutput: 0.4,
			PriceKnown:       true,
		},
		{
			ModelID:          "cloud-b",
			Provider:         types.ProviderOpenRouter,
			PricePer1MInput:  0.1,
			PricePer1MOutput: 0.1,
			PriceKnown:       true,
		},
		{
			ModelID:          "cloud-free",
			Provider:         types.ProviderOpenRouter,
			PricePer1MInput:  0,
			PricePer1MOutput: 0,
			PricePer1M:       "gratis",
			PriceKnown:       true,
		},
	}

	sorted := sortModels(models, "price_high_low")
	if sorted[0].ModelID != "cloud-a" || sorted[1].ModelID != "cloud-b" || sorted[2].ModelID != "cloud-free" {
		t.Fatalf("expected highest priced model first, got %#v", sorted)
	}
}

func TestEnrichMarketplaceMetadataPreservesExplicitFreeCloudPrice(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:          "cohere/north-mini-code:free",
			Provider:         types.ProviderOpenRouter,
			PricePer1MInput:  0,
			PricePer1MOutput: 0,
			PriceKnown:       true,
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{})
	if len(enriched) != 1 {
		t.Fatalf("expected single model, got %#v", enriched)
	}
	if enriched[0].PricePer1M != "gratis" {
		t.Fatalf("expected explicit free cloud price to stay free, got %#v", enriched[0].PricePer1M)
	}
}

func TestEnrichMarketplaceMetadataDoesNotInventCloudPrices(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:  "unknown/cloud-model",
			Provider: types.ProviderOpenRouter,
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{})
	if len(enriched) != 1 {
		t.Fatalf("expected single model, got %#v", enriched)
	}
	if enriched[0].PricePer1M != "" || enriched[0].PricePer1MInput != 0 || enriched[0].PricePer1MOutput != 0 {
		t.Fatalf("expected unknown cloud price to stay empty, got %#v", enriched[0])
	}
}

func TestEnrichMarketplaceMetadataMarksLocalModelsThatFitDetectedGPU(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:         "local-fit-model",
			Provider:        types.ProviderHuggingFace,
			EstimatedVRAMGB: 12,
		},
		{
			ModelID:         "local-too-large-model",
			Provider:        types.ProviderHuggingFace,
			EstimatedVRAMGB: 20,
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{VRAMGB: 16})
	if len(enriched) != 2 {
		t.Fatalf("expected two models, got %#v", enriched)
	}
	if !enriched[0].FitsDetectedGPU {
		t.Fatalf("expected first local model to fit detected GPU, got %#v", enriched[0])
	}
	if enriched[1].FitsDetectedGPU {
		t.Fatalf("expected second local model to exceed detected GPU, got %#v", enriched[1])
	}

	filtered := filterModelsByGPUFit(enriched, true, HardwareProfile{VRAMGB: 16}, "")
	if len(filtered) != 1 || filtered[0].ModelID != "local-fit-model" {
		t.Fatalf("expected gpu_fit filter to keep only runnable local model, got %#v", filtered)
	}
}

func TestEnrichMarketplaceMetadataUsesSmallestDownloadOptionForGPUFit(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:  "mixed-size-model",
			Provider: types.ProviderHuggingFace,
			DownloadOptions: []types.DownloadOption{
				{Label: "Large Q8", AssetID: "model-Q8_0.gguf", SizeBytes: 10 * 1024 * 1024 * 1024},
				{Label: "Small Q4", AssetID: "model-Q4_K_M.gguf", SizeBytes: 4 * 1024 * 1024 * 1024},
			},
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{VRAMGB: 8})
	if len(enriched) != 1 {
		t.Fatalf("expected single model, got %#v", enriched)
	}
	if enriched[0].EstimatedVRAMGB <= 4.8 || enriched[0].EstimatedVRAMGB >= 5.0 {
		t.Fatalf("expected runtime-aware Q4 estimate around 4.9 GB, got %#v", enriched[0].EstimatedVRAMGB)
	}
	if !enriched[0].FitsDetectedGPU {
		t.Fatalf("expected model to fit because smaller option exists, got %#v", enriched[0])
	}
}

func TestEnrichMarketplaceMetadataLeavesUnknownVRAMEmpty(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:         "metadata-missing-model",
			Provider:        types.ProviderHuggingFace,
			ParameterCountB: 3,
			DownloadOptions: []types.DownloadOption{{Label: "unknown-size.gguf"}},
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{VRAMGB: 16})
	if len(enriched) != 1 {
		t.Fatalf("expected one model, got %#v", enriched)
	}
	if enriched[0].EstimatedVRAMGB != 0 {
		t.Fatalf("expected unknown VRAM to stay empty, got %#v", enriched[0].EstimatedVRAMGB)
	}
	if enriched[0].FitsDetectedGPU {
		t.Fatalf("unknown VRAM must not be marked as GPU-compatible: %#v", enriched[0])
	}
}

func TestEnrichMarketplaceMetadataMarksUnknownFitExplicitly(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:         "metadata-missing-model",
			Provider:        types.ProviderHuggingFace,
			ParameterCountB: 3,
			DownloadOptions: []types.DownloadOption{{Label: "unknown-size.gguf"}},
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{VRAMGB: 16})
	if enriched[0].RuntimeFit != "unknown" {
		t.Fatalf("expected runtime_fit=unknown when no size/quantization data exists, got %#v", enriched[0].RuntimeFit)
	}
}

func TestEnrichMarketplaceMetadataReportsGPUPlusRAMOffload(t *testing.T) {
	// A model too large for VRAM alone but small enough with RAM offload
	// must be reported as a usable partial_offload configuration -- not
	// silently dropped -- with the RAM portion broken out so the UI can
	// show "X GB GPU + Y GB RAM" instead of a flat pass/fail badge.
	models := []types.ModelSummary{
		{
			ModelID:  "gpu-plus-ram-model",
			Provider: types.ProviderHuggingFace,
			DownloadOptions: []types.DownloadOption{
				{Label: "Q4", AssetID: "gpu-plus-ram-model-Q4_K_M.gguf", SizeBytes: 12 * 1024 * 1024 * 1024},
			},
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{VRAMGB: 8, RAMGB: 32})
	if enriched[0].RuntimeFit != "partial_offload" {
		t.Fatalf("expected partial_offload, got %#v", enriched[0].RuntimeFit)
	}
	if enriched[0].FitsDetectedGPU {
		t.Fatalf("partial offload must not be reported as a full GPU fit: %#v", enriched[0])
	}
	if enriched[0].RuntimeRAMOffloadGB <= 0 {
		t.Fatalf("expected a positive RAM offload amount, got %#v", enriched[0].RuntimeRAMOffloadGB)
	}
	if enriched[0].RuntimeRAMOffloadGB >= enriched[0].EstimatedVRAMGB {
		t.Fatalf("RAM offload (%v) must be less than the total requirement (%v)", enriched[0].RuntimeRAMOffloadGB, enriched[0].EstimatedVRAMGB)
	}
}

func TestEnrichMarketplaceMetadataReportsUnsupportedWhenNothingFits(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:  "too-large-for-anything",
			Provider: types.ProviderHuggingFace,
			DownloadOptions: []types.DownloadOption{
				{Label: "Q4", AssetID: "too-large-for-anything-Q4_K_M.gguf", SizeBytes: 200 * 1024 * 1024 * 1024},
			},
		},
	}

	// Small GPU and small RAM: this must not be reported as "cpu_only" (which
	// would imply it runs, just slowly) -- it does not run at all here.
	enriched := enrichMarketplaceMetadata(models, HardwareProfile{VRAMGB: 8, RAMGB: 16})
	if enriched[0].RuntimeFit != "unsupported" {
		t.Fatalf("expected unsupported when neither GPU+RAM nor RAM alone suffice, got %#v", enriched[0].RuntimeFit)
	}
	if enriched[0].FitsDetectedGPU {
		t.Fatalf("unsupported model must not be marked as fitting: %#v", enriched[0])
	}
}

func TestGPUFitRespectsRequestedQuantization(t *testing.T) {
	models := []types.ModelSummary{
		{
			ModelID:  "quantized-model",
			Provider: types.ProviderHuggingFace,
			DownloadOptions: []types.DownloadOption{
				{Label: "Q4", AssetID: "quantized-model-Q4_K_M.gguf", SizeBytes: 4 * 1024 * 1024 * 1024},
				{Label: "Q8", AssetID: "quantized-model-Q8_0.gguf", SizeBytes: 10 * 1024 * 1024 * 1024},
			},
		},
	}

	enriched := enrichMarketplaceMetadata(models, HardwareProfile{VRAMGB: 8})
	filteredQ4 := filterModelsByGPUFit(enriched, true, HardwareProfile{VRAMGB: 8}, "q4")
	if len(filteredQ4) != 1 {
		t.Fatalf("expected q4 model to fit GPU, got %#v", filteredQ4)
	}

	filteredQ8 := filterModelsByGPUFit(enriched, true, HardwareProfile{VRAMGB: 8}, "q8")
	if len(filteredQ8) != 0 {
		t.Fatalf("expected q8 model to be excluded for GPU fit, got %#v", filteredQ8)
	}
}

func TestFilterModelsByLocalOnly(t *testing.T) {
	models := []types.ModelSummary{
		{ModelID: "local-a", LocalModel: true},
		{ModelID: "api-a", LocalModel: false},
	}

	filtered := filterModelsByLocalOnly(models, true)
	if len(filtered) != 1 || filtered[0].ModelID != "local-a" {
		t.Fatalf("expected only local model, got %#v", filtered)
	}

	unfiltered := filterModelsByLocalOnly(models, false)
	if len(unfiltered) != 2 {
		t.Fatalf("expected all models when local_only is false, got %#v", unfiltered)
	}
}
