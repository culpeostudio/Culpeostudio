// Package spark is the agent. It owns projects and their own memory scope, the
// tool loop, planning mode, the project file tools and the approval prompts
// that guard anything outside a bound folder.
package spark

import (
	"context"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/culpeohq/backend/modules/spark/tools"

	"github.com/culpeohq/backend/internal/agentplan"
	"github.com/culpeohq/backend/internal/appsettings"
)

// Message is one turn of the conversation handed to the agent.
type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// ChatTurn asks the caller's model for a single completion. The agent supplies
// the conversation and the system prompt; visible text is streamed through emit
// while the returned string carries the full reply.
type ChatTurn func(convo []Message, systemPrompt string, emit func(string) error) (string, error)

// Request describes one agent run.
type Request struct {
	UserID       string
	SessionID    string
	Message      string
	History      []Message
	SystemPrompt string
	ProjectPath  string
	Planning     bool
	ApprovePlan  bool
	// Budget is the context window of the model that answers this run. The
	// tool loop needs it because its own conversation grows with every tool
	// result, and nothing else in this package can know how much room there is.
	Budget    ContextBudget
	EmitText  func(string) error
	EmitEvent func(eventType string, data interface{}) error
}

// PlanStore holds a plan across turns. The owner of the chat session implements
// it, so neither a proposal waiting for approval nor a half-worked plan is lost
// when the process goes down.
type PlanStore interface {
	StorePendingPlan(userID, sessionID string, plan *agentplan.Plan)
	TakePendingPlan(userID, sessionID string) *agentplan.Plan

	// StoreActivePlan records the plan being worked off, after every step, so a
	// crash mid-run leaves the worklist exactly where it stopped.
	StoreActivePlan(userID, sessionID string, plan *agentplan.Plan)

	// ActivePlan returns the plan being worked off without clearing it.
	ActivePlan(userID, sessionID string) *agentplan.Plan

	// ClearActivePlan drops it once every step is green.
	ClearActivePlan(userID, sessionID string)
}

// MemoryProvider gives every project its own recall scope.
type MemoryProvider interface {
	ProjectMemoryContext(userID, project, query string) string
	EnsureProjectScope(userID, project string) error
	PurgeProjectScope(userID, project string) error
}

// Module registers the agent routes and runs the agent for the chat module.
type Module struct {
	mu                sync.Mutex
	projects          map[string]*Project
	projectStore      *projectStore
	permissionBrokers map[string]*tools.Broker
	plans             PlanStore
	memory            MemoryProvider
	projectDetached   func(userID, projectID string)
}

func New(settingsFile ...string) *Module {
	settingsPath := appsettings.DefaultSettingsFile
	if len(settingsFile) > 0 && strings.TrimSpace(settingsFile[0]) != "" {
		settingsPath = strings.TrimSpace(settingsFile[0])
	}
	projectsDir := "data/spark_projects"
	if settingsPath != appsettings.DefaultSettingsFile {
		projectsDir = filepath.Join(filepath.Dir(settingsPath), "spark_projects")
	}
	return &Module{
		projects:          make(map[string]*Project),
		projectStore:      newProjectStore(projectsDir),
		permissionBrokers: make(map[string]*tools.Broker),
	}
}

func (m *Module) Name() string { return "spark" }

func (m *Module) Initialize() error {
	m.adoptLegacyProjectDir()
	m.loadPersistedProjects()
	return nil
}

func (m *Module) Shutdown() error { return nil }

// SetPlanStore hands plan persistence to the module that owns chat sessions.
func (m *Module) SetPlanStore(store PlanStore) { m.plans = store }

// SetMemory connects the per-project memory scope.
func (m *Module) SetMemory(provider MemoryProvider) { m.memory = provider }

// SetProjectDetachedHook is called after a project was deleted, so sessions
// bound to it can be released.
func (m *Module) SetProjectDetachedHook(hook func(userID, projectID string)) {
	m.projectDetached = hook
}

// adoptLegacyProjectDir moves project files written before the agent became its
// own module, so an existing checkout keeps its projects.
func (m *Module) adoptLegacyProjectDir() {
	dir := m.projectStore.dir()
	if dir == "" {
		return
	}
	if _, err := os.Stat(dir); err == nil {
		return
	}
	parent := filepath.Dir(dir)
	for _, legacyName := range []string{"scout_projects", "culpeobot_projects"} {
		legacy := filepath.Join(parent, legacyName)
		if _, err := os.Stat(legacy); err != nil {
			continue
		}
		if err := os.Rename(legacy, dir); err != nil {
			log.Printf("[spark] %s konnte nicht nach %s uebernommen werden: %v", legacy, dir, err)
			return
		}
		log.Printf("[spark] %s wurde nach %s uebernommen", legacy, dir)
		return
	}
}

// Run executes one agent turn: planning mode when asked, the project tool loop
// when the session is bound to a folder, and the web-only loop otherwise.
func (m *Module) Run(ctx context.Context, req Request, turn ChatTurn) (string, error) {
	if handled, reply, err := m.runPlanningFlow(ctx, req, turn); handled {
		return reply, err
	}

	roots := resolveToolRoots(req.ProjectPath, req.Message, req.History)
	if len(roots) == 0 {
		return runWebOnlyToolLoop(ctx, req.History, req.SystemPrompt, req.EmitText, req.EmitEvent, turn, req.Budget)
	}

	broker := tools.NewBroker()
	m.attachBroker(req.SessionID, broker)
	defer m.releaseBroker(req.SessionID, broker)
	return runToolLoop(ctx, req.History, req.SystemPrompt, roots, req.EmitText, req.EmitEvent,
		turn, broker, req.SessionID, req.Budget)
}

func (m *Module) attachBroker(sessionID string, broker *tools.Broker) {
	m.mu.Lock()
	m.permissionBrokers[sessionID] = broker
	m.mu.Unlock()
}

func (m *Module) releaseBroker(sessionID string, broker *tools.Broker) {
	m.mu.Lock()
	if m.permissionBrokers[sessionID] == broker {
		delete(m.permissionBrokers, sessionID)
	}
	m.mu.Unlock()
	broker.Close()
}
