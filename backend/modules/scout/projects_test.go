package scout

import (
	"context"
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	scoutv1 "github.com/culpeohq/backend/gen/go/culpeostudio/scout/v1"
	sparkv1 "github.com/culpeohq/backend/gen/go/culpeostudio/spark/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/modules/spark"
)

// startSparkGRPC serves the agent's project API the way the server does, so a
// test can drive scout and spark side by side.
func startSparkGRPC(t *testing.T, agent *spark.Module) sparkv1.SparkServiceClient {
	t.Helper()

	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Listen fehlgeschlagen: %v", err)
	}
	// The caller has to travel as metadata: over a real connection a context
	// set on the client side never reaches the server.
	server := grpc.NewServer(grpc.UnaryInterceptor(func(
		ctx context.Context,
		req any,
		_ *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		if md, ok := metadata.FromIncomingContext(ctx); ok {
			if users := md.Get(testUserMetadataKey); len(users) > 0 && users[0] != "" {
				ctx = grpcmw.ContextWithUserForTest(ctx, users[0], users[0])
			}
		}
		return handler(ctx, req)
	}))
	agent.RegisterGRPC(server)
	go func() { _ = server.Serve(listener) }()
	t.Cleanup(server.Stop)

	conn, err := grpc.NewClient(listener.Addr().String(),
		grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatalf("Verbindung fehlgeschlagen: %v", err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	return sparkv1.NewSparkServiceClient(conn)
}

const testUserMetadataKey = "x-test-user"

// sparkContext names the caller. The empty name leaves the call
// unauthenticated, which the module maps to its local user.
func sparkContext(user string) context.Context {
	if user == "" {
		return context.Background()
	}
	return metadata.AppendToOutgoingContext(context.Background(), testUserMetadataKey, user)
}

// newWiredApp mounts the chat module together with the agent, the way the
// server wires them, so project and session calls can be exercised together.
func newWiredApp(t *testing.T, settingsPath string) (*ScoutModule, *grpcService, sparkv1.SparkServiceClient) {
	t.Helper()
	chat := New(settingsPath)
	agent := spark.New(settingsPath)
	chat.SetAgent(agent)
	agent.SetPlanStore(chat)
	agent.SetProjectDetachedHook(chat.DetachProject)
	if err := chat.Initialize(); err != nil {
		t.Fatal(err)
	}
	if err := agent.Initialize(); err != nil {
		t.Fatal(err)
	}
	return chat, &grpcService{module: chat}, startSparkGRPC(t, agent)
}

func newProjectTestApp(t *testing.T) (*ScoutModule, *grpcService, sparkv1.SparkServiceClient) {
	t.Helper()
	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	return newWiredApp(t, settingsPath)
}

func TestScoutProjectCRUD(t *testing.T) {
	_, _, projects := newProjectTestApp(t)
	ctx := sparkContext("")

	created, err := projects.CreateProject(ctx, &sparkv1.CreateProjectRequest{
		Name: "Arbeit", Color: "#C9A24A",
	})
	if err != nil {
		t.Fatalf("create error=%v", err)
	}
	project := created.GetProject()
	projectID := project.GetId()
	if projectID == "" || project.GetName() != "Arbeit" || project.GetColor() != "#C9A24A" {
		t.Fatalf("unexpected project payload: %v", project)
	}

	list, err := projects.ListProjects(ctx, &sparkv1.ListProjectsRequest{})
	if err != nil {
		t.Fatalf("list error=%v", err)
	}
	if len(list.GetProjects()) != 1 || list.GetProjects()[0].GetId() != projectID {
		t.Fatalf("expected exactly the created project, got %v", list.GetProjects())
	}

	renamed, err := projects.RenameProject(ctx, &sparkv1.RenameProjectRequest{
		Id: projectID, Name: "Buero",
	})
	if err != nil {
		t.Fatalf("rename error=%v", err)
	}
	if renamed.GetProject().GetName() != "Buero" {
		t.Fatalf("rename not applied: %v", renamed.GetProject())
	}

	if _, err := projects.DeleteProject(ctx, &sparkv1.DeleteProjectRequest{Id: projectID}); err != nil {
		t.Fatalf("delete error=%v", err)
	}
	list, err = projects.ListProjects(ctx, &sparkv1.ListProjectsRequest{})
	if err != nil {
		t.Fatalf("list error=%v", err)
	}
	if len(list.GetProjects()) != 0 {
		t.Fatalf("project survived delete: %v", list.GetProjects())
	}
}

func TestScoutProjectValidation(t *testing.T) {
	_, _, projects := newProjectTestApp(t)
	ctx := sparkContext("")

	_, err := projects.CreateProject(ctx, &sparkv1.CreateProjectRequest{Name: "   "})
	if status.Code(err) != codes.InvalidArgument {
		t.Fatalf("empty name code=%v", status.Code(err))
	}

	created, err := projects.CreateProject(ctx, &sparkv1.CreateProjectRequest{
		Name: strings.Repeat("x", 200),
	})
	if err != nil {
		t.Fatalf("long name error=%v", err)
	}
	if name := created.GetProject().GetName(); len([]rune(name)) > 80 {
		t.Fatalf("name not truncated to 80 runes: %d", len([]rune(name)))
	}

	_, err = projects.RenameProject(ctx, &sparkv1.RenameProjectRequest{
		Id: "does-not-exist", Name: "x",
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("rename missing code=%v", status.Code(err))
	}
	_, err = projects.DeleteProject(ctx, &sparkv1.DeleteProjectRequest{Id: "does-not-exist"})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("delete missing code=%v", status.Code(err))
	}
}

func TestScoutSessionProjectAssignment(t *testing.T) {
	_, chat, projects := newProjectTestApp(t)
	ctx := sparkContext("")

	created, err := projects.CreateProject(ctx, &sparkv1.CreateProjectRequest{Name: "Projekt A"})
	if err != nil {
		t.Fatalf("create error=%v", err)
	}
	projectID := created.GetProject().GetId()

	sessionResp, err := chat.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelId: "stub", ProjectId: projectID,
	})
	if err != nil {
		t.Fatalf("create session error=%v", err)
	}
	sessionID := sessionResp.GetSessionId()

	if _, err := chat.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: sessionID, Message: "Hallo",
	}); err != nil {
		t.Fatalf("message error=%v", err)
	}

	list, err := chat.ListSessions(context.Background(), &scoutv1.ListSessionsRequest{})
	if err != nil {
		t.Fatalf("list sessions error=%v", err)
	}
	if len(list.GetSessions()) != 1 {
		t.Fatalf("expected 1 session summary, got %v", list.GetSessions())
	}
	if list.GetSessions()[0].GetProjectId() != projectID {
		t.Fatalf("summary missing project_id: %v", list.GetSessions()[0])
	}

	second, err := projects.CreateProject(ctx, &sparkv1.CreateProjectRequest{Name: "Projekt B"})
	if err != nil {
		t.Fatalf("create second error=%v", err)
	}
	secondID := second.GetProject().GetId()
	assigned, err := chat.SetSessionProject(context.Background(), &scoutv1.SetSessionProjectRequest{
		SessionId: sessionID, ProjectId: secondID,
	})
	if err != nil {
		t.Fatalf("assign error=%v", err)
	}
	if assigned.GetSession().GetProjectId() != secondID {
		t.Fatalf("assign not reflected: %v", assigned.GetSession())
	}

	if _, err := projects.DeleteProject(ctx, &sparkv1.DeleteProjectRequest{Id: secondID}); err != nil {
		t.Fatalf("delete project error=%v", err)
	}
	list, err = chat.ListSessions(context.Background(), &scoutv1.ListSessionsRequest{})
	if err != nil {
		t.Fatalf("list sessions error=%v", err)
	}
	if len(list.GetSessions()) != 1 {
		t.Fatalf("session lost after project delete: %v", list.GetSessions())
	}
	if pid := list.GetSessions()[0].GetProjectId(); pid != "" {
		t.Fatalf("project_id not cleared after delete: %q", pid)
	}

	created, err = projects.CreateProject(ctx, &sparkv1.CreateProjectRequest{Name: "Tmp"})
	if err != nil {
		t.Fatalf("create tmp error=%v", err)
	}
	tmpID := created.GetProject().GetId()
	if _, err := chat.SetSessionProject(context.Background(), &scoutv1.SetSessionProjectRequest{
		SessionId: sessionID, ProjectId: tmpID,
	}); err != nil {
		t.Fatalf("assign tmp error=%v", err)
	}
	unassigned, err := chat.SetSessionProject(context.Background(), &scoutv1.SetSessionProjectRequest{
		SessionId: sessionID,
	})
	if err != nil {
		t.Fatalf("unassign error=%v", err)
	}
	if pid := unassigned.GetSession().GetProjectId(); pid != "" {
		t.Fatalf("unassign not reflected: %q", pid)
	}

	_, err = chat.SetSessionProject(context.Background(), &scoutv1.SetSessionProjectRequest{
		SessionId: sessionID, ProjectId: "nope",
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("assign unknown project code=%v", status.Code(err))
	}
	_, err = chat.SetSessionProject(context.Background(), &scoutv1.SetSessionProjectRequest{
		SessionId: "nope", ProjectId: tmpID,
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("assign unknown session code=%v", status.Code(err))
	}

	_, err = chat.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelId: "stub", ProjectId: "nope",
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("create session unknown project code=%v", status.Code(err))
	}
}

func TestScoutProjectsIsolatedByUser(t *testing.T) {
	_, chat, projects := newProjectTestApp(t)

	created, err := projects.CreateProject(sparkContext("alice"), &sparkv1.CreateProjectRequest{
		Name: "Alice Privat",
	})
	if err != nil {
		t.Fatalf("create error=%v", err)
	}
	projectID := created.GetProject().GetId()

	list, err := projects.ListProjects(sparkContext("bob"), &sparkv1.ListProjectsRequest{})
	if err != nil {
		t.Fatalf("list error=%v", err)
	}
	if len(list.GetProjects()) != 0 {
		t.Fatalf("alice project leaked to bob: %v", list.GetProjects())
	}

	_, err = projects.RenameProject(sparkContext("bob"), &sparkv1.RenameProjectRequest{
		Id: projectID, Name: "gehackt",
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("bob rename code=%v", status.Code(err))
	}
	_, err = projects.DeleteProject(sparkContext("bob"), &sparkv1.DeleteProjectRequest{Id: projectID})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("bob delete code=%v", status.Code(err))
	}
	bobSessionResp, err := chat.CreateSession(userContext("bob"), &scoutv1.CreateSessionRequest{ModelId: "stub"})
	if err != nil {
		t.Fatalf("bob create session error=%v", err)
	}
	_, err = chat.SetSessionProject(userContext("bob"), &scoutv1.SetSessionProjectRequest{
		SessionId: bobSessionResp.GetSessionId(), ProjectId: projectID,
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("bob assign to alice project code=%v", status.Code(err))
	}

	aliceSessionResp, err := chat.CreateSession(userContext("alice"), &scoutv1.CreateSessionRequest{ModelId: "stub"})
	if err != nil {
		t.Fatalf("alice create session error=%v", err)
	}
	if _, err := chat.SetSessionProject(userContext("alice"), &scoutv1.SetSessionProjectRequest{
		SessionId: aliceSessionResp.GetSessionId(), ProjectId: projectID,
	}); err != nil {
		t.Fatalf("alice assign error=%v", err)
	}
}

func TestScoutProjectsSurviveReload(t *testing.T) {
	tmpDir := t.TempDir()
	settingsPath := filepath.Join(tmpDir, "settings.json")
	if err := os.WriteFile(settingsPath, []byte(`{}`), 0o600); err != nil {
		t.Fatal(err)
	}
	_, chat, projects := newWiredApp(t, settingsPath)
	ctx := sparkContext("")

	created, err := projects.CreateProject(ctx, &sparkv1.CreateProjectRequest{Name: "Persist"})
	if err != nil {
		t.Fatalf("create error=%v", err)
	}
	projectID := created.GetProject().GetId()
	sessionResp, err := chat.CreateSession(context.Background(), &scoutv1.CreateSessionRequest{
		ModelId: "stub", ProjectId: projectID,
	})
	if err != nil {
		t.Fatalf("create session error=%v", err)
	}
	if _, err := chat.SendMessage(context.Background(), &scoutv1.SendMessageRequest{
		SessionId: sessionResp.GetSessionId(), Message: "Hallo",
	}); err != nil {
		t.Fatalf("message error=%v", err)
	}

	_, reloaded, projects2 := newWiredApp(t, settingsPath)

	list, err := projects2.ListProjects(ctx, &sparkv1.ListProjectsRequest{})
	if err != nil {
		t.Fatalf("list error=%v", err)
	}
	if len(list.GetProjects()) != 1 || list.GetProjects()[0].GetId() != projectID {
		t.Fatalf("project lost on reload: %v", list.GetProjects())
	}
	sessions, err := reloaded.ListSessions(context.Background(), &scoutv1.ListSessionsRequest{})
	if err != nil {
		t.Fatalf("list sessions error=%v", err)
	}
	entries := sessions.GetSessions()
	if len(entries) != 1 || entries[0].GetProjectId() != projectID {
		t.Fatalf("session assignment lost on reload: %v", entries)
	}
}
