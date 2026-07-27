package metasearch

import "sort"

// Aggregator sammelt Treffer aus mehreren Engines und dedupliziert sie
// ueber die konfigurierten cacheFields. Treffer, die dieselbe URL/dasselbe
// Bild/denselben Token liefern, werden zusammengefasst; dabei gewinnt die
// Variante mit dem laengsten Body (analog zu ddgs/results.py).
//
// Haeufigkeit wird mitgefuehrt, weil das Ranking in extract() die Treffer
// absteigend nach Haeufigkeit sortiert - ein Treffer, der von mehreren
// Engines geliefert wird, steht weiter vorne.
type Aggregator struct {
	cacheFields []string
	counter     map[string]int
	cache       map[string]Result
}

// NewAggregator erzeugt einen Aggregator. cacheFields muss mindestens
// ein Feld enthalten; andernfalls wird der Treffer spaetestens beim
// ersten Append ignoriert.
func NewAggregator(cacheFields []string) *Aggregator {
	return &Aggregator{
		cacheFields: cacheFields,
		counter:     make(map[string]int),
		cache:       make(map[string]Result),
	}
}

// Len liefert die Anzahl der aktuell gespeicherten Treffer.
func (a *Aggregator) Len() int { return len(a.cache) }

// Append fuegt einen Treffer hinzu. Wenn bereits ein Treffer mit demselben
// Cache-Schluessel existiert, wird die Variante mit dem laengeren Body
// behalten. Der Zaehler wird in jedem Fall inkrementiert.
func (a *Aggregator) Append(item Result) {
	key, ok := item.CacheKey(a.cacheFields)
	if !ok {
		// Ohne Key nicht dedup-faehig; wir suchen den Treffer unter einem
		// Fallback-Schluessel ein, damit er nicht verloren geht.
		key = primaryCacheKey(&item)
		if key == "" {
			return
		}
	}
	if existing, found := a.cache[key]; !found || len(item.Body) > len(existing.Body) {
		a.cache[key] = item
	}
	a.counter[key]++
}

// Extend fuegt eine Liste von Treffern hinzu.
func (a *Aggregator) Extend(items []Result) {
	for i := range items {
		a.Append(items[i])
	}
}

// Extract liefert die Treffer als slice, absteigend sortiert nach
// Haeufigkeit (mehrere Engines => hoeherer Rang).
func (a *Aggregator) Extract() []Result {
	keys := make([]string, 0, len(a.counter))
	for k := range a.counter {
		keys = append(keys, k)
	}
	sort.SliceStable(keys, func(i, j int) bool {
		if a.counter[keys[i]] != a.counter[keys[j]] {
			return a.counter[keys[i]] > a.counter[keys[j]]
		}
		return keys[i] < keys[j]
	})
	out := make([]Result, 0, len(keys))
	for _, k := range keys {
		out = append(out, a.cache[k])
	}
	return out
}

// Counter gibt eine Kopie der Haeufigkeits-Map zurueck (nur fuer Tests).
func (a *Aggregator) Counter() map[string]int {
	out := make(map[string]int, len(a.counter))
	for k, v := range a.counter {
		out[k] = v
	}
	return out
}

// CacheFields liefert die konfigurierten Cache-Felder.
func (a *Aggregator) CacheFields() []string {
	out := make([]string, len(a.cacheFields))
	copy(out, a.cacheFields)
	return out
}
