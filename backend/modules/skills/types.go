package skills

import "time"

const (
	defaultSkillsDir       = "data/skills"
	registryFileName       = "registry.json"
	requiredSkillFileName  = "SKILL.md"
	maxSkillNameLength     = 64
	maxDescriptionLength   = 1024
	maxCompatibilityLength = 500
)

type SkillFrontmatter struct {
	Name          string                 `yaml:"name" json:"name"`
	Description   string                 `yaml:"description" json:"description"`
	License       string                 `yaml:"license,omitempty" json:"license,omitempty"`
	Compatibility string                 `yaml:"compatibility,omitempty" json:"compatibility,omitempty"`
	Metadata      map[string]interface{} `yaml:"metadata,omitempty" json:"metadata,omitempty"`
	AllowedTools  string                 `yaml:"allowed-tools,omitempty" json:"allowed_tools,omitempty"`
}

type FileSummary struct {
	FileCount      int  `json:"file_count"`
	DirectoryCount int  `json:"directory_count"`
	HasScripts     bool `json:"has_scripts"`
	HasReferences  bool `json:"has_references"`
	HasAssets      bool `json:"has_assets"`
}

type SkillRecord struct {
	Name          string                 `json:"name"`
	Description   string                 `json:"description"`
	Enabled       bool                   `json:"enabled"`
	Path          string                 `json:"path"`
	ImportedAt    time.Time              `json:"imported_at"`
	UpdatedAt     time.Time              `json:"updated_at"`
	License       string                 `json:"license,omitempty"`
	Compatibility string                 `json:"compatibility,omitempty"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	AllowedTools  string                 `json:"allowed_tools,omitempty"`
	Valid         bool                   `json:"valid"`
	Errors        []string               `json:"errors,omitempty"`
	FileSummary   FileSummary            `json:"file_summary"`
}

type registryFile struct {
	Skills []SkillRecord `json:"skills"`
}
