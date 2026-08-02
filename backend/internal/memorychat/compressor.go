// Package memorychat compresses finished dialogue pairs into structured chat
// memories and rolling summaries.
package memorychat

import (
	"strings"
	"sync"
	"time"
	"unicode"

	"github.com/fillyengine/backend/internal/memory"
)

type Dialogue struct {
	ID        int
	Speaker   string
	Content   string
	Timestamp time.Time
}

type Compressor struct {
	mu          sync.Mutex
	windowSize  int
	overlapSize int
	maxChars    int
	buffers     map[string][]Dialogue
	counters    map[string]int
}

func NewCompressor(windowSize, overlapSize int) *Compressor {
	if windowSize <= 0 {
		windowSize = 6
	}
	if overlapSize < 0 {
		overlapSize = 0
	}
	if overlapSize >= windowSize {
		overlapSize = windowSize - 1
	}
	return &Compressor{
		windowSize:  windowSize,
		overlapSize: overlapSize,
		maxChars:    900,
		buffers:     map[string][]Dialogue{},
		counters:    map[string]int{},
	}
}

func (c *Compressor) ClearSession(sessionID string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	sessionID = strings.TrimSpace(sessionID)
	delete(c.buffers, sessionID)
	delete(c.counters, sessionID)
}

func (c *Compressor) HasSession(sessionID string) bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	sessionID = strings.TrimSpace(sessionID)
	_, hasBuf := c.buffers[sessionID]
	_, hasCnt := c.counters[sessionID]
	return hasBuf || hasCnt
}

func (c *Compressor) CompressPair(sessionID, userText, assistantText string, at time.Time) []memory.AddObservationInput {
	if at.IsZero() {
		at = time.Now().UTC()
	}
	sessionID = strings.TrimSpace(sessionID)
	userText = cleanText(userText)
	assistantText = cleanText(assistantText)
	if sessionID == "" || (userText == "" && assistantText == "") {
		return []memory.AddObservationInput{}
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	dialogues := []Dialogue{}
	if userText != "" {
		dialogues = append(dialogues, c.nextDialogue(sessionID, "user", userText, at))
	}
	if assistantText != "" {
		dialogues = append(dialogues, c.nextDialogue(sessionID, "assistant", assistantText, at.Add(time.Millisecond)))
	}
	c.buffers[sessionID] = append(c.buffers[sessionID], dialogues...)

	result := []memory.AddObservationInput{c.pairObservation(dialogues, userText, assistantText, at)}
	if len(c.buffers[sessionID]) >= c.windowSize {
		window := append([]Dialogue{}, c.buffers[sessionID][:c.windowSize]...)
		result = append(result, c.windowObservation(window, at))

		if c.overlapSize > 0 {
			c.buffers[sessionID] = append([]Dialogue{}, c.buffers[sessionID][c.windowSize-c.overlapSize:]...)
		} else {
			c.buffers[sessionID] = c.buffers[sessionID][c.windowSize:]
		}
	}
	return result
}

func (c *Compressor) nextDialogue(sessionID, speaker, content string, at time.Time) Dialogue {
	c.counters[sessionID]++
	return Dialogue{
		ID:        c.counters[sessionID],
		Speaker:   speaker,
		Content:   content,
		Timestamp: at,
	}
}

func (c *Compressor) pairObservation(dialogues []Dialogue, userText, assistantText string, at time.Time) memory.AddObservationInput {
	combined := strings.TrimSpace(userText + " " + assistantText)
	keywords := extractKeywords(combined, 12)
	persons := extractPersons(combined)
	entities := extractEntities(combined)
	topic := topicFromKeywords(keywords)
	layer, category := routeLayerCategory(combined)
	narrativeParts := []string{}
	if userText != "" {
		narrativeParts = append(narrativeParts, "User request: "+compactText(userText, c.maxChars/2))
	}
	if assistantText != "" {
		narrativeParts = append(narrativeParts, "Assistant answer: "+compactText(assistantText, c.maxChars/2))
	}
	dialogueID := 0
	if len(dialogues) > 0 {
		dialogueID = dialogues[0].ID
	}
	return memory.AddObservationInput{
		Source:     "chat",
		Layer:      layer,
		Category:   category,
		Type:       "chat_memory",
		Title:      "Chat memory: " + fallbackTopic(topic),
		Narrative:  strings.Join(narrativeParts, "\n"),
		Speaker:    "user+assistant",
		DialogueID: dialogueID,
		Keywords:   keywords,
		Persons:    persons,
		Entities:   entities,
		Topic:      topic,
		ValidFrom:  at.UTC().Format(time.RFC3339),
		Importance: importanceFor(layer, category),
		Confidence: 0.62,
		Tags:       normalizeTags(append([]string{"chat", "simplemem", "dialogue-pair"}, keywords...)),
	}
}

func (c *Compressor) windowObservation(window []Dialogue, at time.Time) memory.AddObservationInput {
	parts := make([]string, 0, len(window))
	combined := strings.Builder{}
	for _, dialogue := range window {
		line := dialogue.Speaker + " said: " + compactText(dialogue.Content, 260)
		parts = append(parts, line)
		combined.WriteString(" ")
		combined.WriteString(dialogue.Content)
	}
	text := combined.String()
	keywords := extractKeywords(text, 16)
	persons := extractPersons(text)
	entities := extractEntities(text)
	topic := topicFromKeywords(keywords)
	layer, category := routeLayerCategory(text)
	dialogueID := 0
	if len(window) > 0 {
		dialogueID = window[0].ID
	}
	return memory.AddObservationInput{
		Source:     "chat",
		Layer:      layer,
		Category:   category,
		Type:       "chat_memory",
		Title:      "Chat window summary: " + fallbackTopic(topic),
		Narrative:  strings.Join(parts, "\n"),
		Speaker:    "chat_window",
		DialogueID: dialogueID,
		Keywords:   keywords,
		Persons:    persons,
		Entities:   entities,
		Topic:      topic,
		ValidFrom:  at.UTC().Format(time.RFC3339),
		Importance: importanceFor(layer, category) + 0.05,
		Confidence: 0.58,
		Tags:       normalizeTags(append([]string{"chat", "simplemem", "sliding-window"}, keywords...)),
	}
}

func routeLayerCategory(text string) (memory.MemoryLayer, memory.MemoryCategory) {
	lower := strings.ToLower(text)
	switch {
	case containsAny(lower, []string{"ich ", "mein ", "meine ", "persoenlich", "persönlich", "vorliebe", "preference"}):
		return memory.LayerUserData, memory.CategoryStatus
	case containsAny(lower, []string{"aenderungsantrag", "änderungsantrag", "change request", "vorschlag"}):
		return memory.LayerProjectData, memory.CategoryChangeRequest
	case containsAny(lower, []string{"brainstorm", "idee", "ideen", "skizze", "moeglichkeit", "möglichkeit"}):
		return memory.LayerProjectData, memory.CategoryBrainstorming
	default:
		return memory.LayerProjectData, memory.CategoryStatus
	}
}

func importanceFor(layer memory.MemoryLayer, category memory.MemoryCategory) float64 {
	switch {
	case layer == memory.LayerUserData:
		return 0.82
	case category == memory.CategoryChangeRequest:
		return 0.78
	case category == memory.CategoryBrainstorming:
		return 0.60
	default:
		return 0.66
	}
}

func extractKeywords(text string, limit int) []string {
	seen := map[string]struct{}{}
	result := []string{}
	for _, raw := range strings.Fields(text) {
		token := cleanToken(raw)
		key := strings.ToLower(token)
		if token == "" || len([]rune(token)) < 3 || stopword(key) {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, token)
		if len(result) == limit {
			break
		}
	}
	return result
}

var commonNouns = map[string]struct{}{
	"projekt": {}, "modul": {}, "tabelle": {}, "datenbank": {}, "server": {}, "befehl": {}, "fehler": {}, "datei": {},
	"ordner": {}, "pfad": {}, "verzeichnis": {}, "wert": {}, "schluessel": {}, "schlüssel": {}, "anfrage": {}, "antwort": {},
	"sitzung": {}, "verbindung": {}, "benutzer": {}, "token": {}, "modell": {}, "code": {}, "entwicklung": {}, "test": {},
	"ausfuehrung": {}, "ausführung": {}, "version": {}, "ausgabe": {}, "eintrag": {}, "beobachtung": {}, "kompression": {},
	"zusammenfassung": {}, "suche": {}, "index": {}, "vektor": {}, "distanz": {}, "aenderung": {}, "änderung": {},
	"vorschlag": {}, "status": {}, "rolle": {}, "ziel": {}, "kategorie": {}, "bereich": {}, "inhalt": {}, "zeit": {},
	"datum": {}, "sekunde": {}, "minute": {}, "stunde": {}, "tag": {}, "woche": {}, "monat": {}, "jahr": {},
	"schritt": {}, "plan": {}, "arbeit": {}, "dokument": {}, "zeile": {}, "spalte": {}, "feld": {}, "typ": {},
	"name": {}, "text": {}, "system": {}, "assistent": {}, "verlauf": {}, "nachricht": {}, "gespraech": {}, "gespräch": {},
	"dialog": {}, "anwendung": {}, "web": {}, "bibliothek": {}, "paket": {}, "funktion": {}, "variable": {}, "klasse": {},
	"methode": {}, "parameter": {}, "argument": {}, "schnittstelle": {}, "treiber": {}, "pool": {},
	"transaktion": {}, "sperre": {}, "schreiben": {}, "lesen": {}, "aktualisierung": {}, "loeschung": {}, "löschung": {},
	"erstellung": {}, "abfrage": {}, "daten": {}, "speicher": {}, "arbeitsspeicher": {}, "prozessor": {}, "kern": {},
	"ressource": {}, "grenze": {}, "budget": {}, "zeichen": {}, "wort": {}, "satz": {}, "absatz": {}, "seite": {},
	"titel": {}, "beschreibung": {}, "ergebnis": {}, "erfolgreich": {}, "fehlgeschlagen": {}, "warnung": {},
	"information": {}, "hinweis": {}, "beispiel": {}, "konfiguration": {}, "einstellung": {}, "umgebung": {},
	"benutzername": {}, "berechtigung": {}, "zugriff": {}, "sicherheit": {}, "verschluesselung": {},
	"zertifikat": {}, "primärschlüssel": {}, "fremdschlüssel": {}, "aehnlichkeit": {}, "ähnlichkeit": {},
	"abstand": {}, "treffer": {}, "gedaechtnis": {}, "gedächtnis": {}, "erkenntnis": {}, "aufgabe": {},
}

func extractPersons(text string) []string {
	result := []string{}
	seen := map[string]struct{}{}
	words := strings.Fields(text)
	startsSentence := true

	for _, raw := range words {
		token := cleanToken(raw)

		endsSentence := false
		if len(raw) > 0 {
			lastChar := raw[len(raw)-1]
			if lastChar == '.' || lastChar == '!' || lastChar == '?' {
				endsSentence = true
			}
		}

		if strings.HasPrefix(token, "@") {
			token = strings.TrimPrefix(token, "@")
		}

		if token == "" || len([]rune(token)) < 3 || !unicode.IsUpper([]rune(token)[0]) {
			startsSentence = endsSentence
			continue
		}

		if strings.Contains(token, ".") || strings.Contains(token, "/") || strings.ToUpper(token) == token {
			startsSentence = endsSentence
			continue
		}

		key := strings.ToLower(token)

		if _, isCommon := commonNouns[key]; isCommon {
			startsSentence = endsSentence
			continue
		}
		if stopword(key) {
			startsSentence = endsSentence
			continue
		}

		if startsSentence && !strings.HasPrefix(raw, "@") {
			startsSentence = endsSentence
			continue
		}

		if _, ok := seen[key]; ok {
			startsSentence = endsSentence
			continue
		}

		seen[key] = struct{}{}
		result = append(result, token)

		startsSentence = endsSentence
		if len(result) == 8 {
			break
		}
	}
	return result
}

func extractEntities(text string) []string {
	result := []string{}
	seen := map[string]struct{}{}
	known := map[string]struct{}{
		"go": {}, "fiber": {}, "sqlite": {}, "philox": {}, "myphiloengine": {}, "simplemem": {}, "embedding": {}, "embeddings": {}, "onnx": {}, "lora": {},
	}
	for _, raw := range strings.Fields(text) {
		token := cleanToken(raw)
		key := strings.ToLower(token)
		_, isKnown := known[key]
		if token == "" || (!isKnown && !strings.Contains(token, "/") && !strings.Contains(token, ".") && strings.ToUpper(token) != token) {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, token)
		if len(result) == 10 {
			break
		}
	}
	return result
}

func topicFromKeywords(keywords []string) string {
	if len(keywords) == 0 {
		return ""
	}
	limit := len(keywords)
	if limit > 4 {
		limit = 4
	}
	return strings.Join(keywords[:limit], " ")
}

func fallbackTopic(topic string) string {
	if strings.TrimSpace(topic) == "" {
		return "dialogue"
	}
	return compactText(topic, 80)
}

func normalizeTags(tags []string) []string {
	result := []string{}
	seen := map[string]struct{}{}
	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		if tag == "" {
			continue
		}
		key := strings.ToLower(tag)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, tag)
	}
	return result
}

func cleanText(text string) string {
	return strings.Join(strings.Fields(strings.TrimSpace(text)), " ")
}

func compactText(text string, max int) string {
	text = cleanText(text)
	if max <= 0 || len(text) <= max {
		return text
	}
	if max <= 3 {
		return text[:max]
	}
	return text[:max-3] + "..."
}

func cleanToken(token string) string {
	return strings.TrimFunc(token, func(r rune) bool {
		return unicode.IsSpace(r) || strings.ContainsRune("\"'`.,;:!?()[]{}<>", r)
	})
}

func containsAny(text string, hints []string) bool {
	for _, hint := range hints {
		if strings.Contains(text, hint) {
			return true
		}
	}
	return false
}

func stopword(token string) bool {
	_, ok := map[string]struct{}{
		"und": {}, "oder": {}, "aber": {}, "der": {}, "die": {}, "das": {}, "den": {}, "dem": {}, "des": {}, "ein": {}, "eine": {}, "einer": {}, "mit": {}, "von": {}, "fuer": {}, "für": {}, "auf": {}, "ist": {}, "sind": {}, "ich": {}, "wir": {}, "du": {}, "mir": {}, "mein": {}, "meine": {}, "the": {}, "and": {}, "for": {}, "with": {}, "that": {}, "this": {}, "you": {}, "are": {},
	}[token]
	return ok
}
