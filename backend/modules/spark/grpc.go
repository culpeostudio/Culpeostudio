package spark

import (
	"context"
	"log"
	"sort"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	sparkv1 "github.com/culpeohq/backend/gen/go/culpeostudio/spark/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
)

type grpcService struct {
	sparkv1.UnimplementedSparkServiceServer
	module *Module
}

func (m *Module) RegisterGRPC(server *grpc.Server) {
	sparkv1.RegisterSparkServiceServer(server, &grpcService{module: m})
}

// contextUserID reads the caller the auth interceptor put on the context and
// falls back to the single local user of an unauthenticated checkout.
func contextUserID(ctx context.Context) string {
	if userID := strings.ToLower(strings.TrimSpace(grpcmw.UserIDFromContext(ctx))); userID != "" {
		return userID
	}
	return "local"
}

func (s *grpcService) ListProjects(ctx context.Context, req *sparkv1.ListProjectsRequest) (*sparkv1.ListProjectsResponse, error) {
	userID := contextUserID(ctx)
	m := s.module

	m.mu.Lock()
	projects := make([]*Project, 0, len(m.projects))
	for _, project := range m.projects {
		if project == nil || project.UserID != userID {
			continue
		}
		projects = append(projects, project)
	}
	m.mu.Unlock()

	sort.Slice(projects, func(i, j int) bool {
		return projects[i].CreatedAt.After(projects[j].CreatedAt)
	})

	items := make([]*sparkv1.Project, 0, len(projects))
	for _, project := range projects {
		items = append(items, projectToProto(project))
	}
	return &sparkv1.ListProjectsResponse{Projects: items}, nil
}

func (s *grpcService) CreateProject(ctx context.Context, req *sparkv1.CreateProjectRequest) (*sparkv1.CreateProjectResponse, error) {
	name := normalizeProjectName(req.GetName())
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "Projektname darf nicht leer sein")
	}

	userID := contextUserID(ctx)
	now := time.Now().UTC()
	project := &Project{
		ID:        newChatProjectID(),
		UserID:    userID,
		Name:      name,
		Color:     normalizeProjectColor(req.GetColor()),
		Path:      normalizeProjectPath(req.GetPath()),
		Icon:      normalizeProjectIcon(req.GetIcon()),
		CreatedAt: now,
		UpdatedAt: now,
	}

	m := s.module
	m.mu.Lock()
	m.projects[project.ID] = project
	m.mu.Unlock()
	m.persistProject(project.ID)
	m.ensureProjectMemory(userID, project.ID)

	return &sparkv1.CreateProjectResponse{Project: projectToProto(project)}, nil
}

func (s *grpcService) RenameProject(ctx context.Context, req *sparkv1.RenameProjectRequest) (*sparkv1.RenameProjectResponse, error) {
	name := normalizeProjectName(req.GetName())
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "Projektname darf nicht leer sein")
	}

	projectID := strings.TrimSpace(req.GetId())
	userID := contextUserID(ctx)
	m := s.module

	m.mu.Lock()
	project := m.projects[projectID]
	if project == nil || project.UserID != userID {
		m.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Projekt wurde nicht gefunden")
	}
	project.Name = name
	if color := normalizeProjectColor(req.GetColor()); color != "" {
		project.Color = color
	}
	project.Path = normalizeProjectPath(req.GetPath())
	// Absent leaves the icon alone; present but empty clears it.
	if req.Icon != nil {
		project.Icon = normalizeProjectIcon(req.GetIcon())
	}
	project.UpdatedAt = time.Now().UTC()
	renamed := projectToProto(project)
	m.mu.Unlock()

	m.persistProject(projectID)
	return &sparkv1.RenameProjectResponse{Project: renamed}, nil
}

func (s *grpcService) DeleteProject(ctx context.Context, req *sparkv1.DeleteProjectRequest) (*sparkv1.DeleteProjectResponse, error) {
	projectID := strings.TrimSpace(req.GetId())
	userID := contextUserID(ctx)
	m := s.module

	m.mu.Lock()
	project := m.projects[projectID]
	if project == nil || project.UserID != userID {
		m.mu.Unlock()
		return nil, status.Error(codes.NotFound, "Projekt wurde nicht gefunden")
	}
	delete(m.projects, projectID)
	m.mu.Unlock()

	if m.projectDetached != nil {
		m.projectDetached(userID, projectID)
	}
	if err := m.projectStore.Delete(projectID); err != nil {
		log.Printf("[spark] Projekt %s loeschen fehlgeschlagen: %v", projectID, err)
	}
	if m.memory != nil {
		if err := m.memory.PurgeProjectScope(userID, projectID); err != nil {
			log.Printf("[spark] Projektgedaechtnis fuer %s konnte nicht geloescht werden: %v", projectID, err)
		}
	}
	return &sparkv1.DeleteProjectResponse{}, nil
}

func (s *grpcService) RespondToPermission(ctx context.Context, req *sparkv1.RespondToPermissionRequest) (*sparkv1.RespondToPermissionResponse, error) {
	m := s.module

	m.mu.Lock()
	broker := m.permissionBrokers[strings.TrimSpace(req.GetSessionId())]
	m.mu.Unlock()

	if broker == nil || !broker.Respond(strings.TrimSpace(req.GetRequestId()), strings.TrimSpace(req.GetDecision())) {
		return nil, status.Error(codes.NotFound, "Permission-Anfrage unbekannt oder bereits beantwortet")
	}
	return &sparkv1.RespondToPermissionResponse{}, nil
}

func projectToProto(project *Project) *sparkv1.Project {
	if project == nil {
		return nil
	}
	message := &sparkv1.Project{
		Id:     project.ID,
		UserId: project.UserID,
		Name:   project.Name,
		Color:  project.Color,
		Path:   project.Path,
		Icon:   project.Icon,
	}
	if !project.CreatedAt.IsZero() {
		message.CreatedAt = timestamppb.New(project.CreatedAt)
	}
	if !project.UpdatedAt.IsZero() {
		message.UpdatedAt = timestamppb.New(project.UpdatedAt)
	}
	return message
}
