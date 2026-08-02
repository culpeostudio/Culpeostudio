package memoryembed

import (
	"math"
	"strings"
)

const HashModel = "hash-v2"

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

		vector[hashToken(token)%uint64(h.dims)] += 2

		for _, gram := range charTrigrams(token) {
			vector[hashToken(gram)%uint64(h.dims)]++
		}
	}
	return normalize(vector), nil
}

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
