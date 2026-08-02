//go:build windows

package hardware

import (
	"context"
	"math"
	"unsafe"

	"golang.org/x/sys/windows"
)

var globalMemoryStatusEx = windows.NewLazySystemDLL("kernel32.dll").NewProc("GlobalMemoryStatusEx")

type memoryStatusEx struct {
	Length                   uint32
	MemoryLoad               uint32
	TotalPhysical            uint64
	AvailablePhysical        uint64
	TotalPageFile            uint64
	AvailablePageFile        uint64
	TotalVirtual             uint64
	AvailableVirtual         uint64
	AvailableExtendedVirtual uint64
}

func detectWindowsMemory(ctx context.Context) (int64, int64) {
	if ctx == nil || ctx.Err() != nil {
		return 0, 0
	}
	status := memoryStatusEx{Length: uint32(unsafe.Sizeof(memoryStatusEx{}))}
	result, _, _ := globalMemoryStatusEx.Call(uintptr(unsafe.Pointer(&status)))
	if result == 0 || ctx.Err() != nil || status.TotalPhysical == 0 {
		return 0, 0
	}
	if status.TotalPhysical > math.MaxInt64 || status.AvailablePhysical > math.MaxInt64 {
		return 0, 0
	}
	return int64(status.TotalPhysical), int64(status.AvailablePhysical)
}
