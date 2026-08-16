package providerconn

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestManagerEncryptsAndRedactsAPIKeys(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "private", "provider_connections.json")
	manager, err := NewManager(path, "test-server-secret")
	if err != nil {
		t.Fatalf("NewManager() error = %v", err)
	}
	apiKey := "super-secret-provider-key"
	saved, err := manager.SaveConnection("User-A", ConnectionInput{
		PresetID: CustomPresetID,
		Name:     "Private test provider",
		Protocol: ProtocolOpenAICompatible,
		BaseURL:  "https://models.example.test/v1",
		APIKey:   &apiKey,
		Enabled:  true,
	})
	if err != nil {
		t.Fatalf("SaveConnection() error = %v", err)
	}
	if saved.APIKey != "" || !saved.APIKeySet {
		t.Fatalf("SaveConnection() exposed or lost the API key: %#v", saved)
	}

	payload, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile() error = %v", err)
	}
	if strings.Contains(string(payload), apiKey) {
		t.Fatal("provider store contains the API key in plaintext")
	}
	if !strings.Contains(string(payload), "secret_ciphertext") {
		t.Fatal("provider store did not persist encrypted secret material")
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("Stat() error = %v", err)
	}
	if got, want := info.Mode().Perm(), os.FileMode(0o600); got != want {
		t.Fatalf("provider store mode = %o, want %o", got, want)
	}

	connections, err := manager.ListConnections("user-a")
	if err != nil {
		t.Fatalf("ListConnections() error = %v", err)
	}
	if len(connections) != 1 || connections[0].APIKey != "" || !connections[0].APIKeySet {
		t.Fatalf("ListConnections() did not redact key: %#v", connections)
	}

	trusted, err := manager.GetConnection("USER-A", saved.ID)
	if err != nil {
		t.Fatalf("GetConnection() error = %v", err)
	}
	if trusted.APIKey != apiKey {
		t.Fatalf("GetConnection() key = %q, want original key", trusted.APIKey)
	}

	reloaded, err := NewManager(path, "test-server-secret")
	if err != nil {
		t.Fatalf("NewManager(reload) error = %v", err)
	}
	trusted, err = reloaded.GetConnection("user-a", saved.ID)
	if err != nil {
		t.Fatalf("GetConnection(reload) error = %v", err)
	}
	if trusted.APIKey != apiKey {
		t.Fatalf("GetConnection(reload) key = %q, want original key", trusted.APIKey)
	}

	wrongSecret, err := NewManager(path, "different-server-secret")
	if err != nil {
		t.Fatalf("NewManager(wrong secret) error = %v", err)
	}
	if _, err := wrongSecret.GetConnection("user-a", saved.ID); err == nil {
		t.Fatal("GetConnection() with a different encryption secret unexpectedly succeeded")
	}
}

func TestChangingProviderTargetClearsExistingAPIKey(t *testing.T) {
	t.Parallel()

	manager, err := NewManager(filepath.Join(t.TempDir(), "provider_connections.json"), "test-server-secret")
	if err != nil {
		t.Fatalf("NewManager() error = %v", err)
	}
	apiKey := "old-provider-key"
	created, err := manager.SaveConnection("user", ConnectionInput{
		PresetID: CustomPresetID,
		Name:     "Initial provider",
		Protocol: ProtocolOpenAICompatible,
		BaseURL:  "https://initial.example.test/v1",
		APIKey:   &apiKey,
		Enabled:  true,
	})
	if err != nil {
		t.Fatalf("SaveConnection(create) error = %v", err)
	}
	if _, err := manager.SetSyncResult("user", created.ID, []Model{{ID: "old", ChatSupported: true}}, nil); err != nil {
		t.Fatalf("SetSyncResult() error = %v", err)
	}

	changed, err := manager.SaveConnection("user", ConnectionInput{
		ID:       created.ID,
		PresetID: "openai",
		Name:     "OpenAI",
		BaseURL:  "https://api.openai.com/v1",
		Enabled:  true,
	})
	if err != nil {
		t.Fatalf("SaveConnection(change target) error = %v", err)
	}
	if changed.APIKeySet || len(changed.Models) != 0 {
		t.Fatalf("target change retained credential or stale models: %#v", changed)
	}
	trusted, err := manager.GetConnection("user", created.ID)
	if err != nil {
		t.Fatalf("GetConnection() error = %v", err)
	}
	if trusted.APIKey != "" || len(trusted.Models) != 0 {
		t.Fatalf("target change retained protected state: %#v", trusted)
	}
}

func TestValidateURLsBlocksNonPublicTargets(t *testing.T) {
	t.Parallel()

	custom, ok := FindPreset(CustomPresetID)
	if !ok {
		t.Fatal("custom preset is missing")
	}
	cloud, ok := FindPreset("openai")
	if !ok {
		t.Fatal("OpenAI preset is missing")
	}
	// No shipped preset is LocalOnly. This literal stands in for a
	// hypothetical one so the loopback-allow branch stays covered.
	localOnly := Preset{ID: "test-local-only", LocalOnly: true}

	for _, test := range []struct {
		name   string
		raw    string
		preset Preset
		wantOK bool
	}{
		{name: "cloud loopback", raw: "http://127.0.0.1:8080/v1", preset: cloud},
		{name: "private IPv4", raw: "https://10.1.2.3/v1", preset: custom},
		{name: "carrier grade NAT", raw: "https://100.64.0.1/v1", preset: custom},
		{name: "documentation range", raw: "https://192.0.2.42/v1", preset: custom},
		{name: "external HTTP", raw: "http://8.8.8.8/v1", preset: custom},
		{name: "query injection", raw: "https://8.8.8.8/v1?target=internal", preset: custom},
		{name: "LocalOnly preset loopback", raw: "http://127.0.0.1:11434/", preset: localOnly, wantOK: true},
		{name: "public HTTPS", raw: "https://8.8.8.8/v1", preset: custom, wantOK: true},
	} {
		t.Run(test.name, func(t *testing.T) {
			_, err := validateBaseURL(test.raw, test.preset)
			if (err == nil) != test.wantOK {
				t.Fatalf("validateBaseURL(%q) error = %v, wantOK = %v", test.raw, err, test.wantOK)
			}
		})
	}

	for _, raw := range []string{
		"http://10.1.2.3/metadata",
		"http://169.254.169.254/latest/meta-data",
		"http://100.64.0.1/internal",
		"http://192.0.2.42/test",
		"http://127.0.0.1:11434/api/tags",
		"file:///etc/passwd",
	} {
		if err := ValidateOutboundURL(context.Background(), raw); err == nil {
			t.Fatalf("ValidateOutboundURL(%q) unexpectedly allowed a non-public target", raw)
		}
	}
	// No shipped preset is LocalOnly, so ValidateConnectionOutboundURL must
	// reject loopback for every known and unknown preset ID alike.
	if err := ValidateConnectionOutboundURL(context.Background(), Connection{PresetID: "openai"}, "http://127.0.0.1:11434/api/tags"); err == nil {
		t.Fatal("ValidateConnectionOutboundURL(known non-local preset) unexpectedly allowed loopback")
	}
	if err := ValidateConnectionOutboundURL(context.Background(), Connection{PresetID: CustomPresetID}, "http://127.0.0.1:11434/v1/models"); err == nil {
		t.Fatal("ValidateConnectionOutboundURL(custom loopback) unexpectedly succeeded")
	}
	if err := ValidateConnectionOutboundURL(context.Background(), Connection{PresetID: "unknown-preset"}, "http://127.0.0.1:11434/api/tags"); err == nil {
		t.Fatal("ValidateConnectionOutboundURL(unknown preset) unexpectedly allowed loopback")
	}
	// The allow-loopback branch itself (used only by a hypothetical LocalOnly
	// preset) is exercised directly, since no shipped preset reaches it.
	if err := validateOutboundURL(context.Background(), "http://127.0.0.1:11434/api/tags", true); err != nil {
		t.Fatalf("validateOutboundURL(allowLoopback=true) error = %v", err)
	}
	if err := ValidateOutboundURL(context.Background(), "https://8.8.8.8/v1/models"); err != nil {
		t.Fatalf("ValidateOutboundURL(public IP) error = %v", err)
	}
}

func TestDiscoverOpenAICompatibleModels(t *testing.T) {
	t.Parallel()

	// This exercises the OpenAI-compatible catalogue normalization directly,
	// without a live HTTP round trip: no shipped preset permits a loopback
	// destination, so a test server can no longer stand in for a provider.
	models, err := normalizeGenericModelList([]byte(`{
  "data": [
    {
      "id": "chat-alpha",
      "display_name": "Chat Alpha",
      "context_length": "128000",
      "max_completion_tokens": 4096,
      "capabilities": {"completion_chat": true, "vision": {"enabled": true}},
      "architecture": {"input_modalities": "text", "output_modalities": ["text"]}
    },
    {"id": "embedding-small", "displayName": "Embedding Small", "capabilities": ["embeddings"]},
    {"id": "old-model", "display_name": "Old Model", "archived": "true"}
  ]
}`), true)
	if err != nil {
		t.Fatalf("normalizeGenericModelList() error = %v", err)
	}
	if len(models) != 3 {
		t.Fatalf("DiscoverModels() count = %d, want 3: %#v", len(models), models)
	}
	if models[0].ID != "chat-alpha" || !models[0].ChatSupported {
		t.Fatalf("first model = %#v, want sorted supported chat model", models[0])
	}
	if models[0].ContextWindow != 128000 || models[0].MaxOutputTokens != 4096 {
		t.Fatalf("chat model token limits = %#v", models[0])
	}
	if !contains(models[0].Capabilities, "completion_chat") || !contains(models[0].Capabilities, "vision") {
		t.Fatalf("chat model capabilities = %#v", models[0].Capabilities)
	}
	if !contains(models[0].InputModalities, "text") || !contains(models[0].OutputModalities, "text") {
		t.Fatalf("chat model modalities = in:%#v out:%#v", models[0].InputModalities, models[0].OutputModalities)
	}

	byID := make(map[string]Model, len(models))
	for _, model := range models {
		byID[model.ID] = model
	}
	if byID["embedding-small"].ChatSupported {
		t.Fatalf("embedding model should not be offered for chat: %#v", byID["embedding-small"])
	}
	if !byID["old-model"].Deprecated || byID["old-model"].ChatSupported {
		t.Fatalf("archived model should be deprecated and non-chat: %#v", byID["old-model"])
	}
}

func TestDiscoverGeminiPaginatesCurrentModels(t *testing.T) {
	t.Parallel()

	// This exercises parseGeminiModelsPage's per-page parsing and pagination
	// token directly, without a live HTTP round trip: no shipped preset
	// permits a loopback destination, so a test server can no longer stand in
	// for a provider. discoverGemini's own request-building loop still calls
	// this same helper for each page.
	now := time.Now().UTC()
	firstPage, nextToken, err := parseGeminiModelsPage([]byte(`{"models":[{"name":"models/gemini-first","displayName":"Gemini First","supportedGenerationMethods":["generateContent"]}],"nextPageToken":"second"}`), now)
	if err != nil {
		t.Fatalf("parseGeminiModelsPage(first) error = %v", err)
	}
	if nextToken != "second" {
		t.Fatalf("parseGeminiModelsPage(first) nextToken = %q, want %q", nextToken, "second")
	}
	secondPage, nextToken, err := parseGeminiModelsPage([]byte(`{"models":[{"name":"models/gemini-second","displayName":"Gemini Second","supportedGenerationMethods":["generateContent"]}]}`), now)
	if err != nil {
		t.Fatalf("parseGeminiModelsPage(second) error = %v", err)
	}
	if nextToken != "" {
		t.Fatalf("parseGeminiModelsPage(second) nextToken = %q, want empty", nextToken)
	}
	models := deduplicateAndSortModels(append(firstPage, secondPage...))
	if len(models) != 2 || models[0].ID != "gemini-first" || models[1].ID != "gemini-second" {
		t.Fatalf("merged models = %#v, want both pages", models)
	}
}

func TestProviderURLHelpersAndStreamingClient(t *testing.T) {
	t.Parallel()

	for _, test := range []struct {
		name string
		got  func() (string, error)
		want string
	}{
		{name: "OpenAI chat", got: func() (string, error) { return ChatCompletionsURL("https://api.example.test/v1") }, want: "https://api.example.test/v1/chat/completions"},
		{name: "Anthropic messages", got: func() (string, error) { return AnthropicMessagesURL("https://api.example.test") }, want: "https://api.example.test/v1/messages"},
		{name: "Gemini stream", got: func() (string, error) { return GeminiStreamURL("https://api.example.test", "models/gemini-2.5-flash") }, want: "https://api.example.test/v1beta/models/gemini-2.5-flash:streamGenerateContent"},
	} {
		t.Run(test.name, func(t *testing.T) {
			got, err := test.got()
			if err != nil || got != test.want {
				t.Fatalf("URL helper = (%q, %v), want (%q, nil)", got, err, test.want)
			}
		})
	}
	if _, err := GeminiStreamURL("https://api.example.test", "models/not/allowed"); err == nil {
		t.Fatal("GeminiStreamURL() accepted a model path separator")
	}
	if timeout := NewStreamingHTTPClient().Timeout; timeout != 0 {
		t.Fatalf("NewStreamingHTTPClient().Timeout = %v, want 0", timeout)
	}
	if timeout := NewHTTPClient().Timeout; timeout != providerRequestTimeout {
		t.Fatalf("NewHTTPClient().Timeout = %v, want %v", timeout, providerRequestTimeout)
	}
}

func TestPresetsKeepQwenPlanNextToModelStudio(t *testing.T) {
	t.Parallel()

	list := Presets()
	modelStudio := -1
	codingPlan := -1
	for index, preset := range list {
		switch preset.ID {
		case "qwen_model_studio":
			modelStudio = index
		case "qwen_coding_plan":
			codingPlan = index
		}
	}
	if modelStudio == -1 || codingPlan != modelStudio+1 {
		t.Fatalf("Qwen preset order = Model Studio %d, Coding Plan %d; they must be adjacent", modelStudio, codingPlan)
	}
	list[modelStudio].Name = "mutated copy"
	preset, ok := FindPreset("qwen_model_studio")
	if !ok || preset.Name == "mutated copy" {
		t.Fatal("Presets() returned mutable backing storage")
	}
}

func TestLoadDropsConnectionsForMarketplaceVendors(t *testing.T) {
	t.Parallel()

	if _, ok := FindPreset("openrouter"); ok {
		t.Fatal("OpenRouter must not be connectable here; it is a built-in Marketplace source")
	}

	path := filepath.Join(t.TempDir(), "provider_connections.json")
	stored := `{"schema_version":1,"users":{"local":{"connections":[
		{"id":"retired","preset_id":"openrouter","name":"OpenRouter","protocol":"openai_compatible","base_url":"https://openrouter.ai/api/v1","enabled":true},
		{"id":"kept","preset_id":"custom_openai_compatible","name":"Eigener Endpunkt","protocol":"openai_compatible","base_url":"https://models.example.test/v1","enabled":true}
	],"active_models":[
		{"model_ref":"connection_retired:abc","connection_id":"retired","model_id":"openai/gpt-4o","display_name":"GPT-4o"}
	]}}}`
	if err := os.WriteFile(path, []byte(stored), 0o600); err != nil {
		t.Fatalf("WriteFile() error = %v", err)
	}

	manager, err := NewManager(path, "test-server-secret")
	if err != nil {
		t.Fatalf("NewManager() error = %v", err)
	}
	connections, err := manager.ListConnections("local")
	if err != nil {
		t.Fatalf("ListConnections() error = %v", err)
	}
	if len(connections) != 1 || connections[0].ID != "kept" {
		t.Fatalf("ListConnections() = %#v, want only the custom connection", connections)
	}

	active, err := manager.ListActiveModels("local")
	if err != nil {
		t.Fatalf("ListActiveModels() error = %v", err)
	}
	if len(active) != 0 {
		t.Fatalf("ListActiveModels() = %#v, want no models from the retired connection", active)
	}
}

func contains(values []string, expected string) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
}
