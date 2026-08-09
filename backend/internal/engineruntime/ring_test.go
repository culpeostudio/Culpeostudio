package engineruntime

import (
	"sync"
	"testing"
)

func TestRingBufferKeepsNewestBytes(t *testing.T) {
	ring := NewRingBuffer(5)
	_, _ = ring.Write([]byte("abc"))
	_, _ = ring.Write([]byte("def"))
	if got := ring.String(); got != "bcdef" {
		t.Fatalf("got %q, want bcdef", got)
	}
	_, _ = ring.Write([]byte("0123456789"))
	if got := ring.String(); got != "56789" {
		t.Fatalf("got %q, want newest large-write suffix", got)
	}
}

func TestRingBufferConcurrentWritersStayBounded(t *testing.T) {
	ring := NewRingBuffer(128)
	var group sync.WaitGroup
	for index := 0; index < 20; index++ {
		group.Add(1)
		go func() {
			defer group.Done()
			for count := 0; count < 100; count++ {
				_, _ = ring.Write([]byte("entry\n"))
			}
		}()
	}
	group.Wait()
	if got := len(ring.Bytes()); got > 128 {
		t.Fatalf("ring grew to %d bytes", got)
	}
}
