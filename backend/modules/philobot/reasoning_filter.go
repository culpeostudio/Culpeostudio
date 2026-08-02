package philobot

import "strings"

const (
	thinkOpenTag  = "<think>"
	thinkCloseTag = "</think>"
)

type thinkTagFilter struct {
	emitVisible   func(string) error
	emitReasoning func(string) error
	buf           strings.Builder
	consumed      int
	inThink       bool
}

func newThinkTagFilter(emitVisible, emitReasoning func(string) error) *thinkTagFilter {
	if emitVisible == nil {
		emitVisible = func(string) error { return nil }
	}
	if emitReasoning == nil {
		emitReasoning = func(string) error { return nil }
	}
	return &thinkTagFilter{emitVisible: emitVisible, emitReasoning: emitReasoning}
}

func (f *thinkTagFilter) Emit(chunk string) error {
	f.buf.WriteString(chunk)
	for {
		s := f.buf.String()[f.consumed:]
		tag := thinkOpenTag
		sink := f.emitVisible
		if f.inThink {
			tag = thinkCloseTag
			sink = f.emitReasoning
		}
		idx := strings.Index(s, tag)
		if idx == -1 {
			holdBack := trailingTagPrefixLen(s, tag)
			visible := len(s) - holdBack
			if visible <= 0 {
				return nil
			}
			if err := sink(s[:visible]); err != nil {
				return err
			}
			f.consumed += visible
			return nil
		}
		if idx > 0 {
			if err := sink(s[:idx]); err != nil {
				return err
			}
		}
		f.consumed += idx + len(tag)
		f.inThink = !f.inThink
	}
}

func (f *thinkTagFilter) Flush() error {
	s := f.buf.String()[f.consumed:]
	if s == "" {
		return nil
	}
	f.consumed += len(s)
	if f.inThink {
		return f.emitReasoning(s)
	}
	return f.emitVisible(s)
}

func trailingTagPrefixLen(s, tag string) int {
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

func stripThinkBlocks(s string) string {
	if !strings.Contains(s, thinkOpenTag) {
		return s
	}
	var b strings.Builder
	rest := s
	for {
		start := strings.Index(rest, thinkOpenTag)
		if start == -1 {
			b.WriteString(rest)
			break
		}
		b.WriteString(rest[:start])
		afterOpen := rest[start+len(thinkOpenTag):]
		end := strings.Index(afterOpen, thinkCloseTag)
		if end == -1 {
			break
		}
		rest = afterOpen[end+len(thinkCloseTag):]
	}
	return strings.TrimSpace(b.String())
}
