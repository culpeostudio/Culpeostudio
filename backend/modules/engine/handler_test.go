package engine

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/localinference"
	"github.com/gofiber/fiber/v2"
)

func TestWriteEngineErrorKeepsLoadPeakConflictActionable(t *testing.T) {
	app := fiber.New()
	app.Get("/", func(c *fiber.Ctx) error {
		return writeEngineError(c, errors.Join(
			localinference.ErrGuardRejected,
			&ResourceConflictError{
				Resource: "gpu:test", RequiredBytes: 15 << 30, AvailableBytes: 14 << 30,
				Reason: "konservativer Lade-Peak unterschreitet die Reserve",
			},
		))
	})
	response := requestJSON(t, app, http.MethodGet, "/", "", http.StatusConflict)
	errorBody, ok := response["error"].(map[string]interface{})
	if !ok || errorBody["code"] != "resource_conflict" {
		t.Fatalf("load-peak response = %#v", response)
	}
}

func TestEngineManagementCatalogRecommendationAndInstanceContract(t *testing.T) {
	t.Setenv("ENGINE_GATEWAY_ADDR", "disabled")
	t.Setenv("ENGINE_RUNTIME_PREWARM", "disabled")
	root := t.TempDir()
	modelDir := filepath.Join(root, "models")
	writeEngineSafeBundle(t, filepath.Join(modelDir, "org", "model"))
	settingsPath := filepath.Join(root, "settings.json")
	settings, _ := json.Marshal(map[string]interface{}{"model_dir": modelDir})
	if err := os.WriteFile(settingsPath, settings, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	defer module.Shutdown()
	// Avoid package installation in this API-contract test. The asynchronous
	// operation must fail cleanly while the management mutation remains valid.
	if module.installer != nil {
		module.installer.Close()
		module.installer = nil
	}

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	models := requestJSON(t, app, http.MethodGet, "/api/engine/models", "", http.StatusOK)
	modelList := models["models"].([]interface{})
	if len(modelList) != 1 {
		t.Fatalf("models = %#v", models)
	}
	model := modelList[0].(map[string]interface{})
	modelID := model["id"].(string)
	if model["status"] != "ready" || model["format"] != "safetensors" {
		t.Fatalf("model response = %#v", model)
	}

	recommendation := requestJSON(t, app, http.MethodPost, "/api/engine/models/"+modelID+"/recommendation", `{"context_mode":"fixed","context_tokens":8192,"kv_cache_policy":"prefer_4bit","max_sequences":1,"runtime_options":{"allow_ram_offload":true}}`, http.StatusOK)
	plan := recommendation["plan"].(map[string]interface{})
	if int(plan["model_context_limit_tokens"].(float64)) != 16384 || int(plan["effective_context_tokens"].(float64)) != 8192 {
		t.Fatalf("plan = %#v", plan)
	}
	if plan["kv_cache_dtype"] != "q4" {
		t.Fatalf("4-bit must describe KV cache only: %#v", plan)
	}
	preflight, ok := plan["preflight"].(map[string]interface{})
	if !ok || preflight["hardware_snapshot_id"] == "" || preflight["model_fingerprint"] == "" {
		t.Fatalf("recommendation has no preflight evidence: %#v", plan)
	}
	if checks, ok := preflight["checks"].([]interface{}); !ok || len(checks) < 4 {
		t.Fatalf("preflight checks = %#v", preflight)
	}

	created := requestJSON(t, app, http.MethodPost, "/api/engine/instances", `{"model_id":"`+modelID+`","runtime":"transformers","context_mode":"fixed","context_tokens":4096,"max_sequences":1,"priority":"normal","kv_cache_policy":"prefer_4bit","allow_fallback":true,"runtime_options":{"gpu_layers":0,"allow_ram_offload":true}}`, http.StatusAccepted)
	instance := created["instance"].(map[string]interface{})
	if instance["id"] == "" || created["operation_id"] == "" {
		t.Fatalf("create response = %#v", created)
	}
	requested := instance["requested_config"].(map[string]interface{})
	runtimeOptions := requested["runtime_options"].(map[string]interface{})
	if value, exists := runtimeOptions["gpu_layers"]; !exists || value.(float64) != 0 {
		t.Fatalf("explicit numeric zero was not preserved: %#v", requested)
	}

	id := instance["id"].(string)
	patched := requestJSON(t, app, http.MethodPatch, "/api/engine/instances/"+id, `{"generation_defaults":{"temperature":0.2,"max_tokens":64}}`, http.StatusOK)
	patchedInstance := patched["instance"].(map[string]interface{})
	defaults := patchedInstance["requested_config"].(map[string]interface{})["generation_defaults"].(map[string]interface{})
	if defaults["temperature"].(float64) != 0.2 {
		t.Fatalf("live defaults = %#v", defaults)
	}

	key := requestJSON(t, app, http.MethodPost, "/api/engine/keys", `{"name":"CI","instance_ids":["`+id+`"]}`, http.StatusCreated)
	plaintext := key["plaintext"].(string)
	listed := requestJSON(t, app, http.MethodGet, "/api/engine/keys", "", http.StatusOK)
	encoded, _ := json.Marshal(listed)
	if plaintext == "" || strings.Contains(string(encoded), plaintext) {
		t.Fatalf("one-time engine key leaked into list: %s", encoded)
	}

	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		operation := requestJSON(t, app, http.MethodGet, "/api/engine/operations/"+created["operation_id"].(string), "", http.StatusOK)["operation"].(map[string]interface{})
		if operation["state"] == "failed" {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("runtime-missing operation did not fail cleanly")
}

func TestDeleteModelRemovesCataloguedFilesAndEmptyFolder(t *testing.T) {
	t.Setenv("ENGINE_GATEWAY_ADDR", "disabled")
	t.Setenv("ENGINE_RUNTIME_PREWARM", "disabled")
	root := t.TempDir()
	modelDir := filepath.Join(root, "models")
	bundle := filepath.Join(modelDir, "publisher", "removable-model")
	writeEngineSafeBundle(t, bundle)
	for name, contents := range map[string]string{
		marketplaceBundleManifest: `{"schema_version":1}`,
		"modeling_custom.py":      "VALUE = 1\n",
		"notes.txt":               "model-owned sidecar\n",
	} {
		if err := os.WriteFile(filepath.Join(bundle, name), []byte(contents), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.MkdirAll(filepath.Join(bundle, "assets"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(bundle, "assets", "template.jinja"), []byte("{{ messages }}\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	settingsPath := filepath.Join(root, "settings.json")
	settings, _ := json.Marshal(map[string]interface{}{"model_dir": modelDir})
	if err := os.WriteFile(settingsPath, settings, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	defer module.Shutdown()

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	listed := requestJSON(t, app, http.MethodGet, "/api/engine/models", "", http.StatusOK)
	modelID := listed["models"].([]interface{})[0].(map[string]interface{})["id"].(string)
	deleted := requestJSON(t, app, http.MethodDelete, "/api/engine/models/"+modelID, "", http.StatusOK)
	if models := deleted["models"].([]interface{}); len(models) != 0 {
		t.Fatalf("remaining models = %#v", models)
	}
	if _, err := os.Stat(bundle); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("model folder should be removed, stat error = %v", err)
	}
}

func TestDeleteMarketplaceGGUFRemovesCompleteRevisionBundle(t *testing.T) {
	t.Setenv("ENGINE_GATEWAY_ADDR", "disabled")
	t.Setenv("ENGINE_RUNTIME_PREWARM", "disabled")
	root := t.TempDir()
	modelDir := filepath.Join(root, "models")
	bundle := filepath.Join(modelDir, "huggingface", "publisher", "model", "commit")
	if err := os.MkdirAll(bundle, 0o755); err != nil {
		t.Fatal(err)
	}
	for name, contents := range map[string]string{
		"model.gguf":              "invalid but catalogued GGUF",
		marketplaceBundleManifest: `{"schema_version":1,"provider":"huggingface"}`,
		"modeling_custom.py":      "VALUE = 1\n",
	} {
		if err := os.WriteFile(filepath.Join(bundle, name), []byte(contents), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	settingsPath := filepath.Join(root, "settings.json")
	settings, _ := json.Marshal(map[string]interface{}{"model_dir": modelDir})
	if err := os.WriteFile(settingsPath, settings, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	defer module.Shutdown()

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	listed := requestJSON(t, app, http.MethodGet, "/api/engine/models", "", http.StatusOK)
	models := listed["models"].([]interface{})
	if len(models) != 1 {
		t.Fatalf("models = %#v", models)
	}
	modelID := models[0].(map[string]interface{})["id"].(string)
	deleted := requestJSON(t, app, http.MethodDelete, "/api/engine/models/"+modelID, "", http.StatusOK)
	if models := deleted["models"].([]interface{}); len(models) != 0 {
		t.Fatalf("remaining models = %#v", models)
	}
	if _, err := os.Stat(bundle); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("marketplace revision folder should be removed, stat error = %v", err)
	}
}

func TestDeleteMarketplaceGGUFKeepsSiblingModelInSharedFolder(t *testing.T) {
	t.Setenv("ENGINE_GATEWAY_ADDR", "disabled")
	t.Setenv("ENGINE_RUNTIME_PREWARM", "disabled")
	root := t.TempDir()
	modelDir := filepath.Join(root, "models")
	bundle := filepath.Join(modelDir, "shared-revision")
	if err := os.MkdirAll(bundle, 0o755); err != nil {
		t.Fatal(err)
	}
	for name, contents := range map[string]string{
		"a.gguf":                  "first catalogued GGUF",
		"b.gguf":                  "second catalogued GGUF",
		marketplaceBundleManifest: `{"schema_version":1}`,
		"notes.txt":               "shared metadata\n",
	} {
		if err := os.WriteFile(filepath.Join(bundle, name), []byte(contents), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	settingsPath := filepath.Join(root, "settings.json")
	settings, _ := json.Marshal(map[string]interface{}{"model_dir": modelDir})
	if err := os.WriteFile(settingsPath, settings, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	defer module.Shutdown()

	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))
	listed := requestJSON(t, app, http.MethodGet, "/api/engine/models", "", http.StatusOK)
	models := listed["models"].([]interface{})
	if len(models) != 2 {
		t.Fatalf("models = %#v", models)
	}
	modelID := ""
	for _, raw := range models {
		model := raw.(map[string]interface{})
		if strings.HasSuffix(model["relative_path"].(string), "a.gguf") {
			modelID = model["id"].(string)
		}
	}
	if modelID == "" {
		t.Fatalf("a.gguf model missing: %#v", models)
	}
	deleted := requestJSON(t, app, http.MethodDelete, "/api/engine/models/"+modelID, "", http.StatusOK)
	if models := deleted["models"].([]interface{}); len(models) != 1 {
		t.Fatalf("remaining models = %#v", models)
	}
	if _, err := os.Stat(filepath.Join(bundle, "a.gguf")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("selected model file should be removed, stat error = %v", err)
	}
	for _, name := range []string{"b.gguf", marketplaceBundleManifest, "notes.txt"} {
		if _, err := os.Stat(filepath.Join(bundle, name)); err != nil {
			t.Fatalf("sibling bundle file %s was removed: %v", name, err)
		}
	}
}

func TestModelDeletionPathsRejectTraversalAndSymlinks(t *testing.T) {
	if _, err := cleanModelRelativePath("../outside.gguf"); err == nil {
		t.Fatal("parent traversal was accepted")
	}
	root := t.TempDir()
	outside := filepath.Join(t.TempDir(), "outside.gguf")
	if err := os.WriteFile(outside, []byte("outside"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(outside, filepath.Join(root, "model.gguf")); err != nil {
		t.Fatal(err)
	}
	rootFS, err := os.OpenRoot(root)
	if err != nil {
		t.Fatal(err)
	}
	defer rootFS.Close()
	if err := rootFS.Mkdir(".philoengine-delete-test.tmp", 0o700); err != nil {
		t.Fatal(err)
	}
	if _, err := stageModelPaths(rootFS, ".philoengine-delete-test.tmp", []string{"model.gguf"}, false); err == nil {
		t.Fatal("catalogue symlink was accepted for deletion")
	}
	contents, err := os.ReadFile(outside)
	if err != nil || string(contents) != "outside" {
		t.Fatalf("outside file changed: contents=%q err=%v", contents, err)
	}
}

func TestCleanupRetriesHiddenModelDeletionStaging(t *testing.T) {
	root := t.TempDir()
	staging := filepath.Join(root, ".philoengine-delete-retry.tmp")
	if err := os.MkdirAll(filepath.Join(staging, "nested"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(staging, "nested", "weights.gguf"), []byte("pending cleanup"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := cleanupStagedModelDeletions(root); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(staging); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("staging cleanup was not retried, stat error = %v", err)
	}
}

func TestStableRouteParamOwnsRequestBytesAfterFiberReusesContext(t *testing.T) {
	app := fiber.New()
	firstStored := ""
	latestStored := ""
	app.Get("/capture/:id", func(c *fiber.Ctx) error {
		latestStored = stableRouteParam(c, "id")
		if firstStored == "" {
			firstStored = latestStored
		}
		return c.SendStatus(http.StatusNoContent)
	})
	for _, id := range []string{"inst_original_identifier", "op_different_identifier"} {
		request := httptest.NewRequest(http.MethodGet, "/capture/"+id, nil)
		response, err := app.Test(request)
		if err != nil {
			t.Fatal(err)
		}
		_ = response.Body.Close()
	}
	if firstStored != "inst_original_identifier" || latestStored != "op_different_identifier" {
		t.Fatalf("stored route IDs changed: first=%q latest=%q", firstStored, latestStored)
	}
}

func TestRemoteCodeConsentIsBoundToCurrentPythonHash(t *testing.T) {
	t.Setenv("ENGINE_GATEWAY_ADDR", "disabled")
	t.Setenv("ENGINE_RUNTIME_PREWARM", "disabled")
	root := t.TempDir()
	modelDir := filepath.Join(root, "models")
	bundle := filepath.Join(modelDir, "custom")
	writeEngineSafeBundle(t, bundle)
	if err := os.WriteFile(filepath.Join(bundle, "modeling_custom.py"), []byte("VALUE = 1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	settingsPath := filepath.Join(root, "settings.json")
	payload, _ := json.Marshal(map[string]string{"model_dir": modelDir})
	if err := os.WriteFile(settingsPath, payload, 0o600); err != nil {
		t.Fatal(err)
	}
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	defer module.Shutdown()
	record := module.models[0]
	config := defaultEngineConfig()
	config.TrustRemoteCode = true
	if err := module.validateRemoteCode(record, config); err == nil {
		t.Fatal("unapproved remote code should be rejected")
	}
	if _, err := module.approveRemoteCode(record.ID); err != nil {
		t.Fatal(err)
	}
	if err := module.validateRemoteCode(record, config); err != nil {
		t.Fatalf("unchanged approved code rejected: %v", err)
	}
	if err := os.WriteFile(filepath.Join(bundle, "modeling_custom.py"), []byte("VALUE = 2\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := module.validateRemoteCode(record, config); err == nil {
		t.Fatal("changed Python code must require renewed consent")
	}
}

func TestEffectiveReserveBytesKeepsExplicitZeroAndRoundsUp(t *testing.T) {
	zero := int64(0)
	if got := effectiveReserveBytes(&zero, 64<<30, 15, 4<<30); got != 0 {
		t.Fatalf("explicit zero reserve = %d", got)
	}
	if got, want := effectiveReserveBytes(nil, 64<<30, 15, 4<<30), int64(10307921511); got != want {
		t.Fatalf("automatic RAM reserve = %d, want %d", got, want)
	}
	if got := effectiveReserveBytes(nil, 2<<30, 15, 4<<30); got != 4<<30 {
		t.Fatalf("reserve floor = %d", got)
	}
}

func requestJSON(t *testing.T, app *fiber.App, method, path, body string, wanted int) map[string]interface{} {
	t.Helper()
	request := httptest.NewRequest(method, path, strings.NewReader(body))
	if body != "" {
		request.Header.Set("Content-Type", "application/json")
	}
	response, err := app.Test(request, 5000)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	var decoded map[string]interface{}
	if err := json.NewDecoder(response.Body).Decode(&decoded); err != nil {
		t.Fatalf("decode %s %s: %v", method, path, err)
	}
	if response.StatusCode != wanted {
		t.Fatalf("%s %s = %d, want %d: %#v", method, path, response.StatusCode, wanted, decoded)
	}
	return decoded
}

func writeEngineSafeBundle(t *testing.T, dir string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	config := map[string]interface{}{
		"model_type": "llama", "architectures": []string{"LlamaForCausalLM"},
		"num_hidden_layers": 4, "num_attention_heads": 8, "num_key_value_heads": 2,
		"hidden_size": 256, "max_position_embeddings": 16384, "torch_dtype": "float16",
	}
	for name, value := range map[string]interface{}{
		"config.json":           config,
		"tokenizer.json":        map[string]interface{}{"version": "1.0"},
		"tokenizer_config.json": map[string]interface{}{"chat_template": "{{ messages }}"},
	} {
		payload, _ := json.Marshal(value)
		if err := os.WriteFile(filepath.Join(dir, name), payload, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	header, _ := json.Marshal(map[string]interface{}{"weight": map[string]interface{}{"dtype": "F16", "shape": []int64{2, 3}, "data_offsets": []int64{0, 12}}})
	if padding := (8 - len(header)%8) % 8; padding > 0 {
		header = append(header, bytes.Repeat([]byte(" "), padding)...)
	}
	var contents bytes.Buffer
	if err := binary.Write(&contents, binary.LittleEndian, uint64(len(header))); err != nil {
		t.Fatal(err)
	}
	contents.Write(header)
	contents.Write(make([]byte, 12))
	if err := os.WriteFile(filepath.Join(dir, "model.safetensors"), contents.Bytes(), 0o600); err != nil {
		t.Fatal(err)
	}
}
