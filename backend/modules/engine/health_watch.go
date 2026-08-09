// What happens when a worker dies on its own.
//
// Detection already existed: monitorWorker waits on the process handle and
// moves the instance to failed, which is what stops it being advertised. What
// was missing is everything after that. The instance sat in failed until
// somebody noticed and pressed start, and on a machine that had been left alone
// overnight that meant the model was simply gone.
//
// Two things live here. A restart, which the owner switches on per instance and
// which backs off so a model that crashes on load does not spin. And a
// reconcile pass, which is the safety net for the case the handle watcher
// cannot cover: a supervisor entry that reached a terminal state without its
// watcher running, for instance because the handle was replaced underneath it.

package engine

import (
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
)

// crashRestartBackoff is how long to wait before each successive restart of the
// same instance. A model that dies during load would otherwise be restarted as
// fast as it can fail, which is the one case where an automatic restart hurts
// more than it helps. The last entry repeats.
var crashRestartBackoff = []time.Duration{
	5 * time.Second, 30 * time.Second, 2 * time.Minute, 10 * time.Minute,
}

// crashRestartForgetAfter is how long an instance has to stay up before its
// crash history is dropped. A model that ran for an hour and then died is a new
// incident, not the fifth attempt of an old one.
const crashRestartForgetAfter = 30 * time.Minute

type crashHistory struct {
	failures   int
	lastCrash  time.Time
	restarting bool
}

// considerCrashRestart is called right after an instance has been moved to
// failed because its worker went away. It is a no-op unless the owner asked for
// the restart, which keeps a model that cannot load from looping forever
// without anyone having chosen that.
func (m *EngineModule) considerCrashRestart(instanceID string) {
	m.mu.RLock()
	instance := m.instances[instanceID]
	shuttingDown := m.shuttingDown
	var generation uint64
	var config EngineConfig
	wanted := false
	if instance != nil {
		generation = instance.workerGeneration
		config = cloneEngineConfig(instance.RequestedConfig)
		wanted = instance.RequestedConfig.RestartOnCrash || instance.EffectiveConfig.RestartOnCrash
	}
	m.mu.RUnlock()
	if instance == nil || shuttingDown || !wanted {
		return
	}

	now := time.Now()
	m.crashMu.Lock()
	if m.crashHistory == nil {
		m.crashHistory = map[string]*crashHistory{}
	}
	history := m.crashHistory[instanceID]
	if history == nil || now.Sub(history.lastCrash) > crashRestartForgetAfter {
		history = &crashHistory{}
		m.crashHistory[instanceID] = history
	}
	if history.restarting {
		m.crashMu.Unlock()
		return
	}
	delay := crashRestartBackoff[minInt(history.failures, len(crashRestartBackoff)-1)]
	history.failures++
	history.lastCrash = now
	history.restarting = true
	attempt := history.failures
	m.crashMu.Unlock()

	log.Printf("[engine] restarting %s after a crash in %s (attempt %d)", instanceID, delay, attempt)
	m.setInstanceStateDetail(instanceID, engineruntime.StateFailed, 0, "crash_restart_pending",
		fmt.Sprintf("Der Modellprozess wird in %s automatisch neu gestartet (Versuch %d).", formatRestartDelay(delay), attempt), "")

	go m.runCrashRestart(instanceID, generation, config, delay)
}

func (m *EngineModule) runCrashRestart(instanceID string, generation uint64, config EngineConfig, delay time.Duration) {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-m.maintenanceStop:
		m.clearCrashRestarting(instanceID)
		return
	case <-timer.C:
	}
	defer m.clearCrashRestarting(instanceID)

	m.mu.RLock()
	instance := m.instances[instanceID]
	// Anything that touched the instance in the meantime - a manual start, a
	// delete, a stop - takes precedence over the automatic restart. The worker
	// generation is what tells those apart from the crash this call is about.
	stale := instance == nil || instance.State != engineruntime.StateFailed ||
		instance.workerGeneration != generation || m.shuttingDown
	m.mu.RUnlock()
	if stale {
		return
	}
	if _, err := m.scheduleStart(instanceID, config, "crash_restart"); err != nil {
		log.Printf("[engine] automatic restart of %s could not be scheduled: %v", instanceID, err)
		m.setInstanceStateDetail(instanceID, engineruntime.StateFailed, 0, "crash_restart_failed",
			"Der automatische Neustart konnte nicht eingeplant werden: "+err.Error(), "")
	}
}

func (m *EngineModule) clearCrashRestarting(instanceID string) {
	m.crashMu.Lock()
	if history := m.crashHistory[instanceID]; history != nil {
		history.restarting = false
	}
	m.crashMu.Unlock()
}

// noteInstanceRecovered drops the crash history of an instance that came up, so
// a later crash starts its backoff from the beginning rather than from wherever
// an old incident left off.
func (m *EngineModule) noteInstanceRecovered(instanceID string) {
	m.crashMu.Lock()
	delete(m.crashHistory, instanceID)
	m.crashMu.Unlock()
}

func formatRestartDelay(delay time.Duration) string {
	if delay < time.Minute {
		return fmt.Sprintf("%d Sekunden", int(delay.Seconds()))
	}
	return fmt.Sprintf("%d Minuten", int(delay.Minutes()))
}

// reconcileWorkers is the safety net behind monitorWorker. It compares what the
// module believes is ready against what the supervisor still has, and closes
// the gap for anything the handle watcher missed.
//
// It is deliberately narrow. Only a ready instance with no operation of its own
// in flight is considered, so this never races a start, a stop or a restart
// that already owns the transition, and an instance the supervisor simply does
// not know about is left alone rather than guessed at - that is the normal
// shape of a state that was just restored from disk.
func (m *EngineModule) reconcileWorkers() {
	if m.supervisor == nil {
		return
	}
	m.mu.RLock()
	shuttingDown := m.shuttingDown
	m.mu.RUnlock()
	if shuttingDown {
		return
	}

	terminal := map[string]engineruntime.InstanceSnapshot{}
	for _, snapshot := range m.supervisor.Instances() {
		if terminalSupervisorState(snapshot.State) {
			terminal[snapshot.InstanceID] = snapshot
		}
	}
	if len(terminal) == 0 {
		return
	}

	lost := []string{}
	m.mu.Lock()
	for id, instance := range m.instances {
		if instance == nil || instance.State != engineruntime.StateReady {
			continue
		}
		if m.activeStartOperationLocked(id) != nil {
			continue
		}
		snapshot, dead := terminal[id]
		if !dead {
			continue
		}
		reason := strings.TrimSpace(snapshot.Error)
		if reason == "" {
			reason = "Der Modellprozess wurde beendet."
		}
		if snapshot.ExitCode != nil {
			reason = fmt.Sprintf("%s (Exit-Code %d)", strings.TrimSuffix(reason, "."), *snapshot.ExitCode)
		}
		instance.State = engineruntime.StateFailed
		instance.Phase = "worker_exited"
		instance.Progress = 0
		// Clearing these is the point: they are what the chat picker and the
		// local gateway read to decide the instance can serve a request.
		instance.BaseURL = ""
		instance.WorkerSecret = ""
		instance.ActiveRequests = 0
		instance.IdleExpiresAt = nil
		instance.Error = reason
		instance.ErrorCode = "worker_exited"
		instance.ErrorSummary = reason
		instance.DetailMessage = reason
		instance.UpdatedAt = time.Now().UTC()
		snapshotCopy := cloneInstance(instance)
		lost = append(lost, id)
		log.Printf("[engine] reconcile found the worker for %s gone: %s", id, sanitizeEngineLogText(reason))
		m.events.publish("instance_changed", snapshotCopy)
	}
	if len(lost) > 0 {
		_ = m.persistLocked()
	}
	m.mu.Unlock()

	for _, id := range lost {
		m.considerCrashRestart(id)
	}
}

// instanceLogs returns the worker's own output. The supervisor keeps a bounded
// ring buffer per stream, so this is always the tail of the run, never all of
// it.
func (m *EngineModule) instanceLogs(instanceID string, tail int) (engineruntime.ProcessLogs, error) {
	if m.supervisor == nil {
		return engineruntime.ProcessLogs{}, fmt.Errorf("der Prozess-Supervisor ist nicht verfuegbar")
	}
	handle, ok := m.supervisor.Instance(strings.TrimSpace(instanceID))
	if !ok {
		return engineruntime.ProcessLogs{}, fmt.Errorf("fuer diese Instanz liegt derzeit keine Prozessausgabe vor; sie liegt nur vor, solange der Prozess existiert")
	}
	logs := handle.Logs()
	return engineruntime.ProcessLogs{
		Stdout: tailLines(logs.Stdout, tail),
		Stderr: tailLines(logs.Stderr, tail),
	}, nil
}

// tailLines trims a log to its last n lines, which is what a caller asking for
// "the end of the output" means. A non-positive limit keeps everything.
func tailLines(text string, limit int) string {
	if limit <= 0 {
		return text
	}
	lines := strings.Split(strings.TrimRight(text, "\n"), "\n")
	if len(lines) <= limit {
		return strings.Join(lines, "\n")
	}
	return strings.Join(lines[len(lines)-limit:], "\n")
}
