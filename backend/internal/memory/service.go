package memory

import (
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/memorytoken"
)

const (
	compressionThreshold = 0.70
	// ActiveWindow is the number of most recent observations kept uncompressed.
	ActiveWindow        = 6
	dedupWindow         = 30 * time.Second
	defaultContextLimit = 8
	// userRecallMaxLines caps how many recalled observations BuildUserContext
	// folds into a plain-chat system prompt. Kept small on purpose: every line
	// is extra prompt the (possibly local) model must process before it can
	// answer, so recall stays a short hint block, not a history dump.
	userRecallMaxLines = 4
	// recallCandidatePool is how many observations BuildUserContext fetches
	// before filtering anti-facts and duplicates, so enough real facts survive
	// to fill userRecallMaxLines.
	recallCandidatePool = 24
	// usageBudgetTokens is the reference size for the session usage estimate
	// (share of a typical model context the session content would occupy).
	usageBudgetTokens = 2500
)

type Repository interface {
	Initialize() error
	Close() error
	CreateSession(session *Session) error
	GetSession(userID, id string) (*Session, error)
	ListSessions(userID string) ([]*Session, error)
	DeleteSession(userID, id string) error
	AddPrompt(prompt *Prompt) error
	ListPrompts(userID, sessionID string, limit int) ([]Prompt, error)
	FindRecentObservationByHash(userID, sessionID, hash string, since time.Time) (*Observation, error)
	AddObservation(observation *Observation) error
	ListObservations(userID, sessionID string) ([]Observation, error)
	GetObservationsByIDs(userID string, ids []string) ([]Observation, error)
	// DeleteObservation removes an observation with search index, vector data
	// and dedupe bucket in one transaction; change requests are tombstoned.
	DeleteObservation(userID, observationID string) (*Observation, bool, error)
	ListMemories(userID, sessionID string) ([]CompressedMemory, error)
	// UpdateCompressedMemory patches a compressed memory. manual=true marks a
	// user correction; manual=false is rejected on corrected memories.
	UpdateCompressedMemory(userID, memoryID string, patch MemoryPatch, manual bool) (*CompressedMemory, SearchDocument, error)
	// WriteCompressedMemory writes the new memory, observation links, archives
	// observations and inserts the vector document inside one BEGIN IMMEDIATE transaction.
	WriteCompressedMemory(userID, sessionID string, plan *CompressionPlan, obsIDs []string) error
	AddSummary(summary *SessionSummary) error
	ListSummaries(userID, sessionID string) ([]SessionSummary, error)
	GetLatestSummary(userID, sessionID string) (*SessionSummary, error)
	UpdateChangeRequestStatus(userID, observationID string, state ChangeRequestState) (*Observation, error)
	UpsertSearchDocument(document SearchDocument) error
	DeleteSearchDocument(docID string) error
	SearchDocuments(query string, filters SearchFilters, limit int) ([]SearchDocument, error)
	ListDocuments(filters SearchFilters, limit int) ([]SearchDocument, error)
	GetSearchDocumentsByIDs(userID string, docIDs []string) ([]SearchDocument, error)
	UpdateSessionUsage(userID, sessionID string, usage float64) error
	UpdateSessionStatus(userID, sessionID string, status SessionStatus) error
}

type EventPublisher interface {
	Publish(eventType string, payload interface{})
}

// Options bundles the service configuration.
type Options struct {
	ProjectTag    string
	DefaultUserID string
	// ContextBudgetTokens is an approximate token budget (see memorytoken).
	ContextBudgetTokens int
	Policy              CompressionPolicy
	Summarizer          Summarizer
	// TokenizerFamily/TokenizerModelPath configure memorytoken.Estimate for
	// exact, model-specific counts instead of the cl100k_base heuristic. See
	// memorytoken.Family for valid values; empty defaults to the heuristic.
	TokenizerFamily    memorytoken.Family
	TokenizerModelPath string
}

type Service struct {
	repo               Repository
	vector             VectorIndex
	publisher          EventPublisher
	projectTag         string
	defaultUserID      string
	contextBudget      int
	policy             CompressionPolicy
	summarizer         Summarizer
	tokenizerFamily    memorytoken.Family
	tokenizerModelPath string
	onSessionCleanup   func(sessionID string)
}

func NewService(repo Repository, vector VectorIndex, publisher EventPublisher, options Options) *Service {
	if options.ContextBudgetTokens <= 0 {
		options.ContextBudgetTokens = 700
	}
	if options.Policy.UserDataThreshold <= 0 {
		options.Policy = DefaultCompressionPolicy()
	}
	if options.Summarizer == nil {
		options.Summarizer = RuleBasedSummarizer{}
	}
	return &Service{
		repo:               repo,
		vector:             vector,
		publisher:          publisher,
		projectTag:         strings.TrimSpace(options.ProjectTag),
		defaultUserID:      normalizeUserID(options.DefaultUserID, "local"),
		contextBudget:      options.ContextBudgetTokens,
		policy:             options.Policy,
		summarizer:         options.Summarizer,
		tokenizerFamily:    options.TokenizerFamily,
		tokenizerModelPath: options.TokenizerModelPath,
	}
}

func (s *Service) RegisterCleanupHandler(fn func(sessionID string)) {
	s.onSessionCleanup = fn
}

func (s *Service) Initialize() error {
	if s.tokenizerFamily != "" {
		// Best-effort: memorytoken.Configure logs and falls back to the
		// cl100k_base heuristic on its own if the model file can't be loaded.
		_ = memorytoken.Configure(memorytoken.Config{
			Family:    s.tokenizerFamily,
			ModelPath: s.tokenizerModelPath,
		})
	}
	if err := s.repo.Initialize(); err != nil {
		return err
	}
	return s.vector.Initialize()
}

func (s *Service) Close() error {
	return s.repo.Close()
}

// Policy exposes the per-layer compression thresholds for logs and metrics.
func (s *Service) Policy() CompressionPolicy { return s.policy }

// SummarizerName reports the active compression engine.
func (s *Service) SummarizerName() string { return s.summarizer.Name() }
