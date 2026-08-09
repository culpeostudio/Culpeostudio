//go:build linux

package engineruntime

import (
	"bytes"
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
	linuxLimiterParentHelper = "CULPEOSTUDIO_TEST_LINUX_LIMITER_PARENT"
	linuxLimiterWorkerHelper = "CULPEOSTUDIO_TEST_LINUX_LIMITER_WORKER"
	linuxLimiterPIDFile      = "CULPEOSTUDIO_TEST_LINUX_LIMITER_PID_FILE"
)

func TestNativeLimiterWrapsWorkerBeforeStart(t *testing.T) {
	command := exec.Command("/bin/true", "argument")
	command.Env = []string{"PATH=/usr/bin:/bin"}
	limiter := NewNativeResourceLimiter()
	preparer, ok := limiter.(ResourceLimitPreparer)
	if !ok {
		t.Fatal("native limiter has no pre-start guard")
	}
	originalPath := command.Path
	if err := preparer.Prepare(command, ResourceLimits{MemoryMaxBytes: 2 << 30}); err != nil {
		t.Fatal(err)
	}
	if command.Path == originalPath || len(command.Args) != 1 {
		t.Fatalf("command was not replaced by safe launcher: path=%q args=%#v", command.Path, command.Args)
	}
	environment := strings.Join(command.Env, "\n")
	if !strings.Contains(environment, resourceLauncherFlag+"=1") || !strings.Contains(environment, resourceLauncherLimit+"=") {
		t.Fatalf("launcher environment = %s", environment)
	}
	if len(command.ExtraFiles) != 1 || !strings.Contains(environment, resourceLauncherLifetimeFD+"=3") {
		t.Fatalf("supervised launcher lifetime was not prepared: files=%d env=%s", len(command.ExtraFiles), environment)
	}
	limiter.(ResourceLimitPreparationAborter).AbortPrepare(command)
}

func TestNativeLimiterEnforcesAddressSpaceBeforeWorkerExec(t *testing.T) {
	python, err := exec.LookPath("python3")
	if err != nil {
		t.Skip("python3 is required for the native limiter smoke test")
	}

	command := exec.Command(python, "-c",
		"import resource; print(resource.getrlimit(resource.RLIMIT_AS)[0])")
	command.Env = os.Environ()
	var stderr bytes.Buffer
	var stdout bytes.Buffer
	command.Stderr = &stderr
	command.Stdout = &stdout
	configureProcessGroup(command)
	limiter := NewNativeResourceLimiter()
	preparer, ok := limiter.(ResourceLimitPreparer)
	if !ok {
		t.Fatal("native limiter has no pre-start guard")
	}
	budget := int64(96 << 20)
	if err := preparer.Prepare(command, ResourceLimits{MemoryMaxBytes: budget}); err != nil {
		t.Fatal(err)
	}
	if err := command.Start(); err != nil {
		t.Fatal(err)
	}
	cleanup, err := limiter.Bind(command, ResourceLimits{MemoryMaxBytes: budget})
	if err != nil {
		_ = command.Process.Kill()
		t.Fatal(err)
	}
	defer cleanup()
	if err := command.Wait(); err != nil {
		t.Fatalf("worker below its budget must start and exit cleanly: %v (stderr: %s)", err, stderr.String())
	}
	appliedLimit, err := strconv.ParseInt(strings.TrimSpace(stdout.String()), 10, 64)
	if err != nil {
		t.Fatalf("unexpected worker output %q: %v", stdout.String(), err)
	}
	expected := budget + addressSpaceHeadroomBytes
	if appliedLimit != expected {
		t.Fatalf("applied RLIMIT_AS = %d, want budget+headroom = %d", appliedLimit, expected)
	}
}

func TestLinuxLauncherWaitsForNativeBindBeforeWorkerSpawn(t *testing.T) {
	marker := filepath.Join(t.TempDir(), "spawned")
	command := exec.Command("/bin/sh", "-c", `printf ready > "$1"`, "sh", marker)
	command.Env = os.Environ()
	var stderr bytes.Buffer
	command.Stderr = &stderr
	configureProcessGroup(command)
	limiter := NewNativeResourceLimiter()
	limits := ResourceLimits{MemoryMaxBytes: 1 << 30}
	if err := limiter.(ResourceLimitPreparer).Prepare(command, limits); err != nil {
		t.Fatal(err)
	}
	if err := command.Start(); err != nil {
		limiter.(ResourceLimitPreparationAborter).AbortPrepare(command)
		t.Fatal(err)
	}
	time.Sleep(75 * time.Millisecond)
	if _, err := os.Stat(marker); err == nil {
		_ = command.Process.Kill()
		t.Fatal("worker spawned before native limiter Bind released it")
	}
	cleanup, err := limiter.Bind(command, limits)
	if err != nil {
		_ = command.Process.Kill()
		t.Fatal(err)
	}
	defer cleanup()
	if err := command.Wait(); err != nil {
		t.Fatalf("released launcher failed: %v: %s", err, stderr.String())
	}
	if content, err := os.ReadFile(marker); err != nil || string(content) != "ready" {
		t.Fatalf("released worker marker = %q, err=%v", content, err)
	}
}

func TestLinuxLimitedWorkerAndGrandchildDieWhenBackendParentExits(t *testing.T) {
	if os.Getenv(linuxLimiterParentHelper) == "1" || os.Getenv(linuxLimiterWorkerHelper) == "1" {
		return
	}
	executable, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	pidFile := filepath.Join(t.TempDir(), "worker-tree.pids")
	parent := exec.Command(executable, "-test.run=^TestLinuxLimiterParentProcess$")
	parent.Env = append(os.Environ(),
		linuxLimiterParentHelper+"=1",
		linuxLimiterPIDFile+"="+pidFile,
	)
	if output, err := parent.CombinedOutput(); err != nil {
		t.Fatalf("parent helper failed: %v\n%s", err, output)
	}
	data, err := os.ReadFile(pidFile)
	if err != nil {
		t.Fatalf("worker PIDs were not recorded: %v", err)
	}
	fields := strings.Fields(string(data))
	if len(fields) != 2 {
		t.Fatalf("worker PID file = %q", data)
	}
	for _, field := range fields {
		pid, parseErr := strconv.Atoi(field)
		if parseErr != nil || pid <= 0 {
			t.Fatalf("invalid worker PID %q: %v", field, parseErr)
		}
		waitForLinuxProcessExit(t, pid)
	}
}

func TestLinuxLimiterParentProcess(t *testing.T) {
	if os.Getenv(linuxLimiterParentHelper) != "1" {
		return
	}
	executable, err := os.Executable()
	if err != nil {
		os.Exit(91)
	}
	pidFile := os.Getenv(linuxLimiterPIDFile)
	worker := exec.Command(executable, "-test.run=^TestLinuxLimiterWorkerProcess$")
	worker.Env = append(os.Environ(),
		linuxLimiterParentHelper+"=0",
		linuxLimiterWorkerHelper+"=1",
		linuxLimiterPIDFile+"="+pidFile,
	)
	worker.Stdout = os.Stdout
	worker.Stderr = os.Stderr
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

	os.Exit(0)
}

func TestLinuxLimiterWorkerProcess(t *testing.T) {
	if os.Getenv(linuxLimiterWorkerHelper) != "1" {
		return
	}
	child := exec.Command("/bin/sleep", "30")
	if err := child.Start(); err != nil {
		os.Exit(96)
	}
	content := strconv.Itoa(os.Getpid()) + " " + strconv.Itoa(child.Process.Pid)
	if err := os.WriteFile(os.Getenv(linuxLimiterPIDFile), []byte(content), 0o600); err != nil {
		_ = child.Process.Kill()
		os.Exit(97)
	}
	for {
		time.Sleep(time.Second)
	}
}

func waitForLinuxProcessExit(t *testing.T, pid int) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		err := syscall.Kill(pid, 0)
		if errors.Is(err, syscall.ESRCH) {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	_ = syscall.Kill(pid, syscall.SIGKILL)
	t.Fatalf("limited process %d survived abnormal backend exit", pid)
}
