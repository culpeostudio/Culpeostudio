// The memory viewer is a page the backend serves to a browser, and a browser
// speaks neither gRPC nor HTTP/2 trailers. What is left in this file is
// therefore what the page itself needs and nothing else: the page, the
// read-only queries it makes, and the event feed it follows. Everything a
// program calls moved to MemoryService in grpc.go.
//
// The health route stays here too, because a liveness probe is reached by
// whatever an operator has at hand, and that is curl.

package memorymodule

import (
	"bufio"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memoryviewer"
	"github.com/culpeohq/backend/internal/security"
)

type ticketInfo struct {
	userID    string
	expiresAt time.Time
}

func (m *MemoryModule) authMiddleware() fiber.Handler {
	bearer := security.BearerAuth(m.apiToken, m.defaultUserID)
	return func(c *fiber.Ctx) error {
		if userID, ok := c.Locals("user_id").(string); ok && strings.TrimSpace(userID) != "" {
			c.Locals(security.UserIDLocalKey, security.SanitizeUserID(userID))
			return c.Next()
		}
		return bearer(c)
	}
}

func (m *MemoryModule) RegisterRoutes(router fiber.Router) {
	group := router.Group("/memory")
	group.Use(m.authMiddleware())
	group.Get("/health", m.handleHealth)
	group.Get("/sessions", m.handleListSessions)
	group.Get("/search", m.handleSearch)
	group.Get("/timeline", m.handleTimeline)
	group.Get("/context/:session_id", m.handleContext)
	group.Post("/events/ticket", m.handleCreateEventTicket)
}

func (m *MemoryModule) RegisterAppRoutes(router fiber.Router) {
	router.Get("/memory/view", func(c *fiber.Ctx) error {
		c.Type("html", "utf-8")
		return c.SendString(memoryviewer.Page(m.viewerTitle))
	})
	router.Get("/memory/events", m.handleEvents)
}

func (m *MemoryModule) handleHealth(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status": "ok",
		"module": m.Name(),
	})
}

func (m *MemoryModule) handleListSessions(c *fiber.Ctx) error {
	sessions, err := m.service.ListSessionsForUser(requestUserID(c))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(sessions)
}

func (m *MemoryModule) handleSearch(c *fiber.Ctx) error {
	results, err := m.service.Search(c.Query("q"), memory.SearchFilters{
		UserID:   requestUserID(c),
		Project:  c.Query("project"),
		Source:   c.Query("source"),
		Layer:    memory.MemoryLayer(c.Query("layer")),
		Category: memory.MemoryCategory(c.Query("category")),
		Type:     c.Query("type"),
		Limit:    parseInt(c.Query("limit"), 10),
	})
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(results)
}

func (m *MemoryModule) handleTimeline(c *fiber.Ctx) error {
	sessionID := strings.TrimSpace(c.Query("session_id"))
	if sessionID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "session_id ist erforderlich"})
	}
	observations, err := m.service.TimelineForUser(requestUserID(c), sessionID, memory.TimelineQuery{
		ObservationID: c.Query("observation_id"),
		Query:         c.Query("q"),
		Before:        parseInt(c.Query("before"), 2),
		After:         parseInt(c.Query("after"), 2),
	})
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(observations)
}

func (m *MemoryModule) handleContext(c *fiber.Ctx) error {
	context, err := m.service.BuildContextForUser(requestUserID(c), c.Params("session_id"), c.Query("q"), parseInt(c.Query("limit"), 8))
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(context)
}

// handleCreateEventTicket hands out a single-use ticket for the event feed.
// EventSource cannot send an Authorization header, so the page authenticates
// here, where it can, and spends the ticket on the connection it opens.
func (m *MemoryModule) handleCreateEventTicket(c *fiber.Ctx) error {
	userID := requestUserID(c)
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to generate ticket"})
	}
	ticket := hex.EncodeToString(bytes)

	m.ticketsMu.Lock()
	now := time.Now()
	for t, info := range m.tickets {
		if now.After(info.expiresAt) {
			delete(m.tickets, t)
		}
	}
	m.tickets[ticket] = ticketInfo{
		userID:    userID,
		expiresAt: now.Add(30 * time.Second),
	}
	m.ticketsMu.Unlock()

	return c.JSON(fiber.Map{"ticket": ticket})
}

func (m *MemoryModule) handleEvents(c *fiber.Ctx) error {

	ticket := strings.TrimSpace(c.Query("ticket"))
	if ticket == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "event ticket required"})
	}

	m.ticketsMu.Lock()
	info, ok := m.tickets[ticket]
	if ok {
		delete(m.tickets, ticket)
	}
	m.ticketsMu.Unlock()

	if !ok || time.Now().After(info.expiresAt) {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid or expired ticket"})
	}
	userID := info.userID

	subscriber := m.hub.Subscribe(64)
	c.Set("Content-Type", "text/event-stream")
	c.Set("Cache-Control", "no-cache")
	c.Set("Connection", "keep-alive")
	c.Set("X-Accel-Buffering", "no")
	c.Context().SetBodyStreamWriter(func(writer *bufio.Writer) {
		defer m.hub.Unsubscribe(subscriber)
		for {
			select {
			case <-c.Context().Done():
				return
			case event, ok := <-subscriber:
				if !ok {
					return
				}
				if eventUserID(event) != userID {
					continue
				}
				payload, err := json.Marshal(event)
				if err != nil {
					continue
				}
				if _, err := writer.WriteString(fmt.Sprintf("event: %s\ndata: %s\n\n", event.Type, payload)); err != nil {
					return
				}
				if err := writer.Flush(); err != nil {
					return
				}
			}
		}
	})
	return nil
}

func respondError(c *fiber.Ctx, err error) error {
	if errors.Is(err, os.ErrNotExist) {
		return c.Status(404).JSON(fiber.Map{"error": "ressource nicht gefunden"})
	}
	return c.Status(400).JSON(fiber.Map{"error": err.Error()})
}

func parseInt(raw string, fallback int) int {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return fallback
	}
	if value, err := strconv.Atoi(raw); err == nil && value > 0 {
		return value
	}
	return fallback
}

func requestUserID(c *fiber.Ctx) string {
	if value, ok := c.Locals(security.UserIDLocalKey).(string); ok && strings.TrimSpace(value) != "" {
		return strings.TrimSpace(value)
	}
	return "local"
}
