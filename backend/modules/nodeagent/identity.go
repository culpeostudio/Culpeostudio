// Package nodeagent contains the small, transport-independent identity and
// gRPC surface a Culpeo node exposes to its Studio.
//
// It deliberately knows nothing about how a Studio reaches the node. Whether
// the connection is local, private, or proxied is a deployment concern; this
// package only owns the pairing credential and the two NodeAgent RPCs.
package nodeagent

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

const (
	defaultNodeName = "Culpeo Node"
	defaultVersion  = "dev"

	minTokenLength  = 16
	maxTokenLength  = 512
	maxNodeIDRunes  = 128
	maxNameRunes    = 128
	maxVersionRunes = 128
)

// Config supplies the stable identity of one node. IdentityPath is required:
// it is where the generated node id and pairing token are kept across
// restarts. The token is never logged by this package.
//
// On the first start NodeID and Token may be omitted. Secure values are then
// generated and can be retrieved explicitly with Service.PairingToken. On a
// later start they are read from IdentityPath; supplying different values is
// rejected rather than silently replacing an already paired identity.
type Config struct {
	IdentityPath string
	NodeID       string
	Name         string
	Token        string
	Version      string
}

// Identity is the non-secret part of a node identity. It is safe to report in
// a status response or diagnostic UI.
type Identity struct {
	NodeID    string
	Name      string
	CreatedAt time.Time
}

// persistedIdentity is intentionally private because it holds the pairing
// token. The JSON file is created with mode 0600 and its parent with mode
// 0700.
type persistedIdentity struct {
	NodeID       string    `json:"node_id"`
	Name         string    `json:"name"`
	Token        string    `json:"token"`
	CreatedAt    time.Time `json:"created_at"`
	GatewayKeyID string    `json:"gateway_key_id,omitempty"`
}

func (value persistedIdentity) public() Identity {
	return Identity{
		NodeID:    value.NodeID,
		Name:      value.Name,
		CreatedAt: value.CreatedAt,
	}
}

func loadOrCreateIdentity(cfg Config) (persistedIdentity, string, error) {
	path, err := cleanIdentityPath(cfg.IdentityPath)
	if err != nil {
		return persistedIdentity{}, "", err
	}

	configuredID, err := normalizeOptionalNodeID(cfg.NodeID)
	if err != nil {
		return persistedIdentity{}, "", err
	}
	configuredName, err := normalizeOptionalName(cfg.Name)
	if err != nil {
		return persistedIdentity{}, "", err
	}
	configuredToken, err := normalizeOptionalToken(cfg.Token)
	if err != nil {
		return persistedIdentity{}, "", err
	}

	stored, found, err := readIdentity(path)
	if err != nil {
		return persistedIdentity{}, "", err
	}
	if !found {
		if configuredID == "" {
			configuredID, err = generateNodeID()
			if err != nil {
				return persistedIdentity{}, "", err
			}
		}
		if configuredName == "" {
			configuredName = defaultNodeName
		}
		if configuredToken == "" {
			configuredToken, err = generateToken()
			if err != nil {
				return persistedIdentity{}, "", err
			}
		}
		stored = persistedIdentity{
			NodeID:    configuredID,
			Name:      configuredName,
			Token:     configuredToken,
			CreatedAt: time.Now().UTC(),
		}
		if err := writeIdentity(path, stored); err != nil {
			return persistedIdentity{}, "", err
		}
		return stored, path, nil
	}

	if err := validatePersistedIdentity(stored); err != nil {
		return persistedIdentity{}, "", err
	}
	if configuredID != "" && configuredID != stored.NodeID {
		return persistedIdentity{}, "", fmt.Errorf("Node-ID in der Konfiguration stimmt nicht mit der gespeicherten Identitaet ueberein")
	}
	if configuredToken != "" && configuredToken != stored.Token {
		return persistedIdentity{}, "", fmt.Errorf("Pairing-Token in der Konfiguration stimmt nicht mit der gespeicherten Identitaet ueberein")
	}
	if configuredName != "" && configuredName != stored.Name {
		stored.Name = configuredName
		if err := writeIdentity(path, stored); err != nil {
			return persistedIdentity{}, "", err
		}
	}
	return stored, path, nil
}

func cleanIdentityPath(raw string) (string, error) {
	path := strings.TrimSpace(raw)
	if path == "" {
		return "", fmt.Errorf("Pfad fuer die Node-Identitaet fehlt")
	}
	path = filepath.Clean(path)
	if path == "." || path == string(filepath.Separator) {
		return "", fmt.Errorf("Pfad fuer die Node-Identitaet ist ungueltig")
	}
	return path, nil
}

func readIdentity(path string) (persistedIdentity, bool, error) {
	info, err := os.Lstat(path)
	if errors.Is(err, os.ErrNotExist) {
		return persistedIdentity{}, false, nil
	}
	if err != nil {
		return persistedIdentity{}, false, fmt.Errorf("Node-Identitaet lesen: %w", err)
	}
	if info.Mode()&os.ModeSymlink != 0 || !info.Mode().IsRegular() {
		return persistedIdentity{}, false, fmt.Errorf("Node-Identitaet muss eine regulaere Datei sein")
	}

	data, err := os.ReadFile(path)
	if err != nil {
		return persistedIdentity{}, false, fmt.Errorf("Node-Identitaet lesen: %w", err)
	}
	var stored persistedIdentity
	if err := json.Unmarshal(data, &stored); err != nil {
		return persistedIdentity{}, false, fmt.Errorf("Node-Identitaet lesen: ungueltiges JSON: %w", err)
	}
	if err := os.Chmod(path, 0o600); err != nil {
		return persistedIdentity{}, false, fmt.Errorf("Zugriffsrechte der Node-Identitaet absichern: %w", err)
	}
	return stored, true, nil
}

func writeIdentity(path string, value persistedIdentity) (writeErr error) {
	directory := filepath.Dir(path)
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return fmt.Errorf("Node-Identitaetsordner anlegen: %w", err)
	}

	temporary, err := os.CreateTemp(directory, ".node-identity-*")
	if err != nil {
		return fmt.Errorf("Node-Identitaet schreiben: %w", err)
	}
	temporaryPath := temporary.Name()
	defer func() {
		if writeErr != nil {
			_ = os.Remove(temporaryPath)
		}
	}()
	if err := temporary.Chmod(0o600); err != nil {
		_ = temporary.Close()
		return fmt.Errorf("Zugriffsrechte der Node-Identitaet setzen: %w", err)
	}

	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		_ = temporary.Close()
		return fmt.Errorf("Node-Identitaet kodieren: %w", err)
	}
	if _, err := temporary.Write(data); err != nil {
		_ = temporary.Close()
		return fmt.Errorf("Node-Identitaet schreiben: %w", err)
	}
	if err := temporary.Sync(); err != nil {
		_ = temporary.Close()
		return fmt.Errorf("Node-Identitaet sichern: %w", err)
	}
	if err := temporary.Close(); err != nil {
		return fmt.Errorf("Node-Identitaet schliessen: %w", err)
	}
	if err := os.Rename(temporaryPath, path); err != nil {
		return fmt.Errorf("Node-Identitaet ersetzen: %w", err)
	}
	return nil
}

func validatePersistedIdentity(value persistedIdentity) error {
	if _, err := normalizeNodeID(value.NodeID); err != nil {
		return fmt.Errorf("gespeicherte %w", err)
	}
	if _, err := normalizeName(value.Name); err != nil {
		return fmt.Errorf("gespeicherter Node-Name: %w", err)
	}
	if _, err := normalizeToken(value.Token); err != nil {
		return fmt.Errorf("gespeicherter %w", err)
	}
	if value.CreatedAt.IsZero() {
		return fmt.Errorf("gespeicherte Node-Identitaet enthaelt kein Erstellungsdatum")
	}
	if value.GatewayKeyID != "" {
		if _, err := normalizeOpaqueValue(value.GatewayKeyID, "Gateway-Schluessel-ID", 1, maxTokenLength); err != nil {
			return fmt.Errorf("gespeicherte %w", err)
		}
	}
	return nil
}

func normalizeOptionalNodeID(value string) (string, error) {
	if value == "" {
		return "", nil
	}
	return normalizeNodeID(value)
}

func normalizeNodeID(value string) (string, error) {
	if value != strings.TrimSpace(value) {
		return "", fmt.Errorf("Node-ID darf keine fuehrenden oder nachgestellten Leerzeichen enthalten")
	}
	if length := utf8.RuneCountInString(value); length < 3 || length > maxNodeIDRunes {
		return "", fmt.Errorf("Node-ID muss zwischen 3 und %d Zeichen lang sein", maxNodeIDRunes)
	}
	for index, character := range value {
		isAlphaNumeric := character >= 'a' && character <= 'z' || character >= 'A' && character <= 'Z' || character >= '0' && character <= '9'
		if (!isAlphaNumeric && character != '-' && character != '_' && character != '.') || (index == 0 && !isAlphaNumeric) {
			return "", fmt.Errorf("Node-ID darf nur Buchstaben, Ziffern, Bindestriche, Unterstriche und Punkte enthalten")
		}
	}
	return value, nil
}

func normalizeOptionalName(value string) (string, error) {
	if value == "" {
		return "", nil
	}
	return normalizeName(value)
}

func normalizeName(value string) (string, error) {
	if value != strings.TrimSpace(value) {
		return "", fmt.Errorf("Node-Name darf keine fuehrenden oder nachgestellten Leerzeichen enthalten")
	}
	if length := utf8.RuneCountInString(value); length == 0 || length > maxNameRunes {
		return "", fmt.Errorf("Node-Name muss zwischen 1 und %d Zeichen lang sein", maxNameRunes)
	}
	for _, character := range value {
		if unicode.IsControl(character) {
			return "", fmt.Errorf("Node-Name darf keine Steuerzeichen enthalten")
		}
	}
	return value, nil
}

func normalizeOptionalToken(value string) (string, error) {
	if value == "" {
		return "", nil
	}
	return normalizeToken(value)
}

func normalizeToken(value string) (string, error) {
	return normalizeOpaqueValue(value, "Pairing-Token", minTokenLength, maxTokenLength)
}

func normalizeOpaqueValue(value, name string, minimum, maximum int) (string, error) {
	if value != strings.TrimSpace(value) {
		return "", fmt.Errorf("%s darf keine fuehrenden oder nachgestellten Leerzeichen enthalten", name)
	}
	if len(value) < minimum || len(value) > maximum {
		return "", fmt.Errorf("%s muss zwischen %d und %d Zeichen lang sein", name, minimum, maximum)
	}
	for _, character := range value {
		if character < 0x21 || character > 0x7e {
			return "", fmt.Errorf("%s darf nur druckbare ASCII-Zeichen ohne Leerzeichen enthalten", name)
		}
	}
	return value, nil
}

func normalizeVersion(value string) (string, error) {
	if value == "" {
		return defaultVersion, nil
	}
	if value != strings.TrimSpace(value) {
		return "", fmt.Errorf("Version darf keine fuehrenden oder nachgestellten Leerzeichen enthalten")
	}
	if length := utf8.RuneCountInString(value); length > maxVersionRunes {
		return "", fmt.Errorf("Version darf hoechstens %d Zeichen lang sein", maxVersionRunes)
	}
	for _, character := range value {
		if unicode.IsControl(character) {
			return "", fmt.Errorf("Version darf keine Steuerzeichen enthalten")
		}
	}
	return value, nil
}

func generateNodeID() (string, error) {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return "", fmt.Errorf("Node-ID erzeugen: %w", err)
	}
	return hex.EncodeToString(bytes), nil
}

func generateToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", fmt.Errorf("Pairing-Token erzeugen: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(bytes), nil
}
