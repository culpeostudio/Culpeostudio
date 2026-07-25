package philobot

import (
	"strings"
	"unicode/utf8"

	"github.com/rivo/uniseg"
)

type streamingTextEmitter struct {
	pendingBytes []byte
	pending      string
	emit         func(string) error
}

func newStreamingTextEmitter(emit func(string) error) *streamingTextEmitter {
	return &streamingTextEmitter{emit: emit}
}

func (e *streamingTextEmitter) Emit(text string) error {
	if e.emit == nil || text == "" {
		return nil
	}
	e.pendingBytes = append(e.pendingBytes, []byte(text)...)
	completeText, restBytes := consumeCompleteUTF8(e.pendingBytes)
	e.pendingBytes = restBytes
	if completeText == "" {
		return nil
	}
	e.pending += completeText
	visible, restText := splitLeavingLastGrapheme(e.pending)
	e.pending = restText
	return emitTextAsGraphemes(visible, e.emit)
}

func (e *streamingTextEmitter) Flush() error {
	if e.emit == nil {
		return nil
	}
	if len(e.pendingBytes) > 0 {
		completeText, _ := consumeCompleteUTF8(e.pendingBytes)
		e.pendingBytes = nil
		e.pending += completeText
	}
	if e.pending == "" {
		return nil
	}
	pending := e.pending
	e.pending = ""
	return emitTextAsGraphemes(pending, e.emit)
}

func consumeCompleteUTF8(data []byte) (string, []byte) {
	if len(data) == 0 {
		return "", nil
	}
	var out strings.Builder
	out.Grow(len(data))
	i := 0
	for i < len(data) {
		if !utf8.FullRune(data[i:]) {
			break
		}
		r, size := utf8.DecodeRune(data[i:])
		if r == utf8.RuneError && size == 1 {
			// A complete invalid byte cannot be fixed by a later chunk.
			i++
			continue
		}
		out.Write(data[i : i+size])
		i += size
	}
	return out.String(), append([]byte(nil), data[i:]...)
}

func emitTextAsGraphemes(text string, emit func(string) error) error {
	if emit == nil {
		return nil
	}
	graphemes := uniseg.NewGraphemes(text)
	for graphemes.Next() {
		if err := emit(graphemes.Str()); err != nil {
			return err
		}
	}
	return nil
}

func splitLeavingLastGrapheme(text string) (string, string) {
	if text == "" {
		return "", ""
	}
	graphemes := uniseg.NewGraphemes(text)
	clusters := make([]string, 0, len(text))
	for graphemes.Next() {
		clusters = append(clusters, graphemes.Str())
	}
	if len(clusters) <= 1 {
		return "", text
	}
	return strings.Join(clusters[:len(clusters)-1], ""), clusters[len(clusters)-1]
}
