package autoupdate

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var (
	ErrSourceNotGit   = errors.New("source directory is not a Git checkout")
	ErrSourceDirty    = errors.New("source checkout contains local changes")
	ErrSourceBranch   = errors.New("source checkout is not on the update branch")
	ErrSourceDiverged = errors.New("source checkout has diverged from the update branch")
	ErrGitUnavailable = errors.New("Git is not installed")
)

type SourceUpdateResult struct {
	Updated bool
	Before  string
	After   string
}

// UpdateSource performs a safe fast-forward update. It intentionally refuses
// to overwrite local changes, switch branches, rebase, or reset commits.
func UpdateSource(
	ctx context.Context,
	root string,
	repository string,
	branch string,
) (SourceUpdateResult, error) {
	git, err := exec.LookPath("git")
	if err != nil {
		return SourceUpdateResult{}, ErrGitUnavailable
	}
	absoluteRoot, err := filepath.Abs(root)
	if err != nil {
		return SourceUpdateResult{}, fmt.Errorf("resolve source root: %w", err)
	}
	if info, err := os.Stat(filepath.Join(absoluteRoot, ".git")); err != nil ||
		(!info.IsDir() && !info.Mode().IsRegular()) {
		return SourceUpdateResult{}, ErrSourceNotGit
	}
	branch = strings.TrimSpace(branch)
	if branch == "" {
		return SourceUpdateResult{}, fmt.Errorf("update branch is empty")
	}
	currentBranch, err := runGit(ctx, git, absoluteRoot, "symbolic-ref", "--quiet", "--short", "HEAD")
	if err != nil || strings.TrimSpace(currentBranch) != branch {
		return SourceUpdateResult{}, fmt.Errorf("%w: expected %q, found %q", ErrSourceBranch, branch, strings.TrimSpace(currentBranch))
	}
	status, err := runGit(ctx, git, absoluteRoot, "status", "--porcelain", "--untracked-files=normal")
	if err != nil {
		return SourceUpdateResult{}, err
	}
	if strings.TrimSpace(status) != "" {
		return SourceUpdateResult{}, ErrSourceDirty
	}
	before, err := runGit(ctx, git, absoluteRoot, "rev-parse", "HEAD")
	if err != nil {
		return SourceUpdateResult{}, err
	}
	if _, err := runGit(ctx, git, absoluteRoot,
		"fetch", "--quiet", "--no-tags", repository, "refs/heads/"+branch); err != nil {
		return SourceUpdateResult{}, fmt.Errorf("fetch source update: %w", err)
	}
	after, err := runGit(ctx, git, absoluteRoot, "rev-parse", "FETCH_HEAD")
	if err != nil {
		return SourceUpdateResult{}, err
	}
	before = strings.TrimSpace(before)
	after = strings.TrimSpace(after)
	if before == after {
		return SourceUpdateResult{Before: before, After: after}, nil
	}
	ancestor := exec.CommandContext(ctx, git, "-C", absoluteRoot, "merge-base", "--is-ancestor", before, after)
	if output, err := ancestor.CombinedOutput(); err != nil {
		return SourceUpdateResult{}, fmt.Errorf("%w: %s", ErrSourceDiverged, strings.TrimSpace(string(output)))
	}
	if _, err := runGit(ctx, git, absoluteRoot, "merge", "--quiet", "--ff-only", "FETCH_HEAD"); err != nil {
		return SourceUpdateResult{}, fmt.Errorf("activate source update: %w", err)
	}
	activated, err := runGit(ctx, git, absoluteRoot, "rev-parse", "HEAD")
	if err != nil {
		return SourceUpdateResult{}, err
	}
	activated = strings.TrimSpace(activated)
	if activated != after {
		return SourceUpdateResult{}, fmt.Errorf("source update activated %s instead of %s", activated, after)
	}
	return SourceUpdateResult{Updated: true, Before: before, After: after}, nil
}

func runGit(ctx context.Context, executable, root string, arguments ...string) (string, error) {
	commandArguments := append([]string{"-C", root}, arguments...)
	command := exec.CommandContext(ctx, executable, commandArguments...)
	command.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
	output, err := command.CombinedOutput()
	if err != nil {
		detail := strings.TrimSpace(string(output))
		if detail == "" {
			detail = err.Error()
		}
		return "", fmt.Errorf("git %s: %s", strings.Join(arguments, " "), detail)
	}
	return string(output), nil
}
