package spark

import (
	"context"
	"path/filepath"
	"strings"
	"testing"

	"github.com/culpeohq/backend/internal/agentplan"
)

// planStoreStub stands in for the chat module that keeps pending and
// half-worked plans.
type planStoreStub struct {
	plans  map[string]*agentplan.Plan
	active map[string]*agentplan.Plan
	writes int
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

func (s *planStoreStub) StoreActivePlan(userID, sessionID string, plan *agentplan.Plan) {
	if s.active == nil {
		s.active = map[string]*agentplan.Plan{}
	}
	s.writes++
	s.active[userID+"/"+sessionID] = plan
}

func (s *planStoreStub) ActivePlan(userID, sessionID string) *agentplan.Plan {
	return s.active[userID+"/"+sessionID]
}

func (s *planStoreStub) ClearActivePlan(userID, sessionID string) {
	delete(s.active, userID+"/"+sessionID)
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

func TestRunPlanningFlowSetztAngefangenenPlanFort(t *testing.T) {
	module := newPlanTestModule(t)
	store := module.plans.(*planStoreStub)
	store.StoreActivePlan("local", "chat-plan-2", &agentplan.Plan{
		Goal: "Ziel",
		Steps: []agentplan.Step{
			{Number: 1, Title: "Erst", Status: agentplan.StatusDone, Result: "war schon"},
			{Number: 2, Title: "Dann", Status: agentplan.StatusPending},
		},
	})

	var tasks []string
	turn := func(convo []Message, prompt string, emit func(string) error) (string, error) {
		if len(convo) > 0 {
			tasks = append(tasks, convo[0].Content)
		}
		return "erledigt", nil
	}

	handled, _, err := module.runPlanningFlow(context.Background(), Request{
		UserID:      "local",
		SessionID:   "chat-plan-2",
		ApprovePlan: true,
	}, turn)
	if err != nil {
		t.Fatalf("runPlanningFlow: %v", err)
	}
	if !handled {
		t.Fatal("eine Freigabe ohne neuen Plan muss den angefangenen fortsetzen")
	}
	if len(tasks) != 2 {
		t.Fatalf("erwartete den offenen Schritt und den Bericht, bekam %v", tasks)
	}
	if !strings.Contains(tasks[0], "Schritt 2") {
		t.Errorf("fortgesetzt werden darf nur der offene Schritt, gestartet wurde %q", tasks[0])
	}
	if store.ActivePlan("local", "chat-plan-2") != nil {
		t.Error("ein durchgearbeiteter Plan muss aus der Sitzung verschwinden")
	}
}

func TestResolveToolRootsKombiniert(t *testing.T) {
	projekt := t.TempDir()
	genannt := t.TempDir()

	got := resolveToolRoots(projekt, "Vergleich das mit "+genannt+" bitte", nil)
	if len(got) != 2 {
		t.Fatalf("erwartete Projekt + genannten Ordner, bekam %v", got)
	}
	if got[0] != projekt {
		t.Errorf("Projekt-Ordner sollte zuerst stehen, war %v", got)
	}
}

func TestResolveToolRootsOhneProjekt(t *testing.T) {
	genannt := t.TempDir()
	got := resolveToolRoots("", "Schau mal in "+genannt, nil)
	if len(got) != 1 {
		t.Fatalf("genannter Ordner sollte auch ohne Projekt freigegeben werden, bekam %v", got)
	}
}

func TestResolveToolRootsLeer(t *testing.T) {
	if got := resolveToolRoots("", "Erklaer mir Go-Slices", nil); len(got) != 0 {
		t.Errorf("ohne Projekt und ohne Pfad darf es keine Roots geben, bekam %v", got)
	}
	if got := resolveToolRoots("   ", "nix", nil); len(got) != 0 {
		t.Errorf("leerer Projektpfad darf keinen Root ergeben, bekam %v", got)
	}
}

func TestResolveToolRootsBehaeltFruehergenanntenOrdner(t *testing.T) {
	genannt := t.TempDir()
	history := []Message{
		{Role: "user", Content: "Das Projekt liegt in " + genannt},
		{Role: "assistant", Content: "Verstanden."},
		{Role: "user", Content: "Bau mir da einen Export ein"},
	}

	got := resolveToolRoots("", "Bau mir da einen Export ein", history)
	if len(got) != 1 || got[0] != genannt {
		t.Fatalf("frueher genannter Ordner muss weiter gelten, bekam %v", got)
	}
}

func TestResolveToolRootsIgnoriertPfadeDerAntwort(t *testing.T) {
	fremd := t.TempDir()
	history := []Message{
		{Role: "user", Content: "Wo liegen eigentlich Logs?"},
		{Role: "assistant", Content: "Zum Beispiel unter " + fremd},
	}

	if got := resolveToolRoots("", "Und weiter?", history); len(got) != 0 {
		t.Errorf("ein Pfad aus der eigenen Antwort darf keinen Zugriff eroeffnen, bekam %v", got)
	}
}

func TestResolveToolRootsEntfernteDoppelungen(t *testing.T) {
	genannt := t.TempDir()
	history := []Message{{Role: "user", Content: "Arbeite in " + genannt}}

	got := resolveToolRoots(genannt, "Nochmal "+genannt, history)
	if len(got) != 1 {
		t.Fatalf("derselbe Ordner darf nur einmal auftauchen, bekam %v", got)
	}
}
