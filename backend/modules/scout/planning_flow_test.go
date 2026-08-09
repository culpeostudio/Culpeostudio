package scout

import (
	"path/filepath"
	"testing"

	"github.com/culpeohq/backend/internal/agentplan"
)

func newPlanTestModule(t *testing.T) (*ScoutModule, string) {
	t.Helper()
	settings := filepath.Join(t.TempDir(), "settings.json")
	module := newTestModule(t, settings)
	session := &scoutSession{ID: "chat-plan-1", UserID: "local"}
	module.mu.Lock()
	module.sessions[session.ID] = session
	module.mu.Unlock()
	return module, settings
}

func TestPendingPlanZyklus(t *testing.T) {
	module, _ := newPlanTestModule(t)
	plan := &agentplan.Plan{
		Goal:    "Ziel",
		Summary: "S",
		Steps:   []agentplan.Step{{Number: 1, Title: "Erst", Status: agentplan.StatusPending}},
	}

	module.StorePendingPlan("local", "chat-plan-1", plan)

	got := module.TakePendingPlan("local", "chat-plan-1")
	if got == nil || got.Goal != "Ziel" {
		t.Fatalf("Plan wurde nicht zurueckgeliefert: %+v", got)
	}

	if again := module.TakePendingPlan("local", "chat-plan-1"); again != nil {
		t.Error("zweiter Abruf sollte nichts mehr liefern")
	}
}

func TestPendingPlanFremderNutzer(t *testing.T) {
	module, _ := newPlanTestModule(t)
	module.StorePendingPlan("local", "chat-plan-1", &agentplan.Plan{Goal: "Ziel"})

	if got := module.TakePendingPlan("jemand-anders", "chat-plan-1"); got != nil {
		t.Error("fremder Nutzer darf den Plan nicht bekommen")
	}
	if got := module.TakePendingPlan("local", "unbekannte-session"); got != nil {
		t.Error("unbekannte Session darf keinen Plan liefern")
	}

	if got := module.TakePendingPlan("local", "chat-plan-1"); got == nil {
		t.Error("Besitzer sollte den Plan bekommen")
	}
}

func TestPendingPlanUeberlebtNeustart(t *testing.T) {
	module, settings := newPlanTestModule(t)
	module.StorePendingPlan("local", "chat-plan-1", &agentplan.Plan{
		Goal:    "Ziel",
		Summary: "S",
		Steps:   []agentplan.Step{{Number: 1, Title: "Erst", Status: agentplan.StatusPending}},
	})

	restarted := newTestModule(t, settings)
	restarted.loadPersistedSessions()
	got := restarted.TakePendingPlan("local", "chat-plan-1")
	if got == nil {
		t.Fatal("Plan wurde nicht persistiert")
	}
	if len(got.Steps) != 1 || got.Steps[0].Title != "Erst" {
		t.Fatalf("Plan kam unvollstaendig zurueck: %+v", got)
	}
}
