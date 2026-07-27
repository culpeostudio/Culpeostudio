package marktplatz

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPhiloEngineProbePathPrefersCanonicalEnvironment(t *testing.T) {
	t.Setenv(philoEngineHardwareProbeEnv, "/new/philoengine-probe.py")
	t.Setenv(legacyWhichLLMProbeEnv, "/legacy/probe.py")

	if got := philoEngineProbePath(); got != "/new/philoengine-probe.py" {
		t.Fatalf("philoEngineProbePath() = %q", got)
	}
}

func TestPhiloEngineProbePathSupportsLegacyEnvironment(t *testing.T) {
	t.Setenv(philoEngineHardwareProbeEnv, "")
	t.Setenv(legacyWhichLLMProbeEnv, "/legacy/probe.py")

	if got := philoEngineProbePath(); got != "/legacy/probe.py" {
		t.Fatalf("philoEngineProbePath() = %q", got)
	}
}

func TestPhiloEngineProbePathPrefersBrandedDefault(t *testing.T) {
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
	preferred := filepath.Join("tools", "philoengine_hardware_probe.py")
	legacy := filepath.Join("tools", "whichllm_hardware_probe.py")
	for _, path := range []string{legacy, preferred} {
		if err := os.WriteFile(path, []byte("# probe\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	if got := philoEngineProbePath(); got != preferred {
		t.Fatalf("philoEngineProbePath() = %q, want %q", got, preferred)
	}
}

func TestPhiloEnginePythonExecutablePrefersCanonicalEnvironment(t *testing.T) {
	t.Setenv(philoEngineHardwarePythonEnv, "/new/python")
	t.Setenv(legacyWhichLLMPythonEnv, "/legacy/python")

	got, err := philoEnginePythonExecutable()
	if err != nil {
		t.Fatal(err)
	}
	if got != "/new/python" {
		t.Fatalf("philoEnginePythonExecutable() = %q", got)
	}
}

func TestPhiloEnginePythonExecutableSupportsLegacyEnvironment(t *testing.T) {
	t.Setenv(philoEngineHardwarePythonEnv, "")
	t.Setenv(legacyWhichLLMPythonEnv, "/legacy/python")

	got, err := philoEnginePythonExecutable()
	if err != nil {
		t.Fatal(err)
	}
	if got != "/legacy/python" {
		t.Fatalf("philoEnginePythonExecutable() = %q", got)
	}
}
