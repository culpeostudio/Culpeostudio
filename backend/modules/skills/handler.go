package skills

import (
	"errors"
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type SkillsModule struct {
	store *Store
}

func New(rootDir string) *SkillsModule {
	return &SkillsModule{store: NewStore(rootDir)}
}

func (m *SkillsModule) Name() string { return "skills" }

func (m *SkillsModule) RegisterRoutes(r fiber.Router) {
	g := r.Group("/skills")
	g.Get("", m.handleList)
	g.Get("/", m.handleList)
	g.Post("/import", m.handleImport)
	g.Post("/rescan", m.handleRescan)
	g.Patch("/:name", m.handleUpdate)
	g.Delete("/:name", m.handleDelete)
}

func (m *SkillsModule) Initialize() error {
	return m.store.Load()
}

func (m *SkillsModule) Shutdown() error { return nil }

func (m *SkillsModule) handleList(c *fiber.Ctx) error {
	skills := m.store.List()
	return c.JSON(fiber.Map{
		"skills": skills,
		"count":  len(skills),
	})
}

func (m *SkillsModule) handleImport(c *fiber.Ctx) error {
	var body struct {
		SourcePath string `json:"source_path"`
		Enabled    *bool  `json:"enabled"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	enabled := true
	if body.Enabled != nil {
		enabled = *body.Enabled
	}
	record, err := m.store.Import(body.SourcePath, enabled)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{
		"skill":   record,
		"message": "Skill eingebunden",
	})
}

func (m *SkillsModule) handleUpdate(c *fiber.Ctx) error {
	name := strings.TrimSpace(c.Params("name"))
	var body struct {
		Enabled *bool `json:"enabled"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	if body.Enabled == nil {
		return c.Status(400).JSON(fiber.Map{"error": "enabled ist erforderlich"})
	}
	record, err := m.store.SetEnabled(name, *body.Enabled)
	if errors.Is(err, os.ErrNotExist) {
		return c.Status(404).JSON(fiber.Map{"error": "Skill nicht gefunden"})
	}
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{
		"skill":   record,
		"message": "Skill aktualisiert",
	})
}

func (m *SkillsModule) handleDelete(c *fiber.Ctx) error {
	name := strings.TrimSpace(c.Params("name"))
	err := m.store.Delete(name)
	if errors.Is(err, os.ErrNotExist) {
		return c.Status(404).JSON(fiber.Map{"error": "Skill nicht gefunden"})
	}
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{
		"name":    name,
		"status":  "deleted",
		"message": "Skill entfernt",
	})
}

func (m *SkillsModule) handleRescan(c *fiber.Ctx) error {
	skills, err := m.store.Rescan()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{
		"skills":  skills,
		"count":   len(skills),
		"message": "Skills neu gescannt",
	})
}
