// Package streamtext holds the small scanning helpers that both the chat module
// and the agent need while a model reply is still arriving in chunks.
package streamtext

import "strings"

// TrailingTagPrefixLen reports how many characters at the end of s could still
// grow into tag. A streaming filter holds those characters back instead of
// emitting a half-written tag.
func TrailingTagPrefixLen(s, tag string) int {
	max := len(tag) - 1
	if max > len(s) {
		max = len(s)
	}
	for k := max; k > 0; k-- {
		if strings.HasSuffix(s, tag[:k]) {
			return k
		}
	}
	return 0
}

// FindJSONObjectEnd returns the index just past the JSON object that starts at
// start, honouring strings and escapes. The second result is false when the
// object is not closed within text.
func FindJSONObjectEnd(text string, start int) (int, bool) {
	depth := 0
	inString := false
	escaped := false
	for i := start; i < len(text); i++ {
		ch := text[i]
		if inString {
			if escaped {
				escaped = false
				continue
			}
			if ch == '\\' {
				escaped = true
				continue
			}
			if ch == '"' {
				inString = false
			}
			continue
		}
		switch ch {
		case '"':
			inString = true
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return i + 1, true
			}
		}
	}
	return 0, false
}
