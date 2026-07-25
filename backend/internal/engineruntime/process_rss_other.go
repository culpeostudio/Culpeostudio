//go:build !linux

package engineruntime

// processResidentBytes is unavailable on this platform; -1 disables the
// RSS-growth extension and the plain health timeout applies.
func processResidentBytes(pid int) int64 {
	return -1
}
