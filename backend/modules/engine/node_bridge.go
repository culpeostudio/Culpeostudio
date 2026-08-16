package engine

import (
	"fmt"
	"log"
	"strings"
)

// This file is the engine's side of node mode: what a node's agent reports
// about the engine, and the one thing a node has to do differently - serve its
// gateway on the tunnel rather than on loopback.

// EnableNodeGateway points the OpenAI gateway at the node's address in the
// tunnel and makes sure it has a key to accept.
//
// The gateway refuses to serve beyond loopback without a key, which is the
// right default: a keyless gateway on a network address would hand every model
// on the machine to anyone who can reach it. A node needs one before the
// Studio can ask for its own, so one is created at startup if the store is
// empty. Nothing is printed: the key is handed out over the tunnel by
// IssueGatewayKey, and a secret in a log file is a secret in a backup.
func (m *EngineModule) EnableNodeGateway(address string) {
	address = strings.TrimSpace(address)
	if address == "" {
		return
	}
	m.gatewayBind = address
	m.gatewayNeedsBootstrapKey = true
}

// SetGatewayBind selects the local address of the Engine's OpenAI-compatible
// gateway before Initialize starts it.  A standalone Node uses a loopback
// listener with an ephemeral port and exposes it only through its own pinned
// TLS proxy; unlike EnableNodeGateway this does not permit a network bind.
func (m *EngineModule) SetGatewayBind(address string) {
	address = strings.TrimSpace(address)
	if address == "" {
		return
	}
	m.gatewayBind = address
}

// ensureBootstrapGatewayKey creates the first key of a node, so the gateway
// may bind to a network address at all.
func (m *EngineModule) ensureBootstrapGatewayKey() error {
	if !m.gatewayNeedsBootstrapKey || m.keys == nil {
		return nil
	}
	if len(m.keys.list()) > 0 {
		return nil
	}
	if _, _, err := m.keys.create("Node-Gateway", nil); err != nil {
		return fmt.Errorf("Gateway-Schluessel fuer den Node-Modus anlegen: %w", err)
	}
	log.Printf("[engine] Node-Modus: Gateway-Schluessel angelegt, Gateway bindet an %s", m.gatewayBind)
	return nil
}

// IssueGatewayKey hands the paired Studio a key for this node's gateway and
// revokes the one it had. It fills the node agent's bridge.
//
// The key is unscoped on purpose: a Studio that may start any model on this
// node may also talk to any of them, and a scope that had to be rewritten on
// every start would only be a second place for the two to disagree.
func (m *EngineModule) IssueGatewayKey(label string) (string, string, error) {
	if m.keys == nil {
		return "", "", fmt.Errorf("der Schluesselspeicher der Engine ist nicht bereit")
	}
	label = strings.TrimSpace(label)
	if label == "" {
		label = "Culpeo Studio"
	}
	for _, existing := range m.keys.list() {
		if strings.EqualFold(existing.Name, label) {
			m.keys.revoke(existing.ID)
		}
	}
	public, plaintext, err := m.keys.create(label, nil)
	if err != nil {
		return "", "", err
	}
	return public.ID, plaintext, nil
}

// GatewayBaseURL is where this machine's OpenAI gateway answers, or empty when
// it is not serving.
func (m *EngineModule) GatewayBaseURL() string { return m.gatewayURL }

// CatalogSize is how many models this machine holds.
func (m *EngineModule) CatalogSize() int {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return len(m.models)
}

// InstanceCount is how many instances it currently has.
func (m *EngineModule) InstanceCount() int {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return len(m.instances)
}

// ModelDir is where this machine keeps its models. A Studio shows it so the
// operator can tell which disk a download will land on.
func (m *EngineModule) ModelDir() string {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.modelDir
}
