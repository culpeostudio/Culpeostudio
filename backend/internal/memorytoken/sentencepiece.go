package memorytoken

import (
	"fmt"
	"strings"

	"github.com/eliben/go-sentencepiece"
)

// sentencePieceTokenizer wraps a real SentencePiece model (the tokenizer.model
// format used by Gemma and the Llama-2 family) for exact token counts.
type sentencePieceTokenizer struct {
	proc *sentencepiece.Processor
}

func newSentencePieceTokenizer(modelPath string) (*sentencePieceTokenizer, error) {
	modelPath = strings.TrimSpace(modelPath)
	if modelPath == "" {
		return nil, fmt.Errorf("kein Tokenizer-Modellpfad angegeben")
	}
	proc, err := sentencepiece.NewProcessorFromPath(modelPath)
	if err != nil {
		return nil, fmt.Errorf("sentencepiece-Modell laden fehlgeschlagen: %w", err)
	}
	return &sentencePieceTokenizer{proc: proc}, nil
}

func (t *sentencePieceTokenizer) Count(text string) int {
	return len(t.proc.Encode(text))
}
