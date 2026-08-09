package metasearch

import (
	"strings"
	"testing"
)

func TestHTMLToMarkdownBasic(t *testing.T) {
	in := `<html><body>
<h1>Title</h1>
<p>This is a <b>bold</b> and <i>italic</i> test with a <a href="https://example.com">link</a>.</p>
<ul><li>one</li><li>two</li></ul>
<pre><code>console.log("hi")</code></pre>
</body></html>`
	out := HTMLToMarkdown(in)
	checks := map[string]bool{
		"# Title":                     strings.Contains(out, "# Title"),
		"**bold**":                    strings.Contains(out, "**bold**"),
		"*italic*":                    strings.Contains(out, "*italic*"),
		"[link](https://example.com)": strings.Contains(out, "[link](https://example.com)"),
		"- one":                       strings.Contains(out, "- one"),
		"- two":                       strings.Contains(out, "- two"),
		"```":                         strings.Contains(out, "```"),
		"console.log":                 strings.Contains(out, "console.log"),
	}
	for want, ok := range checks {
		if !ok {
			t.Errorf("Markdown-Output vermisst %q\noutput:\n%s", want, out)
		}
	}
}

func TestHTMLToMarkdownNoScript(t *testing.T) {
	in := `<div><p>visible</p><script>alert('hidden')</script></div>`
	out := HTMLToMarkdown(in)
	if strings.Contains(out, "alert") {
		t.Errorf("script-Inhalt sollte nicht erscheinen: %q", out)
	}
	if !strings.Contains(out, "visible") {
		t.Errorf("sichtbarer Inhalt fehlt: %q", out)
	}
}

func TestHTMLToMarkdownOnGarbage(t *testing.T) {
	out := HTMLToMarkdown("not html at all")
	if !strings.Contains(out, "not html at all") {
		t.Errorf("plain text sollte plain durchkommen: %q", out)
	}
}
