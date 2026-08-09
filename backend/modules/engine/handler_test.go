package engine

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	"github.com/culpeohq/backend/internal/localinference"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// A rejected load has to name the resource it ran out of, otherwise the screen
// can only say that something went wrong.
func TestEngineErrorKeepsLoadPeakConflictActionable(t *testing.T) {
	err := engineErrorStatus(errors.Join(
		localinference.ErrGuardRejected,
		&ResourceConflictError{
			Resource: "gpu:test", RequiredBytes: 15 << 30, AvailableBytes: 14 << 30,
			Reason: "konservativer Lade-Peak unterschreitet die Reserve",
		},
	))

	if status.Code(err) != codes.Unavailable {
		t.Fatalf("code = %v, want Unavailable", status.Code(err))
	}
	message := status.Convert(err).Message()
	for _, want := range []string{"gpu:test", "Lade-Peak"} {
		if !strings.Contains(message, want) {
			t.Fatalf("message %q does not mention %q", message, want)
		}
	}
}

func TestDeleteModelRemovesCataloguedFilesAndEmptyFolder(t *testing.T) {
	t.Setenv("ENGINE_GATEWAY_ADDR", "disabled")
	t.Setenv("ENGINE_RUNTIME_PREWARM", "disabled")
	root := t.TempDir()
	modelDir := filepath.Join(root, "models")
	bundle := filepath.Join(modelDir, "publisher", "removable-model")
	writeEngineModel(t, bundle)
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

	service := &grpcService{module: module}
	modelID := listModelsForTest(t, service)[0].GetId()
	deleted := deleteModelForTest(t, service, modelID)
	if len(deleted) != 0 {
		t.Fatalf("remaining models = %#v", deleted)
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

	service := &grpcService{module: module}
	models := listModelsForTest(t, service)
	if len(models) != 1 {
		t.Fatalf("models = %#v", models)
	}
	modelID := models[0].GetId()
	deleted := deleteModelForTest(t, service, modelID)
	if len(deleted) != 0 {
		t.Fatalf("remaining models = %#v", deleted)
	}
	if _, err := os.Stat(bundle); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("marketplace revision folder should be removed, stat error = %v", err)
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
	if err := rootFS.Mkdir(".culpeostudio-delete-test.tmp", 0o700); err != nil {
		t.Fatal(err)
	}
	if _, err := stageModelPaths(rootFS, ".culpeostudio-delete-test.tmp", []string{"model.gguf"}, false); err == nil {
		t.Fatal("catalogue symlink was accepted for deletion")
	}
	contents, err := os.ReadFile(outside)
	if err != nil || string(contents) != "outside" {
		t.Fatalf("outside file changed: contents=%q err=%v", contents, err)
	}
}

func TestCleanupRetriesHiddenModelDeletionStaging(t *testing.T) {
	root := t.TempDir()
	staging := filepath.Join(root, ".culpeostudio-delete-retry.tmp")
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

// writeEngineModel lays down a minimal but structurally valid GGUF file so the
// catalogue reports a startable model with real KV architecture metadata.
func writeEngineModel(t *testing.T, dir string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	type metadataEntry struct {
		key       string
		valueType uint32
		value     any
	}
	const (
		ggufTypeUint32 uint32 = 4
		ggufTypeString uint32 = 8
	)
	entries := []metadataEntry{
		{"general.architecture", ggufTypeString, "llama"},
		{"general.name", ggufTypeString, "engine-test"},
		{"general.file_type", ggufTypeUint32, uint32(15)},
		{"llama.block_count", ggufTypeUint32, uint32(4)},
		{"llama.attention.head_count", ggufTypeUint32, uint32(8)},
		{"llama.attention.head_count_kv", ggufTypeUint32, uint32(2)},
		{"llama.embedding_length", ggufTypeUint32, uint32(256)},
		{"llama.context_length", ggufTypeUint32, uint32(16384)},
	}
	var contents bytes.Buffer
	contents.WriteString("GGUF")
	for _, value := range []any{uint32(3), uint64(1), uint64(len(entries))} {
		if err := binary.Write(&contents, binary.LittleEndian, value); err != nil {
			t.Fatal(err)
		}
	}
	writeString := func(value string) {
		if err := binary.Write(&contents, binary.LittleEndian, uint64(len(value))); err != nil {
			t.Fatal(err)
		}
		contents.WriteString(value)
	}
	for _, entry := range entries {
		writeString(entry.key)
		if err := binary.Write(&contents, binary.LittleEndian, entry.valueType); err != nil {
			t.Fatal(err)
		}
		if entry.valueType == ggufTypeString {
			writeString(entry.value.(string))
			continue
		}
		if err := binary.Write(&contents, binary.LittleEndian, entry.value); err != nil {
			t.Fatal(err)
		}
	}
	writeString("weight")
	for _, value := range []any{uint32(2), uint64(2), uint64(3), uint32(0), uint64(0)} {
		if err := binary.Write(&contents, binary.LittleEndian, value); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(dir, "model.gguf"), contents.Bytes(), 0o600); err != nil {
		t.Fatal(err)
	}
}

func listModelsForTest(t *testing.T, service *grpcService) []*enginev1.ModelRecord {
	t.Helper()
	response, err := service.ListModels(context.Background(), &enginev1.ListModelsRequest{})
	if err != nil {
		t.Fatalf("ListModels failed: %v", err)
	}
	return response.GetModels()
}

func deleteModelForTest(t *testing.T, service *grpcService, modelID string) []*enginev1.ModelRecord {
	t.Helper()
	response, err := service.DeleteModel(context.Background(), &enginev1.DeleteModelRequest{ModelId: modelID})
	if err != nil {
		t.Fatalf("DeleteModel failed: %v", err)
	}
	return response.GetModels()
}
