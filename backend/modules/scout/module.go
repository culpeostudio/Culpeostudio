package scout

import (
	"context"
	"errors"
	"fmt"
	"github.com/culpeohq/backend/modules/scout/bots"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/culpeohq/backend/internal/agentplan"
	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/modules/spark"
)

var (
	errAgentUnavailable     = errors.New("der Agent Spark ist nicht verfuegbar")
	errScoutSessionNotFound = errors.New("Scout Session wurde nicht gefunden")
	errScoutBotNotFound     = errors.New("Scout Bot wurde nicht gefunden")
	errScoutSessionBusy     = errors.New("in dieser Scout Session laeuft bereits eine anfrage")
	errModelBindingMissing  = errors.New("gebundenes Modell wurde nicht gefunden")
)

func newProviderHTTPClient() *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			DialContext: (&net.Dialer{
				Timeout:   10 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
			TLSHandshakeTimeout:   10 * time.Second,
			ResponseHeaderTimeout: 90 * time.Second,
			ExpectContinueTimeout: 1 * time.Second,
			IdleConnTimeout:       90 * time.Second,
		},
	}
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
	BotID   string `json:"bot_id,omitempty"`
	BotName string `json:"bot_name,omitempty"`
}

type scoutSession struct {
	ID                   string
	UserID               string
	ModelRef             string
	Provider             string
	ModelID              string
	DisplayName          string
	Title                string
	Messages             []chatMessage
	ActiveBotID          string
	LockedBotID          string
	ProjectID            string
	SelectedModelRef     string
	SelectedProvider     string
	SelectedModelID      string
	SelectedDisplayName  string
	SelectedContextLimit int
	Thinking             string
	Style                string
	AgenticMode          string
	AllowedRoots         []string
	ContextLimit         int

	PendingPlan *agentplan.Plan `json:"pending_plan,omitempty"`
	CreatedAt   time.Time
	UpdatedAt   time.Time

	MutationInFlight bool `json:"-"`
}

type chatOptions struct {
	Thinking         string
	Style            string
	EditMessageIndex int
	AgenticMode      string
	AllowedRoots     []string
	ApprovePlan      bool

	Planning       bool
	PreselectedBot *bots.Config
}

type providerChatHTTPError struct {
	Provider   string
	StatusCode int
	Detail     string
}

func (e *providerChatHTTPError) Error() string {
	return fmt.Sprintf("%s Chat fehlgeschlagen (%d): %s", providerDisplayName(e.Provider), e.StatusCode, e.Detail)
}

// Agent is the part of Spark the chat module drives: it runs one turn and knows
// which folder a project is bound to.
type Agent interface {
	Run(ctx context.Context, req spark.Request, turn spark.ChatTurn) (string, error)
	ProjectPath(userID, projectID string) string
	HasProject(userID, projectID string) bool
	ProjectMemoryContext(userID, projectID, query string) string
}

type ScoutModule struct {
	mu            sync.Mutex
	sessions      map[string]*scoutSession
	settingsStore *appsettings.Store
	activeModels  *apimodels.Store
	botStore      *bots.Store
	httpClient    *http.Client
	orAPIBase     string
	flAPIBase     string
	localModels   localinference.Provider
	agent         Agent
	storage       *sessionStorage
}

func New(settingsFile ...string) *ScoutModule {
	settingsPath := appsettings.DefaultSettingsFile
	if len(settingsFile) > 0 && strings.TrimSpace(settingsFile[0]) != "" {
		settingsPath = strings.TrimSpace(settingsFile[0])
	}
	botStorePath := "data/bots.json"
	sessionsDir := "data/scout_sessions"
	if settingsPath != appsettings.DefaultSettingsFile {
		botStorePath = filepath.Join(filepath.Dir(settingsPath), "bots.json")
		sessionsDir = filepath.Join(filepath.Dir(settingsPath), "scout_sessions")
	}
	return &ScoutModule{
		sessions:      make(map[string]*scoutSession),
		settingsStore: appsettings.NewStore(settingsPath),
		activeModels:  apimodels.NewStoreForSettings(settingsPath),
		botStore:      bots.NewStore(botStorePath),
		httpClient:    newProviderHTTPClient(),
		orAPIBase:     "https://openrouter.ai",
		flAPIBase:     "https://api.featherless.ai",
		storage:       newScoutStorage(sessionsDir),
	}
}

func (m *ScoutModule) Name() string { return "scout" }

func (m *ScoutModule) SetLocalModels(provider localinference.Provider) {
	m.localModels = provider
}

// SetAgent connects the chat module to Spark, which runs the agent and owns the
// projects a session can be bound to.
func (m *ScoutModule) SetAgent(agent Agent) {
	m.agent = agent
}

func (m *ScoutModule) SetExistingUsers(provider func() []string) {
	m.botStore.SetExistingUsers(provider)
}

func (m *ScoutModule) EnsureUser(userID string) error {
	return m.botStore.EnsureUser(userID)
}

func (m *ScoutModule) Initialize() error {
	if err := m.settingsStore.Load(); err != nil {
		return err
	}
	if err := m.botStore.Load(); err != nil {
		return err
	}
	m.adoptLegacySessionDir()
	m.loadPersistedSessions()
	return nil
}

// adoptLegacySessionDir moves sessions written before the module was renamed
// from culpeobot to scout, so an existing checkout keeps its chat history.
func (m *ScoutModule) adoptLegacySessionDir() {
	dir := m.storage.dir()
	if dir == "" {
		return
	}
	if _, err := os.Stat(dir); err == nil {
		return
	}
	legacy := filepath.Join(filepath.Dir(dir), "culpeobot_sessions")
	if _, err := os.Stat(legacy); err != nil {
		return
	}
	if err := os.Rename(legacy, dir); err != nil {
		log.Printf("[scout] %s konnte nicht nach %s uebernommen werden: %v", legacy, dir, err)
		return
	}
	log.Printf("[scout] %s wurde nach %s uebernommen", legacy, dir)
}

func (m *ScoutModule) loadPersistedSessions() {
	if m.storage == nil {
		return
	}
	sessions, err := m.storage.LoadAll()
	if err != nil {
		log.Printf("[scout] Persistierte Sessions konnten nicht geladen werden: %v", err)
		return
	}
	if len(sessions) == 0 {
		return
	}
	m.mu.Lock()
	for _, session := range sessions {
		m.sessions[session.ID] = session
	}
	m.mu.Unlock()
	log.Printf("[scout] %d gespeicherte Chatverlaeufe geladen", len(sessions))
}
func (m *ScoutModule) Shutdown() error { return nil }
