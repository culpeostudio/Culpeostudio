package wireguard

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"net"
	"strconv"
	"strings"
)

// DefaultNetwork is kept for callers of TunnelAddresses that do not have a
// node identity. Pair never uses it for a new node: a static default caused
// every independently installed node to claim the same route.
const DefaultNetwork = "10.77.0.0/24"

// DefaultListenPort is the UDP port a node listens on when none is configured.
const DefaultListenPort = 51820

// PairingRequest is what a node knows about itself when it prepares to be
// paired.
type PairingRequest struct {
	NodeID      string
	Name        string
	Token       string
	GRPCPort    int
	GatewayPort int
	// Network is the tunnel network. When it is empty Pair derives a stable,
	// node-specific /30 from NodeID. An explicit value remains an operator
	// override for networks managed outside the automatic allocation.
	Network string
	// Endpoint is where the Studio dials the node, as host:port. It cannot be
	// detected: a node behind NAT is reached at an address only its operator
	// knows, so it is configured.
	Endpoint   string
	ListenPort int
}

// Pairing is both sides of a freshly built tunnel.
type Pairing struct {
	// JoinCode is the single line the node prints for the Studio.
	JoinCode string
	// NodeConfig is the config the node itself has to bring up.
	NodeConfig string
	// ClientConfig is what the Studio will write. It also travels inside the
	// join code; it is returned separately so the node can show what it handed
	// out.
	ClientConfig  string
	InterfaceName string
	NodeAddress   string
	ClientAddress string
	// Network is the canonical CIDR routed by this pair.
	Network    string
	NodeKeys   KeyPair
	ClientKeys KeyPair
}

// Pair draws both key pairs and renders both configs.
//
// The node holding the Studio's private key for the length of one printed join
// code is what makes pairing possible at all: the Studio cannot announce a
// public key over a tunnel that does not exist yet, and a node with no inbound
// path cannot be told one later. The key is not kept - only the Studio's public
// key stays behind, in the node's own config.
func Pair(request PairingRequest) (Pairing, error) {
	nodeID := strings.TrimSpace(request.NodeID)
	if nodeID == "" {
		return Pairing{}, fmt.Errorf("Node-Kennung fehlt")
	}
	if strings.TrimSpace(request.Token) == "" {
		return Pairing{}, fmt.Errorf("Pairing-Token fehlt")
	}
	endpoint, err := normalizeEndpoint(request.Endpoint, request.ListenPort)
	if err != nil {
		return Pairing{}, err
	}
	network := strings.TrimSpace(request.Network)
	if network == "" {
		network = AutomaticNetwork(nodeID)
	}
	nodeAddress, clientAddress, allowedIPs, err := TunnelAddresses(network)
	if err != nil {
		return Pairing{}, err
	}
	listenPort := request.ListenPort
	if listenPort <= 0 {
		listenPort = DefaultListenPort
	}
	grpcPort := request.GRPCPort
	if grpcPort <= 0 {
		grpcPort = 50051
	}
	gatewayPort := request.GatewayPort
	if gatewayPort <= 0 {
		gatewayPort = 8091
	}

	nodeKeys, err := GenerateKeyPair()
	if err != nil {
		return Pairing{}, err
	}
	clientKeys, err := GenerateKeyPair()
	if err != nil {
		return Pairing{}, err
	}

	interfaceName := InterfaceName(nodeID)
	// The node holds the whole tunnel network, so its address keeps the mask
	// the network was carved from.
	nodeMask := allowedIPs[strings.LastIndex(allowedIPs, "/"):]
	nodeConfig := InterfaceConfig{
		PrivateKey: nodeKeys.PrivateKey,
		Address:    nodeAddress + nodeMask,
		ListenPort: listenPort,

		PeerPublicKey: clientKeys.PublicKey,
		AllowedIPs:    clientAddress,
	}.Render()

	clientConfig := InterfaceConfig{
		PrivateKey: clientKeys.PrivateKey,
		Address:    clientAddress,

		PeerPublicKey: nodeKeys.PublicKey,
		PeerEndpoint:  endpoint,
		AllowedIPs:    allowedIPs,
		// The Studio is the side that dials, so it is the side that has to keep
		// a NAT mapping alive.
		Keepalive: 25,
	}.Render()

	code := JoinCode{
		Version:       JoinCodeVersion,
		NodeID:        nodeID,
		Name:          strings.TrimSpace(request.Name),
		Token:         strings.TrimSpace(request.Token),
		GRPCPort:      grpcPort,
		GatewayPort:   gatewayPort,
		InterfaceName: interfaceName,
		NodeAddress:   nodeAddress,
		LocalAddress:  clientAddress,
		Network:       allowedIPs,
		PeerPublicKey: nodeKeys.PublicKey,
		Endpoint:      endpoint,
		TunnelConfig:  clientConfig,
	}
	encoded, err := code.Encode()
	if err != nil {
		return Pairing{}, err
	}

	return Pairing{
		JoinCode:      encoded,
		NodeConfig:    nodeConfig,
		ClientConfig:  clientConfig,
		InterfaceName: interfaceName,
		NodeAddress:   nodeAddress,
		ClientAddress: clientAddress,
		Network:       allowedIPs,
		NodeKeys:      nodeKeys,
		ClientKeys:    clientKeys,
	}, nil
}

// AutomaticNetwork derives a stable, dedicated /30 in 10.0.0.0/8 for a
// node. A /30 is exactly large enough for the node and its Studio, and the
// full private /8 yields more than four million possible tunnel networks.
//
// Node IDs are random, but this remains deterministic so a restart preserves
// a node's address. The Studio still rejects any collision (including a
// deliberate explicit override) before it writes the second config.
func AutomaticNetwork(nodeID string) string {
	digest := sha256.Sum256([]byte("culpeo-wireguard-network-v1:" + strings.TrimSpace(nodeID)))
	slot := binary.BigEndian.Uint32(digest[:4]) & ((1 << 22) - 1)
	return fmt.Sprintf(
		"10.%d.%d.%d/30",
		(slot>>14)&0xff,
		(slot>>6)&0xff,
		(slot&0x3f)<<2,
	)
}

// normalizeEndpoint accepts a bare host and fills in the listen port, because
// the port is the part an operator forgets.
func normalizeEndpoint(endpoint string, listenPort int) (string, error) {
	endpoint = strings.TrimSpace(endpoint)
	if endpoint == "" {
		return "", fmt.Errorf("die oeffentliche Adresse des Nodes fehlt; sie kann nicht erraten werden und wird als CULPEO_NODE_WG_ENDPOINT gesetzt")
	}
	if listenPort <= 0 {
		listenPort = DefaultListenPort
	}
	if host, port, err := net.SplitHostPort(endpoint); err == nil {
		if strings.TrimSpace(host) == "" {
			return "", fmt.Errorf("die oeffentliche Adresse des Nodes enthaelt keinen Host")
		}
		if _, convErr := strconv.Atoi(port); convErr != nil {
			return "", fmt.Errorf("die oeffentliche Adresse des Nodes hat keinen gueltigen Port")
		}
		return endpoint, nil
	}
	// A bare IPv6 address has to be bracketed before a port can be appended.
	if ip := net.ParseIP(endpoint); ip != nil && ip.To4() == nil {
		return "[" + endpoint + "]:" + strconv.Itoa(listenPort), nil
	}
	return endpoint + ":" + strconv.Itoa(listenPort), nil
}
