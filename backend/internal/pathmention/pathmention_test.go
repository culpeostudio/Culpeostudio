package pathmention

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestExtractFindetGenanntesVerzeichnis(t *testing.T) {
	dir := t.TempDir()
	got := Extract("Schau mal in " + dir + " nach")
	if len(got) != 1 {
		t.Fatalf("erwartete 1 Treffer, bekam %v", got)
	}
	if !sameDir(got[0], dir) {
		t.Fatalf("Extract = %q, erwartet %q", got[0], dir)
	}
}

func TestExtractLiefertOrdnerZurDatei(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "main.go")
	if err := os.WriteFile(file, []byte("package main"), 0o600); err != nil {
		t.Fatal(err)
	}
	got := Extract("Bitte " + file + " anpassen")
	if len(got) != 1 || !sameDir(got[0], dir) {
		t.Fatalf("Extract = %v, erwartet Ordner %q", got, dir)
	}
}

func TestExtractIgnoriertErfundenePfade(t *testing.T) {
	for _, message := range []string{
		"Lege sowas wie /home/nichtvorhanden/projekt an",
		`Unter C:\gibtesnicht\projekt liegt es`,
		"Der Pfad /var/tmp/gibtesganzsichernicht-12345 ist gemeint",
	} {
		if got := Extract(message); len(got) != 0 {
			t.Errorf("Extract(%q) = %v, erwartet leer", message, got)
		}
	}
}

func TestExtractIgnoriertSystemverzeichnisse(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("Unix-Pfade")
	}
	for _, message := range []string{
		"Schau in /etc/hosts",
		"Die Bibliothek liegt in /usr/lib",
		"Log unter /var/log/syslog pruefen",
		"/proc/cpuinfo auslesen",
	} {
		if got := Extract(message); len(got) != 0 {
			t.Errorf("Extract(%q) = %v, Systempfade duerfen nicht automatisch freigegeben werden", message, got)
		}
	}
}

func TestExtractIgnoriertWurzel(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("Unix-Pfade")
	}
	if got := Extract("Alles unter / durchsuchen"); len(got) != 0 {
		t.Errorf("Extract = %v, das Wurzelverzeichnis darf nie freigegeben werden", got)
	}
}

func TestExtractDedupliziert(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "a.txt")
	if err := os.WriteFile(file, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	got := Extract("Erst " + dir + ", dann " + file + " und nochmal " + dir)
	if len(got) != 1 {
		t.Fatalf("erwartete 1 Treffer nach Deduplikation, bekam %v", got)
	}
}

func TestExtractTrenntSatzzeichenAb(t *testing.T) {
	dir := t.TempDir()
	for _, message := range []string{
		"Der Ordner ist " + dir + ".",
		"Der Ordner ist " + dir + ",",
		"Der Ordner ist (" + dir + ")",
		`Der Ordner ist "` + dir + `"`,
	} {
		got := Extract(message)
		if len(got) != 1 || !sameDir(got[0], dir) {
			t.Errorf("Extract(%q) = %v, erwartet %q", message, got, dir)
		}
	}
}

func TestExtractTildeUnterordner(t *testing.T) {
	home, err := os.UserHomeDir()
	if err != nil || home == "" {
		t.Skip("kein Heimatverzeichnis")
	}
	sub, err := os.MkdirTemp(home, "pathmention-test-")
	if err != nil {
		t.Skip("kein Schreibrecht im Heimatverzeichnis")
	}
	defer os.RemoveAll(sub)

	got := Extract("Schau in ~/" + filepath.Base(sub) + " nach")
	if len(got) != 1 || !sameDir(got[0], sub) {
		t.Fatalf("Extract = %v, erwartet %q", got, sub)
	}
}

func TestExtractIgnoriertHeimatverzeichnisSelbst(t *testing.T) {
	home, err := os.UserHomeDir()
	if err != nil || home == "" {
		t.Skip("kein Heimatverzeichnis")
	}
	for _, message := range []string{"Schau in ~/ nach", "Alles unter " + home + " durchsuchen"} {
		if got := Extract(message); len(got) != 0 {
			t.Errorf("Extract(%q) = %v, das Heimatverzeichnis darf nicht automatisch freigegeben werden", message, got)
		}
	}

	if got := Extract("Schau in ~root nach"); len(got) != 0 {
		t.Errorf("Extract = %v, erwartet leer", got)
	}
}

func TestExtractLeereEingabe(t *testing.T) {
	for _, message := range []string{"", "   ", "Ganz normaler Satz ohne Pfad."} {
		if got := Extract(message); len(got) != 0 {
			t.Errorf("Extract(%q) = %v, erwartet leer", message, got)
		}
	}
}

func sameDir(a, b string) bool {
	if resolved, err := filepath.EvalSymlinks(b); err == nil {
		b = resolved
	}
	return strings.EqualFold(filepath.Clean(a), filepath.Clean(b))
}
