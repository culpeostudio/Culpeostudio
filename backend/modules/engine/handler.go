package engine

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/engineplanner"
	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/localinference"
	"github.com/fillyengine/backend/internal/modelcatalog"
	"github.com/fillyengine/backend/internal/security"
)

// Fiber route values normally reference fasthttp's reusable request buffer.
// Engine operations outlive the request, so every identifier crossing that
// boundary must own its bytes even when the top-level app is misconfigured.
func stableRouteParam(c *fiber.Ctx, name string) string {
	return strings.Clone(c.Params(name))
}

func (m *EngineModule) RegisterRoutes(router fiber.Router) {
	g := router.Group("/engine")
	g.Get("/models", m.handleModels)
	g.Post("/models/rescan", m.handleRescan)
	g.Delete("/models/:id", m.handleDeleteModel)
	g.Get("/capabilities", m.handleCapabilities)
	g.Post("/models/:id/recommendation", m.handleRecommendation)
	g.Post("/models/:id/trust-remote-code", m.handleTrustRemoteCode)
	g.Post("/simulate-parallel-load", m.handleSimulateParallelLoad)

	g.Get("/instances", m.handleInstances)
	g.Post("/instances", m.handleCreateInstance)
	g.Get("/instances/:id", m.handleInstance)
	g.Get("/instances/:id/metrics", m.handleInstanceMetrics)
	g.Patch("/instances/:id", m.handlePatchInstance)
	g.Post("/instances/:id/ensure-ready", m.handleEnsureReady)
	g.Delete("/instances/:id", m.handleDeleteInstance)

	g.Get("/operations/:id", m.handleOperation)
	g.Post("/operations/:id/cancel", m.handleCancelOperation)
	g.Post("/events/ticket", m.handleEventTicket)
	g.Get("/events", m.handleEvents)

	g.Get("/runtimes", m.handleRuntimes)
	g.Post("/runtimes/:id/install", m.handleInstallRuntime)
	g.Post("/system-dependencies/vulkan/consent", m.handleVulkanDependencyConsent)
	g.Post("/system-dependencies/vulkan/install", m.handleVulkanDependencyInstall)

	g.Get("/keys", m.handleKeys)
	g.Post("/keys", m.handleCreateKey)
	g.Post("/keys/:id/rotate", m.handleRotateKey)
	g.Delete("/keys/:id", m.handleRevokeKey)

	// Legacy-Wrapper bleiben auf genau eine Instanz mit stabiler ID begrenzt.
	g.Post("/start", m.handleLegacyStart)
	g.Post("/load", m.handleLegacyStart)
	g.Post("/stop", m.handleLegacyStop)
	g.Get("/status", m.handleLegacyStatus)
}

type catalogModelResponse struct {
	modelcatalog.ModelRecord
	Status                  string                         `json:"status"`
	Architecture            string                         `json:"architecture,omitempty"`
	Quantization            string                         `json:"quantization,omitempty"`
	ModelContextLimitTokens int                            `json:"model_context_limit_tokens,omitempty"`
	ValidationIssues        []modelcatalog.ValidationIssue `json:"validation_issues,omitempty"`
}

func catalogResponse(record modelcatalog.ModelRecord) catalogModelResponse {
	status := "incomplete"
	if record.Startable {
		status = "ready"
	} else if record.Complete {
		status = "invalid"
	}
	return catalogModelResponse{ModelRecord: record, Status: status, Architecture: record.Metadata.Architecture, Quantization: record.Metadata.Quantization, ModelContextLimitTokens: record.Metadata.ContextLength, ValidationIssues: record.Issues}
}

func (m *EngineModule) handleModels(c *fiber.Ctx) error {
	m.mu.RLock()
	records := append([]modelcatalog.ModelRecord(nil), m.models...)
	m.mu.RUnlock()
	models := make([]catalogModelResponse, 0, len(records))
	for _, record := range records {
		models = append(models, catalogResponse(record))
	}
	return c.JSON(fiber.Map{"models": models, "model_dir": m.modelDir})
}

func (m *EngineModule) handleRescan(c *fiber.Ctx) error {
	records, err := m.rescan(c.UserContext())
	if err != nil {
		return writeEngineError(c, err)
	}
	models := make([]catalogModelResponse, 0, len(records))
	for _, record := range records {
		models = append(models, catalogResponse(record))
	}
	m.events.publish("models_rescanned", fiber.Map{"count": len(models)})
	return c.JSON(fiber.Map{"models": models, "model_dir": m.modelDir})
}

func (m *EngineModule) handleDeleteModel(c *fiber.Ctx) error {
	records, err := m.deleteModel(c.UserContext(), stableRouteParam(c, "id"))
	if err != nil {
		return writeEngineError(c, err)
	}
	models := make([]catalogModelResponse, 0, len(records))
	for _, record := range records {
		models = append(models, catalogResponse(record))
	}
	return c.JSON(fiber.Map{"models": models, "model_dir": m.modelDir})
}

func (m *EngineModule) handleCapabilities(c *fiber.Ctx) error {
	snapshot, runtimes := m.runtimeCapabilities(c.UserContext())
	settings := m.settings.Get()
	ramReserve := effectiveReserveBytes(settings.EngineRAMReserveBytes, snapshot.RAMTotalBytes, 15, 4<<30)
	gpuReserve := int64(0)
	gpuReservesByID := make(map[string]int64)
	for _, gpu := range snapshot.GPUs {
		if gpu.SharedMemory {
			continue
		}
		reserve := effectiveReserveBytes(settings.EngineGPUReserveBytes, gpu.VRAMTotalBytes, 10, 512<<20)
		gpuReservesByID[gpu.ID] = reserve
		if reserve > gpuReserve {
			gpuReserve = reserve
		}
	}
	return c.JSON(fiber.Map{
		"hardware": snapshot, "runtimes": runtimes,
		"defaults": fiber.Map{
			"minimum_context_tokens": 4096, "context_step_tokens": 256,
			"ram_reserve": "max(4 GiB, 15%)", "gpu_reserve": "max(512 MiB, 10%)",
			"kv_cache_policy": "prefer_4bit", "max_sequences": 1, "autostart": false,
			"gateway_url": m.gatewayURL, "weight_quantization": "unchanged",
			"ram_reserve_bytes":        ramReserve,
			"gpu_reserve_bytes":        gpuReserve,
			"gpu_reserve_bytes_by_id":  gpuReservesByID,
			"ram_reserve_is_automatic": settings.EngineRAMReserveBytes == nil,
			"gpu_reserve_is_automatic": settings.EngineGPUReserveBytes == nil,
			"emergency_ram_floor":      "max(1 GiB, 5%)",
			"emergency_gpu_floor":      "max(256 MiB, 3%)",
		},
	})
}

func effectiveReserveBytes(override *int64, total, percent, floor int64) int64 {
	if override != nil {
		return *override
	}
	percentage := total / 100 * percent
	if remainder := total % 100; remainder > 0 {
		percentage += (remainder*percent + 99) / 100
	}
	if percentage < floor {
		return floor
	}
	return percentage
}

func (m *EngineModule) handleRecommendation(c *fiber.Ctx) error {
	config, err := parseEngineConfig(c.Body(), defaultEngineConfig())
	if err != nil {
		return writeEngineError(c, err)
	}
	plan, _, err := m.recommendation(c.UserContext(), stableRouteParam(c, "id"), "recommendation", config)
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.JSON(fiber.Map{"plan": plan})
}

func (m *EngineModule) handleTrustRemoteCode(c *fiber.Ctx) error {
	var body struct {
		Accepted        bool   `json:"accepted"`
		Acknowledgement string `json:"acknowledgement"`
	}
	if err := c.BodyParser(&body); err != nil {
		return writeEngineError(c, err)
	}
	if !body.Accepted || body.Acknowledgement != "not_sandboxed" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": fiber.Map{"message": "Explizite Zustimmung und acknowledgement=not_sandboxed sind erforderlich", "code": "remote_code_acknowledgement_required"}})
	}
	approval, err := m.approveRemoteCode(stableRouteParam(c, "id"))
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.JSON(approval)
}

func (m *EngineModule) handleInstances(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"instances": m.listInstancesForUser(engineRequestUserID(c))})
}

func (m *EngineModule) handleCreateInstance(c *fiber.Ctx) error {
	var envelope map[string]interface{}
	if err := json.Unmarshal(c.Body(), &envelope); err != nil {
		return writeEngineError(c, err)
	}
	modelID := strings.TrimSpace(stringValue(envelope["model_id"]))
	servedName := strings.TrimSpace(stringValue(envelope["served_model_name"]))
	if modelID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "model_id ist erforderlich"})
	}
	config, err := parseEngineConfig(c.Body(), defaultEngineConfig())
	if err != nil {
		return writeEngineError(c, err)
	}
	instance, operation, err := m.createInstance(c.UserContext(), modelID, servedName, config)
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"instance": m.instanceForUser(instance, engineRequestUserID(c)), "operation_id": operation.ID, "status": operation.State, "queue_position": operation.QueuePosition})
}

func (m *EngineModule) handleInstance(c *fiber.Ctx) error {
	instance, ok := m.getInstance(stableRouteParam(c, "id"))
	if !ok {
		return writeEngineError(c, os.ErrNotExist)
	}
	return c.JSON(fiber.Map{"instance": m.instanceForUser(instance, engineRequestUserID(c))})
}

// handleInstanceMetrics serves live monitoring data for one instance:
// tokens/sec and time-to-first-token from recent requests, worker process
// memory, the planned budget, and current host headroom. Clients poll it
// while a model is in use.
func (m *EngineModule) handleInstanceMetrics(c *fiber.Ctx) error {
	instance, ok := m.getInstance(stableRouteParam(c, "id"))
	if !ok {
		return writeEngineError(c, os.ErrNotExist)
	}
	return c.JSON(m.instanceMetrics(c.UserContext(), instance))
}

func (m *EngineModule) handlePatchInstance(c *fiber.Ctx) error {
	id := stableRouteParam(c, "id")
	instance, ok := m.getInstance(id)
	if !ok {
		return writeEngineError(c, os.ErrNotExist)
	}
	var body map[string]interface{}
	if err := json.Unmarshal(c.Body(), &body); err != nil {
		return writeEngineError(c, err)
	}
	if rawVisible, present := body["show_in_chat_picker"]; present {
		visible, valid := rawVisible.(bool)
		if !valid {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": fiber.Map{"message": "show_in_chat_picker muss ein Boolean sein", "code": "invalid_request"}})
		}
		// Picker visibility is user-owned state in a separate private store. Keep
		// this mutation isolated so a later invalid engine action cannot leave a
		// successful partial preference change behind.
		delete(body, "show_in_chat_picker")
		if len(body) != 0 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": fiber.Map{
				"message": "show_in_chat_picker muss in einem eigenen PATCH gesetzt werden",
				"code":    "visibility_patch_must_be_separate",
			}})
		}
		if err := m.preferences.setVisible(engineRequestUserID(c), id, visible); err != nil {
			return writeEngineError(c, err)
		}
		updated, _ := m.getInstance(id)
		m.events.publish("instance_changed", updated)
		return c.JSON(fiber.Map{"instance": m.instanceForUser(updated, engineRequestUserID(c))})
	}
	if rawDefaults, present := body["generation_defaults"]; present {
		defaults, ok := rawDefaults.(map[string]interface{})
		if !ok {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "generation_defaults muss ein Objekt sein"})
		}
		m.mu.Lock()
		current := m.instances[id]
		if current != nil {
			current.RequestedConfig.GenerationDefaults = cloneJSONMap(defaults)
			current.EffectiveConfig.GenerationDefaults = cloneJSONMap(defaults)
			current.UpdatedAt = time.Now().UTC()
			_ = m.persistLocked()
			instance = cloneInstance(current)
		}
		m.mu.Unlock()
		m.events.publish("instance_changed", instance)
		if strings.TrimSpace(stringValue(body["action"])) == "" {
			return c.JSON(fiber.Map{"instance": m.instanceForUser(instance, engineRequestUserID(c))})
		}
	}
	action := strings.ToLower(strings.TrimSpace(stringValue(body["action"])))
	switch action {
	case "stop":
		operation, err := m.scheduleStop(id)
		if err != nil {
			return writeEngineError(c, err)
		}
		return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"instance": m.instanceForUser(instance, engineRequestUserID(c)), "operation_id": operation.ID, "status": operation.State, "queue_position": operation.QueuePosition})
	case "start", "restart":
		config := instance.RequestedConfig
		if requested, exists := body["requested_config"]; exists {
			payload, _ := json.Marshal(requested)
			var err error
			config, err = parseEngineConfig(payload, config)
			if err != nil {
				return writeEngineError(c, err)
			}
		} else {
			payload, _ := json.Marshal(body)
			config, _ = parseEngineConfig(payload, config)
		}
		operation, err := m.scheduleStart(id, config, action)
		if err != nil {
			return writeEngineError(c, err)
		}
		updated, _ := m.getInstance(id)
		return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"instance": m.instanceForUser(updated, engineRequestUserID(c)), "operation_id": operation.ID, "status": operation.State, "queue_position": operation.QueuePosition})
	case "apply_fix":
		fix := strings.ToLower(strings.TrimSpace(stringValue(body["fix"])))
		config, err := m.configForFix(instance, fix)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": fiber.Map{"message": err.Error(), "code": "unsupported_fix"}})
		}
		operation, err := m.scheduleStart(id, config, "apply_fix")
		if err != nil {
			return writeEngineError(c, err)
		}
		updated, _ := m.getInstance(id)
		return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"instance": m.instanceForUser(updated, engineRequestUserID(c)), "operation_id": operation.ID, "status": operation.State, "queue_position": operation.QueuePosition, "applied_fix": fix})
	case "":
		config, err := parseEngineConfig(c.Body(), instance.RequestedConfig)
		if err != nil {
			return writeEngineError(c, err)
		}
		m.mu.Lock()
		if current := m.instances[id]; current != nil {
			current.RequestedConfig = config
			current.RestartRequiredFields = restartRequiredFields()
			current.UpdatedAt = time.Now().UTC()
			instance = cloneInstance(current)
			_ = m.persistLocked()
		}
		m.mu.Unlock()
		return c.JSON(fiber.Map{"instance": m.instanceForUser(instance, engineRequestUserID(c))})
	default:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "action muss start, stop, restart oder apply_fix sein"})
	}
}

// configForFix translates a one-click remediation into a concrete restart
// configuration for the instance.
func (m *EngineModule) configForFix(instance *EngineInstance, fix string) (EngineConfig, error) {
	config := cloneEngineConfig(instance.RequestedConfig)
	switch fix {
	case engineruntime.FixReduceContext:
		// Halve the last planned context, never below a still-useful minimum.
		current := 0
		if instance.Plan != nil {
			current = instance.Plan.EffectiveContextTokens
		}
		if current <= 0 && instance.EffectiveConfig.ContextTokens != nil {
			current = *instance.EffectiveConfig.ContextTokens
		}
		if current <= 0 {
			current = 8192
		}
		reduced := current / 2
		if reduced < 2048 {
			reduced = 2048
		}
		config.ContextMode = "fixed"
		config.ContextTokens = &reduced
		return config, nil
	case engineruntime.FixRetryOnCPU:
		if config.RuntimeOptions == nil {
			config.RuntimeOptions = map[string]interface{}{}
		}
		config.RuntimeOptions["offload"] = "cpu"
		config.RuntimeOptions["gpu_layers"] = 0
		config.RuntimeOptions["allow_ram_offload"] = true
		return config, nil
	case fixRetryWithRAM:
		if config.RuntimeOptions == nil {
			config.RuntimeOptions = map[string]interface{}{}
		}
		config.RuntimeOptions["allow_ram_offload"] = true
		return config, nil
	default:
		return EngineConfig{}, fmt.Errorf("Fix %q wird nicht unterstuetzt; unterstuetzt sind reduce_context, retry_on_cpu und retry_with_ram", fix)
	}
}

func (m *EngineModule) handleEnsureReady(c *fiber.Ctx) error {
	id := stableRouteParam(c, "id")
	instance, operation, err := m.ensureReady(id)
	if err != nil {
		return writeEngineError(c, err)
	}
	status := "ready"
	operationID := ""
	queuePosition := 0
	httpStatus := fiber.StatusOK
	if operation != nil {
		operationID = operation.ID
		queuePosition = operation.QueuePosition
		status = operation.State
		if status == "running" && queuePosition > 0 {
			status = "queued"
		}
		httpStatus = fiber.StatusAccepted
	}
	return c.Status(httpStatus).JSON(fiber.Map{
		"instance": m.instanceForUser(instance, engineRequestUserID(c)), "operation_id": operationID,
		"status": status, "queue_position": queuePosition,
	})
}

func engineRequestUserID(c *fiber.Ctx) string {
	if value, ok := c.Locals("user_id").(string); ok && strings.TrimSpace(value) != "" {
		return normalizedEngineUserID(value)
	}
	if value, ok := c.Locals(security.UserIDLocalKey).(string); ok && strings.TrimSpace(value) != "" {
		return normalizedEngineUserID(value)
	}
	return "local"
}

func (m *EngineModule) handleDeleteInstance(c *fiber.Ctx) error {
	instance, operation, err := m.scheduleDelete(stableRouteParam(c, "id"))
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"instance": m.instanceForUser(instance, engineRequestUserID(c)), "operation_id": operation.ID})
}

func (m *EngineModule) handleOperation(c *fiber.Ctx) error {
	operation, ok := m.operation(stableRouteParam(c, "id"))
	if !ok {
		return writeEngineError(c, os.ErrNotExist)
	}
	return c.JSON(fiber.Map{"operation": operation})
}

func (m *EngineModule) handleCancelOperation(c *fiber.Ctx) error {
	operation, err := m.cancelOperation(stableRouteParam(c, "id"))
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.JSON(fiber.Map{"operation": operation})
}

func (m *EngineModule) handleEventTicket(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"ticket": m.events.issueTicket(engineRequestUserID(c)), "expires_in_seconds": 60})
}

func (m *EngineModule) handleEvents(c *fiber.Ctx) error {
	userID, valid := m.events.consumeTicket(strings.TrimSpace(c.Query("ticket")))
	if !valid {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "ungueltiges oder bereits verwendetes Event-Ticket"})
	}
	c.Set(fiber.HeaderContentType, "text/event-stream; charset=utf-8")
	c.Set(fiber.HeaderCacheControl, "no-cache")
	c.Set("X-Accel-Buffering", "no")
	c.Context().SetBodyStreamWriter(func(writer *bufio.Writer) {
		events, unsubscribe := m.events.subscribe()
		defer unsubscribe()
		heartbeat := time.NewTicker(15 * time.Second)
		defer heartbeat.Stop()
		initial, _ := json.Marshal(engineEvent{Type: "snapshot", Data: fiber.Map{"instances": m.listInstancesForUser(userID)}, Timestamp: time.Now().UTC()})
		_, _ = fmt.Fprintf(writer, "data: %s\n\n", initial)
		if err := writer.Flush(); err != nil {
			return
		}
		for {
			select {
			case event, ok := <-events:
				if !ok {
					return
				}
				event = m.engineEventForUser(event, userID)
				payload, _ := json.Marshal(event)
				_, _ = fmt.Fprintf(writer, "data: %s\n\n", payload)
			case <-heartbeat.C:
				_, _ = writer.WriteString(": keepalive\n\n")
			}
			if err := writer.Flush(); err != nil {
				return
			}
		}
	})
	return nil
}

func (m *EngineModule) handleRuntimes(c *fiber.Ctx) error {
	_, runtimes := m.runtimeCapabilities(c.UserContext())
	jobs := []engineruntime.InstallJobSnapshot{}
	if m.installer != nil {
		jobs = m.installer.Jobs()
	}
	return c.JSON(fiber.Map{"runtimes": runtimes, "install_operations": jobs})
}

func (m *EngineModule) handleInstallRuntime(c *fiber.Ctx) error {
	kind := engineruntime.RuntimeKind(strings.TrimSpace(stableRouteParam(c, "id")))
	snapshot, _ := m.liveHardware(c.UserContext())
	if kind == engineruntime.RuntimeVLLM && !vllmCompatible(snapshot) {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": fiber.Map{"message": "vLLM wird erst nach bestaetigter CUDA-/ROCm-Kompatibilitaet angeboten", "code": "runtime_incompatible"}})
	}
	if kind == engineruntime.RuntimeLlamaCPP {
		usableSnapshot, warnings := usableLlamaBuildSnapshot(snapshot)
		if len(usableSnapshot.GPUs) != len(snapshot.GPUs) && !m.healthyLlamaGPUCapability(snapshot) {
			reason := strings.Join(warnings, "; ")
			if reason == "" {
				reason = "Die GPU-Build-Abhaengigkeiten sind nicht einsatzbereit."
			}
			return writeEngineError(c, &gpuRuntimeUnavailableError{Reason: reason, Remediation: "install_vulkan_dependencies"})
		}
		if !m.healthyLlamaGPUCapability(snapshot) {
			snapshot = usableSnapshot
		}
	}
	recipe, err := m.runtimeRecipe(kind, snapshot)
	if err != nil || m.installer == nil {
		if err == nil {
			err = fmt.Errorf("Python 3 fehlt")
		}
		return writeEngineError(c, err)
	}
	releaseForeground, err := m.beginForegroundRuntime(c.UserContext())
	if err != nil {
		return writeEngineError(c, err)
	}
	job, err := m.startRuntimeInstall(c.UserContext(), recipe)
	if err != nil {
		releaseForeground()
		return writeEngineError(c, err)
	}
	m.mu.Lock()
	operation, operationCtx := m.newOperationLocked("runtime_install", "", "Runtime wird vorgewärmt")
	_ = m.persistLocked()
	m.mu.Unlock()
	go func() {
		defer releaseForeground()
		_, waitErr := m.waitRuntimeInstall(operationCtx, operation.ID, "", job, "Runtime "+string(kind)+" wird vorbereitet")
		if waitErr != nil {
			if operationCtx.Err() != nil {
				return
			}
			m.setOperation(operation.ID, "failed", 1, "Runtime-Installation fehlgeschlagen", waitErr)
			return
		}
		m.setOperation(operation.ID, "completed", 1, "Runtime ist installiert und geprueft", nil)
	}()
	return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"operation_id": operation.ID, "runtime_install": job.Snapshot()})
}

func (m *EngineModule) handleKeys(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"keys": m.keys.list()})
}

func (m *EngineModule) handleCreateKey(c *fiber.Ctx) error {
	var body struct {
		Name        string   `json:"name"`
		InstanceIDs []string `json:"instance_ids"`
	}
	if err := c.BodyParser(&body); err != nil {
		return writeEngineError(c, err)
	}
	for _, id := range body.InstanceIDs {
		if _, ok := m.getInstance(id); !ok {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "unbekannte Instanz im Schluessel-Scope: " + id})
		}
	}
	public, plaintext, err := m.keys.create(body.Name, body.InstanceIDs)
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"key": public, "plaintext": plaintext, "show_once": true})
}

func (m *EngineModule) handleRotateKey(c *fiber.Ctx) error {
	public, plaintext, err := m.keys.rotate(stableRouteParam(c, "id"))
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.JSON(fiber.Map{"key": public, "plaintext": plaintext, "show_once": true})
}

func (m *EngineModule) handleRevokeKey(c *fiber.Ctx) error {
	if !m.keys.revoke(stableRouteParam(c, "id")) {
		return writeEngineError(c, os.ErrNotExist)
	}
	return c.JSON(fiber.Map{"revoked": true})
}

func (m *EngineModule) handleLegacyStart(c *fiber.Ctx) error {
	var body struct {
		ModelID   string `json:"model_id"`
		ModelPath string `json:"model_path"`
		EngineConfig
	}
	if err := c.BodyParser(&body); err != nil {
		return writeEngineError(c, err)
	}
	modelID := strings.TrimSpace(body.ModelID)
	if modelID == "" {
		var err error
		modelID, err = m.catalogIDForLegacyPath(body.ModelPath)
		if err != nil {
			return writeEngineError(c, err)
		}
	}
	config := normalizeConfig(body.EngineConfig)
	if existing, ok := m.getInstance("default"); ok {
		if existing.ModelID != modelID {
			if existing.State != engineruntime.StateStopped && existing.State != engineruntime.StateFailed {
				return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "default-Instanz zuerst stoppen, bevor ein anderes Modell geladen wird"})
			}
		}
		operation, err := m.scheduleStartForModel("default", modelID, config, "legacy_start")
		if err != nil {
			return writeEngineError(c, err)
		}
		instance, _ := m.getInstance("default")
		return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"status": "starting", "instance": instance, "operation_id": operation.ID})
	}
	instance, operation, err := m.createInstanceWithID(c.UserContext(), "default", modelID, "default", config)
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"status": "starting", "instance": instance, "operation_id": operation.ID})
}

func (m *EngineModule) handleLegacyStop(c *fiber.Ctx) error {
	if _, ok := m.getInstance("default"); !ok {
		return c.JSON(fiber.Map{"status": "stopped"})
	}
	operation, err := m.scheduleStop("default")
	if err != nil {
		return writeEngineError(c, err)
	}
	return c.Status(fiber.StatusAccepted).JSON(fiber.Map{"status": "stopping", "operation_id": operation.ID})
}

func (m *EngineModule) handleLegacyStatus(c *fiber.Ctx) error {
	instance, ok := m.getInstance("default")
	if !ok {
		return c.JSON(fiber.Map{"running": false, "state": "stopped"})
	}
	return c.JSON(fiber.Map{"running": instance.State == engineruntime.StateReady, "state": instance.State, "model": instance.ModelID, "instance": instance})
}

func (m *EngineModule) catalogIDForLegacyPath(value string) (string, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return "", fmt.Errorf("model_id oder model_path ist erforderlich")
	}
	m.mu.RLock()
	root := m.modelDir
	records := append([]modelcatalog.ModelRecord(nil), m.models...)
	m.mu.RUnlock()
	candidate := value
	if !filepath.IsAbs(candidate) {
		candidate = filepath.Join(root, candidate)
	}
	abs, err := filepath.Abs(filepath.Clean(candidate))
	if err != nil {
		return "", err
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return "", err
	}
	relative, err := filepath.Rel(root, resolved)
	if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("model_path muss auf einen Katalogeintrag innerhalb von model_dir zeigen")
	}
	for _, record := range records {
		path, pathErr := m.modelPath(record)
		if pathErr == nil && filepath.Clean(path) == filepath.Clean(resolved) {
			return record.ID, nil
		}
	}
	return "", fmt.Errorf("model_path ist kein startbarer Katalogeintrag")
}

func parseEngineConfig(payload []byte, base EngineConfig) (EngineConfig, error) {
	base = normalizeConfig(base)
	if len(strings.TrimSpace(string(payload))) == 0 {
		return base, nil
	}
	var patch map[string]interface{}
	if err := json.Unmarshal(payload, &patch); err != nil {
		return EngineConfig{}, fmt.Errorf("ungueltige Engine-Konfiguration: %w", err)
	}
	basePayload, _ := json.Marshal(base)
	var merged map[string]interface{}
	_ = json.Unmarshal(basePayload, &merged)
	for key, value := range patch {
		if key == "model_id" || key == "served_model_name" || key == "action" {
			continue
		}
		if (key == "runtime_options" || key == "generation_defaults") && value != nil {
			baseMap, _ := merged[key].(map[string]interface{})
			patchMap, _ := value.(map[string]interface{})
			if baseMap == nil {
				baseMap = map[string]interface{}{}
			}
			for nestedKey, nestedValue := range patchMap {
				baseMap[nestedKey] = nestedValue
			}
			merged[key] = baseMap
			continue
		}
		merged[key] = value
	}
	mergedPayload, _ := json.Marshal(merged)
	var result EngineConfig
	if err := json.Unmarshal(mergedPayload, &result); err != nil {
		return EngineConfig{}, err
	}
	result = normalizeConfig(result)
	if result.ContextMode != "auto_max" && result.ContextMode != "fixed" {
		return EngineConfig{}, fmt.Errorf("context_mode muss auto_max oder fixed sein")
	}
	if result.ContextTokens != nil && *result.ContextTokens < 0 {
		return EngineConfig{}, fmt.Errorf("context_tokens darf nicht negativ sein")
	}
	if result.MaxSequences < 1 {
		return EngineConfig{}, fmt.Errorf("max_sequences muss mindestens 1 sein")
	}
	if !containsString([]string{"low", "normal", "high", "pinned"}, result.Priority) {
		return EngineConfig{}, fmt.Errorf("priority muss low, normal, high oder pinned sein")
	}
	return result, nil
}

func writeEngineError(c *fiber.Ctx, err error) error {
	if err == nil {
		err = errors.New("unbekannter Engine-Fehler")
	}
	status := fiber.StatusBadRequest
	code := "invalid_request"
	response := fiber.Map{"message": err.Error(), "code": code}
	if errors.Is(err, os.ErrNotExist) {
		status = fiber.StatusNotFound
		response["code"] = "not_found"
	}
	var conflict *engineplanner.ConflictError
	if errors.As(err, &conflict) {
		status = fiber.StatusConflict
		response["code"] = "resource_conflict"
		response["conflict"] = conflict
	}
	var loadConflict *ResourceConflictError
	if errors.As(err, &loadConflict) {
		status = fiber.StatusConflict
		response["code"] = "resource_conflict"
		response["conflict"] = loadConflict
	}
	var gpuRuntimeError *gpuRuntimeUnavailableError
	if errors.As(err, &gpuRuntimeError) {
		status = fiber.StatusConflict
		response["code"] = "gpu_runtime_unavailable"
		response["reason"] = gpuRuntimeError.Reason
		if gpuRuntimeError.Remediation != "" {
			response["remediation"] = gpuRuntimeError.Remediation
		}
	}
	var trustError *trustRequiredError
	if errors.As(err, &trustError) {
		status = fiber.StatusConflict
		response["code"] = "remote_code_consent_required"
		response["model_fingerprint"] = trustError.Fingerprint
		response["python_files_hash"] = trustError.PythonHash
		response["python_file_count"] = trustError.FileCount
		response["not_a_sandbox"] = true
	}
	if errors.Is(err, localinference.ErrGuardRejected) && loadConflict == nil {
		status = fiber.StatusServiceUnavailable
		response["code"] = "resource_guard_rejected"
	}
	if errors.Is(err, localinference.ErrQueueTimeout) {
		status = fiber.StatusGatewayTimeout
		response["code"] = "queue_timeout"
	}
	return c.Status(status).JSON(fiber.Map{"error": response})
}

func stringValue(value interface{}) string {
	if value == nil {
		return ""
	}
	return fmt.Sprint(value)
}
