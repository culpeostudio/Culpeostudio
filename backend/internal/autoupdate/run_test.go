package autoupdate

import (
	"os"
	"path/filepath"
	"testing"
)

func TestBundledHardwareProbePrefersPhiloEngineName(t *testing.T) {
	root := t.TempDir()
	toolsDir := filepath.Join(root, "backend", "tools")
	if err := os.MkdirAll(toolsDir, 0o755); err != nil {
		t.Fatal(err)
	}
	legacy := filepath.Join(toolsDir, "whichllm_hardware_probe.py")
	preferred := filepath.Join(toolsDir, "philoengine_hardware_probe.py")
	for _, path := range []string{legacy, preferred} {
		if err := os.WriteFile(path, []byte("# probe\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	if got := bundledHardwareProbe(root); got != preferred {
		t.Fatalf("bundledHardwareProbe() = %q, want %q", got, preferred)
	}
}

func TestBundledHardwareProbeSupportsLegacyBundle(t *testing.T) {
	root := t.TempDir()
	legacy := filepath.Join(
		root,
		"backend",
		"tools",
		"whichllm_hardware_probe.py",
	)
	if err := os.MkdirAll(filepath.Dir(legacy), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(legacy, []byte("# legacy probe\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	if got := bundledHardwareProbe(root); got != legacy {
		t.Fatalf("bundledHardwareProbe() = %q, want %q", got, legacy)
	}
}
