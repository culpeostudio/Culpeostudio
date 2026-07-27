//go:build !linux && !darwin && !windows

package autoupdate

import "os"

func replaceFile(source, destination string) error {
	return os.Rename(source, destination)
}
