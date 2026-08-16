package node

import (
	"fmt"
	"net/netip"
	"os"
	"strings"
)

// manualTunnelAddressEnv is the node-side address of a tunnel that an
// operator manages outside Culpeo. It is deliberately an address, not a
// network: the control plane and the gateway must bind to one interface, not
// to every interface on the host.
const manualTunnelAddressEnv = "CULPEO_NODE_TUNNEL_ADDRESS"

// manualTunnelAddress reads the one address a manually tunnelled node may
// expose. A pairing token travels over this connection without TLS, because
// the tunnel provides transport security. Consequently a public, wildcard,
// loopback, link-local, hostname, port, or CIDR must never be accepted here.
//
// netip.Addr.IsPrivate is intentionally stricter than the Studio-side target
// check: this is a server bind address, so a routable public address would
// make the node's gRPC control plane and model gateway reachable outside the
// private tunnel. It admits RFC 1918 IPv4 and IPv6 unique-local addresses.
func manualTunnelAddress() (string, error) {
	raw := strings.TrimSpace(os.Getenv(manualTunnelAddressEnv))
	if raw == "" {
		return "", fmt.Errorf("%s muss gesetzt sein, wenn CULPEO_NODE_WG_ENDPOINT fehlt", manualTunnelAddressEnv)
	}
	address, err := netip.ParseAddr(raw)
	if err != nil {
		return "", fmt.Errorf("%s muss eine einzelne private IP-Adresse ohne Port oder Netzmaske sein", manualTunnelAddressEnv)
	}
	address = address.Unmap()
	if !address.IsPrivate() {
		return "", fmt.Errorf("%s=%q ist keine private Tunnel-Adresse (erlaubt sind RFC1918-IPv4 oder IPv6-ULA)", manualTunnelAddressEnv, raw)
	}
	return address.String(), nil
}
