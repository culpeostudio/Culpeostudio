//go:build aix || dragonfly || freebsd || netbsd || openbsd || solaris

package engineruntime

import (
	"errors"
	"os/exec"
	"sync"
)

type fallbackCommandLifetime struct {
	cleanup func()
	once    sync.Once
}

func prepareCommandLifetime(_ *exec.Cmd) (preparedCommandLifetime, error) {
	return &fallbackCommandLifetime{}, nil
}

func (l *fallbackCommandLifetime) Bind(cmd *exec.Cmd) error {
	if cmd == nil || cmd.Process == nil {
		return errors.New("installer process is not started")
	}
	cleanup, err := bindProcessLifetime(cmd)
	if err != nil {
		return err
	}
	l.cleanup = cleanup
	return nil
}

func (l *fallbackCommandLifetime) Cleanup() {
	if l == nil {
		return
	}
	l.once.Do(func() {
		if l.cleanup != nil {
			l.cleanup()
		}
	})
}
