package node

import "strings"

// idPrefix marks an identifier that belongs to a node rather than to this
// machine.
//
// Model ids, instance ids and download job ids are all generated where the
// thing they name lives, so two nodes can hand out the same one. Qualifying
// them on the way in gives the Studio one flat namespace and, more usefully,
// makes every id say where it has to be sent - no lookup table that can be out
// of date at the moment a call arrives.
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
