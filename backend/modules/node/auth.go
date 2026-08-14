package node

import (
	"context"
	"strings"
)

// nodeAgentPrefix is this module's own service. Only a node serves it.
const nodeAgentPrefix = "/culpeostudio.node.v1.NodeAgentService/"

// pairedMethodPrefixes are the services a paired Studio may call on a node.
//
// The list is short on purpose. A pairing token is not a login: it lets one
// Studio put models on this machine and run them, and nothing else. Memory,
// scouts, chats, accounts and the node's own registry stay out of reach, so a
// token that leaks cannot read what the machine's owner keeps on it.
var pairedMethodPrefixes = []string{
	nodeAgentPrefix,
	"/culpeostudio.engine.v1.EngineService/",
	"/culpeostudio.marketplace.v1.MarketplaceService/",
}

// pairedMethodDenylist takes back the calls inside those services that a
// Studio has no business making on someone else's machine: the node's gateway
// keys are its own, and are handed out through IssueGatewayKey instead.
var pairedMethodDenylist = map[string]bool{
	"/culpeostudio.engine.v1.EngineService/ListKeys":      true,
	"/culpeostudio.engine.v1.EngineService/CreateKey":     true,
	"/culpeostudio.engine.v1.EngineService/RotateKey":     true,
	"/culpeostudio.engine.v1.EngineService/RevokeKey":     true,
	"/culpeostudio.engine.v1.EngineService/ExportPresets": true,
	"/culpeostudio.engine.v1.EngineService/ImportPresets": true,
}

// AuthenticateGRPCToken accepts a node's pairing token on the calls a paired
// Studio is allowed to make. It fits the AlternateAuth hook the gRPC
// middleware asks once a bearer token has failed to verify as a session JWT,
// which is the same door the memory module's API token comes through.
//
// It answers for nothing unless this backend runs in node mode: a Studio has
// no pairing token of its own, and should not start honouring one.
func (m *Module) AuthenticateGRPCToken(_ context.Context, fullMethod, token string) (string, bool) {
	if !m.nodeMode {
		return "", false
	}
	if !m.identity.matches(token) {
		return "", false
	}
	if !pairedMethodAllowed(fullMethod) {
		return "", false
	}
	current, ok := m.identity.get()
	if !ok {
		return "", false
	}
	// The calls act for the node itself rather than for a user account: a node
	// has no accounts, and the modules only use the id to scope what they
	// store.
	return "node:" + current.NodeID, true
}

func pairedMethodAllowed(fullMethod string) bool {
	if pairedMethodDenylist[fullMethod] {
		return false
	}
	for _, prefix := range pairedMethodPrefixes {
		if strings.HasPrefix(fullMethod, prefix) {
			return true
		}
	}
	return false
}
