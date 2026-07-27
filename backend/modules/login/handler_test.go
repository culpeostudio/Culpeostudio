package login

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/modules/philobot"
)

func newTestLoginApp(t *testing.T) (*fiber.App, *LoginModule) {
	t.Helper()

	dir := t.TempDir()
	module := New(
		"test-secret",
		filepath.Join(dir, "login_accounts.json"),
		filepath.Join(dir, "login_authenticator.json"),
		filepath.Join(dir, "user_preferences.json"),
	)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialize() error = %v", err)
	}

	app := fiber.New()
	api := app.Group("/api")
	module.RegisterRoutes(api)
	return app, module
}

func performJSONRequest(t *testing.T, app *fiber.App, method, path string, body any) *http.Response {
	t.Helper()

	var payload bytes.Buffer
	if body != nil {
		if err := json.NewEncoder(&payload).Encode(body); err != nil {
			t.Fatalf("json encode error = %v", err)
		}
	}

	req := httptest.NewRequest(method, path, &payload)
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req, -1)
	if err != nil {
		t.Fatalf("app.Test() error = %v", err)
	}
	return resp
}

func decodeJSON(t *testing.T, resp *http.Response) map[string]any {
	t.Helper()
	defer resp.Body.Close()

	var data map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		t.Fatalf("json decode error = %v", err)
	}
	return data
}

func configureTestAuthenticator(t *testing.T, module *LoginModule) string {
	t.Helper()
	secret := "JBSWY3DPEHPK3PXP"
	if err := module.authStore.SaveConfigured(secret, time.Now()); err != nil {
		t.Fatalf("SaveConfigured() error = %v", err)
	}
	return secret
}

func currentTOTPCode(t *testing.T, secret string) string {
	t.Helper()
	code, err := generateTOTPCode(secret, time.Now().Unix()/totpPeriod)
	if err != nil {
		t.Fatalf("generateTOTPCode() error = %v", err)
	}
	return code
}

func TestCreateAccountRejectsDuplicates(t *testing.T) {
	app, module := newTestLoginApp(t)
	secret := configureTestAuthenticator(t, module)

	createResp := performJSONRequest(t, app, http.MethodPost, "/api/accounts", map[string]string{
		"username":  "david",
		"password":  "start123",
		"totp_code": currentTOTPCode(t, secret),
	})
	if createResp.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d, want %d", createResp.StatusCode, http.StatusCreated)
	}
	_ = decodeJSON(t, createResp)

	duplicateResp := performJSONRequest(t, app, http.MethodPost, "/api/accounts", map[string]string{
		"username":  "david",
		"password":  "other123",
		"totp_code": currentTOTPCode(t, secret),
	})
	if duplicateResp.StatusCode != http.StatusConflict {
		t.Fatalf("duplicate status = %d, want %d", duplicateResp.StatusCode, http.StatusConflict)
	}
	_ = decodeJSON(t, duplicateResp)

	loginResp := performJSONRequest(t, app, http.MethodPost, "/api/login", map[string]string{
		"username":         "david",
		"password":         "start123",
		"totp_code":        currentTOTPCode(t, secret),
		"session_duration": "48h",
	})
	if loginResp.StatusCode != http.StatusOK {
		t.Fatalf("login status = %d, want %d", loginResp.StatusCode, http.StatusOK)
	}
	loginData := decodeJSON(t, loginResp)
	if loginData["token"] == "" {
		t.Fatalf("login token missing: %#v", loginData)
	}
	if loginData["session_duration"] != "48h" {
		t.Fatalf("session_duration = %v, want 48h", loginData["session_duration"])
	}
}

func TestLoginSupportsPermanentSession(t *testing.T) {
	app, module := newTestLoginApp(t)
	if err := module.accountStore.CreateUser("david", "start123"); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	permanent := performJSONRequest(t, app, http.MethodPost, "/api/login", map[string]string{
		"username":         "david",
		"password":         "start123",
		"session_duration": "permanent",
	})
	if permanent.StatusCode != http.StatusOK {
		t.Fatalf("permanent login status = %d, want %d", permanent.StatusCode, http.StatusOK)
	}
	data := decodeJSON(t, permanent)
	if data["session_duration"] != "permanent" {
		t.Fatalf("session_duration = %v, want permanent", data["session_duration"])
	}
}

func TestCreateAccountRunsUserCreatedHookOnlyAfterPersistence(t *testing.T) {
	app, module := newTestLoginApp(t)
	secret := configureTestAuthenticator(t, module)
	var hooked []string
	module.SetUserCreatedHook(func(username string) error {
		if !module.accountStore.UserExists(username) {
			t.Fatalf("hook ran before account %q was persisted", username)
		}
		hooked = append(hooked, username)
		return nil
	})

	created := performJSONRequest(t, app, http.MethodPost, "/api/accounts", map[string]string{
		"username": "Alice!", "password": "start123", "totp_code": currentTOTPCode(t, secret),
	})
	if created.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d, want %d", created.StatusCode, http.StatusCreated)
	}
	createdBody := decodeJSON(t, created)
	if createdBody["username"] != "Alice!" {
		t.Fatalf("created username = %v, want Alice!", createdBody["username"])
	}
	if len(hooked) != 1 || hooked[0] != "Alice!" {
		t.Fatalf("hook calls = %#v, want [Alice!]", hooked)
	}

	duplicate := performJSONRequest(t, app, http.MethodPost, "/api/accounts", map[string]string{
		"username": "alice!", "password": "other123", "totp_code": currentTOTPCode(t, secret),
	})
	if duplicate.StatusCode != http.StatusConflict {
		t.Fatalf("duplicate status = %d, want %d", duplicate.StatusCode, http.StatusConflict)
	}
	_ = decodeJSON(t, duplicate)
	if len(hooked) != 1 {
		t.Fatalf("hook ran for duplicate account: %#v", hooked)
	}
}

func TestFirstCreatedAccountReceivesPendingLegacyBotsBeforeAnotherUserVisitsBotAPI(t *testing.T) {
	dir := t.TempDir()
	botPath := filepath.Join(dir, "bots.json")
	legacy, err := json.Marshal([]philobot.BotConfig{{
		ID: "legacy", Name: "Legacy", SystemPrompt: "old",
	}})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(botPath, legacy, 0o600); err != nil {
		t.Fatal(err)
	}
	botStore := philobot.NewBotStore(botPath)
	if err := botStore.Load(); err != nil {
		t.Fatal(err)
	}

	module := New(
		"test-secret",
		filepath.Join(dir, "login_accounts.json"),
		filepath.Join(dir, "login_authenticator.json"),
		filepath.Join(dir, "user_preferences.json"),
	)
	if err := module.Initialize(); err != nil {
		t.Fatal(err)
	}
	secret := configureTestAuthenticator(t, module)
	module.SetUserCreatedHook(botStore.EnsureUser)
	app := fiber.New()
	module.RegisterRoutes(app.Group("/api"))

	created := performJSONRequest(t, app, http.MethodPost, "/api/accounts", map[string]string{
		"username": "FirstCreated", "password": "start123", "totp_code": currentTOTPCode(t, secret),
	})
	if created.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d, want %d", created.StatusCode, http.StatusCreated)
	}
	_ = decodeJSON(t, created)

	// Simulate another login opening the Bot API before FirstCreated does.
	if err := botStore.EnsureUser("OtherVisitor"); err != nil {
		t.Fatal(err)
	}
	if _, ok := botStore.GetBotForUser("FirstCreated", "legacy"); !ok {
		t.Fatal("pending legacy bots were not assigned to the first created account")
	}
	if _, ok := botStore.GetBotForUser("OtherVisitor", "legacy"); ok {
		t.Fatal("later Bot API visitor incorrectly received pending legacy bots")
	}
}

func TestListUserIDsReturnsConfiguredAccounts(t *testing.T) {
	_, module := newTestLoginApp(t)
	if err := module.accountStore.CreateUser("Alice", "start123"); err != nil {
		t.Fatalf("CreateUser(Alice) error = %v", err)
	}
	if err := module.accountStore.CreateUser("bob", "start123"); err != nil {
		t.Fatalf("CreateUser(bob) error = %v", err)
	}

	got := module.ListUserIDs()
	if len(got) != 2 || got[0] != "Alice" || got[1] != "bob" {
		t.Fatalf("ListUserIDs() = %#v, want [Alice bob]", got)
	}
}

func TestLoginUsesCanonicalAccountNameForJWTIdentity(t *testing.T) {
	app, module := newTestLoginApp(t)
	if err := module.accountStore.CreateUser("Alice", "start123"); err != nil {
		t.Fatalf("CreateUser(Alice) error = %v", err)
	}

	resp := performJSONRequest(t, app, http.MethodPost, "/api/login", map[string]string{
		"username": "alice",
		"password": "start123",
	})
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("login status = %d, want %d", resp.StatusCode, http.StatusOK)
	}
	data := decodeJSON(t, resp)
	if data["username"] != "Alice" {
		t.Fatalf("username = %v, want Alice", data["username"])
	}
}

func TestPasswordResetUpdatesLogin(t *testing.T) {
	app, module := newTestLoginApp(t)
	secret := configureTestAuthenticator(t, module)
	if err := module.accountStore.CreateUser("david", "oldpass"); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	unknownResp := performJSONRequest(t, app, http.MethodPost, "/api/password/reset", map[string]string{
		"username":     "missing",
		"new_password": "newpass",
		"totp_code":    currentTOTPCode(t, secret),
	})
	if unknownResp.StatusCode != http.StatusNotFound {
		t.Fatalf("unknown user status = %d, want %d", unknownResp.StatusCode, http.StatusNotFound)
	}
	_ = decodeJSON(t, unknownResp)

	resetResp := performJSONRequest(t, app, http.MethodPost, "/api/password/reset", map[string]string{
		"username":     "david",
		"new_password": "newpass",
		"totp_code":    currentTOTPCode(t, secret),
	})
	if resetResp.StatusCode != http.StatusOK {
		t.Fatalf("reset status = %d, want %d", resetResp.StatusCode, http.StatusOK)
	}
	_ = decodeJSON(t, resetResp)

	oldLoginResp := performJSONRequest(t, app, http.MethodPost, "/api/login", map[string]string{
		"username": "david",
		"password": "oldpass",
	})
	if oldLoginResp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("old login status = %d, want %d", oldLoginResp.StatusCode, http.StatusUnauthorized)
	}
	_ = decodeJSON(t, oldLoginResp)

	newLoginResp := performJSONRequest(t, app, http.MethodPost, "/api/login", map[string]string{
		"username":  "david",
		"password":  "newpass",
		"totp_code": currentTOTPCode(t, secret),
	})
	if newLoginResp.StatusCode != http.StatusOK {
		t.Fatalf("new login status = %d, want %d", newLoginResp.StatusCode, http.StatusOK)
	}
	newLoginData := decodeJSON(t, newLoginResp)
	if newLoginData["token"] == "" {
		t.Fatalf("new login token missing: %#v", newLoginData)
	}
}

// TestPasswordResetRejectsWithoutValidTOTP schliesst die Account-Uebernahme,
// die /api/password/reset als oeffentlichem Endpoint sonst offen liesse: ohne
// (oder mit falschem) Authenticator-Code darf ein fremdes Passwort nicht
// zuruecksetzbar sein, egal welcher Username angegeben wird.
func TestPasswordResetRejectsWithoutValidTOTP(t *testing.T) {
	app, module := newTestLoginApp(t)
	secret := configureTestAuthenticator(t, module)
	if err := module.accountStore.CreateUser("victim", "oldpass"); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	missingCodeResp := performJSONRequest(t, app, http.MethodPost, "/api/password/reset", map[string]string{
		"username":     "victim",
		"new_password": "takeover",
	})
	if missingCodeResp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("missing totp status = %d, want %d", missingCodeResp.StatusCode, http.StatusUnauthorized)
	}
	_ = decodeJSON(t, missingCodeResp)

	wrongCodeResp := performJSONRequest(t, app, http.MethodPost, "/api/password/reset", map[string]string{
		"username":     "victim",
		"new_password": "takeover",
		"totp_code":    "000000",
	})
	if wrongCodeResp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("wrong totp status = %d, want %d", wrongCodeResp.StatusCode, http.StatusUnauthorized)
	}
	_ = decodeJSON(t, wrongCodeResp)

	stillOldLoginResp := performJSONRequest(t, app, http.MethodPost, "/api/login", map[string]string{
		"username":  "victim",
		"password":  "oldpass",
		"totp_code": currentTOTPCode(t, secret),
	})
	if stillOldLoginResp.StatusCode != http.StatusOK {
		t.Fatalf("victim's original password should still work, login status = %d, want %d", stillOldLoginResp.StatusCode, http.StatusOK)
	}
	_ = decodeJSON(t, stillOldLoginResp)
}
