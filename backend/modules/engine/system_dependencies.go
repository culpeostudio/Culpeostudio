package engine

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
)

const (
	vulkanDevelopmentPackage       = "libvulkan-dev"
	vulkanShaderCompilerPackage    = "glslc"
	vulkanSPIRVHeadersPackage      = "spirv-headers"
	vulkanCMakePackage             = "cmake"
	vulkanBuildEssentialPackage    = "build-essential"
	vulkanDependencyDisplay        = "libvulkan-dev, glslc, spirv-headers, cmake und build-essential"
	vulkanConsentAcknowledgement   = "install_vulkan_build_dependencies"
	vulkanConsentLifetime          = 2 * time.Minute
	vulkanDependencyOperationType  = "system_dependency_install"
	privilegedExecutable           = "/usr/bin/pkexec"
	debianPackageManagerExecutable = "/usr/bin/apt-get"
)

func vulkanDependencyInstallCommand() []string {
	return []string{
		privilegedExecutable,
		debianPackageManagerExecutable,
		"install",
		"--yes",
		"--no-install-recommends",
		vulkanDevelopmentPackage,
		vulkanShaderCompilerPackage,
		vulkanSPIRVHeadersPackage,
		vulkanCMakePackage,
		vulkanBuildEssentialPackage,
	}
}

type systemDependencyConsent struct {
	UserID    string
	ExpiresAt time.Time
}

type systemDependencyError struct {
	Code       string
	Message    string
	HTTPStatus int
}

func (e *systemDependencyError) Error() string { return e.Message }

type privilegedCommandRunner interface {
	Run(context.Context, []string, io.Writer) error
}

type execPrivilegedCommandRunner struct {
	runner engineruntime.CommandRunner
}

func (r *execPrivilegedCommandRunner) Run(ctx context.Context, argv []string, output io.Writer) error {
	if err := validateVulkanDependencyArgv(argv); err != nil {
		return err
	}
	if r.runner == nil {
		r.runner = &engineruntime.ExecCommandRunner{}
	}

	return r.runner.Run(ctx, append([]string(nil), argv...), nil, output)
}

func validateVulkanDependencyArgv(argv []string) error {
	expectedArgv := vulkanDependencyInstallCommand()
	if len(argv) != len(expectedArgv) {
		return &systemDependencyError{Code: "dependency_command_rejected", Message: "Der privilegierte Installationsbefehl entspricht nicht der festen Freigabeliste."}
	}
	for index, expected := range expectedArgv {
		if argv[index] != expected {
			return &systemDependencyError{Code: "dependency_command_rejected", Message: "Der privilegierte Installationsbefehl entspricht nicht der festen Freigabeliste."}
		}
	}
	return nil
}

func (m *EngineModule) handleVulkanDependencyConsent(c *fiber.Ctx) error {
	if err := m.checkVulkanDependencyPlatform(); err != nil {
		return writeSystemDependencyError(c, err)
	}
	if m.vulkanDevelopmentAvailable() {
		return writeSystemDependencyError(c, &systemDependencyError{
			Code: "dependency_already_available", Message: "Die Vulkan-Build-Abhaengigkeiten sind bereits installiert.", HTTPStatus: fiber.StatusConflict,
		})
	}
	token, expiresAt, err := m.issueSystemDependencyConsent(engineRequestUserID(c))
	if err != nil {
		return writeSystemDependencyError(c, err)
	}
	return c.JSON(fiber.Map{
		"consent_token":            token,
		"expires_at":               expiresAt,
		"package":                  vulkanDependencyDisplay,
		"command_summary":          "Vulkan-/SPIR-V-Header, glslc, CMake und den C/C++-Compiler mit der Debian/Ubuntu-Systempaketverwaltung installieren",
		"warning":                  "Das Betriebssystem zeigt fuer diesen einen Versuch eine Administratorabfrage. PhiloEngine erhaelt und verarbeitet kein Passwort. Bei jedem weiteren Versuch ist eine neue Zustimmung erforderlich.",
		"required_acknowledgement": vulkanConsentAcknowledgement,
	})
}

func (m *EngineModule) handleVulkanDependencyInstall(c *fiber.Ctx) error {
	var request struct {
		ConsentToken    string `json:"consent_token"`
		Acknowledgement string `json:"acknowledgement"`
	}
	if err := c.BodyParser(&request); err != nil {
		return writeSystemDependencyError(c, &systemDependencyError{Code: "invalid_request", Message: "Die Installationsanfrage ist ungueltig.", HTTPStatus: fiber.StatusBadRequest})
	}
	if err := m.consumeSystemDependencyConsent(strings.TrimSpace(request.ConsentToken), engineRequestUserID(c)); err != nil {
		return writeSystemDependencyError(c, err)
	}

	if request.Acknowledgement != vulkanConsentAcknowledgement {
		return writeSystemDependencyError(c, &systemDependencyError{
			Code: "dependency_consent_acknowledgement_required", Message: "Die ausdrueckliche Zustimmung zur Installation der Vulkan-Build-Abhaengigkeiten fehlt.", HTTPStatus: fiber.StatusBadRequest,
		})
	}
	if err := m.checkVulkanDependencyPlatform(); err != nil {
		return writeSystemDependencyError(c, err)
	}
	operation, err := m.scheduleVulkanDependencyInstall()
	if err != nil {
		return writeSystemDependencyError(c, err)
	}
	return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"operation_id": operation.ID})
}

func (m *EngineModule) issueSystemDependencyConsent(userID string) (string, time.Time, error) {
	token, err := randomHex(32)
	if err != nil {
		return "", time.Time{}, &systemDependencyError{Code: "dependency_consent_generation_failed", Message: "Die einmalige Zustimmung konnte nicht sicher erzeugt werden.", HTTPStatus: fiber.StatusInternalServerError}
	}
	now := m.systemDependencyNow()
	expiresAt := now.Add(vulkanConsentLifetime)
	m.dependencyConsentMu.Lock()
	if m.dependencyConsents == nil {
		m.dependencyConsents = map[string]systemDependencyConsent{}
	}
	for existingToken, consent := range m.dependencyConsents {
		if !consent.ExpiresAt.After(now) {
			delete(m.dependencyConsents, existingToken)
		}
	}
	m.dependencyConsents[token] = systemDependencyConsent{UserID: normalizedEngineUserID(userID), ExpiresAt: expiresAt}
	m.dependencyConsentMu.Unlock()
	return token, expiresAt, nil
}

func (m *EngineModule) consumeSystemDependencyConsent(token, userID string) error {
	if token == "" {
		return &systemDependencyError{Code: "dependency_consent_required", Message: "Fuer diese Systemaenderung ist eine neue ausdrueckliche Zustimmung erforderlich.", HTTPStatus: fiber.StatusUnauthorized}
	}
	m.dependencyConsentMu.Lock()
	consent, exists := m.dependencyConsents[token]
	if exists {

		delete(m.dependencyConsents, token)
	}
	m.dependencyConsentMu.Unlock()
	if !exists {
		return &systemDependencyError{Code: "dependency_consent_invalid_or_consumed", Message: "Die Zustimmung ist ungueltig oder wurde bereits verwendet. Bitte erneut bestaetigen.", HTTPStatus: fiber.StatusUnauthorized}
	}
	if !consent.ExpiresAt.After(m.systemDependencyNow()) {
		return &systemDependencyError{Code: "dependency_consent_expired", Message: "Die Zustimmung ist abgelaufen. Bitte die Systemaenderung erneut bestaetigen.", HTTPStatus: fiber.StatusUnauthorized}
	}
	if consent.UserID != normalizedEngineUserID(userID) {
		return &systemDependencyError{Code: "dependency_consent_user_mismatch", Message: "Die Zustimmung gehoert nicht zum aktuellen Benutzer.", HTTPStatus: fiber.StatusForbidden}
	}
	return nil
}

func (m *EngineModule) scheduleVulkanDependencyInstall() (*EngineOperation, error) {
	m.dependencyConsentMu.Lock()
	if m.dependencyInstallActive {
		m.dependencyConsentMu.Unlock()
		return nil, &systemDependencyError{Code: "dependency_install_in_progress", Message: "Die Vulkan-Unterstuetzung wird bereits eingerichtet.", HTTPStatus: fiber.StatusConflict}
	}
	m.dependencyInstallActive = true
	m.dependencyConsentMu.Unlock()

	m.mu.Lock()
	if m.shuttingDown {
		m.mu.Unlock()
		m.dependencyConsentMu.Lock()
		m.dependencyInstallActive = false
		m.dependencyConsentMu.Unlock()
		return nil, &systemDependencyError{Code: "engine_shutting_down", Message: "Die Engine wird gerade beendet.", HTTPStatus: fiber.StatusServiceUnavailable}
	}
	operation, operationCtx := m.newOperationLocked(vulkanDependencyOperationType, "", "GPU-Unterstuetzung wird vorbereitet")
	_ = m.persistLocked()
	operationSnapshot := cloneOperation(operation)
	m.mu.Unlock()
	go m.executeVulkanDependencyInstall(operationCtx, operation.ID)
	return operationSnapshot, nil
}

func (m *EngineModule) executeVulkanDependencyInstall(ctx context.Context, operationID string) {
	defer func() {
		m.dependencyConsentMu.Lock()
		m.dependencyInstallActive = false
		m.dependencyConsentMu.Unlock()
	}()

	m.setOperationDetail(operationID, "running", 0.08, "awaiting_administrator_authorization",
		"Administratorfreigabe wird angefordert",
		"Das Betriebssystem fragt die Berechtigung fuer die Installation von libvulkan-dev, glslc, spirv-headers, cmake und build-essential ab. PhiloEngine sieht kein Passwort.", nil)
	command := vulkanDependencyInstallCommand()
	if err := validateVulkanDependencyArgv(command); err != nil {
		m.failSystemDependencyOperation(operationID, err)
		return
	}
	runner := m.dependencyRunner
	if runner == nil {
		runner = &execPrivilegedCommandRunner{}
	}
	output := engineruntime.NewRingBuffer(32 * 1024)
	if err := runner.Run(ctx, command, output); err != nil {
		if errors.Is(err, context.Canceled) || errors.Is(ctx.Err(), context.Canceled) {
			m.setOperationDetail(operationID, "cancelled", 1, "cancelled", "Einrichtung wurde abgebrochen", "Die Administratorfreigabe oder Installation wurde abgebrochen.", context.Canceled)
			return
		}
		m.failSystemDependencyOperation(operationID, classifyPrivilegedInstallFailure(err, output.String()))
		return
	}

	m.setOperationDetail(operationID, "running", 0.4, "verifying_dependency",
		"Vulkan-Build-Abhaengigkeiten werden geprueft",
		"Die Installation wurde beendet. Vulkan-Header, Shader-Compiler, SPIR-V-Header und Build-Unterstuetzung werden jetzt erneut erkannt.", nil)
	if !m.vulkanDevelopmentAvailable() {
		m.failSystemDependencyOperation(operationID, &systemDependencyError{
			Code: "vulkan_dependency_verification_failed", Message: "Die Vulkan-Header und nativen Build-Werkzeuge wurden installiert, konnten danach aber nicht vollstaendig erkannt werden.",
		})
		return
	}

	snapshot := m.vulkanDependencyHardware(ctx)
	vulkanSnapshot := snapshot
	vulkanSnapshot.GPUs = nil
	for _, gpu := range snapshot.GPUs {
		if strings.EqualFold(gpu.Backend, "vulkan") {
			vulkanSnapshot.GPUs = append(vulkanSnapshot.GPUs, gpu)
		}
	}
	if len(vulkanSnapshot.GPUs) == 0 {
		m.failSystemDependencyOperation(operationID, &systemDependencyError{
			Code: "vulkan_gpu_not_detected", Message: "Die Vulkan-Build-Abhaengigkeiten sind installiert, aber aktuell wurde keine Vulkan-Grafikkarte erkannt.",
		})
		return
	}
	if m.installer == nil {
		m.failSystemDependencyOperation(operationID, &systemDependencyError{
			Code: "runtime_installer_unavailable", Message: "Die Vulkan-Dateien sind installiert, aber Python 3 fuer den llama.cpp-Runtime-Build fehlt.",
		})
		return
	}
	recipe, err := m.runtimeRecipe(engineruntime.RuntimeLlamaCPP, vulkanSnapshot)
	if err != nil || recipe.Environment["CMAKE_ARGS"] != "-DGGML_VULKAN=on" {
		if err == nil {
			err = errors.New("Vulkan-Build-Recipe wurde nicht erzeugt")
		}
		m.failSystemDependencyOperation(operationID, &systemDependencyError{Code: "vulkan_runtime_recipe_failed", Message: "Die llama.cpp-Vulkan-Runtime konnte nicht vorbereitet werden: " + err.Error()})
		return
	}

	releaseForeground, err := m.beginForegroundRuntime(ctx)
	if err != nil {
		m.failSystemDependencyOperation(operationID, &systemDependencyError{Code: "runtime_install_rejected", Message: err.Error()})
		return
	}
	defer releaseForeground()
	job, err := m.startRuntimeInstall(ctx, recipe)
	if err != nil {
		m.failSystemDependencyOperation(operationID, &systemDependencyError{Code: "vulkan_runtime_install_failed", Message: err.Error()})
		return
	}
	m.setOperationDetail(operationID, "running", 0.45, "preparing_vulkan_runtime",
		"llama.cpp-Vulkan-Runtime wird gebaut",
		"Die isolierte GPU-Runtime wird installiert und danach mit echtem GPU-Offloading geprueft.", nil)
	if _, err := m.waitRuntimeInstall(ctx, operationID, "", job, "llama.cpp-Vulkan-Runtime wird vorbereitet"); err != nil {
		if errors.Is(err, context.Canceled) || errors.Is(ctx.Err(), context.Canceled) {
			m.setOperationDetail(operationID, "cancelled", 1, "cancelled", "Einrichtung wurde abgebrochen", "Der Vulkan-Runtime-Build wurde abgebrochen.", context.Canceled)
			return
		}
		m.failSystemDependencyOperation(operationID, &systemDependencyError{Code: "vulkan_runtime_install_failed", Message: err.Error()})
		return
	}
	m.setOperationDetail(operationID, "completed", 1, "completed", "GPU-Unterstuetzung ist bereit", "Vulkan-/SPIR-V-Header, Shader-Compiler, CMake, C/C++-Compiler und die gepruefte llama.cpp-Vulkan-Runtime sind einsatzbereit.", nil)
}

func (m *EngineModule) failSystemDependencyOperation(operationID string, err error) {
	if err == nil {
		err = &systemDependencyError{Code: "system_dependency_install_failed", Message: "Die GPU-Unterstuetzung konnte nicht eingerichtet werden."}
	}
	m.setOperationDetail(operationID, "failed", 1, "failed", "GPU-Unterstuetzung konnte nicht eingerichtet werden", err.Error(), err)
}

func classifyPrivilegedInstallFailure(err error, output string) error {
	var dependencyError *systemDependencyError
	if errors.As(err, &dependencyError) {
		return dependencyError
	}
	var exitError *exec.ExitError
	if errors.As(err, &exitError) {
		switch exitError.ExitCode() {
		case 126:
			return &systemDependencyError{Code: "administrator_authorization_cancelled", Message: "Die Administratorabfrage wurde abgebrochen. Es wurden keine Rechte an PhiloEngine uebergeben."}
		case 127:
			return &systemDependencyError{Code: "administrator_authorization_denied", Message: "Das Betriebssystem hat die Administratorfreigabe nicht erteilt."}
		}
	}
	detail := sanitizeEngineLogText(output)
	if detail == "" {
		detail = err.Error()
	}
	return &systemDependencyError{Code: "dependency_package_install_failed", Message: "Die Vulkan-Header und nativen Build-Werkzeuge konnten nicht installiert werden: " + detail}
}

func (m *EngineModule) checkVulkanDependencyPlatform() error {
	if m.dependencyPlatformCheck != nil {
		return m.dependencyPlatformCheck()
	}
	if runtime.GOOS != "linux" {
		return &systemDependencyError{Code: "dependency_platform_unsupported", Message: "Die automatische Vulkan-Reparatur ist derzeit nur fuer Ubuntu und Debian verfuegbar.", HTTPStatus: fiber.StatusConflict}
	}
	data, err := os.ReadFile("/etc/os-release")
	if err != nil {
		return &systemDependencyError{Code: "dependency_platform_unknown", Message: "Die Linux-Distribution konnte nicht sicher als Ubuntu oder Debian erkannt werden.", HTTPStatus: fiber.StatusConflict}
	}
	if !isDebianLikeOSRelease(data) {
		return &systemDependencyError{Code: "dependency_platform_unsupported", Message: "Die automatische Vulkan-Reparatur ist derzeit nur fuer Ubuntu und Debian verfuegbar.", HTTPStatus: fiber.StatusConflict}
	}
	for _, executable := range []string{privilegedExecutable, debianPackageManagerExecutable} {
		info, statErr := os.Stat(executable)
		if statErr != nil || !info.Mode().IsRegular() || info.Mode().Perm()&0o111 == 0 {
			return &systemDependencyError{Code: "dependency_installer_unavailable", Message: fmt.Sprintf("Das benoetigte Systemprogramm %s ist nicht verfuegbar.", executable), HTTPStatus: fiber.StatusConflict}
		}
	}
	return nil
}

func isDebianLikeOSRelease(data []byte) bool {
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		key := strings.ToUpper(strings.TrimSpace(parts[0]))
		if key != "ID" && key != "ID_LIKE" {
			continue
		}
		value := strings.Trim(strings.TrimSpace(parts[1]), "\"'")
		for _, family := range strings.Fields(strings.ToLower(value)) {
			if family == "ubuntu" || family == "debian" {
				return true
			}
		}
	}
	return false
}

func (m *EngineModule) vulkanDevelopmentAvailable() bool {
	if m.dependencyVulkanProbe != nil {
		return m.dependencyVulkanProbe()
	}
	return vulkanDevelopmentAvailable()
}

func (m *EngineModule) vulkanDependencyHardware(ctx context.Context) hardware.Snapshot {
	if m.dependencyHardware != nil {
		return m.dependencyHardware(ctx)
	}
	snapshot, _ := m.liveHardware(ctx)
	return snapshot
}

func (m *EngineModule) systemDependencyNow() time.Time {
	if m.dependencyNow != nil {
		return m.dependencyNow().UTC()
	}
	return time.Now().UTC()
}

func writeSystemDependencyError(c *fiber.Ctx, err error) error {
	status := fiber.StatusBadRequest
	code := "system_dependency_install_failed"
	message := "Die GPU-Unterstuetzung konnte nicht eingerichtet werden."
	var dependencyError *systemDependencyError
	if errors.As(err, &dependencyError) {
		code = dependencyError.Code
		message = dependencyError.Message
		if dependencyError.HTTPStatus != 0 {
			status = dependencyError.HTTPStatus
		}
	} else if err != nil {
		message = err.Error()
	}
	return c.Status(status).JSON(fiber.Map{"error": fiber.Map{"code": code, "message": message}})
}
