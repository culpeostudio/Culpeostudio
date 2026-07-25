package memory

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"
)

type SessionStatus string
type PromptRole string
type MemoryLayer string
type MemoryCategory string
type ChangeRequestStatus string

const (
	SessionActive    SessionStatus = "active"
	SessionCompleted SessionStatus = "completed"

	PromptRoleUser      PromptRole = "user"
	PromptRoleAssistant PromptRole = "assistant"
	PromptRoleSystem    PromptRole = "system"

	LayerUserData    MemoryLayer = "user_data"
	LayerProjectData MemoryLayer = "project_data"

	CategoryStatus        MemoryCategory = "status"
	CategoryBrainstorming MemoryCategory = "brainstorming"
	CategoryChangeRequest MemoryCategory = "aenderungsantrag"

	ChangeRequestOpen     ChangeRequestStatus = "offen"
	ChangeRequestAccepted ChangeRequestStatus = "angenommen"
	ChangeRequestRejected ChangeRequestStatus = "verworfen"
)

type Prompt struct {
	UserID    string     `json:"user_id"`
	ID        string     `json:"id"`
	SessionID string     `json:"session_id"`
	Role      PromptRole `json:"role"`
	Text      string     `json:"text"`
	CreatedAt time.Time  `json:"created_at"`
}

type Observation struct {
	UserID        string              `json:"user_id"`
	ID            string              `json:"id"`
	SessionID     string              `json:"session_id"`
	Project       string              `json:"project"`
	Source        string              `json:"source"`
	Layer         MemoryLayer         `json:"layer"`
	Category      MemoryCategory      `json:"category,omitempty"`
	Type          string              `json:"type"`
	Title         string              `json:"title"`
	Narrative     string              `json:"narrative"`
	ChangeRequest *ChangeRequestState `json:"change_request,omitempty"`
	Speaker       string              `json:"speaker,omitempty"`
	DialogueID    int                 `json:"dialogue_id,omitempty"`
	Keywords      []string            `json:"keywords,omitempty"`
	Persons       []string            `json:"persons,omitempty"`
	Entities      []string            `json:"entities,omitempty"`
	Topic         string              `json:"topic,omitempty"`
	Location      string              `json:"location,omitempty"`
	ValidFrom     string              `json:"valid_from,omitempty"`
	Importance    float64             `json:"importance,omitempty"`
	Confidence    float64             `json:"confidence,omitempty"`
	SupersededBy  string              `json:"superseded_by,omitempty"`
	ToolName      string              `json:"tool_name,omitempty"`
	SourcePath    string              `json:"source_path,omitempty"`
	Tags          []string            `json:"tags,omitempty"`
	ContentHash   string              `json:"content_hash"`
	Archived      bool                `json:"archived"`
	MemoryID      string              `json:"memory_id,omitempty"`
	// DeletedAt is set on soft-deleted (tombstoned) change requests. The row
	// stays in the store for traceability but drops out of every query.
	DeletedAt string    `json:"deleted_at,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type CompressedMemory struct {
	UserID         string         `json:"user_id"`
	ID             string         `json:"id"`
	SessionID      string         `json:"session_id"`
	Layer          MemoryLayer    `json:"layer"`
	Category       MemoryCategory `json:"category,omitempty"`
	Summary        string         `json:"summary"`
	Learned        []string       `json:"learned,omitempty"`
	OpenTasks      []string       `json:"open_tasks,omitempty"`
	ObservationIDs []string       `json:"observation_ids,omitempty"`
	// CorrectedByUser marks manual edits; automatic re-compression must not
	// overwrite such memories.
	CorrectedByUser bool      `json:"corrected_by_user,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

type SessionSummary struct {
	UserID    string    `json:"user_id"`
	ID        string    `json:"id"`
	SessionID string    `json:"session_id"`
	Learned   []string  `json:"learned,omitempty"`
	Completed []string  `json:"completed,omitempty"`
	NextSteps []string  `json:"next_steps,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type Session struct {
	UserID                string             `json:"user_id"`
	ID                    string             `json:"id"`
	Project               string             `json:"project"`
	Source                string             `json:"source"`
	Status                SessionStatus      `json:"status"`
	Goals                 []string           `json:"goals,omitempty"`
	Prompts               []Prompt           `json:"prompts,omitempty"`
	ActiveObservations    []Observation      `json:"active_observations"`
	ArchivedObservations  []Observation      `json:"archived_observations,omitempty"`
	Memories              []CompressedMemory `json:"memories,omitempty"`
	Summaries             []SessionSummary   `json:"summaries,omitempty"`
	ContextUsageEstimate  float64            `json:"context_usage_estimate"`
	PromptCount           int                `json:"prompt_count"`
	ObservationCount      int                `json:"observation_count"`
	CompressedMemoryCount int                `json:"compressed_memory_count"`
	SummaryCount          int                `json:"summary_count"`
	CreatedAt             time.Time          `json:"created_at"`
	UpdatedAt             time.Time          `json:"updated_at"`
}

type SearchResult struct {
	DocID       string         `json:"doc_id"`
	UserID      string         `json:"user_id"`
	SessionID   string         `json:"session_id"`
	RefID       string         `json:"ref_id"`
	Kind        string         `json:"kind"`
	Project     string         `json:"project"`
	Source      string         `json:"source"`
	Layer       MemoryLayer    `json:"layer"`
	Category    MemoryCategory `json:"category,omitempty"`
	Type        string         `json:"type"`
	Title       string         `json:"title"`
	Snippet     string         `json:"snippet"`
	Score       float64        `json:"score"`
	TextScore   float64        `json:"text_score"`
	VectorScore float64        `json:"vector_score"`
	CreatedAt   time.Time      `json:"created_at"`
}

type ContextEnvelope struct {
	SessionID string `json:"session_id"`
	Query     string `json:"query,omitempty"`
	// Budget and usage are approximate token counts (see memorytoken): a
	// conservative heuristic with safety margin, not the exact tokenizer of
	// Gemma/SentencePiece models.
	BudgetTokens    int                `json:"budget_tokens"`
	UsedTokens      int                `json:"used_tokens"`
	InjectionPrompt string             `json:"injection_prompt"`
	Memories        []CompressedMemory `json:"memories"`
	Observations    []Observation      `json:"observations"`
	Summary         *SessionSummary    `json:"summary,omitempty"`
	ToolHints       []ToolDefinition   `json:"tool_hints"`
}

type ToolDefinition struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	JSONShape   string `json:"json_shape"`
}

type SearchFilters struct {
	UserID   string         `json:"user_id,omitempty"`
	Project  string         `json:"project,omitempty"`
	Source   string         `json:"source,omitempty"`
	Layer    MemoryLayer    `json:"layer,omitempty"`
	Category MemoryCategory `json:"category,omitempty"`
	Type     string         `json:"type,omitempty"`
	Limit    int            `json:"limit,omitempty"`
}

type TimelineQuery struct {
	ObservationID string `json:"observation_id,omitempty"`
	Query         string `json:"query,omitempty"`
	Before        int    `json:"before,omitempty"`
	After         int    `json:"after,omitempty"`
}

type SearchDocument struct {
	DocID      string         `json:"doc_id"`
	UserID     string         `json:"user_id"`
	SessionID  string         `json:"session_id"`
	RefID      string         `json:"ref_id"`
	Kind       string         `json:"kind"`
	Project    string         `json:"project"`
	Source     string         `json:"source"`
	Layer      MemoryLayer    `json:"layer"`
	Category   MemoryCategory `json:"category,omitempty"`
	Type       string         `json:"type"`
	Title      string         `json:"title"`
	Body       string         `json:"body"`
	SourcePath string         `json:"source_path,omitempty"`
	Tags       []string       `json:"tags,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
	TextScore  float64        `json:"text_score,omitempty"`
}

type CreateSessionInput struct {
	UserID    string   `json:"user_id"`
	SessionID string   `json:"session_id"`
	Project   string   `json:"project"`
	Source    string   `json:"source"`
	Goals     []string `json:"goals"`
}

type AddPromptInput struct {
	UserID string     `json:"user_id"`
	Role   PromptRole `json:"role"`
	Text   string     `json:"text"`
}

type AddObservationInput struct {
	UserID        string              `json:"user_id"`
	Project       string              `json:"project"`
	Source        string              `json:"source"`
	Layer         MemoryLayer         `json:"layer"`
	Category      MemoryCategory      `json:"category"`
	Type          string              `json:"type"`
	Title         string              `json:"title"`
	Narrative     string              `json:"narrative"`
	ChangeRequest *ChangeRequestState `json:"change_request"`
	Speaker       string              `json:"speaker"`
	DialogueID    int                 `json:"dialogue_id"`
	Keywords      []string            `json:"keywords"`
	Persons       []string            `json:"persons"`
	Entities      []string            `json:"entities"`
	Topic         string              `json:"topic"`
	Location      string              `json:"location"`
	ValidFrom     string              `json:"valid_from"`
	Importance    float64             `json:"importance"`
	Confidence    float64             `json:"confidence"`
	SupersededBy  string              `json:"superseded_by"`
	ToolName      string              `json:"tool_name"`
	SourcePath    string              `json:"source_path"`
	Tags          []string            `json:"tags"`
}

type CompleteSessionInput struct {
	UserID    string   `json:"user_id"`
	Learned   []string `json:"learned"`
	Completed []string `json:"completed"`
	NextSteps []string `json:"next_steps"`
}

type GetObservationsInput struct {
	UserID string   `json:"user_id"`
	IDs    []string `json:"ids"`
}

type ChangeRequestState struct {
	Status      ChangeRequestStatus `json:"status"`
	Proposal    string              `json:"vorschlag"`
	ReasonShort string              `json:"begruendung_kurz"`
	DecidedAt   string              `json:"entschieden_am,omitempty"`
}

type UpdateChangeRequestInput struct {
	UserID      string              `json:"user_id"`
	Status      ChangeRequestStatus `json:"status"`
	ReasonShort string              `json:"begruendung_kurz"`
}

// MemoryPatch updates single fields of a compressed memory; nil fields stay
// untouched.
type MemoryPatch struct {
	Summary   *string   `json:"summary"`
	Learned   *[]string `json:"learned"`
	OpenTasks *[]string `json:"open_tasks"`
}

// ErrCorrectedByUser is returned when an automatic rewrite hits a memory that
// carries a manual correction.
var ErrCorrectedByUser = errors.New("compressed memory wurde manuell korrigiert und wird nicht automatisch ueberschrieben")

// CompressionPlan is the outcome of one compression decision: the memory to
// write, its search document, and the usage estimates around the cycle. It is
// produced inside the store's write transaction so read, threshold check and
// write commit together.
type CompressionPlan struct {
	Memory      *CompressedMemory
	Document    SearchDocument
	UsageBefore float64
	UsageAfter  float64
}

// VectorHit is one similarity match from the vector index. ScoredBy reports
// whether the real embedding backend or the hash fallback produced the score,
// which feeds the recall-loss metric.
type VectorHit struct {
	DocID    string  `json:"doc_id"`
	Score    float64 `json:"score"`
	ScoredBy string  `json:"scored_by"`
}

// VectorIndex abstracts the vector search layer so the service does not
// depend on a concrete implementation (avoids import cycles and makes the
// backend swappable in tests).
type VectorIndex interface {
	Initialize() error
	Upsert(document SearchDocument) error
	Delete(docID string) error
	Search(query string, filters SearchFilters, limit int) ([]VectorHit, error)
}

// VectorMetrics is exposed via the metrics endpoint.
type VectorMetrics struct {
	Backend          string         `json:"backend"`
	Model            string         `json:"model"`
	Dim              int            `json:"dim"`
	EmbeddingHits    uint64         `json:"embedding_hits"`
	HashFallbackHits uint64         `json:"hash_fallback_hits"`
	ReindexRemaining int            `json:"reindex_remaining"`
	DocsByModel      map[string]int `json:"docs_by_model,omitempty"`
}

type CompressionPolicy struct {
	UserDataThreshold          int
	ProjectStatusThreshold     int
	ProjectBrainstormThreshold int
	ChangeRequestThreshold     int
}

func DefaultCompressionPolicy() CompressionPolicy {
	return CompressionPolicy{
		UserDataThreshold:          1000000,
		ProjectStatusThreshold:     24,
		ProjectBrainstormThreshold: 8,
		ChangeRequestThreshold:     1000000,
	}
}

func newID(prefix string) string {
	// crypto/rand.Read never fails (guaranteed since Go 1.24); 64 random bits
	// make collisions practically impossible, unlike timestamp-based IDs.
	bytes := make([]byte, 8)
	_, _ = rand.Read(bytes)
	return fmt.Sprintf("%s-%s", prefix, hex.EncodeToString(bytes))
}

func newSessionID() string {
	return newID("memsess")
}

func newPromptID() string {
	return newID("prompt")
}

func newObservationID() string {
	return newID("obs")
}

func newMemoryID() string {
	return newID("memory")
}

func newSummaryID() string {
	return newID("summary")
}

func nowUTC() time.Time {
	return time.Now().UTC()
}

func normalizeList(values []string) []string {
	result := make([]string, 0, len(values))
	seen := map[string]struct{}{}
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		key := strings.ToLower(trimmed)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, trimmed)
	}
	return result
}

func previewText(text string, max int) string {
	trimmed := strings.Join(strings.Fields(strings.TrimSpace(text)), " ")
	if len(trimmed) <= max {
		return trimmed
	}
	// Cut on rune boundaries so multi-byte characters (umlauts etc.) are
	// never split into invalid UTF-8.
	runes := []rune(trimmed)
	if len(runes) <= max {
		return trimmed
	}
	if max <= 3 {
		return string(runes[:max])
	}
	return string(runes[:max-3]) + "..."
}

func normalizePromptRole(role PromptRole) PromptRole {
	switch role {
	case PromptRoleAssistant:
		return PromptRoleAssistant
	case PromptRoleSystem:
		return PromptRoleSystem
	default:
		return PromptRoleUser
	}
}

func normalizeLayer(raw MemoryLayer) MemoryLayer {
	switch strings.ToLower(strings.TrimSpace(string(raw))) {
	case string(LayerUserData):
		return LayerUserData
	default:
		return LayerProjectData
	}
}

func normalizeCategory(raw MemoryCategory) MemoryCategory {
	switch strings.ToLower(strings.TrimSpace(string(raw))) {
	case string(CategoryBrainstorming):
		return CategoryBrainstorming
	case string(CategoryChangeRequest), "änderungsantrag", "change_request":
		return CategoryChangeRequest
	case string(CategoryStatus):
		return CategoryStatus
	default:
		return CategoryStatus
	}
}

func normalizeChangeRequestStatus(raw ChangeRequestStatus) ChangeRequestStatus {
	switch strings.ToLower(strings.TrimSpace(string(raw))) {
	case string(ChangeRequestAccepted):
		return ChangeRequestAccepted
	case string(ChangeRequestRejected):
		return ChangeRequestRejected
	default:
		return ChangeRequestOpen
	}
}

func normalizeUserID(value, fallback string) string {
	clean := strings.TrimSpace(value)
	if clean != "" {
		return clean
	}
	if strings.TrimSpace(fallback) != "" {
		return strings.TrimSpace(fallback)
	}
	return "local"
}

func normalizeObservationType(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "decision", "task", "tool_result", "tool_start", "insight", "assistant_reply", "event", "summary", "change_request", "chat_memory":
		return strings.ToLower(strings.TrimSpace(raw))
	default:
		return "note"
	}
}

func contentHash(sessionID, title, narrative string) string {
	sum := sha256.Sum256([]byte(sessionID + "|" + title + "|" + narrative))
	return hex.EncodeToString(sum[:8])
}

func RenderChangeRequestNarrative(state *ChangeRequestState) string {
	if state == nil {
		return ""
	}
	return fmt.Sprintf(
		"status=%s | vorschlag=%s | begruendung_kurz=%s | entschieden_am=%s",
		normalizeChangeRequestStatus(state.Status),
		strings.TrimSpace(state.Proposal),
		strings.TrimSpace(state.ReasonShort),
		strings.TrimSpace(state.DecidedAt),
	)
}

func defaultToolDefinitions() []ToolDefinition {
	return []ToolDefinition{
		{
			Name:        "memory_search",
			Description: "Search compact project memory results before fetching details.",
			JSONShape:   `{"query":"string","type":"optional string","source":"optional string","limit":"optional int"}`,
		},
		{
			Name:        "memory_timeline",
			Description: "Fetch chronological context around an observation or search query.",
			JSONShape:   `{"observation_id":"optional string","query":"optional string","before":"optional int","after":"optional int"}`,
		},
		{
			Name:        "memory_get_observations",
			Description: "Fetch full observation details by IDs after filtering search results.",
			JSONShape:   `{"ids":["obs-1","obs-2"]}`,
		},
	}
}

var ErrAlreadyArchived = errors.New("observations already archived")
