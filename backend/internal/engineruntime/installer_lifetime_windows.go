//go:build windows

package engineruntime

import (
	"errors"
	"fmt"
	"os/exec"
	"sync"
	"unsafe"

	"golang.org/x/sys/windows"
)

type windowsCommandLifetime struct {
	job  windows.Handle
	once sync.Once
}

func prepareCommandLifetime(cmd *exec.Cmd) (preparedCommandLifetime, error) {
	if cmd == nil {
		return nil, errors.New("installer command is missing")
	}
	job, err := windows.CreateJobObject(nil, nil)
	if err != nil {
		return nil, err
	}
	info := windows.JOBOBJECT_EXTENDED_LIMIT_INFORMATION{}
	info.BasicLimitInformation.LimitFlags = windows.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
	if _, err := windows.SetInformationJobObject(
		job,
		windows.JobObjectExtendedLimitInformation,
		uintptr(unsafe.Pointer(&info)),
		uint32(unsafe.Sizeof(info)),
	); err != nil {
		_ = windows.CloseHandle(job)
		return nil, err
	}
	if cmd.SysProcAttr == nil {
		cmd.SysProcAttr = &windows.SysProcAttr{}
	}

	cmd.SysProcAttr.CreationFlags |= windows.CREATE_SUSPENDED
	return &windowsCommandLifetime{job: job}, nil
}

func (l *windowsCommandLifetime) Bind(cmd *exec.Cmd) error {
	if l == nil || l.job == 0 {
		return errors.New("installer lifetime Job Object is unavailable")
	}
	if cmd == nil || cmd.Process == nil {
		return errors.New("installer process is not started")
	}
	process, err := windows.OpenProcess(
		windows.PROCESS_SET_QUOTA|windows.PROCESS_TERMINATE,
		false,
		uint32(cmd.Process.Pid),
	)
	if err != nil {
		return err
	}
	defer windows.CloseHandle(process)
	if err := windows.AssignProcessToJobObject(l.job, process); err != nil {
		return err
	}
	if err := resumeProcessThreads(uint32(cmd.Process.Pid)); err != nil {
		return fmt.Errorf("resume assigned installer process: %w", err)
	}
	return nil
}

func (l *windowsCommandLifetime) Cleanup() {
	if l == nil {
		return
	}
	l.once.Do(func() {
		if l.job != 0 {
			_ = windows.CloseHandle(l.job)
			l.job = 0
		}
	})
}
