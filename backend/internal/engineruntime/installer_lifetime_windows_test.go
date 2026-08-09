//go:build windows

package engineruntime

import (
	"os"
	"os/exec"
	"testing"
	"time"

	"golang.org/x/sys/windows"
)

func TestInstallerLifetimeAssignsSuspendedProcessBeforeResume(t *testing.T) {
	cmd := exec.Command(os.Args[0], "-test.run=^$")
	cmd.Env = os.Environ()
	configureProcessGroup(cmd)
	lifetime, err := prepareCommandLifetime(cmd)
	if err != nil {
		t.Fatal(err)
	}
	defer lifetime.Cleanup()
	if cmd.SysProcAttr == nil || cmd.SysProcAttr.CreationFlags&windows.CREATE_SUSPENDED == 0 {
		t.Fatalf("installer process was not configured suspended: %#v", cmd.SysProcAttr)
	}
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	waitDone := make(chan error, 1)
	go func() { waitDone <- cmd.Wait() }()
	select {
	case err := <-waitDone:
		t.Fatalf("suspended installer ran before Job Object assignment: %v", err)
	case <-time.After(100 * time.Millisecond):
	}
	if err := lifetime.Bind(cmd); err != nil {
		lifetime.Cleanup()
		select {
		case <-waitDone:
		case <-time.After(3 * time.Second):
		}
		t.Fatal(err)
	}
	select {
	case err := <-waitDone:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("assigned installer process was not resumed")
	}
}
