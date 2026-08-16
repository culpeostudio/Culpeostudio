package providerconn

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"net/url"
	"strconv"
	"strings"
)

// nonPublicPrefixes covers ranges that netip.Addr.IsGlobalUnicast alone does
// not reject (for example carrier-grade NAT and documentation networks).
// Treating those as private keeps user-configurable endpoints from becoming a
// path to internal or otherwise non-routable infrastructure.
var nonPublicPrefixes = []netip.Prefix{
	netip.MustParsePrefix("0.0.0.0/8"),
	netip.MustParsePrefix("100.64.0.0/10"),
	netip.MustParsePrefix("192.0.0.0/24"),
	netip.MustParsePrefix("192.0.2.0/24"),
	netip.MustParsePrefix("192.88.99.0/24"),
	netip.MustParsePrefix("198.18.0.0/15"),
	netip.MustParsePrefix("198.51.100.0/24"),
	netip.MustParsePrefix("203.0.113.0/24"),
	netip.MustParsePrefix("240.0.0.0/4"),
	netip.MustParsePrefix("2001:db8::/32"),
}

func normalizeConnectionInput(input ConnectionInput) (ConnectionInput, error) {
	input.ID = strings.TrimSpace(input.ID)
	input.PresetID = strings.TrimSpace(input.PresetID)
	preset, ok := FindPreset(input.PresetID)
	if !ok {
		return ConnectionInput{}, errors.New("unbekannter Anbieter-Preset")
	}
	if !preset.Available {
		reason := strings.TrimSpace(preset.UnavailableReason)
		if reason == "" {
			reason = "Dieser Anbieter ist derzeit nicht verfügbar"
		}
		return ConnectionInput{}, errors.New(reason)
	}

	input.Protocol = NormalizeProtocol(input.Protocol)
	if preset.ID == CustomPresetID {
		if input.Protocol == "" {
			input.Protocol = preset.Protocol
		}
	} else {
		input.Protocol = preset.Protocol
	}
	if input.Protocol == "" {
		return ConnectionInput{}, errors.New("ungültiges API-Protokoll")
	}

	input.Name = strings.TrimSpace(input.Name)
	if input.Name == "" {
		input.Name = preset.Name
	}
	if len([]rune(input.Name)) > 80 {
		return ConnectionInput{}, errors.New("Name der Provider-Verbindung darf höchstens 80 Zeichen haben")
	}

	input.BaseURL = strings.TrimSpace(input.BaseURL)
	if input.BaseURL == "" {
		input.BaseURL = preset.DefaultBaseURL
	}
	cleanURL, err := validateBaseURL(input.BaseURL, preset)
	if err != nil {
		return ConnectionInput{}, err
	}
	input.BaseURL = cleanURL
	if input.APIKey != nil {
		value := strings.TrimSpace(*input.APIKey)
		if len([]rune(value)) > 8192 {
			return ConnectionInput{}, errors.New("API-Key ist ungewöhnlich lang")
		}
		input.APIKey = &value
	}
	return input, nil
}

func validateBaseURL(raw string, preset Preset) (string, error) {
	u, err := parseHTTPURL(raw)
	if err != nil {
		return "", fmt.Errorf("API-Basis-URL ist ungültig: %w", err)
	}
	if u.RawQuery != "" {
		return "", errors.New("API-Basis-URL darf keine Zugangsdaten, Query-Parameter oder Fragmente enthalten")
	}
	host := strings.ToLower(strings.TrimSpace(u.Hostname()))
	isLoopback := isLoopbackHost(host)
	if preset.LocalOnly {
		if !isLoopback {
			return "", errors.New("dieser lokale Anbieter darf nur über localhost oder eine Loopback-Adresse verbunden werden")
		}
	} else {
		// A generic/custom connection runs from the backend process. Allowing it
		// to target loopback would let an ordinary authenticated user probe
		// sidecars or other local services. Only the explicit local presets may
		// use localhost at all.
		if isLoopback {
			return "", errors.New("nur ausdrücklich lokale Presets dürfen auf einen lokalen Endpunkt zeigen")
		}
		if u.Scheme != "https" {
			return "", errors.New("externe Anbieter müssen HTTPS verwenden")
		}
		if ip, err := netip.ParseAddr(host); err == nil && !isPublicIP(ip) {
			return "", errors.New("private oder reservierte Netzwerkadressen sind nur für die lokalen Presets erlaubt")
		}
	}
	u.Path = strings.TrimRight(u.Path, "/")
	u.RawPath = ""
	if u.Path == "." {
		u.Path = ""
	}
	return strings.TrimRight(u.String(), "/"), nil
}

func isLoopbackHost(host string) bool {
	host = strings.Trim(strings.ToLower(strings.TrimSpace(host)), "[]")
	if host == "localhost" {
		return true
	}
	ip, err := netip.ParseAddr(host)
	return err == nil && ip.IsLoopback()
}

func isPublicIP(ip netip.Addr) bool {
	ip = ip.Unmap()
	if !ip.IsValid() || !ip.IsGlobalUnicast() || ip.IsPrivate() ||
		ip.IsLoopback() || ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() ||
		ip.IsUnspecified() || ip.IsMulticast() {
		return false
	}
	for _, prefix := range nonPublicPrefixes {
		if prefix.Contains(ip) {
			return false
		}
	}
	return true
}

// ValidateOutboundURL validates a public provider URL. Callers that hold a
// full Connection should use ValidateConnectionOutboundURL so only explicit
// local presets can opt into a loopback destination.
func ValidateOutboundURL(ctx context.Context, raw string) error {
	return validateOutboundURL(ctx, raw, false)
}

// ValidateConnectionOutboundURL runs immediately before each connection-owned
// provider request. It resolves public hosts and rejects private targets, and
// permits loopback only for a preset explicitly marked LocalOnly. This is
// repeated at request time to guard against DNS rebinding after save.
func ValidateConnectionOutboundURL(ctx context.Context, connection Connection, raw string) error {
	preset, known := FindPreset(connection.PresetID)
	return validateOutboundURL(ctx, raw, known && preset.LocalOnly)
}

func validateOutboundURL(ctx context.Context, raw string, allowLoopback bool) error {
	u, err := parseHTTPURL(raw)
	if err != nil {
		return errors.New("Provider-URL ist ungültig")
	}
	host := strings.TrimSpace(u.Hostname())
	if host == "" {
		return errors.New("Provider-URL enthält keinen Host")
	}
	if isLoopbackHost(host) {
		if allowLoopback {
			return nil
		}
		return errors.New("Provider-URL darf nicht auf einen lokalen Endpunkt zeigen")
	}
	if allowLoopback {
		return errors.New("lokale Provider dürfen nur auf localhost oder eine Loopback-Adresse zeigen")
	}
	if u.Scheme != "https" {
		return errors.New("externe Provider-URLs müssen HTTPS verwenden")
	}
	if ip, err := netip.ParseAddr(host); err == nil {
		if !isPublicIP(ip) {
			return errors.New("Provider-URL zeigt auf eine private oder reservierte Adresse")
		}
		return nil
	}
	addresses, err := net.DefaultResolver.LookupNetIP(ctx, "ip", host)
	if err != nil {
		return fmt.Errorf("Provider-Host kann nicht aufgelöst werden")
	}
	if len(addresses) == 0 {
		return errors.New("Provider-Host liefert keine Adresse")
	}
	for _, address := range addresses {
		if !isPublicIP(address) {
			return errors.New("Provider-Host löst auf eine private oder reservierte Adresse auf")
		}
	}
	return nil
}

func endpointURL(baseURL string, parts ...string) (string, error) {
	u, err := parseHTTPURL(baseURL)
	if err != nil {
		return "", err
	}
	if u.RawQuery != "" {
		return "", errors.New("API-Basis-URL darf keine Query-Parameter enthalten")
	}
	path := strings.TrimRight(u.Path, "/")
	for _, part := range parts {
		part = strings.Trim(part, "/")
		if part == "" {
			continue
		}
		path += "/" + part
	}
	u.Path = path
	u.RawPath = ""
	return u.String(), nil
}

func endpointWithVersion(baseURL, version, resource string) (string, error) {
	u, err := parseHTTPURL(baseURL)
	if err != nil {
		return "", err
	}
	if u.RawQuery != "" {
		return "", errors.New("API-Basis-URL darf keine Query-Parameter enthalten")
	}
	path := strings.TrimRight(u.Path, "/")
	trimmedPath := strings.Trim(path, "/")
	if !strings.HasSuffix(path, "/"+version) && trimmedPath != version {
		path += "/" + version
	}
	path += "/" + strings.Trim(resource, "/")
	u.Path = path
	u.RawPath = ""
	return u.String(), nil
}

func providerAddress(raw string) (host, port string, err error) {
	u, err := parseHTTPURL(raw)
	if err != nil {
		return "", "", err
	}
	host = u.Hostname()
	port = u.Port()
	if port == "" {
		if u.Scheme == "https" {
			port = "443"
		} else {
			port = "80"
		}
	}
	if host == "" {
		return "", "", errors.New("leerer Provider-Host")
	}
	return host, port, nil
}

func joinHostPort(host, port string) string {
	return net.JoinHostPort(host, port)
}

// ChatCompletionsURL returns the OpenAI-compatible text-chat endpoint for a
// validated provider base URL.
func ChatCompletionsURL(baseURL string) (string, error) {
	return endpointURL(baseURL, "chat", "completions")
}

// AnthropicMessagesURL returns the native Anthropic Messages endpoint.  It
// accepts either https://api.anthropic.com or a base URL already ending in v1.
func AnthropicMessagesURL(baseURL string) (string, error) {
	return endpointWithVersion(baseURL, "v1", "messages")
}

// GeminiStreamURL returns the native Gemini streaming endpoint for modelID.
// A Gemini model name can optionally start with "models/"; additional path
// separators are rejected so a provider catalogue cannot alter the endpoint.
func GeminiStreamURL(baseURL, modelID string) (string, error) {
	modelID = strings.TrimPrefix(strings.TrimSpace(modelID), "models/")
	if modelID == "" || strings.ContainsAny(modelID, "/?#") {
		return "", errors.New("Gemini-Modell-ID ist ungültig")
	}
	modelsURL, err := endpointWithVersion(baseURL, "v1beta", "models")
	if err != nil {
		return "", err
	}
	return endpointURL(modelsURL, modelID+":streamGenerateContent")
}

func parseHTTPURL(raw string) (*url.URL, error) {
	u, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		return nil, errors.New("URL kann nicht gelesen werden")
	}
	if u.Scheme != "https" && u.Scheme != "http" {
		return nil, errors.New("URL muss http:// oder https:// verwenden")
	}
	if u.Host == "" || u.User != nil || u.Fragment != "" {
		return nil, errors.New("URL enthält keinen gültigen Host")
	}
	if port := u.Port(); port != "" {
		value, portErr := strconv.Atoi(port)
		if portErr != nil || value < 1 || value > 65535 {
			return nil, errors.New("URL enthält einen ungültigen Port")
		}
	}
	return u, nil
}
