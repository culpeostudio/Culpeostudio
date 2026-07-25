package engineruntime

import "os/exec"

// preparedCommandLifetime is deliberately separate from ResourceLimiter.
// Runtime installers and compiler/prewarm helpers need process-tree lifetime
// supervision, but they are not model workers and must not inherit model RAM
// limits or alter the worker launcher's fail-closed contract.
type preparedCommandLifetime interface {
	// Bind completes the platform attachment after Cmd.Start. Implementations
	// keep the child unable to execute the requested command until Bind has
	// installed the lifetime boundary.
	Bind(cmd *exec.Cmd) error
	// Cleanup releases parent-owned handles. It must be idempotent and, while a
	// process is alive, fail closed by causing its supervised tree to exit.
	Cleanup()
}
