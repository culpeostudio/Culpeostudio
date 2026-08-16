package login

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	loginv1 "github.com/culpeohq/backend/gen/go/culpeostudio/login/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
)

func newUserPreferencesService(t *testing.T) (*grpcService, string) {
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
	return &grpcService{module: module}, preferencesPath
}

func TestUserPreferencesAPIRequiresAuthenticationAndPersistsCompleteProfile(t *testing.T) {
	service, preferencesPath := newUserPreferencesService(t)

	// No authenticated user on the context is what an unauthenticated call
	// looks like once the interceptor has let a public method through.
	if _, err := service.GetUserPreferences(context.Background(), &loginv1.GetUserPreferencesRequest{}); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("unauthenticated GET code = %v, want Unauthenticated", status.Code(err))
	}

	ctx := grpcmw.ContextWithUserForTest(context.Background(), "ALICE!", "ALICE!")

	initial, err := service.GetUserPreferences(ctx, &loginv1.GetUserPreferencesRequest{})
	if err != nil {
		t.Fatalf("initial GET error = %v", err)
	}
	profile := initial.GetPreferences()
	if profile.GetConfigured() || profile.GetLanguage() != "de" {
		t.Fatalf("initial profile = %+v, want unconfigured German default", profile)
	}

	// An omitted field arrives as an empty string, which the store rejects the
	// same way the handler used to reject a missing JSON key.
	if _, err := service.UpdateUserPreferences(ctx, &loginv1.UpdateUserPreferencesRequest{}); status.Code(err) != codes.InvalidArgument {
		t.Fatalf("missing field code = %v, want InvalidArgument", status.Code(err))
	}

	if _, err := service.UpdateUserPreferences(ctx, &loginv1.UpdateUserPreferencesRequest{
		Language: "fr",
	}); status.Code(err) != codes.InvalidArgument {
		t.Fatalf("invalid value code = %v, want InvalidArgument", status.Code(err))
	}

	stillUnconfigured, err := service.GetUserPreferences(ctx, &loginv1.GetUserPreferencesRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if stillUnconfigured.GetPreferences().GetConfigured() {
		t.Fatalf("rejected update unexpectedly configured profile: %+v", stillUnconfigured.GetPreferences())
	}

	updated, err := service.UpdateUserPreferences(ctx, &loginv1.UpdateUserPreferencesRequest{
		Language: " EN ",
	})
	if err != nil {
		t.Fatalf("valid update error = %v", err)
	}
	updatedProfile := updated.GetPreferences()
	if !updatedProfile.GetConfigured() || updatedProfile.GetLanguage() != "en" {
		t.Fatalf("updated profile = %+v, want configured English", updatedProfile)
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
	if !configured || persisted.Language != "en" {
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
			if index%2 == 1 {
				language = "en"
			}
			_, err := store.Set(fmt.Sprintf("User-%d", index), language)
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
		if index%2 == 1 && preferences.Language != "en" {
			t.Fatalf("user-%d preferences = %#v, want English", index, preferences)
		}
		if index%2 == 0 && preferences.Language != "de" {
			t.Fatalf("user-%d preferences = %#v, want German", index, preferences)
		}
	}
}

func TestUserPreferencesStoreDoesNotMutateMemoryWhenAtomicWriteFails(t *testing.T) {
	store := NewUserPreferencesStore(t.TempDir())
	if _, err := store.Set("alice", "en"); err == nil {
		t.Fatal("expected write into directory path to fail")
	}
	preferences, configured := store.Get("alice")
	if configured || preferences != defaultUserPreferences() {
		t.Fatalf("failed write changed memory: %#v, configured=%v", preferences, configured)
	}
}
