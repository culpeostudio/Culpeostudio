package philobot

import (
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/agentplan"
	"github.com/fillyengine/backend/internal/apimodels"
	"github.com/fillyengine/backend/internal/appsettings"
	"github.com/fillyengine/backend/internal/localinference"
)

var (
	errPhiloBotSessionNotFound = errors.New("philobot session wurde nicht gefunden")
	errPhiloBotBotNotFound     = errors.New("philobot bot wurde nicht gefunden")
	errPhiloBotSessionBusy     = errors.New("in dieser philobot session laeuft bereits eine anfrage")
	errModelBindingMissing     = errors.New("gebundenes Modell wurde nicht gefunden")
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

type philoBotSession struct {
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
	PreselectedBot *BotConfig
}

type providerChatHTTPError struct {
	Provider   string
	StatusCode int
	Detail     string
}

func (e *providerChatHTTPError) Error() string {
	return fmt.Sprintf("%s Chat fehlgeschlagen (%d): %s", providerDisplayName(e.Provider), e.StatusCode, e.Detail)
}

type MemoryContextProvider interface {
	PhiloBotMemoryContext(userID, project, query string) string
}

type PhiloBotModule struct {
	mu                sync.Mutex
	sessions          map[string]*philoBotSession
	projects          map[string]*philoBotProject
	settingsStore     *appsettings.Store
	activeModels      *apimodels.Store
	botStore          *BotStore
	httpClient        *http.Client
	orAPIBase         string
	flAPIBase         string
	localModels       localinference.Provider
	memory            MemoryContextProvider
	storage           *sessionStorage
	projectStorage    *projectStorage
	permissionBrokers map[string]*permissionBroker
}

func New(settingsFile ...string) *PhiloBotModule {
	settingsPath := appsettings.DefaultSettingsFile
	if len(settingsFile) > 0 && strings.TrimSpace(settingsFile[0]) != "" {
		settingsPath = strings.TrimSpace(settingsFile[0])
	}
	botStorePath := "data/bots.json"
	sessionsDir := "data/philobot_sessions"
	projectsDir := "data/philobot_projects"
	if settingsPath != appsettings.DefaultSettingsFile {
		botStorePath = filepath.Join(filepath.Dir(settingsPath), "bots.json")
		sessionsDir = filepath.Join(filepath.Dir(settingsPath), "philobot_sessions")
		projectsDir = filepath.Join(filepath.Dir(settingsPath), "philobot_projects")
	}
	return &PhiloBotModule{
		sessions:          make(map[string]*philoBotSession),
		projects:          make(map[string]*philoBotProject),
		settingsStore:     appsettings.NewStore(settingsPath),
		activeModels:      apimodels.NewStoreForSettings(settingsPath),
		botStore:          NewBotStore(botStorePath),
		httpClient:        newProviderHTTPClient(),
		orAPIBase:         "https://openrouter.ai",
		flAPIBase:         "https://api.featherless.ai",
		storage:           newPhiloBotStorage(sessionsDir),
		projectStorage:    newPhiloBotProjectStorage(projectsDir),
		permissionBrokers: make(map[string]*permissionBroker),
	}
}

func (m *PhiloBotModule) Name() string { return "philobot" }

func (m *PhiloBotModule) SetLocalModels(provider localinference.Provider) {
	m.localModels = provider
}

func (m *PhiloBotModule) SetMemory(provider MemoryContextProvider) {
	m.memory = provider
}

func (m *PhiloBotModule) SetExistingUsers(provider func() []string) {
	m.botStore.SetExistingUsers(provider)
}

func (m *PhiloBotModule) EnsureUser(userID string) error {
	return m.botStore.EnsureUser(userID)
}

func (m *PhiloBotModule) RegisterRoutes(r fiber.Router) {
	g := r.Group("/philobot")
	g.Post("/session", m.handleCreateSession)
	g.Post("/message", m.handleMessage)
	g.Post("/stream", m.handleStream)
	g.Get("/sessions", m.handleListSessions)
	g.Get("/history/:session_id", m.handleHistory)
	g.Post("/session/:session_id/rename", m.handleRenameSession)
	g.Delete("/session/:session_id", m.handleDeleteSession)
	g.Get("/bots", m.handleGetBots)
	g.Post("/bots", m.handleSaveBot)
	g.Delete("/bots/:id", m.handleDeleteBot)
	g.Get("/projects", m.handleListProjects)
	g.Post("/project", m.handleCreateProject)
	g.Post("/project/:id/rename", m.handleRenameProject)
	g.Delete("/project/:id", m.handleDeleteProject)
	g.Post("/session/:session_id/project", m.handleSetSessionProject)
	g.Post("/session/:session_id/model", m.handleSetSessionModel)
	g.Get("/session/:session_id/tree", m.handleSessionTree)
	g.Post("/permission", m.handlePermissionResponse)
}

func (m *PhiloBotModule) Initialize() error {
	if err := m.settingsStore.Load(); err != nil {
		return err
	}
	if err := m.botStore.Load(); err != nil {
		return err
	}
	m.loadPersistedSessions()
	m.loadPersistedProjects()
	return nil
}

func (m *PhiloBotModule) loadPersistedSessions() {
	if m.storage == nil {
		return
	}
	sessions, err := m.storage.LoadAll()
	if err != nil {
		log.Printf("[philobot] Persistierte Sessions konnten nicht geladen werden: %v", err)
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
	log.Printf("[philobot] %d gespeicherte Chatverlaeufe geladen", len(sessions))
}
func (m *PhiloBotModule) Shutdown() error { return nil }
