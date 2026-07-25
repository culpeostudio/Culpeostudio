package engine

import (
	"context"
	"io"
	"net/http"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
)

type recordingPrivilegedRunner struct {
	mu       sync.Mutex
	argv     [][]string
	afterRun func()
	err      error
}

func (r *recordingPrivilegedRunner) Run(_ context.Context, argv []string, _ io.Writer) error {
	r.mu.Lock()
	r.argv = append(r.argv, append([]string(nil), argv...))
	afterRun := r.afterRun
	err := r.err
	r.mu.Unlock()
	if afterRun != nil {
		afterRun()
	}
	return err
}

func (r *recordingPrivilegedRunner) calls() [][]string {
	r.mu.Lock()
	defer r.mu.Unlock()
	result := make([][]string, len(r.argv))
	for index := range r.argv {
		result[index] = append([]string(nil), r.argv[index]...)
	}
	return result
}

type recordingDependencyRuntimeRunner struct {
	mu           sync.Mutex
	environments [][]string
}

func (r *recordingDependencyRuntimeRunner) Run(_ context.Context, _ []string, environment []string, _ io.Writer) error {
	r.mu.Lock()
	r.environments = append(r.environments, append([]string(nil), environment...))
	r.mu.Unlock()
	return nil
}

func (r *recordingDependencyRuntimeRunner) sawEnvironment(value string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, environment := range r.environments {
		for _, entry := range environment {
			if entry == value {
				return true
			}
		}
	}
	return false
}

func TestVulkanDependencyConsentIsOneUseAndBuildsVulkanRuntime(t *testing.T) {
	root := t.TempDir()
	module := New(filepath.Join(root, "settings.json"))
	module.dependencyPlatformCheck = func() error { return nil }
	var developmentAvailable atomic.Bool
	module.dependencyVulkanProbe = developmentAvailable.Load
	module.dependencyHardware = func(context.Context) hardware.Snapshot {
		return hardware.Snapshot{OS: "linux", GPUs: []hardware.GPU{{ID: "vulkan-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30}}}
	}
	privilegedRunner := &recordingPrivilegedRunner{afterRun: func() { developmentAvailable.Store(true) }}
	module.dependencyRunner = privilegedRunner
	runtimeRunner := &recordingDependencyRuntimeRunner{}
	installer, err := engineruntime.NewInstaller(filepath.Join(root, "runtimes"), "/usr/bin/python3", runtimeRunner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)
	module.installer = installer

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	consent := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/consent", "{}", http.StatusOK)
	token, _ := consent["consent_token"].(string)
	if token == "" || consent["package"] != vulkanDependencyDisplay || !strings.Contains(consent["warning"].(string), "kein Passwort") {
		t.Fatalf("consent response = %#v", consent)
	}
	if !strings.Contains(consent["command_summary"].(string), vulkanShaderCompilerPackage) {
		t.Fatalf("consent omits shader compiler: %#v", consent)
	}
	if !strings.Contains(consent["command_summary"].(string), "SPIR-V") {
		t.Fatalf("consent omits SPIR-V headers: %#v", consent)
	}
	if !strings.Contains(consent["command_summary"].(string), "CMake") || !strings.Contains(consent["package"].(string), vulkanBuildEssentialPackage) {
		t.Fatalf("consent omits native build tools: %#v", consent)
	}
	body := `{"consent_token":"` + token + `","acknowledgement":"` + vulkanConsentAcknowledgement + `"}`
	started := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/install", body, http.StatusAccepted)
	operationID, _ := started["operation_id"].(string)
	if operationID == "" {
		t.Fatalf("install response = %#v", started)
	}

	// A token is consumed before the asynchronous command and cannot be reused,
	// even while its original operation is still running.
	replayed := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/install", body, http.StatusUnauthorized)
	if code := replayed["error"].(map[string]interface{})["code"]; code != "dependency_consent_invalid_or_consumed" {
		t.Fatalf("replay error = %#v", replayed)
	}

	operation := waitForSystemDependencyOperation(t, module, operationID)
	if operation.State != "completed" || operation.Type != vulkanDependencyOperationType {
		t.Fatalf("operation = %#v", operation)
	}
	calls := privilegedRunner.calls()
	if len(calls) != 1 || strings.Join(calls[0], "\x00") != strings.Join(vulkanDependencyInstallCommand(), "\x00") {
		t.Fatalf("privileged argv = %#v", calls)
	}
	if runtimeRunner.sawEnvironment("CMAKE_ARGS=-DGGML_VULKAN=on") == false {
		t.Fatal("runtime installer did not receive the Vulkan llama.cpp recipe")
	}
}

func TestVulkanDependencyConsentExpiresAndWrongAcknowledgementConsumesIt(t *testing.T) {
	root := t.TempDir()
	module := New(filepath.Join(root, "settings.json"))
	module.dependencyPlatformCheck = func() error { return nil }
	module.dependencyVulkanProbe = func() bool { return false }
	now := time.Date(2026, 7, 16, 18, 0, 0, 0, time.UTC)
	module.dependencyNow = func() time.Time { return now }
	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))

	consent := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/consent", "{}", http.StatusOK)
	token := consent["consent_token"].(string)
	now = now.Add(vulkanConsentLifetime + time.Second)
	body := `{"consent_token":"` + token + `","acknowledgement":"` + vulkanConsentAcknowledgement + `"}`
	expired := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/install", body, http.StatusUnauthorized)
	if code := expired["error"].(map[string]interface{})["code"]; code != "dependency_consent_expired" {
		t.Fatalf("expired error = %#v", expired)
	}
	replayed := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/install", body, http.StatusUnauthorized)
	if code := replayed["error"].(map[string]interface{})["code"]; code != "dependency_consent_invalid_or_consumed" {
		t.Fatalf("expired token replay = %#v", replayed)
	}

	consent = requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/consent", "{}", http.StatusOK)
	token = consent["consent_token"].(string)
	wrongBody := `{"consent_token":"` + token + `","acknowledgement":"not_confirmed"}`
	wrong := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/install", wrongBody, http.StatusBadRequest)
	if code := wrong["error"].(map[string]interface{})["code"]; code != "dependency_consent_acknowledgement_required" {
		t.Fatalf("wrong acknowledgement = %#v", wrong)
	}
	wrongReplay := requestJSON(t, app, http.MethodPost, "/api/engine/system-dependencies/vulkan/install", wrongBody, http.StatusUnauthorized)
	if code := wrongReplay["error"].(map[string]interface{})["code"]; code != "dependency_consent_invalid_or_consumed" {
		t.Fatalf("wrong acknowledgement replay = %#v", wrongReplay)
	}
}

func TestVulkanDependencyCommandRejectsEveryArgvMutation(t *testing.T) {
	expected := vulkanDependencyInstallCommand()
	if strings.Join(expected, " ") != "/usr/bin/pkexec /usr/bin/apt-get install --yes --no-install-recommends libvulkan-dev glslc spirv-headers cmake build-essential" {
		t.Fatalf("privileged command does not contain the exact build dependencies: %#v", expected)
	}
	for index := range expected {
		mutated := append([]string(nil), expected...)
		mutated[index] += "-changed"
		if err := validateVulkanDependencyArgv(mutated); err == nil {
			t.Fatalf("mutated argv index %d was accepted: %#v", index, mutated)
		}
	}
	if err := validateVulkanDependencyArgv(append(expected, "extra")); err == nil {
		t.Fatal("extra privileged argument was accepted")
	}
}

func TestDebianLikeOSReleaseRecognizesUbuntuDerivatives(t *testing.T) {
	tests := []struct {
		name    string
		content string
		want    bool
	}{
		{name: "Ubuntu", content: "ID=ubuntu\n", want: true},
		{name: "Debian", content: "ID=debian\n", want: true},
		{name: "Zorin", content: "ID=zorin\nID_LIKE=\"ubuntu debian\"\n", want: true},
		{name: "Fedora", content: "ID=fedora\nID_LIKE=\"rhel centos\"\n", want: false},
		{name: "Misleading name", content: "NAME=Ubuntu-inspired\nID=custom\n", want: false},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := isDebianLikeOSRelease([]byte(test.content)); got != test.want {
				t.Fatalf("isDebianLikeOSRelease() = %t, want %t", got, test.want)
			}
		})
	}
}

func waitForSystemDependencyOperation(t *testing.T, module *EngineModule, id string) *EngineOperation {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		operation, exists := module.operation(id)
		if exists && terminalOperationState(operation.State) {
			return operation
		}
		time.Sleep(10 * time.Millisecond)
	}
	operation, _ := module.operation(id)
	t.Fatalf("system dependency operation did not finish: %#v", operation)
	return nil
}
