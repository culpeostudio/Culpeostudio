//go:build aix || darwin || dragonfly || freebsd || netbsd || openbsd || solaris

package engineruntime

import (
	"os/exec"
	"syscall"
)

func configureProcessGroup(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
}

func signalProcessGroup(cmd *exec.Cmd, force bool) error {
	if cmd == nil || cmd.Process == nil {
		return nil
	}
	signal := syscall.SIGTERM
	if force {
		signal = syscall.SIGKILL
	}
	// Negative PID addresses the process group created with Setpgid.
	return syscall.Kill(-cmd.Process.Pid, signal)
}

func disableDirectParentDeathSignal(_ *exec.Cmd) {}

func bindProcessLifetime(cmd *exec.Cmd) (func(), error) { return func() {}, nil }
