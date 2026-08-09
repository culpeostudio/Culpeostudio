package engineruntime

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"
)

func intPointer(value int) *int    { return &value }
func boolPointer(value bool) *bool { return &value }

const testServerPath = "/runtimes/vulkan/b10327/abc/llama-server"

func TestAdapterUsesFourBitKVWithoutWeightQuantization(t *testing.T) {
	capability := DefaultCapability(BuildVulkan)
	requested := RequestedConfig{
		Runtime:       RuntimeLlamaCPP,
		ModelPath:     "/models/name;still-one-argument.gguf",
		ContextLength: intPointer(8192),
		GPULayers:     intPointer(0),
		KVPolicy:      KVPolicyPrefer4Bit,
	}
	command, err := BuildAdapterCommand(capability, requested, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "q4_0" {
		t.Fatalf("KV cache = %q, want q4_0", command.Effective.KVCacheDType)
	}
	if command.Argv[0] != testServerPath {
		t.Fatalf("argv[0] = %q, want the installed llama-server", command.Argv[0])
	}
	assertArgPair(t, command.Argv, "--cache-type-k", "q4_0")
	assertArgPair(t, command.Argv, "--cache-type-v", "q4_0")
	// A quantised V cache only works with Flash Attention on; leaving it at
	// "auto" would silently give a bigger cache than the planner budgeted for.
	assertArgPair(t, command.Argv, "--flash-attn", "on")
	assertArgPair(t, command.Argv, "--ctx-size", "8192")
	assertArgPair(t, command.Argv, "--n-gpu-layers", "0")
	assertArgPair(t, command.Argv, "--api-key", command.InternalAPIKey)
	assertArgPair(t, command.Argv, "--alias", InstancePlaceholder)
	assertArgPair(t, command.Argv, "--host", "127.0.0.1")
	assertArgPair(t, command.Argv, "--port", PortPlaceholder)
	if len(command.InternalAPIKey) != 64 || command.HealthHeaders["Authorization"] != "Bearer "+command.InternalAPIKey {
		t.Fatal("internal worker credential was not wired safely")
	}
	if command.HealthPath != "/health" {
		t.Fatalf("health path = %q, want llama-server's /health", command.HealthPath)
	}
	if !containsExact(command.Argv, requested.ModelPath) {
		t.Fatalf("model path was not preserved as one argv item: %#v", command.Argv)
	}
	assertNoWeightQuantization(t, command.Argv)

	processSpec := command.ProcessSpec("my-instance")
	assertArgPair(t, processSpec.Argv, "--alias", "my-instance")
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

func TestAdapterCanonicalizesCacheAliases(t *testing.T) {
	for alias, want := range map[string]string{
		"q4":                 "q4_0",
		"q4_0":               "q4_0",
		"quanto_4bit":        "q4_0",
		"turboquant_4bit_nc": "q4_0",
		"native":             "f16",
		"auto":               "f16",
		"offloaded":          "f16",
		"fp16":               "f16",
		// llama.cpp has no fp8 cache; q8_0 is the nearest type it does have.
		"fp8":  "q8_0",
		"q8_0": "q8_0",
	} {
		requestedCache := alias
		command, err := BuildAdapterCommand(
			DefaultCapability(BuildCPU),
			RequestedConfig{Runtime: RuntimeLlamaCPP, ModelPath: "/models/test.gguf", KVCacheDType: &requestedCache},
			AdapterPaths{Server: testServerPath},
		)
		if err != nil {
			t.Fatalf("%s: %v", alias, err)
		}
		if command.Effective.KVCacheDType != want {
			t.Fatalf("%s resolved to %q, want %q", alias, command.Effective.KVCacheDType, want)
		}
		if len(command.Effective.Fallbacks) != 0 {
			t.Fatalf("%s: an alias must not register a fallback: %#v", alias, command.Effective.Fallbacks)
		}
	}
}

func TestAdapterOnlyEmitsCacheTypesLlamaServerAccepts(t *testing.T) {
	// Verified against llama-server b10327, which rejects anything else with
	// "Unsupported cache type" before it even binds its port.
	want := []string{"q4_0", "q4_1", "iq4_nl", "q5_0", "q5_1", "q8_0", "f16", "bf16", "f32"}
	if !reflect.DeepEqual(SupportedCacheTypes(), want) {
		t.Fatalf("supported cache types = %#v, want %#v", SupportedCacheTypes(), want)
	}
	if containsExact(SupportedCacheTypes(), "q2_k") {
		t.Fatal("upstream llama.cpp has no q2_k KV cache; it must not be offered")
	}
}

func TestAdapterFallsBackDownTheQuantisedLadder(t *testing.T) {
	capability := DefaultCapability(BuildCPU)
	capability.KVCaches = []string{"q8_0", "f16"}
	command, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:   RuntimeLlamaCPP,
		ModelPath: "/models/test.gguf",
		KVPolicy:  KVPolicyPrefer4Bit,
	}, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "q8_0" || len(command.Effective.Fallbacks) != 1 {
		t.Fatalf("unexpected effective config: %#v", command.Effective)
	}
	if fallback := command.Effective.Fallbacks[0]; fallback.From != "q4_0" || fallback.To != "q8_0" {
		t.Fatalf("fallback = %#v, want q4_0 to q8_0", fallback)
	}
	assertArgPair(t, command.Argv, "--cache-type-k", "q8_0")
}

func TestAdapterHonorsDisabledFallback(t *testing.T) {
	capability := DefaultCapability(BuildCPU)
	capability.KVCaches = []string{"f16"}
	_, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:       RuntimeLlamaCPP,
		ModelPath:     "/models/test.gguf",
		KVPolicy:      KVPolicyPrefer4Bit,
		AllowFallback: boolPointer(false),
	}, AdapterPaths{Server: testServerPath})
	if err == nil || !strings.Contains(err.Error(), "fallback is disabled") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestExplicitZeroIsNotTreatedAsAuto(t *testing.T) {
	capability := DefaultCapability(BuildCPU)
	capability.KVCaches = []string{"f16"}
	command, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime:       RuntimeLlamaCPP,
		ModelPath:     "/model.gguf",
		KVPolicy:      KVPolicyNative,
		ContextLength: intPointer(0),
	}, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	// Zero means "take the context the model declares", which is a real choice
	// and must reach the binary rather than being dropped as unset.
	assertArgPair(t, command.Argv, "--ctx-size", "0")
	assertArgPair(t, command.Argv, "--cache-type-k", "f16")
	// An unquantised cache does not need Flash Attention, so the decision is
	// left to the server rather than forced on.
	assertArgPair(t, command.Argv, "--flash-attn", "auto")
}

func TestFlashAttentionIsConfigurableButNotContradictable(t *testing.T) {
	base := RequestedConfig{Runtime: RuntimeLlamaCPP, ModelPath: "/model.gguf"}

	off := base
	off.KVPolicy = KVPolicyNative
	off.FlashAttention = "off"
	command, err := BuildAdapterCommand(DefaultCapability(BuildCPU), off, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	assertArgPair(t, command.Argv, "--flash-attn", "off")

	forced := base
	forced.FlashAttention = "on"
	if command, err = BuildAdapterCommand(DefaultCapability(BuildCPU), forced, AdapterPaths{Server: testServerPath}); err != nil {
		t.Fatal(err)
	}
	assertArgPair(t, command.Argv, "--flash-attn", "on")

	// Turning it off under a quantised cache would silently give a cache far
	// larger than the planner budgeted for, so it is refused outright.
	contradiction := base
	contradiction.KVPolicy = KVPolicyPrefer4Bit
	contradiction.FlashAttention = "off"
	if _, err := BuildAdapterCommand(DefaultCapability(BuildCPU), contradiction, AdapterPaths{Server: testServerPath}); err == nil {
		t.Fatal("a quantised cache with flash attention off was accepted")
	}

	invalid := base
	invalid.FlashAttention = "sometimes"
	if _, err := BuildAdapterCommand(DefaultCapability(BuildCPU), invalid, AdapterPaths{Server: testServerPath}); err == nil {
		t.Fatal("an unknown flash attention setting was accepted")
	}
}

func TestCacheFallbackOnlyEverWalksToLargerTypes(t *testing.T) {
	// A build that reports sub-4-bit caches can use them.
	capability := DefaultCapability(BuildCPU)
	capability.KVCaches = []string{"q2_k", "q3_k", "q4_0", "f16"}
	wanted := "q2_k"
	command, err := BuildAdapterCommand(capability, RequestedConfig{
		Runtime: RuntimeLlamaCPP, ModelPath: "/model.gguf", KVCacheDType: &wanted,
	}, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "q2_k" {
		t.Fatalf("cache = %q, want q2_k on a build that reports it", command.Effective.KVCacheDType)
	}

	// On a build without it, the fallback must climb, never drop: a smaller
	// cache than planned would be silently wrong in the safe-looking direction.
	upstream := DefaultCapability(BuildCPU)
	command, err = BuildAdapterCommand(upstream, RequestedConfig{
		Runtime: RuntimeLlamaCPP, ModelPath: "/model.gguf", KVCacheDType: &wanted,
	}, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	if command.Effective.KVCacheDType != "q4_0" {
		t.Fatalf("q2_k on an upstream build resolved to %q, want the next larger q4_0", command.Effective.KVCacheDType)
	}
	if len(command.Effective.Fallbacks) != 1 || command.Effective.Fallbacks[0].From != "q2_k" {
		t.Fatalf("fallback = %#v", command.Effective.Fallbacks)
	}
}

func TestAdapterEmitsMultiGPUPlacement(t *testing.T) {
	command, err := BuildAdapterCommand(DefaultCapability(BuildCUDA), RequestedConfig{
		Runtime:      RuntimeLlamaCPP,
		ModelPath:    "/models/test.gguf",
		SplitMode:    "row",
		MainGPU:      intPointer(1),
		MaxSequences: intPointer(4),
		Threads:      intPointer(8),
	}, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	assertArgPair(t, command.Argv, "--split-mode", "row")
	assertArgPair(t, command.Argv, "--main-gpu", "1")
	assertArgPair(t, command.Argv, "--parallel", "4")
	assertArgPair(t, command.Argv, "--threads", "8")
	if command.Effective.Variant != BuildCUDA {
		t.Fatalf("effective variant = %q, want cuda", command.Effective.Variant)
	}
}

func TestAdapterRejectsInvalidInput(t *testing.T) {
	for name, requested := range map[string]RequestedConfig{
		"missing model path":  {Runtime: RuntimeLlamaCPP},
		"negative context":    {Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf", ContextLength: intPointer(-1)},
		"negative sequences":  {Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf", MaxSequences: intPointer(-1)},
		"negative main gpu":   {Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf", MainGPU: intPointer(-1)},
		"zero memory limit":   {Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf", GPUMemoryBytes: []int64{0}},
		"unknown split mode":  {Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf", SplitMode: "tensor-parallel"},
		"retired runtime":     {Runtime: RuntimeKind("vllm"), ModelPath: "/m.gguf"},
		"zero cpu mem limit":  {Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf", CPUMemoryBytes: int64Pointer(0)},
		"empty cache request": {Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf", KVCacheDType: stringPointer("")},
	} {
		if _, err := BuildAdapterCommand(DefaultCapability(BuildCPU), requested, AdapterPaths{Server: testServerPath}); err == nil {
			t.Fatalf("%s was accepted: %#v", name, requested)
		}
	}
	if _, err := BuildAdapterCommand(DefaultCapability(BuildCPU), RequestedConfig{
		Runtime: RuntimeLlamaCPP, ModelPath: "/m.gguf",
	}, AdapterPaths{}); err == nil {
		t.Fatal("a missing llama-server path was accepted")
	}
}

func TestEffectiveConfigDoesNotAliasRequestedSlices(t *testing.T) {
	limits := []int64{6 << 30, 3 << 30}
	command, err := BuildAdapterCommand(DefaultCapability(BuildCPU), RequestedConfig{
		Runtime: RuntimeLlamaCPP, ModelPath: "/models/test.gguf", GPUMemoryBytes: limits,
	}, AdapterPaths{Server: testServerPath})
	if err != nil {
		t.Fatal(err)
	}
	limits[0] = 1
	if command.Effective.GPUMemoryBytes[0] != 6<<30 {
		t.Fatal("effective GPU memory limits alias the requested slice")
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
		if value == wanted {
			return true
		}
	}
	return false
}

func int64Pointer(value int64) *int64    { return &value }
func stringPointer(value string) *string { return &value }

func assertNoWeightQuantization(t *testing.T, argv []string) {
	t.Helper()
	joined := strings.ToLower(strings.Join(argv, " "))
	for _, forbidden := range []string{"--quantization", "load-in-4bit", "load_in_4bit", "bitsandbytes"} {
		if strings.Contains(joined, forbidden) {
			t.Fatalf("weight quantization argument %q found in %#v", forbidden, argv)
		}
	}
}
