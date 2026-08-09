package config

import "testing"

func TestLoadReadsUserPreferencesFile(t *testing.T) {
	t.Setenv("JWT_SECRET", "test-jwt-secret")
	t.Setenv("MEMORY_API_TOKEN", "test-memory-token")
	t.Setenv("USER_PREFERENCES_FILE", "testdata/user_preferences.json")

	loaded := Load()
	if loaded.UserPreferencesFile != "testdata/user_preferences.json" {
		t.Fatalf("UserPreferencesFile = %q, want configured path", loaded.UserPreferencesFile)
	}
}
