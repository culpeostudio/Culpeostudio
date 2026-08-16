// Package reasoningcatalog keeps a local copy of the OpenRouter model
// catalogue's per-model metadata: which thinking levels a model supports and
// how large its context window is. The backend refreshes it once at startup;
// when the machine is offline the fetch is skipped silently and the last
// persisted snapshot keeps serving both.
package reasoningcatalog

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// ModelsURL is the public OpenRouter model list. It needs no token.
const ModelsURL = "https://openrouter.ai/api/v1/models"

// Entry is what the catalogue knows about one OpenRouter model: its reasoning
// capability and the size of its context window in tokens.
type Entry struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	// ContextLength is zero for a model the catalogue does not report one for,
	// and for every entry written before the field existed - those fill in on
	// the next refresh.
	ContextLength int `json:"context_length,omitempty"`
	// MaxOutputTokens is the longest single answer the model will produce. It
	// is a separate, usually much smaller number than ContextLength, and zero
	// when unreported.
	MaxOutputTokens  int      `json:"max_output_tokens,omitempty"`
	Mandatory        bool     `json:"mandatory"`
	DefaultEnabled   bool     `json:"default_enabled"`
	SupportedEfforts []string `json:"supported_efforts"`
	DefaultEffort    string   `json:"default_effort"`
}

// snapshot is the on-disk shape: entries plus when they were fetched.
type snapshot struct {
	FetchedAt time.Time `json:"fetched_at"`
	Entries   []Entry   `json:"entries"`
}

// apiModel mirrors only the fields of the OpenRouter response we keep.
type apiModel struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	// The catalogue reports the window twice: once for the model and once for
	// the provider currently serving it. The second one is the smaller, real
	// limit when a provider truncates, so the lower of the two wins.
	ContextLength int `json:"context_length"`
	TopProvider   *struct {
		ContextLength       int `json:"context_length"`
		MaxCompletionTokens int `json:"max_completion_tokens"`
	} `json:"top_provider"`
	Reasoning *struct {
		Mandatory        bool     `json:"mandatory"`
		DefaultEnabled   bool     `json:"default_enabled"`
		SupportedEfforts []string `json:"supported_efforts"`
		DefaultEffort    string   `json:"default_effort"`
	} `json:"reasoning"`
}

type apiResponse struct {
	Data []apiModel `json:"data"`
}

// Catalog serves the last known reasoning metadata. The zero value is not
// usable; construct with New.
type Catalog struct {
	mu         sync.RWMutex
	path       string
	url        string
	httpClient *http.Client
	entries    []Entry
	fetchedAt  time.Time
}

// New returns a catalog persisted at path. A nil httpClient gets a sane
// default with a modest timeout.
func New(path string, httpClient *http.Client) *Catalog {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 20 * time.Second}
	}
	return &Catalog{path: strings.TrimSpace(path), url: ModelsURL, httpClient: httpClient}
}

// Load reads the persisted snapshot. A missing or unreadable file is not an
// error - the catalog simply stays empty and callers fall back to defaults.
func (c *Catalog) Load() {
	if c.path == "" {
		return
	}
	raw, err := os.ReadFile(c.path)
	if err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			log.Printf("[reasoningcatalog] Snapshot konnte nicht gelesen werden: %v", err)
		}
		return
	}
	var snap snapshot
	if err := json.Unmarshal(raw, &snap); err != nil {
		log.Printf("[reasoningcatalog] Snapshot ist ungueltig: %v", err)
		return
	}
	c.mu.Lock()
	c.entries = snap.Entries
	c.fetchedAt = snap.FetchedAt
	c.mu.Unlock()
}

// Refresh pulls the current OpenRouter model list and persists the reasoning
// metadata. Any failure (offline, timeout, bad payload) keeps the previous
// data and is only logged.
func (c *Catalog) Refresh(ctx context.Context) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.url, nil)
	if err != nil {
		log.Printf("[reasoningcatalog] Request konnte nicht gebaut werden: %v", err)
		return
	}
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		log.Printf("[reasoningcatalog] OpenRouter nicht erreichbar (offline?): %v", err)
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		log.Printf("[reasoningcatalog] OpenRouter antwortete mit Status %d", resp.StatusCode)
		return
	}

	var payload apiResponse
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		log.Printf("[reasoningcatalog] Antwort konnte nicht gelesen werden: %v", err)
		return
	}

	entries := make([]Entry, 0, len(payload.Data))
	for _, model := range payload.Data {
		id := strings.TrimSpace(model.ID)
		if id == "" {
			continue
		}
		entry := Entry{ID: id, Name: strings.TrimSpace(model.Name)}
		entry.ContextLength = model.ContextLength
		if model.TopProvider != nil {
			if window := model.TopProvider.ContextLength; window > 0 {
				if entry.ContextLength <= 0 || window < entry.ContextLength {
					entry.ContextLength = window
				}
			}
			if output := model.TopProvider.MaxCompletionTokens; output > 0 {
				entry.MaxOutputTokens = output
			}
		}
		if entry.ContextLength < 0 {
			entry.ContextLength = 0
		}
		if entry.MaxOutputTokens < 0 {
			entry.MaxOutputTokens = 0
		}
		if model.Reasoning != nil {
			entry.Mandatory = model.Reasoning.Mandatory
			entry.DefaultEnabled = model.Reasoning.DefaultEnabled
			entry.SupportedEfforts = normalizeEfforts(model.Reasoning.SupportedEfforts)
			entry.DefaultEffort = normalizeEffort(model.Reasoning.DefaultEffort)
		}
		entries = append(entries, entry)
	}
	if len(entries) == 0 {
		log.Printf("[reasoningcatalog] OpenRouter lieferte keine Modelle, Snapshot bleibt unveraendert")
		return
	}

	c.mu.Lock()
	c.entries = entries
	c.fetchedAt = time.Now()
	c.mu.Unlock()
	c.persist()
}

// Profiles returns a copy of the current entries, possibly empty.
func (c *Catalog) Profiles() []Entry {
	c.mu.RLock()
	defer c.mu.RUnlock()
	out := make([]Entry, len(c.entries))
	copy(out, c.entries)
	return out
}

// ContextLengthFor returns the context window of one model in tokens, or zero
// when the catalogue does not cover it. See MatchID for how a model id is
// resolved against the catalogue.
func (c *Catalog) ContextLengthFor(modelID string) int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	entry, ok := matchEntry(c.entries, modelID)
	if !ok {
		return 0
	}
	return entry.ContextLength
}

// MaxOutputTokensFor returns the longest answer one model will produce, or zero
// when the catalogue does not cover it.
func (c *Catalog) MaxOutputTokensFor(modelID string) int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	entry, ok := matchEntry(c.entries, modelID)
	if !ok {
		return 0
	}
	return entry.MaxOutputTokens
}

// AverageMaxOutputTokens is the mean answer ceiling over every entry that
// reports one - the stand-in for a model the catalogue does not know, for the
// same reason AverageContextLength is.
func (c *Catalog) AverageMaxOutputTokens() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	total := 0
	counted := 0
	for _, entry := range c.entries {
		if entry.MaxOutputTokens <= 0 {
			continue
		}
		total += entry.MaxOutputTokens
		counted++
	}
	if counted == 0 {
		return 0
	}
	return total / counted
}

// AverageContextLength is the mean window over every entry that reports one.
// It is what a model outside the catalogue is measured against - a made-up
// constant would be either far too small for a modern model or far too large
// for a small one. Zero when nothing is known yet.
func (c *Catalog) AverageContextLength() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	total := 0
	counted := 0
	for _, entry := range c.entries {
		if entry.ContextLength <= 0 {
			continue
		}
		total += entry.ContextLength
		counted++
	}
	if counted == 0 {
		return 0
	}
	return total / counted
}

// matchEntry resolves a model id against the catalogue. Ids arrive in several
// shapes - "openai/gpt-5.6", the bare "gpt-5.6" a configured endpoint serves,
// or a name with a vendor suffix - so an exact hit is tried first, then the
// part after the slash, and only then a containment match.
func matchEntry(entries []Entry, modelID string) (Entry, bool) {
	needle := strings.ToLower(strings.TrimSpace(modelID))
	if needle == "" {
		return Entry{}, false
	}
	for _, entry := range entries {
		if strings.ToLower(entry.ID) == needle {
			return entry, true
		}
	}
	needleTail := modelTail(needle)
	for _, entry := range entries {
		if modelTail(strings.ToLower(entry.ID)) == needleTail {
			return entry, true
		}
	}
	// Longest match wins: "gpt-5.6" must not shadow "gpt-5.6-mini" for a
	// needle that names the mini variant.
	best := Entry{}
	bestLen := 0
	for _, entry := range entries {
		id := strings.ToLower(entry.ID)
		if id == "" || !strings.Contains(needle, id) {
			continue
		}
		if len(id) > bestLen {
			best, bestLen = entry, len(id)
		}
	}
	return best, bestLen > 0
}

// modelTail drops the vendor prefix, so the "gpt-5.6" a configured endpoint
// serves resolves to the catalogue's "openai/gpt-5.6".
func modelTail(id string) string {
	if index := strings.LastIndex(id, "/"); index >= 0 {
		return id[index+1:]
	}
	return id
}

// persist writes the snapshot atomically (temp file + rename) so a crash
// mid-write cannot corrupt the last good copy.
func (c *Catalog) persist() {
	if c.path == "" {
		return
	}
	c.mu.RLock()
	snap := snapshot{FetchedAt: c.fetchedAt, Entries: c.entries}
	c.mu.RUnlock()

	raw, err := json.Marshal(snap)
	if err != nil {
		log.Printf("[reasoningcatalog] Snapshot konnte nicht kodiert werden: %v", err)
		return
	}
	if err := os.MkdirAll(filepath.Dir(c.path), 0o755); err != nil {
		log.Printf("[reasoningcatalog] Verzeichnis konnte nicht angelegt werden: %v", err)
		return
	}
	tmp := c.path + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o644); err != nil {
		log.Printf("[reasoningcatalog] Snapshot konnte nicht geschrieben werden: %v", err)
		return
	}
	if err := os.Rename(tmp, c.path); err != nil {
		log.Printf("[reasoningcatalog] Snapshot konnte nicht abgelegt werden: %v", err)
	}
}

// KnownEfforts is the canonical low-to-high order of OpenRouter reasoning
// effort tokens.
var KnownEfforts = []string{"none", "minimal", "low", "medium", "high", "xhigh", "max"}

// normalizeEffort lowercases and trims one token; unknown tokens come back
// empty so callers can fall back to defaults.
func normalizeEffort(raw string) string {
	token := strings.ToLower(strings.TrimSpace(raw))
	for _, known := range KnownEfforts {
		if token == known {
			return token
		}
	}
	return ""
}

// normalizeEfforts filters and orders tokens into the canonical order.
func normalizeEfforts(raw []string) []string {
	seen := map[string]bool{}
	for _, token := range raw {
		if normalized := normalizeEffort(token); normalized != "" {
			seen[normalized] = true
		}
	}
	out := make([]string, 0, len(seen))
	for _, known := range KnownEfforts {
		if seen[known] {
			out = append(out, known)
		}
	}
	return out
}
