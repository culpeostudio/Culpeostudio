// Package settings serves the settings screen, system information and provider
// connection tests.
package settings

import (
	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/modules/settings/anbieter"
	"github.com/culpeohq/backend/modules/settings/node"
)

type SettingsModule struct {
	store    *appsettings.Store
	Anbieter *anbieter.AnbieterHandler
	Node     *node.NodeHandler
}

func New(settingsFile string) *SettingsModule {
	return &SettingsModule{
		store:    appsettings.NewStore(settingsFile),
		Anbieter: anbieter.New(),
		Node:     node.New(),
	}
}

func (m *SettingsModule) Name() string { return "settings" }

func (m *SettingsModule) Initialize() error {
	return m.store.Load()
}

func (m *SettingsModule) Shutdown() error { return nil }
