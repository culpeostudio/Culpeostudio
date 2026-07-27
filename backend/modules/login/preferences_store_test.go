package login

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"sync"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"

	"github.com/fillyengine/backend/internal/middleware"
)

func newAuthenticatedUserPreferencesApp(t *testing.T) (*fiber.App, string) {
	t.Helper()

	dir := t.TempDir()
	accountsPath := filepath.Join(dir, "login_accounts.json")
	accounts := NewAccountStore(accountsPath)
	if err := accounts.Load(); err != nil {
		t.Fatal(err)
	}
	if err := accounts.CreateUser("Alice!", "start123"); err != nil {
		t.Fatal(err)
	}

	preferencesPath := filepath.Join(dir, "user_preferences.json")
	module := New(
		"test-secret",
		accountsPath,
		filepath.Join(dir, "login_authenticator.json"),
		preferencesPath,
	)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}

	app := fiber.New()
	app.Use(middleware.AuthMiddleware("test-secret", module.UserExists))
	module.RegisterRoutes(app.Group("/api"))
	return app, preferencesPath
}

func testUserPreferencesToken(t *testing.T, userID string) string {
	t.Helper()
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  userID,
		"username": userID,
	})
	serialized, err := token.SignedString([]byte("test-secret"))
	if err != nil {
		t.Fatal(err)
	}
	return serialized
}

func performUserPreferencesRequest(t *testing.T, app *fiber.App, method string, body any, token string) *http.Response {
	t.Helper()

	var payload bytes.Buffer
	if body != nil {
		if err := json.NewEncoder(&payload).Encode(body); err != nil {
			t.Fatal(err)
		}
	}
	request := httptest.NewRequest(method, "/api/user/preferences", &payload)
	request.Header.Set("Content-Type", "application/json")
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	response, err := app.Test(request, -1)
	if err != nil {
		t.Fatal(err)
	}
	return response
}

func TestUserPreferencesAPIRequiresAuthenticationAndPersistsCompleteProfile(t *testing.T) {
	app, preferencesPath := newAuthenticatedUserPreferencesApp(t)

	unauthenticated := performUserPreferencesRequest(t, app, http.MethodGet, nil, "")
	if unauthenticated.StatusCode != http.StatusUnauthorized {
		t.Fatalf("unauthenticated GET status = %d, want %d", unauthenticated.StatusCode, http.StatusUnauthorized)
	}
	_ = unauthenticated.Body.Close()

	token := testUserPreferencesToken(t, "ALICE!")
	initial := performUserPreferencesRequest(t, app, http.MethodGet, nil, token)
	if initial.StatusCode != http.StatusOK {
		t.Fatalf("initial GET status = %d, want %d", initial.StatusCode, http.StatusOK)
	}
	initialBody := decodeJSON(t, initial)
	if initialBody["configured"] != false || initialBody["language"] != "de" || initialBody["frontend_version"] != "classic" {
		t.Fatalf("initial profile = %#v, want unconfigured German Classic defaults", initialBody)
	}

	missingField := performUserPreferencesRequest(t, app, http.MethodPut, map[string]string{
		"language": "en",
	}, token)
	if missingField.StatusCode != http.StatusBadRequest {
		t.Fatalf("missing field PUT status = %d, want %d", missingField.StatusCode, http.StatusBadRequest)
	}
	_ = missingField.Body.Close()

	invalid := performUserPreferencesRequest(t, app, http.MethodPut, map[string]string{
		"language": "fr", "frontend_version": "lite",
	}, token)
	if invalid.StatusCode != http.StatusBadRequest {
		t.Fatalf("invalid PUT status = %d, want %d", invalid.StatusCode, http.StatusBadRequest)
	}
	_ = invalid.Body.Close()

	stillUnconfigured := performUserPreferencesRequest(t, app, http.MethodGet, nil, token)
	stillUnconfiguredBody := decodeJSON(t, stillUnconfigured)
	if stillUnconfiguredBody["configured"] != false {
		t.Fatalf("invalid PUT unexpectedly configured profile: %#v", stillUnconfiguredBody)
	}

	updated := performUserPreferencesRequest(t, app, http.MethodPut, map[string]string{
		"language": " EN ", "frontend_version": "LITE",
	}, token)
	if updated.StatusCode != http.StatusOK {
		t.Fatalf("valid PUT status = %d, want %d", updated.StatusCode, http.StatusOK)
	}
	updatedBody := decodeJSON(t, updated)
	if updatedBody["configured"] != true || updatedBody["language"] != "en" || updatedBody["frontend_version"] != "lite" {
		t.Fatalf("updated profile = %#v, want configured English Lite", updatedBody)
	}

	info, err := os.Stat(preferencesPath)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("preferences mode = %o, want 600", info.Mode().Perm())
	}

	reloaded := NewUserPreferencesStore(preferencesPath)
	if err := reloaded.Load(); err != nil {
		t.Fatal(err)
	}
	persisted, configured := reloaded.Get("alice!")
	if !configured || persisted.Language != "en" || persisted.FrontendVersion != "lite" {
		t.Fatalf("reloaded preferences = %#v, configured=%v", persisted, configured)
	}
}

func TestUserPreferencesStoreSerializesConcurrentUpdates(t *testing.T) {
	path := filepath.Join(t.TempDir(), "user_preferences.json")
	store := NewUserPreferencesStore(path)
	if err := store.Load(); err != nil {
		t.Fatal(err)
	}

	const users = 32
	var wait sync.WaitGroup
	errors := make(chan error, users)
	for index := 0; index < users; index++ {
		wait.Add(1)
		go func(index int) {
			defer wait.Done()
			language := "de"
			version := "classic"
			if index%2 == 1 {
				language = "en"
				version = "lite"
			}
			_, err := store.Set(fmt.Sprintf("User-%d", index), language, version)
			errors <- err
		}(index)
	}
	wait.Wait()
	close(errors)
	for err := range errors {
		if err != nil {
			t.Fatal(err)
		}
	}

	reloaded := NewUserPreferencesStore(path)
	if err := reloaded.Load(); err != nil {
		t.Fatal(err)
	}
	for index := 0; index < users; index++ {
		preferences, configured := reloaded.Get(fmt.Sprintf("user-%d", index))
		if !configured {
			t.Fatalf("user-%d was not persisted", index)
		}
		if index%2 == 1 && (preferences.Language != "en" || preferences.FrontendVersion != "lite") {
			t.Fatalf("user-%d preferences = %#v, want English Lite", index, preferences)
		}
		if index%2 == 0 && (preferences.Language != "de" || preferences.FrontendVersion != "classic") {
			t.Fatalf("user-%d preferences = %#v, want German Classic", index, preferences)
		}
	}
}

func TestUserPreferencesStoreDoesNotMutateMemoryWhenAtomicWriteFails(t *testing.T) {
	store := NewUserPreferencesStore(t.TempDir())
	if _, err := store.Set("alice", "en", "lite"); err == nil {
		t.Fatal("expected write into directory path to fail")
	}
	preferences, configured := store.Get("alice")
	if configured || preferences != defaultUserPreferences() {
		t.Fatalf("failed write changed memory: %#v, configured=%v", preferences, configured)
	}
}
