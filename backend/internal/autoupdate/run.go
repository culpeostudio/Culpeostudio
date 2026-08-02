package autoupdate

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type StartupError struct {
	Cause error
}

func (err *StartupError) Error() string {
	return "updated application could not start: " + err.Cause.Error()
}

func (err *StartupError) Unwrap() error {
	return err.Cause
}

func bundledHardwareProbe(root string) string {
	for _, name := range []string{
		"philoengine_hardware_probe.py",
		"whichllm_hardware_probe.py",
	} {
		candidate := filepath.Join(root, "backend", "tools", name)
		if info, err := os.Stat(candidate); err == nil && info.Mode().IsRegular() {
			return candidate
		}
	}
	return ""
}

func RunBundle(
	ctx context.Context,
	installRoot string,
	bundle InstalledBundle,
	stdout io.Writer,
	stderr io.Writer,
) error {
	if stdout == nil {
		stdout = os.Stdout
	}
	if stderr == nil {
		stderr = os.Stderr
	}
	backendWorkdir := filepath.Join(installRoot, "backend")
	frontendWorkdir := filepath.Join(installRoot, "frontend")
	for _, directory := range []string{backendWorkdir, frontendWorkdir} {
		if err := os.MkdirAll(directory, 0o700); err != nil {
			return &StartupError{Cause: fmt.Errorf("create persistent work directory: %w", err)}
		}
	}
	managedEnvironment := map[string]string{
		"PHILOENGINE_INSTALL_ROOT": installRoot,
		"PHILOENGINE_VERSION":      bundle.State.Version,
	}
	transformersWorker := filepath.Join(bundle.Root, "backend", "engineworker", "transformers_worker.py")
	if info, err := os.Stat(transformersWorker); err == nil && info.Mode().IsRegular() {
		managedEnvironment["ENGINE_TRANSFORMERS_WORKER"] = transformersWorker
	}
	if hardwareProbe := bundledHardwareProbe(bundle.Root); hardwareProbe != "" {
		managedEnvironment["PHILOENGINE_HARDWARE_PROBE_PATH"] = hardwareProbe

		managedEnvironment["WHICHLLM_PROBE_PATH"] = hardwareProbe
	}
	environment := withEnvironment(os.Environ(), managedEnvironment)
	backend, err := startProcess(bundle.Backend, bundle.Asset.Backend.Args, backendWorkdir, environment, stdout, stderr)
	if err != nil {
		return &StartupError{Cause: fmt.Errorf("start backend: %w", err)}
	}

	if err := waitUntilReady(ctx, bundle.Asset.HealthURL, backend); err != nil {
		backend.stop()
		return &StartupError{Cause: err}
	}

	frontend, err := startProcess(bundle.Frontend, bundle.Asset.Frontend.Args, frontendWorkdir, environment, stdout, stderr)
	if err != nil {
		backend.stop()
		return &StartupError{Cause: fmt.Errorf("start frontend: %w", err)}
	}

	startupWindow := time.NewTimer(2 * time.Second)
	select {
	case frontendErr := <-frontend.done:
		startupWindow.Stop()
		frontend.exited = true
		backend.stop()
		if frontendErr != nil {
			return &StartupError{Cause: fmt.Errorf("frontend exited during startup: %w", frontendErr)}
		}
		return nil
	case backendErr := <-backend.done:
		startupWindow.Stop()
		backend.exited = true
		frontend.stop()
		if backendErr == nil {
			return &StartupError{Cause: fmt.Errorf("backend stopped during frontend startup")}
		}
		return &StartupError{Cause: fmt.Errorf("backend exited during frontend startup: %w", backendErr)}
	case <-ctx.Done():
		startupWindow.Stop()
		frontend.stop()
		backend.stop()
		return nil
	case <-startupWindow.C:
	}

	select {
	case frontendErr := <-frontend.done:
		frontend.exited = true
		backend.stop()
		if frontendErr != nil {
			return fmt.Errorf("frontend exited: %w", frontendErr)
		}
		return nil
	case backendErr := <-backend.done:
		backend.exited = true
		frontend.stop()
		if backendErr == nil {
			return fmt.Errorf("backend stopped while the frontend was running")
		}
		return fmt.Errorf("backend exited: %w", backendErr)
	case <-ctx.Done():
		frontend.stop()
		backend.stop()
		return nil
	}
}

type managedProcess struct {
	command *exec.Cmd
	done    chan error
	exited  bool
}

func startProcess(
	path string,
	arguments []string,
	workdir string,
	environment []string,
	stdout io.Writer,
	stderr io.Writer,
) (*managedProcess, error) {
	command := exec.Command(path, arguments...)
	command.Dir = workdir
	command.Env = environment
	command.Stdout = stdout
	command.Stderr = stderr
	command.Stdin = os.Stdin
	if err := command.Start(); err != nil {
		return nil, err
	}
	process := &managedProcess{command: command, done: make(chan error, 1)}
	go func() { process.done <- command.Wait() }()
	return process, nil
}

func waitUntilReady(ctx context.Context, healthURL string, backend *managedProcess) error {
	if strings.TrimSpace(healthURL) == "" {
		timer := time.NewTimer(750 * time.Millisecond)
		defer timer.Stop()
		select {
		case err := <-backend.done:
			backend.exited = true
			if err == nil {
				return fmt.Errorf("backend stopped before frontend startup")
			}
			return fmt.Errorf("backend stopped before frontend startup: %w", err)
		case <-timer.C:
			return nil
		case <-ctx.Done():
			return ctx.Err()
		}
	}
	parsed, err := url.Parse(healthURL)
	if err != nil || parsed.Scheme != "http" || !isLoopbackHost(parsed.Hostname()) {
		return fmt.Errorf("invalid bundle health URL")
	}
	transport := &http.Transport{
		Proxy: nil,
		DialContext: (&net.Dialer{
			Timeout: 2 * time.Second,
		}).DialContext,
		DisableKeepAlives: true,
	}
	client := &http.Client{Transport: transport, Timeout: 3 * time.Second}
	defer transport.CloseIdleConnections()
	timeout := time.NewTimer(2 * time.Minute)
	defer timeout.Stop()
	ticker := time.NewTicker(300 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case backendErr := <-backend.done:
			backend.exited = true
			if backendErr == nil {
				return fmt.Errorf("backend stopped before becoming ready")
			}
			return fmt.Errorf("backend stopped before becoming ready: %w", backendErr)
		case <-ticker.C:
			request, requestErr := http.NewRequestWithContext(ctx, http.MethodGet, healthURL, nil)
			if requestErr != nil {
				return requestErr
			}
			response, requestErr := client.Do(request)
			if requestErr == nil {
				_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 4<<10))
				response.Body.Close()
				if response.StatusCode >= 200 && response.StatusCode < 300 {
					return nil
				}
			}
		case <-timeout.C:
			return fmt.Errorf("backend health check timed out")
		case <-ctx.Done():
			return ctx.Err()
		}
	}
}

func (process *managedProcess) stop() {
	if process == nil || process.exited || process.command.Process == nil {
		return
	}
	if err := process.command.Process.Signal(os.Interrupt); err != nil {
		_ = process.command.Process.Kill()
	}
	timer := time.NewTimer(20 * time.Second)
	defer timer.Stop()
	select {
	case <-process.done:
		process.exited = true
		return
	case <-timer.C:
		_ = process.command.Process.Kill()
		select {
		case <-process.done:
			process.exited = true
		case <-time.After(5 * time.Second):
		}
	}
}

func withEnvironment(environment []string, values map[string]string) []string {
	filtered := make([]string, 0, len(environment)+len(values))
	for _, item := range environment {
		name, _, found := strings.Cut(item, "=")
		if _, replace := values[name]; found && replace {
			continue
		}
		filtered = append(filtered, item)
	}
	for name, value := range values {
		filtered = append(filtered, name+"="+value)
	}
	return filtered
}

func IsStartupError(err error) bool {
	var startupError *StartupError
	return errors.As(err, &startupError)
}
