package engine

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/localinference"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

func (m *EngineModule) setInstanceState(id string, state engineruntime.InstanceState, progress float64, instanceError string) {
	m.setInstanceStateDetail(id, state, progress, string(state), defaultInstanceDetail(state), instanceError)
}

func (m *EngineModule) setInstanceStateDetail(id string, state engineruntime.InstanceState, progress float64, phase, detail, instanceError string) {
	m.mu.Lock()
	instance := m.instances[id]
	if instance == nil {
		m.mu.Unlock()
		return
	}
	previousState := instance.State
	previousPhase := instance.Phase
	instance.State = state
	progress = clampProgress(progress)
	if state != engineruntime.StateStopped && state != engineruntime.StateQueued && progress < instance.Progress {
		progress = instance.Progress
	}
	instance.Progress = progress
	if phase != "" {
		instance.Phase = phase
	}
	if detail != "" {
		instance.DetailMessage = detail
	}
	instance.Error = instanceError
	if instanceError != "" {
		instance.ErrorCode, instance.ErrorSummary = classifyEngineError(errors.New(instanceError))
		instance.DetailMessage = instance.ErrorSummary
	} else {
		instance.ErrorCode = ""
		instance.ErrorSummary = ""
	}
	instance.UpdatedAt = time.Now().UTC()
	copy := cloneInstance(instance)
	_ = m.persistLocked()
	m.mu.Unlock()
	if previousState != copy.State || previousPhase != copy.Phase || copy.ErrorSummary != "" {
		log.Printf("[engine-instance] id=%s state=%s phase=%s progress=%.2f detail=%q error_code=%s error_summary=%q",
			copy.ID, copy.State, copy.Phase, copy.Progress, sanitizeEngineLogText(copy.DetailMessage), copy.ErrorCode, sanitizeEngineLogText(copy.ErrorSummary))
	}
	m.events.publish("instance_changed", copy)
}

func defaultInstanceDetail(state engineruntime.InstanceState) string {
	switch state {
	case engineruntime.StateInstalling:
		return "Die benoetigte lokale Runtime wird vorbereitet."
	case engineruntime.StateQueued:
		return "Das Hardwarebudget ist reserviert; der Start wartet auf die Ausfuehrung."
	case engineruntime.StateStarting:
		return "Der Modellprozess wird gestartet und die Gewichte werden geladen."
	case engineruntime.StateDraining:
		return "Laufende Anfragen werden vor dem Neustart noch abgeschlossen."
	case engineruntime.StateRestarting:
		return "Die geaenderte Konfiguration wird sicher neu gestartet."
	case engineruntime.StateReady:
		return "Das Modell ist lokal erreichbar und einsatzbereit."
	case engineruntime.StateStopped:
		return "Das Modell ist gestoppt und belegt keinen Runtime-Speicher."
	case engineruntime.StateFailed, engineruntime.StateFailedRollback:
		return "Der Modellstart konnte nicht abgeschlossen werden."
	default:
		return "Der Modellstatus wird aktualisiert."
	}
}

// notStartableError explains exactly why a model cannot start by listing the
// catalog validation issues instead of a bare "not startable".
func notStartableError(record modelcatalog.ModelRecord) error {
	name := strings.TrimSpace(record.Name)
	if name == "" {
		name = record.ID
	}
	if len(record.Issues) == 0 {
		return fmt.Errorf("Modell %q ist nicht startbar; der Katalog meldet es als unvollstaendig. Ein erneuter Modell-Scan kann helfen.", name)
	}
	details := make([]string, 0, len(record.Issues))
	for _, issue := range record.Issues {
		message := strings.TrimSpace(issue.Message)
		if message == "" {
			message = issue.Code
		}
		if remediation := strings.TrimSpace(issue.Remediation); remediation != "" {
			message += " (" + remediation + ")"
		}
		details = append(details, message)
	}
	const maxListedIssues = 4
	if len(details) > maxListedIssues {
		details = append(details[:maxListedIssues], fmt.Sprintf("und %d weitere Probleme", len(record.Issues)-maxListedIssues))
	}
	return fmt.Errorf("Modell %q ist nicht startbar: %s", name, strings.Join(details, "; "))
}

// isPortConflictError reports whether a worker start failed because its
// loopback port was already bound (stolen in the allocation race or held by an
// orphaned process from a previous run).
func isPortConflictError(err error) bool {
	if err == nil {
		return false
	}
	text := err.Error()
	if code, _, ok := engineruntime.ParseDiagnosisMarker(text); ok {
		return code == "port_in_use"
	}
	lower := strings.ToLower(text)
	return strings.Contains(lower, "address already in use") ||
		strings.Contains(lower, "errno 98") ||
		strings.Contains(lower, "only one usage of each socket address")
}

func classifyEngineError(err error) (string, string) {
	if err == nil {
		return "", ""
	}
	var dependencyError *systemDependencyError
	if errors.As(err, &dependencyError) {
		return dependencyError.Code, dependencyError.Message
	}
	var gpuRuntimeError *gpuRuntimeUnavailableError
	if errors.As(err, &gpuRuntimeError) {
		return "gpu_runtime_unavailable", gpuRuntimeError.Error()
	}
	var planningConflict *engineplanner.ConflictError
	if errors.As(err, &planningConflict) {
		return "resource_conflict", "Das aktuelle Speicherbudget reicht fuer den berechneten Kontext nicht mehr aus. GPU und System-RAM werden beim naechsten Versuch neu berechnet."
	}
	var loadConflict *ResourceConflictError
	if errors.As(err, &loadConflict) {
		return "resource_conflict", "Der konservative Modell-Lade-Peak passt nicht mehr in den freien Grafikspeicher. GPU und System-RAM muessen neu berechnet werden."
	}
	var ramRequired *ramOffloadRequiredError
	if errors.As(err, &ramRequired) {
		return "resource_conflict", "Der GPU-Speicher reicht auch nach der Kontextanpassung nicht aus. Mit deiner Zustimmung kann die Engine GPU und System-RAM neu aufteilen."
	}
	text := strings.TrimSpace(err.Error())
	// Worker exits carry a structured diagnosis marker from the supervisor
	// ("[gpu_out_of_memory] ..."). Recover code and clean summary directly.
	if code, rest, ok := engineruntime.ParseDiagnosisMarker(text); ok {
		return code, rest
	}
	// Raw worker output can also reach this layer through health checks and
	// mini-inference probes; match known Python/CUDA failure patterns there too.
	if diagnosis, ok := engineruntime.DiagnoseWorkerOutput(text); ok {
		return diagnosis.Code, diagnosis.Message
	}
	lower := strings.ToLower(text)
	switch {
	case errors.Is(err, context.Canceled):
		return "operation_cancelled", "Der Vorgang wurde abgebrochen."
	case errors.Is(err, localinference.ErrQueueTimeout):
		return "queue_timeout", "Der Modellstart hat zu lange in der Warteschlange gewartet. Bitte erneut versuchen."
	case strings.Contains(lower, "konservativer lade-peak") ||
		strings.Contains(lower, "system-ram wurde noch nicht freigegeben") ||
		strings.Contains(lower, "engine plan conflict"):
		return "resource_conflict", "Der Modell-Lade-Peak passt nicht in den aktuell freien Grafikspeicher. Mit deiner Zustimmung kann die Engine GPU und System-RAM neu aufteilen."
	case errors.Is(err, localinference.ErrGuardRejected):
		return "resource_guard_rejected", "Der Ressourcenwaechter hat den Start zum Schutz des Hosts abgelehnt oder pausiert."
	case strings.Contains(lower, "gpu-runtime ist fuer dieses modell noch nicht verfuegbar") ||
		strings.Contains(lower, "gpu-runtime ist für dieses modell noch nicht verfügbar"):
		return "gpu_runtime_unavailable", text
	case errors.Is(err, context.DeadlineExceeded) || strings.Contains(lower, "health check failed: timeout"):
		return "worker_start_timeout", "Das Modell hat nicht rechtzeitig geantwortet. Es kann noch geladen haben oder die lokale Runtime konnte nicht bereit werden."
	case errors.Is(err, os.ErrNotExist) || strings.Contains(lower, "file does not exist") || strings.Contains(lower, "no such file"):
		return "required_file_missing", "Eine benoetigte Modell- oder Runtime-Datei wurde nicht gefunden. Bitte den Modellscan aktualisieren oder die Runtime erneut vorbereiten."
	case strings.Contains(lower, "out of memory") || strings.Contains(lower, "cannot allocate memory") || strings.Contains(lower, "cuda oom"):
		return "insufficient_memory", "Fuer diesen Startplan ist nicht genug freier GPU- oder Arbeitsspeicher vorhanden. Ein kleinerer Kontext kann helfen."
	case strings.Contains(lower, "http 401") || strings.Contains(lower, "http 403") || strings.Contains(lower, "unauthorized"):
		return "worker_auth_failed", "Die interne Verbindung zum Modellprozess wurde abgelehnt. Bitte den Start erneut versuchen."
	case strings.Contains(lower, "http 404") && strings.Contains(lower, "health"):
		return "worker_health_endpoint_missing", "Der Modellprozess laeuft, aber sein Bereitschaftsendpunkt ist mit dieser Runtime-Version nicht verfuegbar."
	case strings.Contains(lower, "model-worker") || strings.Contains(lower, "worker exited"):
		return "worker_exited", text
	default:
		if text == "" {
			text = "Der Vorgang ist fehlgeschlagen."
		}
		return "engine_operation_failed", text
	}
}

func (m *EngineModule) markCancelledInstance(id string) {
	m.setInstanceState(id, engineruntime.StateStopped, 0, "Vorgang wurde abgebrochen")
}
