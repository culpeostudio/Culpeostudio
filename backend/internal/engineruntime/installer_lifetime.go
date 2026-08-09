package engineruntime

import "os/exec"

type preparedCommandLifetime interface {
	Bind(cmd *exec.Cmd) error

	Cleanup()
}
