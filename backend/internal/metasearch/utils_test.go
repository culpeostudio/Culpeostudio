package metasearch

import (
	"strings"
	"testing"
)

func TestNormalizeText(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{"empty", "", ""},
		{"strips tags", "<b>Hallo</b> <i>Welt</i>", "Hallo Welt"},
		{"decodes entities", "Tom &amp; Jerry &lt;3", "Tom & Jerry <3"},
		// Achtung: ddgs entfernt alle Unicode-"C"-Kategoriechars
		// (incl. \n, \t) VOR dem Whitespace-Collapse. Daher ver-
		// schmelzen "foo\n\tbar" zu "foobar" - dies entspricht dem
		// Originalverhalten.
		{"collapses whitespace", "  foo\n\tbar  baz  ", "foobar baz"},
		{"strips control chars", "foo\x00bar\x01baz", "foobarbaz"},
		{"nfc best-effort", "café", "café"},
		{"nbsp entity", "a&nbsp;b", "a b"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := NormalizeText(tt.in)
			if got != tt.want {
				t.Errorf("NormalizeText(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}

func TestNormalizeURL(t *testing.T) {
	tests := []struct {
		in   string
		want string
	}{
		{"", ""},
		{"https://example.com/foo", "https://example.com/foo"},
		// %20 -> unquote zu " " -> replace " "->"+" (entspricht Python: unquote(url).replace(" ", "+"))
		{"https://example.com/foo%20bar", "https://example.com/foo+bar"},
		{"https://example.com/foo bar", "https://example.com/foo+bar"},
		{"https://example.com/a%2Bb", "https://example.com/a+b"},
	}
	for _, tt := range tests {
		got := NormalizeURL(tt.in)
		if got != tt.want {
			t.Errorf("NormalizeURL(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestExpandProxyTBAlias(t *testing.T) {
	if got, want := ExpandProxyTBAlias("tb"), "socks5h://127.0.0.1:9150"; got != want {
		t.Errorf("tb -> %q, want %q", got, want)
	}
	if got, want := ExpandProxyTBAlias(""), ""; got != want {
		t.Errorf("empty -> %q, want %q", got, want)
	}
	if got, want := ExpandProxyTBAlias("socks5://localhost:9050"), "socks5://localhost:9050"; got != want {
		t.Errorf("passthrough -> %q, want %q", got, want)
	}
}

func TestExtractVQD(t *testing.T) {
	tests := []struct {
		html string
		want string
	}{
		{`window.__vqd = "12345-abc";`, "12345-abc"}, // not match - pattern doesn't have __
		{`vqd="12345-abc";`, "12345-abc"},
		{`vqd=98765&other=1`, "98765"},
		{`vqd='aaa'`, "aaa"},
	}
	for i, tt := range tests {
		got, err := ExtractVQD([]byte(tt.html), "test")
		// Fuer das erste Test erwarten wir einen Fehler, da das Pattern
		// nicht mit vqd= beginnt (window.__vqd ist nicht vqd). Das ist OK.
		if i == 0 {
			if err == nil {
				t.Errorf("Test %d: erwartet Fehler fuer %q, got %q", i, tt.html, got)
			}
			continue
		}
		if err != nil {
			t.Errorf("Test %d: unerwarteter Fehler %v fuer %q", i, err, tt.html)
			continue
		}
		if got != tt.want {
			t.Errorf("Test %d: ExtractVQD(%q) = %q, want %q", i, tt.html, got, tt.want)
		}
	}
}

func TestResultSetNormalized(t *testing.T) {
	r := Result{}
	r.Set("title", "<b>Hello</b>")
	r.Set("href", "https://example.com/foo%20bar")
	r.Set("body", "  extra   whitespace  ")
	if r.Title != "Hello" {
		t.Errorf("title not normalized: %q", r.Title)
	}
	if r.Href != "https://example.com/foo+bar" {
		t.Errorf("href not normalized: %q", r.Href)
	}
	if r.Body != "extra whitespace" {
		t.Errorf("body not normalized: %q", r.Body)
	}
}

func TestResultCacheKey(t *testing.T) {
	r := Result{}
	r.Set("href", "https://example.com")
	r.Set("title", "Hello")
	key, ok := r.CacheKey([]string{"href"})
	if !ok || key != "https://example.com" {
		t.Errorf("CacheKey(hrefs)= (%q,%v), want (https://example.com,true)", key, ok)
	}
	// Keine Felder gesetzt -> false
	r2 := Result{}
	key2, ok2 := r2.CacheKey([]string{"href"})
	if ok2 {
		t.Errorf("CacheKey auf leeren Result sollte false liefern, got (%q,true)", key2)
	}
}

func TestDedupByCacheFields(t *testing.T) {
	results := []Result{
		{Href: "https://example.com/a"},
		{Href: "https://example.com/b"},
		{Href: "https://example.com/a"}, // dup
		{Href: "https://example.com/c"},
	}
	out := DedupByCacheFields(results, []string{"href"})
	if len(out) != 3 {
		t.Fatalf("dedup len = %d, want 3; got %+v", len(out), out)
	}
}

func TestStripControlChars(t *testing.T) {
	out := stripControlChars("Hello\x00World\x01\b\x02ok\rfine\n")
	if !strings.Contains(out, "Hello") || strings.ContainsAny(out, "\x00\x01\x02\x08") {
		t.Errorf("unexpected output: %q", out)
	}
}
