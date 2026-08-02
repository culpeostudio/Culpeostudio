package philobot

import (
	"context"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
)

const (
	permissionOnce    = "once"
	permissionSession = "session"
	permissionDeny    = "deny"
)

const permissionAskTimeout = 3 * time.Minute

type permissionRequest struct {
	ID   string
	Tool string
	Path string
}

type permissionAsker interface {
	Ask(ctx context.Context, req permissionRequest) string
}

type permissionBroker struct {
	mu      sync.Mutex
	pending map[string]chan string
	closed  bool
}

func newPermissionBroker() *permissionBroker {
	return &permissionBroker{pending: map[string]chan string{}}
}

func (b *permissionBroker) Ask(ctx context.Context, req permissionRequest) string {
	ch := make(chan string, 1)
	b.mu.Lock()
	if b.closed {
		b.mu.Unlock()
		return permissionDeny
	}
	b.pending[req.ID] = ch
	b.mu.Unlock()

	defer func() {
		b.mu.Lock()
		delete(b.pending, req.ID)
		b.mu.Unlock()
	}()

	if ctx == nil {
		ctx = context.Background()
	}
	select {
	case decision := <-ch:
		return decision
	case <-ctx.Done():
		return permissionDeny
	case <-time.After(permissionAskTimeout):
		return permissionDeny
	}
}

func (b *permissionBroker) Respond(requestID, decision string) bool {
	switch decision {
	case permissionOnce, permissionSession, permissionDeny:
	default:
		return false
	}
	b.mu.Lock()
	ch, ok := b.pending[requestID]
	b.mu.Unlock()
	if !ok {
		return false
	}

	select {
	case ch <- decision:
	default:
	}
	return true
}

func (b *permissionBroker) Close() {
	b.mu.Lock()
	if b.closed {
		b.mu.Unlock()
		return
	}
	b.closed = true
	pending := b.pending
	b.pending = map[string]chan string{}
	b.mu.Unlock()
	for _, ch := range pending {
		select {
		case ch <- permissionDeny:
		default:
		}
	}
}

func (m *PhiloBotModule) handlePermissionResponse(c *fiber.Ctx) error {
	var body struct {
		SessionID string `json:"session_id"`
		RequestID string `json:"request_id"`
		Decision  string `json:"decision"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	m.mu.Lock()
	broker := m.permissionBrokers[strings.TrimSpace(body.SessionID)]
	m.mu.Unlock()
	if broker == nil || !broker.Respond(strings.TrimSpace(body.RequestID), strings.TrimSpace(body.Decision)) {
		return c.Status(http.StatusNotFound).JSON(fiber.Map{
			"ok":    false,
			"error": "Permission-Anfrage unbekannt oder bereits beantwortet",
			"code":  "permission_request_not_found",
		})
	}
	return c.JSON(fiber.Map{"ok": true})
}
