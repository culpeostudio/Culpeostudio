package login

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha1"
	"encoding/base32"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

const (
	defaultTOTPIssuer      = "MyCulpeo Engine"
	defaultTOTPAccountName = "culpeostudio"
	totpDigits             = 6
	totpPeriod             = 30
	totpWindow             = 1
)

type authenticatorConfig struct {
	Issuer       string    `json:"issuer"`
	AccountName  string    `json:"account_name"`
	Secret       string    `json:"secret"`
	App          string    `json:"app"`
	GuestMode    bool      `json:"guest_mode,omitempty"`
	ConfiguredAt time.Time `json:"configured_at"`
}

type AuthenticatorStore struct {
	path string
	mu   sync.RWMutex
	cfg  *authenticatorConfig
}

func NewAuthenticatorStore(path string) *AuthenticatorStore {
	return &AuthenticatorStore{path: strings.TrimSpace(path)}
}

func (s *AuthenticatorStore) Path() string {
	return s.path
}

func (s *AuthenticatorStore) Load() error {
	if s.path == "" {
		return errors.New("authenticator file path is empty")
	}

	data, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) {
		s.mu.Lock()
		s.cfg = nil
		s.mu.Unlock()
		return nil
	}
	if err != nil {
		return err
	}
	if len(strings.TrimSpace(string(data))) == 0 {
		s.mu.Lock()
		s.cfg = nil
		s.mu.Unlock()
		return nil
	}

	var cfg authenticatorConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return err
	}
	cfg.Issuer = strings.TrimSpace(cfg.Issuer)
	cfg.AccountName = strings.TrimSpace(cfg.AccountName)
	cfg.Secret = normalizeTOTPSecret(cfg.Secret)
	cfg.App = normalizeAuthenticatorApp(cfg.App)
	if cfg.Issuer == "" || cfg.AccountName == "" || cfg.Secret == "" {
		return errors.New("authenticator config is incomplete")
	}

	s.mu.Lock()
	s.cfg = &cfg
	s.mu.Unlock()
	return nil
}

func (s *AuthenticatorStore) IsConfigured() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.cfg != nil && s.cfg.Secret != ""
}

func (s *AuthenticatorStore) IsGuestMode() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.cfg != nil && s.cfg.GuestMode
}

func (s *AuthenticatorStore) SetGuestMode(enabled bool) error {
	if s.path == "" {
		return errors.New("authenticator file path is empty")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	var cfg authenticatorConfig
	if s.cfg != nil {
		cfg = *s.cfg
	}
	cfg.GuestMode = enabled

	serialized, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	serialized = append(serialized, '\n')

	dir := filepath.Dir(s.path)
	if dir != "." {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return err
		}
	}
	if err := os.WriteFile(s.path, serialized, 0o600); err != nil {
		return err
	}
	s.cfg = &cfg
	return nil
}

func (s *AuthenticatorStore) SaveConfigured(secret string, configuredAt time.Time, app ...string) error {
	if s.path == "" {
		return errors.New("authenticator file path is empty")
	}

	cfg := authenticatorConfig{
		Issuer:       defaultTOTPIssuer,
		AccountName:  defaultTOTPAccountName,
		Secret:       normalizeTOTPSecret(secret),
		ConfiguredAt: configuredAt.UTC(),
	}
	if len(app) > 0 {
		cfg.App = normalizeAuthenticatorApp(app[0])
	} else {
		cfg.App = "google"
	}
	if cfg.Secret == "" {
		return errors.New("authenticator secret is required")
	}

	serialized, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	serialized = append(serialized, '\n')

	dir := filepath.Dir(s.path)
	if dir != "." {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return err
		}
	}
	if err := os.WriteFile(s.path, serialized, 0o600); err != nil {
		return err
	}

	s.mu.Lock()
	s.cfg = &cfg
	s.mu.Unlock()
	return nil
}

func (s *AuthenticatorStore) App() string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.cfg == nil {
		return "google"
	}
	return normalizeAuthenticatorApp(s.cfg.App)
}

func normalizeAuthenticatorApp(value string) string {
	if strings.EqualFold(strings.TrimSpace(value), "2fas") {
		return "2fas"
	}
	return "google"
}

func (s *AuthenticatorStore) ValidateCode(code string, now time.Time) bool {
	s.mu.RLock()
	cfg := s.cfg
	s.mu.RUnlock()
	if cfg == nil {
		return false
	}
	return validateTOTPCode(cfg.Secret, code, now)
}

func GenerateTOTPSecret() (string, error) {
	raw := make([]byte, 20)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return strings.TrimRight(base32.StdEncoding.EncodeToString(raw), "="), nil
}

func BuildTOTPAuthURL(secret string) string {
	return BuildTOTPAuthURLForAccount(secret, defaultTOTPAccountName)
}

func BuildTOTPAuthURLForAccount(secret, accountName string) string {
	issuer := defaultTOTPIssuer
	accountName = strings.TrimSpace(accountName)
	if accountName == "" {
		accountName = defaultTOTPAccountName
	}
	label := url.PathEscape(issuer) + ":" + url.PathEscape(accountName)
	query := url.Values{}
	query.Set("secret", normalizeTOTPSecret(secret))
	query.Set("issuer", issuer)
	query.Set("algorithm", "SHA1")
	query.Set("digits", fmt.Sprintf("%d", totpDigits))
	query.Set("period", fmt.Sprintf("%d", totpPeriod))
	return "otpauth://totp/" + label + "?" + query.Encode()
}

func normalizeTOTPSecret(secret string) string {
	return strings.ToUpper(strings.ReplaceAll(strings.TrimSpace(secret), " ", ""))
}

func normalizeTOTPCode(code string) string {
	return strings.ReplaceAll(strings.TrimSpace(code), " ", "")
}

func validateTOTPCode(secret, code string, now time.Time) bool {
	cleanCode := normalizeTOTPCode(code)
	if len(cleanCode) != totpDigits {
		return false
	}
	for _, r := range cleanCode {
		if r < '0' || r > '9' {
			return false
		}
	}

	counter := now.Unix() / totpPeriod
	for offset := -totpWindow; offset <= totpWindow; offset++ {
		expected, err := generateTOTPCode(secret, counter+int64(offset))
		if err != nil {
			return false
		}
		if hmac.Equal([]byte(expected), []byte(cleanCode)) {
			return true
		}
	}
	return false
}

func generateTOTPCode(secret string, counter int64) (string, error) {
	key, err := base32.StdEncoding.WithPadding(base32.NoPadding).DecodeString(normalizeTOTPSecret(secret))
	if err != nil {
		return "", err
	}

	msg := make([]byte, 8)
	binary.BigEndian.PutUint64(msg, uint64(counter))

	mac := hmac.New(sha1.New, key)
	if _, err := mac.Write(msg); err != nil {
		return "", err
	}
	hash := mac.Sum(nil)
	offset := hash[len(hash)-1] & 0x0f
	binaryCode := (int(hash[offset])&0x7f)<<24 |
		(int(hash[offset+1])&0xff)<<16 |
		(int(hash[offset+2])&0xff)<<8 |
		(int(hash[offset+3]) & 0xff)
	otp := binaryCode % int(math.Pow10(totpDigits))
	return fmt.Sprintf("%0*d", totpDigits, otp), nil
}
