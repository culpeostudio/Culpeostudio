package engineruntime

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"
)

func intPointer(value int) *int    { return &value }
func boolPointer(value bool) *bool { return &value }

func TestLlamaCPPAdapterUsesFourBitKVWithoutWeightQuantization(t *testing.T) {
	capability := DefaultCapability(RuntimeLlamaCPP)
	capability.KVCaches = []string{"q4_0", "f16"}
	requested := RequestedConfig{
		Runtime:       RuntimeLlamaCPP,
		ModelPath:     "/models/name;still-one-argument.gguf",
		ContextLength: intPointer(8192),
		GPULayers:     intPointer(0),
		KVPolicy:      KVPolicyPrefer4Bit,
	}
	command, err := BuildAdapterCommand(capability, requested, AdapterPaths{Python: "/env/bin/python"})
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "q4_0" {
		t.Fatalf("KV cache = %q", command.Effective.KVCacheDType)
	}
	assertArgPair(t, command.Argv, "--type_k", "2")
	assertArgPair(t, command.Argv, "--type_v", "2")
	assertArgPair(t, command.Argv, "--flash_attn", "True")
	if containsExact(command.Argv, "--cache_type_k") || containsExact(command.Argv, "--cache_type_v") {
		t.Fatalf("llama-cpp-python 0.3.33 rejects legacy cache flags: %#v", command.Argv)
	}
	assertArgPair(t, command.Argv, "--n_gpu_layers", "0")
	assertArgPair(t, command.Argv, "--api_key", command.InternalAPIKey)
	assertArgPair(t, command.Argv, "--model_alias", InstancePlaceholder)
	if len(command.InternalAPIKey) != 64 || command.HealthHeaders["Authorization"] != "Bearer "+command.InternalAPIKey {
		t.Fatalf("internal worker credential was not wired safely")
	}
	if command.HealthPath != "/v1/models" {
		t.Fatalf("llama.cpp health path = %q, want its available OpenAI model endpoint", command.HealthPath)
	}
	if !containsExact(command.Argv, requested.ModelPath) {
		t.Fatalf("model path was not preserved as one argv item: %#v", command.Argv)
	}
	assertNoWeightQuantization(t, command.Argv)
	processSpec := command.ProcessSpec("my-instance")
	assertArgPair(t, processSpec.Argv, "--model_alias", "my-instance")
	if processSpec.HealthHeaders["Authorization"] != "Bearer "+command.InternalAPIKey {
		t.Fatal("process health check did not receive the internal bearer credential")
	}
	serializedCommand, err := json.Marshal(command)
	if err != nil {
		t.Fatal(err)
	}
	serializedSpec, err := json.Marshal(processSpec)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(serializedCommand), command.InternalAPIKey) || strings.Contains(string(serializedSpec), command.InternalAPIKey) {
		t.Fatal("internal worker credential leaked through JSON serialization")
	}
}

func TestLlamaCPPAdapterCanonicalizesPlannerQ4Alias(t *testing.T) {
	requestedCache := "q4"
	command, err := BuildAdapterCommand(
		DefaultCapability(RuntimeLlamaCPP),
		RequestedConfig{
			Runtime:      RuntimeLlamaCPP,
			ModelPath:    "/models/test.gguf",
			KVCacheDType: &requestedCache,
		},
		AdapterPaths{Python: "/env/bin/python"},
	)
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "q4_0" {
		t.Fatalf("q4 alias resolved to %q, want q4_0", command.Effective.KVCacheDType)
	}
	if len(command.Effective.Fallbacks) != 0 {
		t.Fatalf("q4 alias must not trigger an f16 fallback: %#v", command.Effective.Fallbacks)
	}
}

func TestVLLMAdapterCanonicalizesLegacyQ4AliasToTurboQuant(t *testing.T) {
	requestedCache := "q4_0"
	command, err := BuildAdapterCommand(
		DefaultCapability(RuntimeVLLM),
		RequestedConfig{
			Runtime:      RuntimeVLLM,
			ModelPath:    "/models/test",
			KVPolicy:     KVPolicyPrefer4Bit,
			KVCacheDType: &requestedCache,
		},
		AdapterPaths{Python: "/env/bin/python"},
	)
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "turboquant_4bit_nc" {
		t.Fatalf("legacy q4_0 resolved to %q, want TurboQuant", command.Effective.KVCacheDType)
	}
	if len(command.Effective.Fallbacks) != 0 {
		t.Fatalf("legacy 4-bit alias must not trigger a native-cache fallback: %#v", command.Effective.Fallbacks)
	}
	assertArgPair(t, command.Argv, "--kv-cache-dtype", "turboquant_4bit_nc")
	assertNoWeightQuantization(t, command.Argv)
}

func TestTransformersAdapterCanonicalizesLegacyQ4AliasToQuanto(t *testing.T) {
	requestedCache := "q4_0"
	command, err := BuildAdapterCommand(
		DefaultCapability(RuntimeTransformers),
		RequestedConfig{
			Runtime:      RuntimeTransformers,
			ModelPath:    "/models/test",
			KVPolicy:     KVPolicyPrefer4Bit,
			KVCacheDType: &requestedCache,
		},
		AdapterPaths{Python: "/env/bin/python", TransformersWorker: "/app/transformers_worker.py"},
	)
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "quanto_4bit" {
		t.Fatalf("legacy q4_0 resolved to %q, want Quanto 4-bit", command.Effective.KVCacheDType)
	}
	if len(command.Effective.Fallbacks) != 0 {
		t.Fatalf("legacy 4-bit alias must not trigger a native-cache fallback: %#v", command.Effective.Fallbacks)
	}
	assertArgPair(t, command.Argv, "--kv-cache", "quanto_4bit")
	assertNoWeightQuantization(t, command.Argv)
}

func TestVLLMAdapterFallsBackFromTurboQuantToFP8(t *testing.T) {
	capability := DefaultCapability(RuntimeVLLM)
	capability.KVCaches = []string{"fp8", "auto"}
	command, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:   RuntimeVLLM,
		ModelPath: "/models/safetensors",
		KVPolicy:  KVPolicyPrefer4Bit,
	}, AdapterPaths{Python: "/env/bin/python"})
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "fp8" || len(command.Effective.Fallbacks) != 1 {
		t.Fatalf("unexpected effective config: %#v", command.Effective)
	}
	assertArgPair(t, command.Argv, "--kv-cache-dtype", "fp8")
	assertArgPair(t, command.Argv, "--api-key", command.InternalAPIKey)
	assertArgPair(t, command.Argv, "--served-model-name", InstancePlaceholder)
	if command.HealthPath != "/v1/models" {
		t.Fatalf("vLLM health path = %q", command.HealthPath)
	}
	assertNoWeightQuantization(t, command.Argv)
}

func TestExplicitTurboQuantFallsBackInBackendOrder(t *testing.T) {
	capability := DefaultCapability(RuntimeVLLM)
	capability.KVCaches = []string{"fp8", "auto"}
	requestedCache := "turboquant_4bit_nc"
	command, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:      RuntimeVLLM,
		ModelPath:    "/models/safetensors",
		KVCacheDType: &requestedCache,
	}, AdapterPaths{Python: "/env/bin/python"})
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "fp8" {
		t.Fatalf("explicit TurboQuant fallback = %q, want fp8", command.Effective.KVCacheDType)
	}
}

func TestAdapterHonorsDisabledFallback(t *testing.T) {
	capability := DefaultCapability(RuntimeVLLM)
	capability.KVCaches = []string{"auto"}
	_, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:       RuntimeVLLM,
		ModelPath:     "/models/safetensors",
		KVPolicy:      KVPolicyPrefer4Bit,
		AllowFallback: boolPointer(false),
	}, AdapterPaths{Python: "/env/bin/python"})
	if err == nil || !strings.Contains(err.Error(), "fallback is disabled") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestTransformersAdapterTrustRemoteCodeIsOptIn(t *testing.T) {
	capability := DefaultCapability(RuntimeTransformers)
	capability.KVCaches = []string{"native"}
	paths := AdapterPaths{Python: "/env/bin/python", TransformersWorker: "/app/engineworker/transformers_worker.py"}
	command, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:      RuntimeTransformers,
		ModelPath:    "/models/safetensors",
		KVPolicy:     KVPolicyNative,
		MaxSequences: intPointer(1),
	}, paths)
	if err != nil {
		t.Fatal(err)
	}
	if containsExact(command.Argv, "--trust-remote-code") {
		t.Fatal("trust_remote_code must default to disabled")
	}
	if command.HealthPath != "/health" {
		t.Fatalf("transformers health path = %q", command.HealthPath)
	}
	assertArgPair(t, command.Argv, "--max-sequences", "1")
	assertNoWeightQuantization(t, command.Argv)
}

func TestTransformersAdapterEmitsPlannedPerDeviceMemoryLimits(t *testing.T) {
	limits := []int64{6 << 30, 3 << 30}
	command, err := BuildAdapterCommand(DefaultCapability(RuntimeTransformers), RequestedConfig{
		Runtime: RuntimeTransformers, ModelPath: "/models/safetensors", GPUMemoryBytes: limits,
	}, AdapterPaths{Python: "/env/bin/python", TransformersWorker: "/app/engineworker/transformers_worker.py"})
	if err != nil {
		t.Fatal(err)
	}
	if got := argValues(command.Argv, "--gpu-max-memory-bytes"); !reflect.DeepEqual(got, []string{"6442450944", "3221225472"}) {
		t.Fatalf("Transformers GPU memory argv = %#v", got)
	}
	limits[0] = 1
	if command.Effective.GPUMemoryBytes[0] != 6<<30 {
		t.Fatal("effective GPU memory limits alias the requested slice")
	}
}

func TestExplicitZeroIsNotTreatedAsAuto(t *testing.T) {
	capability := DefaultCapability(RuntimeLlamaCPP)
	capability.KVCaches = []string{"f16"}
	command, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:       RuntimeLlamaCPP,
		ModelPath:     "/model.gguf",
		KVPolicy:      KVPolicyNative,
		ContextLength: intPointer(0),
	}, AdapterPaths{Python: "/python"})
	if err != nil {
		t.Fatal(err)
	}
	assertArgPair(t, command.Argv, "--n_ctx", "0")
	assertArgPair(t, command.Argv, "--type_k", "1")
	assertArgPair(t, command.Argv, "--type_v", "1")
	if containsExact(command.Argv, "--flash_attn") {
		t.Fatalf("native F16 cache must not force flash attention: %#v", command.Argv)
	}
}

func TestVLLMEmitsExplicitWeightCPUOffload(t *testing.T) {
	offload := 3.5
	command, err := BuildAdapterCommand(DefaultCapability(RuntimeVLLM), RequestedConfig{
		Runtime: RuntimeVLLM, ModelPath: "/models/model", CPUOffloadGB: &offload,
	}, AdapterPaths{Python: "/venv/python"})
	if err != nil {
		t.Fatal(err)
	}
	assertArgPair(t, command.Argv, "--cpu-offload-gb", "3.500")
}

func TestVLLMEmitsConservativePlannedMemoryUtilization(t *testing.T) {
	utilization := 0.625
	command, err := BuildAdapterCommand(DefaultCapability(RuntimeVLLM), RequestedConfig{
		Runtime: RuntimeVLLM, ModelPath: "/models/model", GPUMemoryUtilization: &utilization,
	}, AdapterPaths{Python: "/venv/python"})
	if err != nil {
		t.Fatal(err)
	}
	assertArgPair(t, command.Argv, "--gpu-memory-utilization", "0.625000")
}

func TestAdapterRejectsInvalidRuntimeMemoryLimits(t *testing.T) {
	for _, requested := range []RequestedConfig{
		{Runtime: RuntimeTransformers, ModelPath: "/model", GPUMemoryBytes: []int64{0}},
		{Runtime: RuntimeVLLM, ModelPath: "/model", GPUMemoryUtilization: floatPointer(1.01)},
	} {
		paths := AdapterPaths{Python: "/python", TransformersWorker: "/worker.py"}
		if _, err := BuildAdapterCommand(DefaultCapability(requested.Runtime), requested, paths); err == nil {
			t.Fatalf("invalid runtime memory limit was accepted: %#v", requested)
		}
	}
}

func assertArgPair(t *testing.T, argv []string, key, value string) {
	t.Helper()
	for index := 0; index+1 < len(argv); index++ {
		if argv[index] == key && argv[index+1] == value {
			return
		}
	}
	t.Fatalf("argv does not contain %s %s: %#v", key, value, argv)
}

func containsExact(values []string, wanted string) bool {
	for _, value := range values {
		if reflect.DeepEqual(value, wanted) {
			return true
		}
	}
	return false
}

func argValues(argv []string, key string) []string {
	result := []string{}
	for index := 0; index+1 < len(argv); index++ {
		if argv[index] == key {
			result = append(result, argv[index+1])
		}
	}
	return result
}

func floatPointer(value float64) *float64 { return &value }

func assertNoWeightQuantization(t *testing.T, argv []string) {
	t.Helper()
	joined := strings.ToLower(strings.Join(argv, " "))
	for _, forbidden := range []string{"--quantization", "load-in-4bit", "load_in_4bit", "bitsandbytes"} {
		if strings.Contains(joined, forbidden) {
			t.Fatalf("weight quantization argument %q found in %#v", forbidden, argv)
		}
	}
}
