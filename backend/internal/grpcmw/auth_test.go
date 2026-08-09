package grpcmw

import (
	"context"
	"testing"

	"github.com/golang-jwt/jwt/v5"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

const testSecret = "test-secret"

func signedToken(t *testing.T, secret, userID, username string) string {
	t.Helper()
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  userID,
		"username": username,
	})
	signed, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("token signieren fehlgeschlagen: %v", err)
	}
	return signed
}

func contextWithAuth(value string) context.Context {
	return metadata.NewIncomingContext(
		context.Background(),
		metadata.Pairs(metadataAuthKey, value),
	)
}

// callUnary runs the interceptor and reports the context the handler saw.
func callUnary(cfg AuthConfig, ctx context.Context, method string) (context.Context, error) {
	var seen context.Context
	interceptor := UnaryAuthInterceptor(cfg)
	_, err := interceptor(
		ctx,
		nil,
		&grpc.UnaryServerInfo{FullMethod: method},
		func(handlerCtx context.Context, _ any) (any, error) {
			seen = handlerCtx
			return nil, nil
		},
	)
	return seen, err
}

func TestUnaryAuthAcceptsValidToken(t *testing.T) {
	cfg := AuthConfig{Secret: testSecret}
	token := signedToken(t, testSecret, "user-1", "anna")

	seen, err := callUnary(cfg, contextWithAuth("Bearer "+token), "/svc/Method")
	if err != nil {
		t.Fatalf("erwartete Erfolg, bekam: %v", err)
	}
	if got := UserIDFromContext(seen); got != "user-1" {
		t.Fatalf("user_id = %q, erwartet %q", got, "user-1")
	}
	if got := UsernameFromContext(seen); got != "anna" {
		t.Fatalf("username = %q, erwartet %q", got, "anna")
	}
}

func TestUnaryAuthAcceptsLowercaseScheme(t *testing.T) {
	cfg := AuthConfig{Secret: testSecret}
	token := signedToken(t, testSecret, "user-1", "anna")

	if _, err := callUnary(cfg, contextWithAuth("bearer "+token), "/svc/Method"); err != nil {
		t.Fatalf("Schema sollte case-insensitiv sein, bekam: %v", err)
	}
}

func TestUnaryAuthAllowsPublicMethodWithoutToken(t *testing.T) {
	cfg := AuthConfig{
		Secret:        testSecret,
		PublicMethods: map[string]bool{"/svc/Login": true},
	}

	if _, err := callUnary(cfg, context.Background(), "/svc/Login"); err != nil {
		t.Fatalf("öffentliche Methode sollte ohne Token durchgehen, bekam: %v", err)
	}
}

func TestUnaryAuthRejectsMissingAndMalformedToken(t *testing.T) {
	cfg := AuthConfig{Secret: testSecret}
	token := signedToken(t, testSecret, "user-1", "anna")

	cases := map[string]context.Context{
		"keine Metadaten":   context.Background(),
		"leerer Header":     contextWithAuth(""),
		"falsches Schema":   contextWithAuth("Basic " + token),
		"nur Schema":        contextWithAuth("Bearer "),
		"Token ohne Bearer": contextWithAuth(token),
	}

	for name, ctx := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := callUnary(cfg, ctx, "/svc/Method"); status.Code(err) != codes.Unauthenticated {
				t.Fatalf("erwartete Unauthenticated, bekam: %v", err)
			}
		})
	}
}

func TestUnaryAuthRejectsTokenSignedWithOtherSecret(t *testing.T) {
	cfg := AuthConfig{Secret: testSecret}
	token := signedToken(t, "anderes-secret", "user-1", "anna")

	if _, err := callUnary(cfg, contextWithAuth("Bearer "+token), "/svc/Method"); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("erwartete Unauthenticated, bekam: %v", err)
	}
}

func TestUnaryAuthRejectsRemovedAccount(t *testing.T) {
	cfg := AuthConfig{
		Secret:       testSecret,
		IsActiveUser: func(string) bool { return false },
	}
	token := signedToken(t, testSecret, "user-1", "anna")

	if _, err := callUnary(cfg, contextWithAuth("Bearer "+token), "/svc/Method"); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("erwartete Unauthenticated, bekam: %v", err)
	}
}

// The handler must observe the authenticated context, not the original one.
func TestStreamAuthPassesAuthenticatedContextToHandler(t *testing.T) {
	cfg := AuthConfig{Secret: testSecret}
	token := signedToken(t, testSecret, "user-7", "bo")

	var seen context.Context
	interceptor := StreamAuthInterceptor(cfg)
	err := interceptor(
		nil,
		&fakeServerStream{ctx: contextWithAuth("Bearer " + token)},
		&grpc.StreamServerInfo{FullMethod: "/svc/Stream"},
		func(_ any, stream grpc.ServerStream) error {
			seen = stream.Context()
			return nil
		},
	)
	if err != nil {
		t.Fatalf("erwartete Erfolg, bekam: %v", err)
	}
	if got := UsernameFromContext(seen); got != "bo" {
		t.Fatalf("username = %q, erwartet %q", got, "bo")
	}
}

func TestStreamAuthRejectsMissingToken(t *testing.T) {
	cfg := AuthConfig{Secret: testSecret}
	interceptor := StreamAuthInterceptor(cfg)

	err := interceptor(
		nil,
		&fakeServerStream{ctx: context.Background()},
		&grpc.StreamServerInfo{FullMethod: "/svc/Stream"},
		func(any, grpc.ServerStream) error {
			t.Fatal("Handler darf nicht laufen")
			return nil
		},
	)
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("erwartete Unauthenticated, bekam: %v", err)
	}
}

type fakeServerStream struct {
	grpc.ServerStream
	ctx context.Context
}

func (s *fakeServerStream) Context() context.Context { return s.ctx }

// A module token is not a JWT, so it only gets in through AlternateAuth - and
// the module decides which methods that is on.
func TestUnaryAuthFallsBackToAlternateAuth(t *testing.T) {
	cfg := AuthConfig{
		Secret: testSecret,
		AlternateAuth: func(_ context.Context, fullMethod, token string) (string, bool) {
			if fullMethod == "/module/Method" && token == "module-token" {
				return "tool-user", true
			}
			return "", false
		},
	}

	seen, err := callUnary(cfg, contextWithAuth("Bearer module-token"), "/module/Method")
	if err != nil {
		t.Fatalf("das Modul-Token sollte akzeptiert werden, bekam: %v", err)
	}
	if got := UserIDFromContext(seen); got != "tool-user" {
		t.Fatalf("user_id = %q, erwartet %q", got, "tool-user")
	}
	// No account was named, so nothing may claim one.
	if got := UsernameFromContext(seen); got != "" {
		t.Fatalf("username = %q, erwartet leer", got)
	}
}

func TestUnaryAuthRejectsAlternateTokenOnAnotherMethod(t *testing.T) {
	cfg := AuthConfig{
		Secret: testSecret,
		AlternateAuth: func(_ context.Context, fullMethod, token string) (string, bool) {
			return "tool-user", fullMethod == "/module/Method"
		},
	}

	_, err := callUnary(cfg, contextWithAuth("Bearer module-token"), "/other/Method")
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("erwartete Unauthenticated, bekam: %v", err)
	}
}

// A valid session token must never reach the module credential path, otherwise
// a module could widen what a logged-in call is allowed to do.
func TestUnaryAuthPrefersTheSessionToken(t *testing.T) {
	called := false
	cfg := AuthConfig{
		Secret: testSecret,
		AlternateAuth: func(context.Context, string, string) (string, bool) {
			called = true
			return "tool-user", true
		},
	}

	seen, err := callUnary(cfg, contextWithAuth("Bearer "+signedToken(t, testSecret, "user-1", "anna")), "/svc/Method")
	if err != nil {
		t.Fatalf("erwartete Erfolg, bekam: %v", err)
	}
	if called {
		t.Fatal("AlternateAuth wurde trotz gueltigem Session-Token befragt")
	}
	if got := UserIDFromContext(seen); got != "user-1" {
		t.Fatalf("user_id = %q, erwartet %q", got, "user-1")
	}
}
