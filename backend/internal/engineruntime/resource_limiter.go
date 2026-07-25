package engineruntime

import (
	"os/exec"
)

// ResourceLimits are hard worker-process ceilings, not admission estimates.
// A zero value preserves compatibility for non-model helper processes.
type ResourceLimits struct {
	MemoryMaxBytes int64 `json:"memory_max_bytes,omitempty"`
}

// ResourceLimiter is injectable so supervisor tests can use an explicit fake.
// Production uses NewNativeResourceLimiter. Bind runs immediately after fork
// and must either attach a native limit or return an error; callers kill the
// child on error (fail closed).
type ResourceLimiter interface {
	Bind(cmd *exec.Cmd, limits ResourceLimits) (cleanup func(), err error)
}

type ResourceLimitPreparer interface {
	Prepare(cmd *exec.Cmd, limits ResourceLimits) error
}

// ResourceLimitPreparationAborter releases handles created by Prepare when
// the process cannot be started or bound. It is optional because most native
// limiters do not retain parent-side preparation state.
type ResourceLimitPreparationAborter interface {
	AbortPrepare(cmd *exec.Cmd)
}

type NoopResourceLimiter struct{}

func (NoopResourceLimiter) Prepare(_ *exec.Cmd, _ ResourceLimits) error { return nil }

func (NoopResourceLimiter) Bind(_ *exec.Cmd, _ ResourceLimits) (func(), error) {
	return func() {}, nil
}
