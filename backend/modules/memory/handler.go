package memorymodule

import (
	"bufio"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/memory"
	"github.com/fillyengine/backend/internal/memorycapture"
	"github.com/fillyengine/backend/internal/memoryembed"
	"github.com/fillyengine/backend/internal/memorystore"
	"github.com/fillyengine/backend/internal/memorytoken"
	"github.com/fillyengine/backend/internal/memoryvector"
	"github.com/fillyengine/backend/internal/memoryviewer"
	"github.com/fillyengine/backend/internal/security"
)

type ticketInfo struct {
	userID    string
	expiresAt time.Time
}

// MaintenanceConfig bundles the tunables for the background reindexer and
// the SQLite hygiene job (VACUUM / FTS5 optimize / soft-delete purge)
// started in Initialize. Zero values fall back to the defaults documented on
// memoryvector.RunReindexer and memorystore.RunMaintenance.
type MaintenanceConfig struct {
	ReindexInterval     time.Duration
	ReindexBatchSize    int
	ReindexConcurrency  int
	SoftDeleteRetention time.Duration
}

type MemoryModule struct {
	store            *memorystore.SQLiteStore
	vector           *memoryvector.Index
	hub              *memoryviewer.Hub
	service          *memory.Service
	capture          *memorycapture.Service
	apiToken         string
	defaultUserID    string
	captureRateLimit int
	captureLimiter   *security.RateLimiter
	chatWindowSize   int
	chatOverlapSize  int
	viewerTitle      string
	maintenance      MaintenanceConfig

	stopReindex     chan struct{}
	stopMaintenance chan struct{}

	ticketsMu sync.Mutex
	tickets   map[string]ticketInfo
}

func New(sqlitePath, vectorPath string, embedCfg memoryembed.Config, projectTag, apiToken, defaultUserID string, contextBudget int, policy memory.CompressionPolicy, captureRateLimit int, chatWindowSize int, chatOverlapSize int, viewerTitle string, maintenance MaintenanceConfig, tokenizerFamily, tokenizerModelPath string) *MemoryModule {
	store := memorystore.NewSQLiteStore(sqlitePath)
	activeBackend, hashBackend := memoryembed.Select(embedCfg)
	vector := memoryvector.New(store, activeBackend, hashBackend, vectorPath)
	hub := memoryviewer.NewHub()

	options := memory.Options{
		ProjectTag:          projectTag,
		DefaultUserID:       defaultUserID,
		ContextBudgetTokens: contextBudget,
		Policy:              policy,
		TokenizerFamily:     memorytoken.Family(tokenizerFamily),
		TokenizerModelPath:  tokenizerModelPath,
	}
	service := memory.NewService(store, vector, hub, options)
	capture := memorycapture.New(service, chatWindowSize, chatOverlapSize)
	service.RegisterCleanupHandler(func(sessionID string) {
		capture.ClearSession(sessionID)
	})
	captureLimiter := security.NewRateLimiter(captureRateLimit, time.Minute)
	return &MemoryModule{
		store:            store,
		vector:           vector,
		hub:              hub,
		service:          service,
		capture:          capture,
		apiToken:         apiToken,
		defaultUserID:    defaultUserID,
		captureRateLimit: captureRateLimit,
		captureLimiter:   captureLimiter,
		chatWindowSize:   chatWindowSize,
		chatOverlapSize:  chatOverlapSize,
		viewerTitle:      viewerTitle,
		maintenance:      maintenance,
		tickets:          make(map[string]ticketInfo),
	}
}

func (m *MemoryModule) Name() string { return "memory" }

func (m *MemoryModule) Initialize() error {
	if err := m.service.Initialize(); err != nil {
		return err
	}

	m.stopReindex = make(chan struct{})
	go m.vector.RunReindexer(m.stopReindex, m.maintenance.ReindexInterval, m.maintenance.ReindexBatchSize, m.maintenance.ReindexConcurrency)

	m.stopMaintenance = make(chan struct{})
	go m.store.RunMaintenance(m.stopMaintenance, memorystore.MaintenanceConfig{
		SoftDeleteRetention: m.maintenance.SoftDeleteRetention,
	})
	return nil
}

func (m *MemoryModule) Shutdown() error {
	if m.stopReindex != nil {
		close(m.stopReindex)
	}
	if m.stopMaintenance != nil {
		close(m.stopMaintenance)
	}
	if m.captureLimiter != nil {
		m.captureLimiter.Close()
	}
	if m.hub != nil {
		m.hub.Close()
	}
	return m.service.Close()
}

// authMiddleware bevorzugt die Identitaet aus der globalen JWT-Auth der Engine
// (Locals "user_id"). Ohne JWT-Kontext (Standalone, Tests, Skripte) greift der
// Bearer-Token-Fallback des Memory-Moduls.
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
	group.Post("/session", m.handleCreateSession)
	group.Get("/sessions", m.handleListSessions)
	group.Get("/session/:session_id", m.handleGetSession)
	group.Delete("/session/:session_id", m.handleDeleteSession)
	group.Post("/session/:session_id/prompt", m.handleAddPrompt)
	group.Post("/session/:session_id/observations", m.handleAddObservation)
	group.Post("/session/:session_id/complete", m.handleCompleteSession)
	group.Get("/search", m.handleSearch)
	group.Get("/timeline", m.handleTimeline)
	group.Post("/get_observations", m.handleGetObservations)
	group.Get("/context/:session_id", m.handleContext)
	group.Post("/change_request/:observation_id/status", m.handleUpdateChangeRequest)
	group.Delete("/observation/:id", m.handleDeleteObservation)
	group.Patch("/memory/:id", m.handleUpdateMemory)
	group.Post("/events/ticket", m.handleCreateEventTicket)

	captureGroup := group.Group("/capture")
	if m.captureLimiter != nil {
		captureGroup.Use(m.captureLimiter.Middleware())
	}
	captureGroup.Post("/philox/session_start", m.handleCapturePhiloxSessionStart)
	captureGroup.Post("/philox/prompt", m.handleCapturePhiloxPrompt)
	captureGroup.Post("/philox/tool", m.handleCapturePhiloxTool)
	captureGroup.Post("/philox/assistant", m.handleCapturePhiloxAssistant)
	captureGroup.Post("/chat/message", m.handleCaptureChatMessage)
	captureGroup.Post("/event", m.handleCaptureEvent)
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

func (m *MemoryModule) handleCreateSession(c *fiber.Ctx) error {
	var body memory.CreateSessionInput
	if len(c.Body()) > 0 {
		if err := c.BodyParser(&body); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
		}
	}
	body.UserID = requestUserID(c)
	session, err := m.service.CreateSession(body)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(201).JSON(session)
}

func (m *MemoryModule) handleListSessions(c *fiber.Ctx) error {
	sessions, err := m.service.ListSessionsForUser(requestUserID(c))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(sessions)
}

func (m *MemoryModule) handleGetSession(c *fiber.Ctx) error {
	session, err := m.service.GetSessionForUser(requestUserID(c), c.Params("session_id"))
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(session)
}

func (m *MemoryModule) handleDeleteSession(c *fiber.Ctx) error {
	if err := m.service.DeleteSessionForUser(requestUserID(c), c.Params("session_id")); err != nil {
		return respondError(c, err)
	}
	return c.JSON(fiber.Map{"status": "deleted"})
}

func (m *MemoryModule) handleAddPrompt(c *fiber.Ctx) error {
	var body memory.AddPromptInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	prompt, context, err := m.service.AddPrompt(c.Params("session_id"), body)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(fiber.Map{
		"prompt":  prompt,
		"context": context,
	})
}

func (m *MemoryModule) handleAddObservation(c *fiber.Ctx) error {
	var body memory.AddObservationInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	observation, err := m.service.AddObservation(c.Params("session_id"), body)
	if err != nil {
		return respondError(c, err)
	}
	return c.Status(201).JSON(observation)
}

func (m *MemoryModule) handleCompleteSession(c *fiber.Ctx) error {
	var body memory.CompleteSessionInput
	if len(c.Body()) > 0 {
		if err := c.BodyParser(&body); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
		}
	}
	body.UserID = requestUserID(c)
	summary, err := m.service.CompleteSession(c.Params("session_id"), body)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(summary)
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

func (m *MemoryModule) handleGetObservations(c *fiber.Ctx) error {
	var body memory.GetObservationsInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	observations, err := m.service.GetObservationsForUser(body.UserID, body.IDs)
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

func (m *MemoryModule) handleCapturePhiloxSessionStart(c *fiber.Ctx) error {
	var body memorycapture.PhiloxSessionStartInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	session, err := m.capture.CapturePhiloxSessionStart(body)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(session)
}

func (m *MemoryModule) handleCapturePhiloxPrompt(c *fiber.Ctx) error {
	var body memorycapture.PhiloxPromptInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	context, err := m.capture.CapturePhiloxPrompt(body)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(context)
}

func (m *MemoryModule) handleCapturePhiloxTool(c *fiber.Ctx) error {
	var body memorycapture.PhiloxToolInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	observation, err := m.capture.CapturePhiloxTool(body)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(observation)
}

func (m *MemoryModule) handleCapturePhiloxAssistant(c *fiber.Ctx) error {
	var body memorycapture.AssistantReplyInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	observation, err := m.capture.CaptureAssistantReply(body, "philox")
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(observation)
}

func (m *MemoryModule) handleCaptureChatMessage(c *fiber.Ctx) error {
	var body struct {
		UserID    string `json:"user_id"`
		SessionID string `json:"session_id"`
		Project   string `json:"project"`
		Prompt    string `json:"prompt"`
		Reply     string `json:"reply"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	context, err := m.capture.CaptureChatMessage(body.UserID, body.SessionID, body.Project, body.Prompt, body.Reply)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(context)
}

func (m *MemoryModule) handleCaptureEvent(c *fiber.Ctx) error {
	var body memorycapture.EventBusInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	observation, err := m.capture.CaptureEventBus(body)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(observation)
}

func (m *MemoryModule) handleUpdateChangeRequest(c *fiber.Ctx) error {
	var body memory.UpdateChangeRequestInput
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	body.UserID = requestUserID(c)
	observation, err := m.service.UpdateChangeRequestStatus(body.UserID, c.Params("observation_id"), body)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(observation)
}

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
	// SSE auth runs exclusively over single-use tickets from
	// POST /api/memory/events/ticket. Bearer tokens are never accepted as URL
	// parameters: URLs end up in access logs, browser history and referers.
	ticket := strings.TrimSpace(c.Query("ticket"))
	if ticket == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "event ticket required"})
	}

	m.ticketsMu.Lock()
	info, ok := m.tickets[ticket]
	if ok {
		delete(m.tickets, ticket) // single-use consume
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

func eventUserID(event memoryviewer.Event) string {
	if event.Data == nil {
		return ""
	}
	switch d := event.Data.(type) {
	case *memory.Session:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.Session:
		return security.SanitizeUserID(d.UserID)
	case *memory.Prompt:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.Prompt:
		return security.SanitizeUserID(d.UserID)
	case *memory.Observation:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.Observation:
		return security.SanitizeUserID(d.UserID)
	case *memory.CompressedMemory:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.CompressedMemory:
		return security.SanitizeUserID(d.UserID)
	case *memory.SessionSummary:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.SessionSummary:
		return security.SanitizeUserID(d.UserID)
	case map[string]string:
		if val, ok := d["user_id"]; ok {
			return security.SanitizeUserID(val)
		}
	case map[string]interface{}:
		if val, ok := d["user_id"]; ok {
			if str, ok := val.(string); ok {
				return security.SanitizeUserID(str)
			}
		}
	default:
		val := reflect.ValueOf(event.Data)
		if val.Kind() == reflect.Ptr {
			val = val.Elem()
		}
		if val.Kind() == reflect.Struct {
			field := val.FieldByName("UserID")
			if field.IsValid() && field.Kind() == reflect.String {
				return security.SanitizeUserID(field.String())
			}
		}
	}
	return ""
}

func (m *MemoryModule) handleDeleteObservation(c *fiber.Ctx) error {
	obs, tombstoned, err := m.service.DeleteObservationForUser(requestUserID(c), c.Params("id"))
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(fiber.Map{
		"status":      "deleted",
		"tombstoned":  tombstoned,
		"observation": obs,
	})
}

func (m *MemoryModule) handleUpdateMemory(c *fiber.Ctx) error {
	var patch memory.MemoryPatch
	if err := c.BodyParser(&patch); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}
	mem, err := m.service.UpdateMemoryForUser(requestUserID(c), c.Params("id"), patch)
	if err != nil {
		return respondError(c, err)
	}
	return c.JSON(mem)
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
