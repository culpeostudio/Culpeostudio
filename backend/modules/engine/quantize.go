// Quantising a local GGUF down to a smaller one.
//
// This is deliberately the narrow version of the feature: GGUF in, GGUF out.
// Converting a SafeTensors checkpoint into a GGUF in the first place needs
// Python and the whole HuggingFace stack, which this backend does not have and
// which is a separate decision to make; re-quantising an existing GGUF needs
// nothing that is not already installed, because llama-quantize ships in the
// same archive as llama-server.
//
// The job reuses the engine's existing operation machinery - progress, cancel,
// events, the spawn admission gate - so a conversion behaves like every other
// long-running thing the engine does, and shows up in the same feed.

package engine

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/modelcatalog"
)

// quantizeDiskHeadroom is kept free on top of the estimated output. A volume
// filled to the last byte is a bad outcome even when the file itself fits.
const quantizeDiskHeadroom = int64(1) << 30

// quantizeJob is the module's view of one conversion.
type quantizeJob struct {
	ID          string
	OperationID string
	SourceModel string
	TargetPath  string
	TargetType  string
	StartedAt   time.Time

	mu       sync.Mutex
	logLines []string
	cancel   context.CancelFunc
}

const quantizeJobLogLines = 400

func (j *quantizeJob) appendLog(line string) {
	j.mu.Lock()
	defer j.mu.Unlock()
	j.logLines = append(j.logLines, line)
	if len(j.logLines) > quantizeJobLogLines {
		j.logLines = j.logLines[len(j.logLines)-quantizeJobLogLines:]
	}
}

func (j *quantizeJob) Write(payload []byte) (int, error) {
	for _, line := range strings.Split(strings.TrimRight(string(payload), "\n"), "\n") {
		if strings.TrimSpace(line) != "" {
			j.appendLog(line)
		}
	}
	return len(payload), nil
}

func (j *quantizeJob) logText() string {
	j.mu.Lock()
	defer j.mu.Unlock()
	return strings.Join(j.logLines, "\n")
}

// quantizePath resolves the tool next to whichever llama.cpp build is
// installed. Quantising is pure CPU work, so the variant does not matter: any
// installed build carries the same tool.
func (m *EngineModule) quantizePath(ctx context.Context) (string, error) {
	if m.installer == nil {
		return "", fmt.Errorf("der Runtime-Installer ist nicht verfuegbar")
	}
	snapshot, _ := m.liveHardware(ctx)
	candidates := []engineruntime.Build{}
	if build, _, err := m.selectBuild(snapshot, false); err == nil {
		candidates = append(candidates, build)
	}
	if build, _, err := m.selectBuild(snapshot, true); err == nil {
		candidates = append(candidates, build)
	}
	for _, build := range candidates {
		serverPath, err := m.installer.ServerPath(build)
		if err != nil {
			continue
		}
		if path, err := engineruntime.QuantizePath(serverPath); err == nil {
			return path, nil
		}
	}
	return "", fmt.Errorf("das Quantisierungswerkzeug steht erst zur Verfuegung, wenn eine lokale Runtime installiert ist")
}

// quantizationTypes lists what the installed build can write. The answer is
// cached for the lifetime of the process because it is a property of the
// binary, and reading it means running that binary.
func (m *EngineModule) quantizationTypes(ctx context.Context) ([]engineruntime.QuantizationType, error) {
	m.quantizeMu.Lock()
	cached := m.quantizeTypes
	m.quantizeMu.Unlock()
	if len(cached) > 0 {
		return cached, nil
	}
	path, err := m.quantizePath(ctx)
	if err != nil {
		return nil, err
	}
	types, err := engineruntime.ReadQuantizationTypes(ctx, path)
	if err != nil {
		return nil, err
	}
	m.quantizeMu.Lock()
	m.quantizeTypes = types
	m.quantizeMu.Unlock()
	return types, nil
}

// QuantizeRequest is what a caller asks for.
type QuantizeRequest struct {
	SourceModelID   string
	TargetType      string
	TargetName      string
	AllowRequantize bool
	// LeaveOutputTensor keeps output.weight at its source precision. It costs a
	// few percent of size and recovers a noticeable part of what a
	// re-quantisation loses, which is why it is offered separately.
	LeaveOutputTensor bool
	Threads           int
}

// QuantizePreflight is the answer to "what would this do", assembled before
// anything is written.
type QuantizePreflight struct {
	SourceModelID       string  `json:"source_model_id"`
	SourceName          string  `json:"source_name"`
	SourceQuantization  string  `json:"source_quantization,omitempty"`
	SourceBytes         int64   `json:"source_bytes"`
	TargetType          string  `json:"target_type"`
	TargetName          string  `json:"target_name"`
	TargetRelativePath  string  `json:"target_relative_path"`
	EstimatedBytes      int64   `json:"estimated_bytes"`
	FreeDiskBytes       int64   `json:"free_disk_bytes"`
	RequiredDiskBytes   int64   `json:"required_disk_bytes"`
	SourceBitsPerWeight float64 `json:"source_bits_per_weight,omitempty"`
	TargetBitsPerWeight float64 `json:"target_bits_per_weight,omitempty"`
	// IsRequantization means the source already carries a quantisation, so the
	// result loses quality twice over. It is the single most important thing to
	// put in front of the user, because most local GGUFs are already quantised.
	IsRequantization bool     `json:"is_requantization"`
	Feasible         bool     `json:"feasible"`
	Blockers         []string `json:"blockers,omitempty"`
	Warnings         []string `json:"warnings,omitempty"`
}

// quantizationSuffix matches the quantisation label most GGUF filenames carry,
// so a derived name replaces it rather than piling a second one on top.
var quantizationSuffix = regexp.MustCompile(`(?i)[-_.](I?Q\d[A-Z0-9_]*|F16|F32|BF16|MXFP4(_MOE)?|TQ\d_\d)$`)

// defaultTargetName derives the output filename from the source and the target
// type: "Model-Q8_0.gguf" quantised to Q4_K_M becomes "Model-Q4_K_M.gguf".
func defaultTargetName(sourceName, targetType string) string {
	base := strings.TrimSuffix(sourceName, filepath.Ext(sourceName))
	if replaced := quantizationSuffix.ReplaceAllString(base, ""); replaced != "" {
		base = replaced
	}
	return base + "-" + strings.ToUpper(targetType) + ".gguf"
}

// preflightQuantization gathers everything needed to decide, including the
// exact output size, which llama-quantize will compute for free through its own
// dry run rather than being guessed at from bits per weight.
func (m *EngineModule) preflightQuantization(ctx context.Context, request QuantizeRequest) (QuantizePreflight, error) {
	record, sourcePath, targetType, err := m.resolveQuantizeSource(ctx, request)
	if err != nil {
		return QuantizePreflight{}, err
	}
	quantizeTool, err := m.quantizePath(ctx)
	if err != nil {
		return QuantizePreflight{}, err
	}

	targetName := strings.TrimSpace(request.TargetName)
	if targetName == "" {
		targetName = defaultTargetName(filepath.Base(sourcePath), targetType)
	}
	targetPath, targetRelative, err := m.resolveQuantizeTarget(sourcePath, targetName)
	if err != nil {
		return QuantizePreflight{}, err
	}

	report := QuantizePreflight{
		SourceModelID:      record.ID,
		SourceName:         record.Name,
		SourceQuantization: record.Metadata.Quantization,
		SourceBytes:        record.SizeBytes,
		TargetType:         targetType,
		TargetName:         filepath.Base(targetPath),
		TargetRelativePath: targetRelative,
	}

	// The dry run is the whole preflight: it reports the exact size the real
	// run would write, and it costs milliseconds because it never touches the
	// tensor data.
	estimateCtx, cancel := context.WithTimeout(ctx, 2*time.Minute)
	defer cancel()
	estimate, estimateErr := engineruntime.RunQuantize(estimateCtx, engineruntime.QuantizeRequest{
		QuantizePath: quantizeTool,
		SourcePath:   sourcePath,
		TargetType:   targetType,
		DryRun:       true,
	}, nil, nil)
	if estimateErr != nil {
		return QuantizePreflight{}, fmt.Errorf("die Groesse des Ergebnisses konnte nicht bestimmt werden: %w", estimateErr)
	}
	report.EstimatedBytes = estimate.TargetBytes
	report.SourceBitsPerWeight = estimate.SourceBitsPerWeight
	report.TargetBitsPerWeight = estimate.TargetBitsPerWeight
	report.IsRequantization = estimate.RequiresRequantizeOptIn
	if estimate.SourceBytes > 0 {
		report.SourceBytes = estimate.SourceBytes
	}

	report.RequiredDiskBytes = report.EstimatedBytes + quantizeDiskHeadroom
	if free, freeErr := engineruntime.FreeDiskBytes(filepath.Dir(targetPath)); freeErr == nil {
		report.FreeDiskBytes = free
		if free < report.RequiredDiskBytes {
			report.Blockers = append(report.Blockers, fmt.Sprintf(
				"Auf dem Ziellaufwerk sind %s frei, benoetigt werden %s (Ergebnis plus 1 GB Reserve).",
				formatMemoryBytes(free), formatMemoryBytes(report.RequiredDiskBytes)))
		}
	}
	if _, statErr := os.Stat(targetPath); statErr == nil {
		report.Blockers = append(report.Blockers, fmt.Sprintf("Es existiert bereits eine Datei %q.", filepath.Base(targetPath)))
	}
	if report.IsRequantization && !request.AllowRequantize {
		report.Blockers = append(report.Blockers, "Die Quelle ist bereits quantisiert; eine erneute Quantisierung muss ausdruecklich bestaetigt werden.")
	}

	if report.IsRequantization {
		report.Warnings = append(report.Warnings,
			"Die Quelle ist bereits quantisiert. Das Ergebnis verliert Qualitaet zweimal und ist schlechter als dasselbe Format direkt aus einer F16- oder BF16-Quelle.")
	}
	if report.EstimatedBytes >= report.SourceBytes && report.SourceBytes > 0 {
		report.Warnings = append(report.Warnings,
			"Das Ziel ist nicht kleiner als die Quelle; diese Umwandlung spart keinen Speicher.")
	}
	if report.TargetBitsPerWeight > 0 && report.TargetBitsPerWeight < 3 {
		report.Warnings = append(report.Warnings,
			"Unter etwa 3 Bit pro Gewicht faellt die Qualitaet deutlich ab. Ohne Importance-Matrix ist der Verlust in diesem Bereich besonders gross.")
	}
	report.Feasible = len(report.Blockers) == 0
	return report, nil
}

func (m *EngineModule) resolveQuantizeSource(ctx context.Context, request QuantizeRequest) (modelcatalog.ModelRecord, string, string, error) {
	record, ok := m.getModel(strings.TrimSpace(request.SourceModelID))
	if !ok {
		return modelcatalog.ModelRecord{}, "", "", os.ErrNotExist
	}
	if record.Format != modelcatalog.FormatGGUF {
		return modelcatalog.ModelRecord{}, "", "", fmt.Errorf("nur GGUF-Modelle koennen quantisiert werden")
	}
	fresh, err := m.freshModelRecord(ctx, record)
	if err != nil {
		return modelcatalog.ModelRecord{}, "", "", err
	}
	record = fresh
	sourcePath, err := m.modelPath(record)
	if err != nil {
		return modelcatalog.ModelRecord{}, "", "", err
	}
	targetType, err := m.resolveQuantizeType(ctx, request.TargetType)
	if err != nil {
		return modelcatalog.ModelRecord{}, "", "", err
	}
	return record, sourcePath, targetType, nil
}

// resolveQuantizeType checks the requested format against what the installed
// binary says it can write, rather than against a list maintained here.
func (m *EngineModule) resolveQuantizeType(ctx context.Context, requested string) (string, error) {
	requested = strings.ToUpper(strings.TrimSpace(requested))
	if requested == "" {
		return "", fmt.Errorf("ein Zielformat ist erforderlich")
	}
	types, err := m.quantizationTypes(ctx)
	if err != nil {
		return "", err
	}
	for _, candidate := range types {
		if strings.EqualFold(candidate.Name, requested) {
			return candidate.Name, nil
		}
	}
	names := make([]string, 0, len(types))
	for _, candidate := range types {
		names = append(names, candidate.Name)
	}
	sort.Strings(names)
	return "", fmt.Errorf("der installierte llama.cpp-Build kennt das Zielformat %q nicht; moeglich sind: %s", requested, strings.Join(names, ", "))
}

// resolveQuantizeTarget places the output beside its source and refuses
// anything that would leave the model directory. The name is treated as a bare
// filename: a caller does not get to write to an arbitrary path.
func (m *EngineModule) resolveQuantizeTarget(sourcePath, targetName string) (string, string, error) {
	targetName = strings.TrimSpace(targetName)
	if targetName == "" {
		return "", "", fmt.Errorf("ein Zieldateiname ist erforderlich")
	}
	if targetName != filepath.Base(targetName) || strings.ContainsAny(targetName, `/\`) {
		return "", "", fmt.Errorf("der Zieldateiname darf keinen Pfad enthalten")
	}
	if !strings.EqualFold(filepath.Ext(targetName), ".gguf") {
		targetName += ".gguf"
	}
	targetPath := filepath.Join(filepath.Dir(sourcePath), targetName)

	m.mu.RLock()
	root := m.modelDir
	m.mu.RUnlock()
	if !withinModelRoot(root, targetPath) {
		return "", "", fmt.Errorf("die Zieldatei laege ausserhalb des Modellordners")
	}
	relative, err := filepath.Rel(root, targetPath)
	if err != nil {
		return "", "", err
	}
	return targetPath, filepath.ToSlash(relative), nil
}

// startQuantization schedules the conversion and returns its operation. The
// work itself runs in the background and reports through the same event feed
// every other engine operation uses.
func (m *EngineModule) startQuantization(ctx context.Context, request QuantizeRequest) (*EngineOperation, QuantizePreflight, error) {
	report, err := m.preflightQuantization(ctx, request)
	if err != nil {
		return nil, QuantizePreflight{}, err
	}
	if !report.Feasible {
		return nil, report, fmt.Errorf("die Quantisierung kann nicht gestartet werden: %s", strings.Join(report.Blockers, " "))
	}
	quantizeTool, err := m.quantizePath(ctx)
	if err != nil {
		return nil, report, err
	}
	_, sourcePath, targetType, err := m.resolveQuantizeSource(ctx, request)
	if err != nil {
		return nil, report, err
	}
	targetPath, _, err := m.resolveQuantizeTarget(sourcePath, report.TargetName)
	if err != nil {
		return nil, report, err
	}

	m.mu.Lock()
	if m.shuttingDown {
		m.mu.Unlock()
		return nil, report, fmt.Errorf("Engine wird heruntergefahren")
	}
	operation, operationCtx := m.newOperationLocked("quantize", "",
		fmt.Sprintf("%s wird nach %s quantisiert", report.SourceName, report.TargetType))
	_ = m.persistLocked()
	m.mu.Unlock()

	job := &quantizeJob{
		ID: operation.ID, OperationID: operation.ID, SourceModel: report.SourceModelID,
		TargetPath: targetPath, TargetType: targetType, StartedAt: time.Now().UTC(),
	}
	m.quantizeMu.Lock()
	m.quantizeJobs[operation.ID] = job
	m.quantizeMu.Unlock()

	m.events.publish("quantize_started", map[string]interface{}{
		"operation_id": operation.ID, "source_model_id": report.SourceModelID,
		"target_type": report.TargetType, "target_name": report.TargetName,
	})

	go m.runQuantizeJob(operationCtx, job, engineruntime.QuantizeRequest{
		QuantizePath:      quantizeTool,
		SourcePath:        sourcePath,
		TargetPath:        targetPath,
		TargetType:        targetType,
		Threads:           request.Threads,
		AllowRequantize:   request.AllowRequantize,
		LeaveOutputTensor: request.LeaveOutputTensor,
	}, report)

	return operation, report, nil
}

func (m *EngineModule) runQuantizeJob(ctx context.Context, job *quantizeJob, request engineruntime.QuantizeRequest, report QuantizePreflight) {
	defer func() {
		m.quantizeMu.Lock()
		delete(m.quantizeJobs, job.ID)
		m.quantizeMu.Unlock()
	}()

	// Quantising saturates the cores and the disk, which is exactly what a
	// model start needs too. Going through the same admission gate keeps the
	// two from fighting each other.
	release, err := m.acquireWorkerSpawn(ctx)
	if err != nil {
		m.setOperation(job.OperationID, "failed", 1, "Die Quantisierung wurde nicht zugelassen", err)
		return
	}
	releaseOnce := sync.Once{}
	releaseGate := func() { releaseOnce.Do(release) }
	defer releaseGate()

	m.setOperationDetail(job.OperationID, "running", 0.02, "quantizing",
		fmt.Sprintf("%s wird nach %s quantisiert", report.SourceName, report.TargetType),
		fmt.Sprintf("Erwartete Groesse: %s. Die Umwandlung laeuft auf der CPU und belastet vor allem die Festplatte.", formatMemoryBytes(report.EstimatedBytes)), nil)

	lastPublished := time.Now()
	progress := func(step engineruntime.QuantizeProgress) {
		// The tensor counter is fine-grained enough to update on every step and
		// far too fine-grained to publish that often.
		if time.Since(lastPublished) < 400*time.Millisecond && step.Fraction < 1 {
			return
		}
		lastPublished = time.Now()
		m.setOperationDetail(job.OperationID, "running", 0.02+0.93*step.Fraction, "quantizing",
			fmt.Sprintf("%s wird nach %s quantisiert", report.SourceName, report.TargetType),
			fmt.Sprintf("Tensor %d von %d", step.Tensor, step.TotalTensor), nil)
	}

	estimate, runErr := engineruntime.RunQuantize(ctx, request, job, progress)
	releaseGate()

	if runErr != nil {
		// A run that stopped early leaves a truncated file behind. It is not a
		// model and would only show up in the catalog as a broken entry.
		if removeErr := os.Remove(request.TargetPath); removeErr != nil && !os.IsNotExist(removeErr) {
			log.Printf("[engine] could not remove the incomplete quantisation %s: %v", request.TargetPath, removeErr)
		}
		if ctx.Err() != nil {
			m.setOperationDetail(job.OperationID, "cancelled", 1, "cancelled",
				"Die Quantisierung wurde abgebrochen", "Die unvollstaendige Zieldatei wurde entfernt.", nil)
			m.events.publish("quantize_finished", map[string]interface{}{
				"operation_id": job.OperationID, "state": "cancelled",
			})
			return
		}
		m.setOperation(job.OperationID, "failed", 1, "Die Quantisierung ist fehlgeschlagen", runErr)
		m.events.publish("quantize_finished", map[string]interface{}{
			"operation_id": job.OperationID, "state": "failed", "error": runErr.Error(),
		})
		return
	}

	written := estimate.TargetBytes
	if info, statErr := os.Stat(request.TargetPath); statErr == nil {
		written = info.Size()
	}

	m.setOperationDetail(job.OperationID, "running", 0.97, "rescanning",
		"Das neue Modell wird in den Katalog aufgenommen", "Der Modellordner wird neu eingelesen.", nil)
	if _, rescanErr := m.rescan(ctx); rescanErr != nil {
		log.Printf("[engine] catalog rescan after quantisation failed: %v", rescanErr)
	}
	m.events.publish("models_rescanned", map[string]interface{}{"reason": "quantization_completed"})

	m.setOperationDetail(job.OperationID, "completed", 1, "completed",
		fmt.Sprintf("%s wurde als %s gespeichert", report.TargetName, report.TargetType),
		fmt.Sprintf("Aus %s wurden %s. Das Modell steht jetzt im Katalog.",
			formatMemoryBytes(report.SourceBytes), formatMemoryBytes(written)), nil)
	m.events.publish("quantize_finished", map[string]interface{}{
		"operation_id": job.OperationID, "state": "completed",
		"target_name": report.TargetName, "target_bytes": written,
	})
}

// quantizeJobLog returns what the tool has printed so far, which is the only
// way to see why a conversion is taking the shape it is.
func (m *EngineModule) quantizeJobLog(operationID string) (string, bool) {
	m.quantizeMu.Lock()
	job := m.quantizeJobs[strings.TrimSpace(operationID)]
	m.quantizeMu.Unlock()
	if job == nil {
		return "", false
	}
	return job.logText(), true
}
