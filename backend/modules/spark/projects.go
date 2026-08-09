package spark

import (
	"encoding/json"
	"log"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/culpeohq/backend/modules/spark/tools"

	"github.com/google/uuid"
)

type Project struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Name      string    `json:"name"`
	Color     string    `json:"color,omitempty"`
	Path      string    `json:"path,omitempty"`
	Icon      string    `json:"icon,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

const (
	maxProjectNameRunes  = 80
	maxProjectColorRunes = 32
	maxProjectPathRunes  = 512
	maxProjectIconRunes  = 64
)

func normalizeProjectName(value string) string {
	name := strings.TrimSpace(value)
	if utf8.RuneCountInString(name) > maxProjectNameRunes {
		name = string([]rune(name)[:maxProjectNameRunes])
	}
	return name
}

func normalizeProjectColor(value string) string {
	color := strings.TrimSpace(value)
	if utf8.RuneCountInString(color) > maxProjectColorRunes {
		color = string([]rune(color)[:maxProjectColorRunes])
	}
	return color
}

func normalizeProjectPath(value string) string {
	path := strings.TrimSpace(value)
	if utf8.RuneCountInString(path) > maxProjectPathRunes {
		path = string([]rune(path)[:maxProjectPathRunes])
	}
	return path
}

func newChatProjectID() string {
	return "proj-" + uuid.New().String()
}

func normalizeProjectIcon(value string) string {
	icon := strings.ToLower(strings.TrimSpace(value))
	if utf8.RuneCountInString(icon) > maxProjectIconRunes {
		icon = string([]rune(icon)[:maxProjectIconRunes])
	}
	var b strings.Builder
	for _, r := range icon {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '_' {
			b.WriteRune(r)
		}
	}
	return b.String()
}

func (m *Module) loadPersistedProjects() {
	if m.projectStore == nil {
		return
	}
	projects, err := m.projectStore.LoadAll()
	if err != nil {
		log.Printf("[spark] Persistierte Projekte konnten nicht geladen werden: %v", err)
		return
	}
	if len(projects) == 0 {
		return
	}
	m.mu.Lock()
	for _, project := range projects {
		m.projects[project.ID] = project
	}
	m.mu.Unlock()
	log.Printf("[spark] %d gespeicherte Projektordner geladen", len(projects))
}

func (m *Module) persistProject(projectID string) {
	if m.projectStore == nil || !m.projectStore.enabled() {
		return
	}
	m.mu.Lock()
	project := m.projects[strings.TrimSpace(projectID)]
	if project == nil {
		m.mu.Unlock()
		return
	}
	payload, err := json.MarshalIndent(project, "", "  ")
	m.mu.Unlock()
	if err != nil {
		log.Printf("[spark] Projekt %s serialisieren fehlgeschlagen: %v", projectID, err)
		return
	}
	if err := m.projectStore.Write(projectID, payload); err != nil {
		log.Printf("[spark] Projekt %s speichern fehlgeschlagen: %v", projectID, err)
	}
}

// ensureProjectMemory opens the memory scope a project keeps its own knowledge
// in. A project without a scope still works; it just starts without recall.
func (m *Module) ensureProjectMemory(userID, projectID string) {
	if m.memory == nil {
		return
	}
	if err := m.memory.EnsureProjectScope(userID, projectID); err != nil {
		log.Printf("[spark] Projektgedaechtnis fuer %s konnte nicht angelegt werden: %v", projectID, err)
		return
	}
	log.Printf("[spark] Projektgedaechtnis fuer %s angelegt", projectID)
}

// ProjectPath returns the folder a project is bound to, empty when the project
// is unknown, owned by somebody else, or has no folder yet.
func (m *Module) ProjectPath(userID, projectID string) string {
	project := m.project(userID, projectID)
	if project == nil {
		return ""
	}
	return strings.TrimSpace(project.Path)
}

// HasProject reports whether the user owns a project with that id.
func (m *Module) HasProject(userID, projectID string) bool {
	return m.project(userID, projectID) != nil
}

func (m *Module) project(userID, projectID string) *Project {
	projectID = strings.TrimSpace(projectID)
	if projectID == "" {
		return nil
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	project := m.projects[projectID]
	if project == nil || project.UserID != userID {
		return nil
	}
	return project
}

// ProjectMemoryContext returns the recall block a project has built up, so the
// chat module can prepend it to the system prompt.
func (m *Module) ProjectMemoryContext(userID, projectID, query string) string {
	if m.memory == nil {
		return ""
	}
	return m.memory.ProjectMemoryContext(userID, strings.TrimSpace(projectID), query)
}

// DirTree renders the folder a session works in, for the file tree in the UI.
func DirTree(root string) (*tools.DirTreeEntry, bool) {
	tree, truncated := tools.BuildDirTree(root)
	return tree, truncated
}
