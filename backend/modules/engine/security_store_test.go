package engine

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestEngineKeyPlaintextOnlyReturnedAtCreationAndScopeIsEnforced(t *testing.T) {
	store, err := newEngineKeyStore(filepath.Join(t.TempDir(), "keys.json"))
	if err != nil {
		t.Fatal(err)
	}
	public, plaintext, err := store.create("Test", []string{"instance-a"})
	if err != nil {
		t.Fatal(err)
	}
	if plaintext == "" || public.ID == "" {
		t.Fatal("expected one-time plaintext and public id")
	}
	if !store.authorize(plaintext, "instance-a") {
		t.Fatal("scoped key should authorize its instance")
	}
	if store.authorize(plaintext, "instance-b") {
		t.Fatal("scoped key must not authorize another instance")
	}
	data, err := os.ReadFile(store.path)
	if err != nil {
		t.Fatal(err)
	}
	if string(data) == "" || strings.Contains(string(data), plaintext) {
		t.Fatal("plaintext key must not be persisted")
	}
}

func TestRemoteCodeHashRejectsEscapingPythonSymlink(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("symlink creation commonly requires elevated Windows privileges")
	}
	root := t.TempDir()
	external := filepath.Join(t.TempDir(), "outside.py")
	if err := os.WriteFile(external, []byte("SECRET = 1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(external, filepath.Join(root, "modeling.py")); err != nil {
		t.Fatal(err)
	}
	if _, _, err := hashPythonFiles(root); err == nil {
		t.Fatal("escaping Python symlink was accepted")
	}
}

func TestRemoteCodeApprovalChangesWhenPythonChanges(t *testing.T) {
	root := t.TempDir()
	path := filepath.Join(root, "modeling_custom.py")
	if err := os.WriteFile(path, []byte("value = 1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	first, count, err := hashPythonFiles(root)
	if err != nil || count != 1 {
		t.Fatalf("hash: count=%d err=%v", count, err)
	}
	store, err := newRemoteCodeStore(filepath.Join(t.TempDir(), "trust.json"))
	if err != nil {
		t.Fatal(err)
	}
	if err := store.approve("fingerprint", first); err != nil {
		t.Fatal(err)
	}
	if !store.approved("fingerprint", first) {
		t.Fatal("approval should match unchanged code")
	}
	if err := os.WriteFile(path, []byte("value = 2\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	second, _, _ := hashPythonFiles(root)
	if first == second || store.approved("fingerprint", second) {
		t.Fatal("changed Python must require renewed approval")
	}
}
