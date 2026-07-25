//go:build darwin

package engineruntime

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"sync"
)

type darwinLifetimePipe struct {
	read  *os.File
	write *os.File
}

type nativeResourceLimiter struct {
	mu       sync.Mutex
	prepared map[*exec.Cmd]*darwinLifetimePipe
}

func NewNativeResourceLimiter() ResourceLimiter {
	return &nativeResourceLimiter{prepared: make(map[*exec.Cmd]*darwinLifetimePipe)}
}

func (*nativeResourceLimiter) IncludesProcessLifetime() bool { return true }

func (l *nativeResourceLimiter) Prepare(cmd *exec.Cmd, limits ResourceLimits) error {
	if limits.MemoryMaxBytes <= 0 {
		return nil
	}
	if cmd == nil {
		return fmt.Errorf("worker command is missing")
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	if _, exists := l.prepared[cmd]; exists {
		return fmt.Errorf("worker command is already prepared")
	}
	if err := prepareRlimitLauncher(cmd, limits.MemoryMaxBytes); err != nil {
		return err
	}
	read, write, err := os.Pipe()
	if err != nil {
		return fmt.Errorf("create backend-lifetime descriptor: %w", err)
	}
	fd := 3 + len(cmd.ExtraFiles)
	cmd.ExtraFiles = append(cmd.ExtraFiles, read)
	cmd.Env = mergeEnvironment(cmd.Env, map[string]string{
		resourceLauncherLifetimeFD: strconv.Itoa(fd),
	})
	l.prepared[cmd] = &darwinLifetimePipe{read: read, write: write}
	return nil
}

func (l *nativeResourceLimiter) Bind(cmd *exec.Cmd, limits ResourceLimits) (func(), error) {
	if limits.MemoryMaxBytes <= 0 {
		return func() {}, nil
	}
	if cmd == nil || cmd.Process == nil {
		l.AbortPrepare(cmd)
		return nil, fmt.Errorf("worker process is not started")
	}
	l.mu.Lock()
	pipe := l.prepared[cmd]
	delete(l.prepared, cmd)
	l.mu.Unlock()
	if pipe == nil || pipe.read == nil || pipe.write == nil {
		return nil, fmt.Errorf("backend-lifetime descriptor was not prepared")
	}
	if err := pipe.read.Close(); err != nil {
		_ = pipe.write.Close()
		return nil, fmt.Errorf("release parent copy of backend-lifetime descriptor: %w", err)
	}
	var once sync.Once
	return func() { once.Do(func() { _ = pipe.write.Close() }) }, nil
}

func (l *nativeResourceLimiter) AbortPrepare(cmd *exec.Cmd) {
	if cmd == nil {
		return
	}
	l.mu.Lock()
	pipe := l.prepared[cmd]
	delete(l.prepared, cmd)
	l.mu.Unlock()
	if pipe != nil {
		if pipe.read != nil {
			_ = pipe.read.Close()
		}
		if pipe.write != nil {
			_ = pipe.write.Close()
		}
	}
}
