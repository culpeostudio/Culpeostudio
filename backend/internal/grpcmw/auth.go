// Package grpcmw provides the server interceptors shared by the gRPC services:
// authentication, request logging and panic recovery. It is the gRPC
// counterpart of the Fiber middleware the HTTP control plane used to run.
package grpcmw

import (
	"context"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// metadataAuthKey is the metadata entry carrying the bearer token. gRPC
// lowercases metadata keys, so it must be written in lower case here too.
const metadataAuthKey = "authorization"

type contextKey string

const (
	contextKeyUserID   contextKey = "user_id"
	contextKeyUsername contextKey = "username"
)

// AuthConfig describes how a call is authenticated.
type AuthConfig struct {
	// Secret signs and verifies the JWTs.
	Secret string

	// IsActiveUser reports whether the account named in the token still
	// exists. A nil value skips the check.
	IsActiveUser func(string) bool

	// PublicMethods lists the fully qualified gRPC methods that are reachable
	// without a token, e.g. "/culpeostudio.login.v1.LoginService/Login".
	PublicMethods map[string]bool

	// AlternateAuth authenticates a call whose bearer token is not a session
	// JWT, and reports the user id it acts for. It is asked only once the JWT
	// has failed to verify, and it decides for itself which methods it accepts,
	// so a credential that is not the app's own login cannot reach further than
	// the module that issued it.
	//
	// The memory module uses this: it hands out its own API token to tools
	// outside the app, which have no account to log in with.
	AlternateAuth func(ctx context.Context, fullMethod, token string) (string, bool)
}

// UserIDFromContext returns the authenticated user id, or an empty string on an
// unauthenticated call.
func UserIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyUserID).(string)
	return value
}

// UsernameFromContext returns the authenticated username, or an empty string on
// an unauthenticated call.
func UsernameFromContext(ctx context.Context) string {
	value, _ := ctx.Value(contextKeyUsername).(string)
	return value
}

// ContextWithUserForTest builds the context an authenticated call carries. The
// context keys are unexported, so module tests need this to exercise a handler
// without standing up the interceptor around it.
func ContextWithUserForTest(ctx context.Context, userID, username string) context.Context {
	ctx = context.WithValue(ctx, contextKeyUserID, userID)
	return context.WithValue(ctx, contextKeyUsername, username)
}

// UnaryAuthInterceptor authenticates unary calls.
func UnaryAuthInterceptor(cfg AuthConfig) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		authenticated, err := authenticate(ctx, cfg, info.FullMethod)
		if err != nil {
			return nil, err
		}
		return handler(authenticated, req)
	}
}

// StreamAuthInterceptor authenticates streaming calls. The authenticated
// context is handed to the handler through a wrapped ServerStream, because
// grpc.ServerStream exposes its context read-only.
func StreamAuthInterceptor(cfg AuthConfig) grpc.StreamServerInterceptor {
	return func(
		srv any,
		stream grpc.ServerStream,
		info *grpc.StreamServerInfo,
		handler grpc.StreamHandler,
	) error {
		authenticated, err := authenticate(stream.Context(), cfg, info.FullMethod)
		if err != nil {
			return err
		}
		return handler(srv, &authenticatedStream{ServerStream: stream, ctx: authenticated})
	}
}

type authenticatedStream struct {
	grpc.ServerStream
	ctx context.Context
}

func (s *authenticatedStream) Context() context.Context { return s.ctx }

// authenticate verifies the bearer token in the request metadata and returns a
// context carrying the resulting claims. Public methods pass through untouched.
func authenticate(ctx context.Context, cfg AuthConfig, fullMethod string) (context.Context, error) {
	if cfg.PublicMethods[fullMethod] {
		return ctx, nil
	}

	token, err := bearerToken(ctx)
	if err != nil {
		return nil, err
	}

	parsed, err := jwt.Parse(token, func(*jwt.Token) (any, error) {
		return []byte(cfg.Secret), nil
	})
	if err != nil || !parsed.Valid {
		// Not a session token. It may still be a credential a module issued
		// itself, which only that module's methods accept.
		if cfg.AlternateAuth != nil {
			if userID, ok := cfg.AlternateAuth(ctx, fullMethod, token); ok {
				return context.WithValue(ctx, contextKeyUserID, userID), nil
			}
		}
		return nil, status.Error(codes.Unauthenticated, "Ungueltiger Token")
	}

	claims, ok := parsed.Claims.(jwt.MapClaims)
	if !ok {
		return nil, status.Error(codes.Unauthenticated, "Ungueltige Claims")
	}

	username, _ := claims["username"].(string)
	if cfg.IsActiveUser != nil && !cfg.IsActiveUser(username) {
		return nil, status.Error(codes.Unauthenticated, "Account existiert nicht mehr")
	}

	userID, _ := claims["user_id"].(string)
	ctx = context.WithValue(ctx, contextKeyUserID, userID)
	ctx = context.WithValue(ctx, contextKeyUsername, username)
	return ctx, nil
}

func bearerToken(ctx context.Context) (string, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return "", status.Error(codes.Unauthenticated, "Nicht autorisiert")
	}
	values := md.Get(metadataAuthKey)
	if len(values) == 0 {
		return "", status.Error(codes.Unauthenticated, "Nicht autorisiert")
	}
	// Compare case-insensitively: the scheme is case-insensitive per RFC 7235.
	raw := values[0]
	if len(raw) < 7 || !strings.EqualFold(raw[:7], "Bearer ") {
		return "", status.Error(codes.Unauthenticated, "Nicht autorisiert")
	}
	token := strings.TrimSpace(raw[7:])
	if token == "" {
		return "", status.Error(codes.Unauthenticated, "Nicht autorisiert")
	}
	return token, nil
}
