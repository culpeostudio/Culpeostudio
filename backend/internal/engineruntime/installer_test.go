package engineruntime

import (
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

type recordingRunner struct {
	mu       sync.Mutex
	calls    [][]string
	started  chan struct{}
	block    bool
	fail     error
	failCall int
	output   string
	once     sync.Once
}

type serialRunner struct {
	mu        sync.Mutex
	current   int
	maximum   int
	firstSeen chan struct{}
	release   chan struct{}
	once      sync.Once
}

func (r *serialRunner) Run(ctx context.Context, _ []string, _ []string, _ io.Writer) error {
	r.mu.Lock()
	r.current++
	if r.current > r.maximum {
		r.maximum = r.current
	}
	r.mu.Unlock()
	blocked := false
	r.once.Do(func() {
		blocked = true
		close(r.firstSeen)
	})
	if blocked {
		select {
		case <-r.release:
		case <-ctx.Done():
		}
	}
	r.mu.Lock()
	r.current--
	r.mu.Unlock()
	return ctx.Err()
}

func (r *recordingRunner) Run(ctx context.Context, argv, _ []string, output io.Writer) error {
	r.mu.Lock()
	r.calls = append(r.calls, append([]string(nil), argv...))
	callCount := len(r.calls)
	r.mu.Unlock()
	text := r.output
	if text == "" {
		text = "runner output\n"
	}
	_, _ = io.WriteString(output, text)
	if r.started != nil {
		r.once.Do(func() { close(r.started) })
	}
	if r.block {
		<-ctx.Done()
		return ctx.Err()
	}
	if r.fail != nil && (r.failCall == 0 || callCount >= r.failCall) {
		return r.fail
	}
	return nil
}

func (r *recordingRunner) Calls() [][]string {
	r.mu.Lock()
	defer r.mu.Unlock()
	result := make([][]string, len(r.calls))
	for index := range r.calls {
		result[index] = append([]string(nil), r.calls[index]...)
	}
	return result
}

func TestInstallerDeduplicatesAndUsesArgv(t *testing.T) {
	runner := &recordingRunner{}
	installer, err := NewInstaller(t.TempDir(), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	recipe := DefaultLlamaCPPRecipe(nil)

	first, err := installer.Start(recipe)
	if err != nil {
		t.Fatal(err)
	}
	second, err := installer.Start(recipe)
	if err != nil {
		t.Fatal(err)
	}
	if first != second {
		t.Fatal("same recipe must return the same active install job")
	}
	snapshot, err := first.Wait(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if snapshot.Status != InstallReady {
		t.Fatalf("status = %s", snapshot.Status)
	}
	if !strings.Contains(snapshot.Log, "runner output") {
		t.Fatalf("runner log was not retained: %q", snapshot.Log)
	}

	calls := runner.Calls()
	if len(calls) != 3 {
		t.Fatalf("got %d commands, want venv, pip, probe", len(calls))
	}
	if got := calls[0]; len(got) != 4 || got[0] != "/usr/bin/python3" || got[1] != "-m" || got[2] != "venv" {
		t.Fatalf("unexpected venv argv: %#v", got)
	}
	pip := calls[1]
	if pip[1] != "-m" || pip[2] != "pip" || pip[len(pip)-1] != "llama-cpp-python[server]=="+LlamaCPPVersion {
		t.Fatalf("unexpected pip argv: %#v", pip)
	}
	for _, call := range calls {
		if call[0] == "sh" || call[0] == "bash" || call[0] == "cmd.exe" {
			t.Fatalf("installer invoked a shell: %#v", call)
		}
	}

	third, err := installer.Start(recipe)
	if err != nil {
		t.Fatal(err)
	}
	if third != first {
		t.Fatal("ready recipe must remain deduplicated")
	}
}

func TestExecCommandRunnerRevalidatesSpawnAdmissionImmediatelyBeforeStart(t *testing.T) {
	runner := &ExecCommandRunner{}
	denied := errors.New("resource guard warning")
	var admissions int
	runner.SetSpawnAdmission(func(ctx context.Context) (func(), error) {
		admissions++
		return nil, denied
	})

	err := runner.Run(context.Background(), []string{os.Args[0], "-test.run=^$"}, os.Environ(), io.Discard)
	if !errors.Is(err, denied) {
		t.Fatalf("Run error = %v, want admission denial", err)
	}
	if admissions != 1 {
		t.Fatalf("spawn admissions = %d, want 1", admissions)
	}
}

func TestInstallerCancellationAndRetry(t *testing.T) {
	runner := &recordingRunner{block: true, started: make(chan struct{})}
	installer, err := NewInstaller(t.TempDir(), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	job, err := installer.Start(DefaultVLLMRecipe())
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-runner.started:
	case <-time.After(2 * time.Second):
		t.Fatal("runner did not start")
	}
	if err := installer.Cancel(job.Snapshot().ID); err != nil {
		t.Fatal(err)
	}
	snapshot, err := job.Wait(context.Background())
	if !errors.Is(err, context.Canceled) || snapshot.Status != InstallCanceled {
		t.Fatalf("status=%s err=%v", snapshot.Status, err)
	}

	retry, err := installer.Start(DefaultVLLMRecipe())
	if err != nil {
		t.Fatal(err)
	}
	if retry == job {
		t.Fatal("canceled install must be retryable with a new job")
	}
	_ = installer.Cancel(retry.Snapshot().ID)
}

func TestInstallerCloseWaitsForRunningBuildToStop(t *testing.T) {
	runner := &recordingRunner{block: true, started: make(chan struct{})}
	installer, err := NewInstaller(t.TempDir(), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	job, err := installer.Start(DefaultLlamaCPPRecipe(nil))
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-runner.started:
	case <-time.After(time.Second):
		t.Fatal("runtime build did not start")
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	if err := installer.CloseContext(ctx); err != nil {
		t.Fatal(err)
	}
	snapshot := job.Snapshot()
	if snapshot.Status != InstallCanceled {
		t.Fatalf("status after close = %s", snapshot.Status)
	}
}

func TestInstallerSerializesDifferentRecipes(t *testing.T) {
	runner := &serialRunner{firstSeen: make(chan struct{}), release: make(chan struct{})}
	installer, err := NewInstaller(t.TempDir(), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	first, err := installer.Start(DefaultVLLMRecipe())
	if err != nil {
		t.Fatal(err)
	}
	second, err := installer.Start(DefaultLlamaCPPRecipe(nil))
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-runner.firstSeen:
	case <-time.After(time.Second):
		t.Fatal("first install did not start")
	}
	time.Sleep(50 * time.Millisecond)
	runner.mu.Lock()
	maximumBeforeRelease := runner.maximum
	runner.mu.Unlock()
	if maximumBeforeRelease != 1 {
		t.Fatalf("%d install commands ran concurrently", maximumBeforeRelease)
	}
	close(runner.release)
	if _, err := first.Wait(context.Background()); err != nil {
		t.Fatal(err)
	}
	if _, err := second.Wait(context.Background()); err != nil {
		t.Fatal(err)
	}
	runner.mu.Lock()
	maximum := runner.maximum
	runner.mu.Unlock()
	if maximum != 1 {
		t.Fatalf("installer maximum concurrency = %d, want 1", maximum)
	}
}

func TestInstallerRedactsURLCredentialsAndDropsProviderTokens(t *testing.T) {
	t.Setenv("HF_TOKEN", "must-not-leak")
	t.Setenv("OPENROUTER_TOKEN", "must-not-leak-either")
	t.Setenv("PATH", os.Getenv("PATH"))
	for _, entry := range sanitizedInstallerEnvironment() {
		if strings.Contains(entry, "must-not-leak") {
			t.Fatalf("provider token remained in installer environment: %q", entry)
		}
	}
	redacted := redactCommandArgument("https://user:password@example.invalid/simple?token=abc&ok=1")
	if strings.Contains(redacted, "password") || strings.Contains(redacted, "abc") || !strings.Contains(redacted, "redacted") {
		t.Fatalf("URL was not redacted: %q", redacted)
	}
}

func TestInstallerReportsSanitizedFailurePhaseAndUsefulSummary(t *testing.T) {
	t.Setenv("HF_TOKEN", "provider-secret-must-not-leak")
	runner := &recordingRunner{
		fail:     errors.New("exit status 1"),
		failCall: 2,
		output:   "HF_TOKEN=provider-secret-must-not-leak\nindex https://user:password@example.invalid/simple?token=query-secret\nERROR: Failed building wheel for llama-cpp-python\n",
	}
	installer, err := NewInstaller(t.TempDir(), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	job, err := installer.Start(DefaultLlamaCPPRecipe(nil))
	if err != nil {
		t.Fatal(err)
	}
	snapshot, waitErr := job.Wait(context.Background())
	if waitErr == nil {
		t.Fatal("failed runner unexpectedly produced a ready environment")
	}
	if snapshot.Status != InstallFailed || snapshot.Phase != InstallPackages {
		t.Fatalf("status=%s phase=%s", snapshot.Status, snapshot.Phase)
	}
	if snapshot.ErrorCode != "native_build_failed" || !strings.Contains(snapshot.Error, "native Runtime-Baustein") {
		t.Fatalf("error code=%q summary=%q", snapshot.ErrorCode, snapshot.Error)
	}
	if snapshot.DetailMessage == "" || snapshot.DetailMessage != snapshot.ErrorSummary {
		t.Fatalf("failure detail was not propagated: %#v", snapshot)
	}
	encoded := snapshot.Log + snapshot.Error
	if strings.Contains(encoded, "provider-secret-must-not-leak") || strings.Contains(encoded, "password") || strings.Contains(encoded, "query-secret") || strings.Contains(snapshot.Error, "exit status 1") {
		t.Fatalf("secret or opaque exit status leaked: %q", encoded)
	}
}

func TestInstallerAtomicallyReplacesInvalidExistingEnvironment(t *testing.T) {
	root := t.TempDir()
	recipe := DefaultLlamaCPPRecipe(nil)
	target, err := recipe.EnvironmentPath(root)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(target, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(target, "corrupt.txt"), []byte("partial"), 0o600); err != nil {
		t.Fatal(err)
	}
	installer, err := NewInstaller(root, "/bootstrap/python", &recordingRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	job, err := installer.Start(recipe)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := job.Wait(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if snapshot.Status != InstallReady || !manifestMatches(target, snapshot.RecipeDigest) {
		t.Fatalf("replacement snapshot = %#v", snapshot)
	}
	if _, err := os.Stat(filepath.Join(target, "corrupt.txt")); !os.IsNotExist(err) {
		t.Fatalf("invalid environment survived replacement: %v", err)
	}
	if _, err := os.Stat(target + ".previous"); !os.IsNotExist(err) {
		t.Fatalf("activation backup survived: %v", err)
	}
}
