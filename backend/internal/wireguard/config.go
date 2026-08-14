package wireguard

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net"
	"strconv"
	"strings"
)

// joinCodePrefix marks a join code as ours. Without it a mistyped paste ends
// as an opaque base64 error; with it the Studio can say what was expected.
const joinCodePrefix = "culpeonode1_"

// JoinCodeVersion is the only shape read here. A node that speaks a later one
// is rejected by name rather than mis-parsed.
const JoinCodeVersion = 1

// JoinCode is everything a Studio needs to reach a node, as the node's own
// setup wrote it.
//
// It carries the client's private key. The node generates both key pairs
// because there is no channel to the Studio before the tunnel exists - a
// Studio cannot hand over its public key over a tunnel that is not up yet.
// That makes the join code exactly as sensitive as the config file it
// contains, and it is meant to be moved the same careful way.
type JoinCode struct {
	Version       int    `json:"v"`
	NodeID        string `json:"node_id"`
	Name          string `json:"name"`
	Token         string `json:"token"`
	GRPCPort      int    `json:"grpc_port"`
	GatewayPort   int    `json:"gateway_port"`
	InterfaceName string `json:"interface"`
	// NodeAddress is the node's address inside the tunnel, without a mask.
	NodeAddress string `json:"node_address"`
	// LocalAddress is the address the Studio takes inside the tunnel, with its
	// mask, as it goes into the config.
	LocalAddress  string `json:"local_address"`
	PeerPublicKey string `json:"peer_public_key"`
	Endpoint      string `json:"endpoint"`
	// TunnelConfig is the complete client-side config file.
	TunnelConfig string `json:"tunnel_config"`
}

// Encode renders a join code as the single line a node prints.
func (c JoinCode) Encode() (string, error) {
	if c.Version == 0 {
		c.Version = JoinCodeVersion
	}
	raw, err := json.Marshal(c)
	if err != nil {
		return "", fmt.Errorf("Join-Code kodieren: %w", err)
	}
	return joinCodePrefix + base64.RawURLEncoding.EncodeToString(raw), nil
}

// DecodeJoinCode reads back what Encode wrote and checks that every field the
// Studio will act on is present. Whitespace is tolerated: the code travels by
// copy and paste and often arrives wrapped.
func DecodeJoinCode(value string) (JoinCode, error) {
	trimmed := strings.Join(strings.Fields(value), "")
	if trimmed == "" {
		return JoinCode{}, fmt.Errorf("Join-Code ist leer")
	}
	if !strings.HasPrefix(trimmed, joinCodePrefix) {
		return JoinCode{}, fmt.Errorf("das ist kein Culpeo-Join-Code; erwartet wird eine Zeile, die mit %s beginnt", joinCodePrefix)
	}
	raw, err := base64.RawURLEncoding.DecodeString(strings.TrimPrefix(trimmed, joinCodePrefix))
	if err != nil {
		return JoinCode{}, fmt.Errorf("Join-Code ist beschaedigt; bitte die ganze Zeile kopieren")
	}
	var code JoinCode
	if err := json.Unmarshal(raw, &code); err != nil {
		return JoinCode{}, fmt.Errorf("Join-Code ist beschaedigt; bitte die ganze Zeile kopieren")
	}
	if code.Version != JoinCodeVersion {
		return JoinCode{}, fmt.Errorf("Join-Code hat Version %d, diese Studio-Version liest Version %d", code.Version, JoinCodeVersion)
	}
	if strings.TrimSpace(code.NodeID) == "" || strings.TrimSpace(code.Token) == "" {
		return JoinCode{}, fmt.Errorf("Join-Code ist unvollstaendig: Node-Kennung oder Token fehlt")
	}
	if net.ParseIP(strings.TrimSpace(code.NodeAddress)) == nil {
		return JoinCode{}, fmt.Errorf("Join-Code enthaelt keine gueltige Node-Adresse im Tunnel")
	}
	if !ValidKey(strings.TrimSpace(code.PeerPublicKey)) {
		return JoinCode{}, fmt.Errorf("Join-Code enthaelt keinen gueltigen WireGuard-Schluessel")
	}
	if strings.TrimSpace(code.TunnelConfig) == "" {
		return JoinCode{}, fmt.Errorf("Join-Code enthaelt keine Tunnel-Konfiguration")
	}
	if code.GRPCPort <= 0 {
		code.GRPCPort = 50051
	}
	if code.GatewayPort <= 0 {
		code.GatewayPort = 8091
	}
	return code, nil
}

// InterfaceConfig is one side of a tunnel, in the terms wg-quick reads.
type InterfaceConfig struct {
	PrivateKey string
	// Address carries its mask, e.g. 10.77.0.2/32.
	Address string
	// ListenPort is written only for the side that is dialled, which is the
	// node. Zero leaves it out, and WireGuard picks a port.
	ListenPort int

	PeerPublicKey string
	// PeerEndpoint is empty on the node: it does not know where a Studio dials
	// from, and does not need to.
	PeerEndpoint string
	AllowedIPs   string
	// Keepalive holds a NAT mapping open. Only the side behind NAT needs it,
	// which is the Studio.
	Keepalive int
}

// Render writes the config file. The output is deliberately plain: it is meant
// to be readable by whoever has to check what the Studio put on their machine.
func (c InterfaceConfig) Render() string {
	var builder strings.Builder
	builder.WriteString("[Interface]\n")
	builder.WriteString("PrivateKey = " + c.PrivateKey + "\n")
	builder.WriteString("Address = " + c.Address + "\n")
	if c.ListenPort > 0 {
		builder.WriteString("ListenPort = " + strconv.Itoa(c.ListenPort) + "\n")
	}
	builder.WriteString("\n[Peer]\n")
	builder.WriteString("PublicKey = " + c.PeerPublicKey + "\n")
	if strings.TrimSpace(c.PeerEndpoint) != "" {
		builder.WriteString("Endpoint = " + c.PeerEndpoint + "\n")
	}
	builder.WriteString("AllowedIPs = " + c.AllowedIPs + "\n")
	if c.Keepalive > 0 {
		builder.WriteString("PersistentKeepalive = " + strconv.Itoa(c.Keepalive) + "\n")
	}
	return builder.String()
}

// InterfaceName builds the interface name for a node. Linux allows fifteen
// characters for one, and wg-quick takes the name from the file it is given,
// so the name decides what the config file may be called.
func InterfaceName(nodeID string) string {
	cleaned := strings.Map(func(r rune) rune {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9':
			return r
		case r >= 'A' && r <= 'Z':
			return r + ('a' - 'A')
		default:
			return -1
		}
	}, nodeID)
	if cleaned == "" {
		cleaned = "node"
	}
	if len(cleaned) > 8 {
		cleaned = cleaned[:8]
	}
	return "culpeo-" + cleaned
}

// TunnelAddresses splits a /24 into the node's address and the Studio's. The
// node takes .1 and the Studio .2, which is enough for the one peer a node
// currently accepts and keeps the config readable.
func TunnelAddresses(network string) (nodeAddress, clientAddress, allowedIPs string, err error) {
	network = strings.TrimSpace(network)
	if network == "" {
		network = "10.77.0.0/24"
	}
	ip, subnet, parseErr := net.ParseCIDR(network)
	if parseErr != nil {
		return "", "", "", fmt.Errorf("ungueltiges Tunnel-Netz %q: %w", network, parseErr)
	}
	base := ip.Mask(subnet.Mask).To4()
	if base == nil {
		return "", "", "", fmt.Errorf("Tunnel-Netz %q ist kein IPv4-Netz", network)
	}
	ones, bits := subnet.Mask.Size()
	if bits-ones < 2 {
		return "", "", "", fmt.Errorf("Tunnel-Netz %q ist zu klein fuer zwei Adressen", network)
	}
	nodeIP := make(net.IP, len(base))
	copy(nodeIP, base)
	nodeIP[3] |= 1
	clientIP := make(net.IP, len(base))
	copy(clientIP, base)
	clientIP[3] |= 2
	return nodeIP.String(), clientIP.String() + "/32", subnet.String(), nil
}
