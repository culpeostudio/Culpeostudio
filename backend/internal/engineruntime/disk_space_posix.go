//go:build linux || darwin

package engineruntime

import "golang.org/x/sys/unix"

// freeDiskBytes returns the number of bytes available to the current user on
// the filesystem containing path.
func freeDiskBytes(path string) (int64, error) {
	var stat unix.Statfs_t
	if err := unix.Statfs(path, &stat); err != nil {
		return 0, err
	}
	return int64(stat.Bavail) * int64(stat.Bsize), nil
}
