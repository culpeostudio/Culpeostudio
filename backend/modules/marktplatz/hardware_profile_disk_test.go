package marktplatz

import (
	"testing"
)

func TestDetectDiskFreeBytesSanity(t *testing.T) {
	got := detectDiskFreeBytes()
	if got < 0 {
		t.Fatalf("detectDiskFreeBytes should be >= 0, got %d", got)
	}

	if got == 0 {
		t.Skipf("detectDiskFreeBytes returned 0 (df/powershell nicht verfuegbar) – Pre-Check wuerde hier uebersprungen werden")
	}
}

func TestDetectDiskFreeBytesStringParity(t *testing.T) {
	str := detectDiskFree()
	bytes := detectDiskFreeBytes()
	if bytes > 0 {
		if str == "N/A" || str == "" {
			t.Fatalf("DiskFreeBytes=%d but DiskFree=%q – string detection broken",
				bytes, str)
		}
	}
}
