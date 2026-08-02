//go:build linux || darwin

package engineruntime

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

const (
	resourceLauncherFlag       = "PHILOENGINE_RESOURCE_LAUNCHER"
	resourceLauncherCommand    = "PHILOENGINE_RESOURCE_COMMAND"
	resourceLauncherLimit      = "PHILOENGINE_RESOURCE_MEMORY_MAX"
	resourceLauncherLifetimeFD = "PHILOENGINE_RESOURCE_LIFETIME_FD"
	resourceLauncherExecFlag   = "PHILOENGINE_RESOURCE_EXEC"
)

type resourceLauncherPayload struct {
	Path string   `json:"path"`
	Args []string `json:"args"`
}

func init() {
	supervise := os.Getenv(resourceLauncherFlag) == "1"
	execLimited := os.Getenv(resourceLauncherExecFlag) == "1"
	if !supervise && !execLimited {
		return
	}
	encoded := os.Getenv(resourceLauncherCommand)
	maximum, limitErr := strconv.ParseUint(os.Getenv(resourceLauncherLimit), 10, 64)
	payloadBytes, decodeErr := base64.RawStdEncoding.DecodeString(encoded)
	var payload resourceLauncherPayload
	jsonErr := json.Unmarshal(payloadBytes, &payload)
	if limitErr != nil || decodeErr != nil || jsonErr != nil || maximum == 0 || payload.Path == "" || len(payload.Args) == 0 {
		_, _ = fmt.Fprintln(os.Stderr, "invalid PhiloEngine resource-launcher configuration")
		os.Exit(126)
	}
	if execLimited {
		if err := execLimitedWorker(payload, maximum); err != nil {
			_, _ = fmt.Fprintln(os.Stderr, "cannot exec limited worker:", err)
		}
		os.Exit(126)
	}
	exitCode, err := runLimitedWorker(payload, maximum)
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, "cannot supervise limited worker:", err)
		os.Exit(126)
	}
	os.Exit(exitCode)
}

func resourceWorkerEnvironment() []string {
	environment := make([]string, 0, len(os.Environ()))
	for _, value := range os.Environ() {
		if strings.HasPrefix(value, resourceLauncherFlag+"=") ||
			strings.HasPrefix(value, resourceLauncherCommand+"=") ||
			strings.HasPrefix(value, resourceLauncherLimit+"=") ||
			strings.HasPrefix(value, resourceLauncherLifetimeFD+"=") ||
			strings.HasPrefix(value, resourceLauncherExecFlag+"=") {
			continue
		}
		environment = append(environment, value)
	}
	return environment
}

func limitedExecEnvironment() []string {
	base := make([]string, 0, len(os.Environ()))
	for _, value := range os.Environ() {
		if strings.HasPrefix(value, resourceLauncherFlag+"=") ||
			strings.HasPrefix(value, resourceLauncherLifetimeFD+"=") ||
			strings.HasPrefix(value, resourceLauncherExecFlag+"=") {
			continue
		}
		base = append(base, value)
	}
	return append(base, resourceLauncherExecFlag+"=1")
}

const addressSpaceHeadroomBytes int64 = 32 << 30

func prepareRlimitLauncher(cmd *exec.Cmd, maximum int64) error {
	if maximum <= 0 {
		return nil
	}
	if cmd == nil || cmd.Path == "" || len(cmd.Args) == 0 {
		return fmt.Errorf("worker command is incomplete")
	}
	payload, err := json.Marshal(resourceLauncherPayload{Path: cmd.Path, Args: append([]string(nil), cmd.Args...)})
	if err != nil {
		return err
	}
	executable, err := os.Executable()
	if err != nil {
		return err
	}
	cmd.Path = executable
	cmd.Args = []string{executable}
	cmd.Env = append(cmd.Env,
		resourceLauncherFlag+"=1",
		resourceLauncherCommand+"="+base64.RawStdEncoding.EncodeToString(payload),
		resourceLauncherLimit+"="+strconv.FormatInt(maximum+addressSpaceHeadroomBytes, 10),
	)
	return nil
}
