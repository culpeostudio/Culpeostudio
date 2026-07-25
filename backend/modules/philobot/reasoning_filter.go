package philobot

import "strings"

// thinkOpenTag/thinkCloseTag markieren einen inline Denkblock, den viele
// Reasoning-Modelle (z.B. DeepSeek-R1-Distills, Nemotron) direkt in den
// Antworttext schreiben, statt ihn getrennt zu liefern. Der Nutzer soll diesen
// Rohtext live erkennen koennen, aber nicht als unformatierten JSON-/Tag-Block
// in der finalen Antwort sehen.
const (
	thinkOpenTag  = "<think>"
	thinkCloseTag = "</think>"
)

// thinkTagFilter zerlegt einen rohen Modell-Textstrom in sichtbaren
// Antworttext und Denkprozess-Text zwischen <think> und </think>. Anders als
// toolCallStreamFilter (der nur den Anfang der Antwort bewertet) kann ein
// Denkblock an beliebiger Stelle beginnen und der Strom danach normal
// weiterlaufen — daher ein einfacher Zustandsautomat statt einer einmaligen
// Ja/Nein-Entscheidung.
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

// Emit speist einen neuen Roh-Chunk ein. Vollstaendige <think>/</think>
// Uebergaenge werden sofort aufgeloest; ein evtl. am Chunk-Ende begonnenes Tag
// wird zurueckgehalten, bis der naechste Chunk es bestaetigt oder verwirft.
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

// Flush gibt am Rundenende den zurueckgehaltenen Rest an den passenden Kanal
// aus (sichtbar oder Denkprozess, je nachdem ob ein Denkblock noch offen ist).
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

// trailingTagPrefixLen liefert die Laenge des laengsten Suffixes von s, das
// ein echter Praefix von tag ist — das potenziell angefangene Tag, das
// zurueckgehalten wird, bis der naechste Chunk es bestaetigt oder verwirft.
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

// stripThinkBlocks entfernt alle <think>...</think> Bloecke aus der finalen
// Antwort. Ihr Inhalt wurde bereits live als reasoning_delta gestreamt; in der
// gespeicherten/finalen Antwort waeren sie nur unformatierter Rohtext. Ein
// nicht geschlossener Denkblock (Modell wurde abgeschnitten) wird bis zum
// Ende der Antwort verworfen, da danach kein verwertbarer sichtbarer Text
// mehr folgen kann.
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
