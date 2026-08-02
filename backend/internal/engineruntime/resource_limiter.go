package engineruntime

import (
	"os/exec"
)

type ResourceLimits struct {
	MemoryMaxBytes int64 `json:"memory_max_bytes,omitempty"`
}

type ResourceLimiter interface {
	Bind(cmd *exec.Cmd, limits ResourceLimits) (cleanup func(), err error)
}

type ResourceLimitPreparer interface {
	Prepare(cmd *exec.Cmd, limits ResourceLimits) error
}

type ResourceLimitPreparationAborter interface {
	AbortPrepare(cmd *exec.Cmd)
}

type NoopResourceLimiter struct{}

func (NoopResourceLimiter) Prepare(_ *exec.Cmd, _ ResourceLimits) error { return nil }

func (NoopResourceLimiter) Bind(_ *exec.Cmd, _ ResourceLimits) (func(), error) {
	return func() {}, nil
}
