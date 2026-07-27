package engines

import (
	"strings"
	"testing"

	"github.com/fillyengine/backend/internal/metasearch"
)

// TestUnwrapBingURL prueft, dass Bing-Wrapped-URLs korrekt dekodiert werden.
func TestUnwrapBingURL(t *testing.T) {
	// Beispiel: Bing packt die Original-URL in Base64 (urlsafe) nach 2
	// zufaelligen Zeichen. enc("https://example.com/foo"):
	encoded := "aHR0cHM6Ly9leGFtcGxlLmNvbS9mb28="
	raw := "https://www.bing.com/ck/a?u=aX" + encoded
	got := unwrapBingURL(raw)
	want := "https://example.com/foo"
	if got != want {
		t.Errorf("unwrapBingURL(%q) = %q, want %q", raw, got, want)
	}
}

func TestUnwrapBingURLNoU(t *testing.T) {
	in := "https://example.com/normal"
	got := unwrapBingURL(in)
	if got != in {
		t.Errorf("passthrough failed: got %q, want %q", got, in)
	}
}

func TestSplitRegion(t *testing.T) {
	tests := []struct {
		in          string
		wantCountry string
		wantLang    string
	}{
		{"us-en", "us", "en"},
		{"DE-de", "de", "de"},
		{"UK-en", "uk", "en"},
		{"", "us", "en"},
		{"france", "france", "en"},
	}
	for _, tt := range tests {
		c, l := splitRegion(tt.in)
		if c != tt.wantCountry || l != tt.wantLang {
			t.Errorf("splitRegion(%q) = (%q,%q), want (%q,%q)",
				tt.in, c, l, tt.wantCountry, tt.wantLang)
		}
	}
}

func TestHasPrefix(t *testing.T) {
	if !hasPrefix("https://duckduckgo.com/y.js?x", "https://duckduckgo.com/y.js?") {
		t.Error("hasPrefix true expected")
	}
	if hasPrefix("foo", "https://duckduckgo.com/y.js?") {
		t.Error("hasPrefix false expected")
	}
}

// TestEnginesBuildText liefert keine Engine ohne gueltigen HttpClient.
// Wir erwarten, dass Build("text", "auto", client) mindestens 4
// Engines liefert (wikipedia,bing,brave,google,duckduckgo).
func TestEnginesBuildText(t *testing.T) {
	client, err := metasearch.NewHttpClient(metasearch.ClientOptions{Timeout: 5 * 1000_000_000})
	if err != nil {
		t.Fatalf("client: %v", err)
	}
	engs := Build("text", "auto", client)
	if len(engs) < 4 {
		t.Errorf("erwartet >=4 Engines, got %d", len(engs))
	}
	names := make([]string, 0, len(engs))
	for _, e := range engs {
		names = append(names, e.Info().Name)
	}
	want := []string{"bing", "brave", "duckduckgo", "google", "wikipedia"}
	for _, w := range want {
		if !nameInList(names, w) {
			t.Errorf("engine %q fehlt in Built-Liste %v", w, names)
		}
	}
	// Bevorzugtes Subset Test: backend wuerde nur wikipedia,google erlauben
	engs2 := Build("text", "wikipedia,google", client)
	if len(engs2) != 2 {
		t.Errorf("erwartet 2 Engines fuer wikipedia,google, got %d", len(engs2))
	}
}

func nameInList(list []string, want string) bool {
	for _, n := range list {
		if n == want {
			return true
		}
	}
	return false
}

// TestAvailableBackendFilter erwartet die Filterung ueber den Backend-Parameter.
func TestAvailableBackendFilter(t *testing.T) {
	all := Available("text", "auto")
	if !nameInList(all, "wikipedia") || !nameInList(all, "brave") {
		t.Errorf("auto-liste enthaelt wikipedia+brave nicht: %v", all)
	}
	sub := Available("text", "wikipedia,google")
	if len(sub) != 2 || !nameInList(sub, "wikipedia") || !nameInList(sub, "google") {
		t.Errorf("backend-filter lieferte %v, want [wikipedia google]", sub)
	}
	// Engines, die es nicht gibt, werden ignoriert.
	none := Available("text", "nonexistent,foo")
	if len(none) != 0 {
		t.Errorf("alle nichtexistenten Engines sollten leer liefern, got %v", none)
	}
}

// TestGoogleUANotLeer prueft, dass der User-Agent-Generator schreibt.
func TestGoogleUANotLeer(t *testing.T) {
	ua := getGoogleUA()
	if !strings.HasPrefix(ua, "Mozilla/5.0 (Linux; Android") {
		t.Errorf("ungewoehnlicher Google-UA: %q", ua)
	}
	if !strings.Contains(ua, "Chrome/") {
		t.Errorf("UA enthaelt kein Chrome: %q", ua)
	}
	if !strings.HasSuffix(ua, "NSTNWV") {
		t.Errorf("UA tail fehlt: %q", ua)
	}
}

// TestWikipediaLang stellt sicher, dass aus einer regionsfreien Suche kein
// ungueltiger Wikipedia-Host wird ("wt-wt" -> wt.wikipedia.org existiert nicht).
func TestWikipediaLang(t *testing.T) {
	cases := map[string]string{
		"wt":   "en", // DuckDuckGo-Konvention fuer "weltweit"
		"":     "en",
		"xx":   "en",
		"de":   "de",
		"EN":   "en",
		" fr ": "fr",
	}
	for in, want := range cases {
		if got := wikipediaLang(in); got != want {
			t.Errorf("wikipediaLang(%q) = %q, erwartet %q", in, got, want)
		}
	}
}
