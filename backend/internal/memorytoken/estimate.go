// Package memorytoken estimates LLM token counts for context budgeting.
//
// By default this is an APPROXIMATION: cl100k_base (from tiktoken-go) with a
// 15% safety margin, so a budget overrun on the model side is unlikely; the
// cost is slightly earlier truncation. Call Configure with FamilySentencePiece
// and a real tokenizer.model path (Gemma / Llama-2 family) to switch to exact
// counts for deployments running a local open-source model — Estimate then
// needs no safety margin for that path. If the model file fails to load,
// Configure logs a warning and Estimate keeps using the cl100k_base heuristic.
package memorytoken

import (
	"fmt"
	"log"
	"strings"
	"sync"

	"github.com/pkoukk/tiktoken-go"
	_ "github.com/pkoukk/tiktoken-go-loader" // Registriert den Offline-Loader
)

// Family selects which tokenizer backs Estimate.
type Family string

const (
	// FamilyOpenAI is the default cl100k_base heuristic (no model file needed).
	FamilyOpenAI Family = "openai"
	// FamilySentencePiece loads a real tokenizer.model (Gemma, Llama-2, ...)
	// for exact counts. Llama-3-style BPE tokenizers use a different file
	// format and are not covered by this family.
	FamilySentencePiece Family = "sentencepiece"
)

// Config selects the active tokenizer. ModelPath is required for
// FamilySentencePiece and ignored otherwise.
type Config struct {
	Family    Family
	ModelPath string
}

// exactTokenizer is implemented by real, model-specific tokenizers that don't
// need the heuristic safety margin.
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
		// Use cl100k_base as a general BPE tokenizer approximation
		var err error
		tkm, err = tiktoken.GetEncoding("cl100k_base")
		if err != nil {
			// Fallback is handled in Estimate
			tkm = nil
		}
	})
}

// Configure switches the active tokenizer. Safe to call again later if the
// deployment's model changes. On failure (missing/invalid model file) it
// logs and leaves the previous tokenizer (or the cl100k_base default) active.
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

// Estimate approximates the token count of text. Guarantees: >= 1 for
// non-empty text, monotonic in length, and at least one token per word.
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
		// We add a 15% safety margin to account for SentencePiece/Gemma differences
		tokens := tkm.Encode(text, nil, nil)
		estimate := int(float64(len(tokens)) * 1.15)
		if estimate < 1 {
			return 1
		}
		return estimate
	}

	// Fallback to characters-based heuristic with safety margin if tiktoken fails
	runes := len([]rune(text))
	estimate := int(float64(runes)/3.2) + 1
	return estimate
}
