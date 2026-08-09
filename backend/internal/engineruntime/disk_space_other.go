//go:build !linux && !darwin && !windows

package engineruntime

func freeDiskBytes(path string) (int64, error) {
	return -1, nil
}
