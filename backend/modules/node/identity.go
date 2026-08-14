package node

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// identity is what a machine in node mode knows about itself: the token a
// Studio authenticates with, and the tunnel it printed a join code for.
//
// It is written once and kept. Regenerating it would invalidate every join
// code already handed out and orphan the tunnel on the Studio side, so a node
// that has been paired keeps its identity across restarts and upgrades.
type identity struct {
	NodeID    string    `json:"node_id"`
	Name      string    `json:"name"`
	Token     string    `json:"token"`
	CreatedAt time.Time `json:"created_at"`

	// The WireGuard side. Empty when the node has no public endpoint
	// configured: it can still be added by hand by an operator who runs their
	// own tunnel, it just cannot print a join code.
	InterfaceName string `json:"interface_name,omitempty"`
	ConfigPath    string `json:"config_path,omitempty"`
	NodeAddress   string `json:"node_address,omitempty"`
	ClientAddress string `json:"client_address,omitempty"`
	Endpoint      string `json:"endpoint,omitempty"`
	JoinCode      string `json:"join_code,omitempty"`

	// GatewayKeyID names the engine key handed to the paired Studio, so
	// issuing a new one can revoke the old.
	GatewayKeyID string `json:"gateway_key_id,omitempty"`
}

type identityStore struct {
	mu      sync.RWMutex
	path    string
	current identity
	loaded  bool
}

func newIdentityStore(path string) *identityStore {
	return &identityStore{path: path}
}

func (s *identityStore) load() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	data, err := os.ReadFile(s.path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return fmt.Errorf("Node-Identitaet lesen: %w", err)
	}
	var stored identity
	if err := json.Unmarshal(data, &stored); err != nil {
		return fmt.Errorf("Node-Identitaet lesen: %w", err)
	}
	if strings.TrimSpace(stored.NodeID) == "" || strings.TrimSpace(stored.Token) == "" {
		return nil
	}
	s.current = stored
	s.loaded = true
	return nil
}

func (s *identityStore) get() (identity, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.current, s.loaded
}

func (s *identityStore) save(value identity) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return fmt.Errorf("Node-Identitaet schreiben: %w", err)
	}
	if err := os.MkdirAll(filepath.Dir(s.path), 0o700); err != nil {
		return fmt.Errorf("Node-Identitaet schreiben: %w", err)
	}
	temporary := s.path + ".tmp"
	if err := os.WriteFile(temporary, data, 0o600); err != nil {
		return fmt.Errorf("Node-Identitaet schreiben: %w", err)
	}
	if err := os.Rename(temporary, s.path); err != nil {
		_ = os.Remove(temporary)
		return fmt.Errorf("Node-Identitaet schreiben: %w", err)
	}
	s.current = value
	s.loaded = true
	return nil
}

// update mutates the stored identity and writes it back.
func (s *identityStore) update(mutate func(*identity)) (identity, error) {
	current, ok := s.get()
	if !ok {
		return identity{}, fmt.Errorf("dieser Rechner laeuft nicht im Node-Modus")
	}
	mutate(&current)
	if err := s.save(current); err != nil {
		return identity{}, err
	}
	return current, nil
}

// matches reports whether a presented token is this node's. The comparison is
// a plain one: the token is a 32-byte random value, so there is nothing to
// guess a byte at a time.
func (s *identityStore) matches(token string) bool {
	token = strings.TrimSpace(token)
	if token == "" {
		return false
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.loaded && s.current.Token == token
}
