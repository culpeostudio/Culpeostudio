package engineruntime

import (
	"fmt"
	"regexp"
	"strings"
)

type WorkerDiagnosis struct {
	Code string `json:"code"`

	Message string `json:"message"`

	SuggestedFix string `json:"suggested_fix,omitempty"`

	SuggestedFixLabel string `json:"suggested_fix_label,omitempty"`
}

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

const rawDetailSeparator = " [Technische Meldung: "

func FormatWorkerExit(exitCode int, stderr string, processErr error) (code, summary string) {
	sanitized := sanitizeInstallText(stderr, providerSecretValues())
	if diagnosis, ok := DiagnoseWorkerExit(exitCode, sanitized); ok {
		summary := diagnosis.Message
		if detail := lastUsefulInstallLine(sanitized); detail != "" {

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

var diagnosisMarkerPattern = regexp.MustCompile(`^\[([a-z0-9_]+)\]\s*(.+)$`)

func MarkDiagnosis(code, summary string) string {
	if code == "" {
		return summary
	}
	return "[" + code + "] " + summary
}

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
