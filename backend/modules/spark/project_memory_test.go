package spark

import (
	"context"
	"path/filepath"
	"testing"

	sparkv1 "github.com/culpeohq/backend/gen/go/culpeostudio/spark/v1"
)

// memoryStub records what the agent asks the memory module to do.
type memoryStub struct {
	ensured []string
	purged  []string
	recall  string
	lastKey [3]string
}

func (s *memoryStub) ProjectMemoryContext(userID, project, query string) string {
	s.lastKey = [3]string{userID, project, query}
	return s.recall
}

func (s *memoryStub) EnsureProjectScope(userID, project string) error {
	s.ensured = append(s.ensured, project)
	return nil
}

func (s *memoryStub) PurgeProjectScope(userID, project string) error {
	s.purged = append(s.purged, project)
	return nil
}

func newMemoryTestModule(t *testing.T) (*Module, *memoryStub, *grpcService) {
	t.Helper()
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	stub := &memoryStub{}
	module.SetMemory(stub)
	return module, stub, &grpcService{module: module}
}

// No user on the context, so the handler falls back to the local user of an
// unauthenticated checkout.
func createProject(t *testing.T, service *grpcService, name string) string {
	t.Helper()
	response, err := service.CreateProject(context.Background(), &sparkv1.CreateProjectRequest{
		Name: name,
	})
	if err != nil {
		t.Fatalf("Projekt anlegen fehlgeschlagen: %v", err)
	}
	return response.GetProject().GetId()
}

func TestProjektBekommtEigenesGedaechtnis(t *testing.T) {
	_, stub, service := newMemoryTestModule(t)

	projectID := createProject(t, service, "Culpeo Studio")

	if len(stub.ensured) != 1 || stub.ensured[0] != projectID {
		t.Fatalf("Projekt-Scope wurde nicht angelegt: %v", stub.ensured)
	}
}

func TestGeloeschtesProjektRaeumtSeinGedaechtnisAb(t *testing.T) {
	module, stub, service := newMemoryTestModule(t)

	var detached []string
	module.SetProjectDetachedHook(func(userID, projectID string) {
		detached = append(detached, projectID)
	})

	projectID := createProject(t, service, "Wegwerf")

	if _, err := service.DeleteProject(context.Background(), &sparkv1.DeleteProjectRequest{
		Id: projectID,
	}); err != nil {
		t.Fatalf("Projekt loeschen fehlgeschlagen: %v", err)
	}

	if len(stub.purged) != 1 || stub.purged[0] != projectID {
		t.Fatalf("Projekt-Scope wurde nicht abgeraeumt: %v", stub.purged)
	}
	if len(detached) != 1 || detached[0] != projectID {
		t.Fatalf("Sitzungen wurden nicht vom Projekt geloest: %v", detached)
	}
}

func TestProjektKontextGehtAnDenScope(t *testing.T) {
	module, stub, _ := newMemoryTestModule(t)
	stub.recall = "- Das Projekt nutzt Fiber."

	got := module.ProjectMemoryContext("local", " projekt-1 ", "Woran arbeiten wir?")

	if got != stub.recall {
		t.Fatalf("Recall kam nicht durch: %q", got)
	}
	if stub.lastKey != [3]string{"local", "projekt-1", "Woran arbeiten wir?"} {
		t.Fatalf("Scope falsch angefragt: %v", stub.lastKey)
	}
}

func TestProjektKontextOhneGedaechtnis(t *testing.T) {
	module := New(filepath.Join(t.TempDir(), "settings.json"))
	if got := module.ProjectMemoryContext("local", "projekt-1", "frage"); got != "" {
		t.Fatalf("ohne Gedaechtnis darf kein Recall entstehen, bekam %q", got)
	}
}
