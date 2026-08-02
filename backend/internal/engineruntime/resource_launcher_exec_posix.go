//go:build linux || darwin

package engineruntime

import (
	"fmt"

	"golang.org/x/sys/unix"
)

func execLimitedWorker(payload resourceLauncherPayload, maximum uint64) error {
	if err := unix.Setrlimit(unix.RLIMIT_AS, &unix.Rlimit{Cur: maximum, Max: maximum}); err != nil {
		return fmt.Errorf("apply worker RLIMIT_AS: %w", err)
	}
	return unix.Exec(payload.Path, payload.Args, resourceWorkerEnvironment())
}
