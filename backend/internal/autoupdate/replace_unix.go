//go:build linux || darwin

package autoupdate

import "os"

func replaceFile(source, destination string) error {
	return os.Rename(source, destination)
}
