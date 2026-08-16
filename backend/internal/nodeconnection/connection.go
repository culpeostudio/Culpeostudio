// Package nodeconnection defines the one string a Culpeo Node hands to a
// Studio.  It deliberately carries everything the Studio needs to make its
// first, pinned TLS connection, so an operator never has to transcribe a host,
// port, certificate fingerprint, and token into separate fields.
package nodeconnection

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net"
	"strconv"
	"strings"
)

const (
	// Prefix distinguishes a direct Node connection from the retired
	// WireGuard join-code format.  The payload is base64url JSON so it is safe
	// to paste through terminals, QR scanners, and chat-free clipboard flows.
	Prefix = "culpeo-node://pair/"

	version = 1
)

// Connection is the verified first-contact information for a Node. Endpoint
// is a host:port pair, Fingerprint is the lowercase SHA-256 digest of the
// Node's DER leaf certificate, and Token authorizes the Studio's Node,
// Engine, and Marketplace calls after TLS is pinned. NodeID is the stable
// identity the Node persists across address changes; old version-1 links may
// omit it and still pair normally.
type Connection struct {
	NodeID      string
	Endpoint    string
	Fingerprint string
	Token       string
	Name        string
}

type encodedConnection struct {
	Version     int    `json:"v"`
	NodeID      string `json:"node_id,omitempty"`
	Endpoint    string `json:"endpoint"`
	Fingerprint string `json:"fingerprint"`
	Token       string `json:"token"`
	Name        string `json:"name,omitempty"`
}

// Encode produces the single connection link shown by a freshly installed
// Node. The link is a credential: it must be treated like a password and
// shared only with the Studio that is allowed to control this Node.
func Encode(connection Connection) (string, error) {
	normalized, err := normalize(connection)
	if err != nil {
		return "", err
	}
	payload, err := json.Marshal(encodedConnection{
		Version:     version,
		NodeID:      normalized.NodeID,
		Endpoint:    normalized.Endpoint,
		Fingerprint: normalized.Fingerprint,
		Token:       normalized.Token,
		Name:        normalized.Name,
	})
	if err != nil {
		return "", fmt.Errorf("Node-Verbindungslink kodieren: %w", err)
	}
	return Prefix + base64.RawURLEncoding.EncodeToString(payload), nil
}

// Decode validates and normalizes a connection link. It never dials the
// endpoint; the Studio does that only after it has pinned the fingerprint.
func Decode(raw string) (Connection, error) {
	compact := strings.Join(strings.Fields(raw), "")
	if compact == "" {
		return Connection{}, fmt.Errorf("Node-Verbindungslink ist leer")
	}
	if !strings.HasPrefix(compact, Prefix) {
		return Connection{}, fmt.Errorf("kein Culpeo-Node-Verbindungslink; erwartet wird %s…", Prefix)
	}
	payload, err := base64.RawURLEncoding.DecodeString(strings.TrimPrefix(compact, Prefix))
	if err != nil {
		return Connection{}, fmt.Errorf("Node-Verbindungslink ist beschaedigt; bitte vollstaendig kopieren")
	}
	var encoded encodedConnection
	if err := json.Unmarshal(payload, &encoded); err != nil {
		return Connection{}, fmt.Errorf("Node-Verbindungslink ist beschaedigt; bitte vollstaendig kopieren")
	}
	if encoded.Version != version {
		return Connection{}, fmt.Errorf("Node-Verbindungslink hat Version %d, erwartet wird Version %d", encoded.Version, version)
	}
	return normalize(Connection{
		NodeID:      encoded.NodeID,
		Endpoint:    encoded.Endpoint,
		Fingerprint: encoded.Fingerprint,
		Token:       encoded.Token,
		Name:        encoded.Name,
	})
}

// NormalizeFingerprint validates a SHA-256 certificate fingerprint and
// returns its canonical lowercase hexadecimal form. A sha256: prefix is
// accepted for clear terminal output but is not stored in a connection.
func NormalizeFingerprint(value string) (string, error) {
	value = strings.TrimSpace(strings.TrimPrefix(strings.ToLower(strings.TrimSpace(value)), "sha256:"))
	if len(value) != 64 {
		return "", fmt.Errorf("TLS-Fingerprint muss aus 64 Hex-Zeichen bestehen")
	}
	if _, err := hex.DecodeString(value); err != nil {
		return "", fmt.Errorf("TLS-Fingerprint ist nicht hexadezimal")
	}
	return value, nil
}

func normalize(connection Connection) (Connection, error) {
	nodeID, err := normalizeNodeID(connection.NodeID)
	if err != nil {
		return Connection{}, err
	}
	endpoint, err := normalizeEndpoint(connection.Endpoint)
	if err != nil {
		return Connection{}, err
	}
	fingerprint, err := NormalizeFingerprint(connection.Fingerprint)
	if err != nil {
		return Connection{}, err
	}
	token := strings.TrimSpace(connection.Token)
	if len(token) < 24 || len(token) > 512 || strings.ContainsAny(token, " \t\r\n") {
		return Connection{}, fmt.Errorf("Node-Token muss 24 bis 512 Zeichen ohne Leerzeichen enthalten")
	}
	name := strings.TrimSpace(connection.Name)
	if len(name) > 128 {
		return Connection{}, fmt.Errorf("Node-Name darf hoechstens 128 Zeichen enthalten")
	}
	return Connection{NodeID: nodeID, Endpoint: endpoint, Fingerprint: fingerprint, Token: token, Name: name}, nil
}

func normalizeNodeID(value string) (string, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return "", nil // compatible with early direct links
	}
	if len(value) < 3 || len(value) > 128 {
		return "", fmt.Errorf("Node-ID muss zwischen 3 und 128 Zeichen lang sein")
	}
	for index, character := range value {
		isAlphaNumeric := character >= 'a' && character <= 'z' || character >= 'A' && character <= 'Z' || character >= '0' && character <= '9'
		if (!isAlphaNumeric && character != '-' && character != '_' && character != '.') || (index == 0 && !isAlphaNumeric) {
			return "", fmt.Errorf("Node-ID darf nur Buchstaben, Ziffern, Bindestriche, Unterstriche und Punkte enthalten")
		}
	}
	return value, nil
}

func normalizeEndpoint(value string) (string, error) {
	value = strings.TrimSpace(value)
	host, port, err := net.SplitHostPort(value)
	if err != nil || strings.TrimSpace(host) == "" {
		return "", fmt.Errorf("Node-Endpunkt muss Host:Port sein")
	}
	parsedPort, err := strconv.Atoi(port)
	if err != nil || parsedPort < 1 || parsedPort > 65535 {
		return "", fmt.Errorf("Node-Endpunkt hat keinen gueltigen Port")
	}
	if ip := net.ParseIP(host); ip != nil && ip.IsUnspecified() {
		return "", fmt.Errorf("Node-Endpunkt darf keine Wildcard-Adresse sein")
	}
	return net.JoinHostPort(strings.TrimSpace(host), strconv.Itoa(parsedPort)), nil
}
