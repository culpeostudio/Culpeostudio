package engine

import (
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
)

func TestSuggestedFixForCode(t *testing.T) {
	fix := suggestedFixForCode("gpu_out_of_memory")
	if fix == nil || fix.Action != engineruntime.FixReduceContext || fix.Label == "" {
		t.Fatalf("gpu_out_of_memory should suggest reduce_context, got %+v", fix)
	}
	fix = suggestedFixForCode("resource_guard_rejected")
	if fix == nil || fix.Action != engineruntime.FixReduceContext {
		t.Fatalf("resource_guard_rejected should suggest reduce_context, got %+v", fix)
	}
	fix = suggestedFixForCode("gpu_driver_mismatch")
	if fix == nil || fix.Action != engineruntime.FixRetryOnCPU {
		t.Fatalf("gpu_driver_mismatch should suggest retry_on_cpu, got %+v", fix)
	}
	fix = suggestedFixForCode("gpu_runtime_unavailable")
	if fix == nil || fix.Action != engineruntime.FixReinstallRuntime {
		t.Fatalf("gpu_runtime_unavailable should suggest reinstall_runtime, got %+v", fix)
	}
	fix = suggestedFixForCode("resource_conflict")
	if fix == nil || fix.Action != fixRetryWithRAM {
		t.Fatalf("resource_conflict should suggest retry_with_ram, got %+v", fix)
	}
	if fix := suggestedFixForCode(""); fix != nil {
		t.Fatalf("empty code must not suggest a fix, got %+v", fix)
	}
	if fix := suggestedFixForCode("operation_cancelled"); fix != nil {
		t.Fatalf("cancellation must not suggest a fix, got %+v", fix)
	}
}

func TestClassifyGPURuntimeUnavailableWithoutMemoryConflict(t *testing.T) {
	err := &gpuRuntimeUnavailableError{
		Reason:      "Vulkan-Funktionstest fehlgeschlagen",
		Remediation: "rebuild_gpu_runtime",
	}
	code, summary := classifyEngineError(err)
	if code != "gpu_runtime_unavailable" || summary == "" {
		t.Fatalf("classification = %q / %q", code, summary)
	}
}

func TestClassifyPlannerConflictWithoutLeakingInternalMessage(t *testing.T) {
	err := fmt.Errorf("Hardwarebudget hat sich geaendert: %w", &engineplanner.ConflictError{
		InstanceID: "target",
		Resource:   "memory",
		Reason:     "minimum context 4096 cannot fit; maximum is 0",
	})
	code, summary := classifyEngineError(err)
	if code != "resource_conflict" {
		t.Fatalf("classification code = %q, want resource_conflict", code)
	}
	if summary == "" || strings.Contains(strings.ToLower(summary), "engine plan conflict") {
		t.Fatalf("classification leaked internal planner message: %q", summary)
	}
}

func TestClassifyLoadPeakConflictAsRAMRetry(t *testing.T) {
	cause := &ResourceConflictError{
		Resource: "gpu:test", RequiredBytes: 15 << 30, AvailableBytes: 14 << 30,
		Reason: "konservativer Lade-Peak unterschreitet die Reserve",
	}
	code, summary := classifyEngineError(fmt.Errorf("Ressourcenwaechter: %w", cause))
	if code != "resource_conflict" || summary == "" {
		t.Fatalf("load-peak classification = %q / %q", code, summary)
	}
	fix := suggestedFixForCode(code)
	if fix == nil || fix.Action != fixRetryWithRAM {
		t.Fatalf("load-peak conflict should request a RAM replan, got %+v", fix)
	}

	code, _ = classifyEngineError(errors.New(cause.Error()))
	if code != "resource_conflict" {
		t.Fatalf("persisted load-peak classification = %q", code)
	}
}

func TestConfigForFixReduceContext(t *testing.T) {
	module := &EngineModule{}
	plan := ContextPlanView{EffectiveContextTokens: 8192}
	instance := &EngineInstance{
		RequestedConfig: defaultEngineConfig(),
		EffectiveConfig: defaultEngineConfig(),
		Plan:            &plan,
	}
	config, err := module.configForFix(instance, engineruntime.FixReduceContext)
	if err != nil {
		t.Fatal(err)
	}
	if config.ContextMode != "fixed" || config.ContextTokens == nil || *config.ContextTokens != 4096 {
		t.Fatalf("expected fixed 4096 context, got mode=%q tokens=%v", config.ContextMode, config.ContextTokens)
	}

	plan.EffectiveContextTokens = 3000
	instance.Plan = &plan
	config, err = module.configForFix(instance, engineruntime.FixReduceContext)
	if err != nil {
		t.Fatal(err)
	}
	if *config.ContextTokens != 2048 {
		t.Fatalf("expected floor of 2048, got %d", *config.ContextTokens)
	}
}

func TestConfigForFixRetryOnCPU(t *testing.T) {
	module := &EngineModule{}
	instance := &EngineInstance{RequestedConfig: defaultEngineConfig(), EffectiveConfig: defaultEngineConfig()}
	config, err := module.configForFix(instance, engineruntime.FixRetryOnCPU)
	if err != nil {
		t.Fatal(err)
	}
	if config.RuntimeOptions["offload"] != "cpu" {
		t.Fatalf("expected offload=cpu, got %v", config.RuntimeOptions["offload"])
	}
	if config.RuntimeOptions["gpu_layers"] != 0 {
		t.Fatalf("expected gpu_layers=0, got %v", config.RuntimeOptions["gpu_layers"])
	}
	if config.RuntimeOptions["allow_ram_offload"] != true || !ramOffloadAllowed(config) {
		t.Fatalf("CPU retry did not explicitly permit its RAM placement: %#v", config.RuntimeOptions)
	}
}

func TestConfigForFixRetryWithRAMRequiresExplicitFlag(t *testing.T) {
	module := &EngineModule{}
	instance := &EngineInstance{RequestedConfig: defaultEngineConfig(), EffectiveConfig: defaultEngineConfig()}
	config, err := module.configForFix(instance, fixRetryWithRAM)
	if err != nil {
		t.Fatal(err)
	}
	if config.RuntimeOptions["allow_ram_offload"] != true {
		t.Fatalf("expected explicit RAM permission, got %#v", config.RuntimeOptions)
	}
}

func TestRAMOffloadIsDeniedUnlessExplicitlyAllowed(t *testing.T) {
	config := defaultEngineConfig()
	if ramOffloadAllowed(config) {
		t.Fatal("RAM offload was implicitly allowed")
	}
	config.RuntimeOptions["allow_ram_offload"] = true
	if !ramOffloadAllowed(config) {
		t.Fatal("explicit RAM offload permission was ignored")
	}
	config.RuntimeOptions = map[string]interface{}{"offload": "cpu", "allow_ram_offload": false}
	if !ramOffloadAllowed(config) {
		t.Fatal("an explicit CPU-only request was not treated as RAM consent")
	}
}

func TestRetryLlamaCPUPreservesLoadPeakConflictWithoutRAMConsent(t *testing.T) {
	module := &EngineModule{}
	config := defaultEngineConfig()
	cause := &ResourceConflictError{
		Resource: "gpu:test", RequiredBytes: 15 << 30, AvailableBytes: 14 << 30,
		Reason: "konservativer Lade-Peak unterschreitet die Reserve",
	}
	err := module.retryLlamaCPU(nil, "instance", config, ContextPlanView{}, "operation", cause)
	var preserved *ResourceConflictError
	if !errors.As(err, &preserved) {
		t.Fatalf("retry converted a capacity conflict into %T: %v", err, err)
	}
	code, _ := classifyEngineError(err)
	if code != "resource_conflict" {
		t.Fatalf("retry classification = %q, want resource_conflict", code)
	}
}

func TestForceCPURequestedRecognizesEveryExplicitCPUControl(t *testing.T) {
	tests := []struct {
		name    string
		options map[string]interface{}
	}{
		{name: "force flag", options: map[string]interface{}{"force_cpu_runtime": true}},
		{name: "offload mode", options: map[string]interface{}{"offload": "cpu"}},
		{name: "zero GPU layers", options: map[string]interface{}{"gpu_layers": 0}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			config := defaultEngineConfig()
			config.RuntimeOptions = test.options
			if !forceCPURequested(config) {
				t.Fatalf("explicit CPU config was not recognized: %#v", test.options)
			}
		})
	}
	config := defaultEngineConfig()
	config.RuntimeOptions = map[string]interface{}{"offload": "auto", "gpu_layers": -1}
	if forceCPURequested(config) {
		t.Fatalf("GPU config was misclassified as CPU: %#v", config.RuntimeOptions)
	}
}

func TestConfigForFixUnknownAction(t *testing.T) {
	module := &EngineModule{}
	instance := &EngineInstance{RequestedConfig: defaultEngineConfig()}
	if _, err := module.configForFix(instance, "format_disk"); err == nil {
		t.Fatal("unknown fix action must be rejected")
	}
}

func TestComputeReducedContextUsesExactDeficit(t *testing.T) {

	cause := &ResourceConflictError{
		Resource: "ram", RequiredBytes: 24 << 30, AvailableBytes: (24 << 30) - (64 << 20),
	}
	reduced := computeReducedContext(8192, 64<<10, cause)
	if reduced != 6912 {
		t.Fatalf("expected mathematically derived 6912 tokens, got %d", reduced)
	}
}

func TestComputeReducedContextFallsBackToHalving(t *testing.T) {

	reduced := computeReducedContext(8192, 64<<10, errors.New("[ram_out_of_memory] Der Arbeitsspeicher hat nicht ausgereicht"))
	if reduced != 4096 {
		t.Fatalf("expected halving to 4096, got %d", reduced)
	}

	cause := &ResourceConflictError{Resource: "ram", RequiredBytes: 40 << 30, AvailableBytes: 1 << 30}
	reduced = computeReducedContext(8192, 64<<10, cause)
	if reduced != 4096 {
		t.Fatalf("expected halving for huge deficit, got %d", reduced)
	}
}

func TestComputeReducedContextStopsAtFloor(t *testing.T) {
	if reduced := computeReducedContext(2048, 64<<10, errors.New("oom")); reduced != 0 {
		t.Fatalf("at the floor no further reduction must be offered, got %d", reduced)
	}
	if reduced := computeReducedContext(2304, 64<<10, errors.New("oom")); reduced != 2048 {
		t.Fatalf("just above floor should land on the floor, got %d", reduced)
	}
}

func TestContextSearchUsesVerifiedFloorInsteadOfBlindHalving(t *testing.T) {
	cause := errors.New("[ram_out_of_memory] worker exited while loading")
	reduced := nextContextAfterFailure(52581, 64<<10, cause, 27648, true)
	if reduced != 39936 {
		t.Fatalf("first bounded search step = %d, want 39936", reduced)
	}
	if reduced := nextContextAfterFailure(52581, 64<<10, cause, 27648, false); reduced != 26112 {
		t.Fatalf("ordinary fallback must keep halving, got %d", reduced)
	}
}

func TestContextSearchConvergesUpwardAfterSuccessfulProbe(t *testing.T) {
	if next := nextContextAfterSuccess(39936, 52581); next != 46080 {
		t.Fatalf("next upward probe = %d, want 46080", next)
	}
	if next := nextContextAfterSuccess(52480, 52581); next != 0 {
		t.Fatalf("search should stop within one 256-token step, got %d", next)
	}
	if next := nextContextAfterFailure(27900, 64<<10, errors.New("oom"), 27648, true); next != 27648 {
		t.Fatalf("a narrow failed interval must return to the verified floor, got %d", next)
	}
	if next := nextContextAfterFailure(27648, 64<<10, errors.New("oom"), 27648, true); next != 0 {
		t.Fatalf("a failed verified floor must abort the search for rollback, got %d", next)
	}
}

func TestContextSearchOptionsAreRemovedFromStableConfig(t *testing.T) {
	config := defaultEngineConfig()
	config.Runtime = "auto"
	config.KVCachePolicy = "prefer_4bit"
	config.RuntimeOptions["allow_ram_offload"] = true
	config.RuntimeOptions["offload"] = "auto"
	setContextSearchBounds(&config, 27648, 52581)
	if !contextSearchRequested(config) {
		t.Fatal("search marker was not enabled")
	}
	stable := stableContextRequest(config, 39936)
	if contextSearchRequested(stable) {
		t.Fatal("search marker remained in stable config")
	}
	for _, key := range []string{contextSearchModeOption, contextSearchFloorOption, contextSearchCeilingOption} {
		if _, exists := stable.RuntimeOptions[key]; exists {
			t.Fatalf("internal option %q leaked into stable config", key)
		}
	}
	if stable.ContextMode != "fixed" || stable.ContextTokens == nil || *stable.ContextTokens != 39936 {
		t.Fatalf("stable context was not persisted: %#v", stable)
	}
	if stable.Runtime != "auto" || stable.KVCachePolicy != "prefer_4bit" || stable.RuntimeOptions["offload"] != "auto" || stable.RuntimeOptions["allow_ram_offload"] != true {
		t.Fatalf("user runtime intent changed while persisting search result: %#v", stable)
	}
}

func TestIsMemoryExhaustionError(t *testing.T) {
	if !isMemoryExhaustionError(&ResourceConflictError{Resource: "ram", RequiredBytes: 2, AvailableBytes: 1}) {
		t.Fatal("guard conflict must count as memory exhaustion")
	}
	if !isMemoryExhaustionError(errors.New("[ram_out_of_memory] Der Arbeitsspeicher hat nicht ausgereicht")) {
		t.Fatal("marked ram oom must count")
	}
	if !isMemoryExhaustionError(errors.New("Mini-Inferenztest fehlgeschlagen: CUDA out of memory. Tried to allocate 2 GiB")) {
		t.Fatal("raw cuda oom text must count")
	}
	if isMemoryExhaustionError(errors.New("health check failed: timeout")) {
		t.Fatal("timeout must not count as memory exhaustion")
	}
}
