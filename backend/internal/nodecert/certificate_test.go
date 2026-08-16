package nodecert

import (
	"os"
	"path/filepath"
	"testing"
)

func TestEnsureCreatesPersistentRestrictedCertificate(t *testing.T) {
	directory := t.TempDir()
	first, err := Ensure(directory)
	if err != nil {
		t.Fatalf("Ensure: %v", err)
	}
	if len(first.Fingerprint) != 64 {
		t.Fatalf("fingerprint = %q", first.Fingerprint)
	}
	for _, path := range []string{first.CertificatePath, first.PrivateKeyPath} {
		info, statErr := os.Stat(path)
		if statErr != nil {
			t.Fatalf("stat %s: %v", path, statErr)
		}
		if info.Mode().Perm() != 0o600 {
			t.Errorf("mode for %s = %o, want 600", path, info.Mode().Perm())
		}
	}
	second, err := Ensure(directory)
	if err != nil {
		t.Fatalf("second Ensure: %v", err)
	}
	if second.Fingerprint != first.Fingerprint {
		t.Errorf("fingerprint changed from %s to %s", first.Fingerprint, second.Fingerprint)
	}
}

func TestEnsureRejectsPartialCredentials(t *testing.T) {
	directory := t.TempDir()
	tlsDir := filepath.Join(directory, "tls")
	if err := os.MkdirAll(tlsDir, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(tlsDir, certificateName), []byte("partial"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := Ensure(directory); err == nil {
		t.Fatal("Ensure accepted a partial credential set")
	}
}
