// Package philosearch exposes the metasearch and page extraction over HTTP.
package philosearch

import (
	"context"
	"encoding/base64"
	"errors"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/metasearch"
)

func (m *Module) handleExtract(c *fiber.Ctx) error {
	if m.client == nil {
		return c.Status(503).JSON(fiber.Map{"error": "philosearch: client nicht initialisiert"})
	}
	target := strings.TrimSpace(c.Query("url"))
	format := strings.TrimSpace(c.Query("format", "text_markdown"))
	if target == "" {
		var body extractRequest
		if err := c.BodyParser(&body); err == nil {
			target = strings.TrimSpace(body.URL)
			if body.Format != "" {
				format = body.Format
			}
		}
	}
	if target == "" {
		return c.Status(400).JSON(fiber.Map{"error": "url is required"})
	}
	if format == "" {
		format = "text_markdown"
	}

	ctx, cancel := context.WithTimeout(c.Context(), 20*time.Second)
	defer cancel()

	resp, err := m.client.GetGuarded(ctx, target, nil)
	if err != nil {
		if errors.Is(err, metasearch.ErrBlockedURL) {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(502).JSON(fiber.Map{"error": err.Error()})
	}

	if resp.StatusCode != 200 {
		return c.Status(502).JSON(fiber.Map{
			"error":  "fetch failed",
			"status": resp.StatusCode,
		})
	}

	switch format {
	case "text":
		return c.JSON(fiber.Map{"url": target, "content": resp.Text, "format": format})
	case "content":
		return c.JSON(fiber.Map{
			"url":         target,
			"content_b64": base64.StdEncoding.EncodeToString(resp.Content),
			"format":      "content",
		})
	case "text_plain":
		return c.JSON(fiber.Map{"url": target, "content": metasearch.NormalizeText(resp.Text), "format": format})
	case "text_rich", "text_markdown":
		return c.JSON(fiber.Map{"url": target, "content": metasearch.HTMLToMarkdown(resp.Text), "format": format})
	default:
		return c.Status(400).JSON(fiber.Map{"error": "unsupported format: " + format})
	}
}

func contextWithTimeout(c *fiber.Ctx, d time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(c.Context(), d)
}
