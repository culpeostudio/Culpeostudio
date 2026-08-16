package tools

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

var autoAllowedCommands = map[string]struct{}{
	"ls": {}, "cat": {}, "head": {}, "tail": {}, "wc": {}, "rg": {},
	"grep": {}, "find": {}, "diff": {}, "pwd": {}, "echo": {}, "file": {},
	"stat": {}, "tree": {}, "sort": {}, "uniq": {}, "which": {},
	"go": {}, "flutter": {}, "dart": {}, "python": {}, "python3": {},
	"npm": {}, "node": {},
}

var autoAllowedGitSubcommands = map[string]struct{}{
	"status": {}, "diff": {}, "log": {}, "show": {}, "branch": {},
	"ls-files": {}, "rev-parse": {}, "blame": {}, "grep": {},
}

var blockedCommands = map[string]struct{}{
	"sudo": {}, "su": {}, "doas": {},
}

const (
	// A command gets long enough for the builds an agent actually runs: a Go
	// build over a whole module, a Flutter analyze, a test suite. The old
	// ceiling of two minutes turned those into failures the agent then tried to
	// work around. A command that hangs is still stopped - that is what the
	// ceiling is for - but the number has to be beyond real work, not inside it.
	defaultCommandTimeout = 5 * time.Minute
	maxCommandTimeout     = 30 * time.Minute
	maxCommandOutputRunes = 32000
)

func (e *Executor) commandPreapproved(program string, args []string) bool {
	if _, ok := e.approvedPrograms[program]; ok {
		return true
	}
	if program == "git" {
		if len(args) == 0 {
			return true
		}
		_, ok := autoAllowedGitSubcommands[args[0]]
		return ok
	}
	_, ok := autoAllowedCommands[program]
	return ok
}

func (e *Executor) runCommand(args map[string]interface{}) (map[string]interface{}, error) {
	command, _ := args["command"].(string)
	command = strings.TrimSpace(command)
	program := filepath.Base(command)

	if _, blocked := blockedCommands[program]; blocked {
		return nil, fmt.Errorf("Befehl %q ist dauerhaft blockiert und kann nicht freigegeben werden", program)
	}

	cmdArgs := make([]string, 0, 4)
	if raw, ok := args["args"].([]interface{}); ok {
		for _, item := range raw {
			if s, ok := item.(string); ok {
				cmdArgs = append(cmdArgs, s)
			}
		}
	}
	commandLine := strings.TrimSpace(command + " " + strings.Join(cmdArgs, " "))

	if !e.commandPreapproved(program, cmdArgs) {
		if e.asker == nil {
			return nil, fmt.Errorf("Befehl %q ist nicht in der Allowlist und es ist keine Permission-Verbindung verfuegbar", program)
		}
		decision := e.requestPermission("run_command", commandLine)
		switch decision {
		case permissionOnce:

		case permissionSession:
			e.approvedPrograms[program] = struct{}{}
		default:
			return map[string]interface{}{
				"ok":         false,
				"error":      fmt.Sprintf("Befehl vom Nutzer abgelehnt: %s", commandLine),
				"error_code": "permission_denied",
			}, nil
		}
	}

	timeout := defaultCommandTimeout
	if raw, ok := args["timeout_seconds"].(float64); ok && raw > 0 {
		timeout = time.Duration(raw) * time.Second
		if timeout > maxCommandTimeout {
			timeout = maxCommandTimeout
		}
	}

	ctx := e.ctx
	if ctx == nil {
		ctx = context.Background()
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, command, cmdArgs...)
	if len(e.roots) > 0 {
		cmd.Dir = e.roots[0]
	}

	cmd.Env = []string{
		"PATH=" + os.Getenv("PATH"),
		"HOME=" + os.Getenv("HOME"),
		"LANG=C.UTF-8",
		"TMPDIR=" + os.Getenv("TMPDIR"),
	}
	cmd.WaitDelay = 5 * time.Second

	output, runErr := cmd.CombinedOutput()
	timedOut := errors.Is(ctx.Err(), context.DeadlineExceeded)

	text := string(output)
	truncated := false
	if runes := []rune(text); len(runes) > maxCommandOutputRunes {
		text = string(runes[:maxCommandOutputRunes])
		truncated = true
	}

	exitCode := 0
	if cmd.ProcessState != nil {
		exitCode = cmd.ProcessState.ExitCode()
	} else if timedOut {
		exitCode = -1
	}

	result := map[string]interface{}{
		"ok":        runErr == nil && !timedOut,
		"command":   commandLine,
		"exit_code": exitCode,
		"output":    text,
		"truncated": truncated,
	}
	if timedOut {
		result["error"] = fmt.Sprintf("Zeitlimit von %s ueberschritten", timeout)
	} else if runErr != nil {
		result["error"] = runErr.Error()
	}
	return result, nil
}
