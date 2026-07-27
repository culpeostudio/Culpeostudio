package autoupdate

import (
	"fmt"
	"os"
	"path/filepath"
)

type UpdateLock struct {
	file *os.File
}

func AcquireUpdateLock(installRoot string) (*UpdateLock, error) {
	if err := os.MkdirAll(installRoot, 0o755); err != nil {
		return nil, fmt.Errorf("create install root: %w", err)
	}
	path := filepath.Join(installRoot, ".philoengine.lock")
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, fmt.Errorf("open application lock: %w", err)
	}
	if err := lockFile(file); err != nil {
		file.Close()
		return nil, fmt.Errorf("MyPhiloEngine is already running or updating: %w", err)
	}
	if err := file.Truncate(0); err == nil {
		_, _ = fmt.Fprintf(file, "%d\n", os.Getpid())
		_ = file.Sync()
	}
	return &UpdateLock{file: file}, nil
}

func (lock *UpdateLock) Close() error {
	if lock == nil || lock.file == nil {
		return nil
	}
	unlockErr := unlockFile(lock.file)
	closeErr := lock.file.Close()
	lock.file = nil
	if unlockErr != nil {
		return unlockErr
	}
	return closeErr
}
