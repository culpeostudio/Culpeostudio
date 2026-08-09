package engineruntime

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// The parsing tests work from captured output. These drive the real
// llama-quantize, which is the only way to catch what a fixture cannot show:
// that the operand order is right, that progress actually arrives, and that a
// refusal is reported in terms a user can act on.
//
// They are skipped unless both paths are supplied, so a checkout without an
// installed runtime still runs the suite:
//
//	ENGINE_TEST_SERVER_PATH=<...>/llama-server \
//	ENGINE_TEST_MODEL_PATH=<...>/model.gguf go test ./internal/engineruntime/
func quantizeE2EPaths(t *testing.T) (quantizePath, modelPath string) {
	t.Helper()
	serverPath := os.Getenv("ENGINE_TEST_SERVER_PATH")
	modelPath = os.Getenv("ENGINE_TEST_MODEL_PATH")
	if serverPath == "" || modelPath == "" {
		t.Skip("set ENGINE_TEST_SERVER_PATH and ENGINE_TEST_MODEL_PATH to run against a real build")
	}
	quantizePath, err := QuantizePath(serverPath)
	if err != nil {
		t.Fatal(err)
	}
	return quantizePath, modelPath
}

func TestQuantizeDryRunReadsTheRealBuild(t *testing.T) {
	quantizePath, modelPath := quantizeE2EPaths(t)
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()

	types, err := ReadQuantizationTypes(ctx, quantizePath)
	if err != nil {
		t.Fatal(err)
	}
	if len(types) < 10 {
		t.Fatalf("the build reported only %d quantisation types", len(types))
	}

	steps := 0
	estimate, err := RunQuantize(ctx, QuantizeRequest{
		QuantizePath: quantizePath, SourcePath: modelPath, TargetType: "Q4_K_M", DryRun: true,
	}, nil, func(QuantizeProgress) { steps++ })
	if err != nil {
		t.Fatal(err)
	}
	if estimate.SourceBytes <= 0 || estimate.TargetBytes <= 0 {
		t.Fatalf("the dry run reported no sizes: %+v", estimate)
	}
	if steps == 0 {
		t.Fatal("no progress steps were parsed from the real output")
	}
	t.Logf("%d -> %d bytes (%.2f -> %.2f bpw), %d types, %d steps",
		estimate.SourceBytes, estimate.TargetBytes,
		estimate.SourceBitsPerWeight, estimate.TargetBitsPerWeight, len(types), steps)
}

func TestQuantizeRefusesThenConvertsARealModel(t *testing.T) {
	quantizePath, modelPath := quantizeE2EPaths(t)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	target := filepath.Join(t.TempDir(), "out-q4.gguf")

	base := QuantizeRequest{
		QuantizePath: quantizePath, SourcePath: modelPath,
		TargetPath: target, TargetType: "Q4_K_M", Threads: 4,
	}

	// The tool exits non-zero for this, so the recognised cause has to win over
	// the exit status: "exit status 1" tells the user nothing.
	_, err := RunQuantize(ctx, base, nil, nil)
	if err == nil {
		t.Skip("the source model is not quantised, so there is no refusal to check")
	}
	if !strings.Contains(err.Error(), "bereits quantisiert") {
		t.Fatalf("the refusal was not explained: %v", err)
	}

	base.AllowRequantize = true
	last := 0.0
	estimate, err := RunQuantize(ctx, base, nil, func(p QuantizeProgress) { last = p.Fraction })
	if err != nil {
		t.Fatalf("the opted-in conversion failed: %v", err)
	}
	info, statErr := os.Stat(target)
	if statErr != nil {
		t.Fatalf("no output was written: %v", statErr)
	}
	if last < 0.99 {
		t.Fatalf("progress stopped at %.2f", last)
	}
	// The dry run predicts the tensor payload; the file also carries metadata,
	// so the two are close rather than equal. A large gap would mean the
	// preflight is budgeting for the wrong thing.
	drift := float64(info.Size()-estimate.TargetBytes) / float64(info.Size())
	if drift < -0.05 || drift > 0.05 {
		t.Fatalf("estimate %d and actual %d differ by more than 5%%", estimate.TargetBytes, info.Size())
	}
	t.Logf("wrote %d bytes, estimate said %d", info.Size(), estimate.TargetBytes)
}
