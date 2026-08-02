package engine

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/localinference"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

type runtimePrewarmCandidate struct {
	recipe  engineruntime.Recipe
	purpose string
}

type queuedRuntimePrewarm struct {
	candidate runtimePrewarmCandidate
	reason    string
}

type activeRuntimePrewarm struct {
	digest      string
	queued      queuedRuntimePrewarm
	operationID string
	job         *engineruntime.InstallJob
	retry       bool
	done        chan struct{}
}

func (m *EngineModule) startRuntimeInstall(ctx context.Context, recipe engineruntime.Recipe) (*engineruntime.InstallJob, error) {
	for {
		m.spawnGateMu.Lock()
		m.runtimeInstallMu.Lock()
		m.mu.RLock()
		guard := m.guardState
		shuttingDown := m.shuttingDown
		m.mu.RUnlock()
		if err := ctx.Err(); err != nil {
			m.runtimeInstallMu.Unlock()
			m.spawnGateMu.Unlock()
			return nil, err
		}
		if shuttingDown {
			m.runtimeInstallMu.Unlock()
			m.spawnGateMu.Unlock()
			return nil, errors.New("Engine wird heruntergefahren")
		}
		if guard != GuardNormal {
			m.runtimeInstallMu.Unlock()
			m.spawnGateMu.Unlock()
			return nil, fmt.Errorf("%w: Runtime-Installation ist bei Guard-Zustand %s pausiert", localinference.ErrGuardRejected, guard)
		}
		job, err := m.installer.Start(recipe)
		if err != nil {
			m.runtimeInstallMu.Unlock()
			m.spawnGateMu.Unlock()
			return nil, err
		}
		jobID := job.Snapshot().ID
		canceling := m.runtimeInstallCanceling[jobID]
		if !canceling {
			m.runtimeInstallWaiters[jobID]++
			m.runtimeInstallMu.Unlock()
			m.spawnGateMu.Unlock()
			return job, nil
		}
		m.runtimeInstallMu.Unlock()
		m.spawnGateMu.Unlock()
		if _, err := job.Wait(ctx); err != nil && ctx.Err() != nil {
			return nil, ctx.Err()
		}
	}
}

func (m *EngineModule) releaseRuntimeInstallLease(job *engineruntime.InstallJob, cancelIfLast bool) (engineruntime.InstallJobSnapshot, error) {
	if job == nil {
		return engineruntime.InstallJobSnapshot{}, nil
	}
	jobID := job.Snapshot().ID
	m.runtimeInstallMu.Lock()
	if m.runtimeInstallWaiters[jobID] > 0 {
		m.runtimeInstallWaiters[jobID]--
	}
	last := m.runtimeInstallWaiters[jobID] == 0
	if last {
		delete(m.runtimeInstallWaiters, jobID)
	}
	shouldCancel := cancelIfLast && last && !terminalInstallStatus(job.Snapshot().Status)
	if shouldCancel {
		m.runtimeInstallCanceling[jobID] = true
	}
	m.runtimeInstallMu.Unlock()
	if !shouldCancel {
		return job.Snapshot(), nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 6*time.Second)
	snapshot, err := m.installer.CancelContext(ctx, jobID)
	cancel()
	m.runtimeInstallMu.Lock()
	delete(m.runtimeInstallCanceling, jobID)
	m.runtimeInstallMu.Unlock()
	return snapshot, err
}

func (m *EngineModule) cancelRuntimeInstallJob(job *engineruntime.InstallJob) error {
	if job == nil {
		return nil
	}
	jobID := job.Snapshot().ID
	m.runtimeInstallMu.Lock()
	m.runtimeInstallCanceling[jobID] = true
	m.runtimeInstallMu.Unlock()
	ctx, cancel := context.WithTimeout(context.Background(), 6*time.Second)
	_, err := m.installer.CancelContext(ctx, jobID)
	cancel()
	m.runtimeInstallMu.Lock()
	delete(m.runtimeInstallCanceling, jobID)
	m.runtimeInstallMu.Unlock()
	return err
}

func (m *EngineModule) cancelAllRuntimeInstallJobs() {
	if m.installer == nil {
		return
	}
	jobs := m.installer.Jobs()
	var wait sync.WaitGroup
	for _, snapshot := range jobs {
		if terminalInstallStatus(snapshot.Status) {
			continue
		}
		jobID := snapshot.ID
		m.runtimeInstallMu.Lock()
		m.runtimeInstallCanceling[jobID] = true
		m.runtimeInstallMu.Unlock()
		wait.Add(1)
		go func() {
			defer wait.Done()
			ctx, cancel := context.WithTimeout(context.Background(), 6*time.Second)
			_, _ = m.installer.CancelContext(ctx, jobID)
			cancel()
			m.runtimeInstallMu.Lock()
			delete(m.runtimeInstallCanceling, jobID)
			m.runtimeInstallMu.Unlock()
		}()
	}
	wait.Wait()
}

func (m *EngineModule) requestCancelAllRuntimeInstallJobs() {
	m.runtimeInstallMu.Lock()
	if m.runtimeInstallGuardCancel {
		m.runtimeInstallMu.Unlock()
		return
	}
	m.runtimeInstallGuardCancel = true
	m.runtimeInstallMu.Unlock()
	go func() {
		m.cancelAllRuntimeInstallJobs()
		m.runtimeInstallMu.Lock()
		m.runtimeInstallGuardCancel = false
		m.runtimeInstallMu.Unlock()
	}()
}

func runtimePrewarmEnabled() bool {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("ENGINE_RUNTIME_PREWARM"))) {
	case "0", "false", "off", "disabled":
		return false
	default:
		return true
	}
}

func (m *EngineModule) scheduleRuntimePrewarm(reason string) {
	if !runtimePrewarmEnabled() || m.installer == nil {
		return
	}
	m.mu.RLock()
	if m.shuttingDown {
		m.mu.RUnlock()
		return
	}
	models := append([]modelcatalog.ModelRecord(nil), m.models...)
	m.mu.RUnlock()

	hasGGUF := false
	hasSafeTensors := false
	for _, model := range models {
		if !model.Startable {
			continue
		}
		switch model.Format {
		case modelcatalog.FormatGGUF:
			hasGGUF = true
		case modelcatalog.FormatSafeTensors:
			hasSafeTensors = true
		}
	}
	if !hasGGUF && !hasSafeTensors {
		return
	}
	snapshot, _ := m.liveHardware(context.Background())
	candidates := m.prewarmCandidates(snapshot, hasGGUF, hasSafeTensors)
	if len(candidates) == 0 {
		return
	}
	go m.runRuntimePrewarm(reason, candidates)
}

func (m *EngineModule) prewarmCandidates(snapshot hardware.Snapshot, hasGGUF, hasSafeTensors bool) []runtimePrewarmCandidate {
	result := []runtimePrewarmCandidate{}
	seen := map[string]bool{}
	add := func(recipe engineruntime.Recipe, purpose string) {
		digest, err := recipe.Digest()
		if err != nil || seen[digest] {
			return
		}
		seen[digest] = true
		result = append(result, runtimePrewarmCandidate{recipe: recipe, purpose: purpose})
	}
	cpuSnapshot := snapshot
	cpuSnapshot.GPUs = nil

	if hasGGUF {
		llamaSnapshot, _ := usableLlamaBuildSnapshot(snapshot)
		if len(llamaSnapshot.GPUs) > 0 {
			if recipe, err := m.runtimeRecipe(engineruntime.RuntimeLlamaCPP, llamaSnapshot); err == nil {
				add(recipe, prewarmPurpose(engineruntime.RuntimeLlamaCPP, llamaSnapshot, false))
			}
		}
		if recipe, err := m.runtimeRecipe(engineruntime.RuntimeLlamaCPP, cpuSnapshot); err == nil {
			add(recipe, "llama.cpp CPU-Fallback wird vorbereitet")
		}
	}
	if hasSafeTensors {

		if vllmCompatible(snapshot) {
			if recipe, err := m.runtimeRecipe(engineruntime.RuntimeVLLM, snapshot); err == nil {
				add(recipe, "vLLM GPU-Runtime wird vorbereitet")
			}
		}
		transformersSnapshot := snapshot
		if !hasConfirmedTorchAccelerator(snapshot) {
			transformersSnapshot.GPUs = nil
		}
		if recipe, err := m.runtimeRecipe(engineruntime.RuntimeTransformers, transformersSnapshot); err == nil {
			add(recipe, prewarmPurpose(engineruntime.RuntimeTransformers, transformersSnapshot, len(transformersSnapshot.GPUs) == 0))
		}
		if recipe, err := m.runtimeRecipe(engineruntime.RuntimeTransformers, cpuSnapshot); err == nil {
			add(recipe, "Transformers CPU-Fallback wird vorbereitet")
		}
	}
	return result
}

func usableLlamaBuildSnapshot(snapshot hardware.Snapshot) (hardware.Snapshot, []string) {
	filtered := snapshot
	filtered.GPUs = nil
	warnings := []string{}
	for _, gpu := range snapshot.GPUs {
		if strings.EqualFold(gpu.Backend, "vulkan") && !vulkanDevelopmentAvailable() {
			warnings = append(warnings, "Vulkan wurde erkannt, aber Vulkan-/SPIR-V-Header, Shader-Compiler, CMake oder C/C++-Compiler fehlen; der CPU-Fallback wird vorbereitet")
			continue
		}
		filtered.GPUs = append(filtered.GPUs, gpu)
	}
	return filtered, uniqueStrings(warnings)
}

func vulkanDevelopmentAvailable() bool {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("ENGINE_LLAMA_VULKAN_BUILD"))) {
	case "1", "true", "on":
		return true
	case "0", "false", "off", "disabled":
		return false
	}
	developmentFilesAvailable := false
	if pkgConfig, err := exec.LookPath("pkg-config"); err == nil {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		err = exec.CommandContext(ctx, pkgConfig, "--exists", "vulkan").Run()
		cancel()
		if err == nil {
			developmentFilesAvailable = true
		}
	}
	headers := []string{
		"/usr/include/vulkan/vulkan.h",
		"/usr/local/include/vulkan/vulkan.h",
	}
	if sdk := strings.TrimSpace(os.Getenv("VULKAN_SDK")); sdk != "" {
		headers = append(headers, filepath.Join(sdk, "include", "vulkan", "vulkan.h"))
	}
	for _, header := range headers {
		if info, err := os.Stat(header); err == nil && info.Mode().IsRegular() {
			developmentFilesAvailable = true
			break
		}
	}
	if !developmentFilesAvailable {
		return false
	}
	shaderCompilerAvailable := false
	if _, err := exec.LookPath("glslc"); err == nil {
		shaderCompilerAvailable = true
	}
	if sdk := strings.TrimSpace(os.Getenv("VULKAN_SDK")); sdk != "" {
		compiler := filepath.Join(sdk, "bin", "glslc")
		if info, err := os.Stat(compiler); err == nil && info.Mode().IsRegular() && info.Mode().Perm()&0o111 != 0 {
			shaderCompilerAvailable = true
		}
	}
	if !shaderCompilerAvailable {
		return false
	}
	spirvConfigs := []string{
		"/usr/share/cmake/SPIRV-Headers/SPIRV-HeadersConfig.cmake",
		"/usr/local/share/cmake/SPIRV-Headers/SPIRV-HeadersConfig.cmake",
	}
	if sdk := strings.TrimSpace(os.Getenv("VULKAN_SDK")); sdk != "" {
		spirvConfigs = append(spirvConfigs,
			filepath.Join(sdk, "share", "cmake", "SPIRV-Headers", "SPIRV-HeadersConfig.cmake"),
			filepath.Join(sdk, "lib", "cmake", "SPIRV-Headers", "SPIRV-HeadersConfig.cmake"),
		)
	}
	spirvHeadersAvailable := false
	for _, config := range spirvConfigs {
		if info, err := os.Stat(config); err == nil && info.Mode().IsRegular() {
			spirvHeadersAvailable = true
			break
		}
	}
	if !spirvHeadersAvailable {
		return false
	}
	if _, err := exec.LookPath("cmake"); err != nil {
		return false
	}
	cCompilerAvailable := false
	for _, compiler := range []string{"cc", "gcc", "clang", "cl"} {
		if _, err := exec.LookPath(compiler); err == nil {
			cCompilerAvailable = true
			break
		}
	}
	if !cCompilerAvailable {
		return false
	}
	for _, compiler := range []string{"c++", "g++", "clang++", "cl"} {
		if _, err := exec.LookPath(compiler); err == nil {
			return true
		}
	}
	return false
}

func hasConfirmedTorchAccelerator(snapshot hardware.Snapshot) bool {
	for _, gpu := range snapshot.GPUs {
		if gpu.SharedMemory {
			continue
		}
		if strings.EqualFold(gpu.Backend, "cuda") || strings.EqualFold(gpu.Backend, "rocm") {
			return true
		}
	}
	return false
}

func prewarmPurpose(kind engineruntime.RuntimeKind, snapshot hardware.Snapshot, cpu bool) string {
	if cpu || len(snapshot.GPUs) == 0 {
		return fmt.Sprintf("%s CPU-Runtime wird vorbereitet", kind)
	}
	for _, gpu := range snapshot.GPUs {
		if runtimeSupportsBackend(kind, gpu.Backend) {
			return fmt.Sprintf("%s %s-Unterstuetzung wird vorbereitet", kind, strings.ToUpper(gpu.Backend))
		}
	}
	return fmt.Sprintf("%s Runtime wird vorbereitet", kind)
}

func (m *EngineModule) runRuntimePrewarm(reason string, candidates []runtimePrewarmCandidate) {
	if len(candidates) == 0 || m.installer == nil {
		return
	}
	m.prewarmMu.Lock()
	if m.prewarmPending == nil {
		m.prewarmPending = map[string]queuedRuntimePrewarm{}
	}
	m.mu.RLock()
	shuttingDown := m.shuttingDown
	m.mu.RUnlock()
	if shuttingDown {
		m.prewarmMu.Unlock()
		return
	}
	for _, candidate := range candidates {
		digest, err := candidate.recipe.Digest()
		if err != nil {
			continue
		}
		m.mu.RLock()
		completed := m.prewarmRecipes[digest]
		m.mu.RUnlock()
		_, pending := m.prewarmPending[digest]
		if completed || pending || (m.prewarmActive != nil && m.prewarmActive.digest == digest) {
			continue
		}
		m.prewarmPending[digest] = queuedRuntimePrewarm{candidate: candidate, reason: reason}
	}
	if m.prewarmWorker {
		m.prewarmMu.Unlock()
		m.signalRuntimePrewarm()
		return
	}
	m.prewarmWorker = true
	m.prewarmMu.Unlock()
	m.runtimePrewarmLoop()
}

func (m *EngineModule) runtimePrewarmLoop() {
	defer func() {
		m.prewarmMu.Lock()
		m.prewarmWorker = false
		stopped := false
		select {
		case <-m.maintenanceStop:
			stopped = true
		default:
		}
		m.mu.RLock()
		shuttingDown := m.shuttingDown
		m.mu.RUnlock()
		restart := len(m.prewarmPending) > 0 && !stopped && !shuttingDown
		if restart {
			m.prewarmWorker = true
		}
		m.prewarmMu.Unlock()
		if restart {
			go m.runtimePrewarmLoop()
		}
	}()
	for {
		m.prewarmMu.Lock()
		if len(m.prewarmPending) == 0 {
			m.prewarmMu.Unlock()
			return
		}
		blockedByForeground := m.prewarmForeground > 0
		m.mu.RLock()
		guard := m.guardState
		shuttingDown := m.shuttingDown
		m.mu.RUnlock()
		m.prewarmMu.Unlock()
		if shuttingDown {
			return
		}
		if blockedByForeground || guard != GuardNormal {
			if !m.waitForRuntimePrewarmWake(2 * time.Second) {
				return
			}
			continue
		}

		hardwareSnapshot := m.runtimePrewarmHardware(context.Background())
		if err := m.validateRuntimePrewarmResources(hardwareSnapshot); err != nil {
			if detected := guardStateForSnapshot(hardwareSnapshot); detected != GuardNormal {
				m.setGuardState(detected)
			}
			if !m.waitForRuntimePrewarmWake(2 * time.Second) {
				return
			}
			continue
		}

		m.prewarmMu.Lock()
		m.mu.RLock()
		guard = m.guardState
		shuttingDown = m.shuttingDown
		m.mu.RUnlock()
		if shuttingDown || guard != GuardNormal || m.prewarmForeground > 0 || len(m.prewarmPending) == 0 {
			m.prewarmMu.Unlock()
			continue
		}
		digests := make([]string, 0, len(m.prewarmPending))
		for digest := range m.prewarmPending {
			digests = append(digests, digest)
		}
		sort.Strings(digests)
		digest := digests[0]
		queued := m.prewarmPending[digest]
		delete(m.prewarmPending, digest)

		m.mu.Lock()
		if m.prewarmRecipes[digest] {
			m.mu.Unlock()
			m.prewarmMu.Unlock()
			continue
		}
		operation, operationCtx := m.newOperationLocked("runtime_prewarm", "", queued.candidate.purpose)
		_ = m.persistLocked()
		m.mu.Unlock()
		active := &activeRuntimePrewarm{
			digest: digest, queued: queued, operationID: operation.ID, done: make(chan struct{}),
		}
		m.prewarmActive = active
		job, startErr := m.startRuntimeInstall(context.Background(), queued.candidate.recipe)
		active.job = job
		m.prewarmMu.Unlock()
		m.events.publish("operation", cloneOperation(operation))
		if startErr != nil {
			m.setOperation(operation.ID, "failed", 1, queued.candidate.purpose+" – Start fehlgeschlagen", startErr)
			m.finishRuntimePrewarm(active, false)
			continue
		}

		prefix := queued.candidate.purpose
		if queued.reason != "" {
			prefix += " (" + queued.reason + ")"
		}
		snapshot, waitErr := m.waitRuntimeInstall(operationCtx, operation.ID, "", job, prefix)
		ready := snapshot.Status == engineruntime.InstallReady && waitErr == nil
		if ready {
			m.setOperation(operation.ID, "completed", 1, queued.candidate.purpose+" – bereit", nil)
		} else if operationCtx.Err() == nil {
			message := queued.candidate.purpose + " – " + snapshot.Message
			m.setOperation(operation.ID, "failed", 1, message, waitErr)
		}
		m.finishRuntimePrewarm(active, ready)
	}
}

func terminalInstallStatus(status engineruntime.InstallStatus) bool {
	return status == engineruntime.InstallReady || status == engineruntime.InstallFailed || status == engineruntime.InstallCanceled
}

func (m *EngineModule) finishRuntimePrewarm(active *activeRuntimePrewarm, ready bool) {
	m.prewarmMu.Lock()
	if m.prewarmActive == active {
		m.prewarmActive = nil
	}
	if ready {
		delete(m.prewarmPending, active.digest)
		m.mu.Lock()
		m.prewarmRecipes[active.digest] = true
		m.mu.Unlock()
	} else if active.retry {
		m.prewarmPending[active.digest] = active.queued
	}
	close(active.done)
	m.prewarmMu.Unlock()
	m.signalRuntimePrewarm()
}

func (m *EngineModule) runtimePrewarmHardware(ctx context.Context) hardware.Snapshot {
	if m.prewarmHardware != nil {
		return m.prewarmHardware(ctx)
	}
	snapshot, _ := m.liveHardware(ctx)
	return snapshot
}

func (m *EngineModule) validateRuntimePrewarmResources(snapshot hardware.Snapshot) error {
	if snapshot.RAMTotalBytes <= 0 || snapshot.RAMAvailableBytes <= 0 {
		return errors.New("RAM-Budget fuer Runtime-Prewarm ist nicht messbar")
	}
	if state := guardStateForSnapshot(snapshot); state != GuardNormal {
		return fmt.Errorf("Runtime-Prewarm ist bei Guard-Zustand %s pausiert", state)
	}
	reserve := emergencyFloor(snapshot.RAMTotalBytes, guardRAMFloor)
	if m.settings != nil {
		configured := m.settings.Get().EngineRAMReserveBytes
		reserve = maxInt64(reserve, effectiveReserveBytes(configured, snapshot.RAMTotalBytes, 15, 4<<30))
	}
	const buildHeadroom = int64(1 << 30)
	if snapshot.RAMAvailableBytes <= reserve+buildHeadroom {
		return fmt.Errorf("Runtime-Prewarm benoetigt neben der RAM-Reserve mindestens %d Byte freien Build-Spielraum", buildHeadroom)
	}
	return nil
}

func (m *EngineModule) waitForRuntimePrewarmWake(maxWait time.Duration) bool {
	if maxWait <= 0 {
		maxWait = 2 * time.Second
	}
	timer := time.NewTimer(maxWait)
	defer timer.Stop()
	select {
	case <-m.maintenanceStop:
		return false
	case <-m.prewarmWake:
		return true
	case <-timer.C:
		return true
	}
}

func (m *EngineModule) signalRuntimePrewarm() {
	select {
	case m.prewarmWake <- struct{}{}:
	default:
	}
}

func (m *EngineModule) pauseRuntimePrewarm() {
	m.prewarmMu.Lock()
	active := m.prewarmActive
	if active != nil {
		active.retry = true
		m.prewarmPending[active.digest] = active.queued
	}
	m.prewarmMu.Unlock()
	if active == nil {
		m.signalRuntimePrewarm()
		return
	}
	_, _ = m.cancelOperation(active.operationID)
	_ = m.cancelRuntimeInstallJob(active.job)
	select {
	case <-active.done:
	case <-time.After(6 * time.Second):

	}
	m.signalRuntimePrewarm()
}

func (m *EngineModule) requestRuntimePrewarmPause() {
	m.prewarmMu.Lock()
	if m.prewarmPauseRunning {
		m.prewarmMu.Unlock()
		return
	}
	m.prewarmPauseRunning = true
	m.prewarmMu.Unlock()
	go func() {
		m.pauseRuntimePrewarm()
		m.prewarmMu.Lock()
		m.prewarmPauseRunning = false
		m.prewarmMu.Unlock()
	}()
}

func (m *EngineModule) beginForegroundRuntime(ctx context.Context) (func(), error) {
	m.prewarmMu.Lock()
	m.prewarmForeground++
	active := m.prewarmActive
	if active != nil {
		active.retry = true
		m.prewarmPending[active.digest] = active.queued
	}
	m.prewarmMu.Unlock()
	release := sync.OnceFunc(func() {
		m.prewarmMu.Lock()
		if m.prewarmForeground > 0 {
			m.prewarmForeground--
		}
		m.prewarmMu.Unlock()
		m.signalRuntimePrewarm()
	})
	if active == nil {
		return release, nil
	}
	_, _ = m.cancelOperation(active.operationID)
	_ = m.cancelRuntimeInstallJob(active.job)
	select {
	case <-active.done:
		return release, nil
	case <-ctx.Done():
		release()
		return nil, ctx.Err()
	case <-time.After(6 * time.Second):
		release()
		return nil, errors.New("niedrig priorisierter Runtime-Prewarm konnte nicht sicher unterbrochen werden")
	}
}

func (m *EngineModule) waitRuntimeInstall(ctx context.Context, operationID, instanceID string, job *engineruntime.InstallJob, prefix string) (engineruntime.InstallJobSnapshot, error) {
	ticker := time.NewTicker(250 * time.Millisecond)
	defer ticker.Stop()
	released := false
	release := func(cancelIfLast bool) (engineruntime.InstallJobSnapshot, error) {
		if released {
			return job.Snapshot(), nil
		}
		released = true
		return m.releaseRuntimeInstallLease(job, cancelIfLast)
	}
	defer func() {
		if !released {
			_, _ = release(false)
		}
	}()
	lastStatus := engineruntime.InstallStatus("")
	lastMessage := ""
	lastDetail := ""
	lastProgress := -1.0
	update := func(snapshot engineruntime.InstallJobSnapshot) {
		if snapshot.Status == lastStatus && snapshot.Message == lastMessage && snapshot.DetailMessage == lastDetail && snapshot.Progress == lastProgress {
			return
		}
		lastStatus = snapshot.Status
		lastMessage = snapshot.Message
		lastDetail = snapshot.DetailMessage
		lastProgress = snapshot.Progress
		progress := runtimeInstallProgress(snapshot.Status)
		if snapshot.Progress > 0 {

			progress = snapshot.Progress
		}
		message := prefix + " – " + snapshot.Message
		detail := snapshot.DetailMessage
		if detail == "" {
			detail = snapshot.Message
		}
		m.setOperationDetail(operationID, "running", progress, string(snapshot.Phase), message, detail, nil)
		if instanceID != "" {
			m.setInstanceStateDetail(instanceID, engineruntime.StateInstalling, progress, string(snapshot.Phase), detail, "")
		}
	}
	update(job.Snapshot())
	for {
		select {
		case <-ctx.Done():
			snapshot, cancelErr := release(true)
			if cancelErr != nil {
				return snapshot, fmt.Errorf("Runtime-Installation konnte nach Abbruch nicht bestaetigt gestoppt werden: %w", cancelErr)
			}
			return snapshot, ctx.Err()
		case <-ticker.C:
			update(job.Snapshot())
		case <-job.Done():
			snapshot, err := job.Wait(context.Background())
			_, _ = release(false)
			update(snapshot)
			return snapshot, err
		}
	}
}

func runtimeInstallProgress(status engineruntime.InstallStatus) float64 {
	switch status {
	case engineruntime.InstallQueued:
		return 0.05
	case engineruntime.InstallCreating:
		return 0.15
	case engineruntime.InstallPackages:
		return 0.55
	case engineruntime.InstallProbing:
		return 0.9
	default:
		return 1
	}
}
