package skills

import (
	"encoding/json"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"
)

func TestSkillsAPIImportListUpdateDeleteRescan(t *testing.T) {
	tmpDir := t.TempDir()
	source := filepath.Join(tmpDir, "source")
	writeSkillFile(t, source, `---
name: api-skill
description: Skill managed through the API.
---

# API Skill

Use API workflows.
`)

	module := New(filepath.Join(tmpDir, "skills"))
	if err := module.Initialize(); err != nil {
		t.Fatalf("initialize failed: %v", err)
	}
	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)

	importReq := httptest.NewRequest(
		"POST",
		"/api/skills/import",
		strings.NewReader(`{"source_path":"`+strings.ReplaceAll(source, `\`, `\\`)+`","enabled":true}`),
	)
	importReq.Header.Set("Content-Type", "application/json")
	importResp, err := app.Test(importReq)
	if err != nil {
		t.Fatalf("import request failed: %v", err)
	}
	if importResp.StatusCode != 200 {
		t.Fatalf("expected import 200, got %d", importResp.StatusCode)
	}

	listReq := httptest.NewRequest("GET", "/api/skills", nil)
	listResp, err := app.Test(listReq)
	if err != nil {
		t.Fatalf("list request failed: %v", err)
	}
	var listBody map[string]interface{}
	if err := json.NewDecoder(listResp.Body).Decode(&listBody); err != nil {
		t.Fatalf("decode list body: %v", err)
	}
	if listBody["count"].(float64) != 1 {
		t.Fatalf("expected one skill, got %+v", listBody)
	}

	updateReq := httptest.NewRequest("PATCH", "/api/skills/api-skill", strings.NewReader(`{"enabled":false}`))
	updateReq.Header.Set("Content-Type", "application/json")
	updateResp, err := app.Test(updateReq)
	if err != nil {
		t.Fatalf("update request failed: %v", err)
	}
	if updateResp.StatusCode != 200 {
		t.Fatalf("expected update 200, got %d", updateResp.StatusCode)
	}

	rescanReq := httptest.NewRequest("POST", "/api/skills/rescan", nil)
	rescanResp, err := app.Test(rescanReq)
	if err != nil {
		t.Fatalf("rescan request failed: %v", err)
	}
	if rescanResp.StatusCode != 200 {
		t.Fatalf("expected rescan 200, got %d", rescanResp.StatusCode)
	}

	deleteReq := httptest.NewRequest("DELETE", "/api/skills/api-skill", nil)
	deleteResp, err := app.Test(deleteReq)
	if err != nil {
		t.Fatalf("delete request failed: %v", err)
	}
	if deleteResp.StatusCode != 200 {
		t.Fatalf("expected delete 200, got %d", deleteResp.StatusCode)
	}
}
