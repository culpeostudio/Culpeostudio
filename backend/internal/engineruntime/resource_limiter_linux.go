//go:build linux

package engineruntime

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"sync"
)

type linuxLifetimePipe struct {
	read  *os.File
	write *os.File
}

type nativeResourceLimiter struct {
	mu       sync.Mutex
	prepared map[*exec.Cmd]*linuxLifetimePipe
}

func NewNativeResourceLimiter() ResourceLimiter {
	return &nativeResourceLimiter{prepared: make(map[*exec.Cmd]*linuxLifetimePipe)}
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
	// The supervised launcher must stay alive long enough to observe lifetime
	// EOF and kill the whole process group. PR_SET_PDEATHSIG would kill only the
	// launcher first and could orphan non-inheriting runtime grandchildren.
	if cmd.SysProcAttr != nil {
		cmd.SysProcAttr.Pdeathsig = 0
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
	l.prepared[cmd] = &linuxLifetimePipe{read: read, write: write}
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

	// Moving the waiting launcher before releasing it ensures every later
	// runtime child inherits aggregate cgroup accounting. Missing delegation is
	// acceptable because the supervised RLIMIT_AS fallback is already active.
	cgroupCleanup, _ := bindCgroupV2Memory(cmd.Process.Pid, limits.MemoryMaxBytes)
	if cgroupCleanup == nil {
		cgroupCleanup = func() {}
	}
	if _, err := pipe.write.Write([]byte{resourceLauncherStartByte}); err != nil {
		cgroupCleanup()
		_ = pipe.write.Close()
		return nil, fmt.Errorf("release limited worker: %w", err)
	}
	var once sync.Once
	return func() {
		once.Do(func() {
			_ = pipe.write.Close()
			cgroupCleanup()
		})
	}, nil
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

func bindCgroupV2Memory(pid int, maximum int64) (func(), error) {
	root := "/sys/fs/cgroup"
	if _, err := os.Stat(filepath.Join(root, "cgroup.controllers")); err != nil {
		return nil, err
	}
	directory := filepath.Join(root, "philoengine-"+strconv.Itoa(os.Getuid())+"-"+strconv.Itoa(pid))
	if err := os.Mkdir(directory, 0o700); err != nil {
		return nil, err
	}
	fail := func(err error) (func(), error) {
		_ = os.Remove(directory)
		return nil, err
	}
	if err := os.WriteFile(filepath.Join(directory, "memory.max"), []byte(strconv.FormatInt(maximum, 10)), 0o600); err != nil {
		return fail(err)
	}
	// Swap must not silently turn a RAM ceiling into host-wide thrashing.
	if err := os.WriteFile(filepath.Join(directory, "memory.swap.max"), []byte("0"), 0o600); err != nil {
		return fail(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "cgroup.procs"), []byte(strconv.Itoa(pid)), 0o600); err != nil {
		return fail(err)
	}
	return func() { _ = os.Remove(directory) }, nil
}
