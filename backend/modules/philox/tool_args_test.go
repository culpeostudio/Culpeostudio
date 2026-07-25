package philox

import "testing"

func TestNormalizeToolArgumentsRepairsWrappedAndDuplicatedJSON(t *testing.T) {
	tests := []struct {
		name string
		raw  string
	}{
		{
			name: "quoted json object",
			raw:  "\"{\\\"path\\\":\\\"C:\\\\\\\\repo\\\\\\\\file.txt\\\"}\"",
		},
		{
			name: "prefixed and duplicated json",
			raw:  "json {\"path\":\"C:\\\\repo\\\\file.txt\"}{\"path\":\"C:\\\\repo\\\\file.txt\"}",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			normalized, parsed, err := normalizeToolArguments(test.raw)
			if err != nil {
				t.Fatalf("expected repair to succeed, got %v", err)
			}
			if normalized == "" {
				t.Fatalf("expected normalized JSON")
			}
			if parsed["path"] != `C:\repo\file.txt` {
				t.Fatalf("unexpected parsed path: %#v", parsed["path"])
			}
		})
	}
}

func TestNormalizeToolArgumentsRepairsWindowsPathAndEOF(t *testing.T) {
	tests := []struct {
		name         string
		raw          string
		expectedPath string
	}{
		{
			name:         "windows path without escaped backslashes",
			raw:          `{"path":"C:\Users\david\Music\login.html","content":"ok"}`,
			expectedPath: `C:\Users\david\Music\login.html`,
		},
		{
			name:         "unexpected eof object gets closed",
			raw:          `{"path":"C:\\repo\\file.txt","content":"abc"`,
			expectedPath: `C:\repo\file.txt`,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			normalized, parsed, err := normalizeToolArguments(test.raw)
			if err != nil {
				t.Fatalf("expected repair to succeed, got %v", err)
			}
			if normalized == "" {
				t.Fatalf("expected normalized JSON")
			}
			if parsed["path"] != test.expectedPath {
				t.Fatalf("unexpected parsed path: %#v", parsed["path"])
			}
		})
	}
}

func TestValidateToolArguments(t *testing.T) {
	if err := validateToolArguments("write_file", map[string]interface{}{
		"path":    `C:\tmp\file.txt`,
		"content": "",
	}); err != nil {
		t.Fatalf("expected empty content to be allowed for explicit truncation, got %v", err)
	}

	if err := validateToolArguments("write_file", map[string]interface{}{
		"path": `C:\tmp\file.txt`,
	}); err == nil {
		t.Fatalf("expected missing content to fail validation")
	}

	if err := validateToolArguments("patch_file", map[string]interface{}{
		"path":     `C:\tmp\file.txt`,
		"old_text": "A",
		"new_text": "B",
	}); err != nil {
		t.Fatalf("expected patch_file args to validate, got %v", err)
	}
}
