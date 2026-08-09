package skills

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeSkillFile(t *testing.T, dir string, content string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("mkdir skill dir: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, requiredSkillFileName), []byte(content), 0o600); err != nil {
		t.Fatalf("write skill file: %v", err)
	}
}

func TestValidateSkillDirAcceptsMinimalSkill(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "writer")
	writeSkillFile(t, dir, `---
name: writer
description: Helps with concise writing tasks.
---

# Writer

Follow the user's writing brief.
`)

	result, err := validateSkillDir(dir)
	if err != nil {
		t.Fatalf("validateSkillDir failed: %v", err)
	}
	if result.Frontmatter.Name != "writer" {
		t.Fatalf("expected skill name writer, got %q", result.Frontmatter.Name)
	}
	if result.Summary.FileCount != 1 {
		t.Fatalf("expected one file, got %d", result.Summary.FileCount)
	}
}

func TestValidateSkillDirRejectsInvalidSkills(t *testing.T) {
	longDescription := strings.Repeat("a", maxDescriptionLength+1)
	cases := []struct {
		name    string
		content string
		want    string
	}{
		{
			name:    "missing-frontmatter",
			content: "# Missing\n",
			want:    "YAML-Frontmatter fehlt",
		},
		{
			name: "invalid-name",
			content: `---
name: Bad--Name
description: Has a bad name.
---
Body
`,
			want: "name darf nur",
		},
		{
			name: "missing-description",
			content: `---
name: missing-description
---
Body
`,
			want: "description fehlt",
		},
		{
			name: "long-description",
			content: `---
name: long-description
description: ` + longDescription + `
---
Body
`,
			want: "description ist laenger",
		},
		{
			name: "empty-body",
			content: `---
name: empty-body
description: Body is missing.
---
`,
			want: "Markdown-Inhalt",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			dir := filepath.Join(t.TempDir(), tc.name)
			writeSkillFile(t, dir, tc.content)
			_, err := validateSkillDir(dir)
			if err == nil {
				t.Fatalf("expected validation error")
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("expected error containing %q, got %q", tc.want, err.Error())
			}
		})
	}
}

func TestValidateSkillDirRejectsMissingSkillFile(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "empty")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("mkdir skill dir: %v", err)
	}
	_, err := validateSkillDir(dir)
	if err == nil || !strings.Contains(err.Error(), "SKILL.md fehlt") {
		t.Fatalf("expected missing SKILL.md error, got %v", err)
	}
}
