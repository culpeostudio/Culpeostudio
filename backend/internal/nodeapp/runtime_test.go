package nodeapp

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/culpeohq/backend/internal/nodeconnection"
)

func TestPairingLinkCreatesStableSecretMaterialWithoutStartingEngine(t *testing.T) {
	dataDir := t.TempDir()
	config := Config{
		DataDir:   dataDir,
		Listen:    "127.0.0.1:50051",
		Advertise: "node.example.test:50051",
		Name:      "Werkstatt",
	}
	first, err := PairingLink(config)
	if err != nil {
		t.Fatalf("PairingLink: %v", err)
	}
	second, err := PairingLink(config)
	if err != nil {
		t.Fatalf("second PairingLink: %v", err)
	}
	if first != second {
		t.Fatal("pairing link changed across an unchanged Node identity")
	}
	decoded, err := nodeconnection.Decode(first)
	if err != nil {
		t.Fatalf("Decode: %v", err)
	}
	if decoded.Endpoint != "node.example.test:50051" || decoded.Name != "Werkstatt" {
		t.Fatalf("unexpected link: %+v", decoded)
	}
	for _, path := range []string{
		filepath.Join(dataDir, "node_identity.json"),
		filepath.Join(dataDir, "tls", "node-cert.pem"),
		filepath.Join(dataDir, "tls", "node-key.pem"),
	} {
		if info, statErr := os.Stat(path); statErr != nil || info.Mode().Perm() != 0o600 {
			t.Fatalf("secret material %s has unsafe mode or is absent: info=%v err=%v", path, info, statErr)
		}
	}
}

func TestPrepareSettingsUsesNodeDirectoryByDefaultAndPreservesExplicitOne(t *testing.T) {
	dataDir := t.TempDir()
	config := Config{DataDir: dataDir, Listen: "127.0.0.1:50051", Advertise: "127.0.0.1:50051"}
	config, err := normalizeConfig(config)
	if err != nil {
		t.Fatal(err)
	}
	if err := prepareDataDir(config.DataDir); err != nil {
		t.Fatal(err)
	}
	if err := prepareSettings(config); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(dataDir, "models")); err != nil {
		t.Fatalf("default Node model directory not created: %v", err)
	}
}

func TestPrepareSettingsRejectsProtectedPersistedModelDirectory(t *testing.T) {
	dataDir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dataDir, "settings.json"), []byte(`{"model_dir":"/etc/ssh"}`), 0o600); err != nil {
		t.Fatalf("test settings write: %v", err)
	}
	config, err := normalizeConfig(Config{
		DataDir:   dataDir,
		Listen:    "127.0.0.1:50051",
		Advertise: "127.0.0.1:50051",
	})
	if err != nil {
		t.Fatalf("normalize config: %v", err)
	}
	if err := prepareDataDir(config.DataDir); err != nil {
		t.Fatalf("prepare data dir: %v", err)
	}
	if err := prepareSettings(config); err == nil {
		t.Fatal("gespeicherter geschuetzter Modellordner wurde akzeptiert")
	}
}
