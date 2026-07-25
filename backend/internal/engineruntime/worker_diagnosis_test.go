package engineruntime

import (
	"strings"
	"testing"
)

func TestDiagnoseWorkerOutputKnownPatterns(t *testing.T) {
	cases := []struct {
		name     string
		output   string
		wantCode string
		wantFix  string
	}{
		{
			name: "torch cuda oom",
			output: `Traceback (most recent call last):
  File "worker.py", line 10, in load
torch.cuda.OutOfMemoryError: CUDA out of memory. Tried to allocate 2.50 GiB`,
			wantCode: "gpu_out_of_memory",
			wantFix:  FixReduceContext,
		},
		{
			name:     "cuda driver mismatch",
			output:   "RuntimeError: CUDA driver version is insufficient for CUDA runtime version",
			wantCode: "gpu_driver_mismatch",
			wantFix:  FixRetryOnCPU,
		},
		{
			name:     "illegal memory access",
			output:   "RuntimeError: CUDA error: an illegal memory access was encountered",
			wantCode: "gpu_illegal_access",
			wantFix:  FixRetryOnCPU,
		},
		{
			name:     "no gpu available",
			output:   "RuntimeError: No CUDA GPUs are available",
			wantCode: "gpu_unavailable",
			wantFix:  FixRetryOnCPU,
		},
		{
			name:     "python memory error",
			output:   "MemoryError",
			wantCode: "ram_out_of_memory",
			wantFix:  FixReduceContext,
		},
		{
			name:     "missing module",
			output:   "ModuleNotFoundError: No module named 'transformers'",
			wantCode: "python_dependency_missing",
			wantFix:  FixReinstallRuntime,
		},
		{
			name:     "missing model file",
			output:   "FileNotFoundError: [Errno 2] No such file or directory: '/models/foo.gguf'",
			wantCode: "model_file_missing",
			wantFix:  FixRescanModels,
		},
		{
			name:     "port already bound",
			output:   "OSError: [Errno 98] Address already in use",
			wantCode: "port_in_use",
			wantFix:  "",
		},
		{
			name:     "unsupported architecture",
			output:   "error loading model architecture: unknown model architecture: 'foobar'",
			wantCode: "model_architecture_unsupported",
			wantFix:  "",
		},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			diagnosis, ok := DiagnoseWorkerOutput(testCase.output)
			if !ok {
				t.Fatalf("expected diagnosis for output %q", testCase.output)
			}
			if diagnosis.Code != testCase.wantCode {
				t.Fatalf("code = %q, want %q", diagnosis.Code, testCase.wantCode)
			}
			if diagnosis.SuggestedFix != testCase.wantFix {
				t.Fatalf("fix = %q, want %q", diagnosis.SuggestedFix, testCase.wantFix)
			}
			if strings.TrimSpace(diagnosis.Message) == "" {
				t.Fatal("diagnosis message must not be empty")
			}
		})
	}
}

func TestDiagnoseWorkerOutputNoMatch(t *testing.T) {
	if _, ok := DiagnoseWorkerOutput("all fine, nothing to see"); ok {
		t.Fatal("unexpected diagnosis for harmless output")
	}
	if _, ok := DiagnoseWorkerOutput("   "); ok {
		t.Fatal("unexpected diagnosis for empty output")
	}
}

func TestDiagnoseWorkerExitOOMKiller(t *testing.T) {
	diagnosis, ok := DiagnoseWorkerExit(137, "loading weights ...")
	if !ok || diagnosis.Code != "ram_out_of_memory" {
		t.Fatalf("exit 137 should map to ram_out_of_memory, got %+v ok=%v", diagnosis, ok)
	}
}

func TestDiagnoseWorkerExitPrefersPattern(t *testing.T) {
	diagnosis, ok := DiagnoseWorkerExit(137, "torch.cuda.OutOfMemoryError: CUDA out of memory")
	if !ok || diagnosis.Code != "gpu_out_of_memory" {
		t.Fatalf("stderr pattern should win over exit code, got %+v ok=%v", diagnosis, ok)
	}
}

func TestMarkAndParseDiagnosisMarker(t *testing.T) {
	marked := MarkDiagnosis("gpu_out_of_memory", "Der Grafikspeicher reicht nicht aus.")
	code, rest, ok := ParseDiagnosisMarker(marked)
	if !ok || code != "gpu_out_of_memory" || rest != "Der Grafikspeicher reicht nicht aus." {
		t.Fatalf("round trip failed: code=%q rest=%q ok=%v", code, rest, ok)
	}
	if _, _, ok := ParseDiagnosisMarker("plain error text"); ok {
		t.Fatal("plain text must not parse as marker")
	}
}

func TestSummarizeWorkerExitEmbedsMarker(t *testing.T) {
	summary := summarizeWorkerExit(1, "torch.cuda.OutOfMemoryError: CUDA out of memory", nil)
	code, _, ok := ParseDiagnosisMarker(summary)
	if !ok || code != "gpu_out_of_memory" {
		t.Fatalf("summary should carry marker, got %q", summary)
	}
	plain := summarizeWorkerExit(3, "some unknown failure line", nil)
	if _, _, ok := ParseDiagnosisMarker(plain); ok {
		t.Fatalf("undiagnosed exit should stay plain, got %q", plain)
	}
}

func TestLlamaBufferAllocationIsNotMisreadAsOOM(t *testing.T) {
	// llama.cpp emits "failed to allocate buffer" for KV-cache type
	// incompatibilities too. Misreading it as OOM skipped the q4_0->f16
	// fallback and made previously working models unstartable.
	if diagnosis, ok := DiagnoseWorkerOutput("llama_kv_cache_init: failed to allocate buffer for kv cache"); ok {
		t.Fatalf("ambiguous llama.cpp alloc line must stay undiagnosed, got %+v", diagnosis)
	}
	// Real OOM markers still match.
	if diagnosis, ok := DiagnoseWorkerOutput("ggml_aligned_malloc: insufficient memory (attempted to allocate 24576 MB)"); !ok || diagnosis.Code != "ram_out_of_memory" {
		t.Fatalf("insufficient memory must map to ram_out_of_memory, got %+v ok=%v", diagnosis, ok)
	}
}
