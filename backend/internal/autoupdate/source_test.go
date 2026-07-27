package autoupdate

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestUpdateSourceFastForwardsCleanCheckout(t *testing.T) {
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git is not installed")
	}
	remote := filepath.Join(t.TempDir(), "remote.git")
	runTestGit(t, "", "init", "--bare", "--initial-branch=main", remote)
	publisher := filepath.Join(t.TempDir(), "publisher")
	runTestGit(t, "", "clone", remote, publisher)
	configureTestGit(t, publisher)
	if err := os.WriteFile(filepath.Join(publisher, "version.txt"), []byte("one\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	runTestGit(t, publisher, "add", "version.txt")
	runTestGit(t, publisher, "commit", "-m", "one")
	runTestGit(t, publisher, "push", "origin", "main")

	checkout := filepath.Join(t.TempDir(), "checkout")
	runTestGit(t, "", "clone", remote, checkout)
	configureTestGit(t, checkout)
	if err := os.WriteFile(filepath.Join(publisher, "version.txt"), []byte("two\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	runTestGit(t, publisher, "add", "version.txt")
	runTestGit(t, publisher, "commit", "-m", "two")
	runTestGit(t, publisher, "push", "origin", "main")

	result, err := UpdateSource(context.Background(), checkout, remote, "main")
	if err != nil {
		t.Fatalf("UpdateSource() error = %v", err)
	}
	if !result.Updated || result.Before == result.After {
		t.Fatalf("UpdateSource() result = %#v", result)
	}
	content, err := os.ReadFile(filepath.Join(checkout, "version.txt"))
	if err != nil {
		t.Fatal(err)
	}
	if string(content) != "two\n" {
		t.Fatalf("updated content = %q", content)
	}
}

func TestUpdateSourcePreservesLocalChanges(t *testing.T) {
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git is not installed")
	}
	root := t.TempDir()
	runTestGit(t, "", "init", "--initial-branch=main", root)
	configureTestGit(t, root)
	path := filepath.Join(root, "file.txt")
	if err := os.WriteFile(path, []byte("committed\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	runTestGit(t, root, "add", "file.txt")
	runTestGit(t, root, "commit", "-m", "initial")
	if err := os.WriteFile(path, []byte("local\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	_, err := UpdateSource(context.Background(), root, root, "main")
	if !errors.Is(err, ErrSourceDirty) {
		t.Fatalf("UpdateSource() error = %v, want ErrSourceDirty", err)
	}
	content, readErr := os.ReadFile(path)
	if readErr != nil {
		t.Fatal(readErr)
	}
	if string(content) != "local\n" {
		t.Fatalf("local content was changed: %q", content)
	}
}

func configureTestGit(t *testing.T, root string) {
	t.Helper()
	runTestGit(t, root, "config", "user.email", "updater@example.invalid")
	runTestGit(t, root, "config", "user.name", "Updater Test")
}

func runTestGit(t *testing.T, root string, arguments ...string) string {
	t.Helper()
	commandArguments := arguments
	if root != "" {
		commandArguments = append([]string{"-C", root}, arguments...)
	}
	command := exec.Command("git", commandArguments...)
	command.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s: %v\n%s", strings.Join(commandArguments, " "), err, output)
	}
	return string(output)
}
