package memorychat

import (
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/memory"
)

func TestCompressPairCreatesStructuredChatMemory(t *testing.T) {
	compressor := NewCompressor(6, 2)
	entries := compressor.CompressPair(
		"session-1",
		"Bitte baue die Chat-Kompression mit SimpleMem Keywords in Go aus.",
		"Ich erweitere die Observations um Topic, Keywords und Sliding-Window-Kompression.",
		time.Date(2026, 7, 6, 12, 0, 0, 0, time.UTC),
	)
	if len(entries) != 1 {
		t.Fatalf("expected one pair entry, got %d", len(entries))
	}
	entry := entries[0]
	if entry.Type != "chat_memory" {
		t.Fatalf("expected chat_memory type, got %s", entry.Type)
	}
	if entry.Topic == "" {
		t.Fatalf("expected topic")
	}
	if len(entry.Keywords) == 0 {
		t.Fatalf("expected keywords")
	}
	if entry.ValidFrom == "" {
		t.Fatalf("expected valid_from")
	}
}

func TestCompressPairEmitsSlidingWindowSummary(t *testing.T) {
	compressor := NewCompressor(4, 1)
	total := []memory.AddObservationInput{}
	for index := 0; index < 2; index++ {
		total = append(total, compressor.CompressPair(
			"session-1",
			"User message about Fiber SQLite memory",
			"Assistant response about structured compression",
			time.Now().UTC(),
		)...)
	}
	if len(total) != 3 {
		t.Fatalf("expected two pair memories plus one window memory, got %d", len(total))
	}
	if total[2].Speaker != "chat_window" {
		t.Fatalf("expected window summary, got speaker %s", total[2].Speaker)
	}
}
