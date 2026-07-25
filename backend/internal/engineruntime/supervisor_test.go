package engineruntime

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"testing"
	"time"
)

type orderedTestLimiter struct {
	mu       sync.Mutex
	prepared bool
	bound    bool
}

type blockingBindLimiter struct {
	entered chan struct{}
	proceed chan struct{}
	mu      sync.Mutex
	resumed bool
}

func (l *blockingBindLimiter) Bind(*exec.Cmd, ResourceLimits) (func(), error) {
	close(l.entered)
	<-l.proceed
	l.mu.Lock()
	l.resumed = true
	l.mu.Unlock()
	return func() {}, nil
}

func (l *orderedTestLimiter) Prepare(cmd *exec.Cmd, limits ResourceLimits) error {
	l.mu.Lock()
	defer l.mu.Unlock()
	if cmd.Process != nil || limits.MemoryMaxBytes != 1234 {
		return fmt.Errorf("unexpected prepare state")
	}
	l.prepared = true
	return nil
}

func (l *orderedTestLimiter) Bind(cmd *exec.Cmd, limits ResourceLimits) (func(), error) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if !l.prepared || cmd.Process == nil || limits.MemoryMaxBytes != 1234 {
		return nil, fmt.Errorf("limiter bind happened before prepare/start")
	}
	l.bound = true
	return func() {}, nil
}

func TestSupervisorPreparesAndBindsResourceLimit(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	limiter := &orderedTestLimiter{}
	supervisor := NewSupervisor(SupervisorOptions{
		HealthTimeout: time.Second, HealthInterval: 10 * time.Millisecond, GracePeriod: 100 * time.Millisecond,
		ResourceLimiter: limiter,
	})
	spec := helperSpec("limited", "server", PortPlaceholder)
	spec.ResourceLimits.MemoryMaxBytes = 1234
	handle, err := supervisor.Start(context.Background(), spec)
	if err != nil {
		t.Fatal(err)
	}
	limiter.mu.Lock()
	prepared, bound := limiter.prepared, limiter.bound
	limiter.mu.Unlock()
	if !prepared || !bound {
		t.Fatalf("limiter prepare=%v bind=%v", prepared, bound)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	if err := supervisor.Stop(ctx, handle.Snapshot().InstanceID); err != nil {
		t.Fatal(err)
	}
}

func TestSupervisorRejectsCanceledContextBeforeRegisteringProcess(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	supervisor := NewSupervisor(SupervisorOptions{})
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	handle, err := supervisor.Start(ctx, helperSpec("never-spawned", "server", PortPlaceholder))
	if !errors.Is(err, context.Canceled) || handle != nil {
		t.Fatalf("canceled start handle=%#v err=%v", handle, err)
	}
	if _, exists := supervisor.Instance("never-spawned"); exists {
		t.Fatal("canceled context registered a supervisor process")
	}
}

func TestSupervisorSpawnAdmissionRevalidatesBeforeCmdStart(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	supervisor := NewSupervisor(SupervisorOptions{})
	wanted := errors.New("guard changed")
	spec := helperSpec("guard-denied", "server", PortPlaceholder)
	spec.SpawnAdmission = func(context.Context) (func(), error) { return nil, wanted }
	handle, err := supervisor.Start(context.Background(), spec)
	if !errors.Is(err, wanted) || handle == nil {
		t.Fatalf("spawn admission handle=%#v err=%v", handle, err)
	}
	if snapshot := handle.Snapshot(); snapshot.State != StateFailed || snapshot.PID != 0 {
		t.Fatalf("denied process snapshot = %#v", snapshot)
	}
}

func TestSupervisorHoldsSpawnAdmissionThroughWorkerRelease(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	limiter := &blockingBindLimiter{entered: make(chan struct{}), proceed: make(chan struct{})}
	supervisor := NewSupervisor(SupervisorOptions{ResourceLimiter: limiter})
	var transitionGate sync.Mutex
	spec := helperSpec("atomic-release", "server", PortPlaceholder)
	spec.HealthPath = "-"
	spec.SpawnAdmission = func(context.Context) (func(), error) {
		transitionGate.Lock()
		return transitionGate.Unlock, nil
	}
	type startResult struct {
		handle *InstanceHandle
		err    error
	}
	started := make(chan startResult, 1)
	go func() {
		handle, err := supervisor.Start(context.Background(), spec)
		started <- startResult{handle: handle, err: err}
	}()
	select {
	case <-limiter.entered:
	case <-time.After(time.Second):
		t.Fatal("resource Bind was not reached")
	}

	transitioned := make(chan bool, 1)
	go func() {
		transitionGate.Lock()
		limiter.mu.Lock()
		resumed := limiter.resumed
		limiter.mu.Unlock()
		transitionGate.Unlock()
		transitioned <- resumed
	}()
	select {
	case <-transitioned:
		t.Fatal("guard transition crossed spawn admission before Bind released the worker")
	case <-time.After(50 * time.Millisecond):
	}
	close(limiter.proceed)
	select {
	case resumed := <-transitioned:
		if !resumed {
			t.Fatal("guard transition became visible before worker resume")
		}
	case <-time.After(time.Second):
		t.Fatal("spawn admission was not released after Bind")
	}
	result := <-started
	if result.err != nil {
		t.Fatal(result.err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := supervisor.Stop(ctx, result.handle.Snapshot().InstanceID); err != nil {
		t.Fatal(err)
	}
}

func TestSupervisorForceStopSkipsGracePeriodAndConfirmsExit(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	supervisor := NewSupervisor(SupervisorOptions{GracePeriod: 30 * time.Second})
	handle, err := supervisor.Start(context.Background(), helperSpec("force-now", "server", PortPlaceholder))
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	started := time.Now()
	if err := supervisor.ForceStop(ctx, "force-now"); err != nil {
		t.Fatal(err)
	}
	if time.Since(started) > time.Second {
		t.Fatal("ForceStop waited for graceful period")
	}
	select {
	case <-handle.Done():
	default:
		t.Fatal("ForceStop returned before process watcher confirmation")
	}
}

func TestSupervisorStartsHealthyWorkerAndStopsGracefully(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	t.Setenv("OPENAI_API_KEY", "must-not-reach-worker")
	supervisor := NewSupervisor(SupervisorOptions{
		HealthTimeout:  4 * time.Second,
		HealthInterval: 20 * time.Millisecond,
		GracePeriod:    time.Second,
	})
	ctx, cancel := context.WithTimeout(context.Background(), 6*time.Second)
	defer cancel()
	spec := helperSpec("healthy", "server", PortPlaceholder)
	startupPhases := []string{}
	spec.Progress = func(progress ProcessProgress) { startupPhases = append(startupPhases, progress.Phase) }
	handle, err := supervisor.Start(ctx, spec)
	if err != nil {
		t.Fatal(err)
	}
	snapshot := handle.Snapshot()
	if snapshot.State != StateReady || snapshot.Port <= 0 || !strings.HasPrefix(snapshot.BaseURL, "http://127.0.0.1:") {
		t.Fatalf("unexpected ready snapshot: %#v", snapshot)
	}
	if !containsString(startupPhases, "loading_model") || !containsString(startupPhases, "worker_ready") {
		t.Fatalf("startup phases = %#v", startupPhases)
	}
	if err := supervisor.Stop(ctx, "healthy"); err != nil {
		t.Fatal(err)
	}
	snapshot = handle.Snapshot()
	if snapshot.State != StateStopped {
		t.Fatalf("state after stop = %s, error=%s", snapshot.State, snapshot.Error)
	}
	logs := handle.Logs()
	if !strings.Contains(logs.Stdout, "helper-ready") {
		t.Fatalf("stdout not captured: %q", logs.Stdout)
	}
	if strings.Contains(logs.Stdout, "must-not-reach-worker") {
		t.Fatalf("provider secret leaked to worker: %q", logs.Stdout)
	}
	if !strings.Contains(logs.Stderr, "helper-stopping") {
		t.Fatalf("stderr not captured: %q", logs.Stderr)
	}
}

func TestSupervisorExpiredStopContextStillConfirmsForceKill(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	supervisor := NewSupervisor(SupervisorOptions{
		HealthTimeout:  3 * time.Second,
		HealthInterval: 20 * time.Millisecond,
		GracePeriod:    30 * time.Second,
	})
	handle, err := supervisor.Start(context.Background(), helperSpec("forced-stop", "server", PortPlaceholder))
	if err != nil {
		t.Fatal(err)
	}
	expired, cancel := context.WithCancel(context.Background())
	cancel()
	if err := supervisor.Stop(expired, "forced-stop"); err != nil {
		t.Fatalf("confirmed force-kill returned an error: %v", err)
	}
	select {
	case <-handle.Done():
	default:
		t.Fatal("Stop returned before the worker was reaped")
	}
	if snapshot := handle.Snapshot(); snapshot.State != StateStopped || snapshot.StoppedAt == nil {
		t.Fatalf("unconfirmed terminal snapshot: %#v", snapshot)
	}
}

func TestSupervisorReportsRespondingButWrongHealthEndpoint(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	supervisor := NewSupervisor(SupervisorOptions{
		HealthTimeout: 120 * time.Millisecond, HealthInterval: 20 * time.Millisecond, GracePeriod: 100 * time.Millisecond,
	})
	spec := helperSpec("wrong-health", "server", PortPlaceholder)
	spec.HealthPath = "/missing"
	phases := []string{}
	spec.Progress = func(progress ProcessProgress) { phases = append(phases, progress.Phase) }
	_, err := supervisor.Start(context.Background(), spec)
	if err == nil || !strings.Contains(err.Error(), "HTTP 404") {
		t.Fatalf("health error = %v", err)
	}
	if !containsString(phases, "worker_initializing") {
		t.Fatalf("health phases = %#v", phases)
	}
}

func containsString(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}

func TestSupervisorCrashWatcherMarksUnexpectedExitFailed(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	supervisor := NewSupervisor(SupervisorOptions{GracePeriod: 100 * time.Millisecond})
	spec := helperSpec("crasher", "crash")
	spec.HealthPath = "-"
	handle, err := supervisor.Start(context.Background(), spec)
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-handle.Done():
	case <-time.After(3 * time.Second):
		t.Fatal("crash watcher did not complete")
	}
	snapshot := handle.Snapshot()
	if snapshot.State != StateFailed || snapshot.ExitCode == nil || *snapshot.ExitCode != 7 {
		t.Fatalf("unexpected crash snapshot: %#v", snapshot)
	}
	if !strings.Contains(snapshot.Error, "deliberate-crash") || strings.Contains(snapshot.Error, "exit status") {
		t.Fatalf("worker failure was not summarized usefully: %q", snapshot.Error)
	}
	if !strings.Contains(handle.Logs().Stderr, "deliberate-crash") {
		t.Fatalf("stderr was not retained: %#v", handle.Logs())
	}
}

func TestSupervisorHealthCheckUsesHeaders(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") == "1" {
		return
	}
	supervisor := NewSupervisor(SupervisorOptions{
		HealthTimeout:  3 * time.Second,
		HealthInterval: 20 * time.Millisecond,
		GracePeriod:    time.Second,
	})
	spec := helperSpec("authenticated", "auth-server", PortPlaceholder, "worker-secret")
	spec.HealthHeaders = map[string]string{"Authorization": "Bearer worker-secret"}
	handle, err := supervisor.Start(context.Background(), spec)
	if err != nil {
		t.Fatal(err)
	}
	if handle.Snapshot().State != StateReady {
		t.Fatalf("state=%s", handle.Snapshot().State)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	if err := supervisor.Stop(ctx, "authenticated"); err != nil {
		t.Fatal(err)
	}
}

func helperSpec(id string, arguments ...string) ProcessSpec {
	argv := []string{os.Args[0], "-test.run=TestSupervisorHelperProcess", "--"}
	argv = append(argv, arguments...)
	return ProcessSpec{
		InstanceID: id,
		Argv:       argv,
		Environment: map[string]string{
			"PHILOENGINE_HELPER_PROCESS": "1",
		},
		HealthPath: "/health",
	}
}

// TestSupervisorHelperProcess is re-executed by supervisor tests. It is not a
// unit test in the child: os.Exit prevents the testing harness from continuing.
func TestSupervisorHelperProcess(t *testing.T) {
	if os.Getenv("PHILOENGINE_HELPER_PROCESS") != "1" {
		return
	}
	separator := -1
	for index, arg := range os.Args {
		if arg == "--" {
			separator = index
			break
		}
	}
	if separator < 0 || separator+1 >= len(os.Args) {
		os.Exit(2)
	}
	args := os.Args[separator+1:]
	if args[0] == "crash" {
		_, _ = fmt.Fprintln(os.Stderr, "deliberate-crash")
		time.Sleep(80 * time.Millisecond)
		os.Exit(7)
	}
	if len(args) < 2 {
		os.Exit(2)
	}
	port, err := strconv.Atoi(args[1])
	if err != nil {
		os.Exit(2)
	}
	wantedAuthorization := ""
	if args[0] == "auth-server" {
		if len(args) < 3 {
			os.Exit(2)
		}
		wantedAuthorization = "Bearer " + args[2]
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(writer http.ResponseWriter, request *http.Request) {
		if wantedAuthorization != "" && request.Header.Get("Authorization") != wantedAuthorization {
			http.Error(writer, "unauthorized", http.StatusUnauthorized)
			return
		}
		writer.WriteHeader(http.StatusOK)
	})
	listener, err := net.Listen("tcp4", "127.0.0.1:"+strconv.Itoa(port))
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		os.Exit(3)
	}
	server := &http.Server{Handler: mux}
	go func() { _ = server.Serve(listener) }()
	_, _ = fmt.Fprintln(os.Stdout, "helper-ready secret="+os.Getenv("OPENAI_API_KEY"))
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt, syscall.SIGTERM)
	<-signals
	_, _ = fmt.Fprintln(os.Stderr, "helper-stopping")
	shutdownContext, cancel := context.WithTimeout(context.Background(), time.Second)
	_ = server.Shutdown(shutdownContext)
	cancel()
	os.Exit(0)
}
