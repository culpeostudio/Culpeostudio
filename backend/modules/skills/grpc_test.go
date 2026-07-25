package skills

import (
	"context"
	"path/filepath"
	"strings"
	"testing"

	pb "github.com/fillyengine/backend/proto"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestSkillsGRPCImportListUpdateDelete(t *testing.T) {
	tmpDir := t.TempDir()
	source := filepath.Join(tmpDir, "source")
	writeSkillFile(t, source, `---
name: grpc-skill
description: Skill managed through gRPC.
---

# gRPC Skill

Use gRPC workflows.
`)

	store := NewStore(filepath.Join(tmpDir, "skills"))
	if err := store.Load(); err != nil {
		t.Fatalf("Load failed: %v", err)
	}
	service := &grpcService{store: store}

	importResp, err := service.ImportSkill(context.Background(), &pb.ImportSkillRequest{
		SourcePath: source,
		Enabled:    true,
	})
	if err != nil {
		t.Fatalf("ImportSkill failed: %v", err)
	}
	if importResp.GetSkill().GetName() != "grpc-skill" || !importResp.GetSkill().GetEnabled() {
		t.Fatalf("unexpected import response: %+v", importResp.GetSkill())
	}

	listResp, err := service.ListSkills(context.Background(), &pb.Empty{})
	if err != nil {
		t.Fatalf("ListSkills failed: %v", err)
	}
	if listResp.GetCount() != 1 {
		t.Fatalf("expected one skill, got %d", listResp.GetCount())
	}

	updateResp, err := service.UpdateSkill(context.Background(), &pb.UpdateSkillRequest{
		Name:    "grpc-skill",
		Enabled: false,
	})
	if err != nil {
		t.Fatalf("UpdateSkill failed: %v", err)
	}
	if updateResp.GetSkill().GetEnabled() {
		t.Fatalf("expected disabled skill")
	}

	deleteResp, err := service.DeleteSkill(context.Background(), &pb.DeleteSkillRequest{Name: "grpc-skill"})
	if err != nil {
		t.Fatalf("DeleteSkill failed: %v", err)
	}
	if deleteResp.GetStatus() != "deleted" {
		t.Fatalf("expected deleted status, got %q", deleteResp.GetStatus())
	}
}

func TestSkillsGRPCInvalidImportUsesInvalidArgument(t *testing.T) {
	store := NewStore(filepath.Join(t.TempDir(), "skills"))
	if err := store.Load(); err != nil {
		t.Fatalf("Load failed: %v", err)
	}
	service := &grpcService{store: store}

	_, err := service.ImportSkill(context.Background(), &pb.ImportSkillRequest{SourcePath: ""})
	if status.Code(err) != codes.InvalidArgument {
		t.Fatalf("expected InvalidArgument, got %v", err)
	}
	if !strings.Contains(status.Convert(err).Message(), "Skill-Pfad fehlt") {
		t.Fatalf("unexpected error message: %v", err)
	}
}
