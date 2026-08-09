package engineruntime

import (
	"strings"
	"testing"
)

// quantizeHelpExcerpt is the shape llama-quantize b10327 prints. The three
// forms in the table are all represented: a size-and-perplexity entry, a
// bits-per-weight entry, and an alias.
const quantizeHelpExcerpt = `usage: ./llama-quantize [--help] [--allow-requantize] [--leave-output-tensor]
       model-f32.gguf [model-quant.gguf] type [nthreads]

  --allow-requantize
                                      allow requantizing tensors that have already been quantized
  --dry-run
                                      calculate and show the final quantization size without performing quantization

-----------------------------------------------------------------------------
 allowed quantization types
-----------------------------------------------------------------------------

  40  or  Q1_0    :  1.125 bpw quantization
   2  or  Q4_0    :  4.34G, +0.4685 ppl @ Llama-3-8B
  38  or  MXFP4_MOE :  MXFP4 MoE
  30  or  IQ4_XS  :  4.25 bpw non-linear quantization
  15  or  Q4_K    : alias for Q4_K_M
  14  or  Q4_K_S  :  4.37G, +0.2689 ppl @ Llama-3-8B
  15  or  Q4_K_M  :  4.58G, +0.1754 ppl @ Llama-3-8B
  18  or  Q6_K    :  6.14G, +0.0217 ppl @ Llama-3-8B
   1  or  F16     : 14.00G, +0.0020 ppl @ Mistral-7B
          COPY    : only copy tensors, no quantizing
`

func TestParseQuantizationTypesReadsEachTableForm(t *testing.T) {
	types := ParseQuantizationTypes(quantizeHelpExcerpt)
	byName := map[string]QuantizationType{}
	for _, entry := range types {
		byName[entry.Name] = entry
	}

	if _, exists := byName["COPY"]; exists {
		t.Fatal("COPY is not a quantisation and must not be offered as a target")
	}
	if len(types) != 9 {
		t.Fatalf("expected the nine listed types, got %d: %v", len(types), byName)
	}

	sized := byName["Q4_K_M"]
	if sized.SizeGiBAtReference != 4.58 || sized.PerplexityDelta != 0.1754 || sized.ReferenceModel != "Llama-3-8B" {
		t.Fatalf("Q4_K_M parsed as %+v", sized)
	}
	if bpw := byName["IQ4_XS"]; bpw.BitsPerWeight != 4.25 {
		t.Fatalf("IQ4_XS parsed as %+v", bpw)
	}
	if alias := byName["Q4_K"]; alias.Alias != "Q4_K_M" {
		t.Fatalf("Q4_K parsed as %+v", alias)
	}
	if plain := byName["MXFP4_MOE"]; plain.Description == "" {
		t.Fatalf("MXFP4_MOE lost its description: %+v", plain)
	}
	// A negative delta is the one sign the sign is being read rather than
	// dropped, which matters because F16 and BF16 report improvements.
	if f16 := byName["F16"]; f16.PerplexityDelta != 0.0020 {
		t.Fatalf("F16 parsed as %+v", f16)
	}
}

func TestParseQuantizeEstimateReadsSizesAndDetectsRequantization(t *testing.T) {
	output := `llama_model_loader: - type  f32:   49 tensors
llama_model_loader: - type q8_0:  170 tensors
[   1/ 219] output.weight - [1536, 130560, 1, 1], type = q8_0, size = 203.06 MiB -> 107.81 MiB (q4_K)
llama_model_quantize_impl: model size  =  1095.19 MiB (8.50 BPW)
llama_model_quantize_impl: quant size  =   651.29 MiB (5.06 BPW)
`
	estimate := ParseQuantizeEstimate(output)
	mib := float64(1 << 20)
	if wantSource := int64(1095.19 * mib); estimate.SourceBytes != wantSource {
		t.Fatalf("source bytes %d, want %d", estimate.SourceBytes, wantSource)
	}
	if wantTarget := int64(651.29 * mib); estimate.TargetBytes != wantTarget {
		t.Fatalf("target bytes %d, want %d", estimate.TargetBytes, wantTarget)
	}
	if estimate.SourceBitsPerWeight != 8.50 || estimate.TargetBitsPerWeight != 5.06 {
		t.Fatalf("bits per weight %v -> %v", estimate.SourceBitsPerWeight, estimate.TargetBitsPerWeight)
	}
	if !estimate.RequiresRequantizeOptIn {
		t.Fatal("a q8_0 source is already quantised and must require the opt-in")
	}
}

func TestParseQuantizeEstimateLeavesUnquantizedSourceAlone(t *testing.T) {
	output := `llama_model_loader: - type  f32:   49 tensors
llama_model_loader: - type  f16:  170 tensors
llama_model_quantize_impl: model size  =  14000.00 MiB (16.00 BPW)
llama_model_quantize_impl: quant size  =   4580.00 MiB (4.58 BPW)
`
	if ParseQuantizeEstimate(output).RequiresRequantizeOptIn {
		t.Fatal("an f16 source is the normal case and needs no opt-in")
	}
}

func TestDetectQuantizeFailureRecognisesTheRequantizeRefusal(t *testing.T) {
	// llama-quantize reports this on its output and still exits zero, which is
	// why the text has to be inspected rather than only the status.
	output := `[   1/ 219] output.weight - [1536, 130560, 1, 1], type = q8_0, llama_model_quantize: failed to quantize: requantizing from type q8_0 is disabled
llama_quantize: failed to quantize model from 'model.gguf'
`
	summary := detectQuantizeFailure(output)
	if summary == "" {
		t.Fatal("a refused requantisation must be reported as a failure")
	}
	if !strings.Contains(summary, "bereits quantisiert") {
		t.Fatalf("the refusal should be explained in terms the user can act on, got %q", summary)
	}
}

func TestQuantizeArgvOrdersOperandsTheWayTheToolExpects(t *testing.T) {
	request := QuantizeRequest{
		QuantizePath: "/opt/llama/llama-quantize",
		SourcePath:   "/models/source.gguf",
		TargetPath:   "/models/target.gguf",
		TargetType:   "Q4_K_M",
		Threads:      8,
	}
	argv := request.argv()
	// The tool takes its operands positionally: source, target, type, threads.
	want := []string{"/opt/llama/llama-quantize", "/models/source.gguf", "/models/target.gguf", "Q4_K_M", "8"}
	if len(argv) != len(want) {
		t.Fatalf("argv %v", argv)
	}
	for index := range want {
		if argv[index] != want[index] {
			t.Fatalf("argv[%d] = %q, want %q (full: %v)", index, argv[index], want[index], argv)
		}
	}

	request.AllowRequantize = true
	request.LeaveOutputTensor = true
	argv = request.argv()
	if argv[1] != "--allow-requantize" || argv[2] != "--leave-output-tensor" {
		t.Fatalf("flags must precede the operands, got %v", argv)
	}

	// A dry run takes no destination at all; passing one makes the tool treat
	// it as the type.
	request = QuantizeRequest{QuantizePath: "q", SourcePath: "s.gguf", TargetPath: "t.gguf", TargetType: "Q4_K_M", DryRun: true, Threads: 8}
	argv = request.argv()
	for _, arg := range argv {
		if arg == "t.gguf" {
			t.Fatalf("a dry run must not name a target file: %v", argv)
		}
		if arg == "8" {
			t.Fatalf("a dry run takes no thread count: %v", argv)
		}
	}
	if argv[len(argv)-1] != "Q4_K_M" {
		t.Fatalf("a dry run ends with the type: %v", argv)
	}
}
