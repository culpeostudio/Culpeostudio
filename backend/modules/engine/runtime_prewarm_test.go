package engine

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

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

type successfulPrewarmRunner struct{}

func (successfulPrewarmRunner) Run(context.Context, []string, []string, io.Writer) error { return nil }

type failingGPUProbeRunner struct{}

func (failingGPUProbeRunner) Run(_ context.Context, argv, _ []string, _ io.Writer) error {
	if strings.Contains(strings.Join(argv, " "), "llama_supports_gpu_offload") {
		return errors.New("GPU offload smoke test failed")
	}
	return nil
}

type cancelFirstPrewarmRunner struct {
	mu            sync.Mutex
	calls         int
	firstStarted  chan struct{}
	firstCanceled chan struct{}
	startOnce     sync.Once
	cancelOnce    sync.Once
}

type stubbornPrewarmRunner struct {
	started chan struct{}
	release chan struct{}
	once    sync.Once
}

func (r *stubbornPrewarmRunner) Run(context.Context, []string, []string, io.Writer) error {
	r.once.Do(func() { close(r.started) })
	<-r.release
	return context.Canceled
}

func (r *cancelFirstPrewarmRunner) Run(ctx context.Context, _ []string, _ []string, _ io.Writer) error {
	r.mu.Lock()
	r.calls++
	call := r.calls
	r.mu.Unlock()
	if call != 1 {
		return nil
	}
	r.startOnce.Do(func() { close(r.firstStarted) })
	<-ctx.Done()
	r.cancelOnce.Do(func() { close(r.firstCanceled) })
	return ctx.Err()
}

func prewarmTestHardware() hardware.Snapshot {
	return hardware.Snapshot{RAMTotalBytes: 32 << 30, RAMAvailableBytes: 24 << 30}
}

func waitForPrewarmCondition(t *testing.T, condition func() bool) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if condition() {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("prewarm condition was not reached")
}

func TestPrewarmCandidatesPrepareVulkanLlamaAndCPUFallbackWithoutVLLM(t *testing.T) {
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "true")
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	snapshot := hardware.Snapshot{
		OS:   "linux",
		GPUs: []hardware.GPU{{ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30}},
	}
	candidates := module.prewarmCandidates(snapshot, true, true)
	var llamaGPU, llamaCPU, transformers, vllm int
	for _, candidate := range candidates {
		switch candidate.recipe.Runtime {
		case engineruntime.RuntimeLlamaCPP:
			if candidate.recipe.Environment["CMAKE_ARGS"] == "-DGGML_VULKAN=on" {
				llamaGPU++
			} else if candidate.recipe.Environment["CMAKE_ARGS"] == "" {
				llamaCPU++
			}
		case engineruntime.RuntimeTransformers:
			transformers++
		case engineruntime.RuntimeVLLM:
			vllm++
		}
	}
	if llamaGPU != 1 || llamaCPU != 1 || transformers != 1 || vllm != 0 {
		t.Fatalf("unexpected candidates: llamaGPU=%d llamaCPU=%d transformers=%d vllm=%d (%#v)", llamaGPU, llamaCPU, transformers, vllm, candidates)
	}
}

func TestVulkanLlamaRecipeForcesFreshNativeBuild(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	recipe, err := module.runtimeRecipe(engineruntime.RuntimeLlamaCPP, hardware.Snapshot{
		OS:   "linux",
		GPUs: []hardware.GPU{{ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30}},
	})
	if err != nil {
		t.Fatal(err)
	}
	if recipe.Environment["CMAKE_ARGS"] != "-DGGML_VULKAN=on" || recipe.Environment["FORCE_CMAKE"] != "1" {
		t.Fatalf("Vulkan build environment = %#v", recipe.Environment)
	}
	joined := strings.Join(recipe.PipArgs, " ")
	if !strings.Contains(joined, "--no-cache-dir") || !strings.Contains(joined, "--no-binary=llama-cpp-python") {
		t.Fatalf("Vulkan recipe may reuse a CPU wheel: %#v", recipe.PipArgs)
	}
	if !strings.Contains(strings.Join(recipe.SmokeTestArgs, " "), "llama_supports_gpu_offload") {
		t.Fatalf("Vulkan recipe has no GPU-offload smoke test: %#v", recipe.SmokeTestArgs)
	}
}

func TestRecommendationRecognizesFailedVulkanRuntimeProbe(t *testing.T) {
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "true")
	root := t.TempDir()
	module := New(filepath.Join(root, "settings.json"))
	installer, err := engineruntime.NewInstaller(
		filepath.Join(root, "runtimes"),
		"/usr/bin/python3",
		failingGPUProbeRunner{},
	)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module.installer = installer
	snapshot := hardware.Snapshot{
		OS:   "linux",
		GPUs: []hardware.GPU{{ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30}},
	}
	recipe, err := module.runtimeRecipe(engineruntime.RuntimeLlamaCPP, snapshot)
	if err != nil {
		t.Fatal(err)
	}
	job, err := installer.Start(recipe)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := job.Wait(context.Background()); err == nil {
		t.Fatal("test GPU probe unexpectedly succeeded")
	}
	config := defaultEngineConfig()
	config.RuntimeOptions["allow_ram_offload"] = false
	runtimeErr := module.gpuRuntimePlanningError(
		modelcatalog.ModelRecord{Format: modelcatalog.FormatGGUF},
		config,
		snapshot,
	)
	if runtimeErr == nil || runtimeErr.Remediation != "rebuild_gpu_runtime" {
		t.Fatalf("failed GPU probe was not surfaced for planning: %#v", runtimeErr)
	}
}

func TestHealthyVulkanRuntimeRemainsUsableWithoutBuildTools(t *testing.T) {
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "true")
	root := t.TempDir()
	module := New(filepath.Join(root, "settings.json"))
	installer, err := engineruntime.NewInstaller(
		filepath.Join(root, "runtimes"),
		"/usr/bin/python3",
		successfulPrewarmRunner{},
	)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module.installer = installer
	snapshot := hardware.Snapshot{
		OS:   "linux",
		GPUs: []hardware.GPU{{ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30}},
	}
	recipe, err := module.runtimeRecipe(engineruntime.RuntimeLlamaCPP, snapshot)
	if err != nil {
		t.Fatal(err)
	}
	job, err := installer.Start(recipe)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := job.Wait(context.Background()); err != nil {
		t.Fatal(err)
	}

	// The exact GPU environment is now verified. Removing the build-tool
	// override must not make runtime planning reject that installed artifact.
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "disabled")
	config := defaultEngineConfig()
	config.RuntimeOptions["allow_ram_offload"] = false
	if runtimeErr := module.gpuRuntimePlanningError(
		modelcatalog.ModelRecord{Format: modelcatalog.FormatGGUF},
		config,
		snapshot,
	); runtimeErr != nil {
		t.Fatalf("healthy installed GPU runtime was rejected: %v", runtimeErr)
	}
}

func TestPrewarmSkipsKnownImpossibleVulkanBuild(t *testing.T) {
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "disabled")
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	snapshot := hardware.Snapshot{OS: "linux", GPUs: []hardware.GPU{{ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30}}}
	candidates := module.prewarmCandidates(snapshot, true, false)
	if len(candidates) != 1 || candidates[0].recipe.Environment["CMAKE_ARGS"] != "" {
		t.Fatalf("known-impossible Vulkan build should prepare CPU only: %#v", candidates)
	}
	filtered, warnings := usableLlamaBuildSnapshot(snapshot)
	if len(filtered.GPUs) != 0 || len(warnings) != 1 || !strings.Contains(warnings[0], "Shader-Compiler") {
		t.Fatalf("filtered=%#v warnings=%#v", filtered.GPUs, warnings)
	}
}

func TestVulkanBuildProbeRequiresCompilerAndSPIRVHeaders(t *testing.T) {
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "")
	t.Setenv("PATH", t.TempDir())
	sdk := t.TempDir()
	header := filepath.Join(sdk, "include", "vulkan", "vulkan.h")
	if err := os.MkdirAll(filepath.Dir(header), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(header, []byte("// test Vulkan header"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Setenv("VULKAN_SDK", sdk)
	if vulkanDevelopmentAvailable() {
		t.Fatal("Vulkan build was accepted without glslc")
	}
	compiler := filepath.Join(sdk, "bin", "glslc")
	if err := os.MkdirAll(filepath.Dir(compiler), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(compiler, []byte("#!/bin/sh\nexit 0\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	if vulkanDevelopmentAvailable() {
		t.Fatal("Vulkan build was accepted without SPIR-V CMake headers")
	}
	spirvConfig := filepath.Join(
		sdk,
		"share",
		"cmake",
		"SPIRV-Headers",
		"SPIRV-HeadersConfig.cmake",
	)
	if err := os.MkdirAll(filepath.Dir(spirvConfig), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(spirvConfig, []byte("# test SPIR-V package"), 0o644); err != nil {
		t.Fatal(err)
	}
	if vulkanDevelopmentAvailable() {
		t.Fatal("Vulkan build was accepted without CMake and a C/C++ compiler")
	}
	for _, tool := range []string{"cmake", "cc", "c++"} {
		path := filepath.Join(filepath.Dir(compiler), tool)
		if err := os.WriteFile(path, []byte("#!/bin/sh\nexit 0\n"), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	t.Setenv("PATH", filepath.Dir(compiler))
	if !vulkanDevelopmentAvailable() {
		t.Fatal("Vulkan build was rejected with headers, glslc, CMake and a C/C++ compiler")
	}
}

func TestRecommendationPlansCPUWhenLlamaGPUBuildIsKnownImpossible(t *testing.T) {
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "disabled")
	record := modelcatalog.ModelRecord{Format: modelcatalog.FormatGGUF}
	snapshot := hardware.Snapshot{OS: "linux", GPUs: []hardware.GPU{{ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30}}}
	if !forceCPUForConfig(record, defaultEngineConfig(), snapshot) {
		t.Fatal("recommendation should match the known CPU runtime fallback")
	}
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "true")
	if forceCPUForConfig(record, defaultEngineConfig(), snapshot) {
		t.Fatal("confirmed Vulkan build support should remain GPU-plannable")
	}
}

func TestUnavailableVulkanRuntimeIsNotReportedAsVRAMConflict(t *testing.T) {
	t.Setenv("ENGINE_LLAMA_VULKAN_BUILD", "disabled")
	record := modelcatalog.ModelRecord{Format: modelcatalog.FormatGGUF}
	snapshot := hardware.Snapshot{
		OS: "linux",
		GPUs: []hardware.GPU{{
			ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30,
		}},
	}
	config := defaultEngineConfig()
	config.RuntimeOptions["allow_ram_offload"] = false
	reason := unavailableGPURuntimeReason(record, config, snapshot)
	if !strings.Contains(reason, "Shader-Compiler") {
		t.Fatalf("runtime reason = %q", reason)
	}
	if ramOffloadAllowed(config) {
		t.Fatal("explicit GPU-only calculation unexpectedly allowed RAM")
	}
}

func TestPrewarmNeverQueuesVLLMOnUnsupportedPlatform(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	snapshot := hardware.Snapshot{OS: "windows", GPUs: []hardware.GPU{{ID: "cuda-0", Backend: "cuda", VRAMTotalBytes: 16 << 30}}}
	for _, candidate := range module.prewarmCandidates(snapshot, false, true) {
		if candidate.recipe.Runtime == engineruntime.RuntimeVLLM {
			t.Fatalf("vLLM was queued on unsupported platform: %#v", candidate)
		}
	}
}

func TestBackgroundPrewarmIsContentDeduplicated(t *testing.T) {
	root := t.TempDir()
	module := New(filepath.Join(root, "settings.json"))
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), "/usr/bin/python3", successfulPrewarmRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	recipe := engineruntime.DefaultLlamaCPPRecipe(nil)
	candidates := []runtimePrewarmCandidate{{recipe: recipe, purpose: "llama.cpp CPU-Fallback wird vorbereitet"}}

	module.runRuntimePrewarm("Test", candidates)
	module.runRuntimePrewarm("Test", candidates)

	jobs := installer.Jobs()
	if len(jobs) != 1 || jobs[0].Status != engineruntime.InstallReady {
		t.Fatalf("jobs = %#v", jobs)
	}
	module.mu.RLock()
	operationCount := len(module.operations)
	module.mu.RUnlock()
	if operationCount != 1 {
		t.Fatalf("prewarm operations = %d, want 1", operationCount)
	}
}

func TestRunningPrewarmPausesOnWarningAndResumesExactlyOnce(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	candidate := runtimePrewarmCandidate{recipe: engineruntime.DefaultLlamaCPPRecipe(nil), purpose: "niedrig priorisierte Runtime"}

	go module.runRuntimePrewarm("Test", []runtimePrewarmCandidate{candidate})
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("prewarm process did not start")
	}
	module.setGuardState(GuardWarning)
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("warning did not cancel the running prewarm process")
	}
	var jobs []engineruntime.InstallJobSnapshot
	waitForPrewarmCondition(t, func() bool {
		jobs = installer.Jobs()
		return len(jobs) == 1 && jobs[0].Status == engineruntime.InstallCanceled
	})
	if len(jobs) != 1 || jobs[0].Status != engineruntime.InstallCanceled {
		t.Fatalf("paused jobs = %#v", jobs)
	}
	time.Sleep(100 * time.Millisecond)
	if len(installer.Jobs()) != 1 {
		t.Fatal("prewarm restarted while guard was non-normal")
	}

	module.setGuardState(GuardNormal)
	waitForPrewarmCondition(t, func() bool {
		jobs = installer.Jobs()
		return len(jobs) == 2 && jobs[1].Status == engineruntime.InstallReady
	})
	module.runRuntimePrewarm("duplicate", []runtimePrewarmCandidate{candidate})
	if jobs = installer.Jobs(); len(jobs) != 2 {
		t.Fatalf("resumed candidate was duplicated: %#v", jobs)
	}
	module.mu.RLock()
	defer module.mu.RUnlock()
	completed, cancelled := 0, 0
	for _, operation := range module.operations {
		if operation.Type != "runtime_prewarm" {
			continue
		}
		switch operation.State {
		case "completed":
			completed++
		case "cancelled":
			cancelled++
		}
	}
	if completed != 1 || cancelled != 1 {
		t.Fatalf("prewarm operation states: completed=%d cancelled=%d", completed, cancelled)
	}
}

func TestForegroundRuntimePreemptsAndHoldsBackgroundPrewarm(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	candidate := runtimePrewarmCandidate{recipe: engineruntime.DefaultLlamaCPPRecipe(nil), purpose: "background"}
	go module.runRuntimePrewarm("Test", []runtimePrewarmCandidate{candidate})
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("prewarm process did not start")
	}
	release, err := module.beginForegroundRuntime(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("foreground work did not preempt prewarm")
	}
	time.Sleep(100 * time.Millisecond)
	if len(installer.Jobs()) != 1 {
		t.Fatal("background prewarm restarted while foreground admission was held")
	}
	release()
	waitForPrewarmCondition(t, func() bool {
		jobs := installer.Jobs()
		return len(jobs) == 2 && jobs[1].Status == engineruntime.InstallReady
	})
}

func TestPrewarmResourceAdmissionFailsClosed(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.validateRuntimePrewarmResources(hardware.Snapshot{}); err == nil {
		t.Fatal("unknown RAM telemetry must reject background prewarm")
	}
	low := hardware.Snapshot{RAMTotalBytes: 32 << 30, RAMAvailableBytes: 5 << 30}
	if err := module.validateRuntimePrewarmResources(low); err == nil {
		t.Fatal("configured reserve plus build headroom was not protected")
	}
	if err := module.validateRuntimePrewarmResources(prewarmTestHardware()); err != nil {
		t.Fatalf("safe prewarm budget rejected: %v", err)
	}
}

func TestGuardTransitionDoesNotBlockOnUncooperativePrewarm(t *testing.T) {
	root := t.TempDir()
	runner := &stubbornPrewarmRunner{started: make(chan struct{}), release: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	module.prewarmHardware = func(context.Context) hardware.Snapshot { return prewarmTestHardware() }
	candidate := runtimePrewarmCandidate{recipe: engineruntime.DefaultLlamaCPPRecipe(nil), purpose: "stubborn"}
	go module.runRuntimePrewarm("Test", []runtimePrewarmCandidate{candidate})
	select {
	case <-runner.started:
	case <-time.After(2 * time.Second):
		t.Fatal("prewarm process did not start")
	}
	started := time.Now()
	module.setGuardState(GuardWarning)
	if elapsed := time.Since(started); elapsed > 100*time.Millisecond {
		t.Fatalf("guard transition blocked for %s", elapsed)
	}
	module.prewarmMu.Lock()
	active := module.prewarmActive != nil
	module.prewarmMu.Unlock()
	if !active {
		t.Fatal("unconfirmed installer termination was incorrectly released")
	}
	close(runner.release)
	waitForPrewarmCondition(t, func() bool {
		module.prewarmMu.Lock()
		defer module.prewarmMu.Unlock()
		return module.prewarmActive == nil
	})
	module.maintenanceStopOnce.Do(func() { close(module.maintenanceStop) })
	installer.Close()
}

func TestSharedRuntimeJobCancelsOnlyAfterLastWaiterLeaves(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	recipe := engineruntime.DefaultLlamaCPPRecipe(nil)
	first, err := module.startRuntimeInstall(context.Background(), recipe)
	if err != nil {
		t.Fatal(err)
	}
	second, err := module.startRuntimeInstall(context.Background(), recipe)
	if err != nil {
		t.Fatal(err)
	}
	if first != second {
		t.Fatal("content-addressed waiters did not share one installer job")
	}
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("shared runtime job did not start")
	}
	firstCtx, cancelFirst := context.WithCancel(context.Background())
	cancelFirst()
	if _, err := module.waitRuntimeInstall(firstCtx, "", "", first, "shared"); err == nil {
		t.Fatal("first canceled waiter unexpectedly succeeded")
	}
	select {
	case <-runner.firstCanceled:
		t.Fatal("shared job was canceled while another waiter still owned it")
	case <-time.After(80 * time.Millisecond):
	}
	secondCtx, cancelSecond := context.WithCancel(context.Background())
	cancelSecond()
	if _, err := module.waitRuntimeInstall(secondCtx, "", "", second, "shared"); err == nil {
		t.Fatal("last canceled waiter unexpectedly succeeded")
	}
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("last waiter cancellation did not stop CommandRunner")
	}
}

func TestActivePrewarmUsesFastPressureSampling(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.prewarmMu.Lock()
	module.prewarmActive = &activeRuntimePrewarm{done: make(chan struct{})}
	module.prewarmMu.Unlock()
	if !module.hasStartingInstance() {
		t.Fatal("active runtime prewarm was omitted from fast pressure sampling")
	}
}

func TestCriticalGuardStopsForegroundRuntimeCommand(t *testing.T) {
	root := t.TempDir()
	runner := &cancelFirstPrewarmRunner{firstStarted: make(chan struct{}), firstCanceled: make(chan struct{})}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), "/usr/bin/python3", runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module := New(filepath.Join(root, "settings.json"))
	module.installer = installer
	job, err := module.startRuntimeInstall(context.Background(), engineruntime.DefaultLlamaCPPRecipe(nil))
	if err != nil {
		t.Fatal(err)
	}
	waitDone := make(chan error, 1)
	go func() {
		_, waitErr := module.waitRuntimeInstall(context.Background(), "", "", job, "foreground")
		waitDone <- waitErr
	}()
	select {
	case <-runner.firstStarted:
	case <-time.After(2 * time.Second):
		t.Fatal("foreground runtime command did not start")
	}
	module.setGuardState(GuardCritical)
	select {
	case <-runner.firstCanceled:
	case <-time.After(2 * time.Second):
		t.Fatal("critical guard did not cancel foreground runtime command")
	}
	select {
	case waitErr := <-waitDone:
		if waitErr == nil {
			t.Fatal("canceled foreground runtime unexpectedly succeeded")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("foreground runtime waiter did not observe terminal cancellation")
	}
}

func TestPreferredRuntimeJobUsesReadyFallbackAfterAcceleratorFailure(t *testing.T) {
	jobs := []engineruntime.InstallJobSnapshot{
		{Runtime: engineruntime.RuntimeLlamaCPP, RecipeDigest: "gpu", Status: engineruntime.InstallFailed},
		{Runtime: engineruntime.RuntimeLlamaCPP, RecipeDigest: "cpu", Status: engineruntime.InstallReady, EnvironmentPath: "/cpu"},
	}
	job, ok := preferredRuntimeJob(jobs, engineruntime.RuntimeLlamaCPP, "gpu")
	if !ok || job.RecipeDigest != "cpu" || job.EnvironmentPath != "/cpu" {
		t.Fatalf("preferred job = %#v, %v", job, ok)
	}
}
