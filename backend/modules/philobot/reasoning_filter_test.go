package philobot

import (
	"strings"
	"testing"
)

func splitThinkStream(reply string) (visible string, reasoning string) {
	var visibleBuf, reasoningBuf strings.Builder
	f := newThinkTagFilter(
		func(s string) error { visibleBuf.WriteString(s); return nil },
		func(s string) error { reasoningBuf.WriteString(s); return nil },
	)
	for _, r := range reply {
		_ = f.Emit(string(r))
	}
	_ = f.Flush()
	return visibleBuf.String(), reasoningBuf.String()
}

func TestThinkTagFilterSplitsVisibleAndReasoning(t *testing.T) {
	visible, reasoning := splitThinkStream("<think>Ich ueberlege kurz.</think>Das ist die Antwort.")
	if reasoning != "Ich ueberlege kurz." {
		t.Fatalf("unerwarteter Reasoning-Text: %q", reasoning)
	}
	if visible != "Das ist die Antwort." {
		t.Fatalf("unerwarteter sichtbarer Text: %q", visible)
	}
}

func TestThinkTagFilterPassesPlainTextThrough(t *testing.T) {
	visible, reasoning := splitThinkStream("Ganz normale Antwort ohne Denkblock.")
	if reasoning != "" {
		t.Fatalf("kein Denkblock sollte keinen Reasoning-Text erzeugen, bekam: %q", reasoning)
	}
	if visible != "Ganz normale Antwort ohne Denkblock." {
		t.Fatalf("normaler Text sollte unveraendert sichtbar sein, bekam: %q", visible)
	}
}

func TestThinkTagFilterKeepsTextBeforeAndAfterBlock(t *testing.T) {
	visible, reasoning := splitThinkStream("Vorspann. <think>Denkprozess</think> Nachspann.")
	if reasoning != "Denkprozess" {
		t.Fatalf("unerwarteter Reasoning-Text: %q", reasoning)
	}
	if visible != "Vorspann.  Nachspann." {
		t.Fatalf("Text vor/nach dem Denkblock sollte erhalten bleiben, bekam: %q", visible)
	}
}

func TestThinkTagFilterUnterminatedBlockStaysHidden(t *testing.T) {

	visible, reasoning := splitThinkStream("<think>Abgebrochener Gedanke ohne Ende")
	if visible != "" {
		t.Fatalf("unterminierter Denkblock sollte nicht sichtbar sein, bekam: %q", visible)
	}
	if reasoning != "Abgebrochener Gedanke ohne Ende" {
		t.Fatalf("unerwarteter Reasoning-Text: %q", reasoning)
	}
}

func TestStripThinkBlocksRemovesSingleBlock(t *testing.T) {
	got := stripThinkBlocks("<think>Gedanke</think>Antwort")
	if got != "Antwort" {
		t.Fatalf("Denkblock sollte entfernt werden, bekam: %q", got)
	}
}

func TestStripThinkBlocksRemovesMultipleBlocks(t *testing.T) {
	got := stripThinkBlocks("<think>Erst</think>Mitte<think>Zweitens</think>Ende")
	if got != "MitteEnde" {
		t.Fatalf("beide Denkbloecke sollten entfernt werden, bekam: %q", got)
	}
}

func TestStripThinkBlocksDropsUnterminatedTail(t *testing.T) {
	got := stripThinkBlocks("Antwort <think>abgebrochen ohne Ende")
	if got != "Antwort" {
		t.Fatalf("unterminierter Rest sollte verworfen werden, bekam: %q", got)
	}
}

func TestStripThinkBlocksNoBlockUnchanged(t *testing.T) {
	got := stripThinkBlocks("Ganz normale Antwort.")
	if got != "Ganz normale Antwort." {
		t.Fatalf("Text ohne Denkblock sollte unveraendert bleiben, bekam: %q", got)
	}
}
