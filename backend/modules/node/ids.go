package node

import "github.com/culpeohq/backend/internal/noderouting"

// Qualify turns a node's own identifier into one the Studio can carry around.
// It remains a wrapper for callers that still import modules/node.
func Qualify(nodeID, id string) string { return noderouting.Qualify(nodeID, id) }

// Split reads a qualified identifier back. It reports false for a local one.
func Split(id string) (nodeID, localID string, ok bool) { return noderouting.Split(id) }

// NodeIDOf names the node an identifier belongs to, or the empty string when
// it belongs to this machine.
func NodeIDOf(id string) string { return noderouting.NodeIDOf(id) }

// IsRemote reports whether an identifier names something on a node.
func IsRemote(id string) bool { return noderouting.IsRemote(id) }
