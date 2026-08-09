package engine

import (
	"context"
	"io"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"github.com/culpeohq/backend/internal/engineruntime"
	"github.com/culpeohq/backend/internal/hardware"
)

type successfulPrewarmRunner struct{}

func (successfulPrewarmRunner) Run(context.Context, []string, []string, io.Writer) error { return nil }

type cancelFirstPrewarmRunner struct {
	mu            sync.Mutex
	calls         int
	firstStarted  chan struct{}
	firstCanceled chan struct{}
	startOnce     sync.Once
	cancelOnce    sync.Once
}

type stubbornPrewarmRunner struct {
	started chan struct{}
	release chan struct{}
	once    sync.Once
}

func (r *stubbornPrewarmRunner) Run(context.Context, []string, []string, io.Writer) error {
	r.once.Do(func() { close(r.started) })
	<-r.release
	return context.Canceled
}

func (r *cancelFirstPrewarmRunner) Run(ctx context.Context, _ []string, _ []string, _ io.Writer) error {
	r.mu.Lock()
	r.calls++
	call := r.calls
	r.mu.Unlock()
	if call != 1 {
		return nil
	}
	r.startOnce.Do(func() { close(r.firstStarted) })
	<-ctx.Done()
	r.cancelOnce.Do(func() { close(r.firstCanceled) })
	return ctx.Err()
}

func prewarmTestHardware() hardware.Snapshot {
	return hardware.Snapshot{RAMTotalBytes: 32 << 30, RAMAvailableBytes: 24 << 30}
}

func waitForPrewarmCondition(t *testing.T, condition func() bool) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if condition() {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("prewarm condition was not reached")
}

func TestBackgroundPrewarmIsContentDeduplicated(t *testing.T) {
	root := t.TempDir()
	module := New(filepath.Join(root, "settings.json"))
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), nil, successfulPrewarmRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	build := newTestLlamaBuild(t, engineruntime.BuildCPU)
	candidates := []runtimePrewarmCandidate{{build: build, purpose: "llama.cpp CPU-Fallback wird vorbereitet"}}

	module.runRuntimePrewarm("Test", candidates)
	module.runRuntimePrewarm("Test", candidates)

	jobs := installer.Jobs()
	if len(jobs) != 1 || jobs[0].Status != engineruntime.InstallReady {
		t.Fatalf("jobs = %#v", jobs)
	}
	module.mu.RLock()
	operationCount := len(module.operations)
	module.mu.RUnlock()
	if operationCount != 1 {
		t.Fatalf("prewarm operations = %d, want 1", operationCount)
	}
}

func TestRunningPrewarmPausesOnWarningAndResumesExactlyOnce(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), nil, runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	candidate := runtimePrewarmCandidate{build: newTestLlamaBuild(t, engineruntime.BuildCPU), purpose: "niedrig priorisierte Runtime"}

	go module.runRuntimePrewarm("Test", []runtimePrewarmCandidate{candidate})
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("prewarm process did not start")
	}
	module.setGuardState(GuardWarning)
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("warning did not cancel the running prewarm process")
	}
	var jobs []engineruntime.InstallJobSnapshot
	waitForPrewarmCondition(t, func() bool {
		jobs = installer.Jobs()
		return len(jobs) == 1 && jobs[0].Status == engineruntime.InstallCanceled
	})
	if len(jobs) != 1 || jobs[0].Status != engineruntime.InstallCanceled {
		t.Fatalf("paused jobs = %#v", jobs)
	}
	time.Sleep(100 * time.Millisecond)
	if len(installer.Jobs()) != 1 {
		t.Fatal("prewarm restarted while guard was non-normal")
	}

	module.setGuardState(GuardNormal)
	waitForPrewarmCondition(t, func() bool {
		jobs = installer.Jobs()
		return len(jobs) == 2 && jobs[1].Status == engineruntime.InstallReady
	})
	module.runRuntimePrewarm("duplicate", []runtimePrewarmCandidate{candidate})
	if jobs = installer.Jobs(); len(jobs) != 2 {
		t.Fatalf("resumed candidate was duplicated: %#v", jobs)
	}
	module.mu.RLock()
	defer module.mu.RUnlock()
	completed, cancelled := 0, 0
	for _, operation := range module.operations {
		if operation.Type != "runtime_prewarm" {
			continue
		}
		switch operation.State {
		case "completed":
			completed++
		case "cancelled":
			cancelled++
		}
	}
	if completed != 1 || cancelled != 1 {
		t.Fatalf("prewarm operation states: completed=%d cancelled=%d", completed, cancelled)
	}
}

func TestForegroundRuntimePreemptsAndHoldsBackgroundPrewarm(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), nil, runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	candidate := runtimePrewarmCandidate{build: newTestLlamaBuild(t, engineruntime.BuildCPU), purpose: "background"}
	go module.runRuntimePrewarm("Test", []runtimePrewarmCandidate{candidate})
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("prewarm process did not start")
	}
	release, err := module.beginForegroundRuntime(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("foreground work did not preempt prewarm")
	}
	time.Sleep(100 * time.Millisecond)
	if len(installer.Jobs()) != 1 {
		t.Fatal("background prewarm restarted while foreground admission was held")
	}
	release()
	waitForPrewarmCondition(t, func() bool {
		jobs := installer.Jobs()
		return len(jobs) == 2 && jobs[1].Status == engineruntime.InstallReady
	})
}

func TestPrewarmResourceAdmissionFailsClosed(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.validateRuntimePrewarmResources(hardware.Snapshot{}); err == nil {
		t.Fatal("unknown RAM telemetry must reject background prewarm")
	}
	low := hardware.Snapshot{RAMTotalBytes: 32 << 30, RAMAvailableBytes: 5 << 30}
	if err := module.validateRuntimePrewarmResources(low); err == nil {
		t.Fatal("configured reserve plus build headroom was not protected")
	}
	if err := module.validateRuntimePrewarmResources(prewarmTestHardware()); err != nil {
		t.Fatalf("safe prewarm budget rejected: %v", err)
	}
}

func TestGuardTransitionDoesNotBlockOnUncooperativePrewarm(t *testing.T) {
	root := t.TempDir()
	runner := &stubbornPrewarmRunner{started: make(chan struct{}), release: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), nil, runner)
	if err != nil {
		t.Fatal(err)
	}
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	candidate := runtimePrewarmCandidate{build: newTestLlamaBuild(t, engineruntime.BuildCPU), purpose: "stubborn"}
	go module.runRuntimePrewarm("Test", []runtimePrewarmCandidate{candidate})
	select {
	case <-runner.started:
	case <-time.After(2 * time.Second):
		t.Fatal("prewarm process did not start")
	}
	started := time.Now()
	module.setGuardState(GuardWarning)
	if elapsed := time.Since(started); elapsed > 100*time.Millisecond {
		t.Fatalf("guard transition blocked for %s", elapsed)
	}
	module.prewarmMu.Lock()
	active := module.prewarmActive != nil
	module.prewarmMu.Unlock()
	if !active {
		t.Fatal("unconfirmed installer termination was incorrectly released")
	}
	close(runner.release)
	waitForPrewarmCondition(t, func() bool {
		module.prewarmMu.Lock()
		defer module.prewarmMu.Unlock()
		return module.prewarmActive == nil
	})
	module.maintenanceStopOnce.Do(func() { close(module.maintenanceStop) })
	installer.Close()
}

func TestSharedRuntimeJobCancelsOnlyAfterLastWaiterLeaves(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), nil, runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	build := newTestLlamaBuild(t, engineruntime.BuildCPU)
	first, err := module.startRuntimeInstall(context.Background(), build)
	if err != nil {
		t.Fatal(err)
	}
	second, err := module.startRuntimeInstall(context.Background(), build)
	if err != nil {
		t.Fatal(err)
	}
	if first != second {
		t.Fatal("content-addressed waiters did not share one installer job")
	}
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("shared runtime job did not start")
	}
	firstCtx, cancelFirst := context.WithCancel(context.Background())
	cancelFirst()
	if _, err := module.waitRuntimeInstall(firstCtx, "", "", first, "shared"); err == nil {
		t.Fatal("first canceled waiter unexpectedly succeeded")
	}
	select {
	case <-runner.firstCanceled:
		t.Fatal("shared job was canceled while another waiter still owned it")
	case <-time.After(80 * time.Millisecond):
	}
	secondCtx, cancelSecond := context.WithCancel(context.Background())
	cancelSecond()
	if _, err := module.waitRuntimeInstall(secondCtx, "", "", second, "shared"); err == nil {
		t.Fatal("last canceled waiter unexpectedly succeeded")
	}
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("last waiter cancellation did not stop CommandRunner")
	}
}

func TestActivePrewarmUsesFastPressureSampling(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.prewarmMu.Lock()
	module.prewarmActive = &activeRuntimePrewarm{done: make(chan struct{})}
	module.prewarmMu.Unlock()
	if !module.hasStartingInstance() {
		t.Fatal("active runtime prewarm was omitted from fast pressure sampling")
	}
}

func TestCriticalGuardStopsForegroundRuntimeCommand(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), nil, runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	job, err := module.startRuntimeInstall(context.Background(), newTestLlamaBuild(t, engineruntime.BuildCPU))
	if err != nil {
		t.Fatal(err)
	}
	waitDone := make(chan error, 1)
	go func() {
		_, waitErr := module.waitRuntimeInstall(context.Background(), "", "", job, "foreground")
		waitDone <- waitErr
	}()
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("foreground runtime command did not start")
	}
	module.setGuardState(GuardCritical)
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("critical guard did not cancel foreground runtime command")
	}
	select {
	case waitErr := <-waitDone:
		if waitErr == nil {
			t.Fatal("canceled foreground runtime unexpectedly succeeded")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("foreground runtime waiter did not observe terminal cancellation")
	}
}

func TestPreferredRuntimeJobUsesReadyFallbackAfterAcceleratorFailure(t *testing.T) {
	jobs := []engineruntime.InstallJobSnapshot{
		{Runtime: engineruntime.RuntimeLlamaCPP, BuildDigest: "gpu", Status: engineruntime.InstallFailed},
		{Runtime: engineruntime.RuntimeLlamaCPP, BuildDigest: "cpu", Status: engineruntime.InstallReady, InstallPath: "/cpu"},
	}
	job, ok := preferredRuntimeJob(jobs, "gpu")
	if !ok || job.BuildDigest != "cpu" || job.InstallPath != "/cpu" {
		t.Fatalf("preferred job = %#v, %v", job, ok)
	}
}
