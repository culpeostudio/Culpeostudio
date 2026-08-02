package philobot

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type fakePermissionAsker struct {
	decisions []string
	calls     int
}

func (f *fakePermissionAsker) Ask(_ context.Context, _ permissionRequest) string {
	f.calls++
	if f.calls > len(f.decisions) {
		return permissionDeny
	}
	return f.decisions[f.calls-1]
}

func newTestExecutor(t *testing.T) (*fileToolExecutor, string) {
	t.Helper()
	root := t.TempDir()
	exec, err := newFileToolExecutor([]string{root})
	if err != nil {
		t.Fatalf("newFileToolExecutor: %v", err)
	}
	return exec, root
}

func newPermissionTestSetup(t *testing.T, decisions ...string) (*fileToolExecutor, *fakePermissionAsker, string) {
	t.Helper()
	root := t.TempDir()
	outsideDir := t.TempDir()
	if err := os.WriteFile(filepath.Join(outsideDir, "a.txt"), []byte("datei a"), 0o644); err != nil {
		t.Fatalf("setup outside file a: %v", err)
	}
	if err := os.WriteFile(filepath.Join(outsideDir, "b.txt"), []byte("datei b"), 0o644); err != nil {
		t.Fatalf("setup outside file b: %v", err)
	}
	asker := &fakePermissionAsker{decisions: decisions}
	exec, err := newFileToolExecutorWithPermissions(context.Background(), []string{root}, asker, nil, "sess-1")
	if err != nil {
		t.Fatalf("newFileToolExecutorWithPermissions: %v", err)
	}
	return exec, asker, outsideDir
}

func mustOK(t *testing.T, result map[string]interface{}, context string) {
	t.Helper()
	if ok, _ := result["ok"].(bool); !ok {
		t.Fatalf("%s sollte erfolgreich sein, bekam: %v", context, result)
	}
}

func mustFail(t *testing.T, result map[string]interface{}, context string) {
	t.Helper()
	if ok, _ := result["ok"].(bool); ok {
		t.Fatalf("%s sollte fehlschlagen, bekam: %v", context, result)
	}
}

func TestFileToolExecutorReadWritePatch(t *testing.T) {
	exec, root := newTestExecutor(t)

	mustOK(t, exec.Execute("write_file", map[string]interface{}{
		"path": "notes.txt", "content": "hallo welt",
	}), "write_file")

	onDisk, err := os.ReadFile(filepath.Join(root, "notes.txt"))
	if err != nil {
		t.Fatalf("Datei sollte im Root liegen: %v", err)
	}
	if string(onDisk) != "hallo welt" {
		t.Fatalf("unerwarteter Inhalt: %q", string(onDisk))
	}

	readResult := exec.Execute("read_file", map[string]interface{}{"path": "notes.txt"})
	mustOK(t, readResult, "read_file")
	if content, _ := readResult["content"].(string); content != "hallo welt" {
		t.Fatalf("read_file lieferte falschen Inhalt: %q", content)
	}

	patchResult := exec.Execute("patch_file", map[string]interface{}{
		"path": "notes.txt", "old_text": "welt", "new_text": "projekt",
	})
	mustOK(t, patchResult, "patch_file")

	if _, hasWarning := patchResult["warning"]; hasWarning {
		t.Fatalf("keine Warnung erwartet nach vorherigem read_file: %v", patchResult)
	}
	patched, _ := os.ReadFile(filepath.Join(root, "notes.txt"))
	if string(patched) != "hallo projekt" {
		t.Fatalf("patch_file nicht angewandt: %q", string(patched))
	}
}

func TestFileToolExecutorBlocksTraversal(t *testing.T) {
	exec, root := newTestExecutor(t)

	outside := filepath.Join(filepath.Dir(root), "geheim.txt")
	if err := os.WriteFile(outside, []byte("streng geheim"), 0o644); err != nil {
		t.Fatalf("setup outside file: %v", err)
	}
	t.Cleanup(func() { _ = os.Remove(outside) })

	relResult := exec.Execute("read_file", map[string]interface{}{"path": "../geheim.txt"})
	mustFail(t, relResult, "read_file mit ..-Traversal")
	if errText, _ := relResult["error"].(string); !strings.Contains(errText, "ausserhalb") {
		t.Fatalf("erwartete Sandbox-Fehler, bekam: %v", relResult)
	}

	absResult := exec.Execute("read_file", map[string]interface{}{"path": outside})
	mustFail(t, absResult, "read_file mit absolutem Pfad ausserhalb")

	writeResult := exec.Execute("write_file", map[string]interface{}{
		"path": outside, "content": "ueberschrieben",
	})
	mustFail(t, writeResult, "write_file ausserhalb")
	if content, _ := os.ReadFile(outside); string(content) != "streng geheim" {
		t.Fatalf("Datei ausserhalb wurde veraendert: %q", string(content))
	}
}

func TestFileToolExecutorValidatesArguments(t *testing.T) {
	exec, _ := newTestExecutor(t)

	result := exec.Execute("write_file", map[string]interface{}{"path": "x.txt"})
	mustFail(t, result, "write_file ohne content")
	if code, _ := result["error_code"].(string); code != "invalid_tool_arguments" {
		t.Fatalf("erwartete invalid_tool_arguments, bekam: %v", result)
	}
	if _, hasHint := result["hint"]; !hasHint {
		t.Fatalf("erwartete einen Hinweis fuer die Selbstkorrektur: %v", result)
	}

	unknown := exec.Execute("format_disk", map[string]interface{}{"path": "/"})
	mustFail(t, unknown, "unbekanntes Tool")
}

func TestFileToolExecutorPermissionDeny(t *testing.T) {
	exec, asker, outsideDir := newPermissionTestSetup(t, permissionDeny)

	result := exec.Execute("read_file", map[string]interface{}{
		"path": filepath.Join(outsideDir, "a.txt"),
	})
	mustFail(t, result, "read_file ausserhalb mit deny")
	if code, _ := result["error_code"].(string); code != "permission_denied" {
		t.Fatalf("erwartete permission_denied, bekam: %v", result)
	}
	if asker.calls != 1 {
		t.Fatalf("Asker sollte genau einmal gefragt werden, war %d", asker.calls)
	}
}

func TestFileToolExecutorPermissionOnce(t *testing.T) {
	exec, asker, outsideDir := newPermissionTestSetup(t, permissionOnce)

	result := exec.Execute("read_file", map[string]interface{}{
		"path": filepath.Join(outsideDir, "a.txt"),
	})
	mustOK(t, result, "read_file ausserhalb mit once")
	if content, _ := result["content"].(string); content != "datei a" {
		t.Fatalf("falscher Inhalt: %q", content)
	}

	second := exec.Execute("read_file", map[string]interface{}{
		"path": filepath.Join(outsideDir, "a.txt"),
	})
	mustFail(t, second, "zweiter read_file muss erneut fragen")
	if asker.calls != 2 {
		t.Fatalf("Asker sollte zweimal gefragt worden sein, war %d", asker.calls)
	}
}

func TestFileToolExecutorPermissionSession(t *testing.T) {
	exec, asker, outsideDir := newPermissionTestSetup(t, permissionSession)

	first := exec.Execute("read_file", map[string]interface{}{
		"path": filepath.Join(outsideDir, "a.txt"),
	})
	mustOK(t, first, "read_file ausserhalb mit session")

	second := exec.Execute("read_file", map[string]interface{}{
		"path": filepath.Join(outsideDir, "b.txt"),
	})
	mustOK(t, second, "read_file im freigegebenen Ordner ohne Nachfrage")
	if content, _ := second["content"].(string); content != "datei b" {
		t.Fatalf("falscher Inhalt: %q", content)
	}
	if asker.calls != 1 {
		t.Fatalf("Asker sollte nur einmal gefragt worden sein, war %d", asker.calls)
	}
}

func TestFileToolExecutorPermissionEvents(t *testing.T) {
	root := t.TempDir()
	outsideDir := t.TempDir()
	outsideFile := filepath.Join(outsideDir, "a.txt")
	if err := os.WriteFile(outsideFile, []byte("x"), 0o644); err != nil {
		t.Fatalf("setup outside file: %v", err)
	}
	asker := &fakePermissionAsker{decisions: []string{permissionOnce}}
	type event struct {
		typ  string
		data map[string]interface{}
	}
	var events []event
	exec, err := newFileToolExecutorWithPermissions(
		context.Background(), []string{root}, asker,
		func(eventType string, data interface{}) error {
			if m, ok := data.(map[string]interface{}); ok {
				events = append(events, event{typ: eventType, data: m})
			}
			return nil
		},
		"sess-42",
	)
	if err != nil {
		t.Fatalf("newFileToolExecutorWithPermissions: %v", err)
	}

	exec.Execute("read_file", map[string]interface{}{"path": outsideFile})
	if len(events) != 2 || events[0].typ != "permission_request" || events[1].typ != "permission_result" {
		t.Fatalf("erwartete permission_request + permission_result, bekam: %v", events)
	}
	if sid, _ := events[0].data["session_id"].(string); sid != "sess-42" {
		t.Fatalf("session_id fehlt im permission_request: %v", events[0].data)
	}
	if decision, _ := events[1].data["decision"].(string); decision != permissionOnce {
		t.Fatalf("falsche decision im permission_result: %v", events[1].data)
	}
}

func TestPermissionBrokerLifecycle(t *testing.T) {
	broker := newPermissionBroker()

	result := make(chan string, 1)
	go func() {
		result <- broker.Ask(context.Background(), permissionRequest{ID: "req-1", Tool: "read_file", Path: "/tmp/x"})
	}()
	if broker.Respond("unbekannt", permissionOnce) {
		t.Fatalf("Respond auf unbekannte ID darf nicht true liefern")
	}
	if broker.Respond("req-1", "muell") {
		t.Fatalf("Respond mit ungueltiger Entscheidung darf nicht true liefern")
	}

	answered := false
	for i := 0; i < 200 && !answered; i++ {
		answered = broker.Respond("req-1", permissionSession)
		if !answered {
			time.Sleep(5 * time.Millisecond)
		}
	}
	if !answered {
		t.Fatalf("Respond auf wartende Anfrage sollte true liefern")
	}
	if got := <-result; got != permissionSession {
		t.Fatalf("Ask lieferte %q statt %q", got, permissionSession)
	}

	broker.Close()
	if got := broker.Ask(context.Background(), permissionRequest{ID: "req-2"}); got != permissionDeny {
		t.Fatalf("Ask nach Close sollte deny liefern, bekam %q", got)
	}
	if broker.Respond("req-2", permissionOnce) {
		t.Fatalf("Respond nach Close darf nicht true liefern")
	}
}
