//go:build linux || darwin

package engineruntime

import (
	"fmt"

	"golang.org/x/sys/unix"
)

// execLimitedWorker is intentionally one-way: all JSON/environment parsing is
// complete before the hard address-space cap is installed, and no Go runtime
// supervision runs under that cap. The outer launcher supervises this process
// and its descendants in the shared process group.
func execLimitedWorker(payload resourceLauncherPayload, maximum uint64) error {
	if err := unix.Setrlimit(unix.RLIMIT_AS, &unix.Rlimit{Cur: maximum, Max: maximum}); err != nil {
		return fmt.Errorf("apply worker RLIMIT_AS: %w", err)
	}
	return unix.Exec(payload.Path, payload.Args, resourceWorkerEnvironment())
}
