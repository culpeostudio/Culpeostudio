// Package providerconn stores and talks to user-configured AI provider
// connections.  It is deliberately independent of a UI or gRPC schema so
// Scout and the ProviderService can share the same guarded implementation.
package providerconn

import (
	"encoding/base64"
	"strings"
	"time"
)

const (
	ProtocolOpenAICompatible = "openai_compatible"
	ProtocolAnthropic        = "anthropic_messages"
	ProtocolGoogleGenAI      = "google_genai"

	CustomPresetID = "custom_openai_compatible"
)

// Preset describes a maintained integration.  A custom OpenAI-compatible
// preset covers providers outside this curated list without creating a new
// backend release for each vendor.
type Preset struct {
	ID                string
	Name              string
	Description       string
	Protocol          string
	DefaultBaseURL    string
	DocumentationURL  string
	APIKeyRequired    bool
	Available         bool
	UnavailableReason string
	LocalOnly         bool
}

// Model is provider-supplied metadata normalized for the model picker.  The
// source catalogue differs widely between vendors, so absent values stay zero
// or empty rather than being invented.
type Model struct {
	ID               string    `json:"id"`
	DisplayName      string    `json:"display_name"`
	Description      string    `json:"description,omitempty"`
	ContextWindow    int       `json:"context_window,omitempty"`
	MaxOutputTokens  int       `json:"max_output_tokens,omitempty"`
	InputModalities  []string  `json:"input_modalities,omitempty"`
	OutputModalities []string  `json:"output_modalities,omitempty"`
	Capabilities     []string  `json:"capabilities,omitempty"`
	ChatSupported    bool      `json:"chat_supported"`
	Deprecated       bool      `json:"deprecated,omitempty"`
	DiscoveredAt     time.Time `json:"discovered_at"`
}

// Connection is a backend-only configuration.  APIKey is never JSON encoded;
// the store persists an encrypted representation in a private file instead.
type Connection struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	PresetID      string    `json:"preset_id"`
	Name          string    `json:"name"`
	Protocol      string    `json:"protocol"`
	BaseURL       string    `json:"base_url"`
	APIKey        string    `json:"-"`
	APIKeySet     bool      `json:"api_key_set"`
	Enabled       bool      `json:"enabled"`
	Models        []Model   `json:"models"`
	LastSyncedAt  time.Time `json:"last_synced_at"`
	LastSyncError string    `json:"last_sync_error,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// ActiveModel is intentionally a separate decision from a discovered model:
// discovery is free metadata traffic; selecting a model can incur API cost.
type ActiveModel struct {
	ModelRef      string    `json:"model_ref"`
	ConnectionID  string    `json:"connection_id"`
	ProviderLabel string    `json:"provider_label"`
	ProviderID    string    `json:"provider_id"`
	ModelID       string    `json:"model_id"`
	DisplayName   string    `json:"display_name"`
	Protocol      string    `json:"protocol"`
	ActivatedAt   time.Time `json:"activated_at"`
	LastUsedAt    time.Time `json:"last_used_at"`
}

// ConnectionInput is the write-only part of a connection.  Nil APIKey means
// "leave it unchanged"; ClearAPIKey wins when the user explicitly removes it.
type ConnectionInput struct {
	ID          string
	PresetID    string
	Name        string
	Protocol    string
	BaseURL     string
	APIKey      *string
	ClearAPIKey bool
	Enabled     bool
}

// PublicConnection is safe to return from a service.  It deliberately has no
// Secret/APIKey field.
type PublicConnection struct {
	ID            string
	PresetID      string
	Name          string
	Protocol      string
	BaseURL       string
	APIKeySet     bool
	Enabled       bool
	ModelCount    int
	LastSyncedAt  time.Time
	LastSyncError string
	ChatSupported bool
	Stale         bool
	ProviderLabel string
}

func NormalizeProtocol(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case ProtocolOpenAICompatible:
		return ProtocolOpenAICompatible
	case ProtocolAnthropic:
		return ProtocolAnthropic
	case ProtocolGoogleGenAI:
		return ProtocolGoogleGenAI
	default:
		return ""
	}
}

func IsChatProtocol(protocol string) bool {
	switch NormalizeProtocol(protocol) {
	case ProtocolOpenAICompatible, ProtocolAnthropic, ProtocolGoogleGenAI:
		return true
	default:
		return false
	}
}

func ModelRef(connectionID, modelID string) string {
	connectionID = strings.TrimSpace(connectionID)
	modelID = strings.TrimSpace(modelID)
	if connectionID == "" || modelID == "" {
		return ""
	}
	// The colon separates the connection id from an URL-safe model id.  The
	// connection id itself is generated locally and contains no colon.
	return "connection_" + connectionID + ":" + base64.RawURLEncoding.EncodeToString([]byte(modelID))
}

func Public(connection Connection, now time.Time) PublicConnection {
	lastSynced := connection.LastSyncedAt
	stale := !lastSynced.IsZero() && now.Sub(lastSynced) > 6*time.Hour
	return PublicConnection{
		ID:            connection.ID,
		PresetID:      connection.PresetID,
		Name:          connection.Name,
		Protocol:      connection.Protocol,
		BaseURL:       connection.BaseURL,
		APIKeySet:     connection.APIKeySet,
		Enabled:       connection.Enabled,
		ModelCount:    len(connection.Models),
		LastSyncedAt:  connection.LastSyncedAt,
		LastSyncError: connection.LastSyncError,
		ChatSupported: IsChatProtocol(connection.Protocol),
		Stale:         stale,
		ProviderLabel: connection.Name,
	}
}
