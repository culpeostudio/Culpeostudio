package settings

import (
	"context"
	"path/filepath"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	settingsv1 "github.com/culpeohq/backend/gen/go/culpeostudio/settings/v1"
)

func newTestService(t *testing.T) (*grpcService, string) {
	t.Helper()
	settingsPath := filepath.Join(t.TempDir(), "settings.json")
	module := New(settingsPath)
	if err := module.Initialize(); err != nil {
		t.Fatalf("Initialisierung fehlgeschlagen: %v", err)
	}
	return &grpcService{store: module.store}, settingsPath
}

func TestGetSettingsReportsNoStoredTokens(t *testing.T) {
	service, _ := newTestService(t)

	response, err := service.GetSettings(context.Background(), &settingsv1.GetSettingsRequest{})
	if err != nil {
		t.Fatalf("GetSettings fehlgeschlagen: %v", err)
	}
	settings := response.GetSettings()
	if settings.GetHuggingfaceTokenSet() || settings.GetOpenrouterTokenSet() || settings.GetFeatherlessTokenSet() {
		t.Fatalf("frischer Store sollte keine Tokens melden: %+v", settings)
	}
}

// Storing a token must flip its flag without ever handing the value back. The
// Settings message has no token fields at all, so this is now guaranteed by the
// schema rather than by the handler remembering to strip them.
func TestUpdateSettingsStoresTokensAndReturnsOnlyFlags(t *testing.T) {
	service, settingsPath := newTestService(t)

	modelDir := filepath.Join(filepath.Dir(settingsPath), "models")
	huggingface := "hf_secret"
	openrouter := "or_secret"
	featherless := "fl_secret"

	response, err := service.UpdateSettings(context.Background(), &settingsv1.UpdateSettingsRequest{
		ModelDir:         &modelDir,
		HuggingfaceToken: &huggingface,
		OpenrouterToken:  &openrouter,
		FeatherlessToken: &featherless,
	})
	if err != nil {
		t.Fatalf("UpdateSettings fehlgeschlagen: %v", err)
	}

	settings := response.GetSettings()
	if !settings.GetHuggingfaceTokenSet() || !settings.GetOpenrouterTokenSet() || !settings.GetFeatherlessTokenSet() {
		t.Fatalf("erwartete gesetzte Token-Flags, bekam: %+v", settings)
	}
	if settings.GetModelDir() != modelDir {
		t.Fatalf("model_dir = %q, erwartet %q", settings.GetModelDir(), modelDir)
	}
}

// An omitted field leaves the stored value alone; that is what the optional
// fields express in place of the nil pointers the JSON body used.
func TestUpdateSettingsLeavesOmittedFieldsUntouched(t *testing.T) {
	service, settingsPath := newTestService(t)

	modelDir := filepath.Join(filepath.Dir(settingsPath), "models")
	huggingface := "hf_secret"
	if _, err := service.UpdateSettings(context.Background(), &settingsv1.UpdateSettingsRequest{
		ModelDir:         &modelDir,
		HuggingfaceToken: &huggingface,
	}); err != nil {
		t.Fatalf("erste Aktualisierung fehlgeschlagen: %v", err)
	}

	openrouter := "or_secret"
	response, err := service.UpdateSettings(context.Background(), &settingsv1.UpdateSettingsRequest{
		OpenrouterToken: &openrouter,
	})
	if err != nil {
		t.Fatalf("zweite Aktualisierung fehlgeschlagen: %v", err)
	}

	settings := response.GetSettings()
	if !settings.GetHuggingfaceTokenSet() {
		t.Fatal("ausgelassenes Feld hat den gespeicherten Hugging-Face-Token verworfen")
	}
	if settings.GetModelDir() != modelDir {
		t.Fatalf("ausgelassenes Feld hat model_dir veraendert: %q", settings.GetModelDir())
	}
}

func TestTestProviderRejectsUnspecifiedProvider(t *testing.T) {
	service, _ := newTestService(t)

	_, err := service.TestProvider(context.Background(), &settingsv1.TestProviderRequest{
		Provider: settingsv1.Provider_PROVIDER_UNSPECIFIED,
	})
	if status.Code(err) != codes.InvalidArgument {
		t.Fatalf("erwartete InvalidArgument, bekam: %v", err)
	}
}
