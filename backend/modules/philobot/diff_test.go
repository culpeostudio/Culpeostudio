package philobot

import (
	"strings"
	"testing"
)

func TestUnifiedDiffShowsChange(t *testing.T) {
	oldText := "zeile 1\nzeile 2\nzeile 3\nzeile 4\nzeile 5\n"
	newText := "zeile 1\nzeile 2\ngeaendert\nzeile 4\nzeile 5\n"

	diff := unifiedDiff(oldText, newText, "test.txt")
	if diff == "" {
		t.Fatalf("Diff sollte Aenderungen enthalten")
	}
	if !strings.Contains(diff, "--- a/test.txt") || !strings.Contains(diff, "+++ b/test.txt") {
		t.Fatalf("Header fehlt:\n%s", diff)
	}
	if !strings.Contains(diff, "-zeile 3\n") || !strings.Contains(diff, "+geaendert\n") {
		t.Fatalf("Aenderungszeilen fehlen:\n%s", diff)
	}
	if !strings.Contains(diff, "@@ -") {
		t.Fatalf("Hunk-Header fehlt:\n%s", diff)
	}
	// Kontext: Nachbarzeilen sichtbar, aber nicht die ganze Datei.
	if !strings.Contains(diff, " zeile 2\n") {
		t.Fatalf("Kontextzeile fehlt:\n%s", diff)
	}
}

func TestUnifiedDiffIdentical(t *testing.T) {
	if diff := unifiedDiff("a\nb\n", "a\nb\n", "x.txt"); diff != "" {
		t.Fatalf("identische Dateien duerfen keinen Diff haben, bekam:\n%s", diff)
	}
}

func TestUnifiedDiffNewAndDeletedFile(t *testing.T) {
	created := unifiedDiff("", "neu 1\nneu 2\n", "neu.txt")
	if !strings.Contains(created, "+neu 1\n") || strings.Contains(created, "-neu") {
		t.Fatalf("neue Datei sollte nur +-Zeilen haben:\n%s", created)
	}
	deleted := unifiedDiff("weg 1\n", "", "weg.txt")
	if !strings.Contains(deleted, "-weg 1\n") {
		t.Fatalf("geloeschte Datei sollte nur --Zeilen haben:\n%s", deleted)
	}
}

func TestUnifiedDiffSeparateHunks(t *testing.T) {
	var oldLines, newLines []string
	for i := 1; i <= 20; i++ {
		oldLines = append(oldLines, "zeile "+string(rune('a'+i)))
	}
	newLines = append(newLines, oldLines...)
	newLines[2] = "oben geaendert"
	newLines[17] = "unten geaendert"

	diff := unifiedDiff(strings.Join(oldLines, "\n")+"\n", strings.Join(newLines, "\n")+"\n", "f.txt")
	if strings.Count(diff, "@@ -") != 2 {
		t.Fatalf("zwei getrennte Aenderungen sollten zwei Hunks ergeben:\n%s", diff)
	}
}

func TestCanDiffTextLimits(t *testing.T) {
	if !canDiffText("a", "b") {
		t.Fatalf("kleine Texte sollten diffbar sein")
	}
	huge := strings.Repeat("zeile\n", 5000)
	if canDiffText(huge, "b") {
		t.Fatalf("ueber maxDiffLines hinaus sollte der Diff uebersprungen werden")
	}
}

func TestWriteFileEmitsFileChanged(t *testing.T) {
	exec, _ := newTestExecutor(t)
	var events []map[string]interface{}
	exec.emitEvent = func(eventType string, data interface{}) error {
		if eventType == "file_changed" {
			if m, ok := data.(map[string]interface{}); ok {
				events = append(events, m)
			}
		}
		return nil
	}

	mustOK(t, exec.Execute("write_file", map[string]interface{}{
		"path": "neu.txt", "content": "inhalt\n",
	}), "write_file")
	if len(events) != 1 || events[0]["action"] != "created" {
		t.Fatalf("erwartete created-Event: %v", events)
	}
	diff, _ := events[0]["diff"].(string)
	if !strings.Contains(diff, "+inhalt") {
		t.Fatalf("Diff sollte den neuen Inhalt zeigen: %q", diff)
	}

	mustOK(t, exec.Execute("patch_file", map[string]interface{}{
		"path": "neu.txt", "old_text": "inhalt", "new_text": "besser",
	}), "patch_file")
	if len(events) != 2 || events[1]["action"] != "modified" {
		t.Fatalf("erwartete modified-Event: %v", events)
	}
	diff, _ = events[1]["diff"].(string)
	if !strings.Contains(diff, "-inhalt") || !strings.Contains(diff, "+besser") {
		t.Fatalf("Patch-Diff unvollstaendig: %q", diff)
	}
}
