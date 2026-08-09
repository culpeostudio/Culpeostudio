package login

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	loginv1 "github.com/culpeohq/backend/gen/go/culpeostudio/login/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/modules/scout/bots"
)

func newTestLoginService(t *testing.T) (*grpcService, *LoginModule) {
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
	return &grpcService{module: module}, module
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

func createAccount(t *testing.T, service *grpcService, username, password, totpCode string) error {
	t.Helper()
	_, err := service.CreateAccount(context.Background(), &loginv1.CreateAccountRequest{
		Username: username,
		Password: password,
		TotpCode: totpCode,
	})
	return err
}

func TestCreateAccountRejectsDuplicates(t *testing.T) {
	service, module := newTestLoginService(t)
	secret := configureTestAuthenticator(t, module)

	if err := createAccount(t, service, "david", "start123", currentTOTPCode(t, secret)); err != nil {
		t.Fatalf("CreateAccount() error = %v", err)
	}

	err := createAccount(t, service, "david", "other123", currentTOTPCode(t, secret))
	if status.Code(err) != codes.AlreadyExists {
		t.Fatalf("duplicate code = %v, want AlreadyExists", status.Code(err))
	}

	loginResp, err := service.Login(context.Background(), &loginv1.LoginRequest{
		Username:        "david",
		Password:        "start123",
		SessionDuration: loginv1.SessionDuration_SESSION_DURATION_48H,
	})
	if err != nil {
		t.Fatalf("Login() error = %v", err)
	}
	if loginResp.GetToken() == "" {
		t.Fatalf("login token missing: %#v", loginResp)
	}
	if loginResp.GetSessionDuration() != loginv1.SessionDuration_SESSION_DURATION_48H {
		t.Fatalf("session_duration = %v, want 48H", loginResp.GetSessionDuration())
	}
}

func TestLoginSupportsPermanentSession(t *testing.T) {
	service, module := newTestLoginService(t)
	if err := module.accountStore.CreateUser("david", "start123"); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	response, err := service.Login(context.Background(), &loginv1.LoginRequest{
		Username:        "david",
		Password:        "start123",
		SessionDuration: loginv1.SessionDuration_SESSION_DURATION_PERMANENT,
	})
	if err != nil {
		t.Fatalf("Login() error = %v", err)
	}
	if response.GetSessionDuration() != loginv1.SessionDuration_SESSION_DURATION_PERMANENT {
		t.Fatalf("session_duration = %v, want PERMANENT", response.GetSessionDuration())
	}
}

// An unrecognised duration used to fall back to 24h; UNSPECIFIED keeps that.
func TestLoginFallsBackToDefaultSessionDuration(t *testing.T) {
	service, module := newTestLoginService(t)
	if err := module.accountStore.CreateUser("david", "start123"); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	response, err := service.Login(context.Background(), &loginv1.LoginRequest{
		Username: "david",
		Password: "start123",
	})
	if err != nil {
		t.Fatalf("Login() error = %v", err)
	}
	if response.GetSessionDuration() != loginv1.SessionDuration_SESSION_DURATION_24H {
		t.Fatalf("session_duration = %v, want 24H", response.GetSessionDuration())
	}
}

func TestCreateAccountRunsUserCreatedHookOnlyAfterPersistence(t *testing.T) {
	service, module := newTestLoginService(t)
	secret := configureTestAuthenticator(t, module)

	var hooked []string
	module.SetUserCreatedHook(func(username string) error {
		if !module.accountStore.UserExists(username) {
			t.Fatalf("hook ran before account %q was persisted", username)
		}
		hooked = append(hooked, username)
		return nil
	})

	created, err := service.CreateAccount(context.Background(), &loginv1.CreateAccountRequest{
		Username: "Alice!", Password: "start123", TotpCode: currentTOTPCode(t, secret),
	})
	if err != nil {
		t.Fatalf("CreateAccount() error = %v", err)
	}
	if created.GetUsername() != "Alice!" {
		t.Fatalf("created username = %v, want Alice!", created.GetUsername())
	}
	if len(hooked) != 1 || hooked[0] != "Alice!" {
		t.Fatalf("hook calls = %#v, want [Alice!]", hooked)
	}

	err = createAccount(t, service, "alice!", "other123", currentTOTPCode(t, secret))
	if status.Code(err) != codes.AlreadyExists {
		t.Fatalf("duplicate code = %v, want AlreadyExists", status.Code(err))
	}
	if len(hooked) != 1 {
		t.Fatalf("hook ran for duplicate account: %#v", hooked)
	}
}

func TestFirstCreatedAccountReceivesPendingLegacyBotsBeforeAnotherUserVisitsBotAPI(t *testing.T) {
	dir := t.TempDir()
	botPath := filepath.Join(dir, "bots.json")
	legacy, err := json.Marshal([]bots.Config{{
		ID: "legacy", Name: "Legacy", SystemPrompt: "old",
	}})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(botPath, legacy, 0o600); err != nil {
		t.Fatal(err)
	}
	botStore := bots.NewStore(botPath)
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
	service := &grpcService{module: module}

	if err := createAccount(t, service, "FirstCreated", "start123", currentTOTPCode(t, secret)); err != nil {
		t.Fatalf("CreateAccount() error = %v", err)
	}

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
	_, module := newTestLoginService(t)
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
	service, module := newTestLoginService(t)
	if err := module.accountStore.CreateUser("Alice", "start123"); err != nil {
		t.Fatalf("CreateUser(Alice) error = %v", err)
	}

	response, err := service.Login(context.Background(), &loginv1.LoginRequest{
		Username: "alice",
		Password: "start123",
	})
	if err != nil {
		t.Fatalf("Login() error = %v", err)
	}
	if response.GetUsername() != "Alice" {
		t.Fatalf("username = %v, want Alice", response.GetUsername())
	}
}

func TestPasswordResetUpdatesLogin(t *testing.T) {
	service, module := newTestLoginService(t)
	secret := configureTestAuthenticator(t, module)
	if err := module.accountStore.CreateUser("david", "oldpass"); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	_, err := service.ResetPassword(context.Background(), &loginv1.ResetPasswordRequest{
		Username: "missing", NewPassword: "newpass", TotpCode: currentTOTPCode(t, secret),
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("unknown user code = %v, want NotFound", status.Code(err))
	}

	if _, err := service.ResetPassword(context.Background(), &loginv1.ResetPasswordRequest{
		Username: "david", NewPassword: "newpass", TotpCode: currentTOTPCode(t, secret),
	}); err != nil {
		t.Fatalf("ResetPassword() error = %v", err)
	}

	_, err = service.Login(context.Background(), &loginv1.LoginRequest{
		Username: "david", Password: "oldpass",
	})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("old login code = %v, want Unauthenticated", status.Code(err))
	}

	newLogin, err := service.Login(context.Background(), &loginv1.LoginRequest{
		Username: "david", Password: "newpass",
	})
	if err != nil {
		t.Fatalf("Login() after reset error = %v", err)
	}
	if newLogin.GetToken() == "" {
		t.Fatalf("new login token missing: %#v", newLogin)
	}
}

func TestPasswordResetRejectsWithoutValidTOTP(t *testing.T) {
	service, module := newTestLoginService(t)
	secret := configureTestAuthenticator(t, module)
	if err := module.accountStore.CreateUser("victim", "oldpass"); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	_, err := service.ResetPassword(context.Background(), &loginv1.ResetPasswordRequest{
		Username: "victim", NewPassword: "takeover",
	})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("missing totp code = %v, want Unauthenticated", status.Code(err))
	}

	_, err = service.ResetPassword(context.Background(), &loginv1.ResetPasswordRequest{
		Username: "victim", NewPassword: "takeover", TotpCode: "000000",
	})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("wrong totp code = %v, want Unauthenticated", status.Code(err))
	}

	if _, err := service.Login(context.Background(), &loginv1.LoginRequest{
		Username: "victim", Password: "oldpass",
	}); err != nil {
		t.Fatalf("victim's original password should still work, got: %v", err)
	}
	_ = secret
}

// The preference calls are not public, so they rely on the id the auth
// interceptor puts on the context.
func TestUserPreferencesRequireAuthenticatedContext(t *testing.T) {
	service, _ := newTestLoginService(t)

	_, err := service.GetUserPreferences(context.Background(), &loginv1.GetUserPreferencesRequest{})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("get code = %v, want Unauthenticated", status.Code(err))
	}

	_, err = service.UpdateUserPreferences(context.Background(), &loginv1.UpdateUserPreferencesRequest{
		Language: "de", FrontendVersion: "lite",
	})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("update code = %v, want Unauthenticated", status.Code(err))
	}
}

func TestUserPreferencesRoundTripForAuthenticatedUser(t *testing.T) {
	service, _ := newTestLoginService(t)
	ctx := grpcmw.ContextWithUserForTest(context.Background(), "david", "david")

	before, err := service.GetUserPreferences(ctx, &loginv1.GetUserPreferencesRequest{})
	if err != nil {
		t.Fatalf("GetUserPreferences() error = %v", err)
	}
	if before.GetPreferences().GetConfigured() {
		t.Fatal("fresh account should not report configured preferences")
	}

	updated, err := service.UpdateUserPreferences(ctx, &loginv1.UpdateUserPreferencesRequest{
		Language: "de", FrontendVersion: "lite",
	})
	if err != nil {
		t.Fatalf("UpdateUserPreferences() error = %v", err)
	}
	if !updated.GetPreferences().GetConfigured() || updated.GetPreferences().GetLanguage() != "de" {
		t.Fatalf("unexpected preferences: %+v", updated.GetPreferences())
	}

	after, err := service.GetUserPreferences(ctx, &loginv1.GetUserPreferencesRequest{})
	if err != nil {
		t.Fatalf("GetUserPreferences() after update error = %v", err)
	}
	if after.GetPreferences().GetFrontendVersion() != "lite" {
		t.Fatalf("frontend_version = %q, want lite", after.GetPreferences().GetFrontendVersion())
	}
}
