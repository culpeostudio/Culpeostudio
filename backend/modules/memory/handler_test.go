package memorymodule

import (
	"encoding/json"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/memory"
	"github.com/fillyengine/backend/internal/memoryembed"
)

func TestEventTickets(t *testing.T) {
	embedCfg := memoryembed.Config{
		Backend: "hash",
	}
	policy := memory.DefaultCompressionPolicy()
	m := New(
		t.TempDir()+"/memory.db",
		t.TempDir()+"/vector.json",
		embedCfg,
		"myphiloengine",
		"dev-memory-token",
		"local",
		1000,
		policy,
		120,
		6,
		2,
		"Test Memory",
		MaintenanceConfig{},
		"",
		"",
	)

	if err := m.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	defer m.Shutdown()

	app := fiber.New()
	m.RegisterRoutes(app)

	req1 := httptest.NewRequest("POST", "/memory/events/ticket", nil)
	req1.Header.Set("Authorization", "Bearer dev-memory-token")
	resp1, err := app.Test(req1)
	if err != nil {
		t.Fatalf("failed to create ticket request: %v", err)
	}
	if resp1.StatusCode != fiber.StatusOK {
		t.Fatalf("expected create ticket status 200, got %d", resp1.StatusCode)
	}

	var body struct {
		Ticket string `json:"ticket"`
	}
	if err := json.NewDecoder(resp1.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if body.Ticket == "" {
		t.Fatalf("expected non-empty ticket")
	}

	m.ticketsMu.Lock()
	info, exists := m.tickets[body.Ticket]
	m.ticketsMu.Unlock()

	if !exists {
		t.Fatalf("expected ticket %s to exist in tickets map, but it didn't", body.Ticket)
	}
	if info.userID != "local" {
		t.Errorf("expected ticket user to be 'local', got %s", info.userID)
	}

	req1b := httptest.NewRequest("POST", "/memory/events/ticket", nil)
	req1b.Header.Set("Authorization", "Bearer dev-memory-token")
	req1b.Header.Set("X-Memory-User-ID", "alice")
	resp1b, err := app.Test(req1b)
	if err != nil {
		t.Fatalf("failed to create user-scoped ticket request: %v", err)
	}
	if resp1b.StatusCode != fiber.StatusOK {
		t.Fatalf("expected user-scoped create ticket status 200, got %d", resp1b.StatusCode)
	}
	var body2 struct {
		Ticket string `json:"ticket"`
	}
	if err := json.NewDecoder(resp1b.Body).Decode(&body2); err != nil {
		t.Fatalf("failed to decode user-scoped response: %v", err)
	}
	m.ticketsMu.Lock()
	info2, exists := m.tickets[body2.Ticket]
	m.ticketsMu.Unlock()
	if !exists {
		t.Fatalf("expected user-scoped ticket %s to exist, but it didn't", body2.Ticket)
	}
	if info2.userID != "alice" {
		t.Errorf("expected ticket user to be 'alice', got %s", info2.userID)
	}

	req2 := httptest.NewRequest("GET", "/memory/events?ticket=invalid-ticket", nil)
	resp2, err := app.Test(req2)
	if err != nil {
		t.Fatalf("failed to run GET events request: %v", err)
	}
	if resp2.StatusCode != fiber.StatusUnauthorized {
		t.Errorf("expected unauthorized for invalid ticket, got %d", resp2.StatusCode)
	}
}
