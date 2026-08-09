package marketplace

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCulpeoStudioProbePathPrefersCanonicalEnvironment(t *testing.T) {
	t.Setenv(culpeoStudioHardwareProbeEnv, "/new/culpeostudio-probe.py")
	t.Setenv(legacyWhichLLMProbeEnv, "/legacy/probe.py")

	if got := culpeoStudioProbePath(); got != "/new/culpeostudio-probe.py" {
		t.Fatalf("culpeoStudioProbePath() = %q", got)
	}
}

func TestCulpeoStudioProbePathSupportsLegacyEnvironment(t *testing.T) {
	t.Setenv(culpeoStudioHardwareProbeEnv, "")
	t.Setenv(legacyWhichLLMProbeEnv, "/legacy/probe.py")

	if got := culpeoStudioProbePath(); got != "/legacy/probe.py" {
		t.Fatalf("culpeoStudioProbePath() = %q", got)
	}
}

func TestCulpeoStudioProbePathPrefersBrandedDefault(t *testing.T) {
	workingDirectory, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := os.Chdir(workingDirectory); err != nil {
			t.Errorf("restore working directory: %v", err)
		}
	})

	root := t.TempDir()
	if err := os.Chdir(root); err != nil {
		t.Fatal(err)
	}
	toolsDir := filepath.Join(root, "tools")
	if err := os.MkdirAll(toolsDir, 0o755); err != nil {
		t.Fatal(err)
	}
	preferred := filepath.Join("tools", "culpeostudio_hardware_probe.py")
	legacy := filepath.Join("tools", "whichllm_hardware_probe.py")
	for _, path := range []string{legacy, preferred} {
		if err := os.WriteFile(path, []byte("# probe\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	if got := culpeoStudioProbePath(); got != preferred {
		t.Fatalf("culpeoStudioProbePath() = %q, want %q", got, preferred)
	}
}

func TestCulpeoStudioPythonExecutablePrefersCanonicalEnvironment(t *testing.T) {
	t.Setenv(culpeoStudioHardwarePythonEnv, "/new/python")
	t.Setenv(legacyWhichLLMPythonEnv, "/legacy/python")

	got, err := culpeoStudioPythonExecutable()
	if err != nil {
		t.Fatal(err)
	}
	if got != "/new/python" {
		t.Fatalf("culpeoStudioPythonExecutable() = %q", got)
	}
}

func TestCulpeoStudioPythonExecutableSupportsLegacyEnvironment(t *testing.T) {
	t.Setenv(culpeoStudioHardwarePythonEnv, "")
	t.Setenv(legacyWhichLLMPythonEnv, "/legacy/python")

	got, err := culpeoStudioPythonExecutable()
	if err != nil {
		t.Fatal(err)
	}
	if got != "/legacy/python" {
		t.Fatalf("culpeoStudioPythonExecutable() = %q", got)
	}
}
