package bus

import (
	"sync"
	"testing"
	"time"
)

func newTestBus() *EventBus {
	return &EventBus{handlers: make(map[string][]Handler)}
}

// TestEmitRecoversFromHandlerPanic ist der wichtigste Test dieses Pakets: ohne
// Panic-Recovery in dispatch wuerde ein panischer Handler in seiner Goroutine
// den GESAMTEN Testprozess (und im Betrieb das ganze Backend) beenden. Laeuft
// der zweite Handler trotz des Panics des ersten durch, ist die Recovery aktiv.
func TestEmitRecoversFromHandlerPanic(t *testing.T) {
	b := newTestBus()

	var wg sync.WaitGroup
	wg.Add(2)
	survived := make(chan struct{}, 1)

	b.On("boom", func(Event) {
		defer wg.Done()
		panic("handler explodiert")
	})
	b.On("boom", func(Event) {
		defer wg.Done()
		survived <- struct{}{}
	})

	b.Emit("test", "boom", nil)

	done := make(chan struct{})
	go func() {
		wg.Wait()
		close(done)
	}()

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("Handler wurden nicht innerhalb des Timeouts fertig — Panic hat vermutlich den Prozess mitgerissen")
	}

	select {
	case <-survived:
	default:
		t.Fatal("der zweite Handler lief nicht — Panic des ersten hat ihn verhindert")
	}
}

// TestEmitDeliversToTypedAndGlobalHandlers stellt die Grundzustellung sicher:
// typ-spezifische Handler bekommen nur ihr Event, globale Handler bekommen alle.
func TestEmitDeliversToTypedAndGlobalHandlers(t *testing.T) {
	b := newTestBus()

	var mu sync.Mutex
	typed := 0
	globalTypes := []string{}

	var wg sync.WaitGroup
	wg.Add(3) // 1x typed + 2x global (zwei Emits)

	b.On("ping", func(e Event) {
		defer wg.Done()
		mu.Lock()
		typed++
		mu.Unlock()
	})
	b.OnAll(func(e Event) {
		defer wg.Done()
		mu.Lock()
		globalTypes = append(globalTypes, e.Type)
		mu.Unlock()
	})

	b.Emit("test", "ping", nil)
	b.Emit("test", "pong", nil)

	done := make(chan struct{})
	go func() {
		wg.Wait()
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("Handler nicht rechtzeitig fertig")
	}

	mu.Lock()
	defer mu.Unlock()
	if typed != 1 {
		t.Fatalf("typ-spezifischer Handler = %d Aufrufe, erwartet 1", typed)
	}
	if len(globalTypes) != 2 {
		t.Fatalf("globaler Handler = %d Aufrufe, erwartet 2 (%v)", len(globalTypes), globalTypes)
	}
}
