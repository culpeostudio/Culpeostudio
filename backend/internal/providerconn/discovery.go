package providerconn

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"net"
	"net/http"
	"net/netip"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

const (
	providerRequestTimeout = 30 * time.Second
	maxProviderBodyBytes   = 2 << 20
	maxCatalogPages        = 10
)

// NewHTTPClient creates a client suitable for user-configurable endpoints.
// Redirects are deliberately not followed: a safe public URL must not be able
// to bounce the backend into a private network.
func NewHTTPClient() *http.Client {
	return newProviderHTTPClient(providerRequestTimeout, false)
}

// NewStreamingHTTPClient uses the same DNS-rebinding and SSRF safeguards as
// NewHTTPClient, but leaves response lifetime to the request context. A model
// response stream may legitimately outlive the catalogue request timeout.
func NewStreamingHTTPClient() *http.Client {
	return newProviderHTTPClient(0, false)
}

// NewHTTPClientForConnection uses the same guarded transport as NewHTTPClient
// while permitting loopback only for an explicit LocalOnly preset.
func NewHTTPClientForConnection(connection Connection) *http.Client {
	return newProviderHTTPClient(providerRequestTimeout, connectionAllowsLoopback(connection))
}

// NewStreamingHTTPClientForConnection is the streaming counterpart of
// NewHTTPClientForConnection. It intentionally leaves response lifetime to
// the request context so a legitimate model stream can outlive metadata
// discovery without weakening the destination policy.
func NewStreamingHTTPClientForConnection(connection Connection) *http.Client {
	return newProviderHTTPClient(0, connectionAllowsLoopback(connection))
}

func connectionAllowsLoopback(connection Connection) bool {
	preset, known := FindPreset(connection.PresetID)
	return known && preset.LocalOnly
}

func newProviderHTTPClient(timeout time.Duration, allowLoopback bool) *http.Client {
	dialer := &net.Dialer{Timeout: 10 * time.Second, KeepAlive: 30 * time.Second}
	transport := &http.Transport{
		Proxy:                 nil,
		DialContext:           safeDialContext(dialer, allowLoopback),
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: 25 * time.Second,
		ExpectContinueTimeout: time.Second,
		IdleConnTimeout:       60 * time.Second,
		MaxIdleConns:          20,
		MaxIdleConnsPerHost:   4,
	}
	return &http.Client{
		Timeout:   timeout,
		Transport: transport,
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
}

func safeDialContext(dialer *net.Dialer, allowLoopback bool) func(context.Context, string, string) (net.Conn, error) {
	return func(ctx context.Context, network, address string) (net.Conn, error) {
		host, port, err := net.SplitHostPort(address)
		if err != nil {
			return nil, err
		}
		host = strings.Trim(host, "[]")
		if loopbackAddress, isLoopback := resolvedLoopbackAddress(host, port); isLoopback {
			if !allowLoopback {
				return nil, errors.New("Provider-Ziel darf nicht auf einen lokalen Endpunkt zeigen")
			}
			return dialer.DialContext(ctx, network, loopbackAddress)
		}
		if ip, err := netip.ParseAddr(host); err == nil {
			if !isPublicIP(ip) {
				return nil, errors.New("Provider-Ziel ist keine öffentliche Adresse")
			}
			return dialer.DialContext(ctx, network, joinHostPort(ip.String(), port))
		}
		addresses, err := net.DefaultResolver.LookupNetIP(ctx, "ip", host)
		if err != nil {
			return nil, fmt.Errorf("Provider-Host kann nicht aufgelöst werden")
		}
		var dialErr error
		for _, ip := range addresses {
			if !isPublicIP(ip) {
				return nil, errors.New("Provider-Host löst auf eine private oder reservierte Adresse auf")
			}
			connection, err := dialer.DialContext(ctx, network, joinHostPort(ip.String(), port))
			if err == nil {
				return connection, nil
			}
			dialErr = err
		}
		if dialErr != nil {
			return nil, dialErr
		}
		return nil, errors.New("Provider-Host liefert keine erreichbare Adresse")
	}
}

func resolvedLoopbackAddress(host, port string) (string, bool) {
	host = strings.Trim(strings.ToLower(strings.TrimSpace(host)), "[]")
	if host == "localhost" {
		// Do not let a hosts-file or resolver override turn the special local
		// provider name into a network hop.
		return joinHostPort("127.0.0.1", port), true
	}
	ip, err := netip.ParseAddr(host)
	if err != nil || !ip.IsLoopback() {
		return "", false
	}
	return joinHostPort(ip.String(), port), true
}

// SyncConnection fetches a fresh catalogue and atomically replaces the
// cached metadata only after the fetch succeeds.  A temporary outage leaves
// the last known models selectable and records a visible stale-state reason.
func (m *Manager) SyncConnection(ctx context.Context, userID, connectionID string) (Connection, []Model, error) {
	connection, err := m.GetConnection(userID, connectionID)
	if err != nil {
		return Connection{}, nil, err
	}
	models, err := DiscoverModels(ctx, connection)
	if err != nil {
		updated, storeErr := m.SetSyncResultIfCurrent(userID, connectionID, connection, nil, err)
		if storeErr != nil {
			return Connection{}, nil, storeErr
		}
		return updated, nil, err
	}
	updated, err := m.SetSyncResultIfCurrent(userID, connectionID, connection, models, nil)
	if errors.Is(err, ErrCatalogModelLimit) {
		updated, storeErr := m.SetSyncResultIfCurrent(userID, connectionID, connection, nil, err)
		if storeErr != nil {
			return Connection{}, nil, storeErr
		}
		return updated, nil, err
	}
	if err != nil {
		return Connection{}, nil, err
	}
	return updated, cloneModels(models), nil
}

// TestConnection runs the same authenticated discovery request without
// persisting its model list.  It makes a failed key/endpoint actionable before
// a caller has to inspect the chat screen.
func (m *Manager) TestConnection(ctx context.Context, userID, connectionID string) (int, error) {
	connection, err := m.GetConnection(userID, connectionID)
	if err != nil {
		return 0, err
	}
	models, err := DiscoverModels(ctx, connection)
	if err != nil {
		return 0, err
	}
	return len(models), nil
}

func DiscoverModels(ctx context.Context, connection Connection) ([]Model, error) {
	if !connection.Enabled {
		return nil, errors.New("Provider-Verbindung ist deaktiviert")
	}
	if connection.APIKey == "" && presetRequiresKey(connection.PresetID) {
		return nil, errors.New("API-Key fehlt")
	}
	if _, err := endpointURL(connection.BaseURL); err != nil {
		return nil, errors.New("API-Basis-URL ist ungültig")
	}

	switch connection.PresetID {
	case "fireworks":
		return discoverFireworks(ctx, connection)
	}
	switch NormalizeProtocol(connection.Protocol) {
	case ProtocolOpenAICompatible:
		return discoverOpenAICompatible(ctx, connection)
	case ProtocolAnthropic:
		return discoverAnthropic(ctx, connection)
	case ProtocolGoogleGenAI:
		return discoverGemini(ctx, connection)
	default:
		return nil, errors.New("für dieses Provider-Protokoll gibt es keine Modell-Erkennung")
	}
}

func discoverOpenAICompatible(ctx context.Context, connection Connection) ([]Model, error) {
	endpoint, err := endpointURL(connection.BaseURL, "models")
	if err != nil {
		return nil, err
	}
	payload, err := providerGet(ctx, connection, endpoint, bearerHeaders(connection.APIKey))
	if err != nil {
		return nil, err
	}
	return normalizeGenericModelList(payload, true)
}

func discoverAnthropic(ctx context.Context, connection Connection) ([]Model, error) {
	endpoint, err := endpointWithVersion(connection.BaseURL, "v1", "models")
	if err != nil {
		return nil, err
	}
	all := []Model{}
	afterID := ""
	for page := 0; page < maxCatalogPages; page++ {
		pageURL, err := url.Parse(endpoint)
		if err != nil {
			return nil, err
		}
		query := pageURL.Query()
		query.Set("limit", "100")
		if afterID != "" {
			query.Set("after_id", afterID)
		}
		pageURL.RawQuery = query.Encode()
		payload, err := providerGet(ctx, connection, pageURL.String(), anthropicHeaders(connection.APIKey))
		if err != nil {
			return nil, err
		}
		var response struct {
			Data    []genericModel `json:"data"`
			HasMore bool           `json:"has_more"`
			LastID  string         `json:"last_id"`
		}
		if err := json.Unmarshal(payload, &response); err != nil {
			return nil, errors.New("Anthropic lieferte keine gültige Modellliste")
		}
		models := normalizeGenericModels(response.Data, true)
		all = append(all, models...)
		if !response.HasMore || response.LastID == "" || response.LastID == afterID {
			break
		}
		afterID = response.LastID
	}
	return deduplicateAndSortModels(all), nil
}

func discoverGemini(ctx context.Context, connection Connection) ([]Model, error) {
	endpoint, err := endpointWithVersion(connection.BaseURL, "v1beta", "models")
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	all := []Model{}
	nextPageToken := ""
	for page := 0; page < maxCatalogPages; page++ {
		pageURL, parseErr := url.Parse(endpoint)
		if parseErr != nil {
			return nil, parseErr
		}
		query := pageURL.Query()
		query.Set("pageSize", "100")
		if nextPageToken != "" {
			query.Set("pageToken", nextPageToken)
		}
		pageURL.RawQuery = query.Encode()
		payload, fetchErr := providerGet(ctx, connection, pageURL.String(), geminiHeaders(connection.APIKey))
		if fetchErr != nil {
			return nil, fetchErr
		}
		pageModels, nextToken, parseErr := parseGeminiModelsPage(payload, now)
		if parseErr != nil {
			return nil, parseErr
		}
		all = append(all, pageModels...)
		if nextToken == "" || nextToken == nextPageToken {
			break
		}
		nextPageToken = nextToken
	}
	return deduplicateAndSortModels(all), nil
}

// parseGeminiModelsPage is split out from discoverGemini so the pagination
// merge logic stays testable without a live HTTP round trip.
func parseGeminiModelsPage(payload []byte, now time.Time) ([]Model, string, error) {
	var response struct {
		Models []struct {
			Name                       string   `json:"name"`
			DisplayName                string   `json:"displayName"`
			Description                string   `json:"description"`
			InputTokenLimit            int      `json:"inputTokenLimit"`
			OutputTokenLimit           int      `json:"outputTokenLimit"`
			SupportedGenerationMethods []string `json:"supportedGenerationMethods"`
		} `json:"models"`
		NextPageToken string `json:"nextPageToken"`
	}
	if err := json.Unmarshal(payload, &response); err != nil {
		return nil, "", errors.New("Gemini lieferte keine gültige Modellliste")
	}
	models := make([]Model, 0, len(response.Models))
	for _, raw := range response.Models {
		id := strings.TrimPrefix(strings.TrimSpace(raw.Name), "models/")
		if id == "" {
			continue
		}
		capabilities := uniqueStrings(raw.SupportedGenerationMethods)
		chat := containsInsensitive(capabilities, "generateContent") || containsInsensitive(capabilities, "streamGenerateContent")
		models = append(models, Model{
			ID:               id,
			DisplayName:      firstNonEmpty(strings.TrimSpace(raw.DisplayName), id),
			Description:      strings.TrimSpace(raw.Description),
			ContextWindow:    raw.InputTokenLimit,
			MaxOutputTokens:  raw.OutputTokenLimit,
			InputModalities:  []string{"text"},
			OutputModalities: []string{"text"},
			Capabilities:     capabilities,
			ChatSupported:    chat,
			DiscoveredAt:     now,
		})
	}
	return models, strings.TrimSpace(response.NextPageToken), nil
}

func discoverFireworks(ctx context.Context, connection Connection) ([]Model, error) {
	const apiBase = "https://api.fireworks.ai/v1"
	accountsPayload, err := providerGet(ctx, connection, apiBase+"/accounts", bearerHeaders(connection.APIKey))
	if err != nil {
		return nil, err
	}
	var accounts struct {
		Accounts []struct {
			ID string `json:"id"`
		} `json:"accounts"`
		Data []struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := json.Unmarshal(accountsPayload, &accounts); err != nil {
		return nil, errors.New("Fireworks lieferte keine gültige Accountliste")
	}
	accountIDs := []string{}
	for _, account := range accounts.Accounts {
		accountIDs = append(accountIDs, account.ID)
	}
	for _, account := range accounts.Data {
		accountIDs = append(accountIDs, account.ID)
	}
	accountIDs = uniqueStrings(accountIDs)
	if len(accountIDs) == 0 {
		return nil, errors.New("Fireworks-Konto enthält keine abrufbaren Accounts")
	}

	all := []Model{}
	for _, accountID := range accountIDs {
		endpoint := apiBase + "/accounts/" + url.PathEscape(accountID) + "/models"
		payload, err := providerGet(ctx, connection, endpoint, bearerHeaders(connection.APIKey))
		if err != nil {
			return nil, err
		}
		models, err := normalizeGenericModelList(payload, true)
		if err != nil {
			return nil, err
		}
		all = append(all, models...)
	}
	return deduplicateAndSortModels(all), nil
}

func providerGet(ctx context.Context, connection Connection, endpoint string, headers http.Header) ([]byte, error) {
	if err := ValidateConnectionOutboundURL(ctx, connection, endpoint); err != nil {
		return nil, err
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, errors.New("Provider-Anfrage konnte nicht erstellt werden")
	}
	request.Header = headers.Clone()
	request.Header.Set("Accept", "application/json")
	request.Header.Set("User-Agent", "culpeostudio-provider-sync/1.0")
	response, err := NewHTTPClientForConnection(connection).Do(request)
	if err != nil {
		return nil, fmt.Errorf("Provider ist nicht erreichbar")
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		// Never surface a raw provider body: it may contain request echoes or
		// account details.  The status alone is enough to guide a key retry.
		if response.StatusCode == http.StatusUnauthorized || response.StatusCode == http.StatusForbidden {
			return nil, fmt.Errorf("Provider verweigert den API-Key (%d)", response.StatusCode)
		}
		return nil, fmt.Errorf("Provider antwortet mit HTTP %d", response.StatusCode)
	}
	payload, err := io.ReadAll(io.LimitReader(response.Body, maxProviderBodyBytes+1))
	if err != nil {
		return nil, errors.New("Provider-Antwort konnte nicht gelesen werden")
	}
	if len(payload) > maxProviderBodyBytes {
		return nil, errors.New("Provider-Modellliste ist zu groß")
	}
	return payload, nil
}

func bearerHeaders(key string) http.Header {
	headers := make(http.Header)
	if strings.TrimSpace(key) != "" {
		headers.Set("Authorization", "Bearer "+strings.TrimSpace(key))
	}
	return headers
}

func anthropicHeaders(key string) http.Header {
	headers := make(http.Header)
	headers.Set("x-api-key", strings.TrimSpace(key))
	headers.Set("anthropic-version", "2023-06-01")
	return headers
}

func geminiHeaders(key string) http.Header {
	headers := make(http.Header)
	headers.Set("x-goog-api-key", strings.TrimSpace(key))
	return headers
}

type genericModel struct {
	ID                  string        `json:"id"`
	Name                string        `json:"name"`
	DisplayName         string        `json:"display_name"`
	DisplayNameCamel    string        `json:"displayName"`
	Description         string        `json:"description"`
	ContextLength       flexibleInt   `json:"context_length"`
	ContextWindow       flexibleInt   `json:"context_window"`
	MaxContextLength    flexibleInt   `json:"max_context_length"`
	MaxCompletionTokens flexibleInt   `json:"max_completion_tokens"`
	MaxOutputTokens     flexibleInt   `json:"max_output_tokens"`
	Archived            flexibleBool  `json:"archived"`
	Deprecated          flexibleBool  `json:"deprecated"`
	Capabilities        capabilitySet `json:"capabilities"`
	InputModalities     stringList    `json:"input_modalities"`
	OutputModalities    stringList    `json:"output_modalities"`
	Architecture        struct {
		InputModalities  stringList `json:"input_modalities"`
		OutputModalities stringList `json:"output_modalities"`
	} `json:"architecture"`
}

func normalizeGenericModelList(payload []byte, defaultChat bool) ([]Model, error) {
	var wrapped struct {
		Data   []genericModel `json:"data"`
		Models []genericModel `json:"models"`
	}
	if err := json.Unmarshal(payload, &wrapped); err == nil && (wrapped.Data != nil || wrapped.Models != nil) {
		models := wrapped.Data
		if len(models) == 0 {
			models = wrapped.Models
		}
		return deduplicateAndSortModels(normalizeGenericModels(models, defaultChat)), nil
	}
	var direct []genericModel
	if err := json.Unmarshal(payload, &direct); err != nil {
		return nil, errors.New("Provider lieferte keine gültige Modellliste")
	}
	return deduplicateAndSortModels(normalizeGenericModels(direct, defaultChat)), nil
}

func normalizeGenericModels(rawModels []genericModel, defaultChat bool) []Model {
	now := time.Now().UTC()
	models := make([]Model, 0, len(rawModels))
	for _, raw := range rawModels {
		id := firstNonEmpty(strings.TrimSpace(raw.ID), strings.TrimSpace(raw.Name))
		if id == "" {
			continue
		}
		input := uniqueStrings(append(append([]string(nil), []string(raw.InputModalities)...), []string(raw.Architecture.InputModalities)...))
		output := uniqueStrings(append(append([]string(nil), []string(raw.OutputModalities)...), []string(raw.Architecture.OutputModalities)...))
		if len(input) == 0 {
			input = []string{"text"}
		}
		if len(output) == 0 {
			output = []string{"text"}
		}
		capabilities := []string{}
		hasChatCapability := false
		chat := defaultChat
		for name, enabled := range raw.Capabilities {
			if enabled {
				capabilities = append(capabilities, name)
			}
			if isChatCapability(name) {
				hasChatCapability = true
				chat = enabled
			}
		}
		if !hasChatCapability && looksNonChatModel(id) {
			chat = false
		}
		context := firstPositive(int(raw.ContextLength), int(raw.ContextWindow), int(raw.MaxContextLength))
		maxOutput := firstPositive(int(raw.MaxCompletionTokens), int(raw.MaxOutputTokens))
		models = append(models, Model{
			ID:               id,
			DisplayName:      firstNonEmpty(strings.TrimSpace(raw.DisplayName), strings.TrimSpace(raw.DisplayNameCamel), id),
			Description:      strings.TrimSpace(raw.Description),
			ContextWindow:    context,
			MaxOutputTokens:  maxOutput,
			InputModalities:  input,
			OutputModalities: output,
			Capabilities:     uniqueStrings(capabilities),
			ChatSupported:    chat && !bool(raw.Archived) && !bool(raw.Deprecated),
			Deprecated:       bool(raw.Archived) || bool(raw.Deprecated),
			DiscoveredAt:     now,
		})
	}
	return models
}

func deduplicateAndSortModels(models []Model) []Model {
	byID := make(map[string]Model, len(models))
	for _, model := range models {
		model.ID = strings.TrimSpace(model.ID)
		if model.ID == "" {
			continue
		}
		if previous, exists := byID[model.ID]; !exists || (!previous.ChatSupported && model.ChatSupported) {
			byID[model.ID] = model
		}
	}
	out := make([]Model, 0, len(byID))
	for _, model := range byID {
		out = append(out, model)
	}
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].ChatSupported != out[j].ChatSupported {
			return out[i].ChatSupported
		}
		left := strings.ToLower(out[i].DisplayName)
		right := strings.ToLower(out[j].DisplayName)
		if left == right {
			return out[i].ID < out[j].ID
		}
		return left < right
	})
	return out
}

// flexibleInt accepts documented providers that represent token limits as a
// number or a JSON string. Unknown values are ignored instead of making an
// otherwise valid provider catalogue unusable.
type flexibleInt int

func (value *flexibleInt) UnmarshalJSON(payload []byte) error {
	*value = 0
	var number float64
	if err := json.Unmarshal(payload, &number); err == nil {
		value.set(number)
		return nil
	}
	var text string
	if err := json.Unmarshal(payload, &text); err == nil {
		if parsed, parseErr := strconv.ParseFloat(strings.TrimSpace(text), 64); parseErr == nil {
			value.set(parsed)
		}
	}
	return nil
}

func (value *flexibleInt) set(number float64) {
	maxInt := float64(int(^uint(0) >> 1))
	if math.IsNaN(number) || math.IsInf(number, 0) || number <= 0 || number > maxInt {
		return
	}
	*value = flexibleInt(math.Floor(number))
}

// flexibleBool accepts a boolean plus the string and numeric forms emitted by
// a few OpenAI-compatible catalogues for archived/deprecated flags.
type flexibleBool bool

func (value *flexibleBool) UnmarshalJSON(payload []byte) error {
	*value = false
	var boolean bool
	if err := json.Unmarshal(payload, &boolean); err == nil {
		*value = flexibleBool(boolean)
		return nil
	}
	var text string
	if err := json.Unmarshal(payload, &text); err == nil {
		if parsed, parseErr := strconv.ParseBool(strings.TrimSpace(text)); parseErr == nil {
			*value = flexibleBool(parsed)
		}
		return nil
	}
	var number float64
	if err := json.Unmarshal(payload, &number); err == nil {
		*value = flexibleBool(number != 0)
	}
	return nil
}

// stringList accepts either one modality or an array. Some
// OpenAI-compatible catalogues use one form while others use the other.
type stringList []string

func (values *stringList) UnmarshalJSON(payload []byte) error {
	*values = nil
	var list []string
	if err := json.Unmarshal(payload, &list); err == nil {
		*values = stringList(uniqueStrings(list))
		return nil
	}
	var single string
	if err := json.Unmarshal(payload, &single); err == nil {
		*values = stringList(uniqueStrings([]string{single}))
	}
	return nil
}

// capabilitySet tolerates the common boolean map plus string lists and nested
// capability descriptors. A non-false descriptor means the capability is
// advertised, while an explicit false remains authoritative for chat support.
type capabilitySet map[string]bool

func (capabilities *capabilitySet) UnmarshalJSON(payload []byte) error {
	result := make(map[string]bool)
	var object map[string]json.RawMessage
	if err := json.Unmarshal(payload, &object); err == nil {
		for name, raw := range object {
			name = strings.TrimSpace(name)
			if name != "" {
				result[name] = capabilityEnabled(raw)
			}
		}
		*capabilities = capabilitySet(result)
		return nil
	}
	var list stringList
	if err := json.Unmarshal(payload, &list); err == nil && list != nil {
		for _, name := range list {
			result[name] = true
		}
		*capabilities = capabilitySet(result)
		return nil
	}
	var single string
	if err := json.Unmarshal(payload, &single); err == nil {
		if single = strings.TrimSpace(single); single != "" {
			result[single] = true
		}
	}
	*capabilities = capabilitySet(result)
	return nil
}

func capabilityEnabled(payload json.RawMessage) bool {
	var enabled bool
	if err := json.Unmarshal(payload, &enabled); err == nil {
		return enabled
	}
	var text string
	if err := json.Unmarshal(payload, &text); err == nil {
		if parsed, parseErr := strconv.ParseBool(strings.TrimSpace(text)); parseErr == nil {
			return parsed
		}
	}
	var descriptor struct {
		Enabled   *bool `json:"enabled"`
		Supported *bool `json:"supported"`
	}
	if err := json.Unmarshal(payload, &descriptor); err == nil {
		if descriptor.Enabled != nil {
			return *descriptor.Enabled
		}
		if descriptor.Supported != nil {
			return *descriptor.Supported
		}
	}
	return strings.TrimSpace(string(payload)) != "" && string(payload) != "null"
}

func isChatCapability(name string) bool {
	switch strings.ToLower(strings.TrimSpace(name)) {
	case "completion_chat", "chat_completion", "chat", "messages":
		return true
	default:
		return false
	}
}

func uniqueStrings(values []string) []string {
	seen := make(map[string]bool, len(values))
	out := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" || seen[value] {
			continue
		}
		seen[value] = true
		out = append(out, value)
	}
	return out
}

func containsInsensitive(values []string, expected string) bool {
	for _, value := range values {
		if strings.EqualFold(strings.TrimSpace(value), expected) {
			return true
		}
	}
	return false
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value = strings.TrimSpace(value); value != "" {
			return value
		}
	}
	return ""
}

func firstPositive(values ...int) int {
	for _, value := range values {
		if value > 0 {
			return value
		}
	}
	return 0
}

func looksNonChatModel(modelID string) bool {
	id := strings.ToLower(strings.TrimSpace(modelID))
	for _, marker := range []string{"embed", "embedding", "whisper", "transcri", "tts", "speech", "moderation", "image", "dall-e", "audio"} {
		if strings.Contains(id, marker) {
			return true
		}
	}
	return false
}
