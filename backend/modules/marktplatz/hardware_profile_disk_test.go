package marktplatz

import (
	"testing"
)

// TestDetectDiskFreeBytesSanity prueft, dass detectDiskFreeBytes auf dem
// Testsystem einen positiven Wert liefert (Linux/macOS/Windows haben
// immer freien Speicher im CWD).  Der Test ist bewusst nicht-strict –
// wirkliche Schwellen sind CI-Plattform-abhaengig.  Wichtig: 0 (Detection
// fehlgeschlagen) ist dokumentiert als "Skip Pre-Check"; hier moechten
// wir in jedem Fall, dass die Funktion laeuft.
func TestDetectDiskFreeBytesSanity(t *testing.T) {
	got := detectDiskFreeBytes()
	if got < 0 {
		t.Fatalf("detectDiskFreeBytes should be >= 0, got %d", got)
	}
	// Auf typischen CI-/Entwicklungs-Rechnern ist mind. 1 MB frei.
	if got == 0 {
		t.Skipf("detectDiskFreeBytes returned 0 (df/powershell nicht verfuegbar) – Pre-Check wuerde hier uebersprungen werden")
	}
}

// TestDetectDiskFreeBytesStringParity fordert, dass DiskFree (String) und
// DiskFreeBytes (int64) beide einen Wert >0 liefern, so dass der String
// in der UI nicht "N/A" anzeigt, waehrend der Pre-Check rechnen wuerde.
// Beide Spuren duerfen nicht widerspruechlich sein.
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
