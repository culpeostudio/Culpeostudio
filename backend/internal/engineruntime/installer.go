package engineruntime

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
)

type InstallStatus string

const (
	InstallQueued   InstallStatus = "queued"
	InstallCreating InstallStatus = "creating_environment"
	InstallPackages InstallStatus = "installing_packages"
	InstallProbing  InstallStatus = "probing"
	InstallReady    InstallStatus = "ready"
	InstallFailed   InstallStatus = "failed"
	InstallCanceled InstallStatus = "canceled"
)

type CommandRunner interface {
	Run(ctx context.Context, argv []string, environment []string, output io.Writer) error
}

type SpawnAdmission func(context.Context) (func(), error)

type ExecCommandRunner struct {
	mu             sync.RWMutex
	spawnAdmission SpawnAdmission
}

func (r *ExecCommandRunner) SetSpawnAdmission(admission SpawnAdmission) {
	r.mu.Lock()
	r.spawnAdmission = admission
	r.mu.Unlock()
}

func (r *ExecCommandRunner) admission() SpawnAdmission {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.spawnAdmission
}

func (r *ExecCommandRunner) Run(ctx context.Context, argv []string, environment []string, output io.Writer) error {
	if len(argv) == 0 || strings.TrimSpace(argv[0]) == "" {
		return errors.New("empty command argv")
	}
	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Env = append([]string(nil), environment...)
	cmd.Stdout = output
	cmd.Stderr = output

	cmd.WaitDelay = 500 * time.Millisecond
	configureProcessGroup(cmd)
	lifetime, err := prepareCommandLifetime(cmd)
	if err != nil {
		return fmt.Errorf("prepare installer process lifetime: %w", err)
	}
	defer lifetime.Cleanup()
	if err := ctx.Err(); err != nil {
		return err
	}
	releaseSpawn := func() {}
	if admission := r.admission(); admission != nil {
		var err error
		releaseSpawn, err = admission(ctx)
		if err != nil {
			return err
		}
		if releaseSpawn == nil {
			releaseSpawn = func() {}
		}
	}
	if err := ctx.Err(); err != nil {
		releaseSpawn()
		return err
	}
	if err := cmd.Start(); err != nil {
		releaseSpawn()
		return err
	}
	if err := lifetime.Bind(cmd); err != nil {

		lifetime.Cleanup()
		_ = signalProcessGroup(cmd, true)
		_ = cmd.Wait()
		releaseSpawn()
		return fmt.Errorf("bind installer process lifetime: %w", err)
	}

	releaseSpawn()
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()
	select {
	case err := <-done:

		_ = signalProcessGroup(cmd, true)
		return err
	case <-ctx.Done():
		_ = signalProcessGroup(cmd, false)
		select {
		case <-done:
			_ = signalProcessGroup(cmd, true)
			return ctx.Err()
		case <-time.After(2 * time.Second):
			_ = signalProcessGroup(cmd, true)
			<-done
			return ctx.Err()
		}
	}
}

type InstallJobSnapshot struct {
	ID              string        `json:"id"`
	RecipeDigest    string        `json:"recipe_digest"`
	Runtime         RuntimeKind   `json:"runtime"`
	Version         string        `json:"version"`
	EnvironmentPath string        `json:"environment_path"`
	Status          InstallStatus `json:"status"`
	Phase           InstallStatus `json:"phase"`

	Progress      float64    `json:"progress"`
	Message       string     `json:"message,omitempty"`
	DetailMessage string     `json:"detail_message,omitempty"`
	Log           string     `json:"log,omitempty"`
	Error         string     `json:"error,omitempty"`
	ErrorSummary  string     `json:"error_summary,omitempty"`
	ErrorCode     string     `json:"error_code,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
	FinishedAt    *time.Time `json:"finished_at,omitempty"`
}

type InstallJob struct {
	mu              sync.RWMutex
	id              string
	recipe          Recipe
	digest          string
	environmentPath string
	status          InstallStatus
	failurePhase    InstallStatus
	log             *RingBuffer
	err             string
	errorCode       string
	secretValues    []string
	createdAt       time.Time
	updatedAt       time.Time
	finishedAt      *time.Time
	cancel          context.CancelFunc
	done            chan struct{}
	doneOnce        sync.Once

	pipCollected int
	pipProgress  float64
}

func (j *InstallJob) observePipLine(line string) {
	trimmed := strings.TrimSpace(line)
	if trimmed == "" {
		return
	}
	lower := strings.ToLower(trimmed)
	j.mu.Lock()
	defer j.mu.Unlock()
	switch {
	case strings.HasPrefix(lower, "collecting "):
		j.pipCollected++
		estimate := 0.75 * float64(j.pipCollected) / float64(j.pipCollected+8)
		if estimate > j.pipProgress {
			j.pipProgress = estimate
		}
	case strings.HasPrefix(lower, "building wheel") || strings.HasPrefix(lower, "building editable"):
		if j.pipProgress < 0.8 {
			j.pipProgress = 0.8
		}
	case strings.HasPrefix(lower, "installing collected packages"):
		if j.pipProgress < 0.9 {
			j.pipProgress = 0.9
		}
	case strings.HasPrefix(lower, "successfully installed"):
		j.pipProgress = 1
	}
}

func (j *InstallJob) progressLocked() float64 {
	switch j.status {
	case InstallQueued:
		return 0.02
	case InstallCreating:
		return 0.1
	case InstallPackages:
		return 0.15 + 0.7*j.pipProgress
	case InstallProbing:
		return 0.9
	case InstallReady, InstallFailed, InstallCanceled:
		return 1
	}
	return 0
}

type lineSplittingWriter struct {
	output  io.Writer
	observe func(string)
	buffer  []byte
}

func (w *lineSplittingWriter) Write(p []byte) (int, error) {
	n, err := w.output.Write(p)
	w.buffer = append(w.buffer, p[:n]...)
	for {
		index := -1
		for at, b := range w.buffer {
			if b == '\n' || b == '\r' {
				index = at
				break
			}
		}
		if index < 0 {
			break
		}
		line := string(w.buffer[:index])
		w.buffer = w.buffer[index+1:]
		w.observe(line)
	}

	if len(w.buffer) > 8192 {
		w.buffer = w.buffer[len(w.buffer)-8192:]
	}
	return n, err
}

func (j *InstallJob) Snapshot() InstallJobSnapshot {
	j.mu.RLock()
	defer j.mu.RUnlock()
	phase := j.status
	if j.failurePhase != "" {
		phase = j.failurePhase
	}
	message := installPhaseMessage(phase)
	detailMessage := installDetailMessage(phase, j.log.String())
	errorSummary := sanitizeInstallText(j.err, j.secretValues)
	if j.status == InstallFailed {
		message = "Fehlgeschlagen waehrend: " + message
		detailMessage = errorSummary
	}
	return InstallJobSnapshot{
		ID:              j.id,
		RecipeDigest:    j.digest,
		Runtime:         j.recipe.Runtime,
		Version:         j.recipe.Version,
		EnvironmentPath: j.environmentPath,
		Status:          j.status,
		Phase:           phase,
		Progress:        j.progressLocked(),
		Message:         message,
		DetailMessage:   sanitizeInstallText(detailMessage, j.secretValues),
		Log:             sanitizeInstallText(j.log.String(), j.secretValues),
		Error:           errorSummary,
		ErrorSummary:    errorSummary,
		ErrorCode:       j.errorCode,
		CreatedAt:       j.createdAt,
		UpdatedAt:       j.updatedAt,
		FinishedAt:      cloneTime(j.finishedAt),
	}
}

func (j *InstallJob) Wait(ctx context.Context) (InstallJobSnapshot, error) {
	select {
	case <-ctx.Done():
		return j.Snapshot(), ctx.Err()
	case <-j.done:
		snapshot := j.Snapshot()
		if snapshot.Status == InstallFailed {
			return snapshot, errors.New(snapshot.Error)
		}
		if snapshot.Status == InstallCanceled {
			return snapshot, context.Canceled
		}
		return snapshot, nil
	}
}

func (j *InstallJob) Done() <-chan struct{} { return j.done }

func (j *InstallJob) setStatus(status InstallStatus, err error, terminal bool) {
	now := time.Now().UTC()
	j.mu.Lock()
	previousStatus := j.status
	j.status = status
	j.updatedAt = now
	if err != nil {
		j.err = err.Error()
		if status == InstallFailed && j.failurePhase == "" {
			j.failurePhase = previousStatus
		}
	}
	if terminal {
		j.finishedAt = &now
	}
	j.mu.Unlock()
	if terminal {
		j.doneOnce.Do(func() { close(j.done) })
	}
}

func (j *InstallJob) failCommand(phase InstallStatus, code, summary string) {
	now := time.Now().UTC()
	j.mu.Lock()
	j.status = InstallFailed
	j.failurePhase = phase
	j.errorCode = code
	j.err = summary
	j.updatedAt = now
	j.finishedAt = &now
	j.mu.Unlock()
	j.doneOnce.Do(func() { close(j.done) })
}

type Installer struct {
	root     string
	python   string
	runner   CommandRunner
	logBytes int

	mu          sync.RWMutex
	jobs        map[string]*InstallJob
	jobsByKey   map[string]*InstallJob
	installSlot chan struct{}
	closed      bool
}

func NewInstaller(root, python string, runner CommandRunner) (*Installer, error) {
	if strings.TrimSpace(root) == "" {
		return nil, errors.New("runtime environment root is required")
	}
	if strings.TrimSpace(python) == "" {
		return nil, errors.New("bootstrap Python executable is required")
	}
	if runner == nil {
		runner = &ExecCommandRunner{}
	}
	installer := &Installer{
		root:        root,
		python:      python,
		runner:      runner,
		logBytes:    256 * 1024,
		jobs:        make(map[string]*InstallJob),
		jobsByKey:   make(map[string]*InstallJob),
		installSlot: make(chan struct{}, 1),
	}

	installer.SweepStaleArtifacts()
	return installer, nil
}

func (i *Installer) SweepStaleArtifacts() int {
	removed := 0
	kinds, err := os.ReadDir(i.root)
	if err != nil {
		return 0
	}
	for _, kind := range kinds {
		if !kind.IsDir() {
			continue
		}
		versionsPath := filepath.Join(i.root, kind.Name())
		versions, err := os.ReadDir(versionsPath)
		if err != nil {
			continue
		}
		for _, version := range versions {
			if !version.IsDir() {
				continue
			}
			environmentsPath := filepath.Join(versionsPath, version.Name())
			environments, err := os.ReadDir(environmentsPath)
			if err != nil {
				continue
			}
			for _, environment := range environments {
				name := environment.Name()
				if !environment.IsDir() {
					continue
				}
				if strings.Contains(name, ".staging-") || strings.HasSuffix(name, ".previous") {
					if os.RemoveAll(filepath.Join(environmentsPath, name)) == nil {
						removed++
					}
				}
			}
		}
	}
	return removed
}

const minimumInstallFreeBytes int64 = 5 << 30

func formatGiB(bytes int64) string {
	return fmt.Sprintf("%.1f GB", float64(bytes)/float64(1<<30))
}

func (i *Installer) SetSpawnAdmission(admission SpawnAdmission) {
	i.mu.RLock()
	runner := i.runner
	i.mu.RUnlock()
	if configurable, ok := runner.(interface{ SetSpawnAdmission(SpawnAdmission) }); ok {
		configurable.SetSpawnAdmission(admission)
	}
}

func (i *Installer) Start(recipe Recipe) (*InstallJob, error) {
	digest, err := recipe.Digest()
	if err != nil {
		return nil, err
	}
	environmentPath, err := recipe.EnvironmentPath(i.root)
	if err != nil {
		return nil, err
	}

	i.mu.Lock()
	if i.closed {
		i.mu.Unlock()
		return nil, errors.New("installer is closed")
	}
	if existing := i.jobsByKey[digest]; existing != nil {
		status := existing.Snapshot().Status
		if status != InstallFailed && status != InstallCanceled {
			i.mu.Unlock()
			return existing, nil
		}
	}
	now := time.Now().UTC()
	ctx, cancel := context.WithCancel(context.Background())
	job := &InstallJob{
		id:              randomID("runtime"),
		recipe:          recipe,
		digest:          digest,
		environmentPath: environmentPath,
		status:          InstallQueued,
		log:             NewRingBuffer(i.logBytes),
		createdAt:       now,
		updatedAt:       now,
		cancel:          cancel,
		done:            make(chan struct{}),
		secretValues:    providerSecretValues(),
	}
	i.jobs[job.id] = job
	i.jobsByKey[digest] = job
	i.mu.Unlock()

	go i.run(ctx, job)
	return job, nil
}

func (i *Installer) Job(id string) (InstallJobSnapshot, bool) {
	i.mu.RLock()
	job := i.jobs[id]
	i.mu.RUnlock()
	if job == nil {
		return InstallJobSnapshot{}, false
	}
	return job.Snapshot(), true
}

func (i *Installer) Jobs() []InstallJobSnapshot {
	i.mu.RLock()
	jobs := make([]*InstallJob, 0, len(i.jobs))
	for _, job := range i.jobs {
		jobs = append(jobs, job)
	}
	i.mu.RUnlock()
	result := make([]InstallJobSnapshot, 0, len(jobs))
	for _, job := range jobs {
		result = append(result, job.Snapshot())
	}
	sort.Slice(result, func(a, b int) bool { return result[a].CreatedAt.Before(result[b].CreatedAt) })
	return result
}

func (i *Installer) Latest(recipe Recipe) (InstallJobSnapshot, bool) {
	digest, err := recipe.Digest()
	if err != nil {
		return InstallJobSnapshot{}, false
	}
	i.mu.RLock()
	job := i.jobsByKey[digest]
	i.mu.RUnlock()
	if job == nil {
		return InstallJobSnapshot{}, false
	}
	return job.Snapshot(), true
}

func (i *Installer) Cancel(id string) error {
	i.mu.RLock()
	job := i.jobs[id]
	i.mu.RUnlock()
	if job == nil {
		return fmt.Errorf("install job %q not found", id)
	}
	status := job.Snapshot().Status
	if status == InstallReady || status == InstallFailed || status == InstallCanceled {
		return nil
	}
	job.cancel()
	return nil
}

func (i *Installer) CancelContext(ctx context.Context, id string) (InstallJobSnapshot, error) {
	i.mu.RLock()
	job := i.jobs[id]
	i.mu.RUnlock()
	if job == nil {
		return InstallJobSnapshot{}, fmt.Errorf("install job %q not found", id)
	}
	if err := i.Cancel(id); err != nil {
		return job.Snapshot(), err
	}
	return job.Wait(ctx)
}

func (i *Installer) Close() {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = i.CloseContext(ctx)
}

func (i *Installer) CloseContext(ctx context.Context) error {
	i.mu.Lock()
	i.closed = true
	jobs := make([]*InstallJob, 0, len(i.jobs))
	for _, job := range i.jobs {
		jobs = append(jobs, job)
	}
	i.mu.Unlock()
	for _, job := range jobs {
		job.cancel()
	}
	for _, job := range jobs {
		select {
		case <-job.Done():
		case <-ctx.Done():
			return fmt.Errorf("runtime installer shutdown timed out: %w", ctx.Err())
		}
	}
	return nil
}

func (i *Installer) run(ctx context.Context, job *InstallJob) {
	if manifestMatches(job.environmentPath, job.digest) {
		_, _ = io.WriteString(job.log, "runtime environment already installed\n")
		job.setStatus(InstallReady, nil, true)
		return
	}

	select {
	case i.installSlot <- struct{}{}:
		defer func() { <-i.installSlot }()
	case <-ctx.Done():
		job.setStatus(InstallCanceled, context.Canceled, true)
		return
	}

	parent := filepath.Dir(job.environmentPath)
	if err := os.MkdirAll(parent, 0o700); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}

	if free, err := freeDiskBytes(parent); err == nil && free >= 0 && free < minimumInstallFreeBytes {
		job.failCommand(InstallCreating, "disk_full", fmt.Sprintf(
			"Mindestens %s freier Speicherplatz sind fuer die Runtime-Installation erforderlich. Aktuell verfuegbar: %s. Bitte Speicherplatz freigeben und erneut versuchen.",
			formatGiB(minimumInstallFreeBytes), formatGiB(free)))
		return
	}
	staging := job.environmentPath + ".staging-" + job.id
	if err := os.Mkdir(staging, 0o700); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}

	defer func() { _ = os.RemoveAll(staging) }()

	env := mergeEnvironment(sanitizedInstallerEnvironment(), job.recipe.Environment)
	job.setStatus(InstallCreating, nil, false)
	if err := i.runCommand(ctx, job, []string{i.python, "-m", "venv", staging}, env); err != nil {
		i.finishCommandError(ctx, job, err)
		return
	}

	if _, isExec := i.runner.(*ExecCommandRunner); isExec && job.recipe.Runtime == RuntimeLlamaCPP {
		if err := checkNativeBuildTools(); err != nil {
			job.failCommand(InstallPackages, "compiler_missing", err.Error())
			return
		}
	}

	python := environmentPython(staging)
	argv := []string{python, "-m", "pip", "install", "--disable-pip-version-check", "--no-input"}
	argv = append(argv, job.recipe.PipArgs...)
	argv = append(argv, job.recipe.Packages...)
	job.setStatus(InstallPackages, nil, false)
	pipOutput := &lineSplittingWriter{output: job.log, observe: job.observePipLine}
	if err := i.runCommandWithOutput(ctx, job, argv, env, pipOutput); err != nil {
		i.finishCommandError(ctx, job, err)
		return
	}

	job.setStatus(InstallProbing, nil, false)
	if len(job.recipe.ProbeModules) > 0 {
		probe := "import importlib; [importlib.import_module(name) for name in " + pythonStringList(job.recipe.ProbeModules) + "]"
		if err := i.runCommand(ctx, job, []string{python, "-c", probe}, env); err != nil {
			i.finishCommandError(ctx, job, err)
			return
		}
	}
	if len(job.recipe.SmokeTestArgs) > 0 {
		argv = append([]string{python}, job.recipe.SmokeTestArgs...)
		if err := i.runCommand(ctx, job, argv, env); err != nil {
			i.finishCommandError(ctx, job, err)
			return
		}
	}

	manifest := installManifest{
		RecipeDigest: job.digest,
		Runtime:      job.recipe.Runtime,
		Version:      job.recipe.Version,
		InstalledAt:  time.Now().UTC(),
	}
	manifestBytes, err := json.MarshalIndent(manifest, "", "  ")
	if err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}
	if err := os.WriteFile(filepath.Join(staging, installManifestName), manifestBytes, 0o600); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}
	if err := activateRuntimeEnvironment(staging, job.environmentPath, job.digest); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}
	job.setStatus(InstallReady, nil, true)
}

func activateRuntimeEnvironment(staging, target, digest string) error {
	if manifestMatches(target, digest) {
		return nil
	}
	backup := target + ".previous"
	_ = os.RemoveAll(backup)
	hadTarget := false
	if _, err := os.Stat(target); err == nil {
		if err := os.Rename(target, backup); err != nil {
			return fmt.Errorf("quarantine invalid runtime environment: %w", err)
		}
		hadTarget = true
	} else if !os.IsNotExist(err) {
		return fmt.Errorf("inspect runtime environment: %w", err)
	}
	if err := os.Rename(staging, target); err != nil {
		if hadTarget {
			_ = os.Rename(backup, target)
		}
		return fmt.Errorf("activate runtime environment: %w", err)
	}
	_ = os.RemoveAll(backup)
	return nil
}

func (i *Installer) runCommand(ctx context.Context, job *InstallJob, argv, env []string) error {
	return i.runCommandWithOutput(ctx, job, argv, env, job.log)
}

func (i *Installer) runCommandWithOutput(ctx context.Context, job *InstallJob, argv, env []string, output io.Writer) error {
	redacted := make([]string, len(argv))
	for index, arg := range argv {
		redacted[index] = redactCommandArgument(arg)
	}
	_, _ = fmt.Fprintf(job.log, "$ %s\n", strings.Join(redacted, " "))
	return i.runner.Run(ctx, append([]string(nil), argv...), append([]string(nil), env...), output)
}

func sanitizedInstallerEnvironment() []string {
	denied := []string{"HF_TOKEN", "HUGGINGFACE_TOKEN", "OPENROUTER_TOKEN", "FEATHERLESS_TOKEN", "OPENAI_API_KEY", "ANTHROPIC_API_KEY"}
	result := []string{}
	for _, entry := range os.Environ() {
		key := entry
		if at := strings.IndexByte(entry, '='); at >= 0 {
			key = entry[:at]
		}
		blocked := false
		for _, secretKey := range denied {
			if strings.EqualFold(key, secretKey) {
				blocked = true
				break
			}
		}
		if !blocked {
			result = append(result, entry)
		}
	}
	return result
}

func redactCommandArgument(argument string) string {
	for _, marker := range []string{"https://", "http://"} {
		if index := strings.Index(argument, marker); index > 0 {
			return argument[:index] + redactCommandArgument(argument[index:])
		}
	}
	parsed, err := url.Parse(argument)
	if err == nil && parsed.Scheme != "" && parsed.Host != "" {
		if parsed.User != nil {
			parsed.User = url.User("redacted")
		}
		query := parsed.Query()
		for key := range query {
			lower := strings.ToLower(key)
			if strings.Contains(lower, "token") || strings.Contains(lower, "key") || strings.Contains(lower, "secret") {
				query.Set(key, "redacted")
			}
		}
		parsed.RawQuery = query.Encode()
		return parsed.String()
	}
	return argument
}

func (i *Installer) finishCommandError(ctx context.Context, job *InstallJob, err error) {
	if errors.Is(ctx.Err(), context.Canceled) {
		job.setStatus(InstallCanceled, context.Canceled, true)
		return
	}
	snapshot := job.Snapshot()
	code, summary := summarizeInstallFailure(snapshot.Phase, err, snapshot.Log)
	job.failCommand(snapshot.Phase, code, summary)
}

func installPhaseMessage(phase InstallStatus) string {
	switch phase {
	case InstallQueued:
		return "Wartet auf einen freien Installationsplatz"
	case InstallCreating:
		return "Isolierte Python-Umgebung wird angelegt"
	case InstallPackages:
		return "Runtime-Pakete werden geladen und installiert"
	case InstallProbing:
		return "Imports und Hardware-Unterstuetzung werden geprueft"
	case InstallReady:
		return "Runtime ist installiert und einsatzbereit"
	case InstallCanceled:
		return "Runtime-Vorbereitung wurde abgebrochen"
	case InstallFailed:
		return "Runtime-Vorbereitung ist fehlgeschlagen"
	default:
		return "Runtime wird vorbereitet"
	}
}

func installDetailMessage(phase InstallStatus, logText string) string {
	if detail := lastUsefulInstallLine(logText); detail != "" {
		return friendlyInstallLogDetail(detail)
	}
	switch phase {
	case InstallQueued:
		return "Die Vorbereitung wartet auf einen freien Installationsplatz."
	case InstallCreating:
		return "Eine isolierte Python-Umgebung wird angelegt."
	case InstallPackages:
		return "Die benoetigten Runtime-Pakete werden heruntergeladen, gebaut und installiert."
	case InstallProbing:
		return "Import, Hardwarezugriff und ein kurzer Funktionstest werden geprueft."
	case InstallReady:
		return "Die Runtime wurde erfolgreich geprueft und atomar aktiviert."
	case InstallCanceled:
		return "Die Vorbereitung wurde abgebrochen."
	default:
		return "Die Runtime wird vorbereitet."
	}
}

var pipDownloadPattern = regexp.MustCompile(`(?i)downloading\s+([a-zA-Z0-9_.]+?)-\d[^\s]*\s*\(([^)]+)\)`)

func friendlyInstallLogDetail(detail string) string {
	lower := strings.ToLower(strings.TrimSpace(detail))
	switch {
	case strings.HasPrefix(lower, "downloading ") || strings.Contains(lower, " downloading "):
		if match := pipDownloadPattern.FindStringSubmatch(detail); match != nil {
			return fmt.Sprintf("Runtime-Paket %s (%s) wird heruntergeladen.", match[1], match[2])
		}
		return "Ein benoetigtes Runtime-Paket wird heruntergeladen."
	case strings.Contains(lower, "building wheel") || strings.Contains(lower, "building editable"):
		return "Ein nativer Runtime-Baustein wird fuer dieses System erstellt. Das kann einige Minuten dauern."
	case strings.Contains(lower, "installing collected packages"):
		return "Die heruntergeladenen Runtime-Pakete werden in der isolierten Umgebung aktiviert."
	case strings.Contains(lower, "successfully installed"):
		return "Die Runtime-Pakete sind installiert; als Naechstes folgt der Funktionstest."
	case strings.Contains(lower, "requirement already satisfied"):
		return "Bereits vorhandene Runtime-Pakete werden ueberprueft."
	default:
		return detail
	}
}

func summarizeInstallFailure(phase InstallStatus, commandErr error, logText string) (string, string) {
	lower := strings.ToLower(logText)
	code := "runtime_install_failed"
	reason := "Die Runtime konnte nicht automatisch vorbereitet werden."
	switch {
	case strings.Contains(lower, "no space left on device"):
		code = "disk_full"
		reason = "Auf dem Datentraeger ist nicht genug freier Speicher vorhanden."
	case strings.Contains(lower, "no matching distribution found") || strings.Contains(lower, "could not find a version that satisfies"):
		code = "package_unavailable"
		reason = "Fuer diese Plattform oder Python-Version ist kein passendes, exakt versioniertes Paket verfuegbar."
	case strings.Contains(lower, "failed building wheel") || strings.Contains(lower, "could not build wheels") || strings.Contains(lower, "cmake error"):
		code = "native_build_failed"
		reason = "Der native Runtime-Baustein konnte auf diesem System nicht kompiliert werden; die CPU-Laufzeit bleibt als kompatibler Fallback verfuegbar."
	case strings.Contains(lower, "temporary failure in name resolution") || strings.Contains(lower, "connectionerror") || strings.Contains(lower, "connection timed out") || strings.Contains(lower, "network is unreachable"):
		code = "network_unavailable"
		reason = "Die Runtime-Pakete konnten wegen einer Netzwerkstoerung nicht geladen werden."
	case phase == InstallCreating:
		code = "python_environment_failed"
		reason = "Die isolierte Python-Umgebung konnte nicht angelegt werden; die Python-venv-Komponente fehlt moeglicherweise."
	case phase == InstallProbing:
		code = "runtime_probe_failed"
		reason = "Die Pakete wurden installiert, aber die Import- oder Hardwarepruefung war nicht erfolgreich."
	case phase == InstallPackages:
		code = "package_install_failed"
		reason = "Die Runtime-Pakete konnten nicht installiert werden."
	}
	if detail := lastUsefulInstallLine(logText); detail != "" {
		reason += " Letzte Diagnose: " + detail
	} else if commandErr != nil && !strings.HasPrefix(commandErr.Error(), "exit status") {
		reason += " Diagnose: " + commandErr.Error()
	}
	return code, reason
}

func lastUsefulInstallLine(logText string) string {
	lines := strings.Split(logText, "\n")
	for index := len(lines) - 1; index >= 0; index-- {
		line := strings.TrimSpace(lines[index])
		lower := strings.ToLower(line)
		if line == "" || strings.HasPrefix(line, "$") || strings.HasPrefix(lower, "notice:") || strings.Contains(lower, "token") || strings.Contains(lower, "authorization") || strings.Contains(lower, "bearer ") {
			continue
		}
		if len(line) > 280 {
			line = line[:280] + "..."
		}
		return line
	}
	return ""
}

var (
	installURLPattern   = regexp.MustCompile(`https?://[^\s]+`)
	secretAssignPattern = regexp.MustCompile(`(?i)(HF_TOKEN|HUGGINGFACE_TOKEN|OPENROUTER_TOKEN|FEATHERLESS_TOKEN|OPENAI_API_KEY|ANTHROPIC_API_KEY)\s*[:=]\s*[^\s]+`)
	bearerPattern       = regexp.MustCompile(`(?i)bearer\s+[A-Za-z0-9._~+/=-]+`)
)

func sanitizeInstallText(value string, secrets []string) string {
	for _, secret := range secrets {
		if len(secret) >= 4 {
			value = strings.ReplaceAll(value, secret, "[redacted]")
		}
	}
	value = secretAssignPattern.ReplaceAllString(value, "$1=[redacted]")
	value = bearerPattern.ReplaceAllString(value, "Bearer [redacted]")
	value = installURLPattern.ReplaceAllStringFunc(value, redactCommandArgument)
	return value
}

func providerSecretValues() []string {
	values := []string{}
	for _, key := range []string{"HF_TOKEN", "HUGGINGFACE_TOKEN", "OPENROUTER_TOKEN", "FEATHERLESS_TOKEN", "OPENAI_API_KEY", "ANTHROPIC_API_KEY"} {
		if value := os.Getenv(key); value != "" {
			values = append(values, value)
		}
	}
	return values
}

const installManifestName = ".philoengine-runtime.json"

type installManifest struct {
	RecipeDigest string      `json:"recipe_digest"`
	Runtime      RuntimeKind `json:"runtime"`
	Version      string      `json:"version"`
	InstalledAt  time.Time   `json:"installed_at"`
}

func manifestMatches(environmentPath, digest string) bool {
	b, err := os.ReadFile(filepath.Join(environmentPath, installManifestName))
	if err != nil {
		return false
	}
	var manifest installManifest
	return json.Unmarshal(b, &manifest) == nil && manifest.RecipeDigest == digest
}

func (i *Installer) Capability(recipe Recipe, base RuntimeCapability) RuntimeCapability {
	path, err := recipe.EnvironmentPath(i.root)
	if err != nil {
		base.ProbeError = err.Error()
		return base
	}
	digest, _ := recipe.Digest()
	base.Kind = recipe.Runtime
	base.Version = recipe.Version
	base.Environment = path
	base.Installed = manifestMatches(path, digest)
	base.Healthy = base.Installed
	return base
}

func pythonStringList(values []string) string {
	b, _ := json.Marshal(values)
	return string(b)
}

func mergeEnvironment(base []string, extra map[string]string) []string {
	values := make(map[string]string, len(base)+len(extra))
	for _, item := range base {
		if at := strings.IndexByte(item, '='); at > 0 {
			values[item[:at]] = item[at+1:]
		}
	}
	for key, value := range extra {
		values[key] = value
	}
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	result := make([]string, 0, len(keys))
	for _, key := range keys {
		result = append(result, key+"="+values[key])
	}
	return result
}

func randomID(prefix string) string {
	b := make([]byte, 8)
	if _, err := rand.Read(b); err == nil {
		return prefix + "-" + hex.EncodeToString(b)
	}
	return fmt.Sprintf("%s-%d", prefix, time.Now().UnixNano())
}

func cloneTime(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	cloned := *value
	return &cloned
}
