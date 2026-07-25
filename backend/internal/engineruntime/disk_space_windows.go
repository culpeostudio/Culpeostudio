//go:build windows

package engineruntime

import "golang.org/x/sys/windows"

// freeDiskBytes returns the number of bytes available to the current user on
// the volume containing path.
func freeDiskBytes(path string) (int64, error) {
	pointer, err := windows.UTF16PtrFromString(path)
	if err != nil {
		return 0, err
	}
	var freeBytesAvailable, totalBytes, totalFreeBytes uint64
	if err := windows.GetDiskFreeSpaceEx(pointer, &freeBytesAvailable, &totalBytes, &totalFreeBytes); err != nil {
		return 0, err
	}
	return int64(freeBytesAvailable), nil
}
