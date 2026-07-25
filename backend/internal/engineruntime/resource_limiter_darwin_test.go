//go:build darwin

package engineruntime

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"testing"
	"time"
)

const (
	darwinLimiterParentHelper = "PHILOENGINE_TEST_LIMITER_PARENT"
	darwinLimiterWorkerHelper = "PHILOENGINE_TEST_LIMITER_WORKER"
	darwinLimiterPIDFile      = "PHILOENGINE_TEST_LIMITER_PID_FILE"
)

func TestDarwinLimiterPreparationProvidesAndCleansLifetimeDescriptor(t *testing.T) {
	limiter := NewNativeResourceLimiter().(*nativeResourceLimiter)
	cmd := exec.Command("/usr/bin/true")
	cmd.Env = os.Environ()
	configureProcessGroup(cmd)
	if err := limiter.Prepare(cmd, ResourceLimits{MemoryMaxBytes: 1 << 30}); err != nil {
		t.Fatal(err)
	}
	if len(cmd.ExtraFiles) != 1 {
		t.Fatalf("extra files = %d, want 1", len(cmd.ExtraFiles))
	}
	foundFD := false
	for _, value := range cmd.Env {
		if value == resourceLauncherLifetimeFD+"=3" {
			foundFD = true
		}
	}
	if !foundFD {
		t.Fatalf("lifetime descriptor is missing from launcher environment: %q", cmd.Env)
	}
	limiter.mu.Lock()
	pipe := limiter.prepared[cmd]
	limiter.mu.Unlock()
	if pipe == nil {
		t.Fatal("prepared lifetime pipe was not retained through Start")
	}
	limiter.AbortPrepare(cmd)
	if _, err := pipe.read.Stat(); err == nil {
		t.Fatal("AbortPrepare left the read descriptor open")
	}
	if _, err := pipe.write.Stat(); err == nil {
		t.Fatal("AbortPrepare left the write descriptor open")
	}
}

func TestDarwinLauncherFailsClosedWithoutLifetimeDescriptor(t *testing.T) {
	t.Setenv(resourceLauncherLifetimeFD, "")
	if _, err := runLimitedWorker(resourceLauncherPayload{Path: "/usr/bin/true", Args: []string{"true"}}, 1<<30); err == nil {
		t.Fatal("launcher accepted a missing backend-lifetime descriptor")
	}
}

func TestDarwinLauncherVerifiesBackendLifetimeBeforeSpawn(t *testing.T) {
	read, write, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	defer read.Close()
	if err := verifyBackendLifetime(int(read.Fd())); err != nil {
		t.Fatalf("live backend descriptor was rejected: %v", err)
	}
	if err := write.Close(); err != nil {
		t.Fatal(err)
	}
	if err := verifyBackendLifetime(int(read.Fd())); err == nil {
		t.Fatal("closed backend lifetime was accepted before worker spawn")
	}
}

func TestDarwinLimitedWorkerDiesWhenBackendParentExits(t *testing.T) {
	if os.Getenv(darwinLimiterParentHelper) == "1" || os.Getenv(darwinLimiterWorkerHelper) == "1" {
		return
	}
	executable, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	pidFile := filepath.Join(t.TempDir(), "worker.pid")
	parent := exec.Command(executable, "-test.run=^TestDarwinLimiterParentProcess$")
	parent.Env = append(os.Environ(),
		darwinLimiterParentHelper+"=1",
		darwinLimiterPIDFile+"="+pidFile,
	)
	if output, err := parent.CombinedOutput(); err != nil {
		t.Fatalf("parent helper failed: %v\n%s", err, output)
	}
	data, err := os.ReadFile(pidFile)
	if err != nil {
		t.Fatalf("worker PID was not recorded: %v", err)
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil || pid <= 0 {
		t.Fatalf("invalid worker PID %q: %v", data, err)
	}
	deadline := time.Now().Add(5 * time.Second)
	for processExists(pid) && time.Now().Before(deadline) {
		time.Sleep(20 * time.Millisecond)
	}
	if processExists(pid) {
		_ = syscall.Kill(pid, syscall.SIGKILL)
		t.Fatalf("worker %d survived abnormal backend-parent exit", pid)
	}
}

func TestDarwinLimiterParentProcess(t *testing.T) {
	if os.Getenv(darwinLimiterParentHelper) != "1" {
		return
	}
	executable, err := os.Executable()
	if err != nil {
		os.Exit(91)
	}
	pidFile := os.Getenv(darwinLimiterPIDFile)
	worker := exec.Command(executable, "-test.run=^TestDarwinLimiterWorkerProcess$")
	worker.Env = append(os.Environ(),
		darwinLimiterParentHelper+"=0",
		darwinLimiterWorkerHelper+"=1",
		darwinLimiterPIDFile+"="+pidFile,
	)
	configureProcessGroup(worker)
	limiter := NewNativeResourceLimiter()
	preparer := limiter.(ResourceLimitPreparer)
	limits := ResourceLimits{MemoryMaxBytes: 8 << 30}
	if err := preparer.Prepare(worker, limits); err != nil {
		os.Exit(92)
	}
	if err := worker.Start(); err != nil {
		limiter.(ResourceLimitPreparationAborter).AbortPrepare(worker)
		os.Exit(93)
	}
	if _, err := limiter.Bind(worker, limits); err != nil {
		_ = worker.Process.Kill()
		os.Exit(94)
	}
	deadline := time.Now().Add(5 * time.Second)
	for {
		if data, readErr := os.ReadFile(pidFile); readErr == nil && len(data) > 0 {
			break
		}
		if time.Now().After(deadline) {
			_ = worker.Process.Kill()
			os.Exit(95)
		}
		time.Sleep(10 * time.Millisecond)
	}
	// Deliberately bypass cleanup: kernel-closing the lifetime-pipe writer is
	// the abnormal-backend-death condition under test.
	os.Exit(0)
}

func TestDarwinLimiterWorkerProcess(t *testing.T) {
	if os.Getenv(darwinLimiterWorkerHelper) != "1" {
		return
	}
	pidFile := os.Getenv(darwinLimiterPIDFile)
	if err := os.WriteFile(pidFile, []byte(strconv.Itoa(os.Getpid())), 0o600); err != nil {
		os.Exit(96)
	}
	for {
		time.Sleep(time.Second)
	}
}

func processExists(pid int) bool {
	err := syscall.Kill(pid, 0)
	return err == nil || !errors.Is(err, syscall.ESRCH)
}
