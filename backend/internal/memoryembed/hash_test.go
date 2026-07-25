package memoryembed

import "testing"

func TestHashBackendModelIsV2(t *testing.T) {
	if got := NewHashBackend(128).Model(); got != "hash-v2" {
		t.Fatalf("erwartete hash-v2, war %s", got)
	}
}

// hash-v2 fuegt Zeichen-Trigramme hinzu: morphologische Varianten teilen keine
// ganzen Woerter, aber viele Trigramme und werden dadurch aehnlich – waehrend
// unverwandte Woerter klar unaehnlicher bleiben.
func TestHashBackendTrigramsFuzzyMatch(t *testing.T) {
	backend := NewHashBackend(256)
	sim := func(a, b string) float64 {
		va, err := backend.Embed(a)
		if err != nil {
			t.Fatalf("embed %q failed: %v", a, err)
		}
		vb, err := backend.Embed(b)
		if err != nil {
			t.Fatalf("embed %q failed: %v", b, err)
		}
		return CosineSimilarity(va, vb)
	}

	morph := sim("heiße", "heißt")
	if morph <= 0 {
		t.Fatalf("morphologische Varianten sollten Aehnlichkeit >0 haben, war %v", morph)
	}
	unrelated := sim("heiße", "banane")
	if morph <= unrelated {
		t.Fatalf("Varianten sollten aehnlicher sein als Unverwandtes: morph=%v unrelated=%v", morph, unrelated)
	}

	// Ein gemeinsamer Tippfehler-Nachbar bleibt erkennbar.
	typo := sim("preference", "prefernce")
	if typo <= 0 {
		t.Fatalf("Tippfehler-Variante sollte Aehnlichkeit >0 haben, war %v", typo)
	}
}
