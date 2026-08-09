package autoupdate

import "testing"

func TestAcquireUpdateLockIsExclusive(t *testing.T) {
	root := t.TempDir()
	first, err := AcquireUpdateLock(root)
	if err != nil {
		t.Fatalf("AcquireUpdateLock(first) error = %v", err)
	}
	t.Cleanup(func() { _ = first.Close() })
	if second, err := AcquireUpdateLock(root); err == nil {
		_ = second.Close()
		t.Fatal("AcquireUpdateLock(second) unexpectedly succeeded")
	}
	if err := first.Close(); err != nil {
		t.Fatalf("Close(first) error = %v", err)
	}
	reacquired, err := AcquireUpdateLock(root)
	if err != nil {
		t.Fatalf("AcquireUpdateLock(after close) error = %v", err)
	}
	_ = reacquired.Close()
}
