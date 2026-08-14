package node

import (
	"context"
	"fmt"
	"net"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
)

// remoteCallTimeout bounds every control call to a node. Downloads and model
// starts are scheduled by these calls rather than carried out inside them, so
// none of them is long-running.
const remoteCallTimeout = 20 * time.Second

// pooledConnection keeps one connection per node, together with the settings
// it was built from. When those change the connection is thrown away rather
// than reused against the wrong address or with a rotated token.
type pooledConnection struct {
	connection  *grpc.ClientConn
	fingerprint string
}

// bearerCredentials puts the node's pairing token on every call.
//
// RequireTransportSecurity is false on purpose: the connection runs inside a
// WireGuard tunnel, which already authenticates both ends by key and encrypts
// everything between them. Adding TLS on top would mean shipping a second
// certificate story for a link that is not reachable from anywhere else, and
// Dial refuses any address that is not the node's tunnel address.
type bearerCredentials struct {
	token string
}

func (c bearerCredentials) GetRequestMetadata(context.Context, ...string) (map[string]string, error) {
	return map[string]string{"authorization": "Bearer " + c.token}, nil
}

func (c bearerCredentials) RequireTransportSecurity() bool { return false }

// Dial returns the pooled connection to a node.
func (m *Module) Dial(nodeID string) (*grpc.ClientConn, error) {
	entry, ok := m.registry.get(nodeID)
	if !ok {
		return nil, errNodeUnknown
	}
	if !entry.Enabled {
		return nil, errNodeDisabled
	}
	target := targetFrom(entry)
	endpoint := target.Endpoint()
	if err := checkTunnelAddress(entry.Address); err != nil {
		return nil, err
	}

	fingerprint := endpoint + "|" + target.Token

	m.connectionsMu.Lock()
	defer m.connectionsMu.Unlock()
	if pooled, exists := m.connections[nodeID]; exists {
		if pooled.fingerprint == fingerprint {
			return pooled.connection, nil
		}
		_ = pooled.connection.Close()
		delete(m.connections, nodeID)
	}

	connection, err := grpc.NewClient(
		endpoint,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithPerRPCCredentials(bearerCredentials{token: target.Token}),
		// A node serves the same messages a local module does, and an engine
		// catalog on a well-stocked machine outgrows the four megabyte default.
		grpc.WithDefaultCallOptions(grpc.MaxCallRecvMsgSize(64<<20)),
	)
	if err != nil {
		return nil, fmt.Errorf("Verbindung zu %s: %w", target.Name, err)
	}
	m.connections[nodeID] = &pooledConnection{connection: connection, fingerprint: fingerprint}
	return connection, nil
}

// dropConnection forgets a node's connection, which is what removing or
// re-pairing one has to do.
func (m *Module) dropConnection(nodeID string) {
	m.connectionsMu.Lock()
	defer m.connectionsMu.Unlock()
	if pooled, exists := m.connections[nodeID]; exists {
		_ = pooled.connection.Close()
		delete(m.connections, nodeID)
	}
}

// checkTunnelAddress refuses to send a pairing token anywhere but into the
// tunnel. The token authorises downloads and model starts, and the transport
// is unencrypted by design, so a node address that is a public one is a
// misconfiguration worth failing on rather than a preference.
//
// A hostname is accepted: an operator who runs their own tunnel may well have
// named its far end in /etc/hosts, and a name cannot be judged here without
// resolving it, which would make an address check depend on DNS.
func checkTunnelAddress(address string) error {
	address = strings.TrimSpace(address)
	if address == "" {
		return fmt.Errorf("dem Node fehlt eine Adresse im Tunnel")
	}
	ip := net.ParseIP(address)
	if ip == nil {
		return nil
	}
	if ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() || ip.IsUnspecified() {
		return nil
	}
	return fmt.Errorf(
		"%s ist eine oeffentliche Adresse; ein Node wird ueber seine Tunnel-Adresse angesprochen, nicht direkt aus dem Internet",
		address,
	)
}

// agentClient is the node's own service: status and the gateway key.
func (m *Module) agentClient(nodeID string) (nodev1.NodeAgentServiceClient, error) {
	connection, err := m.Dial(nodeID)
	if err != nil {
		return nil, err
	}
	return nodev1.NewNodeAgentServiceClient(connection), nil
}

// classifyRemoteError turns what a node answered into the state the registry
// records. Telling "wrong token" apart from "no answer" is the difference
// between re-pairing and checking the tunnel.
func classifyRemoteError(err error) (state string, message string) {
	if err == nil {
		return stateOnline, ""
	}
	switch status.Code(err) {
	case codes.Unauthenticated, codes.PermissionDenied:
		return stateUnauthorized, "Der Node hat den Pairing-Token abgelehnt. Bitte den Node neu verbinden."
	case codes.Unavailable, codes.DeadlineExceeded:
		return stateOffline, "Der Node antwortet nicht. Steht der Tunnel, und laeuft dort das Backend?"
	default:
		if statusErr, ok := status.FromError(err); ok {
			return stateOffline, statusErr.Message()
		}
		return stateOffline, err.Error()
	}
}

// remoteContext bounds a call to a node. Everything the Studio asks a node is
// a control call - listing, starting, cancelling - and none of it should hang
// a screen when a tunnel drops mid-request.
func remoteContext(parent context.Context) (context.Context, context.CancelFunc) {
	return context.WithTimeout(parent, remoteCallTimeout)
}
