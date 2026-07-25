package philobot

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"
)

func TestBotStoreMigratesLegacyArrayForEveryExistingUser(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "bots.json")
	legacy := []BotConfig{{
		ID: "legacy-helper", Name: "Legacy Helper", SystemPrompt: "Altbestand",
		Keywords: []string{"legacy"}, ResponseStyle: "short",
	}}
	raw, err := json.MarshalIndent(legacy, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, raw, 0o644); err != nil {
		t.Fatal(err)
	}

	store := NewBotStore(path)
	store.SetExistingUsers(func() []string { return []string{"Alice", "bob"} })
	if err := store.Load(); err != nil {
		t.Fatalf("Load() failed: %v", err)
	}
	for _, userID := range []string{"alice", "bob"} {
		if _, ok := store.GetBotForUser(userID, "legacy-helper"); !ok {
			t.Fatalf("legacy bot missing for %s", userID)
		}
		if _, ok := store.GetBotForUser(userID, "botbuilder"); !ok {
			t.Fatalf("system bot missing for %s", userID)
		}
	}

	backup, err := os.ReadFile(path + ".v1.bak")
	if err != nil {
		t.Fatalf("legacy backup missing: %v", err)
	}
	if string(backup) != string(raw) {
		t.Fatalf("backup changed legacy bytes\n got: %s\nwant: %s", backup, raw)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("v2 mode = %o, want 600", info.Mode().Perm())
	}

	var stored botStoreFile
	v2, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(v2, &stored); err != nil {
		t.Fatalf("v2 decode failed: %v", err)
	}
	if stored.Version != botStoreSchemaVersion || len(stored.Users) != 2 {
		t.Fatalf("unexpected v2 payload: %#v", stored)
	}
	if _, exists := stored.Users["Alice"]; exists {
		t.Fatalf("user ids must be lowercase in persisted schema")
	}

	aliceBot, _ := store.GetBotForUser("ALICE", "legacy-helper")
	aliceBot.Name = "Nur Alice"
	if err := store.SaveBotForUser("ALIce", aliceBot); err != nil {
		t.Fatal(err)
	}
	bobBot, _ := store.GetBotForUser("bob", "legacy-helper")
	if bobBot.Name != "Legacy Helper" {
		t.Fatalf("alice update leaked to bob: %#v", bobBot)
	}
}

func TestBotStoreGivesPendingLegacyOnlyToFirstUser(t *testing.T) {
	path := filepath.Join(t.TempDir(), "bots.json")
	legacy := []BotConfig{{ID: "old", Name: "Old", SystemPrompt: "old"}}
	raw, _ := json.Marshal(legacy)
	if err := os.WriteFile(path, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	store := NewBotStore(path)
	if err := store.Load(); err != nil {
		t.Fatal(err)
	}
	if err := store.EnsureUser("First"); err != nil {
		t.Fatal(err)
	}
	if err := store.EnsureUser("Second"); err != nil {
		t.Fatal(err)
	}
	if _, ok := store.GetBotForUser("first", "old"); !ok {
		t.Fatal("first user did not receive pending legacy bots")
	}
	if _, ok := store.GetBotForUser("second", "old"); ok {
		t.Fatal("later user unexpectedly received pending legacy bots")
	}
	if _, ok := store.GetBotForUser("second", "philobot"); !ok {
		t.Fatal("new user did not receive system bots")
	}

	reloaded := NewBotStore(path)
	if err := reloaded.Load(); err != nil {
		t.Fatal(err)
	}
	if _, ok := reloaded.GetBotForUser("first", "old"); !ok {
		t.Fatal("first user's migrated bots were not persisted")
	}
	if _, ok := reloaded.GetBotForUser("second", "old"); ok {
		t.Fatal("pending legacy seed was not consumed exactly once")
	}
}

func TestBotStoreValidatesAndNormalizesModelBindings(t *testing.T) {
	store := NewBotStore(filepath.Join(t.TempDir(), "bots.json"))
	if err := store.EnsureUser("alice"); err != nil {
		t.Fatal(err)
	}
	local := BotConfig{ID: "local", Name: "Local", SystemPrompt: "x", ModelBinding: &ModelBinding{Kind: "local", InstanceID: "inst-1"}}
	if err := store.SaveBotForUser("alice", local); err != nil {
		t.Fatalf("save local binding: %v", err)
	}
	got, _ := store.GetBotForUser("alice", "local")
	if got.ModelBinding == nil || got.ModelBinding.ModelRef != "local:inst-1" || got.ModelBinding.Provider != "local" {
		t.Fatalf("local binding was not normalized: %#v", got.ModelBinding)
	}

	invalid := BotConfig{ID: "bad", Name: "Bad", SystemPrompt: "x", ModelBinding: &ModelBinding{Kind: "api", Provider: "unsupported", ModelID: "x"}}
	if err := store.SaveBotForUser("alice", invalid); err == nil {
		t.Fatal("invalid API binding was accepted")
	}
}

func TestBotStoreLoadPreservesInvalidBindingForRequestTimeError(t *testing.T) {
	path := filepath.Join(t.TempDir(), "bots.json")
	stored := botStoreFile{
		Version: botStoreSchemaVersion,
		Users: map[string]botStoreUser{
			"alice": {Bots: []BotConfig{{
				ID: "invalid-bound", Name: "Invalid Bound", SystemPrompt: "bound", ResponseStyle: "balanced",
				ModelBinding: &ModelBinding{Kind: "api", Provider: "removed-provider", ModelID: "vendor/model"},
			}}},
		},
	}
	payload, err := json.MarshalIndent(stored, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, payload, 0o600); err != nil {
		t.Fatal(err)
	}

	store := NewBotStore(path)
	if err := store.Load(); err != nil {
		t.Fatal(err)
	}
	bot, ok := store.GetBotForUser("alice", "invalid-bound")
	if !ok || bot.ModelBinding == nil || bot.ModelBinding.Provider != "removed-provider" {
		t.Fatalf("invalid binding was silently erased: %#v", bot.ModelBinding)
	}
	if _, err := normalizeModelBinding(bot.ModelBinding); !errors.Is(err, errInvalidModelBinding) {
		t.Fatalf("preserved binding did not produce request-time validation error: %v", err)
	}

	reloaded := NewBotStore(path)
	if err := reloaded.Load(); err != nil {
		t.Fatal(err)
	}
	bot, _ = reloaded.GetBotForUser("alice", "invalid-bound")
	if bot.ModelBinding == nil || bot.ModelBinding.Provider != "removed-provider" {
		t.Fatalf("normalization save did not preserve invalid binding: %#v", bot.ModelBinding)
	}
}

func TestBotStoreUserNamespacesDoNotCollideAfterLoginNormalization(t *testing.T) {
	path := filepath.Join(t.TempDir(), "bots.json")
	store := NewBotStore(path)
	if err := store.Load(); err != nil {
		t.Fatal(err)
	}
	if err := store.EnsureUser("alice"); err != nil {
		t.Fatal(err)
	}
	if err := store.SaveBotForUser("alice", BotConfig{ID: "plain-only", Name: "Plain", SystemPrompt: "plain"}); err != nil {
		t.Fatal(err)
	}
	if err := store.EnsureUser("alice!"); err != nil {
		t.Fatal(err)
	}
	if _, ok := store.GetBotForUser("alice!", "plain-only"); ok {
		t.Fatal("punctuation-distinct login unexpectedly shared the alice namespace")
	}
	if err := store.SaveBotForUser("alice!", BotConfig{ID: "punctuation-only", Name: "Punctuation", SystemPrompt: "punctuation"}); err != nil {
		t.Fatal(err)
	}
	if _, ok := store.GetBotForUser("ALICE", "punctuation-only"); ok {
		t.Fatal("alice! bot leaked into case-insensitive alice namespace")
	}

	if err := store.EnsureUser("张三"); err != nil {
		t.Fatal(err)
	}
	if err := store.SaveBotForUser("张三", BotConfig{ID: "unicode-only", Name: "Unicode", SystemPrompt: "unicode"}); err != nil {
		t.Fatal(err)
	}
	if err := store.EnsureUser("李四"); err != nil {
		t.Fatal(err)
	}
	if _, ok := store.GetBotForUser("李四", "unicode-only"); ok {
		t.Fatal("distinct Unicode login unexpectedly shared a bot namespace")
	}

	reloaded := NewBotStore(path)
	if err := reloaded.Load(); err != nil {
		t.Fatal(err)
	}
	if _, ok := reloaded.GetBotForUser("ALICE!", "punctuation-only"); !ok {
		t.Fatal("case-insensitive punctuation namespace was not persisted")
	}
	if _, ok := reloaded.GetBotForUser("张三", "unicode-only"); !ok {
		t.Fatal("Unicode namespace was not persisted")
	}
}
