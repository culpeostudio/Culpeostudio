package config

import (
	"path/filepath"
	"testing"
)

func TestLoadReadsUserPreferencesFile(t *testing.T) {
	t.Setenv("JWT_SECRET", "test-jwt-secret")
	t.Setenv("PROVIDER_ENCRYPTION_SECRET", "test-provider-encryption-secret")
	t.Setenv("MEMORY_API_TOKEN", "test-memory-token")
	t.Setenv("USER_PREFERENCES_FILE", "testdata/user_preferences.json")

	loaded := Load()
	if loaded.UserPreferencesFile != "testdata/user_preferences.json" {
		t.Fatalf("UserPreferencesFile = %q, want configured path", loaded.UserPreferencesFile)
	}
}

func TestLoadUsesDedicatedProviderEncryptionSecret(t *testing.T) {
	t.Setenv("MEMORY_DATA_DIR", filepath.Join(t.TempDir(), "data"))
	t.Setenv("JWT_SECRET", "rotated-jwt-secret")
	t.Setenv("PROVIDER_ENCRYPTION_SECRET", "stable-provider-encryption-secret")
	t.Setenv("MEMORY_API_TOKEN", "test-memory-token")

	loaded := Load()
	if loaded.ProviderEncryptionSecret != "stable-provider-encryption-secret" {
		t.Fatalf("ProviderEncryptionSecret = %q, want configured dedicated secret", loaded.ProviderEncryptionSecret)
	}
	if loaded.ProviderEncryptionSecret == loaded.JWTSecret {
		t.Fatal("ProviderEncryptionSecret must not reuse JWTSecret")
	}
}

func TestProviderEncryptionSecretSurvivesJWTRotation(t *testing.T) {
	t.Setenv("MEMORY_DATA_DIR", filepath.Join(t.TempDir(), "data"))
	t.Setenv("MEMORY_API_TOKEN", "test-memory-token")
	t.Setenv("PROVIDER_ENCRYPTION_SECRET", "")
	t.Setenv("JWT_SECRET", "first-jwt-secret")

	first := Load().ProviderEncryptionSecret
	if first == "" {
		t.Fatal("ProviderEncryptionSecret must be generated when unset")
	}

	t.Setenv("JWT_SECRET", "rotated-jwt-secret")
	second := Load().ProviderEncryptionSecret
	if second != first {
		t.Fatalf("ProviderEncryptionSecret changed after JWT rotation: got %q, want %q", second, first)
	}
}
