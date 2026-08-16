package node

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/culpeohq/backend/internal/wireguard"
)

var (
	// errTunnelNetworkConflict stops two managed WireGuard interfaces from
	// claiming overlapping routes on the Studio. Without this guard the route
	// chosen by the operating system depends on interface order.
	errTunnelNetworkConflict = errors.New("Tunnel-Netz ueberschneidet sich mit einem vorhandenen Node")
	// errTunnelNetworkUnknown is deliberately fail-closed for an old managed
	// entry whose config no longer exists or cannot be read. There is no safe
	// way to prove a new route does not overlap a route whose CIDR is unknown.
	errTunnelNetworkUnknown = errors.New("Tunnel-Netz eines vorhandenen Nodes ist nicht feststellbar")
)

// storedTunnel is the WireGuard side of a node as this Studio wrote it.
// Managed is false for a node whose tunnel someone set up by hand: then the
// Studio only knows where to send things and touches no interface.
type storedTunnel struct {
	InterfaceName string `json:"interface_name,omitempty"`
	ConfigPath    string `json:"config_path,omitempty"`
	LocalAddress  string `json:"local_address,omitempty"`
	// Network is the canonical AllowedIPs CIDR from the Studio config. Older
	// registries lack it; when their config is still present it is recovered
	// from there before another node is allowed to claim a route.
	Network       string `json:"network,omitempty"`
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

	Token string `json:"token"`
	// TLSFingerprint marks a direct connection link. It is the SHA-256 digest
	// of the Node's leaf certificate and is intentionally kept beside the
	// pairing token: both are required to make a direct call safe.
	TLSFingerprint string `json:"tls_fingerprint,omitempty"`
	GatewayKeyID   string `json:"gateway_key_id,omitempty"`
	GatewayKey     string `json:"gateway_key,omitempty"`
	// GatewayKeyLabel is a stable, locally generated label for this Studio's
	// gateway credential. It is not the Node ID: two Studios paired to one
	// Node must never rotate each other's inference key.
	GatewayKeyLabel string `json:"gateway_key_label,omitempty"`
	GatewayBaseURL  string `json:"gateway_base_url,omitempty"`

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

	info, err := os.Lstat(r.path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("Node-Registry lesen: %w", err)
	}
	if info.Mode()&os.ModeSymlink != 0 || !info.Mode().IsRegular() {
		return fmt.Errorf("Node-Registry lesen: muss eine regulaere Datei sein")
	}
	data, err := os.ReadFile(r.path)
	if err != nil {
		return fmt.Errorf("Node-Registry lesen: %w", err)
	}
	if err := os.Chmod(r.path, 0o600); err != nil {
		return fmt.Errorf("Zugriffsrechte der Node-Registry absichern: %w", err)
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
	if info, statErr := os.Lstat(r.path); statErr == nil {
		if info.Mode()&os.ModeSymlink != 0 || !info.Mode().IsRegular() {
			return fmt.Errorf("Node-Registry schreiben: Ziel muss eine regulaere Datei sein")
		}
	} else if !os.IsNotExist(statErr) {
		return fmt.Errorf("Node-Registry schreiben: %w", statErr)
	}
	temporary, err := os.CreateTemp(filepath.Dir(r.path), ".nodes-*")
	if err != nil {
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	temporaryPath := temporary.Name()
	defer func() { _ = os.Remove(temporaryPath) }()
	if err := temporary.Chmod(0o600); err != nil {
		_ = temporary.Close()
		return fmt.Errorf("Zugriffsrechte der Node-Registry setzen: %w", err)
	}
	if _, err := temporary.Write(data); err != nil {
		_ = temporary.Close()
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	if err := temporary.Sync(); err != nil {
		_ = temporary.Close()
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	if err := temporary.Close(); err != nil {
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	if err := os.Rename(temporaryPath, r.path); err != nil {
		return fmt.Errorf("Node-Registry schreiben: %w", err)
	}
	if err := os.Chmod(r.path, 0o600); err != nil {
		return fmt.Errorf("Zugriffsrechte der Node-Registry absichern: %w", err)
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
	if strings.TrimSpace(entry.TLSFingerprint) == "" {
		// Only legacy entries can claim a WireGuard route. A direct TLS node
		// never creates or uses an interface on this Studio, even when its
		// endpoint happens to be in an address range a legacy tunnel owns.
		network, err := tunnelNetwork(entry)
		if err != nil {
			return storedNode{}, err
		}
		entry.Tunnel.Network = network
		if err := r.ensureTunnelNetworkAvailableLocked(entry); err != nil {
			return storedNode{}, err
		}
	}
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

// ensureTunnelNetworkAvailableLocked validates the route a new registry entry
// would claim while r.mu is held. Keeping the check inside add makes two
// concurrent AddNode calls safe: only one can reserve a given network.
func (r *registry) ensureTunnelNetworkAvailableLocked(candidate storedNode) error {
	candidateNetwork := strings.TrimSpace(candidate.Tunnel.Network)
	for _, existing := range r.nodes {
		existingNetwork, err := tunnelNetwork(*existing)
		if err != nil {
			return fmt.Errorf("%w: %s: %v", errTunnelNetworkUnknown, existing.Name, err)
		}

		if candidateNetwork == "" {
			// A manually managed tunnel has no route to compare. It can still
			// point at an address claimed by a Studio-managed interface, which
			// would send its pairing token to the wrong peer.
			if existingNetwork != "" {
				contains, containsErr := tunnelNetworkContains(existingNetwork, candidate.Address)
				if containsErr != nil {
					return containsErr
				}
				if contains {
					return tunnelNetworkConflict(candidate, *existing, "", existingNetwork)
				}
			}
			continue
		}

		if existingNetwork == "" {
			// The existing node was added manually. It has no CIDR stored, but
			// its remote address must not fall inside the new managed route.
			contains, containsErr := tunnelNetworkContains(candidateNetwork, existing.Address)
			if containsErr != nil {
				return containsErr
			}
			if contains {
				return tunnelNetworkConflict(candidate, *existing, candidateNetwork, "")
			}
			continue
		}

		overlaps, overlapErr := wireguard.NetworksOverlap(candidateNetwork, existingNetwork)
		if overlapErr != nil {
			return fmt.Errorf("Tunnel-Netz pruefen: %w", overlapErr)
		}
		if overlaps {
			return tunnelNetworkConflict(candidate, *existing, candidateNetwork, existingNetwork)
		}
	}
	return nil
}

func tunnelNetwork(entry storedNode) (string, error) {
	if !entry.Tunnel.Managed {
		return "", nil
	}
	if network := strings.TrimSpace(entry.Tunnel.Network); network != "" {
		canonical, err := wireguard.NormalizeTunnelNetwork(network)
		if err != nil {
			return "", fmt.Errorf("%w: %v", errTunnelNetworkUnknown, err)
		}
		return canonical, nil
	}
	if strings.TrimSpace(entry.Tunnel.ConfigPath) == "" {
		return "", errTunnelNetworkUnknown
	}
	contents, err := os.ReadFile(entry.Tunnel.ConfigPath)
	if err != nil {
		return "", fmt.Errorf("%w: %v", errTunnelNetworkUnknown, err)
	}
	network, err := wireguard.TunnelNetworkFromConfig(string(contents))
	if err != nil {
		return "", fmt.Errorf("%w: %v", errTunnelNetworkUnknown, err)
	}
	return network, nil
}

func tunnelNetworkContains(network, address string) (bool, error) {
	_, subnet, err := net.ParseCIDR(strings.TrimSpace(network))
	if err != nil {
		return false, fmt.Errorf("Tunnel-Netz pruefen: %w", err)
	}
	ip := net.ParseIP(strings.TrimSpace(address))
	if ip == nil {
		// A manually managed endpoint may be a hostname. It does not prove a
		// collision, so leave its routing to the manually managed tunnel.
		return false, nil
	}
	return subnet.Contains(ip), nil
}

func tunnelNetworkConflict(candidate, existing storedNode, candidateNetwork, existingNetwork string) error {
	if candidateNetwork == "" {
		candidateNetwork = strings.TrimSpace(candidate.Address)
	}
	if existingNetwork == "" {
		existingNetwork = strings.TrimSpace(existing.Address)
	}
	return fmt.Errorf(
		"%w: %s (%s) und %s (%s). Bitte den neuen Node mit einem anderen CULPEO_NODE_WG_NETWORK neu einrichten",
		errTunnelNetworkConflict,
		candidate.Name,
		candidateNetwork,
		existing.Name,
		existingNetwork,
	)
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
