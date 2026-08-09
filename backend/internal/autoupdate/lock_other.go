//go:build !linux && !darwin && !windows

package autoupdate

import (
	"fmt"
	"os"
)

func lockFile(_ *os.File) error {
	return fmt.Errorf("application locking is unsupported on this platform")
}

func unlockFile(_ *os.File) error {
	return nil
}
