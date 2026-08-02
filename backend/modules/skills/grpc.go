// Package skills stores and validates the skill definitions and serves them over
// both HTTP and gRPC.
package skills

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"strings"

	pb "github.com/fillyengine/backend/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type grpcService struct {
	pb.UnimplementedSkillsServiceServer
	store *Store
}

func (m *SkillsModule) RegisterGRPC(server *grpc.Server) {
	pb.RegisterSkillsServiceServer(server, &grpcService{store: m.store})
}

func (s *grpcService) ListSkills(ctx context.Context, req *pb.Empty) (*pb.SkillListResponse, error) {
	records := s.store.List()
	return skillListResponse(records), nil
}

func (s *grpcService) ImportSkill(ctx context.Context, req *pb.ImportSkillRequest) (*pb.SkillResponse, error) {
	record, err := s.store.Import(req.GetSourcePath(), req.GetEnabled())
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	return &pb.SkillResponse{
		Skill:   skillRecordToProto(record),
		Message: "Skill eingebunden",
	}, nil
}

func (s *grpcService) UpdateSkill(ctx context.Context, req *pb.UpdateSkillRequest) (*pb.SkillResponse, error) {
	name := strings.TrimSpace(req.GetName())
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "name ist erforderlich")
	}
	record, err := s.store.SetEnabled(name, req.GetEnabled())
	if errors.Is(err, os.ErrNotExist) {
		return nil, status.Error(codes.NotFound, "Skill nicht gefunden")
	}
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	return &pb.SkillResponse{
		Skill:   skillRecordToProto(record),
		Message: "Skill aktualisiert",
	}, nil
}

func (s *grpcService) DeleteSkill(ctx context.Context, req *pb.DeleteSkillRequest) (*pb.DeleteSkillResponse, error) {
	name := strings.TrimSpace(req.GetName())
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "name ist erforderlich")
	}
	err := s.store.Delete(name)
	if errors.Is(err, os.ErrNotExist) {
		return nil, status.Error(codes.NotFound, "Skill nicht gefunden")
	}
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	return &pb.DeleteSkillResponse{
		Name:    name,
		Status:  "deleted",
		Message: "Skill entfernt",
	}, nil
}

func (s *grpcService) RescanSkills(ctx context.Context, req *pb.Empty) (*pb.SkillListResponse, error) {
	records, err := s.store.Rescan()
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	return skillListResponse(records), nil
}

func skillListResponse(records []SkillRecord) *pb.SkillListResponse {
	items := make([]*pb.SkillRecord, 0, len(records))
	for _, record := range records {
		items = append(items, skillRecordToProto(record))
	}
	return &pb.SkillListResponse{
		Skills: items,
		Count:  int32(len(items)),
	}
}

func skillRecordToProto(record SkillRecord) *pb.SkillRecord {
	metadataJSON := ""
	if len(record.Metadata) > 0 {
		if payload, err := json.Marshal(record.Metadata); err == nil {
			metadataJSON = string(payload)
		}
	}
	return &pb.SkillRecord{
		Name:           record.Name,
		Description:    record.Description,
		Enabled:        record.Enabled,
		Path:           record.Path,
		ImportedAtUnix: record.ImportedAt.Unix(),
		UpdatedAtUnix:  record.UpdatedAt.Unix(),
		License:        record.License,
		Compatibility:  record.Compatibility,
		MetadataJson:   metadataJSON,
		AllowedTools:   record.AllowedTools,
		Valid:          record.Valid,
		Errors:         append([]string{}, record.Errors...),
		FileSummary: &pb.SkillFileSummary{
			FileCount:      int32(record.FileSummary.FileCount),
			DirectoryCount: int32(record.FileSummary.DirectoryCount),
			HasScripts:     record.FileSummary.HasScripts,
			HasReferences:  record.FileSummary.HasReferences,
			HasAssets:      record.FileSummary.HasAssets,
		},
	}
}
