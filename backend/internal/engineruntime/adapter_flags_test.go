package engineruntime

import (
	"strings"
	"testing"
)

// serverHelpExcerpt mirrors the layout of `llama-server --help`: aliases before
// the long name, values after it, and prose that also contains dashes.
const serverHelpExcerpt = `
-ncmoe, --n-cpu-moe N                   keep the Mixture of Experts (MoE) weights of the first N layers in the CPU
-cmoe, --cpu-moe                        keep all Mixture of Experts (MoE) weights in the CPU
-ts,   --tensor-split N0,N1,N2,...      fraction of the model to offload to each GPU
       --swa-full                       use full-size SWA cache (default: false)
                                        [(more info)](https://github.com/ggml-org/llama.cpp/pull/13194)
       --spec-draft-n-max N             number of tokens to draft for speculative decoding (default: 3)
       --draft, --draft-n, --draft-max N  the argument has been removed. use --spec-draft-n-max
-ctk,  --cache-type-k TYPE              KV cache data type for K
                                        allowed values: f32, f16, bf16, q8_0, q4_0
`

func TestParseSupportedFlagsTakesFlagsAndNotProse(t *testing.T) {
	flags := ParseSupportedFlags(serverHelpExcerpt)
	present := map[string]bool{}
	for _, flag := range flags {
		present[flag] = true
	}
	for _, want := range []string{"--n-cpu-moe", "--cpu-moe", "--tensor-split", "--swa-full", "--spec-draft-n-max", "--cache-type-k"} {
		if !present[want] {
			t.Fatalf("%s was not recognised; got %v", want, flags)
		}
	}
	// The help text embeds a URL containing "--" and a bracketed link; neither
	// is a flag, and treating them as one would let a typo validate.
	for _, unwanted := range []string{"--(more", "--"} {
		if present[unwanted] {
			t.Fatalf("%q was mistaken for a flag: %v", unwanted, flags)
		}
	}
}

func TestValidateExtraArgsRefusesUnknownAndReservedFlags(t *testing.T) {
	capability := DefaultCapability(BuildCPU)
	capability.Flags = ParseSupportedFlags(serverHelpExcerpt)

	if err := ValidateExtraArgs(capability, []string{"--swa-full"}); err != nil {
		t.Fatalf("a flag the build lists must be accepted: %v", err)
	}
	// A value belonging to the flag before it is not itself checked.
	if err := ValidateExtraArgs(capability, []string{"--spec-draft-n-max", "5"}); err != nil {
		t.Fatalf("a flag value must not be validated as a flag: %v", err)
	}
	// --tensor-split has a first-class field, so passing it here would fight
	// the placement the planner budgeted for.
	if err := ValidateExtraArgs(capability, []string{"--tensor-split", "3,1"}); err == nil {
		t.Fatal("a flag with its own config field must be refused as an extra arg")
	}

	err := ValidateExtraArgs(capability, []string{"--swa-ful"})
	if err == nil || !strings.Contains(err.Error(), "--swa-ful") {
		t.Fatalf("a typo must be caught while the config is written, got %v", err)
	}
	// Passing a flag the engine sets itself would contradict the memory plan
	// the instance was admitted under.
	err = ValidateExtraArgs(capability, []string{"--ctx-size", "999999"})
	if err == nil || !strings.Contains(err.Error(), "--ctx-size") {
		t.Fatalf("an engine-owned flag must be refused, got %v", err)
	}
	// Without a flag list there is nothing to check against, and silently
	// accepting would defeat the point.
	capability.Flags = nil
	if err := ValidateExtraArgs(capability, []string{"--swa-full"}); err == nil {
		t.Fatal("extra args must not be accepted unchecked")
	}
	if err := ValidateExtraArgs(capability, nil); err != nil {
		t.Fatalf("no extra args is not an error: %v", err)
	}
}

func buildArgv(t *testing.T, mutate func(*RequestedConfig)) []string {
	t.Helper()
	requested := RequestedConfig{Runtime: RuntimeLlamaCPP, ModelPath: "/models/m.gguf"}
	mutate(&requested)
	capability := DefaultCapability(BuildCPU)
	capability.Flags = ParseSupportedFlags(serverHelpExcerpt)
	command, err := BuildAdapterCommand(capability, requested, AdapterPaths{Server: "/opt/llama-server"})
	if err != nil {
		t.Fatalf("BuildAdapterCommand: %v", err)
	}
	return command.Argv
}

func argvValue(argv []string, flag string) (string, bool) {
	for index, arg := range argv {
		if arg == flag {
			if index+1 < len(argv) {
				return argv[index+1], true
			}
			return "", true
		}
	}
	return "", false
}

func TestArgvCarriesTheMoESplitAndPlacementFlags(t *testing.T) {
	layers := 24
	argv := buildArgv(t, func(config *RequestedConfig) {
		config.CPUMoELayers = &layers
		config.TensorSplit = []float64{3, 1}
		config.MemoryLock = true
		config.DisableMmap = true
	})
	if value, ok := argvValue(argv, "--n-cpu-moe"); !ok || value != "24" {
		t.Fatalf("--n-cpu-moe %q ok=%v in %v", value, ok, argv)
	}
	if value, ok := argvValue(argv, "--tensor-split"); !ok || value != "3,1" {
		t.Fatalf("--tensor-split %q ok=%v", value, ok)
	}
	if _, ok := argvValue(argv, "--mlock"); !ok {
		t.Fatal("--mlock missing")
	}
	if _, ok := argvValue(argv, "--no-mmap"); !ok {
		t.Fatal("--no-mmap missing")
	}

	// A negative count means every expert layer, which the tool spells as its
	// own flag rather than as a number.
	every := -1
	argv = buildArgv(t, func(config *RequestedConfig) { config.CPUMoELayers = &every })
	if _, ok := argvValue(argv, "--cpu-moe"); !ok {
		t.Fatalf("a full MoE offload must use --cpu-moe: %v", argv)
	}
	if _, ok := argvValue(argv, "--n-cpu-moe"); ok {
		t.Fatalf("--cpu-moe and --n-cpu-moe must not both appear: %v", argv)
	}
}

func TestArgvUsesTheDraftFlagSpellingTheBuildReports(t *testing.T) {
	max := 5
	argv := buildArgv(t, func(config *RequestedConfig) {
		config.DraftModelPath = "/models/draft.gguf"
		config.DraftMaxTokens = &max
	})
	// This build lists --spec-draft-n-max and describes --draft-max as removed,
	// so the current spelling has to win.
	if value, ok := argvValue(argv, "--spec-draft-n-max"); !ok || value != "5" {
		t.Fatalf("expected the current draft flag, got %v", argv)
	}
	if _, ok := argvValue(argv, "--draft-max"); ok {
		t.Fatalf("the removed spelling must not be emitted: %v", argv)
	}
}

func TestExtendedConfigRejectsContradictions(t *testing.T) {
	capability := DefaultCapability(BuildCPU)
	capability.Flags = ParseSupportedFlags(serverHelpExcerpt)
	base := RequestedConfig{Runtime: RuntimeLlamaCPP, ModelPath: "/models/m.gguf"}

	cases := []struct {
		name   string
		mutate func(*RequestedConfig)
		expect string
	}{
		{"micro-batch above batch", func(c *RequestedConfig) {
			batch, micro := 256, 512
			c.BatchSize, c.UBatchSize = &batch, &micro
		}, "micro-batch"},
		{"embedding and reranking together", func(c *RequestedConfig) {
			c.Embeddings, c.Reranking = true, true
		}, "embedding or in reranking"},
		{"pooling without a pooled mode", func(c *RequestedConfig) {
			c.PoolingType = "mean"
		}, "pooling type only applies"},
		{"two chat templates", func(c *RequestedConfig) {
			c.ChatTemplate, c.ChatTemplateFile = "{{x}}", "/models/t.jinja"
		}, "inline or as a file"},
		{"draft options without a draft model", func(c *RequestedConfig) {
			max := 5
			c.DraftMaxTokens = &max
		}, "only applies together with a draft model"},
		{"lora path the command line cannot express", func(c *RequestedConfig) {
			c.LoRAAdapters = []LoRAAdapter{{Path: "/models/a,b.gguf"}}
		}, "comma or a colon"},
	}
	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			requested := base
			test.mutate(&requested)
			_, err := BuildAdapterCommand(capability, requested, AdapterPaths{Server: "/opt/llama-server"})
			if err == nil {
				t.Fatal("expected a refusal")
			}
			if !strings.Contains(err.Error(), test.expect) {
				t.Fatalf("error %q does not explain the problem (%q)", err, test.expect)
			}
		})
	}
}

func TestArgvKeepsExtraArgsLast(t *testing.T) {
	argv := buildArgv(t, func(config *RequestedConfig) {
		config.ExtraArgs = []string{"--swa-full"}
		config.Jinja = true
	})
	if argv[len(argv)-1] != "--swa-full" {
		t.Fatalf("extra args must come last so they can override: %v", argv)
	}
	if _, ok := argvValue(argv, "--jinja"); !ok {
		t.Fatalf("--jinja missing: %v", argv)
	}
}
