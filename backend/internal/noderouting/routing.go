// Package noderouting contains the small contract shared by callers that
// route work to a remote Culpeo node.
//
// It deliberately knows nothing about pairing, WireGuard, or the node
// registry. Engine and marketplace only need a target, a way to obtain a
// connection, and stable identifiers. Keeping that boundary here lets a node
// backend remain an implementation detail instead of a dependency of the
// services it serves.
package noderouting

import (
	"fmt"
	"strings"

	"google.golang.org/grpc"
)

// Directory is the part of a node registry consumers use: which nodes to fan
// out to and how to reach one.
type Directory interface {
	// EnabledTargets lists the nodes that should take part in a merged view.
	EnabledTargets() []Target
	// LookupTarget resolves a single node, enabled or not, because a call that
	// names a node explicitly deserves a clearer answer than "not found".
	LookupTarget(nodeID string) (Target, bool)
	// Dial returns a connection to a node's gRPC control plane, authenticated
	// with its pairing token. The connection is pooled; it must not be closed
	// by the caller.
	Dial(nodeID string) (*grpc.ClientConn, error)
}

// Target is the immutable routing information another module needs to reach a
// node. A directory returns a copy so a caller never observes a registry
// mutation half-way through a request.
type Target struct {
	ID          string
	Name        string
	Address     string
	GRPCPort    int
	GatewayPort int
	Token       string
	// TLSFingerprint is set for a direct Node connection. Its SHA-256 leaf
	// certificate pin authorizes Dial to use a public endpoint without
	// falling back to the legacy WireGuard-only transport rule.
	TLSFingerprint string
	GatewayKey     string
	// GatewayBaseURL is what the node reported. It is preferred over building
	// one from Address and GatewayPort, because a node may serve its gateway
	// somewhere else entirely.
	GatewayBaseURL string
}

// Endpoint is the node's gRPC address inside the tunnel.
func (t Target) Endpoint() string {
	port := t.GRPCPort
	if port <= 0 {
		port = 50051
	}
	return joinHostPort(t.Address, port)
}

// GatewayURL is where the node's OpenAI gateway answers.
func (t Target) GatewayURL() string {
	if trimmed := strings.TrimSpace(t.GatewayBaseURL); trimmed != "" {
		return strings.TrimRight(trimmed, "/")
	}
	port := t.GatewayPort
	if port <= 0 {
		port = 8091
	}
	return "http://" + joinHostPort(t.Address, port)
}

// JoinHostPort joins a tunnel host and port while preserving the existing
// target formatting for bare IPv6 addresses. It is exported for the few
// boundary adapters that need to construct a bind address from node identity.
func JoinHostPort(host string, port int) string {
	return joinHostPort(host, port)
}

func joinHostPort(host string, port int) string {
	host = strings.TrimSpace(host)
	if strings.Contains(host, ":") && !strings.HasPrefix(host, "[") {
		// A bare IPv6 address needs brackets before a port can follow it.
		host = "[" + host + "]"
	}
	return fmt.Sprintf("%s:%d", host, port)
}

// idPrefix marks an identifier that belongs to a node rather than to this
// machine.
const idPrefix = "n:"

// Qualify turns a node's own identifier into one the Studio can carry around.
// An empty node id means this machine, and the identifier is left alone.
func Qualify(nodeID, id string) string {
	nodeID = strings.TrimSpace(nodeID)
	if nodeID == "" || id == "" {
		return id
	}
	return idPrefix + nodeID + ":" + id
}

// Split reads a qualified identifier back. It reports false for a local one,
// which is the common case and not an error.
func Split(id string) (nodeID, localID string, ok bool) {
	if !strings.HasPrefix(id, idPrefix) {
		return "", id, false
	}
	rest := strings.TrimPrefix(id, idPrefix)
	nodeID, localID, found := strings.Cut(rest, ":")
	if !found || strings.TrimSpace(nodeID) == "" || strings.TrimSpace(localID) == "" {
		// Shaped like a node id but unusable. Treating it as local would send
		// the call somewhere it does not belong, so it stays as it is and the
		// caller fails to find it.
		return "", id, false
	}
	return nodeID, localID, true
}

// NodeIDOf names the node an identifier belongs to, or the empty string when
// it belongs to this machine.
func NodeIDOf(id string) string {
	nodeID, _, _ := Split(id)
	return nodeID
}

// IsRemote reports whether an identifier names something on a node.
func IsRemote(id string) bool {
	_, _, ok := Split(id)
	return ok
}
