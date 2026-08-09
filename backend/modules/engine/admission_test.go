package engine

import (
	"context"
	"testing"
)

func TestStartAdmissionCancelVersusPromotionNeverStrandsActiveEntry(t *testing.T) {
	for attempt := 0; attempt < 500; attempt++ {
		queue := newStartAdmissionQueue()
		queue.setPaused(true)
		queue.enqueue("racing", "normal")
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		queue.setPaused(false)
		if err := queue.wait(ctx, "racing"); err != nil {
			t.Fatalf("granted admission returned cancellation on attempt %d: %v", attempt, err)
		}
		queue.done("racing")
		positions := queue.enqueue("next", "normal")
		if positions["next"] != 0 {
			t.Fatalf("active entry was stranded on attempt %d: %#v", attempt, positions)
		}
		queue.done("next")
	}
}
