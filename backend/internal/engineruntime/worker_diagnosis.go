package engineruntime

import (
	"fmt"
	"regexp"
	"strings"
)

// WorkerDiagnosis classifies a raw Python/native worker failure into a stable
// machine-readable code, a user-friendly German message, and an optional
// self-healing action the UI can offer as a 1-click fix.
type WorkerDiagnosis struct {
	// Code is stable and machine-readable, e.g. "gpu_out_of_memory".
	Code string `json:"code"`
	// Message explains the failure in user language, without raw tracebacks.
	Message string `json:"message"`
	// SuggestedFix describes an automatic remediation the caller can offer.
	// Empty when no safe automatic fix exists.
	SuggestedFix string `json:"suggested_fix,omitempty"`
	// SuggestedFixLabel is the button label for the remediation.
	SuggestedFixLabel string `json:"suggested_fix_label,omitempty"`
}

// Suggested fix identifiers understood by the engine module / frontend.
const (
	FixReduceContext        = "reduce_context"
	FixRetryOnCPU           = "retry_on_cpu"
	FixReinstallRuntime     = "reinstall_runtime"
	FixRescanModels         = "rescan_models"
	FixFreeMemoryRetry      = "free_memory_retry"
	FixUpdateGPUDriver      = "update_gpu_driver"
	FixCheckModelFiles      = "check_model_files"
	FixRestartWithLowerLoad = "restart_lower_load"
)

// diagnosisPattern maps lowercase substrings of worker output to a diagnosis.
// Order matters: the first match wins, so more specific patterns come first.
type diagnosisPattern struct {
	substrings []string
	diagnosis  WorkerDiagnosis
}

var workerDiagnosisPatterns = []diagnosisPattern{
	{
		substrings: []string{"cuda out of memory", "torch.outofmemoryerror", "outofmemoryerror", "hip out of memory", "cudamalloc failed", "ggml_backend_cuda_buffer_type_alloc_buffer"},
		diagnosis: WorkerDiagnosis{
			Code:              "gpu_out_of_memory",
			Message:           "Der Grafikspeicher reicht fuer dieses Modell mit dem aktuellen Kontext nicht aus. Ein kleinerer Kontext oder RAM-Offload behebt das in der Regel.",
			SuggestedFix:      FixReduceContext,
			SuggestedFixLabel: "Kontext automatisch verkleinern",
		},
	},
	{
		substrings: []string{"cuda driver version is insufficient", "driver version mismatch", "cuda version mismatch", "unsupported cuda version", "libcuda.so: cannot open"},
		diagnosis: WorkerDiagnosis{
			Code:              "gpu_driver_mismatch",
			Message:           "Der installierte GPU-Treiber passt nicht zur CUDA-Version der Runtime. Ein Treiber-Update oder die CPU-Ausfuehrung loest das Problem.",
			SuggestedFix:      FixRetryOnCPU,
			SuggestedFixLabel: "Auf CPU-Ausfuehrung wechseln",
		},
	},
	{
		substrings: []string{"illegal memory access", "cudaerrorillegaladdress", "device-side assert"},
		diagnosis: WorkerDiagnosis{
			Code:              "gpu_illegal_access",
			Message:           "Die GPU-Ausfuehrung ist mit einem internen Speicherfehler abgebrochen. Das passiert meist bei inkompatiblen Treibern oder zu aggressiven Einstellungen.",
			SuggestedFix:      FixRetryOnCPU,
			SuggestedFixLabel: "Auf CPU-Ausfuehrung wechseln",
		},
	},
	{
		substrings: []string{"no cuda gpus are available", "no cuda-capable device", "found no nvidia driver", "hip error: no rocm-capable device"},
		diagnosis: WorkerDiagnosis{
			Code:              "gpu_unavailable",
			Message:           "Es wurde keine nutzbare GPU gefunden. Das Modell kann stattdessen auf der CPU laufen.",
			SuggestedFix:      FixRetryOnCPU,
			SuggestedFixLabel: "Auf CPU-Ausfuehrung wechseln",
		},
	},
	{
		// "failed to allocate buffer" is deliberately absent: llama.cpp emits it
		// for KV-cache type incompatibilities too, and misreading those as OOM
		// would skip the q4_0->f16 fallback that actually fixes them.
		substrings: []string{"memoryerror", "cannot allocate memory", "std::bad_alloc", "insufficient memory", "out of memory", "signal: killed"},
		diagnosis: WorkerDiagnosis{
			Code:              "ram_out_of_memory",
			Message:           "Der Arbeitsspeicher hat waehrend des Ladens nicht ausgereicht. Andere Programme schliessen oder einen kleineren Kontext waehlen hilft.",
			SuggestedFix:      FixReduceContext,
			SuggestedFixLabel: "Kontext automatisch verkleinern",
		},
	},
	{
		substrings: []string{"modulenotfounderror", "importerror: "},
		diagnosis: WorkerDiagnosis{
			Code:              "python_dependency_missing",
			Message:           "In der Laufzeitumgebung fehlt eine benoetigte Python-Komponente. Eine Neuinstallation der Runtime behebt das automatisch.",
			SuggestedFix:      FixReinstallRuntime,
			SuggestedFixLabel: "Runtime automatisch reparieren",
		},
	},
	{
		substrings: []string{"filenotfounderror", "no such file or directory", "failed to open file", "error loading model: failed to open"},
		diagnosis: WorkerDiagnosis{
			Code:              "model_file_missing",
			Message:           "Eine Modelldatei wurde nicht gefunden oder ist nicht mehr lesbar. Ein erneuter Modell-Scan zeigt den aktuellen Zustand.",
			SuggestedFix:      FixRescanModels,
			SuggestedFixLabel: "Modelle neu scannen",
		},
	},
	{
		substrings: []string{"address already in use", "errno 98", "only one usage of each socket address"},
		diagnosis: WorkerDiagnosis{
			Code:    "port_in_use",
			Message: "Der lokale Netzwerk-Port ist bereits belegt, vermutlich durch einen frueheren Modellprozess. Ein erneuter Start waehlt automatisch einen freien Port.",
		},
	},
	{
		substrings: []string{"permission denied", "errno 13"},
		diagnosis: WorkerDiagnosis{
			Code:    "permission_denied",
			Message: "Der Zugriff auf eine benoetigte Datei wurde vom Betriebssystem verweigert. Bitte die Dateirechte im Modellordner pruefen.",
		},
	},
	{
		substrings: []string{"unknown model architecture", "unsupported architecture", "unknown architecture", "error loading model architecture"},
		diagnosis: WorkerDiagnosis{
			Code:    "model_architecture_unsupported",
			Message: "Diese Modellarchitektur wird von der gewaehlten Runtime nicht unterstuetzt. Ein anderes Format oder eine andere Runtime ist noetig.",
		},
	},
	{
		substrings: []string{"invalid magic", "not a gguf file", "corrupt", "unexpected end of file", "safetensors_rust.safetensorerror"},
		diagnosis: WorkerDiagnosis{
			Code:              "model_file_corrupted",
			Message:           "Eine Modelldatei scheint beschaedigt oder unvollstaendig zu sein. Ein erneuter Download behebt das in der Regel.",
			SuggestedFix:      FixCheckModelFiles,
			SuggestedFixLabel: "Modelldateien pruefen",
		},
	},
}

// DiagnoseWorkerOutput scans raw worker output (stderr/traceback) for known
// failure patterns. Returns false when nothing matches.
func DiagnoseWorkerOutput(output string) (WorkerDiagnosis, bool) {
	lower := strings.ToLower(output)
	if strings.TrimSpace(lower) == "" {
		return WorkerDiagnosis{}, false
	}
	for _, pattern := range workerDiagnosisPatterns {
		for _, substring := range pattern.substrings {
			if strings.Contains(lower, substring) {
				return pattern.diagnosis, true
			}
		}
	}
	return WorkerDiagnosis{}, false
}

// DiagnoseWorkerExit combines stderr pattern matching with exit-code
// heuristics. Exit code 137 (SIGKILL) without a clearer pattern usually means
// the OS out-of-memory killer terminated the worker.
func DiagnoseWorkerExit(exitCode int, output string) (WorkerDiagnosis, bool) {
	if diagnosis, ok := DiagnoseWorkerOutput(output); ok {
		return diagnosis, true
	}
	switch exitCode {
	case 137, -9:
		return WorkerDiagnosis{
			Code:              "ram_out_of_memory",
			Message:           "Das Betriebssystem hat den Modellprozess wegen Speichermangels beendet. Ein kleinerer Kontext oder weniger parallele Modelle helfen.",
			SuggestedFix:      FixReduceContext,
			SuggestedFixLabel: "Kontext automatisch verkleinern",
		}, true
	case 132, 134, -4, -6:
		return WorkerDiagnosis{
			Code:              "cpu_instruction_unsupported",
			Message:           "Der Modellprozess ist mit einem Hardwarefehler abgestuerzt. Die Runtime passt moeglicherweise nicht zu diesem Prozessor; eine Neuinstallation waehlt kompatible Pakete.",
			SuggestedFix:      FixReinstallRuntime,
			SuggestedFixLabel: "Runtime automatisch reparieren",
		}, true
	}
	return WorkerDiagnosis{}, false
}

// rawDetailSeparator carries the last raw worker line alongside a diagnosed
// message so the error log keeps the ground truth. classifyEngineError strips
// it from the user-facing summary again.
const rawDetailSeparator = " [Technische Meldung: "

// FormatWorkerExit renders a user-facing summary for a dead worker process,
// preferring a matched diagnosis over the raw last stderr line.
func FormatWorkerExit(exitCode int, stderr string, processErr error) (code, summary string) {
	sanitized := sanitizeInstallText(stderr, providerSecretValues())
	if diagnosis, ok := DiagnoseWorkerExit(exitCode, sanitized); ok {
		summary := diagnosis.Message
		if detail := lastUsefulInstallLine(sanitized); detail != "" {
			// Keep the raw line for diagnosis; without it a misclassified
			// failure is impossible to debug from the error log.
			summary += rawDetailSeparator + detail + "]"
		}
		return diagnosis.Code, summary
	}
	if detail := lastUsefulInstallLine(sanitized); detail != "" {
		return "worker_exit", fmt.Sprintf("Model-Worker wurde mit Code %d beendet. Letzte Diagnose: %s", exitCode, detail)
	}
	if processErr != nil && !strings.HasPrefix(processErr.Error(), "exit status") {
		return "worker_exit", fmt.Sprintf("Model-Worker wurde mit Code %d beendet: %s", exitCode, processErr)
	}
	return "worker_exit", fmt.Sprintf("Model-Worker wurde unerwartet mit Code %d beendet", exitCode)
}

// DiagnosisByCode returns the canonical diagnosis for a stable code so that
// callers holding only the code can recover the suggested fix.
func DiagnosisByCode(code string) (WorkerDiagnosis, bool) {
	for _, pattern := range workerDiagnosisPatterns {
		if pattern.diagnosis.Code == code {
			return pattern.diagnosis, true
		}
	}
	switch code {
	case "ram_out_of_memory":
		return WorkerDiagnosis{
			Code:              "ram_out_of_memory",
			Message:           "Der Arbeitsspeicher hat nicht ausgereicht.",
			SuggestedFix:      FixReduceContext,
			SuggestedFixLabel: "Kontext automatisch verkleinern",
		}, true
	case "cpu_instruction_unsupported":
		return WorkerDiagnosis{
			Code:              "cpu_instruction_unsupported",
			Message:           "Die Runtime passt nicht zu diesem Prozessor.",
			SuggestedFix:      FixReinstallRuntime,
			SuggestedFixLabel: "Runtime automatisch reparieren",
		}, true
	}
	return WorkerDiagnosis{}, false
}

// diagnosisMarkerPattern recognizes the "[stable_code] message" prefix that
// summarizeWorkerExit embeds so higher layers can recover the structured code
// from a plain error string.
var diagnosisMarkerPattern = regexp.MustCompile(`^\[([a-z0-9_]+)\]\s*(.+)$`)

// MarkDiagnosis prefixes a summary with its machine-readable code.
func MarkDiagnosis(code, summary string) string {
	if code == "" {
		return summary
	}
	return "[" + code + "] " + summary
}

// ParseDiagnosisMarker extracts a code marker embedded by MarkDiagnosis. The
// raw technical detail appended by FormatWorkerExit is stripped from the
// returned summary; it stays available in the full error text.
func ParseDiagnosisMarker(text string) (code, rest string, ok bool) {
	match := diagnosisMarkerPattern.FindStringSubmatch(strings.TrimSpace(text))
	if match == nil {
		return "", "", false
	}
	rest = match[2]
	if cut := strings.Index(rest, rawDetailSeparator); cut > 0 {
		rest = strings.TrimSpace(rest[:cut])
	}
	return match[1], rest, true
}
