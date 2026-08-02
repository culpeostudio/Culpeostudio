package metasearch

import (
	"net/url"
	"regexp"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"golang.org/x/net/html"
)

var stripTagsPattern = regexp.MustCompile(`<[^>]*>`)

func ExtractVQD(htmlBytes []byte, query string) (string, error) {
	markers := []struct {
		prefix []byte
		off    int
		suffix byte
	}{
		{[]byte(`vqd="`), 5, '"'},
		{[]byte("vqd="), 4, '&'},
		{[]byte(`vqd='`), 5, '\''},
	}
	for _, m := range markers {
		idx := bytesIndex(htmlBytes, m.prefix)
		if idx < 0 {
			continue
		}
		start := idx + m.off
		if start >= len(htmlBytes) {
			continue
		}
		end := bytesIndexByteFrom(htmlBytes, m.suffix, start)
		if end < 0 {
			continue
		}
		return string(htmlBytes[start:end]), nil
	}
	return "", NewError(nil, "ExtractVQD: konnte vqd fuer query="+query+" nicht extrahieren")
}

func bytesIndex(haystack, needle []byte) int {
	if len(needle) == 0 {
		return 0
	}
	if len(needle) > len(haystack) {
		return -1
	}
	for i := 0; i <= len(haystack)-len(needle); i++ {
		match := true
		for j := 0; j < len(needle); j++ {
			if haystack[i+j] != needle[j] {
				match = false
				break
			}
		}
		if match {
			return i
		}
	}
	return -1
}

func bytesIndexByteFrom(haystack []byte, needle byte, from int) int {
	if from < 0 || from >= len(haystack) {
		return -1
	}
	for i := from; i < len(haystack); i++ {
		if haystack[i] == needle {
			return i
		}
	}
	return -1
}

func NormalizeURL(raw string) string {
	if raw == "" {
		return ""
	}
	decoded, err := url.QueryUnescape(raw)
	if err != nil {
		return strings.ReplaceAll(raw, " ", "+")
	}
	return strings.ReplaceAll(decoded, " ", "+")
}

func NormalizeText(raw string) string {
	if raw == "" {
		return ""
	}
	text := stripTagsPattern.ReplaceAllString(raw, "")
	text = html.UnescapeString(text)
	text = stripControlChars(text)
	return strings.Join(strings.Fields(text), " ")
}

func stripControlChars(s string) string {
	if !utf8.ValidString(s) {
		return s
	}
	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		if unicode.IsControl(r) {
			continue
		}
		if unicode.Is(unicode.Cf, r) {
			continue
		}
		b.WriteRune(r)
	}
	return b.String()
}

func NormalizeDate(date any) string {
	if date == nil {
		return ""
	}
	switch v := date.(type) {
	case int:
		return time.Unix(int64(v), 0).UTC().Format(time.RFC3339)
	case int64:
		return time.Unix(v, 0).UTC().Format(time.RFC3339)
	case float64:
		return time.Unix(int64(v), 0).UTC().Format(time.RFC3339)
	case string:
		return v
	}
	return ""
}

func ExpandProxyTBAlias(proxy string) string {
	if proxy == "tb" {
		return "socks5h://127.0.0.1:9150"
	}
	return proxy
}

func contains(haystack, needle string) bool {
	return strings.Contains(haystack, needle)
}
