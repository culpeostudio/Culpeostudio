// Re-quantising a GGUF on this machine.
//
// The tool is llama-quantize, which ships inside the same release archive as
// llama-server and is therefore already on disk next to it - nothing new is
// downloaded to make this work. This file knows how to find it, what it can
// produce, and how to read its output; deciding whether a particular conversion
// is a good idea is the engine module's job.

package engineruntime

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strconv"
	"strings"
)

// FreeDiskBytes reports the space available on the volume holding path. It is
// the exported face of the check the installer already does for itself, so a
// quantisation can budget for its output before it starts writing one.
func FreeDiskBytes(path string) (int64, error) {
	return freeDiskBytes(path)
}

// QuantizeBinaryName is the tool as it is named inside the release archive.
func QuantizeBinaryName() string {
	if runtime.GOOS == "windows" {
		return "llama-quantize.exe"
	}
	return "llama-quantize"
}

// QuantizePath locates llama-quantize beside an installed llama-server. The
// archive is unpacked whole, so the two always live in the same directory.
func QuantizePath(serverPath string) (string, error) {
	if strings.TrimSpace(serverPath) == "" {
		return "", errors.New("llama-server ist nicht installiert; ohne die Runtime steht auch das Quantisierungswerkzeug nicht bereit")
	}
	candidate := filepath.Join(filepath.Dir(serverPath), QuantizeBinaryName())
	info, err := os.Stat(candidate)
	if err != nil {
		if os.IsNotExist(err) {
			return "", fmt.Errorf("der installierte llama.cpp-Build enthaelt kein %s", QuantizeBinaryName())
		}
		return "", err
	}
	if !info.Mode().IsRegular() {
		return "", fmt.Errorf("%s ist keine ausfuehrbare Datei", candidate)
	}
	return candidate, nil
}

// QuantizationType is one target format the installed build can write, with the
// size and quality figures its own --help reports.
type QuantizationType struct {
	// Name is the spelling passed on the command line, such as Q4_K_M.
	Name string `json:"name"`
	// Description is the build's own one-line summary of the type.
	Description string `json:"description"`
	// SizeGiBAtReference and PerplexityDelta are the figures llama-quantize
	// prints for its reference model. They are the only quality numbers that
	// come from the tool itself rather than from a table maintained here, which
	// is why they are passed through with the reference named alongside.
	SizeGiBAtReference float64 `json:"size_gib_at_reference,omitempty"`
	PerplexityDelta    float64 `json:"perplexity_delta,omitempty"`
	ReferenceModel     string  `json:"reference_model,omitempty"`
	// BitsPerWeight is reported for the types described that way instead.
	BitsPerWeight float64 `json:"bits_per_weight,omitempty"`
	// Alias marks a name that resolves to another entry, such as Q4_K to Q4_K_M.
	Alias string `json:"alias,omitempty"`
}

var (
	// "  15  or  Q4_K_M  :  4.58G, +0.1754 ppl @ Llama-3-8B"
	quantTypeWithPPL = regexp.MustCompile(`^\s*\d+\s+or\s+([A-Z0-9_]+)\s*:\s*([0-9.]+)G,\s*([+-][0-9.]+)\s*ppl\s*@\s*(\S+)`)
	// "  30  or  IQ4_XS  :  4.25 bpw non-linear quantization"
	quantTypeWithBPW = regexp.MustCompile(`^\s*\d+\s+or\s+([A-Z0-9_]+)\s*:\s*([0-9.]+)\s*bpw\s*(.*)$`)
	// "  12  or  Q3_K    : alias for Q3_K_M"
	quantTypeAlias = regexp.MustCompile(`^\s*\d+\s+or\s+([A-Z0-9_]+)\s*:\s*alias for\s+([A-Z0-9_]+)`)
	// "  38  or  MXFP4_MOE :  MXFP4 MoE"
	quantTypePlain = regexp.MustCompile(`^\s*\d+\s+or\s+([A-Z0-9_]+)\s*:\s*(.+)$`)
)

// ParseQuantizationTypes reads the allowed-types table out of
// `llama-quantize --help`. Taking the list from the binary rather than from a
// table here is what keeps a build that gained or lost a type honest, and it is
// the same approach the KV cache list already uses.
func ParseQuantizationTypes(help string) []QuantizationType {
	result := []QuantizationType{}
	seen := map[string]bool{}
	inTable := false
	for _, line := range strings.Split(help, "\n") {
		if strings.Contains(line, "allowed quantization types") {
			inTable = true
			continue
		}
		if !inTable {
			continue
		}
		if strings.HasPrefix(strings.TrimSpace(line), "COPY") {
			// The table ends with the pseudo-type COPY, which does not quantise.
			break
		}
		entry, ok := parseQuantizationTypeLine(line)
		if !ok || seen[entry.Name] {
			continue
		}
		seen[entry.Name] = true
		result = append(result, entry)
	}
	return result
}

func parseQuantizationTypeLine(line string) (QuantizationType, bool) {
	if match := quantTypeWithPPL.FindStringSubmatch(line); match != nil {
		size, _ := strconv.ParseFloat(match[2], 64)
		delta, _ := strconv.ParseFloat(match[3], 64)
		return QuantizationType{
			Name: match[1], SizeGiBAtReference: size, PerplexityDelta: delta,
			ReferenceModel: match[4],
			Description:    fmt.Sprintf("%s bei %s, Perplexität %+.4f", formatGiBValue(size), match[4], delta),
		}, true
	}
	if match := quantTypeAlias.FindStringSubmatch(line); match != nil {
		return QuantizationType{Name: match[1], Alias: match[2], Description: "identisch mit " + match[2]}, true
	}
	if match := quantTypeWithBPW.FindStringSubmatch(line); match != nil {
		bpw, _ := strconv.ParseFloat(match[2], 64)
		description := strings.TrimSpace(match[3])
		if description == "" {
			description = "Quantisierung"
		}
		return QuantizationType{
			Name: match[1], BitsPerWeight: bpw,
			Description: fmt.Sprintf("%.2f Bit pro Gewicht, %s", bpw, description),
		}, true
	}
	if match := quantTypePlain.FindStringSubmatch(line); match != nil {
		return QuantizationType{Name: match[1], Description: strings.TrimSpace(match[2])}, true
	}
	return QuantizationType{}, false
}

func formatGiBValue(value float64) string {
	return strconv.FormatFloat(value, 'f', 2, 64) + " GB"
}

// ReadQuantizationTypes runs the tool once and parses what it can write.
func ReadQuantizationTypes(ctx context.Context, quantizePath string) ([]QuantizationType, error) {
	output, err := runQuantizeHelp(ctx, quantizePath)
	if err != nil {
		return nil, err
	}
	types := ParseQuantizationTypes(output)
	if len(types) == 0 {
		return nil, errors.New("das Quantisierungswerkzeug hat keine Zielformate gemeldet")
	}
	return types, nil
}

func runQuantizeHelp(ctx context.Context, quantizePath string) (string, error) {
	// --help exits non-zero on this tool, so the output matters and the status
	// does not.
	cmd := exec.CommandContext(ctx, quantizePath, "--help")
	cmd.Env = sanitizedInstallerEnvironment()
	cmd.Dir = filepath.Dir(quantizePath)
	output, _ := cmd.CombinedOutput()
	if len(output) == 0 {
		return "", fmt.Errorf("%s liefert keine Ausgabe", filepath.Base(quantizePath))
	}
	return string(output), nil
}

// QuantizeEstimate is what a dry run reported: the sizes without doing the work.
type QuantizeEstimate struct {
	SourceBytes             int64    `json:"source_bytes"`
	TargetBytes             int64    `json:"target_bytes"`
	SourceBitsPerWeight     float64  `json:"source_bits_per_weight,omitempty"`
	TargetBitsPerWeight     float64  `json:"target_bits_per_weight,omitempty"`
	SourceTensorTypes       []string `json:"source_tensor_types,omitempty"`
	RequiresRequantizeOptIn bool     `json:"requires_requantize_opt_in"`
}

var (
	quantizeModelSize  = regexp.MustCompile(`model size\s*=\s*([0-9.]+)\s*([KMG]i?B)\s*(?:\(([0-9.]+)\s*BPW\))?`)
	quantizeQuantSize  = regexp.MustCompile(`quant size\s*=\s*([0-9.]+)\s*([KMG]i?B)\s*(?:\(([0-9.]+)\s*BPW\))?`)
	quantizeTensorType = regexp.MustCompile(`- type\s+(\S+):\s*\d+ tensors`)
	// "[ 201/ 219] blk.21.ffn_up.weight ..."
	quantizeProgress = regexp.MustCompile(`^\[\s*(\d+)\s*/\s*(\d+)\s*\]`)
)

// ParseQuantizeEstimate reads the sizes off a dry run.
func ParseQuantizeEstimate(output string) QuantizeEstimate {
	estimate := QuantizeEstimate{}
	if match := quantizeModelSize.FindStringSubmatch(output); match != nil {
		estimate.SourceBytes = parseSizeWithUnit(match[1], match[2])
		estimate.SourceBitsPerWeight, _ = strconv.ParseFloat(match[3], 64)
	}
	if match := quantizeQuantSize.FindStringSubmatch(output); match != nil {
		estimate.TargetBytes = parseSizeWithUnit(match[1], match[2])
		estimate.TargetBitsPerWeight, _ = strconv.ParseFloat(match[3], 64)
	}
	for _, match := range quantizeTensorType.FindAllStringSubmatch(output, -1) {
		kind := strings.ToLower(match[1])
		estimate.SourceTensorTypes = append(estimate.SourceTensorTypes, kind)
		// f32 and f16 tensors are the unquantised ones; anything else means the
		// source already carries a quantisation, and re-quantising it stacks
		// loss on loss. llama-quantize refuses that without an explicit opt-in,
		// and so should the caller.
		if kind != "f32" && kind != "f16" && kind != "bf16" {
			estimate.RequiresRequantizeOptIn = true
		}
	}
	return estimate
}

func parseSizeWithUnit(value, unit string) int64 {
	number, err := strconv.ParseFloat(value, 64)
	if err != nil {
		return 0
	}
	multiplier := float64(1)
	switch strings.ToUpper(strings.TrimSuffix(unit, "B")) {
	case "K", "KI":
		multiplier = 1 << 10
	case "M", "MI":
		multiplier = 1 << 20
	case "G", "GI":
		multiplier = 1 << 30
	}
	return int64(number * multiplier)
}

// QuantizeRequest is one conversion.
type QuantizeRequest struct {
	QuantizePath string
	SourcePath   string
	TargetPath   string
	// TargetType is the name from the type table, such as Q4_K_M.
	TargetType string
	// Threads defaults to the machine's core count when zero.
	Threads int
	// AllowRequantize is required when the source is already quantised.
	AllowRequantize bool
	// LeaveOutputTensor keeps output.weight at its original precision, which
	// costs size but recovers some of the quality a re-quantisation loses.
	LeaveOutputTensor bool
	// ImatrixPath is an importance matrix to steer the quantisation.
	ImatrixPath string
	// OutputTensorType and TokenEmbeddingType override those two tensors, which
	// dominate quality at the low end of the range.
	OutputTensorType   string
	TokenEmbeddingType string
	// DryRun estimates the result without writing it.
	DryRun bool
}

// QuantizeProgress is one step of a running conversion.
type QuantizeProgress struct {
	Tensor      int
	TotalTensor int
	Fraction    float64
	Line        string
}

func (r QuantizeRequest) argv() []string {
	argv := []string{r.QuantizePath}
	if r.AllowRequantize {
		argv = append(argv, "--allow-requantize")
	}
	if r.LeaveOutputTensor {
		argv = append(argv, "--leave-output-tensor")
	}
	if r.ImatrixPath != "" {
		argv = append(argv, "--imatrix", r.ImatrixPath)
	}
	if r.OutputTensorType != "" {
		argv = append(argv, "--output-tensor-type", r.OutputTensorType)
	}
	if r.TokenEmbeddingType != "" {
		argv = append(argv, "--token-embedding-type", r.TokenEmbeddingType)
	}
	if r.DryRun {
		// A dry run takes no destination: the tool reports the size it would
		// have written and stops.
		return append(argv, "--dry-run", r.SourcePath, r.TargetType)
	}
	argv = append(argv, r.SourcePath, r.TargetPath, r.TargetType)
	if r.Threads > 0 {
		argv = append(argv, strconv.Itoa(r.Threads))
	}
	return argv
}

// RunQuantize performs the conversion, reporting progress as it goes and
// writing the tool's own output to log. It returns the sizes the run reported.
//
// Cancellation is honoured through ctx. The partially written target is the
// caller's to clean up, because only the caller knows whether it was writing
// over something that mattered.
func RunQuantize(ctx context.Context, request QuantizeRequest, log io.Writer, progress func(QuantizeProgress)) (QuantizeEstimate, error) {
	if strings.TrimSpace(request.QuantizePath) == "" {
		return QuantizeEstimate{}, errors.New("der Pfad zum Quantisierungswerkzeug fehlt")
	}
	if strings.TrimSpace(request.SourcePath) == "" || strings.TrimSpace(request.TargetType) == "" {
		return QuantizeEstimate{}, errors.New("Quelldatei und Zielformat sind erforderlich")
	}
	if !request.DryRun && strings.TrimSpace(request.TargetPath) == "" {
		return QuantizeEstimate{}, errors.New("die Zieldatei ist erforderlich")
	}

	argv := request.argv()
	cmd := exec.CommandContext(ctx, argv[0], argv[1:]...)
	cmd.Env = sanitizedInstallerEnvironment()
	// The tool loads its shared libraries from beside itself, exactly as
	// llama-server does.
	cmd.Dir = filepath.Dir(request.QuantizePath)

	// Both streams matter and their order matters: the tensor lines and the
	// size summary are interleaved across them depending on the build, so they
	// share one pipe rather than being read separately and stitched back
	// together afterwards.
	reader, writer, err := os.Pipe()
	if err != nil {
		return QuantizeEstimate{}, err
	}
	cmd.Stdout = writer
	cmd.Stderr = writer
	if err := cmd.Start(); err != nil {
		_ = reader.Close()
		_ = writer.Close()
		return QuantizeEstimate{}, err
	}
	// The child holds its own copy of the write end; this one has to go, or the
	// scanner below never sees end of file.
	_ = writer.Close()
	defer reader.Close()

	collected := &strings.Builder{}
	scanner := bufio.NewScanner(reader)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for scanner.Scan() {
		line := scanner.Text()
		collected.WriteString(line)
		collected.WriteByte('\n')
		if log != nil {
			_, _ = io.WriteString(log, line+"\n")
		}
		if progress == nil {
			continue
		}
		if match := quantizeProgress.FindStringSubmatch(line); match != nil {
			current, _ := strconv.Atoi(match[1])
			total, _ := strconv.Atoi(match[2])
			fraction := 0.0
			if total > 0 {
				fraction = float64(current) / float64(total)
			}
			progress(QuantizeProgress{Tensor: current, TotalTensor: total, Fraction: fraction, Line: line})
		}
	}

	waitErr := cmd.Wait()
	output := collected.String()
	estimate := ParseQuantizeEstimate(output)
	// The status alone does not say what went wrong, and some failures are
	// reported on the output without a non-zero exit at all. The recognised
	// causes are checked either way, because "exit status 1" is not something a
	// user can act on while "the source is already quantised" is.
	summary := detectQuantizeFailure(output)
	if waitErr != nil {
		if ctx.Err() != nil {
			return estimate, ctx.Err()
		}
		if summary != "" {
			return estimate, errors.New(summary)
		}
		return estimate, fmt.Errorf("%s: %w", summarizeQuantizeFailure(output), waitErr)
	}
	if summary != "" {
		return estimate, errors.New(summary)
	}
	return estimate, nil
}

// detectQuantizeFailure recognises the failures llama-quantize reports without
// a non-zero exit status.
func detectQuantizeFailure(output string) string {
	lower := strings.ToLower(output)
	switch {
	case strings.Contains(lower, "requantizing from type") && strings.Contains(lower, "is disabled"):
		return "Die Quelldatei ist bereits quantisiert. Eine erneute Quantisierung verliert zusaetzliche Qualitaet und muss ausdruecklich erlaubt werden."
	case strings.Contains(lower, "failed to quantize"):
		return summarizeQuantizeFailure(output)
	}
	return ""
}

func summarizeQuantizeFailure(output string) string {
	for _, line := range reverseLines(output) {
		lower := strings.ToLower(line)
		if strings.Contains(lower, "failed to quantize") || strings.Contains(lower, "error") {
			return strings.TrimSpace(line)
		}
	}
	return "Die Quantisierung ist fehlgeschlagen"
}

func reverseLines(text string) []string {
	lines := strings.Split(strings.TrimRight(text, "\n"), "\n")
	for left, right := 0, len(lines)-1; left < right; left, right = left+1, right-1 {
		lines[left], lines[right] = lines[right], lines[left]
	}
	return lines
}
