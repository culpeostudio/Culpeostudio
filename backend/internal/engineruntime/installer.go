package engineruntime

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
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
	InstallQueued      InstallStatus = "queued"
	InstallDownloading InstallStatus = "downloading"
	InstallVerifying   InstallStatus = "verifying"
	InstallExtracting  InstallStatus = "extracting"
	InstallProbing     InstallStatus = "probing"
	InstallReady       InstallStatus = "ready"
	InstallFailed      InstallStatus = "failed"
	InstallCanceled    InstallStatus = "canceled"
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
	ID          string        `json:"id"`
	BuildDigest string        `json:"build_digest"`
	Runtime     RuntimeKind   `json:"runtime"`
	Variant     BuildVariant  `json:"variant"`
	Version     string        `json:"version"`
	InstallPath string        `json:"install_path"`
	ServerPath  string        `json:"server_path,omitempty"`
	Status      InstallStatus `json:"status"`
	Phase       InstallStatus `json:"phase"`

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
	mu           sync.RWMutex
	id           string
	build        Build
	digest       string
	installPath  string
	serverPath   string
	status       InstallStatus
	failurePhase InstallStatus
	log          *RingBuffer
	err          string
	errorCode    string
	secretValues []string
	createdAt    time.Time
	updatedAt    time.Time
	finishedAt   *time.Time
	cancel       context.CancelFunc
	done         chan struct{}
	doneOnce     sync.Once

	downloadedBytes int64
	expectedBytes   int64
}

func (j *InstallJob) observeDownload(delta int64) {
	j.mu.Lock()
	j.downloadedBytes += delta
	j.updatedAt = time.Now().UTC()
	j.mu.Unlock()
}

func (j *InstallJob) setServerPath(relative string) {
	j.mu.Lock()
	j.serverPath = relative
	j.mu.Unlock()
}

// progressLocked reports one number for the whole install. Downloading is the
// long pole by far, so it owns most of the range.
func (j *InstallJob) progressLocked() float64 {
	switch j.status {
	case InstallQueued:
		return 0.02
	case InstallDownloading:
		if j.expectedBytes <= 0 {
			return 0.05
		}
		share := float64(j.downloadedBytes) / float64(j.expectedBytes)
		if share > 1 {
			share = 1
		}
		return 0.05 + 0.70*share
	case InstallVerifying:
		return 0.78
	case InstallExtracting:
		return 0.85
	case InstallProbing:
		return 0.95
	case InstallReady, InstallFailed, InstallCanceled:
		return 1
	}
	return 0
}

func (j *InstallJob) Snapshot() InstallJobSnapshot {
	j.mu.RLock()
	defer j.mu.RUnlock()
	phase := j.status
	if j.failurePhase != "" {
		phase = j.failurePhase
	}
	message := installPhaseMessage(phase)
	detailMessage := installDetailMessage(phase, j.build, j.downloadedBytes, j.expectedBytes)
	errorSummary := sanitizeInstallText(j.err, j.secretValues)
	if j.status == InstallFailed {
		message = "Fehlgeschlagen waehrend: " + message
		detailMessage = errorSummary
	}
	return InstallJobSnapshot{
		ID:            j.id,
		BuildDigest:   j.digest,
		Runtime:       RuntimeLlamaCPP,
		Variant:       j.build.Variant,
		Version:       j.build.Tag,
		InstallPath:   j.installPath,
		ServerPath:    j.serverPath,
		Status:        j.status,
		Phase:         phase,
		Progress:      j.progressLocked(),
		Message:       message,
		DetailMessage: sanitizeInstallText(detailMessage, j.secretValues),
		Log:           sanitizeInstallText(j.log.String(), j.secretValues),
		Error:         errorSummary,
		ErrorSummary:  errorSummary,
		ErrorCode:     j.errorCode,
		CreatedAt:     j.createdAt,
		UpdatedAt:     j.updatedAt,
		FinishedAt:    cloneTime(j.finishedAt),
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
	client   *http.Client
	runner   CommandRunner
	logBytes int

	mu          sync.RWMutex
	jobs        map[string]*InstallJob
	jobsByKey   map[string]*InstallJob
	installSlot chan struct{}
	closed      bool
}

// NewDownloadClient builds the HTTP client used to fetch release archives.
// There is deliberately no overall client timeout: the largest catalogued asset
// is close to 400 MB and a slow connection is not a failure. Stalls are caught
// by the per-operation timeouts below and by cancelling the job context.
func NewDownloadClient() *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyFromEnvironment,
			DialContext: (&net.Dialer{
				Timeout:   30 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
			TLSHandshakeTimeout:   30 * time.Second,
			ResponseHeaderTimeout: 60 * time.Second,
			ExpectContinueTimeout: 10 * time.Second,
			ForceAttemptHTTP2:     true,
			MaxIdleConns:          4,
			IdleConnTimeout:       90 * time.Second,
		},
	}
}

func NewInstaller(root string, client *http.Client, runner CommandRunner) (*Installer, error) {
	if strings.TrimSpace(root) == "" {
		return nil, errors.New("runtime install root is required")
	}
	if client == nil {
		client = NewDownloadClient()
	}
	if runner == nil {
		runner = &ExecCommandRunner{}
	}
	installer := &Installer{
		root:        root,
		client:      client,
		runner:      runner,
		logBytes:    256 * 1024,
		jobs:        make(map[string]*InstallJob),
		jobsByKey:   make(map[string]*InstallJob),
		installSlot: make(chan struct{}, 1),
	}

	installer.SweepStaleArtifacts()
	return installer, nil
}

// SweepStaleArtifacts removes half-finished installs and anything left behind
// by a layout this build no longer understands, including the Python virtual
// environments earlier versions kept here.
func (i *Installer) SweepStaleArtifacts() int {
	removed := 0
	known := map[string]bool{}
	for _, variant := range KnownBuildVariants() {
		known[safePathPart.ReplaceAllString(string(variant), "_")] = true
	}
	entries, err := os.ReadDir(i.root)
	if err != nil {
		return 0
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		if !known[entry.Name()] {
			// A directory that is not a build variant predates the switch to
			// prebuilt binaries and only wastes disk now.
			if os.RemoveAll(filepath.Join(i.root, entry.Name())) == nil {
				removed++
			}
			continue
		}
		removed += sweepVariantDirectory(filepath.Join(i.root, entry.Name()))
	}
	return removed
}

func sweepVariantDirectory(variantPath string) int {
	removed := 0
	tags, err := os.ReadDir(variantPath)
	if err != nil {
		return 0
	}
	for _, tag := range tags {
		if !tag.IsDir() {
			continue
		}
		installsPath := filepath.Join(variantPath, tag.Name())
		installs, err := os.ReadDir(installsPath)
		if err != nil {
			continue
		}
		for _, install := range installs {
			name := install.Name()
			if !install.IsDir() {
				continue
			}
			if strings.Contains(name, ".staging-") || strings.HasSuffix(name, ".previous") {
				if os.RemoveAll(filepath.Join(installsPath, name)) == nil {
					removed++
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

func (i *Installer) Start(build Build) (*InstallJob, error) {
	digest, err := build.Digest()
	if err != nil {
		return nil, err
	}
	installPath, err := build.InstallPath(i.root)
	if err != nil {
		return nil, err
	}

	var expected int64
	for _, asset := range build.Assets() {
		expected += asset.Bytes
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
		id:            randomID("runtime"),
		build:         build,
		digest:        digest,
		installPath:   installPath,
		status:        InstallQueued,
		log:           NewRingBuffer(i.logBytes),
		createdAt:     now,
		updatedAt:     now,
		cancel:        cancel,
		done:          make(chan struct{}),
		secretValues:  providerSecretValues(),
		expectedBytes: expected,
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

func (i *Installer) Latest(build Build) (InstallJobSnapshot, bool) {
	digest, err := build.Digest()
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
	if manifest, ok := readManifest(job.installPath); ok && manifest.BuildDigest == job.digest {
		_, _ = io.WriteString(job.log, "runtime build already installed\n")
		job.setServerPath(manifest.ServerPath)
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

	parent := filepath.Dir(job.installPath)
	if err := os.MkdirAll(parent, 0o700); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}

	// Archives are downloaded and then unpacked, so both have to fit at once.
	required := minimumInstallFreeBytes
	if needed := job.expectedBytes * 3; needed > required {
		required = needed
	}
	if free, err := freeDiskBytes(parent); err == nil && free >= 0 && free < required {
		job.failCommand(InstallDownloading, "disk_full", fmt.Sprintf(
			"Mindestens %s freier Speicherplatz sind fuer die Runtime-Installation erforderlich. Aktuell verfuegbar: %s. Bitte Speicherplatz freigeben und erneut versuchen.",
			formatGiB(required), formatGiB(free)))
		return
	}

	staging := job.installPath + ".staging-" + job.id
	if err := os.Mkdir(staging, 0o700); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}
	defer func() { _ = os.RemoveAll(staging) }()

	downloads := filepath.Join(staging, ".downloads")
	if err := os.Mkdir(downloads, 0o700); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}

	archivePaths := make([]string, 0, len(job.build.Assets()))
	for _, asset := range job.build.Assets() {
		job.setStatus(InstallDownloading, nil, false)
		_, _ = fmt.Fprintf(job.log, "downloading %s (%s)\n", asset.Name, formatGiB(asset.Bytes))
		archivePath := filepath.Join(downloads, asset.Name)
		if err := i.download(ctx, job, asset, archivePath); err != nil {
			i.finishError(ctx, job, InstallDownloading, err)
			return
		}
		job.setStatus(InstallVerifying, nil, false)
		if err := verifyDigest(archivePath, asset.SHA256); err != nil {
			i.finishError(ctx, job, InstallVerifying, err)
			return
		}
		_, _ = fmt.Fprintf(job.log, "verified %s\n", asset.Name)
		archivePaths = append(archivePaths, archivePath)
	}

	job.setStatus(InstallExtracting, nil, false)
	for _, archivePath := range archivePaths {
		_, _ = fmt.Fprintf(job.log, "unpacking %s\n", filepath.Base(archivePath))
		if err := extractArchive(archivePath, staging); err != nil {
			i.finishError(ctx, job, InstallExtracting, err)
			return
		}
		// The archive itself is not needed once unpacked and would otherwise be
		// activated along with the build.
		_ = os.Remove(archivePath)
	}
	if err := os.RemoveAll(downloads); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}

	serverPath, err := findServerBinary(staging)
	if err != nil {
		i.finishError(ctx, job, InstallExtracting, err)
		return
	}
	job.setServerPath(serverPath)

	job.setStatus(InstallProbing, nil, false)
	version, err := i.probe(ctx, job, filepath.Join(staging, serverPath))
	if err != nil {
		i.finishError(ctx, job, InstallProbing, err)
		return
	}
	// Ask the binary which KV cache types it implements instead of assuming the
	// upstream set. A build with sub-4-bit caches becomes usable through this
	// alone, and a build missing one the planner would have picked is caught
	// here rather than at model start. The same read yields the option list an
	// extra-args passthrough is checked against.
	cacheTypes, flags := i.probeHelp(ctx, job, filepath.Join(staging, serverPath))

	manifest := installManifest{
		BuildDigest: job.digest,
		Runtime:     RuntimeLlamaCPP,
		Variant:     job.build.Variant,
		Tag:         job.build.Tag,
		ServerPath:  serverPath,
		Version:     version,
		CacheTypes:  cacheTypes,
		Flags:       flags,
		InstalledAt: time.Now().UTC(),
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
	if err := activateRuntimeInstall(staging, job.installPath, job.digest); err != nil {
		job.setStatus(InstallFailed, err, true)
		return
	}
	job.setStatus(InstallReady, nil, true)
}

// download fetches one asset. The URL is derived from the pinned catalogue, so
// it is always an https github.com release URL; redirects to the release CDN
// are followed but the scheme is re-checked on every hop.
func (i *Installer) download(ctx context.Context, job *InstallJob, asset Asset, target string) error {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, job.build.AssetURL(asset), nil)
	if err != nil {
		return err
	}
	request.Header.Set("Accept", "application/octet-stream")
	response, err := i.client.Do(request)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("download of %s returned HTTP %d", asset.Name, response.StatusCode)
	}
	file, err := os.OpenFile(target, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	defer file.Close()

	// Read no more than the catalogue says the asset is, so a substituted body
	// cannot write unbounded data before the digest check gets to reject it.
	counter := &progressReader{reader: io.LimitReader(response.Body, asset.Bytes+1), observe: job.observeDownload}
	written, err := io.Copy(file, counter)
	if err != nil {
		return err
	}
	if written != asset.Bytes {
		return fmt.Errorf("download of %s returned %d bytes, expected %d", asset.Name, written, asset.Bytes)
	}
	return file.Close()
}

type progressReader struct {
	reader  io.Reader
	observe func(int64)
}

func (r *progressReader) Read(p []byte) (int, error) {
	n, err := r.reader.Read(p)
	if n > 0 && r.observe != nil {
		r.observe(int64(n))
	}
	return n, err
}

func verifyDigest(path, expected string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()
	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return err
	}
	actual := hex.EncodeToString(hash.Sum(nil))
	if actual != expected {
		return fmt.Errorf("checksum mismatch for %s: got %s, expected %s", filepath.Base(path), actual, expected)
	}
	return nil
}

// probe runs the freshly unpacked binary once. It proves the archive matched
// the platform and that the shared libraries beside it resolve, which is the
// failure a bad variant choice produces.
func (i *Installer) probe(ctx context.Context, job *InstallJob, serverPath string) (string, error) {
	if err := os.Chmod(serverPath, 0o755); err != nil {
		return "", err
	}
	output := NewRingBuffer(8 * 1024)
	_, _ = fmt.Fprintf(job.log, "$ %s --version\n", filepath.Base(serverPath))
	probeCtx, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()
	if err := i.runner.Run(probeCtx, []string{serverPath, "--version"}, sanitizedInstallerEnvironment(), io.MultiWriter(job.log, output)); err != nil {
		return "", err
	}
	return firstVersionLine(output.String()), nil
}

// probeHelp reads the build's own --help once and takes from it both the KV
// cache types it implements and the full list of flags it accepts. A failure
// here is not fatal: without cache types the caller falls back to the upstream
// set, and without flags an extra-args passthrough simply refuses to validate.
func (i *Installer) probeHelp(ctx context.Context, job *InstallJob, serverPath string) (cacheTypes, flags []string) {
	output := NewRingBuffer(512 * 1024)
	probeCtx, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()
	if err := i.runner.Run(probeCtx, []string{serverPath, "--help"}, sanitizedInstallerEnvironment(), output); err != nil {
		_, _ = fmt.Fprintf(job.log, "could not read the build's own option list: %v\n", err)
		return nil, nil
	}
	help := output.String()
	cacheTypes = ParseSupportedCacheTypes(help)
	if len(cacheTypes) == 0 {
		_, _ = io.WriteString(job.log, "build did not report its cache types; using the upstream set\n")
	} else {
		_, _ = fmt.Fprintf(job.log, "supported KV cache types: %s\n", strings.Join(cacheTypes, ", "))
	}
	flags = ParseSupportedFlags(help)
	if len(flags) == 0 {
		_, _ = io.WriteString(job.log, "build did not report its options; extra start arguments stay unavailable\n")
	} else {
		_, _ = fmt.Fprintf(job.log, "build accepts %d options\n", len(flags))
	}
	return cacheTypes, flags
}

func firstVersionLine(text string) string {
	for _, line := range strings.Split(text, "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(strings.ToLower(line), "version:") {
			return line
		}
	}
	for _, line := range strings.Split(text, "\n") {
		if line = strings.TrimSpace(line); line != "" {
			return line
		}
	}
	return ""
}

func activateRuntimeInstall(staging, target, digest string) error {
	if manifest, ok := readManifest(target); ok && manifest.BuildDigest == digest {
		return nil
	}
	backup := target + ".previous"
	_ = os.RemoveAll(backup)
	hadTarget := false
	if _, err := os.Stat(target); err == nil {
		if err := os.Rename(target, backup); err != nil {
			return fmt.Errorf("quarantine invalid runtime install: %w", err)
		}
		hadTarget = true
	} else if !os.IsNotExist(err) {
		return fmt.Errorf("inspect runtime install: %w", err)
	}
	if err := os.Rename(staging, target); err != nil {
		if hadTarget {
			_ = os.Rename(backup, target)
		}
		return fmt.Errorf("activate runtime install: %w", err)
	}
	_ = os.RemoveAll(backup)
	return nil
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

func (i *Installer) finishError(ctx context.Context, job *InstallJob, phase InstallStatus, err error) {
	if errors.Is(ctx.Err(), context.Canceled) || errors.Is(err, context.Canceled) {
		job.setStatus(InstallCanceled, context.Canceled, true)
		return
	}
	code, summary := summarizeInstallFailure(phase, err, job.Snapshot().Log)
	job.failCommand(phase, code, summary)
}

func installPhaseMessage(phase InstallStatus) string {
	switch phase {
	case InstallQueued:
		return "Wartet auf einen freien Installationsplatz"
	case InstallDownloading:
		return "llama-server wird heruntergeladen"
	case InstallVerifying:
		return "Pruefsumme wird geprueft"
	case InstallExtracting:
		return "Archiv wird entpackt"
	case InstallProbing:
		return "Der Startversuch der Runtime wird geprueft"
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

func installDetailMessage(phase InstallStatus, build Build, downloaded, expected int64) string {
	switch phase {
	case InstallQueued:
		return "Die Vorbereitung wartet auf einen freien Installationsplatz."
	case InstallDownloading:
		if expected > 0 {
			return fmt.Sprintf("Der %s-Build von llama-server %s wird geladen (%s von %s).",
				buildVariantLabel(build.Variant), build.Tag, formatGiB(downloaded), formatGiB(expected))
		}
		return fmt.Sprintf("Der %s-Build von llama-server %s wird geladen.", buildVariantLabel(build.Variant), build.Tag)
	case InstallVerifying:
		return "Die heruntergeladenen Dateien werden gegen ihre hinterlegte SHA-256-Pruefsumme geprueft."
	case InstallExtracting:
		return "Die geprueften Archive werden in ein isoliertes Verzeichnis entpackt."
	case InstallProbing:
		return "llama-server wird einmal gestartet, um Plattform und Bibliotheken zu bestaetigen."
	case InstallReady:
		return "Die Runtime wurde geprueft und atomar aktiviert."
	case InstallCanceled:
		return "Die Vorbereitung wurde abgebrochen."
	default:
		return "Die Runtime wird vorbereitet."
	}
}

func buildVariantLabel(variant BuildVariant) string {
	switch variant {
	case BuildCUDA:
		return "CUDA"
	case BuildVulkan:
		return "Vulkan"
	case BuildSYCL:
		return "SYCL"
	case BuildMetal:
		return "Metal"
	case BuildCPU:
		return "CPU"
	default:
		return string(variant)
	}
}

func summarizeInstallFailure(phase InstallStatus, commandErr error, logText string) (string, string) {
	lower := strings.ToLower(logText)
	errorText := ""
	if commandErr != nil {
		errorText = strings.ToLower(commandErr.Error())
	}
	code := "runtime_install_failed"
	reason := "Die Runtime konnte nicht automatisch vorbereitet werden."
	switch {
	case strings.Contains(errorText, "checksum mismatch"):
		code = "checksum_mismatch"
		reason = "Die heruntergeladene Datei entspricht nicht der hinterlegten Pruefsumme und wurde verworfen."
	case strings.Contains(lower, "no space left on device") || strings.Contains(errorText, "no space left on device"):
		code = "disk_full"
		reason = "Auf dem Datentraeger ist nicht genug freier Speicher vorhanden."
	case strings.Contains(errorText, "http 404"):
		code = "build_unavailable"
		reason = "Der gepinnte llama-server-Build ist unter seiner Release-Adresse nicht mehr verfuegbar."
	case strings.Contains(errorText, "no such host") || strings.Contains(errorText, "temporary failure in name resolution") ||
		strings.Contains(errorText, "connection refused") || strings.Contains(errorText, "connection timed out") ||
		strings.Contains(errorText, "network is unreachable") || strings.Contains(errorText, "tls handshake"):
		code = "network_unavailable"
		reason = "Der llama-server-Build konnte wegen einer Netzwerkstoerung nicht geladen werden."
	case phase == InstallExtracting:
		code = "archive_invalid"
		reason = "Das heruntergeladene Archiv konnte nicht entpackt werden."
	case phase == InstallProbing:
		code = "runtime_probe_failed"
		reason = "llama-server wurde entpackt, liess sich auf diesem System aber nicht starten. Moeglicherweise fehlt der passende Grafiktreiber."
	case phase == InstallDownloading:
		code = "download_failed"
		reason = "Der llama-server-Build konnte nicht vollstaendig geladen werden."
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

const installManifestName = ".culpeostudio-runtime.json"

type installManifest struct {
	BuildDigest string       `json:"build_digest"`
	Runtime     RuntimeKind  `json:"runtime"`
	Variant     BuildVariant `json:"variant"`
	Tag         string       `json:"tag"`
	ServerPath  string       `json:"server_path"`
	Version     string       `json:"version,omitempty"`
	// CacheTypes is what this build reported for --cache-type-k. Empty means it
	// did not say, and the upstream set applies.
	CacheTypes []string `json:"cache_types,omitempty"`
	// Flags is every long option this build's --help listed. Empty means it did
	// not parse, and extra start arguments cannot be checked against it.
	Flags       []string  `json:"flags,omitempty"`
	InstalledAt time.Time `json:"installed_at"`
}

func readManifest(installPath string) (installManifest, bool) {
	raw, err := os.ReadFile(filepath.Join(installPath, installManifestName))
	if err != nil {
		return installManifest{}, false
	}
	var manifest installManifest
	if json.Unmarshal(raw, &manifest) != nil {
		return installManifest{}, false
	}
	if manifest.ServerPath == "" {
		return installManifest{}, false
	}
	// A manifest is only trustworthy while the binary it names is still there.
	if info, err := os.Stat(filepath.Join(installPath, manifest.ServerPath)); err != nil || !info.Mode().IsRegular() {
		return installManifest{}, false
	}
	return manifest, true
}

// Capability reports whether a build is installed and where its server binary
// is. An install whose binary has gone missing reports as not installed, which
// makes the next start reinstall it rather than fail at spawn time.
func (i *Installer) Capability(build Build, base RuntimeCapability) RuntimeCapability {
	path, err := build.InstallPath(i.root)
	if err != nil {
		base.ProbeError = err.Error()
		return base
	}
	digest, _ := build.Digest()
	base.Kind = RuntimeLlamaCPP
	base.Variant = build.Variant
	base.Version = build.Tag
	base.Environment = path
	manifest, ok := readManifest(path)
	base.Installed = ok && manifest.BuildDigest == digest
	base.Healthy = base.Installed
	if base.Installed {
		base.ServerPath = filepath.Join(path, manifest.ServerPath)
		if manifest.Version != "" {
			base.BuildVersion = manifest.Version
		}
		// Prefer what the binary said over the compiled-in default.
		if len(manifest.CacheTypes) > 0 {
			base.KVCaches = append([]string(nil), manifest.CacheTypes...)
		}
		base.Flags = append([]string(nil), manifest.Flags...)
	}
	return base
}

// ServerPath is the absolute path to an installed build's llama-server.
func (i *Installer) ServerPath(build Build) (string, error) {
	path, err := build.InstallPath(i.root)
	if err != nil {
		return "", err
	}
	digest, _ := build.Digest()
	manifest, ok := readManifest(path)
	if !ok || manifest.BuildDigest != digest {
		return "", fmt.Errorf("llama-server build %s is not installed", build.Variant)
	}
	return filepath.Join(path, manifest.ServerPath), nil
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

// mergeEnvironment overlays a map of variables onto an environ slice and
// returns a deterministically ordered result.
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

func cloneStringMap(in map[string]string) map[string]string {
	if in == nil {
		return nil
	}
	out := make(map[string]string, len(in))
	for key, value := range in {
		out[key] = value
	}
	return out
}
