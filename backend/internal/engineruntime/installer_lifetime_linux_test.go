//go:build linux

package engineruntime

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
	"testing"
	"time"
)

const (
	installerLifetimeHelperRole    = "PHILOENGINE_INSTALLER_LIFETIME_TEST_ROLE"
	installerLifetimeHelperPIDFile = "PHILOENGINE_INSTALLER_LIFETIME_TEST_PID_FILE"
)

// TestInstallerLifetimeProcessTreeHelper is re-executed as the command behind
// the shell-free lifetime wrapper. The child creates a grandchild in the same
// process group so the parent test can prove pipe EOF kills the entire tree.
func TestInstallerLifetimeProcessTreeHelper(t *testing.T) {
	role := os.Getenv(installerLifetimeHelperRole)
	if role == "" {
		return
	}
	if role == "grandchild" {
		select {}
	}
	if role == "marker" {
		if err := os.WriteFile(os.Getenv(installerLifetimeHelperPIDFile), []byte("started"), 0o600); err != nil {
			t.Fatalf("write start marker: %v", err)
		}
		return
	}
	if role != "child" {
		t.Fatalf("unknown helper role %q", role)
	}
	pidFile := os.Getenv(installerLifetimeHelperPIDFile)
	grandchild := exec.Command(os.Args[0], "-test.run=^TestInstallerLifetimeProcessTreeHelper$")
	grandchild.Env = replaceTestEnvironment(os.Environ(), installerLifetimeHelperRole, "grandchild")
	grandchild.Stdout = os.Stdout
	grandchild.Stderr = os.Stderr
	if err := grandchild.Start(); err != nil {
		t.Fatalf("start grandchild: %v", err)
	}
	pids := fmt.Sprintf("%d %d", os.Getpid(), grandchild.Process.Pid)
	if err := os.WriteFile(pidFile, []byte(pids), 0o600); err != nil {
		t.Fatalf("write helper pids: %v", err)
	}
	select {}
}

func TestInstallerLifetimeBarrierPreventsExecutionBeforeBind(t *testing.T) {
	marker := t.TempDir() + "/started"
	cmd := exec.Command(os.Args[0], "-test.run=^TestInstallerLifetimeProcessTreeHelper$")
	cmd.Env = replaceTestEnvironment(os.Environ(), installerLifetimeHelperRole, "marker")
	cmd.Env = replaceTestEnvironment(cmd.Env, installerLifetimeHelperPIDFile, marker)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	configureProcessGroup(cmd)
	lifetime, err := prepareCommandLifetime(cmd)
	if err != nil {
		t.Fatal(err)
	}
	defer lifetime.Cleanup()
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	time.Sleep(100 * time.Millisecond)
	if _, err := os.Stat(marker); err == nil || !errors.Is(err, os.ErrNotExist) {
		_ = signalProcessGroup(cmd, true)
		_ = cmd.Wait()
		t.Fatalf("installer command crossed its pre-Bind barrier: %v", err)
	}
	// Ending the backend lifetime before Bind must fail closed without ever
	// starting the serialized command.
	lifetime.Cleanup()
	waitDone := make(chan error, 1)
	go func() { waitDone <- cmd.Wait() }()
	select {
	case waitErr := <-waitDone:
		if waitErr == nil {
			t.Fatal("unreleased lifetime wrapper unexpectedly succeeded")
		}
	case <-time.After(3 * time.Second):
		_ = signalProcessGroup(cmd, true)
		t.Fatal("unreleased lifetime wrapper did not fail after backend EOF")
	}
	if _, err := os.Stat(marker); err == nil || !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("installer command ran after unreleased wrapper shutdown: %v", err)
	}
}

func TestInstallerLifetimePipeEOFKillsChildAndGrandchild(t *testing.T) {
	pidFile := t.TempDir() + "/tree.pids"
	cmd := exec.Command(os.Args[0], "-test.run=^TestInstallerLifetimeProcessTreeHelper$")
	cmd.Env = replaceTestEnvironment(os.Environ(), installerLifetimeHelperRole, "child")
	cmd.Env = replaceTestEnvironment(cmd.Env, installerLifetimeHelperPIDFile, pidFile)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.WaitDelay = 500 * time.Millisecond
	configureProcessGroup(cmd)
	lifetime, err := prepareCommandLifetime(cmd)
	if err != nil {
		t.Fatal(err)
	}
	defer lifetime.Cleanup()
	if cmd.SysProcAttr == nil || cmd.SysProcAttr.Pdeathsig != 0 {
		t.Fatalf("supervised wrapper retained direct-child PDEATHSIG: %#v", cmd.SysProcAttr)
	}
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	if err := lifetime.Bind(cmd); err != nil {
		_ = signalProcessGroup(cmd, true)
		_ = cmd.Wait()
		t.Fatal(err)
	}

	pids, err := waitForInstallerLifetimePIDs(pidFile)
	if err != nil {
		_ = signalProcessGroup(cmd, true)
		_ = cmd.Wait()
		t.Fatal(err)
	}
	posixLifetime, ok := lifetime.(*posixCommandLifetime)
	if !ok {
		t.Fatalf("prepared lifetime type = %T", lifetime)
	}
	// Closing the backend-owned writer is the kernel-visible effect of abrupt
	// backend termination. No explicit signal is sent from this test process.
	if err := posixLifetime.writer.Close(); err != nil {
		t.Fatal(err)
	}

	waitDone := make(chan error, 1)
	go func() { waitDone <- cmd.Wait() }()
	select {
	case waitErr := <-waitDone:
		if waitErr == nil {
			t.Fatal("lifetime wrapper exited successfully after simulated backend death")
		}
	case <-time.After(3 * time.Second):
		_ = signalProcessGroup(cmd, true)
		t.Fatal("lifetime wrapper did not react to backend pipe EOF")
	}
	for _, pid := range pids {
		assertLinuxProcessTerminated(t, pid)
	}
}

func waitForInstallerLifetimePIDs(path string) ([]int, error) {
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		data, err := os.ReadFile(path)
		if err == nil {
			fields := strings.Fields(string(data))
			if len(fields) == 2 {
				pids := make([]int, 0, 2)
				valid := true
				for _, field := range fields {
					pid, parseErr := strconv.Atoi(field)
					if parseErr != nil || pid <= 0 {
						valid = false
						break
					}
					pids = append(pids, pid)
				}
				if valid {
					return pids, nil
				}
			}
		}
		time.Sleep(10 * time.Millisecond)
	}
	return nil, errors.New("installer helper did not publish child and grandchild PIDs")
}

func assertLinuxProcessTerminated(t *testing.T, pid int) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		err := syscall.Kill(pid, 0)
		if errors.Is(err, syscall.ESRCH) || linuxProcessIsZombie(pid) {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	_ = syscall.Kill(pid, syscall.SIGKILL)
	t.Fatalf("installer descendant %d survived backend lifetime EOF", pid)
}

func linuxProcessIsZombie(pid int) bool {
	data, err := os.ReadFile("/proc/" + strconv.Itoa(pid) + "/stat")
	if err != nil {
		return errors.Is(err, os.ErrNotExist)
	}
	closing := strings.LastIndexByte(string(data), ')')
	return closing >= 0 && len(data) > closing+2 && data[closing+2] == 'Z'
}

func replaceTestEnvironment(environment []string, key, value string) []string {
	prefix := key + "="
	result := make([]string, 0, len(environment)+1)
	for _, entry := range environment {
		if !strings.HasPrefix(entry, prefix) {
			result = append(result, entry)
		}
	}
	return append(result, prefix+value)
}
