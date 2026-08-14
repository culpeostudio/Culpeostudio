package node

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// storedTunnel is the WireGuard side of a node as this Studio wrote it.
// Managed is false for a node whose tunnel someone set up by hand: then the
// Studio only knows where to send things and touches no interface.
type storedTunnel struct {
	InterfaceName string `json:"interface_name,omitempty"`
	ConfigPath    string `json:"config_path,omitempty"`
	LocalAddress  string `json:"local_address,omitempty"`
	Endpoint      string `json:"endpoint,omitempty"`
	PeerPublicKey string `json:"peer_public_key,omitempty"`
	Managed       bool   `json:"managed"`
}

// storedNode is one entry of the registry. The token and the gateway key are
// secrets, which is why the whole file is written 0600 and never leaves the
// backend: the client is told whether a node is paired, not with what.
type storedNode struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Address     string `json:"address"`
	GRPCPort    int    `json:"grpc_port"`
	GatewayPort int    `json:"gateway_port"`
	Enabled     bool   `json:"enabled"`

	Token          string `json:"token"`
	GatewayKeyID   string `json:"gateway_key_id,omitempty"`
	GatewayKey     string `json:"gateway_key,omitempty"`
	GatewayBaseURL string `json:"gateway_base_url,omitempty"`

	Tunnel storedTunnel `json:"tunnel"`

	AddedAt    time.Time `json:"added_at"`
	LastSeenAt time.Time `json:"last_seen_at,omitempty"`

	// What the last successful probe reported. It is cached so a list does not
	// have to reach out to every node, and so a node that has just gone quiet
	// still shows what it had.
	State         string `json:"state,omitempty"`
	StatusMessage string `json:"status_message,omitempty"`
	Version       string `json:"version,omitempty"`
	ModelDir      string `json:"model_dir,omitempty"`
	ModelCount    int    `json:"model_count,omitempty"`
	InstanceCount int    `json:"instance_count,omitempty"`
	DiskFreeBytes int64  `json:"disk_free_bytes,omitempty"`
	// HardwareProto is the last hardware profile, marshalled. Keeping it in its
	// wire form avoids a second Go shape for something the client only ever
	// receives as it was sent.
	HardwareProto []byte `json:"hardware_proto,omitempty"`
}

// Target is what another module needs to reach a node. It is a copy: a caller
// holding one while the registry changes underneath is reading a stale address
// at worst, never a half-written one.
type Target struct {
	ID          string
	Name        string
	Address     string
	GRPCPort    int
	GatewayPort int
	Token       string
	GatewayKey  string
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

func joinHostPort(host string, port int) string {
	host = strings.TrimSpace(host)
	if strings.Contains(host, ":") && !strings.HasPrefix(host, "[") {
		// A bare IPv6 address needs brackets before a port can follow it.
		host = "[" + host + "]"
	}
	return fmt.Sprintf("%s:%d", host, port)
}

type registry struct {
	mu    sync.RWMutex
	path  string
	nodes map[string]*storedNode
	order []string
}

func newRegistry(path string) *registry {
	return &registry{path: path, nodes: map[string]*storedNode{}}
}

type persistedRegistry struct {
	Nodes []*storedNode `json:"nodes"`
}

func (r *registry) load() error {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := os.ReadFile(r.path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return fmt.Errorf("Node-Registry lesen: %w", err)
	}
	var persisted persistedRegistry
	if err := json.Unmarshal(data, &persisted); err != nil {
		return fmt.Errorf("Node-Registry lesen: %w", err)
	}
	r.nodes = make(map[string]*storedNode, len(persisted.Nodes))
	r.order = r.order[:0]
	for _, entry := range persisted.Nodes {
		if entry == nil || strings.TrimSpace(entry.ID) == "" {
			continue
		}
		r.nodes[entry.ID] = entry
		r.order = append(r.order, entry.ID)
	}
	return nil
}

// saveLocked writes the registry. It is only ever called with the lock held,
// so the snapshot it serialises cannot tear.
func (r *registry) saveLocked() error {
	if r.path == "" {
		return nil
	}
	persisted := persistedRegistry{Nodes: make([]*storedNode, 0, len(r.order))}
	for _, id := range r.order {
		if entry, ok := r.nodes[id]; ok {
			persisted.Nodes = append(persisted.Nodes, entry)
		}
	}
	data, err := json.MarshalIndent(persisted, "", "  ")
	if err != nil {
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	if err := os.MkdirAll(filepath.Dir(r.path), 0o700); err != nil {
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	temporary := r.path + ".tmp"
	if err := os.WriteFile(temporary, data, 0o600); err != nil {
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	if err := os.Rename(temporary, r.path); err != nil {
		_ = os.Remove(temporary)
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	return nil
}

func (r *registry) list() []storedNode {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]storedNode, 0, len(r.order))
	for _, id := range r.order {
		if entry, ok := r.nodes[id]; ok {
			out = append(out, *entry)
		}
	}
	return out
}

func (r *registry) get(id string) (storedNode, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	entry, ok := r.nodes[strings.TrimSpace(id)]
	if !ok {
		return storedNode{}, false
	}
	return *entry, true
}

func (r *registry) add(entry storedNode) (storedNode, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	id := strings.TrimSpace(entry.ID)
	if id == "" {
		return storedNode{}, fmt.Errorf("Node-Kennung fehlt")
	}
	if _, exists := r.nodes[id]; exists {
		return storedNode{}, fmt.Errorf("dieser Node ist bereits hinterlegt")
	}
	entry.Name = uniqueNameLocked(r, strings.TrimSpace(entry.Name), id)
	stored := entry
	r.nodes[id] = &stored
	r.order = append(r.order, id)
	if err := r.saveLocked(); err != nil {
		delete(r.nodes, id)
		r.order = r.order[:len(r.order)-1]
		return storedNode{}, err
	}
	return stored, nil
}

// update applies a change under the lock and persists the result. The mutation
// runs against the stored entry itself, so a caller cannot accidentally write
// back a stale copy.
func (r *registry) update(id string, mutate func(*storedNode)) (storedNode, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	entry, ok := r.nodes[strings.TrimSpace(id)]
	if !ok {
		return storedNode{}, errNodeUnknown
	}
	before := *entry
	mutate(entry)
	if err := r.saveLocked(); err != nil {
		*entry = before
		return storedNode{}, err
	}
	return *entry, nil
}

func (r *registry) remove(id string) (storedNode, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	id = strings.TrimSpace(id)
	entry, ok := r.nodes[id]
	if !ok {
		return storedNode{}, errNodeUnknown
	}
	removed := *entry
	delete(r.nodes, id)
	for index, candidate := range r.order {
		if candidate == id {
			r.order = append(r.order[:index], r.order[index+1:]...)
			break
		}
	}
	if err := r.saveLocked(); err != nil {
		r.nodes[id] = &removed
		r.order = append(r.order, id)
		return storedNode{}, err
	}
	return removed, nil
}

// uniqueNameLocked keeps two nodes from carrying the same label. The name is
// what the user picks a download target by, so a duplicate is worse than an
// ugly suffix.
func uniqueNameLocked(r *registry, name, id string) string {
	if name == "" {
		name = "Node " + shortID(id)
	}
	taken := map[string]bool{}
	for otherID, entry := range r.nodes {
		if otherID != id {
			taken[strings.ToLower(entry.Name)] = true
		}
	}
	if !taken[strings.ToLower(name)] {
		return name
	}
	for suffix := 2; suffix < 100; suffix++ {
		candidate := fmt.Sprintf("%s (%d)", name, suffix)
		if !taken[strings.ToLower(candidate)] {
			return candidate
		}
	}
	return name + " " + shortID(id)
}

func shortID(id string) string {
	if len(id) > 6 {
		return id[:6]
	}
	return id
}

// sortedByName orders nodes the way the client shows them.
func sortedByName(nodes []storedNode) []storedNode {
	sort.SliceStable(nodes, func(first, second int) bool {
		return strings.ToLower(nodes[first].Name) < strings.ToLower(nodes[second].Name)
	})
	return nodes
}

// newID draws an identifier for a node. It is hex so it survives being folded
// into an interface name and a qualified id without escaping.
func newID() string {
	raw := make([]byte, 6)
	if _, err := rand.Read(raw); err != nil {
		return fmt.Sprintf("%x", time.Now().UnixNano())
	}
	return hex.EncodeToString(raw)
}

// newToken draws a pairing token. It is the only thing standing between
// someone already inside the tunnel and this node's models, so it is a full
// 32 bytes.
func newToken() string {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return ""
	}
	return hex.EncodeToString(raw)
}
