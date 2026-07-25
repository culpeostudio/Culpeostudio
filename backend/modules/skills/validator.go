package skills

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
)

var skillNamePattern = regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`)

type validationResult struct {
	Frontmatter SkillFrontmatter
	Body        string
	Summary     FileSummary
}

func validateSkillDir(path string) (validationResult, error) {
	trimmedPath := strings.TrimSpace(path)
	if trimmedPath == "" {
		return validationResult{}, errors.New("Skill-Pfad fehlt")
	}
	cleanPath := filepath.Clean(trimmedPath)
	info, err := os.Stat(cleanPath)
	if err != nil {
		return validationResult{}, fmt.Errorf("Skill-Ordner lesen: %w", err)
	}
	if !info.IsDir() {
		return validationResult{}, errors.New("Skill-Pfad muss ein Ordner sein")
	}

	frontmatter, body, err := parseSkillFile(filepath.Join(cleanPath, requiredSkillFileName))
	if err != nil {
		return validationResult{}, err
	}
	if err := validateFrontmatter(frontmatter, body); err != nil {
		return validationResult{}, err
	}

	summary, err := summarizeFiles(cleanPath)
	if err != nil {
		return validationResult{}, err
	}

	return validationResult{
		Frontmatter: frontmatter,
		Body:        body,
		Summary:     summary,
	}, nil
}

func parseSkillFile(path string) (SkillFrontmatter, string, error) {
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return SkillFrontmatter{}, "", errors.New("SKILL.md fehlt")
	}
	if err != nil {
		return SkillFrontmatter{}, "", fmt.Errorf("SKILL.md lesen: %w", err)
	}

	content := strings.ReplaceAll(string(data), "\r\n", "\n")
	content = strings.ReplaceAll(content, "\r", "\n")
	if !strings.HasPrefix(content, "---\n") {
		return SkillFrontmatter{}, "", errors.New("YAML-Frontmatter fehlt")
	}

	end := strings.Index(content[len("---\n"):], "\n---\n")
	if end < 0 {
		return SkillFrontmatter{}, "", errors.New("YAML-Frontmatter ist nicht geschlossen")
	}
	yamlText := content[len("---\n") : len("---\n")+end]
	body := content[len("---\n")+end+len("\n---\n"):]

	var frontmatter SkillFrontmatter
	if err := yaml.Unmarshal([]byte(yamlText), &frontmatter); err != nil {
		return SkillFrontmatter{}, "", fmt.Errorf("YAML-Frontmatter ist ungueltig: %w", err)
	}
	return frontmatter, body, nil
}

func validateFrontmatter(frontmatter SkillFrontmatter, body string) error {
	var problems []string
	name := strings.TrimSpace(frontmatter.Name)
	description := strings.TrimSpace(frontmatter.Description)
	compatibility := strings.TrimSpace(frontmatter.Compatibility)

	if name == "" {
		problems = append(problems, "name fehlt")
	} else {
		if len(name) > maxSkillNameLength {
			problems = append(problems, "name ist laenger als 64 Zeichen")
		}
		if !skillNamePattern.MatchString(name) {
			problems = append(problems, "name darf nur lowercase letters, Zahlen und einzelne Bindestriche enthalten")
		}
	}
	if description == "" {
		problems = append(problems, "description fehlt")
	} else if len(description) > maxDescriptionLength {
		problems = append(problems, "description ist laenger als 1024 Zeichen")
	}
	if compatibility != "" && len(compatibility) > maxCompatibilityLength {
		problems = append(problems, "compatibility ist laenger als 500 Zeichen")
	}
	if strings.TrimSpace(body) == "" {
		problems = append(problems, "Markdown-Inhalt nach Frontmatter fehlt")
	}

	if len(problems) > 0 {
		return errors.New(strings.Join(problems, "; "))
	}
	return nil
}

func summarizeFiles(root string) (FileSummary, error) {
	var summary FileSummary
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if path == root {
			return nil
		}
		rel, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		firstPart := rel
		if idx := strings.IndexRune(rel, filepath.Separator); idx >= 0 {
			firstPart = rel[:idx]
		}
		switch firstPart {
		case "scripts":
			summary.HasScripts = true
		case "references":
			summary.HasReferences = true
		case "assets":
			summary.HasAssets = true
		}
		if entry.IsDir() {
			summary.DirectoryCount++
			return nil
		}
		summary.FileCount++
		return nil
	})
	return summary, err
}
