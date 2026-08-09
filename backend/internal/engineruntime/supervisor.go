package engineruntime

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

type ProcessSpec struct {
	InstanceID         string                `json:"instance_id"`
	Argv               []string              `json:"-"`
	Environment        map[string]string     `json:"-"`
	InheritEnvironment bool                  `json:"-"`
	WorkingDirectory   string                `json:"-"`
	HealthPath         string                `json:"health_path"`
	HealthHeaders      map[string]string     `json:"-"`
	Progress           func(ProcessProgress) `json:"-"`
	GracePeriod        time.Duration         `json:"-"`
	ResourceLimits     ResourceLimits        `json:"-"`

	SpawnAdmission func(context.Context) (func(), error) `json:"-"`
}

type ProcessProgress struct {
	Phase         string
	Progress      float64
	Message       string
	DetailMessage string
	HTTPStatus    int
	Elapsed       time.Duration
}

type InstanceSnapshot struct {
	InstanceID string        `json:"instance_id"`
	State      InstanceState `json:"state"`
	PID        int           `json:"pid,omitempty"`
	Port       int           `json:"port,omitempty"`
	BaseURL    string        `json:"base_url,omitempty"`
	Error      string        `json:"error,omitempty"`
	StartedAt  *time.Time    `json:"started_at,omitempty"`
	ReadyAt    *time.Time    `json:"ready_at,omitempty"`
	StoppedAt  *time.Time    `json:"stopped_at,omitempty"`
	ExitCode   *int          `json:"exit_code,omitempty"`
}

type ProcessLogs struct {
	Stdout string `json:"stdout"`
	Stderr string `json:"stderr"`
}

type InstanceHandle struct {
	mu               sync.RWMutex
	snapshot         InstanceSnapshot
	cmd              *exec.Cmd
	stdout           *RingBuffer
	stderr           *RingBuffer
	done             chan struct{}
	doneOnce         sync.Once
	stopRequested    bool
	terminalOverride InstanceState
	gracePeriod      time.Duration
	lifetimeCleanup  func()
}

func (h *InstanceHandle) Snapshot() InstanceSnapshot {
	h.mu.RLock()
	defer h.mu.RUnlock()
	result := h.snapshot
	result.StartedAt = cloneTime(result.StartedAt)
	result.ReadyAt = cloneTime(result.ReadyAt)
	result.StoppedAt = cloneTime(result.StoppedAt)
	if result.ExitCode != nil {
		exitCode := *result.ExitCode
		result.ExitCode = &exitCode
	}
	return result
}

func (h *InstanceHandle) Logs() ProcessLogs {
	return ProcessLogs{Stdout: h.stdout.String(), Stderr: h.stderr.String()}
}

func (h *InstanceHandle) Done() <-chan struct{} { return h.done }

type SupervisorOptions struct {
	LogBytes        int
	HealthTimeout   time.Duration
	HealthInterval  time.Duration
	GracePeriod     time.Duration
	HTTPClient      *http.Client
	ResourceLimiter ResourceLimiter
}

type Supervisor struct {
	mu        sync.RWMutex
	instances map[string]*InstanceHandle
	options   SupervisorOptions
}

func NewSupervisor(options SupervisorOptions) *Supervisor {
	if options.LogBytes <= 0 {
		options.LogBytes = 256 * 1024
	}
	if options.HealthTimeout <= 0 {
		options.HealthTimeout = 90 * time.Second
	}
	if options.HealthInterval <= 0 {
		options.HealthInterval = 250 * time.Millisecond
	}
	if options.GracePeriod <= 0 {
		options.GracePeriod = 30 * time.Second
	}
	if options.HTTPClient == nil {
		options.HTTPClient = &http.Client{Timeout: 2 * time.Second}
	}
	if options.ResourceLimiter == nil {
		options.ResourceLimiter = NewNativeResourceLimiter()
	}
	return &Supervisor{instances: make(map[string]*InstanceHandle), options: options}
}

func (s *Supervisor) Start(ctx context.Context, spec ProcessSpec) (*InstanceHandle, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if strings.TrimSpace(spec.InstanceID) == "" {
		return nil, errors.New("instance ID is required")
	}
	if len(spec.Argv) == 0 || strings.TrimSpace(spec.Argv[0]) == "" {
		return nil, errors.New("process argv is required")
	}
	if spec.HealthPath == "" {
		spec.HealthPath = "/health"
	}
	if !strings.HasPrefix(spec.HealthPath, "/") && spec.HealthPath != "-" {
		return nil, errors.New("health path must start with / or be - to disable checking")
	}

	s.mu.Lock()
	if existing := s.instances[spec.InstanceID]; existing != nil {
		state := existing.Snapshot().State
		if state != StateStopped && state != StateFailed && state != StateFailedRollback {
			s.mu.Unlock()
			return nil, fmt.Errorf("instance %q is already %s", spec.InstanceID, state)
		}
	}
	handle := &InstanceHandle{
		snapshot:    InstanceSnapshot{InstanceID: spec.InstanceID, State: StateQueued},
		stdout:      NewRingBuffer(s.options.LogBytes),
		stderr:      NewRingBuffer(s.options.LogBytes),
		done:        make(chan struct{}),
		gracePeriod: spec.GracePeriod,
	}
	if handle.gracePeriod <= 0 {
		handle.gracePeriod = s.options.GracePeriod
	}
	s.instances[spec.InstanceID] = handle
	s.mu.Unlock()

	port, err := availableLoopbackPort()
	if err != nil {
		s.failBeforeStart(handle, err)
		return handle, err
	}
	argv := replacePort(spec.Argv, port)
	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Dir = spec.WorkingDirectory
	cmd.Env = workerEnvironment(spec.InheritEnvironment, spec.Environment)
	cmd.Stdout = io.Writer(handle.stdout)
	cmd.Stderr = io.Writer(handle.stderr)

	cmd.WaitDelay = 500 * time.Millisecond
	configureProcessGroup(cmd)
	if preparer, ok := s.options.ResourceLimiter.(ResourceLimitPreparer); ok {
		if err := preparer.Prepare(cmd, spec.ResourceLimits); err != nil {
			s.failBeforeStart(handle, fmt.Errorf("prepare worker resource limits: %w", err))
			return handle, err
		}
	}

	now := time.Now().UTC()
	handle.mu.Lock()
	handle.cmd = cmd
	handle.snapshot.State = StateStarting
	handle.snapshot.Port = port
	handle.snapshot.BaseURL = "http://127.0.0.1:" + strconv.Itoa(port)
	handle.snapshot.StartedAt = &now
	handle.mu.Unlock()
	releaseSpawn := func() {}
	if spec.SpawnAdmission != nil {
		var admissionErr error
		releaseSpawn, admissionErr = spec.SpawnAdmission(ctx)
		if admissionErr != nil {
			if aborter, ok := s.options.ResourceLimiter.(ResourceLimitPreparationAborter); ok {
				aborter.AbortPrepare(cmd)
			}
			s.failBeforeStart(handle, admissionErr)
			return handle, admissionErr
		}
		if releaseSpawn == nil {
			releaseSpawn = func() {}
		}
	}
	if err := ctx.Err(); err != nil {
		releaseSpawn()
		if aborter, ok := s.options.ResourceLimiter.(ResourceLimitPreparationAborter); ok {
			aborter.AbortPrepare(cmd)
		}
		s.failBeforeStart(handle, err)
		return handle, err
	}
	if err := cmd.Start(); err != nil {
		releaseSpawn()
		if aborter, ok := s.options.ResourceLimiter.(ResourceLimitPreparationAborter); ok {
			aborter.AbortPrepare(cmd)
		}
		s.failBeforeStart(handle, err)
		return handle, err
	}
	resourceCleanup, err := s.options.ResourceLimiter.Bind(cmd, spec.ResourceLimits)
	if err != nil {
		if aborter, ok := s.options.ResourceLimiter.(ResourceLimitPreparationAborter); ok {
			aborter.AbortPrepare(cmd)
		}
		_ = signalProcessGroup(cmd, true)
		_ = cmd.Wait()
		releaseSpawn()
		s.failBeforeStart(handle, fmt.Errorf("bind worker resource limits: %w", err))
		return handle, err
	}

	releaseSpawn()
	reportProcessProgress(spec, ProcessProgress{
		Phase: "loading_model", Progress: 0.70,
		Message:       "Modell wird geladen",
		DetailMessage: "Der Modellprozess wurde gestartet. Gewichte und KV-Cache werden in den Arbeitsspeicher geladen.",
	})
	lifetimeCleanup := func() {}
	if binder, ok := s.options.ResourceLimiter.(interface{ IncludesProcessLifetime() bool }); !ok || !binder.IncludesProcessLifetime() || spec.ResourceLimits.MemoryMaxBytes <= 0 {
		lifetimeCleanup, err = bindProcessLifetime(cmd)
	}
	if err != nil {
		_ = signalProcessGroup(cmd, true)
		_ = cmd.Wait()
		if resourceCleanup != nil {
			resourceCleanup()
		}
		s.failBeforeStart(handle, fmt.Errorf("bind worker lifetime: %w", err))
		return handle, err
	}
	combinedCleanup := func() {
		if lifetimeCleanup != nil {
			lifetimeCleanup()
		}
		if resourceCleanup != nil {
			resourceCleanup()
		}
	}
	handle.mu.Lock()
	handle.snapshot.PID = cmd.Process.Pid
	handle.lifetimeCleanup = combinedCleanup
	handle.mu.Unlock()
	go s.watch(handle)

	if spec.HealthPath == "-" {
		if err := markReady(handle); err != nil {
			return handle, err
		}
		return handle, nil
	}
	if err := s.waitHealthy(ctx, handle, spec); err != nil {
		s.stopWithTerminal(handle, StateFailed, fmt.Errorf("health check failed: %w", err))
		return handle, err
	}
	if err := markReady(handle); err != nil {
		return handle, err
	}
	return handle, nil
}

func (s *Supervisor) Instance(id string) (*InstanceHandle, bool) {
	s.mu.RLock()
	handle := s.instances[id]
	s.mu.RUnlock()
	return handle, handle != nil
}

func (s *Supervisor) Instances() []InstanceSnapshot {
	s.mu.RLock()
	handles := make([]*InstanceHandle, 0, len(s.instances))
	for _, handle := range s.instances {
		handles = append(handles, handle)
	}
	s.mu.RUnlock()
	result := make([]InstanceSnapshot, 0, len(handles))
	for _, handle := range handles {
		result = append(result, handle.Snapshot())
	}
	sort.Slice(result, func(a, b int) bool { return result[a].InstanceID < result[b].InstanceID })
	return result
}

func (s *Supervisor) Stop(ctx context.Context, id string) error {
	handle, ok := s.Instance(id)
	if !ok {
		return fmt.Errorf("instance %q not found", id)
	}
	return s.StopHandle(ctx, handle)
}

func (s *Supervisor) StopHandle(ctx context.Context, handle *InstanceHandle) error {
	if handle == nil {
		return errors.New("instance handle is required")
	}
	if err := s.validateStopHandle(handle); err != nil {
		return err
	}
	return s.stop(ctx, handle, StateStopped, nil)
}

func (s *Supervisor) ForceStop(ctx context.Context, id string) error {
	handle, ok := s.Instance(id)
	if !ok {
		return fmt.Errorf("instance %q not found", id)
	}
	return s.ForceStopHandle(ctx, handle)
}

func (s *Supervisor) ForceStopHandle(ctx context.Context, handle *InstanceHandle) error {
	if handle == nil {
		return errors.New("instance handle is required")
	}
	if err := s.validateStopHandle(handle); err != nil {
		return err
	}
	handle.mu.Lock()
	state := handle.snapshot.State
	if state == StateStopped || state == StateFailed || state == StateFailedRollback {
		handle.mu.Unlock()
		return nil
	}
	handle.stopRequested = true
	handle.terminalOverride = StateStopped
	handle.snapshot.State = StateDraining
	cmd := handle.cmd
	handle.mu.Unlock()
	if cmd == nil || cmd.Process == nil {
		s.failBeforeStart(handle, context.Canceled)
		return nil
	}
	killErr := signalProcessGroup(cmd, true)
	select {
	case <-handle.done:
		return nil
	case <-ctx.Done():
		if killErr != nil {
			return fmt.Errorf("worker force-stop unconfirmed (%v): %w", killErr, ctx.Err())
		}
		return fmt.Errorf("worker force-stop unconfirmed: %w", ctx.Err())
	}
}

func (s *Supervisor) validateStopHandle(handle *InstanceHandle) error {
	snapshot := handle.Snapshot()
	if snapshot.State == StateStopped || snapshot.State == StateFailed || snapshot.State == StateFailedRollback {
		return nil
	}
	s.mu.RLock()
	current := s.instances[snapshot.InstanceID]
	s.mu.RUnlock()
	if current != handle {

		snapshot = handle.Snapshot()
		if snapshot.State == StateStopped || snapshot.State == StateFailed || snapshot.State == StateFailedRollback {
			return nil
		}
		return fmt.Errorf("instance %q handle generation is no longer current", snapshot.InstanceID)
	}
	return nil
}

func (s *Supervisor) Shutdown(ctx context.Context) error {
	s.mu.RLock()
	handles := make([]*InstanceHandle, 0, len(s.instances))
	for _, handle := range s.instances {
		handles = append(handles, handle)
	}
	s.mu.RUnlock()
	var failures []string
	for _, handle := range handles {
		if err := s.stop(ctx, handle, StateStopped, nil); err != nil {
			failures = append(failures, handle.Snapshot().InstanceID+": "+err.Error())
		}
	}
	if len(failures) > 0 {
		return errors.New(strings.Join(failures, "; "))
	}
	return nil
}

func (s *Supervisor) waitHealthy(ctx context.Context, handle *InstanceHandle, spec ProcessSpec) error {
	startedAt := time.Now()
	timeout := time.NewTimer(s.options.HealthTimeout)
	defer timeout.Stop()
	ticker := time.NewTicker(s.options.HealthInterval)
	defer ticker.Stop()
	url := handle.Snapshot().BaseURL + spec.HealthPath
	var lastError error
	lastReportedPhase := ""

	const rssGrowthMinimum = 32 << 20
	const extensionCap = 30 * time.Minute
	workerPID := handle.Snapshot().PID
	lastRSS := processResidentBytes(workerPID)
	lastRSSProbe := time.Now()
	maybeExtendTimeout := func() {
		if workerPID <= 0 || time.Since(lastRSSProbe) < 5*time.Second || time.Since(startedAt) > extensionCap {
			return
		}
		lastRSSProbe = time.Now()
		current := processResidentBytes(workerPID)
		if current < 0 {
			return
		}
		if lastRSS >= 0 && current >= lastRSS+rssGrowthMinimum {
			if !timeout.Stop() {
				select {
				case <-timeout.C:
				default:
				}
			}
			timeout.Reset(s.options.HealthTimeout)
		}
		lastRSS = current
	}
	for {
		request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return err
		}
		for key, value := range spec.HealthHeaders {
			request.Header.Set(key, value)
		}
		response, err := s.options.HTTPClient.Do(request)
		if err == nil {
			_, _ = io.Copy(io.Discard, response.Body)
			_ = response.Body.Close()
			if response.StatusCode >= 200 && response.StatusCode < 300 {
				reportProcessProgress(spec, ProcessProgress{
					Phase: "worker_ready", Progress: 0.82,
					Message:       "Modell antwortet",
					DetailMessage: "Der lokale Modellserver ist erreichbar. Als Naechstes folgt ein kurzer Funktionstest.",
					HTTPStatus:    response.StatusCode, Elapsed: time.Since(startedAt),
				})
				return nil
			}
			lastError = fmt.Errorf("HTTP %d", response.StatusCode)
			if lastReportedPhase != "worker_initializing" {
				lastReportedPhase = "worker_initializing"
				reportProcessProgress(spec, ProcessProgress{
					Phase: "worker_initializing", Progress: 0.76,
					Message:       "Modellserver initialisiert sich",
					DetailMessage: fmt.Sprintf("Der Modellprozess antwortet bereits, ist aber noch nicht bereit (HTTP %d auf %s).", response.StatusCode, spec.HealthPath),
					HTTPStatus:    response.StatusCode, Elapsed: time.Since(startedAt),
				})
			}
		} else {
			lastError = err
			if lastReportedPhase != "loading_model" {
				lastReportedPhase = "loading_model"
				reportProcessProgress(spec, ProcessProgress{
					Phase: "loading_model", Progress: 0.70,
					Message:       "Modell wird in den Speicher geladen",
					DetailMessage: "Der Modellprozess laeuft. Der lokale API-Port wird nach dem Laden der Gewichte geoeffnet.",
					Elapsed:       time.Since(startedAt),
				})
			}
		}

		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-handle.done:
			snapshot := handle.Snapshot()
			if snapshot.Error != "" {
				return errors.New(snapshot.Error)
			}
			return errors.New("worker exited before becoming healthy")
		case <-timeout.C:
			if lastError == nil {
				lastError = errors.New("no successful response")
			}
			return fmt.Errorf("timeout: %w", lastError)
		case <-ticker.C:
			maybeExtendTimeout()
		}
	}
}

func reportProcessProgress(spec ProcessSpec, progress ProcessProgress) {
	if spec.Progress != nil {
		spec.Progress(progress)
	}
}

func (s *Supervisor) watch(handle *InstanceHandle) {
	err := handle.cmd.Wait()

	_ = signalProcessGroup(handle.cmd, true)
	handle.mu.Lock()
	cleanup := handle.lifetimeCleanup
	handle.lifetimeCleanup = nil
	handle.mu.Unlock()
	if cleanup != nil {
		cleanup()
	}
	now := time.Now().UTC()
	exitCode := -1
	if handle.cmd.ProcessState != nil {
		exitCode = handle.cmd.ProcessState.ExitCode()
	}
	handle.mu.Lock()
	handle.snapshot.ExitCode = &exitCode
	handle.snapshot.StoppedAt = &now
	if handle.terminalOverride != "" {
		handle.snapshot.State = handle.terminalOverride
	} else if handle.stopRequested {
		handle.snapshot.State = StateStopped
	} else {
		handle.snapshot.State = StateFailed
		if err == nil {
			handle.snapshot.Error = "worker exited unexpectedly"
		} else {
			handle.snapshot.Error = summarizeWorkerExit(exitCode, handle.stderr.String(), err)
		}
	}
	handle.mu.Unlock()
	handle.doneOnce.Do(func() { close(handle.done) })
}

func summarizeWorkerExit(exitCode int, stderr string, processErr error) string {
	code, summary := FormatWorkerExit(exitCode, stderr, processErr)
	if code == "worker_exit" {

		return summary
	}
	return MarkDiagnosis(code, summary)
}

func (s *Supervisor) stopWithTerminal(handle *InstanceHandle, terminal InstanceState, cause error) {
	ctx, cancel := context.WithTimeout(context.Background(), handle.gracePeriod+2*time.Second)
	defer cancel()
	_ = s.stop(ctx, handle, terminal, cause)
}

func (s *Supervisor) stop(ctx context.Context, handle *InstanceHandle, terminal InstanceState, cause error) error {
	handle.mu.Lock()
	state := handle.snapshot.State
	if state == StateStopped || state == StateFailed || state == StateFailedRollback {
		handle.mu.Unlock()
		return nil
	}
	handle.stopRequested = true
	handle.terminalOverride = terminal
	if cause != nil {
		handle.snapshot.Error = cause.Error()
	}
	if terminal == StateStopped {
		handle.snapshot.State = StateDraining
	}
	cmd := handle.cmd
	grace := handle.gracePeriod
	handle.mu.Unlock()
	if cmd == nil || cmd.Process == nil {
		s.failBeforeStart(handle, cause)
		return nil
	}

	_ = signalProcessGroup(cmd, false)
	timer := time.NewTimer(grace)
	defer timer.Stop()
	select {
	case <-handle.done:
		return nil
	case <-ctx.Done():
		killErr := signalProcessGroup(cmd, true)
		select {
		case <-handle.done:

			return nil
		case <-time.After(2 * time.Second):
			if killErr != nil {
				return fmt.Errorf("worker termination unconfirmed after force kill (%v): %w", killErr, ctx.Err())
			}
			return fmt.Errorf("worker termination unconfirmed after force kill: %w", ctx.Err())
		}
	case <-timer.C:
		killErr := signalProcessGroup(cmd, true)
		select {
		case <-handle.done:
			return nil
		case <-ctx.Done():
			select {
			case <-handle.done:
				return nil
			case <-time.After(2 * time.Second):
				if killErr != nil {
					return fmt.Errorf("worker termination unconfirmed after force kill (%v): %w", killErr, ctx.Err())
				}
				return fmt.Errorf("worker termination unconfirmed after force kill: %w", ctx.Err())
			}
		case <-time.After(2 * time.Second):
			if killErr != nil {
				return fmt.Errorf("worker did not exit after force kill: %w", killErr)
			}
			return errors.New("worker did not exit after force kill")
		}
	}
}

func (s *Supervisor) failBeforeStart(handle *InstanceHandle, err error) {
	now := time.Now().UTC()
	handle.mu.Lock()
	handle.snapshot.State = StateFailed
	if err != nil {
		handle.snapshot.Error = err.Error()
	}
	handle.snapshot.StoppedAt = &now
	handle.mu.Unlock()
	handle.doneOnce.Do(func() { close(handle.done) })
}

func markReady(handle *InstanceHandle) error {
	now := time.Now().UTC()
	handle.mu.Lock()
	defer handle.mu.Unlock()
	select {
	case <-handle.done:
		if handle.snapshot.Error != "" {
			return errors.New(handle.snapshot.Error)
		}
		return errors.New("worker exited while starting")
	default:
	}
	handle.snapshot.State = StateReady
	handle.snapshot.ReadyAt = &now
	return nil
}

func availableLoopbackPort() (int, error) {
	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		return 0, err
	}
	defer listener.Close()
	return listener.Addr().(*net.TCPAddr).Port, nil
}

func replacePort(argv []string, port int) []string {
	result := make([]string, len(argv))
	value := strconv.Itoa(port)
	for index, arg := range argv {
		result[index] = strings.ReplaceAll(arg, PortPlaceholder, value)
	}
	return result
}

var inheritedWorkerEnvironment = map[string]struct{}{
	"PATH": {}, "HOME": {}, "USERPROFILE": {}, "TMP": {}, "TEMP": {}, "TMPDIR": {},
	"LANG": {}, "LC_ALL": {}, "LD_LIBRARY_PATH": {}, "DYLD_LIBRARY_PATH": {},
	"CUDA_HOME": {}, "CUDA_PATH": {}, "ROCM_PATH": {}, "HIP_PATH": {},
}

func workerEnvironment(inherit bool, extra map[string]string) []string {
	base := make([]string, 0)
	if inherit {
		base = os.Environ()
	} else {
		for _, entry := range os.Environ() {
			key := entry
			if index := strings.IndexByte(entry, '='); index >= 0 {
				key = entry[:index]
			}
			if _, allowed := inheritedWorkerEnvironment[key]; allowed {
				base = append(base, entry)
			}
		}
	}
	defaults := map[string]string{
		"HF_HUB_OFFLINE":         "1",
		"TRANSFORMERS_OFFLINE":   "1",
		"TOKENIZERS_PARALLELISM": "false",
	}
	for key, value := range extra {
		defaults[key] = value
	}
	return mergeEnvironment(base, defaults)
}
