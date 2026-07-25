package philobot

import (
	"context"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
)

// Erlaubte Entscheidungen des Nutzers auf eine Permission-Anfrage.
const (
	permissionOnce    = "once"    // nur diesen einen Zugriff erlauben
	permissionSession = "session" // Pfad/Ordner fuer den Rest des Tool-Loops freigeben
	permissionDeny    = "deny"    // ablehnen (auch Timeout/Abbruch)
)

// permissionAskTimeout begrenzt das Warten auf die Nutzer-Entscheidung, damit
// ein verlassener Stream nicht ewig blockiert. Danach gilt automatisch "deny".
const permissionAskTimeout = 3 * time.Minute

// permissionRequest beschreibt eine ausstehende Erlaubnis-Anfrage: welches Tool
// will auf welchen Pfad ausserhalb der freigegebenen Roots zugreifen.
type permissionRequest struct {
	ID   string
	Tool string
	Path string
}

// permissionAsker fragt den Nutzer um Erlaubnis. Als Interface, damit Tests
// einen Fake einsetzen koennen; produktiv ist der permissionBroker dahinter.
type permissionAsker interface {
	Ask(ctx context.Context, req permissionRequest) string
}

// permissionBroker vermittelt zwischen dem blockierend wartenden Tool-Loop und
// dem HTTP-Endpunkt, ueber den das Frontend die Entscheidung liefert. Ein
// Broker gehoert zu genau einem laufenden Stream (Session) und wird danach
// ueber Close() aufgeloest.
type permissionBroker struct {
	mu      sync.Mutex
	pending map[string]chan string
	closed  bool
}

func newPermissionBroker() *permissionBroker {
	return &permissionBroker{pending: map[string]chan string{}}
}

// Ask registriert die Anfrage und blockiert, bis das Frontend antwortet, der
// Kontext abbricht oder das Timeout zuschlaegt — in beiden Faellen gilt "deny".
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

// Respond loest eine wartende Anfrage aus. Liefert false, wenn die ID
// unbekannt ist oder die Entscheidung ungueltig.
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
	// Puffer 1: blockiert nie, auch wenn Ask schon per Timeout aufgegeben hat.
	select {
	case ch <- decision:
	default:
	}
	return true
}

// Close loest alle wartenden Anfragen mit "deny" auf und nimmt keine neuen
// mehr an. Wird aufgerufen, wenn der zugehoerige Stream endet.
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

// handlePermissionResponse nimmt die Nutzer-Entscheidung entgegen und reicht
// sie an den wartenden Tool-Loop weiter. Nutzt bewusst KEIN
// acquireSessionMutation: der wartende Stream haelt diesen Lock bereits, ein
// erneutes Erwerben wuerde deadlocken — die Broker-Map hat ihr eigenes Mutex.
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
