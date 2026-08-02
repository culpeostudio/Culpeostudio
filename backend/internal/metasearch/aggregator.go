// Package metasearch queries several public search engines at once, merges and
// ranks the results, and can fetch a page and condense it to Markdown. Requests
// to local-network addresses are refused.
package metasearch

import "sort"

type Aggregator struct {
	cacheFields []string
	counter     map[string]int
	cache       map[string]Result
}

func NewAggregator(cacheFields []string) *Aggregator {
	return &Aggregator{
		cacheFields: cacheFields,
		counter:     make(map[string]int),
		cache:       make(map[string]Result),
	}
}

func (a *Aggregator) Len() int { return len(a.cache) }

func (a *Aggregator) Append(item Result) {
	key, ok := item.CacheKey(a.cacheFields)
	if !ok {

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

func (a *Aggregator) Extend(items []Result) {
	for i := range items {
		a.Append(items[i])
	}
}

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

func (a *Aggregator) Counter() map[string]int {
	out := make(map[string]int, len(a.counter))
	for k, v := range a.counter {
		out[k] = v
	}
	return out
}

func (a *Aggregator) CacheFields() []string {
	out := make([]string, len(a.cacheFields))
	copy(out, a.cacheFields)
	return out
}
