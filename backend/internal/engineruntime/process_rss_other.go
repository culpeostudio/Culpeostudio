//go:build !linux

package engineruntime

func processResidentBytes(pid int) int64 {
	return -1
}
