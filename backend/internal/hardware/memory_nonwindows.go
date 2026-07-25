//go:build !windows

package hardware

import "context"

// detectMemory contains a runtime switch, so non-Windows builds still need the
// symbol even though this branch is unreachable for them.
func detectWindowsMemory(context.Context) (int64, int64) { return 0, 0 }
