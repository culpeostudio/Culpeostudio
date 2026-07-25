package philobot

import (
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
)

func (m *PhiloBotModule) handleGetBots(c *fiber.Ctx) error {
	userID := philoBotRequestUserID(c)
	if err := m.botStore.EnsureUser(userID); err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{
		"bots": m.botStore.GetBotsForUser(userID),
	})
}

func (m *PhiloBotModule) handleSaveBot(c *fiber.Ctx) error {
	var bot BotConfig
	if err := c.BodyParser(&bot); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	if strings.TrimSpace(bot.ID) == "" {
		bot.ID = fmt.Sprintf("bot-%d", time.Now().UnixNano())
	}
	if strings.TrimSpace(bot.Name) == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Name ist erforderlich"})
	}
	userID := philoBotRequestUserID(c)
	if err := m.botStore.EnsureUser(userID); err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if err := m.botStore.SaveBotForUser(userID, bot); err != nil {
		if errors.Is(err, errBotBuilderLocked) {
			return c.Status(403).JSON(fiber.Map{"error": err.Error()})
		}
		if errors.Is(err, errInvalidModelBinding) {
			return c.Status(http.StatusUnprocessableEntity).JSON(fiber.Map{"error": err.Error(), "code": "model_binding_invalid"})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	saved, _ := m.botStore.GetBotForUser(userID, bot.ID)
	return c.JSON(fiber.Map{"status": "ok", "bot": saved})
}

func (m *PhiloBotModule) handleDeleteBot(c *fiber.Ctx) error {
	id := c.Params("id")
	if id == "philobot" || id == "botbuilder" {
		return c.Status(400).JSON(fiber.Map{"error": "Standard-Bot kann nicht geloescht werden"})
	}
	userID := philoBotRequestUserID(c)
	if err := m.botStore.EnsureUser(userID); err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if err := m.botStore.DeleteBotForUser(userID, id); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": "ok"})
}
