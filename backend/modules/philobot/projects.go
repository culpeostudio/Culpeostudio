package philobot

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type philoBotProject struct {
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

type projectStorage struct {
	base *sessionStorage
}

func newPhiloBotProjectStorage(baseDir string) *projectStorage {
	return &projectStorage{base: newPhiloBotStorage(baseDir)}
}

func (s *projectStorage) enabled() bool { return s != nil && s.base.enabled() }

func (s *projectStorage) LoadAll() ([]*philoBotProject, error) {
	if !s.enabled() {
		return nil, nil
	}
	if err := s.base.Initialize(); err != nil {
		return nil, err
	}
	matches, err := filepath.Glob(filepath.Join(s.base.baseDir, "*.json"))
	if err != nil {
		return nil, fmt.Errorf("glob philobot projects: %w", err)
	}
	projects := make([]*philoBotProject, 0, len(matches))
	for _, match := range matches {
		content, readErr := os.ReadFile(match)
		if readErr != nil {
			log.Printf("[philobot] Projekt-Datei %s nicht lesbar: %v", match, readErr)
			continue
		}
		var project philoBotProject
		if err := json.Unmarshal(content, &project); err != nil {
			log.Printf("[philobot] Projekt-Datei %s nicht dekodierbar: %v", match, err)
			continue
		}
		if strings.TrimSpace(project.ID) == "" {
			continue
		}
		projects = append(projects, &project)
	}
	return projects, nil
}

func (s *projectStorage) Delete(id string) error {
	return s.base.Delete(id)
}

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

func (m *PhiloBotModule) loadPersistedProjects() {
	if m.projectStorage == nil {
		return
	}
	projects, err := m.projectStorage.LoadAll()
	if err != nil {
		log.Printf("[philobot] Persistierte Projekte konnten nicht geladen werden: %v", err)
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
	log.Printf("[philobot] %d gespeicherte Projektordner geladen", len(projects))
}

func (m *PhiloBotModule) persistProject(projectID string) {
	if m.projectStorage == nil || !m.projectStorage.enabled() {
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
		log.Printf("[philobot] Projekt %s serialisieren fehlgeschlagen: %v", projectID, err)
		return
	}
	if err := m.projectStorage.base.writeRaw(projectID, payload); err != nil {
		log.Printf("[philobot] Projekt %s speichern fehlgeschlagen: %v", projectID, err)
	}
}

func (m *PhiloBotModule) handleListProjects(c *fiber.Ctx) error {
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	projects := make([]*philoBotProject, 0, len(m.projects))
	for _, project := range m.projects {
		if project == nil || project.UserID != userID {
			continue
		}
		projects = append(projects, project)
	}
	m.mu.Unlock()
	sort.Slice(projects, func(i, j int) bool {
		return projects[i].CreatedAt.After(projects[j].CreatedAt)
	})
	return c.JSON(fiber.Map{"projects": projects})
}

func (m *PhiloBotModule) handleCreateProject(c *fiber.Ctx) error {
	var body struct {
		Name  string `json:"name"`
		Color string `json:"color"`
		Path  string `json:"path"`
		Icon  string `json:"icon"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	name := normalizeProjectName(body.Name)
	if name == "" {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Projektname darf nicht leer sein", "code": "project_name_required"})
	}
	userID := philoBotRequestUserID(c)
	now := time.Now().UTC()
	project := &philoBotProject{
		ID:        newChatProjectID(),
		UserID:    userID,
		Name:      name,
		Color:     normalizeProjectColor(body.Color),
		Path:      normalizeProjectPath(body.Path),
		Icon:      normalizeProjectIcon(body.Icon),
		CreatedAt: now,
		UpdatedAt: now,
	}
	m.mu.Lock()
	m.projects[project.ID] = project
	m.mu.Unlock()
	m.persistProject(project.ID)
	return c.JSON(fiber.Map{"status": "created", "project": project})
}

func (m *PhiloBotModule) handleRenameProject(c *fiber.Ctx) error {
	var body struct {
		Name  string  `json:"name"`
		Color string  `json:"color"`
		Path  string  `json:"path"`
		Icon  *string `json:"icon"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	name := normalizeProjectName(body.Name)
	if name == "" {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Projektname darf nicht leer sein", "code": "project_name_required"})
	}
	projectID := strings.TrimSpace(c.Params("id"))
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	project := m.projects[projectID]
	if project == nil || project.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Projekt wurde nicht gefunden", "code": "project_not_found"})
	}
	project.Name = name
	if color := normalizeProjectColor(body.Color); color != "" {
		project.Color = color
	}

	project.Path = normalizeProjectPath(body.Path)

	if body.Icon != nil {
		project.Icon = normalizeProjectIcon(*body.Icon)
	}
	project.UpdatedAt = time.Now().UTC()
	m.mu.Unlock()
	m.persistProject(projectID)
	return c.JSON(fiber.Map{"status": "ok", "project": project})
}

func (m *PhiloBotModule) handleDeleteProject(c *fiber.Ctx) error {
	projectID := strings.TrimSpace(c.Params("id"))
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	project := m.projects[projectID]
	if project == nil || project.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Projekt wurde nicht gefunden", "code": "project_not_found"})
	}
	delete(m.projects, projectID)
	affected := make([]string, 0)
	for _, session := range m.sessions {
		if session != nil && session.UserID == userID && session.ProjectID == projectID {
			session.ProjectID = ""
			affected = append(affected, session.ID)
		}
	}
	m.mu.Unlock()
	for _, sessionID := range affected {
		m.persistSession(sessionID)
	}
	if err := m.projectStorage.Delete(projectID); err != nil {
		log.Printf("[philobot] Projekt %s loeschen fehlgeschlagen: %v", projectID, err)
	}
	return c.JSON(fiber.Map{"status": "deleted"})
}

func (m *PhiloBotModule) handleSessionTree(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Params("session_id"))
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Session wurde nicht gefunden", "code": "session_not_found"})
	}
	root := m.projectPathForSessionLocked(userID, session)
	m.mu.Unlock()
	if root == "" {
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Session hat kein Projekt mit Projektpfad", "code": "no_project_path"})
	}
	info, err := os.Stat(root)
	if err != nil || !info.IsDir() {
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Projektpfad existiert nicht", "code": "project_path_missing"})
	}
	tree, truncated := buildDirTree(root)
	return c.JSON(fiber.Map{"root": root, "tree": tree, "truncated": truncated})
}

func (m *PhiloBotModule) handleSetSessionProject(c *fiber.Ctx) error {
	var body struct {
		ProjectID string `json:"project_id"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	sessionID := strings.TrimSpace(c.Params("session_id"))
	projectID := strings.TrimSpace(body.ProjectID)
	userID := philoBotRequestUserID(c)
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Session wurde nicht gefunden", "code": "session_not_found"})
	}
	if projectID != "" {
		project := m.projects[projectID]
		if project == nil || project.UserID != userID {
			m.mu.Unlock()
			return c.Status(http.StatusNotFound).JSON(fiber.Map{"error": "Projekt wurde nicht gefunden", "code": "project_not_found"})
		}
	}
	session.ProjectID = projectID
	summary := summarizeSession(session)
	m.mu.Unlock()
	m.persistSession(sessionID)
	return c.JSON(fiber.Map{"status": "ok", "session": summary})
}
