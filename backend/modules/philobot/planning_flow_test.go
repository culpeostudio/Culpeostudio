package philobot

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/fillyengine/backend/internal/agentplan"
)

func newPlanTestModule(t *testing.T) (*PhiloBotModule, string) {
	t.Helper()
	settings := filepath.Join(t.TempDir(), "settings.json")
	module := New(settings)
	session := &philoBotSession{ID: "chat-plan-1", UserID: "local"}
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

	module.storePendingPlan("local", "chat-plan-1", plan)

	got := module.takePendingPlan("local", "chat-plan-1")
	if got == nil || got.Goal != "Ziel" {
		t.Fatalf("Plan wurde nicht zurueckgeliefert: %+v", got)
	}

	if again := module.takePendingPlan("local", "chat-plan-1"); again != nil {
		t.Error("zweiter Abruf sollte nichts mehr liefern")
	}
}

func TestPendingPlanFremderNutzer(t *testing.T) {
	module, _ := newPlanTestModule(t)
	module.storePendingPlan("local", "chat-plan-1", &agentplan.Plan{Goal: "Ziel"})

	if got := module.takePendingPlan("jemand-anders", "chat-plan-1"); got != nil {
		t.Error("fremder Nutzer darf den Plan nicht bekommen")
	}
	if got := module.takePendingPlan("local", "unbekannte-session"); got != nil {
		t.Error("unbekannte Session darf keinen Plan liefern")
	}

	if got := module.takePendingPlan("local", "chat-plan-1"); got == nil {
		t.Error("Besitzer sollte den Plan bekommen")
	}
}

func TestPendingPlanUeberlebtNeustart(t *testing.T) {
	module, settings := newPlanTestModule(t)
	module.storePendingPlan("local", "chat-plan-1", &agentplan.Plan{
		Goal:    "Ziel",
		Summary: "S",
		Steps:   []agentplan.Step{{Number: 1, Title: "Erst", Status: agentplan.StatusPending}},
	})

	restarted := New(settings)
	restarted.loadPersistedSessions()
	got := restarted.takePendingPlan("local", "chat-plan-1")
	if got == nil {
		t.Fatal("Plan wurde nicht persistiert")
	}
	if len(got.Steps) != 1 || got.Steps[0].Title != "Erst" {
		t.Fatalf("Plan kam unvollstaendig zurueck: %+v", got)
	}
}

func TestRunPlanningFlowUebergeht(t *testing.T) {
	module, _ := newPlanTestModule(t)
	cases := map[string]chatOptions{
		"execute-modus":         {AgenticMode: "execute"},
		"leerer modus":          {},
		"freigabe ohne plan":    {ApprovePlan: true},
		"freigabe fremde sess.": {ApprovePlan: true, AgenticMode: "planning"},
	}
	for name, options := range cases {
		t.Run(name, func(t *testing.T) {
			handled, reply, err := module.runPlanningFlow(context.Background(), planningRequest{
				userID:    "local",
				sessionID: "chat-plan-1",
				options:   options,
			})
			if handled {
				t.Errorf("Ablauf sollte nicht uebernehmen (reply=%q, err=%v)", reply, err)
			}
		})
	}
}

func TestResolveToolRootsKombiniert(t *testing.T) {
	projekt := t.TempDir()
	genannt := t.TempDir()

	got := resolveToolRoots(projekt, "Vergleich das mit "+genannt+" bitte")
	if len(got) != 2 {
		t.Fatalf("erwartete Projekt + genannten Ordner, bekam %v", got)
	}
	if got[0] != projekt {
		t.Errorf("Projekt-Ordner sollte zuerst stehen, war %v", got)
	}
}

func TestResolveToolRootsOhneProjekt(t *testing.T) {
	genannt := t.TempDir()
	got := resolveToolRoots("", "Schau mal in "+genannt)
	if len(got) != 1 {
		t.Fatalf("genannter Ordner sollte auch ohne Projekt freigegeben werden, bekam %v", got)
	}
}

func TestResolveToolRootsLeer(t *testing.T) {
	if got := resolveToolRoots("", "Erklaer mir Go-Slices"); len(got) != 0 {
		t.Errorf("ohne Projekt und ohne Pfad darf es keine Roots geben, bekam %v", got)
	}
	if got := resolveToolRoots("   ", "nix"); len(got) != 0 {
		t.Errorf("leerer Projektpfad darf keinen Root ergeben, bekam %v", got)
	}
}
