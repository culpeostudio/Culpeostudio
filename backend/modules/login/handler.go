package login

import (
	"errors"
	"sync"
	"time"
)

type LoginModule struct {
	JWTSecret        string
	accountStore     *AccountStore
	authStore        *AuthenticatorStore
	preferencesStore *UserPreferencesStore
	pendingMu        sync.Mutex
	pendingSecret    string
	accountCreateMu  sync.Mutex
	userCreatedMu    sync.RWMutex
	userCreatedHook  func(string) error
}

func New(jwtSecret string, accountsFile string, authConfigFile string, preferencesFile string) *LoginModule {
	return &LoginModule{
		JWTSecret:        jwtSecret,
		accountStore:     NewAccountStore(accountsFile),
		authStore:        NewAuthenticatorStore(authConfigFile),
		preferencesStore: NewUserPreferencesStore(preferencesFile),
	}
}

func (m *LoginModule) Name() string { return "login" }

func (m *LoginModule) Initialize() error {
	if err := m.accountStore.Load(); err != nil {
		return err
	}
	if err := m.authStore.Load(); err != nil {
		return err
	}
	return m.preferencesStore.Load()
}

func (m *LoginModule) Shutdown() error { return nil }

func (m *LoginModule) ListUserIDs() []string {
	if err := m.accountStore.Load(); err != nil {
		return nil
	}
	return m.accountStore.ListUsers()
}

func (m *LoginModule) UserExists(username string) bool {
	return m.accountStore.UserExists(username)
}

func (m *LoginModule) SetUserCreatedHook(hook func(string) error) {
	m.userCreatedMu.Lock()
	m.userCreatedHook = hook
	m.userCreatedMu.Unlock()
}

func (m *LoginModule) notifyUserCreated(username string) error {
	m.userCreatedMu.RLock()
	hook := m.userCreatedHook
	m.userCreatedMu.RUnlock()
	if hook == nil {
		return nil
	}
	return hook(username)
}

var (
	errAuthenticatorMissing = errors.New("authenticator not configured")
	errInvalidTOTPCode      = errors.New("invalid authenticator code")
)

func (m *LoginModule) requireValidTOTP(code string) error {
	if !m.authStore.IsConfigured() {
		return errAuthenticatorMissing
	}
	if !m.authStore.ValidateCode(code, time.Now()) {
		return errInvalidTOTPCode
	}
	return nil
}
