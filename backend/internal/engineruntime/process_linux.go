//go:build linux

package engineruntime

import (
	"os/exec"
	"syscall"
)

func configureProcessGroup(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setpgid:   true,
		Pdeathsig: syscall.SIGKILL,
	}
}

func signalProcessGroup(cmd *exec.Cmd, force bool) error {
	if cmd == nil || cmd.Process == nil {
		return nil
	}
	signal := syscall.SIGTERM
	if force {
		signal = syscall.SIGKILL
	}
	return syscall.Kill(-cmd.Process.Pid, signal)
}

func disableDirectParentDeathSignal(cmd *exec.Cmd) {
	if cmd != nil && cmd.SysProcAttr != nil {
		cmd.SysProcAttr.Pdeathsig = 0
	}
}

func bindProcessLifetime(cmd *exec.Cmd) (func(), error) { return func() {}, nil }
