package spark

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/culpeohq/backend/internal/agentplan"
)

// planStoreStub stands in for the chat module that keeps pending plans.
type planStoreStub struct {
	plans map[string]*agentplan.Plan
}

func (s *planStoreStub) StorePendingPlan(userID, sessionID string, plan *agentplan.Plan) {
	if s.plans == nil {
		s.plans = map[string]*agentplan.Plan{}
	}
	s.plans[userID+"/"+sessionID] = plan
}

func (s *planStoreStub) TakePendingPlan(userID, sessionID string) *agentplan.Plan {
	key := userID + "/" + sessionID
	plan := s.plans[key]
	delete(s.plans, key)
	return plan
}

func newPlanTestModule(t *testing.T) *Module {
	t.Helper()
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.SetPlanStore(&planStoreStub{})
	return module
}

func TestRunPlanningFlowUebergeht(t *testing.T) {
	module := newPlanTestModule(t)
	cases := map[string]Request{
		"kein modus":         {},
		"freigabe ohne plan": {ApprovePlan: true},
	}
	for name, req := range cases {
		t.Run(name, func(t *testing.T) {
			req.UserID = "local"
			req.SessionID = "chat-plan-1"
			handled, reply, err := module.runPlanningFlow(context.Background(), req, nil)
			if handled {
				t.Errorf("Ablauf sollte nicht uebernehmen (reply=%q, err=%v)", reply, err)
			}
		})
	}
}

func TestPendingPlanGehtUeberDenPlanStore(t *testing.T) {
	module := newPlanTestModule(t)
	module.storePendingPlan("local", "chat-plan-1", &agentplan.Plan{Goal: "Ziel"})

	got := module.takePendingPlan("local", "chat-plan-1")
	if got == nil || got.Goal != "Ziel" {
		t.Fatalf("Plan kam nicht aus dem Store zurueck: %+v", got)
	}
	if again := module.takePendingPlan("local", "chat-plan-1"); again != nil {
		t.Error("zweiter Abruf sollte nichts mehr liefern")
	}
}

func TestPendingPlanOhnePlanStore(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	module.storePendingPlan("local", "chat-plan-1", &agentplan.Plan{Goal: "Ziel"})
	if got := module.takePendingPlan("local", "chat-plan-1"); got != nil {
		t.Error("ohne PlanStore darf kein Plan zurueckkommen")
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
