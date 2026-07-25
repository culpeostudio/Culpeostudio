//go:build !linux && !windows && !darwin

package engineruntime

import (
	"fmt"
	"os/exec"
)

type nativeResourceLimiter struct{}

func NewNativeResourceLimiter() ResourceLimiter { return nativeResourceLimiter{} }

func (nativeResourceLimiter) Prepare(_ *exec.Cmd, limits ResourceLimits) error {
	if limits.MemoryMaxBytes <= 0 {
		return nil
	}
	return fmt.Errorf("hard per-process RAM limits are unavailable on this platform")
}

func (nativeResourceLimiter) Bind(_ *exec.Cmd, limits ResourceLimits) (func(), error) {
	if limits.MemoryMaxBytes <= 0 {
		return func() {}, nil
	}
	return nil, fmt.Errorf("hard per-process RAM limits are unavailable on this platform")
}
