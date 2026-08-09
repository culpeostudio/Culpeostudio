package tools

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func newSearchTestExecutor(t *testing.T) (*Executor, string) {
	t.Helper()
	root := t.TempDir()
	exec, err := newExecutor([]string{root})
	if err != nil {
		t.Fatalf("newExecutor: %v", err)
	}
	write := func(rel, content string) {
		t.Helper()
		full := filepath.Join(root, rel)
		if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
			t.Fatalf("mkdir: %v", err)
		}
		if err := os.WriteFile(full, []byte(content), 0o644); err != nil {
			t.Fatalf("write %s: %v", rel, err)
		}
	}
	write("main.go", "package main\n\nfunc handleRequest() {}\n")
	write("lib/util.dart", "String formatError(String code) => code;\n")
	write("node_modules/pkg/index.js", "func handleRequest() {}\n")
	write("bin.dat", "a\x00b\x00c")
	return exec, root
}

func TestGrepSearchFindsLiteral(t *testing.T) {
	exec, _ := newSearchTestExecutor(t)

	result := exec.Execute("grep_search", map[string]interface{}{"pattern": "handleRequest"})
	mustOK(t, result, "grep_search literal")
	matches, _ := result["matches"].([]map[string]interface{})

	if len(matches) != 1 {
		t.Fatalf("erwartete genau 1 Treffer (Skip-Liste), bekam: %v", result)
	}
	if !strings.HasSuffix(matches[0]["path"].(string), "main.go") {
		t.Fatalf("falscher Trefferpfad: %v", matches[0])
	}
	if matches[0]["line"].(int) != 3 {
		t.Fatalf("falsche Zeilennummer: %v", matches[0])
	}
}

func TestGrepSearchGlobAndRegex(t *testing.T) {
	exec, _ := newSearchTestExecutor(t)

	globbed := exec.Execute("grep_search", map[string]interface{}{
		"pattern": "formatError", "glob": "*.dart",
	})
	mustOK(t, globbed, "grep_search mit glob")
	matches, _ := globbed["matches"].([]map[string]interface{})
	if len(matches) != 1 {
		t.Fatalf("glob sollte auf dart-Dateien begrenzen: %v", globbed)
	}

	regex := exec.Execute("grep_search", map[string]interface{}{
		"pattern": "func handle.*\\(\\)", "is_regex": true,
	})
	mustOK(t, regex, "grep_search mit regex")
	matches, _ = regex["matches"].([]map[string]interface{})
	if len(matches) != 1 {
		t.Fatalf("regex-Treffer erwartet: %v", regex)
	}

	broken := exec.Execute("grep_search", map[string]interface{}{
		"pattern": "([", "is_regex": true,
	})
	mustFail(t, broken, "ungueltiger Regex muss Tool-Fehler sein")
}

func TestGrepSearchRespectsSandbox(t *testing.T) {
	exec, root := newSearchTestExecutor(t)
	outside := filepath.Join(filepath.Dir(root), "geheim.txt")
	if err := os.WriteFile(outside, []byte("handleRequest"), 0o644); err != nil {
		t.Fatalf("setup outside: %v", err)
	}
	t.Cleanup(func() { _ = os.Remove(outside) })

	result := exec.Execute("grep_search", map[string]interface{}{
		"pattern": "handleRequest", "path": outside,
	})
	mustFail(t, result, "grep_search ausserhalb der Roots")
}

func TestFindFilesPatterns(t *testing.T) {
	exec, _ := newSearchTestExecutor(t)

	result := exec.Execute("find_files", map[string]interface{}{"pattern": "*.dart"})
	mustOK(t, result, "find_files *.dart")
	files, _ := result["files"].([]string)
	if len(files) != 1 || files[0] != filepath.Join("lib", "util.dart") {
		t.Fatalf("unerwartete Treffer: %v", files)
	}

	deep := exec.Execute("find_files", map[string]interface{}{"pattern": "**/*.go"})
	mustOK(t, deep, "find_files **/*.go")
	files, _ = deep["files"].([]string)
	if len(files) != 1 || files[0] != "main.go" {
		t.Fatalf("** sollte beliebige Tiefe matchen: %v", files)
	}

	all := exec.Execute("find_files", map[string]interface{}{"pattern": "*"})
	mustOK(t, all, "find_files *")
	files, _ = all["files"].([]string)

	for _, f := range files {
		if strings.Contains(f, "node_modules") {
			t.Fatalf("Skip-Liste verletzt: %v", files)
		}
	}
}

func TestBuildDirTree(t *testing.T) {
	exec, root := newSearchTestExecutor(t)
	_ = exec

	tree, truncated := BuildDirTree(root)
	if truncated {
		t.Fatalf("kleiner Baum darf nicht abgeschnitten werden")
	}
	if tree == nil || !tree.IsDir || len(tree.Children) == 0 {
		t.Fatalf("Baum sollte Wurzel mit Kindern haben: %+v", tree)
	}
	for _, child := range tree.Children {
		if child.Name == "node_modules" {
			t.Fatalf("node_modules darf nicht im Baum sein")
		}
	}
}
