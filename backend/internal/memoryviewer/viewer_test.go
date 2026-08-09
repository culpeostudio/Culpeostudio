package memoryviewer

import (
	"regexp"
	"strings"
	"testing"
)

func TestPageRendersWithoutFormatArtifacts(t *testing.T) {
	page := Page("Memory Viewer")
	if strings.Contains(page, "%!") {
		t.Fatalf("rendered page contains fmt artifacts (unescaped %% in template?)")
	}
	if !strings.Contains(page, "<title>Memory Viewer</title>") {
		t.Fatalf("title was not injected")
	}
}

func TestPageDoesNotConcatenateIntoInnerHTML(t *testing.T) {
	page := Page("t")
	assignments := regexp.MustCompile(`\.innerHTML\s*=\s*([^;\n]+)`).FindAllStringSubmatch(page, -1)
	if len(assignments) == 0 {
		return
	}
	for _, match := range assignments {
		value := strings.TrimSpace(match[1])
		if value != `""` {
			t.Fatalf("innerHTML must only be assigned an empty string, found: %s", match[0])
		}
	}
}
