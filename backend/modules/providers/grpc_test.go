package providers

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	providersv1 "github.com/culpeohq/backend/gen/go/culpeostudio/providers/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/providerconn"
)

func TestProviderConnectionIsUserScopedEncryptedAndActivatable(t *testing.T) {
	t.Parallel()

	const apiKeyValue = "sk-test-provider-key-must-not-be-persisted-plain"
	apiKey := apiKeyValue

	settingsFile := filepath.Join(t.TempDir(), "settings.json")
	module := New(settingsFile, "test encryption secret")
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize: %v", err)
	}
	t.Cleanup(func() { _ = module.Shutdown() })
	service := &grpcService{module: module}
	alice := grpcmw.ContextWithUserForTest(context.Background(), "Alice", "Alice")
	bob := grpcmw.ContextWithUserForTest(context.Background(), "Bob", "Bob")

	// No shipped preset permits a loopback BaseURL, so this saves without
	// syncing (SyncModels: false never dials out) and seeds the catalogue
	// directly through the manager, exactly as SyncModels: true would have
	// stored it after a real discovery call.
	saved, err := service.SaveConnection(alice, &providersv1.SaveConnectionRequest{
		PresetId:   "openai",
		Name:       "Test-Anbieter",
		Protocol:   providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_OPENAI_COMPATIBLE,
		BaseUrl:    "https://provider-connection-test.example/v1",
		ApiKey:     &apiKey,
		Enabled:    true,
		SyncModels: false,
	})
	if err != nil {
		t.Fatalf("SaveConnection: %v", err)
	}
	if saved.GetConnection().GetId() == "" || !saved.GetConnection().GetApiKeySet() {
		t.Fatalf("redacted connection missing expected metadata: %#v", saved.GetConnection())
	}
	if strings.Contains(saved.String(), apiKey) {
		t.Fatal("SaveConnection response exposed the API key")
	}
	if _, err := module.Manager().SetSyncResult("Alice", saved.GetConnection().GetId(), []providerconn.Model{
		{ID: "example/chat", DisplayName: "Example Chat", ContextWindow: 128000, ChatSupported: true},
	}, nil); err != nil {
		t.Fatalf("SetSyncResult: %v", err)
	}

	stored, err := os.ReadFile(filepath.Join(filepath.Dir(settingsFile), "provider_connections.json"))
	if err != nil {
		t.Fatalf("read encrypted store: %v", err)
	}
	if strings.Contains(string(stored), apiKey) {
		t.Fatal("provider connection store contains plaintext API key")
	}

	bobConnections, err := service.ListConnections(bob, &providersv1.ListConnectionsRequest{})
	if err != nil {
		t.Fatalf("ListConnections as another user: %v", err)
	}
	if len(bobConnections.GetConnections()) != 0 {
		t.Fatalf("other user received Alice's connection: %#v", bobConnections.GetConnections())
	}

	activated, err := service.ActivateModel(alice, &providersv1.ActivateModelRequest{
		ConnectionId: saved.GetConnection().GetId(),
		ModelId:      "example/chat",
	})
	if err != nil {
		t.Fatalf("ActivateModel: %v", err)
	}
	if activated.GetModel().GetConnectionId() != saved.GetConnection().GetId() || activated.GetModel().GetModelRef() == "" {
		t.Fatalf("unexpected active model: %#v", activated.GetModel())
	}

	active, err := service.ListActiveModels(alice, &providersv1.ListActiveModelsRequest{})
	if err != nil {
		t.Fatalf("ListActiveModels: %v", err)
	}
	if len(active.GetModels()) != 1 || active.GetModels()[0].GetModelRef() != activated.GetModel().GetModelRef() {
		t.Fatalf("active model was not retained: %#v", active.GetModels())
	}
}

func TestQwenCodingPlanIsAvailableForOwnCredentials(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"), "test encryption secret")
	service := &grpcService{module: module}
	response, err := service.ListPresets(context.Background(), &providersv1.ListPresetsRequest{})
	if err != nil {
		t.Fatalf("ListPresets: %v", err)
	}
	for _, preset := range response.GetPresets() {
		if preset.GetId() != "qwen_coding_plan" {
			continue
		}
		if !preset.GetAvailable() || strings.TrimSpace(preset.GetUnavailableReason()) != "" {
			t.Fatalf("Coding Plan should be connectable with the user's own credentials: %#v", preset)
		}
		return
	}
	t.Fatal("Qwen Coding Plan preset is missing")
}
