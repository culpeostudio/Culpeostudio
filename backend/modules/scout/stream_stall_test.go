package scout

import (
	"io"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

// A stream that keeps delivering may take as long as the work takes - the run
// that these tests protect is an agent working off a plan, which is measured in
// steps, not in minutes. Only silence counts as dead.
func TestWatchProviderStallLaesstEinenLiefernedenStreamLaufen(t *testing.T) {
	var cancelled atomic.Bool
	source := &tickingReader{chunks: 6, pause: 10 * time.Millisecond}

	reader, stop := watchProviderStall(source, "test", func() { cancelled.Store(true) }, 80*time.Millisecond)
	defer stop()

	read, err := io.ReadAll(reader)
	if err != nil {
		t.Fatalf("lesen: %v", err)
	}
	if len(read) == 0 {
		t.Fatal("nichts gelesen")
	}
	if cancelled.Load() {
		t.Error("ein Stream, der weiter liefert, darf nicht abgebrochen werden")
	}
}

func TestWatchProviderStallBrichtStilleAb(t *testing.T) {
	var cancelled atomic.Bool
	// Never delivers anything and never ends: exactly the socket the watch is
	// there for.
	source := &tickingReader{chunks: 0, pause: time.Hour}

	reader, stop := watchProviderStall(source, "test", func() { cancelled.Store(true) }, 30*time.Millisecond)
	defer stop()

	buffer := make([]byte, 8)
	done := make(chan struct{})
	go func() {
		_, _ = reader.Read(buffer)
		close(done)
	}()

	deadline := time.After(time.Second)
	for !cancelled.Load() {
		select {
		case <-deadline:
			t.Fatal("stiller Stream wurde nicht abgebrochen")
		case <-time.After(5 * time.Millisecond):
		}
	}
}

func TestWatchProviderStallStopptDieUhr(t *testing.T) {
	var cancelled atomic.Bool
	reader, stop := watchProviderStall(strings.NewReader("fertig"), "test",
		func() { cancelled.Store(true) }, 20*time.Millisecond)

	if _, err := io.ReadAll(reader); err != nil {
		t.Fatalf("lesen: %v", err)
	}
	stop()

	time.Sleep(60 * time.Millisecond)
	if cancelled.Load() {
		t.Error("nach dem Ende des Streams darf die Uhr nicht mehr feuern")
	}
}

// tickingReader hands out one chunk per read with a pause in between, like a
// provider streaming tokens.
type tickingReader struct {
	chunks int
	pause  time.Duration
}

func (r *tickingReader) Read(payload []byte) (int, error) {
	time.Sleep(r.pause)
	if r.chunks <= 0 {
		return 0, io.EOF
	}
	r.chunks--
	return copy(payload, []byte("data: x\n")), nil
}
