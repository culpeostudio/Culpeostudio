//go:build linux

package engineruntime

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strconv"

	"golang.org/x/sys/unix"
)

const resourceLauncherStartByte = byte(0x51)

func runLimitedWorker(payload resourceLauncherPayload, maximum uint64) (int, error) {
	fd, err := strconv.Atoi(os.Getenv(resourceLauncherLifetimeFD))
	if err != nil || fd < 3 {
		return 126, errors.New("missing backend-lifetime descriptor")
	}
	if unix.Getpgrp() != os.Getpid() {
		return 126, errors.New("resource launcher does not own its process group")
	}
	lifetime := os.NewFile(uintptr(fd), "philoengine-backend-lifetime")
	if lifetime == nil {
		return 126, errors.New("invalid backend-lifetime descriptor")
	}
	defer lifetime.Close()
	unix.CloseOnExec(fd)
	released, err := verifyLinuxBackendLifetime(fd)
	if err != nil {
		return 126, err
	}
	if !released {
		start := []byte{0}
		if count, readErr := lifetime.Read(start); readErr != nil || count != 1 || start[0] != resourceLauncherStartByte {
			if errors.Is(readErr, io.EOF) {
				return 126, errors.New("backend lifetime ended before worker release")
			}
			if readErr != nil {
				return 126, fmt.Errorf("read worker release signal: %w", readErr)
			}
			return 126, fmt.Errorf("invalid worker release signal (bytes=%d, value=%d)", count, start[0])
		}
	}

	executable, err := os.Executable()
	if err != nil {
		return 126, fmt.Errorf("locate resource launcher executable: %w", err)
	}
	worker := &exec.Cmd{Path: executable, Args: []string{executable}}
	worker.Env = limitedExecEnvironment()
	worker.Stdin = os.Stdin
	worker.Stdout = os.Stdout
	worker.Stderr = os.Stderr
	if err := worker.Start(); err != nil {
		return 126, fmt.Errorf("start limited worker: %w", err)
	}

	workerDone := make(chan error, 1)
	go func() { workerDone <- worker.Wait() }()
	lifetimeEnded := make(chan error, 1)
	go func() {
		buffer := []byte{0}
		_, readErr := lifetime.Read(buffer)
		if readErr == nil {
			readErr = errors.New("unexpected data on backend-lifetime descriptor")
		} else if errors.Is(readErr, io.EOF) {
			readErr = errors.New("backend lifetime ended")
		}
		lifetimeEnded <- readErr
	}()

	select {
	case waitErr := <-workerDone:
		_ = lifetime.Close()
		if waitErr == nil {
			return 0, nil
		}
		var exitErr *exec.ExitError
		if errors.As(waitErr, &exitErr) && exitErr.ExitCode() >= 0 {
			return exitErr.ExitCode(), nil
		}
		return 126, waitErr
	case lifetimeErr := <-lifetimeEnded:

		group := unix.Getpgrp()
		if group != os.Getpid() {
			_ = worker.Process.Kill()
			return 126, errors.New("worker process group changed unexpectedly")
		}
		if err := unix.Kill(-group, unix.SIGKILL); err != nil {
			_ = worker.Process.Kill()
			return 126, fmt.Errorf("kill orphaned worker group after %v: %w", lifetimeErr, err)
		}
		return 126, lifetimeErr
	}
}

func verifyLinuxBackendLifetime(fd int) (bool, error) {
	if err := unix.SetNonblock(fd, true); err != nil {
		return false, fmt.Errorf("configure backend-lifetime descriptor: %w", err)
	}
	buffer := []byte{0}
	count, err := unix.Read(fd, buffer)
	if restoreErr := unix.SetNonblock(fd, false); restoreErr != nil {
		return false, fmt.Errorf("restore blocking backend-lifetime descriptor: %w", restoreErr)
	}
	switch {
	case count == 1 && buffer[0] == resourceLauncherStartByte:
		return true, nil
	case count > 0:
		return false, errors.New("invalid early worker release signal")
	case err == nil:
		return false, errors.New("backend lifetime ended before worker spawn")
	case errors.Is(err, unix.EAGAIN) || errors.Is(err, unix.EWOULDBLOCK):
		return false, nil
	default:
		return false, fmt.Errorf("probe backend-lifetime descriptor: %w", err)
	}
}
