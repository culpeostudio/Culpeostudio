// Package memorytoken estimates token counts per model family so context budgets
// can be enforced without calling a tokenizer service.
package memorytoken

import (
	"fmt"
	"log"
	"strings"
	"sync"

	"github.com/pkoukk/tiktoken-go"
	_ "github.com/pkoukk/tiktoken-go-loader"
)

type Family string

const (
	FamilyOpenAI Family = "openai"

	FamilySentencePiece Family = "sentencepiece"
)

type Config struct {
	Family    Family
	ModelPath string
}

type exactTokenizer interface {
	Count(text string) int
}

var (
	tkm  *tiktoken.Tiktoken
	once sync.Once

	activeMu sync.RWMutex
	active   exactTokenizer
)

func initEncoder() {
	once.Do(func() {

		var err error
		tkm, err = tiktoken.GetEncoding("cl100k_base")
		if err != nil {

			tkm = nil
		}
	})
}

func Configure(cfg Config) error {
	switch cfg.Family {
	case "", FamilyOpenAI:
		activeMu.Lock()
		active = nil
		activeMu.Unlock()
		return nil
	case FamilySentencePiece:
		tok, err := newSentencePieceTokenizer(cfg.ModelPath)
		if err != nil {
			log.Printf("[memory-token] sentencepiece-Tokenizer %q nicht ladbar (%v), bleibe bei cl100k_base-Heuristik", cfg.ModelPath, err)
			return err
		}
		activeMu.Lock()
		active = tok
		activeMu.Unlock()
		return nil
	default:
		err := fmt.Errorf("unbekannte Tokenizer-Familie %q", cfg.Family)
		log.Printf("[memory-token] %v, bleibe bei cl100k_base-Heuristik", err)
		return err
	}
}

func Estimate(text string) int {
	text = strings.TrimSpace(text)
	if text == "" {
		return 0
	}

	activeMu.RLock()
	tok := active
	activeMu.RUnlock()
	if tok != nil {
		if count := tok.Count(text); count > 0 {
			return count
		}
		return 1
	}

	return estimateOpenAI(text)
}

func estimateOpenAI(text string) int {
	initEncoder()
	if tkm != nil {

		tokens := tkm.Encode(text, nil, nil)
		estimate := int(float64(len(tokens)) * 1.15)
		if estimate < 1 {
			return 1
		}
		return estimate
	}

	runes := len([]rune(text))
	estimate := int(float64(runes)/3.2) + 1
	return estimate
}
