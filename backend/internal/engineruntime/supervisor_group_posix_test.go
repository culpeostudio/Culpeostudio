//go:build linux || darwin

package engineruntime

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
	"testing"
	"time"
)

type failBindAfterChildSpawnLimiter struct {
	pidFile string
}

func (l failBindAfterChildSpawnLimiter) Bind(*exec.Cmd, ResourceLimits) (func(), error) {
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if data, err := os.ReadFile(l.pidFile); err == nil && len(data) > 0 {
			return nil, errors.New("deliberate bind failure")
		}
		time.Sleep(time.Millisecond)
	}
	return nil, errors.New("child did not spawn before bind failure")
}

func TestSupervisorWatcherKillsDescendantsAfterUnexpectedMainExit(t *testing.T) {
	pidFile := t.TempDir() + "/child.pid"
	supervisor := NewSupervisor(SupervisorOptions{})
	spec := ProcessSpec{
		InstanceID: "orphan-tree",
		Argv: []string{
			"/bin/sh", "-c", `sleep 30 & child=$!; printf '%s' "$child" > "$1"; exit 7`, "sh", pidFile,
		},
		HealthPath: "-",
	}
	handle, _ := supervisor.Start(context.Background(), spec)
	if handle == nil {
		t.Fatal("supervisor did not return a handle for the crashing process tree")
	}
	select {
	case <-handle.Done():
	case <-time.After(3 * time.Second):
		t.Fatalf("main process watcher did not finish: snapshot=%#v logs=%#v", handle.Snapshot(), handle.Logs())
	}
	data, err := os.ReadFile(pidFile)
	if err != nil {
		t.Fatal(err)
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil || pid <= 0 {
		t.Fatalf("child pid = %q: %v", data, err)
	}
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		err = syscall.Kill(pid, 0)
		if errors.Is(err, syscall.ESRCH) {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	_ = syscall.Kill(pid, syscall.SIGKILL)
	t.Fatalf("descendant process %d survived watcher cleanup (kill probe: %v)", pid, err)
}

func TestExecCommandRunnerKillsDescendantsAfterUnexpectedMainExit(t *testing.T) {
	pidFile := t.TempDir() + "/installer-child.pid"
	runner := &ExecCommandRunner{}
	startedAt := time.Now()
	err := runner.Run(
		context.Background(),
		[]string{"/bin/sh", "-c", `sleep 30 & child=$!; printf '%s' "$child" > "$1"; exit 7`, "sh", pidFile},
		os.Environ(),
		NewRingBuffer(4096),
	)
	if err == nil {
		t.Fatal("crashing installer launcher unexpectedly succeeded")
	}
	if elapsed := time.Since(startedAt); elapsed > 3*time.Second {
		t.Fatalf("installer wait was stranded by inherited pipes for %s", elapsed)
	}
	data, readErr := os.ReadFile(pidFile)
	if readErr != nil {
		t.Fatal(readErr)
	}
	pid, parseErr := strconv.Atoi(strings.TrimSpace(string(data)))
	if parseErr != nil || pid <= 0 {
		t.Fatalf("child pid = %q: %v", data, parseErr)
	}
	assertProcessDisappears(t, pid)
}

func TestSupervisorBindFailureKillsAlreadySpawnedProcessGroup(t *testing.T) {
	pidFile := t.TempDir() + "/bind-failure-child.pid"
	supervisor := NewSupervisor(SupervisorOptions{
		ResourceLimiter: failBindAfterChildSpawnLimiter{pidFile: pidFile},
	})
	spec := ProcessSpec{
		InstanceID: "bind-failure-tree",
		Argv: []string{
			"/bin/sh", "-c", `sleep 30 & child=$!; printf '%s' "$child" > "$1"; wait`, "sh", pidFile,
		},
		HealthPath: "-",
	}
	handle, err := supervisor.Start(context.Background(), spec)
	if err == nil || handle == nil {
		t.Fatalf("bind failure handle=%#v err=%v", handle, err)
	}
	data, readErr := os.ReadFile(pidFile)
	if readErr != nil {
		t.Fatal(readErr)
	}
	pid, parseErr := strconv.Atoi(strings.TrimSpace(string(data)))
	if parseErr != nil || pid <= 0 {
		t.Fatalf("child pid = %q: %v", data, parseErr)
	}
	assertProcessDisappears(t, pid)
}

func assertProcessDisappears(t *testing.T, pid int) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	var err error
	for time.Now().Before(deadline) {
		err = syscall.Kill(pid, 0)
		if errors.Is(err, syscall.ESRCH) {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	_ = syscall.Kill(pid, syscall.SIGKILL)
	t.Fatalf("descendant process %d survived cleanup (kill probe: %v)", pid, err)
}
