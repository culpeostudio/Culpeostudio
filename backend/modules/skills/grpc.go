// Package skills stores and validates the skill definitions and serves them
// over gRPC.
package skills

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"strings"

	skillsv1 "github.com/culpeohq/backend/gen/go/culpeostudio/skills/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type grpcService struct {
	skillsv1.UnimplementedSkillsServiceServer
	store *Store
}

func (m *SkillsModule) RegisterGRPC(server *grpc.Server) {
	skillsv1.RegisterSkillsServiceServer(server, &grpcService{store: m.store})
}

func (s *grpcService) ListSkills(ctx context.Context, req *skillsv1.ListSkillsRequest) (*skillsv1.ListSkillsResponse, error) {
	records := skillRecordsToProto(s.store.List())
	return &skillsv1.ListSkillsResponse{
		Skills: records,
		Count:  int32(len(records)),
	}, nil
}

func (s *grpcService) ImportSkill(ctx context.Context, req *skillsv1.ImportSkillRequest) (*skillsv1.ImportSkillResponse, error) {
	record, err := s.store.Import(req.GetSourcePath(), req.GetEnabled())
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	return &skillsv1.ImportSkillResponse{
		Skill:   skillRecordToProto(record),
		Message: "Skill eingebunden",
	}, nil
}

func (s *grpcService) UpdateSkill(ctx context.Context, req *skillsv1.UpdateSkillRequest) (*skillsv1.UpdateSkillResponse, error) {
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
	return &skillsv1.UpdateSkillResponse{
		Skill:   skillRecordToProto(record),
		Message: "Skill aktualisiert",
	}, nil
}

func (s *grpcService) DeleteSkill(ctx context.Context, req *skillsv1.DeleteSkillRequest) (*skillsv1.DeleteSkillResponse, error) {
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
	return &skillsv1.DeleteSkillResponse{
		Name:    name,
		Status:  "deleted",
		Message: "Skill entfernt",
	}, nil
}

func (s *grpcService) RescanSkills(ctx context.Context, req *skillsv1.RescanSkillsRequest) (*skillsv1.RescanSkillsResponse, error) {
	records, err := s.store.Rescan()
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	items := skillRecordsToProto(records)
	return &skillsv1.RescanSkillsResponse{
		Skills: items,
		Count:  int32(len(items)),
	}, nil
}

func skillRecordsToProto(records []SkillRecord) []*skillsv1.SkillRecord {
	items := make([]*skillsv1.SkillRecord, 0, len(records))
	for _, record := range records {
		items = append(items, skillRecordToProto(record))
	}
	return items
}

func skillRecordToProto(record SkillRecord) *skillsv1.SkillRecord {
	metadataJSON := ""
	if len(record.Metadata) > 0 {
		if payload, err := json.Marshal(record.Metadata); err == nil {
			metadataJSON = string(payload)
		}
	}
	return &skillsv1.SkillRecord{
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
		FileSummary: &skillsv1.SkillFileSummary{
			FileCount:      int32(record.FileSummary.FileCount),
			DirectoryCount: int32(record.FileSummary.DirectoryCount),
			HasScripts:     record.FileSummary.HasScripts,
			HasReferences:  record.FileSummary.HasReferences,
			HasAssets:      record.FileSummary.HasAssets,
		},
	}
}
