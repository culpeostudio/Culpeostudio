package main

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestSameExecutableResolvesSymlink(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("symlink creation may require elevated Windows privileges")
	}
	root := t.TempDir()
	executable := filepath.Join(root, "launcher")
	if err := os.WriteFile(executable, []byte("launcher"), 0o700); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(root, "link")
	if err := os.Symlink(executable, link); err != nil {
		t.Fatal(err)
	}
	if !sameExecutable(executable, link) {
		t.Fatal("sameExecutable() did not resolve the symlink")
	}
}

func TestUpdateDisabledRecognizesDocumentedValues(t *testing.T) {
	for _, value := range []string{"1", "true", "TRUE", "yes", "on"} {
		t.Run(value, func(t *testing.T) {
			t.Setenv("PHILOENGINE_SKIP_UPDATE", value)
			if !updateDisabled() {
				t.Fatalf("updateDisabled() = false for %q", value)
			}
		})
	}
	t.Setenv("PHILOENGINE_SKIP_UPDATE", "0")
	if updateDisabled() {
		t.Fatal("updateDisabled() = true for 0")
	}
}
