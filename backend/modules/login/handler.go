package login

import (
	"errors"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
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

func (m *LoginModule) RegisterRoutes(r fiber.Router) {
	r.Post("/login", m.handleLogin)
	r.Get("/auth/status", m.handleAuthStatus)
	r.Post("/auth/setup/start", m.handleSetupStart)
	r.Post("/auth/setup/confirm", m.handleSetupConfirm)
	r.Post("/accounts", m.handleCreateAccount)
	r.Post("/password/reset", m.handlePasswordReset)
	r.Get("/user/preferences", m.handleGetUserPreferences)
	r.Put("/user/preferences", m.handlePutUserPreferences)
}

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

func (m *LoginModule) handleLogin(c *fiber.Ctx) error {
	var body struct {
		Username        string `json:"username"`
		Password        string `json:"password"`
		SessionDuration string `json:"session_duration"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}

	username := strings.TrimSpace(body.Username)
	password := strings.TrimSpace(body.Password)

	if username == "" || password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Username und Passwort sind erforderlich"})
	}

	if err := m.accountStore.Load(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Konnte Accounts nicht laden"})
	}

	if !m.accountStore.ValidateCredentials(username, password) {
		return c.Status(401).JSON(fiber.Map{"error": "Ungueltige Anmeldedaten"})
	}
	if canonical, ok := m.accountStore.CanonicalUsername(username); ok {
		username = canonical
	}

	claims := jwt.MapClaims{
		"user_id":  username,
		"username": username,
	}
	duration, permanent := loginSessionDuration(body.SessionDuration)
	if permanent {
		claims["session_duration"] = "permanent"
	} else {
		claims["exp"] = time.Now().Add(duration).Unix()
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	tokenStr, err := token.SignedString([]byte(m.JWTSecret))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Token-Erstellung fehlgeschlagen"})
	}

	return c.JSON(fiber.Map{
		"token":            tokenStr,
		"username":         username,
		"session_duration": normalizedSessionDuration(body.SessionDuration),
	})
}

func loginSessionDuration(raw string) (time.Duration, bool) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "8h":
		return 8 * time.Hour, false
	case "48h":
		return 48 * time.Hour, false
	case "permanent":
		return 0, true
	default:
		return 24 * time.Hour, false
	}
}

func normalizedSessionDuration(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "8h", "48h", "permanent":
		return strings.ToLower(strings.TrimSpace(raw))
	default:
		return "24h"
	}
}

func (m *LoginModule) handleAuthStatus(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"totp_configured":   m.authStore.IsConfigured(),
		"authenticator_app": m.authStore.App(),
	})
}

func (m *LoginModule) handleSetupStart(c *fiber.Ctx) error {
	if m.authStore.IsConfigured() {
		return c.Status(409).JSON(fiber.Map{"error": "Authenticator ist bereits eingerichtet"})
	}

	secret, err := GenerateTOTPSecret()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Authenticator-Secret konnte nicht erstellt werden"})
	}

	m.pendingMu.Lock()
	m.pendingSecret = secret
	m.pendingMu.Unlock()

	return c.JSON(fiber.Map{
		"secret":      secret,
		"otpauth_url": BuildTOTPAuthURL(secret),
	})
}

func (m *LoginModule) handleSetupConfirm(c *fiber.Ctx) error {
	var body struct {
		Code string `json:"code"`
		App  string `json:"app"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	if m.authStore.IsConfigured() {
		return c.Status(409).JSON(fiber.Map{"error": "Authenticator ist bereits eingerichtet"})
	}

	m.pendingMu.Lock()
	pendingSecret := m.pendingSecret
	m.pendingMu.Unlock()
	if strings.TrimSpace(pendingSecret) == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Authenticator-Setup muss zuerst gestartet werden"})
	}
	if !validateTOTPCode(pendingSecret, body.Code, time.Now()) {
		return c.Status(401).JSON(fiber.Map{"error": "Ungueltiger Authenticator-Code"})
	}
	if err := m.authStore.SaveConfigured(pendingSecret, time.Now(), body.App); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Authenticator konnte nicht gespeichert werden"})
	}

	m.pendingMu.Lock()
	m.pendingSecret = ""
	m.pendingMu.Unlock()

	return c.JSON(fiber.Map{"totp_configured": true})
}

func (m *LoginModule) handleCreateAccount(c *fiber.Ctx) error {
	var body struct {
		Username string `json:"username"`
		Password string `json:"password"`
		TOTPCode string `json:"totp_code"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	if err := m.requireValidTOTP(body.TOTPCode); err != nil {
		return totpErrorResponse(c, err)
	}
	m.accountCreateMu.Lock()
	defer m.accountCreateMu.Unlock()

	if err := m.accountStore.Load(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Konnte Accounts nicht laden"})
	}
	if err := m.accountStore.CreateUser(body.Username, body.Password); err != nil {
		if errors.Is(err, ErrUserExists) {
			return c.Status(409).JSON(fiber.Map{"error": "Benutzer existiert bereits"})
		}
		return c.Status(400).JSON(fiber.Map{"error": "Account konnte nicht erstellt werden"})
	}
	username := strings.TrimSpace(body.Username)
	if canonical, ok := m.accountStore.CanonicalUsername(username); ok {
		username = canonical
	}
	if err := m.notifyUserCreated(username); err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
			"error": "Account wurde erstellt, aber das Benutzerprofil konnte nicht initialisiert werden",
			"code":  "user_profile_initialization_failed",
		})
	}

	return c.Status(201).JSON(fiber.Map{"username": username})
}

func (m *LoginModule) handlePasswordReset(c *fiber.Ctx) error {
	var body struct {
		Username    string `json:"username"`
		NewPassword string `json:"new_password"`
		TOTPCode    string `json:"totp_code"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	if err := m.requireValidTOTP(body.TOTPCode); err != nil {
		return totpErrorResponse(c, err)
	}
	if err := m.accountStore.Load(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Konnte Accounts nicht laden"})
	}
	if err := m.accountStore.ResetPassword(body.Username, body.NewPassword); err != nil {
		if errors.Is(err, ErrUserNotFound) {
			return c.Status(404).JSON(fiber.Map{"error": "Benutzer nicht gefunden"})
		}
		return c.Status(400).JSON(fiber.Map{"error": "Passwort konnte nicht zurueckgesetzt werden"})
	}

	return c.JSON(fiber.Map{"username": strings.TrimSpace(body.Username), "password_reset": true})
}

func (m *LoginModule) handleGetUserPreferences(c *fiber.Ctx) error {
	userID, ok := authenticatedUserID(c)
	if !ok {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{"error": "Nicht autorisiert"})
	}

	preferences, configured := m.preferencesStore.Get(userID)
	return c.JSON(userPreferencesResponse(preferences, configured))
}

func (m *LoginModule) handlePutUserPreferences(c *fiber.Ctx) error {
	userID, ok := authenticatedUserID(c)
	if !ok {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{"error": "Nicht autorisiert"})
	}

	var body struct {
		Language        *string `json:"language"`
		FrontendVersion *string `json:"frontend_version"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}
	if body.Language == nil || body.FrontendVersion == nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"error": "language und frontend_version sind erforderlich",
		})
	}

	preferences, err := m.preferencesStore.Set(userID, *body.Language, *body.FrontendVersion)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(userPreferencesResponse(preferences, true))
}

func authenticatedUserID(c *fiber.Ctx) (string, bool) {
	userID, ok := c.Locals("user_id").(string)
	userID = strings.TrimSpace(userID)
	return userID, ok && userID != ""
}

func userPreferencesResponse(preferences UserPreferences, configured bool) fiber.Map {
	return fiber.Map{
		"configured":       configured,
		"language":         preferences.Language,
		"frontend_version": preferences.FrontendVersion,
	}
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

func totpErrorResponse(c *fiber.Ctx, err error) error {
	if errors.Is(err, errAuthenticatorMissing) {
		return c.Status(409).JSON(fiber.Map{"error": "Authenticator ist nicht eingerichtet"})
	}
	return c.Status(401).JSON(fiber.Map{"error": "Ungueltiger Authenticator-Code"})
}
