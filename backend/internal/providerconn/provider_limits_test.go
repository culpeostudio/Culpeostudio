package providerconn

import (
	"errors"
	"fmt"
	"path/filepath"
	"testing"
)

func TestManagerLimitsConnectionsPerUserWithoutBlockingUpdatesOrOtherUsers(t *testing.T) {
	t.Parallel()

	if maxConnectionsPerUser < 2 {
		t.Fatalf("maxConnectionsPerUser = %d, want a usable positive quota", maxConnectionsPerUser)
	}
	manager := newProviderLimitTestManager(t)
	const owner = "quota-owner"

	connections := make([]Connection, 0, maxConnectionsPerUser)
	for index := 0; index < maxConnectionsPerUser; index++ {
		connection, err := manager.SaveConnection(owner, testProviderInput(fmt.Sprintf("Provider %d", index)))
		if err != nil {
			t.Fatalf("SaveConnection(%d) error = %v", index, err)
		}
		connections = append(connections, connection)
	}

	// A quota must constrain creations only. Editing an existing connection at
	// the quota is required for ordinary maintenance such as changing a name.
	update := testProviderInput("Umbenannter Provider")
	update.ID = connections[0].ID
	if _, err := manager.SaveConnection(owner, update); err != nil {
		t.Fatalf("SaveConnection(update at quota) error = %v", err)
	}

	if _, err := manager.SaveConnection(owner, testProviderInput("One too many")); !errors.Is(err, ErrConnectionLimit) {
		t.Fatalf("SaveConnection(over quota) error = %v, want ErrConnectionLimit", err)
	}
	ownerConnections, err := manager.ListConnections(owner)
	if err != nil {
		t.Fatalf("ListConnections(owner) error = %v", err)
	}
	if got := len(ownerConnections); got != maxConnectionsPerUser {
		t.Fatalf("connections after rejected create = %d, want %d", got, maxConnectionsPerUser)
	}

	// Limits are ownership-scoped; one user must not exhaust another user's
	// configuration capacity.
	if _, err := manager.SaveConnection("another-user", testProviderInput("Independent provider")); err != nil {
		t.Fatalf("SaveConnection(other user) error = %v", err)
	}
}

func TestChangingProviderTargetInvalidatesOnlyItsActiveModels(t *testing.T) {
	t.Parallel()

	manager := newProviderLimitTestManager(t)
	const owner = "target-change-owner"
	primary := mustSaveTestProvider(t, manager, owner, "Primary")
	secondary := mustSaveTestProvider(t, manager, owner, "Secondary")

	mustSetCatalog(t, manager, owner, primary.ID, "primary-a", "primary-b")
	mustSetCatalog(t, manager, owner, secondary.ID, "secondary-a")
	primaryA := mustActivate(t, manager, owner, primary.ID, "primary-a")
	primaryB := mustActivate(t, manager, owner, primary.ID, "primary-b")
	secondaryA := mustActivate(t, manager, owner, secondary.ID, "secondary-a")

	changedTarget := testProviderInput("Primary after endpoint change")
	changedTarget.ID = primary.ID
	changedTarget.BaseURL = "https://provider-limit-test-changed.example/v1"
	if _, err := manager.SaveConnection(owner, changedTarget); err != nil {
		t.Fatalf("SaveConnection(change target) error = %v", err)
	}

	_, models, err := manager.ListModels(owner, primary.ID)
	if err != nil {
		t.Fatalf("ListModels(primary) error = %v", err)
	}
	if len(models) != 0 {
		t.Fatalf("target change retained stale catalog: %#v", models)
	}
	active, err := manager.ListActiveModels(owner)
	if err != nil {
		t.Fatalf("ListActiveModels() error = %v", err)
	}
	if len(active) != 1 || active[0].ModelRef != secondaryA.ModelRef {
		t.Fatalf("target change active models = %#v, want only %#v", active, secondaryA)
	}
	for _, stale := range []ActiveModel{primaryA, primaryB} {
		if _, found, touchErr := manager.TouchActiveModel(owner, stale.ModelRef); touchErr != nil || found {
			t.Fatalf("TouchActiveModel(%q) = (_, %v, %v), want stale model removed", stale.ModelRef, found, touchErr)
		}
	}
}

func TestSuccessfulCatalogReplacementInvalidatesOnlyModelsNoLongerDiscovered(t *testing.T) {
	t.Parallel()

	manager := newProviderLimitTestManager(t)
	const owner = "catalog-replacement-owner"
	connection := mustSaveTestProvider(t, manager, owner, "Catalog provider")
	mustSetCatalog(t, manager, owner, connection.ID, "kept", "removed")
	kept := mustActivate(t, manager, owner, connection.ID, "kept")
	removed := mustActivate(t, manager, owner, connection.ID, "removed")

	if _, err := manager.SetSyncResult(owner, connection.ID, []Model{
		{ID: "kept", DisplayName: "Still available", ChatSupported: true},
		{ID: "new", DisplayName: "Newly discovered", ChatSupported: true},
	}, nil); err != nil {
		t.Fatalf("SetSyncResult(successful replacement) error = %v", err)
	}

	active, err := manager.ListActiveModels(owner)
	if err != nil {
		t.Fatalf("ListActiveModels() error = %v", err)
	}
	if len(active) != 1 || active[0].ModelRef != kept.ModelRef {
		t.Fatalf("active models after catalogue replacement = %#v, want only kept model", active)
	}
	if _, found, touchErr := manager.TouchActiveModel(owner, removed.ModelRef); touchErr != nil || found {
		t.Fatalf("TouchActiveModel(removed) = (_, %v, %v), want model removed from active list", found, touchErr)
	}
}

func TestCatalogModelLimitRejectsOversizedReplacementWithoutDestroyingKnownGoodState(t *testing.T) {
	t.Parallel()

	if maxCatalogModels < 2 {
		t.Fatalf("maxCatalogModels = %d, want a usable positive cap", maxCatalogModels)
	}
	manager := newProviderLimitTestManager(t)
	const owner = "catalog-limit-owner"
	connection := mustSaveTestProvider(t, manager, owner, "Limited catalog provider")
	mustSetCatalog(t, manager, owner, connection.ID, "retained")
	retained := mustActivate(t, manager, owner, connection.ID, "retained")

	overLimit := make([]Model, maxCatalogModels+1)
	for index := range overLimit {
		overLimit[index] = Model{
			ID:            fmt.Sprintf("catalog-%d", index),
			DisplayName:   fmt.Sprintf("Catalog %d", index),
			ChatSupported: true,
		}
	}
	if _, err := manager.SetSyncResult(owner, connection.ID, overLimit, nil); !errors.Is(err, ErrCatalogModelLimit) {
		t.Fatalf("SetSyncResult(over catalog cap) error = %v, want ErrCatalogModelLimit", err)
	}

	_, models, err := manager.ListModels(owner, connection.ID)
	if err != nil {
		t.Fatalf("ListModels() error = %v", err)
	}
	if len(models) != 1 || models[0].ID != "retained" {
		t.Fatalf("oversized replacement changed the known-good catalog: %#v", models)
	}
	active, err := manager.ListActiveModels(owner)
	if err != nil {
		t.Fatalf("ListActiveModels() error = %v", err)
	}
	if len(active) != 1 || active[0].ModelRef != retained.ModelRef {
		t.Fatalf("oversized replacement changed active models: %#v", active)
	}
}

func TestStaleSyncCannotRestoreCatalogAfterConnectionTargetChanges(t *testing.T) {
	t.Parallel()

	manager := newProviderLimitTestManager(t)
	const owner = "stale-sync-owner"
	connection := mustSaveTestProvider(t, manager, owner, "Original target")
	snapshot, err := manager.GetConnection(owner, connection.ID)
	if err != nil {
		t.Fatalf("GetConnection(snapshot) error = %v", err)
	}

	updatedInput := testProviderInput("Changed target")
	updatedInput.ID = connection.ID
	updatedInput.BaseURL = "https://provider-limit-test-changed.example/v1"
	if _, err := manager.SaveConnection(owner, updatedInput); err != nil {
		t.Fatalf("SaveConnection(change target) error = %v", err)
	}

	if _, err := manager.SetSyncResultIfCurrent(owner, connection.ID, snapshot, []Model{{
		ID: "stale-model", DisplayName: "Stale model", ChatSupported: true,
	}}, nil); !errors.Is(err, ErrSyncSuperseded) {
		t.Fatalf("SetSyncResultIfCurrent(stale target) error = %v, want ErrSyncSuperseded", err)
	}
	_, models, err := manager.ListModels(owner, connection.ID)
	if err != nil {
		t.Fatalf("ListModels() error = %v", err)
	}
	if len(models) != 0 {
		t.Fatalf("stale sync restored a catalog after target change: %#v", models)
	}
}

func newProviderLimitTestManager(t *testing.T) *Manager {
	t.Helper()
	manager, err := NewManager(filepath.Join(t.TempDir(), "provider_connections.json"), "provider-limit-test-secret")
	if err != nil {
		t.Fatalf("NewManager() error = %v", err)
	}
	return manager
}

// testProviderInput builds a saveable connection input for tests that only
// care about limits/catalog bookkeeping, not any particular vendor. It uses
// the custom preset (no API key required) since SaveConnection never dials
// out itself: no shipped preset permits a loopback BaseURL.
func testProviderInput(name string) ConnectionInput {
	return ConnectionInput{
		PresetID: CustomPresetID,
		Name:     name,
		Protocol: ProtocolOpenAICompatible,
		BaseURL:  "https://provider-limit-test.example/v1",
		Enabled:  true,
	}
}

func mustSaveTestProvider(t *testing.T, manager *Manager, owner, name string) Connection {
	t.Helper()
	connection, err := manager.SaveConnection(owner, testProviderInput(name))
	if err != nil {
		t.Fatalf("SaveConnection(%q) error = %v", name, err)
	}
	return connection
}

func mustSetCatalog(t *testing.T, manager *Manager, owner, connectionID string, modelIDs ...string) {
	t.Helper()
	models := make([]Model, 0, len(modelIDs))
	for _, modelID := range modelIDs {
		models = append(models, Model{ID: modelID, DisplayName: modelID, ChatSupported: true})
	}
	if _, err := manager.SetSyncResult(owner, connectionID, models, nil); err != nil {
		t.Fatalf("SetSyncResult(%q) error = %v", connectionID, err)
	}
}

func mustActivate(t *testing.T, manager *Manager, owner, connectionID, modelID string) ActiveModel {
	t.Helper()
	active, err := manager.ActivateModel(owner, connectionID, modelID, "")
	if err != nil {
		t.Fatalf("ActivateModel(%q) error = %v", modelID, err)
	}
	return active
}
