package scout

import (
	"net/http"
	"path/filepath"
	"strings"
	"testing"

	scoutv1 "github.com/culpeohq/backend/gen/go/culpeostudio/scout/v1"
	"github.com/culpeohq/backend/internal/providerconn"
	"github.com/culpeohq/backend/modules/scout/bots"
)

// TestConfiguredSessionUsesConnectionMetadata verifies that a chat session
// bound to a user-configured provider connection carries that connection's
// identity through session creation and history, independent of any actual
// network call. No shipped preset permits a loopback BaseURL, so this can no
// longer route a real HTTP round trip through an httptest server; the
// streaming/parsing behavior itself is covered by TestConfiguredProviderNativeStreamReaders,
// readOpenAIStream's own tests, and TestConfiguredProviderHTTPErrorDetail below.
func TestConfiguredSessionUsesConnectionMetadata(t *testing.T) {
	manager := configuredTestManager(t)
	connection := configuredTestConnection(t, manager, "test-key-that-must-not-leak")
	active, err := manager.ActivateModel("alice", connection.ID, "configured-model", "Configured Model")
	if err != nil {
		t.Fatalf("ActivateModel: %v", err)
	}

	module := newTestModule(t, filepath.Join(t.TempDir(), "settings.json"))
	module.SetProviderConnections(manager)
	service := newTestService(t, module)
	created, err := service.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{
		ConnectionId: connection.ID,
		ModelId:      "configured-model",
	})
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if created.GetConnectionId() != connection.ID || created.GetModelRef() != active.ModelRef {
		t.Fatalf("configured session = %+v, active = %+v", created, active)
	}

	history, err := service.GetHistory(userContext("alice"), &scoutv1.GetHistoryRequest{SessionId: created.GetSessionId()})
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if history.GetConnectionId() != connection.ID || history.GetProvider() != connection.Name {
		t.Fatalf("configured connection was not retained in history: %+v", history)
	}
}

// TestConfiguredProviderHTTPErrorDetail guards the same property the old
// end-to-end TestConfiguredProviderErrorDoesNotExposeAPIKey checked over a
// real HTTP response: a rejected provider request must never surface the raw
// response body (which can echo an API key or request contents) back to the
// Scout stream. configuredProviderHTTPDetail is the sole source of that
// user-facing text and takes only a status code, so it structurally cannot
// leak response content - this checks every status code branch it defines.
func TestConfiguredProviderHTTPErrorDetail(t *testing.T) {
	const leakedSecret = "secret-never-in-stream"
	for _, test := range []struct {
		statusCode int
		want       string
	}{
		{http.StatusUnauthorized, "API-Key wurde abgelehnt. Bitte die Provider-Verbindung in den Einstellungen prüfen."},
		{http.StatusForbidden, "API-Key wurde abgelehnt. Bitte die Provider-Verbindung in den Einstellungen prüfen."},
		{http.StatusNotFound, "Modell oder Chat-Endpunkt wurde nicht gefunden. Bitte den Provider-Katalog synchronisieren."},
		{http.StatusTooManyRequests, "Rate-Limit des Anbieters erreicht. Bitte später erneut versuchen."},
		{http.StatusInternalServerError, "Provider antwortet mit HTTP 500"},
	} {
		got := configuredProviderHTTPDetail(test.statusCode)
		if got != test.want {
			t.Fatalf("configuredProviderHTTPDetail(%d) = %q, want %q", test.statusCode, got, test.want)
		}
		if strings.Contains(got, leakedSecret) {
			t.Fatalf("configuredProviderHTTPDetail(%d) leaked a secret: %q", test.statusCode, got)
		}
	}
}

func TestConfiguredProviderNativeStreamReaders(t *testing.T) {
	t.Run("anthropic", func(t *testing.T) {
		var got strings.Builder
		reply, _, err := readAnthropicStream(strings.NewReader("data: {\"type\":\"content_block_delta\",\"delta\":{\"text\":\"Hallo\"}}\n\ndata: {\"type\":\"content_block_delta\",\"delta\":{\"text\":\" Welt\"}}\n\ndata: {\"type\":\"message_stop\"}\n\n"), func(chunk string) error {
			_, writeErr := got.WriteString(chunk)
			return writeErr
		}, nil)
		if err != nil || reply != "Hallo Welt" || got.String() != reply {
			t.Fatalf("reply=%q emitted=%q err=%v", reply, got.String(), err)
		}
	})
	t.Run("gemini", func(t *testing.T) {
		var got strings.Builder
		reply, _, err := readGeminiStream(strings.NewReader("data: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"Hallo\"}]}}]}\n\ndata: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\" Welt\"}]}}]}\n\n"), func(chunk string) error {
			_, writeErr := got.WriteString(chunk)
			return writeErr
		}, nil)
		if err != nil || reply != "Hallo Welt" || got.String() != reply {
			t.Fatalf("reply=%q emitted=%q err=%v", reply, got.String(), err)
		}
	})
}

func configuredTestManager(t *testing.T) *providerconn.Manager {
	t.Helper()
	manager, err := providerconn.NewManager(filepath.Join(t.TempDir(), "provider_connections.json"), "test-provider-secret")
	if err != nil {
		t.Fatalf("NewManager: %v", err)
	}
	return manager
}

func configuredTestConnection(t *testing.T, manager *providerconn.Manager, apiKey string) providerconn.Connection {
	t.Helper()
	// No shipped preset permits a loopback BaseURL, so this can no longer
	// point at a local httptest server; the custom preset needs only a
	// syntactically valid public HTTPS endpoint, which is never dialed here.
	connection, err := manager.SaveConnection("alice", providerconn.ConnectionInput{
		PresetID: providerconn.CustomPresetID,
		Name:     "Configured Test Provider",
		Protocol: providerconn.ProtocolOpenAICompatible,
		BaseURL:  "https://configured-test-provider.example/v1",
		APIKey:   &apiKey,
		Enabled:  true,
	})
	if err != nil {
		t.Fatalf("SaveConnection: %v", err)
	}
	if _, err := manager.SetSyncResult("alice", connection.ID, []providerconn.Model{{
		ID: "configured-model", DisplayName: "Configured Model", ChatSupported: true,
	}}, nil); err != nil {
		t.Fatalf("SetSyncResult: %v", err)
	}
	return connection
}

func TestConfiguredDynamicBotBindingNormalizesConnectionReference(t *testing.T) {
	binding, err := bots.NormalizeModelBinding(&bots.ModelBinding{
		Kind:         "api",
		ConnectionID: "pc_example",
		ModelID:      "configured-model",
	})
	if err != nil {
		t.Fatalf("NormalizeModelBinding: %v", err)
	}
	if want := providerconn.ModelRef("pc_example", "configured-model"); binding.ModelRef != want {
		t.Fatalf("ModelRef = %q, want %q", binding.ModelRef, want)
	}
}
