//go:build !linux && !darwin && !windows

package engineruntime

// freeDiskBytes is unavailable on this platform; a negative value tells the
// caller to skip the proactive space check rather than block installs.
func freeDiskBytes(path string) (int64, error) {
	return -1, nil
}
