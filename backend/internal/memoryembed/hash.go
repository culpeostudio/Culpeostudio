package memoryembed

import (
	"math"
	"strings"
)

// HashModel is the persisted model identifier for hash embeddings. Bump the
// version suffix if the hashing scheme ever changes, so old vectors get
// reindexed instead of silently compared against incompatible ones.
//
// v2 adds character trigrams on top of whole-word buckets: morphological
// variants ("heisse"/"heisst"/"heissen") and small typos now share most of
// their features, so the offline hash path degrades far more gracefully than
// pure whole-word matching. This is not semantic embedding (that needs a real
// model via the sidecar/Ollama/API backend), but it makes the dependency-free
// fallback noticeably fuzzier.
const HashModel = "hash-v2"

// HashBackend is token-bucket hashing, not a semantic embedding model. It is
// deterministic, dependency-free and instant, which makes it the fallback and
// the compatibility scorer for vectors written before a model switch.
type HashBackend struct {
	dims int
}

func NewHashBackend(dims int) *HashBackend {
	if dims <= 0 {
		dims = 128
	}
	return &HashBackend{dims: dims}
}

func (h *HashBackend) Name() string  { return BackendHash }
func (h *HashBackend) Model() string { return HashModel }
func (h *HashBackend) Dim() int      { return h.dims }

func (h *HashBackend) Embed(text string) ([]float32, error) {
	vector := make([]float32, h.dims)
	for _, token := range strings.Fields(strings.ToLower(text)) {
		token = strings.Trim(token, ".,!?;:\"'()[]{}…-–—/*_`")
		if token == "" {
			continue
		}
		// Whole word weighted higher so exact matches stay dominant.
		vector[hashToken(token)%uint64(h.dims)] += 2
		// Character trigrams add fuzzy overlap for morphology and typos.
		for _, gram := range charTrigrams(token) {
			vector[hashToken(gram)%uint64(h.dims)]++
		}
	}
	return normalize(vector), nil
}

// charTrigrams splits a token into boundary-anchored 3-grams. The ^/$ markers
// keep prefixes and suffixes distinguishable, so "^he" (word start) does not
// collide with a mid-word "he".
func charTrigrams(token string) []string {
	runes := []rune("^" + token + "$")
	if len(runes) < 3 {
		return nil
	}
	grams := make([]string, 0, len(runes)-2)
	for i := 0; i+3 <= len(runes); i++ {
		grams = append(grams, string(runes[i:i+3]))
	}
	return grams
}

func hashToken(token string) uint64 {
	var hash uint64 = 1469598103934665603
	for _, ch := range token {
		hash ^= uint64(ch)
		hash *= 1099511628211
	}
	return hash
}

func normalize(values []float32) []float32 {
	total := 0.0
	for _, value := range values {
		total += float64(value) * float64(value)
	}
	if total == 0 {
		return values
	}
	scale := float32(1 / math.Sqrt(total))
	for i := range values {
		values[i] *= scale
	}
	return values
}

// CosineSimilarity compares two vectors of the same model and dimensionality.
func CosineSimilarity(left, right []float32) float64 {
	if len(left) == 0 || len(left) != len(right) {
		return 0
	}
	total := 0.0
	for idx := range left {
		total += float64(left[idx]) * float64(right[idx])
	}
	return total
}
