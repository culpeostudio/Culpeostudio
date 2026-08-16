package scout

import (
	"context"
	"io"
	"log"
	"time"
)

// providerStreamIdleTimeout is how long a provider stream may stay silent
// before it counts as dead.
//
// It is deliberately not a budget for the whole answer. An agent step may
// legitimately run for a long time - a plan works for as long as it takes, and
// capping that by the clock cut off runs that were making progress. What is
// never legitimate is a connection that has delivered nothing at all: that is a
// stalled socket, and no amount of waiting turns it back into an answer.
//
// Every byte that arrives - a token, a keep-alive comment, anything - resets
// the clock, so a model that is thinking hard but still sending stays alive.
const providerStreamIdleTimeout = 2 * time.Minute

// watchProviderStall wraps a provider stream so [cancel] runs once nothing has
// arrived for [idle]. The returned stop function ends the watch and must be
// called when the stream is done, or the timer keeps a goroutine alive until it
// fires.
func watchProviderStall(
	reader io.Reader,
	provider string,
	cancel context.CancelFunc,
	idle time.Duration,
) (io.Reader, func()) {
	if idle <= 0 {
		return reader, func() {}
	}
	timer := time.AfterFunc(idle, func() {
		log.Printf("[scout] %s hat %s lang nichts gesendet, Stream wird beendet", provider, idle)
		cancel()
	})
	return &stallWatchReader{reader: reader, timer: timer, idle: idle}, func() { timer.Stop() }
}

type stallWatchReader struct {
	reader io.Reader
	timer  *time.Timer
	idle   time.Duration
}

func (s *stallWatchReader) Read(payload []byte) (int, error) {
	n, err := s.reader.Read(payload)
	if n > 0 {
		s.timer.Reset(s.idle)
	}
	return n, err
}
