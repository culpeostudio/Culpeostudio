package nodeapp

import (
	"path/filepath"
	"testing"
)

func TestFromEnvUsesSmallDirectNodeContract(t *testing.T) {
	values := map[string]string{
		"CULPEO_NODE_DATA_DIR":  t.TempDir(),
		"CULPEO_NODE_MODEL_DIR": "models",
		"CULPEO_NODE_LISTEN":    "0.0.0.0:50051",
		"CULPEO_NODE_ADVERTISE": "node.example.test:50051",
		"CULPEO_NODE_NAME":      "Werkstatt",
		"CULPEO_NODE_VERSION":   "v0.1.0",
	}
	config, err := FromEnv(func(name string) string { return values[name] })
	if err != nil {
		t.Fatalf("FromEnv: %v", err)
	}
	if !config.ModelDirSet {
		t.Fatal("explicit model dir was not recorded")
	}
	if want := filepath.Join(config.DataDir, "models"); config.ModelDir != want {
		t.Fatalf("ModelDir = %q, want %q", config.ModelDir, want)
	}
	if config.Advertise != "node.example.test:50051" || config.Name != "Werkstatt" || config.Version != "v0.1.0" {
		t.Fatalf("unexpected config: %+v", config)
	}
}

func TestFromEnvRequiresReachableAdvertiseAddressForWildcardListen(t *testing.T) {
	_, err := FromEnv(func(name string) string {
		switch name {
		case "CULPEO_NODE_DATA_DIR":
			return t.TempDir()
		case "CULPEO_NODE_LISTEN":
			return "0.0.0.0:50051"
		default:
			return ""
		}
	})
	if err == nil {
		t.Fatal("wildcard listener without CULPEO_NODE_ADVERTISE was accepted")
	}
}

func TestFromEnvUsesConcreteListenAsDevelopmentAdvertiseDefault(t *testing.T) {
	config, err := FromEnv(func(name string) string {
		switch name {
		case "CULPEO_NODE_DATA_DIR":
			return t.TempDir()
		case "CULPEO_NODE_LISTEN":
			return "127.0.0.1:50051"
		default:
			return ""
		}
	})
	if err != nil {
		t.Fatalf("FromEnv: %v", err)
	}
	if config.Advertise != "127.0.0.1:50051" {
		t.Fatalf("Advertise = %q", config.Advertise)
	}
}

func TestFromEnvRejectsProtectedSystemDirectories(t *testing.T) {
	for _, directory := range []string{
		"/", "/etc", "/etc/ssh", "/usr", "/usr/local", "/var", "/var/lib", "/tmp", "/run/culpeo-node", "/root/.culpeo-node",
	} {
		t.Run(directory, func(t *testing.T) {
			_, err := FromEnv(func(name string) string {
				switch name {
				case "CULPEO_NODE_DATA_DIR":
					return directory
				case "CULPEO_NODE_LISTEN":
					return "127.0.0.1:50051"
				default:
					return ""
				}
			})
			if err == nil {
				t.Fatalf("geschuetzter Ordner %q wurde akzeptiert", directory)
			}
		})
	}
}

func TestFromEnvRejectsProtectedModelDirectory(t *testing.T) {
	_, err := FromEnv(func(name string) string {
		switch name {
		case "CULPEO_NODE_DATA_DIR":
			return t.TempDir()
		case "CULPEO_NODE_MODEL_DIR":
			return "/etc/ssh/models"
		case "CULPEO_NODE_LISTEN":
			return "127.0.0.1:50051"
		default:
			return ""
		}
	})
	if err == nil {
		t.Fatal("geschuetzter Modellordner wurde akzeptiert")
	}
}
