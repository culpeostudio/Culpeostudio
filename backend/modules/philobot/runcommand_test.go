package philobot

import (
	"context"
	"strings"
	"testing"
)

func TestRunCommandAllowlistRunsWithoutAsker(t *testing.T) {
	exec, _ := newTestExecutor(t)

	result := exec.Execute("run_command", map[string]interface{}{
		"command": "echo", "args": []interface{}{"hallo"},
	})
	mustOK(t, result, "echo aus der Allowlist")
	if output, _ := result["output"].(string); strings.TrimSpace(output) != "hallo" {
		t.Fatalf("unerwartete Ausgabe: %q", output)
	}
	if code, _ := result["exit_code"].(int); code != 0 {
		t.Fatalf("exit_code sollte 0 sein: %v", result)
	}
}

func TestRunCommandGitRestriction(t *testing.T) {
	exec, _ := newTestExecutor(t)

	result := exec.Execute("run_command", map[string]interface{}{
		"command": "git", "args": []interface{}{"push"},
	})
	mustFail(t, result, "git push ohne Freigabe")
}

func TestRunCommandBlockedPrograms(t *testing.T) {
	exec, _ := newTestExecutor(t)
	result := exec.Execute("run_command", map[string]interface{}{"command": "sudo", "args": []interface{}{"ls"}})
	mustFail(t, result, "sudo muss blockiert sein")
	if errText, _ := result["error"].(string); !strings.Contains(errText, "blockiert") {
		t.Fatalf("erwartete Block-Meldung: %v", result)
	}
}

func TestRunCommandPermissionFlow(t *testing.T) {
	root := t.TempDir()
	asker := &fakePermissionAsker{decisions: []string{permissionSession}}
	exec, err := newFileToolExecutorWithPermissions(context.Background(), []string{root}, asker, nil, "sess-1")
	if err != nil {
		t.Fatalf("newFileToolExecutorWithPermissions: %v", err)
	}

	first := exec.Execute("run_command", map[string]interface{}{
		"command": "chmod", "args": []interface{}{"--version"},
	})
	mustOK(t, first, "chmod nach session-Freigabe")
	second := exec.Execute("run_command", map[string]interface{}{
		"command": "chmod", "args": []interface{}{"--version"},
	})
	mustOK(t, second, "zweiter Aufruf ohne neue Nachfrage")
	if asker.calls != 1 {
		t.Fatalf("Asker sollte nur einmal gefragt werden, war %d", asker.calls)
	}

	denyAsker := &fakePermissionAsker{decisions: []string{permissionDeny}}
	exec2, _ := newFileToolExecutorWithPermissions(context.Background(), []string{root}, denyAsker, nil, "")
	denied := exec2.Execute("run_command", map[string]interface{}{
		"command": "chmod", "args": []interface{}{"--version"},
	})
	mustFail(t, denied, "abgelehnter Befehl")
	if code, _ := denied["error_code"].(string); code != "permission_denied" {
		t.Fatalf("erwartete permission_denied: %v", denied)
	}
}

func TestRunCommandTimeout(t *testing.T) {
	exec, _ := newTestExecutor(t)

	result := exec.Execute("run_command", map[string]interface{}{
		"command":         "python3",
		"args":            []interface{}{"-c", "import time; time.sleep(5)"},
		"timeout_seconds": float64(1),
	})
	mustFail(t, result, "sleep ueber dem Zeitlimit")
	if errText, _ := result["error"].(string); !strings.Contains(errText, "Zeitlimit") {
		t.Fatalf("erwartete Zeitlimit-Meldung: %v", result)
	}
}

func TestRunCommandOutputCap(t *testing.T) {
	exec, _ := newTestExecutor(t)

	result := exec.Execute("run_command", map[string]interface{}{
		"command": "python3",
		"args":    []interface{}{"-c", "print('x' * 100000)"},
	})
	mustOK(t, result, "python3 output")
	if truncated, _ := result["truncated"].(bool); !truncated {
		t.Fatalf("Ausgabe sollte gekuerzt worden sein")
	}
	if output, _ := result["output"].(string); len([]rune(output)) > maxCommandOutputRunes {
		t.Fatalf("Ausgabe ueberschreitet das Cap: %d", len(output))
	}
}

func TestRunCommandRunsInProjectRoot(t *testing.T) {
	exec, root := newTestExecutor(t)
	result := exec.Execute("run_command", map[string]interface{}{"command": "pwd"})
	mustOK(t, result, "pwd")
	output, _ := result["output"].(string)
	if strings.TrimSpace(output) != root {
		t.Fatalf("cwd sollte der Projekt-Root sein, war %q", output)
	}
}
