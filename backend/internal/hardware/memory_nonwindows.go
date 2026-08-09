//go:build !windows

package hardware

import "context"

func detectWindowsMemory(context.Context) (int64, int64) { return 0, 0 }
