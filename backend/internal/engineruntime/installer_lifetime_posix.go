//go:build linux || darwin

package engineruntime

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"

	"golang.org/x/sys/unix"
)

const (
	installerLifetimeFlag       = "PHILOENGINE_INSTALLER_LIFETIME"
	installerLifetimeCommand    = "PHILOENGINE_INSTALLER_COMMAND"
	installerLifetimeFD         = "PHILOENGINE_INSTALLER_LIFETIME_FD"
	installerLifetimeStartByte  = byte(0x49)
	installerLifetimeExitFailed = 126
)

type installerLifetimePayload struct {
	Path string   `json:"path"`
	Args []string `json:"args"`
}

// init is a shell-free, backend-lifetime supervisor for installer, compiler,
// and runtime-prewarm commands. The requested argv is serialized before fork;
// the wrapper waits on a kernel pipe barrier, then starts it in the wrapper's
// dedicated process group. EOF on that pipe means the backend disappeared and
// SIGKILLs the complete group, including grandchildren.
func init() {
	if os.Getenv(installerLifetimeFlag) != "1" {
		return
	}
	encoded := os.Getenv(installerLifetimeCommand)
	payloadBytes, decodeErr := base64.RawStdEncoding.DecodeString(encoded)
	var payload installerLifetimePayload
	jsonErr := json.Unmarshal(payloadBytes, &payload)
	if decodeErr != nil || jsonErr != nil || payload.Path == "" || len(payload.Args) == 0 {
		_, _ = fmt.Fprintln(os.Stderr, "invalid PhiloEngine installer-lifetime configuration")
		os.Exit(installerLifetimeExitFailed)
	}
	exitCode, err := runInstallerLifetimeSupervisor(payload)
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, "cannot supervise installer process:", err)
		os.Exit(installerLifetimeExitFailed)
	}
	os.Exit(exitCode)
}

type posixCommandLifetime struct {
	reader *os.File
	writer *os.File
	once   sync.Once
}

func prepareCommandLifetime(cmd *exec.Cmd) (preparedCommandLifetime, error) {
	if cmd == nil || cmd.Path == "" || len(cmd.Args) == 0 {
		return nil, errors.New("installer command is incomplete")
	}
	payload, err := json.Marshal(installerLifetimePayload{
		Path: cmd.Path,
		Args: append([]string(nil), cmd.Args...),
	})
	if err != nil {
		return nil, err
	}
	executable, err := os.Executable()
	if err != nil {
		return nil, err
	}
	reader, writer, err := os.Pipe()
	if err != nil {
		return nil, err
	}
	lifetime := &posixCommandLifetime{reader: reader, writer: writer}
	fd := 3 + len(cmd.ExtraFiles)
	cmd.ExtraFiles = append(cmd.ExtraFiles, reader)
	// Linux's direct-child PDEATHSIG must be disabled for this wrapper. It has
	// to survive backend death long enough to observe pipe EOF and atomically
	// kill the complete process group rather than only the direct child.
	disableDirectParentDeathSignal(cmd)
	cmd.Path = executable
	cmd.Args = []string{executable}
	environment := cmd.Env
	if environment == nil {
		environment = os.Environ()
	}
	cmd.Env = append(filterInstallerLifetimeEnvironment(environment),
		installerLifetimeFlag+"=1",
		installerLifetimeCommand+"="+base64.RawStdEncoding.EncodeToString(payload),
		installerLifetimeFD+"="+strconv.Itoa(fd),
	)
	return lifetime, nil
}

func (l *posixCommandLifetime) Bind(_ *exec.Cmd) error {
	if l == nil || l.reader == nil || l.writer == nil {
		return errors.New("installer lifetime pipe is unavailable")
	}
	// Only the wrapper may retain the read end. Otherwise backend death would
	// leave this parent copy open and suppress the EOF notification.
	if err := l.reader.Close(); err != nil {
		return fmt.Errorf("close parent lifetime reader: %w", err)
	}
	l.reader = nil
	count, err := l.writer.Write([]byte{installerLifetimeStartByte})
	if err != nil {
		return fmt.Errorf("release installer lifetime barrier: %w", err)
	}
	if count != 1 {
		return fmt.Errorf("release installer lifetime barrier: wrote %d bytes", count)
	}
	return nil
}

func (l *posixCommandLifetime) Cleanup() {
	if l == nil {
		return
	}
	l.once.Do(func() {
		if l.reader != nil {
			_ = l.reader.Close()
		}
		if l.writer != nil {
			_ = l.writer.Close()
		}
	})
}

func runInstallerLifetimeSupervisor(payload installerLifetimePayload) (int, error) {
	fd, err := strconv.Atoi(os.Getenv(installerLifetimeFD))
	if err != nil || fd < 3 {
		return installerLifetimeExitFailed, errors.New("missing backend-lifetime descriptor")
	}
	group := unix.Getpgrp()
	if group != os.Getpid() {
		return installerLifetimeExitFailed, errors.New("installer lifetime wrapper does not own its process group")
	}
	lifetime := os.NewFile(uintptr(fd), "philoengine-installer-backend-lifetime")
	if lifetime == nil {
		return installerLifetimeExitFailed, errors.New("invalid backend-lifetime descriptor")
	}
	defer lifetime.Close()
	// The requested command and all descendants must not inherit the lifetime
	// descriptor. Only this supervisor watches it for backend death.
	unix.CloseOnExec(fd)
	start := []byte{0}
	count, readErr := io.ReadFull(lifetime, start)
	if readErr != nil || count != 1 || start[0] != installerLifetimeStartByte {
		if errors.Is(readErr, io.EOF) || errors.Is(readErr, io.ErrUnexpectedEOF) {
			return installerLifetimeExitFailed, errors.New("backend lifetime ended before installer release")
		}
		if readErr != nil {
			return installerLifetimeExitFailed, fmt.Errorf("read installer release signal: %w", readErr)
		}
		return installerLifetimeExitFailed, errors.New("invalid installer release signal")
	}

	lifetimeEnded := make(chan error, 1)
	go func() {
		buffer := []byte{0}
		_, watchErr := lifetime.Read(buffer)
		switch {
		case errors.Is(watchErr, io.EOF):
			watchErr = errors.New("backend lifetime ended")
		case watchErr == nil:
			watchErr = errors.New("unexpected data on backend-lifetime descriptor")
		}
		lifetimeEnded <- watchErr
	}()

	worker := &exec.Cmd{Path: payload.Path, Args: append([]string(nil), payload.Args...)}
	worker.Env = filterInstallerLifetimeEnvironment(os.Environ())
	worker.Stdin = os.Stdin
	worker.Stdout = os.Stdout
	worker.Stderr = os.Stderr
	if err := worker.Start(); err != nil {
		return installerLifetimeExitFailed, fmt.Errorf("start installer command: %w", err)
	}
	workerDone := make(chan error, 1)
	go func() { workerDone <- worker.Wait() }()

	select {
	case waitErr := <-workerDone:
		if waitErr == nil {
			return 0, nil
		}
		var exitErr *exec.ExitError
		if errors.As(waitErr, &exitErr) && exitErr.ExitCode() >= 0 {
			return exitErr.ExitCode(), nil
		}
		return installerLifetimeExitFailed, waitErr
	case lifetimeErr := <-lifetimeEnded:
		// The wrapper and requested command intentionally share one dedicated
		// group. Killing the negative group ID therefore includes compiler/pip
		// grandchildren even when the backend itself was SIGKILLed.
		if unix.Getpgrp() != group || group != os.Getpid() {
			_ = worker.Process.Kill()
			return installerLifetimeExitFailed, errors.New("installer process group changed unexpectedly")
		}
		if err := unix.Kill(-group, unix.SIGKILL); err != nil {
			_ = worker.Process.Kill()
			return installerLifetimeExitFailed, fmt.Errorf("kill orphaned installer group after %v: %w", lifetimeErr, err)
		}
		return installerLifetimeExitFailed, lifetimeErr
	}
}

func filterInstallerLifetimeEnvironment(environment []string) []string {
	filtered := make([]string, 0, len(environment))
	for _, value := range environment {
		if strings.HasPrefix(value, installerLifetimeFlag+"=") ||
			strings.HasPrefix(value, installerLifetimeCommand+"=") ||
			strings.HasPrefix(value, installerLifetimeFD+"=") {
			continue
		}
		filtered = append(filtered, value)
	}
	return filtered
}
