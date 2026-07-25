//go:build linux

package engineruntime

import (
	"os"
	"strconv"
	"strings"
)

// processResidentBytes returns the resident set size of a process, or -1 when
// unavailable. Used to detect that a model worker is still actively loading
// weights (its RSS keeps growing) so slow disk loads are not killed by a
// fixed health timeout.
func processResidentBytes(pid int) int64 {
	if pid <= 0 {
		return -1
	}
	data, err := os.ReadFile("/proc/" + strconv.Itoa(pid) + "/status")
	if err != nil {
		return -1
	}
	for _, line := range strings.Split(string(data), "\n") {
		if strings.HasPrefix(line, "VmRSS:") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				value, parseErr := strconv.ParseInt(fields[1], 10, 64)
				if parseErr == nil {
					return value * 1024
				}
			}
			break
		}
	}
	return -1
}
