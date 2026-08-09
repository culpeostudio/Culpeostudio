package login

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	loginv1 "github.com/culpeohq/backend/gen/go/culpeostudio/login/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
)

type grpcService struct {
	loginv1.UnimplementedLoginServiceServer
	module *LoginModule
}

func (m *LoginModule) RegisterGRPC(server *grpc.Server) {
	loginv1.RegisterLoginServiceServer(server, &grpcService{module: m})
}

func (s *grpcService) Login(ctx context.Context, req *loginv1.LoginRequest) (*loginv1.LoginResponse, error) {
	m := s.module

	username := strings.TrimSpace(req.GetUsername())
	password := strings.TrimSpace(req.GetPassword())
	if username == "" || password == "" {
		return nil, status.Error(codes.InvalidArgument, "Username und Passwort sind erforderlich")
	}

	if err := m.accountStore.Load(); err != nil {
		return nil, status.Error(codes.Internal, "Konnte Accounts nicht laden")
	}
	if !m.accountStore.ValidateCredentials(username, password) {
		return nil, status.Error(codes.Unauthenticated, "Ungueltige Anmeldedaten")
	}
	if canonical, ok := m.accountStore.CanonicalUsername(username); ok {
		username = canonical
	}

	granted := resolveSessionDuration(req.GetSessionDuration())
	claims := jwt.MapClaims{
		"user_id":  username,
		"username": username,
	}
	if granted == loginv1.SessionDuration_SESSION_DURATION_PERMANENT {
		claims["session_duration"] = "permanent"
	} else {
		claims["exp"] = time.Now().Add(sessionLifetime(granted)).Unix()
	}

	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(m.JWTSecret))
	if err != nil {
		return nil, status.Error(codes.Internal, "Token-Erstellung fehlgeschlagen")
	}

	return &loginv1.LoginResponse{
		Token:           token,
		Username:        username,
		SessionDuration: granted,
	}, nil
}

// resolveSessionDuration mirrors the old string handling: anything the API did
// not recognise, UNSPECIFIED included, becomes 24h.
func resolveSessionDuration(requested loginv1.SessionDuration) loginv1.SessionDuration {
	switch requested {
	case loginv1.SessionDuration_SESSION_DURATION_8H,
		loginv1.SessionDuration_SESSION_DURATION_48H,
		loginv1.SessionDuration_SESSION_DURATION_PERMANENT:
		return requested
	default:
		return loginv1.SessionDuration_SESSION_DURATION_24H
	}
}

func sessionLifetime(granted loginv1.SessionDuration) time.Duration {
	switch granted {
	case loginv1.SessionDuration_SESSION_DURATION_8H:
		return 8 * time.Hour
	case loginv1.SessionDuration_SESSION_DURATION_48H:
		return 48 * time.Hour
	default:
		return 24 * time.Hour
	}
}

func (s *grpcService) GetAuthStatus(ctx context.Context, req *loginv1.GetAuthStatusRequest) (*loginv1.GetAuthStatusResponse, error) {
	return &loginv1.GetAuthStatusResponse{
		TotpConfigured:   s.module.authStore.IsConfigured(),
		AuthenticatorApp: s.module.authStore.App(),
	}, nil
}

func (s *grpcService) StartAuthenticatorSetup(ctx context.Context, req *loginv1.StartAuthenticatorSetupRequest) (*loginv1.StartAuthenticatorSetupResponse, error) {
	m := s.module
	if m.authStore.IsConfigured() {
		return nil, status.Error(codes.AlreadyExists, "Authenticator ist bereits eingerichtet")
	}

	secret, err := GenerateTOTPSecret()
	if err != nil {
		return nil, status.Error(codes.Internal, "Authenticator-Secret konnte nicht erstellt werden")
	}

	m.pendingMu.Lock()
	m.pendingSecret = secret
	m.pendingMu.Unlock()

	return &loginv1.StartAuthenticatorSetupResponse{
		Secret:     secret,
		OtpauthUrl: BuildTOTPAuthURL(secret),
	}, nil
}

func (s *grpcService) ConfirmAuthenticatorSetup(ctx context.Context, req *loginv1.ConfirmAuthenticatorSetupRequest) (*loginv1.ConfirmAuthenticatorSetupResponse, error) {
	m := s.module
	if m.authStore.IsConfigured() {
		return nil, status.Error(codes.AlreadyExists, "Authenticator ist bereits eingerichtet")
	}

	m.pendingMu.Lock()
	pendingSecret := m.pendingSecret
	m.pendingMu.Unlock()
	if strings.TrimSpace(pendingSecret) == "" {
		return nil, status.Error(codes.FailedPrecondition, "Authenticator-Setup muss zuerst gestartet werden")
	}
	if !validateTOTPCode(pendingSecret, req.GetCode(), time.Now()) {
		return nil, status.Error(codes.Unauthenticated, "Ungueltiger Authenticator-Code")
	}
	if err := m.authStore.SaveConfigured(pendingSecret, time.Now(), req.GetApp()); err != nil {
		return nil, status.Error(codes.Internal, "Authenticator konnte nicht gespeichert werden")
	}

	m.pendingMu.Lock()
	m.pendingSecret = ""
	m.pendingMu.Unlock()

	return &loginv1.ConfirmAuthenticatorSetupResponse{TotpConfigured: true}, nil
}

func (s *grpcService) CreateAccount(ctx context.Context, req *loginv1.CreateAccountRequest) (*loginv1.CreateAccountResponse, error) {
	m := s.module
	if err := totpStatusError(m.requireValidTOTP(req.GetTotpCode())); err != nil {
		return nil, err
	}

	m.accountCreateMu.Lock()
	defer m.accountCreateMu.Unlock()

	if err := m.accountStore.Load(); err != nil {
		return nil, status.Error(codes.Internal, "Konnte Accounts nicht laden")
	}
	if err := m.accountStore.CreateUser(req.GetUsername(), req.GetPassword()); err != nil {
		if errors.Is(err, ErrUserExists) {
			return nil, status.Error(codes.AlreadyExists, "Benutzer existiert bereits")
		}
		return nil, status.Error(codes.InvalidArgument, "Account konnte nicht erstellt werden")
	}

	username := strings.TrimSpace(req.GetUsername())
	if canonical, ok := m.accountStore.CanonicalUsername(username); ok {
		username = canonical
	}
	if err := m.notifyUserCreated(username); err != nil {
		return nil, status.Error(codes.Internal, "Account wurde erstellt, aber das Benutzerprofil konnte nicht initialisiert werden")
	}

	return &loginv1.CreateAccountResponse{Username: username}, nil
}

func (s *grpcService) ResetPassword(ctx context.Context, req *loginv1.ResetPasswordRequest) (*loginv1.ResetPasswordResponse, error) {
	m := s.module
	if err := totpStatusError(m.requireValidTOTP(req.GetTotpCode())); err != nil {
		return nil, err
	}

	if err := m.accountStore.Load(); err != nil {
		return nil, status.Error(codes.Internal, "Konnte Accounts nicht laden")
	}
	if err := m.accountStore.ResetPassword(req.GetUsername(), req.GetNewPassword()); err != nil {
		if errors.Is(err, ErrUserNotFound) {
			return nil, status.Error(codes.NotFound, "Benutzer nicht gefunden")
		}
		return nil, status.Error(codes.InvalidArgument, "Passwort konnte nicht zurueckgesetzt werden")
	}

	return &loginv1.ResetPasswordResponse{
		Username:      strings.TrimSpace(req.GetUsername()),
		PasswordReset: true,
	}, nil
}

func (s *grpcService) GetUserPreferences(ctx context.Context, req *loginv1.GetUserPreferencesRequest) (*loginv1.GetUserPreferencesResponse, error) {
	userID, err := authenticatedUser(ctx)
	if err != nil {
		return nil, err
	}
	preferences, configured := s.module.preferencesStore.Get(userID)
	return &loginv1.GetUserPreferencesResponse{
		Preferences: userPreferencesToProto(preferences, configured),
	}, nil
}

func (s *grpcService) UpdateUserPreferences(ctx context.Context, req *loginv1.UpdateUserPreferencesRequest) (*loginv1.UpdateUserPreferencesResponse, error) {
	userID, err := authenticatedUser(ctx)
	if err != nil {
		return nil, err
	}

	preferences, updateErr := s.module.preferencesStore.Set(userID, req.GetLanguage(), req.GetFrontendVersion())
	if updateErr != nil {
		return nil, status.Error(codes.InvalidArgument, updateErr.Error())
	}
	return &loginv1.UpdateUserPreferencesResponse{
		Preferences: userPreferencesToProto(preferences, true),
	}, nil
}

// authenticatedUser reads the user the auth interceptor put on the context.
// These two calls are not in the public list, so a missing id means the token
// carried no usable claim.
func authenticatedUser(ctx context.Context) (string, error) {
	userID := strings.TrimSpace(grpcmw.UserIDFromContext(ctx))
	if userID == "" {
		return "", status.Error(codes.Unauthenticated, "Nicht autorisiert")
	}
	return userID, nil
}

func userPreferencesToProto(preferences UserPreferences, configured bool) *loginv1.UserPreferences {
	return &loginv1.UserPreferences{
		Configured:      configured,
		Language:        preferences.Language,
		FrontendVersion: preferences.FrontendVersion,
	}
}

func totpStatusError(err error) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, errAuthenticatorMissing):
		return status.Error(codes.FailedPrecondition, "Authenticator ist nicht eingerichtet")
	default:
		return status.Error(codes.Unauthenticated, "Ungueltiger Authenticator-Code")
	}
}
